<#
.SYNOPSIS
    Tests for the shared lens-location helpers in scripts/lib/check-report-lib.ps1.

.DESCRIPTION
    These functions decide WHERE a consumer's repo lenses live, which makes them the single point every
    reader (the roster check, the drift lint, the teardown) and every writer (the bootstrap) agrees on.
    They had no direct test before the seam (issue #221) was added -- only indirect coverage through the
    suites that happen to call them, which is exactly the kind of shared decision that deserves its own
    assertions.

    The interesting one is Get-LensWriteDir. It encodes a promise that is easy to break by accident:
    the bootstrap never relocates a lens tree the repo owner already has, so a consumer who adopted
    before the seam keeps their layout, and a consumer who migrates by hand is followed automatically.

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $RepoRoot 'scripts\lib\check-report-lib.ps1')

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

$Fixture = Join-Path ([System.IO.Path]::GetTempPath()) "check-report-lib-test-$PID"

try {
    Write-Host "== check-report-lib.tests: lens locations and the seam ==" -ForegroundColor Cyan
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture }
    New-Item -ItemType Directory -Path $Fixture -Force | Out-Null

    # --- 1. Get-SeamPaths: the literals the bootstrap writes and the teardown matches ---------------
    #     One source for both sides. If these drift the bootstrap writes a line the teardown cannot
    #     find, and the consumer is left with a dangling import -- silent, because nothing errors.
    Write-Host "Get-SeamPaths -- the shared literals" -ForegroundColor Cyan
    $seam = Get-SeamPaths -RepoRoot $Fixture
    Assert-Equal (Join-Path $Fixture '.claude\specialists') $seam.Dir 'seam dir is .claude\specialists'
    Assert-Equal (Join-Path $Fixture '.claude\specialists\lenses') $seam.LensDir 'lenses live in the seam dir'
    Assert-Equal (Join-Path $Fixture '.claude\specialists\SPECIALISTS.md') $seam.Inclusion 'the inclusion is SPECIALISTS.md'
    Assert-Equal '@.claude/specialists/SPECIALISTS.md' $seam.ImportLine 'the import line is exactly the seam line'
    # An '@'-import path is not a filesystem path: it must read identically on every platform, so a
    # backslash must never leak into it from Join-Path.
    Assert-True (-not ($seam.ImportLine -match '\\')) 'the import line is forward-slashed, never backslashed'

    # --- 2. Get-LensDirCandidates: the seam is the most canonical, legacy still follows -------------
    Write-Host "Get-LensDirCandidates -- order and back-compat" -ForegroundColor Cyan
    $cands = @(Get-LensDirCandidates -RepoRoot $Fixture -PluginName 'specialists')
    Assert-Equal $seam.LensDir $cands[0] 'the seam is candidate 0 -- the most canonical'
    Assert-True ($cands -contains (Join-Path $Fixture '.claude\plugins\claude-specialists\specialists')) 'the pre-seam plugin path is still read'
    Assert-Equal (Join-Path $Fixture '.claude\extensions') $cands[-1] 'the legacy pre-plugin-path location is still read, and stays last'

    # --- 3. Get-LensWriteDir: THE PROMISE -- never relocate an existing tree ------------------------
    #     Fresh consumer -> the seam. A consumer that already has lenses somewhere -> that same place,
    #     because writing seam lenses beside a legacy tree would split the surface in two and leave the
    #     teardown reasoning about both at once.
    Write-Host "Get-LensWriteDir -- fresh gets the seam, an adopted consumer is left alone" -ForegroundColor Cyan
    Assert-Equal $seam.LensDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'specialists') 'fresh consumer: writes to the seam'

    $legacyDir = Join-Path $Fixture '.claude\plugins\claude-specialists\specialists'
    New-Item -ItemType Directory -Path $legacyDir -Force | Out-Null
    $legacyLens = Join-Path $legacyDir '06-16-extension.md'
    [System.IO.File]::WriteAllText($legacyLens, "# 06-16 repo lens`n")
    Assert-Equal $legacyDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'specialists') 'adopted consumer: keeps writing to its existing tree, not the seam'

    # An EMPTY legacy directory is not an adopted consumer -- only an actual lens counts, so a stray
    # leftover folder does not pin a fresh repo to the old layout.
    Remove-Item -LiteralPath $legacyLens -Force
    Assert-Equal $seam.LensDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'specialists') 'an empty legacy directory does not count as adopted'

    # And once the owner migrates by hand, the writer follows them without being told.
    New-Item -ItemType Directory -Path $seam.LensDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $seam.LensDir '06-16-extension.md'), "# 06-16 repo lens`n")
    Assert-Equal $seam.LensDir (Get-LensWriteDir -RepoRoot $Fixture -PluginName 'specialists') 'after a hand migration the writer follows to the seam automatically'

    # --- 4. Write-Coverage: a verdict never travels without its coverage (issue #221) ----------------
    #     The line exists so an empty category cannot pass in silence, so the assertions are about
    #     exactly that: the zero must be PRESENT and must be distinguishable from a healthy count.
    Write-Host "Write-Coverage -- the non-counting [COVERAGE] line" -ForegroundColor Cyan
    # $script:errors/$script:infos are what the lib's Write-Info/Write-Failure bump. Coverage is
    # context, not a signal, so these must be untouched afterwards -- otherwise a legitimately empty
    # category would break its own gate, which is the opposite of the point.
    $script:errors = 0
    $script:infos = 0

    $out = (Write-Coverage -Category 'lenses' -Checked 0 -Of 4 -Note 'nothing to compare' 6>&1 | Out-String)
    Assert-True ($out -match '\[lenses\] checked 0 of 4 -- nothing to compare') 'empty category: category, count, denominator and reason all on one line'
    Assert-Equal 0 $script:errors 'empty category does NOT count as an error -- an empty category is a fact, not a failure'
    Assert-Equal 0 $script:infos  'empty category does NOT count as an info signal either -- [COVERAGE] is non-counting, like [OK]/[SKIP]/[SCOPE]'

    $out = (Write-Coverage -Category 'lenses' -Checked 4 -Of 4 6>&1 | Out-String)
    Assert-True ($out -match '\[lenses\] checked 4 of 4') 'healthy category: states the real count'
    Assert-True (-not ($out -match ' -- ')) 'healthy category: no reason appended when none was given'

    # -Of omitted: a category whose count IS the whole story (files scanned) reads as a plain number,
    # not as "of -1".
    $out = (Write-Coverage -Category 'parse' -Checked 51 6>&1 | Out-String)
    Assert-True ($out -match '\[parse\] checked 51') 'no denominator: plain count'
    Assert-True (-not ($out -match 'of -1')) 'no denominator: the sentinel never leaks into the output'

    # --- Get-SettingsChainPaths / Get-EnabledPlugins (inbound #294) -------------------------------
    #     The shared answer to "which plugins are enabled here", after three call sites each read
    #     .claude/settings.json alone and produced a false green, a silent skip and a false alarm from
    #     the identical blind spot. Direct assertions, because the ORDER and the PRECEDENCE are the
    #     substance: get either wrong and the callers are wrong in ways their own tests cannot see.
    Write-Host "Get-EnabledPlugins -- the settings chain" -ForegroundColor Cyan
    $chainRoot = Join-Path $Fixture 'chain'
    $userHome  = Join-Path $Fixture 'userhome'
    New-Item -ItemType Directory -Path (Join-Path $chainRoot '.claude') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $userHome '.claude') -Force | Out-Null
    $projFile  = Join-Path $chainRoot '.claude\settings.json'
    $localFile = Join-Path $chainRoot '.claude\settings.local.json'
    $userFile  = Join-Path $userHome  '.claude\settings.json'

    # Lowest precedence FIRST, so a caller that walks the list and overwrites gets local > project > user
    # for free. This order IS the contract -- reversing it silently inverts every precedence below.
    $chain = @(Get-SettingsChainPaths -RepoRoot $chainRoot -UserHomeOverride $userHome)
    Assert-Equal 3 $chain.Count 'chain: three layers (user, project, local)'
    Assert-Equal $userFile  $chain[0].Path 'chain: the user layer comes first (lowest precedence)'
    Assert-Equal $projFile  $chain[1].Path 'chain: .claude/settings.json second'
    Assert-Equal $localFile $chain[2].Path 'chain: .claude/settings.local.json last (highest precedence)'

    # Nothing anywhere: no file, no key -- distinguishable from "a key that enables nothing", because the
    # two mean different things to a reader (never configured vs. deliberately empty).
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 0 $e.Ids.Count 'no files: nothing enabled'
    Assert-True (-not $e.AnyFileExists) 'no files: AnyFileExists is false'
    Assert-True (-not $e.AnyKeyFound) 'no files: AnyKeyFound is false'
    Assert-Equal 'no settings file' $e.Summary 'no files: Summary says so instead of naming paths that do not exist'

    # THE #294 CASE: the enable lives only in settings.local.json, the file the plugin's own settings
    # proposal points the reader at and all three call sites used to ignore.
    [System.IO.File]::WriteAllText($localFile, '{ "enabledPlugins": { "specialists@davekjohns-workshop": true } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 'specialists@davekjohns-workshop' ($e.Ids -join ',') 'local-only: the enable is seen'
    Assert-Equal '.claude/settings.local.json' $e.LayerById['specialists@davekjohns-workshop'] 'local-only: the deciding layer is reported'
    Assert-True $e.AnyKeyFound 'local-only: AnyKeyFound is true'

    # Per-key precedence, the deliberate choice documented on the helper: a local 'false' switches off a
    # project 'true' rather than the layers replacing one another wholesale.
    [System.IO.File]::WriteAllText($projFile,  '{ "enabledPlugins": { "specialists@davekjohns-workshop": true } }')
    [System.IO.File]::WriteAllText($localFile, '{ "enabledPlugins": { "specialists@davekjohns-workshop": false } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 0 $e.Ids.Count 'precedence: a local false overrides a project true'
    Assert-True $e.AnyKeyFound 'precedence: the key WAS found -- "enables nothing", not "never configured"'
    Assert-Equal '.claude/settings.json and .claude/settings.local.json' $e.Summary 'precedence: Summary names both existing layers'

    # Per-key merge, the other half: a project enable and a local enable of a DIFFERENT plugin both count.
    # Wholesale replacement would drop the project one, which is the failure direction this helper must
    # never take -- losing an enable is how the false green happened.
    [System.IO.File]::WriteAllText($localFile, '{ "enabledPlugins": { "specialists-lifehub@davekjohns-workshop": true } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal 'specialists-lifehub@davekjohns-workshop,specialists@davekjohns-workshop' ($e.Ids -join ',') 'merge: layers combine per plugin id, they do not replace each other'

    # The user layer counts, and is overridable per key by the repo -- a plugin enabled machine-wide IS
    # loaded in every session, so excluding this layer would rebuild the same false green one level up.
    Remove-Item -LiteralPath $localFile -Force
    [System.IO.File]::WriteAllText($userFile, '{ "enabledPlugins": { "specialists-shopify@davekjohns-workshop": true } }')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-True ($e.Ids -contains 'specialists-shopify@davekjohns-workshop') 'user layer: a machine-wide enable counts'
    Assert-Equal 'user ~/.claude/settings.json' $e.LayerById['specialists-shopify@davekjohns-workshop'] 'user layer: named as the deciding layer'

    # A layer that does not parse is REPORTED, never thrown, and never silently turns the answer into
    # "nothing enabled" -- the rest of the chain still counts.
    [System.IO.File]::WriteAllText($localFile, '{ "enabledPlugins": { oops')
    $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
    Assert-Equal '.claude/settings.local.json' ($e.Unreadable -join ',') 'unparseable layer: reported by label, not thrown'
    Assert-True ($e.Ids -contains 'specialists@davekjohns-workshop') 'unparseable layer: the readable layers still counted'

    # --- Shapes that are VALID but easy to crash on -----------------------------------------------
    #     Found live, not by reasoning: a settings.json holding exactly '{ }' was reported as "does not
    #     parse". Under Set-StrictMode -Version Latest the usual
    #     '$obj.PSObject.Properties.Name -contains ...' idiom throws on an object with NO properties, and
    #     the catch then relabelled a perfectly good file as corrupt. These three shapes are all ordinary
    #     consumer states, so each must produce an ANSWER and never an Unreadable entry.
    Remove-Item -LiteralPath $userFile -Force
    foreach ($shape in @('{ }', '{ "enabledPlugins": { } }', '{ "enabledPlugins": null }', '{ "permissions": { "allow": [] } }')) {
        [System.IO.File]::WriteAllText($projFile, $shape)
        Remove-Item -LiteralPath $localFile -Force -ErrorAction SilentlyContinue
        $e = Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome
        Assert-Equal 0 @($e.Unreadable).Count "valid shape '$shape': not reported as unparseable"
        Assert-Equal 0 $e.Ids.Count "valid shape '$shape': nothing enabled"
        Assert-True $e.AnyFileExists "valid shape '$shape': the file is seen"
    }
    # ... and the key-present cases are still distinguishable from the no-key ones, because the two mean
    # different things to a reader ("deliberately empty" vs "never configured").
    [System.IO.File]::WriteAllText($projFile, '{ "enabledPlugins": { } }')
    Assert-True (Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome).AnyKeyFound 'empty enabledPlugins: AnyKeyFound is true'
    [System.IO.File]::WriteAllText($projFile, '{ }')
    Assert-True (-not (Get-EnabledPlugins -RepoRoot $chainRoot -UserHomeOverride $userHome).AnyKeyFound) 'no enabledPlugins key: AnyKeyFound is false'
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
