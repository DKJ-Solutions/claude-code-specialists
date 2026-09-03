<#
.SYNOPSIS
    Tests for Invoke-GitParkCommit in scripts/lib/park-lib.ps1 -- the stage-and-commit half of a park,
    extracted so open-pr.ps1 can commit the document it publishes without a second copy of the pathspec
    (issue #1269).

.DESCRIPTION
    WHAT THIS EXISTS FOR. open-pr read the branch's development document from the WORKING TREE -- four
    gates and the PR body -- and pushed HEAD. All three downstream readers take the committed copy (the
    branch-entry CI check, the fold, ship-pr's DEPLOY lock), so on PR #1267 the push shipped an empty
    scaffold under a PR body describing a DEPLOY section the branch did not carry, and CI failed on
    arrival. open-pr now commits that document first, through this function.

    SO THE PROPERTIES UNDER TEST ARE THE ONES A CALLER RELIES ON RATHER THAN THE GIT PLUMBING:
    Committed tells "nothing to do" apart from "it worked", Ok tells both apart from "it failed", the
    pathspec is named and not swept, and Ok is a REAL return value rather than dead code behind a
    terminating Write-Error -- the last one is the defect gate-lib.ps1 records for Invoke-WorkflowGates,
    and every caller of this function runs under EAP=Stop.

    Integration style against a throwaway git repo, dependency-free (no Pester). No bare origin and no
    push anywhere: this function does not push, which is the whole reason it exists.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/park-commit.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibPath  = Join-Path $RepoRoot 'scripts\lib\park-lib.ps1'

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

Assert-True (Test-Path -LiteralPath $LibPath) 'park-lib.ps1 exists at its registered source path'
. (Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1')
. $LibPath
Assert-True ([bool](Get-Command -Name 'Invoke-GitParkCommit' -ErrorAction SilentlyContinue)) 'Invoke-GitParkCommit is exported by the lib'

$script:fixtures = @()

function New-Fixture {
    <#
        A throwaway git repo with one commit on 'main'. No remote: nothing here pushes.

        git's own output is silenced with EAP=Continue around the calls for the #96/#97/#107 reason the
        lib itself documents -- git writes progress to stderr, which under Stop becomes a terminating
        NativeCommandError before an exit code can be judged.
    #>
    param([Parameter(Mandatory)][string]$Label)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("park-commit-test-$PID-$Label")
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $dir init -q 2>$null | Out-Null
        & git -C $dir config user.email 'tycho-tests@local.invalid' 2>$null | Out-Null
        & git -C $dir config user.name 'Tycho Tests' 2>$null | Out-Null
        # Pinned LOCALLY rather than inherited: on a machine with core.autocrlf=true every `git add`
        # here writes the "LF will be replaced by CRLF" notice to stderr, which is fixture noise in a
        # suite that decides nothing about line endings. Same choice as gate-lib.tests.ps1.
        & git -C $dir config core.autocrlf false 2>$null | Out-Null
        & git -C $dir symbolic-ref HEAD refs/heads/main 2>$null | Out-Null
        Set-Content -LiteralPath (Join-Path $dir 'README.md') -Value '# fixture' -Encoding utf8
        & git -C $dir add -A 2>$null | Out-Null
        & git -C $dir commit -q -m 'init' 2>$null | Out-Null
    } finally { $ErrorActionPreference = $prevEap }

    $script:fixtures += $dir
    return $dir
}

function Get-Head {
    param([string]$Dir)
    $prevEap = $ErrorActionPreference
    try { $ErrorActionPreference = 'Continue'; return ((& git -C $Dir rev-parse HEAD 2>$null) | Out-String).Trim() }
    finally { $ErrorActionPreference = $prevEap }
}
function Get-Status {
    param([string]$Dir)
    $prevEap = $ErrorActionPreference
    try { $ErrorActionPreference = 'Continue'; return (((& git -C $Dir status --porcelain 2>$null) | Out-String) -replace "`r", '') }
    finally { $ErrorActionPreference = $prevEap }
}
function Get-Subject {
    param([string]$Dir)
    $prevEap = $ErrorActionPreference
    try { $ErrorActionPreference = 'Continue'; return ((& git -C $Dir log -1 --pretty=%s 2>$null) | Out-String).Trim() }
    finally { $ErrorActionPreference = $prevEap }
}
function Write-Doc {
    param([string]$Dir, [string]$Rel, [string]$Text)
    $full = Join-Path $Dir ($Rel -replace '/', '\')
    $parent = Split-Path -Path $full -Parent
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllText($full, $Text, (New-Object System.Text.UTF8Encoding $false))
}

# --- 1. THE CASE THIS FUNCTION EXISTS FOR: a dirty document, committed -----------------------------
Write-Host "`n== 1. a dirty named path is committed ==" -ForegroundColor Cyan
$d1   = New-Fixture -Label 'dirty'
$rel1 = 'contributing-davekjohn/development-fix-x-v1.md'
Write-Doc -Dir $d1 -Rel $rel1 -Text "## Development: fix/x-v1`n"
$before = Get-Head -Dir $d1
$r1 = Invoke-GitParkCommit -RepoRoot $d1 -Branch 'fix/x-v1' -Scope 'BranchFiles' -Paths @($rel1)
Assert-True  ([bool]$r1.Ok)                  'Ok is true'
Assert-True  ([bool]$r1.Committed)           'Committed is true'
Assert-True  ((Get-Head -Dir $d1) -ne $before) 'HEAD moved'
Assert-Equal '' (Get-Status -Dir $d1)        'and the tree is clean afterwards'
Assert-Equal 'park: fix/x-v1 (the branch files only)' (Get-Subject -Dir $d1) 'the subject still comes from the scope map'

# --- 2. a clean path is NOT a failure, and it is not a commit either -------------------------------
# The distinction a bare bool could not carry: open-pr calls this on every run and must only announce a
# commit it actually made.
Write-Host "`n== 2. nothing to commit ==" -ForegroundColor Cyan
$head2 = Get-Head -Dir $d1
$r2 = Invoke-GitParkCommit -RepoRoot $d1 -Branch 'fix/x-v1' -Scope 'BranchFiles' -Paths @($rel1)
Assert-True  ([bool]$r2.Ok)                    'Ok stays true'
Assert-True  (-not $r2.Committed)              'Committed is false'
Assert-Equal $head2 (Get-Head -Dir $d1)        'and HEAD did not move'

# --- 3. THE PATHSPEC IS NAMED, NOT SWEPT ----------------------------------------------------------
# The bound open-pr inherits from park-cycle's bound 1: unrelated work -- staged or not -- must not ride
# along into a commit nobody asked to publish.
Write-Host "`n== 3. unrelated work does not ride along ==" -ForegroundColor Cyan
$d3   = New-Fixture -Label 'bounded'
$rel3 = 'contributing-davekjohn/development-fix-y-v1.md'
Write-Doc -Dir $d3 -Rel $rel3 -Text "## Development: fix/y-v1`n"
Write-Doc -Dir $d3 -Rel 'src/staged.txt'   -Text "staged`n"
Write-Doc -Dir $d3 -Rel 'src/untracked.txt' -Text "untracked`n"
$prevEap = $ErrorActionPreference
try { $ErrorActionPreference = 'Continue'; & git -C $d3 add -- 'src/staged.txt' 2>$null | Out-Null }
finally { $ErrorActionPreference = $prevEap }

$r3 = Invoke-GitParkCommit -RepoRoot $d3 -Branch 'fix/y-v1' -Scope 'BranchFiles' -Paths @($rel3)
Assert-True ([bool]$r3.Committed) 'the document is committed'
$st3 = Get-Status -Dir $d3
Assert-True ($st3 -match 'A\s+src/staged\.txt')  'the staged file is still staged and uncommitted'
Assert-True ($st3 -match '\?\?\s+src/untracked\.txt') 'the untracked file is still untracked'
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $files3 = ((& git -C $d3 show --pretty=format: --name-only HEAD 2>$null) | Out-String)
} finally { $ErrorActionPreference = $prevEap }
Assert-True ($files3 -match [regex]::Escape($rel3)) 'the commit contains the document'
Assert-True (-not ($files3 -match 'staged\.txt'))   'and nothing else'

# --- 4. a path that does not exist is a no-op, not an error ---------------------------------------
# open-pr filters for existence too, so this is the belt to that brace: a branch whose document was
# never written must not turn the PR into a git pathspec failure.
Write-Host "`n== 4. a named path that is not there ==" -ForegroundColor Cyan
$d4    = New-Fixture -Label 'absent'
$head4 = Get-Head -Dir $d4
$r4 = Invoke-GitParkCommit -RepoRoot $d4 -Branch 'fix/z-v1' -Scope 'BranchFiles' -Paths @('contributing-davekjohn/nope.md')
Assert-True  ([bool]$r4.Ok)              'Ok is true'
Assert-True  (-not $r4.Committed)        'Committed is false'
Assert-Equal $head4 (Get-Head -Dir $d4)  'and HEAD did not move'

# --- 5. the Everything scope is unchanged, because three callers still use it ----------------------
Write-Host "`n== 5. the Everything scope still sweeps ==" -ForegroundColor Cyan
$d5 = New-Fixture -Label 'everything'
Write-Doc -Dir $d5 -Rel 'a.txt' -Text "a`n"
Write-Doc -Dir $d5 -Rel 'b.txt' -Text "b`n"
$r5 = Invoke-GitParkCommit -RepoRoot $d5 -Branch 'feat/all-v1' -Scope 'Everything'
Assert-True  ([bool]$r5.Committed) 'Committed is true'
Assert-Equal '' (Get-Status -Dir $d5) 'the whole tree is committed'
Assert-Equal 'park: feat/all-v1 (all outstanding work)' (Get-Subject -Dir $d5) 'and the subject names that scope'

# --- 6. A FAILURE RETURNS Ok=$false RATHER THAN THROWING ------------------------------------------
# THE PROPERTY THIS CASE EXISTS FOR. Every caller runs under EAP=Stop, where Write-Error terminates --
# which would make the return value dead code and open-pr's own refusal message unreachable. Induced
# with a directory that is not a git repo at all, so `git add` fails deterministically on every machine.
Write-Host "`n== 6. a git failure is a return value, not an exception ==" -ForegroundColor Cyan
$d6 = Join-Path ([System.IO.Path]::GetTempPath()) "park-commit-test-$PID-notarepo"
if (Test-Path -LiteralPath $d6) { Remove-Item -Recurse -Force -LiteralPath $d6 }
New-Item -ItemType Directory -Path $d6 -Force | Out-Null
$script:fixtures += $d6
Write-Doc -Dir $d6 -Rel 'x.txt' -Text "x`n"

$threw = $false
$r6 = $null
# 2>$null, NOT -ErrorAction SilentlyContinue: the function passes -ErrorAction Continue on its own
# Write-Error, which wins over the caller's preference -- so the record prints regardless and only a
# stream redirect keeps the expected failure out of the suite's output.
try { $r6 = Invoke-GitParkCommit -RepoRoot $d6 -Branch 'fix/q-v1' -Scope 'Everything' 2>$null }
catch { $threw = $true }
Assert-True (-not $threw)        'it did not throw under the suite EAP=Stop'
Assert-True ($null -ne $r6)      'it returned an object'
if ($null -ne $r6) {
    Assert-True (-not $r6.Ok)        'Ok is false'
    Assert-True (-not $r6.Committed) 'and Committed is false'
}

# --- 7. the "nothing to do" clause is the CALLER's half of the sentence ---------------------------
# Invoke-GitPark says '-- pushing the existing commits as-is'; a caller that does not push must not.
Write-Host "`n== 7. -Continuation ==" -ForegroundColor Cyan
$d7 = New-Fixture -Label 'continuation'
$withNote = Invoke-GitParkCommit -RepoRoot $d7 -Branch 'fix/c-v1' -Scope 'BranchFiles' `
                                 -Paths @('contributing-davekjohn/nope.md') `
                                 -Continuation 'pushing the existing commits as-is' 6>&1
$withNoteText = ($withNote | Out-String)
Assert-True ($withNoteText -match 'pushing the existing commits as-is\.') 'the pusher gets its clause'

$without = Invoke-GitParkCommit -RepoRoot $d7 -Branch 'fix/c-v1' -Scope 'BranchFiles' `
                                -Paths @('contributing-davekjohn/nope.md') 6>&1
$withoutText = ($without | Out-String)
Assert-True ($withoutText -match 'nothing to stage in this scope\.') 'and without one the line simply stops'
Assert-True (-not ($withoutText -match 'pushing')) 'never claiming a push it did not make'

# --- cleanup --------------------------------------------------------------------------------------
foreach ($f in $script:fixtures) {
    if ($f -and (Test-Path -LiteralPath $f)) { Remove-Item -Recurse -Force -LiteralPath $f -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "Summary: $script:pass passed, $script:fail failed." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
