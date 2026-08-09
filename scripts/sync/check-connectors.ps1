<#
.SYNOPSIS
    Connectors check: verifies whether all connected repos (connectors) are still in sync with
    this repo -- the source of truth.

.DESCRIPTION
    The register lives at family level, next to the plugin folders (deliberately NOT inside them,
    so it does not travel along with a consumer's plugin cache): ONE manifest per connected repo
    (connectors/<repo>.json), containing the extension
    inventory per plugin. Manifests contain only METADATA -- never
    lens content and never absolute machine paths; localCheckout is relative to this repo's root.

    Per connector this script checks:
      1. Checkout present on this machine?          no -> [SKIP] (not an error)
      2. Per plugin: enabled anywhere in the consumer's settings CHAIN? no -> [ERROR]. Read via
         Get-EnabledPlugins, so the verdict names the layer it came from (inbound #294); this line used
         to say '.claude/settings.json', which is the single-file reading that produced that inbound.
      3. Per plugin: all registered extensions present?  one missing -> [ERROR]
         Extensions of that plugin that exist in the consumer but are NOT registered
         -> [INFO] (inbound signal: update the register or bring the change back here), plus a
         non-counting [INVENTORY] line the session hook surfaces when that drifted register is
         the one describing the repo the session is in -- the only case a reader here can act on.
      4. Per plugin: machine record older than source -> [ERROR]; no record/no administration -> [INFO]
         (machine-specific, not a gate breach). The record comes from Get-InstallRecord
         (check-report-lib.ps1) -- the shared reader of ~/.claude/plugins/installed_plugins.json this
         block used to be the sole owner of (inbound #302). When a plugin has no record for a checkout
         while being ENABLED there, that [INFO] additionally states the consequence: a session in that
         checkout loads none of it, and that repo's own hooks cannot say so, because they are in the
         plugin that is not loading.
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

.PARAMETER UserHomeOverride
    (Optional, for tests) Use this dir as the user home when resolving the user layer of a consumer's
    settings chain (~/.claude/settings.json), instead of $env:USERPROFILE. Without it a fixture would
    inherit whatever the machine running the suite has enabled globally, so a "plugin not enabled" case
    would pass here and fail on the next machine for a reason no assertion mentions.

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
    [switch]$SkipVersions,
    [string]$UserHomeOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$DriftLint  = Join-Path $RepoRoot 'scripts\lint\check-consumer-drift.ps1'

$script:errors = 0
$script:infos  = 0

# Write-Ok/Write-Info/Write-Failure + Test-PluginNameSlug: shared with check-roster-sync.ps1 (single
# source, issue #114). This script is workshop-only (not mirrored -- it reads the connectors/
# register that only exists here), so the lib is dot-sourced unconditionally.
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')

# Which plugins this repo publishes, and where each one's folder is. Read once: the register is walked
# per consumer and per plugin, and re-reading the marketplace inside that loop is how two answers to one
# question start appearing in one run.
. (Join-Path $PSScriptRoot '..\lib\plugin-tree-lib.ps1')
$PluginRoots = @(Get-RepoPluginRoots -RepoRoot $RepoRoot)

# Plugin id (before the '@') -> that plugin's folder, or $null when this repo does not publish a plugin
# by that name.
#
# IT ASKS THE MARKETPLACE INSTEAD OF JOINING A PATH. This used to be Join-Path <plugins root> <name>,
# which answers "is there a folder with this name" -- a different question, and one that gives the wrong
# answer in both directions: a folder under plugins/ that is not a published plugin resolved happily
# (agent-shared/ would have), while a plugin whose folder is not named after it, or does not sit exactly
# one level down, resolved to nothing. The slug check stays in front of it as defence in depth: the name
# comes out of a register file, and it must not be able to become a path segment unvalidated even though
# nothing is joined with it here any more.
function Get-PluginDir([string]$PluginId) {
    $name = $PluginId.Split('@')[0]
    if (-not (Test-PluginNameSlug -Name $name)) { return $null }
    $root = Get-PluginRootByName -PluginRoots $PluginRoots -Name $name
    if (-not $root) { return $null }
    if (-not (Test-Path -LiteralPath $root.Root)) { return $null }
    return $root.Root
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
    $connectorsRoot = Join-Path $RepoRoot 'connectors'
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

    # Read the consumer's enable state once, from the whole settings chain rather than settings.json
    # alone (inbound #294 -- Get-EnabledPlugins carries the measurement and the reasoning). This check
    # produced the mirror-image symptom of the roster check's false green: a flat
    # "is NOT (or no longer) enabled" for DaveKJohn/life-hub in the very session that had loaded four of
    # its skills and all three of its hooks, because the enable sat in settings.local.json. Literally
    # true about settings.json, false about the session -- and a gate that cries wolf about a working
    # setup is a gate whose next real finding gets waved away.
    #
    # The user layer legitimately counts here too: it belongs to the machine and the user running this
    # check, which is the same machine and user the consumer checkout is used from.
    $consumerEnabled = Get-EnabledPlugins -RepoRoot $checkout -UserHomeOverride $UserHomeOverride

    # The install administration for this checkout, read once per connector (inbound #302). Deliberately
    # WITHOUT -UserHomeOverride: that parameter is documented as pinning the user layer of the SETTINGS
    # CHAIN, and this is a different file answering a different question -- the version test controls it
    # by redirecting $env:USERPROFILE for the child process, which is where Get-InstallRecord reads it.
    #
    # Behind the -SkipVersions guard, because everything that reads it is: the administration is the
    # authority for check 4 and nothing else here. Reading it anyway would widen what a -SkipVersions run
    # does -- and could newly report an unparseable administration in a run that was explicitly asked not
    # to look at versions at all. Once per connector rather than once per plugin, so a consumer with
    # several plugin blocks still reads the file once.
    $consumerInstalled = $null
    if (-not $SkipVersions) {
        $consumerInstalled = Get-InstallRecord -RepoRoot $checkout
        if ($consumerInstalled.Exists -and -not $consumerInstalled.Readable) {
            Write-Failure "$($consumerInstalled.Path) does not parse as JSON ($($consumerInstalled.Error)) -- no install record could be read for this consumer, so every version verdict below is withheld."
        }
    }

    if (-not $consumerEnabled.AnyFileExists) {
        Write-Failure "no settings file found for '$checkout' (looked for $(($consumerEnabled.Layers | ForEach-Object { $_.Label }) -join ', '))"
    }
    foreach ($badLayer in @($consumerEnabled.Unreadable)) {
        Write-Failure "$badLayer does not parse as JSON in '$checkout' -- its enabledPlugins entries were not read."
    }

    foreach ($p in @($m.plugins)) {
        # The DISPLAY form of this manifest's plugin id (inbound #309), bound once per block for the same
        # reason check-roster-sync binds $plugIdShown: $p.id stays raw because Get-PluginDir derives a path
        # from it and the enable/record lookups key on it, while every printed line uses this. Manifest
        # fields are lower-risk than settings keys -- they live in this repo and pass a PR -- but the
        # guardrail note at the top of this file already says manifest values are never blindly trusted,
        # and 'never blindly trusted' had a hole in it for display.
        $pluginIdShown = Format-SafeToken -Value ([string]$p.id)
        Write-Host "  -- plugin: $pluginIdShown" -ForegroundColor Cyan

        # Narrow the label to this plugin block. A consumer can register SEVERAL plugins, and a shared
        # cause (one outdated install) then produces one finding per plugin -- word-for-word identical
        # once the '-- plugin:' header above is filtered out of the session summary. Verified against
        # this repo's own register: smartwatchbanden has two plugin blocks, both behind, and the hook
        # surfaced two indistinguishable [ERROR] lines. Connector name alone was not enough (inbound
        # #203); the plugin id is what makes each line actionable.
        Set-CheckScope "$connectorLabel / $($p.id)"

        $pluginDir = Get-PluginDir $p.id
        if ($null -eq $pluginDir) {
            Write-Failure "invalid or unknown plugin field '$(Format-SuspectToken -Value ([string]$p.id))' in $($mf.Name) -- plugin block skipped."
            continue
        }

        # 2. Plugin enabled in the consumer? Both verdicts name the LAYER, so an enable arriving from
        # outside .claude/settings.json is diagnosable instead of mysterious -- and so the negative
        # verdict states what it actually checked rather than a single path it happened to look at.
        if ($consumerEnabled.AnyFileExists) {
            if ($consumerEnabled.Ids -contains $p.id) {
                Write-Ok "plugin is enabled in $($consumerEnabled.LayerById[$p.id])"
            } else {
                Write-Failure "plugin '$pluginIdShown' is NOT (or no longer) enabled in $($consumerEnabled.Summary)"
            }
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
        #
        # The record read here is now Get-InstallRecord's (inbound #302). This block used to hold the
        # ONLY reader of installed_plugins.json anywhere in these scripts -- which is why #302's grep for
        # it over the plugin tree found prose only, and concluded no code read it: true of the plugin
        # tree, and this file is workshop-owned. Its matching rules did not change; they moved, so the
        # roster check and the bootstrap can ask the same question rather than each growing a reader of
        # their own. The rules themselves, preserved verbatim in the lib:
        #
        # EVERY matching record, not the first one (#240). The old loop stopped at the first hit -- an
        # arbitrary pick dressed up as a fact. Measured on Dave's machine (2026-07-29): `claude plugin
        # list` showed `specialists` three times for one repo (2.13.1, 2.11.0, 2.9.0), because the
        # administration holds several project records for that checkout, in two path spellings. The
        # [OK]/[ERROR] the session hook prints every single start therefore rested on whichever record
        # happened to come first in the JSON. Same defect family as #227, #235 and the teardown's
        # docstring-VUL-IN: evidence that looks conclusive while being satisfied by something other than
        # what it claims to measure. This one did not lie about a string -- it lied about WHICH of several
        # answers it had found. An honest "I cannot tell" is worth more than a confident wrong number,
        # and unlike the wrong number it is actionable.
        #
        # Read once per connector, outside the plugin loop, and asked per plugin id here.
        if (-not $SkipVersions) {
            $pluginJsonPath = Join-Path $pluginDir '.claude-plugin\plugin.json'
            $sourceVersion = (Get-Content -LiteralPath $pluginJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json).version
            # Readable, not merely present. An administration that exists but does not parse yields an
            # EMPTY record set, and running the branches below on that would report "no machine record for
            # this consumer" -- a statement about absence, drawn from a file that could not be read. That is
            # the exact species of claim inbound #302 is about, so the unreadable case gets no verdict at
            # all here; the [ERROR] at connector level already named the file and said the verdicts are
            # withheld.
            if ($consumerInstalled.Exists -and $consumerInstalled.Readable) {
                $recordMatches = @()
                if ($consumerInstalled.RecordsById.ContainsKey($p.id)) { $recordMatches = @($consumerInstalled.RecordsById[$p.id]) }
                $recordVersions = @($recordMatches | ForEach-Object { $_.Version } | Sort-Object -Unique)
                if ($recordMatches.Count -eq 0) {
                    # Sharpened for the case that actually bites (inbound #302). "No record" was worded
                    # purely as a version check that could not run, which is right when the plugin is not
                    # enabled there either. When it IS enabled, the same fact means something much
                    # louder: a session in that checkout loads none of this plugin, while both this
                    # register and that repo's own settings say it is present. And that repo cannot
                    # report it -- the hook that would is inside the plugin that is not loading. This
                    # check, from the workshop, is the one vantage point that still has a voice.
                    #
                    # [INFO], not [ERROR], and deliberately so: a consumer legitimately used from
                    # another machine has no record here either, so the state is not conclusive. The
                    # honest move is to name both readings and the one command that settles it.
                    if ($consumerEnabled.Ids -contains $p.id) {
                        Write-Info "no machine record for this consumer, while the plugin IS enabled in $($consumerEnabled.LayerById[$p.id]) -- a session in that checkout loads none of this plugin (no skills, no subagents, no hooks). Either the install belongs to another machine, or it was never made for this path (or was taken over -- see inbound #301): 'claude plugin install $pluginIdShown --scope project' from that root settles it. Version check skipped."
                    } else {
                        Write-Info "no machine record for this consumer (the install may run via a different machine)."
                    }
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
            } elseif (-not $consumerInstalled.Exists) {
                Write-Info "no plugin administration found on this machine -- version check skipped."
            }
            # No else: an unreadable administration was already reported as an [ERROR] at connector level,
            # and repeating it per plugin would say the same thing N times (the noise the per-plugin scope
            # label was introduced to make actionable, not to multiply).
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
