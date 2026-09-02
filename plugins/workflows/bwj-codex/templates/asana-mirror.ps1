<#
.SYNOPSIS
    Keep a BWJ store repo and its Asana board in step -- the CI half of the bwj-codex rule. It posts
    an update on the Asana task mirrored from a GitHub issue, moves that task to the board section
    its GitHub state has reached, and carries the task's prio score back the other way as a label on
    the issue. Copied into a BWJ store repo as .github/scripts/asana-mirror.ps1 and driven by
    .github/workflows/asana-mirror.yml.

.DESCRIPTION
    IT NEVER COMPLETES A TASK, AND THERE IS NO CODE PATH THAT CAN (Dave, September 1, 2026). Closing
    a GitHub issue says the work is built; it does not say the colleague who asked for it has seen it
    work. Only that person resolves their own ticket, after testing. So this script writes two kinds
    of thing into Asana -- a comment, and which section a task sits in -- and the 'completed' field is
    not written anywhere in it.

    THE SECTION MOVE IS THAT SAME GUARANTEE IN THE BOARD'S OWN CURRENCY, so it carries its own
    ceiling: the two ends of the board are never written. 'Requests' is the submitter's untriaged
    inbox and 'Completed' is their verdict that the work is good -- Test-StageIsWritable is the pure
    guard that says so, and a card already sitting in Completed is not moved at all.

    WHICH NUMBERED SECTION EACH STAGE IS comes from the repo, not from this file: Get-AsanaStageMap in
    scripts/repo-config.ps1, with Get-DefaultAsanaStageMap as the fallback. That seam exists because
    the meanings were literals here for exactly one afternoon (September 2, 2026) and the board they
    were written against grew a section the same day, shifting every stage above it by one. Nothing
    failed loudly; every card would have been filed a column early. A section the map does not name is
    now a hold -- not a target, and not a source.

    MOVES ARE FORWARD, so a card a session advanced by hand is never dragged back by a sweep that can
    see less than the session could. Exactly two answers may go backward, and both are a person
    saying something rather than CI inferring it: the needs-info label, which declares the work
    blocked on the submitter and outranks whatever the branch and the pull request are doing, and the
    reopen event, which is a real state change.

    The one thing it writes OUTSIDE Asana is a prio label on a GitHub issue -- sweep (c) below. That
    is a different system and a different claim, and it leaves the guarantee above exactly where it
    was: nothing about a label says anybody has tested anything.

    Two modes:

      -Mode event      One issue changed. -Event is 'closed', 'reopened', 'labeled' or 'unlabeled';
                       -IssueBody is the issue body (the Asana task is resolved from it, see below);
                       -IssueRef is 'owner/repo#n'.

                       'closed' and 'reopened' COMMENT and move the card. The comment on 'closed'
                       names the pull request(s) that closed the issue and says the work is ready to
                       test; 'reopened' says to hold off. Neither de-duplicates -- an event is a real
                       state change, and a second close after a reopen is news again.

                       'labeled' and 'unlabeled' ONLY move the card, deliberately: a label going on
                       or off is a change in our state, and narrating it would put a comment on the
                       submitter's ticket every time somebody triaged the issue.

      -Mode reconcile  Four sweeps, for events that never arrived, and the only place de-duplication
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
                       (d) GitHub -> Asana, SECTIONS: this repo's issues, open and recently closed,
                           each card moved to the stage its issue's state has reached. This one is
                           not a backstop like (a) and (b): stages 2, 3 and 4 have no GitHub event
                           this workflow subscribes to, so for three of the four writable stages the
                           daily sweep IS the mechanism. It needs no ASANA_PROJECT_GID either -- the
                           board is read off the task's own memberships, see below.

    How the Asana task is found -- Resolve-AsanaTaskRef, three matchers tried in this order:

      1. marker      the machine marker '<!-- asana-task: <digits> -->' the report-issue skill
                     writes. Authoritative: an issue that carries one is never matched any other way.
      2. header-row  the header row of an imported ticket -- a markdown table row whose first cell
                     is '**Asana**' -- carrying an Asana task URL. This is the intake shape: a
                     ticket copied out of Asana links its task for a reader, not for a machine.
      3. sole-url    exactly one Asana task URL anywhere else in the body.

    More than one DIFFERENT task in matcher 3 is reported as 'ambiguous' and skipped: the script never
    guesses which ticket an issue belongs to. Add a marker to settle it.

    How the BOARD is found -- Select-StageMembership, and it is deliberately not a configured GID.
    A task carries one section per project it is in, so the script reads the task's memberships and
    takes the one whose section name begins with a stage number ('3. ...'). The number is the
    machine-readable half and the words after it are the board's own, so renaming a section changes
    nothing here. A task on no numbered section is on no pipeline, and nothing is written to it --
    which is how a board that has not adopted the convention is left alone rather than guessed at.
    Two different numbered boards is 'ambiguous' and skipped, the same refusal to guess as above.

    Auth: -AsanaPat (from the ASANA_PAT secret). Project: -ProjectGid (from the ASANA_PROJECT_GID
    variable), read by sweep (a) alone. Sweep (c) reads the score field by name (-PrioFieldName,
    default 'Prio-Score'). There is deliberately NO workspace parameter: every call this
    script makes addresses a task, a project or a section by GID. BOTH modes need `gh` on PATH with
    GH_TOKEN set -- a close update asks GitHub which pull request closed the issue -- and sweeps (b),
    (c) and (d) additionally need -Repo (GITHUB_REPOSITORY). Where `gh` cannot answer, the update
    still goes out and simply names no pull request, and sweep (d) derives no stage rather than
    guessing one.

    The comment text is English, like everything else this repo ships. It is the workflow speaking,
    not the subject -- the same boundary a BWJ store repo already draws when it keeps its ticket
    headings English while the analysis under them follows whoever filed the ticket.

    The pure helpers (Resolve-AsanaTaskRef, Get-AsanaTaskGid, Get-AsanaGidsFromText,
    New-MirrorComment, Get-MirrorCommentMarker, New-AsanaCommentRequest, Get-IssueRefFromNotes,
    Get-StageFromSectionName, Select-StageMembership, Get-DefaultAsanaStageMap, Get-StageMapNumbers,
    Get-WritableStages, Test-StageIsWritable, Test-AsanaStageMap, Get-StageFloorForIssue,
    Resolve-TargetStage, New-AsanaSectionMoveRequest) take no network and are what the source repo's
    scripts/tests/bwj-codex.tests.ps1 exercises -- including against a board numbered some other way,
    so the map cannot quietly become decoration over literals. The script runs its main flow only when
    invoked directly; dot-sourcing it loads the helpers and does nothing else.

    Pure ASCII (repo convention for .ps1).
