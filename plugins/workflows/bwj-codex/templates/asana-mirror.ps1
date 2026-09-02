<#
.SYNOPSIS
    Keep a BWJ store repo and its Asana board in step -- the CI half of the bwj-codex rule. It posts
    an update on the Asana task mirrored from a GitHub issue, and carries that task's prio score back
    the other way as a label on the issue. Copied into a BWJ store repo as
    .github/scripts/asana-mirror.ps1 and driven by .github/workflows/asana-mirror.yml.

.DESCRIPTION
    IT NEVER COMPLETES A TASK, AND THERE IS NO CODE PATH THAT CAN (Dave, September 1, 2026). Closing
    a GitHub issue says the work is built; it does not say the colleague who asked for it has seen it
    work. Only that person resolves their own ticket, after testing. So this script writes exactly one
    kind of thing into Asana -- a comment -- and the 'completed' field is not written anywhere in it.

    The one thing it writes OUTSIDE Asana is a prio label on a GitHub issue -- sweep (c) below. That
    is a different system and a different claim, and it leaves the guarantee above exactly where it
    was: nothing about a label says anybody has tested anything.

    Two modes:

      -Mode event      One issue changed. -Event is 'closed' or 'reopened'; -IssueBody is the issue
                       body (the Asana task is resolved from it, see below); -IssueRef is
                       'owner/repo#n'. Both events post a comment: 'closed' names the pull request(s)
                       that closed the issue and says the work is ready to test, 'reopened' says to
                       hold off. An event ALWAYS comments -- it is a real state change, and a second
                       close after a reopen is news again.

      -Mode reconcile  Three sweeps, for events that never arrived, and the only place de-duplication
                       applies:
                       (a) Asana -> GitHub: the project's incomplete tasks, reading a GitHub issue
                           URL from each task's notes and commenting when that issue is closed.
                       (b) GitHub -> Asana: this repo's issues closed in the last -SinceDays days,
                           resolving each body's Asana task and commenting on it. Covers a ticket
                           that came the other way -- imported FROM Asana, whose task carries no
                           back-link for (a) to find.
                       Both skip a task that is already complete (a person resolved it -- leave it
                       alone) and a task that already carries this issue's close update.
                       (c) Asana -> GitHub, LABELS: this repo's OPEN issues, each given the one prio
                           label that matches its task's Prio-Score. Walks GitHub rather than the
                           project, so it reaches an imported ticket too and needs no
                           ASANA_PROJECT_GID at all.

    How the Asana task is found -- Resolve-AsanaTaskRef, three matchers tried in this order:

      1. marker      the machine marker '<!-- asana-task: <digits> -->' the report-issue skill
                     writes. Authoritative: an issue that carries one is never matched any other way.
      2. header-row  the header row of an imported ticket -- a markdown table row whose first cell
                     is '**Asana**' -- carrying an Asana task URL. This is the intake shape: a
                     ticket copied out of Asana links its task for a reader, not for a machine.
      3. sole-url    exactly one Asana task URL anywhere else in the body.

    More than one DIFFERENT task in matcher 3 is reported as 'ambiguous' and skipped: the script never
    guesses which ticket an issue belongs to. Add a marker to settle it.

    Auth: -AsanaPat (from the ASANA_PAT secret). Project: -ProjectGid (from the ASANA_PROJECT_GID
    variable), read by sweep (a) alone. Sweep (c) reads the score field by name (-PrioFieldName,
    default 'Prio-Score'). There is deliberately NO workspace parameter: every call this
    script makes addresses a task or a project by GID. BOTH modes need `gh` on PATH with
    GH_TOKEN set -- a close update asks GitHub which pull request closed the issue -- and sweep (b)
    additionally needs -Repo (GITHUB_REPOSITORY). Where `gh` cannot answer, the update still goes out
    and simply names no pull request.

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

    # The Asana number field the prio label is read from, by NAME: its GID differs per workspace, so
    # a name needs no repo variable of its own. A rename does not fail silently -- the label sweep
    # prints how many issues carried a score, and a sudden 0 there is the signal.
    [string]$PrioFieldName = 'Prio-Score'
)

