<#
.SYNOPSIS
    Regression tests for the retired-name guard (issue #1389): Get-RetiredBranchDocNames and
    Get-RetiredDocNameMention in entry-scaffold-lib.ps1, the check script
    scripts/lint/check-retired-doc-name.ps1, and the SessionStart hook
    retired-doc-name-sessioncheck.ps1.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/retired-doc-name-gate.tests.ps1

    THE NAMES COME FROM THE REAL DERIVATION, never from a literal here. Every case that needs a retired
    name reads it out of Get-RetiredBranchDocNames, so the next rename reaches these cases automatically
    instead of leaving a second list of names to go stale in the file whose job is to prove there is only
    one. The two asserts that DO name a literal are the ones about the literals themselves -- that
    'development.md' (the measured instance) is in the set, and that today's name is not.

    THE TWO CASES THE ISSUE MEASURED both appear here in the shape they were found in: a consumer's
    CLAUDE.md restating the retired shared name, and a consumer's contributing-davekjohn/CONTRIBUTING.md
    doing the same -- the second being the one #1380's term-based detector missed, which is why the
    document set includes that page rather than only the always-on closure.

    Fixture paths carry $PID (repo convention): the test gate is a throttled parallel scheduler, so two
    runs overlapping is ordinary and two sharing one fixed temp path tear down each other's tree.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\lint\check-retired-doc-name.ps1'
$Hook     = Join-Path $RepoRoot 'plugins\workflows\contributing-davekjohn\hooks\retired-doc-name-sessioncheck.ps1'
. (Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1')
. (Join-Path $RepoRoot 'scripts\lib\measure-context-lib.ps1')

$script:pass  = 0
$script:fail  = 0
$script:trees = @()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message" -ForegroundColor Red }
}

function New-Tree {
    param([Parameter(Mandatory = $true)][string]$Label)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("retiredname-$PID-$Label-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    New-Item -ItemType Directory -Path (Join-Path $dir 'contributing-davekjohn') -Force | Out-Null
    $script:trees += $dir
    return $dir
}

function Set-Text {
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][string]$Rel,
        [Parameter(Mandatory = $true)][string]$Text
    )
    $target = Join-Path $Dir ($Rel -replace '/', '\')
    $parent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllText($target, $Text + "`n", (New-Object System.Text.UTF8Encoding($false)))
}

function Get-Mentions {
    # The lib the way the check calls it: the always-on closure from this tree's CLAUDE.md, plus the
    # folder's own pages, which the lib adds itself.
    param([Parameter(Mandatory = $true)][string]$Dir)
    $docs = @()
    $root = Join-Path $Dir 'CLAUDE.md'
    if (Test-Path -LiteralPath $root -PathType Leaf) {
        $docs = @(Get-AlwaysOnDocuments -RootDocument $root -RepoRoot $Dir)
    }
    return @(Get-RetiredDocNameMention -RepoRoot $Dir -Documents $docs)
}

function Invoke-Script {
    param([Parameter(Mandatory = $true)][string]$Dir)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -RootOverride $Dir 2>&1
    } finally { $ErrorActionPreference = $prevEap }
    return @{ Out = ($out | Out-String); Code = $LASTEXITCODE }
}

function Invoke-Hook {
    # -CheckScriptOverride defaults to the source check script: a bare test run has no
    # CLAUDE_PLUGIN_ROOT, which is the hook's only other way to find it. Pass an explicit path to
    # exercise the "not found" branch.
    param([Parameter(Mandatory = $true)][string]$Dir, [string]$CheckScriptOverride = $Script)
    $hookArgs = @('-ConsumerPathOverride', $Dir)
    if ($CheckScriptOverride) { $hookArgs += @('-CheckScriptOverride', $CheckScriptOverride) }
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Hook @hookArgs 2>&1
    } finally { $ErrorActionPreference = $prevEap }
    return @{ Out = ($out | Out-String); Code = $LASTEXITCODE }
}

