<#
.SYNOPSIS
    Regression tests for BOTH halves of the "a plugin is a team or a workflow; teams stack, workflows
    do not" change, landed together on August 9, 2026:
      (a) the core team's SessionStart hook (plugins/teams/team-alpha/hooks/workflow-sessioncheck.ps1),
          which counts enabled 'workflow-*' plugin ids and warns when more than one is enabled at once;
      (b) lint check 23 ([plugin-kind]) in scripts/lint/check-plugin-integrity.ps1, which holds every
          published plugin to sitting under plugins/teams/ or plugins/workflows/ per its own name --
          the mechanism (a) depends on, since it decides "is this a workflow" purely by the 'workflow-'
          prefix.

.DESCRIPTION
    Dependency-free: no Pester, plain PowerShell. Integration style -- runs the real hook and the real
    lint script in CHILD PROCESSES against throwaway fixtures in the temp dir and asserts on exit code +
    output.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/workflow-exclusivity.tests.ps1

    PART (a) -- the hook. It has no -ConsumerPathOverride/-UserHomeOverride parameters of its own (unlike
    check-connectors.ps1 / check-roster-sync.ps1): it reads $env:CLAUDE_PROJECT_DIR for the repo root and
    falls through to Get-EnabledPlugins, which reads the USER layer via $env:USERPROFILE. Both env vars
    are therefore set for the child process directly (Invoke-Hook), the same technique
    connectors.tests.ps1 and roster-sync.tests.ps1 already use to pin the settings chain to a fixture
    instead of the real machine. $env:USERPROFILE is ALWAYS pointed at a fixture -- a nonexistent
    'no-user-home' dir when a scenario has nothing to say about the user layer, so a run on a machine
    that happens to have a workflow plugin enabled globally cannot turn a silent scenario noisy.

    PART (b) -- the lint check. Runs the REAL check-plugin-integrity.ps1 against a throwaway fixture that
    carries a copy of the script plus every lib it dot-sources (the exact pattern
    check-plugin-integrity-fixture.ps1 uses, read before writing this). 'team-alpha',
    'workflow-davekjohn', 'workflow-default' AND 'team-shopify' are declared, correctly placed, in EVERY
    scenario: the shared-scripts registry (Get-SharedScriptPairs) throws outright -- uncaught, killing the
    whole gate mid-run -- if the marketplace declares ANY plugin but not one that a registered pair names
    (confirmed the hard way twice: an early draft of this fixture omitted 'workflow-default', which only
    'check-report-lib-default' among two dozen pairs names, and on August 20, 2026 'team-shopify' arrived
    in the registry with 'adopt-shopify-floor' -- both times the gate died before check 23 ever ran). So
    those four are the fixed floor every scenario builds on rather than an arbitrary choice, and the floor
    grows whenever the registry gains a Plugin value.

    THE SECOND TIME EXPOSED A HOLE IN THIS SUITE, now closed. Scenarios 8 and 9 caught the dead gate
    because they expect a finding; scenario 7 expects the ABSENCE of one, so it passed on a gate that had
    died six checks earlier -- an empty scan reading as a clean bill of health. It now also asserts that
    the coverage line was printed, which is the only witness that check 23 ran at all.

    Test-gaps (honest):
      - Part (a): the settings.local.json layer is built and asserted on in roster-sync.tests.ps1 and
        connectors.tests.ps1 already (per-key precedence, local wins); it is not re-exercised here as a
        THIRD source of a workflow conflict, since Get-SettingsChainPaths treats it as an ordinary peer
        entry in the same chain the project/user scenarios already walk -- a third near-identical
        scenario would not exercise a new code path.
      - Part (a): the hook's docstring claims "writes nothing". That is checked here only indirectly
        (every scenario's fixture files are re-read afterwards by nothing else in this suite); no
        scenario asserts on filesystem state before/after a run.
      - Part (b): only check 23 is asserted on. The fixture inevitably trips other checks against such a
        minimal tree (a missing RELEASE.md-successor, no agents/, etc.) -- expected noise, exactly as
        the check-plugin-integrity suites' own fixture does, and not asserted on here either.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Hook     = Join-Path $RepoRoot 'plugins\teams\team-alpha\hooks\workflow-sessioncheck.ps1'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) "workflow-exclusivity-test-fixture-$PID"

# --- Part (b) sources: the lint script plus every lib it dot-sources (transitively), the same set
#     check-plugin-integrity-fixture.ps1 copies -- read there before writing this, rather than re-derived.
$IntegritySrc        = Join-Path $RepoRoot 'scripts\lint\check-plugin-integrity.ps1'
$AgentSharedLibSrc   = Join-Path $RepoRoot 'scripts\lib\agent-shared-lib.ps1'
$SharedScriptsLibSrc = Join-Path $RepoRoot 'scripts\lib\shared-scripts-lib.ps1'
$CheckReportLibSrc   = Join-Path $RepoRoot 'scripts\lib\check-report-lib.ps1'
$ReleaseLibSrc       = Join-Path $RepoRoot 'scripts\lib\release-lib.ps1'
$BranchInfoSrc       = Join-Path $RepoRoot 'scripts\lib\branch-info.ps1'
$EntryScaffoldSrc    = Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1'
$PluginTreeSrc       = Join-Path $RepoRoot 'scripts\lib\plugin-tree-lib.ps1'
# Added with lint check 24 (August 10, 2026). The lint dot-sources this for the recognised placeholder
# list and the reference PR template; a fixture missing it does not skip that check, it kills the whole
# script before check 23 runs -- which is exactly how this suite failed when the check landed.
$PrBodyLibSrc        = Join-Path $RepoRoot 'scripts\lib\pr-body-lib.ps1'
# Added with lint check 28 (August 26, 2026), for the same reason as the line above: the lint dot-sources
# this for the '@'-import parser, and a fixture missing it kills the script at that line rather than
# skipping one check.
$MeasureContextSrc   = Join-Path $RepoRoot 'scripts\lib\measure-context-lib.ps1'

$ProjectDir    = Join-Path $Fixture 'project'
$UserHomeDir   = Join-Path $Fixture 'user-home'
$NoUserHomeDir = Join-Path $Fixture 'no-user-home'   # deliberately never created -- isolation
$LintFixture   = Join-Path $Fixture 'lint'

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

# --- Part (a) helpers --------------------------------------------------------------------------------

function Write-EnabledPluginsJson {
    param([string]$Path, [hashtable]$Enabled)
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    $entries = @()
    foreach ($k in $Enabled.Keys) {
        $entries += ('"' + $k + '": ' + $(if ($Enabled[$k]) { 'true' } else { 'false' }))
    }
    $json = '{ "enabledPlugins": { ' + ($entries -join ', ') + ' } }'
    [System.IO.File]::WriteAllText($Path, $json)
}

# Builds/rebuilds $ProjectDir's settings layer(s). -LocalEnabled is optional and, when given, also
# writes .claude/settings.local.json -- not exercised by any scenario below (see the test-gap note),
# kept only so a future scenario does not have to invent the plumbing.
function New-ProjectFixture {
    param([hashtable]$Enabled, [hashtable]$LocalEnabled = $null)
    if (Test-Path -LiteralPath $ProjectDir) { Remove-Item -Recurse -Force -LiteralPath $ProjectDir }
    New-Item -ItemType Directory -Path $ProjectDir -Force | Out-Null
    Write-EnabledPluginsJson -Path (Join-Path $ProjectDir '.claude\settings.json') -Enabled $Enabled
    if ($LocalEnabled) {
        Write-EnabledPluginsJson -Path (Join-Path $ProjectDir '.claude\settings.local.json') -Enabled $LocalEnabled
    }
    return $ProjectDir
}

# Builds/rebuilds $UserHomeDir's ~/.claude/settings.json -- the USER layer of the settings chain
# (Get-SettingsChainPaths' 'user ~/.claude/settings.json' label).
function New-UserHomeFixture {
    param([hashtable]$Enabled)
    if (Test-Path -LiteralPath $UserHomeDir) { Remove-Item -Recurse -Force -LiteralPath $UserHomeDir }
    New-Item -ItemType Directory -Path $UserHomeDir -Force | Out-Null
    Write-EnabledPluginsJson -Path (Join-Path $UserHomeDir '.claude\settings.json') -Enabled $Enabled
    return $UserHomeDir
}

# Runs the REAL hook as a child process, with $env:CLAUDE_PROJECT_DIR and $env:USERPROFILE pinned to
# fixtures for the duration of the call only. $ErrorActionPreference is relaxed around the child call
# for the same reason Invoke-Fold does it in fold-changelog.tests.ps1: under 'Stop', anything the child
# writes to stderr comes back as a terminating NativeCommandError and kills THIS script instead of
# failing its own assertion.
function Invoke-Hook {
    param([string]$ProjectPath, [string]$UserProfilePath)
    $prevPd      = $env:CLAUDE_PROJECT_DIR
    $prevProfile = $env:USERPROFILE
    $prevEap     = $ErrorActionPreference
    try {
        $env:CLAUDE_PROJECT_DIR = $ProjectPath
        $env:USERPROFILE        = $UserProfilePath
        $ErrorActionPreference  = 'Continue'
        $out  = & powershell -NoProfile -ExecutionPolicy Bypass -File $Hook 2>&1
        $code = $LASTEXITCODE
    } finally {
        if ($null -eq $prevPd) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prevPd }
        $env:USERPROFILE       = $prevProfile
        $ErrorActionPreference = $prevEap
    }
    return [pscustomobject]@{ Code = $code; Out = ($out -join "`n") }
}