#>
[CmdletBinding()]
param(
    [ValidateSet('event', 'reconcile')]
    [string]$Mode = 'event',

    # 'closed' and 'reopened' comment AND move the card; 'labeled'/'unlabeled' only move it.
    [ValidateSet('closed', 'reopened', 'labeled', 'unlabeled')]
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
    [string]$PrioFieldName = 'Prio-Score',

    # Where to look for scripts/repo-config.ps1, whose Get-AsanaStageMap states which numbered
    # section each stage of the cycle is. Defaults to the checkout the workflow runs in.
    [string]$RepoRoot = '.'
)

$ErrorActionPreference = 'Stop'

$script:AsanaApiBase = 'https://app.asana.com/api/1.0'

# The four prio labels, low to high. EXACTLY ONE of these belongs on an issue at a time, which is
# what Set-IssuePrioLabel enforces by removing the other three. Named here rather than inline so the
# mapping helper and the enforcer cannot drift apart.
$script:PrioLabels = @('very low', 'low', 'high', 'very high')

# The stage map, resolved once per run from the repo's own seam -- see Resolve-AsanaStageMap.
$script:StageMap = $null

# Stage -> section-GID map per project, filled on first use. A sweep over fifty issues on one board
# asks Asana for that board's sections once.
$script:StageSectionCache = @{}

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

function Get-StageFromSectionName {
    <#
        The stage number a section's name declares, or $null when it declares none. Pure.

        A pipeline section is named '<N>. <whatever the board likes>'. The NUMBER is the
        machine-readable half and the words after it belong to the board, which is the same split the
        cross-link already uses: a marker for the machine, prose for the reader. So renaming
        '3. In development' to '3. Building it' changes nothing here, and no repo has to keep six
        section GIDs correct in its config.

        It is also the whole containment. A section with no leading number yields $null, and a task
        whose sections all yield $null is on no pipeline and is never written to -- so pointing this
        script at a workspace full of other boards costs nothing.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Name)

    $m = [regex]::Match($Name, '^\s*([0-9]+)\s*\.')
    if (-not $m.Success) { return $null }
    return [int]$m.Groups[1].Value
}

