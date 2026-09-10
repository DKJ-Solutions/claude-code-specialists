<#
.SYNOPSIS
    One command for the clutter this workflow leaves on a machine: finished branches, stale lanes,
    abandoned work, expired backups, orphaned plugin records and leftover fixture trees. It DELETES
    only what prune-merged.ps1 can already prove; everything else it classifies and hands over.

.DESCRIPTION
    WHY THIS EXISTS, MEASURED IN THE SOURCE REPO ON SEPTEMBER 10, 2026. Running prune-merged.ps1
    -DryRun -IncludeRemote there found 32 local branches beside the trunk: 27 provably merged, and 5
    kept. Not one of the five was live work. They were a 7-day-old pre-sync backup, three branches
    whose pull requests had been CLOSED unmerged (#1299, #1243, #1260), and one whose PR had merged
    with the local tip a commit past it (#1599). One of the three also held an entire second checkout
    of the repository -- a lane worktree for a PR closed eight days earlier.

    prune-merged keeps all five CORRECTLY. It proves one thing and it proves it well, and inventing a
    proof it does not have is the defect inbound #1191 measured. What was missing was a command that
    NAMES the rest, plus the four kinds of clutter that are not branches at all.

    SO THIS IS A CONDUCTOR, NOT A SECOND IMPLEMENTATION. Six of its ten lanes are a call into a script
    that already exists and is already tested; only four carry new logic, and that logic is pure and
    lives in tidy-lib.ps1. Nothing here re-derives a merge proof, re-reads a worktree list by hand, or
    re-answers a question another script in this repo already answers -- which is the whole of Ravi's
    rule and the reason issue #81 exists.

    THE AUTHORITY SPLIT, DECIDED BY DAVE ON SEPTEMBER 10, 2026, IS THE DESIGN. Asked what this command
    may throw away on its own, he chose: only what is provably merged. So:

      DELETES  -- exactly one lane, and only by delegation: prune-merged.ps1, on its own two existing
                  proofs (an ancestor of the trunk, or a tip that is the head commit of a merged PR).
      REPORTS  -- everything else, each item with what was measured and the command that would act on
                  it, paste-ready.

    THAT IS THE -IncludeRemote DOCTRINE TURNED INWARD. prune-merged already refuses to delete a remote
    branch and hands over the line instead, on the reasoning that with deleteBranchOnMerge on, the only
    branches a delete could still reach are the ones whose loss is unrecoverable. An abandoned branch is
    in exactly that position from the other direction: its pull request is closed, so the remote copy is
    gone and the local one is the last. A closed PR is strong evidence that nobody wants the work; it is
    not evidence that nobody wants the commits.

    WHAT IT NEVER TOUCHES, AND EACH IS A DECISION:

      - NO REMOTE BRANCH, ever, with or without a switch. Same rule as prune-merged, same reason, and
        asserted structurally by this script's suite.
      - NO STASH IS EVER DROPPED. A stash is unrecoverable and invisible to every other guard here;
        an old one is reported with its age and its `git stash show` line, and that is all.
      - NO PULL REQUEST is opened, merged or closed, and no issue is touched.
      - NOTHING UNDER THE SCRATCH ROOT IS DELETED, and this one is a decision this repo had already
        taken before the lane was written. scripts/README.md, on #1668, says those trees are "left
        standing on purpose" and names a sweep by name pattern as the delete primitive New-ScratchPath
        exists to remove (#1659). An earlier draft of lane 10 offered exactly that behind a flag; it
        was removed rather than defended. The lane ATTRIBUTES instead -- which is the scarce thing that
        measurement actually found, since its first reading mistook 546 retained-on-purpose artefacts
        and 162 unrelated files for leaked fixtures.
      - NO WORKING TREE IS MOVED BY THIS SCRIPT. The one exception is inherited rather than performed:
        prune-merged's step 4c steps off a branch it has just proven merged, and only then. Everything
        this script does itself is a read.

    THE ORDER OF THE LANES IS LOAD-BEARING IN EXACTLY ONE PLACE, and it is worth stating because it
    looks cosmetic. Stale lanes are reported BEFORE prune-merged runs, because git refuses to delete a
    branch that is checked out in any worktree, and that refusal is raised before the merged/unmerged
    question is asked (measured on git 2.54.0.windows.1, issue #1760):

        error: cannot delete branch 'X' used by worktree at '<path>'

    So a lane holding a provably merged branch makes that branch unreapable until the lane goes. Report
    it first and the reader can clear it in the same sitting; report it afterwards and they get git's
    sentence about a worktree in the middle of a list of merge proofs. This script also says so
    explicitly when it finds that pair, rather than leaving the reader to notice.

    THE MACHINE HALF READS ~/.claude/plugins/installed_plugins.json, which is this workflow's only
    machine-wide register. It is per-checkout install records keyed on FOLDER PATH, which is what makes
    a moved or renamed checkout leave a record behind pointing at nothing (issue #1449) -- and it is
    already the file plugin-versions.ps1 reads, so nothing new is being trusted here. It is deliberately
    not connectors/, which exists only in the source repo: this script has to work in a consumer.

    IT VISITS NO OTHER CHECKOUT. Dave's second answer on September 10, 2026 was "this checkout plus the
    machine-wide lanes" rather than "every checkout the machine knows about". A run that walked into
    other repositories would be reaching past the tree the session is standing in, and the blast radius
    of a bug in it would be repositories nobody had opened.

    Every git and gh call goes through the shared Invoke-NativeCapture (EAP=Continue -> run -> record
    $LASTEXITCODE), because git writes progress to stderr, which under EAP=Stop becomes a terminating
    NativeCommandError before the exit code can be judged (the #96/#97/#107 pitfall).

    Pure ASCII (repo convention for .ps1).

.PARAMETER DryRun
    Report everything and change nothing at all, including in the one lane that would otherwise act:
    it is passed straight through to prune-merged.ps1. Use it the first time on any machine.

.PARAMETER CheckoutOnly
    Run only the six per-checkout lanes and skip the four machine-wide ones.

.PARAMETER MachineOnly
    Run only the four machine-wide lanes. Useful when a checkout is mid-flight and you want the
    ~/.claude and scratch answers without anything reading the branch list.

.PARAMETER MaxAgeDays
    How old a `backup/*` branch or a stash must be before it is reported as expired. Default 14. It
    applies to NOTHING else: an age is not evidence about a branch somebody may simply not have got
    round to, and the only branch prefix in this workflow that declares itself temporary is `backup/`.

.PARAMETER MinFixtureAgeHours
    How old a scratch fixture tree must be before it counts as a leftover rather than as a suite that
    is still running. Default 24.

.PARAMETER Remote
    The remote prune-merged fetches and prunes. Default 'origin'.

.PARAMETER UserHomeOverride
    (Fixtures) pin the user home the machine-wide lanes read. A consumer never types this.

.PARAMETER ScratchRoot
    (Fixtures) pin the scratch root the fixture-tree lane walks. Defaults to this machine's TEMP.

.EXAMPLE
    ./scripts/maintenance/tidy-machine.ps1 -DryRun

.EXAMPLE
    ./scripts/maintenance/tidy-machine.ps1

.EXAMPLE
    ./scripts/maintenance/tidy-machine.ps1 -MachineOnly
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$CheckoutOnly,
    [switch]$MachineOnly,
    [int]$MaxAgeDays = 14,
    [double]$MinFixtureAgeHours = 24,
    [string]$Remote = 'origin',
    [string]$UserHomeOverride = '',
    [string]$ScratchRoot = ''
)

$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\merged-pr-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\worktree-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\ref-print-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\tidy-lib.ps1')

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR supplies
# its repo root; in the source root (or outside a session) it falls back to the git root. This way the
# SAME file works in both locations, and the root copy and the plugin mirror stay byte-identical.
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel 2>$null | Out-String).Trim() }
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

if ($CheckoutOnly -and $MachineOnly) {
    Write-Error "-CheckoutOnly and -MachineOnly are mutually exclusive -- pass neither to run both halves."
    exit 2
}
$runCheckout = -not $MachineOnly
$runMachine  = -not $CheckoutOnly

# The trunk name is the one thing that is repo-owned here, read the way every other script in this set
# reads it, with the same default.
$trunk = 'main'
$cfg = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $cfg -PathType Leaf) {
    try {
        . $cfg
        if (Get-Command 'Get-TrunkBranchName' -ErrorAction SilentlyContinue) { $trunk = Get-TrunkBranchName }
    } catch {
        Write-Warning "scripts\repo-config.ps1 could not be loaded -- assuming the trunk is '$trunk'. ($($_.Exception.Message))"
    }
}

function Invoke-Git {
    param([string[]]$Arguments)
    return (Invoke-NativeCapture -FilePath 'git' -Arguments $Arguments)
}

function Write-Lane {
    param([string]$Number, [string]$Title)
    Write-Host ''
    Write-Host "[$Number] $Title" -ForegroundColor Cyan
}

function Write-Item {
    param([string]$Text, [string]$Colour = 'Gray')
    Write-Host "  $Text" -ForegroundColor $Colour
}

function Write-Handover {
    param([string]$Command)
    if ($Command) { Write-Host "      $Command" -ForegroundColor Yellow }
}

function Write-RefHandover {
    <#
        A paste-ready command carrying a BRANCH NAME, put through the shared paste guard first. A ref
        name is not safe to interpolate into a printed command on trust: git enforces only the \p{Cc}
        half of the class, so a branch created by hand, cloned or fetched can carry a \p{Cf} run or a
        shell metacharacter straight into the line a reader is about to paste (#1594, #1617). When the
        name is refused the command still prints -- with a placeholder -- followed by the lib's own
        note, which names the real branch as inert prose so the reader can quote it themselves.
    #>
    param([string]$Prefix, [string]$Ref)
    $safe = Get-PasteableRef -Ref $Ref
    Write-Handover "$Prefix $($safe.Token)"
    if ($safe.Note) { Write-Item "    $($safe.Note)" 'DarkGray' }
}

function Write-PathHandover {
    <#
        The same guard for a command carrying a FILESYSTEM PATH. -Kind Path selects the noun the
        refusal note speaks in; the placeholder says which hole to fill, since '<branch>' would be the
        wrong word for a worktree directory. The path is quoted here because a lane directory legally
        contains spaces -- this repo's own default lane root is a sibling of the checkout.
    #>
    param([string]$Prefix, [string]$Path, [string]$Suffix = '', [string]$Placeholder = '<that lane>')
    $safe = Format-PasteablePathToken -Path $Path -Placeholder $Placeholder
    $tail = if ($Suffix) { " $Suffix" } else { '' }
    Write-Handover "$Prefix $($safe.Token)$tail"
    if ($safe.Note) { Write-Item "    $($safe.Note)" 'DarkGray' }
}

$actedTotal = 0
$reportedTotal = 0

Write-Host "tidy-machine -- repo root: $repoRoot, trunk: '$trunk'." -ForegroundColor White
if ($DryRun) { Write-Host "-DryRun: nothing will be changed anywhere, in any lane." -ForegroundColor DarkGray }

# ===================================================================================================
# GATHER (per-checkout half). Everything the first six lanes classify is read once, here, so no lane
# pays for a second git call and no two lanes can disagree about what the clone holds.
# ===================================================================================================

$branchClasses = @()
$worktreeRecords = @()

if ($runCheckout) {
    $wtRes = Invoke-Git -Arguments @('worktree', 'list', '--porcelain')
    if ($wtRes.ExitCode -eq 0) {
        $worktreeRecords = Get-WorktreeRecords -PorcelainLines @(($wtRes.Output | Out-String) -split '\r?\n')
    } else {
        Write-Warning "could not list worktrees -- the stale-lane lane is skipped. ($(($wtRes.Output | Out-String).Trim()))"
    }

    # Name, tip and committer date in one pass. A second call per branch would be one round trip per
    # branch on a clone that routinely holds thirty of them.
    $refRes = Invoke-Git -Arguments @(
        'for-each-ref', '--format=%(refname:short)%09%(objectname)%09%(committerdate:unix)', 'refs/heads')
    $rows = @()
    if ($refRes.ExitCode -eq 0) {
        $rows = @(($refRes.Output | Out-String) -split '\r?\n' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ } |
            ForEach-Object {
                $parts = $_ -split "`t"
                if ($parts.Count -ge 3) {
                    [pscustomobject]@{ Name = $parts[0].Trim(); Tip = $parts[1].Trim(); Unix = $parts[2].Trim() }
                }
            })
    } else {
        Write-Warning "could not list local branches -- the branch lanes are skipped. ($(($refRes.Output | Out-String).Trim()))"
    }
    $rows = @($rows | Where-Object { $_.Name -ne $trunk })

    # BOTH PR LOOKUPS ARE ONE CALL EACH, matched locally, for the reason prune-merged states for its
    # own: a repo a week into this workflow already has dozens of each, and this is a tidy-up rather
    # than a report anyone waits on. A gh that cannot answer is NOT an error here either -- it means a
    # proof cannot be established, so the branch keeps the weakest classification it qualifies for.
    $mergedTips = $null
    $closedTips = $null
    if ($rows.Count -gt 0) {
        $ghCmd = Get-Command 'gh' -ErrorAction SilentlyContinue
        if ($ghCmd) {
            $mergedRes = Invoke-NativeCapture -FilePath 'gh' -Arguments @(
                'pr', 'list', '--state', 'merged', '--limit', '200', '--json', 'headRefName,headRefOid')
            if ($mergedRes.ExitCode -eq 0) {
                try {
                    $body = ($mergedRes.Output | Out-String).Trim()
                    $parsed = if ($body) { @($body | ConvertFrom-Json) } else { @() }
                    $mergedTips = Get-MergedPrTips -Pairs @($parsed | ForEach-Object {
                        [pscustomobject]@{ Name = $_.headRefName; Tip = $_.headRefOid } })
                } catch {
                    Write-Warning "gh's merged-PR list could not be read as JSON -- squash-merged branches will not be recognised. ($($_.Exception.Message))"
                }
            } else {
                Write-Warning "gh could not list merged PRs -- squash-merged branches will not be recognised. ($(($mergedRes.Output | Out-String).Trim()))"
            }

            # `--state closed` INCLUDES MERGED, because merged is a kind of closed and gh has no state
            # that means closed-and-not-merged. THE FILTER HAS TO BE ON THE SERVER, not here, and that
            # was measured rather than assumed: this script first dropped merged rows client-side after
            # `--limit 200`, and found ZERO abandoned branches in a repo that has three. In a repo where
            # nearly every PR merges, the 200 most recent CLOSED pull requests are 200 merged ones, so
            # every genuinely abandoned branch falls outside the window -- a filter that is correct and
            # reaches nothing. `--search is:unmerged` asks GitHub the question instead, so the whole
            # limit is spent on rows that can actually be a proof.
            #
            # mergedAt is still requested and still dropped on, as a belt: the search qualifier is
            # GitHub's to interpret, and a row carrying a merge date must never reach the abandoned
            # classification whatever the server thought it was answering.
            $closedRes = Invoke-NativeCapture -FilePath 'gh' -Arguments @(
                'pr', 'list', '--state', 'closed', '--search', 'is:unmerged', '--limit', '200',
                '--json', 'headRefName,headRefOid,mergedAt')
            if ($closedRes.ExitCode -eq 0) {
                try {
                    $body = ($closedRes.Output | Out-String).Trim()
                    $parsed = if ($body) { @($body | ConvertFrom-Json) } else { @() }
                    $closedTips = Get-ClosedPrTips -Pairs @($parsed |
                        Where-Object { -not $_.mergedAt } |
                        ForEach-Object { [pscustomobject]@{ Name = $_.headRefName; Tip = $_.headRefOid } })
                } catch {
                    Write-Warning "gh's closed-PR list could not be read as JSON -- no branch will be classified abandoned. ($($_.Exception.Message))"
                }
            } else {
                Write-Warning "gh could not list closed PRs -- no branch will be classified abandoned. ($(($closedRes.Output | Out-String).Trim()))"
            }
        } else {
            Write-Warning "gh is not available -- only ancestry can prove anything, so nothing will be classified abandoned."
        }
    }

    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    foreach ($row in $rows) {
        $anc = (Invoke-Git -Arguments @('merge-base', '--is-ancestor', $row.Tip, $trunk)).ExitCode -eq 0
        $age = -1
        $unix = 0
        if ([long]::TryParse($row.Unix, [ref]$unix) -and $unix -gt 0) {
            $age = [int][math]::Floor(($now - $unix) / 86400)
        }
        $branchClasses += Get-BranchTidyClass -Name $row.Name -Tip $row.Tip -IsAncestorOfTrunk $anc `
            -MergedTips $mergedTips -ClosedTips $closedTips -AgeDays $age -MaxAgeDays $MaxAgeDays
    }
}

# ===================================================================================================
# LANE 1 -- stale lanes. FIRST, because a worktree blocks the delete of the branch it holds (#1760).
# ===================================================================================================

if ($runCheckout) {
    Write-Lane '1' 'Stale lanes -- a worktree whose branch is finished'
    # WRAPPED, and it is not decoration: PowerShell unwraps a single-element array on return, so a run
    # that found exactly ONE stale lane would hand back a bare PSCustomObject whose .Count is $null.
    # That reads as 0, and the summary line then said "nothing found" underneath the lane it had just
    # printed. Measured on the first real run of this script.
    $lanes = @(Get-StaleLaneDecisions -WorktreeRecords $worktreeRecords -BranchClasses $branchClasses)
    if ($lanes.Count -eq 0) {
        Write-Item 'None.' 'DarkGray'
    }
    foreach ($l in $lanes) {
        $reportedTotal++
        Write-Item "$(Get-DisplayRef $l.Branch) -- $($l.Reason)" 'Yellow'
        Write-Item "    a second full checkout at $(Get-DisplayPath $l.Path)" 'DarkGray'
        if ($l.Class -eq 'reapable') {
            Write-Item '    this ALSO blocks lane 2: git will not delete a branch checked out in a worktree.' 'Red'
        }
        Write-PathHandover -Prefix $l.Command -Path $l.Path
        Write-PathHandover -Prefix $l.RawCommand -Path $l.Path
    }
    Write-Item (Get-TidySummaryLine -Lane 'Stale lanes' -Reported $lanes.Count) 'White'
}

# ===================================================================================================
# LANE 2 -- merged branches and stale tracking refs. THE ONLY LANE THAT DELETES, by delegation.
# ===================================================================================================

if ($runCheckout) {
    Write-Lane '2' 'Merged branches and stale tracking refs -- delegated to prune-merged.ps1'
    $prune = Join-Path $PSScriptRoot '..\task\prune-merged.ps1'
    if (-not (Test-Path -LiteralPath $prune -PathType Leaf)) {
        Write-Item "prune-merged.ps1 was not found at $prune -- this lane is skipped." 'Red'
    } else {
        $pruneArgs = @{ Remote = $Remote }
        if ($DryRun) { $pruneArgs['DryRun'] = $true }
        # Invoked directly rather than captured: its output IS this lane's report, and relaying it
        # through a capture would strip the colour that separates its kept lines from its deleted ones.
        & $prune @pruneArgs
        $reapable = @($branchClasses | Where-Object { $_.Class -eq 'reapable' }).Count
        if (-not $DryRun) { $actedTotal += $reapable }
    }
}

# ===================================================================================================
# LANE 3 -- abandoned branches. The new proof, and the reason this script exists.
# ===================================================================================================

if ($runCheckout) {
    Write-Lane '3' 'Abandoned branches -- a pull request that was CLOSED without merging'
    $abandoned = @($branchClasses | Where-Object { $_.Class -eq 'abandoned' })
    if ($abandoned.Count -eq 0) { Write-Item 'None.' 'DarkGray' }
    foreach ($a in $abandoned) {
        $reportedTotal++
        Write-Item "$(Get-DisplayRef $a.Name) -- $($a.Reason)" 'Yellow'
        Write-RefHandover -Prefix 'git branch -D' -Ref $a.Name
    }
    if ($abandoned.Count -gt 0) {
        Write-Item '  Nothing above was deleted. A closed PR means the remote copy is gone, so this clone holds the last one.' 'DarkGray'
    }
    Write-Item (Get-TidySummaryLine -Lane 'Abandoned' -Reported $abandoned.Count) 'White'
}

# ===================================================================================================
# LANE 4 -- expired backups and the unprovable middle. Report only, both of them.
# ===================================================================================================

if ($runCheckout) {
    Write-Lane '4' 'Expired backups, and branches no proof reaches'
    $backups  = @($branchClasses | Where-Object { $_.Class -eq 'expired-backup' })
    $recycled = @($branchClasses | Where-Object { $_.Class -eq 'recycled' })
    $live     = @($branchClasses | Where-Object { $_.Class -eq 'live' })
    if ($backups.Count -eq 0 -and $recycled.Count -eq 0) { Write-Item 'None.' 'DarkGray' }
    foreach ($b in $backups) {
        $reportedTotal++
        Write-Item "$(Get-DisplayRef $b.Name) -- $($b.Reason)" 'Yellow'
        Write-RefHandover -Prefix 'git branch -D' -Ref $b.Name
    }
    foreach ($r in $recycled) {
        $reportedTotal++
        Write-Item "$(Get-DisplayRef $r.Name) -- $($r.Reason)" 'Yellow'
        Write-Item '    nothing is proposed for this one: the lookup came up full and belonged to another commit.' 'DarkGray'
    }
    Write-Item (Get-TidySummaryLine -Lane 'Unproven' -Reported ($backups.Count + $recycled.Count) -Untouched $live.Count) 'White'
}

# ===================================================================================================
# LANE 5 -- old stashes. REPORTED, NEVER DROPPED.
# ===================================================================================================

if ($runCheckout) {
    Write-Lane '5' 'Stashes -- reported only, never dropped'
    $stashRes = Invoke-Git -Arguments @('stash', 'list', '--format=%gd%09%ct%09%s')
    $stale = 0
    $total = 0
    if ($stashRes.ExitCode -eq 0) {
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        foreach ($line in (($stashRes.Output | Out-String) -split '\r?\n')) {
            $t = $line.Trim()
            if (-not $t) { continue }
            $total++
            $parts = $t -split "`t"
            if ($parts.Count -lt 3) { continue }
            $unix = 0
            if (-not [long]::TryParse($parts[1].Trim(), [ref]$unix)) { continue }
            $days = [int][math]::Floor(($now - $unix) / 86400)
            if ($days -le $MaxAgeDays) { continue }
            $stale++
            $reportedTotal++
            # The subject is somebody else's free text -- the same class this workflow sanitises at four
            # other consoles (ref-print-lib.ps1's header lists them). Get-DisplayRef strips it here too.
            Write-Item "$($parts[0].Trim()) -- $days days old: $(Get-DisplayRef $parts[2].Trim())" 'Yellow'
            Write-Handover "git stash show -p $($parts[0].Trim())"
        }
    } else {
        Write-Item 'could not read the stash list.' 'Red'
    }
    if ($stale -eq 0) { Write-Item 'None older than the bound.' 'DarkGray' }
    Write-Item (Get-TidySummaryLine -Lane 'Stashes' -Reported $stale -Untouched ($total - $stale)) 'White'
}

# ===================================================================================================
# LANE 6 -- an unfolded branch document sitting on the trunk.
# ===================================================================================================

if ($runCheckout) {
    Write-Lane '6' 'Unfolded changelog entry on the trunk -- delegated to check-unfolded-entry.ps1'
    $unfolded = Join-Path $PSScriptRoot '..\lint\check-unfolded-entry.ps1'
    if (Test-Path -LiteralPath $unfolded -PathType Leaf) { & $unfolded }
    else { Write-Item 'check-unfolded-entry.ps1 is not present in this repo -- lane skipped.' 'DarkGray' }
}

# ===================================================================================================
# LANE 7 -- the ~/.claude plugin administration.
# ===================================================================================================

if ($runMachine) {
    Write-Lane '7' 'The ~/.claude plugin administration -- delegated to check-claude-home.ps1'
    $claudeHome = Join-Path $PSScriptRoot '..\lint\check-claude-home.ps1'
    if (Test-Path -LiteralPath $claudeHome -PathType Leaf) { & $claudeHome }
    else { Write-Item 'check-claude-home.ps1 is not present in this repo -- lane skipped.' 'DarkGray' }
}

# ===================================================================================================
# LANE 8 -- install records pointing at a checkout that is gone (#1449).
# ===================================================================================================

if ($runMachine) {
    Write-Lane '8' 'Orphaned plugin install records -- a checkout that is not on this machine'
    $install = Get-InstallRecord -RepoRoot $repoRoot -UserHomeOverride $UserHomeOverride
    if (-not $install.Exists) {
        Write-Item 'no install administration on this machine -- nothing to check.' 'DarkGray'
    } elseif (-not $install.Readable) {
        Write-Item "the install administration could not be read: $($install.Error)" 'Red'
    } else {
        # The probe is done here rather than in the lib so the lib stays pure -- and so a caller on a
        # machine with an unmounted drive can see exactly which path was tested.
        $probe = @{}
        foreach ($rec in @($install.AllRecords)) {
            $p = [string]$rec.ProjectPath
            if (-not $p) { continue }
            if ($probe.ContainsKey($p)) { continue }
            $probe[$p] = [bool](Test-Path -LiteralPath $p -PathType Container)
        }
        # Wrapped for the single-element unwrap described at the stale-lane call above.
        $orphans = @(Get-OrphanInstallRecords -Records @($install.AllRecords) -PathExists $probe)
        if ($orphans.Count -eq 0) { Write-Item 'None.' 'DarkGray' }
        foreach ($o in $orphans) {
            $reportedTotal++
            Write-Item "$($o.Plugin) -> $(Get-DisplayPath $o.ProjectPath)" 'Yellow'
            Write-Item "    $($o.Reason)" 'DarkGray'
        }
        if ($orphans.Count -gt 0) {
            Write-Item '  Moved checkout? Re-install the plugin there. Deleted? The record is dead weight. Nothing on disk tells the two apart, so nothing here guesses.' 'DarkGray'
        }
        Write-Item (Get-TidySummaryLine -Lane 'Install records' -Reported $orphans.Count) 'White'
    }
}

# ===================================================================================================
# LANE 9 -- how far behind this checkout's plugins are.
# ===================================================================================================

if ($runMachine) {
    Write-Lane '9' 'Plugin and marketplace staleness -- delegated to plugin-versions.ps1'
    $versions = Join-Path $PSScriptRoot '..\task\plugin-versions.ps1'
    if (Test-Path -LiteralPath $versions -PathType Leaf) { & $versions }
    else { Write-Item 'plugin-versions.ps1 is not present in this repo -- lane skipped.' 'DarkGray' }
}

# ===================================================================================================
# LANE 10 -- leftover fixture trees under the scratch root.
# ===================================================================================================

if ($runMachine) {
    Write-Lane '10' 'Fixture trees under the scratch root -- attributed, never deleted'
    $scratch = if ($ScratchRoot) { $ScratchRoot } else { [System.IO.Path]::GetTempPath() }
    if (-not (Test-Path -LiteralPath $scratch -PathType Container)) {
        Write-Item "scratch root $(Get-DisplayPath $scratch) does not exist -- lane skipped." 'DarkGray'
    } else {
        # THE WALK IS ONE LEVEL DEEP, because that is where New-ScratchPath puts things: a direct child
        # of the temp root, always. A recursive scan would be slow and would also let a match deep
        # inside an unrelated tree be reported as if it were ours.
        $livePids = @()
        try { $livePids = @(Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $_.Id }) } catch { }

        $leftover = 0; $live = 0; $retained = 0
        foreach ($dir in @(Get-ChildItem -LiteralPath $scratch -Directory -ErrorAction SilentlyContinue)) {
            $ageHours = ([DateTime]::UtcNow - $dir.LastWriteTimeUtc).TotalHours
            switch (Get-ScratchLeftoverVerdict -Name $dir.Name -LivePids $livePids -AgeHours $ageHours -MinAgeHours $MinFixtureAgeHours) {
                'leftover' {
                    $leftover++
                    $reportedTotal++
                    Write-Item "$(Get-DisplayPath $dir.Name) -- $([int]$ageHours)h old, and the pid in its name is not a running process" 'Yellow'
                }
                'live'     { $live++ }
                'retained' { $retained++ }
            }
        }
        if ($leftover -eq 0) {
            Write-Item 'No tree attributable to a run that has ended.' 'DarkGray'
        } else {
            # NO COMMAND IS HANDED OVER HERE, and that is the one lane where the omission is the point.
            # scripts/README.md already decided these stay standing, and names a sweep by name pattern
            # as the delete primitive New-ScratchPath exists to remove (#1659, #1668). Printing the
            # Remove-Item line would be re-proposing exactly that, one copy-paste away.
            Write-Item '  Left standing on purpose (#1668). Clear by hand what you recognise -- a pattern sweep here is the delete primitive New-ScratchPath exists to prevent (#1659).' 'DarkGray'
        }
        Write-Item (Get-TidySummaryLine -Lane 'Fixture trees' -Reported $leftover -Untouched ($live + $retained)) 'White'
        if ($retained -gt 0) { Write-Item "  ($retained retained-on-purpose artefact(s) skipped: sync-pr-body, test-suite-gate.)" 'DarkGray' }
    }
}

# ===================================================================================================

Write-Host ''
if ($DryRun) {
    Write-Host "Done (-DryRun). Nothing was changed; $reportedTotal item(s) were handed over." -ForegroundColor Green
} else {
    Write-Host "Done. $actedTotal item(s) acted on, $reportedTotal handed over for you to decide." -ForegroundColor Green
}
Write-Host "No remote branch was touched, no stash was dropped, and no pull request was opened, merged or closed." -ForegroundColor DarkGray
exit 0
