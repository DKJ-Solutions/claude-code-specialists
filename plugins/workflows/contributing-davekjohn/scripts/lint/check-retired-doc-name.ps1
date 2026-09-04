<#
.SYNOPSIS
    Gate: does this consumer's own law-bearing prose still name a RETIRED name of the branch's
    development document? (issue #1389)

.DESCRIPTION
    THE HOLE THIS CLOSES. A renamed convention reaches a consumer through nothing. The branch document
    was renamed twice on September 3, 2026 -- 'development.md' -> 'development-<slug>.md' (#1255) ->
    '<slug>.md' (#1335) -- and the TOOLING was deliberately made rename-proof for exactly that: every
    reader goes through Resolve-BranchFilePath, and the fold's bound in the source repo's constitution
    is named by that resolver rather than spelled out. The PROSE describing it to consumers was not.
    No gate reads a consumer's CLAUDE.md; check-script-contract.ps1 covers functions, so a renamed FILE
    CONVENTION is outside it by construction; and #1273 caught the plugin's own pages while nobody was
    positioned to notice that both live consumers had the same defect, because noticing it means reading
    a repo the source repo never reads.

    MEASURED, in both BWJ consumers: each still restated the retired single 'development.md' in its
    always-on documents -- one day and six days after the rename.

    IT ADDS NO RULE OF ITS OWN. It calls Get-RetiredDocNameMention in entry-scaffold-lib.ps1, which is
    the one definition of "a consumer document restates a retired name": the document set, the changelog
    exclusion, the plugin-payload exclusion, and the scan. The retired names themselves come from
    Get-BranchFileLegacyNames -- already the one ordered source the resolver and new-branch's writer
    share -- so the next rename adds this token by the same row it always adds.

    LITERAL, AND ONLY LITERAL. The prose-contract FRAMEWORK (#1380, 11 laws, a manifest, a fuzzy match)
    was measured at 12.5% precision and DECLINED (Dave, September 4, 2026). The decline recorded this
    check as the alternative that IS proportionate -- "one [grep] for the literal string
    'development.md' outside the changelog and history paths" -- and that sentence is this script's whole
    licence. A filename is an exact string with a mechanical answer, the same distinction that separates
    this repo's accepted dead-link check (17 findings, 17 real) from its declined stale-path check (124
    findings, none real). Anything that reads what a sentence MEANS belongs to the declined design, not
    here.

    IT SKIPS THE REPO THAT PUBLISHES THE PLUGIN, and #1380's own measurement is why: this repo's pages
    narrate the rename history correctly, on purpose, so without the skip the SOURCE reads as consumer
    drift -- which is exactly what the first pass of that measurement did before the guard was applied.
    The test is the source-repo guard's own condition 2, '.claude-plugin/marketplace.json exists': the
    condition that leaves every consumer alone, used here in the mirror direction. Assert-OwnCopy itself
    is deliberately NOT used -- see the note beside the dot-source below.

    NO gh, NO NETWORK. Every input is a file in the working copy, which is what lets the SessionStart
    hook run this in a consumer with no token.

    WHAT IT PRINTS OUT OF A CONSUMER'S FILES IS SANITIZED (#1419). The finding names a path and echoes
    the offending LINE, and the hook forwards this whole report into session context while deciding what
    to surface by matching '[ERROR]' over it -- so a raw echo lets untrusted text choose how loudly it is
    reported. The two values go through check-report-lib.ps1's Format-SafePathToken and
    Format-SafeProseToken; the plugin's own strings (the retired name, the "since" sentence) stay raw.
    The prose form substitutes square brackets rather than deleting them, because in a sentence a bracket
    is ordinary and the only property needed is that no marker can form -- argued in full in that
    function's docstring, and disclosed to the reader in the footer this check prints.

    ONE CALLER, and it is automatic: the SessionStart hook retired-doc-name-sessioncheck.ps1 in the
    workflow plugin, which reports it at the start of every session in every consumer. NO CI leg,
    deliberately -- a consumer's CI is not this repo's to add, and here the check skips by design.

    RUN IT FROM THE COMMAND LINE whenever you want the answer directly:

        powershell -NoProfile -File scripts/lint/check-retired-doc-name.ps1

    Exit 0 when the prose is clean (or this is the publishing repo); exit 1 with the document, the line
    and the retired name otherwise.

    Pure ASCII, per this repo's script-layer convention.

.PARAMETER RootOverride
    Repo root to operate on, for the test suite and the SessionStart hook. A consumer never types this:
    the root is resolved dual-context like every other shared script.

.PARAMETER RootDocument
    (Optional, for tests) the always-on root to walk instead of '<root>/CLAUDE.md'.

.EXAMPLE
    powershell -NoProfile -File scripts/lint/check-retired-doc-name.ps1
#>
[CmdletBinding()]
param(
    [string]$RootOverride = '',
    [string]$RootDocument = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# NO SOURCE-REPO GUARD (Assert-OwnCopy), deliberately, and for exactly the reason
# check-unfolded-entry.ps1 and check-git-identity.ps1 give: a SessionStart hook invokes this from
# '${CLAUDE_PLUGIN_ROOT}/scripts/lint/' against the current repo, so the guard would refuse it -- and
# thereby the hook -- at every session start in the publishing repo. What the publishing repo needs here
# is not a refusal but a SKIP, which is the marketplace test below and a different question.

# Dual-context repo root: a consumer running the plugin mirror gets it from CLAUDE_PROJECT_DIR, the
# source root copy falls back to the git root. Same resolution as every other mirrored script.
$repoRoot = if ($RootOverride) { $RootOverride } elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# THE SKIP. A repo that publishes plugins is the repo these conventions are maintained in, so its own
# pages narrate the rename history on purpose and every hit there is correct prose. Borrowed verbatim
# from the source-repo guard's condition 2, which uses the same file for the mirror-image purpose: there
# it is what keeps a consumer out, here it is what keeps the publisher out.
if (Test-Path -LiteralPath (Join-Path $repoRoot '.claude-plugin\marketplace.json') -PathType Leaf) {
    Write-Host '[OK] this repo publishes the plugin -- its own pages are the source of the convention, not a copy of it.'
    exit 0
}

# repo-config.ps1 first and optional, exactly as check-unfolded-entry loads it. Nothing here requires a
# seam today; it is loaded so that a repo which HAS answered one is read by its own names rather than by
# the built-in defaults, on the day a seam does reach this path.
$repoConfig = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $repoConfig -PathType Leaf) {
    try { . $repoConfig } catch { Write-Warning "scripts/repo-config.ps1 failed to load ($($_.Exception.Message)) -- the built-in wording is used." }
}

. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')

# THE SANITIZERS, for the two values below that come out of a CONSUMER'S OWN FILES (#1419). This report
# is forwarded into session context by retired-doc-name-sessioncheck.ps1, and that hook -- like every
# other one -- decides what to surface by matching '[ERROR]' over this whole output. So a path or a line
# of prose reaching it raw is untrusted text choosing how loudly it is reported. Nothing else is
# supplied from here: the report markers are written literally below, because this check's shape is one
# [ERROR] header with an indented block under it rather than the counted Write-Failure lines the
# roster/connector checks emit.
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')

# THE WALK IS NOT REIMPLEMENTED HERE. Get-AlwaysOnDocuments owns the '@'-import closure -- the hop cap,
# the cycle guard, the fenced-block skip and the tree/external split this check needs -- and a second
# walk would be a second definition of the always-on path. Loaded guarded rather than required: a tree
# that does not carry measure-context-lib.ps1 still gets the workflow folder's own pages judged, which is
# where one of the two measured instances sat.
$documents = @()
$measureLib = Join-Path $PSScriptRoot '..\lib\measure-context-lib.ps1'
if (Test-Path -LiteralPath $measureLib -PathType Leaf) {
    . $measureLib
    $root = if ($RootDocument) { $RootDocument } else { Join-Path $repoRoot 'CLAUDE.md' }
    if (Test-Path -LiteralPath $root -PathType Leaf) {
        $documents = @(Get-AlwaysOnDocuments -RootDocument $root -RepoRoot $repoRoot)
    }
}

$findings = @(Get-RetiredDocNameMention -RepoRoot $repoRoot -Documents $documents)

if ($findings.Count -eq 0) {
    Write-Host '[OK] no retired branch-document name in this repo''s always-on prose.'
    exit 0
}

Write-Host "[ERROR] $($findings.Count) retired name(s) of the branch's development document are still stated here as current:" -ForegroundColor Red
foreach ($f in $findings) {
    # Rel and Text are the consumer's; Name and Since are the PLUGIN'S OWN and stay raw. Name comes from
    # Get-BranchFileLegacyNames and Since is a sentence written in entry-scaffold-lib.ps1 -- sanitizing
    # either would be theatre, and would quietly cap or reshape text this repo controls. Rel is a path,
    # so it takes the path-shaped sanitizer; Text is a sentence, so it takes the prose-shaped one.
    Write-Host "          $(Format-SafePathToken -Value $f.Rel):$($f.Line)  names '$($f.Name)'" -ForegroundColor Red
    Write-Host "            $(Format-SafeProseToken -Value $f.Text)" -ForegroundColor DarkYellow
    Write-Host "            -> $($f.Since)" -ForegroundColor Red
}
Write-Host '        A consumer document may POINT at a shared convention, state this repo''s answer to a' -ForegroundColor Red
Write-Host '        seam the plugin names, or say NOTHING -- never restate the convention in its own words.' -ForegroundColor Red
Write-Host '        The rule is in CONTRIBUTING-portable.md, "The two contributing layers, and which one' -ForegroundColor Red
Write-Host '        wins"; a restatement does not fail on the day it is written, only on the day the' -ForegroundColor Red
Write-Host '        plugin''s answer moves under it. Replace each line above with a pointer.' -ForegroundColor Red
Write-Host '        The echoed line is a PREVIEW, not the text: square brackets are shown as round ones' -ForegroundColor DarkGray
Write-Host '        so nothing in it can be read as a marker of ours. Open it at the file and line above.' -ForegroundColor DarkGray
exit 1
