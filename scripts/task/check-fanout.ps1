<#
.SYNOPSIS
    Did a dispatched fan-out lose any of THIS session's uncommitted work: take a baseline before
    dispatching, compare after the agents return, and report shrinkage only.

.DESCRIPTION
    Two modes, one before the fan-out and one after it:

        # before dispatching any subagent
        powershell -NoProfile -File scripts\task\check-fanout.ps1 -Capture
        # -> prints the baseline path

        # after the fan-out has returned
        powershell -NoProfile -File scripts\task\check-fanout.ps1 -Compare <that path>

    WHAT IT IS FOR (issue #1670). Issue #1665 measured a dispatched review specialist running
    `git stash` and then `git checkout HEAD -- <file>` in the orchestrator's checkout, discarding
    three files of uncommitted work belonging to the session that dispatched it. No error, no notice,
    no refusal, and a clean `git status` afterwards -- which the reviewer cited as proof it had changed
    nothing. It was found days later by accident.

    #1665 was repaired with an instruction (the shared block `working-copy-boundary`, carried by every
    agent def that holds `Bash`). That is purely preventive, and #1670's finding was that no detection
    half existed anywhere -- so a repeat would be exactly as invisible as the first, and less
    conspicuous whenever what gets discarded is a config value rather than a paragraph somebody later
    reads. This script is that half.

    WHY IT IS INVOKED AND NOT AUTOMATIC, stated because this repo's own laziness rule says a step that
    must happen every time belongs in a hook. #1670 left the choice open between a hook, tooling and a
    documented step, and the invoked script is what shipped first for one reason: a Pre/PostToolUse
    hook pair around the dispatch rests on the matcher name of the dispatch tool, and that had not been
    measured. Nothing here rests on anything unmeasured. The hook variant stays open on #1670 and is
    cheap to add on top, because the judgement it would need is already the shared function
    Compare-WorkingCopySnapshot rather than anything in this file.

    IT REPORTS AND REFUSES NOTHING, and it cannot restore. Content discarded by
    `git checkout HEAD -- <path>` was never committed and is in no reflog, so there is nothing to
    restore it from; detection is the whole available remedy, which is why its absence mattered. The
    exit code is 1 when something shrank, so a caller can branch on it -- that is a finding, not a
    refusal, and this script is in no gate.

    SHRINKAGE ONLY. A subagent legitimately writing files makes the changed-path list GROW, which is
    expected and never reported. The four false positives this answers -- the orchestrator's own
    commits, a rewritten history, a branch change, and `git reset` moving a change from the index to
    the worktree -- are documented in scripts\lib\fanout-lib.ps1, which holds the whole judgement.

    THE BASELINE PATH IS UNPREDICTABLE, via New-ScratchPath (#1659), and -Capture PRINTS it rather
    than composing a name both runs can guess. That is the same rule every other shipping script here
    follows, and it costs nothing: the caller is a session that has the printed path in front of it.

    A SPENT BASELINE IS REMOVED, and one that could not be used is kept. After a comparison that
    reached a verdict the file has served its purpose and is deleted; where the two snapshots turned
    out not to be comparable (a branch change, a rewritten history) it stays, because the sensible next
    move is to get back to that state and compare again.

    Exit codes: 0 = nothing shrank (or nothing comparable to say), 1 = something shrank, 2 = the
    invocation itself was wrong (no mode, both modes, an unreadable baseline).

    Pure ASCII (repo convention for .ps1): Windows PowerShell 5.1 reads a BOM-less script as ANSI.
    Tested by scripts/tests/fanout-lib.tests.ps1 in the source repo -- change one, run the other.
#>

param(
    # Take the baseline. Prints the path to hand to -Compare.
    [switch]$Capture,
    # Compare against the baseline at this path.
    [string]$Compare,
    # Explicit repo root, for the suite: it puts this script in front of fixture trees that are not
    # the checkout it is standing in. A caller never types it.
    [string]$RootOverride
)

$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR supplies
# its repo root; in the source root (or outside a session) it falls back to the git root. This way the
# SAME file works in both locations, and the root copy and the plugin mirror stay byte-identical
# (guarded by the shared-scripts drift lint).
$repoRoot = if ($RootOverride) { $RootOverride }
            elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR }
            else { (git rev-parse --show-toplevel).Trim() }

# Both $PSScriptRoot-relative, not $repoRoot: neither lib is repo-owned -- they travel with the SAME
# plugin/mirror payload as this script.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\fanout-lib.ps1')

if ($Capture -and $Compare) {
    Write-Host "check-fanout: pass -Capture (before the fan-out) or -Compare <path> (after it), not both." -ForegroundColor Red
    exit 2
}
if (-not $Capture -and -not $Compare) {
    Write-Host "check-fanout: nothing to do. -Capture takes the baseline BEFORE you dispatch; -Compare <path> reads it back afterwards." -ForegroundColor Red
    exit 2
}

Write-Host "== check-fanout -- $repoRoot ==" -ForegroundColor Cyan

