<#
.SYNOPSIS
    Repo-owned configuration for the workflow scripts (single source of truth for repo data).

.DESCRIPTION
    Dot-source this file from a script:

        . (Join-Path $PSScriptRoot '..\repo-config.ps1')   # from scripts/<folder>/
        . (Join-Path $PSScriptRoot 'repo-config.ps1')       # from scripts/ itself

    This is the small, local block of repo data that the (increasingly generic) workflow scripts
    read in. The scripts themselves are repo-agnostic; everything that differs per repo lives
    here. This way a change to the shared flow does not need to be checked in every consumer --
    only this file differs between life-hub, smartwatchbanden and the workshop.

    Supplies Get-RepoName and Get-RepoBlobUrl. Replaces the repo name that used to be hardcoded in
    open-pr.ps1, fold-changelog-entry.ps1 (2x) and cut-release.ps1 (via release-lib).

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script and
    could break loose code there (same reason as branch-info.ps1 / release-lib.ps1).

    Deliberately pure ASCII (repo convention for .ps1): Windows PowerShell 5.1 reads a BOM-less
    script as ANSI and would mangle an accented literal.
#>

# The GitHub repo where this workshop lives (owner/name). Single place this is stated.
$script:RepoName = 'DaveKJohn/claude-code-specialists'

function Get-RepoName {
    <# owner/name of this repo, e.g. for `gh ... --repo`. #>
    return $script:RepoName
}

function Get-RepoBlobUrl {
    <# Base URL for blob links to main, e.g. to make root-relative links absolute. #>
    return "https://github.com/$($script:RepoName)/blob/main/"
}

# This repo's lint gate, repo-root-relative. open-pr.ps1 runs this before the PR. This is the
# only repo-specific part of open-pr: every consumer has its own lint (the workshop
# check-plugin-integrity, a Brains repo e.g. lint-brain). The test gate is pure convention
# (scripts/tests/*.tests.ps1) and needs no config.
$script:LintScript = 'scripts\lint\check-plugin-integrity.ps1'

function Get-LintScript {
    <# Repo-root-relative path to the lint gate that open-pr.ps1 runs before the PR. #>
    return $script:LintScript
}

# The file that holds the roster (the specialists table/list). check-roster-sync.ps1 reads this to
# decide which agent ids are "present in the roster". Repo-root-relative; 'CLAUDE.md' by default.
# There is deliberately NO Get-RosterFormat: the check is format-agnostic (it scans the text for each
# <group>-<id> token), so it works whether the roster is a table or a list.
# The roster moved behind the seam (issue #221): CLAUDE.md now carries one import line and no roster,
# so check-roster-sync must read the inclusion instead. Getting this wrong is silent in the worst way --
# the check would find zero specialists in a file that legitimately has none, and report the whole roster
# as missing.
$script:RosterPath = '.claude/specialists/SPECIALISTS.md'

function Get-RosterPath {
    <# Repo-root-relative path to the file that holds the roster (specialists table/list). #>
    return $script:RosterPath
}

# Specialist ids ('<group>-<id>') that are ENABLED but deliberately have no roster row and no lens, so
# check-roster-sync.ps1 must not flag them as drift.
#
# EMPTY, and that is the normal state -- for this workshop as much as for a fresh consumer. Every
# enabled specialist belongs in the roster. Adopting one is the default and needs no approval (Dave,
# July 28, 2026): the lens scaffold is empty on purpose and may stay empty until that specialist has
# work here, so adopting costs a file nobody has to fill in today. See the sync-roster skill's
# SKILL.md for the full reasoning.
#
# Why this is worth a comment rather than just an empty array -- the list used to hold six ids, and
# none of them were ever a decision. It was introduced on 2026-07-20 by the very commit that built
# check-roster-sync (d2c8393), pre-populated with Paula/Vera/Gwen/Cody, and justified in this file as
# "a documented choice in CLAUDE.md". CLAUDE.md said no such thing: it said those specialists "rarely
# has work here and therefore has no repo lens (yet)" -- a statement about the current state, with an
# explicit "yet". The list converted "not yet" into "never report this", and then cited Dave for it.
# Auden (06-30) was added on 2026-07-24 as a blocking code-review finding whose stated reason was
# literally "so the roster hook does not flag Auden as drift after merge"; Bianca (03-02) was added on
# 2026-07-28 with the same reflex. Dave, asked about it, did not recognise the list as his.
#
# So the rule, in one line: a check that reports something inconvenient is not silenced by a list.
# If a specialist ever genuinely has no place in a repo, that goes here as a deliberate statement with
# a comment naming who and why -- written on your own initiative, never as a way to quiet a finding.
$script:RosterIgnoredIds = @()

