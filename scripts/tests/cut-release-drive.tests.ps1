<#
.SYNOPSIS
    Drives the REAL cut-release.ps1 end to end against a throwaway git repo (issue #708).

.DESCRIPTION
    Dependency-free: no Pester, plain PowerShell. This is the sibling of cut-release-guardrail.tests.ps1
    and deliberately a different KIND of test. That suite reads cut-release's source text and asserts on
    what it says; this one runs it and asserts on what it leaves behind.

    WHY THIS SUITE EXISTS. cut-release.ps1 is the highest-blast-radius script in the repo: it bumps every
    plugin.json in lockstep, empties CHANGELOG.md down to its intro, writes the release notes, rewrites
    the history table, commits DIRECTLY on the trunk and pushes a tag. Because it runs under the
    narrowly-bounded exception to "never directly on main", no PR and no CI stand between a defect and
    the tag -- CI first sees that commit when it is already pushed and tagged. Until #708 its only
    dedicated coverage was an allowlist drift guard plus source-text asserts, and -- unlike ship-pr.ps1,
    which names its own gap twice in its docstring -- it said nothing about the gap at all, so the
    absence read as coverage.

    HOW IT IS SAFE. The fixture is a fresh `git init` under the temp folder with NO remote, and every run
    passes -NoPush, so nothing can reach a real remote even if the script's push branch were entered. The
    real script is invoked in a CHILD PROCESS with CLAUDE_PROJECT_DIR pointed at the fixture, which is the
    documented way cut-release resolves its repo root. -SkipLint and -SkipTests are passed because the
    fixture has neither a lint script nor suites: this suite is about what cut-release WRITES, and the
    gate behaviour it skips is what cut-release-guardrail.tests.ps1 already pins from the source.

    FIXTURE STRATEGY. scripts/repo-config.ps1 and scripts/lib/branch-info.ps1 are copied VERBATIM from
    this repo -- the same choice script-contract.tests.ps1 makes, and for the same reason: a passing
    suite is then grounded in this repo's real seam answers rather than a hand-rolled stand-in that
    could drift away from them. Everything else the fixture holds is the minimum tree those answers
    describe.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/cut-release-drive.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$CutRelease = Join-Path $RepoRoot 'scripts\release\cut-release.ps1'

# Every git call below goes through the repo's own Invoke-NativeCapture, and that is not decoration.
# Under EAP=Stop, PowerShell 5.1 promotes a native command's stderr to a terminating NativeCommandError
# -- so `git add` writing its ordinary "LF will be replaced by CRLF" warning kills the caller. That is
# the exact pitfall that broke cutting v1.12.0 (#107), which is why this lib exists; a suite about
# cut-release re-learning it by hand would be the wrong lesson.
. (Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1')
$FixtureDir = Join-Path ([System.IO.Path]::GetTempPath()) "cut-release-drive-$PID"

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host "  [PASS] $Message" -ForegroundColor Green; $script:pass++ }
    else            { Write-Host "  [FAIL] $Message" -ForegroundColor Red;   $script:fail++ }
}
function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ("$Expected" -eq "$Actual") { Write-Host "  [PASS] $Message" -ForegroundColor Green; $script:pass++ }
    else { Write-Host "  [FAIL] $Message (expected '$Expected', got '$Actual')" -ForegroundColor Red; $script:fail++ }
}
function Assert-Match {
    param([string]$Pattern, [string]$Text, [string]$Message)
    if ($Text -match $Pattern) { Write-Host "  [PASS] $Message" -ForegroundColor Green; $script:pass++ }
    else { Write-Host "  [FAIL] $Message (pattern '$Pattern' not found)" -ForegroundColor Red; $script:fail++ }
}
function Assert-NotMatch {
    param([string]$Pattern, [string]$Text, [string]$Message)
    if ($Text -notmatch $Pattern) { Write-Host "  [PASS] $Message" -ForegroundColor Green; $script:pass++ }
    else { Write-Host "  [FAIL] $Message (pattern '$Pattern' unexpectedly found)" -ForegroundColor Red; $script:fail++ }
}

function Write-Utf8 {
    param([string]$Path, [string]$Text)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}

