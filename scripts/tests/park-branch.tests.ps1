<#
.SYNOPSIS
    Regression tests for scripts/task/park-branch.ps1 (commit all outstanding work + push -u to
    origin, no PR, refuse on main).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Integration style -- runs the REAL script
    (copied into a throwaway temp git repo with a bare 'origin', so the commit/push mutations never
    touch the own working copy or a real remote) and asserts on exit code + output + git state.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/park-branch.tests.ps1

    park-branch.ps1 itself calls 'exit', so it is run here as a CHILD PROCESS (powershell -File).
    Its git commands already run under ErrorActionPreference=Continue themselves (the #107 pitfall,
    via the shared Invoke-NativeCapture) -- this test script mirrors the same caution around ITS OWN
    git fixture calls.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot         = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$ParkBranchSrc    = Join-Path $RepoRoot 'scripts\task\park-branch.ps1'
# park-branch dot-sources this sibling shared lib for every git call (the #107 stderr guard), so the
# fixture must carry it too.
$NativeCaptureSrc = Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1'
# And the shared park implementation itself since #507 -- park-branch is now the thin entry point and
# Invoke-GitPark does the work, so a fixture without this file has no script at all.
$ParkLibSrc       = Join-Path $RepoRoot 'scripts\lib\park-lib.ps1'

$script:pass = 0
$script:fail = 0

function Get-FlatOutput {
    <#
        Captured child output, whitespace collapsed to single spaces, so a phrase assert cannot fail on
        line breaks that the behaviour under test does not decide. A native child's stderr captured with
        2>&1 arrives as a NativeCommandError, which PowerShell renders with a 'powershell.exe : ' prefix
        and WRAPS at the host width -- so the wrap point moves with the console width and with the length
        of the fixture's temp path, neither of which park-branch.ps1 decides.

        Applied here for the same reason it was applied to new-branch.tests.ps1 on August 3, 2026, where
        a 176-column window split "must not be 'main'" MID-WORD and failed an assert about correct
        behaviour. This suite's own asserts ('on main', 'parked on origin', 'nothing new to commit') sit
        in exactly the same records and are one window width away from the same failure.

        The newlines are removed rather than collapsed to a space, because a mid-word break leaves
        'mus' + 't not be' and a space between them matches nothing. Precedent:
        shared-scripts.tests.ps1's Test-OutputContains.
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

function New-Fixture {
    <#
        A fresh throwaway git repo with park-branch.ps1 + native-capture-lib.ps1 copied in, an
        initial commit on a base branch 'main', and a bare repo wired up as 'origin' so the push has
        somewhere to land (no auth/network needed). Returns the working repo path; the bare origin
        path is $dir + '.git' and is tracked for cleanup.
    #>
    param([Parameter(Mandatory = $true)][string]$Label)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("park-branch-test-$PID-$Label")
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\task') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib')  -Force | Out-Null
    Copy-Item -LiteralPath $ParkBranchSrc    -Destination (Join-Path $dir 'scripts\task\park-branch.ps1')        -Force
    Copy-Item -LiteralPath $NativeCaptureSrc -Destination (Join-Path $dir 'scripts\lib\native-capture-lib.ps1')  -Force
    Copy-Item -LiteralPath $ParkLibSrc       -Destination (Join-Path $dir 'scripts\lib\park-lib.ps1')            -Force

    $bareRemote = "$dir.git"
    if (Test-Path -LiteralPath $bareRemote) { Remove-Item -Recurse -Force -LiteralPath $bareRemote }

    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $dir init -q 2>$null | Out-Null
        & git -C $dir config user.email 'tycho-tests@local.invalid' 2>$null | Out-Null
        & git -C $dir config user.name 'Tycho Tests' 2>$null | Out-Null
        # symbolic-ref instead of checkout -b: works on a still-unborn HEAD regardless of git's own
        # init.defaultBranch setting, and gives no error if HEAD happens to already be named 'main'.
        & git -C $dir symbolic-ref HEAD refs/heads/main 2>$null | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $dir 'README.md'), "# fixture`n", (New-Object System.Text.UTF8Encoding $false))
        & git -C $dir add -A 2>$null | Out-Null
        & git -C $dir commit -q -m 'init' 2>$null | Out-Null
        & git init --bare -q $bareRemote 2>$null | Out-Null
        & git -C $dir remote add origin $bareRemote 2>$null | Out-Null
    } finally {
        $ErrorActionPreference = $prevEap
    }
    $script:fixtures += $dir
    $script:fixtures += $bareRemote
    return $dir
}

