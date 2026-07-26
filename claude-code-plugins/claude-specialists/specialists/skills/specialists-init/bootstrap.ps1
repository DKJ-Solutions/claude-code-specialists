<#
.SYNOPSIS
    Bootstrap script for the specialists-init skill: sets up the non-plugin layer of the
    Claude-Specialists system in a CONSUMING repo -- the orchestrator + main loop personas
    (Chris/Derek/Rendall) via @-imports in CLAUDE.md, plus a documented settings/hooks proposal.
.DESCRIPTION
    A Claude Code plugin can provide subagents, but CANNOT inject always-on main-loop context
    and cannot edit a consumer's CLAUDE.md. Chris (the orchestrator) is precisely such
    main-loop context: he is loaded via an @-import at the bottom of the consumer's CLAUDE.md.
    This script fills that gap. It is invoked by the skill AFTER the consumer has already set up
    the marketplace source + enabledPlugins and restarted the session (otherwise the skill
    itself is not yet available -- the chicken-and-egg documented by the skill in step 0).

    The repo lenses live at the PLUGIN PATH (.claude/plugins/<family>/<plugin>/, the standard) and
    the persona lenses are LENS-ONLY: no body copy, only the repo's own '## Specific to this repo' slot.
    The portable body comes directly from the plugin install via an @-import (the ~/.claude/plugins/
    marketplaces/... path). This way, every behavior rule lives in one place (the plugin), not duplicated.

    It performs only SAFE, additive actions -- it never overwrites existing content:
      1. Places a LENS-ONLY extension per persona (<plugin>/personas/<g>-<id>-persona.md) in
         <ConsumerRoot>/.claude/plugins/<family>/<plugin>/<g>-<id>-extension.md -- only if it does
         not exist yet. The body comes from the plugin install; the extension only carries the repo lens slot.
      1b. Places an empty lens scaffold on the plugin path for each subagent of the ENABLED
         plugin(s) (enabledPlugins in the consumer's settings; without settings, only its own plugin),
         clearly marked as VUL-IN.
      1c. Places the repo-specific script config scaffolds required by the shared workflow skills
         (open-pr / fold-changelog): scripts/repo-config.ps1 (Get-RepoName / Get-RepoBlobUrl /
         Get-LintScript) and scripts/lib/branch-info.ps1 (the prefix table). Both as VUL-IN scaffolds
         with an EMPTY branch table -- taxonomy differs per repo. Without these files, a clean consumer
         hits a raw dot-sourcing error (#86). Never overwrites.
      2. Ensures that <ConsumerRoot>/CLAUDE.md carries the TWO orchestrator @-imports at the bottom:
         the body from the plugin install (~/.claude/plugins/marketplaces/.../01-01-persona.md) and
         the repo lens (.claude/plugins/<family>/<plugin>/01-01-extension.md). If CLAUDE.md is missing,
         it writes a minimal scaffold; if the imports already exist, it does nothing.
      3. Writes a proposal snippet (.claude/settings.suggested.jsonc) with recommended
         permissions.deny + a hooks stub. It DOES NOT touch settings.json -- a JSON merge is
         repo-specific and risky, so that evaluation is left to the user/Claude.

    Exit code: 0 = done (even if everything was already present). 1 = plugin persona source or
    ConsumerRoot was not found.
.PARAMETER ConsumerRoot
    Root of the consuming repo. Default: current working directory.
.EXAMPLE
    powershell -File bootstrap.ps1
.EXAMPLE
    powershell -File bootstrap.ps1 -ConsumerRoot C:\path\to\my-repo
#>
param(
    [string]$ConsumerRoot = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# The persona source is two levels above this script: <plugin>/skills/specialists-init/ -> <plugin>/personas/
$personaDir = Join-Path $PSScriptRoot '../../personas'
if (-not (Test-Path -LiteralPath $personaDir -PathType Container)) {
    Write-Host "Cannot find the persona source ($personaDir) -- stopping." -ForegroundColor Red
    exit 1
}
$personaDir = (Resolve-Path -LiteralPath $personaDir).Path
if (-not (Test-Path -LiteralPath $ConsumerRoot -PathType Container)) {
    Write-Host "ConsumerRoot '$ConsumerRoot' does not exist -- stopping." -ForegroundColor Red
    exit 1
}
$ConsumerRoot = (Resolve-Path -LiteralPath $ConsumerRoot).Path

# --- Derive plugin + the ~ path to the plugin install ---------------------------------------------
# personaDir = <...>/claude-code-plugins/<family>/<plugin>/personas (source/marketplace-clone layout) or
# <...>/<marketplace>/<plugin>/<version>/personas (plugin-cache layout). From that we derive the plugin
# carrying the personas. The portable body comes from the plugin install; if personaDir falls under user
# home (~), the standard marketplace cache, we express that path as a ~ path for the @-import in CLAUDE.md.
#
# The FAMILY segment is deliberately NOT derived here (issue #179). It used to be, and in the
# plugin-cache layout that derivation yields the MARKETPLACE name: a repo installed through
# 'specialists@davekjohns-workshop' got its lenses written to .claude/plugins/davekjohns-workshop/,
# while check-roster-sync.ps1 only ever looked under 'claude-specialists' -- so it reported 16 existing
# lenses as missing, and the fix it suggested would have created a second copy of each on a second
# path. The family is a property of the plugin family, not of the marketplace it came from, so it now
# comes from Get-LensFamily in check-report-lib.ps1: one value, shared by this writer, sync-roster.ps1
# and the check.
$segs = ($personaDir -replace '/', '\') -split '\\' | Where-Object { $_ }
$ccpIdx = [array]::IndexOf([string[]]$segs, 'claude-code-plugins')
if ($ccpIdx -ge 0 -and ($ccpIdx + 2) -lt $segs.Count) {
    $personaPlugin = $segs[$ccpIdx + 2]
} else {
    $pdParent = Split-Path $personaDir -Parent
    if ((Split-Path $pdParent -Leaf) -match '^\d+\.\d+\.\d+') {
        $personaPlugin = Split-Path (Split-Path $pdParent -Parent) -Leaf
    } else {
        $personaPlugin = Split-Path $pdParent -Leaf
    }
}
# check-report-lib.ps1 travels in the same plugin payload as this skill, so a $PSScriptRoot-relative
# dot-source resolves from the source repo, the marketplace clone and the plugin cache alike (the same
# reasoning sync-roster.ps1 relies on). A missing lib must never stop a bootstrap -- this is the script
# that sets a repo up in the first place -- so it falls back to the same literal the lib returns.
$lensLib = Join-Path $PSScriptRoot '../../scripts/lib/check-report-lib.ps1'
if (Test-Path -LiteralPath $lensLib -PathType Leaf) { . $lensLib }
$family = if (Get-Command Get-LensFamily -ErrorAction SilentlyContinue) { Get-LensFamily } else { 'claude-specialists' }
# Durable body path: the written @-import must NEVER point to the version-pinned cache. The cache
# (~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/) is ephemeral -- after a plugin update,
# the old version directory is purged (~7 days) and an import pointing to it breaks; the orchestrator body
# then fails to load. The marketplaces clone (~/.claude/plugins/marketplaces/<marketplace>/) is versionless
# and pulled upon update: that is the durable anchor. @-imports do NOT support variable expansion
# (${CLAUDE_PLUGIN_ROOT} etc. do not work there), so we write a fixed, versionless path. If bootstrap already
# runs from the marketplaces clone or a non-cache location (e.g. source repo consuming itself), $personaDir
# is already durable and nothing changes.
function Get-DurablePersonaDir([string]$PersonaDir, [string]$Plugin) {
    $parts = ($PersonaDir -replace '/', '\') -split '\\' | Where-Object { $_ }
    $cacheIdx = [array]::IndexOf([string[]]$parts, 'cache')
    # Only intervene on real cache layout .../plugins/cache/<mp>/<plugin>/<version>/personas.
    if ($cacheIdx -lt 1 -or ($cacheIdx + 1) -ge $parts.Count) { return $PersonaDir }
    if ($parts[$cacheIdx - 1] -ne 'plugins') { return $PersonaDir }
    $marketplace = $parts[$cacheIdx + 1]
    if ($marketplace -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { return $PersonaDir }
    $clone = Join-Path (($parts[0..($cacheIdx - 1)] -join '\')) (Join-Path 'marketplaces' $marketplace)
    if (-not (Test-Path -LiteralPath $clone -PathType Container)) { return $PersonaDir }
    # Search clone for personas directory under a directory named exactly as the plugin and carrying
    # the orchestrator body (01-01-persona.md is the import target -- it must actually exist).
    $hit = Get-ChildItem -LiteralPath $clone -Recurse -Directory -Filter 'personas' -ErrorAction SilentlyContinue |
        Where-Object {
            (Split-Path $_.Parent.FullName -Leaf) -eq $Plugin -and
            (Test-Path -LiteralPath (Join-Path $_.FullName '01-01-persona.md'))
        } | Select-Object -First 1
    if ($hit) { return $hit.FullName }
    return $PersonaDir
}
$durablePersonaDir = Get-DurablePersonaDir -PersonaDir $personaDir -Plugin $personaPlugin

$homeDir = $HOME
if ($durablePersonaDir.StartsWith($homeDir, [System.StringComparison]::OrdinalIgnoreCase)) {
    $personaTilde = '~' + $durablePersonaDir.Substring($homeDir.Length)
} else {
    $personaTilde = $durablePersonaDir
}
$personaTilde = $personaTilde -replace '\\', '/'

# Plugin path in the consumer (standard location for lenses).
$padRel = ".claude/plugins/$family"
$padDirRoot = Join-Path $ConsumerRoot (".claude/plugins/$family")

Write-Host "== specialists-init bootstrap -- $ConsumerRoot ==" -ForegroundColor Cyan

# --- 1. Persona lenses (LENS-ONLY) to plugin path (never overwrite) ------------------------
$personaDest = Join-Path $padDirRoot $personaPlugin
if (-not (Test-Path -LiteralPath $personaDest)) { New-Item -ItemType Directory -Path $personaDest -Force | Out-Null }

$copied = 0; $kept = 0
Get-ChildItem -Path $personaDir -Filter '*-persona.md' -File | Sort-Object Name | ForEach-Object {
    if ($_.BaseName -notmatch '^(\d{2})-(\d{2})-persona$') { return }
    $g = $Matches[1]; $id = $Matches[2]
    $dest = Join-Path $personaDest "$g-$id-extension.md"
    if (Test-Path -LiteralPath $dest -PathType Leaf) {
        Write-Host "  [keep]  $(Split-Path $dest -Leaf) already exists -- not overwritten." -ForegroundColor DarkGray
        $script:kept++
        return
    }
    # Extract title (first # heading) from template; we do NOT copy the body itself (lens-only).
    # Read as UTF8 -- title contains an emoji and em-dash that otherwise become mojibake.
    $title = ''
    foreach ($line in (([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)) -split "`r?`n")) {
        if ($line -match '^#\s') { $title = $line.TrimEnd(); break }
    }
    if (-not $title) { $title = "# $g-$id" }
    $bodyPath = "$personaTilde/$($_.Name)"
    if ($g -eq '01' -and $id -eq '01') {
        $loadNote = 'Chris loads his body automatically via the `@` import at the bottom of `CLAUDE.md`; other personas are read on-demand from this path.'
    } else {
        $loadNote = 'The body is read on-demand from this path when Chris brings in this persona (no static `@` import).'
    }
    $content = @"
---
id: $id
group: $g
---

$title

> Repo-lens (lens-only persona) -- portable body lives in the plugin source:
> ``$bodyPath``.
> $loadNote

## Specific to this repo (VUL-IN)

<!-- TODO (fill in after bootstrap): replace this placeholder with the repo lens of this
     specialist -- who he or she directs or serves in THIS repo and along which agreements:
     team and routing, pipelines and gatekeepers (safety rules, branch discipline,
     and PR rule; refer to repo-CLAUDE.md#safety-rules). The portable expertise remains in the
     plugin persona; only repo-specific matters belong here. -->
"@
    [System.IO.File]::WriteAllText($dest, ($content.TrimEnd() + "`n"), $Utf8NoBom)
    Write-Host "  [create] lens-only $padRel/$personaPlugin/$(Split-Path $dest -Leaf)" -ForegroundColor Green
    $script:copied++
}

# --- 1b. Empty lens scaffolds for subagent specialists (never overwrite) --------------------
# Agent definitions come from plugin(s); repo lens per specialist lives at consumer's plugin path.
# For each agent of enabled plugin(s), place an empty, marked scaffold.

# Own plugin name: in source layout, directory name is plugin name; in plugin cache, it is
# directory above version directory (...\<plugin>\<x.y.z>\).
function Get-OwnPluginName([string]$PluginRoot) {
    $leaf = Split-Path $PluginRoot -Leaf
    if ($leaf -match '^\d+\.\d+\.\d+') { return (Split-Path (Split-Path $PluginRoot -Parent) -Leaf) }
    return $leaf
}

# agents/ directory of a plugin in both layouts (source: sibling directory; cache: <name>\<version>\agents).
# Note dual role of $parent (Victor finding): in source layout it's family directory, in cache layout
# plugin name directory (above version directories) -- $market resolves to proper parent root in both cases.
function Get-PluginAgentsDir([string]$PluginName, [string]$OwnPluginRoot) {
    $parent = Split-Path $OwnPluginRoot -Parent
    $src = Join-Path $parent (Join-Path $PluginName 'agents')
    if (Test-Path -LiteralPath $src -PathType Container) { return (Resolve-Path -LiteralPath $src).Path }
    $market = Split-Path $parent -Parent
    $nameDir = Join-Path $market $PluginName
    if (Test-Path -LiteralPath $nameDir -PathType Container) {
        # Semantic sort via [version] (Victor finding): plain string sort puts 1.9.0 above
        # 1.10.0 once a version segment reaches two digits.
        $versions = Get-ChildItem -LiteralPath $nameDir -Directory |
            Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
            Sort-Object { [version]$_.Name } -Descending
        foreach ($v in $versions) {
            $a = Join-Path $v.FullName 'agents'
            if (Test-Path -LiteralPath $a -PathType Container) { return (Resolve-Path -LiteralPath $a).Path }
        }
    }
    return $null
}

$ownPluginRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$ownPluginName = Get-OwnPluginName $ownPluginRoot

# Enabled plugins from consumer settings; without (readable) settings, only own plugin.
# Plugin names validated as slugs before converting to paths.
$pluginNames = @($ownPluginName)
$consumerSettings = Join-Path $ConsumerRoot '.claude/settings.json'
if (Test-Path -LiteralPath $consumerSettings -PathType Leaf) {
    try {
        $cs = Get-Content -LiteralPath $consumerSettings -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cs.PSObject.Properties.Name -contains 'enabledPlugins') {
            $enabledNames = @($cs.enabledPlugins.PSObject.Properties |
                Where-Object { $_.Value -eq $true } |
                ForEach-Object { $_.Name.Split('@')[0] })
            if ($enabledNames.Count -gt 0) { $pluginNames = $enabledNames }
        }
    } catch {
        Write-Host "  [notice] .claude/settings.json unreadable -- lens scaffolds only for '$ownPluginName'." -ForegroundColor Yellow
    }
}

$scaffolded = 0; $lensKept = 0
foreach ($pluginName in ($pluginNames | Sort-Object -Unique)) {
    if ($pluginName -notmatch '^[a-z0-9][a-z0-9-]*$') {
        Write-Host "  [notice] plugin name '$pluginName' is not a valid slug -- skipped." -ForegroundColor Yellow
        continue
    }
    $agentsDir = Get-PluginAgentsDir -PluginName $pluginName -OwnPluginRoot $ownPluginRoot
    if ($null -eq $agentsDir) {
        Write-Host "  [notice] agents directory of plugin '$pluginName' not found -- skipped." -ForegroundColor Yellow
        continue
    }
    $pluginPad = Join-Path $padDirRoot $pluginName
    if (-not (Test-Path -LiteralPath $pluginPad)) { New-Item -ItemType Directory -Path $pluginPad -Force | Out-Null }
    Get-ChildItem -Path $agentsDir -Filter '*-agent.md' -File | Sort-Object Name | ForEach-Object {
        if ($_.BaseName -notmatch '^(\d{2})-(\d{2})-agent$') { return }
        $group = $Matches[1]; $id = $Matches[2]
        $dest = Join-Path $pluginPad "$group-$id-extension.md"
        if (Test-Path -LiteralPath $dest -PathType Leaf) { $script:lensKept++; return }
        $midDot = [char]0x00B7
        # Rename-proof (issue #145): the header carries the STABLE '<group>-<id>' slug, never the
        # persona's first name -- so a later rename of the agent-def never drifts this generated
        # header. The name lives in exactly one place, the agent-def's `name:` frontmatter.
        $slug = "$group-$id"
        $template = @"
---
id: $id
group: $group
---

# $slug $midDot repo lens (VUL-IN)

> Repo lens alongside portable domain guide for specialist $slug in ``$pluginName`` plugin.
> Created by ``specialists-init`` as empty template; agent definition reads it automatically.
> Fill in repo-specific tasks and context below that specialist $slug needs in this repo.

## Specific to this repo (VUL-IN)

<!-- TODO: describe what this specialist does in THIS repo:
     - which files/directories belong to their domain;
     - repo-specific tasks, conventions, and agreements;
     - references to safety rules / gatekeepers for this repo.
     Portable expertise remains in plugin manual; only repo-specific matters belong here. -->
"@
        [System.IO.File]::WriteAllText($dest, $template, $Utf8NoBom)
        Write-Host "  [create] lens scaffold $padRel/$pluginName/$group-$id-extension.md" -ForegroundColor Green
        $script:scaffolded++
    }
}

# --- 1c. Repo-specific script config scaffolds (never overwrite) -----------------------------------
# Shared skills open-pr/fold-changelog rely on two repo-specific files in consumer repo root
# (scripts/repo-config.ps1 + scripts/lib/branch-info.ps1). Without them, clean consumer hits raw dot-source error (#86).
# specialists-init places them as VUL-IN scaffolds: repo-agnostic structure with empty spots to fill.
# Branch taxonomy differs per repo and deliberately remains an EMPTY table -- never another repo's taxonomy.
$repoConfigScaffold = @'
<#
.SYNOPSIS
    Repo-specific configuration for shared workflow scripts (open-pr / fold-changelog).
.DESCRIPTION
    Placed by specialists-init as a VUL-IN scaffold. Shared skills read this small block of
    repo data from repo root; scripts themselves are repo-agnostic. Fill in remaining VUL-IN values
    below and remove VUL-IN markers. RepoName is automatically derived from git remote (origin) by
    bootstrap if it has a github.com address; otherwise remains VUL-IN.

    No Set-StrictMode here: dot-sourcing would modify calling script's strict mode.
    Pure ASCII (repo convention for .ps1): Windows PowerShell 5.1 reads BOM-less script as ANSI.
#>

# VUL-IN: GitHub repo hosting this repository (owner/name), e.g. 'DaveKJohn/my-repo'.
$script:RepoName = 'VUL-IN/repo'

function Get-RepoName {
    return $script:RepoName
}

function Get-RepoBlobUrl {
    return "https://github.com/$($script:RepoName)/blob/main/"
}

# VUL-IN: repo-root-relative path to lint gate executed by open-pr before PR,
# e.g. 'scripts/lint/check-plugin-integrity.ps1' or 'scripts/maintenance/lint-brain.ps1'.
$script:LintScript = 'VUL-IN'

function Get-LintScript {
    return $script:LintScript
}

# Optional (#101): if this repo's PR template uses different marker text than the workshop's own,
# or a PR should carry a default assignee/milestone, define any of these four functions --
# Get-PrDescriptionPlaceholder, Get-PrApprovalPattern, Get-PrAssignee, Get-PrMilestone -- and
# open-pr.ps1 picks them up automatically. Left undefined here on purpose: open-pr.ps1 falls back
# to its own built-in defaults (this repo's current markers, no assignee/milestone) when any of
# these four are absent, so a fresh consumer needs none of this to get started.
'@

$branchInfoScaffold = @'
<#
.SYNOPSIS
    Shared branch conventions for workflow scripts (repo-specific prefix table).
.DESCRIPTION
    Placed by specialists-init as a VUL-IN scaffold. Provides Get-BranchTypes, Get-BranchPrefix, and
    Get-BranchInfo. Prefix table determines GitHub label for PR and changelog entry type, and is
    DIFFERENT PER REPO -- fill in your branch taxonomy below (table intentionally empty).

    No Set-StrictMode here: dot-sourcing would modify calling script's strict mode.
    Pure ASCII (repo convention for .ps1).
#>

# VUL-IN: canonical branch types in release notes order, e.g. @('Feat', 'Fix', 'Docs', 'Chore').
$script:BranchTypeOrder = @()

# VUL-IN: prefix -> GitHub label (PR) + branch type (changelog entry). Example:
#   feat  = @{ Label = 'enhancement';   Type = 'Feat' }
#   fix   = @{ Label = 'bug';           Type = 'Fix' }
#   docs  = @{ Label = 'documentation'; Type = 'Docs' }
#   chore = @{ Label = 'documentation'; Type = 'Chore' }
$script:BranchPrefixTable = @{
}

function Get-BranchTypes {
    return $script:BranchTypeOrder
}

function Get-BranchPrefix {
    param([Parameter(Mandatory = $true)][string]$Branch)
    if ($Branch -match '/') { return ($Branch -split '/')[0] }
    return ($Branch -split '-')[0]
}

function Get-BranchInfo {
    param([Parameter(Mandatory = $true)][string]$Branch)
    $prefix = Get-BranchPrefix -Branch $Branch
    $known  = $script:BranchPrefixTable.ContainsKey($prefix)
    [pscustomobject]@{
        Branch   = $Branch
        Prefix   = $prefix
        IsKnown  = $known
        Label    = $(if ($known) { $script:BranchPrefixTable[$prefix].Label } else { $null })
        Type     = $(if ($known) { $script:BranchPrefixTable[$prefix].Type } else { $null })
        SafeName = $Branch -replace '/', '-'
    }
}
'@

# Derive repo name from consumer's git remote (ergonomics): eliminates manual setup for RepoName.
# Remote URL is external input placed into written .ps1 and later used in `gh --repo` -- strictly validate
# (Sean advice) and fall back to VUL-IN placeholder on any doubt. Git invocation must never crash bootstrap
# (missing git/no origin -> clean fallback), wrapped in try/catch.
# Intentionally `git config --get remote.origin.url` NOT `git remote get-url`: latter applies
# `insteadOf` rewrites (CI runners and some dev setups set globally, e.g. git@github.com: -> https),
# making returned format unpredictable. `config --get` gives RAW stored origin -- exactly what consumer configured.
function Get-DerivedRepoName([string]$Root) {
    # Intentionally NO `... | Select-Object -First 1` directly on git call: pipe aborts upstream (git)
    # prematurely on first line, terminating process with non-zero exit code if git hasn't cleanly exited -- timing-dependent.
    # Flaky `$LASTEXITCODE` caused guard below to return `$null` (VUL-IN instead of derived name), causing non-deterministic red CI.
    # Capture complete output first, record exit code immediately, then apply `Select-Object` on static array.
    try {
        $out  = & git -C $Root config --get remote.origin.url 2>$null
        $code = $LASTEXITCODE
    } catch {
        return $null
    }
    if ($code -ne 0) { return $null }
    $url = ($out | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($url)) { return $null }
    # Only github.com; all common forms (https/ssh/git scheme + scp-like git@github.com:).
    # owner/repo as strict slug; remove .git suffix and trailing slash. Scheme forms may carry optional
    # userinfo (e.g. 'x-access-token:TOKEN@' -- how git insteadOf rule rewrites remote, or origin URL with credentials);
    # userinfo intentionally NOT captured -- owner/repo only. Userinfo cannot contain '/', so 'evil.com/x@github.com' spoof won't match.
    $m = [regex]::Match($url.Trim(), '^(?:(?:https|ssh|git)://(?:[^/@]+@)?github\.com/|git@github\.com:)(?<owner>[A-Za-z0-9][A-Za-z0-9._-]*)/(?<repo>[A-Za-z0-9][A-Za-z0-9._-]*?)(?:\.git)?/?$')
    if (-not $m.Success) { return $null }
    return "$($m.Groups['owner'].Value)/$($m.Groups['repo'].Value)"
}

# Insert derived name into repo config scaffold (before $scriptScaffolds assembly so new content is included).
# If derivation fails, VUL-IN placeholder remains.
$derivedRepo = Get-DerivedRepoName $ConsumerRoot
if ($derivedRepo) {
    $repoConfigScaffold = $repoConfigScaffold.Replace(
        "# VUL-IN: GitHub repo hosting this repository (owner/name), e.g. 'DaveKJohn/my-repo'.",
        "# Derived by specialists-init from git remote (origin) of this repo. Adjust if incorrect.")
    $repoConfigScaffold = $repoConfigScaffold.Replace(
        "`$script:RepoName = 'VUL-IN/repo'",
        "`$script:RepoName = '$derivedRepo'")
}

$scriptScaffolds = @(
    @{ Rel = 'scripts/repo-config.ps1';     Content = $repoConfigScaffold }
    @{ Rel = 'scripts/lib/branch-info.ps1'; Content = $branchInfoScaffold }
)
$scriptScaffolded = 0; $scriptKept = 0
$repoConfigDerived = $false
foreach ($s in $scriptScaffolds) {
    $dest = Join-Path $ConsumerRoot $s.Rel
    if (Test-Path -LiteralPath $dest -PathType Leaf) {
        Write-Host "  [keep]   $($s.Rel) already exists -- not overwritten." -ForegroundColor DarkGray
        $scriptKept++
        continue
    }
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    [System.IO.File]::WriteAllText($dest, ($s.Content.TrimEnd() + "`n"), $Utf8NoBom)
    $note = ''
    if ($s.Rel -eq 'scripts/repo-config.ps1' -and $derivedRepo) {
        $note = " (RepoName derived: $derivedRepo)"
        $repoConfigDerived = $true
    }
    Write-Host "  [create] script scaffold $($s.Rel)$note" -ForegroundColor Green
    $scriptScaffolded++
}

# --- 2. The two @-imports at the bottom of CLAUDE.md (plugin body + repo lens) --------------------
$bodyImport = "@$personaTilde/01-01-persona.md"
$lensImport = "@$padRel/$personaPlugin/01-01-extension.md"
$claudeMd = Join-Path $ConsumerRoot 'CLAUDE.md'
$importBlock = @"

The orchestrator (Chris) is always loaded -- portable body from plugin install and repo lens
from plugin path; routes on-demand to specialists in ``$padRel/``.

$bodyImport

$lensImport
"@

if (-not (Test-Path -LiteralPath $claudeMd -PathType Leaf)) {
    $scaffold = @"
# CLAUDE.md

This repo is governed by **Claude Specialists** -- a team of specialized Claudes led by a Chief of Staff.
This scaffold was created by ``specialists-init`` skill; expand with governance and safety rules for this repo.
$importBlock
"@
    [System.IO.File]::WriteAllText($claudeMd, $scaffold, $Utf8NoBom)
    Write-Host "  [create] CLAUDE.md scaffold created with orchestrator imports." -ForegroundColor Green
} else {
    $md = [System.IO.File]::ReadAllText($claudeMd, [System.Text.Encoding]::UTF8)
    if ($md -match [regex]::Escape($lensImport)) {
        Write-Host "  [keep]   CLAUDE.md already has orchestrator imports." -ForegroundColor DarkGray
    } else {
        $md = $md.TrimEnd() + "`n" + $importBlock + "`n"
        [System.IO.File]::WriteAllText($claudeMd, $md, $Utf8NoBom)
        Write-Host "  [add]    orchestrator imports added to bottom of CLAUDE.md." -ForegroundColor Green
    }
}

# --- 3. Settings/hooks proposal (DOES NOT touch settings.json) -------------------------------------
$claudeDir = Join-Path $ConsumerRoot '.claude'
if (-not (Test-Path -LiteralPath $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }
$suggestPath = Join-Path $claudeDir 'settings.suggested.jsonc'
$suggestion = @'
// PROPOSAL -- created by specialists-init. This is NOT active configuration.
// Copy desired blocks to .claude/settings.json (or settings.local.json) and remove
// this file afterward. Hooks are a STUB: scripts are repo-specific and do not exist here yet --
// replace with guards/lints appropriate for this repo (or omit).
{
  // Governance: block destructive git actions prohibited by safety rules.
  "permissions": {
    "deny": [
      "Bash(git push --force:*)",
      "Bash(git push -f:*)",
      "Bash(git reset --hard:*)",
      "Bash(git rebase:*)",
      "Bash(rm -rf:*)"
    ]
  },
  // Safety hooks: STUB. Point to actual scripts in this repo (e.g. scripts/maintenance/*.ps1) or
  // remove unused hooks. Example: Stop hook running lint on changes.
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command",
          "command": "powershell -NoProfile -File scripts/maintenance/lint-changed-hook.ps1",
          "timeout": 30 } ] }
    ]
  }
}
'@
[System.IO.File]::WriteAllText($suggestPath, $suggestion, $Utf8NoBom)
Write-Host "  [create] .claude/settings.suggested.jsonc placed (proposal -- not active)." -ForegroundColor Green

# --- Report ----------------------------------------------------------------------------------------
Write-Host ""
Write-Host "Done: $copied persona-lens(es) created, $kept already present; $scaffolded lens-scaffold(s) created, $lensKept already present; $scriptScaffolded script-scaffold(s) created, $scriptKept already present." -ForegroundColor Cyan
Write-Host "Next steps (manual -- script intentionally leaves settings.json/hooks untouched):" -ForegroundColor Cyan
Write-Host "  1. Fill '## Specific to this repo' slot in each $padRel/*/*-extension.md with repo lens (VUL-IN scaffolds can stay empty until specialist has work here)." -ForegroundColor Gray
if ($repoConfigDerived) {
    Write-Host "  2. Want to use shared workflow skills (open-pr / fold-changelog)? RepoName already derived from git remote ($derivedRepo) -- fill Get-LintScript in scripts/repo-config.ps1 and branch prefix table in scripts/lib/branch-info.ps1." -ForegroundColor Gray
} else {
    Write-Host "  2. Want to use shared workflow skills (open-pr / fold-changelog)? Fill scripts/repo-config.ps1 (RepoName + LintScript) and scripts/lib/branch-info.ps1 (branch prefix table) -- VUL-IN scaffolds ready." -ForegroundColor Gray
}
Write-Host "  3. Copy desired parts from .claude/settings.suggested.jsonc to settings.json and delete proposal." -ForegroundColor Gray
Write-Host "  4. Restart Claude Code session to activate new @-imports + config." -ForegroundColor Gray
exit 0