$ErrorActionPreference = 'Stop'

$script:AsanaApiBase = 'https://app.asana.com/api/1.0'

# The four prio labels, low to high. EXACTLY ONE of these belongs on an issue at a time, which is
# what Set-IssuePrioLabel enforces by removing the other three. Named here rather than inline so the
# mapping helper and the enforcer cannot drift apart.
$script:PrioLabels = @('very low', 'low', 'high', 'very high')

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

        'closed'   the work is built and ready for the person who asked for it to test. -ClosedBy
                   carries the pull request(s) that closed the issue, so the update names WHERE the
                   change was made and links straight to it: that is the first thing a colleague
                   wants when they are about to test, and GitHub itself says it that way
                   ("closed this as completed in #434"). Empty means the issue was closed by hand,
                   and the update then says so rather than implying a PR that does not exist.
        'reopened' it is being worked on again; do not test yet.

        -StateReason 'not_planned' turns the close update into its opposite: nothing was built, so
        asking somebody to test it would be worse than saying nothing.

        No text here claims the ticket is done, and none asks anybody to hurry: this script has no
        say over when a ticket is resolved.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$IssueRef,
        [Parameter(Mandatory = $true)][ValidateSet('closed', 'reopened')][string]$Event,
        [pscustomobject[]]$ClosedBy = @(),
        [string]$StateReason = ''
    )

    $parts = $IssueRef -split '#'
    $url = "https://github.com/$($parts[0])/issues/$($parts[1])"

    if ($Event -eq 'reopened') {
        return @(
            "GitHub issue $IssueRef has been reopened: it is being worked on again, so hold off on testing.",
            $url
        ) -join "`n"
    }

    $marker = Get-MirrorCommentMarker -IssueRef $IssueRef

    if ($StateReason -eq 'not_planned') {
        return @(
            "$marker, as not planned: this is not going to be built.",
            $url,
            '',
            'There is nothing to test. The reason is on the issue; reply there or here if you disagree with it.'
        ) -join "`n"
    }

    $lines = @("$marker`: the work behind this ticket is built and ready to test.", $url, '')

    if ($ClosedBy.Count -gt 0) {
        $lines += if ($ClosedBy.Count -eq 1) { 'Closed by pull request:' } else { 'Closed by pull requests:' }
        foreach ($pr in $ClosedBy) {
            $lines += "  #$($pr.number) $($pr.title)"
            $lines += "  $($pr.url)"
        }
        $lines += ''
    } else {
        $lines += 'Closed by hand -- no pull request is linked to it.'
        $lines += ''
    }

    $lines += 'This ticket stays open on purpose. Tick it off yourself once you have checked that it does what you meant.'
    return ($lines -join "`n")
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
        [Parameter(Mandatory = $true)][string]$Pat,

        # The fields to ask Asana for. The default keeps every existing caller unchanged; the label
        # sweep asks for the custom fields on top of it.
        [string]$OptFields = 'completed,name'
    )
    if ($Gid -notmatch '^[0-9]+$') { throw "Refusing to read a non-numeric task GID: '$Gid'." }
    $uri = "$script:AsanaApiBase/tasks/$Gid" + "?opt_fields=$OptFields"
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

