<#
.SYNOPSIS
    Post an update on the Asana task mirrored from a GitHub issue -- the CI half of the bwj-codex
    rule. Copied into a BWJ store repo as .github/scripts/asana-mirror.ps1 and driven by
    .github/workflows/asana-mirror.yml.

.DESCRIPTION
    IT NEVER COMPLETES A TASK, AND THERE IS NO CODE PATH THAT CAN (Dave, September 1, 2026). Closing
    a GitHub issue says the work is built; it does not say the colleague who asked for it has seen it
    work. Only that person resolves their own ticket, after testing. So this script writes exactly one
    kind of thing into Asana -- a comment -- and the 'completed' field is not written anywhere in it.

    Two modes:

      -Mode event      One issue changed. -Event is 'closed' or 'reopened'; -IssueBody is the issue
                       body (the Asana task is resolved from it, see below); -IssueRef is
                       'owner/repo#n'. Both events post a comment: 'closed' says the work is ready to
                       test, 'reopened' says to hold off. An event ALWAYS comments -- it is a real
                       state change, and a second close after a reopen is news again.

      -Mode reconcile  Two sweeps, for events that never arrived, and the only place de-duplication
                       applies:
                       (a) Asana -> GitHub: the project's incomplete tasks, reading a GitHub issue
                           URL from each task's notes and commenting when that issue is closed.
                       (b) GitHub -> Asana: this repo's issues closed in the last -SinceDays days,
                           resolving each body's Asana task and commenting on it. Covers a ticket
                           that came the other way -- imported FROM Asana, whose task carries no
                           back-link for (a) to find.
                       Both skip a task that is already complete (a person resolved it -- leave it
                       alone) and a task that already carries this issue's close update.

    How the Asana task is found -- Resolve-AsanaTaskRef, three matchers tried in this order:

      1. marker      the machine marker '<!-- asana-task: <digits> -->' the report-issue skill
                     writes. Authoritative: an issue that carries one is never matched any other way.
      2. header-row  the header row of an imported ticket -- a markdown table row whose first cell
                     is '**Asana**' -- carrying an Asana task URL. This is the intake shape: a
                     ticket copied out of Asana links its task for a reader, not for a machine.
      3. sole-url    exactly one Asana task URL anywhere else in the body.

    More than one DIFFERENT task in matcher 3 is reported as 'ambiguous' and skipped: the script never
    guesses which ticket an issue belongs to. Add a marker to settle it.

    Auth: -AsanaPat (from the ASANA_PAT secret). Project/workspace: -ProjectGid / -WorkspaceGid
    (from the ASANA_PROJECT_GID / ASANA_WORKSPACE_GID variables). Sweep (b) additionally needs
    -Repo (GITHUB_REPOSITORY) and `gh` on PATH.

    The comment text is English, like everything else this repo ships. It is the workflow speaking,
    not the subject -- the same boundary a BWJ store repo already draws when it keeps its ticket
    headings English while the analysis under them follows whoever filed the ticket.

    The pure helpers (Resolve-AsanaTaskRef, Get-AsanaTaskGid, Get-AsanaGidsFromText,
    New-MirrorComment, Get-MirrorCommentMarker, New-AsanaCommentRequest, Get-IssueRefFromNotes) take
    no network and are what the source repo's scripts/tests/bwj-codex.tests.ps1 exercises. The script
    runs its main flow only when invoked directly; dot-sourcing it loads the helpers and does nothing
    else.

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
    [string]$Repo = $env:GITHUB_REPOSITORY,

    # Sweep (b) lookback, in days. 0 = every closed issue the listing returns.
    [int]$SinceDays = 30,

    [string]$AsanaPat = $env:ASANA_PAT,
    [string]$ProjectGid = $env:ASANA_PROJECT_GID,
    [string]$WorkspaceGid = $env:ASANA_WORKSPACE_GID
)

$ErrorActionPreference = 'Stop'

$script:AsanaApiBase = 'https://app.asana.com/api/1.0'

