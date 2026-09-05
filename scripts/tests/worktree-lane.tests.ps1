<#
.SYNOPSIS
    Regression tests for scripts/task/worktree-lane.ps1 (open a branch in its own git worktree; hand
    the lane's branch back to the primary checkout).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Integration style -- runs the REAL script in a
    throwaway temp git repo with a bare 'origin', so every worktree/branch mutation lands in the temp
    tree and never in the own working copy.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/worktree-lane.tests.ps1

    worktree-lane.ps1 calls 'exit', so it is run here as a CHILD PROCESS (powershell -File). Its git
    commands already run under ErrorActionPreference=Continue themselves (the #107 pitfall, via the
    shared Invoke-NativeCapture) -- this suite mirrors the same caution around ITS OWN git calls.

    WHY THE FIXTURE CARRIES new-branch.ps1 AND ITS LIBS: opening a lane delegates the branch and both
    branch-dossier files to that script via -RepoRoot. A fixture without it would test the worktree
    half and silently skip the half that proves the delegation writes into the LANE rather than into
    the primary -- which is the whole point of that parameter.

    THE PRIMARY-HEAD ASSERT IS THE LOAD-BEARING ONE. Opening a lane while a ship is running in the
    primary is the entire use case, so a version of this script that moved the primary's HEAD would be
    worse than no script at all: it would break the thing it was built to protect. That is asserted on
    every open, including the rollback path.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot          = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$WorktreeLaneSrc   = Join-Path $RepoRoot 'scripts\task\worktree-lane.ps1'
$NewBranchSrc      = Join-Path $RepoRoot 'scripts\task\new-branch.ps1'
$BranchInfoSrc     = Join-Path $RepoRoot 'scripts\lib\branch-info.ps1'
$NativeCaptureSrc  = Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1'
$EntryScaffoldSrc  = Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1'
$ParkLibSrc        = Join-Path $RepoRoot 'scripts\lib\park-lib.ps1'
# As in new-branch.tests.ps1: this fixture runs new-branch, which reads the changelog seam through this lib
# since inbound #967.
$SeamLibSrc        = Join-Path $RepoRoot 'scripts\lib\seam-lib.ps1'
# And the already-done check's pure half (#1409), which new-branch.ps1 now dot-sources unconditionally --
# same reasoning as the lib above, this fixture runs new-branch and has to carry it too.
$PrIssuesLibSrc    = Join-Path $RepoRoot 'scripts\lib\pr-issues-lib.ps1'

$script:pass = 0
$script:fail = 0

function Get-FlatOutput {
    <#
        Captured child output with newlines removed, so a phrase assert cannot fail on a wrap point
        this script does not decide. A native child's stderr captured with 2>&1 arrives as a
        NativeCommandError, which PowerShell WRAPS at the host width -- and the fixture's temp path
        length moves that wrap point. Same reasoning, and same removal-rather-than-collapse, as
        park-branch.tests.ps1 and new-branch.tests.ps1.
    #>
    param($Captured)
    return (($Captured | Out-String) -replace "`r?`n", '')
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

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & git @Arguments 2>&1
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = (($out | Out-String).Trim()) }
    } finally { $ErrorActionPreference = $prevEap }
}

