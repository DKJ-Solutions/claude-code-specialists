<#
.SYNOPSIS
    Regression tests for scripts/release/publish-to-business.ps1 (marketplace -> business repo).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell and git. The whole suite runs against a
    FIXTURE: a minimal source repo built in a temp directory and a local bare repo as the
    publication target (git init --bare) -- no network, no tokens, and nothing in this repo is
    touched. The script under test is run as a child powershell so its throws become exit codes
    instead of killing the suite, exactly as a real caller sees them.

    What is covered, and why each case earns its place:
      1. first publication into an empty target (the fresh-history path: init + symbolic-ref);
      2. idempotence -- a second run against an unchanged source publishes nothing;
      3. a version bump travels as exactly that one change;
      4. a plugin removed from the source (folder AND manifest) disappears from the target,
         because the script deletes before it copies;
      5. the integrity check: a manifest that names a folder that did not travel is a HARD STOP,
         exit 1, and the target's history is untouched;
      6. the seam: without -TargetRepo the target comes from Get-BusinessMarketplaceRepo in the
         source repo's own scripts/repo-config.ps1;
      7. no seam and no -TargetRepo is a refusal, not a guess;
      8. -DryRun commits nothing.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/publish-to-business.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

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

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name (pattern '$Pattern' not found)" -ForegroundColor Red
    }
}

$scriptUnderTest = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\release\publish-to-business.ps1')).Path

# --- fixture helpers -------------------------------------------------------------------------------

function Invoke-FixtureGit {
    <# git in the fixture, with a fixed identity so commits work on any machine. Throws on failure. #>
    param([string]$Dir, [string[]]$GitArgs)
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & git -C $Dir -c user.name=fixture -c user.email=fixture@localhost @GitArgs 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
    if ($code -ne 0) { throw "fixture git $($GitArgs -join ' ') failed: $out" }
    return @($out | ForEach-Object { "$_" })
}

function Invoke-Publish {
    <#
        Runs the script under test as a child powershell (5.1, like the gate runs everything) and
        returns @{ ExitCode; Output } -- a throw in the script is an exit code here, not a suite
        crash.
    #>
    param([string[]]$ScriptArgs)
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptUnderTest @ScriptArgs 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
    return [pscustomobject]@{ ExitCode = $code; Output = (@($out | ForEach-Object { "$_" }) -join "`n") }
}

function New-SourceFixture {
    <# A minimal marketplace source repo: manifest + two plugins + one reader doc, committed. #>
    param([string]$Dir)

    New-Item -ItemType Directory -Path (Join-Path $Dir '.claude-plugin') -Force | Out-Null
    @'
{
    "name": "fixture-marketplace",
    "owner": { "name": "fixture" },
    "plugins": [
        { "name": "alpha", "source": "plugins/alpha" },
        { "name": "beta",  "source": "plugins/beta" }
    ]
}
'@ | Set-Content -LiteralPath (Join-Path $Dir '.claude-plugin\marketplace.json') -Encoding Ascii

    foreach ($p in @(@{ n = 'alpha'; v = '1.0.0' }, @{ n = 'beta'; v = '2.0.0' })) {
        $pdir = Join-Path $Dir "plugins\$($p.n)\.claude-plugin"
        New-Item -ItemType Directory -Path $pdir -Force | Out-Null
        "{ ""name"": ""$($p.n)"", ""version"": ""$($p.v)"" }" |
            Set-Content -LiteralPath (Join-Path $pdir 'plugin.json') -Encoding Ascii
        "# $($p.n) payload" |
            Set-Content -LiteralPath (Join-Path $Dir "plugins\$($p.n)\README.md") -Encoding Ascii
    }

    '# fixture marketplace' | Set-Content -LiteralPath (Join-Path $Dir 'README.md') -Encoding Ascii

    Invoke-FixtureGit -Dir $Dir -GitArgs @('init') | Out-Null
    Invoke-FixtureGit -Dir $Dir -GitArgs @('add', '-A') | Out-Null
    Invoke-FixtureGit -Dir $Dir -GitArgs @('commit', '-m', 'fixture: initial marketplace') | Out-Null
}

