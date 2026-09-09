<#
.SYNOPSIS
    Regression tests for scripts/lib/fixture-dep-lib.ps1, and the gate itself: no test suite's
    hand-listed fixture lib copies may go stale against what those libs dot-source (issue #1693).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/fixture-lib-deps.tests.ps1

    WHY THIS SUITE IS ALSO THE GATE. The tree-wide pass at the bottom is the check #1693 asked for; it
    lives here rather than as a numbered check in check-plugin-integrity.ps1 for one reason, and it is
    worth stating plainly: while this was written, another branch was repairing that script's .SYNOPSIS
    check list (#1680), and appending a check would have meant both of us rewriting the same block. The
    merits were even -- that file already carries a fixture-shaped check ([fixture-git]) and this one
    already carries three tree-walking meta-suites (shared-scripts, agent-shared,
    template-selfcontained) -- so collision decided it. Moving it later is a one-call change: the
    reading is all in the lib, and Get-FixtureDepReport is the whole answer.

    WHAT WAS MEASURED BEFORE ANY OF IT WAS BUILT, because a gate here arrives measured:

      1. THE SCOPE IN #1693 IS SHORT. It names five suites; twelve copy a lib into a fixture. Its five
         counts are all exactly right (8/8/8/6/2) -- the list was incomplete, not wrong.
      2. THE REAL INSTANCE DOT-SOURCES THROUGH A VARIABLE. On origin/fix/1682-porcelain-line-parse,
         park-lib.ps1 reads
             $parkPorcelainLib = Join-Path $PSScriptRoot 'git-porcelain-lib.ps1'
             if (Test-Path -LiteralPath $parkPorcelainLib -PathType Leaf) { . $parkPorcelainLib }
         so the dot-source command's own text is `. $parkPorcelainLib` and names no file at all. The
         first version of this reader matched on that text and missed the ONLY real instance of the
         class it was built for. Eight libs in scripts/lib dot-source a sibling and every one of them
         does it through a variable, so this is the normal shape here rather than an edge case.
      3. THE NAIVE CHECK IS NOT BORN GREEN, IT IS BORN 100% FALSE. Reading any literal in the Copy-Item
         (rather than its -Destination) produced two findings on a clean tree and both were wrong:
         consumer-check-lib.tests.ps1, whose fixture deliberately has no measure-context-lib sibling
         because it exists to prove the guarded load degrades, and internal-note.tests.ps1, which is
         right not to copy branch-info.ps1 because that seam is repo-owned and supplied by the caller.
         Those two findings are what shaped the reader: bind to the destination, and exempt the
         repo-owned seams. This repo declines a findings-list check on its false-positive rate (the
         stale-path check, 124 findings, all false), so shipping this without those two would have been
         proposing exactly what it turns down.
      4. AFTER BOTH: 83 suites read, 12 subjects, 0 findings -- and the reconstructed pre-repair state
         of that real branch yields exactly 1, naming park-lib.ps1 -> git-porcelain-lib.ps1.

    THE SYNTHETIC FIXTURES BELOW ARE NOT DECORATION. On this tree the gate is silent, so nothing here
    would notice if the reader stopped reading: the shape asserts are what prove it still fires. Each
    one is a shape measured in the tree rather than invented.

    Pure ASCII (repo convention for .ps1).
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1')
. (Join-Path $RepoRoot 'scripts\lib\fixture-dep-lib.ps1')

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
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        Write-Host "         expected: $Expected" -ForegroundColor Red
        Write-Host "         actual:   $Actual" -ForegroundColor Red
    }
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

# Temp paths come from the shared composer (#1659) rather than being built here from a label: the
# fixture trees this suite writes are exactly the shape that issue is about, and #1664 is converting
# the rest of scripts/tests/ the same way.
$SandRoot = New-ScratchPath -Label 'fixdep' -Directory
$LibDir   = Join-Path $SandRoot 'lib'
$TestDir  = Join-Path $SandRoot 'tests'
New-Item -ItemType Directory -Path $LibDir  -Force | Out-Null
New-Item -ItemType Directory -Path $TestDir -Force | Out-Null

function Set-Lib {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Body)
    [System.IO.File]::WriteAllText((Join-Path $LibDir $Name), $Body, $Utf8NoBom)
}

