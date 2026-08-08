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

# --- RETIRED, AUGUST 5, 2026: Get-ChangelogTierHeadings ------------------------------------------
#
# This mapped tier -> the literal '## ' heading its entries were folded under, and CHANGELOG.md carried
# one section per tier: '## Tier 2 - Pull Requests' and its two siblings, in that order, so a reader met
# the changes that reach furthest first.
#
# CHANGELOG.md HAS NO SECTION HEADINGS ANY MORE. An entry IS an H2 and the document is an intro followed
# by a flat list of them, ordered tier-descending then significance-descending -- which keeps exactly what
# the three headings communicated, as an ordering rather than as structure. So there is no heading for
# this map to name.
#
# The fold and release-lib derive the intro/list boundary structurally instead (the first entry heading,
# from Get-EntryHeadingLevel), which is why the resolver that read this seam --
# Get-ChangelogTierSections in scripts/lib/entry-scaffold-lib.ps1 -- retired with it. The older
# single-section Get-ChangelogHeading (issue #178) is no longer read either, and was already absent here.
#
# Removed rather than left returning a value nothing reads, which is this file's own rule about
# write-once config. A consumer that still defines either function is unaffected: nothing calls them.

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

# --- The stub wording new-branch.ps1 writes into an entry file (issue #410) ---------------
#
# The four strings below are the entire visible output of the shared new-branch.ps1: the title
# placeholder, the body heading, the fallback body, and the changelog type an unknown branch prefix
# falls back to. They used to be hardcoded in that script, which is fine for an English repo and wrong
# for any other -- the FILE it writes is repo-owned, so its wording is too.
#
# The concrete case (inbound #410, smartwatchbanden): a Dutch-language repo kept its own copy of
# new-branch.ps1 at the same relative path, purely to change these four strings. Two entry
# points then wrote two formats for the same branch -- the branch flow called the repo copy, the
# new-branch skill called the shared one -- which is exactly the duplication the skill exists to
# prevent. Dropping the copy fixed the duplication and cost them Dutch stubs; these functions give the
# wording back without the copy.
#
# All four are OPTIONAL in the script contract: a consumer that defines none of them gets the values
# below, which are also what the script hardcoded before. Same pattern as Get-ChangelogHeading (#178)
# and Get-LiveStage (#177). Four separate functions rather than one map-returning function, so the
# contract check can name the exact default per knob in its [INFO] line.
#
# TWO OF THEM ARE NOW GATE-ONLY (August 6, 2026). Since the branch/ split, new-branch.ps1 writes
# neither the body heading nor the old to-do placeholder -- branch-progress.md carries the step list, and
# the entry's placeholder asks what the change DOES. The body heading stays defined here because it is
# still a marker open-pr refuses, so a consumer who translated it keeps a gate that recognises their
# wording rather than only the English one. See $script:EntryScaffoldDefaults in entry-scaffold-lib.ps1.
$script:EntryTitlePlaceholder = 'TODO: title'
$script:EntryBodyHeading      = '**To do / where I left off:**'
$script:EntryBodyPlaceholder  = 'TODO: what this change does, for whoever reads CHANGELOG.md later.'
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
# it walks plugins/** for the manuals, agent defs and personas, and releases/** for the archived notes.
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

    # Every markdown file in the repo root: CHANGELOG.md and the root docs.
    $paths = @(Get-ChildItem -LiteralPath $RepoRoot -Filter '*.md' -File |
        Select-Object -ExpandProperty FullName)

    # branch/ -- the branch's entry and step list. They were covered by the root glob above until the split
    # moved them (August 6, 2026), and the entry is the single highest-value file in this set: its text is
    # pasted verbatim into CHANGELOG.md and from there into the release notes, so a mis-decode caught
    # anywhere later has already been copied twice.
    # -Recurse for templates/: those are pasted into a real entry, so a mis-decode there is copied forward
    # into every branch that uses them rather than staying in one file.
    $branchDir = Join-Path $RepoRoot 'branch'
    if (Test-Path -LiteralPath $branchDir) {
        $paths += @(Get-ChildItem -LiteralPath $branchDir -Recurse -Filter '*.md' -File |
            Select-Object -ExpandProperty FullName)
    }

    # Every markdown file under plugins/: the manuals, agent defs, personas and skill pages -- all prose,
    # all equally able to carry a mis-decode. It used to name the per-plugin CHANGELOG.md and RELEASE.md
    # first; those were retired on August 8, 2026 and the rest of the set is unchanged.
    #
    # -Filter, NOT -Include, and that is a bug fix rather than a preference. PowerShell SILENTLY IGNORES
    # -Include when the path is given as -LiteralPath, so the previous form --
    # `Get-ChildItem -LiteralPath $pluginRoot -Recurse -File -Include 'CHANGELOG.md','RELEASE.md'` --
    # returned EVERY file under plugins/, .ps1 and .json included, while the comment above it named two
    # file names. Nothing broke, because the extra files were clean and the tool leaves anything that is
    # not mojibake alone; what was wrong is that the code and its own description disagreed, and the
    # description is what the lint gate quotes to the reader as its coverage. Worth keeping now that the
    # two named files are gone: the WIDE set is what this function has actually returned all along.
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
#   3. the LIVE marker                    Get-ReleaseLiveMarker       (named in the issue)   RETIRED Aug 5
#   4. the plugin/marketplace half        Get-ReleasePluginTier       (NOT named -- the largest block)
#   5. the category labels                Get-ReleaseCategoryTitles   (NOT named)            RETIRED Aug 5
#   6. the permanent root docs            Get-ReservedRootMd          (NOT named)
#
# TWO OF THE SIX ARE GONE (August 5, 2026), and both for the same reason rather than two: the flat
# changelog. Knob 3 marked the live row of a release section CHANGELOG.md no longer has; knob 5 labelled
# category headings the release documents no longer have. Each retirement is written out at the place it
# used to sit, below. Recorded here too because this list is the record of what the #417 measurement
# found, and a list that quietly shrinks stops being that.
#
# KNOB 2 LANDED IN PHASE 2 AS THREE FUNCTIONS AND IS BACK TO ONE (August 5, 2026). "The highlights
# tier" was three independent questions -- whether, for whom, and in whose words -- and the second and
# third existed only to configure the remove-before-publishing marker. The tier model retired that
# marker (see the block further down), which retired both knobs with it: what a consumer notices is now
# declared per entry rather than guessed per branch type. Only 'whether, and for which bump types'
# survives, because that is the one question the entries cannot answer for the repo.
#
# ALL SIX ARE OPTIONAL in the script contract, and every fallback is this workshop's CURRENT
# behaviour -- so a consumer that defines none of them gets exactly what the unshared script did.
# Same pattern as the changelog section headings (#178, now the tier map) and the entry-stub wording
# (#410).

