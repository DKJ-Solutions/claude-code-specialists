<#
.SYNOPSIS
    Tests for scripts/task/plugin-versions.ps1 -- the read-only, per-device "is the plugin version
    this checkout loads the same as the marketplace clone's" report.

.DESCRIPTION
    The script is a monolithic entry point (param -> read the two sides -> print a verdict per
    plugin -> exit 0), not a lib of dot-sourceable functions -- Format-ShortSha, Resolve-Clone and
    Compare-Version are defined INSIDE it and cannot be reached without running the whole flow. So
    every scenario drives it end to end through its two documented test seams, -RootOverride and
    -UserHomeOverride, and asserts on stdout + exit code. Nothing here reads the real ~/.claude.

    THE CHILD IS CAPTURED THROUGH Invoke-NativeCapture -Utf8 (redirect files), never '2>&1' -- see
    Tycho's lens (04-18-extension.md) and issue #1530 for why a '2>&1' capture fails in a way that
    reads as a defect in the script under test. Phrase asserts strip ALL whitespace from both sides,
    so a line the child wrapped at its own console width still matches.

    The verdict paths covered, one scenario each:
      1  install sha == clone HEAD, versions agree            -> "up to date", summary all-current
      2  same version string, clone HEAD is a child of the    -> "clone is AHEAD", per-plugin update
         installed sha
      3  no sha on the install side, installed version <      -> "clone is AHEAD (x -> y)", update
         clone version
      4  installed sha is NOT in the clone's history          -> "refresh the clone" (marketplace update)
      5  plugin enabled but no install record for this path   -> "enabled declaratively only" row, no crash
      6  no marketplace clone at all                          -> "cannot determine", exit 0, no throw
      7  two conflicting install records for one id+path      -> withheld comparison, no crash
      8  non-git clone: HEAD is read from the .gcs-sha file   -> 8a match on that sha, 8b version fallback
      9  a foreign plugin id not in the clone's marketplace   -> "cannot determine", no error
      10 no plugins enabled                                   -> a sentence, exit 0
      11 projectPath separator / trailing-slash insensitivity -> still matched, "up to date"
      12 install sha reachable in the clone but NOT an        -> version strings genuinely say the
         ancestor of HEAD (history rewrite in the clone)         clone is ahead -> per-plugin update,
                                                                   NOT a marketplace refresh
      13 same shape as 12, but the version strings do NOT     -> "your install is AHEAD of the
         say the clone is ahead                                  clone -- stale", marketplace refresh
      14 malformed gitCommitSha in the install record          -> degrades to the version comparison,
                                                                   never reaches git, no crash
      15 asymmetric gap (a): install has a version but no sha, -> the catch-all verdict names BOTH
         clone has HEAD but no readable plugin.json version       missing fields, never a bare
                                                                    "cannot determine -- " (regression)
      16 asymmetric gap (b): install has a sha but no version, -> same regression, opposite side
         clone has a version but no HEAD/.gcs-sha
      17 -Brief on a 'behind' row                             -> one [ERROR] line, action appended
      18 -Brief on a 'clone-behind' row                       -> [INFO], NEVER [ERROR] -- #1591's own
                                                                  rule: a stale clone is not an error
      19 -Brief on an 'indeterminate' row                     -> [INFO], never [ERROR]
      20 -Brief on 'match' (20a) and 'ver-match' (20b)        -> the whole run is the [SUMMARY] line
                                                                  alone: an up-to-date plugin is silent
      21 -Brief with no plugins enabled                       -> one [INFO] line and no [SUMMARY]
      22 -Brief on a mix of every code                        -> exactly one [SUMMARY], whose counts
                                                                  partition all the rows
      23 -Brief suppresses the header, default view unchanged -> an absolute path stays out of a
                                                                  session start
    Every scenario asserts exit code 0 explicitly (this is a report, not a gate).

    Scenarios 12/13 build the "reachable but not an ancestor" state the way a real marketplace clone
    reaches it: a rebase or force-push in the clone after which the OLD commit still exists as a loose
    git object (rev-parse -q --verify resolves it) but is no longer on the line from HEAD. See
    New-DivergedClone below.

    Test 8a additionally carries two SCOPED assertions (Assert-HasBetween / Assert-LacksBetween)
    alongside its existing Assert-Has: 'sha a1b2c3d4e5f6' also appears verbatim in the per-clone
    footer line (printed earlier than the per-plugin block), so an unscoped Assert-Has there would
    still pass even if the PER-PLUGIN "marketplace clone" line wrongly printed 'HEAD' instead of
    'sha' -- the footer alone would satisfy it. The scoped pair bounds the slice to that one line
    (from "marketplace clone" to the next "verdict"), so the needle -- or its absence -- can only be
    found where it is supposed to be.

    Dependency-free (no Pester), same style as check-report-lib.tests.ps1 / adopt-workflow-folder.tests.ps1.
    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\task\plugin-versions.ps1'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) "plugin-versions-test-$PID"
$Utf8     = New-Object System.Text.UTF8Encoding $false