# --- -Capture -------------------------------------------------------------------------------------
if ($Capture) {
    $snap = Get-WorkingCopySnapshot -RepoRoot $repoRoot
    $path = New-ScratchPath -Label 'fanout-baseline' -Extension '.json'
    (ConvertTo-WorkingCopySnapshotJson -Snapshot $snap) | Set-Content -LiteralPath $path -Encoding utf8

    $changed = if ($snap.EntriesKnown) { "$($snap.Entries.Count) changed path(s)" } else { 'changed paths: NOT measured' }
    $stashed = if ($snap.StashKnown) { "$(@($snap.Stash).Count) stash entry(ies)" } else { 'stash: NOT measured' }
    Write-Host "  baseline: $changed, $stashed" -ForegroundColor Gray
    # THE UNMEASURED BASELINE IS SAID OUT LOUD HERE, not only at the comparison. A baseline that could
    # not read the tree compares clean against anything, so a caller told about it now can take another
    # one; told about it afterwards, it has already lost whatever the window was going to lose.
    if (-not $snap.EntriesKnown -or -not $snap.StashKnown) {
        Write-Host "  [WARN] part of this baseline could not be read, so the comparison afterwards cannot speak for it." -ForegroundColor Yellow
    }
    Write-Host "[OK] baseline taken. After the fan-out returns:" -ForegroundColor Green
    Write-Host "     powershell -NoProfile -File scripts\task\check-fanout.ps1 -Compare `"$path`""
    exit 0
}

# --- -Compare -------------------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $Compare -PathType Leaf)) {
    Write-Host "check-fanout: no baseline at '$Compare'. Nothing can be said about a window with no beginning -- take one with -Capture before the next fan-out." -ForegroundColor Red
    exit 2
}

try {
    $before = ConvertFrom-WorkingCopySnapshotJson -Json ((Get-Content -LiteralPath $Compare -Raw))
} catch {
    Write-Host "check-fanout: the baseline at '$Compare' could not be read -- $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}

$after = Get-WorkingCopySnapshot -RepoRoot $repoRoot

# --- The bridge: what only a git read can say about the gap between the two snapshots -------------
# Defaults are the HONEST ones rather than the convenient ones: nothing established, so the comparison
# hedges instead of clearing a path it never checked.
$committedPaths = @()
$committedKnown = $false
$historyLinear = $false
$historyKnown = $false

if ($before.HeadKnown -and $after.HeadKnown) {
    if ($before.Head -eq $after.Head) {
        # HEAD did not move, so there are no commits to bridge and no path can have left the list by
        # being committed. Both figures are KNOWN and empty, which is a different statement from
        # "could not be established".
        $historyLinear = $true
        $historyKnown = $true
        $committedKnown = $true
    } else {
        $ancRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $repoRoot, 'merge-base', '--is-ancestor', $before.Head, $after.Head) -DiscardStderr
        if ($ancRes.ExitCode -eq 0) { $historyLinear = $true; $historyKnown = $true }
        elseif ($ancRes.ExitCode -eq 1) { $historyLinear = $false; $historyKnown = $true }
        # Any other exit code leaves HistoryKnown false: git could not answer, so neither can this.

        if ($historyKnown -and $historyLinear) {
            # TWO DOTS: the commits ADDED since the baseline, which is exactly the set that could have
            # taken a path out of the changed list legitimately.
            $diffRes = Invoke-NativeCapture -FilePath 'git' -Arguments @('-c', 'core.quotePath=true', '-C', $repoRoot, 'diff', '--name-only', "$($before.Head)..$($after.Head)")
            if ($diffRes.ExitCode -eq 0) {
                $committedKnown = $true
                $committedPaths = @(($diffRes.Output | Out-String) -split '\r?\n' |
                    ForEach-Object { $_.Trim().Trim('"') } |
                    Where-Object { $_ })
            }
        }
    }
}

$bridge = [pscustomobject]@{
    CommittedPaths      = $committedPaths
    CommittedPathsKnown = $committedKnown
    HistoryLinear       = $historyLinear
    HistoryKnown        = $historyKnown
}

$findings = @(Compare-WorkingCopySnapshot -Before $before -After $after -Bridge $bridge)
foreach ($line in @(Format-WorkingCopyShrinkage -Findings $findings)) {
    $colour = if ($line.StartsWith('[ALARM]')) { 'Red' } elseif ($line.StartsWith('[OK]')) { 'Green' } else { 'Yellow' }
    Write-Host "  $line" -ForegroundColor $colour
}

$alarms = @($findings | Where-Object { $_.Kind -eq 'Vanished' -or $_.Kind -eq 'WorktreeCleared' -or $_.Kind -eq 'StashGone' })
$untrusted = @($findings | Where-Object { $_.Kind -eq 'BranchChanged' -or $_.Kind -eq 'HistoryRewritten' })

if ($untrusted.Count -gt 0) {
    Write-Host "  baseline kept at: $Compare" -ForegroundColor Gray
    Write-Host "  (it was not spent -- get back to the state it was taken in and compare again.)" -ForegroundColor Gray
} else {
    Remove-Item -LiteralPath $Compare -Force -ErrorAction SilentlyContinue
}

if ($alarms.Count -gt 0) {
    Write-Host ""
    Write-Host "This is a report, not a refusal, and the content is NOT recoverable: nothing above was" -ForegroundColor Yellow
    Write-Host "ever committed, so no reflog holds it. What is actionable is which file to write again." -ForegroundColor Yellow
    exit 1
}

exit 0
