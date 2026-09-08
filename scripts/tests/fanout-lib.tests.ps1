<#
.SYNOPSIS
    Tests for scripts/lib/fanout-lib.ps1 and scripts/task/check-fanout.ps1 (issue #1670): the
    working-copy snapshot, and the shrinkage comparison over two of them.

.DESCRIPTION
        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/fanout-lib.tests.ps1

    WHY THE JUDGEMENT IS TESTED WITHOUT GIT AND THE READS ARE TESTED WITH IT. Compare-WorkingCopySnapshot
    is pure by design, so every decision it makes -- growth stays silent, a vanished path is a finding, a
    committed path is not, `git reset` is not, a branch change refuses instead of differencing -- is three
    lines here instead of a fixture repo per case. The two functions that touch git get a fixture, because
    what they can get wrong is the parse of git's own output rather than a decision.

    EVERY EXEMPTION HAS A COUNTER-CASE, the rule guard-live-theme.tests.ps1 states for the same reason: an
    exemption without one is a hole with a comment on it. So the suite pairs them -- growth silent AND
    shrinkage reported; a committed path excluded AND an uncommitted one named; the index half ignored AND
    the worktree half caught.

    AND THE STASH CASE THAT MATTERS IS THE ONE A COUNT CANNOT SEE. #1670 proposed counting stash entries
    and said a count is enough. Case 7 is the refutation: one entry popped while another is pushed leaves
    the count unchanged, so a count reports nothing on exactly the #1665 command. Ids are compared instead,
    and that case is pinned rather than left as a claim in a docstring.

    Dependency-free (no Pester), same style as session-cache-lib.tests.ps1. Pure ASCII (repo convention
    for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Lib      = Join-Path $RepoRoot 'scripts\lib\fanout-lib.ps1'
$Script   = Join-Path $RepoRoot 'scripts\task\check-fanout.ps1'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) "fanout-lib-test-$PID"

. (Join-Path $PSScriptRoot '..\lib\fixture-git-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')
. $Lib

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ("$Expected" -eq "$Actual") { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}
function Assert-True {
    param([bool]$Condition, [string]$Label)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label" -ForegroundColor Red }
}

# A snapshot in one line. Entries take the two-character porcelain code the way git prints it, so a
# case reads like the `git status --porcelain` output it stands for: @{ 'a.txt' = ' M' }.
function New-Snap {
    param(
        [hashtable]$Entries = @{},
        # Rename pairings, keyed on the NEW path: @{ 'b.txt' = 'a.txt' } is "b.txt used to be a.txt",
        # which is what a porcelain 'R  a.txt -> b.txt' line means.
        [hashtable]$From = @{},
        [string[]]$Stash = @(),
        [string]$Head = 'aaaaaaa',
        [string]$Branch = 'main',
        [bool]$EntriesKnown = $true,
        [bool]$StashKnown = $true,
        [bool]$HeadKnown = $true,
        [bool]$BranchKnown = $true
    )
    $e = @{}
    foreach ($k in $Entries.Keys) {
        $code = [string]$Entries[$k]
        $e[$k] = [pscustomobject]@{
            Index    = $code.Substring(0, 1)
            Worktree = $code.Substring(1, 1)
            From     = if ($From.ContainsKey($k)) { [string]$From[$k] } else { '' }
        }
    }
    return [pscustomobject]@{
        Head = $Head; HeadKnown = $HeadKnown
        Branch = $Branch; BranchKnown = $BranchKnown
        Entries = $e; EntriesKnown = $EntriesKnown
        Stash = @($Stash); StashKnown = $StashKnown
        TakenUtc = '2026-09-08T00:00:00Z'
    }
}

function New-Bridge {
    param(
        [string[]]$CommittedPaths = @(),
        [bool]$CommittedPathsKnown = $true,
        [bool]$HistoryLinear = $true,
        [bool]$HistoryKnown = $true
    )
    return [pscustomobject]@{
        CommittedPaths = @($CommittedPaths); CommittedPathsKnown = $CommittedPathsKnown
        HistoryLinear = $HistoryLinear; HistoryKnown = $HistoryKnown
    }
}

function Get-Kinds {
    param($Findings)
    return (@($Findings | ForEach-Object { $_.Kind }) -join ',')
}

try {
    Write-Host ''
    Write-Host '1. Growth is expected and stays silent -- the asymmetry the whole detector rests on' -ForegroundColor Cyan
    $before = New-Snap -Entries @{ 'a.txt' = ' M' }
    $after  = New-Snap -Entries @{ 'a.txt' = ' M'; 'b.txt' = '??'; 'c.txt' = 'M ' }
    $f = @(Compare-WorkingCopySnapshot -Before $before -After $after -Bridge (New-Bridge))
    Assert-Equal 0 $f.Count '1: three paths appeared and nothing is reported'

    Write-Host ''
    Write-Host '2. A vanished path IS reported -- the #1665 case, git checkout HEAD -- <file>' -ForegroundColor Cyan
    $before = New-Snap -Entries @{ 'a.txt' = ' M'; 'keep.txt' = ' M' }
    $after  = New-Snap -Entries @{ 'keep.txt' = ' M' }
    $f = @(Compare-WorkingCopySnapshot -Before $before -After $after -Bridge (New-Bridge))
    Assert-Equal 1 $f.Count '2: exactly one finding'
    Assert-Equal 'Vanished' $f[0].Kind '2: and it is a Vanished'
    Assert-Equal 'a.txt' $f[0].Path '2: naming the path that lost its edit'
    Assert-True ($f[0].Detail -notmatch 'could NOT be established') '2: with no hedge, because the committed-path list was known'

    Write-Host ''
    Write-Host '3. A path that left the list by being COMMITTED is not a loss (false positive 1)' -ForegroundColor Cyan
    $f = @(Compare-WorkingCopySnapshot -Before $before -After $after -Bridge (New-Bridge -CommittedPaths @('a.txt')))
    Assert-Equal 0 $f.Count '3: the orchestrator kept working, and its own commit is not an alarm'
    $f = @(Compare-WorkingCopySnapshot -Before $before -After $after -Bridge (New-Bridge -CommittedPaths @('other.txt')))
    Assert-Equal 'Vanished' (Get-Kinds $f) '3: a commit that carries a DIFFERENT path does not excuse this one'

    Write-Host ''
    Write-Host '4. Where the committed-path list is unknown, the finding stands WITH the hedge' -ForegroundColor Cyan
    $f = @(Compare-WorkingCopySnapshot -Before $before -After $after -Bridge (New-Bridge -CommittedPathsKnown $false))
    Assert-Equal 'Vanished' (Get-Kinds $f) '4: still reported -- silence would be the wrong direction'
    Assert-True ($f[0].Detail -match 'could NOT be established') '4: and the report says the innocent explanation was not ruled out'

    Write-Host ''
    Write-Host '5. The WORKTREE half going clean is a loss even while the path remains' -ForegroundColor Cyan
    # 'MM' -> 'M ': staged change kept, worktree edit discarded. What `git checkout -- <path>` does.
    $before = New-Snap -Entries @{ 'a.txt' = 'MM' }
    $after  = New-Snap -Entries @{ 'a.txt' = 'M ' }
    $f = @(Compare-WorkingCopySnapshot -Before $before -After $after -Bridge (New-Bridge))
    Assert-Equal 'WorktreeCleared' (Get-Kinds $f) '5: reported, because content really is gone'
    Assert-Equal 'a.txt' $f[0].Path '5: naming the path'

    Write-Host ''
    Write-Host '6. The INDEX half going clean is NOT a loss (false positive 4) -- git reset keeps content' -ForegroundColor Cyan
    $before = New-Snap -Entries @{ 'a.txt' = 'M ' }
    $after  = New-Snap -Entries @{ 'a.txt' = ' M' }
    $f = @(Compare-WorkingCopySnapshot -Before $before -After $after -Bridge (New-Bridge))
    Assert-Equal 0 $f.Count '6: an unstage moves the change, it does not discard it'
    # A file with BOTH halves changed, unstaged: 'MM' -> ' M'. The index half went clean and the
    # worktree edit is still there, so still nothing to report.
    $f = @(Compare-WorkingCopySnapshot -Before (New-Snap -Entries @{ 'a.txt' = 'MM' }) -After (New-Snap -Entries @{ 'a.txt' = ' M' }) -Bridge (New-Bridge))
    Assert-Equal 0 $f.Count '6: and the same on a file whose worktree half is untouched'
    # THE COUNTER-CASE for that exemption, so it is not a hole with a comment on it: the OTHER half of
    # the same 'MM' start, where the worktree edit is the one that goes.
    $f = @(Compare-WorkingCopySnapshot -Before (New-Snap -Entries @{ 'a.txt' = 'MM' }) -After (New-Snap -Entries @{ 'a.txt' = 'M ' }) -Bridge (New-Bridge))
    Assert-Equal 'WorktreeCleared' (Get-Kinds $f) '6: while the mirror-image transition IS caught, so the exemption swallows nothing'

    Write-Host ''
    Write-Host '7. A stash entry is identified, not counted -- the case a COUNT cannot see' -ForegroundColor Cyan
    $before = New-Snap -Stash @('s1', 's2')
    $after  = New-Snap -Stash @('s2', 's3')
    $f = @(Compare-WorkingCopySnapshot -Before $before -After $after -Bridge (New-Bridge))
    Assert-Equal 'StashGone' (Get-Kinds $f) '7: s1 is gone even though the COUNT is unchanged at two'
    Assert-True ($f[0].Detail -match 's1') '7: and the report names the entry that went'
    $f = @(Compare-WorkingCopySnapshot -Before (New-Snap -Stash @('s1')) -After (New-Snap -Stash @('s1', 's2')) -Bridge (New-Bridge))
    Assert-Equal 0 $f.Count '7: a stash that GREW is growth, and stays silent like any other'

    Write-Host ''
    Write-Host '8. Untracked files: a vanished one is caught, and it is never a WorktreeCleared' -ForegroundColor Cyan
    $f = @(Compare-WorkingCopySnapshot -Before (New-Snap -Entries @{ 'new.txt' = '??' }) -After (New-Snap) -Bridge (New-Bridge))
    Assert-Equal 'Vanished' (Get-Kinds $f) '8: a git clean removing an untracked file is a loss'
    # '?' is excluded from the worktree-half rule: an untracked path has no tracked half to clear, so a
    # transition out of '??' can only be a vanish (above) or a git add, which is growth in the index half.
    $f = @(Compare-WorkingCopySnapshot -Before (New-Snap -Entries @{ 'new.txt' = '??' }) -After (New-Snap -Entries @{ 'new.txt' = 'A ' }) -Bridge (New-Bridge))
    Assert-Equal 0 $f.Count '8: a git add on that file is not a loss'

    Write-Host ''
    Write-Host '8b. A RENAME inside the window is followed, not reported (false positive 5)' -ForegroundColor Cyan
    # The defect this pins: an ordinary `git mv` on a file that already carried an edit took the
    # baseline's key out of the list, and the comparison called the edit lost while it sat intact under
    # the new name. Measured on this lib before it shipped -- ' M' on a.txt, renamed, reported Vanished.
    $before = New-Snap -Entries @{ 'a.txt' = ' M' }
    $after  = New-Snap -Entries @{ 'b.txt' = 'RM' } -From @{ 'b.txt' = 'a.txt' }
    $f = @(Compare-WorkingCopySnapshot -Before $before -After $after -Bridge (New-Bridge))
    Assert-Equal 0 $f.Count '8b: a git mv is not a loss -- the edit moved with the file'
    # FOLLOWING IT IS NOT THE SAME AS EXEMPTING IT, and this is the case that proves the difference:
    # the rename happened AND then the worktree edit was discarded on the far side of it.
    $after2 = New-Snap -Entries @{ 'b.txt' = 'R ' } -From @{ 'b.txt' = 'a.txt' }
    $f = @(Compare-WorkingCopySnapshot -Before $before -After $after2 -Bridge (New-Bridge))
    Assert-Equal 'WorktreeCleared' (Get-Kinds $f) '8b: a loss ACROSS the rename is still caught -- an exemption would have hidden it'
    Assert-Equal 'b.txt' $f[0].Path '8b: reported under the name the file has now'
    Assert-True ($f[0].Detail -match "renamed from 'a\.txt'") '8b: and the detail names the old one, so the reader can find it'
    # THE MIRROR IMAGE: the baseline was taken with the rename already staged, and the window unstaged
    # it. The content is back under the old name, so nothing is lost -- and the KEY changed, which is
    # why the same-key arm cannot see this one.
    $before2 = New-Snap -Entries @{ 'b.txt' = 'R ' } -From @{ 'b.txt' = 'a.txt' }
    $after3  = New-Snap -Entries @{ 'a.txt' = ' M' }
    $f = @(Compare-WorkingCopySnapshot -Before $before2 -After $after3 -Bridge (New-Bridge))
    Assert-Equal 0 $f.Count '8b: and un-staging a rename is not a loss either'
    # An entry object with no From at all -- a hand-built one, or a baseline written before the pairing
    # existed -- must not take the comparison down under StrictMode.
    $legacy = [pscustomobject]@{ Head = 'aaaaaaa'; HeadKnown = $true; Branch = 'main'; BranchKnown = $true
                                 Entries = @{ 'a.txt' = [pscustomobject]@{ Index = ' '; Worktree = 'M' } }
                                 EntriesKnown = $true; Stash = @(); StashKnown = $true; TakenUtc = 'x' }
    $f = @(Compare-WorkingCopySnapshot -Before $legacy -After (New-Snap) -Bridge (New-Bridge))
    Assert-Equal 'Vanished' (Get-Kinds $f) '8b: an entry with no From field is read as "not a rename" rather than throwing'

    Write-Host ''
    Write-Host '9. The two refusals return INSTEAD of a comparison, never beside one' -ForegroundColor Cyan
    $before = New-Snap -Entries @{ 'a.txt' = ' M' } -Branch 'feat/x'
    $after  = New-Snap -Entries @{} -Branch 'main'
    $f = @(Compare-WorkingCopySnapshot -Before $before -After $after -Bridge (New-Bridge))
    Assert-Equal 'BranchChanged' (Get-Kinds $f) '9: a branch change reports that, and no Vanished computed across it'
    $f = @(Compare-WorkingCopySnapshot -Before (New-Snap -Entries @{ 'a.txt' = ' M' }) -After (New-Snap) -Bridge (New-Bridge -HistoryLinear $false))
    Assert-Equal 'HistoryRewritten' (Get-Kinds $f) '9: and a rewritten history the same -- a wrong list is worse than none'
    # A history that could not be established does NOT refuse: unknown is not the same as non-linear.
    $f = @(Compare-WorkingCopySnapshot -Before (New-Snap -Entries @{ 'a.txt' = ' M' }) -After (New-Snap) -Bridge (New-Bridge -HistoryLinear $false -HistoryKnown $false -CommittedPathsKnown $false))
    Assert-Equal 'Vanished' (Get-Kinds $f) '9: an UNKNOWN history still compares, hedged, rather than going silent'

    Write-Host ''
    Write-Host '10. A read that failed reports UNKNOWN, never a reassuring zero' -ForegroundColor Cyan
    $f = @(Compare-WorkingCopySnapshot -Before (New-Snap -Entries @{ 'a.txt' = ' M' } -EntriesKnown $false) -After (New-Snap) -Bridge (New-Bridge))
    Assert-Equal 'NotMeasured' (Get-Kinds $f) '10: an unreadable path list says so and compares nothing'
    $f = @(Compare-WorkingCopySnapshot -Before (New-Snap -Stash @('s1') -StashKnown $false) -After (New-Snap) -Bridge (New-Bridge))
    Assert-Equal 'NotMeasured' (Get-Kinds $f) '10: and an unreadable stash list likewise'

    Write-Host ''
    Write-Host '11. Format-WorkingCopyShrinkage -- what a reader actually sees' -ForegroundColor Cyan
    $lines = @(Format-WorkingCopyShrinkage -Findings @())
    Assert-Equal 1 $lines.Count '11: a clean run is one line'
    Assert-True ($lines[0].StartsWith('[OK]')) '11: and it is an [OK]'
    $lines = @(Format-WorkingCopyShrinkage -Findings (Compare-WorkingCopySnapshot -Before (New-Snap -Entries @{ 'a.txt' = ' M' }) -After (New-Snap) -Bridge (New-Bridge)))
    Assert-True ($lines[0].StartsWith('[ALARM]')) '11: a loss is an [ALARM]'
    Assert-True (($lines -join ' ') -match 'a\.txt') '11: and the path is named, unlike park-lib which is counts-only for a public commit'
    $lines = @(Format-WorkingCopyShrinkage -Findings (Compare-WorkingCopySnapshot -Before (New-Snap -Branch 'x') -After (New-Snap -Branch 'y') -Bridge (New-Bridge)))
    Assert-True ($lines[0].StartsWith('[INFO]')) '11: and a not-comparable outcome is an [INFO], not an alarm'

    Write-Host ''
    Write-Host '12. The baseline round-trips through JSON with BOTH status halves intact' -ForegroundColor Cyan
    $snap = New-Snap -Entries @{ 'a.txt' = 'MM'; 'b b.txt' = '??' } -Stash @('s1', 's2') -Head 'deadbeef' -Branch 'feat/x'
    $back = ConvertFrom-WorkingCopySnapshotJson -Json (ConvertTo-WorkingCopySnapshotJson -Snapshot $snap)
    Assert-True ($back.Entries -is [hashtable]) '12: Entries comes back as a hashtable, so ContainsKey works on a baseline read from disk'
    Assert-Equal 'M' $back.Entries['a.txt'].Index '12: the index half survives'
    Assert-Equal 'M' $back.Entries['a.txt'].Worktree '12: and the worktree half separately'
    Assert-True ($back.Entries.ContainsKey('b b.txt')) '12: a path with a space survives'
    Assert-Equal 'deadbeef' $back.Head '12: HEAD survives'
    Assert-Equal 'feat/x' $back.Branch '12: the branch survives'
    Assert-Equal 's1,s2' (@($back.Stash) -join ',') '12: and every stash id, in order'
    # The rename pairing has to survive the file too: a baseline read from disk is the commonest way
    # the comparison runs, so losing From here would restore the false alarm on exactly that path.
    $backR = ConvertFrom-WorkingCopySnapshotJson -Json (ConvertTo-WorkingCopySnapshotJson -Snapshot (New-Snap -Entries @{ 'b.txt' = 'RM' } -From @{ 'b.txt' = 'a.txt' }))
    Assert-Equal 'a.txt' $backR.Entries['b.txt'].From '12: a rename pairing survives the round trip'
    Assert-Equal '' $backR.Entries['b.txt'].From.Replace('a.txt', '') '12: and it is a plain string, not a wrapped object'
    $backN = ConvertFrom-WorkingCopySnapshotJson -Json (ConvertTo-WorkingCopySnapshotJson -Snapshot (New-Snap -Entries @{ 'a.txt' = ' M' }))
    Assert-Equal '' $backN.Entries['a.txt'].From '12: a non-rename round-trips as an empty From, not as null'
    # A single-entry stash must not arrive as a bare string: ConvertTo-Json unwraps a one-element array,
    # and a string would then compare character by character against the second snapshot's ids.
    $back1 = ConvertFrom-WorkingCopySnapshotJson -Json (ConvertTo-WorkingCopySnapshotJson -Snapshot (New-Snap -Stash @('only')))
    Assert-Equal 1 (@($back1.Stash).Count) '12: one stash entry is still an array of one'
    Assert-Equal 'only' (@($back1.Stash)[0]) '12: with its id, not its first character'
    # The empty snapshot is the other unwrap hazard: zero entries must not become $null.
    $back0 = ConvertFrom-WorkingCopySnapshotJson -Json (ConvertTo-WorkingCopySnapshotJson -Snapshot (New-Snap))
    Assert-Equal 0 (@($back0.Stash).Count) '12: and an empty stash is an empty array'
    Assert-Equal 0 $back0.Entries.Count '12: as is an empty entry list'

    Write-Host ''
    Write-Host '13. A baseline in an unknown format is REFUSED, not half-read' -ForegroundColor Cyan
    $threw = $false
    try { ConvertFrom-WorkingCopySnapshotJson -Json '{"Format":99,"Entries":[]}' | Out-Null } catch { $threw = $true }
    Assert-True $threw '13: a future format throws rather than reporting every path as lost'
    $threw = $false
    try { ConvertFrom-WorkingCopySnapshotJson -Json '{"Entries":[]}' | Out-Null } catch { $threw = $true }
    Assert-True $threw '13: and so does one with no format at all'

    # --- The git half: a real fixture, because what these two can get wrong is a PARSE ---------------
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null
    $repo = Join-Path $Fixture 'repo'
    New-Item -ItemType Directory -Path $repo -Force | Out-Null
    Invoke-FixtureGitIn $repo init -q
    Invoke-FixtureGitIn $repo config user.email 't@example.com'
    Invoke-FixtureGitIn $repo config user.name 'Test'
    Invoke-FixtureGitIn $repo symbolic-ref HEAD refs/heads/main
    Set-Content -LiteralPath (Join-Path $repo 'tracked.txt') -Value 'one' -Encoding ascii
    Set-Content -LiteralPath (Join-Path $repo 'other.txt') -Value 'one' -Encoding ascii
    Invoke-FixtureGitIn $repo add -A
    Invoke-FixtureGitIn $repo commit -q -m 'init'

    Write-Host ''
    Write-Host '14. Get-WorkingCopySnapshot parses git status into the two halves' -ForegroundColor Cyan
    Set-Content -LiteralPath (Join-Path $repo 'tracked.txt') -Value 'two' -Encoding ascii
    Set-Content -LiteralPath (Join-Path $repo 'untracked.txt') -Value 'new' -Encoding ascii
    Set-Content -LiteralPath (Join-Path $repo 'staged.txt') -Value 'new' -Encoding ascii
    Invoke-FixtureGitIn $repo add staged.txt
    $snap = Get-WorkingCopySnapshot -RepoRoot $repo
    Assert-True $snap.EntriesKnown '14: the path list was read'
    Assert-Equal ' ' $snap.Entries['tracked.txt'].Index '14: an unstaged edit has a clean index half'
    Assert-Equal 'M' $snap.Entries['tracked.txt'].Worktree '14: and an M in the worktree half'
    Assert-Equal 'A' $snap.Entries['staged.txt'].Index '14: a staged add lands in the index half'
    Assert-Equal '?' $snap.Entries['untracked.txt'].Worktree '14: and an untracked file reads as ??'
    Assert-True (-not $snap.Entries.ContainsKey('other.txt')) '14: an unchanged file is not listed at all'
    Assert-True $snap.HeadKnown '14: HEAD was read'
    Assert-Equal 'main' $snap.Branch '14: and the branch'
    Assert-True $snap.StashKnown '14: the stash list was read'
    Assert-Equal 0 (@($snap.Stash).Count) '14: and it is empty here'

    Write-Host ''
    Write-Host '15. A stash entry gets its own id, and a second one does not overwrite the first' -ForegroundColor Cyan
    Invoke-FixtureGitIn $repo stash push -q -u -m 'first'
    $s1 = Get-WorkingCopySnapshot -RepoRoot $repo
    Assert-Equal 1 (@($s1.Stash).Count) '15: one entry after the first push'
    Set-Content -LiteralPath (Join-Path $repo 'tracked.txt') -Value 'three' -Encoding ascii
    Invoke-FixtureGitIn $repo stash push -q -m 'second'
    $s2 = Get-WorkingCopySnapshot -RepoRoot $repo
    Assert-Equal 2 (@($s2.Stash).Count) '15: two after the second'
    Assert-True (@($s2.Stash)[0] -ne @($s2.Stash)[1]) '15: and the two ids differ, which is what makes a pop visible'

    Write-Host ''
    Write-Host '16. End to end: the #1665 command is REPORTED (exit 1, path named)' -ForegroundColor Cyan
    # Back to a clean-ish state, then reproduce exactly what #1665 measured: an uncommitted edit
    # belonging to the "orchestrator", discarded by a `git checkout HEAD --` it never asked for.
    Invoke-FixtureGitIn $repo stash clear
    Set-Content -LiteralPath (Join-Path $repo 'tracked.txt') -Value 'the orchestrator edit' -Encoding ascii
    $capture = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Capture -RootOverride $repo 2>&1
    $captureText = ($capture | Out-String)
    $baseline = ([regex]::Match($captureText, '-Compare "([^"]+)"')).Groups[1].Value
    Assert-True ($baseline -and (Test-Path -LiteralPath $baseline)) '16: -Capture wrote a baseline and printed its path'
    Assert-True ($baseline -match '[0-9a-f]{32}') '16: at an unpredictable path (New-ScratchPath, #1659)'

    Invoke-FixtureGitIn $repo checkout HEAD -- tracked.txt
    $compare = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Compare $baseline -RootOverride $repo 2>&1
    $code = $LASTEXITCODE
    $compareText = ($compare | Out-String)
    Assert-Equal 1 $code '16: exit 1 -- something shrank'
    Assert-True ($compareText -match '\[ALARM\]') '16: reported as an ALARM'
    Assert-True ($compareText -match 'tracked\.txt') '16: naming the file whose edit is gone'
    Assert-True ($compareText -match 'NOT recoverable') '16: and saying plainly that nothing can restore it'
    Assert-True (-not (Test-Path -LiteralPath $baseline)) '16: the spent baseline is removed'

    Write-Host ''
    Write-Host '17. End to end: the orchestrator committing its own work is NOT an alarm' -ForegroundColor Cyan
    Set-Content -LiteralPath (Join-Path $repo 'tracked.txt') -Value 'edit that will be committed' -Encoding ascii
    $capture = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Capture -RootOverride $repo 2>&1
    $baseline = ([regex]::Match((($capture | Out-String)), '-Compare "([^"]+)"')).Groups[1].Value
    Invoke-FixtureGitIn $repo add tracked.txt
    Invoke-FixtureGitIn $repo commit -q -m 'the orchestrator kept working'
    $compare = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Compare $baseline -RootOverride $repo 2>&1
    $code = $LASTEXITCODE
    $compareText = ($compare | Out-String)
    Assert-Equal 0 $code '17: exit 0 -- a commit is not a loss'
    Assert-True ($compareText -match '\[OK\]') '17: and it reads as clean'

    Write-Host ''
    Write-Host '18. The invocation itself is judged (exit 2), so a typo is not a clean bill of health' -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -RootOverride $repo *> $null
    Assert-Equal 2 $LASTEXITCODE '18: no mode at all is exit 2, not exit 0'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Capture -Compare 'x' -RootOverride $repo *> $null
    Assert-Equal 2 $LASTEXITCODE '18: both modes at once is refused rather than guessed at'
    # A WELL-SHAPED baseline that does not exist: refused by the existence check, not the confinement.
    $missing = New-ScratchPath -Label 'fanout-baseline' -Extension '.json'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Compare $missing -RootOverride $repo *> $null
    Assert-Equal 2 $LASTEXITCODE '18: a missing baseline is exit 2 -- a window with no beginning says nothing'

    Write-Host ''
    Write-Host '19. The -Compare path is CONFINED, because this step both reads and DELETES it' -ForegroundColor Cyan
    # A path outside the temp directory. Left as its own case because the two refusals it prevents are
    # different: a UNC path authenticates outbound before anything is validated, and a stale path
    # naming somebody else's live baseline would be deleted as spent.
    $outside = Join-Path $Fixture 'fanout-baseline-1-00000000000000000000000000000000.json'
    Set-Content -LiteralPath $outside -Value '{}' -Encoding ascii
    & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Compare $outside -RootOverride $repo *> $null
    Assert-Equal 2 $LASTEXITCODE '19: a correctly-named baseline OUTSIDE the temp directory is refused'
    Assert-True (Test-Path -LiteralPath $outside) '19: and it is still there -- a refused path is never deleted'
    # And the leaf shape, inside the temp directory: a file this script did not write.
    $wrongLeaf = New-ScratchPath -Label 'not-a-baseline' -Extension '.json'
    Set-Content -LiteralPath $wrongLeaf -Value '{}' -Encoding ascii
    try {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Compare $wrongLeaf -RootOverride $repo *> $null
        Assert-Equal 2 $LASTEXITCODE '19: a file in the temp directory that is not shaped like a baseline is refused'
        Assert-True (Test-Path -LiteralPath $wrongLeaf) '19: and survives, for the same reason'
    } finally { Remove-Item -LiteralPath $wrongLeaf -Force -ErrorAction SilentlyContinue }

    Write-Host ''
    Write-Host '20. End to end: a git mv during the window is not reported (false positive 5)' -ForegroundColor Cyan
    Set-Content -LiteralPath (Join-Path $repo 'tracked.txt') -Value 'an edit that will be renamed' -Encoding ascii
    $capture = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Capture -RootOverride $repo 2>&1
    $baseline = ([regex]::Match((($capture | Out-String)), '-Compare "([^"]+)"')).Groups[1].Value
    Invoke-FixtureGitIn $repo mv tracked.txt renamed.txt
    $compare = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Compare $baseline -RootOverride $repo 2>&1
    $code = $LASTEXITCODE
    Assert-Equal 0 $code '20: exit 0 -- the edit moved with the file rather than being lost'
    Assert-True ((($compare | Out-String)) -match '\[OK\]') '20: and it reads as clean'

    Write-Host ''
    Write-Host '21. A FAILED read is exit 3 and KEEPS the baseline -- never exit 0 (Victor, #1670 review)' -ForegroundColor Cyan
    # The most likely read failure in this script's own scenario is a `git status` losing a race for
    # .git/index.lock while dispatched agents run git in the same checkout. A directory that is not a
    # repo at all reproduces the same state deterministically: every read fails, so nothing can be
    # compared. It used to exit 0 and delete the baseline, destroying the one artefact a retry needs.
    Set-Content -LiteralPath (Join-Path $repo 'renamed.txt') -Value 'another edit' -Encoding ascii
    $capture = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Capture -RootOverride $repo 2>&1
    $baseline = ([regex]::Match((($capture | Out-String)), '-Compare "([^"]+)"')).Groups[1].Value
    $notARepo = Join-Path $Fixture 'not-a-repo'
    New-Item -ItemType Directory -Path $notARepo -Force | Out-Null
    try {
        $compare = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Compare $baseline -RootOverride $notARepo 2>&1
        $code = $LASTEXITCODE
        $compareText = ($compare | Out-String)
        Assert-Equal 3 $code '21: exit 3 -- unknown, which is a different answer from exit 0'
        Assert-True ($compareText -match 'not measured') '21: and the report says so rather than printing an [OK]'
        Assert-True ($compareText -notmatch '\[OK\]') '21: no clean bill of health is printed'
        Assert-True (Test-Path -LiteralPath $baseline) '21: the baseline is KEPT -- nothing was compared against it, so a retry can still use it'
    } finally { Remove-Item -LiteralPath $baseline -Force -ErrorAction SilentlyContinue }
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

$fixtureBroken = Write-FixtureGitSummary -Subject 'fanout-lib.ps1 / check-fanout.ps1'

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0 -or $fixtureBroken) { exit 1 }
exit 0
