<#
.SYNOPSIS
    Regression tests for the roster-sync check (scripts/sync/check-roster-sync.ps1).

.DESCRIPTION
    Dependency-free: no Pester, plain PowerShell. Integration-style -- runs the real script in a CHILD
    PROCESS against throwaway fixtures in the temp dir and asserts on exit-code + output. The agent set
    is made deterministic with a fixture plugin cache passed via -CacheRootOverride, and the consumer
    repo-root via -ConsumerPathOverride.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/roster-sync.tests.ps1

    Pure ASCII (repo convention for .ps1).

    Test-gaps (honest):
      - The dual-context repo-root fallback (git rev-parse when neither -ConsumerPathOverride nor
        CLAUDE_PROJECT_DIR is set) is not exercised here -- the tests always pin the root explicitly.
        The CLAUDE_PROJECT_DIR branch itself is covered structurally by shared-scripts.tests.ps1's
        dual-context invariant.
      - The $env:CLAUDE_PLUGIN_ROOT hook-context branch of Resolve-PluginDir is not covered; in
        practice this script is not a hook, so that env var is normally unset. The cache-resolution
        branch (incl. semantically-highest-version) IS covered.
      - TWO simultaneously-enabled plugins (the cross-plugin orphan aggregation over the shared
        $allBackingIds/$pluginNames) IS covered (scenario 12): 'specialists' + a second fixture
        plugin 'widgets' each ship one agent and one orphan; the test asserts neither plugin's own
        agent is misreported as an orphan by the other plugin's pass, and that BOTH orphans surface
        (not just the first plugin's), proving the aggregation is a union across the whole loop, not
        truncated to the last plugin processed.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\sync\check-roster-sync.ps1'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) 'roster-sync-test-fixture'

$Marketplace = 'davekjohns-workshop'
$PluginName  = 'specialists'
$PluginId    = "$PluginName@$Marketplace"

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red
    }
}

function Assert-Match {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern not found: '$Pattern'" -ForegroundColor Red
    }
}

function Assert-NotMatch {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -notmatch $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern present but should not be: '$Pattern'" -ForegroundColor Red
    }
}