# 'major' -> releases/development/<X>.x/<X.Y.Z>.md   (this workshop)
# 'minor' -> releases/development/<X.Y>/<X.Y.Z>.md   (a repo that cuts often enough for that to help)
$script:ReleaseNotesGrouping = 'major'

function Get-ReleaseNotesGrouping {
    <# How the generated release notes are foldered: 'major' or 'minor'. #>
    return $script:ReleaseNotesGrouping
}

# --- RETIRED, AUGUST 5, 2026: Get-ReleaseLiveMarker ------------------------------------------------
#
# The "this is the version currently live" suffix Convert-ChangelogForRelease moved from the previous
# release row onto the new one. There are no release rows in CHANGELOG.md any more -- a cut empties the
# document down to its intro -- so the marker has nothing to sit on and nothing to be moved from.
#
# It was EMPTY here throughout its life, and that was never an oversight: a marketplace has no live stage,
# so there is no such thing as the live version -- consumers install from `main` at a moment of their own
# choosing. Get-LiveStage above is a different question and stays: "do you have a live stage" is prose the
# cut-release skill reads to decide whether to print its live-push block, where this was a string a script
# wrote into a file. A repo could always have the first without wanting the second, and now only the first
# exists.

# --- Where this repo keeps its release history (Dave, August 4, 2026) -----------------------------
#
# THE MEASUREMENT BEHIND THIS PATH BECOMING LOAD-BEARING. CHANGELOG.md used to carry an accumulating
# release section that had grown to 434 of the file's 1,062 lines -- 41% -- across 72 blocks that each
# said no more than "see the notes". Every one of those 72 versions was ALSO in releases/README.md, with a
# date, a type and a descriptive title: verified in both directions, zero missing either way. So the
# section was not a long list but a poorer copy of a better one, and the changelog's own subject -- what
# changed since the last release -- was sitting under it.
#
# Get-ReleaseHistoryMode retired on August 5, 2026, and this is the other half of that same measurement
# playing out. It chose between 'all' (a block per release) and 'latest' (only the newest, behind a
# pointer); the flat changelog keeps NEITHER, because a cut now empties the document down to its intro.
# There is no mode left to select, and the file below is not "where the pointer points" any more but the
# only list of releases there is.
#
# THE PRECONDITION IS THEREFORE ABSOLUTE RATHER THAN A CAUTION: this file must really list every release,
# because from now on nothing else does. It did before this change too -- that is what made removing the
# blocks safe rather than lossy.
#
# The path answers ONE question and three things read it: the guardrail that checks which major a new row
# would land in, the inserter that writes that row, and new-internal-note.ps1, which repoints that row's
# Version cell at the internal note once the note exists. One edit here moves all three.
#
# It is deliberately left at the DEFAULT, releases/README.md. The list lived in its own HISTORY.md for one
# day (August 4, 2026), on the reasoning that one page should describe the process and another the outcome.
# That reasoning was superseded the same day: the pages had since been reorganised portable-half first with
# everything repo-specific in one named slot, and once that split exists, process-versus-outcome stops
# earning a file boundary -- the outcome IS repo-specific content, so it is simply the last section of the
# slot. Merging them also removed four cross-references the two pages needed to introduce each other, and
# left a consumer with one file to mirror instead of two.
$script:ReleaseHistoryPath = 'releases/README.md'