function Get-DefaultAsanaStageMap {
    <#
        Which numbered section each stage of the cycle IS, when a repo states nothing. Pure.

        The number convention says how a section is recognised; this says what each one MEANS, and the
        two are separate questions. They were one question until September 2, 2026, with the meanings
        written as literals in the derivation -- and the board they were written against grew a
        section the same afternoon, which shifted every stage from 'Filed' upward by one. Nothing
        failed loudly: the sweep would simply have filed every card one column early.

        So the meaning lives in the repo's own scripts/repo-config.ps1, as Get-AsanaStageMap, and this
        is the fallback. Semantic keys and not GIDs, deliberately: a rebuilt column keeps its number
        and loses its GID, which is the failure mode a GID map is born with.
    #>
    return @{
        Requests       = 1   # the requester's inbox -- never a target, though cards do leave it
        NeedsInfo      = 2   # blocked on the submitter -- set by a label, see Resolve-TargetStage
        Filed          = 3   # the GitHub issue exists; nothing is being built yet
        InDevelopment  = 4   # a branch is open -- the session's own hop, never derived by CI
        InReview       = 5   # a pull request is open OR merged, and the issue is not closed yet
        ReadyToTest    = 6   # the issue is closed as completed -- the submitter's turn
        Completed      = 7   # the submitter says it is good -- never a target, never moved OUT of
        NeedsInfoLabel = 'needs-info'
    }
}

function Get-StageMapNumbers {
    <# The seven stage numbers a map names, in cycle order. Pure. #>
    param([Parameter(Mandatory = $true)]$Map)
    return @($Map.Requests, $Map.NeedsInfo, $Map.Filed, $Map.InDevelopment,
             $Map.InReview, $Map.ReadyToTest, $Map.Completed) | ForEach-Object { [int]$_ }
}

function Get-WritableStages {
    <#
        The stages this script may put a card in: the five pipeline stages. Pure.

        Requests and Completed are excluded, and they are excluded for two different reasons worth
        keeping apart. Requests is never a TARGET -- a card leaves it the moment the issue is filed,
        which is the whole of inbound #1217 -- while Completed is never a target AND never moved out
        of, because a card is only there because a person put it there.
    #>
    param([Parameter(Mandatory = $true)]$Map)
    return @($Map.NeedsInfo, $Map.Filed, $Map.InDevelopment, $Map.InReview, $Map.ReadyToTest) |
        ForEach-Object { [int]$_ }
}

function Test-StageIsWritable {
    <#
        Is this a stage this script may put a card in? Pure, and the code-level twin of the rule that
        the board's two ends belong to the requester.

        It is belt and braces on purpose. Resolve-TargetStage cannot return Requests or Completed
        either, so this guard should never fire -- exactly the property the 'no code path can complete
        a task' guarantee has, and the reason both are asserted rather than assumed.
    #>
    param(
        [AllowNull()]$Stage,
        [Parameter(Mandatory = $true)]$Map
    )

    if ($null -eq $Stage) { return $false }
    return ((Get-WritableStages -Map $Map) -contains [int]$Stage)
}

