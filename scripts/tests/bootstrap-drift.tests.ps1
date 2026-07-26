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
$Bootstrap  = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\skills\specialists-init\bootstrap.ps1'
$DriftLint  = Join-Path $RepoRoot 'scripts\lint\check-consumer-drift.ps1'
$Integrity  = Join-Path $RepoRoot 'scripts\lint\check-plugin-integrity.ps1'
$Fixture    = Join-Path ([System.IO.Path]::GetTempPath()) 'specialists-init-test-fixture'
# Plugin path in a consumer bootstrapped from the source repo (family = claude-specialists).
$Pp         = '.claude\plugins\claude-specialists\specialists'
$PersonaSrc = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\personas\01-01-persona.md'

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

try {
    # --- 1. Bootstrap against a fresh repo: lens-only personas on the plugin path --------------------
    Write-Host "bootstrap.ps1 -- fresh repo (plugin path + lens-only)" -ForegroundColor Cyan
    Reset-Fixture
    $r1 = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-Equal 0 $r1.Code 'bootstrap exit 0 on a fresh repo'
    foreach ($f in '01-01-extension.md', '05-05-extension.md', '05-06-extension.md') {
        Assert-True (Test-Path -LiteralPath (Join-Path $Fixture "$Pp\$f")) "persona lens $f on the plugin path"
    }
    foreach ($f in '06-16-extension.md', '06-23-extension.md') {
        Assert-True (Test-Path -LiteralPath (Join-Path $Fixture "$Pp\$f")) "lens scaffold $f on the plugin path"
    }
    $lensText = [System.IO.File]::ReadAllText((Join-Path $Fixture "$Pp\06-16-extension.md"), [System.Text.Encoding]::UTF8)
    Assert-True ($lensText -match 'VUL-IN') 'lens scaffold carries the VUL-IN marker'
    # Rename-proof (issue #145): the agent-lens header carries the stable g-id slug, not the persona
    # name -- so a later rename of the agent-def never drifts this generated header.
    Assert-True ($lensText -match '(?m)^# 06-16 .* repo lens \(VUL-IN\)') 'lens scaffold header is the nameless g-id form (issue #145)'
    Assert-True (-not ($lensText -match 'Victor')) 'lens scaffold does NOT bake the persona name (Victor) in (issue #145)'
    $claudeMd = Join-Path $Fixture 'CLAUDE.md'
    Assert-True (Test-Path -LiteralPath $claudeMd) 'CLAUDE.md scaffold created'
    $mdText = [System.IO.File]::ReadAllText($claudeMd, [System.Text.Encoding]::UTF8)
    Assert-True ($mdText -match [regex]::Escape('@.claude/plugins/claude-specialists/specialists/01-01-extension.md')) 'CLAUDE.md carries the lens @-import (plugin path)'
    Assert-True ($mdText -match '(?m)^@[^\r\n]*personas/01-01-persona\.md') 'CLAUDE.md carries the body @-import (from the plugin install)'
    Assert-True (Test-Path -LiteralPath (Join-Path $Fixture '.claude\settings.suggested.jsonc')) 'settings.suggested.jsonc placed'

    # --- 1c. scripts/ scaffolds for the shared workflow skills (#86): repo-config + branch-info ----
    Write-Host "bootstrap.ps1 -- script-config scaffolds (#86)" -ForegroundColor Cyan
    $rcScaffold = Join-Path $Fixture 'scripts\repo-config.ps1'
    $biScaffold = Join-Path $Fixture 'scripts\lib\branch-info.ps1'
    Assert-True (Test-Path -LiteralPath $rcScaffold) 'scripts/repo-config.ps1 scaffold placed'
    Assert-True (Test-Path -LiteralPath $biScaffold) 'scripts/lib/branch-info.ps1 scaffold placed'
    $rcText = [System.IO.File]::ReadAllText($rcScaffold, [System.Text.Encoding]::UTF8)
    Assert-True ($rcText -match 'VUL-IN') 'repo-config scaffold carries the VUL-IN marker'
    Assert-True ($rcText -match 'function Get-RepoName') 'repo-config scaffold supplies Get-RepoName'
    $biText = [System.IO.File]::ReadAllText($biScaffold, [System.Text.Encoding]::UTF8)
    Assert-True ($biText -match '\$script:BranchPrefixTable = @\{\s*\}') 'branch-info scaffold has an EMPTY prefix table (no repo taxonomy baked in)'

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
    # layout (no claude-code-plugins segment) is also the one that used to derive the family from the
    # install path and land the lenses under the MARKETPLACE name -- where no reader looks (issue
    # #179). The family is a constant now, so the scaffolds must appear on the canonical path here too.
    Write-Host "bootstrap.ps1 -- version cache picks the semantically highest version" -ForegroundColor Cyan
    $cacheRoot = Join-Path $Fixture 'cache\davekjohns-workshop'
    $ownCache  = Join-Path $cacheRoot 'specialists\1.4.0'
    New-Item -ItemType Directory -Path $ownCache -Force | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\*') -Destination $ownCache -Recurse
    foreach ($v in '1.9.0', '1.10.0') {
        New-Item -ItemType Directory -Path (Join-Path $cacheRoot "specialists-lifehub\$v\agents") -Force | Out-Null
    }
    [System.IO.File]::WriteAllText((Join-Path $cacheRoot 'specialists-lifehub\1.9.0\agents\04-88-agent.md'), "---`nname: oldie`nid: 88`ngroup: 04`n---`nfixture")
    [System.IO.File]::WriteAllText((Join-Path $cacheRoot 'specialists-lifehub\1.10.0\agents\04-99-agent.md'), "---`nname: newest`nid: 99`ngroup: 04`n---`nfixture")
    $cacheConsumer = Join-Path $Fixture 'cache-consumer'
    New-Item -ItemType Directory -Path (Join-Path $cacheConsumer '.claude') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $cacheConsumer '.claude\settings.json'), '{ "enabledPlugins": { "specialists@davekjohns-workshop": true, "specialists-lifehub@davekjohns-workshop": true } }')
    $cachedBootstrap = Join-Path $ownCache 'skills\specialists-init\bootstrap.ps1'
    $rc = Invoke-Script -Path $cachedBootstrap -ScriptArgs @('-ConsumerRoot', $cacheConsumer)
    Assert-Equal 0 $rc.Code 'version cache: bootstrap exit 0'
    $ppCache = '.claude\plugins\claude-specialists\specialists-lifehub'
    Assert-True (Test-Path -LiteralPath (Join-Path $cacheConsumer "$ppCache\04-99-extension.md")) 'version cache: scaffold from the highest version (1.10.0)'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $cacheConsumer "$ppCache\04-88-extension.md"))) 'version cache: older version (1.9.0) not used'
    # Regression #179: the family segment must be the plugin family, never the marketplace the plugin
    # was installed from -- a lens under 'davekjohns-workshop' is invisible to every reader.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $cacheConsumer '.claude\plugins\davekjohns-workshop'))) 'version cache: no lenses under the marketplace name (#179)'
    $cacheMd = [System.IO.File]::ReadAllText((Join-Path $cacheConsumer 'CLAUDE.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($cacheMd -match [regex]::Escape('@.claude/plugins/claude-specialists/specialists/01-01-extension.md')) 'version cache: the CLAUDE.md lens @-import follows the canonical path (#179)'

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
    Copy-Item -Path (Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\*') -Destination $cacheInit -Recurse
    # Versionless marketplaces clone with (at minimum) the personas under claude-code-plugins/<family>/<plugin>/.
    $cloneP = Join-Path $pluginsRoot "marketplaces\$mp\claude-code-plugins\claude-specialists\specialists\personas"
    New-Item -ItemType Directory -Path $cloneP -Force | Out-Null
    Copy-Item -Path (Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\personas\*') -Destination $cloneP -Recurse
    $durConsumer = Join-Path $Fixture 'durable-consumer'
    New-Item -ItemType Directory -Path $durConsumer -Force | Out-Null
    $rd = Invoke-Script -Path (Join-Path $cacheInit 'skills\specialists-init\bootstrap.ps1') -ScriptArgs @('-ConsumerRoot', $durConsumer)
    Assert-Equal 0 $rd.Code 'durable body path: bootstrap exit 0'
    $durMd = [System.IO.File]::ReadAllText((Join-Path $durConsumer 'CLAUDE.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($durMd -match [regex]::Escape("marketplaces/$mp/claude-code-plugins/claude-specialists/specialists/personas/01-01-persona.md")) 'durable body path: @-import points to the marketplaces clone'
    Assert-True (-not ($durMd -match '/cache/')) 'durable body path: @-import does NOT point to the version-pinned cache'

    # --- 3. Drift on a fresh bootstrap: LENS-ONLY (no body to compare) --------------------
    Write-Host "check-consumer-drift.ps1 -- fresh lens-only bootstrap = LENS-ONLY" -ForegroundColor Cyan
    $d1 = Invoke-Script -Path $DriftLint -ScriptArgs @('-ConsumerPath', $Fixture, '-Quiet')
    Assert-Equal 0 $d1.Code 'drift exit 0 (no agent-def drift)'
    Assert-True ($d1.Out -match 'LENS-ONLY\] 01-01-persona') 'persona 01-01 reported as LENS-ONLY'
    Assert-True (-not ($d1.Out -match 'DRIFTED\]')) 'no DRIFTED at all on a fresh bootstrap'

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
}

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
