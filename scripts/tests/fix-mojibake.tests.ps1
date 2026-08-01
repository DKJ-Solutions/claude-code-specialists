<#
.SYNOPSIS
    Tests for scripts/maintenance/fix-mojibake.ps1 and the lint gate that consults it (check 14).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Exit code 0 if everything passes, 1 on a
    failure -- so usable as a CI gate.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/fix-mojibake.tests.ps1

    WHY THIS SUITE EXISTS, measured August 1, 2026. Demoting four headings in CHANGELOG.md with
    Get-Content + WriteAllLines mangled 35 separators into 105 double-encoded sequences. Windows
    PowerShell 5.1's Get-Content reads a BOM-less UTF-8 file as ANSI, so a middot (U+00B7, bytes C2 B7)
    comes back as two characters, and writing that back as UTF-8 stores the mangled pair. NOTHING ERRORS:
    the file stays valid UTF-8 and simply says something else.

    It was not cosmetic. The middot IS the field delimiter in a changelog entry heading, so
    cut-release.ps1 could no longer read the entry TYPE and eleven entries fell into a catch-all category
    instead of Features/Fixes/Documentation. It was caught by inspecting the generated notes before
    pushing -- one person looking carefully at the right moment, which is exactly what a gate is for.

    THIS FILE IS PURE ASCII, like the script it tests: every non-ASCII character is built from
    codepoints. A test for mojibake that is itself written in literal mangled characters corrupts on the
    first careless edit and then asserts nothing.

    Third repo to meet this class (smartwatchbanden -> life-hub -> here), so the suite asserts the two
    properties that make the tool trustworthy rather than merely present: the fixpoint loop (double
    damage needs two passes) and idempotence (a second run changes nothing).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (git rev-parse --show-toplevel).Trim()
$Script = Join-Path $RepoRoot 'scripts\maintenance\fix-mojibake.ps1'
$Lint = Join-Path $RepoRoot 'scripts\lint\check-plugin-integrity.ps1'

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}
function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red }
}

# Build strings from codepoints, so this source stays ASCII-only.
function C([int[]]$cp) { -join ($cp | ForEach-Object { [char]$_ }) }
$MIDDOT = C 0xB7          # the correct character
$ONCE = C 0xC2, 0xB7      # mangled once
$TWICE = C 0xC3, 0x201A, 0xC2, 0xB7  # mangled twice -- what a second round trip leaves
$EMDASH = C 0x2014
$EMDASH_BAD = C 0xE2, 0x20AC, 0x201D

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
$Fixture = Join-Path ([System.IO.Path]::GetTempPath()) ("mojibake-fix-$PID")
New-Item -ItemType Directory -Path $Fixture -Force | Out-Null

function Invoke-Fix {
    param([string]$FilePath, [switch]$CheckOnly)
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Script, '-Path', $FilePath)
    if ($CheckOnly) { $a += '-Check' }
    $out = (& powershell @a 2>&1 | Out-String)
    return [pscustomobject]@{ Out = ($out -replace '\s+', ' '); Code = $LASTEXITCODE }
}

