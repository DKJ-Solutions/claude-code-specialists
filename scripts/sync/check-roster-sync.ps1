<#
.SYNOPSIS
    Roster-sync check: detects when a consumer's repo roster and repo lenses lag behind the agents
    that the ENABLED plugins actually ship (LAYER 1 -- detection only, no fixes).

.DESCRIPTION
    When a plugin release adds a new specialist (e.g. Ravi 06-24), a consumer that updates the plugin
    gets no signal that its roster (a table/list in CLAUDE.md) and its repo lenses now lag behind.
    This script surfaces that drift by comparing three sources:

      (a) Specialists of the ENABLED plugins -- agents AND personas. Enabled plugins are read via
          Get-EnabledPlugins (check-report-lib.ps1) from the SAME settings chain Claude Code honors --
          the user ~/.claude/settings.json, .claude/settings.json and .claude/settings.local.json, per
          plugin id, local winning (enabledPlugins: a plugin id like 'specialists@davekjohns-workshop'
          counts as enabled when its value is $true). Reading only .claude/settings.json is what made
          this check answer "roster in sync" for a repo with no roster at all (inbound #294): the enable
          lived in settings.local.json, so the check saw nothing enabled, the [BOOTSTRAP] branch could
          not fire, and an exit-0 run with no findings reads as health. For each enabled plugin
          the versioned dir is resolved in the local plugin cache (semantically highest version,
          [version]-sort -- the same approach bootstrap.ps1 uses so 1.10.0 beats 1.9.0). Agent ids
          ('<group>-<id>', e.g. 06-24) come from <plugin-dir>/agents/<g>-<id>-agent.md, persona ids
          from <plugin-dir>/personas/<g>-<id>-persona.md (inbound #204 -- see the persona note below).
      (b) The consumer's roster. Its path comes from Get-RosterPath in scripts/repo-config.ps1
          (default 'CLAUDE.md', repo-root-relative). "Present in the roster" is decided by scanning the
          roster text for each '<group>-<id>' token (format-agnostic -- works for a table OR a list;
          deliberately NOT a brittle table parser).
      (c) The lens files, looked up via Get-LensDirCandidates (check-report-lib.ps1 -- the same source
          the writers use, issues #179 and #221): the canonical seam
          .claude/specialists/lenses/<g>-<id>-extension.md, the pre-seam
          .claude/plugins/claude-specialists/<plugin>/ path that is still written for a consumer with a
          tree there, a non-canonical family segment left behind by a pre-#179 bootstrap, and the
          legacy .claude/extensions/<g>-<id>-extension.md.

    Findings + severity (same [OK]/[INFO]/[ERROR] convention as check-connectors.ps1):
      - agent/persona WITHOUT a roster row -> [ERROR] (the core case this feature exists for: a new
                                                 specialist that is invisible in the governance doc).
      - agent/persona WITHOUT a lens file  -> [ERROR] (actionable drift for a real specialist: no
                                                 landing spot for its repo-specific context).
      - orphan (a roster token OR a lens file whose '<group>-<id>' has NO matching agent AND no
        matching persona in any enabled plugin) -> [INFO] (could be a just-removed specialist; also
        soft because personas are counted as backing, see below), PLUS one [ORPHANS] roll-up line
        stating the count. That roll-up is non-counting (like [OK]) and exists so the orphan trail is
        not silent at session start: the hook suppresses [INFO] but does surface [ORPHANS], so the
        finding reaches a session without turning a legitimate transition red (inbound #204).
      - lens on a NON-CANONICAL family segment -> [INFO] (issue #179): a pre-fix bootstrap derived the
                                                 family from the install path and so wrote the lenses
                                                 under the marketplace name. The lens works and counts
                                                 as present; the line only points at the misalignment
                                                 (reported once per directory, not once per lens). The
                                                 two locations current writers actually use -- the seam
                                                 and the pre-seam plugin path -- are NOT reported; see
                                                 Get-OnPathLensDirs.
      - lens header still naming a STALE persona name -> [INFO] (issue #145): an older scaffold baked
        the first name into the lens header ("# Sean <midDot> repo-lens"); after a rename that name is
        stale, but the lens is present, so it is a cosmetic mismatch, not missing-lens drift. Soft on
        purpose (silent at session start); the sync-roster skill stages a paste-ready reconcile.
      - plugin ENABLED but with no install record for this path -> one [NOT-INSTALLED-HERE] roll-up
        (non-counting, like [ORPHANS]) plus a non-counting detail line per plugin naming the enabling
        layer and the administration consulted (inbound #302). Enabling is only half
        of what Claude Code needs; without a record in ~/.claude/plugins/installed_plugins.json for THIS
        projectPath a session loads none of that plugin -- no skills, no subagents, no hooks -- and every
        drift line this check prints about it then describes a surface the repo does not have. Measured:
        27 [ERROR] lines about a session that had loaded zero specialists. Not an error, because the repo
        is not broken and the state is usually one install command away from intended; never silent,
        because "no hooks because the plugin is not loaded" reads exactly like "no hooks because all is
        well". See Get-InstallRecord in check-report-lib.ps1.

    Personas: main-loop specialists (Chris 01-01, Derek 05-05, Rendall 05-06, ...) ship as
    <plugin>/personas/<g>-<id>-persona.md, NOT as agents, yet legitimately have a roster row and a
    lens. They count as "backing" so they are never flagged as orphans -- and, since inbound #204,
    they are ALSO checked for a missing roster row / missing lens, exactly like agents. Those used to
    be one decision; they are two, and only the first followed from the reasoning. "A persona is not an
    orphan" is right. "A persona can therefore never be missing" does not follow: measured in life-hub,
    the check validated 20 specialists where that repo's own duplicate compared 24 -- the gap being
    precisely the persona-only specialists, so the roster could lose Chris's row and stay green.
    The ONE persona exception left is the lens-header drift check (see Get-CheckedSpecialists and the
    header-drift block), which needs a `name:` field personas do not have.

    Consequence worth knowing when adopting this: a persona a consumer deliberately does NOT roster is
    now real drift. That is what the Get-RosterIgnoredIds ignore-list is for -- record the choice there
    (this workshop does so for Bianca 03-02), rather than relying on the check being blind to it.

    What to DO with an [ERROR] from this check (Dave, July 28, 2026): adopt. A specialist that arrives
    with a plugin update is adopted by default -- no approval question, and no per-specialist "which of
    these do you want?". The sync-roster skill stages it; its SKILL.md carries the full reasoning. The
    scaffold is empty on purpose and may stay empty until that specialist has work here, so adopting
    costs nothing that has to be filled in today. The ignore-list above is the deliberate exception you
    write on your own initiative, not the answer to a question this check asks.

    Exit-code: 0 = no errors (INFO does not count), 1 = at least one error.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Use this path as the consumer repo root instead of the dual-context default.

.PARAMETER CacheRootOverride
    (Optional, for tests) Use this dir as the plugin cache root instead of
    $env:USERPROFILE/.claude/plugins/cache -- lets a fixture supply a controlled agent set / versions.

.PARAMETER UserHomeOverride
    (Optional, for tests) Use this dir as the user home when resolving the user layer of the settings
    chain (~/.claude/settings.json), instead of $env:USERPROFILE -- lets a fixture exercise the chain
    without touching the real machine's user settings. Scoped to the SETTINGS CHAIN only: the install
    administration (inbound #302) is a different file answering a different question and is read via
    $env:USERPROFILE, so a fixture that wants to control it redirects that env var for the child process
    -- the pattern the connector version test already uses.

.EXAMPLE
    .\scripts\sync\check-roster-sync.ps1
#>
param(
    [string]$ConsumerPathOverride = '',
    [string]$CacheRootOverride = '',
    [string]$UserHomeOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:errors = 0
$script:infos  = 0

# Middle dot used in the scaffold-lineage lens header; kept as a code point so this file stays ASCII.
$midDot = [char]0x00B7

# Write-Ok/Write-Info/Write-Failure + Test-PluginNameSlug/Test-PluginMarketplaceSlug + Resolve-PluginDir
# + Resolve-CheckRoot/Write-CheckScope: shared with check-connectors.ps1 and
# skills/sync-roster/sync-roster.ps1 (single source, issue #114). This script is a whole-file mirror
# (scripts/lib/shared-scripts-lib.ps1); check-report-lib.ps1 is registered in that same pair set and
# therefore travels along, so a $PSScriptRoot-relative dot-source (not $repoRoot -- this lib is not
# repo-owned, unlike repo-config.ps1/branch-info.ps1) resolves correctly whether this file runs from
# the workshop root or the plugin mirror. Dot-sourced BEFORE the repo-root resolution below, which
# now comes from that same shared lib.
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')

# Repo-root -- dual-context via the shared Resolve-CheckRoot: a consumer running the plugin mirror
# gets its repo-root from CLAUDE_PROJECT_DIR; in the workshop-root (or outside a session) it falls
# back to the git-root. This keeps the root-copy and the plugin-mirror byte-identical (guarded by the
# shared-scripts drift-lint). -ConsumerPathOverride wins so a fixture can point the check at a
# throwaway consumer. The returned Source/Note travel into the [SCOPE] line further down, so a
# finding surfaced by the session hook always names the repo it is about (inbound #203).
$scope = Resolve-CheckRoot -Override $ConsumerPathOverride
if (-not $scope.Path) {
    Write-Host '== check-roster-sync ==' -ForegroundColor Cyan
    Write-Failure "no repo root could be resolved ($($scope.Note)) -- nothing was checked."
    Write-CheckSummary
}
$repoRoot = $scope.Path

# Plugin cache root (overridable for tests).
$cacheRoot = if ($CacheRootOverride) { $CacheRootOverride } else { Join-Path $env:USERPROFILE '.claude\plugins\cache' }

# Agent ids ('<group>-<id>') a plugin ships (source a).
function Get-AgentIds {
    param([string]$PluginDir)
    $dir = Join-Path $PluginDir 'agents'
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $dir -Filter '*-agent.md' -File |
        ForEach-Object { if ($_.BaseName -match '^(\d{2})-(\d{2})-agent$') { "$($Matches[1])-$($Matches[2])" } } |
        Sort-Object -Unique)
}

# Persona ids ('<group>-<id>') a plugin ships (source a', alongside the agents).
function Get-PersonaIds {
    param([string]$PluginDir)
    $dir = Join-Path $PluginDir 'personas'
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $dir -Filter '*-persona.md' -File |
        ForEach-Object { if ($_.BaseName -match '^(\d{2})-(\d{2})-persona$') { "$($Matches[1])-$($Matches[2])" } } |
        Sort-Object -Unique)
}

# Ids that BACK a roster token / lens: agents + personas. Personas run in the main loop (not as
# subagents) but are real specialists with roster rows + lenses, so counting them prevents false orphans.
function Get-BackingIds {
    param([string]$PluginDir)
    return @(@(Get-AgentIds -PluginDir $PluginDir) + @(Get-PersonaIds -PluginDir $PluginDir) | Sort-Object -Unique)
}

# The specialists whose roster row + lens this check REQUIRES: agents and personas alike, each tagged
# with its kind so a finding can name what it is about.
#
# Why personas belong here (inbound #204): the old exclusion bundled two decisions into one, and only
# the first followed from the reasoning. "A persona is not an orphan" is right -- Get-BackingIds above
# keeps that intact. "A persona can therefore never be MISSING" does not follow: a persona is a real
# specialist with a roster row and a lens, exactly like an agent, and when the row or the lens is gone
# that is actionable drift of precisely the kind this check exists for. Measured in life-hub: the check
# validated 20 specialists where the repo's own duplicate compared 24 -- the gap being exactly the
# persona-only main-loop specialists. The roster could lose Chris's or Derek's row and stay green.
#
# An id that is BOTH an agent and a persona counts as an agent: the agent file is the one with a
# `name:` to compare a lens header against, so that kind carries strictly more checking.
function Get-CheckedSpecialists {
    param([string]$PluginDir)
    $agentIds = @(Get-AgentIds -PluginDir $PluginDir)
    $records = @($agentIds | ForEach-Object { [pscustomobject]@{ Id = $_; Kind = 'agent' } })
    # NOT $pid -- that is a PowerShell automatic variable (the process id); shadowing it in a loop is
    # the kind of quiet breakage that surfaces somewhere else entirely.
    foreach ($personaId in (Get-PersonaIds -PluginDir $PluginDir)) {
        if ($agentIds -contains $personaId) { continue }
        $records += [pscustomobject]@{ Id = $personaId; Kind = 'persona' }
    }
    return @($records | Sort-Object Id)
}

# "Present in the roster": scan the roster text for the literal '<group>-<id>' token, bounded so
# '06-24' still matches inside '06-24-extension.md' but NOT inside '106-240' or an ISO date like
# '2026-07-25'. The boundary itself is Get-RosterIdTokenPattern's (check-report-lib.ps1) single
# source, shared with the orphan-scan below -- issue #182. Format-agnostic on purpose (table or
# list) -- see the Get-RosterPath note in repo-config.ps1.
function Test-InRoster {
    param([string]$RosterText, [string]$Id)
    return ($RosterText -match (Get-RosterIdTokenPattern -Id $Id))
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

# The directories a lens may live in WITHOUT being off-path -- what the writers actually produce today,
# canonical first. Candidates 0 and 1 of Get-LensDirCandidates: the seam .claude/specialists/lenses/
# (issue #221, where a FRESH consumer's lenses land) and the pre-seam .claude/plugins/<family>/<plugin>/
# path (where Get-LensWriteDir still writes for a consumer that already has a tree there). Neither is a
# misalignment, so neither belongs in the off-path report.
#
# This function used to be Get-CanonicalLensDir and returned ONLY the pre-seam path, hardcoded -- while
# the shared source (Get-LensDirCandidates/Get-SeamPaths in check-report-lib.ps1) had already named the
# seam canonical. A repo that migrated onto the seam therefore had every one of its OWN lenses reported
# as living somewhere non-canonical, with the remedy pointing back at the layout it had just left: a
# reader following that advice would undo the migration. Derive both from the shared source, so the
# reader cannot drift from the writers again the way it did here.
function Get-OnPathLensDirs {
    param([string]$RepoRoot, [string]$PluginName)
    return @(
        (Get-SeamPaths -RepoRoot $RepoRoot).LensDir,
        (Join-Path (Join-Path (Join-Path $RepoRoot '.claude\plugins') (Get-LensFamily)) $PluginName)
    )
}

# A path rendered relative to the repo root, for display in a finding. Used for BOTH sides of the
# off-path report's "X instead of Y" sentence, so the canonical target it names is the same value the
# comparison actually used rather than a literal repeated in the message.
function Get-RelativeToRoot {
    param([string]$RepoRoot, [string]$Path)
    if ($Path.StartsWith($RepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $Path.Substring($RepoRoot.Length).TrimStart('\', '/')
    }
    return $Path
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

Write-Host '== check-roster-sync ==' -ForegroundColor Cyan
Write-CheckScope -Scope $scope -CheckName 'check-roster-sync'

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

# Drop '@'-import lines before anything reads this text (issue #227). The bootstrap writes
# '@.claude/plugins/<family>/<plugin>/01-01-extension.md' into CLAUDE.md, and that path CONTAINS the
# token '01-01' -- so the roster test was satisfied by the import itself and Chris counted as rostered
# with no roster row anywhere in the file. Measured: 18 ids reported missing after a bootstrap instead
# of 19, and 01-01 is the worst possible one to lose, because a persona appears in no always-on listing
# and the roster row is the ONLY thing that makes them exist for a session.
#
# Narrow on purpose. Get-RosterIdTokenPattern's docstring records that binding the token to a
# roster-row/table shape was DELIBERATELY rejected (inbound #182): Test-InRoster is asked about an id in
# free prose, and a table shape would change behaviour for consumers who format their roster as a list.
# That reasoning still holds and is not overturned here. An '@'-import is a different thing entirely --
# a line the bootstrap writes, never a roster row under any formatting convention -- so excluding it
# needs none of that risk.
#
# Residual, unchanged and deliberately not chased: a repo whose roster file happens to reference a lens
# path in ORDINARY PROSE still satisfies the test for that id. This repo does exactly that (Chris's lens
# is linked from the routing prose), so its 01-01 would pass even without a table row -- harmless here,
# because the real roster row exists. Same accepted class as the prose false positives in #182.
$rosterText = (($rosterText -split "`r?`n") | Where-Object { $_ -notmatch '^\s*@' }) -join "`n"

# Enabled plugins from the whole settings chain, not settings.json alone (inbound #294 -- the shared
# Get-EnabledPlugins carries the measurement and the reasoning; same source the bootstrap uses).
$enabled = Get-EnabledPlugins -RepoRoot $repoRoot -UserHomeOverride $UserHomeOverride
$enabledIds = @($enabled.Ids)

# A settings file that does not parse is an ERROR, not a crash. It used to be the latter: under
# $ErrorActionPreference = 'Stop' a malformed settings.json killed the run, and the hook could only say
# "the roster check could not complete (exit N)" without naming the file. Get-EnabledPlugins keeps
# reading the rest of the chain, so the check still reports everything it can AND says which layer is
# broken -- and it must stay an error, because a chain the check could not fully read is exactly the
# state in which "nothing enabled" would be an unearned conclusion.
foreach ($badLayer in @($enabled.Unreadable)) {
    Write-Failure "$badLayer does not parse as JSON -- its enabledPlugins entries were not read."
}

# [NOTHING-ENABLED]: its own non-counting roll-up, so the session hook can give this state its own
# verdict instead of letting it fall through to "roster in sync with the enabled plugins" (inbound
# #294, symptom 1). Same shape as [ORPHANS]/[BOOTSTRAP]: the [INFO] lines below stay for a deliberate
# run, and this one line is what reaches a session. It is NOT an error -- a repo that has genuinely
# enabled nothing is not broken -- but it must never read as a checked, healthy roster.
if ($enabledIds.Count -eq 0) {
    Write-Host "  [NOTHING-ENABLED] no plugin is enabled for this repo -- checked $($enabled.Summary); nothing was compared against the roster." -ForegroundColor Yellow
    if (-not $enabled.AnyFileExists) {
        Write-Info "no settings file in the chain ($(($enabled.Layers | ForEach-Object { $_.Label }) -join ', ')) -- nothing enabled to check."
    } elseif (-not $enabled.AnyKeyFound) {
        Write-Info "no 'enabledPlugins' key in $($enabled.Summary) -- nothing to check."
    } else {
        # KeySummary, not Summary (inbound #304). Summary phrases the layers that EXIST, which is exactly
        # right one line up ("-- checked <Summary>": a claim about what was inspected) and wrong here,
        # where the layer IS the answer. Measured against life-hub: the key sat in one of three layers --
        # the user one, as an empty object -- and this line named all three, sending a reader looking for
        # it to two repo-owned files that demonstrably do not have it. See Get-EnabledPlugins' KeyIn.
        Write-Info "'enabledPlugins' is present in $($enabled.KeySummary) but enables nothing -- nothing to check."
    }
}

# --- Enabled, but is it installed for THIS path? (inbound #302) -----------------------------------
# The second half of what Claude Code needs, and until now the half no check read. An enable without an
# install record for this project path loads nothing -- no skills, no subagents, no hooks -- while this
# script happily reports every specialist of that plugin as drift. See Get-InstallRecord for the
# measurement (27 [ERROR] lines about a session surface that was not there) and for why a record without
# a projectPath still counts.
#
# Only asked when something is enabled at all. With nothing enabled the question has no subject, and the
# [NOTHING-ENABLED] roll-up above has already said everything there is to say -- adding a second line
# about an administration nobody is waiting for is the session-start noise PR #99 removed.
if ($enabledIds.Count -gt 0) {
    $installRecord = Get-InstallRecord -RepoRoot $repoRoot

    # An administration that exists but does not parse is an [ERROR], on the same reasoning as an
    # unreadable settings layer above: it is the authority on this question, and an authority the check
    # could not read is exactly the state in which any conclusion drawn from it is unearned.
    if ($installRecord.Exists -and -not $installRecord.Readable) {
        Write-Failure "$($installRecord.Path) does not parse as JSON ($($installRecord.Error)) -- whether the enabled plugins are installed for this path was not checked."
    }

    $notInstalledHere = @($enabledIds | Where-Object { -not (Test-PluginInstalledHere -InstallRecord $installRecord -PluginId $_) })

    # [NOT-INSTALLED-HERE]: its own non-counting roll-up, in the family of [NOTHING-ENABLED]/[BOOTSTRAP]/
    # [ORPHANS]. NOT an error -- the repo is not broken, and the state is usually one command away from
    # intended -- but it must never read as a checked, healthy roster, because every finding printed below
    # it is about a specialist surface no session in this repo can see.
    #
    # ONE line, naming the count and the ids, rather than one line per plugin: the session hooks surface
    # this marker, and a repo with several enabled plugins would otherwise produce a wall of
    # near-identical lines at every start -- the noise PR #99 removed. The per-plugin detail follows as
    # [INFO], visible on a deliberate run.
    #
    # Worth knowing about its own reach: in the WORST case of this state -- no plugin installed for this
    # path at all -- nothing in this repo runs the hook that would surface this line, because the hook
    # ships in the plugin. That is not an argument against the marker but the reason the same query now
    # also runs in check-connectors, from the workshop, ABOUT each registered consumer: the one vantage
    # point that still has a voice when a consumer has gone silent.
    if ($notInstalledHere.Count -gt 0) {
        # Format-SafeToken on every id before it is joined into this line (inbound #309). A plugin id is
        # an 'enabledPlugins' KEY NAME, so it is an arbitrary JSON string that may carry newlines -- and
        # this is a line the session hooks forward into the session context, where an unsanitized value
        # could forge a line of its own. Same reasoning Set-CheckScope has carried since #203; it just
        # was not applied to the ids.
        $shownIds = (@($notInstalledHere | ForEach-Object { Format-SafeToken -Value $_ }) -join ', ')
        Write-Host "  [NOT-INSTALLED-HERE] $($notInstalledHere.Count) of $($enabledIds.Count) enabled plugin(s) have no install record for this path ($shownIds) -- a session here will not load them, so anything reported below about them concerns a surface this repo does not have. Fix: 'claude plugin install <id> --scope project' from this root." -ForegroundColor Yellow
        # NON-COUNTING supporting facts, deliberately not [INFO]. The roll-up above is the signal; these
        # add the enabling layer (the #294 promise: never leave a reader guessing WHERE an enable came
        # from) and the administration path that was consulted. Two reasons they must not count:
        #   - one enabled plugin without a record would otherwise add a permanent info signal to every
        #     run, and "this repo reports 0 signals" is an assertion the test suite leans on to mean
        #     something. A baseline that can never be zero is a baseline nobody reads twice.
        #   - inbound #302 asked for this as a verdict, not an error and not a counting signal, on the
        #     grounds that the repo is not broken. Counting it would have smuggled the severity back in
        #     through the summary line.
        foreach ($plugId in $notInstalledHere) {
            Write-Skip "'$(Format-SafeToken -Value $plugId)' is enabled in $($enabled.LayerById[$plugId]) but has no record for this path in $($installRecord.Path) -- enabled is not installed."
        }
    } elseif (-not $installRecord.Exists) {
        # Said out loud rather than passed over: 'no administration file' is the one shape in which every
        # plugin looks installed to the predicate above (absence of the authority is not evidence of
        # absence), so a reader must not mistake that silence for a positive answer. Non-counting for the
        # same reason as above -- it is a statement about what could not be checked, not a finding about
        # this repo.
        Write-Skip "no plugin administration found at $($installRecord.Path) -- whether the enabled plugins are installed for this path could not be checked."
    }
}

# --- Is this repo bootstrapped at all? (issue #225) -----------------------------------------------
# A repo that has never run specialists-init has no lenses and no roster rows, so EVERY enabled
# specialist is "missing" twice over. Measured on a fresh consumer: 38 [ERROR] lines from this check
# alone, and nothing anywhere naming the skill that resolves them -- which reads as "this plugin is
# broken" rather than "you are not done yet". Drift reporting is right for a bootstrapped repo and
# wrong for an unbootstrapped one, and until now the check could not tell those apart.
#
# The predicate is deliberately strict -- no lens ANYWHERE and no roster row for ANY id. A repo with
# roster rows but no lenses is a maintained repo that has drifted, and must keep erroring; the same
# holds the other way round. Only the state where neither exists is "never bootstrapped".
#
# The seam directory belongs in this scan, and its absence was the same pre-seam hardcode as
# Get-OnPathLensDirs': a consumer whose lenses live in .claude/specialists/lenses/ (i.e. any consumer
# bootstrapped since #221) looked lens-less here, so one empty roster slot was enough to declare it
# never bootstrapped -- and the [BOOTSTRAP] line would then swallow every real finding behind advice to
# run specialists-init on a repo that already has its whole lens tree in place.
$anyLensFile = $false
foreach ($dir in @((Get-SeamPaths -RepoRoot $repoRoot).Dir, (Join-Path $repoRoot '.claude\plugins'), (Join-Path $repoRoot '.claude\extensions'))) {
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    if (@(Get-ChildItem -LiteralPath $dir -Recurse -Filter '*-extension.md' -File -ErrorAction SilentlyContinue).Count -gt 0) {
        $anyLensFile = $true; break
    }
}
# Any '<gg>-<ii>' token at all in the roster, using the same boundary rule as Test-InRoster so a
# stray ISO date or a page range cannot pass for a roster row (issue #182).
$anyRosterRow = $rosterText -match '(?<![\d-])\d{2}-\d{2}(?![\d-])'

$unbootstrapped = ($enabledIds.Count -gt 0) -and (-not $anyLensFile) -and (-not $anyRosterRow)
# Counts specialists actually resolved from a cache dir, so the marker below only fires when there was
# genuinely something to report. Deliberately NOT an early exit before the plugin loop: a first version
# did that and broke the "plugin enabled but not in the cache" case, telling the reader to run
# specialists-init when the real problem was that the plugin is not installed on this machine at all.
# The loop therefore still runs and still reports everything else it knows -- not-in-cache, orphans,
# off-path lenses -- and only the two "missing twice over" findings per specialist are replaced.
$suppressedForBootstrap = 0
$allBackingIds = @{}
$pluginNames = @()

foreach ($plugId in ($enabledIds | Sort-Object -Unique)) {
    $parts = $plugId.Split('@')
    $name = $parts[0]
    $marketplace = if ($parts.Count -gt 1) { $parts[1] } else { '' }

    # The DISPLAY form of this id, bound once per iteration (inbound #309). $plugId itself must stay raw:
    # it is a hashtable key ($enabled.LayerById) and the source of the path segments below, so sanitizing
    # it in place would break lookups and silently change which directory is resolved. Two variables, with
    # one job each -- the raw value for logic, this one for every message. Bound here rather than wrapped
    # at each of the dozen call sites below, so a message added later cannot forget it.
    $plugIdShown = Format-SafeToken -Value $plugId

    # Guardrail: plugin-name/marketplace come from settings and become path segments -- validate as
    # slugs before touching the filesystem (mirrors check-connectors' Get-PluginDir).
    #
    # These two use Format-SuspectToken, not Format-SafeToken: here the id IS the complaint, so showing a
    # cleaned-up version without saying so would present a plausible id as the subject of an "invalid id"
    # error -- hiding the very characters that made it invalid.
    if (-not (Test-PluginNameSlug -Name $name)) {
        Write-Failure "invalid plugin id '$(Format-SuspectToken -Value $plugId)' in $($enabled.LayerById[$plugId]) -- skipped."
        continue
    }
    if (-not $marketplace) {
        Write-Info "plugin '$plugIdShown' has no '@marketplace' suffix -- cannot resolve its cache dir, skipped."
        continue
    }
    if (-not (Test-PluginMarketplaceSlug -Marketplace $marketplace)) {
        Write-Failure "invalid marketplace in plugin id '$(Format-SuspectToken -Value $plugId)' -- skipped."
        continue
    }

    $pluginDir = Resolve-PluginDir -Name $name -Marketplace $marketplace -CacheRoot $cacheRoot
    if ($null -eq $pluginDir) {
        Write-Info "plugin '$plugIdShown' is enabled but not found in the cache ($cacheRoot) -- skipped (the install may run on another machine)."
        continue
    }

    $pluginNames += $name
    foreach ($bid in (Get-BackingIds -PluginDir $pluginDir)) { $allBackingIds[$bid] = $true }
    # Agents AND personas (inbound #204) -- see Get-CheckedSpecialists for why the persona exclusion
    # only ever held for the orphan side.
    $specialists = @(Get-CheckedSpecialists -PluginDir $pluginDir)

    # The enabling LAYER travels in this header (inbound #294). Same reasoning as the [SCOPE] line: a
    # reader who is surprised that a plugin is being checked here at all needs the one fact that explains
    # it, and with a three-file chain -- one of which is outside the repo -- "enabled" is no longer
    # self-evidently a property of .claude/settings.json.
    Write-Host "`n-- plugin: $plugIdShown (cache $(Split-Path $pluginDir -Leaf), enabled in $($enabled.LayerById[$plugId]))" -ForegroundColor Cyan
    if ($specialists.Count -eq 0) { Write-Info "no agents or personas found for '$plugIdShown'."; continue }

    $onPathLensDirs   = @(Get-OnPathLensDirs -RepoRoot $repoRoot -PluginName $name)
    $canonicalLensDir = $onPathLensDirs[0]
    $legacyLensDir    = Join-Path $repoRoot '.claude\extensions'
    # Non-canonical family dirs found while walking this plugin's specialists -- reported once per dir
    # after the loop instead of once per lens, so a whole pre-#179 tree yields one line, not sixteen.
    $offPathDirs = @{}

    foreach ($spec in $specialists) {
        $id   = $spec.Id
        $kind = $spec.Kind
        if ($ignoredIds -contains $id) {
            Write-Info "$kind '$id' ($plugIdShown) deliberately kept out of the roster/lenses (repo-config ignore-list) -- skipped."
            continue
        }
        $inRoster = Test-InRoster -RosterText $rosterText -Id $id
        $lensPath = Get-LensPath -RepoRoot $repoRoot -PluginName $name -Id $id
        $hasLens  = [bool]$lensPath
        if ($unbootstrapped) {
            # Never bootstrapped, so both findings are guaranteed for every specialist and neither says
            # anything the one [BOOTSTRAP] line after the loop does not say better. Counted rather than
            # silently dropped, so the marker can state how much it stands in for.
            $suppressedForBootstrap++
        } else {
            if (-not $inRoster) {
                Write-Failure "$kind '$id' ($plugIdShown) has no roster row in $rosterRel -- add it to the roster."
            }
            if (-not $hasLens) {
                Write-Failure "$kind '$id' ($plugIdShown) has no repo-lens (.claude/specialists/lenses/$id-extension.md, the pre-seam .claude/plugins/$(Get-LensFamily)/$name/ path, or the legacy .claude/extensions/ path)."
            }
        }
        if ($inRoster -and $hasLens) { Write-Ok "$kind '$id' present in roster + lens" }

        # Lens on a non-canonical family segment (INFO -- issue #179): a bootstrap from before that fix
        # derived the family from the install path, which in the plugin-cache layout is the MARKETPLACE
        # name. The lens is present and fully functional, so this is NOT missing-lens drift -- flagging
        # it as such is exactly the misleading report #179 was filed about. Soft on purpose: silent at
        # session start, visible on a deliberate run, and the @-import in CLAUDE.md is the thing to
        # check when the tree is moved.
        if ($hasLens) {
            $lensDir = Split-Path $lensPath -Parent
            if ($onPathLensDirs -notcontains $lensDir -and $lensDir -ne $legacyLensDir) {
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
        #
        # AGENTS ONLY, and that is a known gap rather than an oversight (inbound #204). The comparison
        # needs the specialist's CURRENT name, which Get-AgentName reads from the agent file's `name:`
        # frontmatter. A persona file has no such field (only id/group), so for a persona there is no
        # authoritative name to compare against: Get-AgentName would return '', Get-DisplayName would
        # fall back to the id, and every persona lens whose header carries a name -- i.e. all of the
        # older ones -- would be reported as drifting from its own id. That is a false signal, and a
        # false signal in the exact register the hook is being taught to trust is worse than a missing
        # one. Header drift for personas stays undetectable until a persona carries a name in its
        # frontmatter; the missing-row/missing-lens checks above do cover personas.
        if ($hasLens -and $kind -eq 'agent') {
            $staleName = Get-ScaffoldHeaderName -LensPath $lensPath -MidDot $midDot
            if ($staleName -and $staleName -ne $id) {
                $current = Get-DisplayName -RawName (Get-AgentName -PluginDir $pluginDir -Id $id) -Fallback $id
                if ($current -and $staleName -ne $current) {
                    Write-Info "lens '$id' ($plugIdShown) header still names '$staleName' (agent is now '$current') -- run the sync-roster skill to reconcile the header."
                }
            }
        }
    }

    $canonicalRel = Get-RelativeToRoot -RepoRoot $repoRoot -Path $canonicalLensDir
    foreach ($d in ($offPathDirs.Keys | Sort-Object)) {
        $rel = Get-RelativeToRoot -RepoRoot $repoRoot -Path $d
        Write-Info "$($offPathDirs[$d]) lens file(s) for '$plugIdShown' live in '$rel' instead of the canonical '$canonicalRel' -- they are found and counted as present; move them (and the CLAUDE.md @-import along with them) to align with the standard."
    }
}

# Orphans (INFO): roster tokens / lens files whose id has no backing agent or persona among the
# resolved enabled plugins. Only run when at least one plugin resolved -- otherwise we have no basis to
# call anything an orphan (e.g. the only enabled plugin is not on this machine).
if ($pluginNames.Count -gt 0) {
    Write-Host "`n-- orphans" -ForegroundColor Cyan
    $lensIds = Get-LensIds -RepoRoot $repoRoot -PluginNames ($pluginNames | Sort-Object -Unique)
    $rosterTokenIds = @([regex]::Matches($rosterText, (Get-RosterIdTokenPattern)) |
        ForEach-Object { $_.Value } | Sort-Object -Unique)

    $orphanCount = 0
    foreach ($id in (@($lensIds.Keys) + $rosterTokenIds | Sort-Object -Unique)) {
        if ($allBackingIds.ContainsKey($id)) { continue }
        $where = @()
        if ($lensIds.ContainsKey($id)) { $where += 'lens' }
        if ($rosterTokenIds -contains $id) { $where += 'roster' }
        Write-Info "orphan '$id' ($($where -join ' + ')) -- no matching agent/persona in any enabled plugin."
        $orphanCount++
    }
    if ($orphanCount -eq 0) {
        Write-Ok "no orphan roster tokens / lens files"
    } else {
        # One machine-readable roll-up so the orphan trail is not silent at session start (inbound #204,
        # change 2). The per-orphan lines above stay [INFO] and stay suppressed by the hook, which is
        # deliberate: an orphan can be a legitimately just-removed specialist, and promoting it to
        # [ERROR] would put a red line in every session during any transition. But "only visible to
        # whoever deliberately runs the script" is in practice nobody, so the count gets its own
        # non-counting token that the hook DOES surface -- one line, and only when there is something
        # to say. Deliberately not a general "N info signals" line: this repo permanently carries
        # ignore-list [INFO]s, so that would fire at every single session start -- exactly the noise
        # the quieter session start (PR #99) removed.
        Write-Host "  [ORPHANS] $orphanCount roster token(s)/lens file(s) have no backing agent or persona in any enabled plugin -- a removed specialist leaves this behind." -ForegroundColor Yellow
    }
}

if ($suppressedForBootstrap -gt 0) {
    # Non-counting marker the session hooks surface, same shape as [ORPHANS] above and
    # [UNREGISTERED]/[INVENTORY] in connector-sessioncheck: the plugin install is fine, only this
    # repo's own side of the setup has not happened. Counting it as an error would put a red line and
    # exit 1 in every session of a repo whose owner has simply not got round to the bootstrap -- and
    # not shouting at that person is the entire point of issue #225.
    Write-Host "  [BOOTSTRAP] the specialists plugin is enabled here but this repo has not been set up yet: no repo lenses and no roster rows exist, so all $suppressedForBootstrap specialist(s) would each be reported missing twice over. Nothing is broken -- the subagents work; what is missing is the orchestrator and the repo-specific setup. Run the 'specialists-init' skill to put them in place: it is additive and never overwrites anything you have written." -ForegroundColor Yellow
}

Write-CheckSummary
