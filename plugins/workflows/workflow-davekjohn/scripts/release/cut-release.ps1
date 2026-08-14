<#
.SYNOPSIS
    Cuts a repo-wide release directly on main: bumps all plugin versions in lockstep,
    generates release notes in releases/development/, empties CHANGELOG.md down to its intro,
    updates the overview table in releases/README.md, commits that on main, and sets +
    pushes the git tag vX.Y.Z.

.DESCRIPTION
    A release here is a *recorded moment*: all plugins get the same version number
    (lockstep, repo-wide) and the state is tagged as vX.Y.Z. This script itself publishes nothing
    to GitHub Releases -- only a git tag, release notes in releases/, and a row in the overview
    table. For a Minor/Major bump, publishing a GitHub Release is a manual follow-up step
    the release manager takes afterward, per the cut-release skill's closing checklist; a Patch
    bump skips that step entirely (tag only).

    NOTHING IS WRITTEN BACK INTO CHANGELOG.md, and that is a change this header used to contradict
    (August 5, 2026). The cut used to append a '## Latest Release' block naming the version, the date
    and a pointer to the notes; that accumulating section had grown to 434 of the file's 1,062 lines
    across 72 blocks that each said no more than "see the notes", while the overview table already
    listed all 72 with a date, a type and a descriptive title. So the intro carries a one-line pointer
    to that page, and a cut leaves this document at its intro.

    A release deliberately does NOT run via a branch + PR. Like the fold commit, the release
    commit is an allowed direct-on-main action (the second exception to "everything via branch +
    PR" -- see the safety rules). The script therefore runs on main itself and is started ONLY at
    Dave's explicit request.

    SHARED, WITH THE REPO'S OWN ANSWERS IN THE SEAM (issue #417). This script is mirrored into the
    plugin, so a consumer runs it rather than forking it. Everything that legitimately differs per
    repo is read from the OPTIONAL functions in scripts/repo-config.ps1, and every fallback is what
    this script did before it was shared. THE LIST IS THE EIGHT THIS SCRIPT ACTUALLY READS, and it is
    kept that way deliberately: a consumer configures from this list, so a name that does nothing costs
    them an afternoon and a name that is missing hides a knob they needed.

      Get-LintScript              which script the lint gate in step 1 runs
      Get-ReservedRootMd          which root docs are permanent
      Get-ReleaseNotesGrouping    notes foldered per major ('major') or per minor
      Get-ReleaseHistoryPath      where the release overview table lives (step 3 files the new row
                                  under that page's top major section, and REFUSES a new major whose
                                  section does not exist yet -- opening one is a deliberate act)
      Get-ReleasePluginTier       whether this repo publishes plugins at all: it gates the lockstep
                                  bump, and it is what decides whether the current version comes from
                                  a plugin.json or from the newest vX.Y.Z tag
      Get-ReleaseConsumerBumps    which bumps get a stakeholder document; see step 3d. The retired name
                                  Get-ReleaseHighlightsBumps is still read as a fallback
      Get-ReleaseMajorMinMinors   how many minors a major must recap
      Get-TestCommands            extra test commands the test gate in step 1 runs beside the
                                  *.tests.ps1 suites (e.g. 'npm test') -- read inside the shared
                                  Invoke-TestSuiteGate, so open-pr's gate sees the same list

    TWO NAMES THAT USED TO BE ON THIS LIST ARE GONE, and they are named here rather than silently
    dropped, because a consumer's repo-config may still define them: Get-ReleaseLiveMarker described
    the retired release block in CHANGELOG.md (see the seam comment further down), and
    Get-ReleaseCategoryTitles labelled the category headings the flat document retired. Defining either
    today does nothing at all -- which is worse than an error, because it looks configured.

    THE TIER MODEL (August 5, 2026). CHANGELOG.md is an intro followed by one '##' per change, ranked
    furthest-reach-first and, within a reach, highest-significance-first -- there are no sections to file
    into, and each entry declares its own reach in the '### Significance' section it carries. Three
    things here follow from it: the bump gate in step 1, the tier grouping of the notes in step 3, and
    the consumer document in step 3d being the tier-2 entries rather than a category guess.

    All three switch themselves off where NO PENDING ENTRY DECLARED ITS IMPACT AT ALL, so a consumer
    that has not adopted the model cuts exactly the release it always did. That test counts
    DECLARATIONS, and it must not be turned back into a count of sections: a flat changelog gives an
    unadopted repo and an adopting one exactly one group each, so a section-count test would read every
    repo as not adopting and switch the gate off in silence, with nothing erroring.

    Steps (all on main):
      1. Guardrails: clean main, no unfolded entry files in the root, THE BUMP EARNED BY THE PENDING
         TIERS (the bump follows the highest tier pending -- tier 0 only is a patch, tier 1 or higher
         earns a minor, a major needs enough minors behind it -- Test-ReleaseBumpEarned; -SkipTierGate
         overrules), lint gate green, AND all test suites green (-SkipTests overrules).
      2. Determines the current version -- the lockstep value from every
         <plugin>/.claude-plugin/plugin.json where this repo publishes plugins, otherwise the newest
         vX.Y.Z tag -- then the new version (-Version or -Bump) and the bump type.
      3. Generates releases/development/<X>.x/<X.Y.Z>.md from the pending entries, grouped by TIER,
         adds a row to releases/README.md, empties CHANGELOG.md down to its intro, and bumps all
         plugin.json's. Within a tier the entries are RANKED BY THEIR OWN SIGNIFICANCE SCORES FROM
         TIER 1 UP, and deliberately not at tier 0: the development note is the record, so it stays in
         the order the folds left. There is no category grouping any more -- the categories keyed on the
         branch prefix, which this repo has measured does not predict impact, so a document's most
         consequential change could only be reordered within whichever label its prefix produced.
      3b/3c. RETIRED, AUGUST 8, 2026 -- the per-plugin CHANGELOG.md and the per-plugin RELEASE.md card.
          The step numbers are kept here rather than renumbered, so that a reader who has seen an older
          copy of this script, or a consumer's release notes referring to "step 3b", lands on the answer
          instead of on a step that now means something else. The full reasoning is at the point in the
          code where they used to run; in short, a marketplace source is a git clone of the WHOLE repo,
          so those ten files were 11,684 lines restating what the reader already had.
      3d. Writes a second, stakeholder-facing rendering of the same release:
          releases/consumer/<dir>/<X.Y.Z>.md. TWO CONDITIONS, BOTH REQUIRED: the bump type is one the
          seam names in Get-ReleaseConsumerBumps, AND at least one pending entry declared tier 2.
          The second half is the load-bearing one since a minor stopped needing a tier-2 entry to be
          earned (August 7, 2026) -- it is what keeps a tier-1-only minor from handing someone outside
          the project a document about work they cannot see.
          Written for NON-DEVELOPERS, and it is the TIER-2 ENTRIES -- what a consumer notices was
          declared by each entry's own author, so there is no "remove before publishing" marker left to
          cut by hand. Still a draft: the selection is right, the prose is still written for developers.
          Markdown only -- no HTML, deliberately (see release-lib.ps1's tier-2 header).
      4. Commits that directly to main (release: vX.Y.Z) and sets an annotated tag vX.Y.Z, then names
         the documents it deliberately did NOT write: the consumer draft still needs editing, and the
         internal summary (the third tier, for colleagues and management, at EVERY release including a
         patch) has its own script -- new-internal-note.ps1, which needs the notes step 3 just produced.
         Both are hand-written and both land via a branch + PR, because this commit is already tagged.
      5. Pushes main + the tag (unless -NoPush).

.PARAMETER Version
    Explicit new version X.Y.Z (e.g. "1.1.0"). Use this OR -Bump.

.PARAMETER Bump
    Bump the current version automatically: major | minor | patch. Use this OR -Version.

.PARAMETER Title
    Short description of the release as a whole (1 sentence, optional) -- goes into the notes +
    the table row.

.PARAMETER SummaryFile
    Path to a markdown file whose content is placed in the release notes between the -Title line and
    the generated per-PR entries, followed by a horizontal rule.

    FOR A MILESTONE RELEASE, where the point is the arc across many releases rather than the diff since
    the last one. -Title is one sentence and the entries are per-PR, so neither can carry "here is what
    changed between 2.2.0 and 2.16.0" -- and hand-editing a generated file afterwards is not a
    repeatable release, which is the whole reason this script exists.

    The file may live outside the repo (a scratch path is fine, and is the expected case): its canonical
    home becomes the generated notes file itself, so keeping a second copy under releases/ purely to
    feed this parameter would duplicate content for no gain. A missing or empty file is a hard stop --
    an empty one would otherwise produce an ordinary release while the operator believes they cut a
    milestone.

.PARAMETER NoPush
    Everything locally (commit + tag) but do not push main/tag -- for inspection beforehand.

.PARAMETER SkipLint
    Deliberately skip the lint gate (escape valve).

.PARAMETER SkipTests
    Deliberately skip the test-suite gate (escape valve). Separate from -SkipLint for the reason those two
    are separate in open-pr.ps1: they are two different tools, and skipping one is not a reason to skip the
    other. The suites run BEFORE anything is written, so skipping them means a release can be committed and
    tagged on main while a suite is red.

.PARAMETER SkipSignificanceGate
    Cut even though a pending tier-1-or-higher entry has not declared how much it weighs (issue #467).
    The score orders the release documents, so without it an entry cannot be placed; the gate refuses
    rather than sorting it last, because quietly demoting a forgotten line is worst in the one document
    whose subject is which change matters most.

    SEPARATE FROM -SkipTierGate as well as from -SkipLint, because the three overrule different things:
    -SkipLint skips a tool, -SkipTierGate overrules whether the release should exist at all, and this
    overrules how its contents are ordered. One flag for all three would let someone waving through a
    missing score also wave through an unearned version number.

.PARAMETER SkipTierGate
    Cut a bump the pending changelog tiers have not earned (escape valve).

    DELIBERATELY SEPARATE FROM -SkipLint, and for the same reason the scaffold gate's -Force is separate:
    this overrules a judgement about CONTENT -- whether the work reaches far enough to deserve this
    version number -- while -SkipLint skips a tool. Folding them into one flag would let someone skipping
    a slow lint run also, silently, cut a minor with nothing in it for a consumer.

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Version 1.0.0 -Title "First official release"

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Bump minor -NoPush

.EXAMPLE
    ./scripts/release/cut-release.ps1 -Bump major -Title "A new milestone" -SummaryFile ..\summary.md -NoPush
    # Milestone release: the authored summary opens the notes, the pending entries follow it.
#>
[CmdletBinding()]
param(
    [string]$Version,
    [ValidateSet('major', 'minor', 'patch')][string]$Bump,
    [string]$Title = '',
    [string]$SummaryFile = '',
    [switch]$NoPush,
    [switch]$SkipLint,
    [switch]$SkipTests,
    [switch]$SkipTierGate,
    [switch]$SkipSignificanceGate
)
$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Repo root -- dual context, the same contract every shared script here follows (#81): if a consumer
# runs the plugin mirror, CLAUDE_PROJECT_DIR supplies its repo root; in the workshop root (or outside
# a session) it falls back to the git root. This is what lets the root copy and the mirror stay
# byte-identical, which the shared-scripts drift lint enforces.
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }
Set-Location $repoRoot

# Pre-flight, before the dot-sources below turn a missing file into a raw path-not-found (#86, the
# same guard open-pr.ps1 carries). Both files are REPO-OWNED and live in the consumer's root.
$needed = @('scripts\repo-config.ps1', 'scripts\lib\branch-info.ps1')
$absent = @($needed | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_)) })
if ($absent.Count -gt 0) {
    Write-Error ("cut-release cannot run -- missing repo-owned configuration in the repo root ($repoRoot):`n  " + ($absent -join "`n  ") + "`n`nCreate them (the specialists-init bootstrap lays down a VUL-IN scaffold, or take an existing consumer / the workshop repo as a model) and run again afterward.")
    exit 1
}