function Set-Fixture {
    param([string]$Name, [string]$Text, [switch]$WithBom)
    $p = Join-Path $Fixture $Name
    $enc = New-Object System.Text.UTF8Encoding ([bool]$WithBom)
    [System.IO.File]::WriteAllText($p, $Text, $enc)
    return $p
}
function Get-FixtureText {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

try {
    Write-Host 'A single mangled separator is repaired' -ForegroundColor Cyan
    $f = Set-Fixture -Name 'one.md' -Text ("### #1 $ONCE Title $ONCE Fix $ONCE 2026-08-01")
    $r = Invoke-Fix -FilePath $f
    Assert-Equal 0 $r.Code 'exits 0'
    $t = Get-FixtureText -Path $f
    Assert-Equal 3 (@([regex]::Matches($t, [regex]::Escape($MIDDOT))).Count) 'all three separators are correct middots'
    Assert-True ($t -notmatch [regex]::Escape($ONCE)) 'no mangled sequence survives'

    Write-Host 'DOUBLE damage needs the fixpoint loop, not one pass' -ForegroundColor Cyan
    #      The property that cost life-hub a manual fix at v2.1.0: one pass peels the outer layer and
    #      leaves a remainder that matches no rule. If the loop is ever replaced by a single pass, this
    #      is the assert that fails.
    $f2 = Set-Fixture -Name 'twice.md' -Text ("### #2 $TWICE Title $TWICE Docs")
    $r2 = Invoke-Fix -FilePath $f2
    $t2 = Get-FixtureText -Path $f2
    Assert-Equal 2 (@([regex]::Matches($t2, [regex]::Escape($MIDDOT))).Count) 'doubly mangled separators come out as middots'
    Assert-True ($t2 -notmatch [regex]::Escape($ONCE)) 'and no half-peeled remainder is left behind'

    Write-Host 'Idempotent: a second run changes nothing' -ForegroundColor Cyan
    $before = Get-FixtureText -Path $f2
    $r3 = Invoke-Fix -FilePath $f2
    Assert-Equal $before (Get-FixtureText -Path $f2) 'the file is byte-for-byte unchanged on a second run'
    Assert-True ($r3.Out -match 'Nothing to repair') 'and it says so rather than reporting phantom replacements'

    Write-Host 'Correctly encoded text is left alone' -ForegroundColor Cyan
    #      The direction of error that matters: this tool may only ever repair, never invent. A middot and
    #      an em dash that are already right must survive untouched.
    $good = "### #3 $MIDDOT A title with an em dash $EMDASH here $MIDDOT Feat"
    $f4 = Set-Fixture -Name 'good.md' -Text $good
    $r4 = Invoke-Fix -FilePath $f4
    Assert-Equal $good (Get-FixtureText -Path $f4) 'a correct file is not touched'
    Assert-True ($r4.Out -match 'Nothing to repair') 'and it reports nothing to do'

    Write-Host 'A mangled em dash is repaired too (not just the separator)' -ForegroundColor Cyan
    $f5 = Set-Fixture -Name 'emdash.md' -Text ("A title $EMDASH_BAD with damage")
    Invoke-Fix -FilePath $f5 | Out-Null
    Assert-True ((Get-FixtureText -Path $f5) -match [regex]::Escape($EMDASH)) 'the em dash is restored'

    Write-Host 'A UTF-8 BOM is preserved, and absence of one is preserved too' -ForegroundColor Cyan
    $f6 = Set-Fixture -Name 'bom.md' -Text ("### #6 $ONCE T") -WithBom
    Invoke-Fix -FilePath $f6 | Out-Null
    $b6 = [System.IO.File]::ReadAllBytes($f6)
    Assert-True ($b6[0] -eq 0xEF -and $b6[1] -eq 0xBB -and $b6[2] -eq 0xBF) 'a file with a BOM keeps it'
    $f7 = Set-Fixture -Name 'nobom.md' -Text ("### #7 $ONCE T")
    Invoke-Fix -FilePath $f7 | Out-Null
    $b7 = [System.IO.File]::ReadAllBytes($f7)
    Assert-True (-not ($b7[0] -eq 0xEF -and $b7[1] -eq 0xBB -and $b7[2] -eq 0xBF)) 'a file without a BOM does not gain one'

    Write-Host '-Check reports without changing, and exits 1 on damage' -ForegroundColor Cyan
    $f8 = Set-Fixture -Name 'check.md' -Text ("### #8 $ONCE T")
    $textBefore = Get-FixtureText -Path $f8
    $r8 = Invoke-Fix -FilePath $f8 -CheckOnly
    Assert-Equal 1 $r8.Code '-Check exits 1 when there is damage'
    Assert-Equal $textBefore (Get-FixtureText -Path $f8) '-Check changed nothing'
    Assert-True ($r8.Out -match '\[mojibake\]') '-Check names the finding with the marker the lint gate reads'
    Assert-True ($r8.Out -match 'check\.md') '-Check names the file'

    Write-Host '-Check on a clean file exits 0' -ForegroundColor Cyan
    $f9 = Set-Fixture -Name 'clean.md' -Text ("### #9 $MIDDOT T")
    $r9 = Invoke-Fix -FilePath $f9 -CheckOnly
    Assert-Equal 0 $r9.Code '-Check exits 0 on a clean file'
    Assert-True ($r9.Out -match 'clean') 'and says so'

    Write-Host 'The lint gate (check 14) reports its category on the real repo' -ForegroundColor Cyan
    #      Asserted on the coverage line rather than on a fixture: the gate consults the tool over the
    #      repo's own docs, and "the category was examined" is the property that a refactor could silently
    #      drop. The damage-detected direction is covered by the -Check asserts above, on a fixture --
    #      deliberately, because deliberately corrupting the real CHANGELOG.md to test a gate is how a
    #      suite leaves damage behind when it fails halfway.
    $lintOut = (& powershell -NoProfile -ExecutionPolicy Bypass -File $Lint 2>&1 | Out-String)
    Assert-True ($lintOut -match '\[mojibake\] checked 1') 'the lint gate ran the encoding check'
    Assert-True ($lintOut -match 'Summary: 0 error') 'and the repo is clean of mojibake'
} finally {
    Remove-Item -LiteralPath $Fixture -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