function Get-ReleaseHistoryPath {
    <# Repo-root-relative path to the file that lists every release this repo has cut. #>
    return $script:ReleaseHistoryPath
}

# Whether cut-release runs the plugin/marketplace half: enumerating the manifests from
# .claude-plugin/marketplace.json and bumping every plugin.json in lockstep. TRUE here -- that half IS
# this repo's release. It also wrote a consumer-facing CHANGELOG.md and RELEASE.md card per plugin
# until August 8, 2026; the lockstep bump is what the half is now.
#
# THE ONE KNOB WITH A COMPUTED FALLBACK, and the reason is that its answer is a fact rather than a
# preference: a repo with no .claude-plugin/marketplace.json has no plugins to bump, so a consumer
# that never heard of this function gets the right behaviour without stating anything. Stated
# explicitly here anyway, because in THIS repo the answer is load-bearing and a release that
# silently skipped the lockstep bump would be discovered by a consumer rather than by a gate.
$script:ReleasePluginTier = $true

function Get-ReleasePluginTier {
    <# $true if this repo publishes plugins whose versions cut-release must bump in lockstep. #>
    return $script:ReleasePluginTier
}

# --- RETIRED, AUGUST 5, 2026: Get-ReleaseCategoryTitles -------------------------------------------
#
# Display labels for the release-notes category headings, keyed on the branch types: Feat -> Features,
# Fix -> Fixes, Docs -> Documentation, Chore -> Maintenance, plus an 'Other' catch-all. It existed for a
# non-English consumer, where an unlabelled type degrades to the type NAME -- the wrong word rather than a
# missing one, precisely the #410 case.
#
# THE RELEASE DOCUMENTS HAVE NO CATEGORY HEADINGS ANY MORE. They are ranked lists of changes, exactly as
# CHANGELOG.md is, and each change states its own type inside it under a '### Type of change' section. So
# there is no heading for these labels to be the text of.
#
# WHY THE GROUPING WENT, since retiring a whole seam deserves the reason: the grouping was derived from the
# BRANCH PREFIX, which this repo measured does not predict what a change is worth -- the single most
# consequential change for a consumer at v3.2.0 arrived on a chore/ branch. So the grouping put a
# document's most important change third, under whichever label its prefix produced, and the significance
# ranking added in #467 could only reorder the categories rather than escape them.
#
# It was EMPTY here throughout, which was the correct state for an English repo. A consumer that still
# defines it is unaffected: nothing calls it.

