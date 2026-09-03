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
         1 is indistinguishable from the old loop except by how long the run takes, and a gate that quietly
         went back to sequential would be read as "the machine is busy today". Proven by OVERLAP rather
         than by the clock -- see the comment above case 4, which is where the first version of this suite
         went wrong and had to be repaired against CI rather than against a local run.
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
    param([string]$TestsDir, [int]$MaxParallel = 0, [string]$WorkDir = '', [string]$CommandsFile = '')
    # NOT $args: that is an automatic variable holding a function's unbound arguments, and splatting it
    # after assignment is the kind of collision this repo already documents for $script:-owned names.
    $psArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:Driver, '-TestsDir', $TestsDir, '-MaxParallel', "$MaxParallel")
    if ($WorkDir) { $psArgs += @('-WorkDir', $WorkDir) }
    if ($CommandsFile) { $psArgs += @('-CommandsFile', $CommandsFile) }
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

# Folds PowerShell backtick continuations into one logical statement, so a scan judges a statement
# rather than a physical line. Issue #1326: a fixture path whose discriminator ($PID, a fresh GUID)
# sits after a `-continuation is still per-process, but a physical-line scan reads only its first line
# and reports a correct path as an offender. A line whose last non-whitespace character is a backtick
# is glued to the next -- exactly how the parser treats it -- and the returned object keeps the
# STARTING physical line number so an offender is still named at a place you can open.
function Join-BacktickContinuation {
    param([string[]]$Lines)
    $out = New-Object System.Collections.Generic.List[pscustomobject]
    $i = 0
    while ($i -lt $Lines.Count) {
        $start = $i + 1
        $stmt  = $Lines[$i]
        while ($stmt -match '`[ \t]*$' -and ($i + 1) -lt $Lines.Count) {
            $i++
            $stmt = ($stmt -replace '`[ \t]*$', ' ') + $Lines[$i].Trim()
        }
        $i++
        $out.Add([pscustomobject]@{ Line = $start; Text = $stmt })
    }
    ,$out
}