function Test-AsanaStageMap {
    <#
        Is this a usable stage map? Returns the list of complaints, empty when it is. Pure.

        Three ways a hand-written map goes wrong, and all three are silent at runtime rather than
        loud: a missing key reads as stage 0, a non-numeric one as stage 0 too, and a duplicate makes
        two stages the same column so a card can never leave one of them.
    #>
    param([AllowNull()]$Map)

    $keys = @('Requests', 'NeedsInfo', 'Filed', 'InDevelopment', 'InReview', 'ReadyToTest', 'Completed')
    if (-not $Map) { return @('the map is empty') }

    $bad = @()
    foreach ($k in $keys) {
        $v = $Map[$k]
        if ($null -eq $v)                       { $bad += "$k names no section"; continue }
        if ("$v" -notmatch '^[0-9]+$')          { $bad += "$k is '$v', which is not a section number" }
        elseif ([int]$v -lt 1)                  { $bad += "$k is $v, and a section number starts at 1" }
    }
    if ($bad.Count -gt 0) { return $bad }

    $nums = Get-StageMapNumbers -Map $Map
    $dupes = @($nums | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    foreach ($d in $dupes) { $bad += "section $d is named by more than one stage" }
    return $bad
}

function Resolve-AsanaStageMap {
    <#
        The repo's own stage map, or the built-in one. Reads scripts/repo-config.ps1 -- the same file
        contributing-davekjohn already dot-sources and report-issue already reads session-side -- and
        calls Get-AsanaStageMap if it defines one.

        It never throws and it always returns a usable map. A repo with no seam, a seam that fails to
        load, or a map that does not validate all fall back to the default WITH A LINE SAYING SO,
        because a silently wrong map is the exact failure this seam exists to end: every card one
        column early, and nothing in the log to say why.
    #>
    param([string]$RepoRoot = '.')

    $default = Get-DefaultAsanaStageMap
    $cfg = Join-Path $RepoRoot 'scripts/repo-config.ps1'
    if (-not (Test-Path -LiteralPath $cfg)) {
        Write-Host "  No scripts/repo-config.ps1 -- using the built-in stage map."
        return $default
    }

    try { . $cfg } catch {
        Write-Host "  scripts/repo-config.ps1 could not be loaded ($($_.Exception.Message)) -- using the built-in stage map."
        return $default
    }
    if (-not (Get-Command -Name 'Get-AsanaStageMap' -ErrorAction SilentlyContinue)) {
        Write-Host "  scripts/repo-config.ps1 defines no Get-AsanaStageMap -- using the built-in stage map."
        return $default
    }

    $own = $null
    try { $own = Get-AsanaStageMap } catch {
        Write-Host "  Get-AsanaStageMap threw ($($_.Exception.Message)) -- using the built-in stage map."
        return $default
    }

    $complaints = Test-AsanaStageMap -Map $own
    if ($complaints.Count -gt 0) {
        Write-Host "  Get-AsanaStageMap is not usable -- using the built-in stage map instead. $($complaints -join '; ')."
        return $default
    }

    # The label is the one optional key: a map that names none keeps the default, and a map that sets
    # it to '' switches the needs-info column off altogether, which is a real answer.
    if (-not $own.ContainsKey('NeedsInfoLabel')) { $own['NeedsInfoLabel'] = $default.NeedsInfoLabel }
    Write-Host "  Stage map from scripts/repo-config.ps1: $((Get-StageMapNumbers -Map $own) -join '/'), needs-info label '$($own.NeedsInfoLabel)'."
    return $own
}

function Select-StageMembership {
    <#
        Which pipeline board this task is on, read off the task's own memberships. Returns an object
        shaped like Resolve-AsanaTaskRef's, for the same reason -- the caller logs the Source:

            Source      'stage-section' | 'none' | 'ambiguous'
            Membership  ProjectGid / SectionGid / Stage, or $null
            Candidates  the distinct project GIDs seen, for the 'ambiguous' report

        Pure -- no network. Asana gives a task one section per project, so a single numbered project
        resolves to a single section. Two DIFFERENT numbered projects is two answers and this script
        takes neither: a card on two pipelines is a board question, not a script question.
    #>
    param($Memberships)

    $found = @()
    foreach ($m in @($Memberships)) {
        if (-not $m -or -not $m.section) { continue }
        $stage = Get-StageFromSectionName -Name ([string]$m.section.name)
        if ($null -eq $stage) { continue }
        $found += [pscustomobject]@{
            ProjectGid = [string]$m.project.gid
            SectionGid = [string]$m.section.gid
            Stage      = $stage
        }
    }

    $projects = @($found | ForEach-Object { $_.ProjectGid } | Sort-Object -Unique)
    if ($projects.Count -eq 0) { return [pscustomobject]@{ Source = 'none';      Membership = $null;     Candidates = @() } }
    if ($projects.Count -gt 1) { return [pscustomobject]@{ Source = 'ambiguous'; Membership = $null;     Candidates = $projects } }
    return                             [pscustomobject]@{ Source = 'stage-section'; Membership = $found[0]; Candidates = $projects }
}

function Get-StageFloorForIssue {
    <#
        The stage an issue's own GitHub state puts a floor under, or $null when it puts none. Pure.

            open,   no pull request linked      Filed        the issue exists; nothing is being built
            open,   a pull request open         InReview     it is under review
            open,   a pull request merged       InReview     merged, and the issue is not closed yet
            closed as completed                 ReadyToTest  the submitter's turn
            closed as not planned               $null        nothing was built, so nothing to stage

        A FLOOR, not a position, and that is what makes the daily sweep safe to run. CI cannot see a
        branch that has no pull request behind it, so a card a session moved to InDevelopment at
        `new-branch` must not be dragged back to Filed by a sweep that knows less than the session
        did. Sync-AsanaTaskStage therefore moves forward only.

        WHICH MEANS THIS NEVER DERIVES InDevelopment, and that is deliberate rather than a gap: that
        stage is the one hop only a session can see, and forward-only is what protects it. A card
        there with no pull request yet floors at Filed, which is backward, so nothing moves.

        A MERGED pull request floors at InReview and not beyond (Dave, September 2, 2026). His board
        has no column for 'merged but the issue is still open', and the gate he set holds either way:
        a card only reaches the submitter once the issue is actually closed.

        Never Requests and never Completed, whatever it is handed -- see Test-StageIsWritable.
    #>
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$State,
        [AllowEmptyString()][string]$StateReason = '',
        $PullRequests = @(),
        [Parameter(Mandatory = $true)]$Map
    )

    if ($State -and $State.ToUpperInvariant() -eq 'CLOSED') {
        if ($StateReason -and $StateReason.ToLowerInvariant() -eq 'not_planned') { return $null }
        return [int]$Map.ReadyToTest
    }

    $prs = @($PullRequests)
    if ($prs | Where-Object { $_.merged -eq $true -or ([string]$_.state).ToUpperInvariant() -in @('OPEN', 'MERGED') }) {
        return [int]$Map.InReview
    }
    return [int]$Map.Filed
}

