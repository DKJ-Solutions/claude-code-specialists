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

    THE SECOND GUARD, AND WHY IT BELONGS HERE TOO: THE CHILD RUNS NON-INTERACTIVELY (inbound #1179,
    September 1, 2026). Every git and gh call the workflow scripts make comes through this one
    function, and not one of them runs anywhere a human can answer a prompt. Measured on
    DAVE-KOK-BWJ: a `git push -u origin <branch>` spawned `git credential-manager get`, that child
    opened a prompt nothing was listening to, and fifteen minutes later both were still running. The
    ship reported the hang as still shipping, and a lint + 13-suite gate that had already passed was
    thrown away with the kill.

    So Push-NativeNonInteractiveEnv brackets every child with GIT_TERMINAL_PROMPT=0 and
    GCM_INTERACTIVE=never. BOTH ARE NEEDED, AND THEY STOP DIFFERENT THINGS: GIT_TERMINAL_PROMPT is
    git's OWN terminal prompt and says nothing about a credential helper git hands off to -- the Git
    Credential Manager window is GCM's, and GCM_INTERACTIVE=never is what makes GCM fail instead of
    drawing it. Setting only the first leaves exactly the measured hang in place. Environment is the
    only scope a child inherits, so the set is process-wide, saved and restored in the same finally
    the EAP dance uses, and a variable that was ABSENT is restored to absent rather than to ''.

    It is applied to every child rather than only to git: gh shells out to git in places, and there
    is no call in this family for which an interactive credential prompt is ever the right answer.

    -TimeoutSeconds: BOUND THE WAIT, for a hang whose cause is NOT a credential prompt. The guard
    above closes the measured cause and cannot close the class -- the same report carries a second
    stall that no environment variable would have named. A bounded call kills the process TREE (see
    Stop-NativeProcessTree; the blocker was the child, not the parent), reports exit 124 and
    TimedOut = $true, and appends a line saying so to Output -- so a caller that already prints
    Output and judges ExitCode diagnoses the hang without changing a line.

    IT IS OPT-IN, AND THAT IS NOT TIMIDITY. `gh pr checks --watch` (ship-pr.ps1) blocks for as long
    as CI takes, by design; a default bound would turn the longest CORRECT call in the workflow into
    a failure. The bound belongs on the calls that reach the network and should answer in seconds --
    push, fetch -- and $NativeCaptureNetworkTimeoutSeconds is the shared number they pass.

    Usage:
        $r = Invoke-NativeCapture -FilePath 'git' -Arguments @('push', '-u', 'origin', $branch)
        $r.Output | ForEach-Object { Write-Host $_ }
        if ($r.ExitCode -ne 0) { Write-Error 'git push failed.'; exit 1 }

        # -DiscardStderr keeps stderr out of the captured output (e.g. so it cannot pollute JSON):
        $r = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'list', '--json', 'number') -DiscardStderr

        # -TimeoutSeconds bounds a call that reaches the network, so a stall fails loudly (#1179):
        $r = Invoke-NativeCapture -FilePath 'git' -Arguments @('push') -TimeoutSeconds $NativeCaptureNetworkTimeoutSeconds
        if ($r.TimedOut) { Write-Error 'git push never answered -- see the [timeout] line above.' }

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

$script:NativeCaptureInvariant = [System.Globalization.CultureInfo]::InvariantCulture

# THE NON-INTERACTIVE ENVIRONMENT every child is bracketed with (inbound #1179). See
# Invoke-NativeCapture's docstring for why both names are here and why neither is sufficient alone.
# A hashtable rather than two literals at the call site: the pair is one policy, and the next name
# that has to join it (an askpass, another helper's switch) belongs beside these two.
$script:NativeCaptureNonInteractiveEnv = @{
    GIT_TERMINAL_PROMPT = '0'
    GCM_INTERACTIVE     = 'never'
}

# THE BOUND A GIT NETWORK CALL PASSES, in one place so the three sites that reach the network -- the
# push in open-pr.ps1, the fetch in ship-pr.ps1, the fold's push in fold-changelog-entry.ps1 -- cannot
# drift apart. Read it as $NativeCaptureNetworkTimeoutSeconds from a script that dot-sources this lib:
# dot-sourcing runs the file in the CALLER's script scope, which is what makes $script: here readable
# there. Two minutes is roughly twenty times the slowest honest push measured in this repo, and a
# fraction of the fifteen minutes the reported hang sat for -- generous enough that a slow network is
# not mistaken for a stall, short enough that a stall is reported inside one attention span.
$script:NativeCaptureNetworkTimeoutSeconds = 120

# 124 is `timeout(1)`'s conventional "the command timed out" code, borrowed rather than invented so a
# reader who greps it lands on an answer. Neither git nor gh uses it, so it cannot be confused with a
# real verdict -- but a caller who needs certainty reads TimedOut instead of the number.
$script:NativeCaptureTimeoutExitCode = 124