. (Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1')

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
    param([object]$Run, [string]$Needle, [string]$Label)
    Assert-True ($Run.Squish.Contains(($Needle -replace '\s', ''))) $Label
}
function Assert-Lacks {
    param([object]$Run, [string]$Needle, [string]$Label)
    Assert-True (-not $Run.Squish.Contains(($Needle -replace '\s', ''))) $Label
}
function Get-TextBetween {
    # The raw (unsquished) slice of $Run.Text from the first occurrence of $StartMarker up to the
    # next occurrence of $EndMarker (or to the end of the text if $EndMarker is not found after it).
    # $null when $StartMarker itself is not found, so callers can fail loudly on a bad scope rather
    # than silently searching the whole output.
    param([object]$Run, [string]$StartMarker, [string]$EndMarker)
    $s = $Run.Text.IndexOf($StartMarker)
    if ($s -lt 0) { return $null }
    $e = $Run.Text.IndexOf($EndMarker, $s + $StartMarker.Length)
    if ($e -lt 0) { return $Run.Text.Substring($s) }
    return $Run.Text.Substring($s, $e - $s)
}
function Assert-HasBetween {
    # Scoped version of Assert-Has: the needle must appear within the slice from $StartMarker up to
    # the next $EndMarker, not merely anywhere in the whole run's output. Use this where another part
    # of the output (the summary, the per-clone footer, the verdict line) can contain the same words
    # as the one line under test, so an unscoped Contains() would still pass even if that specific
    # line were wrong.
    param([object]$Run, [string]$StartMarker, [string]$EndMarker, [string]$Needle, [string]$Label)
    $slice = Get-TextBetween -Run $Run -StartMarker $StartMarker -EndMarker $EndMarker
    if ($null -eq $slice) {
        $script:fail++
        Write-Host "  [FAIL] $Label`n         marker not found in output: '$StartMarker'" -ForegroundColor Red
        return
    }
    Assert-True (($slice -replace '\s', '').Contains(($Needle -replace '\s', ''))) $Label
}
function Assert-LacksBetween {
    # The negation of Assert-HasBetween.
    param([object]$Run, [string]$StartMarker, [string]$EndMarker, [string]$Needle, [string]$Label)
    $slice = Get-TextBetween -Run $Run -StartMarker $StartMarker -EndMarker $EndMarker
    if ($null -eq $slice) {
        $script:fail++
        Write-Host "  [FAIL] $Label`n         marker not found in output: '$StartMarker'" -ForegroundColor Red
        return
    }
    Assert-True (-not (($slice -replace '\s', '').Contains(($Needle -replace '\s', '')))) $Label
}

# --- fixture builders -------------------------------------------------------------------------------

function Git-X {
    # git under EAP=Continue -- the #107 pitfall guard, the same one shared-scripts.tests.ps1 uses
    # around its own fixture git calls. scripts/tests/ is out of the unprotected-redirect scan, but the
    # runtime hazard (native stderr promoted to a terminating error under EAP=Stop) is real regardless.
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

function Get-CloneGitExitCode {
    # Fixture-side sanity checks (12/13) need the EXIT CODE of a git call in the fixture clone --
    # e.g. does 'rev-parse -q --verify' resolve the orphaned commit at all -- not just its output, so
    # this goes through the already dot-sourced Invoke-NativeCapture rather than Git-X above (which
    # only hands back trimmed text). Distinct name from the script-under-test's own Invoke-CloneGit,
    # deliberately: this is the TEST's fixture helper, not a stand-in for the script's function.
    param([Parameter(Mandatory = $true)][string]$Dir, [Parameter(Mandatory = $true)][string[]]$GitArgs)
    return (Invoke-NativeCapture -FilePath 'git' -Arguments (@('-C', $Dir) + $GitArgs) -DiscardStderr).ExitCode
}

function New-Case {
    # A checkout dir (-RootOverride) and a scratch home (-UserHomeOverride) that carries the install
    # administration and the marketplace clone. One '~/.claude' knob drives all three reads.
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
    # A marketplace clone at $Dir: .claude-plugin/marketplace.json + one plugin.json per name, and
    # either a real git repo (returns the HEAD sha) or a plain tree with an optional .gcs-sha file.
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [string]$Version = '4.32.0',
        [string[]]$PluginNames = @('dkj-team-alpha'),
        [switch]$NoGit,
        [string]$GcsSha = ''
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

    if ($NoGit) {
        if ($GcsSha) { [System.IO.File]::WriteAllText((Join-Path $Dir '.gcs-sha'), $GcsSha, $Utf8) }
        return ''
    }
    Git-X $Dir @('init', '--quiet') | Out-Null
    Git-X $Dir @('config', 'user.email', 'tycho@test.local') | Out-Null
    Git-X $Dir @('config', 'user.name', 'Tycho Test') | Out-Null
    Git-X $Dir @('config', 'commit.gpgsign', 'false') | Out-Null
    Git-X $Dir @('add', '-A') | Out-Null
    Git-X $Dir @('commit', '--quiet', '-m', 'clone c1') | Out-Null
    return (Git-X $Dir @('rev-parse', 'HEAD'))
}

function Add-CloneCommit {
    param([string]$Dir)
    [System.IO.File]::WriteAllText((Join-Path $Dir 'marker.txt'), [guid]::NewGuid().ToString(), $Utf8)
    Git-X $Dir @('add', '-A') | Out-Null
    Git-X $Dir @('commit', '--quiet', '-m', 'clone c2') | Out-Null
    return (Git-X $Dir @('rev-parse', 'HEAD'))
}

function New-DivergedClone {
    # A clone whose HEAD has moved through a history rewrite: the returned sha exists as a real git
    # object in the clone (rev-parse -q --verify resolves it) but is reachable from NEITHER HEAD nor
    # an ancestor of it -- exactly the state a rebase or force-push in the marketplace clone leaves
    # behind while the old object has not yet been garbage-collected. Built by committing once past
    # a shared base, resetting the clone back to that base (the commit is now an orphan, unreachable
    # from the branch, but still a loose object), then committing again down a DIFFERENT line so the
    # clone ends up with a real HEAD that never passed through the returned sha.
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [string]$Version = '4.32.0',
        [string[]]$PluginNames = @('dkj-team-alpha')
    )
    New-Clone -Dir $Dir -Version $Version -PluginNames $PluginNames | Out-Null
    $base = Git-X $Dir @('rev-parse', 'HEAD')
    $diverged = Add-CloneCommit -Dir $Dir
    Git-X $Dir @('reset', '--hard', $base) | Out-Null
    Add-CloneCommit -Dir $Dir | Out-Null
    return $diverged
}