function Resolve-TargetStage {
    <#
        Where this card belongs, and whether the answer may move it BACKWARD. Pure.

            Stage          the target, or $null when nothing derives one
            AllowBackward  $true only for the two answers that are a person's statement
            Why            one phrase for the log, so a move is always attributable

        TWO ANSWERS MAY GO BACKWARD, and both are somebody saying something rather than CI inferring
        it. The needs-info label is a person declaring the work cannot proceed; the reopen is a real
        state change. Everything else is a floor, and floors only rise.

        THE LABEL OUTRANKS THE ISSUE'S STATE, which is the point of it (Dave, September 2, 2026). A
        card blocked on the submitter stays blocked whatever the branch and the pull request are
        doing, because the person who set the label knows something the tracker does not. Removing
        the label hands the card straight back to its state-derived floor -- which is forward, so it
        needs no permission.

        A map whose NeedsInfoLabel is empty switches the column off: the label is then never looked
        for, and that is a real answer for a board without one.
    #>
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$State,
        [AllowEmptyString()][string]$StateReason = '',
        $PullRequests = @(),
        [string[]]$Labels = @(),
        [Parameter(Mandatory = $true)]$Map,
        [switch]$Reopened
    )

    $label = [string]$Map.NeedsInfoLabel
    if ($label -and (@($Labels) -contains $label)) {
        return [pscustomobject]@{
            Stage         = [int]$Map.NeedsInfo
            AllowBackward = $true
            Why           = "the '$label' label"
        }
    }

    $floor = Get-StageFloorForIssue -State $State -StateReason $StateReason -PullRequests $PullRequests -Map $Map
    $why   = if ($Reopened) { 'the reopen' } else { 'the issue state' }
    return [pscustomobject]@{
        Stage         = $floor
        AllowBackward = [bool]$Reopened
        Why           = $why
    }
}

function New-AsanaSectionMoveRequest {
    <#
        Pure: describe the POST that puts a task in a section. No network.

        Separated from the call for the same reason New-AsanaCommentRequest is -- the URL and the body
        are assertable without a network -- and it refuses a non-numeric GID on either side, so no
        text read out of an issue body or a section name can reach a request URL.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Gid,
        [Parameter(Mandatory = $true)][string]$SectionGid
    )
    if ($Gid -notmatch '^[0-9]+$')        { throw "Refusing to move a non-numeric task GID: '$Gid'." }
    if ($SectionGid -notmatch '^[0-9]+$') { throw "Refusing to move a task into a non-numeric section GID: '$SectionGid'." }
    [pscustomobject]@{
        Method = 'POST'
        Uri    = "$script:AsanaApiBase/sections/$SectionGid/addTask"
        Body   = (ConvertTo-Json @{ data = @{ task = $Gid } } -Compress -Depth 5)
    }
}

