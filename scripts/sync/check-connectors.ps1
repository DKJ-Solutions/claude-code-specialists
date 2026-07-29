<#
.SYNOPSIS
    Connectors check: verifies whether all connected repos (connectors) are still in sync with
    this repo -- the source of truth.

.DESCRIPTION
    The register lives at family level, next to the plugin folders (deliberately NOT inside them,
    so it does not travel along with a consumer's plugin cache): ONE manifest per connected repo
    (claude-code-plugins/claude-specialists/connectors/<repo>.json), containing the extension
    inventory per plugin. Manifests contain only METADATA -- never
    lens content and never absolute machine paths; localCheckout is relative to this repo's root.

    Per connector this script checks:
      1. Checkout present on this machine?          no -> [SKIP] (not an error)
      2. Per plugin: enabled in .claude/settings.json?  no -> [ERROR]
      3. Per plugin: all registered extensions present?  one missing -> [ERROR]
         Extensions of that plugin that exist in the consumer but are NOT registered
         -> [INFO] (inbound signal: update the register or bring the change back here), plus a
         non-counting [INVENTORY] line the session hook surfaces when that drifted register is
         the one describing the repo the session is in -- the only case a reader here can act on.
      4. Per plugin: machine record (installed_plugins.json) older than source -> [ERROR];
         no record/no administration -> [INFO] (machine-specific, not a gate breach)
    The register no longer keeps a syncedVersion bookkeeping: the check reads the actual installed
    version from the machine record, and register administration that only duplicates numbers
    produced nothing but maintenance PRs (Dave's decision, July 20, 2026).
    After that, scripts/lint/check-consumer-drift.ps1 runs once per unique consumer
    (agent-def drift = error; persona drift = informational, as in that script itself).

    Guardrail (Sean's advice): manifest fields are data from a public repo and are never blindly
    trusted -- absolute or out-of-scope localCheckout paths and invalid plugin ids are rejected.

    Exit code: 0 = no errors (SKIP/INFO and the non-counting [UNREGISTERED]/[INVENTORY] markers do
    not count), 1 = at least one error.

.PARAMETER Manifest
    (Optional) Path to a single manifest instead of all connectors manifests.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Overrides localCheckout from the manifest.

.PARAMETER OnlyConsumer
    (Optional) Restrict the check to the manifest whose checkout resolves to this path
    (scoping for the SessionStart hook: a session only sees its own register data).

.PARAMETER SkipDrift
    Skip the check-consumer-drift step (faster; register checks only).

.PARAMETER SkipVersions
    Skip the machine-record check (e.g. on CI, where no plugin administration exists).

.EXAMPLE
    .\scripts\sync\check-connectors.ps1
.EXAMPLE
    .\scripts\sync\check-connectors.ps1 -SkipDrift -SkipVersions
#>
param(
    [string]$Manifest = '',
    [string]$ConsumerPathOverride = '',
    [string]$OnlyConsumer = '',
    [switch]$SkipDrift,
    [switch]$SkipVersions
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$FamilyRoot = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists'
$DriftLint  = Join-Path $RepoRoot 'scripts\lint\check-consumer-drift.ps1'

$script:errors = 0
$script:infos  = 0

# Write-Ok/Write-Info/Write-Failure + Test-PluginNameSlug: shared with check-roster-sync.ps1 (single
# source, issue #114). This script is workshop-only (not mirrored -- it reads the connectors/
# register that only exists here), so the lib is dot-sourced unconditionally.
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')

# Plugin id (before the '@') -> plugin folder under the family root, only if the name is a
# simple slug AND the folder actually exists under the family root; otherwise $null.
function Get-PluginDir([string]$PluginId) {
    $name = $PluginId.Split('@')[0]
    if (-not (Test-PluginNameSlug -Name $name)) { return $null }
    $dir = Join-Path $FamilyRoot $name
    if (-not (Test-Path -LiteralPath $dir)) { return $null }
    return $dir
}

# Ids (<group>-<id>) owned by a plugin: agents/ + personas/.
function Get-PluginIds([string]$PluginDir) {
    $ids = @()
    foreach ($sub in @('agents', 'personas')) {
        $dir = Join-Path $PluginDir $sub
        if (Test-Path -LiteralPath $dir) {
            $ids += Get-ChildItem -LiteralPath $dir -Filter '*.md' -File |
                ForEach-Object { $_.BaseName -replace '-(agent|persona)$', '' }
        }
    }
    return $ids | Sort-Object -Unique
}

# Collect manifests from the register at family level.
if ($Manifest) {
    $manifestFiles = @(Get-Item -LiteralPath $Manifest)
} else {
    $connectorsRoot = Join-Path $FamilyRoot 'connectors'
    $manifestFiles = @()
    if (Test-Path -LiteralPath $connectorsRoot) {
        $manifestFiles = @(Get-ChildItem -LiteralPath $connectorsRoot -Filter '*.json' -File)
    }
}

if ($manifestFiles.Count -eq 0) {
    Write-Host 'No connectors manifests found.' -ForegroundColor Yellow
    exit 0
}

$onlyPath = ''
if ($OnlyConsumer) {
    $onlyResolved = Resolve-Path -LiteralPath $OnlyConsumer -ErrorAction SilentlyContinue
    if ($onlyResolved) { $onlyPath = $onlyResolved.Path }
}

# Is this checkout the repo the current session is in? Two shapes, because the check runs two ways:
# a consumer's hook passes -OnlyConsumer <its own root>, while the workshop runs the full sweep with
# no scoping and finds itself as the connector whose localCheckout is '.'. Used to decide whether a
# register finding is actionable HERE (see the [INVENTORY] marker below); with -OnlyConsumer set,
# $onlyPath is authoritative -- falling back to $RepoRoot in that case would attribute a consumer's
# finding to the workshop.
function Test-IsSessionRepo {
    param([Parameter(Mandatory = $true)][string]$Checkout)
    if ($onlyPath) { return $Checkout -eq $onlyPath }
    return $Checkout -eq $RepoRoot
}

Write-Host "== check-connectors -- $($manifestFiles.Count) manifest(s) ==" -ForegroundColor Cyan

$checkedConsumers = @{}
$matched = 0

foreach ($mf in $manifestFiles) {
    $m = Get-Content -LiteralPath $mf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json

    # Every finding from here to the end of this iteration belongs to THIS connector, so it carries
    # that name (inbound #203). The session hook filters this script's output down to the signal
    # lines and drops the '== connector: <repo>' headers, which is how two consumers on the same
    # outdated plugin version produced two IDENTICAL, unattributable [ERROR] lines. Set per iteration
    # rather than once: a stale label from the previous connector would misattribute the guardrail
    # failures below, which fire before this connector's header is ever printed.
    # 'repo' is manifest content, so its presence is probed rather than assumed (StrictMode); the
    # manifest filename is a truthful fallback.
    $connectorLabel = $(if ($m.PSObject.Properties.Name -contains 'repo') { [string]$m.repo } else { $mf.Name })
    Set-CheckScope $connectorLabel

    # Determine the checkout, with guardrails on the manifest field. With -OnlyConsumer, manifests
    # of other consumers are SILENTLY skipped -- their guardrail messages should not land in
    # someone else's session either (Sean's advice, round 3).
    if ($ConsumerPathOverride) {
        $checkout = $ConsumerPathOverride
    } else {
        if ([System.IO.Path]::IsPathRooted($m.localCheckout)) {
            if ($OnlyConsumer) { continue }
            Write-Failure "absolute localCheckout path '$($m.localCheckout)' in $($mf.Name) -- rejected (relative sibling paths only)."
            continue
        }
        $checkout = Join-Path $RepoRoot $m.localCheckout
    }
    if (-not (Test-Path -LiteralPath $checkout)) {
        if (-not $OnlyConsumer) {
            Write-Host "`n== connector: $($m.repo)" -ForegroundColor Cyan
            Write-Skip "checkout '$($m.localCheckout)' not present on this machine -- not checked."
        }
        continue
    }
    $checkout = (Resolve-Path -LiteralPath $checkout).Path

    # Early scoping: only the manifest of the requested consumer gets through here.
    if ($onlyPath -and $checkout -ne $onlyPath) { continue }

    if (-not $ConsumerPathOverride) {
        $scopeRoot = (Resolve-Path -LiteralPath (Join-Path $RepoRoot '..\..')).Path
        if (-not $checkout.StartsWith($scopeRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Failure "localCheckout '$($m.localCheckout)' falls outside the allowed scope ('$scopeRoot') -- rejected."
            continue
        }
    }
    $matched++

    Write-Host "`n== connector: $($m.repo)" -ForegroundColor Cyan

    # Read the consumer's settings.json once.
    $settings = $null
    $settingsPath = Join-Path $checkout '.claude\settings.json'
    if (Test-Path -LiteralPath $settingsPath) {
        $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } else {
        Write-Failure ".claude/settings.json not found in '$checkout'"
    }

    foreach ($p in @($m.plugins)) {
        Write-Host "  -- plugin: $($p.id)" -ForegroundColor Cyan

        # Narrow the label to this plugin block. A consumer can register SEVERAL plugins, and a shared
        # cause (one outdated install) then produces one finding per plugin -- word-for-word identical
        # once the '-- plugin:' header above is filtered out of the session summary. Verified against
        # this repo's own register: smartwatchbanden has two plugin blocks, both behind, and the hook
        # surfaced two indistinguishable [ERROR] lines. Connector name alone was not enough (inbound
        # #203); the plugin id is what makes each line actionable.
        Set-CheckScope "$connectorLabel / $($p.id)"

        $pluginDir = Get-PluginDir $p.id
        if ($null -eq $pluginDir) {
            Write-Failure "invalid or unknown plugin field '$($p.id)' in $($mf.Name) -- plugin block skipped."
            continue
        }

        # 2. Plugin enabled in the consumer?
        if ($null -ne $settings) {
            $enabled = $false
            if ($settings.PSObject.Properties.Name -contains 'enabledPlugins') {
                $prop = $settings.enabledPlugins.PSObject.Properties | Where-Object { $_.Name -eq $p.id }
                if ($prop -and $prop.Value -eq $true) { $enabled = $true }
            }
            if ($enabled) { Write-Ok "plugin is enabled in .claude/settings.json" }
            else          { Write-Failure "plugin '$($p.id)' is NOT (or no longer) enabled in $settingsPath" }
        }

        # 3. Registered extensions present? + unregistered extensions of this plugin.
        # Lenses can live on the canonical plugin path (.claude/plugins/<family>/<plugin>/, since
        # life-hub parity), on a non-canonical family segment a pre-#179 bootstrap left behind, or on
        # the legacy path (.claude/extensions/). All count; Get-LensDirCandidates is the shared source
        # for that list (issue #179), fed the already-validated plugin id (see Get-PluginDir).
        $extDirs = @(@(Get-LensDirCandidates -RepoRoot $checkout -PluginName $p.id.Split('@')[0]) |
            Where-Object { Test-Path -LiteralPath $_ })

        $missing = @()
        foreach ($id in $p.extensions) {
            $hit = $false
            foreach ($dir in $extDirs) {
                if (Test-Path -LiteralPath (Join-Path $dir "$id-extension.md")) { $hit = $true; break }
            }
            if (-not $hit) { $missing += $id }
        }
        if ($missing.Count -gt 0) { Write-Failure ("registered extension(s) missing: " + ($missing -join ', ')) }
        else                      { Write-Ok  "all $(@($p.extensions).Count) registered extensions present" }

        $ownedIds = Get-PluginIds $pluginDir
        $present = @()
        foreach ($dir in $extDirs) {
            $present += Get-ChildItem -LiteralPath $dir -Filter '*-extension.md' -File |
                ForEach-Object { $_.BaseName -replace '-extension$', '' }
        }
        $unregistered = @($present | Sort-Object -Unique | Where-Object { ($ownedIds -contains $_) -and ($p.extensions -notcontains $_) })
        foreach ($id in $unregistered) {
            Write-Info "extension '$id' exists in the consumer but is not in the register -- update the register or review the change."
        }

        # Non-counting marker the session hook DOES surface -- but only when the drifted register is
        # the one describing the repo this session is actually in, which is the only case a reader
        # here can act on. Third instance of the [UNREGISTERED]/[ORPHANS] shape, and for the same
        # reason: the [INFO] above stays (it counts, and a deliberate run should list every id),
        # while this line carries the actionable text for a session start.
        #
        # Why it was needed (2026-07-29): a deliberate run found eleven of these at once, six of them
        # in the register of THIS repo -- the lenses had landed with the adopt-the-six change (PR #212)
        # and the inventory was never updated alongside. Nothing had surfaced it, because the finding
        # is an [INFO] and the hook shows only [ERROR] lines. The connectors README already carried an
        # "after a refresh, also update the manifest" rule; it was not enough, precisely because it
        # reads as a follow-up step and nothing reported the omission.
        #
        # Deliberately NOT promoted for every connector: that would reintroduce exactly the
        # other-machine noise the [INFO]-silence rule removed (Dave, July 20, 2026). Scoped this way
        # the rule's justification -- "often the business of another machine or user" -- simply does
        # not apply: this register is in the repo the reader has open. Decision by Dave, July 29, 2026.
        if ($unregistered.Count -gt 0 -and (Test-IsSessionRepo $checkout)) {
            Write-Host "  [INVENTORY] this repo has $($unregistered.Count) lens(es) that its own entry in the connector register does not list ($($unregistered -join ', ')) -- add them to the 'extensions' array in $($mf.Name), in the same change that landed the lens. Nothing is broken: the register's view of this repo is simply behind reality." -ForegroundColor Yellow
        }

        # 4. Machine record vs. source.
        if (-not $SkipVersions) {
            $pluginJsonPath = Join-Path $pluginDir '.claude-plugin\plugin.json'
            $sourceVersion = (Get-Content -LiteralPath $pluginJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json).version
            $adminPath = Join-Path $env:USERPROFILE '.claude\plugins\installed_plugins.json'
            if (Test-Path -LiteralPath $adminPath) {
                $admin = Get-Content -LiteralPath $adminPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $prop = $admin.plugins.PSObject.Properties | Where-Object { $_.Name -eq $p.id }
                # EVERY matching record, not the first one (#240). The old loop stopped at the first
                # hit -- an arbitrary pick dressed up as a fact. Measured on Dave's machine
                # (2026-07-29): `claude plugin list` showed `specialists` three times for one repo
                # (2.13.1, 2.11.0, 2.9.0), because ~/.claude.json holds several project records for
                # that checkout, in two path spellings. The [OK]/[ERROR] the session hook prints every
                # single start therefore rested on whichever record happened to come first in the JSON.
                #
                # Same defect family as #227, #235 and the teardown's docstring-VUL-IN: evidence that
                # looks conclusive while being satisfied by something other than what it claims to
                # measure. This one did not lie about a string -- it lied about WHICH of several
                # answers it had found. An honest "I cannot tell" is worth more than a confident wrong
                # number, and unlike the wrong number it is actionable.
                $recordMatches = @()
                if ($prop) {
                    # A record can carry a projectPath that no longer exists on this machine;
                    # Resolve-Path then returns $null and must never be blindly read via .Path
                    # (StrictMode crash, Victor's finding).
                    foreach ($rec in @($prop.Value)) {
                        if (-not ($rec.PSObject.Properties.Name -contains 'projectPath')) { continue }
                        $resolved = Resolve-Path -LiteralPath $rec.projectPath -ErrorAction SilentlyContinue
                        if (-not $resolved) { continue }
                        # Case-insensitively and without a trailing separator: the observed duplicates
                        # differ only in spelling, and on Windows that is the same directory. Two
                        # spellings of one path are not two answers.
                        if ($resolved.Path.TrimEnd('\', '/') -ieq $checkout.TrimEnd('\', '/')) { $recordMatches += $rec }
                    }
                }
                $recordVersions = @($recordMatches | ForEach-Object { $_.version } | Sort-Object -Unique)
                if ($recordMatches.Count -eq 0) {
                    Write-Info "no machine record for this consumer (the install may run via a different machine)."
                } elseif ($recordVersions.Count -gt 1) {
                    # Deliberately a failure, not an INFO: as long as the records disagree, every other
                    # version statement about this consumer is unreliable, and that is exactly what the
                    # reader must not take on trust.
                    Write-Failure "$($recordMatches.Count) machine records for this consumer disagree (v$($recordVersions -join ', v')) -- cannot determine which version is running here, so the source comparison (v$sourceVersion) is withheld. Clean up the duplicate project records for this checkout, then re-run."
                } elseif ($recordVersions[0] -eq $sourceVersion) {
                    Write-Ok "machine record is on the source version (v$sourceVersion)"
                } else {
                    Write-Failure "machine record is on v$($recordVersions[0]), source on v$sourceVersion -- update the plugin from the consumer (scope lesson)."
                }
            } else {
                Write-Info "no plugin administration found on this machine -- version check skipped."
            }
        }
    }

    # Back to connector level: anything reported from here on belongs to the connector as a whole, not
    # to whichever plugin block the loop above happened to end on.
    Set-CheckScope $connectorLabel

    if (-not $checkedConsumers.ContainsKey($checkout)) { $checkedConsumers[$checkout] = $m.repo }
}

# Back to run-level findings: clear the per-connector label so the notice below is not attributed to
# whichever connector the loop happened to walk last.
Set-CheckScope

if ($OnlyConsumer -and $matched -eq 0) {
    Write-Info "not registered: no manifest for this consumer in the register."
    # Non-counting marker the session hook DOES surface. The [INFO] above is suppressed at session
    # start (Dave's July 20, 2026 decision), which for this particular signal produced the worst
    # possible outcome: a brand-new consumer was told "connector-sessioncheck: no errors." -- a
    # positive all-clear for a repo this workshop cannot see at all. Found 2026-07-28 on a third
    # consumer that had been running, and filing inbound issues, unregistered for days.
    #
    # The [INFO] deliberately stays (it counts, and a deliberate run should report it in the summary);
    # this line carries the ACTIONABLE text for the session. Same shape as [ORPHANS] in
    # check-roster-sync (inbound #204): a dedicated non-counting token rather than promoting the
    # finding to [ERROR], which would make the exit code 1 and put a red line in every session of a
    # repo somebody deliberately chose not to register.
    #
    # Note this is NOT a general relaxation of the [INFO]-silence rule. That rule was justified as
    # "often the business of another machine or user"; this signal is the opposite -- it is about THIS
    # repo and it is actionable HERE. The README's own classification rule points the same way: a
    # category that must not stay out of sight may not be filed as [INFO].
    # Phrased for a reader who has never heard of this workshop (Dave, July 28, 2026: assume a consumer
    # knows nothing about the source repo -- a colleague who merely installed the plugin must be served
    # by it, not put to work for it). The earlier wording said "add connectors/<repo>.json in the
    # workshop", which is homework in a repo that reader may not have, may not have access to, and has
    # no reason to know exists. Who benefits from registration is the plugin's maintainer; who was being
    # instructed was the consumer. So: state that nothing here is broken, and address the action to the
    # maintainer conditionally.
    Write-Host "  [UNREGISTERED] this repo is not in the plugin maintainer's connector register. Nothing here is affected -- the plugin works normally. It only means the maintainer has no view of this repo's plugin version and lens inventory. If you maintain the plugin source, add a connectors/<repo>.json manifest there; if you just use the plugin, no action is needed on your side." -ForegroundColor Yellow
}

# Content drift per unique consumer (agent defs = error, personas = informational).
if (-not $SkipDrift) {
    foreach ($checkout in $checkedConsumers.Keys) {
        if ($checkout -eq $RepoRoot) { continue }
        Write-Host "`n-- drift-check: $($checkedConsumers[$checkout])" -ForegroundColor Cyan
        Set-CheckScope $checkedConsumers[$checkout]
        & powershell -NoProfile -ExecutionPolicy Bypass -File $DriftLint -ConsumerPath $checkout -Quiet |
            Where-Object { $_ -match 'DRIFTED|IDENTICAL|summary|drift' } |
            ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -ne 0) { Write-Failure "agent-def drift found -- see check-consumer-drift." }
    }
    Set-CheckScope
}

Write-CheckSummary