function New-Fixture {
    <#
        A throwaway repo with the scripts copied in, one commit on 'main', and a bare 'origin' that
        main has been PUSHED to -- the push matters: opening a lane bases it on origin/main, so a
        fixture whose origin has no main would fail for a reason that has nothing to do with the
        behaviour under test.

        The lane directories this creates land NEXT TO the fixture (<fixture>-lanes\...), because that
        is the script's own default; they are registered for cleanup here rather than guessed at later.
    #>
    param([Parameter(Mandatory = $true)][string]$Label)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("worktree-lane-test-$PID-$Label")
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\task') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib')  -Force | Out-Null
    Copy-Item -LiteralPath $WorktreeLaneSrc  -Destination (Join-Path $dir 'scripts\task\worktree-lane.ps1')      -Force
    Copy-Item -LiteralPath $NewBranchSrc     -Destination (Join-Path $dir 'scripts\task\new-branch.ps1')         -Force
    Copy-Item -LiteralPath $BranchInfoSrc    -Destination (Join-Path $dir 'scripts\lib\branch-info.ps1')         -Force
    Copy-Item -LiteralPath $NativeCaptureSrc -Destination (Join-Path $dir 'scripts\lib\native-capture-lib.ps1')  -Force
    Copy-Item -LiteralPath $EntryScaffoldSrc -Destination (Join-Path $dir 'scripts\lib\entry-scaffold-lib.ps1')  -Force
    Copy-Item -LiteralPath $ParkLibSrc       -Destination (Join-Path $dir 'scripts\lib\park-lib.ps1')            -Force
    Copy-Item -LiteralPath $SeamLibSrc       -Destination (Join-Path $dir 'scripts\lib\seam-lib.ps1')            -Force
    Copy-Item -LiteralPath $PrIssuesLibSrc   -Destination (Join-Path $dir 'scripts\lib\pr-issues-lib.ps1')       -Force

    $bareRemote = "$dir.git"
    if (Test-Path -LiteralPath $bareRemote) { Remove-Item -Recurse -Force -LiteralPath $bareRemote }

    Invoke-Git @('init', '-q', $dir)                                        | Out-Null
    Invoke-Git @('-C', $dir, 'config', 'user.email', 'tycho-tests@local.invalid') | Out-Null
    Invoke-Git @('-C', $dir, 'config', 'user.name',  'Tycho Tests')         | Out-Null
    # gpgsign off: a locked signing agent must not fail a fixture commit for a reason unrelated to the test (#1287).
    Invoke-Git @('-C', $dir, 'config', 'commit.gpgsign', 'false')           | Out-Null
    Invoke-Git @('-C', $dir, 'symbolic-ref', 'HEAD', 'refs/heads/main')     | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $dir 'README.md'), "# fixture`n", (New-Object System.Text.UTF8Encoding $false))
    Invoke-Git @('-C', $dir, 'add', '-A')                                   | Out-Null
    Invoke-Git @('-C', $dir, 'commit', '-q', '-m', 'init')                   | Out-Null
    Invoke-Git @('init', '--bare', '-q', $bareRemote)                        | Out-Null
    Invoke-Git @('-C', $dir, 'remote', 'add', 'origin', $bareRemote)         | Out-Null
    Invoke-Git @('-C', $dir, 'push', '-q', '-u', 'origin', 'main')           | Out-Null

    $script:fixtures += $dir
    $script:fixtures += $bareRemote
    $script:fixtures += "$dir-lanes"
    return $dir
}

function Invoke-WorktreeLane {
    <#
        Runs the fixture copy as a child process. -From sets the cwd, because the script resolves the
        PRIMARY worktree from `git worktree list` without -C on purpose (it must work from inside a
        lane) -- so which tree it is standing in is part of the behaviour under test, not a detail.
        CLAUDE_PROJECT_DIR is cleared: an inherited value from the surrounding session would redirect
        new-branch's dual-context fallback at the real repo.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][string]$From,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )
    $scriptPath = Join-Path $Dir 'scripts\task\worktree-lane.ps1'
    $prevPd  = $env:CLAUDE_PROJECT_DIR
    $prevEap = $ErrorActionPreference
    $prevLoc = (Get-Location).Path
    try {
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        Set-Location -LiteralPath $From
        $ErrorActionPreference = 'Continue'
        $out  = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments 2>&1
        $code = $LASTEXITCODE
        return [pscustomobject]@{ Code = $code; Out = (Get-FlatOutput $out) }
    } finally {
        $ErrorActionPreference = $prevEap
        Set-Location -LiteralPath $prevLoc
        if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prevPd }
    }
}

function Get-HeadBranch {
    param([Parameter(Mandatory = $true)][string]$Dir)
    return (Invoke-Git @('-C', $Dir, 'rev-parse', '--abbrev-ref', 'HEAD')).Out
}

