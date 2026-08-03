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
