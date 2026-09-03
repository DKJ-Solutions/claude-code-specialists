<#
.SYNOPSIS
    Regression tests for scripts/sync/check-unfolded-entry.ps1 and the SessionStart hook that runs it
    (plugins/workflows/contributing-davekjohn/hooks/unfolded-entry-sessioncheck.ps1) -- issue #1270.

.DESCRIPTION
    Dependency-free: no Pester, only PowerShell. Integration style -- the REAL check script and its two
    libs are copied into a throwaway git repo under TEMP, commits are built there, and the check is run
    as a child process (it calls `exit`). No network and no gh: the check is purely local by design.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/unfolded-entry.tests.ps1

    The cases:
      1. a clean trunk                          -> [OK], exit 0
      2. an orphaned per-branch document        -> [ERROR] naming the branch + fold command, exit 1
      3. the pre-#1255 shared name              -> [ERROR], exit 1
      4. a reset-state leftover (declares trunk)-> [ERROR] with the "delete it" wording, exit 1
      5. an unresolvable ref                    -> [OK] "could not list", exit 0
      6. a leftover on local main but not origin-> origin/main is preferred, so [OK]
      7. the hook forwards [ERROR]/[SCOPE]      -> headline + lines, always exit 0
      8. the hook on a clean trunk              -> "no unfolded branch document", exit 0
      9. wiring: mirror in sync, registry entry, hooks.json entry

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot        = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$CheckSrc        = Join-Path $RepoRoot 'scripts\sync\check-unfolded-entry.ps1'
$CheckReportLib  = Join-Path $RepoRoot 'scripts\lib\check-report-lib.ps1'
$EntryScaffold   = Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1'
$HookSrc         = Join-Path $RepoRoot 'plugins\workflows\contributing-davekjohn\hooks\unfolded-entry-sessioncheck.ps1'
$MirrorSrc       = Join-Path $RepoRoot 'plugins\workflows\contributing-davekjohn\scripts\sync\check-unfolded-entry.ps1'
$HooksJson       = Join-Path $RepoRoot 'plugins\workflows\contributing-davekjohn\hooks\hooks.json'
$SharedScriptsLib= Join-Path $RepoRoot 'scripts\lib\shared-scripts-lib.ps1'

$script:pass = 0
$script:fail = 0
$script:fixtures = @()

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else            { $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red }
}

function Get-FlatOutput {
    param($Captured)
    return (($Captured | ForEach-Object { [string]$_ }) -join "`n")
}

function Invoke-FixtureGit {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $prev = $ErrorActionPreference
    try { $ErrorActionPreference = 'Continue'; & git @Arguments 2>$null | Out-Null }
    finally { $ErrorActionPreference = $prev }
}

function New-Fixture {
    <# A throwaway git repo on 'main' with the check + its two libs copied to scripts/, one initial
       commit. -WithOrigin also wires a bare repo as 'origin' and pushes main to it. #>
    param([switch]$WithOrigin)
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("ufe_" + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $null = New-Item -ItemType Directory -Path $root
    $script:fixtures += $root

    $null = New-Item -ItemType Directory -Path (Join-Path $root 'scripts\sync')
    $null = New-Item -ItemType Directory -Path (Join-Path $root 'scripts\lib')
    $null = New-Item -ItemType Directory -Path (Join-Path $root 'contributing-davekjohn')
    Copy-Item -LiteralPath $CheckSrc       -Destination (Join-Path $root 'scripts\sync\check-unfolded-entry.ps1')
    Copy-Item -LiteralPath $CheckReportLib -Destination (Join-Path $root 'scripts\lib\check-report-lib.ps1')
    Copy-Item -LiteralPath $EntryScaffold  -Destination (Join-Path $root 'scripts\lib\entry-scaffold-lib.ps1')

    Invoke-FixtureGit -Arguments @('-C', $root, 'init', '-b', 'main')
    Invoke-FixtureGit -Arguments @('-C', $root, 'config', 'user.email', 't@t.t')
    Invoke-FixtureGit -Arguments @('-C', $root, 'config', 'user.name', 'T')
    Set-Content -LiteralPath (Join-Path $root 'README.md') -Value '# fixture' -Encoding ascii
    Invoke-FixtureGit -Arguments @('-C', $root, 'add', '-A')
    Invoke-FixtureGit -Arguments @('-C', $root, 'commit', '-m', 'init')

    if ($WithOrigin) {
        $bare = Join-Path ([System.IO.Path]::GetTempPath()) ("ufe_o_" + [guid]::NewGuid().ToString('N').Substring(0, 10))
        $script:fixtures += $bare
        Invoke-FixtureGit -Arguments @('init', '--bare', $bare)
        Invoke-FixtureGit -Arguments @('-C', $root, 'remote', 'add', 'origin', $bare)
        Invoke-FixtureGit -Arguments @('-C', $root, 'push', '-u', 'origin', 'main')
    }
    return $root
}

function Add-DevDoc {
    <# Commit a development document at $RelPath on the current branch of $Root. #>
    param([string]$Root, [string]$RelPath, [string]$Content)
    $full = Join-Path $Root $RelPath
    $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $full)
    Set-Content -LiteralPath $full -Value $Content -Encoding ascii
    Invoke-FixtureGit -Arguments @('-C', $Root, 'add', '-A')
    Invoke-FixtureGit -Arguments @('-C', $Root, 'commit', '-m', "add $RelPath")
}

