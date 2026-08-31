<#
.SYNOPSIS
    Resolve (or un-resolve) the Asana task mirrored from a GitHub issue -- the CI half of the
    workflow-bwj rule. Copied into a BWJ store repo as .github/scripts/asana-mirror.ps1 and driven
    by .github/workflows/asana-mirror.yml.

.DESCRIPTION
    Two modes:

      -Mode event      One issue changed. -Event is 'closed' or 'reopened'; -IssueBody is the issue
                       body (the <!-- asana-task: GID --> marker is read from it); -IssueRef is
                       'owner/repo#n' for the Asana comment. 'closed' completes the task, 'reopened'
                       re-opens it. A body with no valid marker is logged and skipped, never guessed.

      -Mode reconcile  Sweep. Lists the project's incomplete tasks, reads a GitHub issue URL from
                       each task's notes, checks that issue's state with `gh`, and completes any task
                       whose issue is closed. Covers a missed 'closed' event.

    Auth: -AsanaPat (from the ASANA_PAT secret). Project/workspace: -ProjectGid / -WorkspaceGid
    (from the ASANA_PROJECT_GID / ASANA_WORKSPACE_GID variables).

    The pure helpers (Get-AsanaTaskGid, New-AsanaCompleteRequest, Get-IssueRefFromNotes) take no
    network and are what .github/scripts/asana-mirror.tests.ps1 (and the source repo's
    scripts/tests/workflow-bwj.tests.ps1) exercise. The script runs its main flow only when invoked
    directly; dot-sourcing it loads the helpers and does nothing else.

    Pure ASCII (repo convention for .ps1).
#>
[CmdletBinding()]
param(
    [ValidateSet('event', 'reconcile')]
    [string]$Mode = 'event',

    [ValidateSet('closed', 'reopened')]
    [string]$Event = 'closed',

    [string]$IssueBody = '',
    [string]$IssueRef = '',
    [string]$Repo = '',

    [string]$AsanaPat = $env:ASANA_PAT,
    [string]$ProjectGid = $env:ASANA_PROJECT_GID,
    [string]$WorkspaceGid = $env:ASANA_WORKSPACE_GID
)

$ErrorActionPreference = 'Stop'

$script:AsanaApiBase = 'https://app.asana.com/api/1.0'

function Get-AsanaTaskGid {
    <#
        Read the machine marker '<!-- asana-task: <digits> -->' from an issue body and return the
        bare numeric GID as a string, or $null if there is no valid marker. Non-numeric content
        never matches, so it can never reach a request URL.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$IssueBody)

    $m = [regex]::Match($IssueBody, '<!--\s*asana-task:\s*([0-9]+)\s*-->')
    if (-not $m.Success) { return $null }
    return $m.Groups[1].Value
}

function Get-IssueRefFromNotes {
    <#
        Pull an 'owner/repo#n' reference out of a GitHub issue URL in an Asana task's notes.
        Returns $null when the notes carry no github.com issue URL.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Notes)

    $m = [regex]::Match($Notes, 'https://github\.com/([^/\s]+/[^/\s]+)/issues/([0-9]+)')
    if (-not $m.Success) { return $null }
    return ('{0}#{1}' -f $m.Groups[1].Value, $m.Groups[2].Value)
}

function New-AsanaCompleteRequest {
    <#
        Pure: describe the PUT that completes or re-opens a task. No network.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Gid,
        [Parameter(Mandatory = $true)][bool]$Completed
    )
    if ($Gid -notmatch '^[0-9]+$') { throw "Refusing to build a request for a non-numeric task GID: '$Gid'." }
    [pscustomobject]@{
        Method = 'PUT'
        Uri    = "$script:AsanaApiBase/tasks/$Gid"
        Body   = (ConvertTo-Json @{ data = @{ completed = $Completed } } -Compress -Depth 5)
    }
}