# $repoRoot, not $PSScriptRoot: from the plugin mirror $PSScriptRoot points into the plugin cache,
# while repo-config and branch-info always live in the consumer's repo root. branch-info is dot-sourced
# HERE rather than left to release-lib, because release-lib travels into the mirror and its sibling
# branch-info does not -- Get-ReleaseChangeTypes probes for Get-BranchTypes and finds what we load here.
. (Join-Path $repoRoot 'scripts\lib\branch-info.ps1')
. (Join-Path $repoRoot 'scripts\repo-config.ps1')

# Plugin-owned libraries, from $PSScriptRoot: these travel WITH this script, so the sibling is the
# right one in both locations.
. (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')
# The entry format (Test-EntrySignificanceActive for the significance gate, Get-EntryImpactFindings for
# what it reports). release-lib dot-sources this lib itself, so this line adds no function that was not
# already in scope -- it is here for the same reason branch-info is dot-sourced above rather than left to
# release-lib: a dependency this script's own gates rest on should be visible at the place that rests on
# it, not inherited from another lib's internals.
. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')
# Shared native-capture helper (#114): the #107 EAP=Continue -> capture -> $LASTEXITCODE dance for
# the git mutations in the final block lives here in one tested place.
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# --- The repo's own answers, read once (#417) -----------------------------------------------------
# Every one of these is OPTIONAL in the script contract, and every fallback is what this script did
# before it was shared -- so a consumer that defines none of them gets the unchanged behaviour.
function Get-SeamValue {
    <#
        Calls an optional repo-config function, or returns $Default when the repo does not define it.

        $Name takes MORE THAN ONE NAME where a seam has been renamed: they are tried in order and the
        first one the repo defines wins, so the current name is preferred and a retired one still
        answers. That matters because this is a CONSUMER-OWNED file -- a repo that defined the old name
        receives the rename through a plugin update rather than by choosing to, and without the fallback
        it would drop to $Default in silence. A seam whose default is "off" fails that way without
        erring once.
    #>
    param([Parameter(Mandatory)][string[]]$Name, $Default)
    foreach ($n in $Name) {
        if (Get-Command $n -ErrorAction SilentlyContinue) { return (& $n) }
    }
    return $Default
}

$notesGrouping = Get-SeamValue -Name 'Get-ReleaseNotesGrouping' -Default 'major'
# WHERE THE FULL RELEASE LIST LIVES -- the one survivor of the three changelog-release seams (August 5,
# 2026). Get-ReleaseLiveMarker and Get-ReleaseHistoryMode described the release BLOCK in CHANGELOG.md: the
# "currently live" suffix on its newest row, and whether that section accumulated or kept only the newest
# behind a pointer. A cut writes no such block any more -- it empties the changelog down to its intro -- so
# both knobs describe machinery that is gone and are retired. This one stays because the row inserter below
# still writes into that file, which is now the only list of releases there is.
$historyRelPath = Get-SeamValue -Name 'Get-ReleaseHistoryPath'    -Default 'releases/README.md'
# The computed fallback is a fact, not a guess: no marketplace manifest means there are no plugins to
# version or card. Stated in repo-config here anyway, because in this repo the answer is load-bearing.
$pluginTier    = Get-SeamValue -Name 'Get-ReleasePluginTier' `
    -Default (Test-Path -LiteralPath (Join-Path $repoRoot '.claude-plugin\marketplace.json'))

# The consumer tier (#417 phase 2). Empty by default, which is the tier switched OFF -- what this
# script did for its whole life as a workshop-only file, so nothing changes for a consumer.
#
# ONE KNOB NOW, NOT THREE. Get-ReleaseHighlightsStakeholderTypes and Get-ReleaseHighlightsWording are
# retired (August 5, 2026): both configured the "remove before publishing" marker, and the tier model
# replaced that marker with the entries' own tier-2 declaration. See release-lib.ps1's tier-2 header.
#
# TWO NAMES READ, ONE WRITTEN (August 10, 2026). The knob was Get-ReleaseHighlightsBumps until the tier
# was renamed after its reader, and the old name is read second rather than dropped -- the standing
# "recognise both, write one" rule, load-bearing here because the fallback for "not defined" is @(),
# the tier switched OFF. A consumer whose seam still says Highlights would therefore cut a minor with no
# document for the very reader it was cut for, and nothing in the run would say so.
$consumerBumps = @(Get-SeamValue -Name 'Get-ReleaseConsumerBumps', 'Get-ReleaseHighlightsBumps' -Default @())

# AND WHERE THAT DOCUMENT GOES, which until now was the one path in this file with no knob (inbound
# #616, reported from a consumer). Everything around it was already answered per repo -- the folder
# component by Get-ReleaseNotesGrouping, the release list by Get-ReleaseHistoryPath -- so the file
# already accepted that the folder inside this path varies while its root did not. That left the tier
# above UNANSWERABLE for a repo whose hand-written notes live elsewhere: naming the bumps would have
# pointed the cut at a directory that does not exist there and left the one that does out of the
# release, so the only safe answer was @(), the tier switched off.
#
# Get-ReleaseHistoryPath is the precedent and the same sentence applies: a location convention rather
# than a fact about the repo, and it is already the default -- so nothing changes for anyone who does
# not set it. The name follows this file's own vocabulary for the document (Get-ReleaseNoteWording,
# below) rather than the tier that reads it: since the two hand-written documents merged there is one
# release note with a named section per reader, and the consumer is a section of it, not its title.
#
# releases/development/ is deliberately NOT given one. The reporter could show a repo that genuinely
# differs on this path and none that differs on that one, and a seam nobody can be shown to need is a
# knob a consumer has to read past. It comes back when somebody measures it.
$noteRootRelPath = Get-SeamValue -Name 'Get-ReleaseNoteRoot' -Default 'releases/notes'

# How many minors a major line must have had before a major may be cut. A major here is a RECAP of the
# minors before it, so what earns one is their accumulation -- 10 in this repo. Repo-owned because it is
# a release-cadence policy: a repo that cuts minors rarely would be pinned to a major it never reaches,
# and forking a shared script over one integer is exactly what the seam exists to prevent (#417).
$majorMinMinors = [int](Get-SeamValue -Name 'Get-ReleaseMajorMinMinors' -Default 10)

# RETIRED WITH THE RELEASE BLOCK (August 5, 2026): Get-ChangelogReleaseWording (inbound #462) configured
# the four strings a cut wrote into CHANGELOG.md -- the release section's intro, the notes pointer, and the
# sentence repointing it at the internal note. The cut writes none of them now. What replaced that block is
# the changelog intro's own one-line pointer to the release history: hand-written prose in a file the repo
# owns, which needs no seam to be in the repo's language because it simply is. See release-lib.ps1's
# retirement note for what the consumer who asked for #462 does and does not lose.

# BOM-less UTF8 -- the rest of the repo has no BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

# Permanent root .md files that are NOT branch changelog entries. The stray-entry guardrail below
# treats every other root *.md as an unfolded entry (deliberately catch-all, so an entry with an
# unknown branch prefix is never missed) -- so any permanent root doc added over time must be listed,
# or a release would falsely refuse to cut.
#
# THE LIST MOVED TO THE SEAM IN #417 and no longer lives here. It had gone stale three times, each
# time blocking a release over a document nobody had failed to fold (#165, then QUICKSTART.md +
# UNINSTALL.md in #405, then ADOPTION.md in #408) -- and once this script is shared, which root docs
# a repo has is by definition not something the script can know. The fallback below is the workshop's
# own list, so a consumer that defines nothing still gets the behaviour this script always had -- and
# it tracks that list rather than a snapshot of it: the install and uninstall pages left the root for
# plugins/, so they left here too. A fallback that kept naming them would not have blocked anything,
# but it would have described a root the workshop no longer has, which is how this list went stale the
# first three times.
$reservedRootMd = @(Get-SeamValue -Name 'Get-ReservedRootMd' -Default @(
    'CHANGELOG.md', 'CLAUDE.md', 'README.md', 'LICENSE.md', 'CONTRIBUTING.md', 'SECURITY.md'))

$script:marketplaceJsonText = $null
function Get-MarketplaceJsonText {
    # THE one read of marketplace.json, shared by the two things derived from it: which plugins exist,
    # and what the marketplace is called. Cached rather than re-read per caller -- two reads of one
    # file during a release that also WRITES files is exactly how the two answers start disagreeing,
    # and a function whose comment promises a single read has to deliver one.
    if ($null -eq $script:marketplaceJsonText) {
        $marketplacePath = Join-Path $repoRoot '.claude-plugin\marketplace.json'
        if (-not (Test-Path -LiteralPath $marketplacePath)) {
            Write-Error ".claude-plugin/marketplace.json is missing."; exit 1
        }
        $script:marketplaceJsonText = (Get-Content -Path $marketplacePath -Raw -Encoding UTF8)
    }
    return $script:marketplaceJsonText
}

function Get-PluginManifests {
    # The marketplace definition is the source of truth about what a plugin is: the set is derived from
    # plugins[] (incl. the containment check) by Get-PluginRoots in plugin-tree-lib.ps1 -- pure there and
    # thus tested. Here only the IO: the existence check.
    #
    # RETURNS THE ROOT OBJECTS, NOT BARE PATHS, and that removes two identical derivations further down.
    # Both this error and the bump report used to reconstruct the plugin's name by walking three
    # Split-Paths up from the manifest -- which is only the name because of where the folder happens to
    # sit. The marketplace states the name outright, so both now read it instead of inferring it.
    $roots = @(Get-PluginRoots -RepoRoot $repoRoot -MarketplaceJson (Get-MarketplaceJsonText))
    foreach ($p in $roots) {
        if (-not (Test-Path -LiteralPath $p.ManifestPath)) {
            Write-Error "Plugin '$($p.Name)' is listed in marketplace.json but is missing its manifest ($($p.ManifestPath))."; exit 1
        }
    }
    $roots
}

# --- Guardrails: on main, clean, no unfolded entries ---------------------------------------
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne 'main') { Write-Error "A release is cut directly on main; you are on '$branch'."; exit 1 }
if ((git status --porcelain)) { Write-Error "Working tree not clean -- commit/stash first."; exit 1 }

$strayEntries = Get-ChildItem -Path $repoRoot -Filter '*.md' -File |
    Where-Object { $reservedRootMd -notcontains $_.Name } |
    Select-Object -ExpandProperty Name
if ($strayEntries.Count -gt 0) {
    Write-Error "There are still unfolded changelog entry files in the root: $($strayEntries -join ', '). Fold them first (fold-changelog-entry.ps1)."
    exit 1
}

# THE SAME GUARD FOR branch/ (Dave, August 6, 2026). Since the split the entry arrives at a FIXED path, so
# the catch-all above cannot see it: that one is "every root *.md that is not a permanent doc", and this
# file is neither in the root nor stray -- it is a permanent part of the repo whose CONTENT decides whether
# work is pending. The test is therefore the content, not the file's existence, and it is the same
# structural test the fold uses to decide the file holds an entry at all.
#
# WHY IT MATTERS MORE HERE THAN THE ROOT VERSION DID. A cut EMPTIES CHANGELOG.md; an entry still sitting
# unfolded at this moment does not land in the release documents and is then orphaned on a trunk whose
# pending list has just been cleared. The root form announced itself by being a file nobody expected. The
# branch/ form looks exactly like the reset state at a glance, which is precisely why it needs a gate
# rather than a reader's attention.
$cutBranchFiles = Get-BranchFilePaths
$cutBranchChangelog = Join-Path $repoRoot $cutBranchFiles.Changelog
if ((Test-Path -LiteralPath $cutBranchChangelog) -and
    (Test-BranchChangelogIsFilled -Text ([System.IO.File]::ReadAllText($cutBranchChangelog)))) {
    Write-Error "$($cutBranchFiles.Changelog) still holds an unfolded entry. Fold it first (fold-changelog-entry.ps1); a cut empties CHANGELOG.md, so an entry left here would miss this release and be orphaned afterwards."
    exit 1
}

# --- Determine version + bump type ------------------------------------------------------------
# WHERE THE CURRENT VERSION COMES FROM depends on the plugin tier, and the two sources are not
# interchangeable (#417). With plugins, the manifests ARE the record and Get-LockstepVersion also
# proves they agree -- a disagreement is a defect this must not paper over. Without them there is no
# manifest to read, so the newest reachable tag is the record, which is what a repo with no plugins
# has always used. Deliberately not "tag if the manifests are missing": in this repo a manifest that
# vanished would then silently downgrade to a tag read, and the lockstep check would go with it.
$manifests = @()
$marketplaceName = ''
if ($pluginTier) {
    $manifests = @(Get-PluginManifests)
    if ($manifests.Count -eq 0) { Write-Error "No plugin manifests found."; exit 1 }
    # Read once, outside the per-plugin loop that consumes it: the name is a property of the marketplace,
    # not of the plugin, so re-deriving it per plugin would invite four answers to a one-answer question.
    $marketplaceName = Get-MarketplaceName -MarketplaceJson (Get-MarketplaceJsonText)
    # KEYED ON THE PLUGIN NAME rather than the manifest path. The key is only ever read back in
    # Get-LockstepVersion's error text, where a lockstep disagreement has to be readable at a glance --
    # 'team-alpha: 3.9.0' says which plugin is out of step; an absolute path makes the reader work out
    # the same fact from a folder name.
    $manifestContents = @{}
    foreach ($p in $manifests) { $manifestContents[$p.Name] = (Get-Content -Path $p.ManifestPath -Raw -Encoding UTF8) }
    $current = Get-LockstepVersion -ManifestContents $manifestContents
} else {
    $latestTag = @(git tag --list 'v*' --sort=-v:refname) | Select-Object -First 1
    if ($latestTag) {
        $current = ($latestTag -replace '^v', '')
    } elseif ($Version) {
        # First release in a repo with neither manifests nor tags: -Version says what it is, and
        # 0.0.0 exists only so the bump-type label below has something to compare against.
        $current = '0.0.0'
    } else {
        Write-Error "This repo publishes no plugins (Get-ReleasePluginTier is false) and carries no vX.Y.Z tag, so there is no current version to bump from. Pass -Version <X.Y.Z> for the first release."
        exit 1
    }
}

if ($Version) {
    if ($Version -notmatch '^\d+\.\d+\.\d+$') { Write-Error "-Version must have the form X.Y.Z (e.g. 1.0.0)."; exit 1 }
    $new = $Version
} elseif ($Bump) {
    $new = Get-NextVersion -Current $current -BumpKind $Bump
} else {
    Write-Error "Provide -Version <X.Y.Z> or -Bump <major|minor|patch>. Current version: $current."
    exit 1
}
if ($new -eq $current) { Write-Error "New version ($new) equals the current one -- nothing to bump."; exit 1 }

$bumpType = Get-BumpType -From $current -To $new
$typeLabel = @{ major = 'Major'; minor = 'Minor'; patch = 'Patch' }[$bumpType]
$tagName = "v$new"
if ((git tag --list $tagName)) { Write-Error "Tag $tagName already exists."; exit 1 }

# --- The changelog, read once -------------------------------------------------------------------
# READ HERE RATHER THAN FURTHER DOWN, because the tier gate below needs it and a gate that runs after
# the first write is not a gate. Nothing between this read and the write at the end touches the file, so
# reading early costs nothing and means the whole run judges ONE snapshot of the changelog.
$changelogPath = Join-Path $repoRoot 'CHANGELOG.md'
$changelogRaw = Get-Content -Path $changelogPath -Raw -Encoding UTF8
$tierGroups = @(Get-PullRequestEntriesByTier -Content $changelogRaw)
$entries = @($tierGroups | ForEach-Object { $_.Entries } | Where-Object { $_ })

# --- Guardrail: has this bump been earned? (the tier model, August 5, 2026) ------------------------
# The rules live in Test-ReleaseBumpEarned (release-lib, tested): any release needs a tier-1 entry at
# minimum, a minor needs a tier-2 one, and a major needs enough minors behind it. The version number was
# always supposed to mean this; until now nothing checked, so the meaning depended on whoever typed the
# flag.
#
# PLACED WITH THE OTHER GUARDRAILS, BEFORE ANYTHING IS WRITTEN, for the same reason the new-major check
# is: failing after the notes file exists leaves a release half-cut on main.
#
# IT SWITCHES ITSELF OFF where no pending entry declared its impact at all -- which means the repo has not
# adopted the model, not that nothing qualifies. That test used to be "does the repo declare more than one
# changelog section", and it had to change with the sections: a flat changelog gives an unadopted repo and
# an adopting one exactly one group each, so the old signal would have read every repo as unadopted and
# switched this gate off silently. See Test-ReleaseBumpEarned for why 'declared tier 0' and 'declared
# nothing' must not be confused.
if (-not $SkipTierGate) {
    $earned = Test-ReleaseBumpEarned -BumpType $bumpType -TierGroups $tierGroups `
        -CurrentVersion $current -MinMinorsForMajor $majorMinMinors
    if ($earned.Active -and -not $earned.Earned) {
        $breakdown = ($tierGroups | ForEach-Object {
            "  tier $($_.Tier): $(@($_.Entries | Where-Object { $_ }).Count) entry/entries"
        }) -join "`n"
        $suggestion = if ($earned.EarnedBump) {
            "What the pending work does earn: -Bump $($earned.EarnedBump)."
        } else {
            "Nothing pending earns a release. Raise the tier of an entry that deserves it, or wait for work that does."
        }
        Write-Error @"
This $bumpType has not been earned by the pending changelog entries. Nothing was written.

$($earned.Reason)

Pending, per tier:
$breakdown

$suggestion

The tiers are how far a change reaches: 0 = only this repo's own developers notice, 1 = management and
the employer/commissioner get something out of it, 2 = a subscriber of the service notices it. An entry's
tier is the highest row of its own impact table in CHANGELOG.md; raise it, or correct the bump.
-SkipTierGate overrules this, deliberately separate from -SkipLint because it overrules a judgement
about content rather than skipping a tool.
"@
        exit 1
    }
}