# --- Part (b) helpers ---------------------------------------------------------------------------------

# Builds the fixture's script skeleton ONCE: a copy of the real lint script plus every lib it
# dot-sources, transitively (release-lib pulls in branch-info + entry-scaffold-lib; both release-lib
# and shared-scripts-lib pull in plugin-tree-lib). This part does not change between scenarios, only
# the marketplace/plugin layer does (Set-LintFixturePlugins).
function New-LintFixtureBase {
    if (Test-Path -LiteralPath $LintFixture) { Remove-Item -Recurse -Force -LiteralPath $LintFixture }
    New-Item -ItemType Directory -Path (Join-Path $LintFixture 'scripts\lint') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $LintFixture 'scripts\lib') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $LintFixture 'connectors') -Force | Out-Null
    Copy-Item -Path $IntegritySrc        -Destination (Join-Path $LintFixture 'scripts\lint\check-plugin-integrity.ps1') -Force
    Copy-Item -Path $AgentSharedLibSrc   -Destination (Join-Path $LintFixture 'scripts\lib\agent-shared-lib.ps1') -Force
    Copy-Item -Path $SharedScriptsLibSrc -Destination (Join-Path $LintFixture 'scripts\lib\shared-scripts-lib.ps1') -Force
    Copy-Item -Path $CheckReportLibSrc   -Destination (Join-Path $LintFixture 'scripts\lib\check-report-lib.ps1') -Force
    Copy-Item -Path $ReleaseLibSrc       -Destination (Join-Path $LintFixture 'scripts\lib\release-lib.ps1') -Force
    Copy-Item -Path $BranchInfoSrc       -Destination (Join-Path $LintFixture 'scripts\lib\branch-info.ps1') -Force
    Copy-Item -Path $EntryScaffoldSrc    -Destination (Join-Path $LintFixture 'scripts\lib\entry-scaffold-lib.ps1') -Force
    Copy-Item -Path $PluginTreeSrc       -Destination (Join-Path $LintFixture 'scripts\lib\plugin-tree-lib.ps1') -Force
    Copy-Item -Path $PrBodyLibSrc        -Destination (Join-Path $LintFixture 'scripts\lib\pr-body-lib.ps1') -Force
    Copy-Item -Path $MeasureContextSrc   -Destination (Join-Path $LintFixture 'scripts\lib\measure-context-lib.ps1') -Force
}