function Format-GateSeconds {
    <#
        The elapsed-seconds figure Invoke-TestSuiteGate prints, FORMATTED INVARIANTLY -- and that is not
        a style choice (issue #1159). PowerShell's '-f' formats in the current culture: on a Dutch
        machine '{0:N0}' renders 2182 as '2.182', which an English reader of this repo reads as 2.182
        seconds -- off by a factor of a thousand and still plausible. It only misformats above 1000s,
        which is exactly the runs worth noticing, so nothing looked wrong until a slow run produced one.
        Same reasoning measure-skill-lib.ps1's Format-* helpers state at length: a figure must not
        depend on the machine that printed it. Repo content is English (CLAUDE.md, Language), and a
        number whose meaning depends on regional settings is the same defect as an untranslated string.
    #>
    param(
        [Parameter(Mandatory = $true)][double]$Seconds,
        # WHOLE SECONDS BY DEFAULT, and the default is what every caller before #1358 gets -- a test
        # asserts that 0.4 renders as '0'. The per-suite table added by that issue is the one caller that
        # needs a decimal: most suites in this pool finish under a second, and a column of '0s' rows
        # records nothing. Still routed through the invariant culture, because that is the whole point of
        # this function and a second format string is a second chance to lose it.
        [int]$Decimals = 0
    )
    return [string]::Format($script:NativeCaptureInvariant, ('{0:N' + $Decimals + '}'), $Seconds)
}

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

function Push-NativeNonInteractiveEnv {
    <#
        Set the non-interactive environment for the child about to be started and hand back what was
        there before, for the finally to put back. Internal to this lib (no export, no contract row).

        [Environment]::SetEnvironmentVariable rather than $env:NAME = ... for ONE reason that matters:
        it can write $null, which REMOVES the variable. `$env:NAME = $null` in Windows PowerShell 5.1
        leaves an empty-string variable behind, and empty is not absent -- git reads a defined
        GIT_TERMINAL_PROMPT='' differently from an undefined one, so restoring with the assignment
        form would leave every script that ran a single git call in a state it did not start in.

        The previous value is captured BEFORE the set, per name, so a caller that deliberately set one
        of these itself (a test, a consumer's wrapper) gets its own value back rather than ours.
    #>
    $previous = @{}
    foreach ($name in @($script:NativeCaptureNonInteractiveEnv.Keys)) {
        $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $script:NativeCaptureNonInteractiveEnv[$name], 'Process')
    }
    return $previous
}

function Pop-NativeNonInteractiveEnv {
    <#
        Put back what Push-NativeNonInteractiveEnv handed over. Internal to this lib.

        Runs from a finally, so it must not throw whatever it is given: a $null (the push never ran
        because Start-Process threw first) is a no-op rather than an error, because an exception raised
        HERE would replace the one the caller is actually trying to report.
    #>
    param([AllowNull()][hashtable]$Previous)

    if (-not $Previous) { return }
    foreach ($name in @($Previous.Keys)) {
        [Environment]::SetEnvironmentVariable($name, $Previous[$name], 'Process')
    }
}

function Stop-NativeProcessTree {
    <#
        Kill a timed-out child AND ITS CHILDREN. Internal to this lib.

        /T IS THE ENTIRE POINT, and it is what the measurement in #1179 argues for: the process that
        blocked was not the `git.exe push` (PID 11372) but the `git credential-manager get` it spawned
        (PID 27176), and killing only the parent leaves that one holding the prompt. taskkill is the
        one tool on Windows that walks the tree; Stop-Process signals a single process.

        BOTH ATTEMPTS ARE ALLOWED TO FAIL, and that is deliberate rather than sloppy. taskkill reports
        "not found" for a child that exited in the gap between the wait giving up and this call, and it
        can be refused for a process this session may not signal. By the time we are here the wait has
        already stopped waiting, so a failed kill costs a stray process rather than a wrong answer --
        whereas a throw would replace a diagnosable timeout with an unrelated error.

        taskkill writes to stderr, so its call is bracketed with EAP=Continue for the #96/#107 reason
        this whole lib exists for. The -Utf8 arm that calls this does NOT set EAP itself (it has no &
        call to protect), so the caller's 'Stop' would otherwise be live right here.
    #>
    param([Parameter(Mandatory = $true)][int]$ProcessId)

    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & taskkill.exe '/PID' "$ProcessId" '/T' '/F' 2>&1 | Out-Null
    } catch {
        # Deliberately swallowed -- see the docstring.
    } finally {
        $ErrorActionPreference = $prevEap
    }

    Get-Process -Id $ProcessId -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
}

