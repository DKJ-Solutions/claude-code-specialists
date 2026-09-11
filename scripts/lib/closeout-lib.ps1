<#
.SYNOPSIS
    The close-out receipt shape, printed at the moment a work chain ends -- so the rule is in front
    of the session that is about to write one, instead of 300 lines back in a persona body.

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\closeout-lib.ps1')

    WHY THIS EXISTS (issue #1884, September 11, 2026). Chris's ritual has six steps and step 6 -- the
    close-out -- was the only one with no mechanism behind it. It is also the step that runs LAST,
    when the session is longest and the rule is furthest back in context, and it has now been
    repaired in prose four times and lost four times:

        #849   August 24, 2026   the three permitted shapes (A done / B one decision / C parked)
        --     August 27, 2026   "THE CLOSE-OUT IS A RECEIPT, NOT THE REPORT"
        #1402  September 4, 2026 the filing line bounded to a number and at most a short clause
        #1408  September 4, 2026 the order: duplication filters first, then a ceiling of 2-3 lines

    All four were live, in context, and byte-identical between clone and install cache on the session
    that broke two of them at once with a ~25-line close-out carrying two tables. #1402 named the
    diagnosis correctly a week before this file existed -- "this is not a missing rule. It is a rule
    that keeps losing" -- and the new information in #1884 is only that a fourth sharpening has now
    been tried. That is evidence about the REPAIR STRATEGY, not about the wording, which is why the
    fifth repair is not a fifth paragraph.

    THE PRECEDENT IS THE CLAIM STEP, AND IT IS STATED IN THE SAME PERSONA 250 LINES BELOW: "a rule
    enforced by nothing but memory is one that gets skipped". That principle was acted on for
    claiming -- it became claim-issue.ps1 plus a model-invocable skill -- and step 6 is what was left
    memory-only. This is that same move, one step further down the ritual.

    WHY PRINTING AND NOT MEASURING. The alternative #1884 weighed was a Stop hook reading the
    transcript and reporting the line count after the fact. It is strictly more thorough and it is
    not what this is, for two reasons: it has to parse a transcript shape that differs across the
    harness versions consumers run (#1884 lists that as not investigated), and it reports a close-out
    that has ALREADY been written, where this lands before one is composed. A reminder that arrives
    after the failure is a second report to read, which is the thing being complained about.

    SO THE PLACEMENT IS THE WHOLE MECHANISM: the last line of a chain-ending script is typically the
    last thing in context when the close-out is composed. Nothing here refuses anything, nothing
    fails a run, and nothing is measured -- it costs three lines of DarkGray at the one moment they
    are free.

    IT OBEYS ITS OWN CEILING, deliberately. A reminder about brevity that runs ten lines teaches the
    opposite of what it says, and would be the fifth prose repair wearing a script's clothes.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function Write-CloseOutReceipt {
    <#
    .SYNOPSIS
        Print the three-part close-out shape, with the citation this run already knows.

    .DESCRIPTION
        Called as the LAST statement of a chain-ending script. Prints nothing that a reader has to
        act on -- it is a reminder, not a check -- and never touches an exit code.

    .PARAMETER Cite
        Where the detail already lives, in the form a receipt would carry it: 'PR #1885', 'issue
        #1884', 'the branch document'. The point of naming it is that the receipt's middle part is
        the one a session most often replaces with prose, because "where to read it" feels like it
        needs explaining. It does not; it needs a number. Omitted, the line falls back to the generic
        wording rather than printing an empty parenthesis.

    .PARAMETER Bypass
        A gate this run was told to skip ('-SkipTests', '-SkipLint'), so the reminder can say where a
        deliberate bypass belongs. This is #1884's SECOND, smaller finding and the reason it is a
        parameter rather than a fixed sentence: the three permitted shapes have no home for "I
        deviated from a gate", so the failing session disclosed it in the reply -- correctly refusing
        to let the requester learn it later, and with nowhere else to put it. The honest home is the
        PR body, with the receipt carrying a clause. The SCRIPT knows this fact and the persona
        cannot, which is exactly the kind of thing a mechanism should be carrying rather than prose.

    .PARAMETER Quiet
        Print nothing. For a caller that is itself being driven by another script in the same chain,
        so the shape is printed once per chain rather than once per script.
    #>
    [CmdletBinding()]
    param(
        [string]$Cite = '',
        [string]$Bypass = '',
        [switch]$Quiet
    )

    if ($Quiet) { return }

    # THE MIDDLE PART IS THE ONE THAT DRIFTS, so it is the one that gets the caller's own answer.
    $where = if ([string]::IsNullOrWhiteSpace($Cite)) { 'where to read it' } else { "where to read it ($($Cite.Trim()))" }

    Write-Host ""
    Write-Host "Close-out: a receipt, not a report." -ForegroundColor DarkGray
    Write-Host "  What happened, $where, and that the session can be cleared -- two or three lines." -ForegroundColor DarkGray
    Write-Host "  Longer than that is rehoused, not cut: the branch document, the PR body, or an issue the receipt cites by number." -ForegroundColor DarkGray

    # ONLY WHERE THERE IS SOMETHING TO SAY. A run that skipped nothing prints nothing here, so the
    # clause keeps its signal -- the same reasoning every other conditional line in this workflow
    # carries, and the reason this is not folded into the three lines above.
    if (-not [string]::IsNullOrWhiteSpace($Bypass)) {
        Write-Host "  This run skipped $($Bypass.Trim()): a deliberate gate bypass belongs in the PR body, with a clause in the receipt." -ForegroundColor DarkGray
    }
}
