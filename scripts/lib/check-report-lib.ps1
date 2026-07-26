<#
.SYNOPSIS
    Shared [OK]/[INFO]/[ERROR] report helpers for the sync/check scripts (single source of truth,
    issue #114).

.DESCRIPTION
    Dot-source this file from a sibling of the script that needs it, relative to $PSScriptRoot (NOT
    $repoRoot) -- unlike scripts/repo-config.ps1 / scripts/lib/branch-info.ps1, this lib is not
    repo-owned, so it does not need a consumer-side scaffold. It travels as part of the SAME
    plugin/mirror payload as its callers, so a $PSScriptRoot-relative path resolves correctly
    whether the caller runs from the workshop root, a consumer's plugin cache, or the plugin mirror
    tree (the same reasoning new-branch.ps1 already relies on for its sibling
    new-changelog-entry.ps1 call):

        . (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')          -- from scripts/sync/*
        . (Join-Path $PSScriptRoot '..\..\scripts\lib\check-report-lib.ps1') -- from skills/<name>/*

    Callers of Write-Info/Write-Failure/Write-CheckSummary must declare $script:errors = 0 and
    $script:infos = 0 before use -- dot-sourcing runs in the caller's own scope (verified: a
    function defined via dot-source increments the CALLER's $script: variable, not one local to
    this file), so the counters live with the caller, not here.

    Supplies:
      - Write-Ok / Write-Skip                        -- plain report lines, no counting.
      - Write-Info / Write-Failure                       -- report lines that also bump
                                                          $script:infos / $script:errors.
      - Write-CheckSummary                            -- the "Summary: N error(s), N info
                                                          signal(s)." line + matching exit code
                                                          (0 = no errors, 1 = at least one).
      - Test-PluginNameSlug / Test-PluginMarketplaceSlug -- the plugin-id / '@marketplace' slug
                                                          guards (values from settings.json /
                                                          manifests become filesystem paths, so
                                                          never trusted unvalidated).
      - Resolve-PluginDir                             -- resolve a plugin's versioned dir under a
                                                          plugin cache root (honors
                                                          $env:CLAUDE_PLUGIN_ROOT when it points at
                                                          THIS plugin; else the semantically highest
                                                          version -- [version]-sort, not
                                                          string-sort, so 1.10.0 beats 1.9.0 -- that
                                                          has an agents/ dir).
      - Get-DisplayName                               -- sanitize + capitalize a raw agent name into a
                                                          display name (single source for sync-roster
                                                          and check-roster-sync -- issue #145).
      - Get-LensFamily / Get-LensDirCandidates        -- the family segment of the consumer repo-lens
                                                          path, and the ordered dirs to look for a
                                                          lens in (single source for the writers
                                                          bootstrap.ps1/sync-roster.ps1 and the reader
                                                          check-roster-sync.ps1 -- issue #179).

    Not every caller needs every function -- e.g. sync-roster.ps1 uses its own non-counting
    Write-Info/Write-Failure (it tracks created/kept/proposed, not error/info signals, and always
    exits 0), so it only dot-sources this file for Write-Ok, Resolve-PluginDir and the slug guards,
    and keeps its own Write-Info/Write-Failure defined afterward (a later definition in the same scope
    intentionally shadows the one from this file -- ordinary PowerShell function resolution, not a
    workaround).

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function Write-Ok   ([string]$Msg) { Write-Host "  [OK]    $Msg" -ForegroundColor Green }
function Write-Skip ([string]$Msg) { Write-Host "  [SKIP]  $Msg" -ForegroundColor DarkGray }
function Write-Info ([string]$Msg) { $script:infos++;  Write-Host "  [INFO]  $Msg" -ForegroundColor Yellow }
function Write-Failure ([string]$Msg) { $script:errors++; Write-Host "  [ERROR] $Msg" -ForegroundColor Red }

function Write-CheckSummary {
    <# Prints "Summary: N error(s), N info signal(s)." (green if no errors, red otherwise) and
       exits the script: 1 if $script:errors -gt 0, else 0. Called directly by both
       check-connectors.ps1 and check-roster-sync.ps1 -- no more duplicated ending to mirror. #>
    Write-Host "`nSummary: $($script:errors) error(s), $($script:infos) info signal(s)." -ForegroundColor $(if ($script:errors -gt 0) { 'Red' } else { 'Green' })
    if ($script:errors -gt 0) { exit 1 }
    exit 0
}

function Test-PluginNameSlug {
    <# The plugin-name part of a plugin id (before '@') must be a simple lowercase slug before it
       becomes a path segment. #>
    param([Parameter(Mandatory = $true)][string]$Name)
    return ($Name -match '^[a-z0-9][a-z0-9-]*$')
}

function Test-PluginMarketplaceSlug {
    <# The marketplace part of a plugin id (after '@') must be a simple slug before it becomes a
       path segment. #>
    param([Parameter(Mandatory = $true)][string]$Marketplace)
    return ($Marketplace -match '^[A-Za-z0-9][A-Za-z0-9._-]*$')
}

function Resolve-PluginDir {
    <# Resolve the versioned plugin dir for Name+Marketplace under CacheRoot: honors
       $env:CLAUDE_PLUGIN_ROOT (hook context) only when it points at THIS plugin (its parent dir
       leaf equals Name), so a multi-plugin setup stays correct; otherwise picks the semantically
       highest version under <CacheRoot>/<Marketplace>/<Name>/ that has an agents/ dir
       (bootstrap lesson: a string-sort puts 1.9.0 above 1.10.0 -- [version] fixes that). #>
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Marketplace,
        [Parameter(Mandatory = $true)][string]$CacheRoot
    )

    if ($env:CLAUDE_PLUGIN_ROOT) {
        $cpr = $env:CLAUDE_PLUGIN_ROOT
        if ((Test-Path -LiteralPath $cpr -PathType Container) -and
            ((Split-Path (Split-Path $cpr -Parent) -Leaf) -eq $Name)) {
            return (Resolve-Path -LiteralPath $cpr).Path
        }
    }

    $nameDir = Join-Path (Join-Path $CacheRoot $Marketplace) $Name
    if (-not (Test-Path -LiteralPath $nameDir -PathType Container)) { return $null }
    $versions = Get-ChildItem -LiteralPath $nameDir -Directory |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
        Sort-Object { [version]$_.Name } -Descending
    foreach ($v in $versions) {
        if (Test-Path -LiteralPath (Join-Path $v.FullName 'agents') -PathType Container) {
            return (Resolve-Path -LiteralPath $v.FullName).Path
        }
    }
    return $null
}

function Get-DisplayName {
    <# Sanitize + capitalize a raw agent name (from an agent-def's `name:` frontmatter) into a display
       name. Defense-in-depth: the name may be written into a scaffold file or a proposed roster row,
       so restrict it to a safe charset before use. Returns $Fallback when nothing usable remains.
       Single source (issue #145) for skills/sync-roster/sync-roster.ps1 (roster-row proposals +
       header-drift comparison) and scripts/sync/check-roster-sync.ps1 (header-drift detection). #>
    param([string]$RawName, [string]$Fallback = '')
    $n = $RawName -replace '[^A-Za-z0-9_-]', ''
    if (-not $n) { return $Fallback }
    return ($n.Substring(0, 1).ToUpper() + $n.Substring(1))
}

function Get-LensFamily {
    <# The family segment of a consumer's repo-lens path:
       .claude/plugins/<family>/<plugin>/<group>-<id>-extension.md.

       A CONSTANT, deliberately not derived from the install path (issue #179). specialists-init used
       to derive it, and in the plugin-cache layout (~/.claude/plugins/cache/<marketplace>/<plugin>/
       <version>/) that derivation yields the MARKETPLACE name instead of the plugin family. A repo
       installed through 'specialists@davekjohns-workshop' therefore got its lenses written to
       .claude/plugins/davekjohns-workshop/<plugin>/, while every reader looked only under
       'claude-specialists' -- so existing lenses were reported as missing, and following that advice
       would have produced a second copy of every lens on a second path. The family is a property of
       the plugin family, not of the marketplace it happens to be fetched from, so it is fixed here:
       one value, used by the writers (bootstrap.ps1, sync-roster.ps1) and the reader
       (check-roster-sync.ps1) alike. #>
    return 'claude-specialists'
}

function Get-LensDirCandidates {
    <# The ordered directories a repo lens for $PluginName may live in, most canonical first:
         1. .claude/plugins/<Get-LensFamily>/<plugin>/   -- the standard; where writers write.
         2. .claude/plugins/<other-family>/<plugin>/     -- what a pre-#179 bootstrap left behind
                                                            (the marketplace name as family). Read
                                                            but never written, so a consumer that was
                                                            bootstrapped before the fix keeps working
                                                            without a migration.
         3. .claude/extensions/                          -- the legacy pre-plugin-path location.
       Readers should walk this list; writers should use Get-LensFamily directly. $PluginName is
       assumed slug-validated by the caller (Test-PluginNameSlug) before it becomes a path segment. #>
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$PluginName
    )
    $family = Get-LensFamily
    $pluginsRoot = Join-Path $RepoRoot '.claude\plugins'
    $dirs = @((Join-Path (Join-Path $pluginsRoot $family) $PluginName))
    if (Test-Path -LiteralPath $pluginsRoot -PathType Container) {
        foreach ($fam in (Get-ChildItem -LiteralPath $pluginsRoot -Directory | Sort-Object Name)) {
            if ($fam.Name -eq $family) { continue }
            $d = Join-Path $fam.FullName $PluginName
            if (Test-Path -LiteralPath $d -PathType Container) { $dirs += $d }
        }
    }
    $dirs += (Join-Path $RepoRoot '.claude\extensions')
    return $dirs
}