function Get-RosterIgnoredIds {
    <# Ids of enabled agents/personas intentionally kept out of the roster/lenses (skipped by the
       check). #>
    return $script:RosterIgnoredIds
}

# The CHANGELOG.md section heading that fold-changelog-entry.ps1 folds a merged entry into. This
# workshop keeps merged PRs under '## Pull Requests' (with '## Releases' below it); a consumer on
# Keep-a-Changelog uses '## [Unreleased]'. The heading used to be hardcoded in the fold script, which
# made it stop outright on any repo that names its section differently (issue #178). Optional in the
# contract: a consumer without this function simply gets the default below.
$script:ChangelogHeading = '## Pull Requests'

function Get-ChangelogHeading {
    <# The CHANGELOG.md section heading a folded entry is inserted under. Must be the literal heading
       line as it appears in the file (including the leading '##'). #>
    return $script:ChangelogHeading
}

# Whether this repo has a separate "go live" stage after cutting a release -- e.g. a push to a live
# deploy target, distinct from the tag/GitHub Release. Empty by default: this workshop (like
# life-hub) cuts a release without one, so the cut-release skill's Block 2 (the live push + moving
# the '<- LIVE' marker) never applies here. A repo that DOES have a live stage (e.g. a theme repo
# pushing to a live Shopify theme) describes its target in this string; the cut-release skill then
# prints Block 2 using it. Optional in the contract (see check-script-contract.ps1): a consumer
# without this function simply gets Block 1 only, same pattern as Get-ChangelogHeading (#178).
$script:LiveStage = ''

function Get-LiveStage {
    <# Short description of this repo's "go live" push target for the cut-release skill's Block 2.
       Empty string means: no separate live stage -- the skill only prints Block 1 (cutting). #>
    return $script:LiveStage
}

# --- The stub wording new-changelog-entry.ps1 writes into an entry file (issue #410) ---------------
#
# The four strings below are the entire visible output of the shared new-changelog-entry.ps1: the title
# placeholder, the body heading, the fallback body, and the changelog type an unknown branch prefix
# falls back to. They used to be hardcoded in that script, which is fine for an English repo and wrong
# for any other -- the FILE it writes is repo-owned, so its wording is too.
#
# The concrete case (inbound #410, smartwatchbanden): a Dutch-language repo kept its own copy of
# new-changelog-entry.ps1 at the same relative path, purely to change these four strings. Two entry
# points then wrote two formats for the same branch -- the branch flow called the repo copy, the
# new-branch skill called the shared one -- which is exactly the duplication the skill exists to
# prevent. Dropping the copy fixed the duplication and cost them Dutch stubs; these functions give the
# wording back without the copy.
#
# All four are OPTIONAL in the script contract: a consumer that defines none of them gets the values
# below, which are also what the script hardcoded before. Same pattern as Get-ChangelogHeading (#178)
# and Get-LiveStage (#177). Four separate functions rather than one map-returning function, so the
# contract check can name the exact default per knob in its [INFO] line.
$script:EntryTitlePlaceholder = 'TODO: title'
$script:EntryBodyHeading      = '**To do / where I left off:**'
$script:EntryBodyPlaceholder  = 'TODO: what still needs to happen on this branch, and where you left off.'
$script:EntryFallbackType     = 'Chore'

function Get-EntryTitlePlaceholder {
    <# Placeholder title for an entry created without an explicit -Title. #>
    return $script:EntryTitlePlaceholder
}