function Set-Suite {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Body)
    $path = Join-Path $TestDir $Name
    [System.IO.File]::WriteAllText($path, $Body, $Utf8NoBom)
    return $path
}

function Clear-Sandbox {
    Get-ChildItem -Path $LibDir  -File | Remove-Item -Force
    Get-ChildItem -Path $TestDir -File | Remove-Item -Force
}

try {
    # ---------------------------------------------------------------------------------------------
    Write-Host 'Get-DotSourcedLibName -- the two shapes a dependency arrives in' -ForegroundColor Cyan

    # THE VARIABLE SHAPE IS THE ONE THAT MATTERS, and it is copied verbatim from park-lib.ps1 on
    # origin/fix/1682-porcelain-line-parse -- the guard included, because the guard is why the miss is
    # silent rather than a crash.
    Set-Lib -Name 'a-lib.ps1' -Body @'
$aDep = Join-Path $PSScriptRoot 'b-lib.ps1'
if (Test-Path -LiteralPath $aDep -PathType Leaf) { . $aDep }
function Get-A { 'a' }
'@
    Set-Lib -Name 'b-lib.ps1' -Body "function Get-B { 'b' }`n"

    Assert-Equal 'b-lib.ps1' ((Get-DotSourcedLibName -Path (Join-Path $LibDir 'a-lib.ps1')) -join ',') `
        'a dependency dot-sourced through a variable is read -- the #1682 shape, which the first reader missed'

    # The literal shape, which is what a synthetic-only suite would have tested and passed on.
    Set-Lib -Name 'c-lib.ps1' -Body ". (Join-Path `$PSScriptRoot 'b-lib.ps1')`nfunction Get-C { 'c' }`n"
    Assert-Equal 'b-lib.ps1' ((Get-DotSourcedLibName -Path (Join-Path $LibDir 'c-lib.ps1')) -join ',') `
        'and so is one written out inside the dot-source itself'

    # A COMMENT CANNOT REACH IT. park-lib.ps1's own header carries a dot-source of itself as an
    # .EXAMPLE; the AST does not see comments, which is why this reader can be trusted near docstrings.
    Set-Lib -Name 'd-lib.ps1' -Body @'
<#
    .EXAMPLE
        . (Join-Path $PSScriptRoot 'b-lib.ps1')
#>
function Get-D { 'd' }
'@
    Assert-Equal '' ((Get-DotSourcedLibName -Path (Join-Path $LibDir 'd-lib.ps1')) -join ',') `
        'a dot-source inside a docstring is not a dependency -- the AST cannot see comments'

    # NAMING A .ps1 IS NOT DEPENDING ON IT. shared-scripts-lib.ps1's registry names every mirrored
    # script in the tree; a reader that took every literal would report all of them.
    Set-Lib -Name 'e-lib.ps1' -Body "`$script:Registry = @('b-lib.ps1', 'x-lib.ps1')`nfunction Get-E { 'e' }`n"
    Assert-Equal '' ((Get-DotSourcedLibName -Path (Join-Path $LibDir 'e-lib.ps1')) -join ',') `
        'a .ps1 named in a string but never dot-sourced is not a dependency'

    # ---------------------------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'Get-FixtureCopiedLibName -- the DESTINATION is the subject, not the source' -ForegroundColor Cyan

    # Every one of these copies READS FROM scripts\lib\<x>.ps1 in the real repo, so a reader that takes
    # any literal takes the source as well -- which is what produced two false findings on a clean
    # tree. The flat destination here is consumer-check-lib.tests.ps1's real shape.
    $flat = Set-Suite -Name 'flat.tests.ps1' -Body @'
Copy-Item -LiteralPath (Join-Path $RepoRoot 'scripts\lib\a-lib.ps1') -Destination (Join-Path $loneDir 'a-lib.ps1')
'@
    Assert-Equal '' ((Get-FixtureCopiedLibName -Path $flat) -join ',') `
        'a copy whose destination is NOT a fixture scripts/lib is not a subject, however its source reads'

    $named = Set-Suite -Name 'named.tests.ps1' -Body @'
