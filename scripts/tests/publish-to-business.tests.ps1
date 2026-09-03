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
      8. -DryRun commits nothing;
      9. a malformed manifest is NAMED rather than crashed on (the StrictMode-on-5.1 regression);
     10. the published SUBSET (#683), on a second fixture shaped like the real marketplace:
         no filter publishes everything (back-compat), a filter prunes the tree AND rewrites the
         manifest to match, an emptied kind directory goes whole with its README, a keep-list name
         matching nothing is a hard stop (it would otherwise exclude silently), a non-ASCII
         description survives the manifest rewrite, a description holding a '\u'-shaped Windows path
         round-trips instead of being folded into an invalid escape (#1131), an undeclared plugin
         folder is a hard stop, and the list comes from Get-BusinessMarketplacePlugins when -Plugins
         is not passed.

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
    <# git in the fixture, with a fixed identity and signing off so commits work on any machine --
       commit.gpgsign=false because a machine with signing on but a locked signing agent would
       otherwise fail every fixture commit for a reason unrelated to the script under test (#1287).
       Throws on failure. #>
    param([string]$Dir, [string[]]$GitArgs)
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & git -C $Dir -c user.name=fixture -c user.email=fixture@localhost -c commit.gpgsign=false @GitArgs 2>&1
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

function New-FilterFixture {
    <#
        A marketplace shaped like the real one: plugins/<kind>/<plugin>, with a README on the plugins
        root and on each kind directory. The flat fixture above cannot express the case the subset
        filter is really about -- a kind directory emptied of plugins, whose README then describes
        plugins that are not there.

        One description carries an em dash, written as a code point because this file is pure ASCII by
        repo convention. It is the fixture for the encoding regression: the manifest is the one file
        the script reads AND writes, so a wrong decode on the way in becomes permanent on the way out.

        A SECOND description carries a Windows path whose segment begins 'u' + four hex characters
        (C:\uadded\check.ps1). That is the fixture for the un-escape regression (#1131): the naive
        '\\u([0-9a-fA-F]{4})' fires on the second backslash of the escaped pair and folds '\uadde' into
        one character, so the rewritten manifest no longer parses. It is a description here rather than
        a source because it needs no directory of that name to exercise the same code path -- and a
        description quoting a path is the likelier of the two shapes anyway.
    #>
    param([string]$Dir)

    $emDash = [char]0x2014

    New-Item -ItemType Directory -Path (Join-Path $Dir '.claude-plugin') -Force | Out-Null
    $manifest = @"
{
    "name": "fixture-marketplace",
    "owner": { "name": "fixture" },
    "plugins": [
        { "name": "core",  "source": "./plugins/teams/core",      "description": "the core team $emDash always enabled" },
        { "name": "extra", "source": "./plugins/teams/extra",     "description": "an add-on team -- see C:\\uadded\\check.ps1" },
        { "name": "flow",  "source": "./plugins/workflows/flow",  "description": "a way of working" }
    ]
}
"@
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText((Join-Path $Dir '.claude-plugin\marketplace.json'), $manifest, $utf8NoBom)

    foreach ($p in @(@{ kind = 'teams'; n = 'core' }, @{ kind = 'teams'; n = 'extra' }, @{ kind = 'workflows'; n = 'flow' })) {
        $pdir = Join-Path $Dir "plugins\$($p.kind)\$($p.n)\.claude-plugin"
        New-Item -ItemType Directory -Path $pdir -Force | Out-Null
        "{ ""name"": ""$($p.n)"", ""version"": ""1.0.0"" }" |
            Set-Content -LiteralPath (Join-Path $pdir 'plugin.json') -Encoding Ascii
        "# $($p.n) payload" |
            Set-Content -LiteralPath (Join-Path $Dir "plugins\$($p.kind)\$($p.n)\README.md") -Encoding Ascii
    }

    '# the plugins'   | Set-Content -LiteralPath (Join-Path $Dir 'plugins\README.md') -Encoding Ascii
    '# the teams'     | Set-Content -LiteralPath (Join-Path $Dir 'plugins\teams\README.md') -Encoding Ascii
    '# the workflows' | Set-Content -LiteralPath (Join-Path $Dir 'plugins\workflows\README.md') -Encoding Ascii
    '# fixture'       | Set-Content -LiteralPath (Join-Path $Dir 'README.md') -Encoding Ascii

    Invoke-FixtureGit -Dir $Dir -GitArgs @('init') | Out-Null
    Invoke-FixtureGit -Dir $Dir -GitArgs @('add', '-A') | Out-Null
    Invoke-FixtureGit -Dir $Dir -GitArgs @('commit', '-m', 'fixture: initial kinded marketplace') | Out-Null
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
$sourceDir     = Join-Path $fixtureRoot 'source'
$bareDir       = Join-Path $fixtureRoot 'target.git'
$seamBareDir   = Join-Path $fixtureRoot 'seam-target.git'
$filterDir     = Join-Path $fixtureRoot 'filter-source'
$filterBareDir = Join-Path $fixtureRoot 'filter-target.git'

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

    # --- 9. a malformed manifest is NAMED, not crashed on -------------------------------------------
    #
    # THE 5.1 REGRESSION THIS SUITE EXISTS TO PIN. Under Set-StrictMode -Version Latest a missing
    # property is a TERMINATING error on Windows PowerShell 5.1, so a bare $plugin.source threw before
    # the check that exists to explain it could report anything -- while on 7.4.6, where this script
    # was first tested, the same access is silent. A manual test of "manifest missing a required
    # field" therefore passed on the developer's machine and would have failed on the repo's own
    # convention. Both asserts are about the MESSAGE, because both paths already exit 1.
    Write-Host 'publish-to-business: a malformed manifest is named' -ForegroundColor Cyan
    @'
{
    "name": "fixture-marketplace",
    "owner": { "name": "fixture" },
    "plugins": [
        { "name": "alpha", "source": "plugins/alpha" },
        { "name": "sourceless" }
    ]
}
'@ | Set-Content -LiteralPath (Join-Path $sourceDir '.claude-plugin\marketplace.json') -Encoding Ascii
    Invoke-FixtureGit -Dir $sourceDir -GitArgs @('commit', '-am', 'fixture: an entry with no source') | Out-Null
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $sourceDir, '-TargetRepo', $bareDir)
    Assert-Equal 1 $r.ExitCode 'an entry with no source is exit 1'
    Assert-Match $r.Output 'sourceless: no source' 'the entry with no source is named, not a StrictMode error'
    Assert-True ($r.Output -notmatch 'cannot be found on this object') 'and no raw StrictMode property error reaches the reader'

    @'
{
    "name": "fixture-marketplace",
    "owner": { "name": "fixture" }
}
'@ | Set-Content -LiteralPath (Join-Path $sourceDir '.claude-plugin\marketplace.json') -Encoding Ascii
    Invoke-FixtureGit -Dir $sourceDir -GitArgs @('commit', '-am', 'fixture: manifest without a plugins field') | Out-Null
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $sourceDir, '-TargetRepo', $bareDir)
    Assert-Equal 1 $r.ExitCode 'a manifest missing a required field is exit 1'
    Assert-Match $r.Output "missing the required field 'plugins'" 'the missing field is named'
    Assert-True ($r.Output -notmatch 'cannot be found on this object') 'and that path stays clean under StrictMode too'

    # --- 10-16. the published SUBSET (issue #683) ---------------------------------------------------
    #
    # A second fixture, shaped like the real marketplace -- plugins/<kind>/<plugin>, each kind
    # directory carrying its own README -- because the flat fixture above cannot express the case that
    # matters most here: a kind directory emptied of plugins must go whole, README and all.
    Write-Host 'publish-to-business: the published subset' -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $filterDir -Force | Out-Null
    New-FilterFixture -Dir $filterDir
    Invoke-FixtureGit -Dir $fixtureRoot -GitArgs @('init', '--bare', $filterBareDir) | Out-Null

    # 10. no -Plugins and no seam publishes EVERYTHING. The back-compat guarantee: this is what the
    #     script did before the subset existed, and a caller that has not heard of it must keep it.
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $filterDir, '-TargetRepo', $filterBareDir)
    Assert-Equal 0 $r.ExitCode 'an unfiltered run exits 0'
    $tree = Get-TargetTree -BareDir $filterBareDir
    Assert-True ($tree -contains 'plugins/workflows/flow/.claude-plugin/plugin.json') 'unfiltered: the workflow travelled'
    Assert-True ($tree -contains 'plugins/teams/core/.claude-plugin/plugin.json') 'unfiltered: the team travelled'
    Assert-Match $r.Output 'every entry in the manifest' 'unfiltered: the run says it filtered nothing'

    # 11. the filter: the excluded plugin is gone from the tree AND from the manifest, and the kind
    #     directory it was the only member of is gone with its README.
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $filterDir, '-TargetRepo', $filterBareDir,
                                      '-Plugins', 'core,extra')
    Assert-Equal 0 $r.ExitCode 'the filtered run exits 0'
    Assert-Match $r.Output 'Excluded from this target: flow' 'the filtered run names what it dropped'
    $tree = Get-TargetTree -BareDir $filterBareDir
    Assert-True ($tree -notcontains 'plugins/workflows/flow/.claude-plugin/plugin.json') 'the excluded plugin did not travel'
    Assert-True ($tree -notcontains 'plugins/workflows/README.md') 'and the emptied kind directory went with it, README included'
    Assert-True ($tree -contains 'plugins/teams/core/.claude-plugin/plugin.json') 'the kept plugins did travel'
    Assert-True ($tree -contains 'plugins/teams/README.md') 'and their kind directory kept its README'
    Assert-True ($tree -contains 'plugins/README.md') 'the plugins root README is untouched by the pruning'

    # Read the published manifest from a CHECKOUT, not from `git show`. Native stdout is decoded with
    # the console output codepage, so a real UTF-8 em dash in the blob arrives here already mangled --
    # which would fail the encoding assert below for a reason that has nothing to do with the script
    # under test. A clone plus ReadAllText measures the bytes that were actually committed.
    $checkoutDir = Join-Path $fixtureRoot 'filter-checkout'
    if (Test-Path -LiteralPath $checkoutDir) { Remove-Item -Recurse -Force -LiteralPath $checkoutDir }
    # --branch main explicitly: `git init --bare` leaves HEAD on master, so a plain clone of this
    # fixture checks out nothing at all and the read below fails for the wrong reason.
    Invoke-FixtureGit -Dir $fixtureRoot -GitArgs @('clone', '--quiet', '--branch', 'main', $filterBareDir, $checkoutDir) | Out-Null
    $publishedManifest = [System.IO.File]::ReadAllText((Join-Path $checkoutDir '.claude-plugin\marketplace.json'))
    Assert-True ($publishedManifest -notmatch '"flow"') 'the rewritten manifest does not name the excluded plugin'
    Assert-Match $publishedManifest '"core"' 'the rewritten manifest still names the kept ones'

    # 12. THE MOJIBAKE REGRESSION, measured on the first real dry run of this filter. The manifest is
    #     the one file the script both reads and writes, and Get-Content -Raw on 5.1 decodes a BOM-less
    #     UTF-8 file with the system ANSI codepage -- so the em dashes in the descriptions came back as
    #     three characters and were written out as valid, permanent nonsense. Nothing errors; the
    #     assert has to be on the character itself.
    $emDash = [char]0x2014
    Assert-True ($publishedManifest.Contains($emDash)) 'a non-ASCII description survives the manifest rewrite'
    Assert-True (-not $publishedManifest.Contains([char]0x00E2 + [char]0x20AC)) 'and is not double-encoded on the way'

    # 12b. THE UN-ESCAPE REGRESSION (#1131). The rewrite restores 5.1's \uXXXX escapes for the four
    #      HTML-sensitive characters; the naive expression matched one backslash without asking whether
    #      it was itself escaped, so an escaped pair followed by 'u' + four hex ('C:\\uadded') had
    #      '\uadde' folded into one character and the file stopped being JSON.
    #
    #      TWO ASSERTS, because neither one is enough on its own. The regression's actual symptom is a
    #      REFUSAL: Assert-MarketplaceIntegrity parses the rewritten manifest moments later and exits 1,
    #      so nothing is published and the checkout below still holds the PREVIOUS, unfiltered
    #      publication -- against which a round-trip assert passes while the defect is present. So the
    #      run's own output is asserted first, and it is the assert that bites. The round-trip is kept
    #      beside it because the exit code names nothing about escaping, and because it is what pins the
    #      path is restored rather than merely left escaped. Parse rather than string-match: an invalid
    #      escape is a PARSER error, not a visible one.
    Assert-True ($r.Output -notmatch 'not valid JSON') 'the filtered run does not reject the manifest it just wrote'
    $reparsed = $null
    $parsed = $true
    try { $reparsed = $publishedManifest | ConvertFrom-Json } catch { $parsed = $false }
    Assert-True $parsed 'the rewritten manifest is still valid JSON'
    $backslashDesc = if ($parsed) {
        @($reparsed.plugins | Where-Object { $_.name -eq 'extra' })[0].description
    } else { '<unparsed>' }
    Assert-Match $backslashDesc ([regex]::Escape('C:\uadded\check.ps1')) 'a description holding a \u-shaped Windows path round-trips intact'

    # 13. a name in the keep-list that matches nothing is a HARD STOP, because the failure it would
    #     otherwise cause is silent: the plugin it meant to keep is simply excluded, and the run
    #     reports success with one plugin fewer.
    $before = Get-TargetCommitCount -BareDir $filterBareDir
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $filterDir, '-TargetRepo', $filterBareDir,
                                      '-Plugins', 'core,kore')
    Assert-Equal 1 $r.ExitCode 'a keep-list name that matches nothing is exit 1'
    Assert-Match $r.Output 'kore' 'the refusal names the unmatched entry'
    Assert-Equal $before (Get-TargetCommitCount -BareDir $filterBareDir) 'and nothing was committed'

    # 14. excluding every plugin is an empty marketplace, not a subset.
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $filterDir, '-TargetRepo', $filterBareDir, '-Plugins', 'nothing-here')
    Assert-Equal 1 $r.ExitCode 'a keep-list that keeps nothing is exit 1'

    # 15. THE REVERSE INTEGRITY CHECK -- the silent half. A plugin folder that travels while the
    #     manifest never names it produces no error anywhere: Claude just never offers it, and the
    #     manifest reads as complete to anyone who checks it instead of the tree.
    $strayDir = Join-Path $filterDir 'plugins\teams\stray\.claude-plugin'
    New-Item -ItemType Directory -Path $strayDir -Force | Out-Null
    '{ "name": "stray", "version": "9.9.9" }' | Set-Content -LiteralPath (Join-Path $strayDir 'plugin.json') -Encoding Ascii
    Invoke-FixtureGit -Dir $filterDir -GitArgs @('add', '-A') | Out-Null
    Invoke-FixtureGit -Dir $filterDir -GitArgs @('commit', '-m', 'fixture: a plugin folder the manifest never mentions') | Out-Null
    $before = Get-TargetCommitCount -BareDir $filterBareDir
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $filterDir, '-TargetRepo', $filterBareDir)
    Assert-Equal 1 $r.ExitCode 'an undeclared plugin folder is exit 1'
    Assert-Match $r.Output 'plugins/teams/stray travelled but no manifest entry names it' 'the refusal names the stray folder'
    Assert-Equal $before (Get-TargetCommitCount -BareDir $filterBareDir) 'and nothing was committed on it either'

    # 16. the subset seam: without -Plugins the list comes from Get-BusinessMarketplacePlugins.
    Remove-Item -Recurse -Force -LiteralPath (Join-Path $filterDir 'plugins\teams\stray')
    New-Item -ItemType Directory -Path (Join-Path $filterDir 'scripts') -Force | Out-Null
    @"
function Get-BusinessMarketplacePlugins { return @('core', 'extra') }
"@ | Set-Content -LiteralPath (Join-Path $filterDir 'scripts\repo-config.ps1') -Encoding Ascii
    Invoke-FixtureGit -Dir $filterDir -GitArgs @('add', '-A') | Out-Null
    Invoke-FixtureGit -Dir $filterDir -GitArgs @('commit', '-m', 'fixture: add the subset seam') | Out-Null
    $r = Invoke-Publish -ScriptArgs @('-RepoRoot', $filterDir, '-TargetRepo', $filterBareDir)
    Assert-Equal 0 $r.ExitCode 'a run without -Plugins exits 0 once the seam answers'
    Assert-Match $r.Output 'Excluded from this target: flow' 'and the seam is what excluded the workflow'
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