try {
    Write-Host "== test-suite-gate.tests: the gate every PR and every release runs ==" -ForegroundColor Cyan
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null

    # --- 0. The elapsed figure is formatted INVARIANTLY (issue #1159) ------------------------------
    #
    # '-f' formats in the current culture: on a Dutch machine '{0:N0}' renders 2182 as '2.182', which an
    # English reader of this repo reads as 2.182 seconds -- a factor of a thousand off and still
    # plausible. It only misformats above 1000s, i.e. exactly the slow runs worth noticing, so a bare
    # -f went unnoticed for the gate's whole life. Format-GateSeconds routes through InvariantCulture;
    # this asserts it under nl-NL, where a regression would go green in en-US (measure-skill's lesson).
    Write-Host "the elapsed figure does not shift meaning with the operator's locale" -ForegroundColor Cyan
    . $LibPath
    $prevCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
    try {
        [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('nl-NL')
        Assert-Equal '2,182' (Format-GateSeconds 2182.4) 'Format-GateSeconds: 2182s is 2,182 even under nl-NL (not 2.182)'
        Assert-Equal '249'   (Format-GateSeconds 249)    'Format-GateSeconds: a sub-1000 figure carries no separator'
        Assert-Equal '0'     (Format-GateSeconds 0.4)    'Format-GateSeconds: rounds to whole seconds'
    } finally {
        [System.Threading.Thread]::CurrentThread.CurrentCulture = $prevCulture
    }

    # The driver dot-sources the REAL lib -- not a copy. A fixture copy would let the lib change without
    # this suite noticing, which is the whole failure mode it exists to catch.
    $script:Driver = Join-Path $Fixture 'drive-gate.ps1'
    $driverBody = @"
param([string]`$TestsDir, [int]`$MaxParallel = 0, [string]`$WorkDir = '', [string]`$CommandsFile = '')
`$ErrorActionPreference = 'Stop'
. '$LibPath'
if (`$WorkDir) { Set-Location -LiteralPath `$WorkDir }
# Models a consumer's repo-config defining the optional seam: the gate reads it via Get-Command, the
# way open-pr and cut-release have it in scope after their own dot-source of repo-config.ps1.
if (`$CommandsFile) {
    `$script:GateCommands = @(Get-Content -LiteralPath `$CommandsFile)
    function Get-TestCommands { return `$script:GateCommands }
}
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
    # THE LANE COUNT IS ON THE SUMMARY LINE (issue #1318). The count line at :674 already carried it, but
    # nobody quotes that line -- the summary is the one that reaches a branch doc or a changelog entry, and
    # the seconds without the lanes are a draw from a 4.5x spread. The number is the resolved $MaxParallel
    # (clamped to the suite count here), so it is machine-dependent -- assert its shape, not its value.
    Assert-True ($r.Text -match 'test gate: all 3 suites passed in \d+s \(\d+ lanes?\)\.') 'the summary names the lane count the seconds depend on'

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
    Assert-True ($r.Text -match 'test gate: 1 of 2 suites FAILED in \d+s \(\d+ lanes?\): z-broken\.tests\.ps1') 'and the closing summary carries the lane count and names it (issue #1318 -- the red line too)'
    Assert-True ($r.Text -match 'MARKER-Z') 'the failing suite still prints its own output -- attributable without a second run'

    # --- 4. It really is parallel, and -MaxParallel 1 really is the way back ------------------------
    #
    # ASSERTED ON OVERLAP, NOT ON THE CLOCK -- and the first version of this suite got that wrong in a way
    # worth keeping written down. It asserted that six 2s suites finish "well under" their 12s serial sum,
    # which passed locally at 2.8s and FAILED IN CI at 9.3s: a four-core runner, this suite itself running
    # alongside three others, and six Start-Process launches competing with all of it. The ratio assert
    # that was supposed to be the load-independent backstop failed with it, because an inflated parallel
    # figure sits in its denominator.
    #
    # THE RULE THAT FALLS OUT OF IT: a timing FLOOR is a testable property, because Start-Sleep guarantees
    # it; a timing CEILING is not, because nothing bounds how slow a shared machine can be. So the question
    # "did these run at the same time?" is answered by asking whether their lifetimes OVERLAP, which is
    # what the word means and is immune to how long each one took. Each fake suite stamps its own start and
    # end; parallel must produce at least one intersecting pair, serial exactly none. That is a stronger
    # claim than any stopwatch bound, and it let the sleeps shrink from 2s to 1.2s.
    Write-Host "the point of the exercise -- do the suites overlap in time, or queue behind each other" -ForegroundColor Cyan
    $slow   = Join-Path $Fixture 'suites-slow'
    $stamps = Join-Path $Fixture 'stamps'
    New-Item -ItemType Directory -Path $stamps -Force | Out-Null
    1..6 | ForEach-Object {
        $body = "`$s = [DateTime]::UtcNow.Ticks`r`n" +
                "Start-Sleep -Milliseconds 1200`r`n" +
                "Set-Content -LiteralPath '$stamps\s$_.txt' -Value (`"`$s `" + [DateTime]::UtcNow.Ticks) -Encoding Ascii`r`n" +
                "Write-Host 'SLEPT-$_'`r`nexit 0`r`n"
        New-FakeSuite -Dir $slow -Name "s$_.tests.ps1" -Body $body
    }

    # Counts pairs of [start,end] intervals that intersect. Reads the stamp files the fake suites wrote.
    function Get-OverlapCount {
        param([string]$StampDir)
        $iv = @(Get-ChildItem -Path $StampDir -Filter '*.txt' -File | ForEach-Object {
            $parts = (Get-Content -LiteralPath $_.FullName -Raw).Trim() -split '\s+'
            [pscustomobject]@{ Start = [long]$parts[0]; End = [long]$parts[1] }
        })
        $n = 0
        for ($a = 0; $a -lt $iv.Count; $a++) {
            for ($b = $a + 1; $b -lt $iv.Count; $b++) {
                if ($iv[$a].Start -lt $iv[$b].End -and $iv[$b].Start -lt $iv[$a].End) { $n++ }
            }
        }
        return $n
    }

    $par = Invoke-Gate -TestsDir $slow
    Assert-True ($par.Text -match 'GATE-RESULT: True') 'all six slow suites pass'
    Assert-Equal 6 (@($par.Lines | Where-Object { $_ -match '^SLEPT-\d$' }).Count) 'and all six actually ran'
    Assert-Equal 6 (@(Get-ChildItem -Path $stamps -Filter '*.txt' -File).Count) 'and all six stamped their own lifetime'
    $parOverlap = Get-OverlapCount -StampDir $stamps
    Assert-True ($parOverlap -ge 1) "their lifetimes overlap -- they ran at the same time ($parOverlap intersecting pair(s) of 15)"

    Get-ChildItem -Path $stamps -Filter '*.txt' -File | Remove-Item -Force
    $ser = Invoke-Gate -TestsDir $slow -MaxParallel 1
    Assert-True ($ser.Text -match 'GATE-RESULT: True') '-MaxParallel 1 still passes them'
    Assert-True ($ser.Flat -match 'one at a time') 'and says which mode it is in'
    # -MaxParallel 1 is the one deterministic lane count, so it is the one the summary can be asserted on
    # exactly: singular 'lane', not 'lanes' (issue #1318).
    Assert-True ($ser.Text -match 'test gate: all 6 suites passed in \d+s \(1 lane\)\.') 'the summary says one lane, singular, when the valve is closed'
    Assert-Equal 0 (Get-OverlapCount -StampDir $stamps) 'serially NOTHING overlaps -- the valve really queues them'
    # The one timing assert that is safe, because it is a floor the sleeps guarantee: six 1.2s suites in
    # sequence cannot come in under 7.2s of sleeping, however fast the machine is.
    Assert-True ($ser.Seconds -ge 6) "and it costs their sum (took $([math]::Round($ser.Seconds,1))s)"

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

    # --- 6. Get-TestCommands: the repo's own commands join the gate (inbound #644) -------------------
    #
    # The seam is read INSIDE the gate via Get-Command, so the driver models a consumer by defining the
    # function before the call -- exactly what open-pr/cut-release's dot-source of repo-config.ps1 does.
    # The exit-code case uses cmd /c exit 7, a NATIVE exit code: the child powershell must propagate it
    # rather than report its own did-it-parse verdict, which is what the trailing 'exit $LASTEXITCODE'
    # buys and what this assert would catch losing.
    Write-Host "Get-TestCommands -- a consumer's own test commands run and are judged like suites" -ForegroundColor Cyan
    $cmdOk = Join-Path $Fixture 'commands-ok.txt'
    [System.IO.File]::WriteAllText($cmdOk, "Write-Host 'CMD-MARKER-OK'`r`n", $Utf8NoBom)
    $r = Invoke-Gate -TestsDir $ok -CommandsFile $cmdOk
    Assert-True ($r.Text -match 'GATE-RESULT: True') 'three suites plus a passing command: the gate returns true'
    Assert-True ($r.Flat -match 'running 1 repo test command') 'and it announces the command half separately'
    Assert-True ($r.Text -match 'CMD-MARKER-OK') 'the command''s own output is printed'
    Assert-True ($r.Text -match 'test gate: all 4 suites passed in \d+s \(\d+ lanes?\)\.') 'the summary counts the command with the suites and still names the lane count (issue #1318)'

    $cmdBad = Join-Path $Fixture 'commands-bad.txt'
    [System.IO.File]::WriteAllText($cmdBad, "cmd /c exit 7`r`n", $Utf8NoBom)
    $r = Invoke-Gate -TestsDir $ok -CommandsFile $cmdBad
    Assert-True ($r.Text -match 'GATE-RESULT: False') 'a failing command fails the whole gate'
    Assert-True ($r.Text -match '== cmd /c exit 7 == FAILED \(exit 7\)') 'its header carries the NATIVE exit code, propagated through the child'
    Assert-True ($r.Text -match 'test gate: 1 of 4 suites FAILED in \d+s \(\d+ lanes?\): cmd /c exit 7') 'and the closing summary carries the lane count and names the command'

    # A repo whose whole suite is Get-TestCommands: no scripts\tests at all, and the gate still runs.
    $r = Invoke-Gate -TestsDir (Join-Path $Fixture 'no-such-dir') -CommandsFile $cmdOk
    Assert-True ($r.Text -match 'GATE-RESULT: True') 'commands-only: a missing suites dir does not skip the gate'
    Assert-True ($r.Flat -notmatch 'test gate skipped') 'and it does not claim to have skipped'
    Assert-True ($r.Text -match 'test gate: all 1 suites passed in \d') 'the verdict counts the one command'
    # THE EDGE THE LANE NOTE HAS TO RESPECT (issue #1318): a commands-only gate never resolves $MaxParallel
    # -- its commands run one at a time -- so there is no pool count to state and the summary carries none.
    Assert-True ($r.Flat -notmatch 'test gate: all 1 suites passed in \d+s \(') 'a commands-only gate states no lane count -- the pool never ran'

    # The two silent-success shapes the judging suffix exists to close (found in review). A bare
    # 'exit $LASTEXITCODE' coerced both to exit 0: the pure-PowerShell failure sets no native exit
    # code at all, and the unterminated quote swallowed the suffix into its own string literal.
    $cmdPsFail = Join-Path $Fixture 'commands-psfail.txt'
    [System.IO.File]::WriteAllText($cmdPsFail, "Write-Error 'red but native-exit-code-less'`r`n", $Utf8NoBom)
    $r = Invoke-Gate -TestsDir $ok -CommandsFile $cmdPsFail
    Assert-True ($r.Text -match 'GATE-RESULT: False') 'a pure-PowerShell failure with no native exit code still fails the gate'

    $cmdNoParse = Join-Path $Fixture 'commands-noparse.txt'
    [System.IO.File]::WriteAllText($cmdNoParse, "Write-Host `"unterminated`r`n", $Utf8NoBom)
    $r = Invoke-Gate -TestsDir $ok -CommandsFile $cmdNoParse
    Assert-True ($r.Text -match 'GATE-RESULT: False') 'a command that does not parse is refused, not run truncated'
    Assert-True ($r.Text -match 'FAILED \(does not parse') 'and the header says why'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

# --- Every suite's temp fixture must be per-process ------------------------------------------------
#
# THE FAILURE THIS PREVENTS, measured on August 11, 2026. Running one suite by hand while the gate was
# running produced TWO failing asserts in connectors.tests.ps1 -- a suite that passes on its own. Nothing
# was wrong with the code under test: both runs built a fixture at the same fixed temp path, and each
# tore down the other's tree mid-assert. The visible result is a red gate naming a subject that is fine,
# which is the most expensive kind of false failure because the obvious next move is to go and read the
# subject.
#
# WHY THIS SUITE OWNS THE RULE. Since #512 the gate is a throttled PARALLEL scheduler, so concurrency is
# this file's subject. There is no collision WITHIN one gate run -- each fixture name is unique per suite
# -- but two gate runs, or a gate run beside a developer running one suite, share every fixed name. The
# gate being parallel is what makes that an ordinary situation rather than an exotic one.
#
# MEASURED BEFORE BEING WRITTEN: 38 of the temp paths in these suites already carried $PID or a GUID and
# 14 did not, across 11 files. So this asserts a convention the suites had already chosen, rather than
# imposing a new one -- which is also why the 14 repaired sites carry no explanatory comment: the 38 that
# were already right do not either, and a comment on half of them would read as the odd case.
#
# THE SUBJECT IS THE DISCRIMINATOR, NOT THE SPELLING. $PID, a fresh GUID and a per-case label built on top
# of either all pass; a bare literal does not. Two suites legitimately use a GUID rather than $PID because
# they create one file PER CHILD INVOCATION and $PID would be the same for all of them.
#
# And the spelling includes the LINE BREAKS. Backtick continuations are folded first, so the unit judged
# is a statement rather than a physical line: a discriminator on the far side of a `-continuation is in
# view, and a path split so that GetTempPath() and Join-Path land on different lines is still seen (#1326).
Write-Host ''
Write-Host 'every suite keeps its temp fixture per-process' -ForegroundColor Cyan
# This file is the guard, not a fixture-building suite -- it carries GetTempPath()/Join-Path in its
# own prose and in the #1326 fold cases below, which are test DATA rather than paths a run creates.
# Its one real fixture ($Fixture, at the top) is $PID-keyed. A guard scanning itself only re-checks
# its own example strings, so it is left out.
$self = 'test-suite-gate.tests.ps1'
$suiteFiles = @(Get-ChildItem -Path (Join-Path $RepoRoot 'scripts\tests') -Filter '*.ps1' -File |
    Where-Object { $_.Name -ne $self })
Assert-True ($suiteFiles.Count -gt 20) "the scan found the suites (saw $($suiteFiles.Count) files)"

$tempLines = New-Object System.Collections.Generic.List[pscustomobject]
foreach ($sf in $suiteFiles) {
    $folded = Join-BacktickContinuation ([System.IO.File]::ReadAllLines($sf.FullName))
    foreach ($stmt in $folded) {
        if ($stmt.Text -notmatch 'GetTempPath\(\)') { continue }
        # This file's own guard quotes the API in prose above; only statements that BUILD a path count.
        if ($stmt.Text -notmatch 'Join-Path') { continue }
        $tempLines.Add([pscustomobject]@{ File = $sf.Name; Line = $stmt.Line; Text = $stmt.Text.Trim() })
    }
}
Assert-True ($tempLines.Count -gt 40) "the scan really read the temp paths (found $($tempLines.Count))"

# A path is safe when its name carries something that differs between two concurrent processes: $PID, or a
# variable holding a freshly generated value. $Label alone is NOT enough -- it varies within a run and
# repeats across them, which is exactly the case that was wrong in bootstrap-drift.
$unsafe = @($tempLines | Where-Object { $_.Text -notmatch '\$PID|\$tag|\$Guid|NewGuid' })
Assert-Equal 0 $unsafe.Count ("every temp fixture path is per-process (offenders: " +
    (@($unsafe | ForEach-Object { "$($_.File):$($_.Line)" }) -join ', ') + ')')

# --- The continuation fold, exercised directly (#1326) ---------------------------------------------
#
# The scan above trusted the discriminator to sit on the same physical line as the GetTempPath()/
# Join-Path pair. A backtick continuation puts it on the next line, and the assert then reported a
# path that is in fact per-process -- measured on fix/guard-coverage-comment-counts (#1321), where a
# helper carrying both $PID and a fresh GUID was named as an offender. These two cases pin the fold:
# a split SAFE path must fold to one statement with its discriminator visible, and a split BARE
# literal must still be caught.
Write-Host ''
Write-Host 'a backtick continuation does not hide the discriminator' -ForegroundColor Cyan
$splitSafe = Join-BacktickContinuation @(
    '    $p = Join-Path ([System.IO.Path]::GetTempPath()) `',
    '        ("srguard-$PID-$Label-" + [guid]::NewGuid().ToString(''N'').Substring(0, 6) + ''.ps1'')'
)
Assert-Equal 1 $splitSafe.Count 'a backtick continuation folds to a single statement'
Assert-True (($splitSafe[0].Text -match 'GetTempPath\(\)') -and ($splitSafe[0].Text -match 'Join-Path')) `
    'the folded statement still carries both path markers'
Assert-True ($splitSafe[0].Text -match '\$PID|\$tag|\$Guid|NewGuid') `
    'and the discriminator after the continuation is now in view'

$splitBare = Join-BacktickContinuation @(
    '    $p = Join-Path ([System.IO.Path]::GetTempPath()) `',
    '        "fixed-fixture-name.ps1"'
)
Assert-True ($splitBare[0].Text -notmatch '\$PID|\$tag|\$Guid|NewGuid') `
    'a bare literal split across a continuation is still reported'

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
