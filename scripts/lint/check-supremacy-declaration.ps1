<#
.SYNOPSIS
    Gate: does this consumer's own law-bearing prose declare its OWN 'CLAUDE.md' the winner over the
    workflow's contributing page, inverting the third-rank order the plugin legislates? (issue #1415)

.DESCRIPTION
    THE HOLE THIS CLOSES, and it is the one hole #1380 identified as STRUCTURALLY invisible to every
    candidate it measured. A flagged finding is by construction a section carrying no citation, so
    cites-then-contradicts can only ever appear among the SUPPRESSED findings -- a pointer test built on
    "is the source mentioned nearby" cannot tell correct deference from restatement-with-citation-and-
    override. The census of suppressed sections there was 4: 3 correct deferrals and 1 contradiction.
    That one is a consumer preamble naming the portable contributing page as a pointer into the plugin
    and, four lines later, overriding it.

    THE LAW IT READS is LAW-THIRD-RANK-ORDER out of #1380's surviving manifest: the plugin's portable
    pages and skills outrank 'contributing-davekjohn/CONTRIBUTING.md', which outranks the floor. A repo
    declaring its own 'CLAUDE.md' the winner has inverted that -- and it has done so in prose, in the one
    layer no gate reads.

    THE MEASUREMENT CAME FIRST, AND IT OVERTURNED THE RECORDED SHAPE. #1380's decline recorded this
    alternative as "'wins'/'wint' plus 'CLAUDE.md' plus the contributing page's own filename, all three
    in the same sentence", and #1415 asked for that to be measured before it shipped, since it had never
    been run as a check. Over the same 8-document corpus it scores 0 raw findings at sentence scope and
    0 at line scope -- ZERO RECALL on the single defect it was named to catch -- and 1 finding at
    paragraph scope, which is a false positive. The reason is exact: the real sentence names the
    contributing page by a Dutch prose noun, 'de contributor-pagina', not by its filename, so the third
    term is precisely the one that is absent.

    WHAT SHIPS INSTEAD IS ADJACENCY, which is literal in the same way a filename is literal but answers
    the question co-occurrence cannot: WHICH page is declared the winner. 'this page wins' over
    'CLAUDE.md' is the law stated CORRECTLY and a term list scores it identically to the inversion.
    Requiring the two tokens to sit next to each other makes the subject of the verb readable without
    reading the sentence. Measured: 3 raw / 2 reported / 2 true / 100% precision, both standing instances
    found -- one more than #1380's census knew about. Held against this repo's own bar, the accepted
    dead-link check (17 findings, 17 real) against the declined stale-path check (124 findings, none
    real), it lands on the accepted side. The detector, the one quotation suppression, and the honest note
    that the suppression rests on a single instance are all in Get-SupremacyDeclaration.

    IT SKIPS THE REPO THAT PUBLISHES THE PLUGIN, the same condition its sibling uses -- the source-repo
    guard's condition 2, '.claude-plugin/marketplace.json exists'. STATED HONESTLY, THE SKIP IS A GUARD
    RATHER THAN A REPAIR HERE: measured on the day it was written, this repo's own always-on pages
    produce ZERO hits, because every supremacy sentence they carry names the plugin's page as the winner
    and adjacency reads that correctly. It is kept because this is the repo where such sentences are
    written about consumers, one future line would fire, and it costs four lines and keeps the two
    sibling checks the same shape.

    NO gh, NO NETWORK. Every input is a file in the working copy, which is what lets the SessionStart
    hook run this in a consumer with no token.

    ONE CALLER, and it is automatic: the SessionStart hook supremacy-declaration-sessioncheck.ps1 in the
    workflow plugin. NO CI leg, deliberately, for the reason its sibling gives -- a consumer's CI is not
    this repo's to add, and here the check skips by design.

    RUN IT FROM THE COMMAND LINE whenever you want the answer directly:

        powershell -NoProfile -File scripts/lint/check-supremacy-declaration.ps1

    Exit 0 when the prose is clean (or this is the publishing repo); exit 1 with the document, the line
    and the matched text otherwise.

    Pure ASCII, per this repo's script-layer convention.

.PARAMETER RootOverride
    Repo root to operate on, for the test suite and the SessionStart hook. A consumer never types this:
    the root is resolved dual-context like every other shared script.

.PARAMETER RootDocument
    (Optional, for tests) the always-on root to walk instead of '<root>/CLAUDE.md'.

