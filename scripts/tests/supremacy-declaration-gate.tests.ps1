<#
.SYNOPSIS
    Regression tests for the supremacy-declaration guard (issue #1415): Get-SupremacyDeclaration and the
    shared Get-ConsumerProseDocuments in entry-scaffold-lib.ps1, the check script
    scripts/lint/check-supremacy-declaration.ps1, and the SessionStart hook
    supremacy-declaration-sessioncheck.ps1.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/supremacy-declaration-gate.tests.ps1

    THE TWO MEASURED INSTANCES ARE BOTH FIXTURES HERE, in the STRUCTURE they were found in on
    September 4, 2026 in BWJ-ecommerce/smartwatchbanden: the Dutch preamble inversion in the consumer's
    own CLAUDE.md, line 22 ('wint' beside `CLAUDE.md`, inside a blockquote), and the same inversion
    stated from the other side in contributing-davekjohn/CONTRIBUTING.md, line 306 (`CLAUDE.md` beside
    'wins', under bold markup). The second is the one #1380's census never counted at all, and it is why
    the document set includes that page rather than only the always-on closure.

    STRUCTURE, NOT WORDING, AND THAT IS THE BOUND RATHER THAN AN ACCIDENT. That consumer is private and
    this repository is public, so a measurement taken there quotes only what the finding reads -- here
    the adjacency, which is this detector's own pattern -- with the repo, file and line carrying the
    provenance. The rule is in CLAUDE.md's public-repo bullet (Dave, September 5, 2026, issue #1420) and
    it binds a fixture exactly as it binds prose: a matcher reads shape, so the consumer's surrounding
    sentence adds no coverage and a public repository would keep it forever. Each fixture below is
    therefore built from this repo's own words around the clause that fires, and is pinned to the line it
    was measured at -- which is what keeps the suppression rule testable rather than folklore.

    AND SO IS THE ONE SUPPRESSED FALSE POSITIVE, because a suppression rule resting on a single instance
    has to be pinned by that instance or it is untestable folklore: xoxowildhearts QUOTING the closing
    line of a page it retired, in order to explain why it removed it.

    DIRECTION IS THE POINT, AND IT HAS ITS OWN CASE. 'this page wins' over CLAUDE.md is the law stated
    CORRECTLY, and a term-co-occurrence detector scores it identically to the inversion. The negative
    case below is what proves adjacency reads the subject of the verb rather than merely the presence of
    two words -- it is the assert that fails first if anybody ever loosens the pattern back toward
    co-occurrence, which is the design #1380 declined.

    Fixture paths carry $PID (repo convention): the test gate is a throttled parallel scheduler, so two
    runs overlapping is ordinary and two sharing one fixed temp path tear down each other's tree.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\lint\check-supremacy-declaration.ps1'
$Hook     = Join-Path $RepoRoot 'plugins\workflows\contributing-davekjohn\hooks\supremacy-declaration-sessioncheck.ps1'
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
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("supremacy-$PID-$Label-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
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

function Get-Declarations {
    # The lib the way the check calls it: the always-on closure from this tree's CLAUDE.md, plus the
    # folder's own pages, which the shared corpus adds itself.
    param([Parameter(Mandatory = $true)][string]$Dir)
    $docs = @()
    $root = Join-Path $Dir 'CLAUDE.md'
    if (Test-Path -LiteralPath $root -PathType Leaf) {
        $docs = @(Get-AlwaysOnDocuments -RootDocument $root -RepoRoot $Dir)
    }
    return @(Get-SupremacyDeclaration -RepoRoot $Dir -Documents $docs)
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

$paths = Get-BranchFilePaths

try {
    # --- Get-ConsumerProseDocuments, the shared corpus ---------------------------------------------
    # It is asserted on its OWN, not only through a detector, because it is the half two checks share:
    # a change here moves what BOTH #1389 and #1415 are allowed to look at.
    Write-Host 'Get-ConsumerProseDocuments'

    $bare = @(Get-ConsumerProseDocuments)
    Assert-True (@($bare | Where-Object { $_ -eq "$($paths.Directory)/CONTRIBUTING.md" }).Count -eq 1) `
        "the folder's contributor page is in the corpus with no always-on walk supplied at all"
    Assert-True (@($bare | Where-Object { $_ -match 'CHANGELOG\.md$' }).Count -eq 0) `
        'the changelog is NOT in the corpus -- a folded entry correctly states the rule of its day'
    Assert-True (@($bare | Where-Object { $_ -match '^releases/' -or $_ -match '/releases/' }).Count -eq 0) `
        'releases/ is not in the corpus either -- neither always-on nor a reserved page'

    # --- Get-SupremacyDeclaration, the detector ----------------------------------------------------
    Write-Host ''
    Write-Host 'Get-SupremacyDeclaration'

    $empty = New-Tree -Label 'empty'
    Assert-True ((Get-Declarations -Dir $empty).Count -eq 0) 'a tree with no documents at all -- no findings, no throw'

    $nodir = Join-Path ([System.IO.Path]::GetTempPath()) ("supremacy-$PID-nodir-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    Assert-True (@(Get-SupremacyDeclaration -RepoRoot $nodir).Count -eq 0) `
        'a repo root that does not exist -- no findings, no throw'

    $clean = New-Tree -Label 'clean'
    Set-Text -Dir $clean -Rel 'CLAUDE.md' -Text "# Consumer`n`nThe rank order is in CONTRIBUTING-portable.md. We only point at it."
    Assert-True ((Get-Declarations -Dir $clean).Count -eq 0) 'a consumer that POINTS instead of declaring -- no findings'

    # MEASURED INSTANCE 1 -- smartwatchbanden/CLAUDE.md:22, the Dutch preamble inversion, and the one
    # #1380 named as structurally invisible: the portable page's filename sits two lines above, so every
    # pointer-based candidate suppressed it.
    $dutch = New-Tree -Label 'dutch'
    Set-Text -Dir $dutch -Rel 'CLAUDE.md' -Text "# Consumer`n`n> **Deze pagina staat bovenaan.** Bij tegenspraak wint ``CLAUDE.md``."
    $f = @(Get-Declarations -Dir $dutch)
    Assert-True ($f.Count -eq 1 -and $f[0].Rel -eq 'CLAUDE.md' -and $f[0].Line -eq 3) `
        'the measured Dutch inversion -- one finding naming the document and the line'
    Assert-True ($f[0].Match -match 'wint') `
        'the Dutch verb is matched, and the match is reported so the finding names what fired'

    # MEASURED INSTANCE 2 -- smartwatchbanden/contributing-davekjohn/CONTRIBUTING.md:306, the same
    # inversion from the other side, on a page that is NOT always-on.
    $english = New-Tree -Label 'english'
    Set-Text -Dir $english -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# Contributing`n`nSo when this page and ``CLAUDE.md`` disagree, **``CLAUDE.md`` wins.**"
    $f = @(Get-Declarations -Dir $english)
    Assert-True ($f.Count -eq 1 -and $f[0].Rel -eq "$($paths.Directory)/CONTRIBUTING.md") `
        'the folder CONTRIBUTING.md is scanned with no CLAUDE.md present at all'
    Assert-True ($f[0].Match -match 'wins') `
        'bold markup between the tokens does not break the adjacency'

    # DIRECTION. The law stated CORRECTLY carries both terms and must NOT fire. This is the assert that
    # separates this detector from the co-occurrence design #1380 measured at 12.5% and declined.
    $correct = New-Tree -Label 'correct'
    Set-Text -Dir $correct -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# Contributing`n`nThis page sits on top of ``CLAUDE.md``, and where they disagree, this page wins."
    Assert-True ((Get-Declarations -Dir $correct).Count -eq 0) `
        'the rank order stated CORRECTLY carries both terms and does not fire -- adjacency reads direction'

    # And the near miss on the same line: a clause between the two tokens ends the adjacency, because it
    # is a different claim.
    $between = New-Tree -Label 'between'
    Set-Text -Dir $between -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# Contributing`n`nWhere ``CLAUDE.md``, which we treat as the floor, disagrees, the portable page wins."
    Assert-True ((Get-Declarations -Dir $between).Count -eq 0) `
        'a whole clause between the two tokens is not adjacency -- no finding'

    # THE ONE SUPPRESSION, pinned by the instance that produced it: xoxowildhearts quoting the closing
    # line of a page it RETIRED, to explain why it removed it. Somebody else's words, reported.
    $quoted = New-Tree -Label 'quoted'
    Set-Text -Dir $quoted -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# Contributing`n`nIts own closing line conceded the point: *`"when this page and ``CLAUDE.md`` disagree, ``CLAUDE.md`` wins.`"* It was retired."
    Assert-True ((Get-Declarations -Dir $quoted).Count -eq 0) `
        'a hit sitting wholly inside a quotation span is suppressed -- a retired page being narrated'

    # ... and the suppression is a SPAN test, not a "this line contains a quote mark" test: an unquoted
    # declaration on a line that also carries an unrelated quotation still fires.
    $mixed = New-Tree -Label 'mixed'
    Set-Text -Dir $mixed -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# Contributing`n`nWe call it the `"grondwet`" here: on any disagreement ``CLAUDE.md`` wins."
    # @() BEFORE .Count, and it is load-bearing rather than style: PowerShell unwraps a single-element
    # array on return, and under Set-StrictMode -Version Latest '.Count' on the resulting scalar THROWS
    # rather than answering 1. Every assert here that expects exactly one finding wraps first for that
    # reason -- the zero cases survive unwrapped only because $null.Count is still 0.
    Assert-True (@(Get-Declarations -Dir $mixed).Count -eq 1) `
        'an unrelated quotation elsewhere on the line does not suppress a real declaration'

    # --- WRAPPING, the false negative review found and reproduced --------------------------------
    # This repo's prose convention hard-wraps at about 100 columns, so a declaration routinely straddles
    # two physical lines. The detector matched per line until this was found, and reported NOTHING for
    # either shape below. Both are pinned, and so is the line number a finding must still resolve to --
    # a check that found the defect but named the wrong line is a check nobody can act on.
    Write-Host ''
    Write-Host 'Get-SupremacyDeclaration -- hard-wrapped prose'

    $wrapped = New-Tree -Label 'wrapped'
    Set-Text -Dir $wrapped -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# C`n`nOn any real conflict between the two, ``CLAUDE.md```nwins, and the contributing page is simply wrong."
    $f = @(Get-Declarations -Dir $wrapped)
    Assert-True ($f.Count -eq 1 -and $f[0].Line -eq 3) `
        'a declaration hard-wrapped across two lines is found, and names the line it BEGINS on'

    # THE ONE THAT MATTERS MOST: the single real instance this check exists for lives in a blockquote.
    # It sits on one physical line today, so a line-scoped detector found it -- one re-wrap of that
    # paragraph would have emptied the gate with every test still green.
    $bq = New-Tree -Label 'blockquote'
    Set-Text -Dir $bq -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# C`n`n> Bij tegenspraak wint`n> ``CLAUDE.md``."
    $f = @(Get-Declarations -Dir $bq)
    Assert-True ($f.Count -eq 1 -and $f[0].Line -eq 3) `
        "a wrapped BLOCKQUOTE declaration is found -- the '>' markers are stripped, not read as text"

    # The bound on the join: a paragraph break is where a unit ends, so a gap may not bridge one.
    $across = New-Tree -Label 'across'
    Set-Text -Dir $across -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# C`n`nSomething about ``CLAUDE.md```n`nwins is a new paragraph here."
    Assert-True ((Get-Declarations -Dir $across).Count -eq 0) `
        'adjacency does not bridge a blank line -- the paragraph is the largest unit joined'

    # ... and the suppression has to survive the join too, or widening the match would have re-admitted
    # the very false positive the quotation rule was built for.
    $qWrapped = New-Tree -Label 'qwrapped'
    Set-Text -Dir $qWrapped -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# C`n`nIts closing line conceded: *`"when this page and ``CLAUDE.md```ndisagree, ``CLAUDE.md`` wins.`"* It was retired."
    Assert-True ((Get-Declarations -Dir $qWrapped).Count -eq 0) `
        'a quotation that itself wraps still suppresses -- the quote span is read on the joined unit'

    # LIST ITEMS, the regression the wrap repair introduced and review caught. A tight list has no blank
    # line between its items, and '*' is BOTH a bullet marker and the bold decoration the gap class must
    # allow -- so joining a paragraph ran two unrelated bullets together into a match present in neither.
    # All three marker shapes are pinned, not just the one that could bridge: '-' and '1.' are outside
    # the gap class today, and the assert is what keeps them safe if it is ever widened.
    Write-Host ''
    Write-Host 'Get-SupremacyDeclaration -- list items'

    $stars = New-Tree -Label 'stars'
    Set-Text -Dir $stars -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# C`n`n* Read the constitution in ``CLAUDE.md```n* wins arguments only when they cite the rank order."
    Assert-True ((Get-Declarations -Dir $stars).Count -eq 0) `
        "two '*' bullets do not bridge into a declaration that exists in neither item"

    $dashes = New-Tree -Label 'dashes'
    Set-Text -Dir $dashes -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# C`n`n- Read the constitution in ``CLAUDE.md```n- wins arguments only when they cite the rank order."
    Assert-True ((Get-Declarations -Dir $dashes).Count -eq 0) "'-' bullets do not bridge either"

    $numbered = New-Tree -Label 'numbered'
    Set-Text -Dir $numbered -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# C`n`n1. Read the constitution in ``CLAUDE.md```n2. wins arguments only when they cite the rank order."
    Assert-True ((Get-Declarations -Dir $numbered).Count -eq 0) 'numbered items do not bridge either'

    # The other edge of the same rule: a real declaration INSIDE one bullet is still found, and so is one
    # that wraps within its own item -- the item is a unit, not a dead zone.
    $inBullet = New-Tree -Label 'inbullet'
    Set-Text -Dir $inBullet -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# C`n`n* On any real conflict between the two, ``CLAUDE.md```n  wins outright.`n* Something else entirely."
    $f = @(Get-Declarations -Dir $inBullet)
    Assert-True ($f.Count -eq 1 -and $f[0].Line -eq 3) `
        'a declaration wrapped inside ONE bullet is still found, at the line it begins on'

    # And the marker test must not catch bold at the start of a line -- '**text**' has no space after the
    # first '*', which is the whole difference between a bullet and emphasis.
    $boldStart = New-Tree -Label 'boldstart'
    Set-Text -Dir $boldStart -Rel 'contributing-davekjohn/CONTRIBUTING.md' -Text "# C`n`n**On any real conflict ``CLAUDE.md`` wins outright.**"
    Assert-True (@(Get-Declarations -Dir $boldStart).Count -eq 1) `
        "a line opening with '**bold**' is not read as a list item"

    # --- Get-ProseParagraphUnits, on its own ------------------------------------------------------
    Write-Host ''
    Write-Host 'Get-ProseParagraphUnits'

    $units = @(Get-ProseParagraphUnits -Lines @('# H', '', 'one', 'two', '', '> quoted', '> more'))
    Assert-True ($units.Count -eq 3) 'blank lines separate units -- heading, paragraph, blockquote'
    Assert-True ($units[1].Text -eq 'one two') 'continuation lines are joined with a single space'
    Assert-True ($units[2].Text -eq 'quoted more') "blockquote markers are stripped from every line of the unit"
    Assert-True ((Resolve-ProseUnitLine -Unit $units[1] -Offset 0) -eq 3 -and (Resolve-ProseUnitLine -Unit $units[1] -Offset 4) -eq 4) `
        'an offset resolves to the source line that contributed it, not to the unit start'

    # The empty-input edge, which is what the parameter attributes exist for: blank lines ARE the input.
    Assert-True (@(Get-ProseParagraphUnits -Lines @()).Count -eq 0) 'no lines at all -- no units, no throw'
    Assert-True (@(Get-ProseParagraphUnits -Lines @('', '', '')).Count -eq 0) 'only blank lines -- no units, no throw'

    # THE EXCLUSION THAT IS NOT OPTIONAL, exercised through this detector too: the corpus assert above
    # proves the path is absent, this proves a real declaration sitting there is genuinely never read.
    $archive = New-Tree -Label 'archive'
    Set-Text -Dir $archive -Rel 'contributing-davekjohn/CHANGELOG.md' -Text "# Changelog`n`n### DEPLOY: old/branch`n`nBack then ``CLAUDE.md`` wins was the rule."
    Set-Text -Dir $archive -Rel 'contributing-davekjohn/releases/history.md' -Text "Historic: ``CLAUDE.md`` wins."
    Assert-True ((Get-Declarations -Dir $archive).Count -eq 0) `
        'the changelog and releases/ are never read -- a folded entry correctly states the rule of its day'

    # A per-branch document is transient working prose and must not report itself -- this very branch's
    # document discusses the inversion at length.
    $ownDoc = New-Tree -Label 'owndoc'
    Set-Text -Dir $ownDoc -Rel ((Get-BranchFilePaths -Branch 'feat/x').File) -Text "## feat/x`n`nThe defect is a line saying ``CLAUDE.md`` wins over the contributing page."
    Assert-True ((Get-Declarations -Dir $ownDoc).Count -eq 0) `
        "a branch's own development document is not in the set, so a plan about the defect is silent"

    # Plugin-shipped payload: one file '@'-imported by every consumer, not one finding per consumer.
    $external = New-Tree -Label 'external'
    $extDir = Join-Path ([System.IO.Path]::GetTempPath()) ("supremacy-$PID-ext-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    New-Item -ItemType Directory -Path $extDir -Force | Out-Null
    $script:trees += $extDir
    [System.IO.File]::WriteAllText((Join-Path $extDir 'persona.md'), "# Persona`n`nOn a disagreement ``CLAUDE.md`` wins.`n", (New-Object System.Text.UTF8Encoding($false)))
    Set-Text -Dir $external -Rel 'CLAUDE.md' -Text ("# Consumer`n`n@" + (($extDir -replace '\\', '/') + '/persona.md'))
    $rows = @(Get-AlwaysOnDocuments -RootDocument (Join-Path $external 'CLAUDE.md') -RepoRoot $external)
    Assert-True (@($rows | Where-Object { $_.Source -eq 'external' }).Count -ge 1) `
        'the fixture really does produce an external row (otherwise the next assert proves nothing)'
    Assert-True (@(Get-SupremacyDeclaration -RepoRoot $external -Documents $rows).Count -eq 0) `
        'plugin-shipped payload (Source = external) is excluded -- it is the text a consumer points AT'

    # An '@'-imported document one hop down: the closure is walked, not just the root.
    $imported = New-Tree -Label 'imported'
    Set-Text -Dir $imported -Rel 'CLAUDE.md' -Text "# Consumer`n`n@.claude/specialists/SPECIALISTS.md"
    Set-Text -Dir $imported -Rel '.claude/specialists/SPECIALISTS.md' -Text "# Roster`n`nBij tegenspraak wint ``CLAUDE.md``."
    $f = @(Get-Declarations -Dir $imported)
    Assert-True ($f.Count -eq 1 -and $f[0].Rel -eq '.claude/specialists/SPECIALISTS.md') `
        "an '@'-imported always-on document is scanned too, not only the root"

    # --- check-supremacy-declaration.ps1, the gate -------------------------------------------------
    Write-Host ''
    Write-Host 'check-supremacy-declaration.ps1'

    $r = Invoke-Script -Dir $clean
    Assert-True ($r.Code -eq 0 -and $r.Out -match '\[OK\] no inverted supremacy declaration') `
        'clean consumer fixture -- [OK], exit 0'

    $r = Invoke-Script -Dir $dutch
    Assert-True ($r.Code -eq 1 -and $r.Out -match '\[ERROR\]' -and $r.Out -match 'CLAUDE\.md:3') `
        'a declaration present -- [ERROR] exit 1, naming the document and the line'

    Assert-True ($r.Out -match 'THE ORDER RUNS THE OTHER WAY' -and $r.Out -match 'CONTRIBUTING-portable\.md') `
        'the finding names the remedy and the page the rank order lives on'

    Assert-True ($r.Out -match 'SEAM answer') `
        'the finding names the sanctioned route for a repo that really does want its own page to lead'

    # WHAT THE REPORT PRINTS OUT OF THE CONSUMER'S OWN FILE IS SANITIZED (#1419). The hook forwards this
    # whole report into session context and decides what to surface by matching '[ERROR]' over it, so a
    # raw echo lets a consumer's own line choose how loudly it is reported -- and paint a terminal on the
    # way past. Every value on those two lines is the consumer's here: the path, the matched phrase and
    # the echoed line alike. Asserted end to end rather than only on the helper, because the defect was
    # never in the helper: it was this script printing around it.
    $forged = New-Tree -Label 'forged'
    Set-Text -Dir $forged -Rel 'CLAUDE.md' -Text ("# Consumer`n`nHere ``CLAUDE.md`` wins$([char]27)[31m, and also [ERROR] forged.")
    $r = Invoke-Script -Dir $forged
    Assert-True ($r.Code -eq 1 -and ([regex]::Matches($r.Out, '\[ERROR\]')).Count -eq 1) `
        "a forged '[ERROR]' in the consumer's own line cannot add a second marker to the report"
    Assert-True (-not $r.Out.Contains([char]27)) `
        'an ESC in that line never reaches the terminal'
    Assert-True ($r.Out -match '\(ERROR\)') `
        'the bracketed text is still legible -- substituted, not deleted, so the reader recognises the line'
    Assert-True ($r.Out -match 'shown sanitized') `
        'and the preview says it was altered, so nobody hunts for text that is not in the file'
    Assert-True ($r.Out -match 'square brackets are shown as round ones') `
        'the footer discloses the substitution, which carries no per-line note of its own'

    # THE SKIP, measured on a real marketplace file rather than asserted about this repo: the same tree
    # answers [ERROR] without one and [OK] with one.
    #
    # BOTH DIRECTIONS SINCE #1422, for the reason its sibling suite states: the skip narrowed from
    # "publishes plugins" to Test-IsWorkflowSourceRepo's "publishes THIS workflow", so a manifest
    # publishing somebody else's product is a consumer and is judged. The negative case is asserted
    # first, being the one the old broad file test would have passed as [OK].
    New-Item -ItemType Directory -Path (Join-Path $dutch '.claude-plugin') -Force | Out-Null
    Set-Text -Dir $dutch -Rel '.claude-plugin/marketplace.json' -Text '{ "name": "fixture", "plugins": [ { "name": "some-other-product" } ] }'
    $r = Invoke-Script -Dir $dutch
    Assert-True ($r.Code -eq 1 -and $r.Out -match '\[ERROR\]') `
        'a repo publishing ANOTHER product is a consumer of this workflow -- still judged, not skipped'

    Set-Text -Dir $dutch -Rel '.claude-plugin/marketplace.json' -Text '{ "name": "fixture", "plugins": [ { "name": "contributing-davekjohn" } ] }'
    $r = Invoke-Script -Dir $dutch
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'publishes the workflow') `
        'a repo that publishes THIS workflow is skipped -- its own pages are the source of the rank order'

    # --- supremacy-declaration-sessioncheck.ps1, the hook (always exit 0) --------------------------
    Write-Host ''
    Write-Host 'supremacy-declaration-sessioncheck.ps1'

    $r = Invoke-Hook -Dir $clean
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'no inverted supremacy declaration') `
        'clean consumer -- the in-sync line, exit 0'

    $r = Invoke-Hook -Dir $english
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'declares its own CLAUDE\.md above' -and $r.Out -match '\[ERROR\]') `
        'a declaration present -- a compact summary carrying the [ERROR] detail, still exit 0'

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
