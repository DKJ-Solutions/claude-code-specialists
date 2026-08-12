<#
Folds one or more changelog entry files into CHANGELOG.md's flat list of changes, and then clears them.

WHERE THE ENTRY COMES FROM, AND WHY THAT IS TWO PLACES (Dave, August 6, 2026). A branch now carries its
working files in branch/: branch-changelog.md (the entry) and branch-progress.md (the step list). Entries
written before that split are a <branch-name>.md in the repo ROOT, and every consumer with a branch in
flight has one right now -- they receive these scripts through a plugin update rather than by choosing to.
Both forms are discovered, in both modes: "recognise both, write one".

AND THE TWO ARE CLEARED DIFFERENTLY, which is the one real asymmetry. A root entry is named after its
branch, so once folded it is deleted. branch/branch-changelog.md is a FIXED path the next branch will use,
so it is REWRITTEN to its empty state -- together with branch-progress.md, whose ticked-off steps would
otherwise greet the next branch as somebody else's work. The reset opens with an H1, which is also what
makes it impossible to fold twice.

THERE ARE NO SECTIONS ANY MORE (Dave, August 5, 2026). CHANGELOG.md used to carry one
'## Tier N - Pull Requests' section per tier, and the fold's first job was to pick one from a repo-owned
map. The document is a FLAT RANKED LIST now: everything above the first '## ' heading is the intro, and
from there down every '## ' IS a change. So the boundary this script inserts against is derived
STRUCTURALLY instead of read from a configured heading -- which retires Get-ChangelogTierHeadings, the
legacy single-section Get-ChangelogHeading (issue #178) and the '## Pull Requests' fallback in one move.
There is no heading left to name, so there is no heading left to get wrong: the whole class of failure
the old "could not find the heading -- stopping" path existed for cannot occur.

WHERE IN that list is decided by the entry's TIER first and its SIGNIFICANCE SCORE second (issue #467),
and this is the only moment either can be: the cut EMPTIES the pending list, and the release documents
read what is left in document order without sorting it. So the order this script leaves behind is the
order the notes and the consumer document inherits -- which is what makes it reproducible across two moments days
apart with nothing re-estimated in between. Furthest reach at the top, highest score within a tier; an
equal rank keeps the NEWER entry above its equals, which is exactly what the fold did before ranking
existed. That ordering is what the three section headings used to communicate visually, kept as an
ordering rather than as structure. INSERT-ONLY, NEVER A RE-SORT, deliberately: this commit lands directly
on main, so a bug must be able to misplace at most the one entry being folded rather than scramble a list
it did not write.

Both facts come from the entry's IMPACT TABLE -- one row per tier, the row's second column its
significance. The highest row is the reach; that row's score is the position. An entry with no table falls
back to the older 'Tier: N' line and folds unranked, which is correct rather than tolerated: every entry
written before this format has no score to rank by.

NOTHING IS CONSUMED ANY MORE, AND THAT IS A REVERSAL RATHER THAN AN OMISSION. While the sections existed,
the HEADING stated the tier, so an entry restating it below was the same fact in two places -- the drift
shape this repo has paid for three times -- and this script therefore stripped both the 'Tier: N' line and
an unscored impact table. With the sections gone there is nothing above the entry stating anything, so the
entry is the only carrier and both now SURVIVE the fold:

  * the impact table is folded in whole, scored or not. '### Who is this for' is a named section of every
    entry, and a section with its answer cut out is worse than a scaffold row: the reader cannot tell
    "nobody was asked" from "somebody deleted it".
  * the legacy 'Tier: N' line is KEPT. Removing it now would leave the folded entry declaring no reach at
    all, so every downstream reader would read it back as tier 0 -- silent, correct-looking, and wrong in
    the one direction that empties a release document.

A missing score is reported and folded anyway: refusing the fold of an already-merged branch is the
silent half-state this repo has measured, and cut-release.ps1 is the refusal point instead. A malformed
table DOES stop the run -- it decides where the entry lands, and getting that wrong is a move on main.

In fold-all mode (no -Branch) only files that are actually changelog entries are folded: an entry opens
with its own heading -- an H2 since this change, an H3 before it -- so repo-root meta docs
(CONTRIBUTING.md, SECURITY.md, ...) that open with an H1 are left untouched. -Branch mode targets exactly
the named entry and is unaffected.

What the fold adds is exactly what does not exist until the merge, and it is now ONE line rather than two
places: the closing '[PR #NN](url) <midDot> merged <date>'. The heading is left as its author wrote it --
the fold used to prepend '#NN <midDot> ' to the title as well, and that is gone (Dave, August 5, 2026).
Nothing is lost by it: the number is still in the entry, on that closing line, where the url makes it
clickable rather than merely printed. What the heading gains is being readable as a sentence, and it is the
one line every reader of the changelog and of all three release documents scans.

The number, url and merge timestamp are fetched via one `gh pr list` (on -Branch, or in fold-all mode
derived from the file name) -- which can only happen after opening the PR. If no PR is found (e.g. a manual
merge without a PR), no closing line is added and the heading is untouched either way.

AN ENTRY FILE WRITTEN BEFORE THIS FORMAT IS PROMOTED, NOT PASSED THROUGH. Its H3 heading becomes an H2 as
it lands, because the document it lands in is a flat list of H2s -- and an H3 in that list is not an entry
boundary to any reader of it, so it would be swallowed into the block above it and inherit that block's
PR link. The case is not hypothetical: a branch parked before this change carries exactly such a file and
will be folded after it. Only the heading's LEVEL changes; its fields (the title, the type, and a date
where one was scaffolded in) are left exactly as written.

THE DATE MOVED HERE FROM THE SCAFFOLD ON AUGUST 5, 2026 (Dave), and both halves of that were
deliberate. It is the FOLD's to write, because new-branch.ps1 runs when the branch is created
and could only ever record the branch's birth date -- wrong by however many days the branch lived, in
the one document whose subject is when things landed. And it goes at the BOTTOM, because the heading
carries what the author knows (title, type) while this line carries what only the merge knows.

Nothing here parses that date back out, and neither does anything downstream: release-lib reads the
TYPE off the heading by matching the known branch types rather than by counting fields from the end,
so a heading with or without a trailing date is read the same way. That was a required part of this
change -- the old parse took the second-to-last field, which would have silently made every entry's
type 'Other' the moment the date left.

