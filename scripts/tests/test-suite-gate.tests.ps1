<#
.SYNOPSIS
    Tests for Invoke-TestSuiteGate in scripts/lib/native-capture-lib.ps1 -- the gate open-pr.ps1,
    cut-release.ps1 and CI all run.

.DESCRIPTION
    The function had wiring-level coverage only: cut-release-guardrail.tests.ps1 asserts that both release
    scripts CALL it and that it is defined once. Nothing asserted what it DOES, which was tolerable while
    it was a fifteen-line foreach and stopped being tolerable on August 7, 2026, when issue #512 turned it
    into a throttled parallel scheduler. Three of its properties can now break silently:

      1. IT MUST ACTUALLY RUN THEM IN PARALLEL. A scheduler with an off-by-one that leaves the throttle at
         1 is indistinguishable from the old loop except by the clock, and a gate that quietly went back
         to 572s would be read as "the machine is busy today".
      2. ATTRIBUTION MOVED FROM POSITION TO HEADER. Sequentially, a suite's output followed its own
         '== name ==' line because nothing else could be printed in between. In parallel that is only true
         because each child's output is buffered to its own files and flushed as one block. An interleaving
         bug produces output that still LOOKS right -- 26 headers, all the lines present -- with the lines
         under the wrong headers, which is worse than no attribution at all.
      3. THE CHILD'S WORKING DIRECTORY. Start-Process starts a child in [Environment]::CurrentDirectory,
         which does not follow Set-Location, so dropping -WorkingDirectory would hand every suite a
         different vantage point than '& powershell -File' did. roster-sync.tests.ps1 asserts against the
         tree it runs in and would go red for a reason nobody would look for in this file.

    WHY EVERY CASE GOES THROUGH A CHILD PROCESS. The gate reports through Write-Host, which writes to the
    host and never enters the pipeline -- an in-process '$out = Invoke-TestSuiteGate ...' would capture the
    return value and NOT one line of the output these assertions are about, so every assertion on that
    output would pass by being unable to see anything (Sylvester's lens, July 29, 2026). The driver script
    below dot-sources the real lib and prints the verdict, and the suite reads it back the way open-pr's
    console does.

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibPath  = Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1'

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

$Fixture   = Join-Path ([System.IO.Path]::GetTempPath()) "test-suite-gate-test-$PID"
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function New-FakeSuite {
    param([string]$Dir, [string]$Name, [string]$Body)
    New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $Dir $Name), $Body, $Utf8NoBom)
}

# Returns the gate's console output as a line array plus how long the run took. The elapsed time is
# measured around the CHILD, so it includes one powershell start-up (~0.2s) on top of the gate itself --
# irrelevant against the multi-second margins the timing cases work with.
function Invoke-Gate {
    param([string]$TestsDir, [int]$MaxParallel = 0, [string]$WorkDir = '')
    # NOT $args: that is an automatic variable holding a function's unbound arguments, and splatting it
    # after assignment is the kind of collision this repo already documents for $script:-owned names.
    $psArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:Driver, '-TestsDir', $TestsDir, '-MaxParallel', "$MaxParallel")
    if ($WorkDir) { $psArgs += @('-WorkDir', $WorkDir) }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $out = & powershell @psArgs 2>&1
    $sw.Stop()
    $lines = @($out | ForEach-Object { "$_" })
    $text  = ($lines -join "`n")
    return [pscustomobject]@{
        Lines   = $lines
        Text    = $text
        # ASSERT PROSE AGAINST .Flat, NOT .Text. Write-Host writes its string through untouched, but
        # Write-Warning goes through the formatter, which HARD-WRAPS at the console width of a redirected
        # child -- and a fixture path is long enough that the break lands mid-sentence. The first version
        # of the missing-dir assert failed for exactly that, on a gate that was behaving correctly.
        # Collapsing every run of whitespace to one space makes a wrapped line and an unwrapped one read
        # the same.
        Flat    = ($text -replace '\s+', ' ')
        Seconds = $sw.Elapsed.TotalSeconds
    }
}

