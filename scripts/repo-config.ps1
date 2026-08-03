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