function Get-EntryBodyHeading {
    <# The bold line above the entry body. Must be a single line; it is written verbatim. #>
    return $script:EntryBodyHeading
}

function Get-EntryBodyPlaceholder {
    <# Fallback body when no -Intent was given -- a directional prompt, not an empty placeholder. #>
    return $script:EntryBodyPlaceholder
}

function Get-EntryFallbackType {
    <# The changelog type an unknown branch prefix falls back to. Must be one of the types this repo's
       own branch table produces, since cut-release groups entries by it. #>
    return $script:EntryFallbackType
}

# --- Which files the mojibake tool examines by default (issue #413) -------------------------------
#
# scripts/maintenance/fix-mojibake.ps1 used to carry this list itself, and the list is workshop-shaped:
# it walks plugins/** for the per-plugin CHANGELOG.md/RELEASE.md and releases/** for the archived notes.
# In a consumer neither directory exists, so the tool's own Test-Path filter quietly reduced the set to
# whatever root docs happened to be there -- a gate that examines almost nothing while reporting
# "clean". Which files a repo has is a property of the repo, so the list belongs here.
#
# Takes the repo root as a parameter rather than resolving one of its own: the caller has already done
# that (dual-context, CLAUDE_PROJECT_DIR or the git root), and a second resolution here is a second
# answer to a one-answer question. The Get-ChildItem work sits INSIDE the function on purpose -- this
# file is dot-sourced by every workflow script, and none of the others should pay for a directory walk
# they never use.
#
# OPTIONAL in the contract: a consumer without this function gets the tool's own repo-agnostic
# fallback -- every *.md in the repo root, which covers the changelog, the root docs and the unfolded
# entry files in any repo. That fallback is deliberately broader than what this workshop's list used to
# be, because an entry file is exactly the kind of freshly written, non-ASCII-carrying file the damage
# shows up in first.
function Get-MojibakePaths {
    <# Absolute paths of the files fix-mojibake.ps1 examines when called without -Path. #>
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    # Every markdown file in the repo root: CHANGELOG.md, the root docs, and any unfolded entry file.
    $paths = @(Get-ChildItem -LiteralPath $RepoRoot -Filter '*.md' -File |
        Select-Object -ExpandProperty FullName)

    # Every markdown file under plugins/: the per-plugin CHANGELOG.md and RELEASE.md that cut-release.ps1
    # writes entry text into, and the manuals, agent defs and personas beside them -- all prose, all
    # equally able to carry a mis-decode.
    #
    # -Filter, NOT -Include, and that is a bug fix rather than a preference. PowerShell SILENTLY IGNORES
    # -Include when the path is given as -LiteralPath, so the previous form --
    # `Get-ChildItem -LiteralPath $pluginRoot -Recurse -File -Include 'CHANGELOG.md','RELEASE.md'` --
    # returned EVERY file under plugins/, .ps1 and .json included, while the comment above it named two
    # file names. Nothing broke, because the extra files were clean and the tool leaves anything that is
    # not mojibake alone; what was wrong is that the code and its own description disagreed, and the
    # description is what the lint gate quotes to the reader as its coverage.
    $pluginRoot = Join-Path $RepoRoot 'plugins'
    if (Test-Path -LiteralPath $pluginRoot) {
        $paths += @(Get-ChildItem -LiteralPath $pluginRoot -Recurse -File -Filter '*.md' |
            Select-Object -ExpandProperty FullName)
    }

    # THE ARCHIVED RELEASE NOTES, added August 2, 2026 after they turned out to hold the largest single
    # concentration of damage in the repo (474 sequences in 3.1.0.md alone, more than the root
    # changelog). They sit outside the language rule because they are history, but the two questions are
    # not the same: not translating an old note preserves what it said, while leaving mojibake in it
    # preserves a mis-decode nobody wrote.
    $releasesRoot = Join-Path $RepoRoot 'releases'
    if (Test-Path -LiteralPath $releasesRoot) {
        $paths += @(Get-ChildItem -LiteralPath $releasesRoot -Recurse -File -Filter '*.md' |
            Select-Object -ExpandProperty FullName)
    }

    return @($paths | Sort-Object -Unique)
}