function New-AsanaCommentRequest {
    <#
        Pure: describe the POST that adds a comment to a task. No network. One of the two writes this
        script knows how to build -- the other is New-AsanaSectionMoveRequest.
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

function Get-ProjectStageSections {
    <#
        One project's stage -> section-GID map, built from its section NAMES. Cached for the run.

        A project with no numbered section gives an empty map, and that is the answer for a board
        which has not adopted the convention -- nothing is created and nothing is guessed. Where two
        sections claim the same number the first one the board lists wins, which is a board defect
        this script reports rather than resolves.

        An unreadable project gives an empty map too, reported and not thrown: one board this PAT
        cannot see must not end a sweep over all the others.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectGid,
        [Parameter(Mandatory = $true)][string]$Pat
    )
    if ($ProjectGid -notmatch '^[0-9]+$') { throw "Refusing to read a non-numeric project GID: '$ProjectGid'." }
    if ($script:StageSectionCache.ContainsKey($ProjectGid)) { return $script:StageSectionCache[$ProjectGid] }

    $map = @{}
    $uri = "$script:AsanaApiBase/projects/$ProjectGid/sections?opt_fields=name&limit=100"
    try {
        while ($uri) {
            $resp = Invoke-RestMethod -Method GET -Uri $uri -Headers @{ Authorization = "Bearer $Pat" }
            foreach ($s in @($resp.data)) {
                $stage = Get-StageFromSectionName -Name ([string]$s.name)
                if ($null -eq $stage) { continue }
                if ($map.ContainsKey($stage)) {
                    Write-Host "  Asana project $ProjectGid has more than one section numbered $stage -- using the first one it lists."
                    continue
                }
                $map[$stage] = [string]$s.gid
            }
            $uri = if ($resp.next_page -and $resp.next_page.uri) { $resp.next_page.uri } else { $null }
        }
    } catch {
        Write-Host "  Sections of Asana project $ProjectGid are not readable ($($_.Exception.Message)) -- no card is moved on that board."
    }
    $script:StageSectionCache[$ProjectGid] = $map
    return $map
}

