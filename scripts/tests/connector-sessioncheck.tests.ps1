<#
.SYNOPSIS
    Tests for plugins/dkj-policy/hooks/connector-sessioncheck.ps1's #1591 fallback: what a SESSION
    SEES on a machine with no sibling source checkout (the ordinary state of a consumer), now that
    the hook runs plugin-versions.ps1 -Brief instead of printing "check skipped" unconditionally.

.DESCRIPTION
    WHY A NEW FILE RATHER THAN EXTENDING connectors.tests.ps1's SECTION 9. That section already
    covers this hook, but through a completely different seam: New-StubWorkshop builds a FAKE
    check-connectors.ps1 behind a valid marketplace marker, and every stub scenario there answers
    "does a workshop resolve, and what does it say". The fallback tested here fires precisely when
    NO workshop resolves, and what it prints depends on a different subsystem entirely -- the
    install administration (~/.claude/plugins/installed_plugins.json) and the marketplace clone
    that plugin-versions.ps1 reads. Bolting that fixture shape (repo + home + git clone + admin
    JSON, exactly plugin-versions.tests.ps1's own idiom) onto an 800+-line file already organised
    around stub workshops would blur two unrelated subjects under one section number. Two of
    connectors.tests.ps1's existing scenarios (9a, 9e) still cover this hook's PRE-fallback rejection
    path (no workshop marker found at all) and were repaired in place there, isolated the same way
    this file isolates everything -- CLAUDE_PROJECT_DIR + USERPROFILE redirected to a scratch
    fixture, per Get-InstallRecord's own docstring, which is the seam that already existed and
    the one this file uses throughout.

    THE FOUR BRANCHES THIS FILE PINS, one scenario group each:
      1  the engine reports at least one [ERROR]   -> a "behind the marketplace clone" verdict
         line, then the [ERROR] lines, then any [INFO] lines, then the [SUMMARY] line, then the
         restart-the-session line -- in that exact order (Assert-Equal on the whole run, line by
         line, not just Assert-Match on fragments)
      2  no [ERROR], but the engine has something to  -> ONE line carrying the summary text, with
         say ([INFO] present or the run is fully quiet)  the [INFO] line(s) NOT forwarded (they would
                                                          be permanent session-start noise from a
                                                          plugin nobody can act on -- the hook's own
                                                          docstring names this explicitly)
      3  the engine's output carries none of the three -> its own branch: neither a finding nor an
         markers this hook recognises (a broken           all-clear, and the engine's own exit code
         install, or a shape change)                      is carried into the message
      4  no plugin-versions.ps1 engine reachable at all  -> the pre-#1591 "check skipped" line,
         (a plugin install predating the mirror)          UNCHANGED

    EVERY ONE OF THE FOUR IS ASSERTED TO SAY THE REGISTER CHECKS DID NOT RUN -- the #533 lesson,
    applied to this new code path. That is true of all four, and branch 4 is why the assertion is
    worth making rather than assuming: it inherited the pre-#1591 wording ("... check skipped."),
    which never mentioned register checks at all, so for a while the hook's own docstring
    overclaimed by exactly one branch. Found by pinning the four independently instead of trusting
    the docstring (#1606), and repaired in the hook rather than by weakening the assert -- which
    would have made this suite lie about what ships.

    BRANCH 2'S ZERO-PLUGINS CORNER WAS THE SECOND ONE FOUND THE SAME WAY (#1607): the engine's whole
    answer there is a single [INFO] line and no [SUMMARY], and the hook read $vsummary
    unconditionally -- so the line trailed off after "Version check: " and dropped the one thing the
    engine had to say. Also repaired in the hook. Both are pinned below on the FIXED behaviour, and
    both scenarios keep the reasoning, because a pin whose history is gone is a pin nobody dares
    touch.

    HOW EACH BRANCH IS REACHED, since none of them is the hook's normal candidate-search path:
      - Branches 1 and 2 drive the REAL hook against a REAL plugin-versions.ps1 (this repo's own
        root copy), isolated via CLAUDE_PROJECT_DIR + USERPROFILE exactly as plugin-versions.tests.ps1
        isolates that script directly -- Invoke-Hook additionally pushes the process location to
        $RepoRoot so the hook's engine search (which reads (Get-Location), NOT
        $env:CLAUDE_PROJECT_DIR) finds this repo's own scripts/task/plugin-versions.ps1 regardless
        of wherever this suite itself was launched from.
      - Branch 3 substitutes a FAKE engine by the same mechanism the hook itself uses to prefer
        "the repo's own copy": the hook's first candidate is (cwd)/scripts/task/plugin-versions.ps1,
        so pushing the location to a scratch dir that HAS its own such file (one that prints
        neither [ERROR] nor [INFO] nor [SUMMARY]) makes the hook run that instead of the real one.
      - Branch 4 needs BOTH hook-relative candidates to miss: the fixed second candidate is
        ($PSScriptRoot/../scripts/task/plugin-versions.ps1) relative to the HOOK FILE'S OWN
        location, which in this repo always resolves (root and plugin mirror are kept identical --
        see plugin-versions.tests.ps1's own note on dual-context). So this branch copies the hook
        itself into an isolated fixture tree with no such sibling, the same "stub" technique
        connectors.tests.ps1 already uses for check-connectors.ps1.

    Every scenario asserts exit code 0 explicitly: a SessionStart hook must never fail a session.
    -WorkshopPathOverride always points at a path that does not exist, so every scenario enters the
    "no verified workshop checkout" branch deliberately, never by accident of the real machine.

    Dependency-free (no Pester), same style as plugin-versions.tests.ps1 / connectors.tests.ps1.
    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Hook     = Join-Path $RepoRoot 'plugins\dkj-policy\hooks\connector-sessioncheck.ps1'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) "connector-sessioncheck-test-$PID"
$Utf8     = New-Object System.Text.UTF8Encoding $false

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ("$Expected" -eq "$Actual") { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}
function Assert-True {
    param([bool]$Condition, [string]$Label)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label" -ForegroundColor Red }
}
function Assert-Has {
    param([string]$Text, [string]$Needle, [string]$Label)
    Assert-True ($Text.Contains($Needle)) $Label
}
function Assert-Lacks {
    param([string]$Text, [string]$Needle, [string]$Label)
    Assert-True (-not $Text.Contains($Needle)) $Label
}

# --- fixture builders (same idiom as plugin-versions.tests.ps1) ---------------------------------

function Git-X {
    # git under EAP=Continue -- the #107 pitfall guard, same reasoning as plugin-versions.tests.ps1.
    param([string]$Dir, [string[]]$GitArgs)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & git -C $Dir @GitArgs 2>&1
        return (($out | ForEach-Object { "$_" }) -join "`n").Trim()
    } finally {
        $ErrorActionPreference = $prev
    }
}