function Invoke-Ps {
    param([string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

# Builds a fixture plugin cache. -VersionAgents: @{ '1.11.0' = @('06-16','06-24') }.
# -VersionPersonas: @{ '1.11.0' = @('01-01') }. -Plugin: which plugin name to build under the cache
# root (default the module-level $PluginName, 'specialists'). -KeepExisting: do NOT wipe the cache
# root first -- needed to build a SECOND plugin into the same cache (scenario 12, two enabled plugins
# sharing one cache root, matching the real $env:USERPROFILE\.claude\plugins\cache layout). Returns
# the cache root.
function New-FixtureCache {
    param([hashtable]$VersionAgents, [hashtable]$VersionPersonas = @{}, [string]$Plugin = $PluginName, [switch]$KeepExisting, [hashtable]$Names = @{})
    $cache = Join-Path $Fixture 'cache'
    if (-not $KeepExisting -and (Test-Path -LiteralPath $cache)) { Remove-Item -Recurse -Force -LiteralPath $cache }
    foreach ($ver in $VersionAgents.Keys) {
        $adir = Join-Path $cache "$Marketplace\$Plugin\$ver\agents"
        New-Item -ItemType Directory -Path $adir -Force | Out-Null
        foreach ($id in $VersionAgents[$ver]) {
            $g = $id.Split('-')[0]; $i = $id.Split('-')[1]
            $nm = if ($Names.ContainsKey($id)) { $Names[$id] } else { 'x' }
            [System.IO.File]::WriteAllText((Join-Path $adir "$id-agent.md"), "---`nname: $nm`nid: $i`ngroup: $g`n---`nfixture")
        }
    }
    foreach ($ver in $VersionPersonas.Keys) {
        $pdir = Join-Path $cache "$Marketplace\$Plugin\$ver\personas"
        New-Item -ItemType Directory -Path $pdir -Force | Out-Null
        foreach ($id in $VersionPersonas[$ver]) {
            $g = $id.Split('-')[0]; $i = $id.Split('-')[1]
            [System.IO.File]::WriteAllText((Join-Path $pdir "$id-persona.md"), "---`nid: $i`ngroup: $g`n---`nfixture")
        }
    }
    return $cache
}

# Builds a fixture consumer repo-root. RosterIds -> written into the roster file; LensIds -> lens files
# on the plugin-path; LegacyLensIds -> lens files on the legacy path; OffPathLensIds -> lens files on a
# NON-canonical family segment, the way a pre-#179 bootstrap wrote them.
function New-FixtureConsumer {
    param(
        [string[]]$RosterIds = @(),
        [string[]]$LensIds = @(),
        [string[]]$LegacyLensIds = @(),
        [string[]]$OffPathLensIds = @(),
        [string]$OffPathFamily = 'davekjohns-workshop',
        [bool]$Enabled = $true,
        [bool]$WriteSettings = $true,
        [string]$RosterFile = 'CLAUDE.md',
        [string]$RepoConfig = '',
        [string]$EnabledPluginId = $PluginId,
        # Scenario 12 (two enabled plugins): extra 'name@marketplace' ids written into
        # enabledPlugins alongside $EnabledPluginId, and a map of pluginName -> ids whose lens files
        # are written under that plugin's OWN .claude/plugins/claude-specialists/<name>/ dir (a
        # second plugin has its own lens namespace, distinct from $PluginName's).
        [string[]]$ExtraEnabledPluginIds = @(),
        [hashtable]$ExtraLensesByPlugin = @{},
        # Per-id override for a plugin-path lens file's content (default 'lens'). Lets a case give a
        # lens a specific header to exercise the stale-header detection (issue #145).
        [hashtable]$LensContent = @{}
    )
    $root = Join-Path $Fixture 'consumer'
    if (Test-Path -LiteralPath $root) { Remove-Item -Recurse -Force -LiteralPath $root }
    New-Item -ItemType Directory -Path (Join-Path $root '.claude') -Force | Out-Null

    if ($WriteSettings) {
        $val = if ($Enabled) { 'true' } else { 'false' }
        $entries = @('"' + $EnabledPluginId + '": ' + $val)
        foreach ($extraId in $ExtraEnabledPluginIds) { $entries += '"' + $extraId + '": true' }
        $settings = '{ "enabledPlugins": { ' + ($entries -join ', ') + ' } }'
        [System.IO.File]::WriteAllText((Join-Path $root '.claude\settings.json'), $settings)
    }

    $lines = @('# Roster', '')
    foreach ($id in $RosterIds) { $lines += "| $id | [$id-extension.md](x) |" }
    [System.IO.File]::WriteAllText((Join-Path $root $RosterFile), ($lines -join "`n"))

    if ($LensIds.Count -gt 0) {
        $pdir = Join-Path $root ".claude\plugins\claude-specialists\$PluginName"
        New-Item -ItemType Directory -Path $pdir -Force | Out-Null
        foreach ($id in $LensIds) {
            $body = if ($LensContent.ContainsKey($id)) { $LensContent[$id] } else { 'lens' }
            [System.IO.File]::WriteAllText((Join-Path $pdir "$id-extension.md"), $body)
        }
    }
    if ($LegacyLensIds.Count -gt 0) {
        $ldir = Join-Path $root '.claude\extensions'
        New-Item -ItemType Directory -Path $ldir -Force | Out-Null
        foreach ($id in $LegacyLensIds) { [System.IO.File]::WriteAllText((Join-Path $ldir "$id-extension.md"), "lens") }
    }
    if ($OffPathLensIds.Count -gt 0) {
        $odir = Join-Path $root ".claude\plugins\$OffPathFamily\$PluginName"
        New-Item -ItemType Directory -Path $odir -Force | Out-Null
        foreach ($id in $OffPathLensIds) { [System.IO.File]::WriteAllText((Join-Path $odir "$id-extension.md"), "lens") }
    }
    foreach ($pn in $ExtraLensesByPlugin.Keys) {
        $edir = Join-Path $root ".claude\plugins\claude-specialists\$pn"
        New-Item -ItemType Directory -Path $edir -Force | Out-Null
        foreach ($id in $ExtraLensesByPlugin[$pn]) { [System.IO.File]::WriteAllText((Join-Path $edir "$id-extension.md"), "lens") }
    }
    if ($RepoConfig) {
        New-Item -ItemType Directory -Path (Join-Path $root 'scripts') -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $root 'scripts\repo-config.ps1'), $RepoConfig)
    }
    return $root
}

try {
    Write-Host "== roster-sync.tests ==" -ForegroundColor Cyan

    # --- 1. Happy path: agents present in roster + lens -> exit 0 --------------------------------
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16', '06-17') }
    $c = New-FixtureConsumer -RosterIds @('06-16', '06-17') -LensIds @('06-16', '06-17')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'happy path: exit-code 0'
    Assert-Match "\[OK\]\s+agent '06-16' present in roster \+ lens" $r.Out 'happy path: 06-16 OK'
    Assert-NotMatch '\[ERROR\]' $r.Out 'happy path: no errors'

    # --- 2. New agent missing from the roster -> [ERROR] + exit 1 naming the id ------------------
    #     06-24 is an agent, but the roster only lists 06-16. Lens for 06-24 IS present, so the only
    #     finding is the missing roster row.
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16', '06-24') }
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @('06-16', '06-24')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 1 $r.Code 'new agent: exit-code 1'
    Assert-Match "\[ERROR\].*'06-24'.*no roster row" $r.Out 'new agent: ERROR names the id + reason'

    # --- 3. Agent missing a lens -> reported (ERROR) ---------------------------------------------
    #     06-16 is in the roster but has no lens anywhere.
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @()
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 1 $r.Code 'missing lens: exit-code 1'
    Assert-Match "\[ERROR\].*'06-16'.*no repo-lens" $r.Out 'missing lens: reported'

    # --- 4. Orphan roster/lens id -> [INFO], exit 0 ----------------------------------------------
    #     06-16 fully satisfied; 09-99 is a roster token + lens file with no backing agent/persona.
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $c = New-FixtureConsumer -RosterIds @('06-16', '09-99') -LensIds @('06-16', '09-99')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'orphan: exit-code 0 (INFO, not blocking)'
    Assert-Match "\[INFO\].*orphan '09-99'" $r.Out 'orphan: INFO names the id'
    Assert-Match '1 info signal' $r.Out 'orphan: counted as info signal'

    # --- 5. Plugin not enabled -> handled, exit 0 ------------------------------------------------
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $c = New-FixtureConsumer -RosterIds @() -Enabled $false
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'plugin disabled: exit-code 0'
    Assert-Match 'no enabled plugins' $r.Out 'plugin disabled: reported'
    Assert-NotMatch '\[ERROR\]' $r.Out 'plugin disabled: no errors'

    # --- 5b. Enabled but not in cache -> INFO, exit 0 (install may be on another machine) --------
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $emptyCache = Join-Path $Fixture 'empty-cache'
    New-Item -ItemType Directory -Path $emptyCache -Force | Out-Null
    $c = New-FixtureConsumer -RosterIds @() -Enabled $true
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $emptyCache)
    Assert-Equal 0 $r.Code 'not in cache: exit-code 0'
    Assert-Match 'not found in the cache' $r.Out 'not in cache: INFO'

    # --- 6. Highest-version cache resolution -----------------------------------------------------
    #     1.9.0 ships only 06-16; 1.10.0 adds 06-24. A string-sort would wrongly pick 1.9.0 (misses
    #     06-24). With [version]-sort the script picks 1.10.0, so 06-24 (absent from roster/lens) is
    #     flagged -> exit 1. That exit 1 + the 06-24 ERROR proves 1.10.0 was chosen.
    $cache = New-FixtureCache -VersionAgents @{ '1.9.0' = @('06-16'); '1.10.0' = @('06-16', '06-24') }
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @('06-16')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 1 $r.Code 'highest version: exit-code 1 (1.10.0 chosen, 06-24 seen)'
    Assert-Match "\[ERROR\].*'06-24'" $r.Out 'highest version: 06-24 (only in 1.10.0) flagged'
    Assert-Match 'cache 1\.10\.0' $r.Out 'highest version: header shows 1.10.0'

    # --- 7. Persona backing: a persona-only id is NOT drift and NOT an orphan --------------------
    #     01-01 ships as a persona (no agent). It has a roster row + lens. It must produce no ERROR
    #     (personas are not agents) and no orphan INFO (personas count as backing).
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') } -VersionPersonas @{ '1.11.0' = @('01-01') }
    $c = New-FixtureConsumer -RosterIds @('06-16', '01-01') -LensIds @('06-16', '01-01')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'persona backing: exit-code 0'
    Assert-NotMatch "orphan '01-01'" $r.Out 'persona backing: 01-01 not an orphan'
    Assert-NotMatch "'01-01'.*no roster row" $r.Out 'persona backing: 01-01 not flagged as missing agent'

    # --- 8. Get-RosterPath override: roster lives in ROSTER.md -----------------------------------
    #     repo-config returns 'ROSTER.md'; the roster is written there, CLAUDE.md is empty. If the
    #     default were used, 06-16 would be "missing from roster" (exit 1). Exit 0 proves ROSTER.md
    #     was read via Get-RosterPath.
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $repoConfig = "function Get-RosterPath { return 'ROSTER.md' }"
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @('06-16') -RosterFile 'ROSTER.md' -RepoConfig $repoConfig
    # Also drop an empty CLAUDE.md to prove the default path is NOT the one being consulted.
    [System.IO.File]::WriteAllText((Join-Path $c 'CLAUDE.md'), "# empty`n")
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'roster override: exit-code 0 (ROSTER.md consulted)'
    Assert-Match "\[OK\]\s+agent '06-16' present in roster" $r.Out 'roster override: 06-16 found in ROSTER.md'

    # --- 9. Legacy lens path (.claude/extensions) is honored -------------------------------------
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @() -LegacyLensIds @('06-16')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'legacy lens: exit-code 0 (lens found on legacy path)'
    Assert-NotMatch '\[ERROR\]' $r.Out 'legacy lens: no errors'

    # --- 9b. Non-canonical family segment is honored, and flagged softly (issue #179) --------------
    #     A pre-#179 bootstrap derived the family from the install path and wrote the lenses under the
    #     MARKETPLACE name. Those lenses exist and work, so they must NOT be reported as missing (the
    #     misleading double-ERROR from the issue: 12 present lenses counted as 24 errors). The check
    #     finds them and adds ONE soft line per directory pointing at the misalignment.
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16', '06-17') }
    $c = New-FixtureConsumer -RosterIds @('06-16', '06-17') -LensIds @() -OffPathLensIds @('06-16', '06-17')
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'off-path lens: exit-code 0 (lens found under the marketplace family)'
    Assert-NotMatch '\[ERROR\]' $r.Out 'off-path lens: no false missing-lens errors'
    Assert-Match "\[OK\]\s+agent '06-16' present in roster \+ lens" $r.Out 'off-path lens: counted as present'
    Assert-Match '\[INFO\].*2 lens file\(s\).*davekjohns-workshop.*canonical' $r.Out 'off-path lens: one INFO per directory naming the misalignment'
    Assert-Equal 1 ([regex]::Matches($r.Out, 'instead of the canonical').Count) 'off-path lens: reported once per directory, not once per lens'

    # --- 10. Ignore-list: an enabled agent deliberately kept out of the roster/lenses is skipped ---
    #     04-11 is an agent with no roster row and no lens, but repo-config's Get-RosterIgnoredIds
    #     lists it -> no ERROR (exit 0), reported as a deliberate skip. Without the ignore-list this
    #     would be a double ERROR (missing roster + missing lens).
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16', '04-11') }
    $repoConfig = "function Get-RosterIgnoredIds { return @('04-11') }"
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @('06-16') -RepoConfig $repoConfig
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'ignore-list: exit-code 0 (ignored agent not flagged)'
    Assert-Match "\[INFO\].*'04-11'.*deliberately kept out" $r.Out 'ignore-list: 04-11 reported as skipped'
    Assert-NotMatch "'04-11'.*no roster row" $r.Out 'ignore-list: 04-11 not an ERROR'

    # --- Hook (roster-sessioncheck.ps1): soft, surfaces only [ERROR], always exit 0 ---------------
    $Hook = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\hooks\roster-sessioncheck.ps1'
    # A stub "check" script with fixed output + exit code, so the hook is tested in isolation.
    function New-StubCheck {
        param([string]$Name, [string[]]$OutputLines, [int]$ExitCode)
        $p = Join-Path $Fixture "$Name.ps1"
        $body = (($OutputLines | ForEach-Object { 'Write-Host "' + $_ + '"' }) -join "`r`n") + "`r`nexit $ExitCode`r`n"
        [System.IO.File]::WriteAllText($p, $body)
        return $p
    }
    function Invoke-Hook { param([string[]]$A) $o = & powershell -NoProfile -ExecutionPolicy Bypass -File $Hook @A; return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($o -join "`n") } }

    # H1. Check script not found -> soft notice, exit 0.
    $r = Invoke-Hook @('-CheckScriptOverride', (Join-Path $Fixture 'does-not-exist.ps1'))
    Assert-Equal 0 $r.Code 'hook: exit 0 when check script missing'
    Assert-Match 'check skipped' $r.Out 'hook: missing-script notice'

    # H2. Stub emits an [ERROR] (roster drift) -> surfaced, exit 0 (never blocks the session).
    $stub = New-StubCheck -Name 'stub-drift' -ExitCode 1 -OutputLines @("  [ERROR]  agent '06-24' has no roster row", '  [INFO]  orphan 09-99')
    $r = Invoke-Hook @('-CheckScriptOverride', $stub)
    Assert-Equal 0 $r.Code 'hook: exit 0 even on drift (never blocks)'
    Assert-Match 'roster drift found' $r.Out 'hook: drift summary shown'
    Assert-Match "06-24" $r.Out 'hook: the ERROR line is surfaced'
    Assert-NotMatch 'orphan 09-99' $r.Out 'hook: [INFO] stays silent at session start'

    # H3. Stub emits only [INFO]/[OK] -> silent in-sync message, exit 0.
    $stub = New-StubCheck -Name 'stub-clean' -ExitCode 0 -OutputLines @('  [OK]    all present', '  [INFO]  orphan 09-99')
    $r = Invoke-Hook @('-CheckScriptOverride', $stub)
    Assert-Equal 0 $r.Code 'hook: exit 0 when clean'
    Assert-Match 'in sync' $r.Out 'hook: in-sync message'
    Assert-NotMatch 'roster drift found' $r.Out 'hook: no drift summary when clean'

    # H4. Stub crashes (non-zero exit, NO [ERROR] line) -> not misreported as "in sync"; a distinct
    #     "could not complete" notice, still exit 0 (finding Victor: a top-level crash in the check
    #     must not read as all-good).
    $stub = New-StubCheck -Name 'stub-crash' -ExitCode 1 -OutputLines @('some unexpected failure')
    $r = Invoke-Hook @('-CheckScriptOverride', $stub)
    Assert-Equal 0 $r.Code 'hook: exit 0 even when the check crashes'
    Assert-Match 'could not complete' $r.Out 'hook: crash reported as could-not-complete'
    Assert-NotMatch 'in sync' $r.Out 'hook: crash NOT misreported as in sync'

    # --- 11. Guardrail: a malformed plugin id in settings.json is rejected before filesystem access ---
    #     An uppercase/underscore plugin name fails the slug regex; the script must ERROR ("invalid
    #     plugin id") and skip it rather than build a path from it. Security-relevant branch (Sean/Victor).
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @('06-16') -EnabledPluginId 'Bad_Name@davekjohns-workshop'
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 1 $r.Code 'guardrail: exit-code 1 on malformed plugin id'
    Assert-Match "\[ERROR\].*invalid plugin id" $r.Out 'guardrail: malformed plugin id rejected'

    # --- 12. Cross-plugin orphan aggregation: TWO enabled plugins, each with its own orphan --------
    #     Documented test-gap (see file header). 'specialists' ships agent 06-16, 'widgets' ships
    #     agent 07-07; both are satisfied (roster + own lens dir). 09-90 (lens under specialists'
    #     dir) and 09-91 (lens under widgets' dir) are backed by NEITHER plugin -- true orphans.
    #     Assertions prove: (1) 06-16/07-07 are NOT misreported as orphans by the OTHER plugin's
    #     pass (the union $allBackingIds must survive across both loop iterations, not just the
    #     last one), and (2) BOTH orphans surface -- not just the first plugin's -- via the
    #     '2 info signal(s)' summary count.
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') } -Plugin 'specialists'
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('07-07') } -Plugin 'widgets' -KeepExisting
    $c = New-FixtureConsumer -RosterIds @('06-16', '07-07', '09-90', '09-91') -LensIds @('06-16', '09-90') `
        -ExtraEnabledPluginIds @('widgets@davekjohns-workshop') `
        -ExtraLensesByPlugin @{ 'widgets' = @('07-07', '09-91') }
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'two-plugin: exit-code 0 (both agents satisfied, orphans are INFO only)'
    Assert-Match "\[OK\]\s+agent '06-16' present in roster \+ lens" $r.Out 'two-plugin: specialists agent 06-16 OK'
    Assert-Match "\[OK\]\s+agent '07-07' present in roster \+ lens" $r.Out 'two-plugin: widgets agent 07-07 OK'
    Assert-Match "\[INFO\].*orphan '09-90'" $r.Out 'two-plugin: specialists orphan 09-90 reported'
    Assert-Match "\[INFO\].*orphan '09-91'" $r.Out 'two-plugin: widgets orphan 09-91 reported'
    Assert-NotMatch "orphan '06-16'" $r.Out 'two-plugin: 06-16 (backed by specialists) not an orphan'
    Assert-NotMatch "orphan '07-07'" $r.Out 'two-plugin: 07-07 (backed by widgets) not an orphan'
    Assert-Match '2 info signal' $r.Out 'two-plugin: BOTH orphans counted (not just the first)'

    # --- 13. Stale lens header after a rename -> [INFO], exit 0 (issue #145) -----------------------
    #     All three agents are present in roster + lens (no missing-lens/roster drift). What differs is
    #     the LENS HEADER:
    #       06-16: agent now 'sebastian', header still "# Sean <midDot> repo-lens"  -> stale  -> INFO.
    #       06-17: agent 'edith', header "# Edith <midDot> repo-lens"               -> matches -> no INFO.
    #       06-19: agent 'edith', hand-customized "# Whoever - Copy Editor" (no "<midDot> repo-lens"
    #              tail)                                                            -> not scaffold shape -> no INFO.
    #     Proves: detection fires on a drifted scaffold header, is silent when the name matches, and
    #     never touches a hand-customized header. INFO -> exit 0 (never blocks the session).
    $midDot = [char]0x00B7
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16', '06-17', '06-19') } `
        -Names @{ '06-16' = 'sebastian'; '06-17' = 'edith'; '06-19' = 'edith' }
    $stale16 = "---`nid: 16`ngroup: 06`n---`n`n# Sean $midDot repo-lens`n`nbody"
    $fresh17 = "---`nid: 17`ngroup: 06`n---`n`n# Edith $midDot repo-lens`n`nbody"
    $hand19  = "---`nid: 19`ngroup: 06`n---`n`n# Whoever - Copy Editor`n`nbody"
    $c = New-FixtureConsumer -RosterIds @('06-16', '06-17', '06-19') -LensIds @('06-16', '06-17', '06-19') `
        -LensContent @{ '06-16' = $stale16; '06-17' = $fresh17; '06-19' = $hand19 }
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'stale header: exit-code 0 (INFO, not blocking)'
    Assert-Match "\[INFO\].*lens '06-16'.*header still names 'Sean'.*is now 'Sebastian'" $r.Out 'stale header: 06-16 drift reported'
    Assert-NotMatch "lens '06-17'.*header still names" $r.Out 'stale header: 06-17 (name matches) not flagged'
    Assert-NotMatch "lens '06-19'.*header still names" $r.Out 'stale header: 06-19 (hand-customized header) not flagged'

    # --- 14. Strict-mode crash guard: consumer's repo-config.ps1 defines Get-RosterPath /
    #     Get-RosterIgnoredIds fine but ALSO carries harmless pre-strict-mode loose top-level code
    #     (a bare `if ($LegacyDebugFlag) {...}` referencing an unset variable). Under the OLD
    #     dot-source-in-the-strict-scope behavior this threw under Set-StrictMode + EAP=Stop and
    #     TERMINATED the whole check (the roster-sessioncheck hook then reported "could not
    #     complete" every session start). Sibling of the check-script-contract.ps1 fix (PR #148).
    #     DO NOT DELETE -- this is the regression guard for that strict-mode dot-source crash.
    #     Proves: (1) the check completes normally (exit 0, no unhandled-throw crash), and
    #     (2) Get-RosterPath is still honored (roster read from ROSTER.md, not the empty default).
    $cache = New-FixtureCache -VersionAgents @{ '1.11.0' = @('06-16') }
    $repoConfig = "if (`$LegacyDebugFlag) { Write-Host 'legacy' }`nfunction Get-RosterPath { return 'ROSTER.md' }`nfunction Get-RosterIgnoredIds { return @() }"
    $c = New-FixtureConsumer -RosterIds @('06-16') -LensIds @('06-16') -RosterFile 'ROSTER.md' -RepoConfig $repoConfig
    # Empty default-path CLAUDE.md, same trick as scenario 8: proves ROSTER.md (not the default) was read.
    [System.IO.File]::WriteAllText((Join-Path $c 'CLAUDE.md'), "# empty`n")
    $r = Invoke-Ps @('-ConsumerPathOverride', $c, '-CacheRootOverride', $cache)
    Assert-Equal 0 $r.Code 'strict-mode crash guard: exit-code 0 (no crash from loose top-level code)'
    Assert-Match "\[OK\]\s+agent '06-16' present in roster" $r.Out 'strict-mode crash guard: Get-RosterPath honored (ROSTER.md read)'
    Assert-NotMatch '\[ERROR\]' $r.Out 'strict-mode crash guard: no false ERROR'
    Assert-NotMatch 'cannot be retrieved|has not been set|Exception' $r.Out 'strict-mode crash guard: no raw strict-mode exception surfaced'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
}

Write-Host "`nResult: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
