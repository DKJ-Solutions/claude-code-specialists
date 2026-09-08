<#
.SYNOPSIS
    One function -- Invoke-CheckScript -- so a SessionStart hook can run its check script IN THE
    HOOK'S OWN INTERPRETER instead of spawning a second powershell.exe for it (issue #1625).

.DESCRIPTION
    Dot-source this file as a $PSScriptRoot-relative sibling, exactly like check-report-lib.ps1 and
    native-capture-lib.ps1 -- it is plugin-carried, not repo-owned, so a consumer answers no seam for
    it and needs no scaffold:

        . (Join-Path $PSScriptRoot '..\scripts\lib\hook-check-lib.ps1')   -- from hooks/*

    WHAT IT REPLACES, AND WHAT THAT COST. Every session check in this family ran its check script the
    same way:

        $out  = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $checkScript @checkArgs)
        $code = $LASTEXITCODE

    The harness already pays one interpreter start-up to run the hook, so the second one is pure
    addition. Measured on Windows PowerShell 5.1, a script whose only line is 'exit 0': 219 ms median
    for the spawn against 6 ms for the in-process call -- and six hooks carried one each.

    THE SAVING IS WALL-CLOCK AND IT IS NOT THE SUM, BECAUSE THE HARNESS RUNS HOOKS IN PARALLEL.
    "Claude Code runs all matching hooks in parallel" (Claude Code hooks guide), so the six spawns
    never sat end to end on the critical path and the ~1.3 s that summing them suggests was never
    real. Measured instead the way the harness actually runs them -- six concurrent hook processes,
    with the redundant spawn and without -- the difference is 311-443 ms over three rounds. That is
    MORE than one spawn in isolation and far less than six, because six simultaneous process
    creations contend for CPU and disk rather than costing what one costs. Paid on every startup,
    resume, clear and compact.

    That measurement is the reason this lib exists at all rather than the issue being closed as an
    accepted cost: #1625 filed the figure as ~875 ms additive on the assumption that hooks run
    sequentially, and settling the parallel question was named there as the thing to do BEFORE
    optimising on the number. Settled, the prize is smaller than filed and still worth a contained
    change.

    THREE TRAPS, WHICH IS WHY THIS IS A LIB AND NOT FOUR LINES COPIED SIX TIMES. Each of them fails
    SILENTLY -- a wrong answer, not a crash -- so a drifted copy would report a clean check rather
    than announce itself:

      1. AN ARRAY SPLATS POSITIONALLY IN-PROCESS. '& powershell -File $s @arr' hands the child a
         command LINE, so '-Skip','-Path','C:\x' binds by name. '& $s @arr' hands a script an
         ARGUMENT LIST, and the same array binds '-Skip' to the first positional parameter. Measured:
         a script with 'param([switch]$Skip,[string]$Path)' called that way reported
         'Skip=False Path=-Skip'. Nothing errors. So this function takes a HASHTABLE and callers pass
         one.
      2. Write-Host DOES NOT REACH THE PIPELINE. In a child process it lands on the child's stdout,
         which the caller captures. In-process it goes to the information stream (6) -- so a plain
         '$out = @(& $s)' captures NOTHING and every line the check wrote leaks straight to the hook's
         own stdout, i.e. unfiltered into the session context. That is the failure that matters most
         here: these hooks exist to forward [ERROR] and hold everything else back, and it would
         forward the lot. '6>&1' is what makes the capture equivalent.
      3. ONE Write-Host CAN CARRY SEVERAL LINES. A child process's stdout arrives already split, so a
         Write-Host of "a", "b" and "c" joined by newlines reached the old callers as three elements.
         Stringifying an InformationRecord gives one element holding two newlines instead, and the
         hooks then indent the block once and line-match it as a unit. Measured on a fixture: 5
         captured lines through the child, 3 in-process, 5 again once split. So the records are split
         on newlines and in-process capture is line-for-line what the spawn produced.

    AND ONE THAT DOES NOT FAIL SILENTLY BUT IS WORTH THE SAME CARE: $LASTEXITCODE IS STALE, NOT
    ABSENT. A '-File' child always leaves an exit code behind. A script called in-process that returns
    without reaching an 'exit' leaves $LASTEXITCODE holding whatever the previous native call put
    there, so a check that ended cleanly could report its predecessor's failure. It is reset before
    the call, which makes "no exit statement" read as 0 -- which is what the child did.

    WHY IN-PROCESS IS SAFE FOR THESE CALLERS, on the two grounds a reviewer asks about:

      - 'exit' DOES NOT TAKE THE HOOK WITH IT. The check scripts call it freely (6 in
        check-unfolded-entry.ps1, 6 in check-git-identity.ps1, 5 in check-consumer-prose.ps1), and
        #1625 reasoned from that to "the obvious fix is not a one-liner". That reasoning holds for
        DOT-SOURCING, which runs in the caller's scope, and for a script BLOCK invoked with '&'.
        It does not hold for a .ps1 FILE invoked with '&': that gets its own scope, its 'exit'
        terminates the script alone, and control returns to the hook with $LASTEXITCODE set.
        Verified before this lib was written, not assumed.
      - SCOPE DOES NOT LEAK EITHER WAY THAT MATTERS. '&' gives the script a child scope, so nothing
        it defines or assigns reaches the hook. It does INHERIT the hook's Set-StrictMode and
        $ErrorActionPreference -- and every check script in this family sets both itself, on its
        first two statements, so the inherited values are overwritten before any of its code runs.
        A future check that does not set them is the one case a caller has to think about.

    WHAT IS DELIBERATELY NOT DONE HERE: stderr is not merged in. A '-File' child's stderr never
    reached these callers either (it went to the hook's own stderr), and merging it would put lines
    the check never meant as findings in front of the hooks' [ERROR] filter. In-process, a
    terminating error surfaces as an exception instead, which every one of these hooks already wraps
    in a try/catch that reports the check as skipped.

    NOT A REPLACEMENT FOR Invoke-NativeCapture. That lib bounds a child process with a timeout,
    which is the right tool when the callee may HANG -- a hook's try/catch cannot save it from a
    blocking call. This function has no timeout and cannot have a useful one: an in-process call
    cannot be abandoned from the thread that is making it. Nothing regresses, because the six calls
    it replaces were unbounded spawns with no timeout either; the harness's own per-hook timeout in
    hooks.json remains the backstop for both. A check that grows a network call of its own belongs
    behind Invoke-NativeCapture, not here.

    Pure ASCII, per this repo's script-layer convention.
#>

function Invoke-CheckScript {
    <#
    .SYNOPSIS
        Run a check script in this interpreter and return its output lines and its exit code.

    .DESCRIPTION
        Returns a hashtable, deliberately the same two-field shape Invoke-NativeCapture returns so a
        caller can be moved between the two without re-reading its own result handling:

            Output    string[] -- the check's lines, split as the child's stdout was split
            ExitCode  int      -- the check's exit code, 0 when it returned without exiting

        Throws nothing of its own. A terminating error inside the check propagates to the caller,
        which in every current caller is a hook whose try/catch reports the check as skipped.

    .PARAMETER Path
        The check script. Resolved and existence-checked by the CALLER -- every hook here already
        does that in order to print its own "check script not found" line, and duplicating the test
        would mean two different messages for one state.

    .PARAMETER Arguments
        The check's parameters as a HASHTABLE, splatted by name. Never an array: see trap 1 in this
        file's header. Omit for a check that takes none.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [hashtable]$Arguments = @{}
    )

    # Reset, so "the check returned without an exit statement" reads as 0 rather than as whatever the
    # last native call in this hook left behind. See the header.
    $global:LASTEXITCODE = 0

    # 6>&1 captures Write-Host (trap 2); the split makes one multi-line record into the several lines
    # the spawn produced (trap 3); @Arguments splats a hashtable by name (trap 1).
    $lines = @(& $Path @Arguments 6>&1 |
        ForEach-Object { [string]$_ } |
        ForEach-Object { $_ -split "`r?`n" })

    return @{
        Output   = $lines
        ExitCode = [int]$LASTEXITCODE
    }
}
