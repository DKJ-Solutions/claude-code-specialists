<#
.SYNOPSIS
    Test-FunctionDefined: is a FUNCTION of this name defined in the current session -- asked without
    routing the name through the command searcher's wildcard matcher (issue #1729).

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot 'command-probe-lib.ps1')

    ONE DEFINITION FOR THE SEAM PROBE, where there were 65 inline copies of
    `Get-Command <name> -ErrorAction SilentlyContinue` (issue #1729). Every one of them asks the same
    thing -- "did the repo, or a lib I dot-sourced, define this function" -- and every one of them
    asked it through the most expensive path PowerShell has for the question.

    WHY IT WAS FILED. `Get-Command <bare name>` still routes through
    CommandSearcher.SearchForFunctions and WildcardPatternMatcher even with no wildcard in the name,
    and that matcher is the frame that faulted in #1723: an AccessViolationException inside
    WildcardPatternMatcher.PatternPositionsVisitor.Add, raised from this idiom at
    entry-scaffold-lib.ps1's Get-ReleaseAudienceTier probe, under a 30-lane test pool. That fault has
    ONE sighting and was never reproduced, so it is not what this change rests on -- see the next
    two blocks, which are reproducible on any machine.

    WHAT IT COSTS, measured September 9, 2026 on Windows PowerShell 5.1.26100.9444, 19 PATH entries,
    2000 probes per cell:

      |                       | Get-Command | GetCommands(name,'Function',$false) |
      | seam DEFINED (hit)    |    0.135 ms |                            0.038 ms |
      | seam ABSENT  (miss)   |   32.523 ms |                            0.084 ms |

    THE MISS IS THE CASE THAT MATTERS, and it is the common one. A seam probe is optional by
    definition: a repo that has configured nothing misses every time. `Get-Command` answers a miss by
    falling through to a PATH scan, looking for an executable called `Get-ReleaseAudienceTier` in all
    19 directories -- and nothing caches the negative, so it pays again on the next probe.
    sync-main.ps1 runs 10 of these in a row and build-release-notes-page.ps1 runs 8; in a repo that
    has answered none of them that is a third of a second of directory scanning per run, for a
    question the function table answers from a hashtable.

    AND THE NAME IS PARSED AS A PATTERN, which is the wildcard path showing through in behaviour
    rather than in a stack trace. With `function Get-Weird[x] { }` defined,
    `Get-Command 'Get-Weird[x]' -ErrorAction SilentlyContinue` returns nothing -- it reads the
    brackets as a character class. All three alternatives below return the function. No seam here is
    named like that, so this fixes no live bug; it is cited because it is the cheap, reproducible
    proof that the idiom this replaces really does go through the machinery #1723 faulted inside.

    WHY THIS OVERLOAD AND NOT THE OTHER TWO WAYS TO ASK, both of which are also wildcard-free and
    both of which were measured rather than reasoned about:

      * $ExecutionContext.InvokeCommand.GetCommand($n,'Function') -- THROWS CommandNotFoundException
        on a miss, so it needs a try/catch, and the exception is the cost: 78.5 s for the same 20000
        probes against 0.5 s here. The expensive case is again the common one.
      * Test-Path -LiteralPath "Function:\$n" -- correct, and 2.5x slower (1336 ms vs 532 ms over
        20000), because it goes out through the provider stack to reach the same table. Nothing is
        wrong with it; it is simply the long way round.

    WHAT THIS DOES NOT ANSWER, deliberately: whether an EXECUTABLE, a cmdlet or an alias of this name
    exists. It reads the function table and only the function table, which is what makes it cheap. So
    before reaching for it, decide which question you are asking -- a probe for `gh` or `git` is
    asking about PATH, and for that question `Get-Command` is not the expensive way to ask, it is the
    only way. Those probes keep the old idiom and are correct as they stand.

    Deliberately no census of call sites here. seam-lib.ps1's Test-IsWorkflowSourceRepo records what
    that costs: a list of sites in a docstring is a snapshot, it goes stale silently while the tree
    keeps being written, and it was wrong at three different values in nine days. `grep` is the
    inventory and it is always current.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function Test-FunctionDefined {
    <#
        $true when a FUNCTION of this name is defined in the current session, from any scope the
        caller can see -- global, script, or an enclosing function's. See the file synopsis for why
        this is not Get-Command and for what it deliberately does not look at.

        The third argument is the one doing the work: nameIsPattern = $false tells PowerShell the
        string is a literal name, which is what keeps it off the wildcard matcher.

        TOTAL ON DEGENERATE INPUT, and asserted in the suite rather than left to be discovered: '',
        whitespace and $null all return $false instead of throwing. A probe is asked in order to
        decide whether to call something, so a caller that has been handed an empty seam name wants
        "no" and not a terminating error two frames further down.
    #>
    param([string]$Name)
    return ([bool](@($ExecutionContext.InvokeCommand.GetCommands($Name, 'Function', $false)).Count))
}