# Rewrites .claude-plugin/marketplace.json to declare exactly $Plugins (each a hashtable with Name +
# Source, e.g. Source = './plugins/teams/team-alpha'), and creates a minimal real directory + plugin.json
# for each -- so check 1 (marketplace) does not also complain "source folder does not exist" and drown
# out the [plugin-kind] finding under test. Wipes plugins/ and .claude-plugin/ first, so a leftover
# directory from a previous scenario cannot leak into the next one's scan.
function Set-LintFixturePlugins {
    param([hashtable[]]$Plugins)
    $pluginsDir = Join-Path $LintFixture 'plugins'
    if (Test-Path -LiteralPath $pluginsDir) { Remove-Item -Recurse -Force -LiteralPath $pluginsDir }
    $cpDir = Join-Path $LintFixture '.claude-plugin'
    if (Test-Path -LiteralPath $cpDir) { Remove-Item -Recurse -Force -LiteralPath $cpDir }
    New-Item -ItemType Directory -Path $cpDir -Force | Out-Null

    $entries = @()
    foreach ($pl in $Plugins) {
        $entries += ('    { "name": "' + $pl.Name + '", "source": "' + $pl.Source + '" }')
        $relDir = ($pl.Source.TrimStart('.', '/')) -replace '/', '\'
        $dir = Join-Path $LintFixture $relDir
        $manifestDir = Join-Path $dir '.claude-plugin'
        New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $manifestDir 'plugin.json'), ('{ "name": "' + $pl.Name + '", "version": "0.0.1" }'))
    }
    $mp = "{`n  `"name`": `"fixture-marketplace`",`n  `"plugins`": [`n" + ($entries -join ",`n") + "`n  ]`n}`n"
    [System.IO.File]::WriteAllText((Join-Path $cpDir 'marketplace.json'), $mp)
}

# Runs the real (fixture-copied) lint script as a child process. Same $ErrorActionPreference relaxation
# as Invoke-Hook and as check-plugin-integrity-fixture.ps1's own Invoke-Integrity, and for the identical
# reason: a scenario that makes the gate crash must fail its own assertion, not abort the whole suite.
function Invoke-Integrity {
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $scriptPath = Join-Path $LintFixture 'scripts\lint\check-plugin-integrity.ps1'
        $out  = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prevEap
    }
    return [pscustomobject]@{ Code = $code; Out = ($out -join "`n") }
}

