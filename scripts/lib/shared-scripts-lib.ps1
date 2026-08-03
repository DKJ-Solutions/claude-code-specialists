<#
.SYNOPSIS
    Registry + helpers for the shared workflow scripts (root copy <-> plugin mirror).

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')

    Some workflow scripts are repo-agnostic and are mirrored into the plugin as a shared source, so
    consumers do not duplicate them (issue #81). The model: the **workshop root copy is the
    canonical, tested source**; the **plugin mirror** is what a consumer runs via a skill. Both are
    LF-normalized identical -- made possible because the scripts resolve their repo root
    dual-context (CLAUDE_PROJECT_DIR for a consumer, otherwise the git root).

    Supplies Get-SharedScriptPairs (the registry) and Get-NormalizedScriptContent (LF-normalized
    read). The generator (scripts/sync/build-shared-scripts.ps1), the lint gate
    (check-plugin-integrity.ps1), and the test (scripts/tests/shared-scripts.tests.ps1) share this
    one source.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function Get-SharedScriptPairs {
    <#
        The registry of shared scripts. Each pair: the canonical root source (Source) and the
        plugin mirror (Mirror), both repo-root-relative. Extend per centralized script.

        LibOnly = $true marks a DOT-SOURCED library rather than a standalone entry point. Such a
        file never resolves a repo root of its own -- it is reached via a $PSScriptRoot-relative
        dot-source from a caller that already resolved one -- so the dual-context invariant does not
        apply to it. The flag lives HERE, next to the registration, because the test used to keep
        its own hand-written list of lib names: a second literal that a new lib silently fell out of
        (the accumulation shape of #275/#331). Registering a lib now declares its own exception.
    #>
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $pairs = @(
        @{
            Name   = 'fold-changelog-entry'
            Source = 'scripts\release\fold-changelog-entry.ps1'
            Mirror = 'plugins\specialists\scripts\release\fold-changelog-entry.ps1'
        },
        @{
            Name   = 'open-pr'
            Source = 'scripts\release\open-pr.ps1'
            Mirror = 'plugins\specialists\scripts\release\open-pr.ps1'
        },
        @{
            Name   = 'check-roster-sync'
            Source = 'scripts\sync\check-roster-sync.ps1'
            Mirror = 'plugins\specialists\scripts\sync\check-roster-sync.ps1'
        },
        @{
            Name   = 'check-script-contract'
            Source = 'scripts\sync\check-script-contract.ps1'
            Mirror = 'plugins\specialists\scripts\sync\check-script-contract.ps1'
        },
        @{
            Name   = 'new-changelog-entry'
            Source = 'scripts\release\new-changelog-entry.ps1'
            Mirror = 'plugins\specialists\scripts\release\new-changelog-entry.ps1'
        },
        @{
            Name   = 'new-branch'
            Source = 'scripts\task\new-branch.ps1'
            Mirror = 'plugins\specialists\scripts\task\new-branch.ps1'
        },
        @{
            Name   = 'park-branch'
            Source = 'scripts\task\park-branch.ps1'
            Mirror = 'plugins\specialists\scripts\task\park-branch.ps1'
        },
        @{
            # Issue #411. Was excluded as "workshop-only" on the reasoning that merge policy and the CI
            # check name are repo-specific. Only the first half held: the check NAME never entered the
            # logic (step 3 watches whatever checks exist and reads the exit code), and the merge METHOD
            # moved into the seam as the optional Get-PrMergeMethod. Without this mirror, merge + fold is
            # hand work in every consumer -- and it is the one sequence classified safety-critical,
            # because it merges to main and then commits directly to main.
            Name   = 'ship-pr'
            Source = 'scripts\release\ship-pr.ps1'
            Mirror = 'plugins\specialists\scripts\release\ship-pr.ps1'
        },
        @{
            # Travels with ship-pr rather than on its own merit: it IS ship-pr's step 6, and a consumer
            # whose ship-pr calls a file that is not in the mirror would fail at the last step of a
            # sequence that has already merged. Portable as it stands -- dual-context root, Get-RepoName,
            # and pr-issues-lib/native-capture-lib are both mirrored already.
            Name   = 'verify-resolved-issues'
            Source = 'scripts\release\verify-resolved-issues.ps1'
            Mirror = 'plugins\specialists\scripts\release\verify-resolved-issues.ps1'
        },
        @{
            # Issue #413. Three repos had written their own copy of this repair tool, which is the
            # argument for one source rather than for a fourth. Its workshop-shaped default file set --
            # the part that made it unusable elsewhere -- moved into the seam as Get-MojibakePaths.
            Name   = 'fix-mojibake'
            Source = 'scripts\maintenance\fix-mojibake.ps1'
            Mirror = 'plugins\specialists\scripts\maintenance\fix-mojibake.ps1'
        },
        @{
            Name    = 'check-report-lib'
            Source  = 'scripts\lib\check-report-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\check-report-lib.ps1'
            LibOnly = $true
        },
        @{
            Name    = 'native-capture-lib'
            Source  = 'scripts\lib\native-capture-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\native-capture-lib.ps1'
            LibOnly = $true
        },
        @{
            Name    = 'pr-issues-lib'
            Source  = 'scripts\lib\pr-issues-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\pr-issues-lib.ps1'
            LibOnly = $true
        },
        @{
            # The third release tier (August 3, 2026). Its own script rather than part of cut-release, and
            # the reason changed on the way: the source repo kept it separate because cut-release was
            # "temporarily diverged" and must not be extended, which #417 settled. What holds instead is
            # that cut-release COMMITS AND TAGS in one motion, so a skeleton generated there would put an
            # empty document inside the release tag while the written version landed afterwards anyway.
            Name   = 'new-internal-note'
            Source = 'scripts\release\new-internal-note.ps1'
            Mirror = 'plugins\specialists\scripts\release\new-internal-note.ps1'
        },
        @{
            # The changelog entry's scaffold wording, needed by TWO shared scripts that must not be able
            # to disagree about it: new-changelog-entry.ps1 writes it, open-pr.ps1's scaffold gate refuses
            # to ship it. A copy in each would make the gate silently miss whatever the writer changed --
            # a drift guard that drifts. So it travels with both rather than living in either.
            Name    = 'entry-scaffold-lib'
            Source  = 'scripts\lib\entry-scaffold-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\entry-scaffold-lib.ps1'
            LibOnly = $true
        },
        @{
            # Issue #417, phase 1. Two repos ran two independently evolved files of this name, and the
            # owner's goal is one release workflow rather than two that resemble each other. The audit
            # that produced the issue named three divergences; reading both files found six, and the
            # largest -- the whole plugin/marketplace half -- was not among them. All six now sit in the
            # seam (scripts\repo-config.ps1), each optional, each falling back to what this script did
            # unshared, so registering it here changes nothing about how the workshop cuts a release.
            #
            # The highlights tier the other repo generates is NOT part of this entry: porting it is
            # phase 2, and it renders stakeholder-facing HTML, which under the safety rules is work that
            # waits for Dave's own eye rather than merging on the gates.
            Name   = 'cut-release'
            Source = 'scripts\release\cut-release.ps1'
            Mirror = 'plugins\specialists\scripts\release\cut-release.ps1'
        },
        @{
            # Travels with cut-release for the same reason verify-resolved-issues travels with ship-pr:
            # cut-release dot-sources it as a $PSScriptRoot sibling, so a mirror without it would fail
            # on the first line that matters. Its one repo-owned dependency, branch-info.ps1, does NOT
            # travel -- the branch table differs per repo -- so the dot-source of that sibling is
            # guarded and Get-ReleaseCategories probes for Get-BranchTypes, which cut-release loads
            # from the consumer's own root before calling in.
            Name    = 'release-lib'
            Source  = 'scripts\lib\release-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\release-lib.ps1'
            LibOnly = $true
        }
    )

    foreach ($p in $pairs) {
        [pscustomobject]@{
            Name       = $p.Name
            SourceRel  = $p.Source
            MirrorRel  = $p.Mirror
            SourcePath = Join-Path $RepoRoot $p.Source
            MirrorPath = Join-Path $RepoRoot $p.Mirror
            # Absent on an entry-point script -- normalized to $false so a caller can test the
            # property without ContainsKey gymnastics under StrictMode.
            LibOnly    = [bool]($p.ContainsKey('LibOnly') -and $p.LibOnly)
        }
    }
}

function Get-NormalizedScriptContent {
    <# Reads a script LF-normalized (CRLF -> LF); $null if the file is missing. #>
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    return ($raw -replace "`r`n", "`n")
}