function Get-AsanaGidsFromText {
    <#
        Return the distinct task GIDs of every Asana task URL in a piece of text, in the order they
        first appear. Both URL shapes Asana hands out are read:

            https://app.asana.com/1/<workspace>/project/<project>/task/<task>
            https://app.asana.com/0/<project>/<task>

        A URL that names no task (a project or portfolio link) contributes nothing.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text)

    $gids = @()
    foreach ($m in [regex]::Matches($Text, 'https://app\.asana\.com/[^\s)>\]]*')) {
        $url = $m.Value
        $t = [regex]::Match($url, '/task/([0-9]+)')
        if (-not $t.Success) { $t = [regex]::Match($url, '^https://app\.asana\.com/0/[0-9]+/([0-9]+)') }
        if ($t.Success) { $gids += $t.Groups[1].Value }
    }
    return @($gids | Select-Object -Unique)
}

function Get-AsanaHeaderRowText {
    <#
        Return the contents of an imported ticket's '| **Asana** | ... |' header row, or '' when the
        body has no such row. Anchored on the row label, so a link to a sibling ticket elsewhere in
        the body cannot be mistaken for this ticket's own task.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$IssueBody)

    $m = [regex]::Match($IssueBody, '(?m)^\|\s*\*{0,2}Asana\*{0,2}\s*\|(.*)$')
    if (-not $m.Success) { return '' }
    return $m.Groups[1].Value
}

function Resolve-AsanaTaskRef {
    <#
        Resolve which Asana task an issue body belongs to. Returns an object with:

            Gid         the numeric task GID as a string, or $null
            Source      'marker' | 'header-row' | 'sole-url' | 'ambiguous' | 'none'
            Candidates  the distinct GIDs seen, for the 'ambiguous' report

        Pure -- no network. Non-numeric content never matches, so it can never reach a request URL.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$IssueBody)

    $marker = [regex]::Match($IssueBody, '<!--\s*asana-task:\s*([0-9]+)\s*-->')
    if ($marker.Success) {
        return [pscustomobject]@{ Gid = $marker.Groups[1].Value; Source = 'marker'; Candidates = @($marker.Groups[1].Value) }
    }

    $row = Get-AsanaHeaderRowText -IssueBody $IssueBody
    if ($row) {
        $rowGids = @(Get-AsanaGidsFromText -Text $row)
        if ($rowGids.Count -ge 1) {
            return [pscustomobject]@{ Gid = $rowGids[0]; Source = 'header-row'; Candidates = $rowGids }
        }
    }

    $all = @(Get-AsanaGidsFromText -Text $IssueBody)
    if ($all.Count -eq 1) { return [pscustomobject]@{ Gid = $all[0]; Source = 'sole-url'; Candidates = $all } }
    if ($all.Count -gt 1) { return [pscustomobject]@{ Gid = $null; Source = 'ambiguous'; Candidates = $all } }
    return [pscustomobject]@{ Gid = $null; Source = 'none'; Candidates = @() }
}

function Get-AsanaTaskGid {
    <#
        The GID Resolve-AsanaTaskRef settled on, or $null. Kept as its own name because it is the
        one thing most callers want.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$IssueBody)

    return (Resolve-AsanaTaskRef -IssueBody $IssueBody).Gid
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

function Get-MirrorCommentMarker {
    <#
        The opening sentence of a close update, which doubles as its de-duplication key. It names the
        issue, so two issues mirrored onto the same task never mask each other. Pure.

        Deliberately a readable sentence rather than an invisible token: this comment is read by a
        colleague, and a machine marker in it would be clutter they cannot act on.
    #>
    param([Parameter(Mandatory = $true)][string]$IssueRef)

    return "GitHub issue $IssueRef is closed"
}

function New-MirrorComment {
    <#
        The comment text for one event. Pure -- no network.

        'closed'   the work is built and ready for the person who asked for it to test.
        'reopened' it is being worked on again; do not test yet.

        Neither text claims the ticket is done, and neither asks anybody to hurry: this script has no
        say over when a ticket is resolved.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$IssueRef,
        [Parameter(Mandatory = $true)][ValidateSet('closed', 'reopened')][string]$Event
    )

    $parts = $IssueRef -split '#'
    $url = "https://github.com/$($parts[0])/issues/$($parts[1])"

    if ($Event -eq 'closed') {
        return @(
            (Get-MirrorCommentMarker -IssueRef $IssueRef) + ': the work behind this ticket is built and ready to test.',
            $url,
            '',
            'This ticket stays open on purpose. Tick it off yourself once you have checked that it does what you meant.'
        ) -join "`n"
    }

    return @(
        "GitHub issue $IssueRef has been reopened: it is being worked on again, so hold off on testing.",
        $url
    ) -join "`n"
}

