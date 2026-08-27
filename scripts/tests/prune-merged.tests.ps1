<#
.SYNOPSIS
    Regression tests for scripts/task/prune-merged.ps1 (fast-forward the trunk, prune stale
    remote-tracking refs, delete only the local branches whose merge can be proven).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Integration style -- runs the REAL script
    (copied into a throwaway temp git repo with a bare 'origin', so every mutation lands in TEMP and
    never touches the own working copy or a real remote) and asserts on exit code + output + git state.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/prune-merged.tests.ps1

    THE ASSERTS DELIBERATELY DO NOT DEPEND ON gh. A fixture's remote is a local bare repo, so
    `gh pr list` cannot resolve a GitHub repo there and the merged-PR proof is simply unavailable --
    which is a path the script has to answer gracefully anyway, and one of the cases below is exactly
    that. What is asserted is the ANCESTRY proof and the keep-with-a-reason behaviour, both of which
    are pure git and identical on a developer machine and in CI.

    prune-merged.ps1 itself calls 'exit', so it is run here as a CHILD PROCESS (powershell -File).
    Its git commands already run under ErrorActionPreference=Continue themselves (the #107 pitfall,
    via the shared Invoke-NativeCapture) -- this test script mirrors the same caution around ITS OWN
    git fixture calls.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot          = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$PruneMergedSrc    = Join-Path $RepoRoot 'scripts\task\prune-merged.ps1'
# Dot-sourced by the script for every git call (the #107 stderr guard).
$NativeCaptureSrc  = Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1'
# And for Get-BranchTrunkName: the trunk comes from the seam rather than a literal, so a fixture
# without this lib has no script at all.
$EntryScaffoldSrc  = Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1'

$script:pass = 0
$script:fail = 0

function Get-FlatOutput {
    <#
        Captured child output as ONE line: every record read as text, then joined with nothing between.
        A native child's stderr captured with 2>&1 arrives as a NativeCommandError per stderr LINE, and
        the child has already WRAPPED its message at its own host width -- a point that moves with the
        console width and with the length of the fixture's temp path, neither of which this script
        decides. So a phrase assert must survive a break anywhere.

        Read as text rather than rendered with Out-String, which is the part that used to break it:
        Out-String FORMATS each of those records for display, and the decoration it adds ('At <file>:<line>
        char:<n>', the '+ CategoryInfo' block, '+ FullyQualifiedErrorId : NativeCommandError') lands
        BETWEEN the two halves of a wrapped sentence. Removing newlines cannot bridge that -- there is now
        a paragraph of PowerShell in the gap, not a line break. Measured on prune-merged's no-trunk
        refusal, which is long enough to wrap mid-phrase on a developer machine while staying whole in
        CI: green there, red here, for a script that was correct in both places.

        Joined with '' rather than a space because the wrap is a HARD break at a column, so the halves
        reconstruct exactly ('dirt' + 'y working tree'); a space between them would match nothing.
        seam-lib.tests.ps1 and internal-note.tests.ps1 carry this same copy since #982/#959, where the
        wrap reached both of them for real: red on a developer console, green in CI.

        WHO ELSE ANSWERS THIS QUESTION, AND HOW -- measured August 27, 2026, because the list that stood
        here was wrong in both directions and a stale at-risk record is worse than none. Three older
        variants are in the tree, and they are NOT equally exposed:

          * park-branch, park-cycle and worktree-lane: Out-String, then newlines removed. Safe against
            the mid-word break, exposed to the decoration Out-String inserts between the halves. The
            last two were absent from the list that stood here.
          * new-branch: Out-String, then ALL whitespace stripped -- robust against a break anywhere, at
            the price of asserts that must themselves be whitespace-free.
          * find-specialist-mentions: joins with a SPACE, which is the one variant measured to fail
            outright ('the da' + ' ' + 'te by hand' matches nothing). Exposed on both counts.

        shared-scripts.tests.ps1 was named here and carries no copy at all: it captures the child's
        stderr to a redirect FILE and strips all whitespace in Test-OutputContains, which is stronger
        than this helper rather than older than it. (session-status.tests.ps1 did carry one, until #957
        removed it with the script it covered.)

        All five are green, so they are deliberately left alone rather than repaired pre-emptively --
        the risk is named here, which is what this repo does with a risk that has not bitten yet.
    #>
    param($Captured)
    return (($Captured | ForEach-Object { [string]$_ }) -join '')
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

$script:fixtures = @()

function Invoke-FixtureGit {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git @Arguments 2>$null | Out-Null
    } finally { $ErrorActionPreference = $prevEap }
}

function New-Fixture {
    <#
        A fresh throwaway git repo with the script and its two libs copied in, an initial commit on
        'main', and a bare repo wired up as 'origin' -- pushed, so the fast-forward and the
        fetch --prune have a real remote to succeed against with no auth or network.
    #>
    param([Parameter(Mandatory = $true)][string]$Label)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("prune-merged-test-$PID-$Label")
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\task') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib')  -Force | Out-Null
    Copy-Item -LiteralPath $PruneMergedSrc   -Destination (Join-Path $dir 'scripts\task\prune-merged.ps1')       -Force
    Copy-Item -LiteralPath $NativeCaptureSrc -Destination (Join-Path $dir 'scripts\lib\native-capture-lib.ps1')  -Force
    Copy-Item -LiteralPath $EntryScaffoldSrc -Destination (Join-Path $dir 'scripts\lib\entry-scaffold-lib.ps1')  -Force

    $bareRemote = "$dir.git"
    if (Test-Path -LiteralPath $bareRemote) { Remove-Item -Recurse -Force -LiteralPath $bareRemote }

    Invoke-FixtureGit -Arguments @('-C', $dir, 'init', '-q')
    Invoke-FixtureGit -Arguments @('-C', $dir, 'config', 'user.email', 'tycho-tests@local.invalid')
    Invoke-FixtureGit -Arguments @('-C', $dir, 'config', 'user.name', 'Tycho Tests')
    # symbolic-ref instead of checkout -b: works on a still-unborn HEAD regardless of git's own
    # init.defaultBranch setting, and errors on nothing if HEAD is already named 'main'.
    Invoke-FixtureGit -Arguments @('-C', $dir, 'symbolic-ref', 'HEAD', 'refs/heads/main')
    [System.IO.File]::WriteAllText((Join-Path $dir 'README.md'), "# fixture`n", (New-Object System.Text.UTF8Encoding $false))
    Invoke-FixtureGit -Arguments @('-C', $dir, 'add', '-A')
    Invoke-FixtureGit -Arguments @('-C', $dir, 'commit', '-q', '-m', 'init')
    Invoke-FixtureGit -Arguments @('init', '--bare', '-q', $bareRemote)
    Invoke-FixtureGit -Arguments @('-C', $dir, 'remote', 'add', 'origin', $bareRemote)
    Invoke-FixtureGit -Arguments @('-C', $dir, 'push', '-q', '-u', 'origin', 'main')

    $script:fixtures += $dir
    $script:fixtures += $bareRemote
    return $dir
}