function Invoke-NativeCapture {
    <#
        Run $FilePath with $Arguments under $ErrorActionPreference = 'Continue' and return a
        pscustomobject with:
          - Output   : the command's output. By default stderr is merged in (2>&1) so a caller can
                       echo full progress; with -DiscardStderr stderr is dropped (2>$null) so it
                       cannot pollute a machine-readable stdout (e.g. gh --json).
          - ExitCode : $LASTEXITCODE recorded immediately after the command ran.
          - TimedOut : $true only when -TimeoutSeconds was given AND expired. Present on every return
                       from both arms, so a caller never has to know which arm answered it.
        EAP and the environment are always restored (finally), whether the command succeeds, fails, or
        throws.

        -DiscardStderr IS NOT A CREDENTIAL GUARD, AND THAT WAS MEASURED (issue #1313). The reason to
        pass it is the one above: stderr merged into output a caller then PARSES. It is tempting to
        reach for it as a security flag as well -- a git call that talks to the remote writes all of
        its output to stderr, and its failure line quotes the remote URL -- but git redacts that URL
        itself. Measured on git 2.55.0.windows.5: `user:token@host`, `token@host` and an unresolvable
        host all came back as a bare `https://host/o/r.git`, because the "unable to access" and
        "Authentication failed" messages go through transport_anonymize_url, which strips userinfo. A
        token somewhere ELSE in the URL (a query string, a path segment) is printed verbatim -- also
        measured -- but that is not a shape any remote of this family uses.

        SO THE TRADE RUNS THE OTHER WAY on a network call, and #1313 is the worked example: it proposed
        the flag for the `git fetch` in ship-pr.ps1's fold step, in worktree-lane.ps1 and in
        prune-merged.ps1, and applying it would have removed git's own diagnosis from three failure
        paths -- one of them the step where the PR is ALREADY MERGED and git's reason is all a reader
        has -- in exchange for nothing. Declined on that measurement, and the same measurement is why
        Invoke-GitPark's `git push` keeps stderr on purpose (#1143): git's words there are the answer.

        WHERE A CREDENTIAL REALLY DOES REACH A LOG is where WE compose the line rather than git. A URL
        an operator handed us, interpolated into our own Write-Host or our own throw message, gets no
        redaction from anybody -- that was the standing half of #1313, in publish-to-business.ps1, and
        the fix there is to mask the userinfo before printing (Format-UrlForDisplay), not to drop
        stderr. If you are about to print a URL, mask it; if you are about to hide git's output, ask
        what the reader is left with.

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
        [switch]$Utf8,
        [int]$TimeoutSeconds = 0
    )

    # A BOUND IMPLIES THE Start-Process ARM, because the & operator cannot be interrupted: it hands
    # control to PowerShell's own pipeline reader until the child exits, and there is no handle to wait
    # on with a deadline. The -Utf8 arm already starts the child with -PassThru, which is exactly the
    # handle a bounded wait needs -- so -TimeoutSeconds routes there whether or not -Utf8 was asked for.
    # THE CONSEQUENCE IS REAL AND WORTH KNOWING: a bounded call therefore also gets that arm's UTF-8
    # decode and its line-array Output. For the push and fetch progress the bound is applied to, that is
    # cosmetic-to-better; for a caller that PARSES the output it is a change of shape, which is why
    # -TimeoutSeconds is opt-in per call site rather than a default.
    if ($Utf8 -or $TimeoutSeconds -gt 0) {
        return Invoke-NativeCaptureUtf8 -FilePath $FilePath -Arguments $Arguments `
                                        -DiscardStderr:$DiscardStderr -TimeoutSeconds $TimeoutSeconds
    }

    $prevEap = $ErrorActionPreference
    $prevEnv = $null
    try {
        $ErrorActionPreference = 'Continue'
        $prevEnv = Push-NativeNonInteractiveEnv
        if ($DiscardStderr) {
            $output = & $FilePath @Arguments 2>$null
        } else {
            $output = & $FilePath @Arguments 2>&1
        }
        $code = $LASTEXITCODE
    } finally {
        Pop-NativeNonInteractiveEnv -Previous $prevEnv
        $ErrorActionPreference = $prevEap
    }

    return [pscustomobject]@{ Output = $output; ExitCode = $code; TimedOut = $false }
}

function Read-NativeCaptureFileText {
    <#
        Read a capture file as text with the given encoding, TOLERATING A WRITE HANDLE STILL OPEN ON
        IT. Internal to this lib; the -Utf8/timeout arm below is the only caller.

        WHY THIS EXISTS (issue #1252). On a timeout, Invoke-NativeCaptureUtf8 force-kills the child's
        whole process tree with taskkill /T and then waits on the DIRECT child only. A grandchild that
        inherited the redirected stdout handle keeps out.txt open until IT is reaped too, and the gap
        between the kill and that moment is wall-clock -- invisible on a fast machine, a lost race on a
        CI runner several times slower. [System.IO.File]::ReadAllText opens the file with
        FileShare.Read, which cannot coexist with the writer handle still held, so it throws
        "The process cannot access the file ... because it is being used by another process." -- and
        the exception replaces a diagnosable timeout with an unrelated IO error, on a branch whose diff
        never touched this code.

        FileShare.ReadWrite coexists with that lingering handle and returns whatever was flushed. For a
        process tree that was just killed, a possibly-truncated tail is the honest answer -- the same
        judgement Stop-NativeProcessTree already makes when it lets its own kill attempts fail. Used
        for BOTH reads, not only the timeout path: a grandchild can outlive a clean exit too, and a
        shared read costs the normal case nothing.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][System.Text.Encoding]$Encoding
    )

    $stream = New-Object System.IO.FileStream(
        $Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $reader = New-Object System.IO.StreamReader($stream, $Encoding)
        try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
    } finally {
        $stream.Dispose()
    }
}

function Invoke-NativeCaptureUtf8 {
    <#
        The -Utf8 arm of Invoke-NativeCapture; see that function's docstring for WHY. Split out rather
        than nested in an if/else because the two share no lines: different launcher, different
        capture, different decode. Callers pass -Utf8 instead of naming this -- and since #1179 they
        also arrive here by passing -TimeoutSeconds, because the bounded wait needs the -PassThru
        handle only this arm has. So the arm is no longer "the UTF-8 one": it is the Start-Process one,
        and UTF-8 decoding is one of the two things that follows from that.

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
        [switch]$DiscardStderr,
        [int]$TimeoutSeconds = 0
    )

    $capDir  = Join-Path ([System.IO.Path]::GetTempPath()) ("native-capture-$PID-" + [guid]::NewGuid().ToString('n'))
    $outFile = Join-Path $capDir 'out.txt'
    $errFile = Join-Path $capDir 'err.txt'

    $prevEnv = $null
    try {
        New-Item -ItemType Directory -Path $capDir -Force | Out-Null

        # Before Start-Process, because a child inherits its environment at CREATION -- setting these
        # after the process exists would guard nothing. Restored in the finally below.
        $prevEnv = Push-NativeNonInteractiveEnv

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

        # THE BOUNDED WAIT (#1179). WaitForExit(ms) returns $false when the deadline passed rather than
        # throwing, so the timeout is a verdict to report and not an exception to catch. The second,
        # short wait after the kill is not belt-and-braces: the capture files are still open handles
        # until the child is actually reaped, and reading them before that returns a truncated document
        # -- which would drop the very git output a reader needs to see WHY it stalled. That wait is on
        # the DIRECT child only, though, so a killed grandchild can still hold out.txt when the read
        # runs -- see Read-NativeCaptureFileText below (#1252) for why the read tolerates that rather
        # than waiting longer.
        $timedOut = $false
        if ($TimeoutSeconds -gt 0) {
            if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
                $timedOut = $true
                Stop-NativeProcessTree -ProcessId $proc.Id
                $null = $proc.WaitForExit(5000)
            }
        } else {
            $proc.WaitForExit()
        }

        # A KILLED CHILD HAS AN EXIT CODE OF ITS OWN and it is a misleading one -- taskkill /F leaves 1
        # or 0x40010004 behind, which reads as an ordinary git failure. The timeout code is substituted
        # so the number and TimedOut tell the same story.
        $code = if ($timedOut) { $script:NativeCaptureTimeoutExitCode } else { $proc.ExitCode }

        # No BOM on the decoder: a BOM-emitting child is not something gh or git does, and
        # UTF8Encoding($false) still strips one if it is there.
        $utf8 = New-Object System.Text.UTF8Encoding $false
        $text = ''
        if (Test-Path -LiteralPath $outFile) { $text = Read-NativeCaptureFileText -Path $outFile -Encoding $utf8 }
        if (-not $DiscardStderr -and (Test-Path -LiteralPath $errFile)) {
            $text += Read-NativeCaptureFileText -Path $errFile -Encoding $utf8
        }

        # Lines, to match what the & path hands back. A single trailing newline is the terminator of
        # the last line rather than an empty line after it, so it is dropped; anything else is content.
        $lines = @()
        if ($text.Length -gt 0) {
            $text = $text -replace "`r`n", "`n"
            if ($text.EndsWith("`n")) { $text = $text.Substring(0, $text.Length - 1) }
            $lines = @($text -split "`n")
        }

        # THE DIAGNOSIS GOES IN Output, not only in the exit code, because that is where every existing
        # caller already looks: they pipe Output to Write-Host and then judge ExitCode. Appending the
        # line means the three bounded sites report a stall in full without one of them changing a line
        # -- and it names the command, so a reader who only has the console scrollback still knows which
        # call it was. It goes AFTER git's own output rather than before: what git managed to say before
        # it stalled is the evidence, and this is the verdict on it.
        if ($timedOut) {
            $lines = @($lines) + @(
                "[timeout] '$FilePath' did not finish within $TimeoutSeconds seconds; its process tree was killed (reported as exit $($script:NativeCaptureTimeoutExitCode)).",
                "[timeout] A git network call that stalls this way is usually a credential helper waiting on a prompt nothing can answer (inbound #1179). Check 'git config --get-all credential.helper' and that the credential for this remote is still valid."
            )
        }

        return [pscustomobject]@{ Output = $lines; ExitCode = $code; TimedOut = $timedOut }
    } finally {
        Pop-NativeNonInteractiveEnv -Previous $prevEnv
        if (Test-Path -LiteralPath $capDir) {
            Remove-Item -Recurse -Force -LiteralPath $capDir -ErrorAction SilentlyContinue
        }
    }
}