# --- Guardrail: has every entry that gets ranked said how much it weighs? (issue #467) --------------
# The significance score orders the release documents, so an entry without one cannot be placed -- and the
# fallback ("sorts last") would quietly punish a forgotten line in the very document whose subject is
# which change matters most. This is Dave's chosen refusal point (August 5, 2026): the branch may merge
# without a score, the release may not be cut without one. By now the branch is long gone, so the fix is
# one edit in CHANGELOG.md rather than a reopened PR.
#
# ONLY TIER 1 AND UP ARE ASKED, because only they reach a ranked document. Tier 0 is the record: complete
# and chronological, and never sorted.
#
# THE TIER COMES FROM THE ENTRY, which is the reversal in this change. It used to come from the changelog
# SECTION, because the fold consumed the 'Tier:' line the moment the section took over stating it -- so
# $tierGroups was the only thing that knew, and this gate could not have lived in the fold. With the
# sections gone the entry carries its own declaration into the changelog, and $tierGroups is simply where
# that declaration has already been read once.
#
# SAME OFF-SWITCH AS THE SCAFFOLD AND THE FOLD: Test-EntrySignificanceActive, which now defaults ON with
# Get-EntrySignificanceEnabled as the opt-out. A repo that sets it $false opted out of all three at once --
# a score that is demanded but never read is worse than no score. Note this is a DIFFERENT off-switch from
# the bump gate's above: that one asks whether the repo declares tiers at all, this one whether it wants
# them ranked, and a repo can want the first without the second.
if (-not $SkipSignificanceGate -and (Test-EntrySignificanceActive)) {
    $significanceProblems = @()
    foreach ($group in $tierGroups) {
        if ([int]$group.Tier -lt 1) { continue }
        foreach ($entry in @($group.Entries | Where-Object { $_ -and $_.Trim() })) {
            $findings = @(Get-EntryImpactFindings -EntryText $entry)
            if ($findings.Count -eq 0) { continue }
            # Named by its heading, so the operator can find the entry in a 1,000-line changelog. The
            # heading is the entry's first line; '### #468 <md> Title <md> Feat' is enough to locate it.
            $heading = (($entry -split "`r?`n")[0] -replace '^#+\s*', '').Trim()
            foreach ($finding in $findings) { $significanceProblems += "  $heading`n      $finding" }
        }
    }
    if ($significanceProblems.Count -gt 0) {
        $rubric = (Format-EntrySignificanceRubricLines) -join "`n"
        Write-Error @"
$($significanceProblems.Count) pending entry/entries have not said how much they weigh. Nothing was written.

$($significanceProblems -join "`n")

The rubric:
$rubric

The score decides where in its release document an entry sits -- highest first -- so the most
consequential change leads. Every tier an entry reaches owes a row, because every tier is a document with
its own reader:

  | Tier | Significance | Why |
  |---|---|---|
  | 2 | 5 | what a subscriber of the service gets out of it |
  | 1 | 4 | what management and the employer/commissioner get out of it |

Add the rows to the entries in CHANGELOG.md and cut again.

-SkipSignificanceGate overrules this, deliberately separate from -SkipLint: this overrules a judgement
about content, while -SkipLint skips a tool.
"@
        exit 1
    }
    if (-not $earned.Active) {
        Write-Host "  (no pending entry declares its impact -- this repo has not adopted the tier model, so the bump gate does not apply.)" -ForegroundColor DarkGray
    }
}