function Get-IssueClosure {
    <#
        How an issue was closed: its state reason, and the pull request(s) that closed it -- the same
        thing GitHub itself shows as "closed this as completed in #434".

        Asked through the GraphQL field built for exactly this question
        (closedByPullRequestsReferences) rather than reconstructed from the timeline, where a merge
        commit, a manual close and a cross-reference all look similar enough to get wrong.

        Never throws. An unreachable API, a missing `gh`, or an issue nobody linked a PR to all give
        an empty PullRequests list, and the update then says the issue was closed by hand instead of
        inventing a reference.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][int]$Number
    )

    $empty = [pscustomobject]@{ StateReason = ''; PullRequests = @() }
    $parts = $Repo -split '/'
    if ($parts.Count -ne 2) { return $empty }

    $query = 'query($owner:String!,$name:String!,$number:Int!){repository(owner:$owner,name:$name){issue(number:$number){stateReason closedByPullRequestsReferences(first:10,includeClosedPrs:true){nodes{number url title}}}}}'
    $ErrorActionPreference = 'Continue'
    $raw = (& gh api graphql -f query=$query -F "owner=$($parts[0])" -F "name=$($parts[1])" -F "number=$Number") 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $raw) {
        Write-Host "  Could not ask GitHub which pull request closed $Repo#$Number -- the update will not name one."
        return $empty
    }
    try {
        $issue = (($raw | Out-String) | ConvertFrom-Json).data.repository.issue
        if (-not $issue) { return $empty }
        return [pscustomobject]@{
            StateReason  = ([string]$issue.stateReason).ToLowerInvariant()
            PullRequests = @($issue.closedByPullRequestsReferences.nodes)
        }
    } catch {
        return $empty
    }
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
    $text = if ($Event -eq 'closed') {
        $closure = Get-IssueClosure -Repo ($IssueRef -split '#')[0] -Number ([int]($IssueRef -split '#')[1])
        New-MirrorComment -IssueRef $IssueRef -Event 'closed' -ClosedBy $closure.PullRequests -StateReason $closure.StateReason
    } else {
        New-MirrorComment -IssueRef $IssueRef -Event 'reopened'
    }
    Add-AsanaComment -Gid $ref.Gid -Text $text -Pat $AsanaPat
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

    $closure = Get-IssueClosure -Repo ($IssueRef -split '#')[0] -Number ([int]($IssueRef -split '#')[1])
    $text = New-MirrorComment -IssueRef $IssueRef -Event 'closed' -ClosedBy $closure.PullRequests -StateReason $closure.StateReason
    Add-AsanaComment -Gid $Gid -Text $text -Pat $AsanaPat
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

function Get-PrioLabelForScore {
    <#
        The GitHub label for one Asana Prio-Score, or $null when the score names none. Pure.

            1.00-1.99  very low     3.00-3.99  high
            2.00-2.99  low          4.00-5.00  very high

        Dave's mapping, September 2, 2026. There is deliberately no 'medium': four buckets, and each
        boundary is closed at the bottom and open at the top, so a precision-2 field can never land
        between two of them.

        $null for a task with no score AND for a score outside 1.00-5.00. Neither is guessed at and
        neither is an error: an unscored ticket simply carries no prio label, which is the common case
        rather than the exception -- measured on the BWJ board the day this was written, 28 of 96 open
        tasks had no score at all.
    #>
    param([AllowNull()]$Score)

    if ($null -eq $Score) { return $null }
    $s = [double]$Score
    if ($s -ge 1 -and $s -lt 2) { return 'very low'  }
    if ($s -ge 2 -and $s -lt 3) { return 'low'       }
    if ($s -ge 3 -and $s -lt 4) { return 'high'      }
    if ($s -ge 4 -and $s -le 5) { return 'very high' }
    return $null
}

function Get-PrioScoreFromTask {
    <#
        The named number field's value from a task object, or $null when the task carries no such
        field or the field is empty. Pure -- no network.

        Asana returns every custom field the task has, each with its own name, so the lookup is a
        match on name rather than a position.
    #>
    param(
        [AllowNull()]$Task,
        [Parameter(Mandatory = $true)][string]$FieldName
    )

    if (-not $Task -or -not $Task.custom_fields) { return $null }
    foreach ($f in $Task.custom_fields) {
        if ($f.name -eq $FieldName) { return $f.number_value }
    }
    return $null
}

function Get-OpenIssues {
    <#
        This repo's open issues with their bodies and their current labels. Returns an empty list
        (not a throw) when `gh` is unavailable or fails, so one broken listing cannot end the run.
    #>
    param([Parameter(Mandatory = $true)][string]$Repo)

    $ErrorActionPreference = 'Continue'
    $raw = (& gh issue list --repo $Repo --state open --limit 200 --json number,body,labels) 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $raw) {
        Write-Host "  Could not list the open issues of $Repo with gh -- the label sweep is skipped."
        return @()
    }
    return @(($raw | Out-String) | ConvertFrom-Json)
}