function New-Case {
    # A checkout dir (for CLAUDE_PROJECT_DIR) and a scratch home (for USERPROFILE) that carries the
    # install administration and the marketplace clone -- the hook's fallback reads BOTH via the
    # ambient environment (it passes no -RootOverride/-UserHomeOverride of its own to the engine).
    param([Parameter(Mandatory = $true)][string]$Label)
    $repo    = Join-Path $Fixture "$Label\repo"
    $homeDir = Join-Path $Fixture "$Label\home"
    New-Item -ItemType Directory -Path $repo -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $homeDir '.claude\plugins') -Force | Out-Null
    [pscustomobject]@{
        Repo  = $repo
        Home  = $homeDir
        Clone = (Join-Path $homeDir '.claude\plugins\marketplaces\ccs-fixture')
        Admin = (Join-Path $homeDir '.claude\plugins\installed_plugins.json')
    }
}

function Set-Enabled {
    param([string]$RepoDir, [string[]]$Ids = @())
    New-Item -ItemType Directory -Path (Join-Path $RepoDir '.claude') -Force | Out-Null
    if ($Ids.Count -eq 0) {
        [System.IO.File]::WriteAllText((Join-Path $RepoDir '.claude\settings.json'), '{ "enabledPlugins": { } }', $Utf8)
        return
    }
    $ep = @{}
    foreach ($i in $Ids) { $ep[$i] = $true }
    [System.IO.File]::WriteAllText((Join-Path $RepoDir '.claude\settings.json'),
        (@{ enabledPlugins = $ep } | ConvertTo-Json -Depth 5), $Utf8)
}