# The permanent root *.md files that are NOT unfolded changelog entries. cut-release treats every
# OTHER root *.md as an entry somebody forgot to fold (deliberately catch-all, so an entry with an
# unknown branch prefix is never missed), and refuses to cut while one exists.
#
# THIS LIST HAS GONE STALE THREE TIMES AND EACH TIME IT BLOCKED A RELEASE OVER A DOCUMENT NOBODY HAD
# FAILED TO FOLD: #165 first, then QUICKSTART.md + UNINSTALL.md in #405 when flattening moved them to
# the root, then ADOPTION.md in #408. It lived in the script until now, which made it a fourth thing a
# consumer would have had to fork the script over -- so it moves here, where the answer actually
# lives. Add a new permanent root doc here, and nowhere else.
# AND THE THREE IT BLOCKED OVER ARE OFF IT AGAIN, because they left the root for plugins/. Keeping them
# would not have blocked anything -- an allowlist entry for a file that is not there is inert -- but it
# would have made the list describe a root that no longer exists, and it would have SILENCED the one
# signal worth having: a QUICKSTART.md reappearing in the root now means somebody moved it back by
# accident, and cut-release should say so rather than wave it through.
$script:ReservedRootMd = @(
    'CHANGELOG.md', 'CLAUDE.md', 'README.md', 'LICENSE.md', 'CONTRIBUTING.md', 'SECURITY.md'
)

function Get-ReservedRootMd {
    <# File names in the repo root that are permanent docs rather than unfolded changelog entries. #>
    return $script:ReservedRootMd
}

# --- The highlights tier: whether, and for which bumps (issue #417 knob 2; narrowed August 5, 2026) --
#
# The second, stakeholder-facing rendering of a release: releases/highlights/<dir>/<X.Y.Z>.md. Written
# for NON-DEVELOPERS (Dave, July 13, 2026), and since the tier model it is assembled from the TIER-2
# ENTRIES rather than from a category guess plus a marker somebody deletes by hand. MARKDOWN ONLY -- the
# tier briefly also generated a print-ready .html and no longer does anywhere (Dave, August 3, 2026);
# whoever wants a PDF renders the markdown with a real tool.
#
# ON IN THIS REPO SINCE AUGUST 3, 2026, for minor and major only -- Dave's decision, and it reversed
# what this file said one commit earlier. The reasoning that had it off was that this repo's release
# audience "is developers", so a stakeholder document would have no reader. That was the wrong unit of
# analysis: the audience question is not developer-vs-not, it is WHO DECIDES WHETHER TO UPDATE. That
# reader does not want the full per-PR record, and giving them only the developer notes is the same
# mismatch a storefront repo has with its management -- one tier serving two audiences badly.
#
# So this repo runs three release documents, one per tier of the ladder the entries declare:
#   releases/development/<X>.x/<X.Y.Z>.md   tier 0   developers   -- every release, complete, raw
#   releases/internal/<X>.x/<X.Y.Z>.md      tier 1   colleagues   -- every release, what it is worth
#   releases/highlights/<X>.x/<X.Y.Z>.md    tier 2   consumers    -- minor/major, what they notice
#
# THE TIER NUMBER AND THE DOCUMENT ARE THE SAME SCALE, which is the point of the renumbering (Dave,
# August 5, 2026 -- they were 1/2/3 before, one off from the entries they describe). A tier-1 entry is
# in the internal note; a tier-2 entry is in the highlights AND, the ladder being cumulative, in the
# internal note as well. The development note carries everything, tier 0 included, because it is the
# record.
#
# PER MAJOR, NOT PER MINOR (Dave, August 3, 2026). The consumer this came from folders its notes per
# minor; this repo keeps <X>.x for all three tiers, which Get-ReleaseNotesGrouping above already says
# and every tier reads from that one answer rather than restating it.
#
# WHY MINOR/MAJOR AND NOT PATCH: a minor here is cut when a consumer actually notices something. That
# is the same test the version number itself answers, so the tier and the bump agree by construction --
# a patch has nothing a consumer would read, which is precisely why it is a patch.
#
# SINCE AUGUST 5, 2026 THAT AGREEMENT IS ENFORCED RATHER THAN HOPED FOR: cut-release refuses a minor
# unless a tier-2 entry is pending, so "this bump has a highlights reader" is a precondition of the
# bump instead of a convention about it. This knob therefore no longer decides WHETHER there is
# anything to write -- the tier does -- only whether this repo wants the document for that bump type.
$script:ReleaseHighlightsBumps = @('minor', 'major')