function New-CutFixture {
    <#
        The minimum tree this repo's own seam answers describe: a marketplace, two plugins to bump in
        lockstep, a CHANGELOG with an intro and one pending entry, the release history table, and the
        two note roots. Returns the fixture path.
    #>
    # The history shape is copied from this repo's own page rather than invented: '### The release list',
    # then one '#### <major>.x' per major, each over a table whose header is '| Version | Date | Type |
    # Title |'. Getting this wrong is not a loud failure -- the first draft of this fixture used
    # '| Release |' and no list heading, and the cut simply wrote no row and refused nothing, which is
    # exactly the silent shape a suite about this script exists to catch.
    # $AudienceTier and $EntryTopTier exist for the tier-1 scenario, and 2/0 keep every earlier caller
    # byte-identical. They are two parameters rather than one switch because they are two independent
    # facts -- which audience the repo publishes to, and how far its pending entry reaches -- and the
    # defect they were added for (#747) is precisely what happens when one is assumed from the other.
    param(
        [string]$Name,
        [string]$PluginVersion = '1.4.0',
        [string]$HistoryMajors = "#### 1.x`n`n| Version | Date | Type | Title |`n|---|---|---|---|`n",
        [int]$AudienceTier = 2,
        [int]$EntryTopTier = 0)

    $root = Join-Path $FixtureDir $Name
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
    New-Item -ItemType Directory -Path $root -Force | Out-Null

    # The two seam libs, verbatim from this repo.
    New-Item -ItemType Directory -Path (Join-Path $root 'scripts\lib') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'scripts\repo-config.ps1')     -Destination (Join-Path $root 'scripts\repo-config.ps1') -Force
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'scripts\lib\branch-info.ps1') -Destination (Join-Path $root 'scripts\lib\branch-info.ps1') -Force
    # THE ONE DELIBERATE DEPARTURE FROM 'VERBATIM', and only when asked for. This repo answers 2, so the
    # tier-1 path cannot be reached with its seam file unaltered -- which is the whole reason #747 shipped:
    # every local run of every gate produced a correct document. Patched by targeted replacement rather
    # than by hand-writing a stand-in config, so the fixture keeps every OTHER answer grounded in the real
    # file. The assert makes a failed patch loud: a silent no-op would leave this scenario testing tier 2
    # twice and reporting a pass.
    if ($AudienceTier -ne 2) {
        $cfgPath = Join-Path $root 'scripts\repo-config.ps1'
        $cfg = Get-Content -LiteralPath $cfgPath -Raw
        $patched = $cfg -replace '(?m)^\$script:ReleaseAudienceTier\s*=\s*2\s*$', "`$script:ReleaseAudienceTier = $AudienceTier"
        if ($patched -eq $cfg) { throw "fixture: could not repoint ReleaseAudienceTier to $AudienceTier -- the seam literal in repo-config.ps1 changed shape." }
        Write-Utf8 $cfgPath $patched
    }

    Write-Utf8 (Join-Path $root '.claude-plugin\marketplace.json') @"
{
  "name": "claude-code-specialists",
  "owner": { "name": "fixture" },
  "plugins": [
    { "name": "team-fixture",     "source": "./plugins/teams/team-fixture" },
    { "name": "workflow-fixture", "source": "./plugins/workflows/workflow-fixture" }
  ]
}
"@
    foreach ($p in @(
        @{ Path = 'plugins\teams\team-fixture';         Name = 'team-fixture' },
        @{ Path = 'plugins\workflows\workflow-fixture'; Name = 'workflow-fixture' })) {
        Write-Utf8 (Join-Path $root "$($p.Path)\.claude-plugin\plugin.json") @"
{
  "name": "$($p.Name)",
  "description": "A fixture plugin.",
  "version": "$PluginVersion"
}
"@
    }

    # CHANGELOG: an intro, then one pending entry scored at tier 0 so a patch is what it earns -- plus a
    # higher tier's section where the caller asked for one, which is what lets a minor be earned AND gives
    # the audience section something real to be pre-filled from.
    $topTierSection = if ($EntryTopTier -gt 0) { @"

#### Tier $EntryTopTier

The reader this repo publishes to notices it.

**Score:** 4
"@ } else { '' }
    Write-Utf8 (Join-Path $root 'CHANGELOG.md') @"
# Changelog

Everything merged since the last release, furthest reach first.

---

## ``fix/a-fixture-change`` changelog

### Branch title

A fixture change

### Branch ID

20260815-000000

### Branch type

fix

### What does the change on this branch bring to main?

A fixture entry, written so this suite has something real to fold.

### Significance

#### Tier 0

The maintainers notice it.

**Score:** 2
$topTierSection

### Pull Request

https://github.com/DaveKJohn/claude-code-specialists/pull/1
"@

    Write-Utf8 (Join-Path $root 'releases\README.md') @"
# Releases

A fixture release page.

### The release list

$HistoryMajors
"@
    New-Item -ItemType Directory -Path (Join-Path $root 'workflow-davekjohn\releases\audience\1.x') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root 'releases\development\1.x') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $root 'releases\github\1.x') -Force | Out-Null

    # A git repo with NO remote: -NoPush is belt, this is braces.
    Push-Location $root
    try {
        Invoke-NativeCapture -FilePath 'git' -Arguments @('init', '--quiet', '--initial-branch=main') | Out-Null
        Invoke-NativeCapture -FilePath 'git' -Arguments @('config', 'user.email', 'fixture@example.invalid') | Out-Null
        Invoke-NativeCapture -FilePath 'git' -Arguments @('config', 'user.name', 'Fixture') | Out-Null
        Invoke-NativeCapture -FilePath 'git' -Arguments @('add', '-A') | Out-Null
        Invoke-NativeCapture -FilePath 'git' -Arguments @('commit', '--quiet', '-m', 'fixture: initial') | Out-Null
    } finally { Pop-Location }

    return $root
}