Copy-Item -LiteralPath (Join-Path $RepoRoot 'scripts\lib\a-lib.ps1') -Destination (Join-Path $dir 'scripts\lib\a-lib.ps1') -Force
'@
    Assert-Equal 'a-lib.ps1' ((Get-FixtureCopiedLibName -Path $named) -join ',') `
        'the named -Destination form is read'

    # THE POSITIONAL FORM IS IN THIS TREE TOO -- source-repo-guard.tests.ps1 writes it this way, and a
    # reader that handled only the named form stopped treating that suite as a subject at all.
    $positional = Set-Suite -Name 'positional.tests.ps1' -Body @'
Copy-Item $GuardLib (Join-Path $awayDir 'scripts\lib\a-lib.ps1')
'@
    Assert-Equal 'a-lib.ps1' ((Get-FixtureCopiedLibName -Path $positional) -join ',') `
        'and so is the positional form, where the destination is the second positional argument'

    # A switch between the two positionals must not shift which one is the destination.
    $switched = Set-Suite -Name 'switched.tests.ps1' -Body @'
Copy-Item -Force $GuardLib (Join-Path $awayDir 'scripts\lib\a-lib.ps1')
'@
    Assert-Equal 'a-lib.ps1' ((Get-FixtureCopiedLibName -Path $switched) -join ',') `
        'a switch parameter consumes no positional, so -Force before the paths changes nothing'

    Clear-Sandbox

    # ---------------------------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'Get-FixtureDepFinding -- the gap, the closure, and what is deliberately not a finding' -ForegroundColor Cyan

    Set-Lib -Name 'a-lib.ps1' -Body @'
$aDep = Join-Path $PSScriptRoot 'b-lib.ps1'
if (Test-Path -LiteralPath $aDep -PathType Leaf) { . $aDep }
'@
    Set-Lib -Name 'b-lib.ps1' -Body @'
$bDep = Join-Path $PSScriptRoot 'c-lib.ps1'
if (Test-Path -LiteralPath $bDep -PathType Leaf) { . $bDep }
'@
    Set-Lib -Name 'c-lib.ps1' -Body "function Get-C { 'c' }`n"

    $onlyA = Set-Suite -Name 'onlya.tests.ps1' -Body @'
Copy-Item -LiteralPath $x -Destination (Join-Path $dir 'scripts\lib\a-lib.ps1') -Force
'@
    $f = @(Get-FixtureDepFinding -SuitePath $onlyA -LibDirectory $LibDir)
    Assert-Equal 2 $f.Count 'the CLOSURE is walked in one pass: copying only a-lib reports b AND c, not b alone'
    # @() around each filter, not for tidiness: under Set-StrictMode a Where-Object that matches ONE
    # object hands back that object rather than a list, and reading .Count off it throws.
    Assert-Equal 1 @($f | Where-Object { $_.Lib -eq 'a-lib.ps1' -and $_.Missing -eq 'b-lib.ps1' }).Count `
        'the direct dependency is named with the lib that wants it'
    Assert-Equal 1 @($f | Where-Object { $_.Lib -eq 'b-lib.ps1' -and $_.Missing -eq 'c-lib.ps1' }).Count `
        'and so is the one a level further down, attributed to b rather than to a'

    $allThree = Set-Suite -Name 'allthree.tests.ps1' -Body @'