# --- Guardrail: a NEW MAJOR needs its own overview section before the row can land ----------------
# Placed here, with the other guardrails, because it must stop the run BEFORE anything is written: the
# row insertion happens after the notes file already exists, and failing there would leave a release
# half-cut. Get-OverviewTargetMajor (release-lib, tested) answers where the row would actually go.
#
# The failure this prevents is silent, not loud: the inserter matches the FIRST table header, so on a
# major bump a 'v3.0.0' row is filed neatly under '### 2.x' and nothing errors. And it has never been
# hit, because the grouping-by-major arrived in v2.0.1 -- one release after the only major ever cut.
# Rare plus silent is the worst combination for a manual step, which is why this speaks up instead.
#
# The path comes from Get-ReleaseHistoryPath rather than being hardcoded (August 4, 2026). That seam
# already answers "where does this repo keep its release history?" for the changelog's pointer, and the
# overview table IS that history -- so one answer serves both. Two hardcoded copies would be two places
# that have to keep agreeing, and the day they stop, the changelog points at one file while the row
# lands in another.
$newMajor = ($new -split '\.')[0]
$relReadmePath = Join-Path $repoRoot ($historyRelPath -replace '/', '\')
if (Test-Path -LiteralPath $relReadmePath) {
    $historyContent = Get-Content -LiteralPath $relReadmePath -Raw -Encoding UTF8
    $targetMajor = Get-OverviewTargetMajor -ReadmeContent $historyContent
    if ($null -ne $targetMajor -and $targetMajor -ne $newMajor) {
        # The heading is QUOTED BACK AT THE LEVEL THE DOCUMENT USES, not at a level this script assumes.
        # It hardcoded '###' until August 4, 2026, which broke the moment the release list was nested one
        # deeper under a repo-specific section heading: the advice then told you to add a heading whose
        # level the guardrail would not recognise, so following it exactly would leave the guardrail off.
        # Get-OverviewSectionHeading reports what was actually matched, from the same pattern.
        $targetHeading = Get-OverviewSectionHeading -ReadmeContent $historyContent
        $hashes = ($targetHeading -split '\s+')[0]
        $newHeading = "$hashes $newMajor.x"

        # The message must state what is actually KNOWN, not assume a direction. The mismatch is
        # reachable both ways, and the two ways need different remedies:
        #   newMajor > target -- the usual case: a new major whose section does not exist yet.
        #   newMajor < target -- the section exists but is not on top, because a HIGHER major was opened
        #     already. Saying "has no '2.x' section yet" there would be plainly false, and a
        #     guardrail that misdescribes the repo teaches people to bypass it.
        $advice = if ([int]$newMajor -lt [int]$targetMajor) {
            "'$newHeading' does exist, but '$targetHeading' sits above it, so that is where the row goes.`n" +
            "Releasing an older major after a newer one has been opened needs a decision this script will not make for`n" +
            "you: either move the row by hand after cutting, or reconsider the version."
        } else {
            # Positioned RELATIVE to the heading that was actually found, not under a named heading of
            # its own. It used to say "directly under '## Overview'", which was stale from the day the
            # overview moved out of releases/README.md into its own history page -- and naming any fixed
            # heading is wrong on principle here, because the history file is repo-owned via
            # Get-ReleaseHistoryPath and a consumer's may be structured differently. The '<n>.x' heading
            # is the one shape this script does depend on, so that is the one it may point at.
            # THE ADVICE NAMES BOTH EDITS, NOT JUST THE SECTION (August 9, 2026). A repo may also PIN the
            # major its overview targets in a test -- this repo does, deliberately, so the overview and the
            # pin are one fact written twice and a half-done edit cannot land quietly. The consequence is
            # that opening the section turns that test red, and until this message said so, the second
            # commit arrived as a surprise AFTER following advice that read as complete. Naming it costs two
            # lines and removes nothing: the pin is still repointed by a person, which is the whole point of
            # having it. Phrased as a conditional because the pin is repo-owned -- a consumer without one
            # reads a sentence that does not apply, which is strictly better than hitting a red test with no
            # idea it was coming.
            "Add the section first -- directly ABOVE '$targetHeading', at that same heading level:`n`n" +
            "$newHeading`n`n| Version | Date | Type | Title |`n|---|---|---|---|`n`n" +
            "Then, IF this repo pins the targeted major in a test, repoint that assertion at '$newMajor' and`n" +
            "write down why, next to it -- opening the section is what turns it red, and that is the pin doing`n" +
            "its job rather than a broken test. Both edits belong to this cut, so they go on the trunk ahead of`n" +
            "the release commit.`n`n" +
            "Then run this again. Opening a new major's section is a deliberate milestone moment, which is why it`n" +
            "is not done for you."
        }
        Write-Error @"
This release is v$new, but a new row in $historyRelPath would be filed under '$targetHeading'
(the first table in the overview). Nothing was written.

$advice
"@
        exit 1
    }
}

# --- Lint gate ----------------------------------------------------------------------------------
# The release route's OWN gate, and it needs one precisely because this route does not travel via a
# PR: nothing else here ever meets open-pr's copy of it.
#
# RESOLVED THROUGH THE SEAM, not by a fixed path (inbound #464). Until August 5, 2026 this read
# `Join-Path $PSScriptRoot '..\lint\check-plugin-integrity.ps1'` -- the SOURCE repo's own lint script,
# by a path that only exists in the source repo. From a consumer's plugin cache that file is not
# there, so every consumer release ran with no gate at all and said so in a warning nobody had to act
# on. Get-LintScript is the same seam open-pr already reads for exactly this question, so the two
# routes now run the same repo's gate instead of one of them running this repo's.
#
# The measured cost of not having it, in the repo that reported this: two dead links reached its main
# through the release route and would have blocked every subsequent PR. That repo ran a lint here for
# that reason, and adopting the shared script silently took it away again.
#
# A MISSING SCRIPT IS A HARD STOP rather than a warning, which is the second half of the repair. A
# gate that switches itself off on a condition the operator did not choose is not a gate; -SkipLint is
# how you choose it, and choosing it is recorded in the command instead of in output that scrolls past.
if (-not $SkipLint) {
    $lintRel  = Get-SeamValue -Name 'Get-LintScript' -Default 'scripts\lint\check-plugin-integrity.ps1'
    $lintPath = Join-Path $repoRoot $lintRel
    if (-not (Test-Path -LiteralPath $lintPath)) {
        Write-Error "the lint gate '$lintRel' does not exist in the repo root ($repoRoot) -- release aborted. Point Get-LintScript in scripts\repo-config.ps1 at this repo's lint script, or run with -SkipLint to cut without a gate."
        exit 1
    }
    Write-Host "lint gate: integrity check for the release ($lintRel)..." -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File $lintPath
    if ($LASTEXITCODE -ne 0) { Write-Error "the lint gate found errors -- release aborted. Fix them, or run with -SkipLint."; exit 1 }
}

# THE TEST GATE, ADDED AUGUST 7, 2026 (issue #510). Until then the release ran the lint ALONE, which made
# the release commit the least-checked commit in the whole workflow: every ordinary PR passes the lint AND
# all the suites locally, and CI runs both again before the merge is allowed. The release ran one of the
# two, and its push to main is not held back by the required check -- so a red suite could be committed,
# tagged and pushed, with CI reporting it only afterwards, when the tag was already on it.
#
# BEFORE ANY WRITE, deliberately -- same position as the lint above. A release that fails halfway through
# leaves a half-bumped tree on main under one of this repo's two direct-commit exceptions, which is the
# one place a failure is expensive to unpick.
#
# WHAT THIS STILL CANNOT SEE, so nobody reads more into it than it gives: the suites run against the tree
# BEFORE the cut, so a defect the cut itself introduces -- a malformed RELEASE.md card, a broken generated
# note -- is invisible to them. CI on the main push is what catches that, after the fact. The two are
# complementary and neither replaces the other; that is why #510 asks for both.
#
# Shares Invoke-TestSuiteGate with open-pr.ps1 rather than repeating its loop -- one owner, so the two
# gates cannot drift into checking different things.
if (-not $SkipTests) {
    if (-not (Invoke-TestSuiteGate -TestsDir (Join-Path $repoRoot 'scripts\tests') -Context 'the release')) {
        Write-Error "test gate found failing suites -- release aborted, nothing written. Fix the tests, or run with -SkipTests to cut without them."
        exit 1
    }
}

# --- Build content (before the write actions, so a parse error leaves nothing behind) --------
# The notes folder: '<X>.x' per major (this workshop) or '<X.Y>' per minor, from the seam (#417).
# $notesDirName is used for the path, the README row link and the directory creation below, so the
# scheme is answered once rather than three times.
$notesDirName = if ($notesGrouping -eq 'minor') {
    $p = $new -split '\.'; "$($p[0]).$($p[1])"
} else {
    ($new -split '\.')[0] + '.x'
}
$notesRelPath = "releases/development/$notesDirName/$new.md"
$today = (Get-Date -Format 'yyyy-MM-dd')

# $changelogPath / $changelogRaw / $tierGroups / $entries were read up with the bump gate, which had to
# see them before the first write. $entries is the flat list, in document order across the tiers -- the
# per-plugin loop below selects on the 'Plugins:' line and is deliberately tier-blind: a plugin's
# consumer-facing CHANGELOG carries everything that touched that plugin.

# -SummaryFile: an authored milestone block, read here rather than passed as a string, because a
# multi-page summary does not survive a command line. Deliberately NOT required to live in the repo:
# its canonical home becomes the generated notes file, and keeping a second copy under releases/ just
# to feed this parameter would be the duplication this repo removes elsewhere.
$summaryText = ''
if ($SummaryFile) {
    if (-not (Test-Path -LiteralPath $SummaryFile -PathType Leaf)) {
        Write-Error "-SummaryFile '$SummaryFile' does not exist. Nothing was written."
        exit 1
    }
    $summaryText = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $SummaryFile).Path, [System.Text.Encoding]::UTF8)
    if (-not $summaryText.Trim()) {
        # An empty file is a mistake worth stopping on: it would silently produce an ordinary release
        # while the operator believes they cut a milestone.
        Write-Error "-SummaryFile '$SummaryFile' is empty. Nothing was written."
        exit 1
    }
}

