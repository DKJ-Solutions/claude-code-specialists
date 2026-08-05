<#
.SYNOPSIS
    Lays down the skeleton for the internal release summary: releases/internal/<dir>/<X.Y.Z>.md.

.DESCRIPTION
    THE TIER-1 release document, for colleagues, employers and management. It exists at EVERY release,
    patch included, and fills the gap between the other two:

      releases/development/<dir>/<X.Y.Z>.md   tier 0   developers   -- always, complete and long
      releases/internal/<dir>/<X.Y.Z>.md      tier 1   colleagues   -- always, what the work is worth
      releases/highlights/<dir>/<X.Y.Z>.md    tier 2   consumers    -- minor/major, what they notice

    THE DISTINCTION THAT KEEPS THE TIERS WORKABLE: highlights = WHAT THE CONSUMER NOTICES, internal =
    WHAT THE ORGANISATION GETS OUT OF IT. They come apart most clearly on a patch, which is where this
    tier was first needed: a release with nothing for a consumer -- correctly a patch, therefore no
    highlights -- can still be the release where a team stopped needing a developer for a routine change.

    WHICH ENTRIES IT CARRIES OVER: tier 1 AND tier 2, because the ladder is cumulative. Something a
    consumer notices is something a colleague should hear about too, so a tier-2 entry appears in this
    document as well as in the highlights. Tier-0 entries do not: they are repo-internal by definition,
    the developer notes are their record, and copying them here would rebuild the document this tier
    exists to avoid.

    IT GENERATES ONLY HALF, AND THAT IS THE POINT. Version, date, type and the entry titles come from the
    developer notes; "what it is worth" cannot be derived from a changelog. So what you get is a SKELETON
    with the titles as bullets and three fixed headings to fill in -- the same "edit it afterwards" shape
    the highlights tier has. The three headings are fixed on purpose: without that boundary this tier
    grows back into the developer notes it was created to avoid.

    WHY THIS IS ITS OWN SCRIPT RATHER THAN PART OF cut-release.ps1. In the repo this was ported from the
    reason was that cut-release was marked "temporarily diverged" and must not be extended; that reason is
    gone (#417 made it shared). The reason it still holds is different and better: cut-release COMMITS AND
    TAGS in one motion, so a skeleton generated there would put an empty document inside the release tag
    and the written version would land afterwards anyway. Keeping it separate means the release commit
    stays what it is -- purely generated artefacts -- while the one document that is human-written from
    beginning to end travels the normal reviewed route.

    SHARED, WITH THE DOCUMENT'S WORDING IN THE SEAM. This script is mirrored into the plugin. Its console
    output and errors are English like every shared script here, but the DOCUMENT it writes is read by a
    given repo's own colleagues -- so every string that lands in the file comes from the optional
    Get-InternalNoteWording in scripts/repo-config.ps1, falling back to the English text below. Same
    #410 reasoning as the entry stubs and the highlights marker.

    Pure ASCII (repo convention for .ps1): Windows PowerShell 5.1 reads a BOM-less script using the system
    ANSI codepage, so a literal non-ASCII character in the source is decoded wrongly. The middot that
    separates the entry heading fields is therefore built from its codepoint.

.PARAMETER Version
    The release, as X.Y.Z or vX.Y.Z (e.g. 3.2.0).

.PARAMETER RepoRoot
    Alternative repo root. Defaults to CLAUDE_PROJECT_DIR, then the git toplevel. Exists so the test
    suite can run against a fixture without touching a real release, and so the script works from any
    directory.

.PARAMETER Force
    Overwrite an existing internal note. Without this flag the script refuses -- resetting an already
    written note back to a skeleton is a loss you do not want to make by accident.

.EXAMPLE
    ./scripts/release/new-internal-note.ps1 -Version 3.2.0
#>
param(
    [Parameter(Mandatory)]
    [string]$Version,

    [string]$RepoRoot = '',

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Anchor the repo root -------------------------------------------------------------------------
# Every path below is absolute and derived from this root. Deliberately no Set-Location: then a
# divergent process cwd cannot write into the wrong repo (the pitfall cut-release.ps1 has to close with
# an explicit anchor). Dual context first, the same contract every shared script here follows (#81).
if (-not $RepoRoot) {
    $RepoRoot = if ($env:CLAUDE_PROJECT_DIR) {
        $env:CLAUDE_PROJECT_DIR
    } else {
        $topLevel = git rev-parse --show-toplevel | Select-Object -First 1
        if (-not $topLevel) { Write-Error "No git repo found. Run this from the repo, or pass -RepoRoot."; exit 1 }
        $topLevel.Trim()
    }
}
if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) {
    Write-Error "RepoRoot does not exist: $RepoRoot"; exit 1
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

# Set-ReleaseInternalNoteLink, for repointing the changelog's release block at this note once it exists
# (see the call near the end). $PSScriptRoot-relative, like every other shared script's dot-source, so
# the plugin mirror resolves its own copy rather than the consumer's repo root.
. (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')

# --- Parse the version --------------------------------------------------------------------------
$verNum = ($Version.Trim() -replace '^[vV]', '')
if ($verNum -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
    Write-Error "Version '$Version' is not X.Y.Z (e.g. 3.2.0)."; exit 1
}
$major = $Matches[1]
$minor = $Matches[2]

# --- The repo's own answers ----------------------------------------------------------------------
# Optional, all of them, each falling back to the English text below -- so a consumer that defines
# nothing still gets a working skeleton in this script's own language.
function Get-SeamValue {
    param([Parameter(Mandatory)][string]$Name, $Default)
    if (Get-Command $Name -ErrorAction SilentlyContinue) { return (& $Name) }
    return $Default
}

$configPath = Join-Path $RepoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $configPath) {
    try {
        . $configPath
    } catch {
        Write-Warning "scripts\repo-config.ps1 could not be loaded ($($_.Exception.Message)) -- writing the skeleton with the built-in English wording."
    }
}

# The notes folder scheme is answered ONCE for the whole repo (#417) and every tier reads it, so the
# internal note lands beside its developer notes rather than in a scheme of its own.
$grouping = Get-SeamValue -Name 'Get-ReleaseNotesGrouping' -Default 'major'
$notesDir = if ($grouping -eq 'minor') { "$major.$minor" } else { "$major.x" }

# THE DOCUMENT'S OWN WORDING (#410 class). Merged over these defaults rather than replacing them, so a
# consumer that renames one heading does not have to restate the rest.
$w = @{
    Title          = 'Internal summary'
    AudienceLabel  = 'For whom'
    Audience       = 'colleagues and management -- what the organisation gets out of this release'
    SkeletonNote   = @(
        'SKELETON. Edit this file and delete these comment blocks afterwards.',
        'The bullets below are the tier-1 and tier-2 entries of the developer notes -- tier 0 is',
        'repo-internal and deliberately absent. The [type] marker is a hint about what is',
        'worth keeping, and belongs gone once you rewrite the line. Keep it to one page at most:',
        '1-3 lines per subject, no file names, no code. Anything that means nothing to someone',
        'outside the team, remove -- this tier is not complete, it is readable.'
    ) -join "`n     "
    SectionChanged = 'What is different now'
    SectionValue   = 'What it is worth'
    HintValue      = @(
        'This is the core of this tier and the only part that cannot be generated. Think in time,',
        'risk and reduced dependence on a developer. For example: "changing an amount took five',
        'edits in code and can now be done by the team itself".'
    ) -join "`n     "
    SectionOpen    = 'What was still open at this release'
    HintOpen       = @(
        'What was deliberately left, and with whom the next step sits. "Nothing" is also an answer',
        '-- leave the heading standing with that one line.',
        'Write it as a SNAPSHOT of this release, not as a claim about the present. Where this note is',
        'the published release body it does not move with reality, so a line here goes stale in hours',
        'rather than months -- measured three times in one day, once by a line stating that the',
        'previous release had no public page, which its own author then published.'
    ) -join "`n     "
    NoEntries      = '(no entries found -- fill in by hand)'
    Unknown        = '(fill in)'
}
$override = Get-SeamValue -Name 'Get-InternalNoteWording' -Default @{}
if ($override) { foreach ($k in $override.Keys) { $w[$k] = $override[$k] } }

$devRel = "releases/development/$notesDir/$verNum.md"
$intRel = "releases/internal/$notesDir/$verNum.md"
$devFile = Join-Path $RepoRoot ($devRel -replace '/', '\')
$intFile = Join-Path $RepoRoot ($intRel -replace '/', '\')

# --- Refuse where nothing sensible can be done ----------------------------------------------------
# The developer notes are the INPUT: without them there is no title to carry over and no date/type to
# copy. So this is a hard precondition rather than a precaution -- cut the release first.
if (-not (Test-Path -LiteralPath $devFile -PathType Leaf)) {
    Write-Error ("Developer notes not found: $devRel`n" +
                 "Cut the release first with scripts/release/cut-release.ps1, or check the version.")
    exit 1
}
if ((Test-Path -LiteralPath $intFile) -and -not $Force) {
    Write-Error "$intRel already exists. Use -Force to overwrite it (you lose the text you filled in)."
    exit 1
}

# --- Read the developer notes ---------------------------------------------------------------------
$dev = [System.IO.File]::ReadAllText($devFile, [System.Text.Encoding]::UTF8)

function Get-MetaLine {
    param([string]$Text, [string]$Label)
    $m = [regex]::Match($Text, "(?m)^\*\*${Label}:\*\*\s*(.+?)\s*$")
    if ($m.Success) { return $m.Groups[1].Value }
    return ''
}

# Read against the label release-lib.ps1 actually writes ('**Date:**' / '**Type:**'). A repo whose notes
# use different labels gets the '(fill in)' fallback and a warning rather than a silently blank line.
$date = Get-MetaLine -Text $dev -Label 'Date'
$typeLabel = Get-MetaLine -Text $dev -Label 'Type'
if (-not $date) {
    Write-Warning "No '**Date:**' line in $devRel -- fill in the date by hand."
    $date = $w.Unknown
}
if (-not $typeLabel) {
    Write-Warning "No '**Type:**' line in $devRel -- fill in the type by hand."
    $typeLabel = $w.Unknown
}

# --- Carry over the entry titles, TIER 1 AND UP ----------------------------------------------------
# The headings in the developer notes carry the compact changelog shape:
#   #NN <midDot> title <midDot> type <midDot> date            (the #NN part is optional)
#
# AN ENTRY IS RECOGNISED BY THAT SHAPE, NOT BY ITS HEADING LEVEL, and that is a fix rather than a
# refinement. The level moved when the notes gained tier sections: entries used to be H3 under H2
# categories, and are now H4 under H3 categories under H2 tiers. A level-based match would have silently
# swapped what it collected -- reading the CATEGORY headings ('Features', 'Fixes') as entry titles and
# putting those four words in a document written for colleagues. The metadata triple is what an entry has
# and a category heading never does, so that is what is matched.
#
# ONLY TIER 1 AND ABOVE REACH THIS DOCUMENT. The ladder is cumulative: tier 2 is what a consumer notices
# and therefore also something a colleague should hear about, so it belongs here as well as in the
# highlights. Tier 0 is repo-internal by definition -- it is in the developer notes, which is where the
# record belongs, and putting it here would rebuild exactly the document this tier exists to avoid.
#
# NOTES WITH NO TIER HEADINGS AT ALL take everything, which is the repo-without-a-tier-split case: there
# is no tier information to filter on, so filtering would empty the document rather than focus it.
$midDot = [char]0x00B7
$bullets = New-Object System.Collections.Generic.List[string]

$hasTierHeadings = [regex]::IsMatch($dev, '(?m)^##\s+Tier\s+\d+\b')
$currentTier = $null
$skippedTier0 = 0

foreach ($line in ($dev -split "`r?`n")) {
    $tierMatch = [regex]::Match($line, '^##\s+Tier\s+(\d+)\b')
    if ($tierMatch.Success) { $currentTier = [int]$tierMatch.Groups[1].Value; continue }

    $hm = [regex]::Match($line, '^#{3,6}\s+(.+?)\s*$')
    if (-not $hm.Success) { continue }
    $head = $hm.Groups[1].Value.Trim()

    $parts = @($head -split "\s*$midDot\s*")
    # Fewer than three fields is a category heading (or any other heading), not an entry.
    if ($parts.Count -lt 3) { continue }

    if ($hasTierHeadings -and ($null -eq $currentTier -or $currentTier -lt 1)) {
        if ($currentTier -eq 0) { $skippedTier0++ }
        continue
    }

    $type = $parts[$parts.Count - 2].Trim()
    $startIdx = if ($parts[0] -match '^#\d+$') { 1 } else { 0 }
    $endIdx = $parts.Count - 3
    # The title itself may contain a middot, so join the range back rather than taking $parts[1].
    $title = if ($endIdx -ge $startIdx) { (@($parts[$startIdx..$endIdx]) -join " $midDot ").Trim() } else { $head }

    if (-not $title) { continue }
    if ($type) { $bullets.Add("- [$type] $title") } else { $bullets.Add("- $title") }
}

if ($bullets.Count -eq 0) {
    # Distinguished on purpose: "this release was all repo-internal" is a different situation from "the
    # notes did not parse", and the second is a defect while the first is a release that legitimately has
    # little to say to a colleague.
    if ($skippedTier0 -gt 0) {
        Write-Warning "Every entry in $devRel is tier 0 ($skippedTier0 of them) -- nothing in this release reaches beyond this repo's own developers, so the list is empty. Write the note from what you know, or reconsider whether those tiers are right."
    } else {
        Write-Warning "No entry titles found in $devRel -- the skeleton gets an empty list."
    }
    $bullets.Add("- $($w.NoEntries)")
}

# --- Write the skeleton ---------------------------------------------------------------------------
$nl = "`r`n"
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

$skeleton =
    # Blank line after the H1, matching what release-lib.ps1 writes for the other two tiers -- three
    # documents of one release sitting side by side should not differ in shape, or the difference becomes
    # something a later reader "fixes" in the wrong place. It is also what markdown linters expect.
    "# $($w.Title) v$verNum$nl$nl" +
    "**Date:** $date$nl" +
    "**Type:** $typeLabel$nl" +
    "**$($w.AudienceLabel):** $($w.Audience)$nl" +
    $nl +
    "<!-- $($w.SkeletonNote)$nl" +
    "     Source: $devRel -->$nl" +
    $nl +
    "## $($w.SectionChanged)$nl" +
    $nl +
    ($bullets -join $nl) + $nl +
    $nl +
    "## $($w.SectionValue)$nl" +
    $nl +
    "<!-- $($w.HintValue) -->$nl" +
    $nl +
    "## $($w.SectionOpen)$nl" +
    $nl +
    "<!-- $($w.HintOpen) -->$nl"

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $intFile) | Out-Null
[System.IO.File]::WriteAllText($intFile, $skeleton, $Utf8NoBom)

# --- Point the changelog's release block at this note ---------------------------------------------
# The cut wrote the DEVELOPER link, because that is the only one that exists while it runs: it commits
# and tags in one motion, and this note is written afterwards. So the moment the note exists is the
# moment the link can be corrected -- here, in the same change that adds the file, so the two cannot
# disagree. Doing it at cut time would have put a dead relative link inside an immutable tag.
#
# Best-effort by design: a release that has already succeeded must not be reported as failed over a
# link. Set-ReleaseInternalNoteLink returns the content untouched when it finds nothing to change, and
# it is idempotent, so a second run is harmless.
$changelogFile = Join-Path $RepoRoot 'CHANGELOG.md'
$changelogTouched = $false
if (Test-Path -LiteralPath $changelogFile -PathType Leaf) {
    $clBefore = [System.IO.File]::ReadAllText($changelogFile, [System.Text.Encoding]::UTF8)
    $clAfter = Set-ReleaseInternalNoteLink -Content $clBefore -Version $verNum `
        -InternalRelPath $intRel -DevRelPath $devRel
    if ($clAfter -ne $clBefore) {
        [System.IO.File]::WriteAllText($changelogFile, $clAfter, $Utf8NoBom)
        $changelogTouched = $true
    }
}

Write-Host ""
Write-Host "read    :  $devRel  ($($bullets.Count) entry title(s))"
Write-Host "created :  $intRel  (skeleton -- edit it now)"
if ($changelogTouched) {
    Write-Host "updated :  CHANGELOG.md  (the release block now points at this note)"
} else {
    Write-Host "skipped :  CHANGELOG.md  (no release block for v$verNum with a notes line to repoint -- nothing changed)"
}
Write-Host ""
Write-Host "Step 1 -- fill in the note (the three headings stay):"
Write-Host "  code $intRel"
Write-Host ""
# Via a branch + PR, NOT appended to the release commit. cut-release.ps1 has already committed and
# tagged by the time this script can run (it needs the developer notes as input), so this file is a
# separate change -- and a hand-written document is exactly the kind that belongs in a reviewed PR.
Write-Host "Step 2 -- ship it like any other change (the release commit is already tagged):"
Write-Host "  the new-branch skill, then open-pr / ship-pr"
Write-Host ""
