<#
.SYNOPSIS
    Tests for specialists-teardown: the round-trip with the bootstrap, and the safety properties.

.DESCRIPTION
    The interesting assertions here are the NEGATIVE ones. A teardown that removes plenty is easy; one
    that can be trusted on somebody's repo has to demonstrably NOT touch authored content, NOT edit
    settings.json, and NOT eat an unrelated @-import that happens to share the line shape.

    Dependency-free (no Pester), exit 1 on the first failure, same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot  = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Plugin    = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists'
$Bootstrap = Join-Path $Plugin 'skills\specialists-init\bootstrap.ps1'
$Teardown  = Join-Path $Plugin 'skills\specialists-teardown\teardown.ps1'
$Fixture   = Join-Path ([System.IO.Path]::GetTempPath()) 'specialists-teardown-fixture'

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Label)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label" -ForegroundColor Red }
}
function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ("$Expected" -eq "$Actual") { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}

function Invoke-Script {
    param([string]$Path, [string[]]$ScriptArgs = @())
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @ScriptArgs 2>&1
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

# Builds a consumer with its OWN CLAUDE.md content, then bootstraps it. -ExtraClaudeMdLines lets a case
# add lines the bootstrap did not write, which is how the unrelated-@-import case is built.
function New-BootstrappedConsumer {
    param([string[]]$ExtraClaudeMdLines = @())
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path (Join-Path $Fixture '.claude') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $Fixture '.claude\settings.json'),
        '{ "enabledPlugins": { "specialists@davekjohns-workshop": true } }')
    $md = @('# CLAUDE.md - my own project', '', '## Conventions', '', '- Feature work goes on a branch.') + $ExtraClaudeMdLines
    [System.IO.File]::WriteAllLines((Join-Path $Fixture 'CLAUDE.md'), $md)
    $prevPlugin = $env:CLAUDE_PLUGIN_ROOT
    $env:CLAUDE_PLUGIN_ROOT = $Plugin
    try {
        $r = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture)
        if ($r.Code -ne 0) { throw "bootstrap failed (exit $($r.Code)): $($r.Out)" }
    } finally { $env:CLAUDE_PLUGIN_ROOT = $prevPlugin }
    return $Fixture
}

function Get-LensCount {
    return @(Get-ChildItem -LiteralPath (Join-Path $Fixture '.claude') -Recurse -Filter '*-extension.md' -File -ErrorAction SilentlyContinue).Count
}
function Get-ImportCount {
    $p = Join-Path $Fixture 'CLAUDE.md'
    if (-not (Test-Path -LiteralPath $p)) { return 0 }
    return @([System.IO.File]::ReadAllLines($p) | Where-Object { $_ -match '^\s*@' }).Count
}