function Invoke-ParkBranch {
    <#
        Runs the fixture copy of park-branch.ps1 as a child process, with the fixture folder as cwd
        (so the dual-context fallback `git rev-parse --show-toplevel` lands there) and without
        CLAUDE_PROJECT_DIR from an earlier test run. EAP=Continue around the call -- the same caution
        as new-branch.tests.ps1 (native stderr under EAP=Stop would otherwise become terminating here).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [string]$Intent
    )
    $scriptPath = Join-Path $Dir 'scripts\task\park-branch.ps1'
    $callArgs = @()
    if ($PSBoundParameters.ContainsKey('Intent')) { $callArgs += @('-Intent', $Intent) }

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

function Get-CommitCount {
    param([Parameter(Mandatory = $true)][string]$Dir)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        return @(& git -C $Dir log --oneline).Count
    } finally { $ErrorActionPreference = $prevEap }
}

function Checkout-NewBranch {
    param([Parameter(Mandatory = $true)][string]$Dir, [Parameter(Mandatory = $true)][string]$Name)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $Dir checkout -q -b $Name 2>$null | Out-Null
    } finally { $ErrorActionPreference = $prevEap }
}

try {
    # --- (a) Guardrail: refuses on main (exit 1), no commit, no push --------------------------------
    Write-Host "park-branch.ps1 -- refuses on main (exit 1)" -ForegroundColor Cyan
    $fixtureA = New-Fixture -Label 'a'
    $rMain = Invoke-ParkBranch -Dir $fixtureA
    Assert-Equal 1 $rMain.Code "on main: exit 1 (guardrail)"
    Assert-True ($rMain.Out -match 'on main') "on main: pointer names the main rule"
    Assert-Equal 1 (Get-CommitCount -Dir $fixtureA) "on main: no commit added"
    & git -C "$fixtureA.git" rev-parse --verify --quiet 'refs/heads/main' | Out-Null
    Assert-True ($LASTEXITCODE -ne 0) "on main: nothing pushed to origin"

    # --- (b) Commit ALL outstanding work + push -u, no PR ------------------------------------------
    Write-Host "park-branch.ps1 -- commits all outstanding work and pushes to origin" -ForegroundColor Cyan
    $fixtureB = New-Fixture -Label 'b'
    Checkout-NewBranch -Dir $fixtureB -Name 'feat/wip'
    # A mix of outstanding work: a modified tracked file, a staged new file, and an untracked file.
    [System.IO.File]::WriteAllText((Join-Path $fixtureB 'README.md'), "# fixture edited`n", (New-Object System.Text.UTF8Encoding $false))
    [System.IO.File]::WriteAllText((Join-Path $fixtureB 'staged.txt'), "staged`n", (New-Object System.Text.UTF8Encoding $false))
    $prevEap = $ErrorActionPreference
    try { $ErrorActionPreference = 'Continue'; & git -C $fixtureB add -- 'staged.txt' 2>$null | Out-Null } finally { $ErrorActionPreference = $prevEap }
    [System.IO.File]::WriteAllText((Join-Path $fixtureB 'untracked.txt'), "untracked`n", (New-Object System.Text.UTF8Encoding $false))

    $rB = Invoke-ParkBranch -Dir $fixtureB
    Assert-Equal 0 $rB.Code 'park: exit 0'
    Assert-True ($rB.Out -match 'parked on origin') 'park: reports the branch was parked on origin'
    # working tree fully clean -- nothing left behind
    $statusB = ((& git -C $fixtureB status --porcelain) -join "`n")
    Assert-True ([string]::IsNullOrWhiteSpace($statusB)) 'park: working tree clean after park (all work committed)'
    Assert-Equal 2 (Get-CommitCount -Dir $fixtureB) 'park: exactly one park commit on top of the initial commit'
    # the park commit contains every outstanding file
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $parkFiles = @(& git -C $fixtureB diff-tree --no-commit-id --name-only -r HEAD 2>$null)
    } finally { $ErrorActionPreference = $prevEap }
    Assert-True ($parkFiles -contains 'README.md')    'park: modified tracked file in the park commit'
    Assert-True ($parkFiles -contains 'staged.txt')   'park: staged new file in the park commit'
    Assert-True ($parkFiles -contains 'untracked.txt') 'park: untracked file swept into the park commit (add -A)'
    # pushed + upstream tracking set
    & git -C "$fixtureB.git" rev-parse --verify --quiet 'refs/heads/feat/wip' | Out-Null
    Assert-True ($LASTEXITCODE -eq 0) 'park: branch ref present on origin (pushed)'
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $upstream = ((& git -C $fixtureB rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null) | Out-String).Trim()
    } finally { $ErrorActionPreference = $prevEap }
    Assert-Equal 'origin/feat/wip' $upstream 'park: upstream tracking set to origin/<branch>'

    # --- (c) Already committed locally but not pushed: no new commit, still pushes ------------------
    Write-Host "park-branch.ps1 -- already committed locally, not pushed: pushes as-is" -ForegroundColor Cyan
    $fixtureC = New-Fixture -Label 'c'
    Checkout-NewBranch -Dir $fixtureC -Name 'feat/committed'
    [System.IO.File]::WriteAllText((Join-Path $fixtureC 'work.txt'), "done`n", (New-Object System.Text.UTF8Encoding $false))
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $fixtureC add -A 2>$null | Out-Null
        & git -C $fixtureC commit -q -m 'local work' 2>$null | Out-Null
    } finally { $ErrorActionPreference = $prevEap }
    $countBeforeC = Get-CommitCount -Dir $fixtureC

    $rC = Invoke-ParkBranch -Dir $fixtureC
    Assert-Equal 0 $rC.Code 'park (already committed): exit 0'
    Assert-True ($rC.Out -match 'nothing new to commit') 'park (already committed): reports nothing new to commit'
    Assert-Equal $countBeforeC (Get-CommitCount -Dir $fixtureC) 'park (already committed): no extra commit created'
    & git -C "$fixtureC.git" rev-parse --verify --quiet 'refs/heads/feat/committed' | Out-Null
    Assert-True ($LASTEXITCODE -eq 0) 'park (already committed): branch still pushed to origin'

    # --- (d) -Intent recorded in the park commit message ------------------------------------------
    Write-Host "park-branch.ps1 -- -Intent recorded in the park commit message" -ForegroundColor Cyan
    $fixtureD = New-Fixture -Label 'd'
    Checkout-NewBranch -Dir $fixtureD -Name 'feat/intent'
    [System.IO.File]::WriteAllText((Join-Path $fixtureD 'wip.txt'), "wip`n", (New-Object System.Text.UTF8Encoding $false))
    $intentText = 'Skeleton done; next: wire the API client.'
    $rD = Invoke-ParkBranch -Dir $fixtureD -Intent $intentText
    Assert-Equal 0 $rD.Code '-Intent: exit 0'
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $lastMsg = ((& git -C $fixtureD log -1 --pretty=%B 2>$null) | Out-String)
    } finally { $ErrorActionPreference = $prevEap }
    Assert-True ($lastMsg -match [regex]::Escape('park: feat/intent')) '-Intent: park commit still carries the park subject'
    Assert-True ($lastMsg -match [regex]::Escape($intentText)) '-Intent: the intent text is recorded in the commit body'

    # --- (d2) The subject NAMES THE SCOPE (#507) ----------------------------------------------------
    # THE DEFECT THIS SUITE COULD NOT SEE. Both parking entry points wrote the identical subject --
    # `park: <branch> (work parked for later)` -- while committing different things, so a reader could not
    # tell afterwards whether only the two branch files or everything outstanding had reached origin.
    # Nothing here asserted the subject beyond the branch name, which is why the drift survived a suite
    # that otherwise checks this script closely. The phrase is read from the lib rather than retyped, so
    # rewording a scope stays a one-place change and this assert cannot quietly stop matching.
    . (Join-Path $RepoRoot 'scripts\lib\park-lib.ps1')
    $scopes = Get-GitParkScopes
    Assert-True ($lastMsg -match [regex]::Escape($scopes['Everything'])) '-Intent: the subject names the scope that was committed (everything outstanding)'
    Assert-True (-not ($lastMsg -match [regex]::Escape($scopes['BranchFiles']))) 'and does not claim the narrower scope it did not use'
    Assert-True ($scopes['Everything'] -ne $scopes['BranchFiles']) 'the two scopes are told apart by their words -- the whole point of #507'

    # --- (e) No PR interaction: park never invokes gh / opens a PR ---------------------------------
    Write-Host "park-branch.ps1 -- no PR is opened" -ForegroundColor Cyan
    # (b) already proved a full push; here we assert the source itself carries no PR/gh path, so a
    # future edit cannot silently turn park into a PR opener.
    $srcText = [System.IO.File]::ReadAllText($ParkBranchSrc, [System.Text.Encoding]::UTF8)
    Assert-True (-not ($srcText -match '(?m)^\s*[^#]*\bgh\b')) 'park: source contains no active gh/PR call'
} finally {
    foreach ($f in $script:fixtures) {
        if (Test-Path -LiteralPath $f) { Remove-Item -Recurse -Force -LiteralPath $f -ErrorAction SilentlyContinue }
    }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