Usage:
  .\scripts\release\fold-changelog-entry.ps1 -Branch feat/new-plugin
  .\scripts\release\fold-changelog-entry.ps1              # folds all present entry files
  .\scripts\release\fold-changelog-entry.ps1 -RepoRoot C:\path\to\worktree   # explicit root (#101)
  .\scripts\release\fold-changelog-entry.ps1 -Branch feat/x -Push            # fold, commit and push

Run this on main, right after merging a branch.

COMMITTING IS OPT-IN (-Commit, or -Push which implies it). Without either, the fold is left on disk for
you to commit -- the behaviour this script always had. With them it makes the commit itself, naming
CHANGELOG.md and the entry files as the commit's pathspec so nothing else can be swept in: this commit
lands directly on the main branch under one of the two named exceptions to "never commit directly", and
an exception only stays safe while it stays the size it was granted at.
#>

param(
    [string]$Branch,
    # #101: explicit override of the repo root, for a consumer that runs the fold from a
    # temporary/detached worktree (e.g. a ship-pr.ps1 that checks out main elsewhere) and wants to
    # write to that tree instead of whatever CLAUDE_PROJECT_DIR/git-root would resolve to. Default
    # (omitted): unchanged behavior below.
    [string]$RepoRoot,
    # Commit the fold. OFF BY DEFAULT, deliberately: this commit lands directly on the main branch,
    # which is one of the two named exceptions to "never commit directly" -- so it has to be asked for,
    # exactly like teardown.ps1 requires -Apply before it removes anything.
    #
    # The scope limit the exception grants is enforced by git rather than by care: the commit names its
    # paths, so CHANGELOG.md and the entry files this run folded are the only things that can end up in
    # it, whatever else is lying around in the tree or already staged.
    [switch]$Commit,
    # Push the fold commit. Implies -Commit. Separate because a fold commit sitting unpushed on main is
    # its own silent half-state -- the repo looks folded locally and unfolded to everyone else -- and
    # that is precisely the class of half-finished state this repo keeps finding the expensive way.
    [switch]$Push
)

$ErrorActionPreference = "Stop"

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Repo root -- dual context: if a consumer runs the shared plugin mirror, CLAUDE_PROJECT_DIR
# supplies its repo root; in the workshop root (or outside a session) it falls back to the git
# root. This way the SAME file works in both locations, and the root copy and the plugin mirror
# stay byte-identical (guarded by the shared-scripts drift lint).
# -RepoRoot (#101), when supplied, wins over both -- see the param comment above. Note: PowerShell
# variable names are case-insensitive, so $RepoRoot (the param) and $repoRoot (used below) are the
# same variable; the guard below only computes the dual-context fallback when it is still empty.
if (-not $repoRoot) {
    $repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }
}
Set-Location $repoRoot

# Pre-flight (#86): fold relies on scripts\repo-config.ps1 in the consumer's repo root. If that is
# missing -- typically on a clean consumer -- stop with a clear pointer instead of a raw
# dot-source error on the . (dot-source) line below.
$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Error "fold-changelog cannot run -- missing repo-owned file: $configPath (Get-RepoName / Get-RepoBlobUrl / Get-LintScript). This file is repo-specific and belongs in the consumer's repo root. Create it (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward."
    exit 1
}

# Repo name from the repo root's local repo-config (single source), no longer hardcoded.
# Deliberately from $repoRoot and not $PSScriptRoot: from the plugin mirror, $PSScriptRoot points
# to the plugin cache, while repo-config always lives in the consumer's repo root.
. (Join-Path $repoRoot 'scripts\repo-config.ps1')
$repo = Get-RepoName

# Pre-flight (#86): an unfilled scaffold (repo-config still at VUL-IN) would otherwise only fail
# further down with an unclear gh error. Stop here with a clear pointer.
if ($repo -match 'VUL-IN') {
    Write-Error "fold-changelog cannot run -- scripts\repo-config.ps1 still contains VUL-IN placeholders. Fill in Get-RepoName with this repo's value and run again."
    exit 1
}

# The 'Plugins:' detection: Get-TouchedPlugins plus the plugin roots it reads (#103, Victor #3).
# $PSScriptRoot-relative, like the two libs below and for the same reason -- this lib travels in the
# same mirror payload as this script, so it resolves from the workshop root, a consumer's plugin cache
# and the mirror tree alike.
#
# IT USED TO LOOK release-lib.ps1 UP UNDER $repoRoot, guarded, and the comment here justified that by
# saying release-lib "is deliberately NOT mirrored to the plugin". That stopped being true on August 8,
# 2026, when the lib was registered as a mirror pair -- so a consumer running the fold had a perfectly
# good copy sitting beside the script and looked for it in their own scripts\lib\ instead, where it is
# not. The outcome was right by accident and for the wrong reason, which is the shape that survives a
# review.
#
# THE DEPENDENCY IS THE SMALL LIB, NOT release-lib. Get-TouchedPlugins moved down into plugin-tree-lib
# on August 9, 2026 precisely so this dot-source could be the dependency-free one: release-lib pulls
# entry-scaffold-lib in behind it, three thousand lines, and this script runs immediately after a merge
# and directly on the trunk.
#
# What decides the 'Plugins:' line is the marketplace, not the presence of a lib: a repo that declares
# no plugins yields no roots and therefore no line. That is an answer rather than a degradation, so the
# $canDetectPlugins gate is gone along with the reason it existed for.
. (Join-Path $PSScriptRoot '..\lib\plugin-tree-lib.ps1')

# Shared native-capture helper (#114 item 1). $PSScriptRoot-relative, not $repoRoot: like
# check-report-lib.ps1 this lib is not repo-owned -- it travels with the SAME plugin/mirror payload
# as this script (registered in scripts\lib\shared-scripts-lib.ps1), so it resolves from the
# workshop root, a consumer's plugin cache, or the plugin mirror tree alike.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# The entry format: the heading levels this script recognises and normalises to, the impact table it reads
# the reach and the significance from, and the ranked insert offset it places the entry at.
# $PSScriptRoot-relative for the same reason as the lib above -- it travels with this script, so the writer
# (new-branch.ps1), the validator (open-pr.ps1) and this reader always hold the same version of
# the format.
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')

