<#
.SYNOPSIS
    Tests for the shared lens-location helpers in scripts/lib/check-report-lib.ps1.

.DESCRIPTION
    These functions decide WHERE a consumer's repo lenses live, which makes them the single point every
    reader (the roster check, the drift lint, the teardown) and every writer (the bootstrap) agrees on.
    They had no direct test before the seam (issue #221) was added -- only indirect coverage through the
    suites that happen to call them, which is exactly the kind of shared decision that deserves its own
    assertions.

    The interesting one is Get-LensWriteDir. It encodes a promise that is easy to break by accident:
    the bootstrap never relocates a lens tree the repo owner already has, so a consumer who adopted
    before the seam keeps their layout, and a consumer who migrates by hand is followed automatically.

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $RepoRoot 'scripts\lib\check-report-lib.ps1')

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

$Fixture = Join-Path ([System.IO.Path]::GetTempPath()) "check-report-lib-test-$PID"

try {
    Write-Host "== check-report-lib.tests: lens locations and the seam ==" -ForegroundColor Cyan
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null

    # --- 1. Get-SeamPaths: the literals the bootstrap writes and the teardown matches ---------------
    #     One source for both sides. If these drift the bootstrap writes a line the teardown cannot
    #     find, and the consumer is left with a dangling import -- silent, because nothing errors.
    Write-Host "Get-SeamPaths -- the shared literals" -ForegroundColor Cyan
    $seam = Get-SeamPaths -RepoRoot $Fixture
    Assert-Equal (Join-Path $Fixture '.claude\specialists') $seam.Dir 'seam dir is .claude\specialists'
    Assert-Equal (Join-Path $Fixture '.claude\specialists\lenses') $seam.LensDir 'lenses live in the seam dir'
    Assert-Equal (Join-Path $Fixture '.claude\specialists\SPECIALISTS.md') $seam.Inclusion 'the inclusion is SPECIALISTS.md'
    Assert-Equal '@.claude/specialists/SPECIALISTS.md' $seam.ImportLine 'the import line is exactly the seam line'
    # An '@'-import path is not a filesystem path: it must read identically on every platform, so a
    # backslash must never leak into it from Join-Path.
    Assert-True (-not ($seam.ImportLine -match '\\')) 'the import line is forward-slashed, never backslashed'

    # --- 2. Get-LensDirCandidates: the seam is the most canonical, legacy still follows -------------
    Write-Host "Get-LensDirCandidates -- order and back-compat" -ForegroundColor Cyan
    $cands = @(Get-LensDirCandidates -RepoRoot $Fixture -PluginName 'specialists')
    Assert-Equal $seam.LensDir $cands[0] 'the seam is candidate 0 -- the most canonical'
    Assert-True ($cands -contains (Join-Path $Fixture '.claude\plugins\claude-specialists\specialists')) 'the pre-seam plugin path is still read'
    Assert-Equal (Join-Path $Fixture '.claude\extensions') $cands[-1] 'the legacy pre-plugin-path location is still read, and stays last'

    # --- 3. Get-LensWriteDir: THE PROMISE -- never relocate an existing tree ------------------------
    #     Fresh consumer -> the seam. A consumer that already has lenses somewhere -> that same place,
    #     because writing seam lenses beside a legacy tree would split the surface in two and leave the
    #     teardown reasoning about both at once.
    Write-Host "Get-LensWriteDir -- fresh gets the seam, an adopted consumer is left alone" -ForegroundColor Cyan
    Assert-Equal $seam.LensDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'specialists') 'fresh consumer: writes to the seam'

    $legacyDir = Join-Path $Fixture '.claude\plugins\claude-specialists\specialists'
    New-Item -ItemType Directory -Path $legacyDir -Force | Out-Null
    $legacyLens = Join-Path $legacyDir '06-16-extension.md'
    [System.IO.File]::WriteAllText($legacyLens, "# 06-16 repo lens`n")
    Assert-Equal $legacyDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'specialists') 'adopted consumer: keeps writing to its existing tree, not the seam'

    # An EMPTY legacy directory is not an adopted consumer -- only an actual lens counts, so a stray
    # leftover folder does not pin a fresh repo to the old layout.
    Remove-Item -LiteralPath $legacyLens -Force
    Assert-Equal $seam.LensDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'specialists') 'an empty legacy directory does not count as adopted'

    # And once the owner migrates by hand, the writer follows them without being told.
    New-Item -ItemType Directory -Path $seam.LensDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $seam.LensDir '06-16-extension.md'), "# 06-16 repo lens`n")
    Assert-Equal $seam.LensDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'specialists') 'after a hand migration the writer follows to the seam automatically'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
