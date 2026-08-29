<#
.SYNOPSIS
    Regression tests for scripts/lib/worktree-lib.ps1 -- the porcelain reader behind ship-pr.ps1's
    trunk-lock pre-flight (issue #1069), its trunk hand-back before the CI wait (issue #1073), and
    prune-merged.ps1's error message.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Every function in the lib is pure -- it takes
    the lines `git worktree list --porcelain` produced and returns strings -- so the whole suite runs
    in-process against dot-sourced fixtures. No git, no repository, no temp directory.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/worktree-lib.tests.ps1

    THAT PURITY IS THE REASON THE LIB EXISTS, and it is worth saying here rather than only in the lib.
    ship-pr.ps1 drives live git and gh against a real remote and carries no suite of its own; its own
    header asks for exactly this ("anything in here that is a pure function of text belongs in a lib,
    precisely because this file cannot be tested"). The decision the #1069 repair turns on -- does
    another worktree hold the trunk? -- is that pure function, so it is asserted here instead of being
    exercised only by a full live ship whose failure mode is a merged-but-unfolded PR.

    What is asserted:
      1. the porcelain parses into one record per stanza, with the branch stored SHORT ('main', not
         'refs/heads/main') and the detached/bare markers read;
      2. a stanza closes on the next `worktree` line rather than on the blank line between stanzas --
         the case that matters because captured output is routinely trimmed;
      3. Get-PrimaryWorktreePath returns the FIRST stanza, which is the only thing in the output that
         identifies the main worktree;
      4. Get-WorktreeHoldingBranch finds another tree holding the trunk, and -- the case that would
         otherwise refuse every ordinary run -- does NOT report the caller's own tree as the holder;
      5. the path comparison survives the three ways two spellings of one Windows directory differ:
         separator, case, and a trailing separator;
      6. the empty and malformed inputs answer rather than throw, since every caller reaches this lib
         with whatever git actually printed;
      7. Get-TrunkReturnDecision answers all three of its conditions (issue #1073): the primary
         checkout only, nobody else holding the trunk, and a clean tree -- and answers rather than
         throwing on everything git might hand over, because step 2b is not a gate and a decision it
         cannot make must leave the ship running.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $RepoRoot 'scripts\lib\worktree-lib.ps1')

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

function Assert-Equal {
    param([string]$Expected, [string]$Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        Write-Host "         expected: '$Expected'" -ForegroundColor DarkGray
        Write-Host "         actual:   '$Actual'" -ForegroundColor DarkGray
    }
}

# The real thing, captured on this machine the day #1069 was filed: a primary checkout on a branch, and
# a lane standing on main because its own ship-pr left it there. Forward slashes, because that is how
# git spells a Windows path in this output.
$PorcelainTwoTrees = @(
    'worktree C:/Users/dave/Documents/GitHub/DaveKJohn/claude-code-specialists',
    'HEAD 926bd0cabf0f9d8e4e3f2a1b0c9d8e7f6a5b4c3d',
    'branch refs/heads/fix/a-lane-must-not-hold-the-trunk-hostage-v1',
    '',
    'worktree C:/Users/dave/Documents/GitHub/DaveKJohn/claude-code-specialists-lanes/feat--thumbnail',
    'HEAD 3fd2905a1122334455667788990011aabbccddee',
    'branch refs/heads/main',
    ''
)
$PrimaryPath = 'C:/Users/dave/Documents/GitHub/DaveKJohn/claude-code-specialists'
$LanePath    = 'C:/Users/dave/Documents/GitHub/DaveKJohn/claude-code-specialists-lanes/feat--thumbnail'

Write-Host ""
Write-Host "1. Get-WorktreeRecords -- the stanzas" -ForegroundColor Cyan

$records = Get-WorktreeRecords -PorcelainLines $PorcelainTwoTrees
Assert-Equal '2' "$($records.Count)" 'two stanzas produce two records'
Assert-Equal $PrimaryPath $records[0].Path 'the first record carries the primary path'
Assert-Equal 'fix/a-lane-must-not-hold-the-trunk-hostage-v1' $records[0].Branch `
    "the branch is stored SHORT -- 'refs/heads/' is stripped once, in the parser"
Assert-Equal 'main' $records[1].Branch 'the lane record carries the trunk'
Assert-True (-not $records[0].Detached) 'an attached stanza is not detached'
Assert-True (-not $records[0].Bare) 'an attached stanza is not bare'

# A LANE OPENED BY worktree-lane.ps1 IS DETACHED at origin/<trunk> until its branch is created, so this
# shape is the normal one rather than an edge case -- and a detached stanza must not answer as holding
# any branch at all.
$PorcelainDetached = @(
    'worktree C:/repo',
    'HEAD aaaa',
    'branch refs/heads/main',
    '',
    'worktree C:/repo-lanes/fresh',
    'HEAD bbbb',
    'detached',
    ''
)
$detachedRecords = Get-WorktreeRecords -PorcelainLines $PorcelainDetached
Assert-True $detachedRecords[1].Detached 'a detached stanza is read as detached'
Assert-Equal '' $detachedRecords[1].Branch 'a detached stanza holds no branch'

$bareRecords = Get-WorktreeRecords -PorcelainLines @('worktree C:/repo.git', 'bare')
Assert-True $bareRecords[0].Bare 'a bare stanza is read as bare'

# THE BLANK LINE IS NOT THE DELIMITER, and this assert is why. Invoke-NativeCapture's callers routinely
# trim and filter captured output, so a parser that split on blank lines would fold two worktrees into
# one exactly where the answer matters -- and would report the trunk as unheld.
$noBlanks = @($PorcelainTwoTrees | Where-Object { $_ })
$trimmedRecords = Get-WorktreeRecords -PorcelainLines $noBlanks
Assert-Equal '2' "$($trimmedRecords.Count)" 'stanzas separate on the `worktree` line, not on the blank line'
Assert-Equal 'main' $trimmedRecords[1].Branch 'the second stanza is intact without its blank line'

Write-Host ""
Write-Host "2. Get-PrimaryWorktreePath -- git lists the main worktree first" -ForegroundColor Cyan

Assert-Equal $PrimaryPath (Get-PrimaryWorktreePath -PorcelainLines $PorcelainTwoTrees) `
    'the primary is the FIRST stanza, which is the only thing that identifies it'
Assert-Equal '' (Get-PrimaryWorktreePath -PorcelainLines @()) 'no stanzas answers empty rather than throwing'

Write-Host ""
Write-Host "3. Get-WorktreeHoldingBranch -- the question ship-pr asks before it merges" -ForegroundColor Cyan

Assert-Equal $LanePath (Get-WorktreeHoldingBranch -PorcelainLines $PorcelainTwoTrees -Branch 'main' -SelfPath $PrimaryPath) `
    'a lane standing on the trunk is named, so the refusal can print a directory'
Assert-Equal '' (Get-WorktreeHoldingBranch -PorcelainLines $PorcelainTwoTrees -Branch 'main' -SelfPath $LanePath) `
    'the tree asking the question is never its own blocker'

# THE CASE THAT WOULD BREAK EVERY ORDINARY RUN. A single checkout already standing on main is the state
# ship-pr's step 5 deliberately leaves the primary in, so a pre-flight that reported it as held would
# refuse the next chain in the one repo shape that has no lanes at all.
$PorcelainSingleOnTrunk = @('worktree C:/repo', 'HEAD aaaa', 'branch refs/heads/main', '')
Assert-Equal '' (Get-WorktreeHoldingBranch -PorcelainLines $PorcelainSingleOnTrunk -Branch 'main' -SelfPath 'C:/repo') `
    'a lone checkout on the trunk does not report itself'
Assert-Equal '' (Get-WorktreeHoldingBranch -PorcelainLines $PorcelainTwoTrees -Branch 'docs/nobody' -SelfPath $PrimaryPath) `
    'a branch no worktree holds answers empty'

Write-Host ""
Write-Host "4. Get-WorktreePathKey -- the three ways one Windows directory has two spellings" -ForegroundColor Cyan

Assert-Equal (Get-WorktreePathKey 'C:/repo/lane') (Get-WorktreePathKey 'C:\repo\lane') `
    'separator: git prints forward slashes, PowerShell composes back slashes'
Assert-Equal (Get-WorktreePathKey 'C:\Repo\Lane') (Get-WorktreePathKey 'c:\repo\lane') `
    'case: NTFS is case-insensitive, so two spellings are one directory'
Assert-Equal (Get-WorktreePathKey 'C:\repo\lane\') (Get-WorktreePathKey 'C:\repo\lane') `
    'a trailing separator, which Join-Path and a typed path disagree about'
Assert-Equal '' (Get-WorktreePathKey '') 'an empty path answers empty rather than throwing'

# Proof that the key is actually WIRED INTO the lookup, not merely available beside it: the self-path is
# handed in with every one of the three differences at once, and the tree must still recognise itself.
Assert-Equal '' (Get-WorktreeHoldingBranch -PorcelainLines $PorcelainSingleOnTrunk -Branch 'main' -SelfPath 'c:\REPO\') `
    'the self-comparison goes through the key, not through -eq'
Write-Host ""
Write-Host "5. Input git might actually hand over" -ForegroundColor Cyan

Assert-Equal '0' "$((Get-WorktreeRecords -PorcelainLines @()).Count)" 'no lines produce no records'
Assert-Equal '0' "$((Get-WorktreeRecords -PorcelainLines $null).Count)" 'a null input produces no records'
# A `branch` line before any `worktree` line cannot happen in git's output, which is exactly why it is
# asserted: every caller here reaches this lib with whatever a failing or future git printed, and a
# parser that dereferenced $current would throw at the one moment the caller is trying to report a
# problem.
Assert-Equal '0' "$((Get-WorktreeRecords -PorcelainLines @('branch refs/heads/main', 'HEAD aaaa')).Count)" `
    'lines before the first stanza are ignored rather than throwing'
Assert-Equal '' (Get-WorktreeHoldingBranch -PorcelainLines @('garbage') -Branch 'main' -SelfPath 'C:/repo') `
    'unparseable output answers "nobody holds it" rather than throwing'


Write-Host ""
Write-Host "6. Get-TrunkReturnDecision -- may this tree go home while the ship runs? (issue #1073)" -ForegroundColor Cyan

# THE ORDINARY RUN: the primary checkout stands on its shipping branch, no lane holds the trunk, and the
# tree is clean. This is the case the whole repair exists for -- without it the close-out has to choose
# between "parking is a state" and "it ends on the trunk", and #1073 measured what choosing costs.
$PorcelainPrimaryOnBranch = @(
    'worktree C:/repo',
    'HEAD aaaa',
    'branch refs/heads/fix/something-v1',
    ''
)
Assert-True (Get-TrunkReturnDecision -PorcelainLines $PorcelainPrimaryOnBranch -SelfPath 'C:/repo' -TrunkBranch 'main' -StatusLines @()).Return `
    'the primary checkout on a clean tree goes back to the trunk'
Assert-Equal '' (Get-TrunkReturnDecision -PorcelainLines $PorcelainPrimaryOnBranch -SelfPath 'C:/repo' -TrunkBranch 'main' -StatusLines @()).Reason `
    'a yes carries no reason -- there is nothing for the reader to be told'

# A LANE MUST NOT TAKE THE TRUNK HERE, and this is the assert that keeps #1069 closed. Step 5b hands a
# lane back to its own branch AFTER the fold; a lane taking the trunk at step 2b would hold the
# clone-wide lock for the whole CI wait instead of for the length of a fold -- strictly worse than the
# defect #1069 repaired, introduced by the repair for #1073.
$decLane = Get-TrunkReturnDecision -PorcelainLines $PorcelainTwoTrees -SelfPath $LanePath -TrunkBranch 'main' -StatusLines @()
Assert-True (-not $decLane.Return) 'a lane does not take the trunk at step 2b'
Assert-True ($decLane.Reason -like '*not the primary checkout*') 'and the reason names the primary checkout'
Assert-True ($decLane.Reason -like "*$PrimaryPath*") 'and names the directory, so the reader can go there'

# SOMEBODY ELSE HOLDS THE TRUNK: git would refuse the checkout anyway, so this is asked rather than
# attempted. $PorcelainTwoTrees is the lane-on-main capture, seen from the primary this time.
$decHeld = Get-TrunkReturnDecision -PorcelainLines $PorcelainTwoTrees -SelfPath $PrimaryPath -TrunkBranch 'main' -StatusLines @()
Assert-True (-not $decHeld.Return) 'the trunk held by another worktree is not taken from it'
Assert-True ($decHeld.Reason -like "*$LanePath*") 'and the holder is named'

# A DIRTY TREE IS #972'S TWO OUTCOMES MET ONE STEP EARLIER: a colliding edit makes the checkout exit 1,
# and a non-colliding one TRAVELS TO THE TRUNK. The branch's own work is committed and pushed by step 1,
# so anything here is something else -- and something else is what must not ride along.
$decDirty = Get-TrunkReturnDecision -PorcelainLines $PorcelainPrimaryOnBranch -SelfPath 'C:/repo' -TrunkBranch 'main' -StatusLines @(' M scripts/lib/worktree-lib.ps1')
Assert-True (-not $decDirty.Return) 'a modified file keeps the tree where it is'
Assert-True ($decDirty.Reason -like '*not clean*') 'and the reason says so'
# UNTRACKED COUNTS AS DIRTY ON PURPOSE: `git checkout main` carries an untracked file across too, which
# is the silent half of #972's second outcome.
Assert-True (-not (Get-TrunkReturnDecision -PorcelainLines $PorcelainPrimaryOnBranch -SelfPath 'C:/repo' -TrunkBranch 'main' -StatusLines @('?? notes.txt')).Return) `
    'an untracked file counts as dirty'
# Blank lines are not dirt. Invoke-NativeCapture's callers trim, and an empty capture can arrive as a
# single empty string rather than as no elements at all.
Assert-True (Get-TrunkReturnDecision -PorcelainLines $PorcelainPrimaryOnBranch -SelfPath 'C:/repo' -TrunkBranch 'main' -StatusLines @('', '   ')).Return `
    'blank status lines are not treated as changes'

# ALREADY ON THE TRUNK: the tree is the primary, holds main itself, and Get-WorktreeHoldingBranch
# excludes it -- so the answer is yes and step 2b's checkout is the no-op it should be. Asserted because
# the opposite (a tree reporting itself as its own blocker) is exactly the bug -SelfPath exists for.
Assert-True (Get-TrunkReturnDecision -PorcelainLines $PorcelainSingleOnTrunk -SelfPath 'C:/repo' -TrunkBranch 'main' -StatusLines @()).Return `
    'a tree already on the trunk does not report itself as the blocker'

# WHAT GIT MIGHT ACTUALLY HAND OVER. Every one of these answers instead of throwing, because step 2b is
# not a gate: a decision it cannot make must leave the ship running, never stop it.
$decEmpty = Get-TrunkReturnDecision -PorcelainLines @() -SelfPath 'C:/repo' -TrunkBranch 'main' -StatusLines @()
Assert-True (-not $decEmpty.Return) 'an empty porcelain answers no'
Assert-True ($decEmpty.Reason -like '*no primary checkout*') 'and says the list named no primary checkout'
Assert-True (-not (Get-TrunkReturnDecision -PorcelainLines $PorcelainPrimaryOnBranch -SelfPath '' -TrunkBranch 'main' -StatusLines @()).Return) `
    'an unreadable self path answers no'
Assert-True (-not (Get-TrunkReturnDecision -PorcelainLines @('garbage') -SelfPath 'C:/repo' -TrunkBranch 'main' -StatusLines @()).Return) `
    'unparseable output answers no rather than throwing'
# THE TRUNK IS A PARAMETER, NOT 'main': a consumer whose trunk is 'master' or 'trunk' gets the same
# three conditions. ship-pr passes 'main' because that is this repo's trunk, not because the lib knows it.
$PorcelainMasterLane = @(
    'worktree C:/repo', 'HEAD aaaa', 'branch refs/heads/fix/x', '',
    'worktree C:/lane', 'HEAD bbbb', 'branch refs/heads/master', ''
)
Assert-True (-not (Get-TrunkReturnDecision -PorcelainLines $PorcelainMasterLane -SelfPath 'C:/repo' -TrunkBranch 'master' -StatusLines @()).Return) `
    'the trunk name is the caller''s, not hardcoded'
Assert-True (Get-TrunkReturnDecision -PorcelainLines $PorcelainMasterLane -SelfPath 'C:/repo' -TrunkBranch 'main' -StatusLines @()).Return `
    'and a lane on master does not block a repo whose trunk is main'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