function New-Clone {
    # A git-based marketplace clone at $Dir: .claude-plugin/marketplace.json + one plugin.json per
    # name, all at the same version. Returns the HEAD sha after the first commit.
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [string]$Version = '4.32.0',
        [string[]]$PluginNames = @('dkj-team-alpha')
    )
    New-Item -ItemType Directory -Path (Join-Path $Dir '.claude-plugin') -Force | Out-Null
    $plugins = @()
    foreach ($pn in $PluginNames) {
        $pdir = Join-Path $Dir "plugins\$pn\.claude-plugin"
        New-Item -ItemType Directory -Path $pdir -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $pdir 'plugin.json'),
            (@{ name = $pn; version = $Version } | ConvertTo-Json -Depth 5), $Utf8)
        $plugins += @{ name = $pn; source = "./plugins/$pn" }
    }
    [System.IO.File]::WriteAllText((Join-Path $Dir '.claude-plugin\marketplace.json'),
        (@{ name = 'ccs-fixture'; plugins = @($plugins) } | ConvertTo-Json -Depth 6), $Utf8)
    Git-X $Dir @('init', '--quiet') | Out-Null
    Git-X $Dir @('config', 'user.email', 'tycho@test.local') | Out-Null
    Git-X $Dir @('config', 'user.name', 'Tycho Test') | Out-Null
    Git-X $Dir @('config', 'commit.gpgsign', 'false') | Out-Null
    Git-X $Dir @('add', '-A') | Out-Null
    Git-X $Dir @('commit', '--quiet', '-m', 'clone c1') | Out-Null
    return (Git-X $Dir @('rev-parse', 'HEAD'))
}

function New-Rec {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [string]$Version = '4.32.0',
        [string]$Sha = ''
    )
    $h = @{ scope = 'project'; projectPath = $ProjectPath; version = $Version }
    if ($Sha) { $h['gitCommitSha'] = $Sha }
    return $h
}

function Write-Admin {
    param([string]$Path, [hashtable]$Plugins)
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [System.IO.File]::WriteAllText($Path, (@{ version = 2; plugins = $Plugins } | ConvertTo-Json -Depth 12), $Utf8)
}