function New-AsanaCommentRequest {
    <#
        Pure: describe the POST that adds a comment to a task. No network. This is the only write
        this script knows how to build.
    #>
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

function Add-AsanaComment {
    param(
        [Parameter(Mandatory = $true)][string]$Gid,
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pat
    )
    Invoke-AsanaRequest -Request (New-AsanaCommentRequest -Gid $Gid -Text $Text) -Pat $Pat | Out-Null
}

function Get-AsanaTaskState {
    <#
        Read a task's 'completed' flag. Returns $null when the task cannot be read -- it was deleted,
        or it lives in a workspace this PAT has no access to. That is reported and skipped rather
        than thrown, so one unreachable ticket cannot end a sweep over all of them.

        Read-only. The flag is never written back: see the .DESCRIPTION.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Gid,
        [Parameter(Mandatory = $true)][string]$Pat
    )
    if ($Gid -notmatch '^[0-9]+$') { throw "Refusing to read a non-numeric task GID: '$Gid'." }
    $uri = "$script:AsanaApiBase/tasks/$Gid" + '?opt_fields=completed,name'
    try {
        $resp = Invoke-RestMethod -Method GET -Uri $uri -Headers @{ Authorization = "Bearer $Pat" }
        return $resp.data
    } catch {
        Write-Host "  Asana task $Gid is not readable with this token ($($_.Exception.Message)) -- skipped."
        return $null
    }
}

function Test-MirrorUpdatePosted {
    <#
        Has this task already been told that this issue is closed? Reads the task's comments and
        looks for the marker sentence. Used by the sweeps only -- an event always comments.

        An unreadable task answers $true, so a sweep that cannot check does not comment blindly.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Gid,
        [Parameter(Mandatory = $true)][string]$IssueRef,
        [Parameter(Mandatory = $true)][string]$Pat
    )
    if ($Gid -notmatch '^[0-9]+$') { throw "Refusing to read a non-numeric task GID: '$Gid'." }
    $marker = Get-MirrorCommentMarker -IssueRef $IssueRef
    $uri = "$script:AsanaApiBase/tasks/$Gid/stories" + '?opt_fields=text,type&limit=100'
    try {
        $seen = $false
        while ($uri) {
            $resp = Invoke-RestMethod -Method GET -Uri $uri -Headers @{ Authorization = "Bearer $Pat" }
            foreach ($s in @($resp.data)) {
                if ([string]$s.text -and ([string]$s.text).Contains($marker)) { $seen = $true }
            }
            $uri = if ($resp.next_page -and $resp.next_page.uri) { $resp.next_page.uri } else { $null }
        }
        return $seen
    } catch {
        Write-Host "  Comments of Asana task $Gid are not readable ($($_.Exception.Message)) -- skipped rather than commented on blindly."
        return $true
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
    # EAP=Continue for the redirect below: under 'Stop' a successful `gh` that writes any progress to
    # stderr raises a terminating NativeCommandError, so the 2>$null would throw instead of discard.
    # Reverts at function exit. This template ships standalone, so it cannot use Invoke-NativeCapture.
    $ErrorActionPreference = 'Continue'
    $state = (& gh issue view $parts[1] --repo $parts[0] --json state --jq '.state') 2>$null
    return ($LASTEXITCODE -eq 0 -and $state -eq 'CLOSED')
}

function Get-ClosedIssues {
    <#
        This repo's closed issues, newest first, optionally narrowed to the last -SinceDays days.
        Returns an empty list (not a throw) when `gh` is unavailable or fails, so sweep (a) still runs.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [int]$SinceDays = 30
    )
    $ErrorActionPreference = 'Continue'
    $raw = (& gh issue list --repo $Repo --state closed --limit 200 --json number,body,closedAt) 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $raw) {
        Write-Host "  Could not list the closed issues of $Repo with gh -- the GitHub-side sweep is skipped."
        return @()
    }
    $items = @(($raw | Out-String) | ConvertFrom-Json)
    if ($SinceDays -gt 0) {
        $cutoff = (Get-Date).ToUniversalTime().AddDays(-$SinceDays)
        $items = @($items | Where-Object { $_.closedAt -and ([datetime]$_.closedAt).ToUniversalTime() -ge $cutoff })
    }
    return $items
}