# BOM-less UTF8 -- Set-Content -Encoding UTF8 always adds a BOM in Windows PowerShell 5.1,
# and the rest of the repo (CHANGELOG.md etc.) has no BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Test-IsChangelogEntryFile {
    # A changelog entry file (created by new-branch.ps1) always opens with its own heading, and
    # since August 5, 2026 that heading is an H2 ('## <title>') rather than the H3 it was before. Repo-root
    # meta docs (CONTRIBUTING.md, SECURITY.md, a future CODE_OF_CONDUCT.md, ...) open with an H1 ('# ...').
    # Fold-all mode keys off this structural signature so it only ever folds a genuine entry, never
    # whatever other *.md happens to sit in the repo root. Deliberately independent of the branch-
    # prefix table: consumer-extended prefixes (Shopify's style/, liquid/, ...) still fold, since an
    # entry from any prefix is written in this same format. The denylist below stays as a cheap
    # first filter; this is the actual gate.
    #
    # BOTH LEVELS ARE ACCEPTED, and the range is built from the lib rather than written out, so the two
    # scripts cannot end up recognising different things. An entry file lives only on a branch, so the H3
    # shape is not distant history: a branch created before this change still carries one, and refusing to
    # recognise it would silently leave that entry unfolded in the root -- the exact half-state this repo
    # keeps rediscovering. The fold PROMOTES it to an H2 as it lands (see the loop below).
    #
    # The bound is a RANGE from the current level, not a hardcoded '{2,3}': '^#{2,3}\s' looks like it also
    # matches an H2 by prefix, but it does not -- '^##' followed by '\s' fails on '###', which is why the
    # alternation has to be spelled as a quantifier over the whole run.
    param([Parameter(Mandatory = $true)][string]$Path)
    $entryLevel  = Get-EntryHeadingLevel
    $legacyLevel = $entryLevel + 1
    $rx = '^#{' + $entryLevel + ',' + $legacyLevel + '}\s'
    foreach ($line in [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        return ($line -match $rx)
    }
    return $false
}

# THE ENTRY NOW ARRIVES IN branch/, AND THE ROOT FORM IS STILL FOLDED (Dave, August 6, 2026). Since the
# branch/ split, new-branch.ps1 writes branch/branch-changelog.md; every branch created before
# that -- here and in every consumer, who get these scripts through a plugin update rather than by
# choosing to -- carries a root <branch-name>.md instead. Recognising only the new path would leave those
# entries sitting unfolded in the root, which is precisely the silent half-state this repo keeps
# rediscovering. So both are discovered, in both modes: "recognise both, write one".
$branchFiles = Get-BranchFilePaths
$branchChangelogPath = Join-Path $repoRoot $branchFiles.Changelog
$branchChangelogFilled = (Test-Path -LiteralPath $branchChangelogPath) -and
    (Test-BranchChangelogIsFilled -Text ([System.IO.File]::ReadAllText($branchChangelogPath)))

# WHICH BRANCH THE branch/ ENTRY BELONGS TO, read from branch-progress.md's own '**Branch:**' line.
#
# This is the one thing the fixed filename genuinely costs, and the reason the branch line is in the
# document rather than only in the scaffolder's head. In fold-all mode the branch is what the PR lookup
# keys on, and it used to be recovered from the entry's file NAME (feat-x.md -> feat/x). A fixed name
# carries no branch, so 'branch-changelog' would have been read as the branch 'branch/changelog', found
# no PR, and folded the entry with neither number nor merge date -- silently, since a missing PR is a
# legitimate outcome the script already prints and moves past.
#
# READ BEFORE THE LOOP, WHICH IS ALSO BEFORE THE RESET at the end of the run: on main after the merge the
# progress file still names the branch that was just merged, which is exactly the fact needed here.
$branchFileOwner = ''
if ($branchChangelogFilled) {
    $progressFile = Join-Path $repoRoot $branchFiles.Progress
    if (Test-Path -LiteralPath $progressFile) {
        $declared = Get-BranchFileDeclaredBranch -Text ([System.IO.File]::ReadAllText($progressFile))
        if ($declared -and $declared -ne (Get-BranchTrunkName)) { $branchFileOwner = $declared }
    }
}

if ($Branch) {
    # Explicit target: the caller named the branch, so trust it. The legacy root file is named after that
    # branch; the branch/ file is not named after anything, so it qualifies on being filled.
    $entryFiles = @()
    if ($branchChangelogFilled) { $entryFiles += $branchFiles.Changelog }
    $legacyName = ($Branch -replace '/', '-') + ".md"
    if (Test-Path -LiteralPath (Join-Path $repoRoot $legacyName)) { $entryFiles += $legacyName }
}
else {
    # Fold-all: never fold a file that is not an actual changelog entry (structural gate above).
    $reserved = @("CHANGELOG.md", "CLAUDE.md", "README.md")
    $entryFiles = @()
    if ($branchChangelogFilled) { $entryFiles += $branchFiles.Changelog }
    $entryFiles += @(Get-ChildItem -Path $repoRoot -Filter "*.md" -File |
        Where-Object { $reserved -notcontains $_.Name } |
        Where-Object { Test-IsChangelogEntryFile -Path $_.FullName } |
        Select-Object -ExpandProperty Name)
}

if ($entryFiles.Count -eq 0) {
    Write-Host "No entry files found to fold." -ForegroundColor Yellow
    exit 0
}

$changelogPath = Join-Path $repoRoot "CHANGELOG.md"

