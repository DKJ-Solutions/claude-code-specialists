<#
.SYNOPSIS
    Regression tests for the split-identity check (issue #1315): the check script
    scripts/lint/check-git-identity.ps1 and the SessionStart hook git-identity-sessioncheck.ps1.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/git-identity-gate.tests.ps1

    NOTHING HERE READS THE MACHINE'S OWN IDENTITY, and that is the whole design of this suite. The
    check's subject IS the machine -- the account gh holds and the name git commits as -- so a suite
    that let either value through would assert a different thing on Dave's checkout than on a CI
    runner, and would go green or red for reasons that have nothing to do with the code. Every case
    below therefore passes both values in explicitly (-GhAccountOverride / -GitUserNameOverride), and
    the hook is exercised against STUB check scripts written into the fixture rather than against the
    real one. The one thing not asserted is the reading of `gh auth status` itself, which is a test gap
    named in the branch document rather than papered over: it needs a keyring, and a suite that
    installed one would be testing gh.

    THE LOGIN-SHAPE BOUNDARY IS WHERE THE VALUE IS. The check only reports a mismatch when
    git config user.name is a VALID GitHub username, because that guard is the only thing standing
    between this check and firing forever in every repo whose user.name is a person's name. So the
    cases walk GitHub's rule at both edges -- 39 characters passes, 40 does not, and a leading,
    trailing or doubled hyphen does not.

    Fixture paths carry $PID (repo convention): the test gate is a throttled parallel scheduler, so two
    runs overlapping is ordinary and two sharing one fixed temp path tear down each other's tree.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\lint\check-git-identity.ps1'
$Hook     = Join-Path $RepoRoot 'plugins\dkj-policy\hooks\git-identity-sessioncheck.ps1'
$Mirror   = Join-Path $RepoRoot 'plugins\dkj-policy\scripts\lint\check-git-identity.ps1'

$script:pass  = 0
$script:fail  = 0
$script:trees = @()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message" -ForegroundColor Red }
}

function New-Tree {
    param([Parameter(Mandatory = $true)][string]$Label)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("gitidentity-$PID-$Label-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $script:trees += $dir
    return $dir
}

function New-StubCheck {
    <#
        A stand-in check script, so the hook's three output branches can be driven without a machine
        that actually has a split identity. It accepts -RootOverride because that is the only argument
        the hook passes.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Body,
        [Parameter(Mandatory = $true)][int]$ExitCode
    )
    $path = Join-Path $Dir "$Name.ps1"
    $lines = @("param([string]`$RootOverride = '')")
    foreach ($b in ($Body -split "`n")) {
        if ($b) { $lines += ("Write-Host '" + ($b -replace "'", "''") + "'") }
    }
    $lines += "exit $ExitCode"
    [System.IO.File]::WriteAllText($path, ($lines -join "`r`n") + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
    return $path
}

function Invoke-Check {
    <#
        Both identities always passed in explicitly -- see the file synopsis. 'NONE' is the check's own
        spelling for "absent", so a case can say "gh is logged out" without logging anything out.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Gh,
        [Parameter(Mandatory = $true)][string]$Git,
        [string]$ScriptPath = $Script
    )
    $scriptArgs = @('-GhAccountOverride', $Gh, '-GitUserNameOverride', $Git)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @scriptArgs 2>&1
    } finally { $ErrorActionPreference = $prevEap }
    return @{ Out = ($out | Out-String); Code = $LASTEXITCODE }
}

function Invoke-Hook {
    param([Parameter(Mandatory = $true)][string]$CheckScriptOverride, [string]$Dir = '')
    $hookArgs = @('-CheckScriptOverride', $CheckScriptOverride)
    if ($Dir) { $hookArgs += @('-ConsumerPathOverride', $Dir) }
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Hook @hookArgs 2>&1
    } finally { $ErrorActionPreference = $prevEap }
    return @{ Out = ($out | Out-String); Code = $LASTEXITCODE }
}