function Invoke-Check {
    param([string]$Root, [string]$TrunkRef = '')
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
        (Join-Path $Root 'scripts\sync\check-unfolded-entry.ps1'),
        '-ConsumerPathOverride', $Root)
    if ($TrunkRef) { $a += @('-TrunkRefOverride', $TrunkRef) }
    $out = & powershell @a 2>&1
    return [pscustomobject]@{ Out = (Get-FlatOutput $out); Code = $LASTEXITCODE }
}

function Invoke-Hook {
    param([string]$Root, [string]$TrunkRef = '')
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $HookSrc,
        '-CheckScriptOverride', (Join-Path $Root 'scripts\sync\check-unfolded-entry.ps1'),
        '-ConsumerPathOverride', $Root)
    if ($TrunkRef) { $a += @('-TrunkRefOverride', $TrunkRef) }
    $out = & powershell @a 2>&1
    return [pscustomobject]@{ Out = (Get-FlatOutput $out); Code = $LASTEXITCODE }
}

$filledDoc = @'
## Development: `fix/foo-v1`

### PLAN

work

### DEPLOY: `fix/foo-v1`

Does a thing.
'@

$sharedNameDoc = @'
## Development: `feat/bar-v1`

### DEPLOY: `feat/bar-v1`

Bar.
'@

$resetDoc = @'
# Development: `main`

The reset state.
'@