function Get-WorktreeCount {
    param([Parameter(Mandatory = $true)][string]$Dir)
    $r = Invoke-Git @('-C', $Dir, 'worktree', 'list', '--porcelain')
    return @($r.Out -split "`r?`n" | Where-Object { $_ -match '^worktree\s+' }).Count
}

function Test-BranchExists {
    param([Parameter(Mandatory = $true)][string]$Dir, [Parameter(Mandatory = $true)][string]$Name)
    return ((Invoke-Git @('-C', $Dir, 'rev-parse', '--verify', '--quiet', "refs/heads/$Name")).Code -eq 0)
}

try {
    # --- (a) Open a lane: branch + both dossier files land IN THE LANE, primary HEAD untouched ------
    Write-Host "worktree-lane.ps1 -- opens a lane without touching the primary" -ForegroundColor Cyan
    $fa = New-Fixture -Label 'a'
    $rA = Invoke-WorktreeLane -Dir $fa -From $fa -Arguments @('-Name', 'feat/lane-a', '-Title', 'Lane A')
    Assert-Equal 0 $rA.Code "open: exit 0"
    $laneA = Join-Path "$fa-lanes" 'feat--lane-a'
    Assert-True (Test-Path -LiteralPath $laneA -PathType Container) "open: lane directory created"
    Assert-Equal 2 (Get-WorktreeCount -Dir $fa) "open: git registers exactly two worktrees"
    # THE NAME IS USED AS GIVEN since new-branch stopped completing a '-v1' suffix (Dave, September 3,
    # 2026): the lane opens whatever branch the shared scaffolder decides on, and it now decides on the
    # name verbatim, so this asserts through it rather than around it.
    Assert-True (Test-BranchExists -Dir $fa -Name 'feat/lane-a') "open: branch created"
    Assert-Equal 'feat/lane-a' (Get-HeadBranch -Dir $laneA) "open: the LANE is on the new branch"
    Assert-Equal 'main' (Get-HeadBranch -Dir $fa) "open: the PRIMARY still sits on main (the load-bearing guarantee)"
    # The -RepoRoot delegation: the dossier belongs to the lane, and the primary must not have gained
    # a copy. Asserting only the first half would pass for a script that wrote into both.
    # The name carries the branch since #1255, and the lane's branch is 'feat/lane-a'. Written out
    # rather than derived, deliberately: this suite is asserting that worktree-lane delegated -RepoRoot
    # correctly, and a path computed from the same lib the script used would agree with it either way.
    Assert-True (Test-Path -LiteralPath (Join-Path $laneA 'contributing-davekjohn\feat-lane-a.md')) "open: the development document is written in the lane"
    # THE NAME THIS COULD ACTUALLY GAIN, which is the per-branch one (#1255). Checking the pre-#1255
    # shared name here would pass whatever the script did, because nothing writes that name any more --
    # a negative assert against a path no writer can produce is not a measurement.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $fa 'contributing-davekjohn\feat-lane-a.md'))) "open: the primary did NOT gain one"
    # AND THE LANE IS ON ORIGIN THE MOMENT IT OPENS (#900). Asserted here rather than left to
    # new-branch's own suite, because a lane is the case that needs it most: opening one is by definition
    # work running beside something else, which is exactly when the other side cannot see a local branch.
    # The -RepoRoot delegation is what has to carry the push through, and nothing else covers that pair.
    Invoke-Git @('-C', "$fa.git", 'rev-parse', '--verify', '--quiet', 'refs/heads/feat/lane-a') | Out-Null
    Assert-True ($LASTEXITCODE -eq 0) "open: the lane's branch is already on origin"

    # --- (b) A refused branch name rolls the lane back completely -----------------------------------
    Write-Host "worktree-lane.ps1 -- rolls back when new-branch refuses the name" -ForegroundColor Cyan
    $fb = New-Fixture -Label 'b'
    # 'main' is rejected by Test-BranchName, so this exercises the rollback via the real refusal path
    # rather than via a mock -- the name is validated by new-branch, which is the point of step 5.
    $rB = Invoke-WorktreeLane -Dir $fb -From $fb -Arguments @('-Name', 'main', '-Title', 'Nope')
    Assert-Equal 1 $rB.Code "rollback: exit 1"
    Assert-Equal 1 (Get-WorktreeCount -Dir $fb) "rollback: no lane left registered"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path "$fb-lanes" 'main'))) "rollback: no lane directory left on disk"
    Assert-Equal 'main' (Get-HeadBranch -Dir $fb) "rollback: primary HEAD untouched"

    # --- (c) A non-empty lane path is refused before anything is created ---------------------------
    Write-Host "worktree-lane.ps1 -- refuses a non-empty lane path" -ForegroundColor Cyan
    $fc = New-Fixture -Label 'c'
    $occupied = Join-Path "$fc-lanes" 'feat--taken'
    New-Item -ItemType Directory -Path $occupied -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $occupied 'in-the-way.txt'), "x`n")
    $rC = Invoke-WorktreeLane -Dir $fc -From $fc -Arguments @('-Name', 'feat/taken')
    Assert-Equal 1 $rC.Code "occupied path: exit 1"
    Assert-True ($rC.Out -match 'already exists') "occupied path: message names the cause"
    Assert-Equal 1 (Get-WorktreeCount -Dir $fc) "occupied path: nothing registered"

    # --- (d) HandBack refuses while the LANE is dirty ----------------------------------------------
    # THE DIRT IS MADE HERE NOW, AND #900 IS WHY (August 26, 2026). This used to rest on the default: a
    # freshly opened lane was always dirty, because new-branch wrote its document and committed nothing.
    # Since the creation push became the default it commits and pushes that document, so a lane opens
    # CLEAN -- which is the improvement, most of all for a lane, whose whole reason to exist is work
    # running in parallel with something else.
    #
    # The guard is still worth its assert; what changed is only that the state has to be arranged. Note
    # which direction that cuts: a test resting on a convenient default passes for two reasons and tells
    # you nothing when one of them goes away.
    Write-Host "worktree-lane.ps1 -HandBack -- refuses on a dirty lane" -ForegroundColor Cyan
    $fd = New-Fixture -Label 'd'
    Invoke-WorktreeLane -Dir $fd -From $fd -Arguments @('-Name', 'feat/lane-d', '-Title', 'Lane D') | Out-Null
    $laneD = Join-Path "$fd-lanes" 'feat--lane-d'
    [System.IO.File]::WriteAllText((Join-Path $laneD 'work-in-progress.txt'), "half-finished`n", (New-Object System.Text.UTF8Encoding $false))
    $rD = Invoke-WorktreeLane -Dir $fd -From $fd -Arguments @('-HandBack', '-Lane', $laneD)
    Assert-Equal 1 $rD.Code "dirty lane: exit 1"
    Assert-True ($rD.Out -match 'uncommitted work') "dirty lane: message names the cause"
    Assert-Equal 2 (Get-WorktreeCount -Dir $fd) "dirty lane: the lane survives"

    # --- (e) HandBack refuses while the PRIMARY is dirty -------------------------------------------
    Write-Host "worktree-lane.ps1 -HandBack -- refuses on a dirty primary" -ForegroundColor Cyan
    Invoke-Git @('-C', $laneD, 'add', '-A')                       | Out-Null
    Invoke-Git @('-C', $laneD, 'commit', '-q', '-m', 'lane work') | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $fd 'dirty.txt'), "x`n")
    $rE = Invoke-WorktreeLane -Dir $fd -From $fd -Arguments @('-HandBack', '-Lane', $laneD)
    Assert-Equal 1 $rE.Code "dirty primary: exit 1"
    Assert-True ($rE.Out -match 'primary checkout has uncommitted work') "dirty primary: message names the cause"
    Assert-Equal 2 (Get-WorktreeCount -Dir $fd) "dirty primary: the lane survives"
    Assert-Equal 'main' (Get-HeadBranch -Dir $fd) "dirty primary: no checkout happened"

    # --- (f) HandBack happy path, run FROM INSIDE the lane ----------------------------------------
    # From inside, deliberately: that is the normal case and the one that first failed, because the
    # process's own cwd holds the directory open on Windows.
    Write-Host "worktree-lane.ps1 -HandBack -- hands the branch back from inside the lane" -ForegroundColor Cyan
    Remove-Item -LiteralPath (Join-Path $fd 'dirty.txt') -Force
    $rF = Invoke-WorktreeLane -Dir $fd -From $laneD -Arguments @('-HandBack')
    Assert-Equal 0 $rF.Code "hand back: exit 0"
    Assert-Equal 1 (Get-WorktreeCount -Dir $fd) "hand back: the lane is deregistered"
    Assert-Equal 'feat/lane-d' (Get-HeadBranch -Dir $fd) "hand back: the branch is checked out in the primary"
    Assert-True ($rF.Out -match 'ship-pr') "hand back: names the next step"
    Assert-True (Test-BranchExists -Dir $fd -Name 'feat/lane-d') "hand back: the branch itself survives"

    # --- (g) HandBack refuses when the target is the primary --------------------------------------
    Write-Host "worktree-lane.ps1 -HandBack -- refuses to hand back the primary" -ForegroundColor Cyan
    $rG = Invoke-WorktreeLane -Dir $fd -From $fd -Arguments @('-HandBack', '-Lane', $fd)
    Assert-Equal 1 $rG.Code "primary as target: exit 1"
    Assert-True ($rG.Out -match 'primary checkout, not a lane') "primary as target: message names the cause"

    # --- (h) HandBack refuses a path that is not a worktree of this repo --------------------------
    Write-Host "worktree-lane.ps1 -HandBack -- refuses a foreign path" -ForegroundColor Cyan
    $foreign = Join-Path ([System.IO.Path]::GetTempPath()) "worktree-lane-test-$PID-foreign"
    New-Item -ItemType Directory -Path $foreign -Force | Out-Null
    $script:fixtures += $foreign
    $rH = Invoke-WorktreeLane -Dir $fd -From $fd -Arguments @('-HandBack', '-Lane', $foreign)
    Assert-Equal 1 $rH.Code "foreign path: exit 1"
    Assert-True ($rH.Out -match 'Not a registered worktree') "foreign path: message names the cause"

    # --- (i) Structural: the hand-back removal is never forced ------------------------------------
    # The mirror image of prune-merged.tests.ps1's "no --delete anywhere" assert, and for the same
    # reason: the safety property is a property of the CODE, not of one run. --force belongs only on
    # the rollback path, where the lane was created seconds earlier by this same script and holds
    # nothing a person made.
    Write-Host "worktree-lane.ps1 -- structural: the hand-back removal carries no --force" -ForegroundColor Cyan
    $srcLines = [System.IO.File]::ReadAllLines($WorktreeLaneSrc)
    $removeCalls = @($srcLines | Where-Object { $_ -match "'worktree',\s*'remove'" })
    Assert-True ($removeCalls.Count -ge 2) "structural: both removal call sites found"
    $handBackRemoval = @($removeCalls | Where-Object { $_ -notmatch '--force' })
    $forcedRemoval   = @($removeCalls | Where-Object { $_ -match '--force' })
    Assert-Equal 1 $handBackRemoval.Count "structural: exactly one unforced removal (the hand-back)"
    Assert-Equal 1 $forcedRemoval.Count   "structural: exactly one forced removal (the rollback)"
} finally {
    foreach ($f in ($script:fixtures | Select-Object -Unique)) {
        if ($f -and (Test-Path -LiteralPath $f)) {
            Remove-Item -Recurse -Force -LiteralPath $f -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ""
Write-Host "worktree-lane.tests.ps1: $script:pass passed, $script:fail failed" -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