function Invoke-PruneMerged {
    <#
        Runs the fixture copy as a child process, with the fixture folder as cwd (so the dual-context
        fallback `git rev-parse --show-toplevel` lands there) and without CLAUDE_PROJECT_DIR left over
        from an earlier test run. EAP=Continue around the call, the same caution as the suites next to
        this one.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [switch]$DryRun
    )
    $scriptPath = Join-Path $Dir 'scripts\task\prune-merged.ps1'
    $callArgs = @()
    if ($DryRun) { $callArgs += '-DryRun' }

    $prevPd  = $env:CLAUDE_PROJECT_DIR
    $prevEap = $ErrorActionPreference
    $prevLoc = (Get-Location).Path
    try {
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        Set-Location -LiteralPath $Dir
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @callArgs 2>&1
        $code = $LASTEXITCODE
        return [pscustomobject]@{ Code = $code; Out = (Get-FlatOutput $out) }
    } finally {
        $ErrorActionPreference = $prevEap
        Set-Location -LiteralPath $prevLoc
        if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prevPd }
    }
}

function Get-LocalBranches {
    param([Parameter(Mandatory = $true)][string]$Dir)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        return @(& git -C $Dir for-each-ref --format='%(refname:short)' refs/heads |
            ForEach-Object { $_.Trim() } | Where-Object { $_ })
    } finally { $ErrorActionPreference = $prevEap }
}

function New-MergedBranch {
    <# A branch whose commit is then merged into main, so it IS an ancestor of the trunk. #>
    param([Parameter(Mandatory = $true)][string]$Dir, [Parameter(Mandatory = $true)][string]$Name)
    Invoke-FixtureGit -Arguments @('-C', $Dir, 'checkout', '-q', '-b', $Name)
    [System.IO.File]::WriteAllText((Join-Path $Dir "$($Name -replace '[\\/]', '-').txt"), "work`n", (New-Object System.Text.UTF8Encoding $false))
    Invoke-FixtureGit -Arguments @('-C', $Dir, 'add', '-A')
    Invoke-FixtureGit -Arguments @('-C', $Dir, 'commit', '-q', '-m', "work on $Name")
    Invoke-FixtureGit -Arguments @('-C', $Dir, 'checkout', '-q', 'main')
    Invoke-FixtureGit -Arguments @('-C', $Dir, 'merge', '-q', '--no-ff', '-m', "merge: $Name", $Name)
    Invoke-FixtureGit -Arguments @('-C', $Dir, 'push', '-q', 'origin', 'main')
}