try {
    # --- Get-RetiredBranchDocNames, the derivation ------------------------------------------------
    Write-Host 'Get-RetiredBranchDocNames'

    $names = @(Get-RetiredBranchDocNames)
    Assert-True ($names.Count -ge 2) 'the set is non-empty and carries more than one name'

    Assert-True (@($names | Where-Object { $_.Name -eq 'development.md' -and $_.Kind -eq 'file' }).Count -eq 1) `
        "the measured instance's own name, 'development.md', is in the set exactly once"

    Assert-True (@($names | Where-Object { $_.Name -eq 'workflow-davekjohn' -and $_.Kind -eq 'folder' }).Count -eq 1) `
        "the retired FOLDER name is in the set, derived from the pre-#886 paths rather than written out"

    $paths = Get-BranchFilePaths
    $currentLeaf = [System.IO.Path]::GetFileName(((Get-BranchFilePaths -Branch 'feat/x').File -replace '/', '\'))
    Assert-True (@($names | Where-Object { $_.Name -ieq $currentLeaf }).Count -eq 0) `
        "today's document name ('$currentLeaf') is NOT reported as retired"
    Assert-True (@($names | Where-Object { $_.Name -ieq $paths.Directory }).Count -eq 0) `
        "today's folder name ('$($paths.Directory)') is NOT reported as retired"

    $lengths = @($names | ForEach-Object { $_.Name.Length })
    $sorted = @($lengths | Sort-Object -Descending)
    Assert-True ((($lengths -join ',') -eq ($sorted -join ','))) `
        'the set is longest-name-first, which the span claim in Get-RetiredDocNameMention depends on'

    Assert-True (@($names | Where-Object { -not $_.Since }).Count -eq 0) `
        'every row carries a Since line, so a finding never leaves its remedy to be derived'

    # --- Get-RetiredDocNameMention, the detector --------------------------------------------------
    Write-Host ''
    Write-Host 'Get-RetiredDocNameMention'

    $retired = ($names | Where-Object { $_.Kind -eq 'file' } | Select-Object -First 1).Name

    $empty = New-Tree -Label 'empty'
    Assert-True ((Get-Mentions -Dir $empty).Count -eq 0) 'a tree with no documents at all -- no findings, no throw'

    $nodir = Join-Path ([System.IO.Path]::GetTempPath()) ("retiredname-$PID-nodir-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    Assert-True (@(Get-RetiredDocNameMention -RepoRoot $nodir).Count -eq 0) `
        'a repo root that does not exist -- no findings, no throw'

    $clean = New-Tree -Label 'clean'
    Set-Text -Dir $clean -Rel 'CLAUDE.md' -Text "# Consumer`n`nThe branch document is described in CONTRIBUTING-portable.md. We only point at it."
    Assert-True ((Get-Mentions -Dir $clean).Count -eq 0) 'a consumer that POINTS instead of restating -- no findings'

    # The first measured instance: a consumer's own always-on CLAUDE.md restating the retired name.
    $inRoot = New-Tree -Label 'inroot'
    Set-Text -Dir $inRoot -Rel 'CLAUDE.md' -Text "# Consumer`n`nElke branch krijgt zijn eigen ``contributing-davekjohn/$retired``."
    $f = @(Get-Mentions -Dir $inRoot)
    Assert-True ($f.Count -eq 1 -and $f[0].Rel -eq 'CLAUDE.md' -and $f[0].Line -eq 3 -and $f[0].Name -eq $retired) `
        "a retired name in the consumer's own CLAUDE.md -- one finding naming the document, the line and the name"

    # An '@'-imported document one hop down: the closure is walked, not just the root.
    $imported = New-Tree -Label 'imported'
    Set-Text -Dir $imported -Rel 'CLAUDE.md' -Text "# Consumer`n`n@.claude/specialists/SPECIALISTS.md"
    Set-Text -Dir $imported -Rel '.claude/specialists/SPECIALISTS.md' -Text "# Roster`n`nDe cyclus staat in $retired."
    $f = @(Get-Mentions -Dir $imported)
    Assert-True ($f.Count -eq 1 -and $f[0].Rel -eq '.claude/specialists/SPECIALISTS.md') `
        "an '@'-imported always-on document is scanned too, not only the root"

    # The second measured instance, and the one #1380's detector missed: the folder's own contributor
    # page. It is NOT always-on, so it is in the set only because the lib names it.
    $inFolder = New-Tree -Label 'infolder'
    Set-Text -Dir $inFolder -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# Contributing`n`nWelke scripts wonen in de plugin: zie $retired."
    $f = @(Get-Mentions -Dir $inFolder)
    Assert-True ($f.Count -eq 1 -and $f[0].Rel -eq "$($paths.Directory)/CONTRIBUTING.md") `
        'the workflow folder CONTRIBUTING.md is scanned with no CLAUDE.md present at all'

    # THE EXCLUSION THAT IS NOT OPTIONAL.
    $archive = New-Tree -Label 'archive'
    Set-Text -Dir $archive -Rel 'contributing-davekjohn/CHANGELOG.md' -Text "# Changelog`n`n### DEPLOY: old/branch`n`nRenamed $retired at the time."
    Set-Text -Dir $archive -Rel 'contributing-davekjohn/releases/history.md' -Text "Historic: $retired."
    Assert-True ((Get-Mentions -Dir $archive).Count -eq 0) `
        'the changelog and releases/ are never read -- a folded entry correctly names the file of its day'

    # A per-branch document is transient working prose and must not report itself.
    $ownDoc = New-Tree -Label 'owndoc'
    Set-Text -Dir $ownDoc -Rel ((Get-BranchFilePaths -Branch 'feat/x').File) -Text "## feat/x`n`nThis plan discusses $retired at length."
    Assert-True ((Get-Mentions -Dir $ownDoc).Count -eq 0) `
        "a branch's own development document is not in the set, so a plan about the rename is silent"

    # Plugin-shipped payload: one file '@'-imported by every consumer, not one finding per consumer.
    $external = New-Tree -Label 'external'
    $extDir = Join-Path ([System.IO.Path]::GetTempPath()) ("retiredname-$PID-ext-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    New-Item -ItemType Directory -Path $extDir -Force | Out-Null
    $script:trees += $extDir
    [System.IO.File]::WriteAllText((Join-Path $extDir 'persona.md'), "# Persona`n`nThe document was $retired.`n", (New-Object System.Text.UTF8Encoding($false)))
    Set-Text -Dir $external -Rel 'CLAUDE.md' -Text ("# Consumer`n`n@" + (($extDir -replace '\\', '/') + '/persona.md'))
    $rows = @(Get-AlwaysOnDocuments -RootDocument (Join-Path $external 'CLAUDE.md') -RepoRoot $external)
    Assert-True (@($rows | Where-Object { $_.Source -eq 'external' }).Count -ge 1) `
        'the fixture really does produce an external row (otherwise the next assert proves nothing)'
    Assert-True (@(Get-RetiredDocNameMention -RepoRoot $external -Documents $rows).Count -eq 0) `
        'plugin-shipped payload (Source = external) is excluded -- it is the text a consumer points AT'

    # One line, one repair: two different retired names on one line are two findings, the same name
    # twice on one line is two spans -- but no span is claimed twice.
    $twice = New-Tree -Label 'twice'
    Set-Text -Dir $twice -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# C`n`nBoth $retired and $retired appear here."
    $f = @(Get-Mentions -Dir $twice)
    Assert-True ($f.Count -eq 2 -and @($f | Where-Object { $_.Line -eq 3 }).Count -eq 2) `
        'the same retired name twice on one line -- two spans, both reported, neither doubled'

    # --- check-retired-doc-name.ps1, the gate -----------------------------------------------------
    Write-Host ''
    Write-Host 'check-retired-doc-name.ps1'

    $r = Invoke-Script -Dir $clean
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[OK\] no retired branch-document name') `
        'clean consumer fixture -- [OK], exit 0'

    $r = Invoke-Script -Dir $inRoot
    Assert-True ($r.Code -eq 1 -and $r.Out -match '\[ERROR\]' -and $r.Out -match [regex]::Escape($retired) -and $r.Out -match 'CLAUDE\.md:3') `
        'a restatement present -- [ERROR] exit 1, naming the document, the line and the retired name'

    Assert-True ($r.Out -match 'POINT at a shared convention' -and $r.Out -match 'CONTRIBUTING-portable\.md') `
        'the finding names the remedy and the page the rule lives on'

    # THE SKIP, and it is measured on a real marketplace file rather than asserted about this repo:
    # the same tree answers [ERROR] without one and [OK] with one.
    #
    # BOTH DIRECTIONS SINCE #1422, because the skip narrowed from "publishes plugins" to
    # Test-IsWorkflowSourceRepo's "publishes THIS workflow". A manifest publishing somebody else's
    # product is now a CONSUMER and is judged; only one publishing 'contributing-davekjohn' is skipped.
    # The negative case is asserted first: under the old broad file test it passed as [OK], so it is
    # the assert that would catch a reversion to it.
    New-Item -ItemType Directory -Path (Join-Path $inRoot '.claude-plugin') -Force | Out-Null
    Set-Text -Dir $inRoot -Rel '.claude-plugin/marketplace.json' -Text '{ "name": "fixture", "plugins": [ { "name": "some-other-product" } ] }'
    $r = Invoke-Script -Dir $inRoot
    Assert-True ($r.Code -eq 1 -and $r.Out -match '\[ERROR\]') `
        'a repo publishing ANOTHER product is a consumer of this workflow -- still judged, not skipped'

    Set-Text -Dir $inRoot -Rel '.claude-plugin/marketplace.json' -Text '{ "name": "fixture", "plugins": [ { "name": "contributing-davekjohn" } ] }'
    $r = Invoke-Script -Dir $inRoot
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'publishes the workflow') `
        'a repo that publishes THIS workflow is skipped -- its own pages are the source of the convention'

    # --- retired-doc-name-sessioncheck.ps1, the hook (always exit 0) ------------------------------
    Write-Host ''
    Write-Host 'retired-doc-name-sessioncheck.ps1'

    $r = Invoke-Hook -Dir $clean
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'no retired branch-document name') `
        'clean consumer -- the in-sync line, exit 0'

    $r = Invoke-Hook -Dir $inFolder
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'states a retired name of the branch document as current' -and $r.Out -match [regex]::Escape($retired)) `
        'a restatement present -- a compact summary carrying the [ERROR] detail, still exit 0'

    $r = Invoke-Hook -Dir $clean -CheckScriptOverride (Join-Path ([System.IO.Path]::GetTempPath()) "no-such-check-$PID.ps1")
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'check script not found -- check skipped') `
        'check script missing -- a notice, exit 0, never a strand'
}
finally {
    foreach ($t in $script:trees) {
        if ($t -and (Test-Path -LiteralPath $t)) { Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAIL: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
