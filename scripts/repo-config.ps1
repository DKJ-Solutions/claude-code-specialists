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
