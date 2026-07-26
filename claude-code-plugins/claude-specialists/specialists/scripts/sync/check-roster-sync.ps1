<#
.SYNOPSIS
    Roster-sync check: detects when a consumer's repo roster and repo lenses lag behind the agents
    that the ENABLED plugins actually ship (LAYER 1 -- detection only, no fixes).

.DESCRIPTION
    When a plugin release adds a new specialist (e.g. Ravi 06-24), a consumer that updates the plugin
    gets no signal that its roster (a table/list in CLAUDE.md) and its repo lenses now lag behind.
    This script surfaces that drift by comparing three sources:

      (a) Agents of the ENABLED plugins. Enabled plugins are read from .claude/settings.json
          (enabledPlugins: a plugin id like 'specialists@davekjohns-workshop' counts as enabled when
          its value is $true -- mirrors bootstrap.ps1). For each enabled plugin the versioned dir is
          resolved in the local plugin cache (semantically highest version, [version]-sort -- the same
          approach bootstrap.ps1 uses so 1.10.0 beats 1.9.0), and the agent ids ('<group>-<id>', e.g.
          06-24) are taken from <plugin-dir>/agents/<g>-<id>-agent.md.
      (b) The consumer's roster. Its path comes from Get-RosterPath in scripts/repo-config.ps1
          (default 'CLAUDE.md', repo-root-relative). "Present in the roster" is decided by scanning the
          roster text for each '<group>-<id>' token (format-agnostic -- works for a table OR a list;
          deliberately NOT a brittle table parser).
      (c) The lens files, looked up via Get-LensDirCandidates (check-report-lib.ps1 -- the same source
          the writers use, issue #179): the canonical .claude/plugins/claude-specialists/<plugin>/
          <g>-<id>-extension.md, a non-canonical family segment left behind by a pre-#179 bootstrap,
          and the legacy .claude/extensions/<g>-<id>-extension.md.

    Findings + severity (same [OK]/[INFO]/[ERROR] convention as check-connectors.ps1):
      - agent WITHOUT a roster row  -> [ERROR]  (the core case this feature exists for: a new
                                                 specialist that is invisible in the governance doc).
      - agent WITHOUT a lens file   -> [ERROR]  (actionable drift for a real agent: no landing spot
                                                 for its repo-specific context).
      - orphan (a roster token OR a lens file whose '<group>-<id>' has NO matching agent AND no
        matching persona in any enabled plugin) -> [INFO] (could be a just-removed specialist; also
        soft because personas are counted as backing, see below).
      - lens on a NON-CANONICAL family segment -> [INFO] (issue #179): a pre-fix bootstrap derived the
                                                 family from the install path and so wrote the lenses
                                                 under the marketplace name. The lens works and counts
                                                 as present; the line only points at the misalignment
                                                 (reported once per directory, not once per lens).
      - lens header still naming a STALE persona name -> [INFO] (issue #145): an older scaffold baked
        the first name into the lens header ("# Sean <midDot> repo-lens"); after a rename that name is
        stale, but the lens is present, so it is a cosmetic mismatch, not missing-lens drift. Soft on
        purpose (silent at session start); the sync-roster skill stages a paste-ready reconcile.

    Personas as orphan-backing: main-loop specialists (Chris 01-01, Derek 05-05, Rendall 05-06, ...)
    ship as <plugin>/personas/<g>-<id>-persona.md, NOT as agents, yet legitimately have a roster row
    and a lens. Counting personas as "backing" keeps them from being flagged as orphans on every real
    repo. Personas are NEVER treated as missing-roster/missing-lens drift -- only agents are (source a).

    Exit-code: 0 = no errors (INFO does not count), 1 = at least one error.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Use this path as the consumer repo root instead of the dual-context default.

.PARAMETER CacheRootOverride
    (Optional, for tests) Use this dir as the plugin cache root instead of
    $env:USERPROFILE/.claude/plugins/cache -- lets a fixture supply a controlled agent set / versions.

.EXAMPLE
    .\scripts\sync\check-roster-sync.ps1
#>
param(
    [string]$ConsumerPathOverride = '',
    [string]$CacheRootOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Repo-root -- dual-context: a consumer running the shared plugin mirror gets its repo-root from
# CLAUDE_PROJECT_DIR; in the workshop-root (or outside a session) it falls back to the git-root. This
# keeps the root-copy and the plugin-mirror byte-identical (guarded by the shared-scripts drift-lint).
# -ConsumerPathOverride wins so a fixture can point the check at a throwaway consumer.
$repoRoot = if ($ConsumerPathOverride) { $ConsumerPathOverride }
            elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR }
            else { (git rev-parse --show-toplevel).Trim() }
$repoRoot = (Resolve-Path -LiteralPath $repoRoot).Path

# Plugin cache root (overridable for tests).
$cacheRoot = if ($CacheRootOverride) { $CacheRootOverride } else { Join-Path $env:USERPROFILE '.claude\plugins\cache' }

$script:errors = 0
$script:infos  = 0

# Middle dot used in the scaffold-lineage lens header; kept as a code point so this file stays ASCII.
$midDot = [char]0x00B7

# Write-Ok/Write-Info/Write-Failure + Test-PluginNameSlug/Test-PluginMarketplaceSlug + Resolve-PluginDir:
# shared with check-connectors.ps1 and skills/sync-roster/sync-roster.ps1 (single source, issue
# #114). This script is a whole-file mirror (scripts/lib/shared-scripts-lib.ps1); check-report-lib.ps1
# is registered in that same pair set and therefore travels along, so a $PSScriptRoot-relative
# dot-source (not $repoRoot -- this lib is not repo-owned, unlike repo-config.ps1/branch-info.ps1)
# resolves correctly whether this file runs from the workshop root or the plugin mirror.
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')

# Agent ids ('<group>-<id>') a plugin ships (source a).
function Get-AgentIds {
    param([string]$PluginDir)
    $dir = Join-Path $PluginDir 'agents'
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $dir -Filter '*-agent.md' -File |
        ForEach-Object { if ($_.BaseName -match '^(\d{2})-(\d{2})-agent$') { "$($Matches[1])-$($Matches[2])" } } |
        Sort-Object -Unique)
}

# Ids that BACK a roster token / lens: agents + personas. Personas run in the main loop (not as
# subagents) but are real specialists with roster rows + lenses, so counting them prevents false orphans.
function Get-BackingIds {
    param([string]$PluginDir)
    $ids = @(Get-AgentIds -PluginDir $PluginDir)
    $pdir = Join-Path $PluginDir 'personas'
    if (Test-Path -LiteralPath $pdir -PathType Container) {
        $ids += @(Get-ChildItem -LiteralPath $pdir -Filter '*-persona.md' -File |
            ForEach-Object { if ($_.BaseName -match '^(\d{2})-(\d{2})-persona$') { "$($Matches[1])-$($Matches[2])" } })
    }
    return @($ids | Sort-Object -Unique)
}

# "Present in the roster": scan the roster text for the literal '<group>-<id>' token, bounded by
# non-digits so '06-24' still matches inside '06-24-extension.md' but NOT inside '106-240'.
# Format-agnostic on purpose (table or list) -- see the Get-RosterPath note in repo-config.ps1.
function Test-InRoster {
    param([string]$RosterText, [string]$Id)
    return ($RosterText -match ('(?<!\d)' + [regex]::Escape($Id) + '(?!\d)'))
}

# The lens path for '<group>-<id>': the first of Get-LensDirCandidates that actually holds the file --
# the canonical plugin-path, a non-canonical family segment left by a pre-#179 bootstrap, or the legacy
# extensions-path; $null when none does. The candidate list is the shared source the writers
# (bootstrap.ps1, sync-roster.ps1) derive their target path from, so reader and writer cannot drift.
function Get-LensPath {
    param([string]$RepoRoot, [string]$PluginName, [string]$Id)
    foreach ($d in (Get-LensDirCandidates -RepoRoot $RepoRoot -PluginName $PluginName)) {
        $c = Join-Path $d "$Id-extension.md"
        if (Test-Path -LiteralPath $c -PathType Leaf) { return $c }
    }
    return $null
}

# A lens for '<group>-<id>' exists at any of the candidate locations.
function Test-LensExists {
    param([string]$RepoRoot, [string]$PluginName, [string]$Id)
    return [bool](Get-LensPath -RepoRoot $RepoRoot -PluginName $PluginName -Id $Id)
}

# The canonical directory a lens for $PluginName belongs in -- what the writers produce.
function Get-CanonicalLensDir {
    param([string]$RepoRoot, [string]$PluginName)
    return (Join-Path (Join-Path (Join-Path $RepoRoot '.claude\plugins') (Get-LensFamily)) $PluginName)
}

# The agent's display name from its cache-file frontmatter (best-effort; '' when absent). Only the
# `name:` line is needed here -- lighter than sync-roster's Get-AgentInfo, which also reads the desc.
function Get-AgentName {
    param([string]$PluginDir, [string]$Id)
    $p = Join-Path (Join-Path $PluginDir 'agents') "$Id-agent.md"
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return '' }
    foreach ($ln in (Get-Content -LiteralPath $p -TotalCount 15)) {
        if ($ln -match '^name:\s*(.+?)\s*$') { return $Matches[1].Trim() }
    }
    return ''
}

# The leading name token of a scaffold-lineage lens header "# <Name> <midDot> repo[- ]lens" (both the
# sync-roster and specialists-init generators write that shape). Returns '' when the first heading is
# NOT that shape -- so a hand-customized header (no "<midDot> repo-lens" tail) is never touched, and
# the new nameless scaffold "# <g>-<id> <midDot> repo-lens" returns the '<g>-<id>' token (which the
# caller treats as up-to-date, not drift). $MidDot is passed in so this file stays pure ASCII.
function Get-ScaffoldHeaderName {
    param([string]$LensPath, [string]$MidDot)
    if (-not $LensPath) { return '' }
    $rx = [regex]("^#\s+(?<nm>[^\s#" + [regex]::Escape($MidDot) + "]+)\s+" + [regex]::Escape($MidDot) + "\s+repo[- ]lens")
    foreach ($ln in (Get-Content -LiteralPath $LensPath -TotalCount 30 -Encoding UTF8)) {
        $m = $rx.Match($ln)
        if ($m.Success) { return $m.Groups['nm'].Value }
        if ($ln -match '^#\s') { return '' }
    }
    return ''
}

# All lens ids present in the consumer (every candidate dir for each enabled plugin + the legacy path),
# mapped to a display path -- used to surface lens files that back no agent (orphans).
function Get-LensIds {
    param([string]$RepoRoot, [string[]]$PluginNames)
    $dirs = @()
    foreach ($pn in $PluginNames) { $dirs += @(Get-LensDirCandidates -RepoRoot $RepoRoot -PluginName $pn) }
    # -Unique: the legacy .claude/extensions dir is a candidate for every plugin, so with two enabled
    # plugins it would otherwise be walked twice.
    $dirs = @($dirs | Sort-Object -Unique)
    $result = @{}
    foreach ($d in $dirs) {
        if (-not (Test-Path -LiteralPath $d -PathType Container)) { continue }
        Get-ChildItem -LiteralPath $d -Filter '*-extension.md' -File | ForEach-Object {
            if ($_.BaseName -match '^(\d{2})-(\d{2})-extension$') {
                $id = "$($Matches[1])-$($Matches[2])"
                if (-not $result.ContainsKey($id)) { $result[$id] = $_.FullName }
            }
        }
    }
    return $result
}

Write-Host "== check-roster-sync -- $repoRoot ==" -ForegroundColor Cyan

# Roster path from repo-config's Get-RosterPath (default 'CLAUDE.md'). repo-config is repo-specific and
# lives in the consumer repo-root; if it is absent we fall back to the default (this check has a sane
# default and does not hard-require repo-config, unlike open-pr/fold).
$rosterRel = 'CLAUDE.md'
$ignoredIds = @()
$configPath = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    # Dot-source + call the consumer's repo-config in a CHILD scope with StrictMode explicitly OFF --
    # sibling of the check-script-contract.ps1 fix: the real runtime callers of repo-config.ps1
    # (open-pr.ps1, fold-changelog-entry.ps1, ...) never enable StrictMode, and repo-config.ps1 is
    # explicitly documented as written on that no-strict-mode assumption (harmless loose top-level
    # code is expected there). Probing inside the same block keeps the dot-sourced functions visible
    # to Get-Command while nothing leaks into this script's own strict scope. A genuine failure (a
    # real syntax error, not just strict-mode noise) falls back to the sane defaults below rather than
    # crashing this whole check -- this check does not hard-require repo-config.
    $probe = & {
        Set-StrictMode -Off
        $result = [pscustomobject]@{ Loaded = $true; Error = $null; RosterPath = $null; IgnoredIds = $null }
        try {
            . $args[0]
        } catch {
            $result.Loaded = $false
            $result.Error = $_.Exception.Message
            return $result
        }
        if (Get-Command Get-RosterPath -ErrorAction SilentlyContinue) { $result.RosterPath = Get-RosterPath }
        if (Get-Command Get-RosterIgnoredIds -ErrorAction SilentlyContinue) { $result.IgnoredIds = @(Get-RosterIgnoredIds) }
        return $result
    } $configPath

    if ($probe.Loaded) {
        if ($null -ne $probe.RosterPath) { $rosterRel = $probe.RosterPath }
        # Ids that are enabled but deliberately kept out of the roster/lenses (a documented repo choice);
        # they are skipped rather than flagged as drift. Empty on a fresh consumer.
        if ($null -ne $probe.IgnoredIds) { $ignoredIds = @($probe.IgnoredIds) }
    } else {
        Write-Info "scripts\repo-config.ps1 failed to load ($($probe.Error)) -- falling back to defaults (roster '$rosterRel', no ignored ids)."
    }
}
$rosterPath = Join-Path $repoRoot $rosterRel
if (Test-Path -LiteralPath $rosterPath -PathType Leaf) {
    $rosterText = [System.IO.File]::ReadAllText($rosterPath, [System.Text.Encoding]::UTF8)
} else {
    $rosterText = ''
    Write-Info "roster file '$rosterRel' not found in the repo-root -- treated as empty."
}

