<#
.SYNOPSIS
    Regression tests for the bootstrap adoption path: the skill bootstrap (bootstrap.ps1) and the
    persona drift detection in check-consumer-drift.ps1.

.DESCRIPTION
    Dependency-free: no Pester, only PowerShell. Integration style -- it runs the real scripts
    against a throwaway fixture consumer in the temp folder and asserts on their exit code + output.
    The scripts themselves call 'exit', so they are run in a CHILD PROCESS (powershell -File),
    otherwise 'exit' would abort the test runner itself.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/bootstrap-drift.tests.ps1

    The bootstrap seeds the lenses on the PLUGIN PATH (.claude/plugins/<family>/<plugin>/) and the
    persona lenses are LENS-ONLY (no body copy; the body comes via @-import from the plugin install).

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Bootstrap  = Join-Path $RepoRoot 'plugins\specialists\skills\specialists-init\bootstrap.ps1'
$DriftLint  = Join-Path $RepoRoot 'scripts\lint\check-consumer-drift.ps1'
$Integrity  = Join-Path $RepoRoot 'scripts\lint\check-plugin-integrity.ps1'
$Fixture    = Join-Path ([System.IO.Path]::GetTempPath()) 'specialists-init-test-fixture'
# Where a FRESH consumer's lenses land as of the seam (issue #221): one flat directory, no per-plugin
# segment, because <group>-<id> is unique family-wide.
$Pp         = '.claude\specialists\lenses'
$Seam       = '.claude\specialists'
$SeamInclusion = '.claude\specialists\SPECIALISTS.md'
$SeamImport = '@.claude/specialists/SPECIALISTS.md'
# The pre-seam plugin path (family = claude-specialists). Still READ by every reader, and still WRITTEN
# for a consumer that already has a lens tree there -- the bootstrap never relocates one.
$PpLegacy   = '.claude\plugins\claude-specialists\specialists'
$PersonaSrc = Join-Path $RepoRoot 'plugins\specialists\personas\01-01-persona.md'

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