# --- How ship-pr.ps1 merges a PR (issue #411) -----------------------------------------------------
#
# 'merge', 'squash' or 'rebase' -- the flag ship-pr.ps1 hands `gh pr merge`. This workshop merges, so
# every PR keeps its own commits on main; a repo that squashes says so here instead of keeping a
# private copy of ship-pr.
#
# Declared even though inbound #411 argued a shared ship-pr would need NO new contract function. That
# claim did not survive reading both files: the source merges with --merge while the reporting repo
# describes its own flow as squash-merging, so the two genuinely differ on exactly this, and a shared
# script with a hardcoded --merge would silently impose one repo's policy on the other. OPTIONAL, with
# 'merge' as the fallback, so nothing changes for a consumer that does not care.
$script:PrMergeMethod = 'merge'

function Get-PrMergeMethod {
    <# The merge method ship-pr.ps1 uses: 'merge', 'squash' or 'rebase'. #>
    return $script:PrMergeMethod
}

# --- What cut-release.ps1 does differently per repo (issue #417) -----------------------------------
#
# cut-release.ps1 became a SHARED script in #417, after an audit in a second consumer found the two
# repos running two independently evolved files of the same name. The stated goal is that both repos
# run exactly the same release workflow, and the inbound issue named three divergences. Reading both
# files found SIX, and the largest one was not on that list -- so the knobs below are what the
# measurement produced rather than what the report predicted:
#
#   1. where the notes are grouped        Get-ReleaseNotesGrouping    (named in the issue)
#   2. the highlights tier                Get-ReleaseHighlightsBumps  (named in the issue)
#                                         + Get-ReleaseHighlightsStakeholderTypes
#                                         + Get-ReleaseHighlightsWording
#   3. the LIVE marker                    Get-ReleaseLiveMarker       (named in the issue)
#   4. the plugin/marketplace half        Get-ReleasePluginTier       (NOT named -- the largest block)
#   5. the category labels                Get-ReleaseCategoryTitles   (NOT named)
#   6. the permanent root docs            Get-ReservedRootMd          (NOT named)
#
# KNOB 2 LANDED IN PHASE 2 and needed three functions rather than one, because "the highlights tier"
# turned out to be three independent questions and answering them with one config object would have
# given the script contract a single record whose 'Returns' line could not say anything actionable:
#
#   Bumps             -- WHETHER, and for which bump types. @() switches the tier off entirely.
#   StakeholderTypes  -- WHICH branch types a non-developer is the audience for. The rest of the
#                        release lands under the remove-before-publishing marker.
#   Wording           -- the words on that marker. One function rather than two, unlike the four #410
#                        entry stubs: those are chosen independently, while these are one document's
#                        language and are always set together. (It briefly also carried an HTML lang
#                        attribute; the tier produces no HTML -- see below.)
#
# ALL EIGHT ARE OPTIONAL in the script contract, and every fallback is this workshop's CURRENT
# behaviour -- so a consumer that defines none of them gets exactly what the unshared script did.
# Same pattern as Get-ChangelogHeading (#178) and the entry-stub wording (#410).

# 'major' -> releases/development/<X>.x/<X.Y.Z>.md   (this workshop)
# 'minor' -> releases/development/<X.Y>/<X.Y.Z>.md   (a repo that cuts often enough for that to help)
$script:ReleaseNotesGrouping = 'major'

function Get-ReleaseNotesGrouping {
    <# How the generated release notes are foldered: 'major' or 'minor'. #>
    return $script:ReleaseNotesGrouping
}