try {
    # --- 1. clean trunk ---------------------------------------------------------------------------
    Write-Host "1. a clean trunk" -ForegroundColor Cyan
    $f = New-Fixture
    $r = Invoke-Check -Root $f -TrunkRef 'main'
    Assert-True ($r.Code -eq 0) 'clean: exit 0'
    Assert-True ($r.Out -match '\[OK\]') 'clean: reports [OK]'
    Assert-True ($r.Out -notmatch '\[ERROR\]') 'clean: no [ERROR]'

    # --- 2. an orphaned per-branch document -----------------------------------------------------
    Write-Host "2. an orphaned per-branch development document on the trunk" -ForegroundColor Cyan
    $f = New-Fixture
    Add-DevDoc -Root $f -RelPath 'contributing-davekjohn/development-fix-foo-v1.md' -Content $filledDoc
    $r = Invoke-Check -Root $f -TrunkRef 'main'
    Assert-True ($r.Code -eq 1) 'orphan: exit 1'
    Assert-True ($r.Out -match '\[ERROR\]') 'orphan: reports [ERROR]'
    Assert-True ($r.Out -match 'development-fix-foo-v1\.md') 'orphan: names the file'
    Assert-True ($r.Out -match "fold-changelog-entry\.ps1 -Branch fix/foo-v1") 'orphan: names the fold command with the declared branch'
    Assert-True ($r.Out -match "never reached CHANGELOG\.md") 'orphan: explains the entry never folded'

    # --- 3. the pre-#1255 shared name ----------------------------------------------------------
    Write-Host "3. the pre-#1255 shared name (contributing-davekjohn/development.md)" -ForegroundColor Cyan
    $f = New-Fixture
    Add-DevDoc -Root $f -RelPath 'contributing-davekjohn/development.md' -Content $sharedNameDoc
    $r = Invoke-Check -Root $f -TrunkRef 'main'
    Assert-True ($r.Code -eq 1) 'shared-name: exit 1'
    Assert-True ($r.Out -match 'contributing-davekjohn/development\.md is committed') 'shared-name: names the file'
    Assert-True ($r.Out -match '-Branch feat/bar-v1') 'shared-name: reads the declared branch from the heading'

    # --- 4. a reset-state leftover (declares the trunk) --------------------------------------
    Write-Host "4. a reset-state leftover that declares the trunk" -ForegroundColor Cyan
    $f = New-Fixture
    Add-DevDoc -Root $f -RelPath 'contributing-davekjohn/development-fix-old-v1.md' -Content $resetDoc
    $r = Invoke-Check -Root $f -TrunkRef 'main'
    Assert-True ($r.Code -eq 1) 'reset: exit 1'
    Assert-True ($r.Out -match "declares the trunk") 'reset: says it declares the trunk'
    Assert-True ($r.Out -match "Delete it") 'reset: tells the reader to delete it, not fold it'
    Assert-True ($r.Out -notmatch "fold-changelog-entry\.ps1 -Branch") 'reset: does not offer a fold command'

    # --- 4b. DEVELOPMENT-portable.md is NOT a finding (case-sensitive match) -----------------
    Write-Host "4b. contributing-davekjohn/DEVELOPMENT-portable.md on the trunk is not a finding" -ForegroundColor Cyan
    $f = New-Fixture
    Add-DevDoc -Root $f -RelPath 'contributing-davekjohn/DEVELOPMENT-portable.md' -Content "# The development document, in prose`n`nReference copy."
    $r = Invoke-Check -Root $f -TrunkRef 'main'
    Assert-True ($r.Code -eq 0) 'portable-doc: exit 0 -- the case-insensitive glob would have matched this'
    Assert-True ($r.Out -notmatch '\[ERROR\]') 'portable-doc: no [ERROR] for the portable reference doc'

    # --- 5. an unresolvable ref -------------------------------------------------------------
    Write-Host "5. an unresolvable trunk ref" -ForegroundColor Cyan
    $f = New-Fixture
    $r = Invoke-Check -Root $f -TrunkRef 'refs/heads/nope-not-a-ref'
    Assert-True ($r.Code -eq 0) 'no-ref: exit 0 (an authority that cannot be read is not a finding)'
    Assert-True ($r.Out -match '\[OK\]') 'no-ref: reports [OK]'
    Assert-True ($r.Out -notmatch '\[ERROR\]') 'no-ref: no [ERROR]'

    # --- 6. origin/main is preferred over local main ------------------------------------------
    Write-Host "6. a leftover on local main only -- origin/main is inspected and is clean" -ForegroundColor Cyan
    $f = New-Fixture -WithOrigin
    Add-DevDoc -Root $f -RelPath 'contributing-davekjohn/development-fix-local-v1.md' -Content $filledDoc
    $r = Invoke-Check -Root $f      # no override: resolves origin/main, then local main
    Assert-True ($r.Code -eq 0) 'origin-pref: exit 0 -- origin/main carries no leftover'
    Assert-True ($r.Out -match "origin/main") 'origin-pref: the [OK] line names origin/main'
    # and pointed explicitly at local main it does see the leftover
    $r2 = Invoke-Check -Root $f -TrunkRef 'refs/heads/main'
    Assert-True ($r2.Code -eq 1) 'origin-pref: local main does carry it when inspected directly'

    # --- 7. the hook forwards a finding ----------------------------------------------------
    Write-Host "7. the SessionStart hook forwards [ERROR]/[SCOPE]" -ForegroundColor Cyan
    $f = New-Fixture
    Add-DevDoc -Root $f -RelPath 'contributing-davekjohn/development-fix-hook-v1.md' -Content $filledDoc
    $r = Invoke-Hook -Root $f -TrunkRef 'main'
    Assert-True ($r.Code -eq 0) 'hook/error: always exit 0'
    Assert-True ($r.Out -match 'a fold was skipped after a merge') 'hook/error: headline'
    Assert-True ($r.Out -match '\[SCOPE\]') 'hook/error: forwards the [SCOPE] line'
    Assert-True ($r.Out -match '\[ERROR\]') 'hook/error: forwards the [ERROR] line'
    Assert-True ($r.Out -match 'development-fix-hook-v1\.md') 'hook/error: the forwarded line still names the file'

    # --- 8. the hook on a clean trunk ---------------------------------------------------
    Write-Host "8. the hook on a clean trunk" -ForegroundColor Cyan
    $f = New-Fixture
    $r = Invoke-Hook -Root $f -TrunkRef 'main'
    Assert-True ($r.Code -eq 0) 'hook/clean: exit 0'
    Assert-True ($r.Out -match 'no unfolded branch document on the trunk') 'hook/clean: the clean line'
    Assert-True ($r.Out -notmatch '\[ERROR\]') 'hook/clean: no [ERROR]'

    # --- 9. wiring -------------------------------------------------------------------
    Write-Host "9. wiring: mirror, registry, hooks.json" -ForegroundColor Cyan
    $srcNorm    = ([System.IO.File]::ReadAllText($CheckSrc)    -replace "`r`n", "`n")
    $mirrorNorm = ([System.IO.File]::ReadAllText($MirrorSrc)   -replace "`r`n", "`n")
    Assert-True ($srcNorm -eq $mirrorNorm) 'wiring: the plugin mirror is LF-identical to the source (run build-shared-scripts.ps1)'
    $reg = [System.IO.File]::ReadAllText($SharedScriptsLib)
    Assert-True ($reg -match "Name\s*=\s*'check-unfolded-entry'") 'wiring: registered in shared-scripts-lib.ps1'
    Assert-True ($reg -match "Source\s*=\s*'scripts\\sync\\check-unfolded-entry\.ps1'") 'wiring: the registry names the source path'
    $hooks = [System.IO.File]::ReadAllText($HooksJson) | ConvertFrom-Json
    $cmds = @($hooks.hooks.SessionStart[0].hooks | ForEach-Object { $_.command })
    Assert-True (@($cmds | Where-Object { $_ -match 'unfolded-entry-sessioncheck\.ps1' }).Count -eq 1) 'wiring: hooks.json registers the SessionStart hook exactly once'
} finally {
    foreach ($x in $script:fixtures) {
        if ($x -and (Test-Path -LiteralPath $x)) { Remove-Item -Recurse -Force -LiteralPath $x -ErrorAction SilentlyContinue }
    }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "Result: $($script:pass) pass, $($script:fail) fail." -ForegroundColor Red
    exit 1
}
Write-Host "Result: $($script:pass) pass, 0 fail." -ForegroundColor Green
exit 0