# The development notes are grouped BY TIER, each tier a flat ranked list of entries -- the same shape
# CHANGELOG.md has, which is what makes this tier "the whole changelog, raw and complete". A repo whose
# entries declare no tier gets one group and Build-ReleaseNotes renders the flat document it always did.
$notesContent = Build-ReleaseNotes -TierGroups $tierGroups -Version $new -Date $today -Type $typeLabel -Title $Title -Summary $summaryText
# THE CHANGELOG IS EMPTIED, AND NOTHING IS WRITTEN BACK INTO IT (August 5, 2026). This call used to hand
# over the version, the date, the type, the notes path and three seam values to rebuild a release block and
# one section per tier. There is no block and there are no sections: the intro stays as the repo wrote it,
# the entries this release just consumed are removed, and the only thing left saying where releases live is
# the pointer in that intro -- which is why this now takes the content and nothing else.
$changelogNew = Convert-ChangelogForRelease -Content $changelogRaw

# The ONE hand-written release document, drafted here with everything else so a failure leaves no
# half-written release behind. Two documents used to be written per release -- an internal note for the
# organisation and a consumer document -- and both were written at all twelve releases since the internal
# tier existed, about the same changes. This is one file with a named section per reader (Dave, August 10,
# 2026); the measurement that refused a BLENDED document instead is in Build-ReleaseNoteDraft.
#
# THE TWO CONDITIONS SPLIT ACROSS TWO DECISIONS NOW, which is the change. The seam decides whether a
# document is written AT ALL -- so a patch writes none and the release is announced by the generated body
# alone. The tier-2 count decides only whether that document gets a CONSUMER SECTION: the organisational
# half applies to every release the seam names, while a section about work no consumer can see is worse
# than no section, because it looks written.
#
# BEFORE THIS, BOTH CONDITIONS GATED THE WHOLE FILE, so a tier-1-only minor produced no consumer document
# and an internal note from a second script. The audience of each SECTION follows the tier; whether there
# is a document follows the bump.
$tier2Entries = @($tierGroups | Where-Object { [int]$_.Tier -eq 2 } | ForEach-Object { $_.Entries } | Where-Object { $_ })
$cutNote = ($consumerBumps -contains $bumpType)
$noteRelPath = "$noteRootRelPath/$notesDirName/$new.md"
if ($cutNote) {
    $noteWording = Get-SeamValue -Name 'Get-ReleaseNoteWording', 'Get-InternalNoteWording' -Default @{}
    # The link prefix is DERIVED FROM THE NOTE'S OWN DEPTH rather than left at the '../../../' default
    # (August 14, 2026): that default is the depth of releases/audience/<X>.x/, and a consumer whose
    # note root sits inside the workflow folder is one level deeper -- every root-relative link in the
    # note would silently point one directory short. For this repo the derivation produces the default.
    $noteDepth = @($noteRelPath -split '/').Count - 1
    $noteContent = Build-ReleaseNoteDraft -Entries $tier2Entries -Version $new -Date $today `
        -Type $typeLabel -Title $Title -Wording $noteWording -LinkPrefix ('../' * $noteDepth)
}

# --- Write the release-notes file -------------------------------------------------------------
# EVERY target is checked before ANY of them is written. With the consumer tier on there are two
# files, and stopping halfway through would leave a release whose notes exist and whose stakeholder
# document does not -- discovered by the release manager rather than by this guard.
# Kept as REPO-RELATIVE paths and joined per check: the message has to name the file the way the repo
# does, and [System.IO.Path]::GetRelativePath does not exist in the .NET Framework that Windows
# PowerShell 5.1 runs on -- it would throw here instead of reporting the collision it was written for.

# --- The GitHub Release body (generated, every release) -------------------------------------------
# WRITTEN HERE BECAUSE IT CANNOT BE WRITTEN LATER: this run empties CHANGELOG.md, so the entries the
# body is a list of are gone by the time anyone reaches the publish step. Its pointer is gated on a
# hand-written document actually being expected -- naming an attachment that will not exist is exactly
# the sort of confidently wrong line this repo keeps finding in published records.
#
# IT LIVES IN ITS OWN ROOT, AND THE ROOT IS THE STATEMENT (Dave, August 12, 2026). This file used to be
# written into releases/development/ as '<X.Y.Z>-github-body.md', which put the one GENERATED document that
# does get published inside the directory whose whole job is the record nobody publishes. Each root answers
# one question now: development/ is the record, audience/ is the hand-written published document, github/ is
# the generated published one. The '-github-body' suffix went with the move, because the root says it and
# both siblings are '<X.Y.Z>.md' already.
#
# NO SEAM, DELIBERATELY, and the precedent is stated one knob over: Get-ReleaseNoteRoot's contract record
# says releases/development/ "deliberately has no equivalent knob: nobody has been able to show a repo that
# differs on it". A brand-new root has no legacy placement to accommodate either, so it stays hardcoded
# until somebody differs -- and the day they do, that is one function, not a migration.
$bodyRelPath = "releases/github/$notesDirName/$new.md"
$bodyPointer = if ($cutNote) {
    "Whether you need to act, and what it is worth: see the notes attached to this release."
} else {
    ''
}
$bodyContent = Build-GitHubReleaseBody -Entries $entries -Version $new -Title $Title -NotePointer $bodyPointer

$plannedFiles = @($notesRelPath, $bodyRelPath)
if ($cutNote) { $plannedFiles += @($noteRelPath) }
foreach ($rel in $plannedFiles) {
    if (Test-Path -LiteralPath (Join-Path $repoRoot ($rel -replace '/', '\'))) {
        Write-Error "$rel already exists. Nothing was written."
        exit 1
    }
}
$notesAbs = Join-Path $repoRoot ($notesRelPath -replace '/', '\')

$notesDir = Join-Path $repoRoot ("releases\development\$notesDirName")
New-Item -ItemType Directory -Force -Path $notesDir | Out-Null
Write-Utf8NoBom -Path $notesAbs -Content $notesContent
Write-Host "  created: $notesRelPath ($($entries.Count) entries)" -ForegroundColor DarkGray
# THE BODY'S DIRECTORY IS DERIVED FROM ITS OWN PATH rather than rebuilt from the root and the grouping.
# It used to land in $notesDir, so the single New-Item above covered it; now that the two roots differ, a
# second hand-built path would be a second definition of where this file goes. The first cut into a fresh
# major is the run that would find out, because that is the only one where the directory does not exist yet.
$bodyAbs = Join-Path $repoRoot ($bodyRelPath -replace '/', '\')
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $bodyAbs) | Out-Null
Write-Utf8NoBom -Path $bodyAbs -Content $bodyContent
Write-Host "  created: $bodyRelPath (the GitHub Release body -- generated, no editing needed)" -ForegroundColor DarkGray

# --- Update the releases/README.md overview table ------------------------------------------------
# The overview table header is English ("Version | Date | Type | Title", #114 follow-up), so
# $headerRe below matches that; a new row is inserted right after it. The overview is grouped by
# major version (### 2.x, ### 1.x, ... newest first), each group its own table with this same
# header; $headerRe.Match returns the FIRST match, so the row always lands in the top (current
# major) table -- correct for every minor/patch bump. A brand-new major starts a new top section
# manually first (a deliberate milestone moment), after which its table becomes the insertion target.
# Same seam as the guardrail above, so the file this row lands in and the file the changelog points at
# cannot drift apart.
$relReadme = Join-Path $repoRoot ($historyRelPath -replace '/', '\')
$shortTitle = if ($Title) { $Title } else { "$typeLabel release" }
# THE VERSION CELL POINTS AT THE MOST READABLE DOCUMENT THIS RELEASE HAS, and the cut can finally write
# that itself. It used to always name the development notes, with new-internal-note.ps1 repointing the cell
# afterwards (Set-ReleaseInternalNoteLink) for the one reason that the note did not exist while this ran.
# The hand-written note is drafted above now, so the row is right the first time and there is no second
# writer of the same cell. A release with no note -- a patch -- keeps pointing at the record, which is the
# most readable document it has.
# AND IT READS Get-ReleaseNoteRoot RATHER THAN SPELLING THE ROOT OUT. This line carried the literal
# 'notes/' and produced a dead row the day that seam became 'releases/audience' (caught at the v4.6.0 cut,
# August 12, 2026, by the -NoPush inspection). Nothing errored: the row pointed at a file the same run had
# just written somewhere else, and every neighbouring row was correct because a PR had repointed them by
# hand. The rename moved the directory, the reader and the archives, and missed the one place the path was
# a string -- which is why the release manager's lens states 'read the seam, never hardcode the root'.
# AND THE ROW IS COMPUTED RELATIVE TO THE HISTORY FILE'S OWN DIRECTORY (August 14, 2026). This was
# `-replace '^releases/'`, with a comment conceding that a history root outside releases/ "would need a
# '../' here, which no repo has yet asked for" -- the workflow folder is that ask: a consumer's history
# lives at workflow-davekjohn/releases/README.md while the generated development notes stay at the repo
# root. Get-RelativeLinkPath answers both layouts, and for this repo it produces byte-identical rows to
# the old strip.
$historyDirRel = if ($historyRelPath -match '/') { $historyRelPath -replace '/[^/]+$', '' } else { '' }
$rowTargetRel = if ($cutNote) { "$noteRootRelPath/$notesDirName/$new.md" } else { "releases/development/$notesDirName/$new.md" }
$versionTarget = Get-RelativeLinkPath -FromDir $historyDirRel -To $rowTargetRel
$newRow = "| [$new]($versionTarget) | $today | $typeLabel | $shortTitle |"
if (Test-Path $relReadme) {
    $rm = Get-Content -Path $relReadme -Raw -Encoding UTF8
    $rmNl = if ($rm.Contains("`r`n")) { "`r`n" } else { "`n" }
    $headerRe = [regex]"(?m)^\| Version \| Date \| Type \| Title \|\r?\n\|[-| ]+\|\r?\n"
    $hm = $headerRe.Match($rm)
    if ($hm.Success) {
        $at = $hm.Index + $hm.Length
        $rm = $rm.Substring(0, $at) + $newRow + $rmNl + $rm.Substring($at)
        Write-Utf8NoBom -Path $relReadme -Content $rm
        Write-Host "  updated: $historyRelPath" -ForegroundColor DarkGray
    } else {
        Write-Warning "Overview table not found in $historyRelPath -- add the row manually: $newRow"
    }
} else {
    # $historyRelPath, not the literal: the two messages above already use the seam, and this is the one
    # that fires when the file is MISSING -- i.e. exactly when the reader is about to go looking for the
    # path it names. A repo that had repointed the seam was being sent to the default instead.
    Write-Warning "$historyRelPath is missing -- row not added: $newRow"
}