function New-AsanaCommentRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Gid,
        [Parameter(Mandatory = $true)][string]$Text
    )
    if ($Gid -notmatch '^[0-9]+$') { throw "Refusing to build a request for a non-numeric task GID: '$Gid'." }
    [pscustomobject]@{
        Method = 'POST'
        Uri    = "$script:AsanaApiBase/tasks/$Gid/stories"
        Body   = (ConvertTo-Json @{ data = @{ text = $Text } } -Compress -Depth 5)
    }
}

function Invoke-AsanaRequest {
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$Request,
        [Parameter(Mandatory = $true)][string]$Pat
    )
    $headers = @{ Authorization = "Bearer $Pat"; 'Content-Type' = 'application/json' }
    return Invoke-RestMethod -Method $Request.Method -Uri $Request.Uri -Headers $headers -Body $Request.Body
}

function Set-AsanaTaskCompleted {
    param(
        [Parameter(Mandatory = $true)][string]$Gid,
        [Parameter(Mandatory = $true)][bool]$Completed,
        [Parameter(Mandatory = $true)][string]$Pat,
        [string]$Comment = ''
    )
    Invoke-AsanaRequest -Request (New-AsanaCompleteRequest -Gid $Gid -Completed $Completed) -Pat $Pat | Out-Null
    if ($Comment) {
        Invoke-AsanaRequest -Request (New-AsanaCommentRequest -Gid $Gid -Text $Comment) -Pat $Pat | Out-Null
    }
}

function Get-ProjectIncompleteTasks {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectGid,
        [Parameter(Mandatory = $true)][string]$Pat
    )
    $headers = @{ Authorization = "Bearer $Pat" }
    $uri = "$script:AsanaApiBase/projects/$ProjectGid/tasks?opt_fields=completed,notes,name&limit=100"
    $out = @()
    while ($uri) {
        $resp = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
        $out += @($resp.data | Where-Object { -not $_.completed })
        $uri = if ($resp.next_page -and $resp.next_page.uri) { $resp.next_page.uri } else { $null }
    }
    return $out
}

function Test-GitHubIssueClosed {
    param([Parameter(Mandatory = $true)][string]$IssueRef)
    $parts = $IssueRef -split '#'
    $state = (& gh issue view $parts[1] --repo $parts[0] --json state --jq '.state') 2>$null
    return ($LASTEXITCODE -eq 0 -and $state -eq 'CLOSED')
}

function Invoke-EventMode {
    if (-not $AsanaPat) { throw 'ASANA_PAT is not set.' }
    $gid = Get-AsanaTaskGid -IssueBody $IssueBody
    if (-not $gid) {
        Write-Host "No <!-- asana-task: ... --> marker on $IssueRef -- nothing to mirror."
        return
    }
    $completed = ($Event -eq 'closed')
    $comment = if ($completed) { "Resolved via GitHub $IssueRef" } else { "Reopened via GitHub $IssueRef" }
    Set-AsanaTaskCompleted -Gid $gid -Completed $completed -Pat $AsanaPat -Comment $comment
    Write-Host "Asana task $gid set completed=$completed (from $IssueRef)."
}

function Invoke-ReconcileMode {
    if (-not $AsanaPat) { throw 'ASANA_PAT is not set.' }
    if (-not $ProjectGid) { throw 'ASANA_PROJECT_GID is not set.' }
    $tasks = Get-ProjectIncompleteTasks -ProjectGid $ProjectGid -Pat $AsanaPat
    $fixed = 0
    foreach ($t in $tasks) {
        $ref = Get-IssueRefFromNotes -Notes ([string]$t.notes)
        if (-not $ref) { continue }
        if (Test-GitHubIssueClosed -IssueRef $ref) {
            Set-AsanaTaskCompleted -Gid $t.gid -Completed $true -Pat $AsanaPat -Comment "Resolved via GitHub $ref (reconciliation sweep)"
            Write-Host "Reconciled: Asana task $($t.gid) completed for closed issue $ref."
            $fixed++
        }
    }
    Write-Host "Reconciliation done -- $fixed task(s) completed."
}

function Invoke-Main {
    switch ($Mode) {
        'event'     { Invoke-EventMode }
        'reconcile' { Invoke-ReconcileMode }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Main
}
