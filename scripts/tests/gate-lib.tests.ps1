<#
.SYNOPSIS
    Tests for scripts/lib/gate-lib.ps1 -- the record of what the gates proved, and against which
    exact working state.

.DESCRIPTION
    This lib decides whether open-pr.ps1 may SKIP a gate. Every way it can be wrong is asymmetric: a
    false negative costs one gate run, a false positive lets an ungated commit reach a merge. So the
    suite is written from that side -- most cases here assert that evidence is REFUSED, and the
    happy path is the short one.

    THE PROPERTY THAT WOULD BREAK SILENTLY IS THE FINGERPRINT'S SENSITIVITY. The obvious
    implementation hashes HEAD plus `git status --porcelain`, and it passes every casual test: a
    clean tree matches itself, a dirty tree differs from a clean one. It is still wrong, because
    porcelain reports THAT a file is modified and never what it was modified TO -- so a file edited,
    gated, and edited again presents a byte-identical status line over different content, and the
    gate would be skipped on a tree it never saw. Case 3 is that exact sequence and it is the reason
    this file exists.

    A REAL GIT REPOSITORY PER CASE, NOT A STUB. The lib's whole job is to be right about what git
    reports, so a fake that returns canned porcelain would prove only that the parser agrees with
    the fake. Each fixture is a genuine `git init` under the temp directory, keyed on $PID so
    concurrent suites cannot collide (the gate runs these in parallel).

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibPath  = Join-Path $RepoRoot 'scripts\lib\gate-lib.ps1'

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

Assert-True (Test-Path -LiteralPath $LibPath) 'gate-lib.ps1 exists at its registered source path'
. $LibPath

$FixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) "gate-lib-tests-$PID"
$Utf8NoBom   = New-Object System.Text.UTF8Encoding $false
$script:seq  = 0

function Invoke-FixtureGit {
    <#
        Git MUTATIONS inside a fixture, run under EAP=Continue.

        This is the repo's standing pitfall and it bit this very suite on its first run: `git add`
        writes the autocrlf "LF will be replaced by CRLF" notice to stderr, which under
        $ErrorActionPreference = 'Stop' becomes a TERMINATING NativeCommandError even though git
        exits 0 -- the same failure that broke cut-release.ps1 while cutting v1.12.0. The redirect
        alone is not enough, because the error is raised on the stderr write rather than on the exit
        code, so the preference has to be lowered around the call.
    #>
    param([string]$Dir, [Parameter(ValueFromRemainingArguments)][string[]]$GitArgs)
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & git -C $Dir @GitArgs 2>&1 | Out-Null
    } finally { $ErrorActionPreference = $prev }
}

function New-GitFixture {
    <#
        A real repository with one committed file. Returns its path. Each call gets its own
        directory, so a case that dirties a tree cannot leak into the next.
    #>
    $script:seq++
    $dir = Join-Path $FixtureRoot "repo-$script:seq"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Invoke-FixtureGit -Dir $dir 'init' '-q'
    # Pinned rather than inherited: on a machine with core.autocrlf=true the checkout would rewrite
    # line endings underneath the fixture, which is a second, invisible way to move a fingerprint.
    Invoke-FixtureGit -Dir $dir 'config' 'core.autocrlf' 'false'
    Invoke-FixtureGit -Dir $dir 'config' 'user.email' 'tycho@example.test'
    Invoke-FixtureGit -Dir $dir 'config' 'user.name'  'Tycho'
    [System.IO.File]::WriteAllText((Join-Path $dir 'tracked.txt'), "one`n", $Utf8NoBom)
    Invoke-FixtureGit -Dir $dir 'add' '-A'
    Invoke-FixtureGit -Dir $dir 'commit' '-qm' 'init'
    return $dir
}

function Set-FixtureFile {
    param([string]$Dir, [string]$Name, [string]$Content)
    [System.IO.File]::WriteAllText((Join-Path $Dir $Name), $Content, $Utf8NoBom)
}