function Invoke-EventMode {
    if (-not $AsanaPat) { throw 'ASANA_PAT is not set.' }
    $ref = Resolve-AsanaTaskRef -IssueBody $IssueBody
    if (-not $ref.Gid) {
        if ($ref.Source -eq 'ambiguous') {
            Write-Host "$IssueRef links several different Asana tasks ($($ref.Candidates -join ', ')) -- refusing to guess. Add an explicit <!-- asana-task: GID --> marker to settle it."
        } else {
            Write-Host "No Asana task is linked from $IssueRef -- nothing to mirror."
        }
        return
    }
    # No de-duplication here on purpose: an event is a real state change, so a close after a reopen
    # is news again and gets said again.
    Add-AsanaComment -Gid $ref.Gid -Text (New-MirrorComment -IssueRef $IssueRef -Event $Event) -Pat $AsanaPat
    Write-Host "Asana task $($ref.Gid) updated: $IssueRef $Event (matched by $($ref.Source)). The task was NOT completed -- that is the requester's call."
}

function Update-MirroredTask {
    <#
        The sweeps' shared step: comment on a task for a closed issue, unless a person has already
        resolved it or the update is already there. Returns 1 when it commented, 0 otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Gid,
        [Parameter(Mandatory = $true)][string]$IssueRef,
        [string]$MatchedBy = ''
    )
    $task = Get-AsanaTaskState -Gid $Gid -Pat $AsanaPat
    if ($null -eq $task) { return 0 }
    if ($task.completed) { return 0 }
    if (Test-MirrorUpdatePosted -Gid $Gid -IssueRef $IssueRef -Pat $AsanaPat) { return 0 }

    Add-AsanaComment -Gid $Gid -Text (New-MirrorComment -IssueRef $IssueRef -Event 'closed') -Pat $AsanaPat
    $how = if ($MatchedBy) { " (matched by $MatchedBy)" } else { '' }
    Write-Host "  Updated: Asana task $Gid told that $IssueRef is closed$how."
    return 1
}

function Invoke-ReconcileFromAsana {
    <# Sweep (a): the project's incomplete tasks, matched back to GitHub through their notes. #>
    if (-not $ProjectGid) {
        Write-Host 'ASANA_PROJECT_GID is not set -- the Asana-side sweep is skipped.'
        return 0
    }
    $tasks = Get-ProjectIncompleteTasks -ProjectGid $ProjectGid -Pat $AsanaPat
    $done = 0
    foreach ($t in $tasks) {
        $ref = Get-IssueRefFromNotes -Notes ([string]$t.notes)
        if (-not $ref) { continue }
        if (-not (Test-GitHubIssueClosed -IssueRef $ref)) { continue }
        $done += Update-MirroredTask -Gid ([string]$t.gid) -IssueRef $ref
    }
    Write-Host "Asana-side sweep: $($tasks.Count) open task(s) examined, $done updated."
    return $done
}

function Invoke-ReconcileFromGitHub {
    <#
        Sweep (b): this repo's recently closed issues, matched forward to Asana through their bodies.
        This is the half that reaches a ticket imported FROM Asana -- its task was written by a
        colleague and carries no GitHub back-link for the Asana -> GitHub pass to find.
    #>
    if (-not $Repo) {
        Write-Host 'GITHUB_REPOSITORY is not set -- the GitHub-side sweep is skipped.'
        return 0
    }
    $issues = Get-ClosedIssues -Repo $Repo -SinceDays $SinceDays
    $done = 0
    foreach ($i in $issues) {
        $ref = Resolve-AsanaTaskRef -IssueBody ([string]$i.body)
        if (-not $ref.Gid) { continue }
        $done += Update-MirroredTask -Gid $ref.Gid -IssueRef "$Repo#$($i.number)" -MatchedBy $ref.Source
    }
    Write-Host "GitHub-side sweep: $($issues.Count) closed issue(s) examined, $done updated."
    return $done
}

function Invoke-ReconcileMode {
    if (-not $AsanaPat) { throw 'ASANA_PAT is not set.' }
    $done = 0
    $done += Invoke-ReconcileFromAsana
    $done += Invoke-ReconcileFromGitHub
    Write-Host "Reconciliation done -- $done task(s) updated, 0 completed (this script completes nothing)."
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
