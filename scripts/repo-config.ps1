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
$script:RepoName = 'DaveKJohn/davekjohns-workshop'

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
$script:RosterPath = 'CLAUDE.md'

function Get-RosterPath {
    <# Repo-root-relative path to the file that holds the roster (specialists table/list). #>
    return $script:RosterPath
}

# Agent ids ('<group>-<id>') that are ENABLED but deliberately have no roster row and no lens, so
# check-roster-sync.ps1 must not flag them as drift. In this workshop, Paula (02-09), Vera (04-11),
# Gwen (04-12), Cody (04-13) and Auden (06-30) are enabled from the `specialists` plugin but have
# (as yet) no repo work here, hence no lens and no roster row -- a documented choice in CLAUDE.md,
# not drift. A fresh consumer leaves this empty (every enabled agent belongs in its roster).
$script:RosterIgnoredIds = @('02-09', '04-11', '04-12', '04-13', '06-30')

function Get-RosterIgnoredIds {
    <# Ids of enabled agents intentionally kept out of the roster/lenses (skipped by the check). #>
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
