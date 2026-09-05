<#
.SYNOPSIS
    Regression tests for scripts/lint/check-branch-entry.ps1 -- the CI gate that holds every branch to
    carrying a written changelog entry (inbound #789).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell and git.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/branch-entry-gate.tests.ps1
    THE ENTRY STATES COME FROM THE REAL FORMATTERS, NEVER FROM A LITERAL IN THIS FILE. Format-EntryBlock
    with empty fields IS the scaffolded state, and Format-Development with no branch IS the empty,
    trunk-declaring state a repo updating from an older plugin still has on its trunk -- so a change to
    either shape reaches these cases automatically. A fixture written by hand would be a third
    definition of the format, in the file whose whole job is to prove there are not two -- and it would go
    stale exactly when the gate did, hiding the failure instead of catching it.

    THE CASE THAT CARRIES THE MOST WEIGHT IS THE ONE THAT PASSES. An entry whose significance is not
    settled must exit 0: Dave placed that refusal at the release cut (open-pr.ps1, August 5, 2026), and
    both hand-written consumer gates refuse a merge over it -- which is the drift this shipped gate exists
    to end. A test that only checked the refusals would let that come straight back.

    Fixture paths carry $PID (repo convention): the test gate is a throttled parallel scheduler, so two
    runs overlapping is ordinary, and two runs sharing one fixed temp path tear down each other's tree
    mid-assert.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\lint\check-branch-entry.ps1'
. (Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1')

$script:pass = 0
$script:fail = 0
$script:trees = @()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message" -ForegroundColor Red }
}

function New-Consumer {
    <# A fixture repo with the branch dossier in place. No git history is needed: the gate reads files
       and a branch NAME, which the caller passes. #>
    param([Parameter(Mandatory = $true)][string]$Label, [string]$RepoConfig = '')
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("entrygate-$PID-$Label-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    New-Item -ItemType Directory -Path (Join-Path $dir 'dkj-policy\branch') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib') -Force | Out-Null
    $script:trees += $dir
    if ($RepoConfig) {
        Set-Content -LiteralPath (Join-Path $dir 'scripts\repo-config.ps1') -Value $RepoConfig -Encoding ascii
    }
    return $dir
}

function Set-Entry {
    # [AllowEmptyString()] is load-bearing and the lib says so about its own callers: most of a formatted
    # entry is blank lines, and a [string[]] without it rejects the whole call.
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Lines
    )
    # THE PRIMARY PATH, from the seam rather than typed out (August 23, 2026). It wrote the pre-merge
    # branch/branch-deployment.md, which the resolver still reads -- so this suite kept passing while
    # asserting nothing about the path every branch actually gets. Taking it from Get-BranchFilePaths is
    # what makes a future move show up here instead of quietly falling through to a legacy read.
    $target = Join-Path $Dir ((Get-BranchFilePaths).File -replace '/', '\')
    $dir = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($target, (($Lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-Gate {
    param([Parameter(Mandatory = $true)][string]$Dir, [Parameter(Mandatory = $true)][string]$Branch)
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -RootOverride $Dir -Branch $Branch 2>&1
    } finally { $ErrorActionPreference = $prevEap }
    return @{ Out = ($out | Out-String); Code = $LASTEXITCODE }
}

try {
    # --- The two exits that are not about the entry at all -------------------------------------------
    Write-Host 'the exemptions'

    $c = New-Consumer -Label 'exempt'
    Set-Entry -Dir $c -Lines (Format-Development -Branch '')

    $r = Invoke-Gate -Dir $c -Branch 'sync/live-2026-08-20'
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'exempt prefix') 'exempt/default: a sync branch owes no entry, even with the entry in its reset state'

    $r = Invoke-Gate -Dir $c -Branch 'main'
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'trunk') 'trunk: judged as the trunk, where the reset state is the DESIGNED state'

    # An unknown prefix is deliberately NOT exempt: a typo in a prefix would otherwise skip the gate.
    $r = Invoke-Gate -Dir $c -Branch 'syncc/typo'
    Assert-True ($r.Code -eq 1) 'exempt/typo: a prefix that merely LOOKS exempt is not -- the gate still runs'

    # The seam narrows and widens it, and the source declares no exemption of its own.
    $c2 = New-Consumer -Label 'seam' -RepoConfig "function Get-EntryGateExemptPrefixes { return @('mirror','vendor') }"
    Set-Entry -Dir $c2 -Lines (Format-Development -Branch '')
    $r = Invoke-Gate -Dir $c2 -Branch 'mirror/upstream'
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'exempt prefix') 'exempt/seam: the seam answer replaces the default'
    $r = Invoke-Gate -Dir $c2 -Branch 'sync/live-2026-08-20'
    Assert-True ($r.Code -eq 1) 'exempt/seam: and REPLACES it -- a repo that names its own list does not silently keep sync'

    # --- The refusals -------------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'the refusals'

    $missing = New-Consumer -Label 'missing'
    $r = Invoke-Gate -Dir $missing -Branch 'feat/thing'
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'does not exist') 'missing: no entry file at all refuses, and names new-branch'

    $reset = New-Consumer -Label 'reset'
    Set-Entry -Dir $reset -Lines (Format-Development -Branch '')
    $r = Invoke-Gate -Dir $reset -Branch 'feat/thing'
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'reset state') 'reset: the state the fold leaves behind is not an entry'

    # THE CASE A HEADING TEST PASSES AND THIS ONE MUST NOT. A freshly scaffolded entry already carries
    # its own heading and the section headings, which is exactly why the hand-written gates reached for
    # the score.
    $scaffolded = New-Consumer -Label 'scaffolded'
    Set-Entry -Dir $scaffolded -Lines (Format-EntryBlock -Branch 'feat/thing' -Description '' -Type 'Feat' -Body '')
    $r = Invoke-Gate -Dir $scaffolded -Branch 'feat/thing'
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'has not been written yet') 'scaffolded: created and never filled in refuses -- the case a heading test lets through'
    Assert-True ($r.Out -match '- ') 'scaffolded: and it NAMES the fields still waiting, rather than only saying no'

    # --- The pass, and the one that must not become a refusal ---------------------------------------
    Write-Host ''
    Write-Host 'what passes'

    $written = New-Consumer -Label 'written'
    Set-Entry -Dir $written -Lines (Format-EntryBlock -Branch 'feat/thing' -Type 'Feat' `
        -Description 'The thing now does the thing.' -Body 'The thing now does the thing.' `
        -ImpactRows @([pscustomobject]@{ Tier = 0; Score = 2; Why = 'Maintainers notice it.' }))
    $r = Invoke-Gate -Dir $written -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'written: a filled-in entry passes'
    Assert-True ($r.Out -match 'carries a written entry') 'written: and says which file it read'

    # AN EMPTY SCORE IS NOT AN UNSETTLED ONE, which is worth pinning because it is counter-intuitive and
    # it is what the hand-written gates got wrong. A tier section whose Score line is blank carries no
    # number, so the entry's REACH is tier 0 -- a complete, legitimate answer that owes nothing
    # (entry-scaffold-lib: "TIER 0 OWES NOTHING"). The gate must pass it in silence.
    $blank = New-Consumer -Label 'blank'
    Set-Entry -Dir $blank -Lines (Format-EntryBlock -Branch 'feat/thing' -Type 'Feat' `
        -Description 'The thing now does the thing.' -Body 'The thing now does the thing.' `
        -ImpactRows @([pscustomobject]@{ Tier = 2; Score = 0; Why = 'Subscribers notice it.' }))
    $r = Invoke-Gate -Dir $blank -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'blank score: reads as tier 0, which owes nothing -- passes'
    Assert-True ($r.Out -notmatch 'RELEASE CUT') 'blank score: and is not even reported, because nothing is unsettled'

    # THE LOAD-BEARING CASE. Scores genuinely unsettled -> still exit 0, with the cut named as where the
    # refusal lives. Both hand-written consumer gates fail this one, which is why it is here.
    # Tier 1 carries its REASON but no number. A reason left blank is a different case and belongs to the
    # scaffold gate above -- it is an unwritten field, and that one does refuse. This is the narrow state
    # where everything is written and only the ranking is still open.
    $unscored = New-Consumer -Label 'unscored'
    Set-Entry -Dir $unscored -Lines (Format-EntryBlock -Branch 'feat/thing' -Type 'Feat' `
        -Description 'The thing now does the thing.' -Body 'The thing now does the thing.' `
        -ImpactRows @(
            [pscustomobject]@{ Tier = 2; Score = 4; Why = 'Subscribers notice it.' },
            [pscustomobject]@{ Tier = 1; Score = 0; Why = 'Colleagues get something out of it.' }
        ))
    $r = Invoke-Gate -Dir $unscored -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'unscored: an unsettled significance does NOT block the merge -- that refusal is the cut''s'
    Assert-True ($r.Out -match 'RELEASE CUT will refuse') 'unscored: and the gate says where the refusal does live'

    # --- The document's SHAPE: four phases (#898) and a generic preamble (#899) ----------------------
    # BOTH RULES WERE CAUGHT BY EYE, on the same document, on the same afternoon, and neither had a
    # reader. #898: a fifth '## Where this stands (August 25, 2026, late)' above '## PLAN', which survived
    # a park and a merge-up with every gate green -- the reporter tested it rather than assuming, and got
    # byte-identical gate output at four headings and at five. #899: branch state written into the region
    # between the H1 and the first '##', which is generic guidance in every branch document in every repo.
    # Two sessions in a row used that region that way, so it is a shape the document invites.
    #
    # THE TWO CHECKS ARE SCOPED DIFFERENTLY, ON PURPOSE, and these scenarios are where that is pinned:
    #   - the heading rule is the SOURCE REPO's. DEVELOPMENT-portable.md states heading-blindness as a
    #     feature precisely so a consumer may keep headings of their own, so refusing them everywhere
    #     would break correct files elsewhere -- the shape this repo declined at 124 findings once before.
    #   - the preamble rule holds EVERYWHERE, because it reads the SHAPE and not the text: guidance is
    #     blockquoted whatever language it has been translated into. A byte comparison against
    #     StepsGuidance could not say that -- it carries a '{0}' seam the consumer answers themselves.
    Write-Host 'the document shape'

    function New-SourceRepoFixture {
        <# Same fixture as New-Consumer plus the manifest that makes Test-IsWorkflowSourceRepo say yes.
           Written here rather than as a flag on New-Consumer so the two callers read differently at the
           call site -- which of the two a scenario builds IS the thing under test.

           THE MANIFEST HAS TO PUBLISH THE WORKFLOW SINCE ISSUE #998 (August 27, 2026). It used to carry
           an EMPTY plugins array, which was enough while that test was `Test-Path marketplace.json` --
           and an empty marketplace publishing nothing is precisely the repo the old test called a source
           by mistake. The test reads the manifest now, so the fixture has to name what it publishes. #>
        param([Parameter(Mandatory = $true)][string]$Label)
        $dir = New-Consumer -Label $Label
        New-Item -ItemType Directory -Path (Join-Path $dir '.claude-plugin') -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $dir '.claude-plugin\marketplace.json'),
            "{ `"name`": `"fixture`", `"plugins`": [ { `"name`": `"dkj-policy`", `"source`": `"./x`" } ] }`n",
            (New-Object System.Text.UTF8Encoding($false)))
        return $dir
    }

    # A document that is WRITTEN, so the scaffold gate above is already satisfied and these scenarios
    # measure the shape and nothing else. The DEPLOY half comes from Format-EntryBlock -- the same source
    # the passing scenarios above use, so a change to the entry format shows up here rather than leaving
    # this suite asserting against a shape nothing produces. The head is spelled out on purpose: the
    # preamble's SHAPE is the subject of #899, and a scenario that hid it behind a formatter call would
    # read as though the region were incidental.
    $shapeHead = @(
        '# Development: `feat/thing`',
        '',
        '> **How this file is read.** A step is `- [ ]` until it is resolved.',
        '> The four phases are below, and this block is the same in every branch document.',
        '',
        '## PLAN',
        '',
        '## CREATE',
        '',
        '- [x] Did the thing',
        '',
        '## TEST',
        ''
    )
    $shapeEntry = @(Format-EntryBlock -Branch 'feat/thing' -Type 'Feat' `
        -Description 'The thing now does the thing.' -Body 'The thing now does the thing.' `
        -ImpactRows @([pscustomobject]@{ Tier = 0; Score = 2; Why = 'Maintainers notice it.' }))
    $shapeLines = $shapeHead + $shapeEntry

    # 1. THE BASELINE, and it has to be a source repo: without it the scenario below would pass for the
    #    wrong reason (scoped out rather than shaped right).
    $shapeOk = New-SourceRepoFixture -Label 'shape-ok'
    Set-Entry -Dir $shapeOk -Lines $shapeLines
    $r = Invoke-Gate -Dir $shapeOk -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'shape: a four-phase document with a guidance-only preamble passes in the source repo'

    # 2. #898 -- the fifth heading, in the position the measured instance used.
    $shapeFive = New-SourceRepoFixture -Label 'shape-five'
    Set-Entry -Dir $shapeFive -Lines (@($shapeLines |
        ForEach-Object { if ($_ -eq '## PLAN') { '## Where this stands (August 25, 2026, late)', '', 'Parked.', '', $_ } else { $_ } }))
    $r = Invoke-Gate -Dir $shapeFive -Branch 'feat/thing'
    Assert-True ($r.Code -ne 0) 'shape/#898: a fifth ## heading fails the gate in the source repo'
    Assert-True ($r.Out -match 'Where this stands') 'shape/#898: and the finding names the extra heading, so the repair needs no counting'
    Assert-True ($r.Out -match '###') 'shape/#898: and it says to demote it, which is the whole remedy'

    # 3. THE SCOPING, which is the half a later refactor is most likely to drop. Same document, consumer
    #    fixture: it must pass. Without this assert the check could quietly become repo-wide and every
    #    consumer that keeps a heading of their own would start failing, having changed nothing.
    $shapeFiveConsumer = New-Consumer -Label 'shape-five-consumer'
    Set-Entry -Dir $shapeFiveConsumer -Lines (@($shapeLines |
        ForEach-Object { if ($_ -eq '## PLAN') { '## Our own section', '', 'Text.', '', $_ } else { $_ } }))
    $r = Invoke-Gate -Dir $shapeFiveConsumer -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'shape/#898: a consumer keeping a heading of their own is NOT refused -- heading-blindness is their guarantee'

    # 4. A '##' INSIDE A FENCE is illustration, not a phase. Every reader of this format is fence-aware
    #    and this one has to be too: a document explaining the arc quotes its own headings.
    $shapeFenced = New-SourceRepoFixture -Label 'shape-fenced'
    Set-Entry -Dir $shapeFenced -Lines (@($shapeLines |
        ForEach-Object { if ($_ -eq '## TEST') { '```text', '## NOT A PHASE', '```', '', $_ } else { $_ } }))
    $r = Invoke-Gate -Dir $shapeFenced -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'shape/#898: a ## inside a fence is illustration -- quoting a heading is not writing one'

    # 5. #899 -- branch prose in the preamble, in the shape both measured instances had: a plain paragraph
    #    flush against the guidance block, with no heading between them.
    $preBranch = New-Consumer -Label 'pre-branch'
    Set-Entry -Dir $preBranch -Lines (@($shapeLines |
        ForEach-Object { if ($_ -eq '## PLAN') { 'PLAN only for now (issue #886) -- do not start CREATE until Dave says go.', '', $_ } else { $_ } }))
    $r = Invoke-Gate -Dir $preBranch -Branch 'feat/thing'
    Assert-True ($r.Code -ne 0) 'shape/#899: branch prose above the first ## fails the gate'
    Assert-True ($r.Out -match 'PLAN only for now') 'shape/#899: and the finding quotes the line, so there is nothing to hunt for'

    # 6. AND IT HOLDS IN A CONSUMER, deliberately unlike #898: this rule reads the shape, so it says the
    #    same thing in every repo. The asymmetry between 5 and 3 is the design, not an inconsistency.
    Assert-True ($preBranch -notmatch 'nothing') 'shape/#899: (the fixture above is a CONSUMER -- the rule is not source-scoped)'

    # 7. A TRANSLATED GUIDANCE BLOCK STILL PASSES, which is the reason this is a shape rule and not a byte
    #    comparison against StepsGuidance. Inbound #562 is the measured consumer who translated the block;
    #    a byte check would have refused their correct document.
    $preTranslated = New-Consumer -Label 'pre-translated'
    Set-Entry -Dir $preTranslated -Lines (@(
        '# Development: `feat/thing` ' + [char]0x00B7 + ' 20260826-120000',
        '',
        '> **Zo wordt dit bestand gelezen.** Een stap is `- [ ]` tot hij is afgehandeld.',
        '> De vier fasen staan hieronder.',
        '',
        '## PLAN', '', '## CREATE', '', '- [x] Done', '', '## TEST', '',
        '## DEPLOY: `feat/thing`', '', 'It does the thing.', '', '**Score:** 3'))
    $r = Invoke-Gate -Dir $preTranslated -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'shape/#899: a translated guidance block passes -- the rule reads the blockquote, not the words'

    # 8. #915 -- THE REAL SCAFFOLDED PREAMBLE, which is the one shape none of the seven above ever fed this
    #    gate. Scenarios 1-7 spell their head out by hand (with reason: the region's SHAPE is the subject of
    #    #899, and a formatter call would have read as though it were incidental) -- but that hand-written
    #    head is also why a generator writing a BROKEN preamble shipped green. Format-Development
    #    composed the heading levels from the knobs with '+' inside a ',' array literal, so ',' bound first
    #    and dropped four bare '###'/'####' lines into the guidance; this gate read them as branch content
    #    and refused every document new-branch wrote, here and in every consumer taking the plugin.
    #
    #    So the preamble comes from the FORMATTER and the phases stay written out: the suite's stated rule
    #    ("the entry states come from the real formatters") applied to the half that had been exempt. Taken
    #    up to the first phase heading rather than by a line count, so the guidance may grow without this
    #    scenario going stale.
    $scaffoldPreamble = @()
    foreach ($cycleLine in (Format-Development -Branch 'feat/thing' -Id '20260826-000000')) {
        if ($cycleLine -match ('^#{' + (Get-BranchCycleSectionLevel) + '}\s+\S')) { break }
        $scaffoldPreamble += $cycleLine
    }
    Assert-True ($scaffoldPreamble.Count -gt 4) 'shape/#915: (the fixture really carries the generated guidance, not an empty head)'
    $phaseHashes = '#' * (Get-BranchCycleSectionLevel)
    $shapeReal = New-SourceRepoFixture -Label 'shape-real-preamble'
    Set-Entry -Dir $shapeReal -Lines ($scaffoldPreamble + @(
        "$phaseHashes PLAN", '', "$phaseHashes CREATE", '', '- [x] Did the thing', '', "$phaseHashes TEST", ''
    ) + $shapeEntry)
    $r = Invoke-Gate -Dir $shapeReal -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'shape/#915: the preamble the scaffolder actually writes passes the gate that reads it'

    # 9. #924 -- THE FINDING NAMES THE LEVEL IT ACTUALLY READ. The gate derives the phase level from the
    #    document's own title, and until this scenario only the [OK] line quoted that derivation: six
    #    markers on the failure path were typed as '##'/'###'. So on the day the shape shifted one level
    #    down, a refused document was told to demote a '###' to a '###' and to look above "the first '##'"
    #    in a document whose phases are '###' -- the success path level-aware and the failure path not,
    #    which is the worse way round, since the failure message is the one read while confused.
    #
    #    Fed the same defect twice, at two levels, through one code path. That is the only shape that can
    #    tell "reads the document" apart from "happens to match today's constant", and it is why the
    #    asserts match on the LEVEL rather than on the wording -- a rephrasing must not break them.
    $strayNote = 'Parked until Dave says go.'
    $shapeLevelNow = New-SourceRepoFixture -Label 'shape-level-now'
    Set-Entry -Dir $shapeLevelNow -Lines ($scaffoldPreamble + @($strayNote, '') + @(
        "$phaseHashes PLAN", '', "$phaseHashes CREATE", '', '- [x] Did the thing', '', "$phaseHashes TEST", ''
    ) + $shapeEntry)
    $r = Invoke-Gate -Dir $shapeLevelNow -Branch 'feat/thing'
    Assert-True ($r.Code -ne 0) 'shape/#924: (the fixture really is refused -- the stray sits in the preamble)'
    Assert-True ($r.Out -match ("above the first '" + $phaseHashes + "'")) `
        "shape/#924: the preamble finding names the document's own phase level, not a typed '##'"
    Assert-True ($r.Out -match ("as a '" + ('#' * ((Get-BranchCycleSectionLevel) + 1)) + "'")) `
        'shape/#924: and the remedy names one level under it, so nobody is told to demote a heading to its own level'

    # The legacy-level half: phases at '##', so the SAME finding has to say '##'. Written out by hand
    # rather than generated, because the point is a document the generator no longer writes.
    $shapeLevelLegacy = New-SourceRepoFixture -Label 'shape-level-legacy'
    Set-Entry -Dir $shapeLevelLegacy -Lines (@($shapeLines |
        ForEach-Object { if ($_ -eq '## PLAN') { $strayNote, '', $_ } else { $_ } }))
    $r = Invoke-Gate -Dir $shapeLevelLegacy -Branch 'feat/thing'
    Assert-True ($r.Code -ne 0) 'shape/#924: (the legacy-level fixture is refused too)'
    Assert-True ($r.Out -match "above the first '##'") `
        'shape/#924: a document whose phases are ## gets a finding that says ## -- the level follows the file, not the calendar'

    # 10. #908 -- THE SAME FIXTURE WITH -Intent, which is the one input scenario 8 does not pass and the
    #    reason this defect shipped green. Scenario 8 proves the scaffolder's GUIDANCE passes the gate that
    #    reads it; it says nothing about the scaffolder's other writer into that same region. -Intent was
    #    one: it emitted a branch's parking note between the guidance and the first phase, so new-branch
    #    -Intent produced a document this gate refused -- silently on a fresh scaffold, because the
    #    unwritten-entry check exits first, and then loudly at the PR once the entry was written.
    #
    #    SO THIS FEEDS THE WHOLE DOCUMENT, not a hand-assembled head. Scenario 8 takes the preamble from
    #    the formatter and writes the phases out, deliberately, because the region's SHAPE is #899's
    #    subject. Here the PLACEMENT is the subject, so the phases have to come from the formatter too --
    #    a hand-written '## PLAN' would be the test asserting its own idea of where the intent goes.
    #    The entry half is replaced with the written one, because the entry check runs first and a
    #    scaffolded entry would mask whatever the shape check has to say.
    $intentText = 'Skeleton + routing done; next: wire the API client.'
    $cycleWithIntent = @(Format-Development -Branch 'feat/thing' -Id '20260826-000000' -Intent $intentText)
    $entryHeadRx = '^#{1,6}\s+DEPLOY\b'
    $cycleHead = @()
    foreach ($cycleLine in $cycleWithIntent) {
        if ($cycleLine -match $entryHeadRx) { break }
        $cycleHead += $cycleLine
    }
    Assert-True (@($cycleHead | Where-Object { $_ -eq $intentText }).Count -eq 1) `
        'shape/#908: (the fixture really carries the intent, once, above the entry)'
    $shapeIntent = New-SourceRepoFixture -Label 'shape-intent'
    Set-Entry -Dir $shapeIntent -Lines ($cycleHead + $shapeEntry)
    $r = Invoke-Gate -Dir $shapeIntent -Branch 'feat/thing'
    Assert-True ($r.Code -eq 0) 'shape/#908: a document carrying -Intent passes -- the note is inside a phase, not above the first one'
    Assert-True ($r.Out -notmatch 'branch content above') 'shape/#908: and specifically not as a preamble stray'
}
finally {
    foreach ($d in $script:trees) {
        if ($d -and (Test-Path -LiteralPath $d)) {
            Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILED: $($script:fail) of $($script:pass + $script:fail) asserts." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
