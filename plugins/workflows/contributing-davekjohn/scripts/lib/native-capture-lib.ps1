<#
.SYNOPSIS
    Shared helper to run a native command safely and capture its output + exit code (single source
    of truth, issue #114 item 1).

.DESCRIPTION
    Dot-source this file from a sibling of the script that needs it, relative to $PSScriptRoot (NOT
    $repoRoot) -- like scripts/lib/check-report-lib.ps1 and unlike scripts/repo-config.ps1 /
    scripts/lib/branch-info.ps1, this lib is not repo-owned, so it does not need a consumer-side
    scaffold. It travels as part of the SAME plugin/mirror payload as its callers (registered in
    scripts/lib/shared-scripts-lib.ps1), so a $PSScriptRoot-relative path resolves correctly whether
    the caller runs from the workshop root, a consumer's plugin cache, or the plugin mirror tree:

        . (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')   -- from scripts/release/*

    Why this exists (the #96/#97/#107 lesson, in one place):
      Windows PowerShell 5.1 promotes a native command's stderr lines to a TERMINATING
      NativeCommandError when $ErrorActionPreference is 'Stop'. A command that writes progress to
      stderr -- git push's 'remote:' lines, gh's status/URL lines -- would then kill the script
      BEFORE its $LASTEXITCODE could be judged, even when the command itself returned exit 0. The
      lesson: never rely on stderr-as-error, always on $LASTEXITCODE. This helper centralizes the
      save-EAP -> Continue -> run -> record $LASTEXITCODE -> restore dance so that reasoning lives
      in exactly one tested place instead of being re-derived at every call site.

    The native command runs INSIDE this function's own scope, where EAP is set to 'Continue'. That
    is deliberate: a scriptblock passed in by the caller would keep the caller's script scope (where
    EAP is usually 'Stop') as its resolution scope, so an EAP override here would not reach it --
    passing FilePath/Arguments and invoking here is what makes the guard actually take effect.

    Usage:
        $r = Invoke-NativeCapture -FilePath 'git' -Arguments @('push', '-u', 'origin', $branch)
        $r.Output | ForEach-Object { Write-Host $_ }
        if ($r.ExitCode -ne 0) { Write-Error 'git push failed.'; exit 1 }

        # -DiscardStderr keeps stderr out of the captured output (e.g. so it cannot pollute JSON):
        $r = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'list', '--json', 'number') -DiscardStderr

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function ConvertTo-NativeArgumentToken {
    <#
        One argument, quoted the way CreateProcess parses it back apart. Start-Process joins
        -ArgumentList on SPACES and quotes nothing, so an argument carrying a space would arrive at the
        child as two -- which is why this exists and why it is not needed on the & path, where
        PowerShell does the quoting itself.

        The backslash rule is the fiddly half and it is not optional: inside quotes, a run of
        backslashes immediately before the closing quote is halved by the parser, so a value ending in
        '\' would escape the very quote that terminates it. Doubling that run is the documented fix.
        An empty string becomes '""', which is a real argument rather than nothing at all.

        Internal to this lib (no export, no contract row): it exists only to serve the -Utf8 path
        below.
    #>
    param([AllowEmptyString()][Parameter(Mandatory = $true)][string]$Value)

    if ($Value -eq '') { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }

    # Double any backslash run that precedes a quote, and any that ends the value; escape the quotes.
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-NativeCapture {
    <#
        Run $FilePath with $Arguments under $ErrorActionPreference = 'Continue' and return a
        pscustomobject with:
          - Output   : the command's output. By default stderr is merged in (2>&1) so a caller can
                       echo full progress; with -DiscardStderr stderr is dropped (2>$null) so it
                       cannot pollute a machine-readable stdout (e.g. gh --json).
          - ExitCode : $LASTEXITCODE recorded immediately after the command ran.
        EAP is always restored (finally), whether the command succeeds, fails, or throws.

        -Utf8: DECODE THE OUTPUT AS UTF-8 INSTEAD OF WITH THE CONSOLE CODE PAGE (issue #907,
        August 26, 2026). Windows PowerShell 5.1 decodes a native child's stdout with
        [Console]::OutputEncoding, so the SAME command returns different strings on cp65001 and cp850.
        For a progress line that is cosmetic; for output the caller then PARSES or COMPARES it is a
        wrong answer that arrives as a plausible value. Measured on the DEPLOY lock: gh's UTF-8
        em-dash 'e2 80 94' came back as 'c3 94 c3 87 c3 b6' on a cp850 console, so the lock refused a
        PR whose body was intact and named a line that reads as correct -- in a gate with no -Force.
        Pass -Utf8 wherever the output is DATA rather than progress.

        WHY A REDIRECT AND NOT [Console]::OutputEncoding = UTF8 AROUND THE CALL. That setter is
        SetConsoleOutputCP: console-WIDE, not per-process. The test gate runs every suite with
        -NoNewWindow on one shared console, and a sibling holding UTF-8 is exactly how inbound #821
        stayed invisible -- an assert green under the gate and red on its own.
        .claude/rules/language-layers.md states the prohibition outright. Redirecting to a file and
        reading it with an explicit UTF-8 decode touches no shared state and is provably immune:
        measured identical on cp65001, cp850 and cp437.

        THE -Utf8 PATH IS A DIFFERENT MECHANISM, not a flag on the same one, so two things differ and
        both are deliberate. Output comes back as an ARRAY OF LINES (strings) rather than whatever
        objects the & operator produced -- ErrorRecords included, which is what a caller merging
        stderr was really getting. And the child is started by Start-Process, so $Arguments are quoted
        here rather than by PowerShell; see ConvertTo-NativeArgumentToken above.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [switch]$DiscardStderr,
        [switch]$Utf8
    )

    if ($Utf8) { return Invoke-NativeCaptureUtf8 -FilePath $FilePath -Arguments $Arguments -DiscardStderr:$DiscardStderr }

    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        if ($DiscardStderr) {
            $output = & $FilePath @Arguments 2>$null
        } else {
            $output = & $FilePath @Arguments 2>&1
        }
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prevEap
    }

    return [pscustomobject]@{ Output = $output; ExitCode = $code }
}