Copy-Item -LiteralPath $x -Destination (Join-Path $dir 'scripts\lib\a-lib.ps1') -Force
Copy-Item -LiteralPath $x -Destination (Join-Path $dir 'scripts\lib\b-lib.ps1') -Force
Copy-Item -LiteralPath $x -Destination (Join-Path $dir 'scripts\lib\c-lib.ps1') -Force
'@
    Assert-Equal 0 @(Get-FixtureDepFinding -SuitePath $allThree -LibDirectory $LibDir).Count `
        'a complete list is silent -- the assert that keeps this from being a check that always fires'

    # A DEPENDENCY THE TREE DOES NOT CARRY IS NOT A FINDING. The guarded dot-source exists precisely
    # because a lib may legitimately not be present, and this reader has no opinion about a name that
    # is not there.
    Set-Lib -Name 'g-lib.ps1' -Body @'
$gDep = Join-Path $PSScriptRoot 'not-in-this-tree-lib.ps1'
if (Test-Path -LiteralPath $gDep -PathType Leaf) { . $gDep }
'@
    $ghost = Set-Suite -Name 'ghost.tests.ps1' -Body @'
Copy-Item -LiteralPath $x -Destination (Join-Path $dir 'scripts\lib\g-lib.ps1') -Force
'@
    Assert-Equal 0 @(Get-FixtureDepFinding -SuitePath $ghost -LibDirectory $LibDir).Count `
        'a dot-source of a lib the tree does not have is not a finding'

    # A CYCLE MUST NOT SPIN. Two libs dot-sourcing each other is not a shape in this tree, and the
    # visited set is what makes that a safe thing to be true rather than a lucky one.
    Set-Lib -Name 'p-lib.ps1' -Body @'
$pDep = Join-Path $PSScriptRoot 'q-lib.ps1'
if (Test-Path -LiteralPath $pDep -PathType Leaf) { . $pDep }
'@
    Set-Lib -Name 'q-lib.ps1' -Body @'
$qDep = Join-Path $PSScriptRoot 'p-lib.ps1'
if (Test-Path -LiteralPath $qDep -PathType Leaf) { . $qDep }
'@
    $cycle = Set-Suite -Name 'cycle.tests.ps1' -Body @'
Copy-Item -LiteralPath $x -Destination (Join-Path $dir 'scripts\lib\p-lib.ps1') -Force
'@
    $cf = @(Get-FixtureDepFinding -SuitePath $cycle -LibDirectory $LibDir)
    Assert-Equal 1 $cf.Count 'a cycle terminates and reports once rather than spinning'

    # ---------------------------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'The repo-owned seam exemption (the second false finding on a clean tree)' -ForegroundColor Cyan

    Assert-Equal 'branch-info.ps1' ((Get-FixtureDepRepoOwnedSeam) -join ',') `
        'exactly one seam is exempt, and the list is read from the lib rather than restated here'

    Set-Lib -Name 'r-lib.ps1' -Body @'
$rSeam = Join-Path $PSScriptRoot 'branch-info.ps1'
if (Test-Path -LiteralPath $rSeam -PathType Leaf) { . $rSeam }
'@
    Set-Lib -Name 'branch-info.ps1' -Body "function Get-BranchInfo { }`n"
    $seamSuite = Set-Suite -Name 'seam.tests.ps1' -Body @'
