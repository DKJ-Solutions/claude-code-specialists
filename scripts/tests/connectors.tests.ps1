<#
.SYNOPSIS
    Regression tests for the connectors check (scripts/sync/check-connectors.ps1) and the
    SessionStart hook (connector-sessioncheck.ps1).

.DESCRIPTION
    Dependency-free: no Pester, only PowerShell. Integration style -- runs the real scripts
    in a CHILD PROCESS against throwaway fixtures in the temp folder and asserts on exit code + output.
    Register checks run with -SkipDrift and -SkipVersions unless a test specifically covers that
    code path (the drift check has its own suite; no plugin administration exists on CI).

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/connectors.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\sync\check-connectors.ps1'
$Hook     = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\hooks\connector-sessioncheck.ps1'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) 'connectors-test-fixture'

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
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern found that should not be there: '$Pattern'" -ForegroundColor Red
    }
}

function Invoke-Ps {
    param([string]$Path, [string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

# Builds a fixture consumer with settings.json + given extensions. -Layout chooses where the
# lenses live: 'legacy' (.claude/extensions/) or 'plugins'
# (.claude/plugins/claude-specialists/specialists/, since life-hub parity).
function New-FixtureConsumer {
    param([string[]]$ExtensionIds, [bool]$PluginEnabled = $true, [string]$Layout = 'legacy')
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    $extDir = if ($Layout -eq 'plugins') {
        Join-Path $Fixture '.claude\plugins\claude-specialists\specialists'
    } else {
        Join-Path $Fixture '.claude\extensions'
    }
    New-Item -ItemType Directory -Path $extDir -Force | Out-Null
    $enabled = if ($PluginEnabled) { '{ "specialists@davekjohns-workshop": true }' } else { '{ }' }
    $settings = '{ "enabledPlugins": ' + $enabled + ' }'
    [System.IO.File]::WriteAllText((Join-Path $Fixture '.claude\settings.json'), $settings)
    foreach ($id in $ExtensionIds) {
        $p = Join-Path $extDir "$id-extension.md"
        [System.IO.File]::WriteAllText($p, "---`nid: $($id.Split('-')[1])`ngroup: $($id.Split('-')[0])`n---`nfixture")
    }
}

# Writes a fixture manifest (per-repo schema) and returns its path.
function New-FixtureManifest {
    param(
        [string[]]$Extensions,
        [string]$LocalCheckout = 'nonexistent-fixture-path',
        [string]$Plugin = 'specialists@davekjohns-workshop'
    )
    $mfPath = Join-Path $Fixture 'manifest.json'
    $obj = [ordered]@{
        repo          = 'fixture/consumer'
        visibility    = 'private'
        localCheckout = $LocalCheckout
        plugins       = @(
            [ordered]@{
                id         = $Plugin
                extensions = $Extensions
            }
        )
        notes         = ''
    }
    [System.IO.File]::WriteAllText($mfPath, ($obj | ConvertTo-Json -Depth 5))
    return $mfPath
}

# Builds a stub workshop (for the hook tests): marker + a fake check script with fixed output.
function New-StubWorkshop {
    param([string]$Name, [string[]]$OutputLines, [int]$ExitCode, [bool]$ValidMarker = $true)
    $root = Join-Path $Fixture $Name
    New-Item -ItemType Directory -Path (Join-Path $root 'scripts\sync') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root '.claude-plugin') -Force | Out-Null
    $markerName = if ($ValidMarker) { 'davekjohns-workshop' } else { 'fake-marketplace' }
    [System.IO.File]::WriteAllText((Join-Path $root '.claude-plugin\marketplace.json'), ('{ "name": "' + $markerName + '" }'))
    $body = (($OutputLines | ForEach-Object { 'Write-Host "' + $_ + '"' }) -join "`r`n") + "`r`nexit $ExitCode`r`n"
    [System.IO.File]::WriteAllText((Join-Path $root 'scripts\sync\check-connectors.ps1'), $body)
    return $root
}

try {
    Write-Host "== connectors.tests ==" -ForegroundColor Cyan
    $base = @('-SkipDrift', '-SkipVersions')

    # --- 1. Happy path: everything present and enabled -> exit 0 -------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16', '06-17')
    $mf = New-FixtureManifest -Extensions @('06-16', '06-17')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 0 $r.Code 'happy path: exit code 0'
    Assert-Match '\[OK\]\s+plugin is enabled' $r.Out 'happy path: enabled check OK'
    Assert-Match 'all 2 registered extensions present' $r.Out 'happy path: extensions OK'
    Assert-NotMatch 'manifest synced at' $r.Out 'happy path: no more manifest-version INFO (register slimming)'

    # --- 1b. New layout: lenses on the plugin path -> same happy path -----------------------
    New-FixtureConsumer -ExtensionIds @('06-16', '06-17') -Layout 'plugins'
    $mf = New-FixtureManifest -Extensions @('06-16', '06-17')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 0 $r.Code 'plugin path: exit code 0'
    Assert-Match 'all 2 registered extensions present' $r.Out 'plugin path: extensions OK'

    # --- 2. Registered extension is missing -> exit 1 ----------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16')
    $mf = New-FixtureManifest -Extensions @('06-16', '06-19')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 1 $r.Code 'missing extension: exit code 1'
    Assert-Match '\[ERROR\].*06-19' $r.Out 'missing extension: ERROR names the id'
    # inbound #203: the finding carries the connector it is about. The session hook filters this output
    # down to the signal lines and drops the '== connector: <repo>' headers, so two consumers on the
    # same outdated plugin version used to produce two identical, unattributable [ERROR] lines. This is
    # the end-to-end proof that Set-CheckScope reaches a real Write-Failure line.
    # The label narrows to '<repo> / <plugin-id>' inside a plugin block: a consumer can register several
    # plugins, and one shared cause (a single outdated install) then yields one finding per plugin --
    # identical to the character once the '-- plugin:' header is filtered out. Found live in this repo's
    # own register while verifying the connector-name fix, so the plugin id is part of the fix, not a
    # nice-to-have.
    Assert-Match '\[ERROR\]\s+fixture/consumer / specialists@davekjohns-workshop:' $r.Out 'missing extension: the ERROR line names the connector AND the plugin block it belongs to'

    # --- 3. Plugin not enabled -> exit 1 --------------------------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16') -PluginEnabled $false
    $mf = New-FixtureManifest -Extensions @('06-16')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 1 $r.Code 'plugin disabled: exit code 1'
    Assert-Match '\[ERROR\].*is NOT' $r.Out 'plugin disabled: ERROR message'

    # --- 4. Checkout not present -> SKIP, exit 0 -----------------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16')
    $mf = New-FixtureManifest -Extensions @('06-16') -LocalCheckout 'nonexistent-fixture-path'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf))
    Assert-Equal 0 $r.Code 'missing checkout: exit code 0'
    Assert-Match '\[SKIP\]' $r.Out 'missing checkout: SKIP message'

    # --- 5. Unregistered extension of this plugin -> INFO, exit 0 ------------------------
    New-FixtureConsumer -ExtensionIds @('06-16', '06-23')
    $mf = New-FixtureManifest -Extensions @('06-16')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 0 $r.Code 'unregistered: exit code 0 (INFO, not an error)'
    Assert-Match "\[INFO\].*'06-23'" $r.Out 'unregistered: INFO names the id (first layer)'

    # --- 5b. Same INFO signal from the plugin path --------------------------------------------
    New-FixtureConsumer -ExtensionIds @('06-16', '06-23') -Layout 'plugins'
    $mf = New-FixtureManifest -Extensions @('06-16')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 0 $r.Code 'unregistered on plugin path: exit code 0'
    Assert-Match "\[INFO\].*'06-23'" $r.Out 'unregistered on plugin path: INFO names the id'

    # --- 5d. Inventory drift in the session's OWN register -> non-counting [INVENTORY] --------------
    #     Found 2026-07-29: a deliberate run turned up eleven of these at once, six in the workshop's
    #     own entry (the lenses landed with PR #212, the inventory was never updated alongside). The
    #     finding is an [INFO], the hook shows only [ERROR], so nothing had surfaced it. -OnlyConsumer
    #     marks the fixture as the repo this run is "in", which is the case a reader can act on.
    New-FixtureConsumer -ExtensionIds @('06-16', '06-23')
    $mf = New-FixtureManifest -Extensions @('06-16')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture, '-OnlyConsumer', $Fixture))
    Assert-Match '\[INVENTORY\]' $r.Out 'own inventory drift: a non-counting [INVENTORY] marker is emitted for the hook'
    Assert-Match "\[INVENTORY\].*06-23" $r.Out 'own inventory drift: the marker names the missing id'
    Assert-Match "\[INFO\].*'06-23'" $r.Out 'own inventory drift: the [INFO] stays for the count and the deliberate run'
    Assert-Match '1 info signal' $r.Out 'own inventory drift: [INVENTORY] is non-counting (still exactly 1 info signal)'
    Assert-Equal 0 $r.Code 'own inventory drift: exit 0 -- a behind-reality register is not a failure of the plugin install'
    # Same audience rule as [UNREGISTERED]: say plainly that nothing is broken, so the line reads as
    # bookkeeping rather than as a fault in the reader's repo.
    Assert-Match 'Nothing is broken' $r.Out 'own inventory drift: the message states the repo is not broken'

    # --- 5e. The same drift in ANOTHER repo's register stays silent --------------------------------
    #     The scoping that keeps this from reintroducing the other-machine noise the [INFO]-silence
    #     rule removed (Dave, July 20, 2026). Identical fixture to 5d, minus -OnlyConsumer: the
    #     checkout is then no longer the repo the run is in, so the [INFO] must still appear while the
    #     [INVENTORY] marker must not. Without this test the feature would look correct in 5d and
    #     quietly surface every consumer's bookkeeping at every session start.
    New-FixtureConsumer -ExtensionIds @('06-16', '06-23')
    $mf = New-FixtureManifest -Extensions @('06-16')
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Match "\[INFO\].*'06-23'" $r.Out "another repo's inventory drift: the [INFO] is still reported on a deliberate run"
    Assert-NotMatch '\[INVENTORY\]' $r.Out "another repo's inventory drift: NO [INVENTORY] marker -- it would be another machine's bookkeeping"

    # --- 5c. -OnlyConsumer without a manifest in the register -> INFO, exit 0 -----------------------
    #     A fresh/unregistered consumer (as the SessionStart hook passes via -OnlyConsumer) should
    #     see an informational "not registered" signal -- NOT the reassuring "in sync" branch. The
    #     manifest checkout does not exist, so no manifest matches this consumer -> matched=0
    #     (regression: this used to be a bare Write-Host that did not count as an info signal,
    #     causing the hook to show "all connectors in sync").
    New-FixtureConsumer -ExtensionIds @('06-16')
    $mf = New-FixtureManifest -Extensions @('06-16') -LocalCheckout 'nonexistent-fixture-path'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-OnlyConsumer', $Fixture))
    Assert-Equal 0 $r.Code 'unregistered consumer: exit code 0 (INFO, no block)'
    Assert-Match '\[INFO\].*not registered' $r.Out 'unregistered consumer: not-registered signal'
    Assert-Match '1 info signal' $r.Out 'unregistered consumer: counts as an info signal'
    # This notice is about the RUN, not about any single connector, so it must not inherit the label of
    # whichever manifest the loop walked last (inbound #203 -- the reason the label is cleared after the
    # loop rather than set once). 'fixture/consumer' is exactly the label that would leak in here.
    Assert-NotMatch '\[INFO\]\s+fixture/consumer:.*not registered' $r.Out 'unregistered consumer: the run-level notice is NOT attributed to the last connector walked'
    # Gap found 2026-07-28: the [INFO] above is suppressed by the session hook, so a brand-new consumer
    # was told "no errors" -- a positive all-clear for a repo the workshop cannot see at all. The
    # non-counting [UNREGISTERED] marker is what reaches the session; the [INFO] stays for the count and
    # the deliberate run. Both must be present, and the marker must not inflate the tally.
    Assert-Match '\[UNREGISTERED\]' $r.Out 'unregistered consumer: a non-counting [UNREGISTERED] marker is emitted for the hook'
    # The message has to serve a reader who knows nothing about the plugin's source repo (Dave, July 28,
    # 2026). Two halves: say nothing here is broken, and address the fix to the maintainer rather than
    # handing homework to whoever merely installed the plugin.
    Assert-Match 'Nothing here is affected' $r.Out 'unregistered consumer: the message states the consumer is not broken'
    Assert-Match 'no action is needed on your side' $r.Out 'unregistered consumer: a plain user is told explicitly to do nothing'
    Assert-NotMatch 'in the workshop' $r.Out 'unregistered consumer: no instruction to go work in a repo the reader may not have'
    Assert-Match '1 info signal' $r.Out 'unregistered consumer: [UNREGISTERED] is non-counting (still exactly 1 info signal)'
    Assert-Equal 0 $r.Code 'unregistered consumer: still exit 0 -- not being registered is not a failure of the plugin install'

    # --- 6. Real manifests of this repo: the self-manifest always checks ----------------------
    $selfManifest = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\connectors\davekjohns-workshop.json'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $selfManifest))
    Assert-Equal 0 $r.Code 'self-manifest (workshop consumes itself): exit code 0'

    # --- 7. Guardrails (Sean's advice): manifest fields are not blindly trusted -----------------
    # 7a. Absolute localCheckout path -> rejected, exit 1.
    New-FixtureConsumer -ExtensionIds @('06-16')
    $mf = New-FixtureManifest -Extensions @('06-16') -LocalCheckout 'C:\Windows'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf))
    Assert-Equal 1 $r.Code 'absolute path: exit code 1'
    Assert-Match '\[ERROR\].*rejected' $r.Out 'absolute path: rejected message'

    # 7b. Path traversal outside the scope root -> rejected, exit 1. '..\..\..' resolved from
    #     the repo root always ends up above the scope root (= two levels above the repo root).
    $mf = New-FixtureManifest -Extensions @('06-16') -LocalCheckout '..\..\..'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf))
    Assert-Equal 1 $r.Code 'path traversal: exit code 1'
    Assert-Match '\[ERROR\].*outside the allowed scope' $r.Out 'path traversal: scope message'

    # 7c. Plugin field with path characters -> rejected, exit 1.
    $mf = New-FixtureManifest -Extensions @('06-16') -Plugin '..\..\evil@davekjohns-workshop'
    $r = Invoke-Ps $Script ($base + @('-Manifest', $mf, '-ConsumerPathOverride', $Fixture))
    Assert-Equal 1 $r.Code 'invalid plugin field: exit code 1'
    Assert-Match '\[ERROR\].*plugin field' $r.Out 'invalid plugin field: ERROR message'

    # --- 8. Machine-record check (without -SkipVersions; Victor's finding) ---------------------------
    # The administration is read via $env:USERPROFILE; the child process inherits the env var, so
    # we point it at the fixture temporarily. -SkipDrift stays on (own suite).
    function Set-FixtureAdmin([string]$RecordsJson) {
        $dir = Join-Path $Fixture '.claude\plugins'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $dir 'installed_plugins.json'), $RecordsJson)
    }
    $oldProfile = $env:USERPROFILE
    try {
        # 8a. Stale record (projectPath does not exist) -> no crash, INFO, exit 0.
        New-FixtureConsumer -ExtensionIds @('06-16')
        $mf = New-FixtureManifest -Extensions @('06-16')
        Set-FixtureAdmin '{ "version": 2, "plugins": { "specialists@davekjohns-workshop": [ { "scope": "project", "projectPath": "C:\\does-not-exist-connectors-fixture", "installPath": "x", "version": "0.0.1" } ] } }'
        $env:USERPROFILE = $Fixture
        $r = Invoke-Ps $Script @('-SkipDrift', '-Manifest', $mf, '-ConsumerPathOverride', $Fixture)
        Assert-Equal 0 $r.Code 'stale record: exit code 0 (no crash)'
        Assert-Match '\[INFO\].*no machine record' $r.Out 'stale record: INFO message'

        # 8b. Record points to the fixture but with an older version than the source -> ERROR, exit 1.
        $fixtureEscaped = ($Fixture -replace '\\', '\\')
        Set-FixtureAdmin ('{ "version": 2, "plugins": { "specialists@davekjohns-workshop": [ { "scope": "project", "projectPath": "' + $fixtureEscaped + '", "installPath": "x", "version": "0.0.1" } ] } }')
        $r = Invoke-Ps $Script @('-SkipDrift', '-Manifest', $mf, '-ConsumerPathOverride', $Fixture)
        Assert-Equal 1 $r.Code 'outdated record: exit code 1'
        Assert-Match '\[ERROR\].*machine record is on v0\.0\.1' $r.Out 'outdated record: ERROR message'

        # 8c. SEVERAL records for one checkout, at DIFFERENT versions -> say so, do not pick one (#240).
        #     The old loop took the first match and stopped, so the [OK]/[ERROR] the session hook shows
        #     every start depended on JSON ordering. Measured on Dave's machine: three registered
        #     versions for one repo. An honest "cannot determine" is the only defensible output, and it
        #     must NOT be an INFO -- while the records disagree, every version claim about this consumer
        #     is unreliable.
        Set-FixtureAdmin ('{ "version": 2, "plugins": { "specialists@davekjohns-workshop": [ ' +
            '{ "scope": "project", "projectPath": "' + $fixtureEscaped + '", "installPath": "x", "version": "0.0.1" }, ' +
            '{ "scope": "project", "projectPath": "' + $fixtureEscaped + '", "installPath": "x", "version": "0.0.2" }, ' +
            '{ "scope": "project", "projectPath": "' + $fixtureEscaped + '", "installPath": "x", "version": "0.0.3" } ] } }')
        $r = Invoke-Ps $Script @('-SkipDrift', '-Manifest', $mf, '-ConsumerPathOverride', $Fixture)
        Assert-Equal 1 $r.Code 'disagreeing records: exit code 1'
        Assert-Match '\[ERROR\].*3 machine records for this consumer disagree' $r.Out 'disagreeing records: reports the count instead of a version'
        Assert-Match 'v0\.0\.1, v0\.0\.2, v0\.0\.3' $r.Out 'disagreeing records: names every version it found'
        Assert-Match 'cannot determine' $r.Out 'disagreeing records: says outright that it cannot tell'

        # 8d. Several records, SAME version, different path spellings -> agreement, not a disagreement.
        #     Two spellings of one directory are not two answers: on Windows the trailing separator and
        #     the casing are noise, and reporting them as a conflict would trade a confident wrong
        #     number for a confident false alarm.
        $fixtureLowerEscaped = ($Fixture.ToLowerInvariant() -replace '\\', '\\')
        Set-FixtureAdmin ('{ "version": 2, "plugins": { "specialists@davekjohns-workshop": [ ' +
            '{ "scope": "project", "projectPath": "' + $fixtureEscaped + '\\", "installPath": "x", "version": "0.0.1" }, ' +
            '{ "scope": "project", "projectPath": "' + $fixtureLowerEscaped + '", "installPath": "x", "version": "0.0.1" } ] } }')
        $r = Invoke-Ps $Script @('-SkipDrift', '-Manifest', $mf, '-ConsumerPathOverride', $Fixture)
        Assert-Match '\[ERROR\].*machine record is on v0\.0\.1' $r.Out 'same version, two spellings: still the plain version verdict'
        Assert-NotMatch 'disagree' $r.Out 'same version, two spellings: NOT reported as a disagreement'
    } finally {
        $env:USERPROFILE = $oldProfile
    }

    # --- 9. SessionStart hook (connector-sessioncheck.ps1) ---------------------------------------
    # 9a. No workshop checkout findable -> soft message, exit 0 (never block a session).
    New-FixtureConsumer -ExtensionIds @('06-16')
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', (Join-Path $Fixture 'does-not-exist'))
    Assert-Equal 0 $r.Code 'hook without a workshop: exit code 0'
    Assert-Match 'check skipped' $r.Out 'hook without a workshop: skipped message'

    # 9b. With the real workshop: integration smoke. Which branch (in-sync or signals) fires depends
    #     on the repo's current register state (e.g. manifests not yet updated after a release
    #     bump) -- that is deliberately not asserted here; the branches themselves are
    #     deterministically covered by the stub tests 9c and 9d (a lesson from CI run PR #54).
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $RepoRoot, '-SkipDrift', '-SkipVersions')
    Assert-Equal 0 $r.Code 'hook with a workshop: exit code 0'
    Assert-Match 'connector-sessioncheck:' $r.Out 'hook with a workshop: session-check output'

    # 9c. Stub workshop with clean output including boilerplate drifted lines (Victor's finding):
    #     the bare summary lines must NOT count as a signal.
    $stub = New-StubWorkshop -Name 'stub-clean' -ExitCode 0 -OutputLines @(
        '  [OK]    all good',
        'Agent-def summary: 19 missing, 0 identical (dead copies), 0 drifted.',
        'Persona drift is INFORMATIONAL (does not affect the exit code): 0 drifted.'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'clean stub: exit code 0'
    Assert-Match 'no errors' $r.Out 'clean stub: boilerplate does not count as a signal'

    # 9c2. Stub workshop with only INFO lines -> OK branch, no session alert (Dave's wish,
    #      July 20, 2026): INFO is register administration about consumer sync (often another
    #      machine/user) and should not be reported at every session start.
    $stub = New-StubWorkshop -Name 'stub-info' -ExitCode 0 -OutputLines @(
        '  [INFO]  fixture register-administration signal',
        '  [INFO]  extension 06-24 exists in the consumer but is not in the register.'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'info stub: exit code 0'
    Assert-Match 'no errors' $r.Out 'info stub: OK branch (INFO gives no session alert)'
    Assert-NotMatch 'fixture register-administration signal' $r.Out 'info stub: INFO line NOT passed through'

    # 9d. Stub workshop with a real error -> signals branch, line comes through. BILINGUAL: the hook
    #     must recognize both the new [ERROR] and the legacy [FOUT] as a blocking signal, because
    #     the plugin cache (this hook) and the workshop checkout (check-connectors) can be on
    #     different versions.
    $stub = New-StubWorkshop -Name 'stub-error' -ExitCode 1 -OutputLines @(
        '  [ERROR] fixture-error-new',
        '  [FOUT]  fixture-error-legacy'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'error stub: exit code 0 (the hook never blocks)'
    Assert-Match 'signals found' $r.Out 'error stub: signals branch'
    Assert-Match 'fixture-error-new' $r.Out 'error stub: new [ERROR] line passed through (bilingual)'
    Assert-Match 'fixture-error-legacy' $r.Out 'error stub: legacy [FOUT] line passed through (bilingual)'

    # 9d2. Stub with a blocking signal (new [ERROR]) AND [INFO] in the same run -> the signal
    #      comes through, the INFO stays out (the most sensitive regression scenario for the
    #      separation, Victor's finding).
    $stub = New-StubWorkshop -Name 'stub-mix' -ExitCode 1 -OutputLines @(
        '  [ERROR] fixture-mix-error',
        '  [INFO]  fixture-mix-info'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Match 'fixture-mix-error' $r.Out 'mix stub: [ERROR] line passed through'
    Assert-NotMatch 'fixture-mix-info' $r.Out 'mix stub: INFO line NOT passed through'

    # 9d3. Complete report (Summary line present) -> findings surface WITHOUT a partial-report warning,
    #      and the summary states what the run covered. The hook is invoked from the repo root against a
    #      stub workshop elsewhere, so this is the -OnlyConsumer scoping path (inbound #203): saying so
    #      distinguishes "this repo is behind" from "some registered consumer is behind" -- the exact
    #      confusion the 2026-07-27 investigation ran into.
    $stub = New-StubWorkshop -Name 'stub-complete' -ExitCode 1 -OutputLines @(
        '  [ERROR] life-hub: machine record is on v2.1.0, source on v2.8.0',
        'Summary: 1 error(s), 0 info signal(s).'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'complete stub: exit code 0'
    Assert-Match 'signals found' $r.Out 'complete stub: signals branch'
    Assert-Match 'life-hub' $r.Out 'complete stub: the connector name travels with the finding'
    Assert-NotMatch 'may be partial' $r.Out 'complete stub: a complete report is not flagged as partial'
    Assert-Match 'scoped to this repo' $r.Out 'complete stub: the summary states the run was scoped to this repo (-OnlyConsumer)'

    # 9d4. Same findings, but the check stopped before its Summary line -> flagged as possibly partial.
    #      The exit code cannot carry this on its own: a complete report WITH findings and a crash
    #      halfway both leave the child on a non-zero exit (inbound #203 item 2).
    $stub = New-StubWorkshop -Name 'stub-partial' -ExitCode 1 -OutputLines @(
        '  [ERROR] life-hub: machine record is on v2.1.0, source on v2.8.0'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Match 'signals found' $r.Out 'partial stub: findings still surface'
    Assert-Match 'may be partial' $r.Out 'partial stub: missing Summary marker flags the list as possibly incomplete'

    # 9d5. Non-zero exit with NO signal line at all: the check broke before it could report anything.
    #      This used to fall into the else-branch and print the "signals found -- summary" header with an
    #      EMPTY list under it, which reads as a finding that is not there. It now has its own branch.
    $stub = New-StubWorkshop -Name 'stub-broke' -ExitCode 1 -OutputLines @(
        'some unexpected failure before any check ran'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'broken stub: exit code 0 (the hook never blocks)'
    Assert-Match 'could not complete' $r.Out 'broken stub: reported as could-not-complete'
    Assert-NotMatch 'signals found' $r.Out 'broken stub: NOT a signals summary with an empty list under it'
    Assert-NotMatch 'no errors' $r.Out 'broken stub: NOT misreported as no errors'

    # 9f. An unregistered consumer must NOT be told "no errors." full stop (gap found 2026-07-28). The
    #     check reports it as [INFO], which this hook suppresses, so the reassurance used to be the only
    #     thing a brand-new consumer ever saw. The non-counting [UNREGISTERED] line now survives next to
    #     the no-errors verdict -- next to, not under: nothing is wrong with the plugin install here,
    #     only with the workshop's view of it, so the exit code and the "no errors" reading both stand.
    # The stub carries the REAL message text (kept in step with check-connectors.ps1), because the
    # jargon assertion below only means something if the fixture is faithful -- an old-wording stub would
    # make the hook look guilty of text it never produced.
    $stub = New-StubWorkshop -Name 'stub-unregistered' -ExitCode 0 -OutputLines @(
        '  [INFO]  not registered: no manifest for this consumer in the register.',
        "  [UNREGISTERED] this repo is not in the plugin maintainer's connector register. Nothing here is affected -- the plugin works normally. If you maintain the plugin source, add a connectors/<repo>.json manifest there; if you just use the plugin, no action is needed on your side.",
        'Summary: 0 error(s), 1 info signal(s).'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'unregistered stub: exit code 0'
    Assert-Match '\[UNREGISTERED\]' $r.Out 'unregistered stub: the marker reaches the session context'
    Assert-Match "not in the plugin maintainer's register" $r.Out 'unregistered stub: the verdict line says so instead of a bare "no errors"'
    # Consumer-first wording (Dave, July 28, 2026): a reader who only installed the plugin has never
    # heard of "the workshop", so that nickname must not appear in anything surfaced to a session.
    Assert-NotMatch 'workshop' $r.Out 'unregistered stub: no internal "workshop" jargon reaches the consumer'
    Assert-NotMatch 'signals found' $r.Out 'unregistered stub: NOT escalated to a signals summary (nothing is wrong with the install)'
    Assert-NotMatch '\[INFO\]\s+not registered' $r.Out 'unregistered stub: the per-signal [INFO] line still stays out'

    # 9g. A REGISTERED consumer gains nothing: no marker, so the plain no-errors line is unchanged. The
    #     guard against this fix becoming a line every session start carries.
    $stub = New-StubWorkshop -Name 'stub-registered' -ExitCode 0 -OutputLines @(
        '  [OK]    all 3 registered extensions present',
        'Summary: 0 error(s), 0 info signal(s).'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Match 'no errors\.' $r.Out 'registered stub: the plain no-errors line is unchanged'
    Assert-NotMatch 'UNREGISTERED' $r.Out 'registered stub: no unregistered notice'
    Assert-NotMatch 'not in the workshop register' $r.Out 'registered stub: no register wording at all'

    # 9i. An [INVENTORY] notice reaches the session on its own verdict line (found 2026-07-29). Same
    #     shape as 9f one step further in: the repo IS registered, so "not in the register" would be the
    #     wrong story -- its entry simply lists fewer lenses than the repo holds. The check emits the
    #     line only about the repo the session is in, so the hook can surface it unconditionally.
    $stub = New-StubWorkshop -Name 'stub-inventory' -ExitCode 0 -OutputLines @(
        "  [INFO]  DaveKJohn/davekjohns-workshop / specialists@davekjohns-workshop: extension '04-11' exists in the consumer but is not in the register -- update the register or review the change.",
        "  [INVENTORY] this repo has 1 lens(es) that its own entry in the connector register does not list (04-11) -- add them to the 'extensions' array in davekjohns-workshop.json, in the same change that landed the lens. Nothing is broken: the register's view of this repo is simply behind reality.",
        'Summary: 0 error(s), 1 info signal(s).'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'inventory stub: exit code 0'
    Assert-Match '\[INVENTORY\]' $r.Out 'inventory stub: the marker reaches the session context'
    Assert-Match 'lens inventory for this repo is behind' $r.Out 'inventory stub: its own verdict line, not the not-registered one'
    Assert-NotMatch "not in the plugin maintainer's register" $r.Out 'inventory stub: NOT reported as unregistered -- the entry exists, it is just behind'
    Assert-NotMatch 'signals found' $r.Out 'inventory stub: NOT escalated to a signals summary (nothing is wrong with the install)'
    Assert-NotMatch '\[INFO\]' $r.Out 'inventory stub: the per-signal [INFO] line still stays out'

    # 9j. A clean run gains nothing: the guard against this becoming a line every session start carries.
    $stub = New-StubWorkshop -Name 'stub-no-inventory' -ExitCode 0 -OutputLines @(
        '  [OK]    all 19 registered extensions present',
        'Summary: 0 error(s), 0 info signal(s).'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Match 'no errors\.' $r.Out 'no-inventory stub: the plain no-errors line is unchanged'
    Assert-NotMatch 'INVENTORY' $r.Out 'no-inventory stub: no inventory notice'
    Assert-NotMatch 'inventory' $r.Out 'no-inventory stub: no inventory wording at all'

    # 9k. Real signals AND an inventory notice in one run: both surface (the $notices list, not just
    #     $unregistered -- a regression here would silently drop the marker whenever anything else is
    #     also wrong, which is exactly when a session is busiest).
    $stub = New-StubWorkshop -Name 'stub-inv-mixed' -ExitCode 1 -OutputLines @(
        '  [ERROR] life-hub / specialists@davekjohns-workshop: machine record is on v2.9.0, source on v2.11.0',
        "  [INVENTORY] this repo has 1 lens(es) that its own entry in the connector register does not list (04-11) -- add them to the 'extensions' array in davekjohns-workshop.json, in the same change that landed the lens. Nothing is broken: the register's view of this repo is simply behind reality.",
        'Summary: 1 error(s), 1 info signal(s).'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Match 'signals found' $r.Out 'inventory mixed: the signals branch fires'
    Assert-Match 'v2\.9\.0' $r.Out 'inventory mixed: the real [ERROR] surfaces'
    Assert-Match '\[INVENTORY\]' $r.Out 'inventory mixed: the inventory marker surfaces alongside it'

    # 9h. Real signals AND an unregistered notice in one run: both surface, neither crowds out the other.
    $stub = New-StubWorkshop -Name 'stub-unreg-mixed' -ExitCode 1 -OutputLines @(
        '  [ERROR] life-hub / specialists@davekjohns-workshop: machine record is on v2.1.0, source on v2.9.0',
        '  [UNREGISTERED] this repo has no manifest in the workshop register.',
        'Summary: 1 error(s), 1 info signal(s).'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Match 'signals found' $r.Out 'unregistered mixed: the signals branch fires'
    Assert-Match 'v2\.1\.0' $r.Out 'unregistered mixed: the real [ERROR] surfaces'
    Assert-Match '\[UNREGISTERED\]' $r.Out 'unregistered mixed: the unregistered marker surfaces alongside it'

    # 9e. Marker check (Sean guardrail): a candidate path without a valid marker is NOT executed.
    $stub = New-StubWorkshop -Name 'stub-fake' -ExitCode 0 -ValidMarker $false -OutputLines @(
        'FAKE-EXECUTED'
    )
    $r = Invoke-Ps $Hook @('-WorkshopPathOverride', $stub)
    Assert-Equal 0 $r.Code 'fake workshop: exit code 0'
    Assert-Match 'check skipped' $r.Out 'fake workshop: rejected as a workshop'
    Assert-NotMatch 'FAKE-EXECUTED' $r.Out 'fake workshop: script was NOT executed'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
}

Write-Host "`nResult: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
