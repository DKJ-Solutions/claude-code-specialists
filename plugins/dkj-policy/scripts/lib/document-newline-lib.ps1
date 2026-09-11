<#
.SYNOPSIS
    Get-DocumentNewline: the newline style a document is ALREADY written in -- "`r`n" or "`n"
    (issue #1832).

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot 'document-newline-lib.ps1')

    ONE DEFINITION FOR THE READING EVERY DOCUMENT-EDITING SCRIPT IN THIS TREE DOES, where there were
    nine hand-typed copies across six files (issue #1832). Six carried the one-liner verbatim and three
    spelled the same answer over two statements, which is why a grep for the one-liner undercounted it.

    WHY IT MATTERS AT ALL. A script that composes a block with a hardcoded LF and then compares it
    against a page read byte-exact reports "drifted" on every CRLF checkout, and a script that appends
    an LF block to a CRLF page leaves the file mixed. That is inbound #1829:
    adopt-workflow-folder.ps1's README top-up did both. Four scripts in this tree already knew the
    answer to that exact question; the fifth did not, and nothing connected them. A NAMED helper is the
    thing the sixth one finds when it looks -- which is the whole point of this file, since the body is
    one line and would be cheaper to retype than to load.

    IT IS A WHOLE-FILE READING, AND THAT IS THE KNOWN LIMIT OF IT -- carried here from
    adopt-workflow-folder.ps1, where #1829 wrote it down, because it is the same in every caller and
    belongs with the answer rather than beside one of them. A page that is ALREADY mixed -- mostly LF
    with one stray CRLF somewhere in it -- answers 'CRLF', so a block composed from that answer is CRLF
    while the text immediately around it is LF: the mix is RELOCATED rather than removed. That is
    accepted rather than overlooked, and extracting the reading deliberately did not change it. A
    neighbourhood-local answer would make whichever caller adopted it judge differently from all the
    others, and the pages it would be judging are ones nothing in this workflow wrote that way.

    WHAT A CALLER STILL OWNS. This returns the style and nothing else. Whether a caller wants a
    fallback of its own -- adopt-workflow-folder.ps1 reads `else { $nl }` where the libs read
    `else { "`n" }`, identical in effect because that variable is assigned "`n" once and never
    reassigned -- is the caller's business, not a behaviour this file settles.

    A LEAF WITH NO DEPENDENCIES OF ITS OWN, like ref-print-lib.ps1 and command-probe-lib.ps1, which is
    what makes it safe for the libs that dot-source it to load it first. Two do -- entry-scaffold-lib
    and pr-body-lib -- and between them they reach every caller: release-lib, cut-release,
    fold-changelog-entry and adopt-workflow-folder all already load entry-scaffold-lib, so none of them
    gains a dependency it did not have. The same transitive reach Test-FunctionDefined already relies
    on.
#>

function Get-DocumentNewline {
    <#
    .SYNOPSIS
        The newline style $Content is written in: "`r`n" if it contains one anywhere, else "`n".

    .DESCRIPTION
        Read the style off the document you are about to edit, then compose and compare in it. See this
        file's banner for the whole-file limit, which is deliberate.

        AN EMPTY DOCUMENT ANSWERS "`n", and that is the right answer rather than a missing case: there
        is no evidence for CRLF in it, and every caller that can be handed an empty string is writing
        the first content into it. Two callers declare [AllowEmptyString()] on their own parameter and
        reached the old inline reading with '' already.
    #>
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Content)

    if ($Content.Contains("`r`n")) { "`r`n" } else { "`n" }
}