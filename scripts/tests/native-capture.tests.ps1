<#
.SYNOPSIS
    Regression tests for scripts/lib/native-capture-lib.ps1 -- the -Utf8 capture path (issue #907),
    the non-interactive environment + bounded wait (inbound #1179), and the shared read of the capture
    files while a killed grandchild still holds a handle (#1252).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Exit code 0 if everything passes, 1 on a
    failure -- so usable as a CI gate.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/native-capture.tests.ps1

    What this suite is for. Windows PowerShell 5.1 decodes a native child's stdout with
    [Console]::OutputEncoding, so the SAME command returns different strings depending on the console
    code page the run inherited. The DEPLOY lock compares a gh-read PR body against a file read as
    UTF-8; on a cp850 console the two sides were decoded differently and the lock refused a PR whose
    body was intact, naming a line that reads as correct -- in a gate with no -Force (issue #907,
    measured on PR #906).

    WHAT THE #1179 SECTIONS ARE FOR, since they test a different property of the same file. A git call
    the workflow makes can block on a credential helper that opens a prompt nothing will answer: on
    DAVE-KOK-BWJ a `git push` and the `git credential-manager get` it spawned were both still running
    fifteen minutes later, and the ship reported it as still shipping. Two guards answer that, and each
    is pinned separately because either one alone leaves a hole -- the environment closes the measured
    cause, the bound closes the class. The kill is asserted against a GRANDCHILD, because the process
    that actually blocked was the grandchild and a kill that misses it buys nothing.

    Those sections cost this suite roughly fifteen seconds of deliberate waiting. That is the subject:
    a bound can only be tested by outlasting it, and a fixture that stalls for less than the bound
    proves nothing. The suites run in parallel under the gate, so it costs wall-clock only if this is
    the slowest one.

    THE ENCODING ASSERTS RUN IN A CHILD PROCESS WITH ITS OWN CONSOLE, and that is the whole reason
    this suite is shaped the way it is. [Console]::OutputEncoding's setter is SetConsoleOutputCP,
    which is console-WIDE rather than per-process: the test gate starts every suite with
    -NoNewWindow on one shared console, so a suite that flips the code page flips it for every
    sibling scheduled beside it. That is exactly how inbound #821 stayed invisible for as long as it
    did -- an assert green under the gate and red on its own. Start-Process WITHOUT -NoNewWindow
    gives the child its own console, so the flip cannot leave this process.

    Note what is deliberately NOT asserted: that the default (non -Utf8) path mangles UTF-8 on cp850.
    It does, and that is the defect this switch exists to route around -- but pinning it would turn a
    future decision to change the default into a test failure rather than a decision. What is pinned
    is the property that matters: -Utf8 returns the same bytes on every code page.

    Pure ASCII (repo convention for .ps1) -- the em-dash under test is built from its code point.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

$sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("native-capture-tests-$PID")
if (Test-Path -LiteralPath $sandbox) { Remove-Item -Recurse -Force -LiteralPath $sandbox }
New-Item -ItemType Directory -Path $sandbox -Force | Out-Null

try {
    # ---------------------------------------------------------------------------------------------
    Write-Host 'ConvertTo-NativeArgumentToken -- quoting for CreateProcess' -ForegroundColor Cyan

    Assert-Equal 'plain'          (ConvertTo-NativeArgumentToken -Value 'plain')        'an argument with nothing special is passed through unquoted'
    Assert-Equal '"hello world"'  (ConvertTo-NativeArgumentToken -Value 'hello world')  'a space forces quoting -- Start-Process joins on spaces and quotes nothing'
    Assert-Equal '""'             (ConvertTo-NativeArgumentToken -Value '')             'an empty string becomes a real empty argument, not nothing at all'
    Assert-True  ((ConvertTo-NativeArgumentToken -Value 'a"b') -like '*\"*')            'an embedded quote is escaped rather than left to terminate the token'
    # A trailing backslash only needs doubling when a closing quote follows it -- unquoted, it is an
    # ordinary character and is passed through. So the doubling case is a value that ALSO forces
    # quoting; asserting it on a bare 'ends\' would be asserting the wrong branch.
    Assert-Equal 'ends\'          (ConvertTo-NativeArgumentToken -Value 'ends\')        'a trailing backslash on an otherwise plain value is left alone -- nothing quotes it'
    Assert-Equal '"a b\\"'        (ConvertTo-NativeArgumentToken -Value 'a b\')         'a trailing backslash run IS doubled once quoting is forced, so it cannot escape the closing quote'

    # ---------------------------------------------------------------------------------------------
    Write-Host 'Invoke-NativeCapture -Utf8 -- argument round trip through a real argv parser' -ForegroundColor Cyan

    # cmd's echo prints its remainder verbatim, quotes included, so it cannot answer this question.
    # A PowerShell child receiving $args can: whatever comes out of it is what CreateProcess parsed.
    $argProbe = Join-Path $sandbox 'argprobe.ps1'
    Set-Content -LiteralPath $argProbe -Encoding Ascii -Value 'foreach ($a in $args) { Write-Output ("[" + $a + "]") }'

    function Invoke-ArgProbe {
        param([string[]]$Values)
        $r = Invoke-NativeCapture -Utf8 -FilePath 'powershell' -Arguments (@('-NoProfile', '-File', $argProbe) + $Values)
        return (@($r.Output) -join ' ')
    }

    Assert-Equal '[plain]'            (Invoke-ArgProbe -Values @('plain'))          'a plain argument arrives intact'
    Assert-Equal '[hello world]'      (Invoke-ArgProbe -Values @('hello world'))    'an argument with a space arrives as ONE argument'
    Assert-Equal '[a b] [c]'          (Invoke-ArgProbe -Values @('a b', 'c'))       'a spaced argument does not swallow the one after it'
    Assert-Equal '[has"quote]'        (Invoke-ArgProbe -Values @('has"quote'))      'an embedded quote survives the round trip'
    Assert-Equal '[trailing\]'        (Invoke-ArgProbe -Values @('trailing\'))      'a trailing backslash survives the round trip'
    # The two hard rules meeting in one value: this is the case the doubling exists for, and the only
    # one where getting it wrong swallows the NEXT argument rather than corrupting this one.
    Assert-Equal '[a b\] [next]'      (Invoke-ArgProbe -Values @('a b\', 'next'))   'a quoted argument ending in a backslash does not escape its own closing quote'

    # ---------------------------------------------------------------------------------------------
    Write-Host 'Invoke-NativeCapture -Utf8 -- exit codes and stderr' -ForegroundColor Cyan

    $ok  = Invoke-NativeCapture -Utf8 -FilePath 'cmd' -Arguments @('/c', 'exit', '0')
    $bad = Invoke-NativeCapture -Utf8 -FilePath 'cmd' -Arguments @('/c', 'exit', '3')
    Assert-Equal 0 $ok.ExitCode  'exit 0 is reported as 0'
    # Not merely "non-zero": Start-Process -PassThru without reading .Handle returns an EMPTY
    # ExitCode once the child has exited, and empty is not 3. This is the assert that catches it.
    Assert-Equal 3 $bad.ExitCode 'a non-zero exit code is reported exactly, not as empty'

    $merged    = Invoke-NativeCapture -Utf8 -FilePath 'cmd' -Arguments @('/c', 'echo oops 1>&2')
    $discarded = Invoke-NativeCapture -Utf8 -FilePath 'cmd' -Arguments @('/c', 'echo oops 1>&2') -DiscardStderr
    Assert-True  ((@($merged.Output) -join '').Contains('oops')) 'stderr is merged into Output by default'
    Assert-Equal 0 (@($discarded.Output).Count)                  '-DiscardStderr keeps stderr out, so it cannot pollute JSON'

    # ---------------------------------------------------------------------------------------------
    Write-Host 'Invoke-NativeCapture -Utf8 -- output shape' -ForegroundColor Cyan

    # A FILE rather than 'cmd /c echo a& echo b': echo's handling of its remainder inserts trailing
    # spaces around the separators, which would be asserting cmd's quirks instead of this function's
    # line splitting. The file's bytes are known exactly, including its single terminating newline.
    $lines3 = Join-Path $sandbox 'lines3.txt'
    [System.IO.File]::WriteAllText($lines3, "a`r`nb`r`nc`r`n", (New-Object System.Text.UTF8Encoding $false))
    $three = Invoke-NativeCapture -Utf8 -FilePath 'cmd' -Arguments @('/c', 'type', $lines3)
    Assert-Equal 3 (@($three.Output).Count) 'output comes back as one entry per line'
    Assert-Equal 'a' (@($three.Output)[0])  'the first line is the first line'
    # The newline that ENDS the last line is a terminator, not an empty line after it. A stray ''
    # here would become an extra element in every caller's -join.
    Assert-Equal 'c' (@($three.Output)[-1]) 'no phantom empty line is appended from the trailing newline'

    # ---------------------------------------------------------------------------------------------
    Write-Host 'Invoke-NativeCapture -- the child runs non-interactively (inbound #1179)' -ForegroundColor Cyan

    # THE ASSERTS BELOW MUTATE THIS PROCESS'S ENVIRONMENT, and that is safe here for the reason the
    # code-page asserts further down are NOT: Invoke-TestSuiteGate starts every suite as its own
    # Start-Process child, so a process-scope environment variable cannot reach a sibling suite. The
    # console is what is shared, not the environment.
    #
    # And every assert starts by DELETING both names rather than assuming they are unset. The machine
    # that produced #1179 may well carry them as a hand-placed bridge, and an assert that reads
    # "restored to absent" while the machine set it to '0' would pass on a laptop and fail in CI.
    function Reset-GuardEnv {
        foreach ($n in 'GIT_TERMINAL_PROMPT', 'GCM_INTERACTIVE') {
            [Environment]::SetEnvironmentVariable($n, $null, 'Process')
        }
    }

    Reset-GuardEnv
    $seen = Invoke-NativeCapture -FilePath 'cmd' -Arguments @('/c', 'echo GTP=%GIT_TERMINAL_PROMPT% GCM=%GCM_INTERACTIVE%')
    $seenText = (@($seen.Output) -join '')
    # BOTH NAMES, ASSERTED SEPARATELY. They stop different things -- git's own terminal prompt and the
    # credential manager's window -- and setting only GIT_TERMINAL_PROMPT leaves the measured hang
    # exactly in place, so an assert on the pair as one string would pass with the real defect present.
    Assert-True ($seenText -like '*GTP=0*')      'the child sees GIT_TERMINAL_PROMPT=0 -- git will not prompt on a terminal'
    Assert-True ($seenText -like '*GCM=never*')  'the child sees GCM_INTERACTIVE=never -- the credential manager fails instead of drawing a window'

    Reset-GuardEnv
    $seen8 = Invoke-NativeCapture -Utf8 -FilePath 'cmd' -Arguments @('/c', 'echo GTP=%GIT_TERMINAL_PROMPT% GCM=%GCM_INTERACTIVE%')
    # The Start-Process arm is a DIFFERENT launcher, so it inherits nothing from the assert above. Both
    # arms are exercised because ship-pr.ps1 reaches gh through one and git through the other.
    Assert-True ((@($seen8.Output) -join '') -like '*GTP=0*') 'the Start-Process arm guards its child too, not only the & arm'

    Reset-GuardEnv
    $null = Invoke-NativeCapture -FilePath 'cmd' -Arguments @('/c', 'exit', '0')
    # ABSENT IS NOT '': git reads a defined-but-empty GIT_TERMINAL_PROMPT differently from an undefined
    # one, so a restore that writes '' would leave every script that ran one git call in a state it did
    # not start in. This is the assert that catches `$env:NAME = $null`, which does exactly that.
    Assert-True ($null -eq [Environment]::GetEnvironmentVariable('GIT_TERMINAL_PROMPT', 'Process')) 'a variable that was ABSENT is restored to absent, not to the empty string'

    [Environment]::SetEnvironmentVariable('GIT_TERMINAL_PROMPT', 'callers-own', 'Process')
    $null = Invoke-NativeCapture -FilePath 'cmd' -Arguments @('/c', 'exit', '0')
    Assert-Equal 'callers-own' ([Environment]::GetEnvironmentVariable('GIT_TERMINAL_PROMPT', 'Process')) "a caller's own value is handed back, not ours"

    Reset-GuardEnv
    try { $null = Invoke-NativeCapture -FilePath 'a-command-that-does-not-exist-1179' -Arguments @() } catch { }
    # The restore is in a finally, and this is what proves it: a command that cannot even be launched
    # must not leave the guard behind for the rest of the script.
    Assert-True ($null -eq [Environment]::GetEnvironmentVariable('GIT_TERMINAL_PROMPT', 'Process')) 'the guard is restored even when the call throws instead of running'

    Reset-GuardEnv

    # ---------------------------------------------------------------------------------------------
    Write-Host 'Invoke-NativeCapture -TimeoutSeconds -- a stall fails loudly (inbound #1179)' -ForegroundColor Cyan

    # WHAT THIS PINS is the property the report asked for: the call RETURNS. Before the bound, a child
    # that never exits held the script forever and the workflow reported it as still working -- the
    # fifteen-minute hang on DAVE-KOK-BWJ. So the assert is on the elapsed time as much as on the
    # verdict: a wait that answered correctly after 30 seconds would be the defect, not the fix.
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $stalled = Invoke-NativeCapture -FilePath 'powershell' -Arguments @('-NoProfile', '-Command', 'Start-Sleep -Seconds 30') -TimeoutSeconds 2
    $sw.Stop()
    Assert-True  ($sw.Elapsed.TotalSeconds -lt 25)  'a child that would run for 30s is given up on, not waited out'
    Assert-True  $stalled.TimedOut                  'TimedOut says so, so a caller does not have to recognise an exit code'
    Assert-Equal 124 $stalled.ExitCode              'the exit code is the timeout code, not whatever the kill left behind'
    # THE DIAGNOSIS IS IN Output BECAUSE THAT IS WHERE CALLERS LOOK: every bounded site pipes Output to
    # Write-Host and then judges ExitCode. Without this line the three of them report a stall as a bare
    # non-zero exit, which is the "hang presented as something else" the report was about.
    Assert-True  ((@($stalled.Output) -join ' ') -like '*[[]timeout[]]*') 'Output carries a [timeout] line, so an unchanged caller still prints the reason'

    # A BOUND THAT DOES NOT EXPIRE CHANGES NOTHING. This is the assert that keeps the bound from
    # becoming a second failure mode of its own: the exit code still comes back exactly, which is the
    # #907 empty-ExitCode trap the Start-Process arm has to keep clearing.
    $inTime = Invoke-NativeCapture -FilePath 'cmd' -Arguments @('/c', 'exit', '7') -TimeoutSeconds 30
    Assert-Equal 7 $inTime.ExitCode   'a bounded call that finishes in time reports its own exit code'
    Assert-True  (-not $inTime.TimedOut) 'and does not claim to have timed out'

    # TimedOut IS PRESENT ON EVERY RETURN, from both arms, so no caller has to know which arm answered.
    $plain = Invoke-NativeCapture -FilePath 'cmd' -Arguments @('/c', 'exit', '0')
    Assert-True (-not $plain.TimedOut) 'an unbounded call on the & arm still carries TimedOut = $false'
    $plain8 = Invoke-NativeCapture -Utf8 -FilePath 'cmd' -Arguments @('/c', 'exit', '0')
    Assert-True (-not $plain8.TimedOut) 'and so does an unbounded call on the Start-Process arm'

    # A BOUND MUST NOT MOVE THE CHILD'S WORKING DIRECTORY (inbound #1181). This is the assumption every
    # bounded caller silently rests on, and it was worth measuring rather than reasoning about: passing
    # -TimeoutSeconds routes the call onto the Start-Process arm, and Set-Location changes PowerShell's
    # PROVIDER location without touching [Environment]::CurrentDirectory -- the classic 5.1 divergence.
    # Had Start-Process followed the .NET value, a bound would have run git in whatever directory the
    # session happened to start in. sync-main.ps1 is the caller that makes this load-bearing: it does
    # Set-Location to the repo root it resolved and then relies on every git call landing there.
    #
    # THE ASSERT IS AGAINST A DIVERGENCE IT CREATES ITSELF, so it cannot pass by accident on a session
    # where the two already agree -- which is how the first hand-check of this nearly proved nothing.
    $cwdProbe = Join-Path $sandbox 'cwd-probe'
    New-Item -ItemType Directory -Path $cwdProbe -Force | Out-Null
    $prevNetCurrent = [Environment]::CurrentDirectory
    Push-Location -LiteralPath $cwdProbe
    try {
        [Environment]::CurrentDirectory = $sandbox
        Assert-True ((Get-Location).Path -ne [Environment]::CurrentDirectory) 'the probe really did diverge the two notions of "here"'
        $whereBounded = Invoke-NativeCapture -FilePath 'cmd' -Arguments @('/c', 'cd') -TimeoutSeconds 30
        Assert-Equal $cwdProbe (@($whereBounded.Output) -join '').Trim() 'a bounded call runs in the PROVIDER location, not in [Environment]::CurrentDirectory'
    } finally {
        Pop-Location
        [Environment]::CurrentDirectory = $prevNetCurrent
    }

    # ---------------------------------------------------------------------------------------------
    Write-Host 'Stop-NativeProcessTree -- the GRANDCHILD dies too (inbound #1179)' -ForegroundColor Cyan

    # THIS IS THE MEASURED SHAPE, and it is the reason taskkill /T is used rather than Stop-Process. In
    # the report the process that blocked was not `git.exe push` (PID 11372) but the
    # `git credential-manager get` it spawned (PID 27176). Killing only the parent leaves that one
    # holding the prompt -- the hang survives the timeout, and the bound buys nothing.
    #
    # The fixture writes TWO markers: 'started' the moment the grandchild runs, 'survived' only after it
    # outlives the kill. Both are needed. Asserting the absence of 'survived' alone passes just as
    # happily when the grandchild never launched at all, which would be a test that cannot fail.
    #
    # BOTH HALVES OF THE FIXTURE ARE FILES, not -Command strings, and that is this suite's own subject
    # biting back: Start-Process joins -ArgumentList on spaces and quotes NOTHING, so a -Command string
    # carrying the sandbox path would arrive at the grandchild torn into pieces -- the grandchild would
    # never launch, and the survival assert would pass for the wrong reason. -File plus parameters means
    # the only quoting that has to be right is ConvertTo-NativeArgumentToken's, which is under test
    # sixty lines above.
    # ONE SANDBOX PATH PER ATTEMPT (see the retry note below): a kill is ALLOWED to fail, so a
    # grandchild that outlived its attempt must not be able to write into the next attempt's markers
    # and vouch for a launch that did not happen.
    $gcScript = Join-Path $sandbox 'grandchild.ps1'
    Set-Content -LiteralPath $gcScript -Encoding Ascii -Value @(
        'param([string]$Started, [string]$Survived, [int]$Sleep)'
        'Set-Content -LiteralPath $Started -Value started'
        'Start-Sleep -Seconds $Sleep'
        'Set-Content -LiteralPath $Survived -Value survived'
    )

    # The outer quotes the grandchild's arguments itself, for the same Start-Process reason.
    $outerScript = Join-Path $sandbox 'grandchild-parent.ps1'
    Set-Content -LiteralPath $outerScript -Encoding Ascii -Value @(
        'param([string]$Child, [string]$Started, [string]$Survived, [int]$Sleep, [int]$Stall)'
        '$quoted = @($Child, $Started, $Survived) | ForEach-Object { ''"'' + $_ + ''"'' }'
        'Start-Process -FilePath powershell -NoNewWindow -ArgumentList (@(''-NoProfile'', ''-ExecutionPolicy'', ''Bypass'', ''-File'') + $quoted + @("$Sleep"))'
        'Start-Sleep -Seconds $Stall'
    )

    # THE BOUND HAS TO COVER TWO COLD POWERSHELL 5.1 STARTUPS BEFORE THE GRANDCHILD CAN WRITE ITS
    # MARKER, and on a loaded machine 3s does not (issue #1232). Measured here on 18 cores, launch to
    # marker: 0.52s idle, 0.58s at half the cores busy, 2.67s with every core busy, 9.68s at twice
    # that -- so the failure arrives exactly when this suite is run the way it is meant to be run, in
    # a 58-suite sweep. The two startups split it roughly in half, and the OUTER half alone (4.6s at
    # twice the cores) already overruns 3s, so making only the grandchild cheaper would not settle it.
    #
    # POLLING FOR THE MARKER AFTER THE RUN RETURNS CANNOT WORK, which is worth stating because it is
    # the obvious repair: Stop-NativeProcessTree kills with taskkill /T, the grandchild is inside that
    # tree, and whether it wrote its marker is therefore settled AT kill time and never changes after.
    #
    # SO THE ATTEMPT IS REPEATED WITH A WIDER BOUND. An unloaded machine passes the first one and pays
    # what this fixture always paid; a loaded one re-runs the fixture instead of reporting a failure
    # of the code under test. A run where even the wide bound cannot get the grandchild up still
    # FAILS -- the gate keeps a verdict that means something, and by then the machine is the finding.
    #
    # The two derived numbers, per attempt. The grandchild must outlive the kill, so it sleeps
    # bound + 3. A SURVIVOR must have had time to write its second marker before that marker is
    # checked, so the wait after the run is bound + 6. At the first bound those are 6 and 9 -- the
    # numbers this fixture has used since it was written.
    $tree     = $null
    $started  = $null
    $survived = $null
    $afterRun = 0
    foreach ($bound in 3, 12) {
        $started  = Join-Path $sandbox "grandchild-started-$bound.txt"
        $survived = Join-Path $sandbox "grandchild-survived-$bound.txt"
        $afterRun = $bound + 6

        $tree = Invoke-NativeCapture -FilePath 'powershell' -Arguments @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $outerScript,
            $gcScript, $started, $survived, "$($bound + 3)", "$($bound + 30)"
        ) -TimeoutSeconds $bound

        if (Test-Path -LiteralPath $started) { break }
        Write-Host "  the grandchild did not launch inside ${bound}s -- loaded machine, retrying wider" -ForegroundColor DarkYellow
    }

    Assert-True $tree.TimedOut 'the fixture stalled as intended, so the kill under test actually ran'
    Assert-True (Test-Path -LiteralPath $started) 'the grandchild really launched -- without this the next assert could not fail'

    # Long enough that a SURVIVING grandchild would have written its second marker (it sleeps from a
    # start that precedes the bound), with margin for a loaded machine.
    Start-Sleep -Seconds $afterRun
    Assert-True (-not (Test-Path -LiteralPath $survived)) 'the grandchild was killed with its parent -- taskkill /T, not Stop-Process'

    # ---------------------------------------------------------------------------------------------
    Write-Host 'Read-NativeCaptureFileText -- a lingering write handle is not an IO error (#1252)' -ForegroundColor Cyan

    # THE OTHER HALF OF THE KILL ABOVE. The grandchild dies, but not synchronously: the bounded wait
    # after Stop-NativeProcessTree is on the DIRECT child only, so a grandchild that inherited the
    # redirected stdout handle can still hold out.txt when the read runs. The gap is wall-clock --
    # invisible locally (58 suites, 207s), a lost race on a CI runner four times slower (859s), where
    # it turned an unrelated branch's green red. [System.IO.File]::ReadAllText opens with
    # FileShare.Read, which cannot coexist with the writer handle still open, so it throws
    # "being used by another process". The fixture holds that handle for real rather than simulating
    # the window with a sleep.
    $held = Join-Path $sandbox 'held-open.txt'
    [System.IO.File]::WriteAllText($held, "flushed output`n", (New-Object System.Text.UTF8Encoding $false))
    $writer = New-Object System.IO.FileStream(
        $held, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
    try {
        $threw = $false
        try { [void][System.IO.File]::ReadAllText($held) } catch { $threw = $true }
        Assert-True $threw 'the plain ReadAllText throws while the handle is held -- this is the bug the CI red was'

        $got = Read-NativeCaptureFileText -Path $held -Encoding (New-Object System.Text.UTF8Encoding $false)
        Assert-Equal "flushed output`n" $got 'the shared read returns what was flushed instead of throwing'
    } finally {
        $writer.Dispose()
    }

    # ---------------------------------------------------------------------------------------------
    Write-Host 'Invoke-NativeCapture -Utf8 -- the code page cannot reach the answer (issue #907)' -ForegroundColor Cyan

    # 'ory <em-dash> e' as gh would put it on the wire: UTF-8, e2 80 94 in the middle. Written as
    # bytes so this .ps1 stays ASCII, which the script layer requires.
    $wire = Join-Path $sandbox 'wire.txt'
    [System.IO.File]::WriteAllBytes($wire, [byte[]](0x6f, 0x72, 0x79, 0x20, 0xe2, 0x80, 0x94, 0x20, 0x65))

    # The child: set ITS console to $cp, capture the file through the lib, report the bytes it got.
    # Runs with its own console (no -NoNewWindow) so SetConsoleOutputCP cannot reach this process or
    # any sibling suite -- see the .DESCRIPTION.
    $cpProbe = Join-Path $sandbox 'cpprobe.ps1'
    $cpProbeBody = @'
param([int]$Cp, [string]$Lib, [string]$Wire, [string]$Out)
$ErrorActionPreference = 'Stop'
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding($Cp)
    . $Lib
    $r = Invoke-NativeCapture -Utf8 -FilePath 'cmd' -Arguments @('/c', 'type', $Wire)
    $text = (@($r.Output) -join '')
    $hex = ([System.Text.Encoding]::UTF8.GetBytes($text) | ForEach-Object { $_.ToString('x2') }) -join ' '
    Set-Content -LiteralPath $Out -Encoding Ascii -Value $hex
} catch {
    Set-Content -LiteralPath $Out -Encoding Ascii -Value ("ERROR: " + $_.Exception.Message)
}
'@
    Set-Content -LiteralPath $cpProbe -Encoding Ascii -Value $cpProbeBody

    $lib = (Resolve-Path (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')).Path
    $expectedHex = '6f 72 79 20 e2 80 94 20 65'
    $results = @{}
    foreach ($cp in @(65001, 850, 437)) {
        $outFile = Join-Path $sandbox "cp$cp.txt"
        $p = Start-Process -FilePath 'powershell' -WindowStyle Hidden -PassThru -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $cpProbe + '"'),
            '-Cp', $cp, '-Lib', ('"' + $lib + '"'), '-Wire', ('"' + $wire + '"'), '-Out', ('"' + $outFile + '"'))
        $null = $p.Handle
        $p.WaitForExit()
        $results[$cp] = if (Test-Path -LiteralPath $outFile) { (Get-Content -LiteralPath $outFile -Raw).Trim() } else { '<no output>' }
    }

    foreach ($cp in @(65001, 850, 437)) {
        Assert-Equal $expectedHex $results[$cp] "cp $cp decodes the UTF-8 em-dash to the bytes that were on the wire"
    }
    # Stated as its own assert because it is the property the DEPLOY lock actually depends on: not
    # that any one code page is right, but that they cannot disagree with each other.
    Assert-Equal 1 (@($results.Values | Sort-Object -Unique).Count) 'all three code pages agree -- the console cannot change the answer'

    # ---------------------------------------------------------------------------------------------
    Write-Host 'Test-DeployLock -- the defect end to end (issue #907)' -ForegroundColor Cyan

    . (Join-Path $PSScriptRoot '..\lib\pr-body-lib.ps1')

    $dash = [string][char]0x2014
    $section = "## DEPLOY: ``fix/x-v1``" + "`n`n" + "A line with an $dash em-dash in it." + "`n`n" + '**Score:** 2'

    # What a correct read produces: body and document identical, so the lock holds.
    $lockOk = Test-DeployLock -EntryText $section -PrBody $section
    Assert-True $lockOk.Applicable      'the lock applies to a section carrying its own heading'
    Assert-True $lockOk.Locked          'an intact body locks'

    # What a cp850 read produced: the em-dash arriving as the three characters it decodes to. This is
    # the exact shape #907 measured, and the assert says the lock was RIGHT to refuse it -- the defect
    # was never in the comparison, it was in handing it a mis-decoded string.
    $mojibake = $section.Replace($dash, ([string][char]0x00D4 + [string][char]0x00C7 + [string][char]0x00F6))
    $lockBad = Test-DeployLock -EntryText $section -PrBody $mojibake
    Assert-True $lockBad.Applicable     'the lock still applies -- the heading is ASCII and survived the mis-decode'
    Assert-True (-not $lockBad.Locked)  'a mis-decoded body does NOT lock, which is why #907 refused a correct PR'
    Assert-True ($lockBad.FirstDrift -like "*$dash*") 'and the line it names is the one carrying the em-dash'

    # ---------------------------------------------------------------------------------------------
    Write-Host 'Get-GitFileTextAtRef -- a COMMIT is not a checkout (issue #970)' -ForegroundColor Cyan

    # A REAL REPOSITORY RATHER THAN A MOCK, because every property under test is git's: which bytes a
    # blob holds, what `git show` does with a path a ref does not carry, and how its stderr behaves. A
    # fake that answered those would only pin what this suite already believes.
    #
    # A LOCAL FIXTURE RATHER THAN THIS REPO'S OWN HISTORY, deliberately: the divergence asserts below
    # need the working tree to differ from the commit and a second branch to exist, and arranging that
    # in the checkout the suite is running from would be editing the tree under the gate.
    $gitFx = Join-Path $sandbox 'ref-read'
    New-Item -ItemType Directory -Path $gitFx -Force | Out-Null
    function Invoke-FxGit {
        param([string[]]$GitArgs)
        # -c over `git config`: the fixture needs an identity to commit and nothing should depend on
        # whatever the machine running the gate has set globally.
        $r = Invoke-NativeCapture -FilePath 'git' -Arguments (@(
            '-C', $gitFx, '-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid',
            '-c', 'commit.gpgsign=false') + $GitArgs)
        if ($r.ExitCode -ne 0) { throw "fixture git failed: $($GitArgs -join ' ')`n$($r.Output -join "`n")" }
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    # symbolic-ref rather than `init --initial-branch=main`: the flag is git 2.28 and later, and this
    # points the unborn HEAD at the same place on every version.
    Invoke-FxGit -GitArgs @('init', '--quiet')
    Invoke-FxGit -GitArgs @('symbolic-ref', 'HEAD', 'refs/heads/main')

    $committed = "# Development: ``feat/shipping-v1``" + "`n`nA line with an $dash em-dash." + "`n"
    [System.IO.File]::WriteAllText((Join-Path $gitFx 'cycle.md'), $committed, $utf8NoBom)
    [System.IO.File]::WriteAllText((Join-Path $gitFx 'empty.md'), '', $utf8NoBom)
    Invoke-FxGit -GitArgs @('add', 'cycle.md', 'empty.md')
    Invoke-FxGit -GitArgs @('commit', '--quiet', '-m', 'the shipping commit')

    Assert-Equal $committed.TrimEnd("`n") (Get-GitFileTextAtRef -Ref 'refs/heads/main' -Path 'cycle.md' -RepoRoot $gitFx) 'the ref hands back the committed text'
    Assert-True ((Get-GitFileTextAtRef -Ref 'refs/heads/main' -Path 'cycle.md' -RepoRoot $gitFx).Contains($dash)) 'and its em-dash survives, so a DEPLOY-lock comparison is not comparing a mis-decode'
    # ABSENT AND EMPTY ARE DIFFERENT ANSWERS, and this is the assert the resolver's fallback rests on:
    # both are falsy in PowerShell, so a caller that tested truthiness would read an empty document as
    # a missing one -- which is the silent-skip direction #970 is about.
    $absent = Get-GitFileTextAtRef -Ref 'refs/heads/main' -Path 'no/such/file.md' -RepoRoot $gitFx
    Assert-True ($null -eq $absent) 'a path the ref does not carry comes back as $null'
    $blank = Get-GitFileTextAtRef -Ref 'refs/heads/main' -Path 'empty.md' -RepoRoot $gitFx
    Assert-True ($null -ne $blank) 'an EMPTY committed file is not absent'
    Assert-Equal '' $blank 'it is the empty string -- so absent and empty cannot be confused'

    # git writes 'fatal: path ... does not exist' to stderr for the missing path above. -DiscardStderr
    # is what keeps that out of the returned document; without it a caller would have to RECOGNISE it.
    Assert-True (-not ([string]$absent).Contains('fatal')) "git's own error line never arrives inside the document"

    # THE DIVERGENCE THAT IS THE WHOLE POINT. The working tree is overwritten and a second branch is
    # created and checked out -- the #970 shape exactly: the run is shipping feat/shipping-v1 while the
    # checkout has moved on. The read must still answer for the commit.
    [System.IO.File]::WriteAllText((Join-Path $gitFx 'cycle.md'), "# Development: ``main```n", $utf8NoBom)
    Invoke-FxGit -GitArgs @('checkout', '--quiet', '-b', 'feat/the-next-thing')
    Invoke-FxGit -GitArgs @('add', 'cycle.md')
    Invoke-FxGit -GitArgs @('commit', '--quiet', '-m', 'the branch created during the CI wait')

    Assert-Equal $committed.TrimEnd("`n") (Get-GitFileTextAtRef -Ref 'refs/heads/main' -Path 'cycle.md' -RepoRoot $gitFx) 'the shipping ref still answers its own commit after the checkout moved'
    Assert-True ((Get-GitFileTextAtRef -Ref 'refs/heads/feat/the-next-thing' -Path 'cycle.md' -RepoRoot $gitFx) -notlike "*shipping*") 'and the other branch is a different answer -- which is what the working tree would have given'

    # A SLASH IN THE BRANCH NAME IS THE ORDINARY CASE HERE, so the ref form is asserted rather than
    # assumed: 'refs/heads/feat/the-next-thing' resolves, and that is why callers pass the full name.
    Assert-True ($null -ne (Get-GitFileTextAtRef -Ref 'refs/heads/feat/the-next-thing' -Path 'cycle.md' -RepoRoot $gitFx)) 'a prefixed branch name resolves as a ref'

    # Join-Path output is the likeliest input a caller has lying around, so a backslash path is
    # converted rather than refused.
    Assert-Equal $committed.TrimEnd("`n") (Get-GitFileTextAtRef -Ref 'refs/heads/main' -Path 'cycle.md' -RepoRoot $gitFx) 'a forward-slash path reads'
    New-Item -ItemType Directory -Path (Join-Path $gitFx 'sub') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $gitFx 'sub\nested.md'), "nested`n", $utf8NoBom)
    Invoke-FxGit -GitArgs @('add', 'sub/nested.md')
    Invoke-FxGit -GitArgs @('commit', '--quiet', '-m', 'a nested path')
    Assert-Equal 'nested' (Get-GitFileTextAtRef -Ref 'HEAD' -Path 'sub\nested.md' -RepoRoot $gitFx) 'and so does the same path written with backslashes'
} finally {
    if (Test-Path -LiteralPath $sandbox) { Remove-Item -Recurse -Force -LiteralPath $sandbox -ErrorAction SilentlyContinue }
}

Write-Host ''
if ($script:fail -eq 0) {
    Write-Host "Result: $($script:pass) pass, 0 fail." -ForegroundColor Green
    exit 0
}
Write-Host "Result: $($script:pass) pass, $($script:fail) fail." -ForegroundColor Red
exit 1