try {
    New-Item -ItemType Directory -Path $FixtureRoot -Force | Out-Null

    # --- 1. the happy path, and it is deliberately the short one -------------------------------
    Write-Host "`n== 1. a recorded pass covers the tree it was recorded against ==" -ForegroundColor Cyan
    $r1 = New-GitFixture
    $f1 = Get-GateFingerprint -RepoRoot $r1
    Assert-True ([bool]$f1) 'a clean repository yields a fingerprint'
    Assert-True (-not (Test-GateEvidence -RepoRoot $r1 -Gate 'tests')) 'with no record, evidence is refused'
    Assert-True ([bool](Save-GateEvidence -RepoRoot $r1 -Gate 'tests' -Fingerprint $f1)) 'a pass can be recorded'
    Assert-True (Test-GateEvidence -RepoRoot $r1 -Gate 'tests') 'and is then honoured on the same tree'

    # The two gates prove different things. Recording one must not vouch for the other -- otherwise
    # -SkipTests plus a lint pass would silently satisfy the test gate.
    Assert-True (-not (Test-GateEvidence -RepoRoot $r1 -Gate 'lint')) 'a tests pass does NOT vouch for the lint gate'
    Assert-True ([bool](Save-GateEvidence -RepoRoot $r1 -Gate 'lint' -Fingerprint $f1)) 'the lint gate records separately'
    Assert-True (Test-GateEvidence -RepoRoot $r1 -Gate 'lint')  'lint is now honoured'
    Assert-True (Test-GateEvidence -RepoRoot $r1 -Gate 'tests') 'and the tests pass survived the second write'

    # --- 2. the state file is never committable ------------------------------------------------
    Write-Host "`n== 2. the record lives inside the git directory ==" -ForegroundColor Cyan
    $path1 = Get-GateEvidencePath -RepoRoot $r1
    Assert-True ([bool]$path1) 'a path is resolved'
    Assert-True ($path1 -like '*\.git\*') "the record sits under .git (got '$(Split-Path $path1 -Leaf)')"
    Assert-True (Test-Path -LiteralPath $path1 -PathType Leaf) 'and it was actually written'
    # Nothing under .git can be added to a commit, so this is what makes the file un-committable
    # without a .gitignore entry every consumer would otherwise have to be given.
    Push-Location $r1
    try { $porcelain = @(& git status --porcelain 2>$null | ForEach-Object { "$_" }) } finally { Pop-Location }
    Assert-Equal 0 @($porcelain | Where-Object { $_ -match 'gate-evidence' }).Count 'the record is invisible to git status'

    # --- 3. THE CASE THIS FILE EXISTS FOR ------------------------------------------------------
    Write-Host "`n== 3. content, not the status letter ==" -ForegroundColor Cyan
    $r3 = New-GitFixture
    Set-FixtureFile -Dir $r3 -Name 'tracked.txt' -Content "edited once`n"
    $a = Get-GateFingerprint -RepoRoot $r3
    [void](Save-GateEvidence -RepoRoot $r3 -Gate 'tests' -Fingerprint $a)
    Assert-True (Test-GateEvidence -RepoRoot $r3 -Gate 'tests') 'the dirty tree is gated and recorded'

    # Same file, still modified, still ' M tracked.txt' in porcelain -- different bytes. A
    # fingerprint built on porcelain alone would call this a match and skip the gate.
    Set-FixtureFile -Dir $r3 -Name 'tracked.txt' -Content "edited twice`n"
    $b = Get-GateFingerprint -RepoRoot $r3
    Assert-True ($a -ne $b) 'a second edit with the SAME status letter moves the fingerprint'
    Assert-True (-not (Test-GateEvidence -RepoRoot $r3 -Gate 'tests')) 'so the recorded pass no longer covers it'

    # Restoring the exact earlier content must restore the match: the evidence is the content, so
    # an undo is genuinely the tree that was gated.
    Set-FixtureFile -Dir $r3 -Name 'tracked.txt' -Content "edited once`n"
    Assert-True (Test-GateEvidence -RepoRoot $r3 -Gate 'tests') 'and reverting to the gated content honours it again'

    # --- 4. every other way the tree can move --------------------------------------------------
    Write-Host "`n== 4. new commits and untracked files move it too ==" -ForegroundColor Cyan
    $r4 = New-GitFixture
    $c0 = Get-GateFingerprint -RepoRoot $r4
    [void](Save-GateEvidence -RepoRoot $r4 -Gate 'tests' -Fingerprint $c0)

    Set-FixtureFile -Dir $r4 -Name 'untracked.txt' -Content "new`n"
    Assert-True (-not (Test-GateEvidence -RepoRoot $r4 -Gate 'tests')) 'an untracked file invalidates the record'
    Remove-Item -LiteralPath (Join-Path $r4 'untracked.txt') -Force
    Assert-True (Test-GateEvidence -RepoRoot $r4 -Gate 'tests') 'removing it again restores the match'

    # A new commit changes HEAD while leaving the working tree clean -- the single most common real
    # movement between an open-pr and a ship-pr, and the one the skip must never survive.
    Set-FixtureFile -Dir $r4 -Name 'tracked.txt' -Content "committed change`n"
    Invoke-FixtureGit -Dir $r4 'add' '-A'
    Invoke-FixtureGit -Dir $r4 'commit' '-qm' 'second'
    Assert-True (-not (Test-GateEvidence -RepoRoot $r4 -Gate 'tests')) 'a new commit invalidates the record'

    # --- 5. a stale or malformed record is no record -------------------------------------------
    Write-Host "`n== 5. every failure path refuses, rather than trusting ==" -ForegroundColor Cyan
    $r5 = New-GitFixture
    $f5 = Get-GateFingerprint -RepoRoot $r5
    [void](Save-GateEvidence -RepoRoot $r5 -Gate 'tests' -Fingerprint $f5)
    $p5 = Get-GateEvidencePath -RepoRoot $r5

    # Age bound: the content has not moved, so only the clock can refuse this one.
    $old = [pscustomobject]@{
        fingerprint = $f5
        recordedAt  = ([datetime]::UtcNow.AddMinutes(-241)).ToString('o')
        gates       = [pscustomobject]@{ tests = $true }
    }
    [System.IO.File]::WriteAllText($p5, ($old | ConvertTo-Json -Depth 4), $Utf8NoBom)
    Assert-True (-not (Test-GateEvidence -RepoRoot $r5 -Gate 'tests')) 'a record past the age bound is refused'

    $fresh = [pscustomobject]@{
        fingerprint = $f5
        recordedAt  = ([datetime]::UtcNow.AddMinutes(-5)).ToString('o')
        gates       = [pscustomobject]@{ tests = $true }
    }
    [System.IO.File]::WriteAllText($p5, ($fresh | ConvertTo-Json -Depth 4), $Utf8NoBom)
    Assert-True (Test-GateEvidence -RepoRoot $r5 -Gate 'tests') 'a record inside the bound is honoured'

    # A clock that moved backwards leaves a record stamped in the future. That is also what a
    # restored or hand-edited file looks like, so it is refused rather than treated as very fresh.
    $future = [pscustomobject]@{
        fingerprint = $f5
        recordedAt  = ([datetime]::UtcNow.AddMinutes(30)).ToString('o')
        gates       = [pscustomobject]@{ tests = $true }
    }
    [System.IO.File]::WriteAllText($p5, ($future | ConvertTo-Json -Depth 4), $Utf8NoBom)
    Assert-True (-not (Test-GateEvidence -RepoRoot $r5 -Gate 'tests')) 'a record stamped in the future is refused'

    [System.IO.File]::WriteAllText($p5, "{ not json at all", $Utf8NoBom)
    Assert-True (-not (Test-GateEvidence -RepoRoot $r5 -Gate 'tests')) 'a malformed record is refused, not thrown on'
    Assert-True ($null -eq (Read-GateEvidence -RepoRoot $r5)) 'and reads back as no record at all'

    [System.IO.File]::WriteAllText($p5, (([pscustomobject]@{ gates = [pscustomobject]@{ tests = $true } }) | ConvertTo-Json), $Utf8NoBom)
    Assert-True (-not (Test-GateEvidence -RepoRoot $r5 -Gate 'tests')) 'a record with no fingerprint is refused'

    # --- 6. no repository, no evidence ---------------------------------------------------------
    Write-Host "`n== 6. outside a repository the gate simply runs ==" -ForegroundColor Cyan
    $bare = Join-Path $FixtureRoot 'not-a-repo'
    New-Item -ItemType Directory -Path $bare -Force | Out-Null
    Assert-True ($null -eq (Get-GateFingerprint -RepoRoot $bare)) 'a non-repository yields no fingerprint'
    Assert-True (-not (Test-GateEvidence -RepoRoot $bare -Gate 'tests')) 'and therefore never honours a skip'
    Assert-True (-not (Save-GateEvidence -RepoRoot $bare -Gate 'tests')) 'and records nothing'

    # --- 7. Clear-GateEvidence -----------------------------------------------------------------
    Write-Host "`n== 7. the record can be dropped ==" -ForegroundColor Cyan
    $r7 = New-GitFixture
    $f7 = Get-GateFingerprint -RepoRoot $r7
    [void](Save-GateEvidence -RepoRoot $r7 -Gate 'tests' -Fingerprint $f7)
    Assert-True (Test-GateEvidence -RepoRoot $r7 -Gate 'tests') 'recorded'
    Assert-True ([bool](Clear-GateEvidence -RepoRoot $r7)) 'cleared'
    Assert-True (-not (Test-GateEvidence -RepoRoot $r7 -Gate 'tests')) 'and the skip is gone with it'
    Assert-True ([bool](Clear-GateEvidence -RepoRoot $r7)) 'clearing an absent record is not an error'

    # --- 8. open-pr wires it in, and only on a real pass ---------------------------------------
    # The lib being right proves nothing about it being REACHED -- the lesson pr-issues-lib cost:
    # a pure decision table proves the decision, never that it is reached.
    Write-Host "`n== 8. open-pr.ps1 consults and records ==" -ForegroundColor Cyan
    $openPr = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'scripts\release\open-pr.ps1'))
    Assert-True ($openPr -match "lib\\gate-lib\.ps1") 'open-pr dot-sources gate-lib'
    Assert-True ($openPr -match 'Get-GateFingerprint -RepoRoot \$repoRoot') 'it computes the fingerprint once'
    Assert-Equal 1 ([regex]::Matches($openPr, 'Get-GateFingerprint').Count) 'exactly once, not per gate'
    Assert-Equal 2 ([regex]::Matches($openPr, 'Test-GateEvidence').Count) 'both gates consult the record'
    Assert-Equal 2 ([regex]::Matches($openPr, 'Save-GateEvidence').Count) 'and both record their own pass'

    # The escape valves must record nothing: a skipped gate proves nothing about the tree, and
    # evidence written there would make -SkipTests suppress the NEXT run's gate as well.
    $lintBlock = [regex]::Match($openPr, '(?s)if \(-not \$SkipLint\).*?\n\}').Value
    $testBlock = [regex]::Match($openPr, '(?s)if \(-not \$SkipTests\).*?\n\}').Value
    Assert-True ($lintBlock -match 'Save-GateEvidence') 'the lint save sits INSIDE the -SkipLint guard'
    Assert-True ($testBlock -match 'Save-GateEvidence') 'the tests save sits INSIDE the -SkipTests guard'

    # --- 9. the pair is registered and mirrored ------------------------------------------------
    Write-Host "`n== 9. the lib travels to the consumer ==" -ForegroundColor Cyan
    . (Join-Path $RepoRoot 'scripts\lib\shared-scripts-lib.ps1')
    $pairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot)
    $gatePair = @($pairs | Where-Object { $_.Name -eq 'gate-lib' })
    Assert-Equal 1 $gatePair.Count 'gate-lib is registered exactly once'
    if ($gatePair.Count -eq 1) {
        Assert-True ([bool]$gatePair[0].LibOnly) 'registered as a dot-sourced library'
        Assert-True (Test-Path -LiteralPath $gatePair[0].MirrorPath) 'and its mirror exists in the plugin tree'
        $srcText = [System.IO.File]::ReadAllText($gatePair[0].SourcePath)
        $mirText = [System.IO.File]::ReadAllText($gatePair[0].MirrorPath)
        Assert-Equal $srcText.Length $mirText.Length 'source and mirror are byte-identical in length'
    }

    # --- 10. CI must never consult a local record ----------------------------------------------
    # A fresh checkout has no state file, so this holds today by construction. The assert exists so
    # that stays true if somebody later teaches ci.yml to reuse open-pr's gate wiring.
    Write-Host "`n== 10. CI is unaffected ==" -ForegroundColor Cyan
    $ci = [System.IO.File]::ReadAllText((Join-Path $RepoRoot '.github\workflows\ci.yml'))
    Assert-True ($ci -notmatch 'Test-GateEvidence') 'ci.yml does not consult gate evidence'
    Assert-True ($ci -notmatch 'gate-lib') 'ci.yml does not load gate-lib at all'

} finally {
    if (Test-Path -LiteralPath $FixtureRoot) {
        Remove-Item -Recurse -Force -LiteralPath $FixtureRoot -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
