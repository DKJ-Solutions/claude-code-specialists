<#
.SYNOPSIS
    Regression tests for scripts/lib/native-capture-lib.ps1 -- the -Utf8 capture path (issue #907).

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

    $committed = "# Development cycle: ``feat/shipping-v1``" + "`n`nA line with an $dash em-dash." + "`n"
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
    [System.IO.File]::WriteAllText((Join-Path $gitFx 'cycle.md'), "# Development cycle: ``main```n", $utf8NoBom)
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