function New-Rec {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [string]$Version = '4.32.0',
        [string]$Sha = '',
        [string]$Scope = 'project'
    )
    $h = @{ scope = $Scope; projectPath = $ProjectPath; version = $Version }
    if ($Sha) { $h['gitCommitSha'] = $Sha }
    return $h
}

function Write-Admin {
    # installed_plugins.json: { version, plugins: { "<id>": [ <record>, ... ] } }
    param([string]$Path, [hashtable]$Plugins)
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [System.IO.File]::WriteAllText($Path, (@{ version = 2; plugins = $Plugins } | ConvertTo-Json -Depth 12), $Utf8)
}

function Invoke-PV {
    param([Parameter(Mandatory = $true)][string]$Repo, [Parameter(Mandatory = $true)][string]$UserHome, [switch]$Brief)
    # CLAUDE_PROJECT_DIR is pinned to the fixture checkout so the source-repo guard resolves a
    # deterministic root (a dir with no .claude-plugin/marketplace.json -> condition 2 fails -> the
    # guard returns nothing) instead of depending on the ambient env or `git rev-parse`. -RootOverride
    # still wins inside the script itself.
    $prev = $env:CLAUDE_PROJECT_DIR
    $env:CLAUDE_PROJECT_DIR = $Repo
    try {
        $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Script,
               '-RootOverride', $Repo, '-UserHomeOverride', $UserHome)
        if ($Brief) { $a += '-Brief' }
        $run = Invoke-NativeCapture -FilePath 'powershell' -Arguments $a -Utf8
        $joined = ($run.Output | ForEach-Object { "$_" }) -join "`n"
        return [pscustomobject]@{
            Code   = $run.ExitCode
            Text   = $joined
            Squish = ($joined -replace '\s', '')
        }
    } finally {
        if ($null -eq $prev) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prev }
    }
}

$ID  = 'dkj-team-alpha@ccs-fixture'
$UPD = 'claude plugin update dkj-team-alpha@ccs-fixture --scope project'
$MKT = 'claude plugin marketplace update ccs-fixture'

