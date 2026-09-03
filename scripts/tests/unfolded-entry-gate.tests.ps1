<#
.SYNOPSIS
    Regression tests for the skipped-fold guard (issue #1270): Get-UnfoldedTrunkEntry in
    entry-scaffold-lib.ps1, the check script scripts/lint/check-unfolded-entry.ps1, and the
    SessionStart hook unfolded-entry-sessioncheck.ps1.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell and git.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/unfolded-entry-gate.tests.ps1

    THE DOCUMENT STATES COME FROM THE REAL FORMATTER, never from a literal here. Format-Development
    -Branch 'feat/x' IS a written branch document and Format-Development -Branch '' IS the trunk/reset
    state -- so a change to either shape reaches these cases automatically, instead of a third
    definition of the format going stale in the file whose job is to prove there are not two.

    Fixture paths carry $PID (repo convention): the test gate is a throttled parallel scheduler, so two
    runs overlapping is ordinary and two sharing one fixed temp path tear down each other's tree.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\lint\check-unfolded-entry.ps1'
$Hook     = Join-Path $RepoRoot 'plugins\workflows\contributing-davekjohn\hooks\unfolded-entry-sessioncheck.ps1'
. (Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1')

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
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("unfoldedgate-$PID-$Label-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    New-Item -ItemType Directory -Path (Join-Path $dir 'contributing-davekjohn') -Force | Out-Null
    $script:trees += $dir
    return $dir
}

function Set-Doc {
    # Write a development document at its per-branch path (or the shared name), content from the real
    # formatter. -Branch '' writes the trunk/reset state.
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Branch,
        [switch]$SharedName
    )
    $rel = if ($SharedName) { (Get-BranchFilePaths).SharedFile } else { (Get-BranchFilePaths -Branch $Branch).File }
    if (-not $Branch -and -not $SharedName) { $rel = (Get-BranchFilePaths).SharedFile }
    $target = Join-Path $Dir ($rel -replace '/', '\')
    $parent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $text = (Format-Development -Branch $Branch) -join "`n"
    [System.IO.File]::WriteAllText($target, $text + "`n", (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-Script {
    param([Parameter(Mandatory = $true)][string]$Dir, [string]$Branch = '')
    $args = @('-RootOverride', $Dir)
    if ($Branch) { $args += @('-Branch', $Branch) }
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script @args 2>&1
    } finally { $ErrorActionPreference = $prevEap }
    return @{ Out = ($out | Out-String); Code = $LASTEXITCODE }
}

function Invoke-Hook {
    # -CheckScriptOverride defaults to the source check script: a bare test run has no
    # CLAUDE_PLUGIN_ROOT, which is the hook's only other way to find it. Pass an explicit path to
    # exercise the "not found" branch.
    param([Parameter(Mandatory = $true)][string]$Dir, [string]$CheckScriptOverride = $Script)
    $args = @('-ConsumerPathOverride', $Dir)
    if ($CheckScriptOverride) { $args += @('-CheckScriptOverride', $CheckScriptOverride) }
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Hook @args 2>&1
    } finally { $ErrorActionPreference = $prevEap }
    return @{ Out = ($out | Out-String); Code = $LASTEXITCODE }
}

try {
    # --- Get-UnfoldedTrunkEntry, the detector ------------------------------------------------------
    Write-Host 'Get-UnfoldedTrunkEntry'

    $empty = New-Tree -Label 'empty'
    Assert-True (@(Get-UnfoldedTrunkEntry -RepoRoot $empty -CurrentBranch 'main').Count -eq 0) `
        'empty contributing-davekjohn/ -- no findings'

    $nodir = Join-Path ([System.IO.Path]::GetTempPath()) ("unfoldedgate-$PID-nodir-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    Assert-True (@(Get-UnfoldedTrunkEntry -RepoRoot $nodir -CurrentBranch 'main').Count -eq 0) `
        'no contributing-davekjohn/ directory at all -- no findings, no throw'

    $onMain = New-Tree -Label 'onmain'
    Set-Doc -Dir $onMain -Branch 'feat/alpha'
    $f = @(Get-UnfoldedTrunkEntry -RepoRoot $onMain -CurrentBranch 'main')
    Assert-True ($f.Count -eq 1 -and $f[0].DeclaredBranch -eq 'feat/alpha' -and $f[0].Rel -match 'development-feat-alpha\.md$') `
        'a written per-branch doc, HEAD = main -- one finding naming the file and the branch it declares'

    $onOwn = New-Tree -Label 'onown'
    Set-Doc -Dir $onOwn -Branch 'feat/alpha'
    Assert-True (@(Get-UnfoldedTrunkEntry -RepoRoot $onOwn -CurrentBranch 'feat/alpha').Count -eq 0) `
        "the branch's own document is not a leftover when HEAD is that branch"

    $mixed = New-Tree -Label 'mixed'
    Set-Doc -Dir $mixed -Branch 'feat/alpha'
    Set-Doc -Dir $mixed -Branch 'fix/beta'
    $f = @(Get-UnfoldedTrunkEntry -RepoRoot $mixed -CurrentBranch 'feat/alpha')
    Assert-True ($f.Count -eq 1 -and $f[0].DeclaredBranch -eq 'fix/beta') `
        "on feat/alpha with a fix/beta leftover beside it -- only the leftover is reported"

    $reset = New-Tree -Label 'reset'
    Set-Doc -Dir $reset -Branch ''
    Assert-True (@(Get-UnfoldedTrunkEntry -RepoRoot $reset -CurrentBranch 'main').Count -eq 0) `
        'a reset-state development.md (declares the trunk) is not a leftover'

    $shared = New-Tree -Label 'shared'
    Set-Doc -Dir $shared -Branch 'feat/gamma' -SharedName
    $f = @(Get-UnfoldedTrunkEntry -RepoRoot $shared -CurrentBranch 'main')
    Assert-True ($f.Count -eq 1 -and $f[0].DeclaredBranch -eq 'feat/gamma' -and $f[0].Rel -match 'development\.md$') `
        'the pre-#1255 shared name development.md is checked too, though the glob would miss it'

    # --- check-unfolded-entry.ps1, the gate ------------------------------------------------------
    Write-Host ''
    Write-Host 'check-unfolded-entry.ps1'

    $r = Invoke-Script -Dir (New-Tree -Label 'gate-clean') -Branch 'main'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[OK\] no unfolded changelog entry') `
        'clean trunk fixture -- [OK], exit 0'

    $gd = New-Tree -Label 'gate-dirty'
    Set-Doc -Dir $gd -Branch 'feat/alpha'
    $r = Invoke-Script -Dir $gd -Branch 'main'
    Assert-True ($r.Code -eq 1 -and $r.Out -match '\[ERROR\]' -and $r.Out -match 'feat/alpha' -and $r.Out -match 'fold-changelog-entry\.ps1 -Branch feat/alpha') `
        'leftover present, -Branch main -- [ERROR] exit 1, names the file, the branch and the fold command'

    $r = Invoke-Script -Dir $gd -Branch 'feat/alpha'
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[OK\]') `
        'same tree, -Branch feat/alpha -- its own document is expected, [OK] exit 0'

    # --- unfolded-entry-sessioncheck.ps1, the hook (always exit 0) --------------------------------
    Write-Host ''
    Write-Host 'unfolded-entry-sessioncheck.ps1'

    $r = Invoke-Hook -Dir (New-Tree -Label 'hook-clean')
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'no unfolded changelog entry on the trunk') `
        'clean trunk -- the in-sync line, exit 0'

    $hd = New-Tree -Label 'hook-dirty'
    Set-Doc -Dir $hd -Branch 'feat/alpha'
    $r = Invoke-Hook -Dir $hd
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'an unfolded changelog entry is sitting on the trunk' -and $r.Out -match 'feat/alpha') `
        'leftover on the trunk -- a compact summary carrying the [ERROR] detail, still exit 0'

    $r = Invoke-Hook -Dir (New-Tree -Label 'hook-nocheck') -CheckScriptOverride (Join-Path ([System.IO.Path]::GetTempPath()) "no-such-check-$PID.ps1")
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