try {
    Write-Host "== teardown.tests: specialists-teardown ==" -ForegroundColor Cyan

    # --- 1. Dry run is genuinely dry -----------------------------------------------------------------
    #     The default. A destructive script that runs on somebody's repo must not act unasked, and the
    #     preview is also the inventory a reader needs in order to say yes.
    New-BootstrappedConsumer | Out-Null
    $lensesBefore = Get-LensCount
    Assert-True ($lensesBefore -gt 0) "setup: the bootstrap placed lenses ($lensesBefore)"
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-Equal 0 $r.Code 'dry run: exit-code 0'
    Assert-True ($r.Out -match 'DRY RUN') 'dry run: says so up front'
    Assert-True ($r.Out -match 'to remove') 'dry run: reports items as "to remove", not "removed"'
    Assert-Equal $lensesBefore (Get-LensCount) 'dry run: removed NOTHING -- lens count unchanged'
    Assert-Equal 2 (Get-ImportCount) 'dry run: the @-imports are still there'
    Assert-True ($r.Out -match 'Re-run with -Apply') 'dry run: tells the reader how to act'

    # --- 2. -Apply removes the generated set ---------------------------------------------------------
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-Equal 0 $r.Code 'apply: exit-code 0'
    Assert-Equal 0 (Get-LensCount) 'apply: every generated lens is gone'
    Assert-Equal 0 (Get-ImportCount) 'apply: both @-imports are gone from CLAUDE.md'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture 'scripts\repo-config.ps1'))) 'apply: the untouched repo-config scaffold is gone'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture 'scripts\lib\branch-info.ps1'))) 'apply: the untouched branch-info scaffold is gone'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture '.claude\settings.suggested.jsonc'))) 'apply: the settings proposal is gone'
    # The owner's own file must survive having two lines cut out of it.
    $md = [System.IO.File]::ReadAllText((Join-Path $Fixture 'CLAUDE.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($md -match 'Feature work goes on a branch') "apply: the owner's own CLAUDE.md prose is intact"
    Assert-True ($md -match '# CLAUDE.md - my own project') "apply: the owner's heading is intact"

    # --- 3. settings.json is never edited -----------------------------------------------------------
    #     Disabling the plugin is the owner's act, and the bootstrap never wrote this file either. The
    #     symmetry that makes the teardown safe to run cuts both ways.
    $settings = [System.IO.File]::ReadAllText((Join-Path $Fixture '.claude\settings.json'), [System.Text.Encoding]::UTF8)
    Assert-True ($settings -match 'specialists@davekjohns-workshop') 'settings.json: still enables the plugin -- never edited'
    Assert-True ($r.Out -match 'That file is yours') "settings.json: reported as the owner's to change"
    Assert-True ($r.Out -match 'restart') 'settings.json: the note says a restart is needed'

    # --- 4. Idempotent: a second run finds nothing and does not fail ---------------------------------
    $r2 = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-Equal 0 $r2.Code 'second run: exit-code 0 (idempotent, like the bootstrap)'
    Assert-True ($r2.Out -match 'Summary: 0 item') 'second run: nothing left to remove'

    # --- 5. THE SAFETY PROPERTY: authored content is kept, not deleted ------------------------------
    #     The assertion this whole script exists to earn. Deleting a filled-in lens to leave a tidy tree
    #     destroys repo knowledge somebody wrote -- a worse outcome than leaving clutter.
    New-BootstrappedConsumer | Out-Null
    $authoredLens = Join-Path $Fixture '.claude\plugins\claude-specialists\specialists\06-16-extension.md'
    [System.IO.File]::WriteAllText($authoredLens, "# 06-16 repo lens`n`n## Specific to this repo`n`nTessa guards our API docs under docs/api/.")
    $authoredRc = Join-Path $Fixture 'scripts\repo-config.ps1'
    [System.IO.File]::WriteAllText($authoredRc, "function Get-RepoName { return 'someone/my-repo' }`nfunction Get-LintScript { return 'scripts/lint.ps1' }")
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-Equal 0 $r.Code 'authored content: exit-code 0'
    Assert-True (Test-Path -LiteralPath $authoredLens) 'authored content: the filled-in lens is KEPT'
    Assert-True (Test-Path -LiteralPath $authoredRc) 'authored content: the filled-in repo-config is KEPT'
    Assert-Equal 1 (Get-LensCount) 'authored content: exactly the authored lens remains'
    Assert-True ($r.Out -match '\[KEEP\]') 'authored content: reported as kept, not silently skipped'
    Assert-True ($r.Out -match 'delete by hand') 'authored content: the reader is told how to finish if they want to'
    # The directory must survive too -- pruning it would take the authored lens with it.
    Assert-True (Test-Path -LiteralPath (Join-Path $Fixture '.claude\plugins')) 'authored content: the lens directory is not pruned while a kept file lives in it'
    # And the branch-info scaffold was still untouched, so it must still have gone.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture 'scripts\lib\branch-info.ps1'))) 'authored content: the still-untouched scaffold is removed as normal'

    # --- 6. An unrelated @-import is NOT eaten ------------------------------------------------------
    #     The sharpest risk in the design. The matcher must key on the specialist shape
    #     (-persona.md / -extension.md), not merely on a line starting with '@' -- a consumer's own
    #     '@docs/git-instructions.md' import is exactly the kind of line that a sloppy rule destroys,
    #     and the consumer would have no idea why their instructions stopped loading.
    New-BootstrappedConsumer -ExtraClaudeMdLines @('', '@docs/git-instructions.md', '@~/.claude/my-notes.md') | Out-Null
    Assert-Equal 4 (Get-ImportCount) "unrelated imports: setup has 4 imports (2 specialist + 2 of the owner's)"
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-Equal 0 $r.Code 'unrelated imports: exit-code 0'
    Assert-Equal 2 (Get-ImportCount) "unrelated imports: only the 2 specialist imports were removed"
    $md = [System.IO.File]::ReadAllText((Join-Path $Fixture 'CLAUDE.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($md -match [regex]::Escape('@docs/git-instructions.md')) "unrelated imports: the owner's own import survives"
    Assert-True ($md -match [regex]::Escape('@~/.claude/my-notes.md')) "unrelated imports: the owner's home-dir import survives"
    Assert-True (-not ($md -match '01-01-persona\.md')) 'unrelated imports: the persona import is gone'
    Assert-True (-not ($md -match '01-01-extension\.md')) 'unrelated imports: the lens import is gone'

    # --- 7. A repo that never adopted is a no-op, not an error --------------------------------------
    $bare = Join-Path ([System.IO.Path]::GetTempPath()) 'specialists-teardown-bare'
    if (Test-Path -LiteralPath $bare) { Remove-Item -Recurse -Force -LiteralPath $bare }
    New-Item -ItemType Directory -Path $bare -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $bare 'CLAUDE.md'), "# plain project`n`nnothing to do with specialists.")
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $bare, '-Apply')
    Assert-Equal 0 $r.Code 'never adopted: exit-code 0'
    Assert-True ($r.Out -match 'Summary: 0 item') 'never adopted: nothing to remove'
    $md = [System.IO.File]::ReadAllText((Join-Path $bare 'CLAUDE.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($md -match 'nothing to do with specialists') 'never adopted: the file is untouched'
    Remove-Item -Recurse -Force -LiteralPath $bare -ErrorAction SilentlyContinue
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