function Invoke-Hook {
    <#
        Runs the REAL hook (this repo's own copy) with CLAUDE_PROJECT_DIR and USERPROFILE pinned to
        a fixture, and the process location pushed to $RepoRoot -- the hook's engine search reads
        (Get-Location), not $env:CLAUDE_PROJECT_DIR, and pinning it to $RepoRoot rather than relying
        on wherever this suite happens to be invoked from is what makes "the real root copy is
        found" independent of the caller's own working directory.

        No native-capture-lib redirect-file capture here (unlike plugin-versions.tests.ps1):
        Invoke-Ps in connectors.tests.ps1 already established this hook is safe to call with a plain
        '&' (it never writes to stderr on its own success paths, and every path here catches its own
        errors before Write-Host), so the extra machinery buys nothing this hook's own tests need.
    #>
    param([string]$RepoDir, [string]$HomeDir, [string[]]$HookArgs = @())
    $prevP = $env:CLAUDE_PROJECT_DIR
    $prevU = $env:USERPROFILE
    $env:CLAUDE_PROJECT_DIR = $RepoDir
    $env:USERPROFILE = $HomeDir
    Push-Location $RepoRoot
    try {
        $args = @('-WorkshopPathOverride', (Join-Path $Fixture 'nowhere')) + $HookArgs
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Hook @args
        return [pscustomobject]@{ Code = $LASTEXITCODE; Lines = @($out); Text = ($out -join "`n") }
    } finally {
        Pop-Location
        $env:CLAUDE_PROJECT_DIR = $prevP
        $env:USERPROFILE = $prevU
    }
}

function Invoke-HookWithFakeEngine {
    <#
        Branch 3: substitutes a FAKE plugin-versions.ps1 by placing one at
        <EngineDir>\scripts\task\plugin-versions.ps1 and pushing the location there -- the hook's
        OWN candidate search tries (Get-Location)\scripts\task\plugin-versions.ps1 FIRST, so this
        wins over both the real root copy and the real plugin mirror without touching either.
    #>
    param([string]$EngineDir, [string]$FakeBody, [string]$RepoDir, [string]$HomeDir)
    New-Item -ItemType Directory -Path (Join-Path $EngineDir 'scripts\task') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $EngineDir 'scripts\task\plugin-versions.ps1'), $FakeBody, $Utf8)
    $prevP = $env:CLAUDE_PROJECT_DIR
    $prevU = $env:USERPROFILE
    $env:CLAUDE_PROJECT_DIR = $RepoDir
    $env:USERPROFILE = $HomeDir
    Push-Location $EngineDir
    try {
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Hook -WorkshopPathOverride (Join-Path $Fixture 'nowhere')
        return [pscustomobject]@{ Code = $LASTEXITCODE; Lines = @($out); Text = ($out -join "`n") }
    } finally {
        Pop-Location
        $env:CLAUDE_PROJECT_DIR = $prevP
        $env:USERPROFILE = $prevU
    }
}

function Invoke-IsolatedHookNoEngine {
    <#
        Branch 4: copies the REAL hook file into a fixture tree with no sibling
        ..\scripts\task\plugin-versions.ps1 at all, and pushes the location to a bare dir that also
        has none of its own -- so BOTH of the hook's candidates miss and $engine stays $null. This is
        the same "isolated copy" technique New-StubWorkshop already uses for check-connectors.ps1,
        applied to this hook's own file rather than reimplementing its logic.
    #>
    param([string]$IsolatedRoot, [string]$CwdDir)
    $hookCopy = Join-Path $IsolatedRoot 'hooks\connector-sessioncheck.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $hookCopy) -Force | Out-Null
    Copy-Item -LiteralPath $Hook -Destination $hookCopy -Force
    New-Item -ItemType Directory -Path $CwdDir -Force | Out-Null
    Push-Location $CwdDir
    try {
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $hookCopy -WorkshopPathOverride (Join-Path $CwdDir 'nowhere')
        return [pscustomobject]@{ Code = $LASTEXITCODE; Lines = @($out); Text = ($out -join "`n") }
    } finally {
        Pop-Location
    }
}

$REGISTER_PHRASE = 'the register checks (consumer registration, lens inventory, agent-def drift) did not run'