function Get-ReleaseHighlightsBumps {
    <# Bump types that also get a highlights document: e.g. @('minor','major'). Empty = tier off. #>
    return $script:ReleaseHighlightsBumps
}

# --- How many minors a major must recap (Dave, August 5, 2026) ------------------------------------
#
# A major here is not "a big release" but a RECAP of the minors before it -- which is what the two majors
# this repo has cut actually were: v2.0.0 consolidated v1.0 to v1.18, v3.0.0 consolidated v2.2.0 to
# v2.16.0. Both were written that way after the fact; this states it up front and lets the cut enforce it.
#
# TEN, and read off the CURRENT VERSION's minor component rather than counted from the tag list. Within
# major 3 the minors are 3.1 .. 3.10, so the component IS the number of minors cut in that line -- one
# number that cannot disagree with itself, where counting tags could (a deleted tag, a minor cut in
# another line). Held against this repo's own history the threshold is roughly right rather than
# arbitrary: the 1.x line ran to 1.18 and the 2.x line to 2.16 before each was recapped.
#
# Repo-owned because it is release cadence, not language: a repo that cuts minors rarely would be pinned
# to a major it never reaches, and forking a shared script over one integer is precisely what the seam
# exists to prevent (#417). Only read where a tier split is declared -- the whole bump gate is off
# without one.
$script:ReleaseMajorMinMinors = 10

function Get-ReleaseMajorMinMinors {
    <# The number of minors a major line must have had before a major may be cut. #>
    return $script:ReleaseMajorMinMinors
}

# --- RETIRED, AUGUST 5, 2026: Get-ReleaseHighlightsStakeholderTypes + Get-ReleaseHighlightsWording ---
#
# Both existed to serve ONE mechanism: the highlights generator wrote out every category, put Feat+Fix
# above a "remove before publishing" marker and left the release manager to cut the rest by hand. The
# marker was explicitly a PROPOSAL rather than a verdict, and the reason it could only ever be a
# proposal is the measurement this repo already had: held against the 19 entries pending at v3.2.0, the
# single most consequential change for a consumer -- renaming the marketplace, which breaks every
# existing install -- arrived on a chore/ branch and therefore landed below the marker.
#
# The tier model answers that question at the source instead of guessing at the end: the author of the
# entry says whether a consumer notices, and the generator selects on that. So the marker has nothing
# left to propose, and the two knobs that configured it -- which types to promote, and in whose words to
# label the block -- describe machinery that is gone. They are removed rather than left returning values
# nothing reads, which is this file's own rule about write-once config.
#
# A consumer that still defines either function is unaffected: nothing calls them, so they are simply
# dead code in that repo's seam, and its next fold and cut behave exactly as this repo's do.

# --- The internal tier's own text (the third tier, August 3, 2026) --------------------------------
#
# releases/internal/<X>.x/<X.Y.Z>.md, written by new-internal-note.ps1 for colleagues, employers and
# management -- at EVERY release including a patch, which is exactly what separates it from highlights:
# highlights = what a CONSUMER notices, internal = what the ORGANISATION gets out of it. A release with
# nothing for a consumer (correctly a patch, so no highlights) can still be the one where a team stopped
# needing a developer for a routine change.
#
# NO ON/OFF KNOB, deliberately, unlike the highlights tier. That tier is generated BY cut-release, so it
# needs to be told whether to run; this one is a script you invoke when you want a note. The switch is
# running it or not. cut-release only decides whether to PRINT the suggestion, and it does that by
# checking whether the script exists in the repo -- a fact rather than a preference, the same reasoning
# as Get-ReleasePluginTier's computed fallback.
#
# EMPTY HERE, for the third time in this file and for the same reason: an English repo is already served
# by the English defaults in the script. The knob exists for a consumer whose colleagues read another
# language, where an unset heading is the wrong word rather than a missing one -- the #410 class. Keys:
# Title, AudienceLabel, Audience, SkeletonNote, SectionChanged, SectionValue, HintValue, SectionOpen,
# HintOpen, NoEntries, Unknown. Merged over the defaults, so overriding one leaves the rest alone.
$script:InternalNoteWording = @{}

function Get-InternalNoteWording {
    <# Overrides for the internal note's headings, audience line and fill-in hints. Empty = English. #>
    return $script:InternalNoteWording
}