function New-UnmergedBranch {
    <# A branch with its own commit and NO merge -- the shape of unfinished or parked work. #>
    param([Parameter(Mandatory = $true)][string]$Dir, [Parameter(Mandatory = $true)][string]$Name)
    Invoke-FixtureGit -Arguments @('-C', $Dir, 'checkout', '-q', '-b', $Name)
    [System.IO.File]::WriteAllText((Join-Path $Dir "$($Name -replace '[\\/]', '-').txt"), "wip`n", (New-Object System.Text.UTF8Encoding $false))
    Invoke-FixtureGit -Arguments @('-C', $Dir, 'add', '-A')
    Invoke-FixtureGit -Arguments @('-C', $Dir, 'commit', '-q', '-m', "wip on $Name")
    Invoke-FixtureGit -Arguments @('-C', $Dir, 'checkout', '-q', 'main')
}

try {
    # --- (a) Only the trunk: nothing to reap, exit 0 -------------------------------------------------
    Write-Host "prune-merged.ps1 -- only the trunk" -ForegroundColor Cyan
    $dirA = New-Fixture -Label 'a'
    $rA = Invoke-PruneMerged -Dir $dirA
    Assert-Equal 0 $rA.Code 'only the trunk: exit 0 -- nothing to reap is not an error'
    Assert-True ($rA.Out -match 'Nothing to reap') 'only the trunk: and it says so rather than printing an empty report'
    Assert-Equal 1 (Get-LocalBranches -Dir $dirA).Count 'only the trunk: main is still there'

    # --- (b) A merged branch goes, an unmerged branch stays -----------------------------------------
    #     THE CENTRAL PAIR. Both proofs are absent for the unmerged branch (no ancestry, and gh cannot
    #     resolve a GitHub repo from a local bare remote), which is precisely the state a parked branch
    #     or unfinished work is in -- so this asserts the safety property, not just the happy path.
    Write-Host "prune-merged.ps1 -- merged goes, unmerged stays" -ForegroundColor Cyan
    $dirB = New-Fixture -Label 'b'
    New-MergedBranch   -Dir $dirB -Name 'feat/landed'
    New-UnmergedBranch -Dir $dirB -Name 'feat/still-going'
    $rB = Invoke-PruneMerged -Dir $dirB
    Assert-Equal 0 $rB.Code 'mixed: exit 0'
    $branchesB = Get-LocalBranches -Dir $dirB
    Assert-True (-not ($branchesB -contains 'feat/landed')) 'mixed: the merged branch is deleted'
    Assert-True ($branchesB -contains 'feat/still-going') 'mixed: the UNMERGED branch survives -- the whole safety property of this script'
    Assert-True ($branchesB -contains 'main') 'mixed: and the trunk is never a candidate'
    Assert-True ($rB.Out -match 'Deleted feat/landed') 'mixed: the run names what it deleted'
    Assert-True ($rB.Out -match 'ancestor of main') 'mixed: with the proof it deleted on, so a reader can check the reasoning'
    Assert-True ($rB.Out -match 'Kept feat/still-going') 'mixed: and names what it kept'
    Assert-True ($rB.Out -match 'not an ancestor of the trunk') 'mixed: with the reason, rather than leaving it inferred from an absent line'
    # The remote half is somebody else's, and saying so is what stops a clean local list being read as
    # evidence about the remote.
    Assert-True ($rB.Out -match 'ls-remote --heads origin') 'mixed: it names the command that actually answers the remote question'

    # --- (c) -DryRun reports and deletes nothing -----------------------------------------------------
    Write-Host "prune-merged.ps1 -- -DryRun" -ForegroundColor Cyan
    $dirC = New-Fixture -Label 'c'
    New-MergedBranch -Dir $dirC -Name 'fix/landed-too'
    $rC = Invoke-PruneMerged -Dir $dirC -DryRun
    Assert-Equal 0 $rC.Code '-DryRun: exit 0'
    Assert-True ((Get-LocalBranches -Dir $dirC) -contains 'fix/landed-too') '-DryRun: the reapable branch is STILL THERE'
    Assert-True ($rC.Out -match 'Would delete fix/landed-too') '-DryRun: and it says what it would have done'
    Assert-True ($rC.Out -match 'Nothing was deleted') '-DryRun: with the line that makes the run unmistakable for the real one'

    # --- (d) A dirty tree is refused before anything is touched ------------------------------------
    #     Refused UP FRONT rather than discovered by a failing checkout halfway through: at that point
    #     the fetch may already have run, and the reader has to work out what did and did not happen.
    Write-Host "prune-merged.ps1 -- refuses on a dirty tree" -ForegroundColor Cyan
    $dirD = New-Fixture -Label 'd'
    New-MergedBranch -Dir $dirD -Name 'feat/would-have-gone'
    [System.IO.File]::WriteAllText((Join-Path $dirD 'uncommitted.txt'), "in progress`n", (New-Object System.Text.UTF8Encoding $false))
    $rD = Invoke-PruneMerged -Dir $dirD
    Assert-Equal 1 $rD.Code 'dirty: exit 1'
    Assert-True ($rD.Out -match 'dirty working tree') 'dirty: the refusal names what is wrong'
    Assert-True ($rD.Out -match 'park-branch') 'dirty: and points at the ways out rather than only refusing'
    Assert-True ((Get-LocalBranches -Dir $dirD) -contains 'feat/would-have-gone') 'dirty: NOTHING was deleted -- a branch that was reapable a line earlier is untouched'

    # --- (e) A clone without the declared trunk refuses rather than guessing ------------------------
    #     The safe direction, and asserted because it is the one case where a wrong answer would delete
    #     against the wrong ancestry.
    Write-Host "prune-merged.ps1 -- no local trunk" -ForegroundColor Cyan
    $dirE = New-Fixture -Label 'e'
    New-UnmergedBranch -Dir $dirE -Name 'feat/orphan'
    Invoke-FixtureGit -Arguments @('-C', $dirE, 'checkout', '-q', 'feat/orphan')
    Invoke-FixtureGit -Arguments @('-C', $dirE, 'branch', '-q', '-D', 'main')
    $rE = Invoke-PruneMerged -Dir $dirE
    Assert-Equal 1 $rE.Code 'no trunk: exit 1'
    Assert-True ($rE.Out -match "no local branch 'main'") 'no trunk: the refusal names the branch it looked for'
    Assert-True ($rE.Out -match 'Get-TrunkBranchName') 'no trunk: and the seam that decides it, so a repo on another trunk knows where to answer'
    Assert-True ((Get-LocalBranches -Dir $dirE) -contains 'feat/orphan') 'no trunk: and it deleted nothing'

    # --- (f) It never deletes a remote branch -------------------------------------------------------
    #     A deliberate decision rather than an omission: with the remote reaping its own merged heads,
    #     a remote delete would only ever reach branches that are NOT merged.
    Write-Host "prune-merged.ps1 -- the remote is untouched" -ForegroundColor Cyan
    $dirF = New-Fixture -Label 'f'
    New-MergedBranch -Dir $dirF -Name 'feat/pushed-and-landed'
    Invoke-FixtureGit -Arguments @('-C', $dirF, 'push', '-q', 'origin', 'feat/pushed-and-landed')
    $rF = Invoke-PruneMerged -Dir $dirF
    Assert-Equal 0 $rF.Code 'remote: exit 0'
    Assert-True (-not ((Get-LocalBranches -Dir $dirF) -contains 'feat/pushed-and-landed')) 'remote: the LOCAL branch is deleted'
    $remoteHeads = @(& git -C $dirF ls-remote --heads origin | ForEach-Object { $_ })
    Assert-True (($remoteHeads -join ' ') -match 'feat/pushed-and-landed') 'remote: and the REMOTE branch is still standing -- this script deletes nothing there'

    # AND STRUCTURALLY, not only on this fixture. Matched on the QUOTED argument form -- the shape a
    # git call actually takes here (Invoke-NativeCapture takes an array of quoted strings) -- rather
    # than on the bare words, which appear in the script's own header explaining why it does not do
    # this. A prose ban and a code ban are two different assertions and only the second is worth one.
    $srcText = [System.IO.File]::ReadAllText($PruneMergedSrc)
    Assert-True ($srcText -notmatch "'--delete") 'remote: and no git call in the source carries a --delete argument, so the property is structural rather than only untested here'
} finally {
    foreach ($f in $script:fixtures) {
        if ($f -and (Test-Path -LiteralPath $f)) { Remove-Item -Recurse -Force -LiteralPath $f -ErrorAction SilentlyContinue }
    }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "Result: $($script:pass) pass, $($script:fail) fail." -ForegroundColor Red
    exit 1
}
Write-Host "Result: $($script:pass) pass, 0 fail." -ForegroundColor Green
exit 0