# Enabled plugins from .claude/settings.json (mirrors bootstrap.ps1).
$settingsPath = Join-Path $repoRoot '.claude\settings.json'
$enabledIds = @()
if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
    $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($settings.PSObject.Properties.Name -contains 'enabledPlugins') {
        $enabledIds = @($settings.enabledPlugins.PSObject.Properties |
            Where-Object { $_.Value -eq $true } | ForEach-Object { $_.Name })
    }
} else {
    Write-Info "no .claude/settings.json in the repo-root -- nothing enabled to check."
}

if ($enabledIds.Count -eq 0 -and (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
    Write-Info "no enabled plugins in .claude/settings.json -- nothing to check."
}

$allBackingIds = @{}
$pluginNames = @()

foreach ($plugId in ($enabledIds | Sort-Object -Unique)) {
    $parts = $plugId.Split('@')
    $name = $parts[0]
    $marketplace = if ($parts.Count -gt 1) { $parts[1] } else { '' }

    # Guardrail: plugin-name/marketplace come from settings and become path segments -- validate as
    # slugs before touching the filesystem (mirrors check-connectors' Get-PluginDir).
    if (-not (Test-PluginNameSlug -Name $name)) {
        Write-Failure "invalid plugin id '$plugId' in .claude/settings.json -- skipped."
        continue
    }
    if (-not $marketplace) {
        Write-Info "plugin '$plugId' has no '@marketplace' suffix -- cannot resolve its cache dir, skipped."
        continue
    }
    if (-not (Test-PluginMarketplaceSlug -Marketplace $marketplace)) {
        Write-Failure "invalid marketplace in plugin id '$plugId' -- skipped."
        continue
    }

    $pluginDir = Resolve-PluginDir -Name $name -Marketplace $marketplace -CacheRoot $cacheRoot
    if ($null -eq $pluginDir) {
        Write-Info "plugin '$plugId' is enabled but not found in the cache ($cacheRoot) -- skipped (the install may run on another machine)."
        continue
    }

    $pluginNames += $name
    foreach ($bid in (Get-BackingIds -PluginDir $pluginDir)) { $allBackingIds[$bid] = $true }
    $agentIds = @(Get-AgentIds -PluginDir $pluginDir)

    Write-Host "`n-- plugin: $plugId (cache $(Split-Path $pluginDir -Leaf))" -ForegroundColor Cyan
    if ($agentIds.Count -eq 0) { Write-Info "no agents found for '$plugId'."; continue }

    $canonicalLensDir = Get-CanonicalLensDir -RepoRoot $repoRoot -PluginName $name
    $legacyLensDir    = Join-Path $repoRoot '.claude\extensions'
    # Non-canonical family dirs found while walking this plugin's agents -- reported once per dir after
    # the loop instead of once per lens, so a whole pre-#179 tree yields one line, not sixteen.
    $offPathDirs = @{}

    foreach ($id in $agentIds) {
        if ($ignoredIds -contains $id) {
            Write-Info "agent '$id' ($plugId) deliberately kept out of the roster/lenses (repo-config ignore-list) -- skipped."
            continue
        }
        $inRoster = Test-InRoster -RosterText $rosterText -Id $id
        $lensPath = Get-LensPath -RepoRoot $repoRoot -PluginName $name -Id $id
        $hasLens  = [bool]$lensPath
        if (-not $inRoster) {
            Write-Failure "agent '$id' ($plugId) has no roster row in $rosterRel -- add it to the roster."
        }
        if (-not $hasLens) {
            Write-Failure "agent '$id' ($plugId) has no repo-lens (.claude/plugins/$(Get-LensFamily)/$name/$id-extension.md or the legacy .claude/extensions/ path)."
        }
        if ($inRoster -and $hasLens) { Write-Ok "agent '$id' present in roster + lens" }

        # Lens on a non-canonical family segment (INFO -- issue #179): a bootstrap from before that fix
        # derived the family from the install path, which in the plugin-cache layout is the MARKETPLACE
        # name. The lens is present and fully functional, so this is NOT missing-lens drift -- flagging
        # it as such is exactly the misleading report #179 was filed about. Soft on purpose: silent at
        # session start, visible on a deliberate run, and the @-import in CLAUDE.md is the thing to
        # check when the tree is moved.
        if ($hasLens) {
            $lensDir = Split-Path $lensPath -Parent
            if ($lensDir -ne $canonicalLensDir -and $lensDir -ne $legacyLensDir) {
                if (-not $offPathDirs.ContainsKey($lensDir)) { $offPathDirs[$lensDir] = 0 }
                $offPathDirs[$lensDir]++
            }
        }

        # Header drift (INFO -- issue #145): a lens generated by an older scaffold bakes the persona's
        # first name into its header ("# Sean <midDot> repo-lens"). After a rename that name is stale in
        # every consumer, yet the lens itself is present, so this is NOT missing-lens drift -- it is a
        # cosmetic mismatch. Kept INFO on purpose: silent at session start (the hook only surfaces
        # [ERROR]), shown on a deliberate run, and staged as a paste-ready reconcile by the sync-roster
        # skill. The nameless header the scaffold now writes never triggers this (its token is the g-id).
        if ($hasLens) {
            $staleName = Get-ScaffoldHeaderName -LensPath $lensPath -MidDot $midDot
            if ($staleName -and $staleName -ne $id) {
                $current = Get-DisplayName -RawName (Get-AgentName -PluginDir $pluginDir -Id $id) -Fallback $id
                if ($current -and $staleName -ne $current) {
                    Write-Info "lens '$id' ($plugId) header still names '$staleName' (agent is now '$current') -- run the sync-roster skill to reconcile the header."
                }
            }
        }
    }

    foreach ($d in ($offPathDirs.Keys | Sort-Object)) {
        $rel = $d
        if ($rel.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $rel = $rel.Substring($repoRoot.Length).TrimStart('\', '/')
        }
        Write-Info "$($offPathDirs[$d]) lens file(s) for '$plugId' live in '$rel' instead of the canonical '.claude\plugins\$(Get-LensFamily)\$name' -- they are found and counted as present; move them (and the CLAUDE.md @-import along with them) to align with the standard."
    }
}

# Orphans (INFO): roster tokens / lens files whose id has no backing agent or persona among the
# resolved enabled plugins. Only run when at least one plugin resolved -- otherwise we have no basis to
# call anything an orphan (e.g. the only enabled plugin is not on this machine).
if ($pluginNames.Count -gt 0) {
    Write-Host "`n-- orphans" -ForegroundColor Cyan
    $lensIds = Get-LensIds -RepoRoot $repoRoot -PluginNames ($pluginNames | Sort-Object -Unique)
    $rosterTokenIds = @([regex]::Matches($rosterText, '(?<!\d)\d{2}-\d{2}(?!\d)') |
        ForEach-Object { $_.Value } | Sort-Object -Unique)

    $orphanFound = $false
    foreach ($id in (@($lensIds.Keys) + $rosterTokenIds | Sort-Object -Unique)) {
        if ($allBackingIds.ContainsKey($id)) { continue }
        $where = @()
        if ($lensIds.ContainsKey($id)) { $where += 'lens' }
        if ($rosterTokenIds -contains $id) { $where += 'roster' }
        Write-Info "orphan '$id' ($($where -join ' + ')) -- no matching agent/persona in any enabled plugin."
        $orphanFound = $true
    }
    if (-not $orphanFound) { Write-Ok "no orphan roster tokens / lens files" }
}

Write-CheckSummary