function Set-IssuePrioLabel {
    <#
        Put EXACTLY ONE prio label on an issue: add -Label if it is missing, and remove whichever of
        the other three the issue carries. That second half is the whole point -- a ticket rescored
        from 2.5 to 4.2 must lose 'low' as it gains 'very high', or the issue ends up claiming two
        priorities at once.

        Returns $true when it changed something, $false when the issue already read correctly or the
        edit failed. Nothing is done when there is nothing to do, so a re-run is quiet.

        `gh issue edit` fails outright on a label the repo does not have; adopt-bwj-asana creates all
        four, which is why that step and this function ship together.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][int]$Number,
        [Parameter(Mandatory = $true)][string]$Label,
        [string[]]$Current = @()
    )

    $stale = @($script:PrioLabels | Where-Object { $_ -ne $Label -and $Current -contains $_ })
    $needsAdd = ($Current -notcontains $Label)
    if (-not $needsAdd -and $stale.Count -eq 0) { return $false }

    $ghArgs = @('issue', 'edit', "$Number", '--repo', $Repo)
    if ($needsAdd) { $ghArgs += @('--add-label', $Label) }
    foreach ($s in $stale) { $ghArgs += @('--remove-label', $s) }

    $ErrorActionPreference = 'Continue'
    & gh @ghArgs 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Could not set '$Label' on $Repo#$Number -- does the repo have all four prio labels?"
        return $false
    }
    $removed = if ($stale.Count) { " (removed $($stale -join ', '))" } else { '' }
    Write-Host "  $Repo#$Number -> $Label$removed"
    return $true
}

function Invoke-LabelSweep {
    <#
        Sweep (c): this repo's OPEN issues, each carrying its Asana task's Prio-Score as one label.

        It walks GITHUB and not the Asana project, deliberately, and that is what separates it from
        sweep (a). Two reasons. It reaches a ticket imported FROM Asana, whose task carries no GitHub
        back-link for a project walk to follow -- the same gap the header-row matcher was added for.
        And it needs no ASANA_PROJECT_GID, so a repo whose project GID is wrong or provisional still
        gets its labels right.

        Priority flows Asana -> GitHub, which is the one direction this system's 'GitHub first' rule
        does not cover and does not contradict: the business sets what matters in the window it looks
        through, and the workbench is where that has to be visible. Nothing here writes to Asana.
    #>
    if (-not $Repo) {
        Write-Host 'GITHUB_REPOSITORY is not set -- the label sweep is skipped.'
        return 0
    }
    $issues = Get-OpenIssues -Repo $Repo
    $scored = 0
    $done   = 0
    foreach ($i in $issues) {
        $ref = Resolve-AsanaTaskRef -IssueBody ([string]$i.body)
        if (-not $ref.Gid) { continue }
        $task = Get-AsanaTaskState -Gid $ref.Gid -Pat $AsanaPat `
                    -OptFields 'completed,name,custom_fields.name,custom_fields.number_value'
        if (-not $task) { continue }
        $label = Get-PrioLabelForScore -Score (Get-PrioScoreFromTask -Task $task -FieldName $PrioFieldName)
        if (-not $label) { continue }
        $scored++
        $current = @($i.labels | ForEach-Object { $_.name })
        if (Set-IssuePrioLabel -Repo $Repo -Number ([int]$i.number) -Label $label -Current $current) { $done++ }
    }
    Write-Host "Label sweep: $($issues.Count) open issue(s) examined, $scored carrying a '$PrioFieldName', $done relabelled."
    return $done
}

function Invoke-ReconcileMode {
    if (-not $AsanaPat) { throw 'ASANA_PAT is not set.' }
    $done = 0
    $done += Invoke-ReconcileFromAsana
    $done += Invoke-ReconcileFromGitHub
    Write-Host "Reconciliation done -- $done task(s) updated, 0 completed (this script completes nothing)."

    # Sweep (c) reports separately: it relabels ISSUES, where the two above update TASKS, and one
    # count covering both would say neither.
    $labelled = Invoke-LabelSweep
    Write-Host "Prio labels done -- $labelled issue(s) relabelled."
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