try {
    Write-Host "== connector-sessioncheck.tests: the #1591 fallback (no sibling source checkout) ==" -ForegroundColor Cyan
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null

    Assert-True (Test-Path -LiteralPath $Hook -PathType Leaf) 'connector-sessioncheck.ps1 exists at its canonical path'

    # --- 1. [ERROR] lines present -> the "behind" verdict, in the documented order -------------------
    Write-Host "1. [ERROR] present -> verdict line, [ERROR]s, [INFO]s, [SUMMARY], restart line -- in order" -ForegroundColor Cyan
    $c = New-Case 'branch1'
    $shaA = New-Clone -Dir $c.Clone -Version '4.32.0' -PluginNames @('plug-behind', 'plug-clonebehind')
    [System.IO.File]::WriteAllText((Join-Path $c.Clone 'marker.txt'), 'x', $Utf8)
    Git-X $c.Clone @('add', '-A') | Out-Null
    Git-X $c.Clone @('commit', '--quiet', '-m', 'clone c2') | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @('plug-behind@ccs-fixture', 'plug-clonebehind@ccs-fixture')
    Write-Admin -Path $c.Admin -Plugins @{
        'plug-behind@ccs-fixture'      = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $shaA) )
        'plug-clonebehind@ccs-fixture' = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef') )
    }
    $r = Invoke-Hook -RepoDir $c.Repo -HomeDir $c.Home
    Assert-Equal 0 $r.Code '1: exit 0 -- a session start never blocks'
    Assert-Equal 5 $r.Lines.Count '1: exactly five lines -- verdict, one ERROR, one INFO, one SUMMARY, restart'
    Assert-Equal "connector-sessioncheck: no source checkout on this machine, so $REGISTER_PHRASE. This checkout is behind the marketplace clone:" $r.Lines[0] '1: line 1 -- the register-checks phrase, then the behind-the-clone verdict'
    Assert-Equal "  [ERROR] plug-behind@ccs-fixture: the clone is AHEAD of your install (same version string 4.32.0, newer commit) -- claude plugin update plug-behind@ccs-fixture --scope project" $r.Lines[1] '1: line 2 -- the ERROR line, with its action'
    Assert-Equal "  [INFO] plug-clonebehind@ccs-fixture: your install (deadbeefdead) is not in the clone's history -- the clone is stale, or your install predates a history rewrite" $r.Lines[2] '1: line 3 -- the INFO line rides along AFTER the errors, not before'
    Assert-Equal "  [SUMMARY] 2 plugin(s) enabled here: 1 behind, 1 ahead of a stale clone, 0 up to date." $r.Lines[3] '1: line 4 -- the summary, after every finding'
    Assert-Equal "  (then restart the session -- a skill or hook that arrives with an update is not in a session that started before it.)" $r.Lines[4] '1: line 5 -- the restart-the-session line comes last'

    # --- 2. no [ERROR] -> ONE line with the summary; [INFO] must NOT be forwarded on a clean run -----
    Write-Host "2a. no [ERROR], an [INFO] exists (stale clone) -> one line, the INFO is NOT forwarded" -ForegroundColor Cyan
    $c = New-Case 'branch2a'
    New-Clone -Dir $c.Clone -Version '4.32.0' | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @('dkj-team-alpha@ccs-fixture')
    Write-Admin -Path $c.Admin -Plugins @{
        'dkj-team-alpha@ccs-fixture' = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef') )
    }
    $r = Invoke-Hook -RepoDir $c.Repo -HomeDir $c.Home
    Assert-Equal 0 $r.Code '2a: exit 0'
    Assert-Equal 1 $r.Lines.Count '2a: exactly one line -- the [INFO] finding is not printed'
    Assert-Equal "connector-sessioncheck: no source checkout on this machine, so $REGISTER_PHRASE. Version check: 1 plugin(s) enabled here: 0 behind, 1 ahead of a stale clone, 0 up to date." $r.Lines[0] '2a: the one line carries the register-checks phrase and the summary, verbatim'
    Assert-Lacks $r.Text '[INFO]' '2a: the [INFO] marker never reaches the session -- permanent noise the docstring explicitly refuses'

    Write-Host "2b. fully quiet run (nothing behind, nothing undetermined) -> the same one-line shape" -ForegroundColor Cyan
    $c = New-Case 'branch2b'
    $head = New-Clone -Dir $c.Clone -Version '4.32.0'
    Set-Enabled -RepoDir $c.Repo -Ids @('dkj-team-alpha@ccs-fixture')
    Write-Admin -Path $c.Admin -Plugins @{
        'dkj-team-alpha@ccs-fixture' = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $head) )
    }
    $r = Invoke-Hook -RepoDir $c.Repo -HomeDir $c.Home
    Assert-Equal 0 $r.Code '2b: exit 0'
    Assert-Equal 1 $r.Lines.Count '2b: exactly one line'
    Assert-Equal "connector-sessioncheck: no source checkout on this machine, so $REGISTER_PHRASE. Version check: 1 plugin(s) enabled here: 0 behind, 1 up to date." $r.Lines[0] '2b: an all-current install reads as a plain one-line "up to date" version check'

    # 2c. ZERO PLUGINS ENABLED -- the one state where the engine's whole answer is a notice (#1607).
    #     It emits a single [INFO] line and no [SUMMARY] at all, and the hook used to read $vsummary
    #     unconditionally: the line trailed off after "Version check: " and the only thing the engine
    #     had to say was dropped. The hook now reads whichever half is actually there. Pinned on the
    #     whole line, because the failure was an EMPTY interpolation -- a fragment match would have
    #     passed straight through it.
    Write-Host "2c. zero plugins enabled -> the engine's only line is carried, not dropped (#1607)" -ForegroundColor Cyan
    $c = New-Case 'branch2c'
    Set-Enabled -RepoDir $c.Repo -Ids @()
    $r = Invoke-Hook -RepoDir $c.Repo -HomeDir $c.Home
    Assert-Equal 0 $r.Code '2c: exit 0 -- still never blocks'
    Assert-Equal "connector-sessioncheck: no source checkout on this machine, so $REGISTER_PHRASE. Version check: no plugins are enabled for this checkout -- nothing to compare." $r.Lines[0] '2c: #1607 -- the engines own sentence is carried through, with its [INFO] marker stripped'

    # --- 3. the engine's output matches none of the three markers -> its own branch ------------------
    Write-Host "3. engine output carries no [ERROR]/[INFO]/[SUMMARY] -> neither a finding nor an all-clear" -ForegroundColor Cyan
    $c = New-Case 'branch3'
    $fakeBody = "Write-Host 'SOMETHING WEIRD, NOT A MARKER LINE'`r`nexit 3`r`n"
    $r = Invoke-HookWithFakeEngine -EngineDir (Join-Path $Fixture 'branch3\engine') -FakeBody $fakeBody -RepoDir $c.Repo -HomeDir $c.Home
    Assert-Equal 0 $r.Code '3: exit 0 -- the hook itself never fails even though the engine gave it nothing usable'
    Assert-Equal 1 $r.Lines.Count '3: exactly one line'
    Assert-Equal "connector-sessioncheck: no source checkout on this machine, so $REGISTER_PHRASE, and the version check produced no readable output (exit 3) -- run the plugin-versions skill to see why." $r.Lines[0] '3: its own branch -- names the engine exit code, neither "no errors" nor a findings summary'
    Assert-Lacks $r.Text 'SOMETHING WEIRD' '3: the fake engines own raw output never reaches the session'

    # --- 4. no plugin-versions.ps1 engine reachable at all -> the pre-#1591 line, unchanged ----------
    Write-Host "4. no engine at all -> the pre-#1591 'check skipped' line" -ForegroundColor Cyan
    $r = Invoke-IsolatedHookNoEngine -IsolatedRoot (Join-Path $Fixture 'branch4\isolated') -CwdDir (Join-Path $Fixture 'branch4\cwd')
    Assert-Equal 0 $r.Code '4: exit 0'
    Assert-Equal 1 $r.Lines.Count '4: exactly one line'
    Assert-Equal "connector-sessioncheck: no source checkout on this machine, so $REGISTER_PHRASE, and no plugin-versions engine sits beside this hook either -- version check skipped." $r.Lines[0] '4: the verdict half degrades to the pre-#1591 answer, and the register half is stated as in every other branch'
    # #1606: this branch inherited the pre-#1591 wording and was therefore the ONE sibling that never
    # said the register checks had not run, while the hook's docstring claimed all of them did. The
    # assert below is the whole point of pinning the four branches independently rather than trusting
    # that claim -- it is what turns "every branch says it" from a comment into a measurement.
    Assert-Has $r $REGISTER_PHRASE '4: #1606 -- this branch carries the register-checks phrase too, like its three siblings'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
