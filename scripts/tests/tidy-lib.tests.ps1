<#
.SYNOPSIS
    Tests for scripts/lib/tidy-lib.ps1 and the structural promises of scripts/maintenance/tidy-machine.ps1.

.DESCRIPTION
    WHY THIS SUITE EXISTS, AND WHY ALMOST ALL OF IT IS PURE. tidy-machine.ps1 is a conductor: six of
    its ten lanes are a call into a script that already has its own suite, so testing those again here
    would be testing prune-merged, check-claude-home and plugin-versions a second time. What is NEW is
    the classification -- and that is exactly the part that is pure, takes every input as a parameter,
    and can therefore be driven over states this machine has never been in.

    THE ASSERTS THAT MATTER MOST ARE THE ONES ABOUT WHAT IS *NOT* PROVEN. This lib introduces a second
    proof (a CLOSED, unmerged pull request) into a workflow where a wrong proof has already cost twice:
    inbound #1190 and #1191, where a name-only match let a recycled branch name inherit an earlier PR's
    verdict and a live branch was force-deleted while the output printed the word "merged" at it. So
    the pair test is asserted in both directions, and the missing-lookup case is asserted to fall back
    to doing nothing rather than to doing something.

    AND THREE STRUCTURAL ASSERTS, each pinning a promise the header makes in prose. A promise nobody
    can break by accident is worth more than a promise nobody has broken yet:

      - no `--delete` argument anywhere in the script, in quotes of either kind -- the same assert
        prune-merged.tests.ps1 carries, for the same reason;
      - no call that could close, merge or reopen a pull request;
      - nothing that deletes under the scratch root, and no -ReapScratch parameter. That lane was
        drafted with one and it was removed rather than defended: scripts/README.md had already decided
        those trees stay standing (#1668), and named a sweep by name pattern as the delete primitive
        New-ScratchPath exists to remove (#1659). A decision that lives only in prose is one draft away
        from being made again, so it is pinned here.

    Dependency-free: no Pester, only PowerShell. Exit 0 if everything passes, 1 on a failure.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\maintenance\tidy-machine.ps1'

# tidy-lib depends on both of the first two: the pair test comes from merged-pr-lib, and the display
# class Format-PasteablePathToken refuses on is ASKED of ref-print-lib's Get-DisplayPath rather than
# re-typed here -- pr-issues.tests.ps1 pins that exactly two libs may type it, and an earlier draft of
# this lib was the third.
. (Join-Path $RepoRoot 'scripts\lib\merged-pr-lib.ps1')
. (Join-Path $RepoRoot 'scripts\lib\ref-print-lib.ps1')
. (Join-Path $RepoRoot 'scripts\lib\worktree-lib.ps1')
. (Join-Path $RepoRoot 'scripts\lib\tidy-lib.ps1')

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}

# Two lookups in the shape Get-MergedPrTips returns. 40-hex object names, because the lib validates the
# shape and a short sha would be dropped -- which would make a passing test prove nothing.
$TipA = 'a' * 40
$TipB = 'b' * 40
$TipC = 'c' * 40
$Merged = Get-MergedPrTips -Pairs @(
    [pscustomobject]@{ Name = 'feat/landed';   Tip = $TipA }
    [pscustomobject]@{ Name = 'feat/recycled'; Tip = $TipB }
)
$Closed = Get-ClosedPrTips -Pairs @(
    [pscustomobject]@{ Name = 'fix/abandoned';      Tip = $TipA }
    [pscustomobject]@{ Name = 'fix/closed-recycled'; Tip = $TipB }
)

# --- 1. The proof ladder, strongest first ---------------------------------------------------------
Write-Host '-- 1. the proof ladder --' -ForegroundColor Cyan

$r = Get-BranchTidyClass -Name 'anything' -Tip $TipC -IsAncestorOfTrunk $true -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'reapable' $r.Class 'an ancestor of the trunk is reapable, whatever the trackers say'

$r = Get-BranchTidyClass -Name 'feat/landed' -Tip $TipA -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'reapable' $r.Class 'a tip that is a merged PR head is reapable'

$r = Get-BranchTidyClass -Name 'fix/abandoned' -Tip $TipA -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'abandoned' $r.Class 'a tip that is a CLOSED unmerged PR head is abandoned'

$r = Get-BranchTidyClass -Name 'docs/never-heard-of-it' -Tip $TipC -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'live' $r.Class 'a branch no lookup knows is live'

# --- 2. The pair test, in both directions (inbound #1190/#1191) -----------------------------------
Write-Host '-- 2. name AND tip, never the name alone --' -ForegroundColor Cyan

$r = Get-BranchTidyClass -Name 'feat/recycled' -Tip $TipC -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'recycled' $r.Class 'a MERGED name carrying a different tip is recycled, not reapable'

$r = Get-BranchTidyClass -Name 'fix/closed-recycled' -Tip $TipC -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'recycled' $r.Class 'a CLOSED name carrying a different tip is recycled, not abandoned'
Assert-True ($r.Reason -like '*closed PR used this name*') 'and the reason says which lookup came up full'

$r = Get-BranchTidyClass -Name 'fix/abandoned' -Tip '' -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'recycled' $r.Class 'an UNREADABLE tip is never a proof -- it lands on recycled, not abandoned'

$r = Get-BranchTidyClass -Name 'fix/abandoned' -Tip $TipA -MergedTips $Merged -ClosedTips $null
Assert-Equal 'live' $r.Class 'with no closed-PR lookup at all, nothing is ever classified abandoned'

# --- 3. Nothing that acts is proposed without a proof ---------------------------------------------
Write-Host '-- 3. only a proven class carries a verb --' -ForegroundColor Cyan

foreach ($case in @(
    @{ N = 'feat/landed';         T = $TipA; Want = 'reapable' }
    @{ N = 'feat/recycled';       T = $TipC; Want = 'recycled' }
    @{ N = 'docs/never-heard-of-it'; T = $TipC; Want = 'live' }
)) {
    $r = Get-BranchTidyClass -Name $case.N -Tip $case.T -MergedTips $Merged -ClosedTips $Closed
    Assert-Equal '' $r.Command "$($case.Want) proposes no command"
}

# THE VERB ONLY. A finished command line leaving the lib would be one that skipped the paste guard at
# whatever call site printed it -- the whole reason the lib composes none (#1594, #1617, #1762).
$r = Get-BranchTidyClass -Name 'fix/abandoned' -Tip $TipA -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'git branch -D' $r.Command 'abandoned carries the VERB'
Assert-True ($r.Command -notlike '*fix/abandoned*') 'and the branch name is NOT interpolated into it'

# --- 4. The age bound applies to backup/ and to nothing else --------------------------------------
Write-Host '-- 4. the age bound --' -ForegroundColor Cyan

$r = Get-BranchTidyClass -Name 'backup/main-pre-sync' -Tip $TipC -AgeDays 30 -MaxAgeDays 14 -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'expired-backup' $r.Class 'a backup/ branch past the bound is expired'
Assert-True ($r.Reason -like '*NOT an ancestor*') 'and the reason says it holds commits nothing else has'

$r = Get-BranchTidyClass -Name 'backup/main-pre-sync' -Tip $TipC -AgeDays 3 -MaxAgeDays 14 -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'live' $r.Class 'a backup/ branch inside the bound is left alone'

$r = Get-BranchTidyClass -Name 'feat/old-but-mine' -Tip $TipC -AgeDays 300 -MaxAgeDays 14 -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'live' $r.Class 'age alone never condemns a branch that is not a backup'

$r = Get-BranchTidyClass -Name 'backup/unknown-age' -Tip $TipC -AgeDays -1 -MaxAgeDays 14 -MergedTips $Merged -ClosedTips $Closed
Assert-Equal 'live' $r.Class 'an unknown age never expires anything'

# --- 5. Stale lanes ------------------------------------------------------------------------------
Write-Host '-- 5. stale lanes --' -ForegroundColor Cyan

$classes = @(
    (Get-BranchTidyClass -Name 'feat/landed'   -Tip $TipA -MergedTips $Merged -ClosedTips $Closed)
    (Get-BranchTidyClass -Name 'fix/abandoned' -Tip $TipA -MergedTips $Merged -ClosedTips $Closed)
    (Get-BranchTidyClass -Name 'feat/busy'     -Tip $TipC -MergedTips $Merged -ClosedTips $Closed)
)
$records = Get-WorktreeRecords -PorcelainLines @(
    'worktree C:\repo', 'branch refs/heads/feat/landed', '',
    'worktree C:\lanes\one', 'branch refs/heads/fix/abandoned', '',
    'worktree C:\lanes\two', 'branch refs/heads/feat/busy', '',
    'worktree C:\lanes\three', 'detached', ''
)
$lanes = @(Get-StaleLaneDecisions -WorktreeRecords $records -BranchClasses $classes)
Assert-Equal 1 $lanes.Count 'exactly one lane is stale'
Assert-Equal 'fix/abandoned' $lanes[0].Branch 'and it is the abandoned one'
Assert-True ($lanes[0].Command -notlike '*C:\lanes*') 'the hand-back verb does not carry the path either'

# THE PRIMARY IS NEVER A LANE, even standing on a finished branch. git lists it first and that IS the
# definition; removing it is deleting the checkout, not tidying it.
Assert-True (-not ($lanes | Where-Object { $_.Path -eq 'C:\repo' })) 'the primary worktree is never reported'

# --- 6. Orphaned install records ------------------------------------------------------------------
Write-Host '-- 6. orphaned install records --' -ForegroundColor Cyan

$recs = @(
    [pscustomobject]@{ Plugin = 'p-here';    ProjectPath = 'C:\here' }
    [pscustomobject]@{ Plugin = 'p-gone';    ProjectPath = 'C:\gone' }
    [pscustomobject]@{ Plugin = 'p-unknown'; ProjectPath = 'D:\unmounted' }
)
$orphans = @(Get-OrphanInstallRecords -Records $recs -PathExists @{ 'C:\here' = $true; 'C:\gone' = $false })
Assert-Equal 1 $orphans.Count 'only the record whose path is proven gone is an orphan'
Assert-Equal 'C:\gone' $orphans[0].ProjectPath 'and it is the right one'

# A PATH THE CALLER DID NOT PROBE IS SILENCE, NOT A FINDING. An unmounted drive is the false positive
# to beat here, and a wrong claim about somebody's disk is worse than saying nothing.
Assert-True (-not ($orphans | Where-Object { $_.ProjectPath -eq 'D:\unmounted' })) 'an unprobed path is never reported'

# --- 7. The path formatter (issue #1762) ----------------------------------------------------------
Write-Host '-- 7. paste-safe paths --' -ForegroundColor Cyan

$t = Format-PasteablePathToken -Path 'C:\Users\x\repo-lanes\feat--thing'
Assert-True $t.IsSafe 'an ordinary absolute Windows path is safe -- the shared ref allowlist refuses all of these'
Assert-Equal "'C:\Users\x\repo-lanes\feat--thing'" $t.Token 'and it comes back single-quoted, which is literal in PowerShell'

$t = Format-PasteablePathToken -Path "C:\it's\here"
Assert-Equal "'C:\it''s\here'" $t.Token "an embedded single quote is doubled, the only escape the literal form has"

# A '$(...)' inside a SINGLE-quoted PowerShell string is characters, not syntax. That is the whole
# argument for this formatter over a double-quoted interpolation, which ref-print-lib's header calls
# out by name as reading like a guard while being none.
$t = Format-PasteablePathToken -Path 'C:\tmp\$(whoami).txt'
Assert-True $t.IsSafe 'a shell metacharacter is inert inside the literal form, so it is not refused'
Assert-Equal "'C:\tmp\`$(whoami).txt'" $t.Token 'and it survives verbatim, so the command targets the real file'

$t = Format-PasteablePathToken -Path "C:\tmp\one$([char]0x202E)two"
Assert-True (-not $t.IsSafe) 'a path that would repaint the terminal IS refused -- quoting cannot fix reading'
Assert-True ($t.Note -like '*control or format characters*') 'and the note says why'

$t = Format-PasteablePathToken -Path ''
Assert-True (-not $t.IsSafe) 'an empty path is refused rather than printing a hole in a command'

# --- 8. Scratch attribution -----------------------------------------------------------------------
Write-Host '-- 8. scratch attribution --' -ForegroundColor Cyan

# A CONSTANT, NOT A FRESH GUID, AND NOT NAMED ONE EITHER. This is the hex tail of a NAME being
# classified -- a string this suite reads, never a path it writes -- so the fixture rule's reason
# (an unpredictable directory nobody can pre-plant at) does not apply. Named $leafHex rather than
# $guid so the neighbouring scan is not asked to tell those two apart by intent.
$leafHex = '0' * 32
Assert-Equal 'not-ours'  (Get-ScratchLeftoverVerdict -Name 'some-unrelated-folder' -LivePids @(1)) 'a name that is not New-ScratchPath''s shape is not ours'
Assert-Equal 'retained'  (Get-ScratchLeftoverVerdict -Name "sync-pr-body-4242-$leafHex" -LivePids @() -AgeHours 999) 'sync-pr-body is retained on purpose (#1668), never a leftover'
Assert-Equal 'retained'  (Get-ScratchLeftoverVerdict -Name "test-suite-gate-4242-$leafHex" -LivePids @() -AgeHours 999) 'the gate''s capture directories are retained on purpose (#1636)'
Assert-Equal 'live'      (Get-ScratchLeftoverVerdict -Name "native-capture-777-$leafHex" -LivePids @(777) -AgeHours 999) 'a tree whose pid is running belongs to a live suite'
Assert-Equal 'live'      (Get-ScratchLeftoverVerdict -Name "native-capture-778-$leafHex" -LivePids @() -AgeHours 1) 'a young tree is live even with no matching pid -- the pid-reuse belt'
Assert-Equal 'leftover'  (Get-ScratchLeftoverVerdict -Name "native-capture-779-$leafHex" -LivePids @() -AgeHours 999) 'an old tree whose pid is gone is attributable to a run that ended'

# --- 9. The summary line --------------------------------------------------------------------------
Write-Host '-- 9. the summary line --' -ForegroundColor Cyan
Assert-Equal 'Lanes -- nothing found.' (Get-TidySummaryLine -Lane 'Lanes') 'an empty lane says so in words, not as three zeroes'
Assert-Equal 'Lanes -- 1 acted on, 2 handed over, 3 left alone, of 6.' (Get-TidySummaryLine -Lane 'Lanes' -Acted 1 -Reported 2 -Untouched 3) 'and a populated one tallies'

# --- 10. The structural promises ------------------------------------------------------------------
Write-Host '-- 10. what the script may never contain --' -ForegroundColor Cyan

$src = [System.IO.File]::ReadAllText($Script, [Text.Encoding]::UTF8)

# Comments carry the words 'delete' and 'remote' constantly -- the header is largely ABOUT not deleting
# -- so the scan is over code lines only, with the comment tail of each stripped.
$code = @($src -split '\r?\n' | ForEach-Object { ($_ -replace '#.*$', '') } | Where-Object { $_.Trim() })
$codeText = ($code -join "`n")

Assert-True ($codeText -notmatch "'--delete'") 'no --delete argument, in single quotes'
Assert-True ($codeText -notmatch '"--delete"') 'no --delete argument, in double quotes'
Assert-True ($codeText -notmatch "'push'")     'no git push'
Assert-True ($codeText -notmatch "'merge'")    'no gh pr merge'
Assert-True ($codeText -notmatch "'close'")    'no gh pr close'
Assert-True ($codeText -notmatch 'Remove-Item') 'nothing in this script removes anything from disk'
Assert-True ($codeText -notmatch 'ReapScratch') 'and the scratch-sweep flag does not exist (#1659/#1668)'

# The two gh calls it DOES make are both reads, and the closed one must carry the server-side filter:
# without it the limit is spent on merged PRs and the abandoned lane silently finds nothing, which is
# what the first real run of this script did.
Assert-True ($codeText -match "'is:unmerged'") 'the closed-PR lookup filters unmerged ON THE SERVER'
Assert-True ($codeText -match "'--state', 'merged'") 'and the merged lookup is its own call'

Write-Host ''
Write-Host "tidy-lib.tests: $script:pass passed, $script:fail failed." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