# --- The document has to BE a flat list before anything is inserted into it (inbound #561) ---------
#
# THE ASSUMPTION THIS SCRIPT MAKES IS THAT EVERY H2 BELOW THE INTRO IS ONE CHANGE, and until August 10,
# 2026 it made that assumption without ever checking it. cut-release.ps1 makes the same one and has
# refused over it by name since August 5 -- the two came apart in the direction that loses the least
# noise and the most trust. Measured in a consumer on 2026-08-09, one day after they adopted the entry
# convention:
#
#   Folded and reset: branch/branch-changelog.md (tier 1, significance 3 -- placed above 2 existing entries)
#   CHANGELOG.md updated.
#
# Exit 0, no warning. Their "2 existing entries" were two SECTION headings ('## Pull Requests',
# '## Releases'), which sit at exactly the level an entry now occupies -- so the insert landed above the
# first of them, outside the section they keep their entries in. The only way to see it is to open the
# file afterwards, which is precisely what nobody does after a green fold.
#
# SO IT REFUSES, AND IT REFUSES HERE: in the pre-pass, before the first entry is written and before any
# entry file is reset or deleted. A fold-all run writes one entry at a time, so finding this on the third
# file would leave the first two folded into the wrong place with their sources already gone.
#
# NO -Force, AND THAT IS DELIBERATE. Every other refusal in this workflow that overrules a judgement about
# content has an escape valve; this one overrules a FACT about the document, and there is no state in which
# writing into the wrong section is what the caller wanted. The cut has no valve for it either.
#
# WHAT IT COSTS, SAID OUT LOUD RATHER THAN GLOSSED. This script runs after a merge, so a refusal leaves an
# unfolded entry on the trunk -- the silent half-state this repo has measured, and the reason a missing
# significance score is warned about here instead of refused. The difference is that a missing score still
# produces a CORRECT write, while this cannot: the choice is between a state the caller is told about in
# full and a wrong write nothing reports. So the message names the file that is still waiting and both ways
# out of it, which is what turns a half-state into a next step.
#
# READ DEFENSIVELY, because this is now the FIRST read of the document rather than the third. An absent or
# empty CHANGELOG.md used to reach the loop below and fail there; '' keeps that unchanged -- the check finds
# nothing in an empty document, which is correct (there is no block to misread), and whatever the loop did
# about a missing file it still does.
$changelogRaw = ''
if (Test-Path -LiteralPath $changelogPath) {
    $changelogRaw = [string](Get-Content -Path $changelogPath -Raw -Encoding UTF8)
}
$preFlat = Get-PreFlatChangelogRefusal -Content $changelogRaw `
    -Consequence 'this entry would be inserted ABOVE the first of them -- outside the section you keep your entries in, which is only visible to somebody who opens the file afterwards'
if ($preFlat) {
    Write-Host "Nothing was folded -- CHANGELOG.md is not the flat list this script writes into:" -ForegroundColor Red
    Write-Host "  $preFlat" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Your entry is untouched: $($entryFiles -join ', '). Either migrate CHANGELOG.md as described above and run this again, or paste the entry under your own section by hand and reset the file." -ForegroundColor Yellow
    exit 1
}

# Does this repo rank its entries at all (issue #467)? Switchable off via Get-EntrySignificanceEnabled --
# see Test-EntrySignificanceActive. Resolved once here rather than per entry.
#
# IT NO LONGER GOVERNS THE ORDERING, only what is said about it, and that is deliberate. The tier decides
# the position first, and with the sections gone that ordering IS what the three headings used to say -- so
# it cannot be optional without the document losing the distinction it was restructured to keep. The score
# is read unconditionally too (an absent one is simply 0, which sorts to the bottom of its tier). What this
# flag still buys is the WARNING below: a repo that has switched ranking off should not be told off for not
# ranking.
$significanceActive = Test-EntrySignificanceActive

# --- Pre-pass: every entry's impact is resolved and checked BEFORE anything is folded --------------
# A fold-all run writes one entry at a time, so a problem found on the third file would leave the first
# two already folded and their source files deleted -- a half-state that has to be unpicked by hand on
# main. The failure this catches is cheap to see up front and impossible to undo afterwards, so it is
# checked here rather than in the loop: an impact table that does not parse.
#
# THE SECOND PRE-PASS FAILURE IS GONE WITH THE SECTIONS. "This repo declares no changelog section for
# tier N" was the other refusal here, and it existed because the tier had to be mapped to a heading that
# might not be there. A flat list has no such mapping, so a tier the repo happens not to use is no longer
# an error state -- it is simply a position in the order.
#
# Nothing else moves to a pre-pass. The gh lookup stays in the loop where it always was: it depends on
# state this pass cannot know (the PR, and a changelog the previous iteration has already rewritten).
$tierByFile = @{}
$tierProblems = @()
foreach ($file in $entryFiles) {
    $filePath = Join-Path $repoRoot $file
    if (-not (Test-Path $filePath)) { continue }
    $raw = Get-Content -Path $filePath -Raw -Encoding UTF8
    # One read answers both halves of the position: the reach (the highest tier a row claims) and the weight
    # at that reach (that row's significance). Resolve-EntryImpact falls back to the older 'Tier: N' line
    # when the entry carries no table, so an entry written before this format still ranks correctly.
    $impact = Resolve-EntryImpact -EntryText $raw
    $tier = [pscustomobject]@{ Tier = $impact.Tier; Declared = $impact.Declared }
    $impactErrors = @(@($impact.Errors) | Where-Object { $_ })
    if ($impactErrors.Count -gt 0) {
        # A tier that cannot be honoured stops the whole run, exactly as a malformed 'Tier:' line did: it
        # decides where in the list the entry goes, and guessing that wrong is a move on main.
        foreach ($problem in $impactErrors) { $tierProblems += "  $file -- $problem" }
        continue
    }
    # The significance score that decides WHERE IN its tier this entry lands (issue #467). Read here with
    # the tier, because the position depends on both.
    #
    # DELIBERATELY NOT A $tierProblems ENTRY, unlike a malformed table. This pass refuses before anything
    # is folded, and that is right for the failure it does catch: it is decidable before the merge, and
    # open-pr.ps1 refuses over it while the branch is still the only thing affected. A missing significance
    # score is different in the one way that matters here -- refusing the FOLD of an already-merged branch
    # produces the silent half-state this repo has measured (an unfolded entry file sitting in the repo root
    # the morning after its merge, with main looking finished). So a missing score is said out loud and the
    # fold proceeds; cut-release.ps1 is the refusal point Dave chose for it, and by then the branch is long
    # gone and the fix is one edit in CHANGELOG.md.
    #
    # READ UNCONDITIONALLY, warned about only where the repo ranks -- see $significanceActive above. The
    # entry sits at its OWN tier's position in the list, so that tier's row is the one that orders it.
    $rankScore = Get-EntryImpactScore -Impact $impact -Tier $tier.Tier
    if ($significanceActive -and $tier.Tier -ge 1 -and $rankScore -le 0) {
        # 'at the bottom of its tier', and stating the position is the point: an unscored entry reads as 0,
        # which is the LOWEST rank rather than the absence of one, so it sinks below everything scored at the
        # same reach. Saying "unranked" alone would leave the author expecting it at the top.
        Write-Host "  ($file declares no significance for tier $($tier.Tier) -- folded at the bottom of tier $($tier.Tier), because an unscored entry reads as 0. The release cut will refuse until it has one.)" -ForegroundColor DarkYellow
    }
    $tierByFile[$file] = [pscustomobject]@{
        Tier      = $tier.Tier
        Declared  = $tier.Declared
        RankScore = $rankScore
    }
}
if ($tierProblems.Count -gt 0) {
    Write-Host "Nothing was folded -- these entries could not be filed:" -ForegroundColor Red
    $tierProblems | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    exit 1
}

# What this run actually folded -- the source for both the commit message and the committed pathspec.
$folded = @()

foreach ($file in $entryFiles) {
    $filePath = Join-Path $repoRoot $file
    if (-not (Test-Path $filePath)) {
        Write-Host "Entry file '$file' not found - skipped." -ForegroundColor Yellow
        continue
    }

    $entryContent = (Get-Content -Path $filePath -Raw -Encoding UTF8).TrimEnd()
    $changelogContent = Get-Content -Path $changelogPath -Raw -Encoding UTF8

    $usesCRLF = $changelogContent.Contains("`r`n")
    $nl = if ($usesCRLF) { "`r`n" } else { "`n" }
    $entryContent = ($entryContent -replace "`r`n", "`n") -replace "`n", $nl

    # THE GUIDANCE COMMENTS ARE STRIPPED HERE, AND THIS IS THE ONLY PLACE THAT DOES IT. Every field in the
    # dossier form carries an HTML comment saying what a good answer looks like -- that is the form, not the
    # author's answer, and it has no business in CHANGELOG.md or in the three release documents built from
    # it. Stripping at the fold is what makes the guidance safe to be generous with: nobody has to remember
    # to delete it, so leaving a block standing is not a defect and the scaffold gate has one less thing to
    # police.
    #
    # WIRED IN LATE, AND THE GAP WAS REAL. Remove-EntryHtmlComments was written for this caller and its own
    # header said "the fold calls this" while nothing did -- so between the guidance shipping and this line,
    # every comment block in an entry would have folded into the changelog verbatim. Found by reading the
    # fold rather than by anything failing, which is how a stripper that is never called stays invisible:
    # the output is well-formed either way, just full of form text.
    #
    # BEFORE the promote and the footer below, so the comment count cannot change what those measure.
    $entryContent = (Remove-EntryHtmlComments -EntryText $entryContent).TrimEnd()

    # THE DOCUMENT'S TAIL IS NORMALISED BEFORE ANYTHING IS MEASURED IN IT: it ends with exactly one blank
    # line, whatever it ended with before. BOTH insertion paths below need that, and only one of them used
    # to ensure it -- the one that runs when nothing is pending, which is the rarer of the two.
    #
    # WHAT IT PREVENTS. Get-ImpactInsertOffset returns the slice's LENGTH for the lowest-ranked entry -- the
    # COMMON case, since tier 0 sinks to the bottom of the list -- so the insert lands at the very end of the
    # content. On a document ending in '---' with nothing after it, that produces '---## <title>' on ONE line.
    # That is not a heading any more: '^## ' does not match it, so Split-Changelog does not see the entry, the
    # cut leaves it out of every release document, and the entry FILE has already been deleted by then. The
    # markdown stays well-formed, nothing errors, and one merged change is gone -- the failure shape this repo
    # keeps paying for.
    #
    # FOUND IN A WORKING TREE RATHER THAN IN THE HISTORY, and that is why nothing had caught it. The branch
    # behind PR #486 was handed over with CHANGELOG.md's final newline stripped by an editor, and it was
    # repaired in the pre-commit diff review -- so the commit, the PR and the fold that followed all ran on a
    # well-formed document. Which is exactly why 'git log' holds no trace of the condition and no gate ever
    # met it: the CONDITION is ordinary editing, the LOSS is what this line prevents, and the demonstration
    # that the loss follows from the condition is the regression test, not an incident.
    #
    # Idempotent, so the happy path is byte-identical: a document already ending in '---' plus one blank line
    # comes back unchanged. It also caps the trailing blanks a hand-edit can leave behind, which is the same
    # accumulation Split-Changelog strips from the head.
    #
    # THE TRADEOFF, SO IT IS A CHOICE RATHER THAN AN OVERSIGHT: TrimEnd() takes all trailing whitespace, not
    # only line breaks, so a markdown HARD BREAK (two spaces) on the document's very last line loses those two
    # spaces. Unreachable on a machine-written tail, which always ends in '---', and it can only be a
    # hand-typed intro's closing line -- where a hard break before end-of-file has nothing to break onto.
    $changelogContent = $changelogContent.TrimEnd() + $nl + $nl

    # The pre-pass has already proved the entry's impact is usable, so this is a lookup rather than a
    # decision. NOTHING IS STRIPPED FROM THE ENTRY HERE, and that reverses what this block used to do.
    # While CHANGELOG.md had tier sections, the HEADING above an entry stated its reach, so the entry's own
    # 'Tier: N' line was the same fact twice and an unscored table was a question nobody had put. With the
    # sections gone the entry is the only carrier of both: strip the line and the entry reads back as tier 0,
    # which is how a change silently drops out of the release documents; strip the scaffold row and
    # '### Who is this for' has a heading with its answer cut out, which reads as somebody having deleted it.
    # The header at the top of this file carries the full reasoning.
    $filed = $tierByFile[$file]
    if (-not $filed.Declared) {
        # Worth saying out loud rather than absorbing. Tier 0 is the documented default and the safe
        # one, but an author who simply forgot has produced work that cannot carry a release on its own --
        # and the moment to learn that is now, not when the cut refuses.
        Write-Host "  ($file declares no tier -- filed as tier 0, which no release can be cut from on its own.)" -ForegroundColor DarkYellow
    }

    # THE ENTRY'S OWN HEADING IS BROUGHT TO THE CURRENT LEVEL, whatever level it was written at. An entry
    # file created before August 5, 2026 opens with an H3, and the document it is landing in is a flat list
    # of H2s -- an H3 in that list is not an entry boundary to any reader of it (Get-ImpactInsertOffset, the
    # release renderers, a human scanning the file), so it would be absorbed into the block above it and
    # inherit that block's PR link.
    #
    # DONE HERE RATHER THAN INSIDE THE PR BLOCK BELOW, which is where it started out. The prepend of
    # '#NN <midDot> ' only runs when gh found a PR, and an entry folded WITHOUT one -- a manual merge, or gh
    # unavailable -- would then have kept its H3 silently. Two jobs, two substitutions.
    #
    # count 1, so only the entry's OWN heading moves. A '### ' section heading inside the body ('### Who is
    # this for') has to keep its level, and a replace-all would flatten every one of them and turn one entry
    # into four.
    $entryHashes = '#' * (Get-EntryHeadingLevel)
    $legacyHeading = '(?m)^#{' + (Get-EntryHeadingLevel) + ',' + ((Get-EntryHeadingLevel) + 1) + '} '
    # An already-current heading is replaced by itself, so string inequality IS "this was promoted" -- no
    # second test of the first line, which would be a separate answer to a question already answered.
    $promoted = ([regex]$legacyHeading).Replace($entryContent, "$entryHashes ", 1)
    if ($promoted -ne $entryContent) {
        Write-Host "  ($file was written in the pre-flat entry format -- its heading is promoted to '$entryHashes ' so it is an entry boundary in the list.)" -ForegroundColor DarkYellow
    }
    $entryContent = $promoted

    # THE HEADING IS JUST THE TITLE (Dave, August 5, 2026). The fold adds the PR link and the merge date as
    # the entry's closing line and touches the heading no further -- it used to also prepend '#NN <midDot> '
    # to the title, and that prepend is gone.
    #
    # NOTHING IS LOST, WHICH IS WHY IT COULD GO: the number is still in the entry, on the closing
    # '[PR #NN](url) <midDot> merged <date>' line, where the url makes it clickable rather than merely
    # printed. What the heading gains is being readable as a sentence -- it is the one line every reader of
    # the changelog and of all three release documents scans, and it now says what changed and nothing else.
    # The two facts the merge owns already had a home together at the end of the block; the number was the
    # last one still stated twice.
    #
    # WHAT HAD TO MOVE WITH IT, because the number was load-bearing in one reader: new-internal-note.ps1
    # recognised an entry in the development notes by counting middot fields in its heading. That was
    # already broken by the flat format -- the type and date had left the heading, so every real entry fell
    # under its threshold and the one heading that still matched was a QUOTED example inside a fenced block,
    # which it turned into the note's only bullet. It now reads the format's own sections instead.
    #
    # The PR number only exists after the merge; we fetch it via the branch -- from -Branch, or in fold-all
    # mode derived from the file name (<prefix>-<rest>.md -> <prefix>/<rest>).
    $midDot = [char]0x00B7
    $branchForPr = $Branch
    if (-not $branchForPr) {
        if ($file -eq $branchFiles.Changelog) {
            # From branch-progress.md's branch line -- see $branchFileOwner above for why the file name
            # cannot answer this any more.
            $branchForPr = $branchFileOwner
            if (-not $branchForPr) {
                Write-Host "  $($branchFiles.Progress) names no branch, so there is nothing to look a PR up by. Pass -Branch to get the number and merge date." -ForegroundColor Yellow
            }
        } else {
            $base = [System.IO.Path]::GetFileNameWithoutExtension($file)
            $branchForPr = $base -replace '^([^-]+)-', '$1/'
        }
    }
    # gh can write messages to stderr; Invoke-NativeCapture runs it under EAP=Continue so that
    # cannot become a terminating error before the graceful exit-code handling below (#107).
    # -DiscardStderr (2>$null) keeps stderr out of the captured JSON. 'files' is simply included in
    # --json (Victor #4, #103) -- gh pr list supplies that field just as well as gh pr view, so the
    # second gh call (previously gh pr view --json files) has been dropped: one PR lookup suffices
    # for both the number/url and the touched files.
    # 'mergedAt' joined the field list on August 5, 2026 for the merge date below -- at no cost, since
    # this call already happens and gh returns whatever fields are asked for in one roundtrip.
    #
    # SKIPPED ENTIRELY WITHOUT A BRANCH NAME. 'gh pr list --head ""' is not a no-op -- it drops the head
    # filter and returns the repo's most recent PR, whichever branch that came from -- so an entry whose
    # branch could not be determined would be stamped with a stranger's PR number, url and merge date. A
    # wrong reference in the changelog is worse than none, and none is a state this script already handles.
    if ($branchForPr) {
        $prList = Invoke-NativeCapture -FilePath 'gh' -Arguments @('pr', 'list', '--head', $branchForPr, '--state', 'all', '--json', 'number,url,files,mergedAt', '--limit', '1', '--repo', $repo) -DiscardStderr
        $ghCode = $prList.ExitCode
        $prJson = $prList.Output
        if ($ghCode -ne 0) { Write-Host "  (gh pr list returned exit code $ghCode -- PR-number enrichment skipped; run gh manually for the reason.)" -ForegroundColor DarkYellow }
        $prs = if ($ghCode -eq 0 -and $prJson) { @($prJson | ConvertFrom-Json) } else { @() }
    } else {
        $prs = @()
    }
    if ($prs.Count -ge 1) {
        $num = $prs[0].number
        # The heading is left exactly as its author wrote it. $entryHashes is still what the promotion above
        # uses, so a pre-format entry file still arrives at the right level.

        # Deriving touched plugins from the PR files (automation-first): a file under a plugin root
        # this repo's marketplace declares becomes a 'Plugins:' line, which the release notes read
        # (Get-EntryPlugins). It fed the per-plugin CHANGELOGs too until those were retired on
        # August 8, 2026 -- the line outlived them. The detection itself lives in the pure
        # Get-TouchedPlugins (plugin-tree-lib.ps1, #103 -- release-lib.ps1 until August 9, 2026, and
        # this script no longer loads that file at all); 'files' already came along with the gh pr
        # list call above, so no separate gh roundtrip is needed.
        #
        # No guard around it any more: a repo that declares no plugins yields no roots and therefore no
        # line, so the empty case answers itself instead of being tested for here.
        $paths = @($prs[0].files | ForEach-Object { $_.path })
        $touched = @(Get-TouchedPlugins -Files $paths -PluginRoots (Get-RepoPluginRoots -RepoRoot $repoRoot))
        if ($touched.Count -gt 0) {
            $entryContent = $entryContent.TrimEnd() + "$nl$nl" + ('Plugins: ' + ($touched -join ', '))
        }

        # THE CLOSING LINE CARRIES BOTH FACTS THE MERGE OWNS: which PR this was, and when it landed
        # (Dave, August 5, 2026). Built by Format-EntryFoldFooter in entry-scaffold-lib.ps1 -- the lib
        # that owns the entry FORMAT, so the one place that writes this line is the one place a test can
        # read it. Its header carries the reasoning for reading mergedAt rather than the clock; the clock
        # is passed in as the fallback because a pure function may not have one of its own.
        $entryContent = $entryContent.TrimEnd() + "$nl$nl" + (Format-EntryFoldFooter `
            -Number $num -Url $prs[0].url -MergedAt ([string]$prs[0].mergedAt) `
            -FallbackDate (Get-Date -Format 'yyyy-MM-dd'))
    }
    else {
        # No PR: no number, no url -- and no merge date either, deliberately. There is nothing to read a
        # landing date off, and inventing one from the clock would put a fact in the changelog that
        # nothing backs. An entry folded this way simply carries no closing line; its heading is the same
        # heading it would have had with one, since the fold no longer writes into the heading at all.
        Write-Host "  No PR found for '$branchForPr' - entry without PR number/url or merge date." -ForegroundColor Yellow
    }

    # WHERE THE LIST BEGINS, derived structurally rather than read from a configured heading. Everything
    # above the FIRST entry heading is the document's intro; from there down is the ranked list. That one
    # regex replaces the seam, the '## Pull Requests' fallback and the "could not find the heading --
    # stopping" refusal that used to sit here: there is no name to look up, so there is nothing to mismatch.
    #
    # It cannot mistake a section heading of the entry FORMAT for the list, because those are one level
    # deeper: '^## ' does not match '### Who is this for' -- after '##' comes '#', not a space.
    $listMatch = ([regex]('(?m)^' + $entryHashes + ' ')).Match($changelogContent)
    if ($listMatch.Success) {
        $listStart = $listMatch.Index
    }
    else {
        # Nothing pending yet: the whole file is intro, so this entry opens the list. The blank line the
        # heading needs is already there -- an intro whose last line has none would get the heading glued to
        # it, which markdown renders as one paragraph and no heading at all. That used to be ensured HERE,
        # for this path only; the tail normalisation above now does it for both, which is the whole point of
        # having moved it.
        $listStart = $changelogContent.Length
    }

    # WHERE IN the list, decided by the tier and then the significance score (issue #467). The fold is the
    # only moment at which CHANGELOG.md's pending list can be ordered, because the cut empties it: whatever
    # order is left here IS the order the release documents inherit, since they read the list in document
    # order and sort nothing. That is what makes the ordering reproducible across the fold and the cut
    # without either re-estimating a score.
    #
    # THE SLICE, AND WHY THE OFFSET IS RELATIVE TO IT: Get-ImpactInsertOffset only ever returns an entry
    # boundary or the slice's end, so adding $listStart back cannot land mid-entry. The insert itself is
    # unchanged -- '<entry>\n\n---\n\n' is correct before any entry heading and at the list's end alike,
    # because every folded entry is followed by its own separator AND the tail normalisation above has
    # guaranteed the content ends on a line break. Landing at the end is where that guarantee is load-bearing.
    $listText = $changelogContent.Substring($listStart)
    $insertPos = $listStart + (Get-ImpactInsertOffset -SectionText $listText -Score $filed.RankScore -Tier $filed.Tier)

    $entryBlock = "$entryContent$nl$nl---$nl$nl"
    $changelogContent = $changelogContent.Substring(0, $insertPos) + $entryBlock + $changelogContent.Substring($insertPos)

    Write-Utf8NoBom -Path $changelogPath -Content $changelogContent

    # DISPOSAL DIFFERS BY WHERE THE ENTRY LIVED, and that is the one real asymmetry the split introduces.
    # A legacy root entry is named after its branch, so once folded it has no reason to exist and is
    # deleted, exactly as before. branch/branch-changelog.md is a FIXED path that every future branch will
    # use, so deleting it would leave the trunk missing a file the next `git checkout -b` expects -- and
    # would quietly turn the reset state into "somebody has to recreate this". It is rewritten to its empty
    # state instead, which is also what makes it impossible to fold twice: the reset opens with an H1, and
    # the entry test only accepts the entry heading levels.
    $isBranchFile = ($file -eq $branchFiles.Changelog)
    if ($isBranchFile) {
        Write-Utf8NoBom -Path $filePath -Content (((Format-BranchChangelogReset) -join $nl) + $nl)
    } else {
        Remove-Item -Path $filePath -Force
    }
    $rankNote = if ($filed.RankScore -gt 0) { ", significance $($filed.RankScore)" } else { ', unranked' }
    # WHERE it landed, not just that it landed. With the sections gone there is no heading name to report,
    # and "folded" alone would say nothing about the one thing this script decides -- so the position in the
    # list is printed instead, which is also what makes a misplacement visible without opening the file.
    $aheadOf = @([regex]::Matches($changelogContent.Substring($insertPos + $entryBlock.Length), '(?m)^' + $entryHashes + ' ')).Count
    $disposal = if ($isBranchFile) { 'reset' } else { 'removed' }
    Write-Host "Folded and ${disposal}: $file (tier $($filed.Tier)$rankNote -- placed above $aheadOf existing $(if ($aheadOf -eq 1) { 'entry' } else { 'entries' }))" -ForegroundColor Green
    # Captured per iteration rather than read back afterwards. $num in particular survives from one loop
    # pass to the next, so an entry whose PR lookup found nothing would otherwise inherit the previous
    # entry's number -- into a commit message, where a wrong PR reference is worse than none.
    $folded += [pscustomobject]@{
        File   = $file
        # The file name as the fallback, so a fold whose branch could not be determined still produces a
        # commit subject that names something. Without it the message would read 'fold:  changelog' --
        # a commit on main that says nothing about what it folded.
        Branch = $(if ($branchForPr) { $branchForPr } else { $file })
        Pr     = $(if ($prs.Count -ge 1) { $prs[0].number } else { $null })
    }
}