function Get-GitFileTextAtRef {
    <#
        The text of ONE file as a given git ref has it -- the commit's blob, not the working copy -- or
        $null when that ref does not carry the path at all.

        WHY THIS EXISTS AT ALL (issue #970, August 27, 2026). A gate that runs before a merge has to judge
        the document the MERGE will merge, and the working tree is not that document: ship-pr.ps1 waits on
        CI -- 10m57s on the run that produced the report -- and a session that backgrounds the ship and
        starts the next piece of work has moved the checkout while it waits. Reading a commit instead of a
        checkout is the whole repair, and it is one call so that every caller makes the same three decisions
        the same way.

        DECISION ONE: -Utf8, AND IT IS LOAD-BEARING. git's stdout here is DATA rather than progress, and
        5.1 decodes a native child with [Console]::OutputEncoding -- so on cp850 an em dash in the document
        arrives as three characters, and the DEPLOY lock then compares that against a PR body read with an
        explicit UTF-8 decode. See Invoke-NativeCapture's docstring for the measurement, and
        .claude/rules/language-layers.md for the rule.

        DECISION TWO: -DiscardStderr, so git's own 'fatal: path ... does not exist' line can never arrive
        INSIDE the returned document. A missing path is signalled by $null, which is what the exit code
        already said; a caller must never have to recognise it in the text.

        DECISION THREE: ABSENT AND EMPTY ARE DIFFERENT ANSWERS. A ref that has the path but holds an empty
        file returns '', which is falsy in PowerShell -- so every caller tests $null explicitly. A gate that
        conflates them treats a file it could not find as a file with nothing in it, which is exactly the
        silence this repair exists to remove.

        -Path takes repo-relative FORWARD slashes, which is what Get-BranchFilePaths hands out; a
        backslash path is converted rather than refused, because Join-Path output is the likeliest input.
        -RepoRoot is optional and becomes `git -C`, so a caller does not have to Set-Location first.

        The ref is passed as given. Prefer a full 'refs/heads/<branch>' over a bare branch name: `git show`
        resolves its left half as a rev, and a name that also names a directory is otherwise ambiguous.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Ref,
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$RepoRoot
    )

    $rel = $Path -replace '\\', '/'
    $gitArgs = @()
    if ($RepoRoot) { $gitArgs += @('-C', $RepoRoot) }
    $gitArgs += @('show', "${Ref}:${rel}")

    $show = Invoke-NativeCapture -Utf8 -DiscardStderr -FilePath 'git' -Arguments $gitArgs
    if ($show.ExitCode -ne 0) { return $null }
    # Lines back to one string: the -Utf8 arm hands back an array and drops the single trailing newline.
    # Every reader of this document splits on newlines again, so the terminator is not reconstructed.
    return ((@($show.Output) | ForEach-Object { "$_" }) -join "`n")
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

        AND THE CONVERSE, MEASURED (issue #1033, August 28, 2026). The rule above reads in one direction
        only, and the commoner event is the other one: a suite RED under the gate and GREEN standalone. A
        re-run during the v4.22.0 cut reported 11 of 54 suites failed in 626s, every one with the same
        shape -- a child that exited 1, then every downstream assert about what that child should have
        written -- on a tree the cut itself had just passed 54/54 on. The report inferred that the verdict
        depended on WHO CALLED the gate, because the red run came from a session that had dot-sourced this
        lib and repo-config while the green one came from cut-release.ps1. IT DOES NOT: cut-release
        dot-sources exactly those two libs before calling this function, so both runs had identical state,
        and the axis the report names cannot be the difference. Five full runs on that same tree were all
        54/54 green -- 16 lanes 194s, 18 lanes 216s, 18 lanes with the console at UTF-8 203s, and two
        18-lane runs side by side 421s and 419s. That last pair is the number to keep: 2x load reproduces
        the release's own 443s "green" wall clock to within 5%, which makes 443s a reading of the MACHINE
        rather than a cost of this gate, whose cost on that tree was ~200s.

        SO A RED HERE IS EVIDENCE ABOUT THE RUN BEFORE IT IS EVIDENCE ABOUT THE TREE, and the standing
        response is re-running the suite alone -- which is already written down twice, from two earlier
        sightings of these same suites: the Start-Job fan-out of August 12, 2026 (6 of 31, all green
        alone) and the two reds in the post-split pool of August 16 (bootstrap-drift and fix-mojibake,
        both green alone, not diagnosed). What cost 22 minutes of that release was not the flake; it was
        that neither page was reached before the chase started. NOT REPAIRED HERE, deliberately and for
        the same reason the console is not isolated above: three sightings and no reproduction is a
        hazard to name, not yet a mechanism to fix.

        SHARDING: -Shard/-ShardCount RUN ONE SLICE OF THE POOL (issue #1351, September 3, 2026). The
        paragraph above says the lever is the slowest FILE and that splitting one is available where
        narrowing it is not. That was the answer while the gate had lanes to spare. It does not hold on a
        hosted runner, which is where the number that actually blocks a merge is produced: measured on run
        33798952362, `lint-en-tests` spent 12m23s of its 13m03s in this function -- 'all 64 suites passed
        in 742s (4 lanes)' -- against ~200s for the same pool on 16-18 lanes on a workstation. In
        lane-seconds that is 2968 against ~3400: comparable total work, so the 3.7x is LANE COUNT, and
        `windows-latest` has four cores. The gate was not critical-path-bound there (the #714 regime, where
        its total equalled one file to a tenth of a second) but contention-bound, which is the one regime
        where adding lanes is close to linear -- and the only way to add lanes to a four-core runner is to
        use more than one runner.
        So the caller may now ask for a quarter of the pool and run four of itself. ci.yml does; every
        other caller passes neither parameter and gets the whole pool, unchanged, down to the wording of
        its summary line.
        WHY THE FUNCTION PARTITIONS RATHER THAN THE CALLER -- and why a STRIDE: both at the partition
        itself, below the suite glob. WHY THIS DOES NOT PAY #714's BILL TWICE: the four
        check-plugin-integrity suites build a fixture EACH, in a per-process directory (that file's own
        header says so), so scattering them across shards duplicates no shared setup -- verified before
        this was written, because a shared builder would have made a stride the worst possible split.
        WHAT SHARDING CANNOT SLICE is Get-TestCommands, handled at its own comment below.
        THE HAZARD IT REMOVES INCIDENTALLY: suites in different shards no longer share a console, so the
        SetConsoleOutputCP class of cross-talk (inbound #821) cannot reach across a shard boundary. The
        rule above still holds WITHIN one.
        AND THE HAZARD IT ADDS: the fail-closed summary. Four green shards prove nothing unless something
        refuses when one of them did not report -- a workflow-level concern, so it lives in ci.yml's own
        banner rather than here, and it is the reason this function throws on a nonsensical (Shard,
        ShardCount) instead of quietly selecting nothing.

        PER-SUITE DURATIONS ARE RECORDED, NOT RECONSTRUCTED (issue #1358). Before that this function timed
        only the pool, and because it buffers a suite's output until that suite exits, the only per-suite
        signal a log carried was a FINISH time. Subtracting the pool's start from it is a duration only for
        a suite that started at t0 -- one of the first -MaxParallel dequeued -- and nothing in the
        arithmetic says so. It cost a five-file plateau that had four members: the method was applied
        correctly to the four suites in the opening lanes and then extended to two sitting 5th and 9th in a
        4-lane queue, reading their lane wait as runtime. The table printed after the pool now carries each
        suite's duration AND the offset at which its lane opened, slowest first, and marks the one that set
        the makespan -- the only suite whose shortening moves the total, which is #714's finding and the
        thing every wall-clock question about this pool starts from.

        Returns $true when every suite exited 0, $false when any did not, and $true with a warning when
        there is nothing to run -- an empty or missing directory is a repo without suites, not a failure,
        and neither is a shard that drew none of them.
    #>
    param(
        [Parameter(Mandatory)][string]$TestsDir,
        [string]$Context = 'the gate',
        # 0 = decide from the machine. 1 = run them one at a time, which is the valve for debugging a
        # suite that only fails with 25 siblings competing for the disk -- a real possibility this
        # function introduces, so it ships with the way to rule it out.
        [int]$MaxParallel = 0,
        # WHICH SLICE OF THE POOL TO RUN, 1-based; 0 (both) = the whole pool, which is the unchanged
        # behaviour every existing caller gets. See the SHARDING banner in the docstring for why the
        # partition is computed HERE from two integers rather than taken as a list of suite names.
        [int]$Shard = 0,
        [int]$ShardCount = 0
    )

    # BOTH OR NEITHER, AND IN RANGE -- REFUSED RATHER THAN INTERPRETED. Every wrong combination here has
    # a plausible-looking silent reading, which is this file's own documented failure family (see the
    # .Handle comment further down): -Shard 3 with no -ShardCount could defensibly mean "the whole pool",
    # and -Shard 5 -ShardCount 4 selects nothing and would report a green gate over zero suites. A gate
    # that silently ran none of its suites is exactly the shape of #1294's dropped runs -- green, and
    # measuring nothing -- so this is the one input this function will not guess at. It throws rather
    # than returning $false: a caller that passed nonsense has a bug, and a red gate would send its
    # operator looking at the suites instead.
    if (($Shard -gt 0) -ne ($ShardCount -gt 0)) {
        throw "Invoke-TestSuiteGate: -Shard and -ShardCount go together -- got Shard=$Shard, ShardCount=$ShardCount."
    }
    if ($ShardCount -gt 0 -and ($Shard -lt 1 -or $Shard -gt $ShardCount)) {
        throw "Invoke-TestSuiteGate: -Shard must be between 1 and -ShardCount ($ShardCount) -- got $Shard."
    }

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
    $poolTotal = $suites.Count

    # THE PARTITION IS A STRIDE, NOT A CONTIGUOUS BLOCK, and that is the whole design (issue #1351).
    # Taking suites 1-16 for shard 1, 17-32 for shard 2 and so on would pile correlated work into one
    # shard: the heavy suites in this repo are heavy because they share a subject, and suites that share
    # a subject share a NAME PREFIX and therefore sort adjacently. The four check-plugin-integrity-*
    # suites are the measured case -- they are the pool's four most expensive files (#714 split them out
    # of one ~160s file precisely because the gate parallelises per file), they are alphabetically
    # consecutive, and a contiguous split puts all four in the same shard while another shard runs
    # sixteen cheap ones. A stride puts them in four different shards, which is the balance this change
    # exists to buy, WITHOUT this function having to know or store what anything costs. Verified on this
    # repo's own 64-suite pool: 16/16/16/16, one heavy suite each.
    #
    # SORT ORDER IS THE CONTRACT. The stride is taken over the Sort-Object Name list above, so a given
    # (Shard, ShardCount) always selects the same files -- a shard that goes red is re-runnable by hand
    # with the same two integers. Adding a suite reshuffles the assignment, which is fine: nothing
    # persists an assignment between runs, and every suite is independent by construction.
    #
    # WHY NOT A LIST OF SUITE NAMES FROM THE CALLER. That is the shape the workflow would have to keep
    # in sync with the directory, and this repo has measured what happens to a second copy of a list
    # nobody looks at (#512's inline gate copy, which would have kept running the suites one at a time
    # for days after both local callers were parallelised). Two integers cannot drift from the contents
    # of a folder.
    if ($ShardCount -gt 1 -and $suites.Count -gt 0) {
        $suites = @($suites | ForEach-Object -Begin { $i = 0 } -Process {
            if (($i % $ShardCount) -eq ($Shard - 1)) { $_ }
            $i++
        })
    }

    # Get-TestCommands BELONGS TO ONE SHARD, NOT TO EVERY SHARD (issue #1351). These are the repo's own
    # whole-stack commands -- 'npm test' and its kind -- and they are not a per-file pool this function
    # can slice: running them in all four shards runs the consumer's entire test suite four times, for
    # four times the wall clock this change exists to reduce, and any of them that writes outside its own
    # process (a coverage file, a build artefact, a fixture database) would then have three concurrent
    # writers. Shard 1 carries them. That leaves shard 1 the longest, which is the correct place for a
    # cost that cannot be divided: it is bounded by the commands' own runtime either way, and the pool
    # keeps flowing around it.
    if ($ShardCount -gt 1 -and $Shard -ne 1 -and $extraCommands.Count -gt 0) {
        Write-Host "test gate: $($extraCommands.Count) repo test command(s) run in shard 1 -- not repeated here." -ForegroundColor DarkGray
        $extraCommands = @()
    }

    # A repo with neither suites nor commands is a repo without tests, not a failure -- but each empty
    # half stays quiet once the OTHER half has something to run: a consumer whose whole suite is
    # Get-TestCommands legitimately has no scripts\tests at all.
    #
    # AND UNDER SHARDING AN EMPTY SLICE IS A THIRD THING, which neither warning below describes: more
    # shards than suites is a workflow configured wider than the pool, not a repo without tests, and
    # saying "no suites found in scripts\tests" of a directory holding sixty of them sends the reader
    # to the wrong place. Still green -- there is genuinely nothing for THIS shard to run, and the
    # summary job's fail-closed check is what makes an entire pool of empty shards impossible to
    # mistake for a pass.
    if ($suites.Count -eq 0 -and $extraCommands.Count -eq 0) {
        if (-not (Test-Path -LiteralPath $TestsDir)) {
            Write-Warning "$TestsDir not found - test gate skipped."
        } elseif ($ShardCount -gt 1 -and $poolTotal -gt 0) {
            Write-Warning "shard $Shard of $ShardCount got none of the $poolTotal suites in $TestsDir - more shards than suites."
        } else {
            Write-Warning "no *.tests.ps1 suites found in $TestsDir - test gate had nothing to run."
        }
        return $true
    }

    $launchDir  = (Get-Location).Path
    $sw         = [System.Diagnostics.Stopwatch]::StartNew()
    $failedNames = New-Object System.Collections.ArrayList
    # PER-SUITE DURATIONS, RECORDED RATHER THAN RECONSTRUCTED -- issue #1358. This function used to time
    # only the whole pool, and it buffers each suite's output until that suite exits, so the ONLY per-suite
    # signal in a log was the timestamp of a completed suite's first line: a FINISH time. Subtracting the
    # pool's start from it gives a duration only for a suite that started at t0, i.e. one of the first
    # $MaxParallel to be dequeued -- and that assumption is invisible in the arithmetic. Measured cost of
    # leaving it implicit: a five-file plateau reported off this pool had four members, because the method
    # was applied correctly to the suites in the opening lanes and then extended to two that were 5th and
    # 9th in a 4-lane queue, reading their lane wait as runtime.
    #
    # BOTH NUMBERS ARE KEPT, and the start offset is the one that was missing. A duration alone still
    # cannot be checked against the pool's makespan by a reader who does not know when the suite began, and
    # the offset is what makes 'this suite waited for a lane' visible instead of inferable.
    $suiteTimings = New-Object System.Collections.ArrayList

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
        # 'all N' IS A CLAIM, AND UNDER SHARDING IT IS A FALSE ONE. This line and the verdict at the foot
        # of the function are the two a session copies into a branch document or a commit message, so a
        # sliced run has to say so on both -- otherwise 'all 16 test suites' is on the record for a pool
        # of 64, which reads as 48 suites having been deleted rather than as one shard of four.
        $scopeLabel = if ($ShardCount -gt 1) { "shard $Shard/$ShardCount -- $($suites.Count) of $poolTotal" } else { "all $($suites.Count)" }
        Write-Host "test gate: running $scopeLabel test suites for $Context ($modeLabel)..." -ForegroundColor Cyan

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
                        # WHEN THIS LANE OPENED, off the gate's own stopwatch -- see $suiteTimings for why
                        # the offset is recorded and not just the duration (issue #1358).
                        StartOffset = $sw.Elapsed.TotalSeconds
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
                    # RECORDED HERE, WHERE BOTH ENDS ARE KNOWN. Reaping is the only moment this loop holds
                    # a suite's start and its finish at once; after $running.Remove the start offset is gone.
                    $suiteTimings.Add([pscustomobject]@{
                        Name        = $d.Name
                        StartOffset = $d.StartOffset
                        Duration    = ($sw.Elapsed.TotalSeconds - $d.StartOffset)
                        Failed      = ($code -ne 0)
                    }) | Out-Null
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

    # THE PER-SUITE TABLE, slowest first -- issue #1358. Printed before the verdict so the verdict stays
    # the last line a session copies, and only when there is a pool to describe.
    #
    # WHY SLOWEST FIRST RATHER THAN COMPLETION ORDER: the whole reason to have this is to find the file
    # that sets the shard's wall clock, and #714's finding is that a shard costs its slowest FILE. The
    # blocks above are already in completion order, so ordering by cost adds the view the log did not have.
    #
    # THE MAKESPAN MARKER IS THE ACTIONABLE BIT. A suite is marked '<-- set the makespan' when it finished
    # last, because that is the only suite whose shortening moves this pool's total -- everything else has
    # slack behind it. That is the claim #714 proved and #1354 re-proved, and printing it stops the next
    # reader deriving it from timestamps.
    if ($suiteTimings.Count -gt 0) {
        $lastFinish = ($suiteTimings | ForEach-Object { $_.StartOffset + $_.Duration } | Measure-Object -Maximum).Maximum
        $nameWidth = ($suiteTimings | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
        Write-Host ''
        Write-Host "test gate: per-suite durations, slowest first (recorded, not reconstructed -- #1358)" -ForegroundColor Cyan
        Write-Host "  'started' is when a LANE OPENED, not when the suite was queued: a late start is lane wait, not runtime." -ForegroundColor DarkGray
        foreach ($t in ($suiteTimings | Sort-Object -Property Duration -Descending)) {
            $finish = $t.StartOffset + $t.Duration
            # Within a tick of the pool's end, so a rounding difference does not hide the marker.
            $marker = if ([Math]::Abs($finish - $lastFinish) -lt 0.05) { '  <-- set the makespan' } else { '' }
            $flag   = if ($t.Failed) { ' FAILED' } else { '' }
            Write-Host ("  {0,8}s  {1,-$nameWidth}  started +{2}s{3}{4}" -f `
                (Format-GateSeconds $t.Duration -Decimals 1), $t.Name,
                (Format-GateSeconds $t.StartOffset -Decimals 1), $flag, $marker) `
                -ForegroundColor $(if ($t.Failed) { 'Red' } else { 'Gray' })
        }
        Write-Host ''
    }

    # The verdict is printed here rather than left to the caller, because completion-order blocks bury it:
    # in a 27-suite weave the one red header is 2000 lines up. Sorted, so two runs name the same failures
    # in the same order. The elapsed line is deliberate too -- the whole point of this function's shape is
    # a number, and one it reports at every run cannot go stale in a document. The count includes the
    # Get-TestCommands entries: each is a suite of the repo's own stack, judged by the same exit-code rule.
    $elapsed = Format-GateSeconds $sw.Elapsed.TotalSeconds
    # THE LANE COUNT RIDES THE SAME LINE AS THE SECONDS, green and red (issue #1318, the #1314 defect one
    # step upstream). This summary line is the one a session copies into a branch document, a changelog
    # entry or a commit message -- and the seconds on their own are a draw from a distribution that spans
    # at least 4.5x, because the run's parallelism is not stated. $modeLabel already put the lanes on the
    # opening line at :674, which nobody quotes; this carries the same number to the line everybody does,
    # and the workflow's DEPLOY-section rule asks a quoted gate figure to name what produced it. Only when the pool
    # actually ran: a commands-only gate never resolves $MaxParallel and runs its commands one at a time,
    # so there is no lane count to state. The MACHINE is deliberately left off -- CI passes
    # -MaxParallel ([Environment]::ProcessorCount) while a dev box takes ([Environment]::ProcessorCount - 2),
    # so the lane number already tells a hosted runner from a workstation without naming either.
    $laneNote = ''
    if ($suites.Count -gt 0) {
        $laneWord = if ($MaxParallel -eq 1) { 'lane' } else { 'lanes' }
        $laneNote = " ($MaxParallel $laneWord)"
    }
    # THE SHARD RIDES THE SAME LINE, for the reason #1318 put the lane count here: this is the line that
    # gets quoted, and a figure quoted without its scope is unreadable later. '742s (4 lanes)' and
    # '186s (4 lanes)' say nothing about each other unless the second one also says it ran a quarter of
    # the pool -- and the whole argument of #1351 is a comparison between those two numbers.
    $shardNote = if ($ShardCount -gt 1) { " [shard $Shard/$ShardCount]" } else { '' }
    if ($failedNames.Count -eq 0) {
        $passScope = if ($ShardCount -gt 1) { "{0} of $poolTotal" } else { 'all {0}' }
        Write-Host ("test gate: $passScope suites passed in {1}s{2}{3}." -f $total, $elapsed, $laneNote, $shardNote) -ForegroundColor Green
        return $true
    }
    $namesInOrder = @($failedNames | Sort-Object) -join ', '
    Write-Host ("test gate: {0} of {1} suites FAILED in {2}s{3}{4}: {5}" -f $failedNames.Count, $total, $elapsed, $laneNote, $shardNote, $namesInOrder) -ForegroundColor Red
    return $false
}