# The "this is the version currently live" suffix on the newest '## Releases' row. EMPTY here, and
# that is not an oversight: a marketplace has no live stage, so there is no such thing as the live
# version -- consumers install from `main` at a moment of their own choosing. A repo that DOES push
# to a live target (a theme repo pushing to a live storefront) sets its marker here, and
# Convert-ChangelogForRelease then MOVES it from the previous row to the new one.
#
# Deliberately separate from Get-LiveStage above, which the cut-release SKILL reads to decide whether
# to print its live-push block. Two questions, one repo: "do you have a live stage" is prose for a
# human, "what marks the live row" is a string a script writes into a file. A repo can have the first
# without wanting the second.
$script:ReleaseLiveMarker = ''

function Get-ReleaseLiveMarker {
    <# The literal marker appended to the newest release heading, e.g. '<- **LIVE**'. Empty = none. #>
    return $script:ReleaseLiveMarker
}

# Whether cut-release runs the plugin/marketplace half: enumerating the manifests from
# .claude-plugin/marketplace.json, writing each plugin's consumer-facing CHANGELOG.md and RELEASE.md
# card, and bumping every plugin.json in lockstep. TRUE here -- that half IS this repo's release.
#
# THE ONE KNOB WITH A COMPUTED FALLBACK, and the reason is that its answer is a fact rather than a
# preference: a repo with no .claude-plugin/marketplace.json has no plugins to bump, so a consumer
# that never heard of this function gets the right behaviour without stating anything. Stated
# explicitly here anyway, because in THIS repo the answer is load-bearing and a release that
# silently skipped the lockstep bump would be discovered by a consumer rather than by a gate.
$script:ReleasePluginTier = $true

function Get-ReleasePluginTier {
    <# $true if this repo publishes plugins that cut-release must version and card. #>
    return $script:ReleasePluginTier
}

# Display labels for the release-notes categories, keyed on the branch TYPES from
# scripts/lib/branch-info.ps1. Only the ones that differ from release-lib's English defaults
# (Feat -> Features, Fix -> Fixes, Docs -> Documentation, Chore -> Maintenance, Other -> Other) need
# to appear; the map is merged over those rather than replacing them.
#
# EMPTY HERE, and that is the correct state for an English repo: the defaults already say what this
# repo means. The knob exists for a non-English consumer, where an unlabelled type degrades to the
# type name -- the wrong word rather than a missing one. Precisely the #410 case one level up.
$script:ReleaseCategoryTitles = @{}

function Get-ReleaseCategoryTitles {
    <# type -> label overrides for the release-notes category headings. Empty = use the defaults. #>
    return $script:ReleaseCategoryTitles
}

# The permanent root *.md files that are NOT unfolded changelog entries. cut-release treats every
# OTHER root *.md as an entry somebody forgot to fold (deliberately catch-all, so an entry with an
# unknown branch prefix is never missed), and refuses to cut while one exists.
#
# THIS LIST HAS GONE STALE THREE TIMES AND EACH TIME IT BLOCKED A RELEASE OVER A DOCUMENT NOBODY HAD
# FAILED TO FOLD: #165 first, then QUICKSTART.md + UNINSTALL.md in #405 when flattening moved them to
# the root, then ADOPTION.md in #408. It lived in the script until now, which made it a fourth thing a
# consumer would have had to fork the script over -- so it moves here, where the answer actually
# lives. Add a new permanent root doc here, and nowhere else.
$script:ReservedRootMd = @(
    'CHANGELOG.md', 'CLAUDE.md', 'README.md', 'LICENSE.md', 'CONTRIBUTING.md', 'SECURITY.md',
    'QUICKSTART.md', 'ADOPTION.md', 'UNINSTALL.md'
)

function Get-ReservedRootMd {
    <# File names in the repo root that are permanent docs rather than unfolded changelog entries. #>
    return $script:ReservedRootMd
}