.EXAMPLE
    powershell -NoProfile -File scripts/lint/check-supremacy-declaration.ps1
#>
[CmdletBinding()]
param(
    [string]$RootOverride = '',
    [string]$RootDocument = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# NO SOURCE-REPO GUARD (Assert-OwnCopy), deliberately, and for exactly the reason check-unfolded-entry.ps1,
# check-git-identity.ps1 and check-retired-doc-name.ps1 give: a SessionStart hook invokes this from
# '${CLAUDE_PLUGIN_ROOT}/scripts/lint/' against the current repo, so the guard would refuse it -- and
# thereby the hook -- at every session start in the publishing repo. What the publishing repo needs here is
# not a refusal but a SKIP, which is the marketplace test below and a different question.

# Dual-context repo root: a consumer running the plugin mirror gets it from CLAUDE_PROJECT_DIR, the source
# root copy falls back to the git root. Same resolution as every other mirrored script.
$repoRoot = if ($RootOverride) { $RootOverride } elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# THE SKIP. See the docstring: a guard rather than a repair, measured at zero hits here on the day it was
# written, kept because this is the repo where sentences about a consumer's supremacy rule get written.
if (Test-Path -LiteralPath (Join-Path $repoRoot '.claude-plugin\marketplace.json') -PathType Leaf) {
    Write-Host '[OK] this repo publishes the plugin -- its own pages are the source of the rank order, not a copy of it.'
    exit 0
}

# repo-config.ps1 first and optional, exactly as check-retired-doc-name loads it. Nothing here requires a
# seam today; it is loaded so that a repo which HAS answered one is read by its own names rather than by the
# built-in defaults, on the day a seam does reach this path.
$repoConfig = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $repoConfig -PathType Leaf) {
    try { . $repoConfig } catch { Write-Warning "scripts/repo-config.ps1 failed to load ($($_.Exception.Message)) -- the built-in wording is used." }
}

. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')

# THE WALK IS NOT REIMPLEMENTED HERE, and neither is the corpus. Get-AlwaysOnDocuments owns the '@'-import
# closure; Get-ConsumerProseDocuments owns which of those documents a consumer-prose check may look in.
# Loaded guarded rather than required: a tree that does not carry measure-context-lib.ps1 still gets the
# workflow folder's own pages judged, which is where one of the two measured instances sat.
$documents = @()
$measureLib = Join-Path $PSScriptRoot '..\lib\measure-context-lib.ps1'
if (Test-Path -LiteralPath $measureLib -PathType Leaf) {
    . $measureLib
    $root = if ($RootDocument) { $RootDocument } else { Join-Path $repoRoot 'CLAUDE.md' }
    if (Test-Path -LiteralPath $root -PathType Leaf) {
        $documents = @(Get-AlwaysOnDocuments -RootDocument $root -RepoRoot $repoRoot)
    }
}

$findings = @(Get-SupremacyDeclaration -RepoRoot $repoRoot -Documents $documents)

if ($findings.Count -eq 0) {
    Write-Host '[OK] no inverted supremacy declaration in this repo''s always-on prose.'
    exit 0
}

Write-Host "[ERROR] $($findings.Count) line(s) declare this repo's CLAUDE.md the winner over the workflow's contributing page:" -ForegroundColor Red
foreach ($f in $findings) {
    Write-Host "          $($f.Rel):$($f.Line)  matched '$($f.Match)'" -ForegroundColor Red
    Write-Host "            $($f.Text)" -ForegroundColor DarkYellow
}
Write-Host '        THE ORDER RUNS THE OTHER WAY. The plugin''s portable pages and skills outrank' -ForegroundColor Red
Write-Host '        contributing-davekjohn/CONTRIBUTING.md, which outranks this repo''s own CLAUDE.md --' -ForegroundColor Red
Write-Host '        see CONTRIBUTING-portable.md, "A third rank sits above both". A line above inverts it,' -ForegroundColor Red
Write-Host '        so a session reading that page and a session reading CLAUDE.md follow different rules' -ForegroundColor Red
Write-Host '        and neither is wrong on the page it read.' -ForegroundColor Red
Write-Host '        A repo that genuinely wants its own constitution to lead states that as a SEAM answer,' -ForegroundColor Red
Write-Host '        not by overriding the page in prose. Otherwise replace each line above with a pointer.' -ForegroundColor Red
exit 1