function Invoke-Cut {
    param([string]$Root, [string[]]$Arguments)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName  = 'powershell'
    $psi.Arguments = (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$CutRelease`"") + $Arguments) -join ' '
    $psi.WorkingDirectory      = $Root
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute        = $false
    $psi.EnvironmentVariables['CLAUDE_PROJECT_DIR'] = $Root
    $p = [System.Diagnostics.Process]::Start($psi)
    $out = $p.StandardOutput.ReadToEnd()
    $err = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    return [pscustomobject]@{ Code = $p.ExitCode; Out = ($out + "`n" + $err) }
}

function Get-GitOut {
    param([string]$Root, [string[]]$GitArgs)
    Push-Location $Root
    try { return ((Invoke-NativeCapture -FilePath 'git' -Arguments $GitArgs).Output | Out-String) }
    finally { Pop-Location }
}

try {
    Write-Host "== cut-release-drive.tests ==" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $FixtureDir -Force | Out-Null

    # --- 1. The happy path: a patch is cut, and every artefact it owns is on disk ------------------
    Write-Host ""
    Write-Host "cut-release.ps1 -- a patch cut writes every artefact and tags the commit" -ForegroundColor Cyan
    $root = New-CutFixture -Name 'happy'
    $r = Invoke-Cut -Root $root -Arguments @('-Bump', 'patch', '-NoPush', '-SkipLint', '-SkipTests')
    Assert-Equal 0 $r.Code 'happy path: exit code 0'

    # Lockstep is the property a consumer depends on: team-fixture and workflow-fixture must move
    # together, because a consumer running both needs matching versions.
    $v1 = (Get-Content -LiteralPath (Join-Path $root 'plugins\teams\team-fixture\.claude-plugin\plugin.json') -Raw | ConvertFrom-Json).version
    $v2 = (Get-Content -LiteralPath (Join-Path $root 'plugins\workflows\workflow-fixture\.claude-plugin\plugin.json') -Raw | ConvertFrom-Json).version
    Assert-Equal '1.4.1' $v1 'happy path: the team plugin was bumped to the patch version'
    Assert-Equal '1.4.1' $v2 'happy path: the workflow plugin moved with it -- lockstep, not per plugin'

    # CHANGELOG down to its intro: the entry is gone, the intro survives verbatim.
    $changelog = Get-Content -LiteralPath (Join-Path $root 'CHANGELOG.md') -Raw
    Assert-Match '# Changelog'   $changelog 'happy path: the CHANGELOG intro survives the cut'
    Assert-NotMatch 'a-fixture-change' $changelog 'happy path: the pending entry is gone from CHANGELOG.md'

    # The development note carries the entry that was folded away, which is the whole point of writing
    # it before emptying the file.
    $notePath = Join-Path $root 'releases\development\1.x\1.4.1.md'
    Assert-True (Test-Path -LiteralPath $notePath) 'happy path: the development note was written at the grouped path'
    if (Test-Path -LiteralPath $notePath) {
        Assert-Match 'A fixture change' (Get-Content -LiteralPath $notePath -Raw) 'happy path: and it carries the entry the CHANGELOG lost'
    }

    # The history table gains its own row -- the cut inserts it, so nobody adds one by hand.
    $history = Get-Content -LiteralPath (Join-Path $root 'releases\README.md') -Raw
    Assert-Match '1\.4\.1' $history 'happy path: the release history table gained a row for this version'

    # Commit + tag on the trunk, which is the irreversible half of the exception this script runs under.
    Assert-Match 'v1\.4\.1' (Get-GitOut -Root $root -GitArgs @('tag','--list')) 'happy path: the tag exists'
    Assert-Match 'v1\.4\.1' (Get-GitOut -Root $root -GitArgs @('log','-1','--pretty=%D')) 'happy path: and it points at the commit the cut just made'
    Assert-Equal '' (Get-GitOut -Root $root -GitArgs @('status','--porcelain')).Trim() 'happy path: the tree is clean afterwards -- everything written was committed'

    # --- 2. The bump gate: tier 0 alone does not earn a minor -------------------------------------
    Write-Host ""
    Write-Host "cut-release.ps1 -- a bump that the pending entries have not earned is refused" -ForegroundColor Cyan
    $root2 = New-CutFixture -Name 'unearned'
    $r2 = Invoke-Cut -Root $root2 -Arguments @('-Bump', 'minor', '-NoPush', '-SkipLint', '-SkipTests')
    Assert-True ($r2.Code -ne 0) 'unearned minor: refused with a non-zero exit'
    $v3 = (Get-Content -LiteralPath (Join-Path $root2 'plugins\teams\team-fixture\.claude-plugin\plugin.json') -Raw | ConvertFrom-Json).version
    Assert-Equal '1.4.0' $v3 'unearned minor: NOTHING was written -- the gate runs before the first write'
    Assert-Equal '' (Get-GitOut -Root $root2 -GitArgs @('tag','--list')).Trim() 'unearned minor: and no tag was created'

    # --- 3. A new major refuses until its section exists ------------------------------------------
    # This is the case CLAUDE.md documents as needing two hand edits on the trunk BEFORE a cut will
    # run. Pinning it here means the refusal cannot quietly become a silent success.
    Write-Host ""
    Write-Host "cut-release.ps1 -- a major with no section in the history table refuses" -ForegroundColor Cyan
    $root3 = New-CutFixture -Name 'newmajor'
    $r3 = Invoke-Cut -Root $root3 -Arguments @('-Version', '2.0.0', '-NoPush', '-SkipLint', '-SkipTests', '-SkipTierGate')
    Assert-True ($r3.Code -ne 0) 'new major: refused with a non-zero exit'
    Assert-Equal '' (Get-GitOut -Root $root3 -GitArgs @('tag','--list')).Trim() 'new major: no tag was created'
    $v4 = (Get-Content -LiteralPath (Join-Path $root3 'plugins\teams\team-fixture\.claude-plugin\plugin.json') -Raw | ConvertFrom-Json).version
    Assert-Equal '1.4.0' $v4 'new major: and no version was bumped -- the refusal leaves the tree untouched'

    # --- 4. The audience section follows the repo's tier, not the literal 2 (inbound #747) ---------
    # THE DEFECT THIS PINS could not be seen from inside this repo: Get-ReleaseAudienceTier answers 2
    # here, so every gate and every local cut produced a correct document while a tier-1 consumer's
    # draft came out with the two sections that cannot be generated and none that said what shipped.
    # Driven through the real script rather than asserted at the lib, because the hardcode was in the
    # SELECTION (cut-release.ps1) and not in the renderer -- a lib-level test would have passed
    # throughout, which is how a suite of 40 files missed this.
    Write-Host ""
    Write-Host "cut-release.ps1 -- the audience section is drawn from the repo's own tier" -ForegroundColor Cyan
    $root4 = New-CutFixture -Name 'tier1' -AudienceTier 1 -EntryTopTier 1
    $r4 = Invoke-Cut -Root $root4 -Arguments @('-Bump', 'minor', '-NoPush', '-SkipLint', '-SkipTests')
    Assert-Equal 0 $r4.Code 'tier 1: the minor is earned by the tier-1 entry and the cut succeeds'
    $note4 = Join-Path $root4 'workflow-davekjohn\releases\audience\1.x\1.5.0.md'
    Assert-True (Test-Path -LiteralPath $note4) 'tier 1: the hand-written note was drafted'
    if (Test-Path -LiteralPath $note4) {
        $n4 = Get-Content -LiteralPath $note4 -Raw
        # The finding itself: a section that says what changed, at all.
        Assert-Match '(?m)^## What changed$'  $n4 'tier 1: the draft HAS a section saying what changed -- the whole of #747'
        Assert-NotMatch '(?m)^## For consumers$' $n4 'tier 1: and it is not the consumer heading, which names the wrong reader here'
        # PRE-FILLED, not merely asked for. #747 proposed an empty heading on the reasoning that a tier-1
        # repo has no generatable source; it has the same source a tier-2 repo has, and this is the assert
        # that would fail if the fix were narrowed back to a bare heading.
        Assert-Match 'A fixture change' $n4 'tier 1: the section is PRE-FILLED from the tier-1 entry, not left empty'
        # The two sections that genuinely cannot be generated still arrive, still empty.
        Assert-Match '(?m)^## What it is worth$'                 $n4 "tier 1: 'what it is worth' still arrives"
        Assert-Match '(?m)^## What was still open at this release$' $n4 'tier 1: and so does the open section'
        # #747's second finding: the audience line promised two readers with one section each, in a
        # document that renders one reader and two sections.
        Assert-NotMatch 'consumers of this product' $n4 'tier 1: the audience line no longer promises a reader this repo does not publish to'
        Assert-Match '(?m)^\*\*For whom:\*\* colleagues in the organisation' $n4 'tier 1: it names the reader the repo actually has'
        # The score is a self-assigned number and must not reach a document that travels outward, at
        # either tier -- the strip is inherited, so this catches a caller that stopped passing it.
        Assert-NotMatch '\*\*Score:\*\*' $n4 'tier 1: the self-assigned score is stripped, as at tier 2'
    }

    # --- 5. And tier 2 is unmoved by the same change -----------------------------------------------
    # The other half of the claim. A fix that reads a seam is only safe if the answer this repo gives
    # produces what it produced before, so the tier-2 path is driven with a tier-2 entry and asserted
    # on the heading the change could most easily have broken.
    Write-Host ""
    Write-Host "cut-release.ps1 -- a tier-2 repo's consumer section is unchanged by the same code" -ForegroundColor Cyan
    $root5 = New-CutFixture -Name 'tier2' -EntryTopTier 2
    $r5 = Invoke-Cut -Root $root5 -Arguments @('-Bump', 'minor', '-NoPush', '-SkipLint', '-SkipTests')
    Assert-Equal 0 $r5.Code 'tier 2: the minor is earned by the tier-2 entry and the cut succeeds'
    $note5 = Join-Path $root5 'workflow-davekjohn\releases\audience\1.x\1.5.0.md'
    Assert-True (Test-Path -LiteralPath $note5) 'tier 2: the hand-written note was drafted'
    if (Test-Path -LiteralPath $note5) {
        $n5 = Get-Content -LiteralPath $note5 -Raw
        Assert-Match '(?m)^## For consumers$' $n5 'tier 2: the consumer heading is exactly what it always was'
        Assert-NotMatch '(?m)^## What changed$' $n5 'tier 2: and the tier-1 heading does not leak into it'
        Assert-Match 'consumers of this product' $n5 'tier 2: its audience line still names both readers'
        Assert-Match 'A fixture change' $n5 'tier 2: pre-filled from the tier-2 entry, as before'
    }

} finally {
    if (Test-Path -LiteralPath $FixtureDir) {
        Remove-Item -LiteralPath $FixtureDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