# --- The highlights tier: whether, for whom, and in whose words (issue #417, knob 2) --------------
#
# The second, stakeholder-facing rendering of a release: releases/highlights/<dir>/<X.Y.Z>.md. Written
# for NON-DEVELOPERS (Dave, July 13, 2026), so the generated draft puts the stakeholder categories
# first and everything else under an explicit "remove before publishing" marker for the release manager
# to cut by hand. MARKDOWN ONLY -- the tier briefly also generated a print-ready .html and no longer
# does anywhere (Dave, August 3, 2026); whoever wants a PDF renders the markdown with a real tool.
#
# ON IN THIS REPO SINCE AUGUST 3, 2026, for minor and major only -- Dave's decision, and it reversed
# what this file said one commit earlier. The reasoning that had it off was that this repo's release
# audience "is developers", so a stakeholder document would have no reader. That was the wrong unit of
# analysis: the audience question is not developer-vs-not, it is WHO DECIDES WHETHER TO UPDATE. That
# reader does not want the full per-PR record, and giving them only the developer notes is the same
# mismatch a storefront repo has with its management -- one tier serving two audiences badly.
#
# So this repo runs the same three tiers as the consumer it was ported from:
#   releases/development/<X>.x/<X.Y.Z>.md   developers   -- every release, auto-complete, long
#   releases/internal/<X>.x/<X.Y.Z>.md      colleagues   -- every release, what it is worth
#   releases/highlights/<X>.x/<X.Y.Z>.md    consumers    -- minor/major only, what they notice
#
# PER MAJOR, NOT PER MINOR (Dave, August 3, 2026). The consumer this came from folders its notes per
# minor; this repo keeps <X>.x for all three tiers, which Get-ReleaseNotesGrouping above already says
# and every tier reads from that one answer rather than restating it.
#
# WHY MINOR/MAJOR AND NOT PATCH: a minor here is cut when a consumer actually notices something. That
# is the same test the version number itself answers, so the tier and the bump agree by construction --
# a patch has nothing a consumer would read, which is precisely why it is a patch.
$script:ReleaseHighlightsBumps = @('minor', 'major')

function Get-ReleaseHighlightsBumps {
    <# Bump types that also get a highlights document: e.g. @('minor','major'). Empty = tier off. #>
    return $script:ReleaseHighlightsBumps
}

# Which branch types a non-developer reader is the audience for; every other category present lands in
# the developer-only block. Keyed on the TYPES from scripts/lib/branch-info.ps1, like
# Get-ReleaseCategoryTitles above -- not on the display labels, which a consumer may have renamed.
#
# READ THE MARKER AS A PROPOSAL, NOT A VERDICT, and in this repo more so than in the one this was
# ported from. There, a 'Style' or 'Content' branch IS a storefront change, so the prefix predicts the
# impact. HERE IT MEASURABLY DOES NOT: held against the 19 entries pending at v3.2.0, the single most
# consequential change for a consumer -- renaming the marketplace, which breaks every existing install
# -- arrived on a chore/ branch and therefore lands BELOW the marker, as did "a folder rename silently
# unlinks plugin installs" on a docs/ one.
#
# Feat+Fix is kept anyway, deliberately: the split's value is that both halves are written out and the
# release manager sees what is a candidate for cutting. A wrong-but-visible proposal costs one edit; the
# alternative (no split at all) costs the hint entirely. So when editing the draft, expect to promote
# Docs/Chore items rather than trusting the halves.
$script:ReleaseHighlightsStakeholderTypes = @('Feat', 'Fix')

function Get-ReleaseHighlightsStakeholderTypes {
    <# Branch types whose entries go above the remove-before-publishing marker. Empty = no split. #>
    return $script:ReleaseHighlightsStakeholderTypes
}

# The words on the marker -- the #410 class one level up. A repo whose stakeholders read Dutch
# generates a Dutch document, and a hardcoded English heading in it is the wrong word rather than a
# missing one. Only the keys that differ from release-lib's English defaults need to appear; the map is
# merged over them rather than replacing them. Two keys now: DevBlockComment and DevBlockHeading.
#
# EMPTY HERE for the same reason Get-ReleaseCategoryTitles is: the defaults already say what an
# English repo means. The tier is ON now, so these ARE read -- an empty map means the English defaults
# reach the generated document, not that nothing happens.
$script:ReleaseHighlightsWording = @{}

function Get-ReleaseHighlightsWording {
    <# Overrides for the highlights tier's own text: DevBlockComment, DevBlockHeading. #>
    return $script:ReleaseHighlightsWording
}