function Get-TargetCommitCount {
    <# Commits on main in the bare target; 0 when the branch does not exist yet. #>
    param([string]$BareDir)
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & git --git-dir $BareDir rev-list --count main 2>$null
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
    if ($code -ne 0) { return 0 }
    return [int]("$out".Trim())
}

function Get-TargetTree {
    <# The file list of the target's main tip, repo-relative with forward slashes. #>
    param([string]$BareDir)
    return @(& git --git-dir $BareDir ls-tree -r --name-only main | ForEach-Object { "$_" })
}

# --- the fixture -----------------------------------------------------------------------------------

$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("publish-tests-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
$sourceDir   = Join-Path $fixtureRoot 'source'
$bareDir     = Join-Path $fixtureRoot 'target.git'
$seamBareDir = Join-Path $fixtureRoot 'seam-target.git'

try {
    New-Item -ItemType Directory -Path $sourceDir -Force | Out-Null
    New-SourceFixture -Dir $sourceDir
    Invoke-FixtureGit -Dir $fixtureRoot -GitArgs @('init', '--bare', $bareDir) | Out-Null
    Invoke-FixtureGit -Dir $fixtureRoot -GitArgs @('init', '--bare', $seamBareDir) | Out-Null

    # --- 1. first publication into an empty target -------------------------------------------------
    Write-Host 'publish-to-business: first publication' -ForegroundColor Cyan
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $sourceDir, '-TargetRepo', $bareDir)
    Assert-Equal 0 $r.ExitCode 'first publication exits 0'
    Assert-Equal 1 (Get-TargetCommitCount -BareDir $bareDir) 'first publication is one commit on main'
    $tree = Get-TargetTree -BareDir $bareDir
    Assert-True ($tree -contains '.claude-plugin/marketplace.json') 'the manifest travelled, in the root'
    Assert-True ($tree -contains 'plugins/alpha/.claude-plugin/plugin.json') 'plugin alpha travelled'
    Assert-True ($tree -contains 'plugins/beta/.claude-plugin/plugin.json') 'plugin beta travelled'
    Assert-True ($tree -contains 'README.md') 'the reader doc travelled'
    $subject = (& git --git-dir $bareDir log -1 --format=%s main) -join ''
    Assert-Match $subject 'alpha 1\.0\.0' 'the commit message records the alpha version'
    Assert-Match $subject 'beta 2\.0\.0' 'the commit message records the beta version'

    # --- 2. idempotence: unchanged source publishes nothing ----------------------------------------
    Write-Host 'publish-to-business: second run (idempotence)' -ForegroundColor Cyan
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $sourceDir, '-TargetRepo', $bareDir)
    Assert-Equal 0 $r.ExitCode 'second run exits 0'
    Assert-Match $r.Output 'Nothing to publish' 'second run reports nothing to publish'
    Assert-Equal 1 (Get-TargetCommitCount -BareDir $bareDir) 'second run adds no commit'

    # --- 3. a version bump travels as one change ----------------------------------------------------
    Write-Host 'publish-to-business: version bump' -ForegroundColor Cyan
    '{ "name": "alpha", "version": "1.1.0" }' |
        Set-Content -LiteralPath (Join-Path $sourceDir 'plugins\alpha\.claude-plugin\plugin.json') -Encoding Ascii
    Invoke-FixtureGit -Dir $sourceDir -GitArgs @('commit', '-am', 'fixture: bump alpha') | Out-Null
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $sourceDir, '-TargetRepo', $bareDir)
    Assert-Equal 0 $r.ExitCode 'version bump run exits 0'
    Assert-Equal 2 (Get-TargetCommitCount -BareDir $bareDir) 'version bump is the second commit'
    $changed = @(& git --git-dir $bareDir diff --name-only main~1 main | ForEach-Object { "$_" })
    Assert-Equal 1 $changed.Count 'exactly one file changed'
    Assert-Equal 'plugins/alpha/.claude-plugin/plugin.json' $changed[0] 'and it is the bumped plugin.json'

    # --- 4. -DryRun commits nothing -----------------------------------------------------------------
    Write-Host 'publish-to-business: dry run' -ForegroundColor Cyan
    '# alpha payload, edited' | Set-Content -LiteralPath (Join-Path $sourceDir 'plugins\alpha\README.md') -Encoding Ascii
    Invoke-FixtureGit -Dir $sourceDir -GitArgs @('commit', '-am', 'fixture: edit alpha payload') | Out-Null
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $sourceDir, '-TargetRepo', $bareDir, '-DryRun')
    Assert-Equal 0 $r.ExitCode 'dry run exits 0'
    Assert-Match $r.Output 'Dry run: nothing committed, nothing pushed' 'dry run says so'
    Assert-Equal 2 (Get-TargetCommitCount -BareDir $bareDir) 'dry run adds no commit'

    # --- 5. integrity check: a manifest pointing at a folder that did not travel is a hard stop ----
    Write-Host 'publish-to-business: integrity hard stop' -ForegroundColor Cyan
    Remove-Item -Recurse -Force -LiteralPath (Join-Path $sourceDir 'plugins\beta')
    Invoke-FixtureGit -Dir $sourceDir -GitArgs @('commit', '-am', 'fixture: drop beta folder but not its manifest row') | Out-Null
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $sourceDir, '-TargetRepo', $bareDir)
    Assert-Equal 1 $r.ExitCode 'a manifest row without its folder is exit 1'
    Assert-Match $r.Output "beta.*did not travel" 'the refusal names the plugin and the reason'
    Assert-Equal 2 (Get-TargetCommitCount -BareDir $bareDir) 'nothing was committed on the refusal'

    # --- 6. a deletion travels once the manifest agrees ---------------------------------------------
    Write-Host 'publish-to-business: deletion travels' -ForegroundColor Cyan
    @'
{
    "name": "fixture-marketplace",
    "owner": { "name": "fixture" },
    "plugins": [
        { "name": "alpha", "source": "plugins/alpha" }
    ]
}
'@ | Set-Content -LiteralPath (Join-Path $sourceDir '.claude-plugin\marketplace.json') -Encoding Ascii
    Invoke-FixtureGit -Dir $sourceDir -GitArgs @('commit', '-am', 'fixture: retire beta in the manifest too') | Out-Null
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $sourceDir, '-TargetRepo', $bareDir)
    Assert-Equal 0 $r.ExitCode 'the aligned deletion publishes'
    $tree = Get-TargetTree -BareDir $bareDir
    Assert-True ($tree -notcontains 'plugins/beta/.claude-plugin/plugin.json') 'beta is gone from the target'
    Assert-True ($tree -contains 'plugins/alpha/.claude-plugin/plugin.json') 'alpha is still there'

    # --- 7. the seam: the target comes from Get-BusinessMarketplaceRepo -----------------------------
    Write-Host 'publish-to-business: target from the repo-config seam' -ForegroundColor Cyan
    New-Item -ItemType Directory -Path (Join-Path $sourceDir 'scripts') -Force | Out-Null
    @"