try {
    Write-Host "== plugin-versions.tests: scripts/task/plugin-versions.ps1 ==" -ForegroundColor Cyan
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null

    Assert-True (Test-Path -LiteralPath $Script -PathType Leaf) 'plugin-versions.ps1 exists at its canonical path'

    # --- 1. Happy path: install sha == clone HEAD, versions agree --------------------------------------
    Write-Host "1. up to date -- install sha == clone HEAD" -ForegroundColor Cyan
    $c = New-Case 'happy'
    $head = New-Clone -Dir $c.Clone -Version '4.32.0'
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $head) ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '1: exit 0'
    Assert-Has  $r 'dkj-team-alpha@ccs-fixture' '1: the plugin id heads its block'
    Assert-Has  $r 'up to date -- your install is at the clone''s HEAD' '1: verdict is "up to date"'
    Assert-Has  $r 'All 1 plugin(s) up to date on 4.32.0' '1: summary says every plugin is current'
    Assert-Has  $r $MKT '1: the action names the clone-refresh command (currency is unprovable from here)'
    Assert-Lacks $r 'cannot determine' '1: nothing is indeterminate'
    Assert-Lacks $r $UPD '1: no per-plugin update is advised'

    # --- 2. Clone ahead by commit: same version string, HEAD is a child of the installed sha ----------
    Write-Host "2. clone ahead by commit -> per-plugin update" -ForegroundColor Cyan
    $c = New-Case 'ahead-commit'
    $shaA = New-Clone -Dir $c.Clone -Version '4.32.0'
    $shaB = Add-CloneCommit -Dir $c.Clone
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $shaA) ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '2: exit 0'
    Assert-True ($shaA -ne $shaB) '2: fixture sanity -- the clone really advanced a commit'
    Assert-Has  $r 'the clone is AHEAD of your install' '2: verdict says the clone is ahead'
    Assert-Has  $r 'same version string 4.32.0' '2: and that the version string is unchanged'
    Assert-Has  $r $UPD '2: the action is the per-plugin update command'
    Assert-Has  $r '1 of 1 plugin(s) behind' '2: the summary counts it as behind'
    Assert-Lacks $r 'up to date' '2: it is not reported as current'

    # --- 3. Clone ahead by version: no sha on the install side, installed version < clone version -----
    Write-Host "3. clone ahead by version -> per-plugin update" -ForegroundColor Cyan
    $c = New-Case 'ahead-version'
    New-Clone -Dir $c.Clone -Version '4.33.0' | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '3: exit 0'
    Assert-Has  $r 'the clone is AHEAD of your install (4.32.0 -> 4.33.0)' '3: verdict names both versions'
    Assert-Has  $r $UPD '3: the action is the per-plugin update command'
    Assert-Has  $r '1 of 1 plugin(s) behind' '3: the summary counts it as behind'

    # --- 4. Installed sha is NOT in the clone's history -> refresh the clone --------------------------
    Write-Host "4. installed sha not in clone history -> marketplace refresh" -ForegroundColor Cyan
    $c = New-Case 'not-in-history'
    New-Clone -Dir $c.Clone -Version '4.32.0' | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @(
        (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha '1234567890abcdef1234567890abcdef12345678') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '4: exit 0'
    Assert-Has  $r "is not in the clone's history" '4: verdict says the recorded commit is unknown to the clone'
    Assert-Has  $r $MKT '4: the action is the marketplace-refresh command'
    Assert-Lacks $r $UPD '4: a per-plugin update is NOT advised here'
    Assert-Has  $r '1 of 1 plugin(s) behind' '4: the summary counts it as behind'

    # --- 5. Plugin enabled but no install record for this checkout -----------------------------------
    Write-Host "5. enabled declaratively only -> the no-record row, no crash" -ForegroundColor Cyan
    $c = New-Case 'declared-only'
    New-Clone -Dir $c.Clone -Version '4.32.0' | Out-Null
    $elsewhere = Join-Path $c.Home 'some-other-checkout'
    New-Item -ItemType Directory -Path $elsewhere -Force | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $elsewhere -Version '4.32.0') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '5: exit 0'
    Assert-Has  $r 'no install record in this checkout (enabled declaratively only)' '5: the installed-here line names the state'
    Assert-Has  $r 'cannot determine -- not installed in this checkout (enabled declaratively only)' '5: and the verdict does too'
    Assert-Has  $r 'claude plugin install dkj-team-alpha@ccs-fixture --scope project' '5: the action offers the install command'
    Assert-Lacks $r 'Exception' '5: no unhandled exception text leaked'

    # --- 6. No marketplace clone at all ------------------------------------------------------------
    Write-Host "6. no marketplace clone -> cannot determine, exit 0, no throw" -ForegroundColor Cyan
    $c = New-Case 'no-clone'
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha 'abc123') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '6: exit 0 -- a missing clone is an ordinary consumer state'
    Assert-Has  $r 'no marketplace clone at' '6: the clone line says the directory is absent'
    Assert-Has  $r 'cannot determine -- no marketplace clone to compare against' '6: the verdict says so'
    Assert-Has  $r 'none confirmed up to date and none confirmed behind' '6: the summary is the indeterminate sentence'
    Assert-Lacks $r 'Exception' '6: nothing threw'

    # --- 7. Two conflicting install records for one id+path --------------------------------------------
    Write-Host "7. conflicting install records -> withheld comparison, no crash" -ForegroundColor Cyan
    $c = New-Case 'conflicting'
    New-Clone -Dir $c.Clone -Version '4.32.0' | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @(
        (New-Rec -ProjectPath $c.Repo -Version '4.32.0'),
        (New-Rec -ProjectPath $c.Repo -Version '4.31.0') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '7: exit 0'
    Assert-Has  $r '2 CONFLICTING records for this checkout' '7: the installed-here line reports the conflict'
    Assert-Has  $r 'cannot determine -- this checkout has 2 conflicting install records' '7: the verdict withholds the comparison'
    Assert-Has  $r 'repair: claude plugin install dkj-team-alpha@ccs-fixture --scope project' '7: the action offers the repair install'
    Assert-Lacks $r 'Exception' '7: no crash on the multi-record shape'

    # --- 8a. Non-git clone: HEAD read from .gcs-sha, and it matches the install sha -------------------
    Write-Host "8a. non-git clone -> HEAD comes from .gcs-sha (matches -> up to date)" -ForegroundColor Cyan
    $gcs = 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2'
    $c = New-Case 'gcs-match'
    New-Clone -Dir $c.Clone -Version '4.32.0' -NoGit -GcsSha $gcs | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $gcs) ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '8a: exit 0'
    Assert-Has  $r 'non-git fetch' '8a: the clone line marks it as a non-git fetch'
    Assert-Has  $r 'sha a1b2c3d4e5f6' '8a: the short sha printed is the one from .gcs-sha'
    # Scoped: 'sha a1b2c3d4e5f6' also appears verbatim in the per-clone FOOTER line (printed earlier,
    # before this plugin's own block), so the unscoped Assert-Has above would still pass even if the
    # PER-PLUGIN "marketplace clone" line wrongly printed 'HEAD' instead of 'sha'. Bound the slice to
    # that one line (from "marketplace clone" to the next "verdict") so the needle can only be found
    # where it is supposed to be.
    Assert-HasBetween  $r 'marketplace clone' 'verdict' 'sha a1b2c3d4e5f6' '8a: the PER-PLUGIN line itself (not just the footer) says "sha", scoped to that line'
    Assert-LacksBetween $r 'marketplace clone' 'verdict' 'HEAD' '8a: and that same line never says "HEAD" for a non-git clone'
    Assert-Has  $r 'up to date -- your install is at the clone''s HEAD' '8a: matching that sha yields "up to date"'
    Assert-Has  $r 'All 1 plugin(s) up to date on 4.32.0' '8a: and the summary agrees'

    # --- 8b. Non-git clone: shas differ -> version-only fallback, history cannot confirm direction ----
    Write-Host "8b. non-git clone -> version fallback when the shas differ" -ForegroundColor Cyan
    $c = New-Case 'gcs-fallback'
    New-Clone -Dir $c.Clone -Version '4.33.0' -NoGit -GcsSha $gcs | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @(
        (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha '9999999999999999999999999999999999999999') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '8b: exit 0'
    Assert-Has  $r 'non-git fetch so the commit history cannot confirm direction' '8b: verdict flags the non-git fallback'
    Assert-Has  $r $UPD '8b: and still advises the per-plugin update (version is behind)'

    # --- 9. A foreign plugin id that the clone's marketplace.json does not list ----------------------
    Write-Host "9. foreign plugin id -> cannot determine, no error" -ForegroundColor Cyan
    $c = New-Case 'foreign'
    New-Clone -Dir $c.Clone -Version '4.32.0' -PluginNames @('dkj-team-alpha') | Out-Null
    $foreign = 'foreign-thing@ccs-fixture'
    Set-Enabled -RepoDir $c.Repo -Ids @($foreign)
    Write-Admin -Path $c.Admin -Plugins @{ $foreign = @( (New-Rec -ProjectPath $c.Repo -Version '9.9.9' -Sha 'beefbeef') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '9: exit 0'
    Assert-Has  $r "cannot determine -- 'foreign-thing' is not in the clone's marketplace.json" '9: the verdict names the missing plugin'
    Assert-Has  $r 'could not be determined' '9: the summary rolls it up as indeterminate'
    Assert-Lacks $r 'Exception' '9: a foreign id does not throw'

    # --- 10. No plugins enabled -----------------------------------------------------------------------
    Write-Host "10. no plugins enabled -> a sentence, exit 0" -ForegroundColor Cyan
    $c = New-Case 'none-enabled'
    Set-Enabled -RepoDir $c.Repo -Ids @()
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '10: exit 0'
    Assert-Has  $r 'No plugins are enabled for this checkout.' '10: it says there is nothing to compare'

    # --- 11. projectPath separator / trailing-slash insensitivity -----------------------------------
    Write-Host "11. projectPath separator + trailing slash still match" -ForegroundColor Cyan
    $c = New-Case 'sep-fwd'
    $head = New-Clone -Dir $c.Clone -Version '4.32.0'
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @(
        (New-Rec -ProjectPath ($c.Repo -replace '\\', '/') -Version '4.32.0' -Sha $head) ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '11: exit 0'
    Assert-Has  $r 'up to date -- your install is at the clone''s HEAD' '11: a forward-slash projectPath still matches this checkout'
    Assert-Lacks $r 'no install record in this checkout' '11: it is not misread as "no record"'
    Assert-Lacks $r 'enabled declaratively only' '11: nor as "declared only"'

    $c = New-Case 'sep-trail'
    $head = New-Clone -Dir $c.Clone -Version '4.32.0'
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @(
        (New-Rec -ProjectPath ($c.Repo + '\') -Version '4.32.0' -Sha $head) ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '11b: exit 0'
    Assert-Has  $r 'up to date -- your install is at the clone''s HEAD' '11b: a trailing-separator projectPath still matches'

    # --- 12. Reachable in the clone, NOT an ancestor of HEAD -- version strings say clone IS ahead ----
    # existsInClone = $true, isAncestor = $false. Before the pre-PR repair the script concluded
    # unconditionally here "your install is AHEAD -- the clone is stale" (a marketplace-refresh
    # verdict); it now consults Compare-Version first, exactly like its -not $existsInClone sibling
    # branch. This scenario pins the direction where that consultation matters: the clone's version
    # really is newer, so the correct verdict points at the PER-PLUGIN update, not a refresh.
    Write-Host "12. reachable-not-ancestor (history rewrite), version says clone IS ahead -> per-plugin update" -ForegroundColor Cyan
    $c = New-Case 'diverged-clone-ahead'
    $orphanSha = New-DivergedClone -Dir $c.Clone -Version '4.33.0'
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $orphanSha) ) }
    $verify = Get-CloneGitExitCode -Dir $c.Clone -GitArgs @('rev-parse', '-q', '--verify', "$orphanSha^{commit}")
    $isAnc = Get-CloneGitExitCode -Dir $c.Clone -GitArgs @('merge-base', '--is-ancestor', $orphanSha, 'HEAD')
    Assert-Equal 0 $verify '12: fixture sanity -- the orphaned commit is still a resolvable object in the clone'
    Assert-True ($isAnc -ne 0) '12: fixture sanity -- and it is NOT an ancestor of the clone''s (rewritten) HEAD'
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '12: exit 0'
    Assert-Has  $r 'the clone is AHEAD of your install (4.32.0 -> 4.33.0)' '12: verdict says the clone is genuinely ahead, by version'
    Assert-Has  $r 'history rewrite?' '12: verdict names the mechanism (a rewrite in the clone''s history)'
    Assert-Has  $r $UPD '12: the action is the PER-PLUGIN update command, not a marketplace refresh'
    Assert-Lacks $r $MKT '12: a marketplace refresh is NOT advised here'
    Assert-Has  $r '1 of 1 plugin(s) behind' '12: the summary counts it as behind'

    # --- 13. Same reachable-not-ancestor shape, but the versions do NOT say the clone is ahead -------
    # Same existsInClone/isAncestor shape as 12, opposite version relationship: here the stale-clone
    # verdict (marketplace refresh) is the CORRECT one, and must stay that way.
    Write-Host "13. reachable-not-ancestor (history rewrite), version does NOT say clone is ahead -> stale clone, refresh" -ForegroundColor Cyan
    $c = New-Case 'diverged-clone-stale'
    $orphanSha = New-DivergedClone -Dir $c.Clone -Version '4.32.0'
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $orphanSha) ) }
    $verify = Get-CloneGitExitCode -Dir $c.Clone -GitArgs @('rev-parse', '-q', '--verify', "$orphanSha^{commit}")
    $isAnc = Get-CloneGitExitCode -Dir $c.Clone -GitArgs @('merge-base', '--is-ancestor', $orphanSha, 'HEAD')
    Assert-Equal 0 $verify '13: fixture sanity -- the orphaned commit is still a resolvable object in the clone'
    Assert-True ($isAnc -ne 0) '13: fixture sanity -- and it is NOT an ancestor of the clone''s (rewritten) HEAD'
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '13: exit 0'
    Assert-Has  $r 'your install is AHEAD of the clone -- the clone is stale' '13: verdict says the clone is stale (equal version strings do not overrule it)'
    Assert-Has  $r $MKT '13: the action is the marketplace-refresh command'
    Assert-Lacks $r $UPD '13: a per-plugin update is NOT advised here'
    Assert-Has  $r '1 of 1 plugin(s) behind' '13: the summary counts it as behind'

    # --- 14. A malformed gitCommitSha in the install record degrades to the version comparison --------
    # Get-ValidatedSha rejects anything that is not 7-40 hex characters. A record carrying something
    # else (corruption, a future format change) must fall through to the version-only comparison
    # exactly like "no sha recorded at all" (scenario 3) -- never be handed to git.
    Write-Host "14. malformed gitCommitSha -> degrades to version comparison, never reaches git" -ForegroundColor Cyan
    $c = New-Case 'malformed-sha'
    New-Clone -Dir $c.Clone -Version '4.33.0' | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @(
        (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha 'not-a-valid-sha!!') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '14: exit 0 -- a malformed sha does not crash the script'
    Assert-Has  $r 'the clone is AHEAD of your install (4.32.0 -> 4.33.0)' '14: verdict is the same as the no-sha version-comparison case (scenario 3)'
    Assert-Has  $r $UPD '14: the action is the per-plugin update command'
    Assert-Lacks $r 'not-a-valid-sha' '14: the malformed sha itself is never echoed back'
    Assert-Lacks $r 'Exception' '14: no unhandled exception text leaked'
    # --- 15. Asymmetric gap (a): version but no sha on the install side, HEAD but no readable ---------
    # -- plugin.json version on the clone side. NEITHER side is fully empty, so the pre-fix per-SIDE
    # test ("-not $instSha -and -not $instVer" / "-not $clone.Head -and -not $cloneVer") never fires on
    # either line, and the catch-all verdict used to print a bare "cannot determine -- " with the
    # reason missing -- the Code and the summary tally stayed right throughout, which is why nothing
    # else surfaced it. This is the exact defect Victor found on pickup of that branch; the fix names
    # the missing fields per FIELD instead of per side.
    Write-Host "15. asymmetric gap (a): version/no-sha vs HEAD/no-version -> reason is named, not blank" -ForegroundColor Cyan
    $c = New-Case 'gap-a'
    New-Clone -Dir $c.Clone -Version '' | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '15: exit 0'
    Assert-True (-not ($r.Text -match 'cannot determine --[ \t]*\r?\n')) '15: the regression itself -- the verdict is never a bare "cannot determine --" with the reason missing'
    Assert-Has  $r 'no commit sha in the install record' '15: names the missing sha on the install side'
    Assert-Has  $r "no version in the clone's plugin.json" '15: names the missing version on the clone side'
    Assert-Has  $r '-- 1 could not be determined' '15: still counted as indeterminate in the summary tally'

    # --- 16. Asymmetric gap (b): the symmetric flip -- sha but no version on the install side, ---------
    # -- version but no HEAD/.gcs-sha on the clone side (a non-git fetch missing its sha file). Same
    # defect, opposite side: a per-side test that only ever fires on one side's both-empty state leaves
    # this state silent too.
    Write-Host "16. asymmetric gap (b): sha/no-version vs version/no-HEAD -> reason is named, not blank" -ForegroundColor Cyan
    $c = New-Case 'gap-b'
    New-Clone -Dir $c.Clone -Version '4.33.0' -NoGit | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @(
        (New-Rec -ProjectPath $c.Repo -Version '' -Sha 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    Assert-Equal 0 $r.Code '16: exit 0'
    Assert-True (-not ($r.Text -match 'cannot determine --[ \t]*\r?\n')) '16: the regression itself -- the verdict is never a bare "cannot determine --" with the reason missing'
    Assert-Has  $r 'no version in the install record' '16: names the missing version on the install side'
    Assert-Has  $r 'no HEAD or sha on the clone side' '16: names the missing HEAD/sha on the clone side'
    Assert-Has  $r '-- 1 could not be determined' '16: still counted as indeterminate in the summary tally'

    # --- 17. -Brief: a 'behind' verdict -> "[ERROR] <id>: <verdict> -- <action>" ---------------------
    Write-Host "17. -Brief: 'behind' -> [ERROR] with the action appended" -ForegroundColor Cyan
    $c = New-Case 'brief-behind'
    $shaA = New-Clone -Dir $c.Clone -Version '4.32.0'
    $shaB = Add-CloneCommit -Dir $c.Clone
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $shaA) ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home -Brief
    Assert-Equal 0 $r.Code '17: exit 0'
    Assert-Equal (
        "[ERROR] ${ID}: the clone is AHEAD of your install (same version string 4.32.0, newer commit) -- $UPD`n" +
        "[SUMMARY] 1 plugin(s) enabled here: 1 behind, 0 up to date."
    ) $r.Text.Trim() '17: the whole run is the marker line plus the summary, verbatim'

    # --- 18. -Brief: a 'clone-behind' verdict (stale clone) -> "[INFO]", NEVER "[ERROR]" -------------
    # THE REGRESSION #1591 NAMES EXPLICITLY: a stale clone is not an error. If this code is ever
    # promoted to [ERROR], this assert is the one that must fail.
    Write-Host "18. -Brief: 'clone-behind' -> [INFO], never [ERROR]" -ForegroundColor Cyan
    $c = New-Case 'brief-clonebehind'
    New-Clone -Dir $c.Clone -Version '4.32.0' | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @(
        (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home -Brief
    Assert-Equal 0 $r.Code '18: exit 0'
    Assert-Has   $r "[INFO] $($ID): your install (deadbeefdead) is not in the clone's history" '18: reported as [INFO]'
    Assert-Lacks $r '[ERROR]' '18: never promoted to [ERROR] -- the #1591 regression guard'
    Assert-Has   $r '[SUMMARY] 1 plugin(s) enabled here: 0 behind, 1 ahead of a stale clone, 0 up to date.' '18: the summary counts it as a stale clone, not as behind'

    # --- 19. -Brief: an 'indeterminate' verdict (foreign plugin) -> "[INFO]", NEVER "[ERROR]" --------
    Write-Host "19. -Brief: 'indeterminate' (foreign plugin) -> [INFO], never [ERROR]" -ForegroundColor Cyan
    $c = New-Case 'brief-indeterminate'
    New-Clone -Dir $c.Clone -Version '4.32.0' -PluginNames @('dkj-team-alpha') | Out-Null
    $foreign = 'foreign-thing@ccs-fixture'
    Set-Enabled -RepoDir $c.Repo -Ids @($foreign)
    Write-Admin -Path $c.Admin -Plugins @{ $foreign = @( (New-Rec -ProjectPath $c.Repo -Version '9.9.9' -Sha 'beefbeef') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home -Brief
    Assert-Equal 0 $r.Code '19: exit 0'
    Assert-Has   $r "[INFO] $($foreign): cannot determine -- 'foreign-thing' is not in the clone's marketplace.json" '19: reported as [INFO]'
    Assert-Lacks $r '[ERROR]' '19: never promoted to [ERROR]'
    Assert-Has   $r '[SUMMARY] 1 plugin(s) enabled here: 0 behind, 1 undetermined, 0 up to date.' '19: the summary counts it as undetermined'

    # --- 17. -Brief: 'match' / 'ver-match' -> nothing printed for that plugin ------------------------
    # With one plugin enabled, "nothing printed for that plugin" means the ENTIRE run is the
    # [SUMMARY] line -- the strongest form of "emits nothing" this suite can pin.
    Write-Host "20a. -Brief: 'match' -> the whole run is just the [SUMMARY] line" -ForegroundColor Cyan
    $c = New-Case 'brief-match'
    $head = New-Clone -Dir $c.Clone -Version '4.32.0'
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $head) ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home -Brief
    Assert-Equal 0 $r.Code '20a: exit 0'
    Assert-Equal '[SUMMARY] 1 plugin(s) enabled here: 0 behind, 1 up to date.' $r.Text.Trim() '20a: match emits nothing but the summary'

    Write-Host "20b. -Brief: 'ver-match' -> the whole run is just the [SUMMARY] line, identically" -ForegroundColor Cyan
    $c = New-Case 'brief-vermatch'
    New-Clone -Dir $c.Clone -Version '4.32.0' | Out-Null
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0') ) }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home -Brief
    Assert-Equal 0 $r.Code '20b: exit 0'
    Assert-Equal '[SUMMARY] 1 plugin(s) enabled here: 0 behind, 1 up to date.' $r.Text.Trim() '20b: ver-match emits nothing but the summary -- indistinguishable from match, by contract'

    # --- 21. -Brief: no plugins enabled -> a single [INFO] line, no [SUMMARY], exit 0 -----------------
    Write-Host "21. -Brief: no plugins enabled -> one [INFO] line, no [SUMMARY]" -ForegroundColor Cyan
    $c = New-Case 'brief-none-enabled'
    Set-Enabled -RepoDir $c.Repo -Ids @()
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home -Brief
    Assert-Equal 0 $r.Code '21: exit 0'
    Assert-Equal '[INFO] no plugins are enabled for this checkout -- nothing to compare.' $r.Text.Trim() '21: exactly one INFO line and nothing else -- no [SUMMARY] when there is nothing to summarize'

    # --- 22. -Brief: one run mixing every code -> exactly one [SUMMARY] line partitioning all rows ---
    Write-Host "22. -Brief: a mix of every code -> one [SUMMARY] line, correctly partitioned" -ForegroundColor Cyan
    $c = New-Case 'brief-mixed'
    $mixNames = @('plug-behind', 'plug-clonebehind', 'plug-match', 'plug-vermatch')
    $shaA = New-Clone -Dir $c.Clone -Version '4.32.0' -PluginNames $mixNames
    $shaB = Add-CloneCommit -Dir $c.Clone
    $foreignMix = 'plug-foreign@ccs-fixture'
    $ids = @('plug-behind@ccs-fixture', 'plug-clonebehind@ccs-fixture', $foreignMix, 'plug-match@ccs-fixture', 'plug-vermatch@ccs-fixture')
    Set-Enabled -RepoDir $c.Repo -Ids $ids
    Write-Admin -Path $c.Admin -Plugins @{
        'plug-behind@ccs-fixture'      = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $shaA) )
        'plug-clonebehind@ccs-fixture' = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef') )
        $foreignMix                    = @( (New-Rec -ProjectPath $c.Repo -Version '9.9.9' -Sha 'beefbeef') )
        'plug-match@ccs-fixture'       = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $shaB) )
        'plug-vermatch@ccs-fixture'    = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0') )
    }
    $r = Invoke-PV -Repo $c.Repo -UserHome $c.Home -Brief
    Assert-Equal 0 $r.Code '22: exit 0'
    $lines = @($r.Text -split "`n" | ForEach-Object { $_.TrimEnd("`r") })
    $errLines = @($lines | Where-Object { $_ -match '^\[ERROR\]' })
    $infoLines = @($lines | Where-Object { $_ -match '^\[INFO\]' })
    $summaryLines = @($lines | Where-Object { $_ -match '^\[SUMMARY\]' })
    Assert-Equal 1 $errLines.Count '22: exactly one [ERROR] line (only the behind plugin)'
    Assert-True  ($errLines[0] -like "*plug-behind@ccs-fixture*") '22: the [ERROR] line names the behind plugin'
    Assert-Equal 2 $infoLines.Count '22: exactly two [INFO] lines (the stale clone + the foreign plugin)'
    Assert-True  (($infoLines -join '|') -like '*plug-clonebehind@ccs-fixture*') '22: one [INFO] line is the stale-clone plugin'
    Assert-True  (($infoLines -join '|') -like '*plug-foreign@ccs-fixture*') '22: the other [INFO] line is the foreign plugin'
    Assert-Equal 1 $summaryLines.Count '22: exactly one [SUMMARY] line for the whole run'
    Assert-Equal '[SUMMARY] 5 plugin(s) enabled here: 1 behind, 1 ahead of a stale clone, 1 undetermined, 2 up to date.' $summaryLines[0] '22: the summary partitions all five rows correctly'
    Assert-Lacks $r 'plug-match@ccs-fixture:'    '22: the match plugin gets no marker line of its own'
    Assert-Lacks $r 'plug-vermatch@ccs-fixture:' '22: the ver-match plugin gets no marker line of its own'

    # --- 23. -Brief suppresses the header; the default view keeps it, unaffected --------------------
    Write-Host "23. -Brief has no header; the default (no -Brief) view is unchanged" -ForegroundColor Cyan
    $c = New-Case 'brief-header'
    $head = New-Clone -Dir $c.Clone -Version '4.32.0'
    Set-Enabled -RepoDir $c.Repo -Ids @($ID)
    Write-Admin -Path $c.Admin -Plugins @{ $ID = @( (New-Rec -ProjectPath $c.Repo -Version '4.32.0' -Sha $head) ) }
    $rDefault = Invoke-PV -Repo $c.Repo -UserHome $c.Home
    $rBrief   = Invoke-PV -Repo $c.Repo -UserHome $c.Home -Brief
    Assert-Equal 0 $rDefault.Code '23: default view exit 0'
    Assert-Equal 0 $rBrief.Code   '23: brief view exit 0'
    Assert-Has   $rDefault "plugin-versions -- $($c.Repo)" '23: the default view still prints its header (unchanged)'
    Assert-Lacks $rDefault '[SUMMARY]' '23: the default view never emits the brief marker vocabulary'
    Assert-Lacks $rBrief   'plugin-versions--'  '23: -Brief never prints the header line (an absolute path stays out of a session start)'
    Assert-Has   $rBrief   '[SUMMARY]' '23: -Brief still emits its own summary'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