function Sync-AsanaTaskStage {
    <#
        Put one card in the section its issue's state has reached. Returns $true when it moved.

        The guards, in the order they are checked. Every one of them is a case where the board is
        right and this script is not, which is why each returns quietly instead of failing:

            no target stage        nothing derived an opinion -- an issue closed as not planned
            not a writable stage   Requests and Completed are the submitter's (Test-StageIsWritable)
            task unreadable        deleted, or in a workspace this PAT is not a member of
            task completed         a person resolved it; leave it exactly where they left it
            on no numbered board   it is on no pipeline at all
            on two numbered boards two answers, so neither is taken
            in an UNMAPPED column  the board grew a section this repo's map does not name
            already in Completed   a person put it there, and nothing here takes it back out
            already at or past     forward-only, unless the answer earned -AllowBackward
            board has no such      a board missing that section is not given one

        THE UNMAPPED-COLUMN GUARD IS THE ONE WITH SCAR TISSUE ON IT. Without it a card in a section
        the map does not name is read as a stage number like any other, so a board that grew a column
        gets its cards yanked into whatever the old numbering meant. That is not hypothetical: the
        board this was first written against gained a section within the afternoon (September 2,
        2026), and every stage above it shifted by one. An unnamed column is now a hold -- not a
        target and not a source.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Gid,
        [AllowNull()]$TargetStage,
        [Parameter(Mandatory = $true)][string]$Pat,
        [Parameter(Mandatory = $true)]$Map,

        # A label for the log line, normally 'owner/repo#n'.
        [string]$For = '',

        # Why the target was chosen, for the log -- Resolve-TargetStage's own phrase.
        [string]$Why = '',

        # Only the needs-info label and the reopen earn this; see Resolve-TargetStage.
        [switch]$AllowBackward
    )

    if ($null -eq $TargetStage) { return $false }
    $stage = [int]$TargetStage
    if (-not (Test-StageIsWritable -Stage $stage -Map $Map)) {
        Write-Host "  Refusing to move Asana task $Gid to stage $stage -- only $((Get-WritableStages -Map $Map) -join ', ') are this workflow's to write."
        return $false
    }

    $task = Get-AsanaTaskState -Gid $Gid -Pat $Pat `
                -OptFields 'completed,name,memberships.project.gid,memberships.section.gid,memberships.section.name'
    if ($null -eq $task) { return $false }
    if ($task.completed) { return $false }

    $ref = Select-StageMembership -Memberships $task.memberships
    if ($ref.Source -eq 'none') { return $false }
    if ($ref.Source -eq 'ambiguous') {
        Write-Host "  Asana task $Gid sits on two numbered boards ($($ref.Candidates -join ', ')) -- refusing to guess which pipeline it belongs to."
        return $false
    }

    $current = $ref.Membership.Stage
    $known = Get-StageMapNumbers -Map $Map
    if ($known -notcontains $current) {
        Write-Host "  Asana task $Gid sits in section $current, which this repo's stage map does not name -- left alone."
        return $false
    }
    if ($current -eq [int]$Map.Completed) { return $false }
    if ($current -eq $stage) { return $false }
    if ($current -gt $stage -and -not $AllowBackward) { return $false }

    $sections = Get-ProjectStageSections -ProjectGid $ref.Membership.ProjectGid -Pat $Pat
    if (-not $sections.ContainsKey($stage)) {
        Write-Host "  Asana project $($ref.Membership.ProjectGid) has no section numbered $stage -- $($task.name) stays in $current."
        return $false
    }

    Invoke-AsanaRequest -Request (New-AsanaSectionMoveRequest -Gid $Gid -SectionGid $sections[$stage]) -Pat $Pat | Out-Null
    $what = if ($For) { "$For -> " } else { '' }
    $back = if ($current -gt $stage) { ' (back)' } else { '' }
    $why  = if ($Why) { " -- $Why" } else { '' }
    Write-Host "  $what$($task.name): stage $current -> $stage$back$why"
    return $true
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

function Get-IssueLinkState {
    <#
        Where an issue stands and which pull requests are linked to it: its state, its state reason,
        and the pull request(s) that close or would close it -- the same thing GitHub itself shows as
        "closed this as completed in #434".

        Asked through the GraphQL field built for exactly this question
        (closedByPullRequestsReferences) rather than reconstructed from the timeline, where a merge
        commit, a manual close and a passing cross-reference all look similar enough to get wrong.
        That field answers for an OPEN issue too, which is what lets one query serve both callers:
        the close update, which wants the pull request's number and title, and the stage sweep, which
        wants to know whether that pull request is open or merged.

        A cross-reference is deliberately NOT read. A pull request that merely mentions an issue says
        nothing about whether anybody is building it, and stage 3 is a claim about work in progress.

        Never throws. An unreachable API, a missing `gh`, or an issue nobody linked a pull request to
        all give an empty PullRequests list -- the update then says the issue was closed by hand
        instead of inventing a reference, and the stage sweep reads the issue as unstarted rather than
        moving a card on a guess.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][int]$Number
    )

    $empty = [pscustomobject]@{ State = ''; StateReason = ''; PullRequests = @(); Labels = @() }
    $parts = $Repo -split '/'
    if ($parts.Count -ne 2) { return $empty }

    $query = 'query($owner:String!,$name:String!,$number:Int!){repository(owner:$owner,name:$name){issue(number:$number){state stateReason labels(first:50){nodes{name}} closedByPullRequestsReferences(first:10,includeClosedPrs:true){nodes{number url title state merged}}}}}'
    $ErrorActionPreference = 'Continue'
    $raw = (& gh api graphql -f query=$query -F "owner=$($parts[0])" -F "name=$($parts[1])" -F "number=$Number") 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $raw) {
        Write-Host "  Could not ask GitHub about $Repo#$Number -- no pull request is named and no card is moved."
        return $empty
    }
    try {
        $issue = (($raw | Out-String) | ConvertFrom-Json).data.repository.issue
        if (-not $issue) { return $empty }
        return [pscustomobject]@{
            State        = ([string]$issue.state).ToUpperInvariant()
            StateReason  = ([string]$issue.stateReason).ToLowerInvariant()
            PullRequests = @($issue.closedByPullRequestsReferences.nodes)
            Labels       = @($issue.labels.nodes | ForEach-Object { [string]$_.name })
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
    $link = Get-IssueLinkState -Repo ($IssueRef -split '#')[0] -Number ([int]($IssueRef -split '#')[1])

    # A LABEL EVENT MOVES THE CARD AND SAYS NOTHING. 'closed' and 'reopened' are news for the person
    # waiting on the ticket; a label going on or off is a change in OUR state, and narrating it would
    # put a comment on the submitter's ticket every time somebody triaged it.
    if ($Event -in @('closed', 'reopened')) {
        # No de-duplication here on purpose: an event is a real state change, so a close after a
        # reopen is news again and gets said again.
        $text = if ($Event -eq 'closed') {
            New-MirrorComment -IssueRef $IssueRef -Event 'closed' -ClosedBy $link.PullRequests -StateReason $link.StateReason
        } else {
            New-MirrorComment -IssueRef $IssueRef -Event 'reopened'
        }
        Add-AsanaComment -Gid $ref.Gid -Text $text -Pat $AsanaPat
        Write-Host "Asana task $($ref.Gid) updated: $IssueRef $Event (matched by $($ref.Source)). The task was NOT completed -- that is the requester's call."
    }

    # And the card follows. The state comes from the query above rather than from -Event, so a close
    # the API has already superseded cannot move a card on a stale reading.
    $target = Resolve-TargetStage -State $link.State -StateReason $link.StateReason `
                  -PullRequests $link.PullRequests -Labels $link.Labels -Map $script:StageMap `
                  -Reopened:($Event -eq 'reopened')
    Sync-AsanaTaskStage -Gid $ref.Gid -TargetStage $target.Stage -Pat $AsanaPat -Map $script:StageMap `
        -For $IssueRef -Why $target.Why -AllowBackward:$target.AllowBackward | Out-Null
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

        A field is defined in ONE workspace and does not cross into another, which is what makes the
        name -- not a GID -- the only portable handle. The consequence is on the caller, not here: a
        task living in a project of some other workspace carries no field by this name at all, so a
        ticket this workflow filed itself scores only when ASANA_PROJECT_GID names a project in the
        board's own workspace. Issue #1213.
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