# Runs a .ps1 in a child process and returns [pscustomobject]@{ Code; Out }.
function Invoke-Script {
    param([string]$Path, [string[]]$ScriptArgs)
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArgs
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

function Reset-Fixture {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Isolate the USER layer of the settings chain for every child process this suite starts (inbound #294).
# bootstrap.ps1 now reads enabledPlugins from ~/.claude/settings.json as well as the consumer's own two
# files, so without this the lens counts asserted below would depend on what the machine running the
# suite happens to have enabled globally -- green here, red elsewhere, for a reason no assertion names.
# $env:USERPROFILE is what Get-SettingsChainPaths resolves and what a child process inherits, so
# redirecting it once covers every Invoke-Script call (the same technique connectors.tests.ps1 uses).
$OldUserProfile = $env:USERPROFILE
$env:USERPROFILE = Join-Path $Fixture '..\bootstrap-drift-no-user-home'

try {
    # --- 1. Bootstrap against a fresh repo: lens-only personas in the seam --------------------------
    Write-Host "bootstrap.ps1 -- fresh repo (the seam + lens-only)" -ForegroundColor Cyan
    Reset-Fixture
    $r1 = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-Equal 0 $r1.Code 'bootstrap exit 0 on a fresh repo'
    foreach ($f in '01-01-extension.md', '05-05-extension.md', '05-06-extension.md') {
        Assert-True (Test-Path -LiteralPath (Join-Path $Fixture "$Pp\$f")) "persona lens $f in the seam"
    }
    foreach ($f in '06-16-extension.md', '06-23-extension.md') {
        Assert-True (Test-Path -LiteralPath (Join-Path $Fixture "$Pp\$f")) "lens scaffold $f in the seam"
    }
    # Nothing lands on the pre-seam path for a fresh consumer -- one surface, not two.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture $PpLegacy))) 'fresh repo: nothing written to the pre-seam plugin path'
    $lensText = [System.IO.File]::ReadAllText((Join-Path $Fixture "$Pp\06-16-extension.md"), [System.Text.Encoding]::UTF8)
    Assert-True ($lensText -match 'VUL-IN') 'lens scaffold carries the VUL-IN marker'
    # Still asserted, and now the load-bearing half: after the title lost its marker (inbound #451) the
    # SLOT is the only thing left carrying one, so this line is what proves an unfilled scaffold is still
    # RECOGNISABLE as unfilled. Drop it and the fix could silently become "no marker anywhere", which
    # makes the teardown keep every empty lens forever -- the opposite defect, same root.
    Assert-True ($lensText -match '(?m)^##\sSpecific to this repo \(VUL-IN\)\s*$') 'lens scaffold marks the SLOT heading -- the signal the teardown keys on'
    # Rename-proof (issue #145): the agent-lens header carries the stable g-id slug, not the persona
    # name -- so a later rename of the agent-def never drifts this generated header.
    Assert-True ($lensText -match '(?m)^# 06-16 .* repo lens\s*$') 'lens scaffold header is the nameless g-id form (issue #145)'
    # THE MIRROR OF THE SPECIALISTS.md ASSERTION BELOW (inbound #451), and the reason it exists: filling a
    # lens replaces the SLOT heading and never touches the title, while Test-LooksGenerated matches
    # '(VUL-IN)' at any heading level. A marked title therefore outlives the filling and makes
    # specialists-teardown list authored repo knowledge as removable. Measured in a consumer with 24
    # lenses: three filled ones holding 153 lines all printed [remove].
    Assert-True (-not ($lensText -match '(?m)^#\s[^\r\n]*\(VUL-IN\)')) 'lens TITLE carries NO VUL-IN -- only the slot does'
    Assert-True (-not ($lensText -match 'Victor')) 'lens scaffold does NOT bake the persona name (Victor) in (issue #145)'
    $claudeMd = Join-Path $Fixture 'CLAUDE.md'
    Assert-True (Test-Path -LiteralPath $claudeMd) 'CLAUDE.md scaffold created'
    $mdText = [System.IO.File]::ReadAllText($claudeMd, [System.Text.Encoding]::UTF8)
    # THE SEAM: CLAUDE.md carries exactly ONE specialist line, and the two imports it used to hold now
    # live in SPECIALISTS.md. That single-line property is the whole reason a teardown can be "remove one
    # directory and one line", so it is asserted as a COUNT, not just as a presence.
    Assert-True ($mdText -match [regex]::Escape($SeamImport)) 'CLAUDE.md carries the single seam import'
    Assert-Equal 1 (@([System.IO.File]::ReadAllLines($claudeMd) | Where-Object { $_ -match '^\s*@' }).Count) 'CLAUDE.md carries exactly ONE import line'
    $inclusion = Join-Path $Fixture $SeamInclusion
    Assert-True (Test-Path -LiteralPath $inclusion) 'the seam inclusion SPECIALISTS.md is placed'
    $inclText = [System.IO.File]::ReadAllText($inclusion, [System.Text.Encoding]::UTF8)
    Assert-True ($inclText -match '(?m)^@[^\r\n]*personas/01-01-persona\.md') 'SPECIALISTS.md carries the body @-import (from the plugin install)'
    # Relative, because "relative paths resolve relative to the file containing the import".
    Assert-True ($inclText -match '(?m)^@lenses/01-01-extension\.md') 'SPECIALISTS.md imports the lens relative to itself'
    # The roster slot carries the marker; the TITLE deliberately does not. Filling in the roster removes
    # the marker, so a teardown reads the file as authored instead of deleting somebody's roster.
    Assert-True ($inclText -match '(?m)^##\s.*\(VUL-IN\)\s*$') 'SPECIALISTS.md has a VUL-IN roster slot'
    Assert-True (-not ($inclText -match '(?m)^#\s[^\r\n]*\(VUL-IN\)')) 'SPECIALISTS.md title carries NO VUL-IN -- only the roster slot does'
    Assert-True (Test-Path -LiteralPath (Join-Path $Fixture '.claude\settings.suggested.jsonc')) 'settings.suggested.jsonc placed'
    # The FULL path, not the relative name (#241). Many consumers gitignore '.claude/*', so this file
    # never appears in 'git status' and 'git checkout .' does not clean it up -- an operator verifying a
    # round-trip with git alone cannot see it exists. The stdout line is the only pointer they get, so
    # it has to be a path they can act on.
    Assert-True ($r1.Out -match [regex]::Escape((Join-Path $Fixture '.claude\settings.suggested.jsonc'))) 'the proposal is announced by FULL path -- git cannot announce it in a repo that ignores .claude/*'

    # --- inbound #363: the proposal must not invite copying a hook that points at nothing -------------
    # The Stop hook names a script this bootstrap does not create and nothing else ships. The file itself
    # said "STUB" twice already; what it lacked was a path a reader could not mistake for a real one, and
    # a console step 3 that named the exception while inviting "copy desired parts". Both asserted,
    # because the warning being present somewhere is exactly what made this survive to v11.
    $suggestText = [System.IO.File]::ReadAllText((Join-Path $Fixture '.claude\settings.suggested.jsonc'))
    Assert-True ($suggestText -match 'scripts/maintenance/<[^>]+>\.ps1') `
        'the proposed hook path is visibly a placeholder, not a plausible-looking real path (#363)'
    Assert-True (-not ($suggestText -match 'lint-changed-hook\.ps1')) `
        'and the old copyable-looking name is gone'
    Assert-True ($r1.Out -match "(?s)Copy desired parts.*?'permissions' block is ready to use.*?'hooks' block is NOT") `
        'step 3 names which block is ready to use and which is not -- the caveat sits where the invitation is'
    # Trailing newline. The here-string ends at its closing brace and WriteAllText adds nothing; the
    # #337.2 warning covers CLAUDE.md and not this file, so nothing pointed at it.
    Assert-True ($suggestText.EndsWith("`n")) 'settings.suggested.jsonc ends in a newline (#363)'

    # --- 1b. Register proposal: the bootstrap points at the workshop register (gap found 2026-07-28) --
    #     Bootstrapping a consumer used to leave no trace towards the connector register, and nothing
    #     else filled that gap -- a third consumer ran unregistered for days while the workshop stayed
    #     blind to its plugin version, lens inventory and agent-def drift. The script cannot create the
    #     manifest (it lives in the workshop; the register never writes cross-repo), so it must hand one
    #     over. These assertions pin the handover, not the wording of the prose around it.
    Assert-True ($r1.Out -match 'connector register proposal') 'register proposal: the bootstrap prints a register block'
    Assert-True ($r1.Out -match '"repo"\s*:') 'register proposal: the block is a manifest with a repo field'
    # The inventory must cover BOTH lens kinds -- a persona-only specialist (01-01) and an agent
    # (06-16). Missing the personas would hand over a manifest that under-reports the repo, which is
    # exactly the class of bug inbound #204 was about.
    Assert-True ($r1.Out -match '"01-01"') 'register proposal: inventory includes a persona-only id'
    Assert-True ($r1.Out -match '"06-16"') 'register proposal: inventory includes an agent id'
    # The two fields this script genuinely cannot know stay VUL-IN rather than being guessed: it has no
    # idea where the workshop checkout sits relative to this repo, and a guessed path is what the
    # register's marker check exists to prevent.
    Assert-True ($r1.Out -match 'visibility.*VUL-IN') 'register proposal: visibility is left as VUL-IN, not guessed'
    Assert-True ($r1.Out -match 'localCheckout.*VUL-IN') 'register proposal: localCheckout is left as VUL-IN, not guessed'
    # Propose-only, like every other bootstrap output: nothing may be written into the consumer.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture 'connectors'))) 'register proposal: writes no connectors/ dir into the consumer'

    # --- 1c. scripts/ scaffolds (#86) -- THE CORE-ONLY SHAPE ---------------------------------------
    # SPLIT INTO TWO CASES ON AUGUST 8, 2026, when the branch/release workflow became its own opt-in
    # plugin. What the bootstrap writes now depends on whether the consumer enabled that pack, and this
    # fixture has no settings.json at all -- so it IS the plain consumer, which is the case the
    # plugin-serves-the-consumer doctrine is about. Asserting only the full shape here would have left
    # the case that matters most untested while looking thorough.
    Write-Host "bootstrap.ps1 -- script-config scaffolds (#86), core-only consumer" -ForegroundColor Cyan
    $rcScaffold = Join-Path $Fixture 'scripts\repo-config.ps1'
    $biScaffold = Join-Path $Fixture 'scripts\lib\branch-info.ps1'
    Assert-True (Test-Path -LiteralPath $rcScaffold) 'core-only: scripts/repo-config.ps1 placed -- check-roster-sync reads the roster half'
    Assert-True (-not (Test-Path -LiteralPath $biScaffold)) 'core-only: scripts/lib/branch-info.ps1 NOT placed -- both its functions serve scripts this consumer does not have'
    $rcText = [System.IO.File]::ReadAllText($rcScaffold, [System.Text.Encoding]::UTF8)
    Assert-True ($rcText -match 'function Get-RosterPath') 'core-only: the roster half is there -- Get-RosterPath'
    Assert-True ($rcText -match 'function Get-RosterIgnoredIds') 'core-only: the roster half is there -- Get-RosterIgnoredIds'
    foreach ($wf in 'Get-RepoName', 'Get-LintScript', 'Get-ChangelogHeading', 'Get-LiveStage') {
        Assert-True (-not ($rcText -match "function $wf\b")) "core-only: $wf is absent -- nothing in this repo would read it"
    }
    # The roster half has nothing to fill in, so it carries no placeholder VALUE. Asserted because the
    # teardown's classification turns on exactly that, and the case below proves it still recognises
    # this shape as generated rather than authored.
    Assert-True (-not ($rcText -match "=\s*'[^']*VUL-IN")) 'core-only: no placeholder value -- the roster half is complete as generated'
    Assert-True ($r1.Out -match 'specialists-workflow-davekjohn') 'core-only: the run NAMES the pack the missing half belongs to, so the absence is legible'

    # --- 1c0. The core-only scaffold must stay REMOVABLE by the teardown ---------------------------
    # Without this, a file the bootstrap just wrote is classified as authored and kept forever --
    # adoption exactly as irreversible as specialists-teardown promises it is not.
    Write-Host "bootstrap.ps1 -- the core-only scaffold stays removable by the teardown" -ForegroundColor Cyan
    $teardownScript = Join-Path $RepoRoot 'plugins\specialists\skills\specialists-teardown\teardown.ps1'
    function Test-TeardownSeesGenerated {
        param([string]$Path)
        # The classifier alone, lifted out of the script text: running the whole teardown here would
        # need a fully staged consumer and would test far more than the one question being asked.
        & {
            Set-StrictMode -Off
            $EmptyLensPattern = ''
            $src = [System.IO.File]::ReadAllText($teardownScript, [System.Text.Encoding]::UTF8)
            $m = [regex]::Match($src, '(?ms)^function Test-LooksGenerated \{.*?\r?\n\}\r?\n')
            if (-not $m.Success) { return 'NO-MATCH' }
            . ([scriptblock]::Create($m.Value))
            return [bool](Test-LooksGenerated -Path $Path -Kind 'repo-config')
        }
    }
    Assert-Equal $true (Test-TeardownSeesGenerated $rcScaffold) 'teardown: an untouched core-only repo-config reads as generated (removable)'
    $touchedRc = Join-Path $Fixture 'scripts\repo-config-touched.ps1'
    [System.IO.File]::WriteAllText($touchedRc, $rcText.Replace('$script:RosterIgnoredIds = @()', "`$script:RosterIgnoredIds = @('06-16')"), $Utf8NoBom)
    Assert-Equal $false (Test-TeardownSeesGenerated $touchedRc) 'teardown: one ignored id added and it reads as authored (kept)'
    # THE LOOK-ALIKE. A consumer's own file can hold exactly these two functions and an empty ignore
    # list; only the bootstrap's own docstring says who wrote it. Without this test the shape test
    # alone would delete somebody's hand-written config -- the direction a removing script must never
    # resolve doubt in.
    [System.IO.File]::WriteAllText($touchedRc, $rcText.Replace('Placed by specialists-init', 'Written by hand for this repo'), $Utf8NoBom)
    Assert-Equal $false (Test-TeardownSeesGenerated $touchedRc) "teardown: a look-alike that never claims the bootstrap wrote it is KEPT"
    Remove-Item -LiteralPath $touchedRc -Force

    # --- 1c1. The SAME bootstrap against a consumer that DID enable the workflow pack ---------------
    # Everything this suite used to assert on the single fixture lives here now: the shape a consumer
    # receives when they chose that way of working.
    Write-Host "bootstrap.ps1 -- script-config scaffolds (#86), workflow pack enabled" -ForegroundColor Cyan
    $FixtureWf = Join-Path ([System.IO.Path]::GetTempPath()) "specialists-init-wf-$PID"
    if (Test-Path -LiteralPath $FixtureWf) { Remove-Item -Recurse -Force -LiteralPath $FixtureWf }
    New-Item -ItemType Directory -Path (Join-Path $FixtureWf '.claude') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $FixtureWf '.claude\settings.json'),
        '{ "enabledPlugins": { "specialists@claude-code-specialists": true, "specialists-workflow-davekjohn@claude-code-specialists": true } }', $Utf8NoBom)
    $rWf = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $FixtureWf)
    Assert-Equal 0 $rWf.Code 'workflow pack: bootstrap exit 0'
    $rcScaffold = Join-Path $FixtureWf 'scripts\repo-config.ps1'
    $biScaffold = Join-Path $FixtureWf 'scripts\lib\branch-info.ps1'
    Assert-True (Test-Path -LiteralPath $rcScaffold) 'workflow pack: scripts/repo-config.ps1 scaffold placed'
    Assert-True (Test-Path -LiteralPath $biScaffold) 'workflow pack: scripts/lib/branch-info.ps1 scaffold placed'
    $rcText = [System.IO.File]::ReadAllText($rcScaffold, [System.Text.Encoding]::UTF8)
    Assert-True ($rcText -match 'VUL-IN') 'repo-config scaffold carries the VUL-IN marker'
    Assert-True ($rcText -match 'function Get-RepoName') 'repo-config scaffold supplies Get-RepoName'
    # Both halves in one file: the assembly must not drop the roster pair when the workflow half joins.
    Assert-True ($rcText -match 'function Get-RosterPath') 'workflow pack: the roster half is still there alongside the workflow half'
    # Get-ChangelogHeading (#178) and Get-LiveStage (#177) both ship a concrete, non-VUL-IN default
    # (unlike Get-RepoName/Get-LintScript above, which are placeholders every consumer must fill in) --
    # both are Optional in the script contract, so a consumer that never touches these two lines still
    # gets a working fallback. Asserted here on the literal default value, not just function presence,
    # so a future edit that accidentally reintroduces a VUL-IN marker on either line is caught.
    Assert-True ($rcText -match 'function Get-ChangelogHeading') 'repo-config scaffold supplies Get-ChangelogHeading (#178)'
    Assert-True ($rcText -match "\`$script:ChangelogHeading = '## Pull Requests'") 'repo-config scaffold defaults ChangelogHeading to a concrete value, not VUL-IN'
    Assert-True ($rcText -match 'function Get-LiveStage') 'repo-config scaffold supplies Get-LiveStage (#177)'
    Assert-True ($rcText -match "\`$script:LiveStage = ''") 'repo-config scaffold defaults LiveStage to empty (no live stage), not VUL-IN'
    $biText = [System.IO.File]::ReadAllText($biScaffold, [System.Text.Encoding]::UTF8)
    Assert-True ($biText -match '\$script:BranchPrefixTable = @\{\s*\}') 'branch-info scaffold has an EMPTY prefix table (no repo taxonomy baked in)'

    # --- 1c2. THE INVARIANT: the bootstrap's own scaffolds satisfy the plugin's own contract --------
    #     Issue #226. Every function assertion above is a spot-check against a hand-maintained list,
    #     and that is exactly how this drifted: the contract grew (Test-BranchName for new-branch,
    #     Get-RosterPath + Get-RosterIgnoredIds for check-roster-sync) while the scaffolds did not
    #     follow, so a freshly bootstrapped repo got 3 [ERROR] lines about files the bootstrap had
    #     just written -- phrased as "this lib predates the contract", which is the wrong story for a
    #     lib written seconds earlier by the current version of the plugin.
    #
    #     This case does not spot-check anything. It runs the REAL contract check against the REAL
    #     bootstrap output, so the invariant holds by construction: add a required contract entry
    #     without extending the scaffold and this fails, whatever the entry happens to be named.
    Write-Host "bootstrap.ps1 -- the scaffolds satisfy check-script-contract (#226)" -ForegroundColor Cyan
    # AGAINST THE WORKFLOW FIXTURE, not the core-only one, and that is the accurate scope rather than a
    # convenience: since August 8, 2026 check-script-contract SHIPS IN the workflow pack, so the only
    # repos it ever runs in are the ones that enabled it. Pointing it at the core-only fixture would
    # assert a contract on a consumer that will never run the check -- and would fail on branch-info,
    # which that consumer is correct not to have.
    $contractCheck = Join-Path $RepoRoot 'scripts\sync\check-script-contract.ps1'
    $rc = Invoke-Script -Path $contractCheck -ScriptArgs @('-ConsumerPathOverride', $FixtureWf)
    Assert-Equal 0 $rc.Code 'scaffolds vs contract: exit-code 0 -- a freshly bootstrapped repo satisfies the contract'
    Assert-True (-not ($rc.Out -match '\[ERROR\]')) 'scaffolds vs contract: no [ERROR] about a file the bootstrap just wrote'
    # And it must be reaching the real per-function verdicts, not passing because the [BOOTSTRAP]
    # short-circuit from #225 swallowed the run -- that would make this assertion worthless.
    Assert-True (-not ($rc.Out -match '\[BOOTSTRAP\]')) 'scaffolds vs contract: the libs exist, so the check really did probe them'
    Assert-True ($rc.Out -match "\[OK\]\s+'Test-BranchName'") 'scaffolds vs contract: Test-BranchName probed and present'
    Assert-True ($rc.Out -match "\[OK\]\s+'Get-RosterPath'") 'scaffolds vs contract: Get-RosterPath probed and present'

    # --- 1c3. Get-RosterPath must POINT AT THE SEAM, not merely exist (inbound #333) -----------------
    #     Present-and-wrong was the actual defect, and it was invisible to the assertion above. The
    #     scaffold said 'CLAUDE.md' -- where the roster lived before the seam existed -- while this same
    #     bootstrap writes the roster slot into .claude/specialists/SPECIALISTS.md and its own next-steps
    #     block says the roster does NOT go in CLAUDE.md. So on a freshly bootstrapped consumer the check
    #     read a file containing only the @-import, found no roster rows, and reported every specialist as
    #     missing -- naming the wrong file as the place to fix it. Measured on a virgin profile: nineteen
    #     [ERROR] lines on the documented happy path.
    Assert-True ($rcText -match [regex]::Escape("'.claude/specialists/SPECIALISTS.md'")) 'roster path: the scaffold points at the seam inclusion'
    Assert-True (-not ($rcText -match "RosterPath = 'CLAUDE\.md'")) 'roster path: and NOT at CLAUDE.md, which the bootstrap itself rules out'
    # The placeholder must be gone: a consumer receiving the literal token would be worse off than with the
    # wrong-but-real path this replaced.
    Assert-True (-not ($rcText -match '__SEAM_ROSTER_PATH__')) 'roster path: the template placeholder was substituted, not shipped'
    # And the value the scaffold writes must be the SAME literal the shared source hands out, so the writer
    # and the check that reads it back cannot drift apart again.
    . (Join-Path $RepoRoot 'scripts\lib\check-report-lib.ps1')
    $seamRel = (Get-SeamPaths -RepoRoot $Fixture).RelInclusion
    Assert-True ($rcText -match [regex]::Escape("'$seamRel'")) 'roster path: it is Get-SeamPaths'' own value, not a second hand-typed copy'
    Assert-True ($rc.Out -match "\[OK\]\s+'Get-RosterIgnoredIds'") 'scaffolds vs contract: Get-RosterIgnoredIds probed and present'
    # The two required functions that were never missing -- guards against a "fix" that adds the three
    # new ones while dropping an old one.
    Assert-True ($rc.Out -match "\[OK\]\s+'Get-BranchInfo'") 'scaffolds vs contract: Get-BranchInfo still present'
    Assert-True ($rc.Out -match "\[OK\]\s+'Get-RepoName'") 'scaffolds vs contract: Get-RepoName still present'

    # --- 1d. RepoName derived from the consumer's git remote (origin) (Gap B) -------------------
    # A consumer that is a git repo with a github.com origin gets RepoName pre-filled instead of
    # the VUL-IN placeholder; non-github or no remote -> falls back to VUL-IN. The git call must
    # never crash the bootstrap. Each case runs in its own throwaway git repo.
    Write-Host "bootstrap.ps1 -- RepoName derived from the git remote (origin)" -ForegroundColor Cyan
    function Test-DerivedRepoName {
        param([string]$OriginUrl, [string]$Expected, [bool]$ShouldDerive, [string]$Label)
        $gitFix = Join-Path ([System.IO.Path]::GetTempPath()) ('specialists-init-git-' + $Label)
        if (Test-Path -LiteralPath $gitFix) { Remove-Item -Recurse -Force -LiteralPath $gitFix }
        New-Item -ItemType Directory -Path $gitFix -Force | Out-Null
        try {
            & git -C $gitFix init -q 2>$null | Out-Null
            if ($OriginUrl) { & git -C $gitFix remote add origin $OriginUrl 2>$null | Out-Null }
            # The workflow pack has to be enabled here: RepoName lives in that half of the scaffold since
            # August 8, 2026, so without it there is no line for the derivation to land in and every case
            # below would pass or fail for the wrong reason.
            New-Item -ItemType Directory -Path (Join-Path $gitFix '.claude') -Force | Out-Null
            [System.IO.File]::WriteAllText((Join-Path $gitFix '.claude\settings.json'),
                '{ "enabledPlugins": { "specialists@claude-code-specialists": true, "specialists-workflow-davekjohn@claude-code-specialists": true } }', $Utf8NoBom)
            $rg = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $gitFix)
            Assert-Equal 0 $rg.Code "git derivation ($Label): bootstrap exit 0"
            $txt = [System.IO.File]::ReadAllText((Join-Path $gitFix 'scripts\repo-config.ps1'), [System.Text.Encoding]::UTF8)
            if ($ShouldDerive) {
                Assert-True ($txt -match [regex]::Escape("`$script:RepoName = '$Expected'")) "git derivation ($Label): RepoName = $Expected"
                Assert-True (-not ($txt -match "RepoName = 'VUL-IN")) "git derivation ($Label): no VUL-IN on the RepoName line"
            } else {
                Assert-True ($txt -match "RepoName = 'VUL-IN/repo'") "git derivation ($Label): falls back to VUL-IN/repo"
            }
        } finally {
            if (Test-Path -LiteralPath $gitFix) { Remove-Item -Recurse -Force -LiteralPath $gitFix -ErrorAction SilentlyContinue }
        }
    }
    # The bootstrap reads the origin via `git config --get remote.origin.url`, which gives the RAW
    # stored URL and ignores `insteadOf` -- so what we set here with `remote add` arrives unchanged
    # at the derivation, regardless of the (CI) machine's git config. No isolation needed anymore.
    Test-DerivedRepoName -OriginUrl 'https://github.com/DaveKJohn/my-repo.git' -Expected 'DaveKJohn/my-repo' -ShouldDerive $true  -Label 'https'
    Test-DerivedRepoName -OriginUrl 'git@github.com:DaveKJohn/my-repo.git'    -Expected 'DaveKJohn/my-repo' -ShouldDerive $true  -Label 'ssh'
    Test-DerivedRepoName -OriginUrl 'ssh://git@github.com/DaveKJohn/my-repo.git' -Expected 'DaveKJohn/my-repo' -ShouldDerive $true -Label 'ssh-scheme'
    # Credential-embedded https (e.g. a token in the URL): owner/repo is derived, the userinfo discarded.
    Test-DerivedRepoName -OriginUrl 'https://x-access-token:SECRET@github.com/DaveKJohn/my-repo.git' -Expected 'DaveKJohn/my-repo' -ShouldDerive $true -Label 'https-cred'
    Test-DerivedRepoName -OriginUrl 'https://gitlab.com/DaveKJohn/my-repo.git' -Expected '' -ShouldDerive $false -Label 'non-github'
    Test-DerivedRepoName -OriginUrl ''                                          -Expected '' -ShouldDerive $false -Label 'no-remote'

    # --- 1b. Persona lens is LENS-ONLY: no body copy, but the VUL-IN slot -------------------------
    Write-Host "persona lens -- lens-only (no body copy)" -ForegroundColor Cyan
    $srcPersona = [System.IO.File]::ReadAllText($PersonaSrc, [System.Text.Encoding]::UTF8)
    Assert-True (-not ($srcPersona -match '(?m)^## (Eigen aan deze repo|Specific to this repo)')) 'persona template no longer carries a slot marker (neither language)'
    $lens = [System.IO.File]::ReadAllText((Join-Path $Fixture "$Pp\01-01-extension.md"), [System.Text.Encoding]::UTF8)
    Assert-True ($lens -match 'Repo-lens \(lens-only persona\)') 'persona lens opens with the lens-only blockquote'
    Assert-True ($lens -match '(?m)^## Specific to this repo \(VUL-IN\)') 'persona lens carries a fresh VUL-IN slot (English heading)'
    Assert-True (-not ($lens -match 'fixed ritual')) 'persona lens contains NO body copy'

    # --- 1c. The skill's prose must not undercount what the script places (inbound #275) ------------
    #     SKILL.md named three main-loop personas (01-01, 05-05, 05-06) while the bootstrap enumerates
    #     personas/ and places FOUR. Nothing miscounted -- the closing line reported 4 honestly and the
    #     total was right -- but the description was narrower than the behaviour, which costs a reader a
    #     detour to reconcile the prose with the counter. The doc now derives the set from the payload
    #     and lists it; this test is what keeps those two from drifting apart again when a release adds
    #     a persona.
    Write-Host "bootstrap.ps1 -- the skill doc lists every persona the payload ships (inbound #275)" -ForegroundColor Cyan
    $personaIds = @(
        Get-ChildItem -LiteralPath (Split-Path $PersonaSrc -Parent) -Filter '*-persona.md' -File |
            ForEach-Object { if ($_.BaseName -match '^(\d{2}-\d{2})-persona$') { $Matches[1] } }
    )
    Assert-True ($personaIds.Count -gt 0) "payload ships personas ($($personaIds.Count))"
    $initSkill = [System.IO.File]::ReadAllText(
        (Join-Path (Split-Path (Split-Path $PersonaSrc -Parent) -Parent) 'skills\specialists-init\SKILL.md'),
        [System.Text.Encoding]::UTF8)
    # NOT $pid: that is a read-only automatic variable (the process id), and assigning it in a foreach
    # aborts the suite with a runtime error rather than a failed assertion.
    foreach ($personaId in $personaIds) {
        Assert-True ($initSkill -match [regex]::Escape($personaId)) "specialists-init SKILL.md names persona $personaId"
    }
    # And the count the bootstrap reported for the fresh consumer above is that same number -- the run's
    # own counter stays the authority, so a doc claim can never be the only place a reader is told.
    Assert-True ($r1.Out -match "$($personaIds.Count) persona-lens\(es\) created") 'the run reports exactly the payload persona count'

    # --- 2. Idempotence: second run overwrites nothing ----------------------------------------------
    Write-Host "bootstrap.ps1 -- idempotent (second run)" -ForegroundColor Cyan
    $r2 = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-Equal 0 $r2.Code 'second bootstrap exit 0'
    Assert-True ($r2.Out -match '0 persona-lens') 'second run creates 0 persona lenses (everything already present)'
    Assert-True ($r2.Out -match '0 lens-scaffold') 'second run creates 0 lens scaffolds (everything already present)'
    Assert-True ($r2.Out -match '0 script-scaffold') 'second run creates 0 script scaffolds (#86, everything already present)'
    Assert-True ($r2.Out -match 'already exists') 'second run leaves the existing lens alone'

    # --- 2b. Version-cache layout: the semantically highest version wins (Victor's finding) ------------
    # Mimicked version cache: the specialists plugin as 1.4.0, plus a sibling domain plugin with
    # 1.9.0 AND 1.10.0 side by side -- a string sort would pick 1.9.0, a [version] sort 1.10.0. This
    # layout (<marketplace>/<plugin>/<version>/, with no repo-side plugins/ directory in the path) is
    # also the one that used to derive the family from the install path and land the lenses under the
    # MARKETPLACE name -- where no reader looks (issue #179). The family is a constant now, so the
    # scaffolds must appear on the canonical path here too.
    Write-Host "bootstrap.ps1 -- version cache picks the semantically highest version" -ForegroundColor Cyan
    $cacheRoot = Join-Path $Fixture 'cache\claude-code-specialists'
    $ownCache  = Join-Path $cacheRoot 'specialists\1.4.0'
    New-Item -ItemType Directory -Path $ownCache -Force | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot 'plugins\specialists\*') -Destination $ownCache -Recurse
    foreach ($v in '1.9.0', '1.10.0') {
        New-Item -ItemType Directory -Path (Join-Path $cacheRoot "specialists-lifehub\$v\agents") -Force | Out-Null
    }
    [System.IO.File]::WriteAllText((Join-Path $cacheRoot 'specialists-lifehub\1.9.0\agents\04-88-agent.md'), "---`nname: oldie`nid: 88`ngroup: 04`n---`nfixture")
    [System.IO.File]::WriteAllText((Join-Path $cacheRoot 'specialists-lifehub\1.10.0\agents\04-99-agent.md'), "---`nname: newest`nid: 99`ngroup: 04`n---`nfixture")
    $cacheConsumer = Join-Path $Fixture 'cache-consumer'
    New-Item -ItemType Directory -Path (Join-Path $cacheConsumer '.claude') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $cacheConsumer '.claude\settings.json'), '{ "enabledPlugins": { "specialists@claude-code-specialists": true, "specialists-lifehub@claude-code-specialists": true } }')
    $cachedBootstrap = Join-Path $ownCache 'skills\specialists-init\bootstrap.ps1'
    $rc = Invoke-Script -Path $cachedBootstrap -ScriptArgs @('-ConsumerRoot', $cacheConsumer)
    Assert-Equal 0 $rc.Code 'version cache: bootstrap exit 0'
    # A second plugin's lenses land in the SAME flat seam directory -- no per-plugin segment, since
    # <group>-<id> is unique family-wide. That is what makes "remove one directory" true for a consumer
    # with several plugins enabled, not just for a single-plugin one.
    Assert-True (Test-Path -LiteralPath (Join-Path $cacheConsumer "$Pp\04-99-extension.md")) 'version cache: scaffold from the highest version (1.10.0)'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $cacheConsumer "$Pp\04-88-extension.md"))) 'version cache: older version (1.9.0) not used'
    # Regression #179: nothing may land under the MARKETPLACE name. The seam makes the family segment
    # moot for a fresh consumer, but the assertion is kept: it guards the fallback path that still
    # derives one, and a lens under 'claude-code-specialists' is invisible to every reader.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $cacheConsumer '.claude\plugins\claude-code-specialists'))) 'version cache: no lenses under the marketplace name (#179)'
    $cacheMd = [System.IO.File]::ReadAllText((Join-Path $cacheConsumer 'CLAUDE.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($cacheMd -match [regex]::Escape($SeamImport)) 'version cache: CLAUDE.md carries the single seam import'

    # --- 2c. Durable body path: cache install -> @-import points to the marketplaces clone (Gap C) -----
    # Mimics the real user-scope layout: .../plugins/cache/<mp>/<plugin>/<version>/ next to a
    # versionless .../plugins/marketplaces/<mp>/ clone. The @-import written into CLAUDE.md must point
    # to the clone (durable, survives an update), NOT to the version-pinned cache (which gets cleaned
    # up after an update -> Chris' body would no longer load).
    Write-Host "bootstrap.ps1 -- durable body path (cache -> marketplaces clone)" -ForegroundColor Cyan
    $pluginsRoot = Join-Path $Fixture 'plugins'
    $mp = 'mp-fixture'
    $cacheInit = Join-Path $pluginsRoot "cache\$mp\specialists\9.9.9"
    New-Item -ItemType Directory -Path $cacheInit -Force | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot 'plugins\specialists\*') -Destination $cacheInit -Recurse
    # Versionless marketplaces clone with (at minimum) the personas under plugins/<plugin>/.
    $cloneP = Join-Path $pluginsRoot "marketplaces\$mp\plugins\specialists\personas"
    New-Item -ItemType Directory -Path $cloneP -Force | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot 'plugins\specialists\personas\*') -Destination $cloneP -Recurse
    $durConsumer = Join-Path $Fixture 'durable-consumer'
    New-Item -ItemType Directory -Path $durConsumer -Force | Out-Null
    $rd = Invoke-Script -Path (Join-Path $cacheInit 'skills\specialists-init\bootstrap.ps1') -ScriptArgs @('-ConsumerRoot', $durConsumer)
    Assert-Equal 0 $rd.Code 'durable body path: bootstrap exit 0'
    # The body import now lives in SPECIALISTS.md, not in CLAUDE.md -- so that is where the durability
    # property has to be asserted. Reading the wrong file here would make this pass vacuously.
    $durIncl = [System.IO.File]::ReadAllText((Join-Path $durConsumer $SeamInclusion), [System.Text.Encoding]::UTF8)
    Assert-True ($durIncl -match [regex]::Escape("marketplaces/$mp/plugins/specialists/personas/01-01-persona.md")) 'durable body path: @-import points to the marketplaces clone'
    Assert-True (-not ($durIncl -match '/cache/')) 'durable body path: @-import does NOT point to the version-pinned cache'
    # And CLAUDE.md itself must be free of the cache path too -- the one line it carries is repo-relative.
    $durMd = [System.IO.File]::ReadAllText((Join-Path $durConsumer 'CLAUDE.md'), [System.Text.Encoding]::UTF8)
    Assert-True (-not ($durMd -match '/cache/')) 'durable body path: CLAUDE.md carries no cache path at all'

    # --- 3. Drift on a fresh bootstrap: LENS-ONLY (no body to compare) --------------------
    Write-Host "check-consumer-drift.ps1 -- fresh lens-only bootstrap = LENS-ONLY" -ForegroundColor Cyan
    $d1 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-Equal 0 $d1.Code 'drift exit 0 (no agent-def drift)'
    Assert-True ($d1.Out -match 'LENS-ONLY\] 01-01-persona') 'persona 01-01 reported as LENS-ONLY'
    Assert-True (-not ($d1.Out -match 'DRIFTED\]')) 'no DRIFTED at all on a fresh bootstrap'
    # A verdict travels with its coverage (issue #221): on a bootstrapped consumer the personas were
    # genuinely examined, so the count must say so rather than leaving "0 drifted" to be interpreted.
    Assert-True ($d1.Out -match '\[personas\] checked [1-9]') 'coverage: the personas it DID compare are counted'
    Assert-True ($d1.Out -match 'drifted of [1-9]\d* compared') 'coverage: the verdict names its own denominator'

    # --- 3a. The silent-skip case: a consumer with NO lens file at all (issue #221) ---------------
    # THE DEFECT THIS GUARDS, measured 2026-07-30. The persona section used to be wrapped in
    # `if ($personaResults.Count -gt 0)` and closed with "Persona drift is INFORMATIONAL: 0 drifted."
    # Against a repo holding no lens files -- a torn-down consumer, a bad merge, a wrong -ConsumerPath
    # -- that printed a clean persona verdict over personas it had never compared, and "0 drifted of 0
    # compared" was word-for-word the same sentence as "0 drifted of 4 compared". Right for a
    # deliberate teardown, wrong for an accidental loss, and indistinguishable between them.
    Write-Host "check-consumer-drift.ps1 -- a consumer with no lens tree says so (issue #221)" -ForegroundColor Cyan
    $bare = Join-Path ([System.IO.Path]::GetTempPath()) "drift-bare-consumer-$PID"
    if (Test-Path -LiteralPath $bare) { Remove-Item -Recurse -Force -LiteralPath $bare }
    New-Item -ItemType Directory -Path $bare -Force | Out-Null
    try {
        [System.IO.File]::WriteAllText((Join-Path $bare 'CLAUDE.md'), "# A repo that never adopted, or just tore down`n", $Utf8NoBom)
        $d0 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $bare, '-Quiet')
        Assert-Equal 0 $d0.Code 'bare consumer: exit 0 -- an empty category is not a failure'
        Assert-True ($d0.Out -match 'Personas \(portable body') 'bare consumer: the persona SECTION is printed at all -- it used to vanish entirely'
        Assert-True ($d0.Out -match '\[personas\] checked 0 of [1-9]') 'bare consumer: 0 compared out of the personas that exist -- the zero is stated, not implied'
        Assert-True ($d0.Out -match 'the consumer holds no lens file for any persona') 'bare consumer: the line says WHY, so a teardown is distinguishable from a loss'
        Assert-True ($d0.Out -match 'drifted of 0 compared') 'bare consumer: the verdict carries its denominator, so "0 drifted" cannot read as "all clean"'
    } finally {
        if (Test-Path -LiteralPath $bare) { Remove-Item -Recurse -Force -LiteralPath $bare -ErrorAction SilentlyContinue }
    }

    # --- 3b. Root fix #64: the index line is location-independent (no path-depth link) ------------
    Write-Host "persona index line -- location-independent (inbound #64)" -ForegroundColor Cyan
    Assert-True (-not ($srcPersona -match '\]\((?:\.\./)+CLAUDE\.md\)')) 'persona index line no longer carries a path-depth-dependent CLAUDE.md link'

    # --- 4. Drift comparison on a LEGACY body copy: IDENTICAL -> DRIFTED ------------------------
    # The drift check still supports a consumer with a full body copy (not lens-only).
    # We place one ourselves (template body + repo-lens marker) to test that comparison.
    Write-Host "check-consumer-drift.ps1 -- legacy body copy: IDENTICAL, then DRIFTED" -ForegroundColor Cyan
    $ext = Join-Path $Fixture "$Pp\01-01-extension.md"
    # Legacy Dutch slot marker: proves that an old Dutch consumer still splits correctly on the
    # marker (back-compat) -> the portable body is IDENTICAL to the source.
    $fullBody = $srcPersona.TrimEnd() + "`n`n## Eigen aan deze repo (test-fixture)`n`nrepo-eigen.`n"
    [System.IO.File]::WriteAllText($ext, $fullBody, $Utf8NoBom)
    $d2 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-True ($d2.Out -match 'IDENTICAL\] 01-01-persona') 'legacy NL slot marker: body copy is IDENTICAL to the source'
    # Parallel: the new English slot marker splits identically -> also IDENTICAL.
    $fullBodyEn = $srcPersona.TrimEnd() + "`n`n## Specific to this repo (test-fixture)`n`nrepo-specific.`n"
    [System.IO.File]::WriteAllText($ext, $fullBodyEn, $Utf8NoBom)
    $d2en = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-True ($d2en.Out -match 'IDENTICAL\] 01-01-persona') 'new EN slot marker: splits identically (IDENTICAL)'
    $extText = [System.IO.File]::ReadAllText($ext, [System.Text.Encoding]::UTF8).Replace('Chief of Staff', 'CHIEF-OF-STAFF-TEST-CHANGE')
    [System.IO.File]::WriteAllText($ext, $extText, $Utf8NoBom)
    $d3 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-Equal 0 $d3.Code 'drift exit stays 0 (persona drift is informational)'
    Assert-True ($d3.Out -match 'DRIFTED\]   01-01-persona') 'persona 01-01 DRIFTED after a body change'

    # --- 5. Lint smoke: the repo itself stays green ----------------------------------------------------
    Write-Host "check-plugin-integrity.ps1 -- smoke" -ForegroundColor Cyan
    $li = Invoke-Script -Path $Integrity -ScriptArgs @()
    Assert-Equal 0 $li.Code 'lint gate green on the repo'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
    # Declared in the try block, so it may not exist if the run failed before section 1c1.
    if ($FixtureWf -and (Test-Path -LiteralPath $FixtureWf)) { Remove-Item -Recurse -Force -LiteralPath $FixtureWf -ErrorAction SilentlyContinue }
    $env:USERPROFILE = $OldUserProfile
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