`$script:BusinessMarketplaceRepo = '$($seamBareDir -replace '\\', '\\')'
function Get-BusinessMarketplaceRepo { return `$script:BusinessMarketplaceRepo }
"@ | Set-Content -LiteralPath (Join-Path $sourceDir 'scripts\repo-config.ps1') -Encoding Ascii
    Invoke-FixtureGit -Dir $sourceDir -GitArgs @('add', '-A') | Out-Null
    Invoke-FixtureGit -Dir $sourceDir -GitArgs @('commit', '-m', 'fixture: add repo-config seam') | Out-Null
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $sourceDir)
    Assert-Equal 0 $r.ExitCode 'a run without -TargetRepo exits 0 once the seam answers'
    Assert-Equal 1 (Get-TargetCommitCount -BareDir $seamBareDir) 'and it published to the seam-named target'

    # --- 8. no seam and no -TargetRepo is a refusal --------------------------------------------------
    Write-Host 'publish-to-business: no target is a refusal' -ForegroundColor Cyan
    Remove-Item -LiteralPath (Join-Path $sourceDir 'scripts\repo-config.ps1') -Force
    Invoke-FixtureGit -Dir $sourceDir -GitArgs @('commit', '-am', 'fixture: drop the seam again') | Out-Null
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $sourceDir)
    Assert-Equal 1 $r.ExitCode 'no target anywhere is exit 1'
    Assert-Match $r.Output 'Get-BusinessMarketplaceRepo' 'the refusal names the seam to fill in'
} finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -Recurse -Force -LiteralPath $fixtureRoot -ErrorAction SilentlyContinue
    }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