try {
    Write-Host "== test-suite-gate.tests: the gate every PR and every release runs ==" -ForegroundColor Cyan
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null

    # The driver dot-sources the REAL lib -- not a copy. A fixture copy would let the lib change without
    # this suite noticing, which is the whole failure mode it exists to catch.
    $script:Driver = Join-Path $Fixture 'drive-gate.ps1'
    $driverBody = @"
param([string]`$TestsDir, [int]`$MaxParallel = 0, [string]`$WorkDir = '')
`$ErrorActionPreference = 'Stop'
. '$LibPath'
if (`$WorkDir) { Set-Location -LiteralPath `$WorkDir }
`$r = Invoke-TestSuiteGate -TestsDir `$TestsDir -Context 'the fixture' -MaxParallel `$MaxParallel
Write-Host "GATE-RESULT: `$r"
"@
    [System.IO.File]::WriteAllText($script:Driver, $driverBody, $Utf8NoBom)

    # --- 1. The empty-input contract: a repo without suites is not a failing repo -------------------
    Write-Host "the two empty cases -- nothing to run is not a red gate" -ForegroundColor Cyan
    $missing = Join-Path $Fixture 'no-such-dir'
    $r = Invoke-Gate -TestsDir $missing
    Assert-True ($r.Text -match 'GATE-RESULT: True') 'a missing tests dir returns true'
    Assert-True ($r.Flat -match 'test gate skipped') 'and says so instead of passing in silence'

    $empty = Join-Path $Fixture 'empty-suites'
    New-Item -ItemType Directory -Path $empty -Force | Out-Null
    $r = Invoke-Gate -TestsDir $empty
    Assert-True ($r.Text -match 'GATE-RESULT: True') 'a dir with no suites returns true'
    Assert-True ($r.Flat -match 'had nothing to run') 'and says that too'

    # --- 2. All-pass: the count, the filter, the blocks, the summary --------------------------------
    Write-Host "an all-passing run -- attribution comes from the header, not the position" -ForegroundColor Cyan
    $ok = Join-Path $Fixture 'suites-ok'
    New-FakeSuite -Dir $ok -Name 'a-first.tests.ps1'  -Body "Write-Host 'MARKER-A'`r`nexit 0`r`n"
    New-FakeSuite -Dir $ok -Name 'b-second.tests.ps1' -Body "Write-Host 'MARKER-B'`r`nexit 0`r`n"
    # Writes on BOTH streams. Start-Process cannot redirect stdout and stderr to one file, so the two are
    # captured apart and printed one after the other -- a suite whose only diagnostic went to stderr would
    # otherwise vanish, and the gate would report a failure with no visible reason.
    New-FakeSuite -Dir $ok -Name 'c-noisy.tests.ps1'  -Body "Write-Host 'MARKER-C'`r`n[Console]::Error.WriteLine('STDERR-MARKER-C')`r`nexit 0`r`n"
    # Not a suite: pins the *.tests.ps1 filter, which the count line would otherwise report as 4.
    New-FakeSuite -Dir $ok -Name 'helper.ps1'         -Body "Write-Host 'MARKER-HELPER'`r`nexit 1`r`n"

    $r = Invoke-Gate -TestsDir $ok
    Assert-True ($r.Text -match 'GATE-RESULT: True') 'three passing suites: the gate returns true'
    Assert-True ($r.Text -match 'running all 3 test suites for the fixture') 'the count names 3 -- helper.ps1 is not a suite'
    Assert-True ($r.Text -notmatch 'MARKER-HELPER') 'and it was never run'
    Assert-True ($r.Text -match 'test gate: all 3 suites passed in \d') 'the summary states the verdict and the elapsed time'

    # THE ATOMIC-BLOCK ASSERT. Not "both lines are present somewhere" -- an interleaving bug satisfies
    # that. Each marker must sit on the line directly after its OWN header, which is exactly the property
    # buffering per child buys and the property a switch back to live streaming would lose.
    foreach ($pair in @(
        @{ Suite = 'a-first.tests.ps1';  Marker = 'MARKER-A' },
        @{ Suite = 'b-second.tests.ps1'; Marker = 'MARKER-B' },
        @{ Suite = 'c-noisy.tests.ps1';  Marker = 'MARKER-C' }
    )) {
        $h = [Array]::IndexOf($r.Lines, "== $($pair.Suite) ==")
        Assert-True ($h -ge 0) "$($pair.Suite): its header is printed"
        Assert-True ($h -ge 0 -and $r.Lines[$h + 1] -eq $pair.Marker) "$($pair.Suite): its own output is the very next line"
    }
    $hc = [Array]::IndexOf($r.Lines, '== c-noisy.tests.ps1 ==')
    Assert-True ($hc -ge 0 -and $r.Lines[$hc + 2] -eq 'STDERR-MARKER-C') 'a suite stderr line lands inside that same block, right behind its stdout'

    # --- 3. A failing suite: the exit code, the marked header, the named summary --------------------
    Write-Host "a failing run -- the verdict must survive 25 green siblings" -ForegroundColor Cyan
    $bad = Join-Path $Fixture 'suites-bad'
    New-FakeSuite -Dir $bad -Name 'a-first.tests.ps1' -Body "Write-Host 'MARKER-A'`r`nexit 0`r`n"
    New-FakeSuite -Dir $bad -Name 'z-broken.tests.ps1' -Body "Write-Host 'MARKER-Z'`r`nexit 3`r`n"

    $r = Invoke-Gate -TestsDir $bad
    Assert-True ($r.Text -match 'GATE-RESULT: False') 'one failing suite fails the whole gate'
    Assert-True ($r.Text -match '== z-broken\.tests\.ps1 == FAILED \(exit 3\)') 'its header carries the failure AND the real exit code'
    Assert-True ($r.Text -match '== a-first\.tests\.ps1 ==\r?\n') 'the passing sibling keeps its plain header'
    Assert-True ($r.Text -match 'test gate: 1 of 2 suites FAILED in \d+s: z-broken\.tests\.ps1') 'and the closing summary names it'
    Assert-True ($r.Text -match 'MARKER-Z') 'the failing suite still prints its own output -- attributable without a second run'

    # --- 4. It really is parallel, and -MaxParallel 1 really is the way back ------------------------
    Write-Host "the point of the exercise -- six 2s suites do not cost twelve seconds" -ForegroundColor Cyan
    $slow = Join-Path $Fixture 'suites-slow'
    1..6 | ForEach-Object {
        New-FakeSuite -Dir $slow -Name "s$_.tests.ps1" -Body "Start-Sleep -Seconds 2`r`nWrite-Host 'SLEPT-$_'`r`nexit 0`r`n"
    }
    $par = Invoke-Gate -TestsDir $slow
    Assert-True ($par.Text -match 'GATE-RESULT: True') 'all six slow suites pass'
    Assert-Equal 6 (@($par.Lines | Where-Object { $_ -match '^SLEPT-\d$' }).Count) 'and all six actually ran'
    Assert-True ($par.Seconds -lt 8) "six 2s suites finish well under their 12s serial sum (took $([math]::Round($par.Seconds,1))s)"

    $ser = Invoke-Gate -TestsDir $slow -MaxParallel 1
    Assert-True ($ser.Text -match 'GATE-RESULT: True') '-MaxParallel 1 still passes them'
    Assert-True ($ser.Text -match 'one at a time') 'and says which mode it is in'
    Assert-True ($ser.Seconds -ge 10) "serially the same six cost their sum (took $([math]::Round($ser.Seconds,1))s)"
    # The ratio assert is the load-independent one: on a machine busy enough to blow the absolute bounds
    # above, this still separates a scheduler from a loop.
    Assert-True ($ser.Seconds -gt ($par.Seconds * 2)) 'serial is more than twice parallel -- the throttle is doing the work, not the clock'

    # --- 5. The working directory the child is handed ----------------------------------------------
    Write-Host "-WorkingDirectory -- the child inherits PowerShell's location, not the process's" -ForegroundColor Cyan
    # THIS CASE ONLY PROVES ANYTHING BECAUSE THE TWO DIFFER. The driver starts in whatever directory this
    # suite was launched from and then Set-Location's into $wdHome, which moves PowerShell's location and
    # leaves [Environment]::CurrentDirectory where it was. A gate that omitted -WorkingDirectory would
    # report the launch directory here and pass every other assert in this file.
    $wdHome   = Join-Path $Fixture 'wd-home'
    $wdSuites = Join-Path $Fixture 'wd-suites'
    New-Item -ItemType Directory -Path $wdHome -Force | Out-Null
    New-FakeSuite -Dir $wdSuites -Name 'cwd.tests.ps1' -Body "Write-Host ('CWD:' + (Get-Location).Path)`r`nexit 0`r`n"
    $r = Invoke-Gate -TestsDir $wdSuites -WorkDir $wdHome
    $reported = @($r.Lines | Where-Object { $_ -match '^CWD:' } | ForEach-Object { $_.Substring(4) })
    Assert-Equal 1 $reported.Count 'the probe suite reported its location'
    Assert-Equal $wdHome $reported[0] 'the suite ran in the gate caller''s location, not in the process working directory'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