$TeamAlpha         = @{ Name = 'team-alpha';         Source = './plugins/teams/team-alpha' }
$WorkflowDavekjohn = @{ Name = 'workflow-davekjohn'; Source = './plugins/workflows/workflow-davekjohn' }
# Also part of the fixed floor (see the DESCRIPTION above): the registry's 'check-report-lib-default'
# pair names 'workflow-default', so it has to be declared -- correctly placed -- alongside the other two
# in every scenario, or Get-SharedScriptPairs throws before check 23 ever runs.
$WorkflowDefault   = @{ Name = 'workflow-default';   Source = './plugins/workflows/workflow-default' }
# And team-shopify, for the identical reason, added August 20, 2026 when 'adopt-shopify-floor' and a
# second copy of the source-repo guard lib were registered under it. This is the THIRD time the floor has
# had to grow with the registry (after workflow-default, and after the sibling fixture in
# check-plugin-integrity-fixture.ps1 the same day) -- so read the paragraph above as a standing rule
# rather than a note: a new Plugin value in the registry means a line here.
$TeamShopify       = @{ Name = 'team-shopify';       Source = './plugins/teams/team-shopify' }

try {
    Write-Host "== workflow-exclusivity.tests ==" -ForegroundColor Cyan

    # ===================================================================================================
    # Part (a): plugins/teams/team-alpha/hooks/workflow-sessioncheck.ps1
    # ===================================================================================================

    # --- 1. Zero workflows enabled (only the core team) -> completely silent, exit 0 -----------------
    #     "Silent" means NO output at all, not merely no [ERROR] -- a stray notice here would itself be a
    #     regression against the documented design (0 workflows is a deliberate, unremarkable state: a
    #     repo may run the specialists with no workflow plugin at all).
    $p = New-ProjectFixture -Enabled @{ 'team-alpha@claude-code-specialists' = $true }
    $r = Invoke-Hook -ProjectPath $p -UserProfilePath $NoUserHomeDir
    Assert-Equal 0 $r.Code '1. zero workflows: exit code 0'
    Assert-Equal '' $r.Out.Trim() '1. zero workflows: completely silent, not merely error-free'

    # --- 2. Exactly one workflow enabled -> silent, exit 0 (the ordinary state) -----------------------
    $p = New-ProjectFixture -Enabled @{
        'team-alpha@claude-code-specialists'         = $true
        'workflow-davekjohn@claude-code-specialists' = $true
    }
    $r = Invoke-Hook -ProjectPath $p -UserProfilePath $NoUserHomeDir
    Assert-Equal 0 $r.Code '2. one workflow: exit code 0'
    Assert-Equal '' $r.Out.Trim() '2. one workflow: silent'

    # --- 3. Two workflows, both enabled from .claude/settings.json -> [ERROR], but NEVER blocks -------
    $p = New-ProjectFixture -Enabled @{
        'team-alpha@claude-code-specialists'         = $true
        'workflow-davekjohn@claude-code-specialists' = $true
        'workflow-default@claude-code-specialists'   = $true
    }
    $r = Invoke-Hook -ProjectPath $p -UserProfilePath $NoUserHomeDir
    Assert-Equal 0 $r.Code '3. two workflows: exit code 0 (a SessionStart hook never blocks)'
    Assert-Match '\[ERROR\] 2 workflows are enabled at once' $r.Out '3. two workflows: the count is named'
    Assert-Match 'workflow-davekjohn@claude-code-specialists\s+\(enabled in \.claude/settings\.json\)' $r.Out '3. two workflows: workflow-davekjohn is named with its layer'
    Assert-Match 'workflow-default@claude-code-specialists\s+\(enabled in \.claude/settings\.json\)' $r.Out '3. two workflows: workflow-default is named with its layer'

    # --- 4. Two workflows arriving from DIFFERENT layers -- the highest-value scenario ----------------
    #     A conflict caused by the machine (user) layer looks identical, from inside the repo, to one the
    #     repo itself caused. Naming the layer per id is what sends the reader to the right file instead
    #     of the wrong one -- so this is the assertion that actually proves Get-EnabledPlugins'
    #     LayerById reaches the hook's output, not just that a conflict is detected at all.
    $p = New-ProjectFixture -Enabled @{
        'team-alpha@claude-code-specialists'         = $true
        'workflow-davekjohn@claude-code-specialists' = $true
    }
    $u = New-UserHomeFixture -Enabled @{ 'workflow-default@claude-code-specialists' = $true }
    $r = Invoke-Hook -ProjectPath $p -UserProfilePath $u
    Assert-Equal 0 $r.Code '4. cross-layer conflict: exit code 0'
    Assert-Match '\[ERROR\] 2 workflows are enabled at once' $r.Out '4. cross-layer conflict: detected'
    Assert-Match 'workflow-davekjohn@claude-code-specialists\s+\(enabled in \.claude/settings\.json\)' $r.Out '4. cross-layer conflict: the PROJECT-layer id is attributed to .claude/settings.json'
    Assert-Match 'workflow-default@claude-code-specialists\s+\(enabled in user ~/\.claude/settings\.json\)' $r.Out '4. cross-layer conflict: the USER-layer id is attributed to ~/.claude/settings.json, not the repo'

    # --- 5. Teams STACK and must never trigger this check, however many are enabled ------------------
    #     Three team-* plugins alongside exactly one workflow. A check that fired here would be actively
    #     wrong, not merely noisy: teams are documented to stack.
    $p = New-ProjectFixture -Enabled @{
        'team-alpha@claude-code-specialists'         = $true
        'team-beta@claude-code-specialists'          = $true
        'team-gamma@claude-code-specialists'         = $true
        'workflow-davekjohn@claude-code-specialists' = $true
    }
    $r = Invoke-Hook -ProjectPath $p -UserProfilePath $NoUserHomeDir
    Assert-Equal 0 $r.Code '5. several teams + one workflow: exit code 0'
    Assert-Equal '' $r.Out.Trim() '5. several teams + one workflow: silent -- teams stacking is not a conflict'

    # --- 6. A DISABLED workflow ('false' in settings) does not count towards the total ----------------
    $p = New-ProjectFixture -Enabled @{
        'team-alpha@claude-code-specialists'         = $true
        'workflow-davekjohn@claude-code-specialists' = $true
        'workflow-default@claude-code-specialists'   = $false
    }
    $r = Invoke-Hook -ProjectPath $p -UserProfilePath $NoUserHomeDir
    Assert-Equal 0 $r.Code '6. one enabled + one disabled workflow: exit code 0'
    Assert-Equal '' $r.Out.Trim() '6. one enabled + one disabled workflow: silent -- the disabled one is not counted'

    # ===================================================================================================
    # Part (b): lint check 23, [plugin-kind], in scripts/lint/check-plugin-integrity.ps1
    # ===================================================================================================
    New-LintFixtureBase

    # --- 7. A correctly placed team and a correctly placed workflow -> no [plugin-kind] finding -------
    Set-LintFixturePlugins -Plugins @($TeamAlpha, $WorkflowDavekjohn, $WorkflowDefault, $TeamShopify)
    $r = Invoke-Integrity
    # \[plugin-kind\] ' (with the quote) rather than the bare marker: Write-Coverage always prints a
    # non-counting "[plugin-kind] checked N -- ..." line regardless of findings, and a bare-marker
    # assertion would false-fail against that line even with zero errors -- caught by this scenario
    # itself on the first run.
    Assert-NotMatch "\[plugin-kind\] '" $r.Out '7. correctly placed team + workflow: no [plugin-kind] finding at all'
    # AND THE CHECK ACTUALLY RAN, which the assertion above cannot tell on its own. Added August 20, 2026
    # after this scenario PASSED while the gate was dying at check 8 -- a registry pair named a plugin the
    # fixture floor did not declare, Get-SharedScriptPairs threw, and check 21 never executed. Scenarios
    # 8 and 9 caught it because they expect a finding; this one reads a dead gate as a clean bill of
    # health. The coverage line is the only witness, which is why every sibling suite asserts on one.
    Assert-Match '\[plugin-kind\] checked \d+' $r.Out '7. correctly placed team + workflow: and the check WAS reached -- the pass is not a gate that died upstream'

    # --- 8. A 'team-*' plugin whose marketplace source sits under plugins/workflows/ -> reported -------
    $teamBad = @{ Name = 'team-bad'; Source = './plugins/workflows/team-bad' }
    Set-LintFixturePlugins -Plugins @($TeamAlpha, $WorkflowDavekjohn, $WorkflowDefault, $TeamShopify, $teamBad)
    $r = Invoke-Integrity
    Assert-Match "\[plugin-kind\] 'team-bad' is a team by its name but its source is '.*' -- a team belongs under plugins/teams/\." $r.Out "8. misplaced team: 'team-bad' under plugins/workflows/ is reported"
    Assert-NotMatch "\[plugin-kind\] 'team-alpha'" $r.Out '8. misplaced team: the correctly placed team is not also flagged'
    Assert-NotMatch "\[plugin-kind\] 'workflow-davekjohn'" $r.Out '8. misplaced team: the correctly placed workflow is not also flagged'

    # --- 9. A plugin named with neither the 'team-' nor the 'workflow-' prefix -> reported, and the ----
    #        message explains WHY the naming half matters (not just that it is wrong).
    $widgetFoo = @{ Name = 'widget-foo'; Source = './plugins/teams/widget-foo' }
    Set-LintFixturePlugins -Plugins @($TeamAlpha, $WorkflowDavekjohn, $WorkflowDefault, $TeamShopify, $widgetFoo)
    $r = Invoke-Integrity
    Assert-Match "\[plugin-kind\] 'widget-foo' is neither 'team-\*' nor 'workflow-\*'" $r.Out "9. unprefixed name: 'widget-foo' is reported"
    Assert-Match 'workflow-sessioncheck counts enabled workflows BY THAT PREFIX' $r.Out '9. unprefixed name: the message explains the mechanism the naming half protects'
    Assert-Match 'would never be counted and could be enabled alongside another in silence' $r.Out '9. unprefixed name: the message states the concrete failure this prevents'
} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
}

Write-Host "`nResult: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