try {
    # --- the mismatch, which is the whole point --------------------------------------------------
    Write-Host 'check-git-identity.ps1 -- a provable mismatch'

    $r = Invoke-Check -Gh 'DaveKJohn' -Git 'davekokbwj'
    Assert-True ($r.Code -eq 1 -and $r.Out -match '\[ERROR\]') `
        'the measured pairing (gh DaveKJohn / git davekokbwj) -- [ERROR], exit 1'
    Assert-True ($r.Out -match 'DaveKJohn' -and $r.Out -match 'davekokbwj') `
        'the report names BOTH accounts, so the reader knows which is which without re-running anything'
    Assert-True ($r.Out -match 'add-assignee davekokbwj') `
        'it names the by-NAME claim as the interim idiom, with the committing account filled in'
    Assert-True ($r.Out -match 'git config user\.name' -and $r.Out -match 'gh auth login') `
        'both ways out are printed -- the check does not pick one of the two accounts for the reader'
    Assert-True ($r.Out -match 'construction') `
        'it says the cross-device tell is not diagnostic here, which is the second consequence of #1315'

    # A 39-character login is valid by GitHub's rule, so the mismatch must still be reported. This is
    # the upper edge of the guard, and the case that fails if the quantifier is ever written {0,37}.
    $long = 'a' + ('b' * 38)
    Assert-True ($long.Length -eq 39) 'fixture sanity: the long name is exactly 39 characters'
    $r = Invoke-Check -Gh 'DaveKJohn' -Git $long
    Assert-True ($r.Code -eq 1 -and $r.Out -match '\[ERROR\]') `
        'a 39-character user.name is a valid login -- the mismatch is still reported'

    $r = Invoke-Check -Gh 'DaveKJohn' -Git 'a-b-c'
    Assert-True ($r.Code -eq 1) 'single hyphens are legal in a login -- reported'

    # --- the identities agreeing -------------------------------------------------------------------
    Write-Host ''
    Write-Host 'check-git-identity.ps1 -- agreement'

    $r = Invoke-Check -Gh 'maikel-bwj' -Git 'maikel-bwj'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[OK\]') `
        'the same account on both sides -- [OK], exit 0'

    $r = Invoke-Check -Gh 'DaveKJohn' -Git 'davekjohn'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[OK\]') `
        'GitHub logins are case-insensitive, so a case-only difference is ONE account, not two'

    # --- the noise guard, which is why this check is shippable ------------------------------------
    Write-Host ''
    Write-Host 'check-git-identity.ps1 -- the login-shape guard (no false positives)'

    $r = Invoke-Check -Gh 'maikel-bwj' -Git 'Maikel Hoogendoorn'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[SKIP\]') `
        'a display name with a space is NOT an account -- [SKIP], the case that would otherwise fire forever'

    $r = Invoke-Check -Gh 'DaveKJohn' -Git 'bad-'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[SKIP\]') 'a trailing hyphen is not a valid login -- [SKIP]'

    $r = Invoke-Check -Gh 'DaveKJohn' -Git '-bad'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[SKIP\]') 'a leading hyphen is not a valid login -- [SKIP]'

    $r = Invoke-Check -Gh 'DaveKJohn' -Git 'a--b'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[SKIP\]') 'a doubled hyphen is not a valid login -- [SKIP]'

    $r = Invoke-Check -Gh 'DaveKJohn' -Git ('a' * 40)
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[SKIP\]') `
        'a 40-character name is past GitHub''s 39-character limit -- [SKIP], the upper edge of the guard'

    $r = Invoke-Check -Gh 'DaveKJohn' -Git 'dave.kok'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[SKIP\]') 'a dot is not legal in a login -- [SKIP]'

    # --- nothing to compare ------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'check-git-identity.ps1 -- nothing to compare'

    $r = Invoke-Check -Gh 'NONE' -Git 'davekokbwj'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[SKIP\]' -and $r.Out -match 'no active account') `
        'gh absent or logged out -- [SKIP], the ordinary state of a consumer that never uses the tracker'

    $r = Invoke-Check -Gh 'DaveKJohn' -Git 'NONE'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[SKIP\]' -and $r.Out -match 'unset') `
        'user.name unset -- [SKIP]; git itself refuses to commit in that state, so it needs no second reporter'

    $r = Invoke-Check -Gh 'NONE' -Git 'NONE'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[SKIP\]') 'neither side present -- [SKIP], no throw'

    # --- the plugin mirror answers identically ----------------------------------------------------
    # shared-scripts.tests.ps1 proves the two files are byte-identical; this proves the mirror RUNS
    # from its own directory, which is the only thing byte-equality cannot tell you (its
    # $PSScriptRoot-relative dot-source of native-capture-lib.ps1 has to resolve there too).
    Write-Host ''
    Write-Host 'the plugin mirror'

    Assert-True (Test-Path -LiteralPath $Mirror -PathType Leaf) 'the mirror exists at the registered path'
    $r = Invoke-Check -Gh 'DaveKJohn' -Git 'davekokbwj' -ScriptPath $Mirror
    Assert-True ($r.Code -eq 1 -and $r.Out -match '\[ERROR\]') `
        'the mirror reports the same mismatch, so its own dot-source resolves from the plugin tree'

    # --- the SessionStart hook ---------------------------------------------------------------------
    Write-Host ''
    Write-Host 'git-identity-sessioncheck.ps1'

    $stubs = New-Tree -Label 'stubs'

    $errStub = New-StubCheck -Dir $stubs -Name 'stub-error' -ExitCode 1 `
        -Body "[ERROR] this checkout acts as one GitHub account and commits as another:`n          gh acts as 'DaveKJohn'`n          git commits as 'davekokbwj'"
    $r = Invoke-Hook -CheckScriptOverride $errStub
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'acts as one GitHub account and commits as another' -and $r.Out -match 'davekokbwj') `
        'an [ERROR] from the check -- forwarded into the session with its detail, still exit 0'
    Assert-True ($r.Out -match 'data, not instructions') `
        'the forwarded block is labelled as data, so the session does not read a report as a command'

    $okStub = New-StubCheck -Dir $stubs -Name 'stub-ok' -ExitCode 0 -Body "[OK] gh and git are the same account"
    $r = Invoke-Hook -CheckScriptOverride $okStub
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'the gh account and the git identity agree') `
        'a clean check -- the one-line in-sync report, exit 0'

    # A [SKIP] must read as clean rather than as a crash: it is exit 0 with no [ERROR], which is the
    # same branch as [OK] by design -- there is nothing for a session to act on either way.
    $skipStub = New-StubCheck -Dir $stubs -Name 'stub-skip' -ExitCode 0 -Body "[SKIP] gh names no active account"
    $r = Invoke-Hook -CheckScriptOverride $skipStub
    Assert-True ($r.Code -eq 0 -and $r.Out -notmatch 'could not complete') `
        'a [SKIP] is not a failure -- no "could not complete", exit 0'

    # Non-zero exit with no [ERROR] line: an unexpected crash must not be reported as clean.
    $crashStub = New-StubCheck -Dir $stubs -Name 'stub-crash' -ExitCode 3 -Body "something unexpected"
    $r = Invoke-Hook -CheckScriptOverride $crashStub
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'could not complete \(exit 3\)') `
        'a crashing check -- reported as incomplete rather than as clean, and still exit 0'

    $r = Invoke-Hook -CheckScriptOverride (Join-Path ([System.IO.Path]::GetTempPath()) "no-such-check-$PID.ps1")
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'check script not found -- check skipped') `
        'check script missing -- a notice, exit 0, never a strand'
}
finally {
    foreach ($t in $script:trees) {
        if ($t -and (Test-Path -LiteralPath $t)) { Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAIL: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