function Invoke-StageSweep {
    <#
        Sweep (d): this repo's issues -- open, and closed within the -SinceDays window -- each card
        moved to the stage its issue's state has reached.

        THIS ONE IS NOT A BACKSTOP, and that is what separates it from (a) and (b). Stages 2, 3 and 4
        have no GitHub event this workflow subscribes to: an issue is filed, a branch opens and a pull
        request merges without `issues: closed` ever firing. So for three of the four writable stages
        the daily run is the mechanism rather than the safety net, and only stage 5 has an event of
        its own.

        It walks GitHub rather than the Asana project, for the same two reasons sweep (c) does: it
        reaches a ticket imported FROM the board, whose task carries no GitHub back-link, and it needs
        no ASANA_PROJECT_GID -- the board comes off the task's own memberships.

        Two reads per issue that carries a task: one GraphQL for the issue's state and linked pull
        requests, one Asana GET for the card's current section. An issue with no task costs neither,
        because Resolve-AsanaTaskRef is pure and runs first.
    #>
    if (-not $Repo) {
        Write-Host 'GITHUB_REPOSITORY is not set -- the stage sweep is skipped.'
        return 0
    }

    $issues = @(Get-OpenIssues -Repo $Repo) + @(Get-ClosedIssues -Repo $Repo -SinceDays $SinceDays)
    $moved  = 0
    $carded = 0
    foreach ($i in $issues) {
        $ref = Resolve-AsanaTaskRef -IssueBody ([string]$i.body)
        if (-not $ref.Gid) { continue }
        $carded++
        $link = Get-IssueLinkState -Repo $Repo -Number ([int]$i.number)
        if (-not $link.State) { continue }
        $target = Resolve-TargetStage -State $link.State -StateReason $link.StateReason `
                      -PullRequests $link.PullRequests -Labels $link.Labels -Map $script:StageMap
        if (Sync-AsanaTaskStage -Gid $ref.Gid -TargetStage $target.Stage -Pat $AsanaPat `
                -Map $script:StageMap -For "$Repo#$($i.number)" -Why $target.Why `
                -AllowBackward:$target.AllowBackward) { $moved++ }
    }
    Write-Host "Stage sweep: $($issues.Count) issue(s) examined, $carded carrying an Asana task, $moved card(s) moved."
    return $moved
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

    # And (d) again separately: it moves CARDS. Three counts, three claims -- a single total would
    # let a quiet day and a broken sweep read the same.
    $staged = Invoke-StageSweep
    Write-Host "Stage sections done -- $staged card(s) moved, still 0 completed."
}

function Invoke-Main {
    # Resolved once, before either mode, so the run says which map it used exactly once and every
    # move afterwards is against the same answer.
    $script:StageMap = Resolve-AsanaStageMap -RepoRoot $RepoRoot
    switch ($Mode) {
        'event'     { Invoke-EventMode }
        'reconcile' { Invoke-ReconcileMode }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Main
}