Write-Utf8NoBom -Path $changelogPath -Content $changelogNew

# RETIRED, AUGUST 8, 2026: the per-plugin CHANGELOG.md and RELEASE.md card.
#
# The cut used to write two documents into every plugin directory -- a per-plugin history and a
# snapshot card naming the current version -- on the reasoning that they "travel along with the
# plugin cache" and are therefore what a consumer can actually read. Measured on the day they were
# removed, that reasoning does not hold: the marketplace source is a GIT CLONE OF THE WHOLE REPO, so
# a consumer already has the root CHANGELOG.md and the full releases/ tree at
# ~/.claude/plugins/marketplaces/<marketplace>/. The 11,684 lines in those ten files were a second
# copy of something the reader had all along -- and a copy that could disagree, which is what checks
# 9 and 17 existed to police.
#
# One repository, one product, one changelog. Decision by Dave, August 8, 2026.
#
# What this deliberately does NOT change: the lockstep version bump. plugin.json is still the place a
# plugin's version lives, and it is still bumped for every plugin in step 3a -- a consumer running
# the core team alongside an add-on team still needs matching versions. What is gone is a SECOND statement of that
# same version, in prose, in a file nothing reads back.

# --- 3d. The consumer document (stakeholder-facing; only for the bump types the seam names) ---------
# Content and collision were both settled above, so this block is pure IO. It writes NOTHING when the
# tier is off, which is every release in this repo -- see the seam for why the answer here is empty.
#
# THE NOTE'S DIRECTORY IS DERIVED FROM ITS OWN PATH, exactly as the Release body's is twenty lines up
# and for the same reason. This line built it from a hardcoded 'releases\notes\' until August 13, 2026,
# which is the seam escaping in a THIRD spelling: the two asserts that guard the seam match the
# fully-qualified 'releases/notes', the overview row's escape was the bare 'notes/', and this one was
# invisible to both because it is spelled with a BACKSLASH. Same shape every time -- a matcher that
# reads as thorough and cannot see the instance.
#
# IT WAS NOT COSMETIC. Write-Utf8NoBom is a bare File.WriteAllText and creates no directories, so this
# line made releases/notes/<X>.x/ while the write below went to releases/audience/<X>.x/. It worked only
# because releases/audience/4.x/ already existed from earlier cuts in this major. The first cut into a
# FRESH major would have created the wrong directory, thrown DirectoryNotFoundException on the write,
# and died mid-run on main -- after the development notes, the Release body and the releases/README.md
# row, before the version bump and the commit. Found on a filesystem rather than by a gate: git tracks
# no empty directory, so the stray releases/notes/4.x/ this left behind at every cut since the rename
# appeared in no commit, no git status, and in front of nothing.
if ($cutNote) {
    $noteAbs = Join-Path $repoRoot ($noteRelPath -replace '/', '\')
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $noteAbs) | Out-Null
    Write-Utf8NoBom -Path $noteAbs -Content $noteContent
    $sectionCount = if ($tier2Entries.Count -gt 0) { 'consumer + organisation sections' } else { 'organisation section only -- no entry reached tier 2' }
    Write-Host "  created: $noteRelPath (draft -- $sectionCount)" -ForegroundColor DarkGray
}