Copy-Item -LiteralPath $x -Destination (Join-Path $dir 'scripts\lib\r-lib.ps1') -Force
'@
    Assert-Equal 0 @(Get-FixtureDepFinding -SuitePath $seamSuite -LibDirectory $LibDir).Count `
        'a repo-owned seam the caller supplies is not a debt the fixture owes -- internal-note.tests.ps1 is why'

    # And the exemption is narrow: the same shape with a non-seam lib IS reported, so the list is doing
    # the work rather than the reader having quietly stopped looking.
    Set-Lib -Name 's-lib.ps1' -Body @'
$sDep = Join-Path $PSScriptRoot 'c-lib.ps1'
if (Test-Path -LiteralPath $sDep -PathType Leaf) { . $sDep }
'@
    $nonSeam = Set-Suite -Name 'nonseam.tests.ps1' -Body @'
Copy-Item -LiteralPath $x -Destination (Join-Path $dir 'scripts\lib\s-lib.ps1') -Force
'@
    Assert-Equal 1 @(Get-FixtureDepFinding -SuitePath $nonSeam -LibDirectory $LibDir).Count `
        'while an ordinary sibling in the same position is still reported'

    # ---------------------------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'The per-path memo is keyed on the FILE, not the path' -ForegroundColor Cyan

    # THIS IS A REGRESSION ASSERT WITH A RED IT ACTUALLY HAD. Get-DotSourcedLibName memoises, because
    # Get-FixtureDepFinding asks it once per (suite, lib) pair; keyed on the path alone it answered
    # from the cache after a rewrite, and two asserts above went red on the stale answer. A cache that
    # is only correct while every caller remembers not to rewrite a file is enforced by memory, so the
    # key carries the timestamp and the length. Asserted directly rather than left to the sections
    # above to notice, because there it looked like a closure bug.
    Set-Lib -Name 'cache-lib.ps1' -Body @'
$cacheDep = Join-Path $PSScriptRoot 'c-lib.ps1'
if (Test-Path -LiteralPath $cacheDep -PathType Leaf) { . $cacheDep }
'@
    Assert-Equal 'c-lib.ps1' ((Get-DotSourcedLibName -Path (Join-Path $LibDir 'cache-lib.ps1')) -join ',') `
        'the first read of a lib answers from the file'

    Start-Sleep -Milliseconds 20   # so the rewrite lands on a different last-write tick
    Set-Lib -Name 'cache-lib.ps1' -Body "function Get-Cache { 'nothing dot-sourced now' }`n"
    Assert-Equal '' ((Get-DotSourcedLibName -Path (Join-Path $LibDir 'cache-lib.ps1')) -join ',') `
        'and a rewrite at the SAME path is read again rather than served from the memo'

    # ---------------------------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'An unparseable file throws rather than reading as "no dependencies"' -ForegroundColor Cyan

    # An empty answer here means "nothing to copy", which is the silence this lib exists to remove. So
    # a file that cannot be parsed must fail loudly instead of passing quietly.
    Set-Lib -Name 'broken-lib.ps1' -Body "function Get-Broken { `n"
    $threw = $false
    try { $null = Get-DotSourcedLibName -Path (Join-Path $LibDir 'broken-lib.ps1') } catch { $threw = $true }
    Assert-True $threw 'an unparseable lib throws, so a parse failure can never read as a clean dependency set'

    # ---------------------------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'THE GATE: this repo own suites, held against what their copied libs dot-source' -ForegroundColor Cyan

    $report = Get-FixtureDepReport -TestsDirectory (Join-Path $RepoRoot 'scripts\tests') `
                                  -LibDirectory   (Join-Path $RepoRoot 'scripts\lib')

    # BOTH FIGURES, BECAUSE A SILENT PASS NEEDS BOTH. Zero findings over zero subjects is a reader that
    # found nothing to read; zero over twelve is the tree being clean. The two must never print the
    # same line -- the same reason check-plugin-integrity.ps1's span checks print both.
    Assert-True ($report.Suites -gt 50) "the whole suite directory was read (found $($report.Suites) suites)"
    Assert-True ($report.Subjects -ge 10) `
        "and $($report.Subjects) of them copy a lib into a fixture -- so this gate has subjects rather than being vacuous"

    if ($report.Findings.Count -gt 0) {
        foreach ($f in $report.Findings) {
            Write-Host "         $($f.Suite): $($f.Lib) dot-sources $($f.Missing), which the fixture does not copy" -ForegroundColor Red
        }
    }
    Assert-Equal 0 $report.Findings.Count `
        'every fixture copies the libs its copied libs dot-source (#1693)'

} finally {
    if (Test-Path -LiteralPath $SandRoot) {
        Remove-Item -Recurse -Force -LiteralPath $SandRoot -ErrorAction SilentlyContinue
    }
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