function Invoke-NativeCaptureUtf8 {
    <#
        The -Utf8 arm of Invoke-NativeCapture; see that function's docstring for WHY. Split out rather
        than nested in an if/else because the two share no lines: different launcher, different
        capture, different decode. Callers pass -Utf8 instead of naming this.

        Start-Process -PassThru THEN $proc.Handle THEN WaitForExit is the proven pattern from
        Invoke-TestSuiteGate below, and reading .Handle is NOT a no-op: without it .NET does not retain
        the OS handle and .ExitCode comes back EMPTY once the child has exited -- empty is not 0, and
        that is how this file's own gate once judged every green suite as failed.

        Capture goes to FILES rather than pipes: with -Wait-less Start-Process a full pipe buffer
        deadlocks, and a file cannot. Temp directory is per-process AND per-call, so two captures in
        one script cannot read each other's output.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [switch]$DiscardStderr
    )

    $capDir  = Join-Path ([System.IO.Path]::GetTempPath()) ("native-capture-$PID-" + [guid]::NewGuid().ToString('n'))
    $outFile = Join-Path $capDir 'out.txt'
    $errFile = Join-Path $capDir 'err.txt'

    try {
        New-Item -ItemType Directory -Path $capDir -Force | Out-Null

        $startArgs = @{
            FilePath               = $FilePath
            NoNewWindow            = $true
            PassThru               = $true
            RedirectStandardOutput = $outFile
            RedirectStandardError  = $errFile
        }
        # An EMPTY -ArgumentList is an error in Windows PowerShell 5.1, so it is omitted rather than
        # passed empty -- a command with no arguments is a normal call, not a special case.
        if ($Arguments.Count -gt 0) {
            $startArgs['ArgumentList'] = @($Arguments | ForEach-Object { ConvertTo-NativeArgumentToken -Value $_ })
        }

        $proc = Start-Process @startArgs
        $null = $proc.Handle
        $proc.WaitForExit()
        $code = $proc.ExitCode

        # No BOM on the decoder: a BOM-emitting child is not something gh or git does, and
        # UTF8Encoding($false) still strips one if it is there.
        $utf8 = New-Object System.Text.UTF8Encoding $false
        $text = ''
        if (Test-Path -LiteralPath $outFile) { $text = [System.IO.File]::ReadAllText($outFile, $utf8) }
        if (-not $DiscardStderr -and (Test-Path -LiteralPath $errFile)) {
            $text += [System.IO.File]::ReadAllText($errFile, $utf8)
        }

        # Lines, to match what the & path hands back. A single trailing newline is the terminator of
        # the last line rather than an empty line after it, so it is dropped; anything else is content.
        $lines = @()
        if ($text.Length -gt 0) {
            $text = $text -replace "`r`n", "`n"
            if ($text.EndsWith("`n")) { $text = $text.Substring(0, $text.Length - 1) }
            $lines = @($text -split "`n")
        }

        return [pscustomobject]@{ Output = $lines; ExitCode = $code }
    } finally {
        if (Test-Path -LiteralPath $capDir) {
            Remove-Item -Recurse -Force -LiteralPath $capDir -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-TestSuiteGate {
    <#
        Runs every *.tests.ps1 in $TestsDir as a child process and returns $true when they all passed.
        Prints each suite's name and its own output as it goes, so a failure is attributable without a
        second run.

        ONE OWNER, BECAUSE THERE ARE NOW TWO GATES (August 7, 2026). open-pr.ps1 has run the suites
        before pushing since PR #54's lesson; cut-release.ps1 ran the LINT only, which made the release
        commit the least-checked commit in the workflow -- the one that bumps four plugin versions,
        rewrites four RELEASE.md cards and empties CHANGELOG.md. Issue #510.

        The obvious repair was to copy those fifteen lines into the cut. That is the duplication this
        repo spent August 7 removing in six other places: two copies of one rule, free to drift, with the
        one that drifts being whichever nobody looked at. So the loop moved here and both call it.

        WHY THIS LIB AND NOT A NEW ONE, stated because the fit is imperfect. This file's synopsis is "run
        a native command safely and capture its output + exit code", and a test-suite gate is a step above
        that. A dedicated gate-lib.ps1 would read better -- and would cost an entry in the shared-scripts
        registry, a mirror file, and a row in the script contract, for one function. Both callers already
        dot-source this lib, and what the function does IS running child processes and judging their exit
        codes. The trade was taken deliberately; if a second gate helper ever appears, move both out
        together rather than widening this file again.

        NOT -SkipTests AWARE. The caller owns the escape valve, because the two differ: open-pr's is
        -SkipTests, the cut's is its own flag, and a lib that knew about either would be reaching into its
        callers' parameter sets.

        THE REPO'S OWN TEST COMMANDS RUN HERE TOO (inbound #644, August 13, 2026). The gate globbed
        scripts\tests\*.tests.ps1 and nothing else, while both callers describe it as "all test suites
        green" -- true in the source, whose suites are all PowerShell, and an overstatement in a consumer
        whose stack is not: the reporting repo runs 4 PowerShell suites next to 605 Vitest tests, and the
        gate saw only the first number. The release route is where that gap bites, because it is the one
        route with no later gate that can still stop anything -- CI fires after the tag is pushed, against
        a commit this repo's own rules say is not rewritten.

        The seam is the optional Get-TestCommands in scripts/repo-config.ps1: extra command lines to run
        alongside the suites (e.g. 'npm test'), defaulting to none, so an unadopting repo keeps exactly
        yesterday's gate. IT IS READ HERE AND NOT AT THE CALL SITES, deliberately: a seam read once in
        the shared gate cannot leave the gates checking different things -- which is this function's
        founding rule, stated above. THE CALLERS ARE THREE, NOT TWO, and each must have dot-sourced
        repo-config before calling this: open-pr and cut-release do so for their other seams, and
        ci.yml does so explicitly for this one -- it dot-sources only this lib otherwise, and without
        that line the required merge-blocking check would be the one gate that cannot see the repo's
        own commands, silently. The
        commands run SEQUENTIALLY, after the parallel pool: their runtimes and internal parallelism are
        their own (npm test manages its workers itself), and sequential output needs no capture files to
        stay attributable. Each runs as its own powershell child with the caller's location, exit code
        propagated, and a failing command fails the gate exactly like a failing suite.

        THE SUITES RUN IN PARALLEL (issue #512, August 7, 2026). Measured in the source repo on one machine
        within one session, all 27 suites green every time: 510s one at a time, against 128-263s parallel
        over six runs (median 159s). Every suite is an independent child process that spends most of its
        time waiting on children of its own, so running them sequentially was the simplest possible
        arrangement rather than a considered one. Parallel, the gate costs what its SLOWEST SINGLE SUITE
        costs instead of the sum -- which is why the remaining half of #512 matters more after this change
        than before it (check-plugin-integrity.tests, ~154s for 86 full lint runs over its fixture: the
        critical path all by itself), and also why the spread above is wide where the sequential figure is
        not. A sum averages its own variance out; a maximum does the opposite.

        AND THAT REMAINING HALF WAS THE WHOLE BILL, MEASURED (August 16, 2026, issue #714). At 40 suites the
        gate's total EQUALLED that one suite to a tenth of a second, four runs out of four: every other
        suite finished at 126.9s, after which one process ran alone for another 70-86 seconds with 15 of 16
        lanes empty. A new suite could therefore only lengthen the gate by CONTENDING with it -- which is
        what the "+40% and diffuse" report in #714 had actually measured. Because this scheduler
        parallelises per FILE, the repair was to make that work more than one file: it is now four suites
        sharing one fixture builder, ~51s across four lanes instead of ~160s in one, with no scenario
        removed. Read before proposing anything about this gate's cost: the lever is the slowest FILE, and
        splitting it is available where narrowing it is not.

        WHY Start-Process AND NOT A JOB. Windows PowerShell 5.1 has no ForEach-Object -Parallel, and
        Start-Job pays for a whole runspace to then spawn the same child process this does directly. What
        parallelism costs here is the console: two dozen suites writing to one screen interleave into an
        unreadable weave, so each child's output is captured to its own pair of files and printed as ONE
        BLOCK when it exits. Attribution therefore comes from the '== <suite> ==' header the block opens
        with, not from its position -- which is the property that mattered in the sequential version too.
        Blocks arrive in COMPLETION order, so the log is no longer alphabetical; the closing summary names
        the failures in a fixed order for that reason.

        -WorkingDirectory IS NOT OPTIONAL, and leaving it off is the one way this rewrite could have
        broken a suite silently. Start-Process starts the child in [Environment]::CurrentDirectory, which
        does NOT follow Set-Location -- so a suite that asks git about "the tree I am in" would have been
        answered by whatever directory the process was launched from, days ago. roster-sync.tests.ps1
        asserts exactly that (Sylvester's lens: "run a suite from the tree it is meant to judge"), and a
        false red there reads like a regression in the branch under test. Passing PowerShell's own location
        reproduces precisely what '& powershell -File' handed the child before.

        ONE CONSOLE, AND THAT IS SHARED STATE BETWEEN SUITES (inbound #821, August 21, 2026). -NoNewWindow
        means every child attaches to THIS console, so anything a suite does to the console rather than to
        itself is done to all of them. The measured case is [Console]::OutputEncoding, whose setter is
        SetConsoleOutputCP: one suite held it at UTF-8 for its whole run, and while that window was open
        every concurrently scheduled suite decoded native output as UTF-8 too. A second suite's accented-path
        assert was therefore GREEN under the gate and RED on its own, on the same commit -- and the bug it
        was correctly reporting (a git path decoded with the inherited code page) read as a test quirk for
        as long as nobody ran it alone. Reproduced deterministically by starting the two 1.2s apart.
        The rule that follows: a suite green under the gate and red standalone is reporting a real defect
        until proven otherwise, because the gate is the run with the shared state in it. Isolating the
        console per suite is possible (its own hidden console instead of -NoNewWindow) and is NOT done here:
        it changes how all 50 children are created, for a hazard whose one known instance is now scoped to
        a few lines inside the suite that needs it. Named rather than fixed, deliberately.

        Returns $true when every suite exited 0, $false when any did not, and $true with a warning when
        there is nothing to run -- an empty or missing directory is a repo without suites, not a failure.
    #>
    param(
        [Parameter(Mandatory)][string]$TestsDir,
        [string]$Context = 'the gate',
        # 0 = decide from the machine. 1 = run them one at a time, which is the valve for debugging a
        # suite that only fails with 25 siblings competing for the disk -- a real possibility this
        # function introduces, so it ships with the way to rule it out.
        [int]$MaxParallel = 0
    )

    # The repo's own extra test commands (inbound #644) -- read via Get-Command like every other optional
    # repo-config function, so a repo that defines nothing is untouched and a missing repo-config cannot
    # crash the gate.
    $extraCommands = @()
    if (Get-Command Get-TestCommands -ErrorAction SilentlyContinue) {
        $extraCommands = @(Get-TestCommands | ForEach-Object { "$_" } | Where-Object { $_.Trim() })
    }

    $suites = @()
    if (Test-Path -LiteralPath $TestsDir) {
        $suites = @(Get-ChildItem -Path $TestsDir -Filter '*.tests.ps1' -File | Sort-Object Name)
    }

    # A repo with neither suites nor commands is a repo without tests, not a failure -- but each empty
    # half stays quiet once the OTHER half has something to run: a consumer whose whole suite is
    # Get-TestCommands legitimately has no scripts\tests at all.
    if ($suites.Count -eq 0 -and $extraCommands.Count -eq 0) {
        if (-not (Test-Path -LiteralPath $TestsDir)) {
            Write-Warning "$TestsDir not found - test gate skipped."
        } else {
            Write-Warning "no *.tests.ps1 suites found in $TestsDir - test gate had nothing to run."
        }
        return $true
    }

    $launchDir  = (Get-Location).Path
    $sw         = [System.Diagnostics.Stopwatch]::StartNew()
    $failedNames = New-Object System.Collections.ArrayList

    if ($suites.Count -gt 0) {
        if ($MaxParallel -le 0) {
            # Two cores held back: the suites spawn children of their own, and a gate that saturates the
            # machine it runs on makes every other window on it unusable for two minutes. The floor is 2 and
            # not 1, because on a four-core machine that reservation would otherwise cost HALF the box and a
            # two-core one would fall back to the sequential loop this replaced -- and the suites spend most
            # of their time waiting on children rather than computing, so a little oversubscription is cheap.
            # A runner nobody is sitting at should pass its own core count instead; ci.yml does.
            $MaxParallel = [Math]::Max(2, [Environment]::ProcessorCount - 2)
        }
        if ($MaxParallel -gt $suites.Count) { $MaxParallel = $suites.Count }

        $modeLabel = if ($MaxParallel -eq 1) { 'one at a time' } else { "$MaxParallel at a time" }
        Write-Host "test gate: running all $($suites.Count) test suites for $Context ($modeLabel)..." -ForegroundColor Cyan

        $captureDir = Join-Path ([System.IO.Path]::GetTempPath()) ("test-suite-gate-$PID")

        try {
            if (Test-Path -LiteralPath $captureDir) { Remove-Item -Recurse -Force -LiteralPath $captureDir }
            New-Item -ItemType Directory -Path $captureDir -Force | Out-Null

            $queue = New-Object System.Collections.Queue
            foreach ($s in $suites) { $queue.Enqueue($s) | Out-Null }
            $running = New-Object System.Collections.ArrayList

            while ($queue.Count -gt 0 -or $running.Count -gt 0) {
                while ($queue.Count -gt 0 -and $running.Count -lt $MaxParallel) {
                    $suite   = $queue.Dequeue()
                    $outFile = Join-Path $captureDir ($suite.BaseName + '.out.txt')
                    $errFile = Join-Path $captureDir ($suite.BaseName + '.err.txt')
                    # The suite path is quoted: Start-Process joins ArgumentList on spaces, so an unquoted
                    # path under a folder with a space in it would arrive as two arguments.
                    $proc = Start-Process -FilePath 'powershell' `
                        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $suite.FullName + '"')) `
                        -WorkingDirectory $launchDir -NoNewWindow -PassThru `
                        -RedirectStandardOutput $outFile -RedirectStandardError $errFile
                    # READING .Handle IS NOT A NO-OP -- it is what makes .ExitCode readable later, and leaving
                    # it out is how this rewrite first shipped. Start-Process -PassThru hands back a Process
                    # object without retaining the OS handle, so once the child has exited .NET has nothing
                    # left to ask and .ExitCode comes back EMPTY. Empty is not 0: every suite was then judged
                    # 'FAILED (exit )', and the gate reported all of them failing while printing each one's
                    # green, passing output directly underneath. Same family as the rest of this file -- the
                    # wrong answer arrives as a plausible value instead of as an error.
                    $null = $proc.Handle
                    $running.Add([pscustomobject]@{
                        Name = $suite.Name; Process = $proc; OutFile = $outFile; ErrFile = $errFile
                    }) | Out-Null
                }

                $done = @($running | Where-Object { $_.Process.HasExited })
                if ($done.Count -eq 0) {
                    Start-Sleep -Milliseconds 100
                    continue
                }

                foreach ($d in $done) {
                    $d.Process.WaitForExit()          # settles ExitCode before it is read
                    $code = $d.Process.ExitCode
                    if ($code -eq 0) {
                        Write-Host "== $($d.Name) ==" -ForegroundColor Cyan
                    } else {
                        Write-Host "== $($d.Name) == FAILED (exit $code)" -ForegroundColor Red
                        $failedNames.Add($d.Name) | Out-Null
                    }
                    # -Encoding Oem matches what a redirected Windows PowerShell child writes (its
                    # [Console]::OutputEncoding is the OEM codepage). Everything in scope here is ASCII by
                    # repo convention, where every candidate decoder agrees; the choice only shows on a high
                    # byte that reached a suite's output from a document it was reading.
                    foreach ($f in @($d.OutFile, $d.ErrFile)) {
                        if (-not (Test-Path -LiteralPath $f)) { continue }
                        $text = Get-Content -LiteralPath $f -Raw -Encoding Oem
                        if ([string]::IsNullOrWhiteSpace($text)) { continue }
                        Write-Host $text.TrimEnd()
                    }
                    $running.Remove($d)
                }
            }
        } finally {
            if (Test-Path -LiteralPath $captureDir) {
                Remove-Item -Recurse -Force -LiteralPath $captureDir -ErrorAction SilentlyContinue
            }
        }
    }

    # The repo's own commands, sequentially and after the pool -- see the docstring for why they do not
    # join it. Same header-then-output shape as a suite, so a failure is attributable the same way.
    if ($extraCommands.Count -gt 0) {
        Write-Host "test gate: running $($extraCommands.Count) repo test command(s) from Get-TestCommands for $Context (one at a time)..." -ForegroundColor Cyan
        foreach ($cmd in $extraCommands) {
            # A command that does not PARSE is refused rather than run: an unterminated quote would
            # swallow the judging suffix below into its string literal, and the truncated statement's
            # own exit code (usually 0) would stand -- the wrong answer arriving as a plausible value,
            # this file's own failure family (see the .Handle comment above).
            $parseErrors = $null
            [void][System.Management.Automation.Language.Parser]::ParseInput($cmd, [ref]$null, [ref]$parseErrors)
            if ($parseErrors -and $parseErrors.Count -gt 0) {
                Write-Host "== $cmd == FAILED (does not parse: $($parseErrors[0].Message))" -ForegroundColor Red
                $failedNames.Add($cmd) | Out-Null
                continue
            }
            # A child powershell rather than in-process invocation: the command line stays an opaque
            # string ('npm test', a script call, anything) and its noise cannot trip this scope's EAP.
            # The judging suffix starts on its OWN LINE, so a trailing comment in the command cannot
            # absorb it, and it judges both halves a command can fail in: a native exit code where one
            # was set, and $? where none was -- a pure-PowerShell entry ending in a non-terminating
            # Write-Error sets no $LASTEXITCODE at all, and a bare 'exit $LASTEXITCODE' would have
            # coerced that to exit 0, a green gate over a red command.
            $judge = '$__gateOk = $?; if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; if (-not $__gateOk) { exit 1 }; exit 0'
            $r = Invoke-NativeCapture -FilePath 'powershell' -Arguments @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', ($cmd + "`n" + $judge))
            if ($r.ExitCode -eq 0) {
                Write-Host "== $cmd ==" -ForegroundColor Cyan
            } else {
                Write-Host "== $cmd == FAILED (exit $($r.ExitCode))" -ForegroundColor Red
                $failedNames.Add($cmd) | Out-Null
            }
            $cmdText = (@($r.Output | ForEach-Object { "$_" }) -join "`n")
            if (-not [string]::IsNullOrWhiteSpace($cmdText)) { Write-Host $cmdText.TrimEnd() }
        }
    }

    $sw.Stop()
    $total = $suites.Count + $extraCommands.Count

    # The verdict is printed here rather than left to the caller, because completion-order blocks bury it:
    # in a 27-suite weave the one red header is 2000 lines up. Sorted, so two runs name the same failures
    # in the same order. The elapsed line is deliberate too -- the whole point of this function's shape is
    # a number, and one it reports at every run cannot go stale in a document. The count includes the
    # Get-TestCommands entries: each is a suite of the repo's own stack, judged by the same exit-code rule.
    if ($failedNames.Count -eq 0) {
        Write-Host ("test gate: all {0} suites passed in {1:N0}s." -f $total, $sw.Elapsed.TotalSeconds) -ForegroundColor Green
        return $true
    }
    $namesInOrder = @($failedNames | Sort-Object) -join ', '
    Write-Host ("test gate: {0} of {1} suites FAILED in {2:N0}s: {3}" -f $failedNames.Count, $total, $sw.Elapsed.TotalSeconds, $namesInOrder) -ForegroundColor Red
    return $false
}