# --- Bump plugin versions (regex on the version line -- preserves the JSON formatting) -----------
foreach ($p in $manifests) {
    $raw = Get-Content -Path $p.ManifestPath -Raw -Encoding UTF8
    $bumped = [regex]::Replace($raw, '("version"\s*:\s*")\d+\.\d+\.\d+(")', "`${1}$new`$2", 1)
    Write-Utf8NoBom -Path $p.ManifestPath -Content $bumped
    Write-Host "  bumped: $($p.Name)/.claude-plugin/plugin.json -> $new" -ForegroundColor DarkGray
}

# The follow-up documents this script deliberately does NOT write, printed once at the end whether or
# not the tag was pushed. Both are hand-written and both need the notes that only exist after this run:
# the consumer DRAFT (generated above -- the tier-2 entries, selected but not yet rewritten for their
# reader) and the internal note (its own script, because a skeleton committed here would sit inside the
# release tag).
#
# GATED ON THE SCRIPT EXISTING rather than on a config knob: whether a repo has an internal tier is a
# fact its file tree already answers, so a repo without that script simply never sees the line. Same
# reasoning as Get-ReleasePluginTier's computed fallback.
#
# WHICH FILE TREE, THOUGH -- that is what inbound #461 caught. The probe looked only in the CONSUMER's
# repo root, where a consumer has no copy, that being the entire point of the mirror. So the reasoning
# above held in the source and inverted everywhere else: the tree answered "no internal tier" for a repo
# that has one, and the line about the one tier written at EVERY release, patch included, was the one
# line a consumer never got. It is also the tier nothing else reminds you about.
#
# So the repo's own copy is tried first and the sibling that travels with THIS script second. The fact
# is still read off a file tree; it is now read off the tree that can answer it -- a repo running this
# script has the note's script beside it, because they are mirrored together.
#
# AND THE PRINTED PATH IS THE RESOLVED ONE (inbound #460's class, one file over): './scripts/release/...'
# is a command in the source repo and a dead path in a consumer. A checklist that prints something
# unrunnable is worse than one that prints something long.
function Write-FollowUpSteps {
    # The body is generated, so it is reported whether or not anything is left to write by hand -- a
    # patch with no hand-written document still gets a Release page, which is the whole point of
    # generating it.
    Write-Host ""
    Write-Host "The GitHub Release body is written for you:" -ForegroundColor Cyan
    Write-Host "  gh release create $tagName --title `"$tagName - <short title>`" --notes-file $bodyRelPath"

    # ONE DOCUMENT, AND NO SECOND SCRIPT TO INVOKE (Dave, August 10, 2026). This block used to name two
    # follow-ups: the consumer draft, and an invocation of new-internal-note.ps1 gated on that script being
    # present in one of two trees -- machinery that existed only because the second document was written by
    # a second tool AFTER the cut. The draft above is both readers' sections in one file, so the follow-up
    # is an edit rather than a command. new-internal-note.ps1 is still shipped and still works for a repo
    # running the two-document flow; nothing here calls it.
    if (-not $cutNote) { return }
    Write-Host ""
    Write-Host "Still to write by hand (via a branch + PR -- this commit is already tagged):" -ForegroundColor Cyan
    Write-Host "  - $noteRelPath"
    if ($tier2Entries.Count -gt 0) {
        Write-Host "      the consumer section is a DRAFT (the tier-2 entries, in the words their authors wrote for a reviewer);"
        Write-Host "      'what it is worth' and 'what was still open' are empty and cannot be generated."
    } else {
        Write-Host "      no entry reached tier 2, so it carries the organisation's sections only -- both empty."
    }
}

# --- Commit + tag directly on main ---------------------------------------------------------
# Native git writes chatter to stderr (the LF->CRLF warning from `git add`, `remote:` on push).
# Under ErrorActionPreference=Stop, PowerShell 5.1 would promote that to a terminating
# NativeCommandError before the $LASTEXITCODE checks -- the pitfall that broke cutting v1.12.0 on
# `git add` (#107). Invoke-NativeCapture (#114) runs each git call under EAP=Continue and hands back
# output + exit code, so we rely purely on $LASTEXITCODE; the captured chatter is echoed so the
# release run stays as verbose as before.
$add = Invoke-NativeCapture -FilePath 'git' -Arguments @('add', '-A')
$add.Output | ForEach-Object { Write-Host $_ }
if ($add.ExitCode -ne 0) { Write-Error "git add failed."; exit 1 }

$commit = Invoke-NativeCapture -FilePath 'git' -Arguments @('commit', '-m', "release: v$new")
$commit.Output | ForEach-Object { Write-Host $_ }
if ($commit.ExitCode -ne 0) { Write-Error "git commit failed."; exit 1 }

$tag = Invoke-NativeCapture -FilePath 'git' -Arguments @('tag', '-a', $tagName, '-m', "Release $tagName")
$tag.Output | ForEach-Object { Write-Host $_ }
if ($tag.ExitCode -ne 0) { Write-Error "git tag failed."; exit 1 }

if ($NoPush) {
    Write-Host ""
    Write-Host "Release v$new recorded locally on main (commit + tag $tagName), not pushed." -ForegroundColor Green
    Write-Host "Push it yourself when ready:" -ForegroundColor Cyan
    Write-Host "  git push origin main; git push origin $tagName"
    Write-FollowUpSteps
    exit 0
}

$pushMain = Invoke-NativeCapture -FilePath 'git' -Arguments @('push', 'origin', 'main')
$pushMain.Output | ForEach-Object { Write-Host $_ }
if ($pushMain.ExitCode -ne 0) { Write-Error "git push of main failed."; exit 1 }

$pushTag = Invoke-NativeCapture -FilePath 'git' -Arguments @('push', 'origin', $tagName)
$pushTag.Output | ForEach-Object { Write-Host $_ }
if ($pushTag.ExitCode -ne 0) { Write-Error "git push of the tag failed."; exit 1 }

Write-Host ""
Write-Host "Done: v$new has been cut ($current -> $new, $typeLabel), committed on main and tagged as $tagName. Recorded." -ForegroundColor Green
Write-FollowUpSteps