Write-Host "CHANGELOG.md updated." -ForegroundColor Green

# THE STEP LIST IS RESET WITH THE ENTRY, and only with it. branch-progress.md is never folded -- nothing
# in it belongs in a changelog -- but it is the same branch's file, and leaving a merged branch's ticked-off
# steps on the trunk would greet the next branch with somebody else's work. The reset is keyed on the entry
# actually having been folded rather than on the file existing, so a fold-all run that only found legacy
# root entries leaves it alone: that run belongs to a branch that never had a step list.
$resetPaths = @()
if (@($folded | ForEach-Object { $_.File }) -contains $branchFiles.Changelog) {
    $progressPath = Join-Path $repoRoot $branchFiles.Progress
    Write-Utf8NoBom -Path $progressPath -Content (((Format-BranchProgressReset) -join $nl) + $nl)
    $resetPaths += $branchFiles.Progress
    Write-Host "Reset to its empty state: $($branchFiles.Progress)" -ForegroundColor Green
}

# --- The fold commit ------------------------------------------------------------------------------
# WHY THIS IS IN THE SCRIPT AT ALL. The fold has always ended with a hand-typed commit, and on
# August 2, 2026 that happened four times in one session -- the exact "noticed once, automated the
# second time" trigger this house works by. It is also the step where a mistake is least visible: the
# fold itself is verified by the lint gate, while the commit around it is typed from memory each time.
#
# THE SCOPE IS ENFORCED BY GIT, NOT BY CARE. 'git commit -- <paths>' commits exactly those paths and
# ignores the index, so whatever else is modified or already staged cannot ride along. That matters
# more here than anywhere else in this repo: this commit goes straight to the main branch under a named
# exception to "never commit directly", and an exception is only safe while it stays the size it was
# granted at.
if ($Push) { $Commit = $true }
if ($Commit) {
    if ($folded.Count -eq 0) {
        Write-Host "Nothing was folded, so there is nothing to commit." -ForegroundColor Yellow
        exit 0
    }
    $subjects = @($folded | ForEach-Object {
        if ($_.Pr) { "$($_.Branch) (#$($_.Pr))" } else { $_.Branch }
    })
    # 'fold:' IS THE TYPE, NOT 'chore:' (Dave, August 10, 2026). Folding is a named act with its own
    # script, its own exception to "never commit directly on main" and its own place in the cycle;
    # 'chore' said only "housekeeping" and left the reader to parse the rest of the line to find out
    # which housekeeping. It is also the second half of a shape this repo already chose: 'merge:' was
    # invented on August 7 for exactly the same reason -- a commit that belongs to no branch still
    # deserves a type -- and merge + fold are one movement written as two commits, so they now read as
    # one pair. With 'chore/' refused as a branch prefix since August 7, this was the last thing in the
    # repo still producing a 'chore:' subject.
    #
    # NOTHING TO RECOGNISE ON THE WAY OUT, checked rather than assumed: no script, gate or hook parses
    # this subject -- only this line writes it and one assert in fold-changelog.tests.ps1 reads it back.
    # ('^chore(/|$)' in branch-info.ps1 matches a BRANCH NAME and is untouched.) So the usual "recognise
    # both, write one" rule has nothing to attach to here; every 'chore: fold ...' already in this repo's
    # history and in every consumer's stays exactly as valid as it was, because nobody was reading it.
    # The workflow-default discovery script keys on the shape '^[a-z]+:' rather than on a list of types,
    # so 'fold:' still reads as conventional there.
    #
    # THE PR NUMBER STAYS (Dave's call, weighed against the shorter form): it is the only link from this
    # commit back to the PR it folded, and it is what makes the subject line up field for field with the
    # 'merge: <branch> (#NN)' one commit below it.
    # The singular form is composed from Branch and Pr rather than from $subjects, because the number
    # belongs at the END of the line -- '<branch> (#NN) changelog' would bury it mid-sentence. The plural
    # form does use $subjects: there the number has to travel with each branch it belongs to.
    $message = if ($folded.Count -eq 1) {
        $prSuffix = if ($folded[0].Pr) { " (#$($folded[0].Pr))" } else { '' }
        "fold: $($folded[0].Branch) changelog$prSuffix"
    } else {
        "fold: $($folded.Count) changelogs: " + ($subjects -join ', ')
    }
    # CHANGELOG.md plus the entry files -- named, and nothing else. The entry files are gone from disk
    # by now; naming a deleted path is how git is told to record the deletion.
    #
    # ONLY THE ONES GIT ALREADY KNOWS. In the normal flow the entry file was committed on the branch and
    # came to main with the merge, so it is tracked and its deletion belongs in this commit. But an entry
    # written and folded without ever being committed is untracked, and naming an untracked path makes
    # 'git commit' fail on the pathspec -- after the fold has already deleted the file, which is the
    # worst possible moment for an avoidable error. Read from the index rather than from disk, because by
    # now the file is gone from disk and still in the index, which is exactly the state that needs
    # recording.
    # THE PROGRESS FILE RIDES ALONG, because this run rewrote it. It is not an entry and was not folded,
    # but leaving it out would produce a commit that resets half the pair -- the changelog file empty on
    # main and the step list still showing the merged branch's ticked boxes. Named explicitly rather than
    # swept up, so the enforced scope stays exactly as small as it was: CHANGELOG.md, the entries, and the
    # one file the fold itself reset.
    $entryPaths = @($folded | ForEach-Object { $_.File })
    $writtenPaths = @($entryPaths) + @($resetPaths | Where-Object { $entryPaths -notcontains $_ })
    $lsFiles = Invoke-NativeCapture -FilePath 'git' -Arguments (@('ls-files', '--') + $writtenPaths)
    # git reports its own paths with forward slashes; the entry names are plain file names in the repo
    # root, so normalising both sides costs nothing and removes the one way this could silently drop a
    # deletion from the commit.
    $tracked = @($lsFiles.Output | Where-Object { $_ } | ForEach-Object { ($_ -replace '/', '\').Trim() })
    $paths = @('CHANGELOG.md') + @($writtenPaths | Where-Object { $tracked -contains ($_ -replace '/', '\') })
    $untracked = @($writtenPaths | Where-Object { $tracked -notcontains ($_ -replace '/', '\') })
    if ($untracked.Count -gt 0) {
        # Deliberately not "deleted": since the split, an untracked path here may have been reset rather
        # than removed, and a message that names the wrong disposal sends the reader looking for a file
        # that is still on disk.
        Write-Host "  (not in the commit, because git never tracked them: $($untracked -join ', ') -- the fold handled them on disk all the same.)" -ForegroundColor DarkYellow
    }
    $commitRun = Invoke-NativeCapture -FilePath 'git' -Arguments (@('commit', '-m', $message, '--') + $paths)
    if ($commitRun.ExitCode -ne 0) {
        Write-Host ($commitRun.Output -join "`n") -ForegroundColor Red
        Write-Host "The fold is on disk but NOT committed (git commit exited $($commitRun.ExitCode)). Commit it by hand; do not re-run the fold, it has already removed the entry files." -ForegroundColor Red
        exit 1
    }
    Write-Host "Committed: $message" -ForegroundColor Green

    if ($Push) {
        $pushRun = Invoke-NativeCapture -FilePath 'git' -Arguments @('push')
        if ($pushRun.ExitCode -ne 0) {
            Write-Host ($pushRun.Output -join "`n") -ForegroundColor Red
            Write-Host "Committed locally but NOT pushed (git push exited $($pushRun.ExitCode)) -- the state this flag exists to avoid. Push by hand." -ForegroundColor Red
            exit 1
        }
        Write-Host "Pushed." -ForegroundColor Green
    }
}
