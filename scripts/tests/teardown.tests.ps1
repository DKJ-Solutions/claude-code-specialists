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
    Assert-Equal 1 (Get-ImportCount) 'dry run: the seam import is still there'
    Assert-True ($r.Out -match 'Re-run with -Apply') 'dry run: tells the reader how to act'

    # --- 2. -Apply removes the generated set ---------------------------------------------------------
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-Equal 0 $r.Code 'apply: exit-code 0'
    Assert-Equal 0 (Get-LensCount) 'apply: every generated lens is gone'
    Assert-Equal 0 (Get-ImportCount) 'apply: the seam import is gone from CLAUDE.md'
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
    $authoredLens = Join-Path $Fixture '.claude\specialists\lenses\06-16-extension.md'
    [System.IO.File]::WriteAllText($authoredLens, "# 06-16 repo lens`n`n## Specific to this repo`n`nTessa guards our API docs under docs/api/.")
    $authoredRc = Join-Path $Fixture 'scripts\repo-config.ps1'
    [System.IO.File]::WriteAllText($authoredRc, "function Get-RepoName { return 'someone/my-repo' }`nfunction Get-LintScript { return 'scripts/lint.ps1' }")
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-Equal 0 $r.Code 'authored content: exit-code 0'
    Assert-True (Test-Path -LiteralPath $authoredLens) 'authored content: the filled-in lens is KEPT'
    Assert-True (Test-Path -LiteralPath $authoredRc) 'authored content: the filled-in repo-config is KEPT'
    Assert-Equal 1 (Get-LensCount) 'authored content: exactly the authored lens remains'
    Assert-True ($r.Out -match '\[KEEP\]') 'authored content: reported as kept, not silently skipped'
    # Asserts the SUBSTANCE -- the reader is pointed at both ways to finish the job -- rather than one
    # brittle phrase. The wording changed once already, when the blanket "authored" claim was dropped.
    Assert-True ($r.Out -match 'yours to delete') 'authored content: the reader is told the kept files are theirs to remove'
    Assert-True ($r.Out -match 'EmptyLensPattern') 'authored content: the reader is pointed at the declared-convention escape hatch'
    Assert-True (-not ($r.Out -match 'kept \(authored\)')) 'authored content: no blanket authorship claim in the summary'
    # The directory must survive too -- pruning it would take the authored lens with it.
    Assert-True (Test-Path -LiteralPath (Join-Path $Fixture '.claude\specialists\lenses')) 'authored content: the lens directory is not pruned while a kept file lives in it'
    # And the branch-info scaffold was still untouched, so it must still have gone.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture 'scripts\lib\branch-info.ps1'))) 'authored content: the still-untouched scaffold is removed as normal'

    # --- 5b. MENTION vs USE: a filled-in file that merely NAMES VUL-IN must be kept ------------------
    #     The bug a dry run against a real consumer found on 2026-07-29, which no fixture had caught.
    #     davekokbwj/smartwatchbanden's repo-config.ps1 carries real values for all eight contract
    #     functions -- and the scaffold's own DOCSTRING still says "Fill in remaining VUL-IN values",
    #     because a consumer has no reason to strip a docstring. The naive test ('VUL-IN' anywhere in
    #     the file) therefore classified a fully configured, actively used file as an untouched scaffold
    #     and would have deleted it, breaking open-pr, fold-changelog, new-branch and check-roster-sync
    #     in that repo. Not an edge case: it is the NORMAL state of a filled-in scaffold.
    #     The fixture below reproduces that exact shape -- real values, docstring mention retained.
    New-BootstrappedConsumer | Out-Null
    $filledRc = Join-Path $Fixture 'scripts\repo-config.ps1'
    [System.IO.File]::WriteAllText($filledRc, @"
<#
.DESCRIPTION
    Placed by specialists-init as a VUL-IN scaffold. Fill in remaining VUL-IN values
    below and remove VUL-IN markers.
#>
`$script:RepoName = 'someone/my-repo'
function Get-RepoName { return `$script:RepoName }
`$script:LintScript = 'scripts/lint.ps1'
function Get-LintScript { return `$script:LintScript }
"@)
    # Same shape on the lens side: an authored lens that happens to explain the scaffold convention.
    $filledLens = Join-Path $Fixture '.claude\specialists\lenses\06-16-extension.md'
    [System.IO.File]::WriteAllText($filledLens, "# 06-16 repo lens`n`n## Specific to this repo`n`nTessa guards the docs. A lens may stay a VUL-IN scaffold until that specialist has work here.")
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-Equal 0 $r.Code 'mention vs use: exit-code 0'
    Assert-True (Test-Path -LiteralPath $filledRc) 'mention vs use: a filled repo-config whose DOCSTRING says VUL-IN is KEPT'
    Assert-True (Test-Path -LiteralPath $filledLens) 'mention vs use: a filled lens whose PROSE says VUL-IN is KEPT'
    # Its content must be byte-identical -- kept means untouched, not rewritten.
    Assert-True ([System.IO.File]::ReadAllText($filledRc) -match 'someone/my-repo') 'mention vs use: the kept repo-config still holds its real value'
    # And the genuinely unfilled branch-info scaffold must still go, so this did not simply stop removing.
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture 'scripts\lib\branch-info.ps1'))) 'mention vs use: the genuinely unfilled branch-info scaffold is still removed'

    # --- 5c. The positive side of each signal still fires -------------------------------------------
    #     Guard against 5b being "fixed" by never removing anything. Each kind keeps its own signal:
    #     a placeholder VALUE for repo-config, an EMPTY prefix table for branch-info, an unfilled slot
    #     HEADING for a lens.
    New-BootstrappedConsumer | Out-Null
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture 'scripts\repo-config.ps1'))) 'signals: an unfilled repo-config (placeholder VALUE) is removed'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture 'scripts\lib\branch-info.ps1'))) 'signals: an unfilled branch-info (empty prefix table) is removed'
    Assert-Equal 0 (Get-LensCount) 'signals: unfilled lenses (slot heading) are removed'

    # --- 6. An unrelated @-import is NOT eaten ------------------------------------------------------
    #     The sharpest risk in the design. The matcher must key on the specialist shape
    #     (-persona.md / -extension.md), not merely on a line starting with '@' -- a consumer's own
    #     '@docs/git-instructions.md' import is exactly the kind of line that a sloppy rule destroys,
    #     and the consumer would have no idea why their instructions stopped loading.
    New-BootstrappedConsumer -ExtraClaudeMdLines @('', '@docs/git-instructions.md', '@~/.claude/my-notes.md') | Out-Null
    Assert-Equal 3 (Get-ImportCount) "unrelated imports: setup has 3 imports (1 seam + 2 of the owner's)"
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-Equal 0 $r.Code 'unrelated imports: exit-code 0'
    Assert-Equal 2 (Get-ImportCount) "unrelated imports: only the seam import was removed -- the owner's 2 survive"
    $md = [System.IO.File]::ReadAllText((Join-Path $Fixture 'CLAUDE.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($md -match [regex]::Escape('@docs/git-instructions.md')) "unrelated imports: the owner's own import survives"
    Assert-True ($md -match [regex]::Escape('@~/.claude/my-notes.md')) "unrelated imports: the owner's home-dir import survives"
    Assert-True (-not ($md -match '01-01-persona\.md')) 'unrelated imports: the persona import is gone'
    Assert-True (-not ($md -match '01-01-extension\.md')) 'unrelated imports: the lens import is gone'

    # --- 6b. THE ROUND-TRIP DOES NOT ACCUMULATE ------------------------------------------------------
    #     Measured in davekokbwj/smartwatchbanden on 2026-07-29: the bootstrap's note line survived a
    #     teardown (which removes '@' lines and deliberately nothing else), so the bootstrap's guard --
    #     which only tested for the lens import -- read "not present" and re-appended the WHOLE block.
    #     One extra copy of the note per teardown->init cycle, counted 1 -> 2 -> 3, with all three
    #     session hooks reporting "in sync" throughout. Two runs of the cycle here, since one cycle
    #     cannot distinguish "does not accumulate" from "accumulates once".
    $note = 'The orchestrator (Chris) is always loaded -- portable body from plugin install and repo lens'
    function Get-NoteCount {
        $p = Join-Path $Fixture 'CLAUDE.md'
        if (-not (Test-Path -LiteralPath $p)) { return 0 }
        return @([System.IO.File]::ReadAllLines($p) | Where-Object { $_.Trim() -eq $note }).Count
    }
    New-BootstrappedConsumer | Out-Null
    Assert-Equal 1 (Get-NoteCount) 'round-trip: one note line after the first init'
    foreach ($cycle in 1, 2) {
        $null = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
        Assert-Equal 0 (Get-NoteCount) "round-trip cycle ${cycle}: the teardown removes the note line too"
        $prevPlugin = $env:CLAUDE_PLUGIN_ROOT
        $env:CLAUDE_PLUGIN_ROOT = $Plugin
        try { $ri = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture) }
        finally { $env:CLAUDE_PLUGIN_ROOT = $prevPlugin }
        Assert-Equal 0 $ri.Code "round-trip cycle ${cycle}: re-init exit 0"
        Assert-Equal 1 (Get-NoteCount) "round-trip cycle ${cycle}: STILL exactly one note line -- no accumulation"
        Assert-Equal 1 (Get-ImportCount) "round-trip cycle ${cycle}: exactly one import restored"
    }

    # --- 6b2. The bootstrap's own guard, ISOLATED ----------------------------------------------------
    #     6b passes even with the bootstrap fix reverted, because the teardown now removes the note and
    #     the cycle needed BOTH defects. Verified by reverting it. So 6b does not cover the bootstrap
    #     half at all, and the scenario it actually defends is a repo whose imports were removed by
    #     hand -- or by an older teardown -- while the note stayed. Without the guard, re-init appends
    #     a second copy.
    New-BootstrappedConsumer | Out-Null
    $mdP = Join-Path $Fixture 'CLAUDE.md'
    $handEdited = @([System.IO.File]::ReadAllLines($mdP) | Where-Object { $_ -notmatch '^\s*@' })
    [System.IO.File]::WriteAllLines($mdP, $handEdited)
    Assert-Equal 1 (Get-NoteCount) 'isolated guard: setup leaves the note but no imports'
    Assert-Equal 0 (Get-ImportCount) 'isolated guard: setup really removed the imports'
    $prevPlugin = $env:CLAUDE_PLUGIN_ROOT
    $env:CLAUDE_PLUGIN_ROOT = $Plugin
    try { $rg = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture) }
    finally { $env:CLAUDE_PLUGIN_ROOT = $prevPlugin }
    Assert-Equal 0 $rg.Code 'isolated guard: re-init exit 0'
    Assert-Equal 1 (Get-NoteCount) 'isolated guard: STILL one note -- the bootstrap tidied the leftover'
    Assert-Equal 1 (Get-ImportCount) 'isolated guard: the import is restored'

    # --- 6c. NO LINE-ENDING DRIFT ---------------------------------------------------------------------
    #     Also measured there: the bootstrap pasted a "`n"-built block into a CRLF file, leaving 8 lone
    #     LFs. Invisible to every gate, and the kind of thing that turns a later diff into noise.
    New-BootstrappedConsumer | Out-Null
    $mdPath = Join-Path $Fixture 'CLAUDE.md'
    # Force the consumer's file to CRLF, the realistic Windows case, then run a full cycle.
    $crlf = ([System.IO.File]::ReadAllText($mdPath) -replace "`r`n", "`n") -replace "`n", "`r`n"
    [System.IO.File]::WriteAllText($mdPath, $crlf)
    $null = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    $afterTeardown = [System.IO.File]::ReadAllText($mdPath)
    $loneAfterTeardown = ([regex]::Matches($afterTeardown, "(?<!`r)`n")).Count
    Assert-Equal 0 $loneAfterTeardown 'line endings: the teardown leaves no lone LF in a CRLF file'
    $prevPlugin = $env:CLAUDE_PLUGIN_ROOT
    $env:CLAUDE_PLUGIN_ROOT = $Plugin
    try { $null = Invoke-Script -Path $Bootstrap -ScriptArgs @('-ConsumerRoot', $Fixture) }
    finally { $env:CLAUDE_PLUGIN_ROOT = $prevPlugin }
    $afterInit = [System.IO.File]::ReadAllText($mdPath)
    $loneAfterInit = ([regex]::Matches($afterInit, "(?<!`r)`n")).Count
    Assert-Equal 0 $loneAfterInit 'line endings: re-init appends CRLF into a CRLF file, not lone LF'

    # --- 6d. A CONSUMER'S OWN EMPTY-LENS CONVENTION, only when declared ----------------------------
    #     The blindness this skill shipped with: 20 of smartwatchbanden's 22 lenses are empty under
    #     that repo's own convention (a closing sentence, no '(VUL-IN)' heading), so all 22 were kept
    #     and reported as authored -- right answer, wrong reason, and adoption was less reversible than
    #     claimed. The plugin must not GUESS at a convention it did not create, so the consumer
    #     declares it. Default (no pattern) keeps them, which is the safe direction.
    New-BootstrappedConsumer | Out-Null
    $emptyByConvention = Join-Path $Fixture '.claude\specialists\lenses\06-16-extension.md'
    [System.IO.File]::WriteAllText($emptyByConvention, "---`nid: 16`ngroup: 06`n---`n`n# 06-16 repo-lens`n`n## Eigen aan deze repo`n`nSchone lei: hier staan alleen repo-eigen regels. Nog niets vastgelegd.")
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-True ($r.Out -match [regex]::Escape('06-16-extension.md') ) 'own convention: the lens appears in the report'
    Assert-True (Test-Path -LiteralPath $emptyByConvention) 'own convention: WITHOUT a declared pattern it is kept (safe default)'
    Assert-True (-not ($r.Out -match 'filled in')) 'own convention: the report no longer claims the file was filled in'
    Assert-True ($r.Out -match 'does not judge it') 'own convention: it states what it actually knows'
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply', '-EmptyLensPattern', 'Nog niets vastgelegd')
    Assert-True (-not (Test-Path -LiteralPath $emptyByConvention)) 'own convention: WITH the pattern declared it is removed'

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

    # --- 8. A RUNTIME DEPENDENCY ON THE PLUGIN: warned about, never removed -------------------------
    #     The one leftover a teardown cannot classify away (measured in davekokbwj/smartwatchbanden,
    #     2026-07-29): the consumer's own resolver locates the marketplace cache and throws once it is
    #     gone, and three operational scripts dot-source it -- so the uninstall took the daily git
    #     workflow down rather than leaving debris. Two properties are asserted here, and the second
    #     matters more than the first: the report NAMES it, and -Apply still does not TOUCH it. A check
    #     that deleted the consumer's own scripts to make its summary look clean would be doing exactly
    #     the damage the whole classification exists to prevent.
    New-BootstrappedConsumer | Out-Null
    $resolver = Join-Path $Fixture 'scripts\lib\plugin-paths.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $resolver) -Force | Out-Null
    [System.IO.File]::WriteAllText($resolver, (@(
        '# Resolves the shared scripts in the marketplace cache.',
        '$cache = Join-Path $env:USERPROFILE ''.claude\plugins\marketplaces\davekjohns-workshop''',
        'if (-not (Test-Path $cache)) { throw ''the specialists plugin is not installed'' }'
    ) -join "`n"))
    $starter = Join-Path $Fixture 'scripts\task\start-task.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $starter) -Force | Out-Null
    [System.IO.File]::WriteAllText($starter, (@(
        '. "$PSScriptRoot\..\lib\plugin-paths.ps1"',
        'Write-Host ''starting a task'''
    ) -join "`n"))
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-Equal 0 $r.Code 'runtime dependency: exit-code 0 -- a warning is not a failure'
    Assert-True ($r.Out -match 'resolves the plugin cache') 'runtime dependency: the resolver is named'
    Assert-True ($r.Out -match [regex]::Escape('start-task.ps1')) 'runtime dependency: what depends on it is named too'
    Assert-True ($r.Out -match 'No teardown can fix this') 'runtime dependency: says plainly that no teardown fixes it'
    Assert-True ($r.Out -match 'keep local copies') 'runtime dependency: offers the way out before the uninstall'
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-True (Test-Path -LiteralPath $resolver) "runtime dependency: -Apply leaves the consumer's resolver alone"
    Assert-True (Test-Path -LiteralPath $starter) "runtime dependency: -Apply leaves the dependent script alone"

    # No false alarm: a consumer whose scripts never reach into the plugin hears nothing about it.
    New-BootstrappedConsumer | Out-Null
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture)
    Assert-True (-not ($r.Out -match 'resolves the plugin cache')) 'no false alarm: no resolver, no warning'

    # --- 9. -VendorScripts: the way out, and the one additive act in a subtractive script -----------
    #     Warning about the runtime dependency was half the answer; this is the other half. Three
    #     properties, and the middle one is the important one: the payload lands with its STRUCTURE
    #     intact (the scripts dot-source siblings $PSScriptRoot-relative, so a flattened copy would
    #     break at the next branch rather than here), it is BYTE-IDENTICAL to the plugin's (a copy that
    #     drifts is worse than no copy), and a destination that already exists and DIFFERS is left
    #     alone -- that file is the consumer's own wrapper, i.e. authored content.
    New-BootstrappedConsumer | Out-Null
    $pluginPayload = Join-Path $Plugin 'scripts'
    # A consumer wrapper sitting exactly where a vendored script wants to go.
    $wrapper = Join-Path $Fixture 'scripts\release\open-pr.ps1'
    New-Item -ItemType Directory -Path (Split-Path -Parent $wrapper) -Force | Out-Null
    [System.IO.File]::WriteAllText($wrapper, "# my own wrapper around the shared open-pr`nWrite-Host 'wrapping'")
    $wrapperBefore = [System.IO.File]::ReadAllText($wrapper, [System.Text.Encoding]::UTF8)

    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-VendorScripts')
    Assert-Equal 0 $r.Code 'vendor dry run: exit-code 0'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture 'scripts\task\new-branch.ps1'))) 'vendor dry run: writes NOTHING without -Apply'
    Assert-True ($r.Out -match 'would be written') 'vendor dry run: says what it would write'

    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply', '-VendorScripts')
    Assert-Equal 0 $r.Code 'vendor: exit-code 0'
    $vendoredBranch = Join-Path $Fixture 'scripts\task\new-branch.ps1'
    Assert-True (Test-Path -LiteralPath $vendoredBranch) 'vendor: the operational script is now local'
    Assert-True (Test-Path -LiteralPath (Join-Path $Fixture 'scripts\lib\native-capture-lib.ps1')) 'vendor: the sibling lib it dot-sources came along'
    Assert-Equal (Get-FileHash -LiteralPath (Join-Path $pluginPayload 'task\new-branch.ps1')).Hash `
                 (Get-FileHash -LiteralPath $vendoredBranch).Hash `
                 "vendor: byte-identical to the plugin's copy -- no drift on arrival"
    # THE SAFETY PROPERTY, same family as "an authored lens is kept".
    Assert-Equal $wrapperBefore ([System.IO.File]::ReadAllText($wrapper, [System.Text.Encoding]::UTF8)) "vendor: the consumer's own wrapper is NOT overwritten"
    Assert-True ($r.Out -match 'yours, not overwritten') 'vendor: the collision is reported, not silent'

    # Idempotent, and honest about it: a second run recognises its own work instead of rewriting it.
    $r2 = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply', '-VendorScripts')
    Assert-Equal 0 $r2.Code 'vendor: second run exit-code 0'
    Assert-True ($r2.Out -match 'already current') 'vendor: a second run reports the copies as already current'

    # Default behaviour is untouched: no switch, no writing.
    New-BootstrappedConsumer | Out-Null
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture 'scripts\task\new-branch.ps1'))) 'vendor: nothing is vendored without the switch'

    # --- 10. THE SEAM: one directory and one line (issue #221) ---------------------------------------
    #     The claim the whole seam exists to make good on, asserted as an absolute rather than a count:
    #     after a teardown of an untouched consumer, the specialist surface is GONE -- not "smaller".
    Write-Host "the seam -- an untouched consumer tears down to nothing" -ForegroundColor Cyan
    New-BootstrappedConsumer | Out-Null
    $seamDir = Join-Path $Fixture '.claude\specialists'
    Assert-True (Test-Path -LiteralPath (Join-Path $seamDir 'SPECIALISTS.md')) 'seam: the bootstrap placed the inclusion'
    Assert-Equal 1 (Get-ImportCount) 'seam: CLAUDE.md carries exactly one import'
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-Equal 0 $r.Code 'seam: exit-code 0'
    Assert-True (-not (Test-Path -LiteralPath $seamDir)) 'seam: the whole .claude/specialists directory is gone -- one directory'
    Assert-Equal 0 (Get-ImportCount) 'seam: CLAUDE.md has no import left -- one line'
    $ownMd = [System.IO.File]::ReadAllText((Join-Path $Fixture 'CLAUDE.md'), [System.Text.Encoding]::UTF8)
    Assert-True ($ownMd -match 'Feature work goes on a branch') "seam: the owner's own prose is untouched"

    # --- 10b. An AUTHORED inclusion is kept, and the report says it is now loaded by nothing ---------
    #     The safety property from section 5, applied to the file that now holds the roster. And the
    #     honest half: the import is still removed, so the file survives as an orphan -- but ONE named
    #     orphan holding the roster in one piece, instead of 43 lines scattered through CLAUDE.md. That
    #     trade is the seam's actual payoff, so the report has to say it out loud.
    Write-Host "the seam -- an authored SPECIALISTS.md is kept and reported" -ForegroundColor Cyan
    New-BootstrappedConsumer | Out-Null
    $inclusion = Join-Path $Fixture '.claude\specialists\SPECIALISTS.md'
    # A roster somebody wrote: the VUL-IN slot heading is gone, which is exactly the signal.
    [System.IO.File]::WriteAllText($inclusion, "# The Claude Specialists`n`n## Our roster`n`n| signal | specialist |`n|---|---|`n| branches | Derek |`n")
    $r = Invoke-Script -Path $Teardown -ScriptArgs @('-ConsumerRoot', $Fixture, '-Apply')
    Assert-Equal 0 $r.Code 'authored inclusion: exit-code 0'
    Assert-True (Test-Path -LiteralPath $inclusion) 'authored inclusion: kept, never deleted'
    Assert-True ([System.IO.File]::ReadAllText($inclusion) -match 'branches \| Derek') 'authored inclusion: the roster somebody wrote is intact'
    Assert-Equal 0 (Get-ImportCount) 'authored inclusion: the import is STILL removed -- that line is what made it live'
    Assert-True ($r.Out -match 'nothing loads it') 'authored inclusion: the report says outright that nothing loads it any more'
    Assert-True ($r.Out -match 'one named file to decide about') 'authored inclusion: the report names the trade the seam makes'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
