<#
.SYNOPSIS
    Regression tests for scripts/lib/entry-scaffold-lib.ps1 and the scaffold gate that reads it -- the
    guard that refuses a PR whose changelog entry still carries the wording it was scaffolded with.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/entry-scaffold.tests.ps1

    Three layers, in the order that a failure is most usefully diagnosed:

      1. Get-EntryScaffoldWording -- the seam probe: defaults when the repo says nothing, this repo's
         answers when it does, and an empty override IGNORED rather than honoured.
      2. Get-EntryScaffoldFindings -- the pure matcher, including the exact shape that shipped in
         v3.2.0 (heading kept, status appended) and the fenced-code exclusion.
      3. THE ROUND TRIP, which is the real point: an entry written by the actual new-branch.ps1
         must be seen as scaffolded by the actual matcher. That is the assert that makes the writer and
         the guard incapable of disagreeing -- the whole reason the wording became one shared source
         rather than a copy in each script.

    Pure ASCII (repo convention for .ps1). The middot in an entry heading is built from its codepoint.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot        = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibSrc          = Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1'
$NewBranchSrc = Join-Path $RepoRoot 'scripts\task\new-branch.ps1'
$BranchInfoSrc   = Join-Path $RepoRoot 'scripts\lib\branch-info.ps1'
# new-branch reads the changelog seam through this since inbound #967, to state the right link base in the
# guidance it writes. In a real consumer it arrives with the plugin, beside the scripts; the fixture below
# is a hand-built stand-in for that tree, so it has to be copied in like the other two.
$SeamLibSrc      = Join-Path $RepoRoot 'scripts\lib\seam-lib.ps1'
# AND THE TWO THE PUSH PATH NEEDS, which the fixture below did NOT hold until inbound #1046 -- and it has
# been silently broken since #900 made the creation push the default. new-branch dot-sourced
# native-capture-lib.ps1 unconditionally in its push block, so the fixture's run has been dying there with
# exit 1 all along; it happened AFTER the document was written, the child's stderr goes to $null and its
# exit code is not read, so every assert below stayed green over a run that failed. #1046 moved that
# dot-source ABOVE the checkout (a second caller needs it before HEAD moves) and the same missing file then
# killed the run BEFORE the document existed, which is how a two-week-old hole surfaced. Same reasoning as
# seam-lib above: in a real consumer these arrive with the plugin, so the stand-in tree has to hold them.
$NativeCaptureSrc = Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1'
$ParkLibSrc       = Join-Path $RepoRoot 'scripts\lib\park-lib.ps1'
$OpenPrSrc       = Join-Path $RepoRoot 'scripts\release\open-pr.ps1'

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

. $LibSrc

# --- 1. Get-EntryScaffoldWording: the seam probe --------------------------------------------------
Write-Host "Get-EntryScaffoldWording (the seam probe)" -ForegroundColor Cyan
# No getters defined -> the built-in English defaults. Asserted on the literal values because they are
# the contract with every consumer that configures nothing.
$bare = Get-EntryScaffoldWording
Assert-Equal 'TODO: title' $bare.Title 'no getters: the default placeholder title'
Assert-Equal '**To do / where I left off:**' $bare.BodyHeading 'no getters: the default body heading'
Assert-Equal 'TODO: what this change does, for whoever reads CHANGELOG.md later.' $bare.BodyPlaceholder 'no getters: the default fallback body'

function Get-EntryTitlePlaceholder { return 'TE DOEN: titel' }
function Get-EntryBodyHeading { return '**Nog te doen:**' }
$overridden = Get-EntryScaffoldWording
Assert-Equal 'TE DOEN: titel' $overridden.Title 'override: the repo answer wins for the title'
Assert-Equal '**Nog te doen:**' $overridden.BodyHeading 'override: and for the body heading'
Assert-Equal 'TODO: what this change does, for whoever reads CHANGELOG.md later.' $overridden.BodyPlaceholder 'override: an unmentioned string keeps its default -- probed per key, not all-or-nothing'
Remove-Item Function:\Get-EntryTitlePlaceholder, Function:\Get-EntryBodyHeading

# An EMPTY override is ignored, and this is the load-bearing one. A blank marker is a substring of every
# string, so honouring it would make the gate refuse every PR in the repo -- the worst failure available
# to a guard whose only value is being trusted.
function Get-EntryBodyHeading { return '' }
$emptyOverride = Get-EntryScaffoldWording
Assert-Equal '**To do / where I left off:**' $emptyOverride.BodyHeading 'empty override: ignored, the default stands (a blank marker would match everything)'
Remove-Item Function:\Get-EntryBodyHeading

# --- 2. Get-EntryScaffoldFindings: the pure matcher -----------------------------------------------
Write-Host "Get-EntryScaffoldFindings (the matcher)" -ForegroundColor Cyan
$midDot = [char]0x00B7

# THE FORMAT'S LEVELS COME FROM THE LIB, and they are declared HERE -- at the top, before the first fixture --
# because a fixture further down the file cannot use a variable defined below it. That is not a style point:
# the tilde-fence and fenced-insert fixtures sit above where these used to live, kept their literal '##' when
# everything else was composed, and were the last four failures of the shift on August 26, 2026.
#
# A document's SHAPE depends on the relationships, not the numbers: the pending heading is one level shallower
# than an entry, an entry one shallower than its sections, and a tier sub-heading follows the section level.
# Writing any of them out makes this file a second declaration of the format, free to drift from the one the
# functions under test read.
$entryH = '#' * (Get-EntryHeadingLevel)
$sectH  = '#' * (Get-EntrySectionLevel)
$tierH  = '#' * (Get-EntryTierSubLevel)
$pendH  = Get-ChangelogUnreleasedHeading
$wording = Get-EntryScaffoldWording

$written = "### A real title $midDot Feat $midDot 2026-08-03`n`nThis entry says what the change does.`n"
Assert-Equal 0 (@(Get-EntryScaffoldFindings -EntryText $written -Wording $wording)).Count 'a written entry produces no findings'

# The CURRENT untouched scaffold: since the branch/ split the writer no longer puts a to-do heading above
# the body, so an unedited entry carries exactly two markers.
$untouched = "## TODO: title`n`n### What does this change do?`n`nTODO: what this change does, for whoever reads CHANGELOG.md later.`n"
$bothMarkers = @(Get-EntryScaffoldFindings -EntryText $untouched -Wording $wording)
Assert-Equal 2 $bothMarkers.Count 'a completely untouched scaffold produces a finding per marker it carries'
Assert-True (@($bothMarkers | ForEach-Object { $_.Label }) -contains 'the placeholder title') 'the placeholder title is named'
Assert-True (@($bothMarkers | ForEach-Object { $_.Label }) -contains 'the fallback body') 'the fallback body is named'
Assert-True ($bothMarkers[0].Marker -is [string] -and $bothMarkers[0].Marker.Length -gt 0) 'each finding carries the literal marker it matched, for the error message'

# THE PRE-SPLIT SCAFFOLD IS STILL REFUSED, and this is the assert that matters most about the change that
# retired it. Every consumer with a branch in flight has an entry in exactly this shape, and they receive
# the new scripts through a plugin update rather than by choosing to. A gate that only knew the current
# wording would wave all of them through into CHANGELOG.md without erroring -- so both are recognised, and
# only one is written.
$legacyUntouched = "### TODO: title $midDot Chore $midDot 2026-08-03`n`n**To do / where I left off:**`n`nTODO: what still needs to happen on this branch, and where you left off.`n"
$legacyFindings = @(Get-EntryScaffoldFindings -EntryText $legacyUntouched -Wording $wording)
Assert-Equal 3 $legacyFindings.Count 'the pre-split scaffold still produces all three of its findings'
Assert-True (@($legacyFindings | ForEach-Object { $_.Label }) -contains 'the scaffold body heading') 'the retired body heading is still named'
Assert-True (@($legacyFindings | ForEach-Object { $_.Label }) -contains 'a retired scaffold placeholder') 'and the retired placeholder is named as retired, so the message says which era it came from'

# THE SHAPE THAT ACTUALLY SHIPPED (v3.2.0, entries #424/#425/#426): the author kept the heading and
# appended a status behind it. A whole-line match would have passed all three, which is why the matcher
# uses a substring. This assert is the measured case, not a hypothetical.
$measured = "### cut-release moves to the shared mirror $midDot Feat $midDot 2026-08-03`n`n**To do / where I left off:** phase 1 done -- lint gate green, all 23 suites green.`n"
$measuredFindings = @(Get-EntryScaffoldFindings -EntryText $measured -Wording $wording)
Assert-Equal 1 $measuredFindings.Count 'the v3.2.0 shape (heading kept, status appended) IS caught'
Assert-Equal 'the scaffold body heading' $measuredFindings[0].Label 'and it is reported as the body heading rather than the fallback body'

# Fenced code is excluded: this repo's own docs quote the scaffold while explaining this mechanism, and a
# guard that cannot tell a quote from the real thing gets switched off.
$quoted = "### Document the scaffold $midDot Docs $midDot 2026-08-03`n`nThe generated stub looks like this:`n`n" + '```' + "`n**To do / where I left off:**`nTODO: title`n" + '```' + "`n`nThat is the wording the gate refuses.`n"
Assert-Equal 0 (@(Get-EntryScaffoldFindings -EntryText $quoted -Wording $wording)).Count 'scaffold wording inside a fence is not a finding'
# ...but outside the fence in the same file it still is, so the exclusion is scoped rather than a blanket
# amnesty for any entry that happens to contain a fence.
$quotedPlusReal = $quoted + "`n**To do / where I left off:** still figuring this out.`n"
Assert-Equal 1 (@(Get-EntryScaffoldFindings -EntryText $quotedPlusReal -Wording $wording)).Count 'the same wording OUTSIDE the fence in that file is still caught'

Assert-Equal 0 (@(Get-EntryScaffoldFindings -EntryText '' -Wording $wording)).Count 'an empty entry produces no findings rather than throwing'
# An unclosed fence swallows the tail. Asserted deliberately: it can only cause a MISSED finding, never a
# false accusation against prose somebody did write, and that is the direction a guard should fail in.
$unclosed = "### T $midDot Feat $midDot 2026-08-03`n`n" + '```' + "`n**To do / where I left off:**`n"
Assert-Equal 0 (@(Get-EntryScaffoldFindings -EntryText $unclosed -Wording $wording)).Count 'an unclosed fence hides the tail -- the safe direction (a miss, not a false accusation)'

# A 'Plugins:' LINE IS THE FOLD'S TO WRITE (issue #1015). fold-changelog-entry.ps1 derives it from the
# PR's touched files and appends it at the merge; an author who copies the folded shape into the branch
# document's '#### Pull Request' section leaves a second one, and the fold's unconditional append
# doubled it -- 22 reached the changelog. The gate now tells the author on the branch, before the merge.
$withPlugins = "## A real title`n`n### What does this change do?`n`nReal prose about the change.`n`n#### Pull Request`n`nA real title`n`nPlugins: team-alpha`n"
$pluginFindings = @(Get-EntryScaffoldFindings -EntryText $withPlugins -Wording $wording)
Assert-Equal 1 $pluginFindings.Count 'a hand-written Plugins: line is a finding'
Assert-True ($pluginFindings[0].Label -like "*Plugins*") 'and it is named as a Plugins: line, not one of the scaffold markers'
Assert-True ($pluginFindings[0].Marker -eq 'Plugins: team-alpha') 'the finding quotes the line it matched'
# Same fence rule as the scaffold markers: an entry documenting the format may quote the line.
$pluginQuoted = "## Document the fold $midDot Docs $midDot 2026-08-03`n`nThe fold appends:`n`n" + '```' + "`nPlugins: team-alpha`n" + '```' + "`n`nThat line is machine-written.`n"
Assert-Equal 0 (@(Get-EntryScaffoldFindings -EntryText $pluginQuoted -Wording $wording)).Count 'a Plugins: line inside a fence is illustration, not a finding'
# A written entry with no Plugins: line is still clean -- the check adds nothing to the happy path.
Assert-Equal 0 (@(Get-EntryScaffoldFindings -EntryText $written -Wording $wording)).Count 'the Plugins: check does not fire on an entry that has no such line'

# --- 3. The round trip: the writer's output must trip the guard -----------------------------------
Write-Host "the round trip (new-branch writes what the gate refuses)" -ForegroundColor Cyan
# THE ASSERT THIS SUITE EXISTS FOR. Both scripts read the wording from the lib, so they cannot disagree
# -- but "cannot" is a claim about code, and this measures it by running the real writer and handing its
# output to the real matcher. If someone reintroduces a literal in either place, this goes red.
$fixture = Join-Path ([System.IO.Path]::GetTempPath()) "entry-scaffold-test-$PID"
if (Test-Path -LiteralPath $fixture) { Remove-Item -Recurse -Force -LiteralPath $fixture }
New-Item -ItemType Directory -Path (Join-Path $fixture 'scripts\task') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $fixture 'scripts\lib') -Force | Out-Null
Copy-Item -LiteralPath $NewBranchSrc -Destination (Join-Path $fixture 'scripts\task\new-branch.ps1') -Force
Copy-Item -LiteralPath $BranchInfoSrc -Destination (Join-Path $fixture 'scripts\lib\branch-info.ps1') -Force
Copy-Item -LiteralPath $LibSrc -Destination (Join-Path $fixture 'scripts\lib\entry-scaffold-lib.ps1') -Force
Copy-Item -LiteralPath $SeamLibSrc -Destination (Join-Path $fixture 'scripts\lib\seam-lib.ps1') -Force
Copy-Item -LiteralPath $NativeCaptureSrc -Destination (Join-Path $fixture 'scripts\lib\native-capture-lib.ps1') -Force
Copy-Item -LiteralPath $ParkLibSrc -Destination (Join-Path $fixture 'scripts\lib\park-lib.ps1') -Force
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    & git -C $fixture init -q 2>$null | Out-Null
    & git -C $fixture config user.email 'tycho-tests@local.invalid' 2>$null | Out-Null
    & git -C $fixture config user.name 'Tycho Tests' 2>$null | Out-Null
    & git -C $fixture symbolic-ref HEAD refs/heads/main 2>$null | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $fixture 'README.md'), "# fixture`n", (New-Object System.Text.UTF8Encoding $false))
    & git -C $fixture add -A 2>$null | Out-Null
    & git -C $fixture commit -q -m 'init' 2>$null | Out-Null
    # new-branch makes the branch ITSELF since the two scripts merged (August 7, 2026) -- the fixture no
    # longer checks one out first. CLAUDE_PROJECT_DIR is what the shared scripts read for their repo root
    # (the dual-context contract), and it is set for the child only rather than for this runner.
    # No -Title: that is the path that leaves every field for the gate to report.
    Push-Location $fixture
    try {
        $env:CLAUDE_PROJECT_DIR = $fixture
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fixture 'scripts\task\new-branch.ps1') -Name 'feat/round-trip-v1' 2>$null | Out-Null
        $script:roundTripCode = $LASTEXITCODE
    } finally {
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        Pop-Location
    }
} finally {
    $ErrorActionPreference = $prevEap
}

# AND THE RUN IS HELD TO ITS EXIT CODE (inbound #1046). Nothing read it, which is how a broken run went
# unnoticed for two weeks: this fixture was missing native-capture-lib.ps1, new-branch dot-sourced that
# unconditionally in its push block, and the resulting exit 1 landed AFTER the document was written -- so
# every assert below passed over a script that had died. The child's stderr goes to $null and its output to
# Out-Null by design (this suite measures the FILE, not the chatter), which leaves the exit code as the only
# thing that can say the run finished at all. So it is asserted, once, here.
Assert-Equal 0 $script:roundTripCode 'the round-trip run finished -- a fixture missing one of the shared libs cannot pass silently any more'

# ONE DOCUMENT, at a fixed path: contributing-davekjohn/development.md, not feat-round-trip-v1.md in the
# root and not a pair under branch/. The path comes from the same lib the readers use.
$writtenDoc = Join-Path $fixture ((Get-BranchFilePaths).File)
Assert-True (Test-Path -LiteralPath $writtenDoc) 'the writer produced the development document in the fixture'
# BOTH HALVES ANSWER SEPARATELY, which is the claim the merge has to keep. Split-Development is what
# every reader in the system uses to find the boundary, so asserting through it is asserting the contract
# rather than a shape this test invented.
$docText  = if (Test-Path -LiteralPath $writtenDoc) { [System.IO.File]::ReadAllText($writtenDoc, [System.Text.Encoding]::UTF8) } else { '' }
$docSplit = Split-Development -Text $docText
Assert-Equal $true $docSplit.Found 'the document carries a DEPLOY section, so the fold has a boundary to split on'
Assert-Equal 'feat/round-trip-v1' (Get-BranchFileDeclaredBranch -Text $docText) 'the document names the branch it belongs to -- the fold reads this back to find the PR'
Assert-True ($docSplit.Head -match '(?m)^- \[ \] ') 'the step half opens its list with an unticked item'
# THE STEP HALF IS NOT AN ENTRY, and asserting it through the gate's own reader is the point: the scaffold
# gate must never be handed the plan. Before the merge this was a separate FILE and the assert was free;
# now it is a section, and the thing being proven is that the split holds.
Assert-Equal 0 @(Get-EntryScaffoldFindings -EntryText $docSplit.Head -Wording (Get-EntryScaffoldWording)).Count 'the step half carries no entry-scaffold markers -- it is not an entry and must not be judged as one'
# AND A CHECKBOX INSIDE THE ENTRY IS NOT A STEP. The gate reads the head, so an entry describing work in
# checkbox shape cannot hold up a PR -- the one regression the merge could introduce that no other assert
# here would see.
$stepsBefore = @(Get-BranchProgressFindings -Text $docText).Count
$withProse   = $docText -replace '(?m)^\*\*Score:\*\*$', "- [ ] a sentence in the entry's prose`r`n`r`n**Score:**"
Assert-Equal $stepsBefore @(Get-BranchProgressFindings -Text $withProse).Count 'a checkbox written into the entry is prose, and the step gate does not count it'

# --- NOTHING IS GENERATED BESIDE THE DOCUMENT ANY MORE --------------------------------------------
# THE FIXTURE IS A CONSUMER, and that is the whole point of asserting it here. It holds the shared scripts
# and nothing else -- no lint, no hand-written references -- which is exactly what a consuming repo has.
#
# WHAT THIS BLOCK USED TO PIN, AND WHY IT IS THE OPPOSITE ASSERT NOW. Until August 7, 2026 nothing created
# branch/templates/ anywhere: they existed in the source repo because they were written by hand there, and
# the check holding them to Get-BranchTemplates is repo-owned. When the working files became bare, the
# source repo's guidance moved to those templates and a consumer's went away entirely -- so new-branch was
# made to write and refresh them. Inbound #810 is what the arrangement still cost: the guidance was in the
# file NEXT TO the one you write in. The merged document carries its own, so the reference is gone and this
# assert is that it stays gone -- a directory nobody maintains is a directory that drifts.
Assert-True (-not (Test-Path -LiteralPath (Join-Path $fixture 'contributing-davekjohn\branch'))) 'the writer creates no branch/ directory -- the document carries its own guidance'

# AND THE GUIDANCE IS IN THE FILE A BRANCH ACTUALLY GETS, which is the half #810 reported. Asserted on one
# of the blocks the report named rather than on "some comment exists": a document that kept the headings and
# lost the hints would pass a laxer test.
Assert-True ($docText -match 'ABOVE the Score line') 'the branch document carries the field guidance itself'
# AND THIS FIXTURE IS EXACTLY THE REPO #967 WAS ABOUT, which is why the assert says THIS DIRECTORY rather
# than THE REPO ROOT. It has no .claude-plugin/marketplace.json, so it is a consumer: Get-DefaultChangelogPath
# puts its CHANGELOG.md inside the workflow folder, the same directory the cycle document sits in. The
# sentence this file carried until then told that author to write the one link form the fold would break --
# and it read as correct here for weeks, because the assert only ever asked whether SOME base was named.
Assert-True ($docText -match 'FROM THIS DIRECTORY') 'including the link convention, which cannot be derived from the file in front of you -- and which names this consumer''s own destination'
Assert-True ($docText -notmatch 'FROM THE REPO ROOT') 'and it does NOT name the root, which is what it wrongly named in every consumer before inbound #967'

# A RERUN CHANGES NOTHING, which is what idempotency means once there is no reference copy to refresh. The
# author's own document must survive it untouched -- byte for byte, because a rerun that "helpfully"
# rewrote the shape would take somebody's written entry with it.
$beforeRerun = $docText
$prevEap2 = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    Push-Location $fixture
    try {
        $env:CLAUDE_PROJECT_DIR = $fixture
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fixture 'scripts\task\new-branch.ps1') -Name 'feat/round-trip-v1' 2>$null | Out-Null
    } finally {
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        Pop-Location
    }
} finally { $ErrorActionPreference = $prevEap2 }
Assert-Equal $beforeRerun ([System.IO.File]::ReadAllText($writtenDoc, [System.Text.Encoding]::UTF8)) 'a rerun on the same branch leaves the document exactly as it was'

if ($docSplit.Found) {
    # THE ENTRY HALF, through the splitter every reader uses. Handed the whole document these asserts would
    # measure the plan too -- the scaffold findings would count the guidance in the head, and the "opens with
    # its own heading" assert would see the document's H1.
    $text = [string]$docSplit.Entry
    $roundTrip = @(Get-EntryScaffoldFindings -EntryText $text -Wording (Get-EntryScaffoldWording))
    Assert-True ($roundTrip.Count -gt 0) 'the matcher sees the writer output as scaffolded -- writer and guard share one source'
    # THREE FINDINGS, AND NONE OF THEM IS A STRING. The dossier form writes no visible placeholder at all --
    # every field is a heading with an empty space under it -- so what the gate reports is EMPTINESS: the PR
    # title the author owes, plus one per tier with no reason yet. It was five until August 16, 2026, when
    # the separate title and body sections went: this fixture's repo states no audience tier, so it is
    # scaffolded with all three, and 1 + 3 is the count. A gate still looking for 'TODO: title' would have
    # gone silent on the very entry it exists to stop.
    Assert-Equal 4 $roundTrip.Count 'and it names each unanswered field: the PR title, and all three tiers'
    Assert-Equal 0 @($roundTrip | Where-Object { $_.Label -notmatch 'unanswered|no reason' }).Count `
        'all three are measurements of an empty field rather than matches on placeholder prose'
    # THE ENTRY NO LONGER ASKS FOR A TO-DO LIST, which is the whole point of the split: the file whose text
    # folds verbatim into CHANGELOG.md must prompt for what the change DOES.
    Assert-True (-not ($text -match 'To do / where I left off')) 'the entry carries no to-do heading -- that job moved to the step list'
    # THE SAME ROUND TRIP FOR THE IMPACT DECLARATION, and it is the assert that matters most for the tier
    # model: the writer, the validator (open-pr), the fold and the cut all read this one format, and a real
    # file written by the real writer is the only thing that proves they agree. Tier 0 is DECLARED, not merely
    # defaulted -- the difference is what lets the fold tell "somebody chose 0" from "somebody forgot".
    $writtenImpact = Resolve-EntryImpact -EntryText $text
    Assert-Equal $true $writtenImpact.Table 'the writer writes an impact table, not the superseded Tier: line'
    Assert-Equal 0 $writtenImpact.Tier 'and the row it writes is the harmless default tier'
    Assert-Equal $true $writtenImpact.Declared 'declared, not omitted -- so the fold can tell a choice from a forgetting'
    Assert-Equal 0 @($writtenImpact.Errors).Count 'the written table parses without complaint'
    Assert-Equal 0 ([int]$writtenImpact.Rows[0].Score) 'with NO score, because any scaffolded number would be a guess at a ranking'
    # A tier-0 entry owes nothing, so the writer's own output must pass the gates it will meet.
    Assert-Equal 0 @(Get-EntryImpactFindings -EntryText $text).Count 'and a freshly scaffolded entry has no impact findings against it'

    # THE SHAPE OF THE FILE: one H2 for the change, three H3 sections inside it. Asserted on a file the real
    # writer produced rather than on Format-EntryBlock, because the two agreeing is the actual claim.
    $entryLines = @(($text -split "`r?`n") | Where-Object { $_.Trim() -ne '' })
    Assert-True ($entryLines[0] -match ('^#{' + (Get-EntryHeadingLevel) + '} ')) 'the entry opens with its own heading, at the entry level'
    Assert-True ($entryLines[0] -notmatch '^#{4}') 'and not one level deeper'
    # THE HEADING NAMES THE BRANCH, not the change (Dave, August 6, 2026). Asserted against the reader that
    # has to get it back out: the fold looks the PR up by this name, so writer and reader agreeing about the
    # backticks is the whole contract.
    Assert-Equal 'feat/round-trip-v1' (Get-BranchFileDeclaredBranch -Text $text) 'the entry heading names the branch, and reads back as it'
    # THE WRITTEN KEYS, NOT EVERY RECOGNISED ONE (August 16, 2026). Get-EntrySectionHeadings answers for the
    # four retired keys too -- that is what keeps the entries already in CHANGELOG.md readable -- so walking
    # it here would demand headings the scaffolder deliberately stopped writing.
    $sectionKeys = @(Get-EntryWrittenSectionKeys)
    foreach ($key in $sectionKeys) {
        Assert-True ($text -match ('(?m)^' + [regex]::Escape((Get-EntrySectionHeading -Key $key)) + '\s*$')) `
            "the '$key' section heading is written verbatim as the parser expects it"
    }
    # AND THE RETIRED ONES ARE ABSENT, which is the half that would otherwise go unnoticed: a writer that
    # kept emitting them would pass every assert above while producing the document this change removed.
    foreach ($gone in @('Description', 'Id', 'Type', 'Significance')) {
        Assert-True ($text -notmatch ('(?m)^' + [regex]::Escape((Get-EntrySectionHeading -Key $gone)) + '\s*$')) `
            "the retired '$gone' section is no longer written"
    }
    # ORDER, not just presence: the parser finds a section wherever it is, but a reader meets them in the
    # order they are written, and the lint's split-entry rule keys on which one comes FIRST. Walked from the
    # map rather than spelled out, so reordering the sections cannot leave this assert testing yesterday.
    $positions = @($sectionKeys | ForEach-Object { $text.IndexOf((Get-EntrySectionHeading -Key $_)) })
    $ascending = $true
    for ($i = 1; $i -lt $positions.Count; $i++) { if ($positions[$i] -le $positions[$i - 1]) { $ascending = $false } }
    Assert-True $ascending 'and the sections are written in the order the map declares them'
    Assert-Equal 'What' (Get-EntryFirstSectionKey) 'the entry opens with what the change brings -- what the lint tests a split entry against'
    # AND THE OPENER LIST STILL HOLDS THE OLD ONE. This is the assert that would have caught the six false
    # accusations this change first produced against CHANGELOG.md: every pending entry there opens with
    # 'Branch title', and a rule that knew only the current opener reads all of them as split entries.
    Assert-True ((Get-EntryOpeningSectionKeys) -contains 'What') 'the current opener is an opener'
    Assert-True ((Get-EntryOpeningSectionKeys) -contains 'Description') 'and so is the one every entry already in CHANGELOG.md uses'
    # THE TYPE IS THE BRANCH PREFIX IN THE HEADING NOW -- the section that used to state it held the prefix
    # of the branch beside it, which is one fact in two places. Asserted through the same reader the release
    # documents use, so a heading this test accepts cannot be one they file under a catch-all.
    $writtenType = Resolve-EntryType -EntryText $text
    Assert-Equal $true $writtenType.Declared 'the type is declared -- by the branch the heading names'
    Assert-Equal $null $writtenType.Error 'and is a type this repo actually produces'
    Assert-Equal 'Feat' $writtenType.Type 'the prefix in the heading reads back as the canonical type'
    Assert-Equal '' (Get-EntrySectionAnswer -EntryText $text -Key 'Type') 'while the section that used to state it is not written at all'
    # THE PR TITLE'S NEW HOME, which is the contract open-pr composes its title from. This branch was
    # created without -Title, so the right answer is EMPTY -- and empty is the interesting case: the
    # section is present and its guidance stripped, so a reader that returned the hint, or the fold's own
    # PR link, would look like a title and title somebody's PR with it.
    Assert-True (Test-EntryHasSection -EntryText $text -Key 'PullRequest') 'the Pull Request section is written from the start'
    Assert-Equal '' (Get-EntryPrTitle -EntryText $text) 'and a branch created without -Title has no PR title yet, rather than inheriting one'
    # DECLARING TIER 0 IS NOT A STUB -- a tier-0 entry is a legitimate final answer about reach, and the gate
    # must never report the NUMBER as evidence of an unedited entry. What it may report is the empty reason
    # underneath it, which is content the author still owes. The distinction is the whole difference between
    # "you chose the lowest tier" and "you have not said why this matters", so it is asserted rather than
    # assumed: the one tier finding here is about the missing why.
    $tierFindings = @($roundTrip | Where-Object { $_.Marker -match 'Tier' })
    Assert-Equal 3 $tierFindings.Count 'one finding per scaffolded tier -- the tier itself is not faulted, only its missing reason'
    Assert-Equal 0 @($tierFindings | Where-Object { $_.Label -ne 'a tier with no reason' }).Count 'and each says so, rather than accusing the tier of being a stub'
    Assert-Equal 0 @(Get-EntryImpactFindings -EntryText $text).Count 'while the RANKING gates stay silent: tier 0 owes no score'
}
Remove-Item -Recurse -Force -LiteralPath $fixture -ErrorAction SilentlyContinue

# --- 4. The wiring: the gate is really installed in open-pr --------------------------------------
Write-Host "the wiring (open-pr installs the gate, new-branch keeps no copy)" -ForegroundColor Cyan
# Text asserts, for the same reason the cut-release guardrail suite uses them: open-pr.ps1 drives a live
# push and gh, so the gate cannot be exercised end-to-end here without a remote. What IS checkable is
# that the wiring exists and that the duplication did not come back.
$openPrText = [System.IO.File]::ReadAllText($OpenPrSrc)
Assert-True ($openPrText -match 'entry-scaffold-lib\.ps1') 'open-pr dot-sources the shared scaffold lib'
Assert-True ($openPrText -match 'Get-EntryScaffoldFindings') 'open-pr calls the matcher'
Assert-True ($openPrText -match 'scaffold gate:') 'open-pr reports under a named gate, so a block is attributable'
Assert-True ($openPrText -match '(?m)\[switch\]\$Force') 'open-pr declares -Force as the escape valve'
# The gate must sit BEFORE the push, or it reports a problem that has already left the machine.
$gateIdx = $openPrText.IndexOf('scaffold gate:')
$pushIdx = $openPrText.IndexOf("'push'")
Assert-True ($gateIdx -gt 0 -and $pushIdx -gt 0 -and $gateIdx -lt $pushIdx) 'the gate runs before the git push'

$writerText = [System.IO.File]::ReadAllText($NewBranchSrc)
Assert-True ($writerText -match 'entry-scaffold-lib\.ps1') 'new-branch reads the entry format from the shared lib'
# The literals must be GONE as VALUES, not absent as words. Matched on an ASSIGNMENT rather than on the
# bare string, because the writer legitimately names 'TODO: title' in a comment explaining why its -Title
# default is an empty sentinel -- prose about a historical value is not a second copy of it, and an
# assert that cannot tell those apart would push someone to delete a useful comment to get green.
foreach ($literal in @('TODO: title', '**To do / where I left off:**', 'TODO: what still needs to happen')) {
    $assignment = "=\s*'" + [regex]::Escape($literal)
    Assert-True ($writerText -notmatch $assignment) "new-branch assigns no literal '$literal'"
}

# --- 5. The tier line: the entry's other declared fact -------------------------------------------
Write-Host "the tier line (Resolve-EntryTier / Remove-EntryTierLine)" -ForegroundColor Cyan
$md = [char]0x00B7
Assert-Equal 'Tier' (Get-EntryTierLabel) 'the label is the machine-read key, not translated prose'
Assert-Equal 2 (Get-EntryTierMax) 'the model has three tiers, 0 to 2'
Assert-Equal 'Tier: 0' (Format-EntryTierLine) 'the formatter defaults to the harmless tier'
Assert-Equal 'Tier: 2' (Format-EntryTierLine -Tier 2) 'and writes the tier it is given'

# --- 5b. The fold footer: the two facts that only exist after the merge (August 5, 2026) ----------
#     Asserted here rather than in fold-changelog.tests.ps1 on purpose. That suite deliberately runs
#     without a PR -- the fold drives a live remote -- so the with-a-PR path, which is the only path
#     this line has, could not be reached there. Extracting the pure part is the same move (and the
#     same reason) as Get-ExistingPrRecord in pr-issues-lib.ps1.
Write-Host "the fold footer (Format-EntryFoldFooter) and the merge stamp beside it" -ForegroundColor Cyan
# THE LINE IS THE PR AND NOTHING ELSE SINCE AUGUST 19, 2026 (Dave). It carried ' <middot> merged <date>'
# from August 5; the date stamps the 'Pull Request' heading now, so the same fact does not stand twice in
# one section. Asserted as the WHOLE line, which is the claim that proves the date is gone rather than moved
# within it.
$footer = Format-EntryFoldFooter -Number 468 -Url 'https://gh.test/pr/468'
Assert-Equal '[PR #468](https://gh.test/pr/468)' $footer 'the footer carries the PR link, and only that'

# UNLESS THERE IS NO HEADING TO HOLD THE DATE, which is the one case the move above left with nothing.
# A pre-dossier entry has no named sections at all -- its title WAS its heading -- so Set-EntryMergeStamp
# finds nothing to stamp and returns the text unchanged, silently. Without this fallback such an entry
# would land with a PR link and no landing date, in the one document whose subject is when things landed,
# where the same entry folded a day earlier always carried one. Every branch in flight from before
# August 6, 2026 is that shape, here and in every consumer.
$footerLegacy = Format-EntryFoldFooter -Number 468 -Url 'https://gh.test/pr/468' -MergedStamp '20260819-171500'
Assert-Equal "[PR #468](https://gh.test/pr/468) $md merged 20260819-171500" $footerLegacy 'with no heading to stamp, the line carries the landing moment instead'
Assert-Equal $footer (Format-EntryFoldFooter -Number 468 -Url 'https://gh.test/pr/468' -MergedStamp '') 'and an empty stamp leaves the line exactly as the normal path writes it -- the date is never in both places'

# THE DATE ITSELF IS STILL THE PR'S RATHER THAN THE CLOCK'S -- the reasoning the line used to carry, now
# living on the stamp. Same three cases, one heading up.
$stampOnTime = Format-EntryMergeStamp -MergedAt '2026-08-05T09:14:00Z' -FallbackNow '20990101-000000'
Assert-True ($stampOnTime -match '^2026080[45]-\d{6}$') 'the stamp is the PR merge moment'
Assert-True ($stampOnTime -notmatch '2099') 'the PR timestamp wins over the fallback -- the clock is not consulted when gh answered'
# THE CASE THE WHOLE MECHANISM IS ABOUT: a fold that runs the day after the merge must still date the
# entry by the merge, not by the run. Measured in this repo -- unfolded entries were once found in the
# root the morning after they landed.
$stampLate = Format-EntryMergeStamp -MergedAt '2026-08-05T23:30:00Z' -FallbackNow '20260807-101500'
Assert-True ($stampLate -match '^2026080[56]-') 'a late fold still dates the entry by the merge, not by the day it was folded'
# No timestamp: a PR found but not yet merged, which -Branch mode can reach. Then "now" really is the
# best available answer, so the fallback is used rather than the stamp being dropped.
Assert-Equal '20260805-120000' (Format-EntryMergeStamp -FallbackNow '20260805-120000') 'no merge timestamp: the caller-supplied moment is used'
# A malformed timestamp must not turn a completed fold into a failure over a cosmetic field.
Assert-Equal '20260805-120000' (Format-EntryMergeStamp -MergedAt 'not-a-date' -FallbackNow '20260805-120000') 'an unparseable timestamp degrades to the fallback instead of throwing'

$entry2 = "### A title $md Feat $md 2026-08-05`n`nTier: 2`n`n**Body heading**`n`nBody text.`n"
$t2 = Resolve-EntryTier -EntryText $entry2
Assert-Equal 2 $t2.Tier 'a declared tier is read back'
Assert-Equal $true $t2.Declared 'and reported as declared'
Assert-Equal '2' $t2.Raw 'with the raw text kept for quoting back'
Assert-Equal $null $t2.Error 'and no error'

# THE DEFAULT IS THE HARMLESS END, and that is the whole safety argument: forgetting to classify can never
# promote work into a consumer-facing document, only leave it unreleasable on its own.
$tNone = Resolve-EntryTier -EntryText "### A title $md Feat $md 2026-08-05`n`nBody only.`n"
Assert-Equal 0 $tNone.Tier 'no declaration reads as tier 0'
Assert-Equal $false $tNone.Declared 'and is reported as UNdeclared, so a caller can tell the two apart'
Assert-Equal $null $tNone.Error 'an absent line is not an error -- it is the documented default'

# A MALFORMED VALUE IS REPORTED, NOT ABSORBED. Silently reading 'Tier: 5' back as 0 would file
# consumer-facing work as repo-internal: correct-looking output, wrong document, nothing to notice.
$tHigh = Resolve-EntryTier -EntryText "### x $md Feat $md 2026-08-05`n`nTier: 5`n"
Assert-Equal 0 $tHigh.Tier 'an out-of-range tier still falls back to the safe end'
Assert-True ($tHigh.Error -match 'tier 5 does not exist') 'but the error names the value'
$tWord = Resolve-EntryTier -EntryText "### x $md Feat $md 2026-08-05`n`nTier: two`n"
Assert-True ($tWord.Error -match 'is not a tier') 'a non-numeric tier is reported too'
Assert-Equal $true $tWord.Declared 'and still counts as declared -- somebody wrote it, it is just wrong'
$tNeg = Resolve-EntryTier -EntryText "### x $md Feat $md 2026-08-05`n`nTier: -1`n"
Assert-True ($null -ne $tNeg.Error) 'a negative tier is rejected rather than read as a number'

# FENCE-AWARENESS, in both directions. The entry documenting this mechanism quotes the line it explains --
# this repo's own entry for the tier model does -- so a parser that cannot tell a quote from a declaration
# would read the wrong value AND a blind stripper would delete that line out of the fence while folding.
$fencedOnly = "### x $md Feat $md 2026-08-05`n`nAn example:`n`n" + '```text' + "`nTier: 2`n" + '```' + "`n"
$tFenced = Resolve-EntryTier -EntryText $fencedOnly
Assert-Equal 0 $tFenced.Tier 'a tier line only inside a fence is not a declaration'
Assert-Equal $false $tFenced.Declared 'and is reported as undeclared'
Assert-Equal $fencedOnly (Remove-EntryTierLine -EntryText $fencedOnly) 'and the stripper leaves a fenced-only entry byte-identical'

$mixed = "### x $md Feat $md 2026-08-05`n`nTier: 1`n`nBody.`n`n" + '```text' + "`nTier: 2`n" + '```' + "`n"
Assert-Equal 1 (Resolve-EntryTier -EntryText $mixed).Tier 'the real declaration wins over a quoted one'
$stripped = Remove-EntryTierLine -EntryText $mixed
Assert-True ($stripped -notmatch '(?m)^Tier: 1$') 'the real declaration is removed'
Assert-True ($stripped -match '(?m)^Tier: 2$') 'and the quoted one survives -- exactly what was read is what was removed'
Assert-True ($stripped -match 'Body\.') 'the body is untouched'
# No double blank line left behind where the line was.
Assert-True ($stripped -notmatch "`n`n`n") 'the blank line the removal left behind is collapsed'
# CRLF in, CRLF out: the caller has already matched the changelog's own style, so this must not rewrite it.
$crlf = "### x $md Feat $md 2026-08-05`r`n`r`nTier: 1`r`n`r`nBody.`r`n"
$crlfOut = Remove-EntryTierLine -EntryText $crlf
Assert-True ($crlfOut -match "`r`n") 'CRLF line endings survive the strip'
Assert-True ($crlfOut -notmatch "(?<!`r)`n") 'and no bare LF is introduced alongside them'
# Nothing to remove = nothing changed.
$noTier = "### x $md Feat $md 2026-08-05`n`nBody.`n"
Assert-Equal $noTier (Remove-EntryTierLine -EntryText $noTier) 'an entry with no tier line comes back unchanged'

Write-Host "the wiring (open-pr validates the impact, the fold consumes it)" -ForegroundColor Cyan
# Text asserts for the same reason as the scaffold gate above: open-pr drives a live push and gh.
#
# MATCHED AS A CALL, NOT AS A MENTION. The obvious assert here is `-match 'Resolve-EntryImpact'`, and it
# would pass on the COMMENT above the call explaining why the legacy reader was dropped -- the "satisfied by
# a mention rather than a use" failure this repo has measured four times in one day. Requiring the
# assignment shape means only an actual call can satisfy it.
Assert-True ($openPrText -match '\$entryTier\s*=\s*Resolve-EntryImpact') 'open-pr resolves the entry impact -- reach and significance in one read'
# ONE resolve, not two. This was two gates reading two functions, and the legacy one reported tier 0 for a
# table declaring tier 2 -- the author told the opposite of what they wrote, one line above the reader that
# got it right. Two readers of one fact is the drift this repo keeps paying for.
Assert-Equal 1 ([regex]::Matches($openPrText, 'Resolve-EntryImpact -EntryText').Count) 'and does so exactly once, so the two halves cannot disagree'
Assert-True ($openPrText -notmatch 'Resolve-EntryTier -EntryText') 'and no longer calls the legacy tier reader directly'
Assert-True ($openPrText -match 'impact gate:') 'and reports under a named gate, so a block is attributable'
# NOT -Force-able, deliberately: -Force exists for text somebody legitimately wrote, and there is no
# legitimate '| 2 | 9 | x |'. Asserted by reading the refusal block rather than the whole file.
$tierGateIdx = $openPrText.IndexOf('impact gate:')
$tierGateBlock = $openPrText.Substring($tierGateIdx, [Math]::Min(900, $openPrText.Length - $tierGateIdx))
Assert-True ($tierGateBlock -notmatch '\$Force') 'the impact gate has no -Force escape -- a meaningless value is never legitimate'
$foldText = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'scripts\release\fold-changelog-entry.ps1'))
Assert-True ($foldText -match 'entry-scaffold-lib\.ps1') 'the fold dot-sources the shared entry-format lib'
# Resolve-EntryImpact, not Resolve-EntryTier: since the impact table (issue #467) the fold reads the reach
# and the significance in ONE pass, and that resolver falls back to the older 'Tier: N' line itself -- so
# asserting the old name here would demand the fold reach past its own abstraction.
Assert-True ($foldText -match 'Resolve-EntryImpact') 'the fold reads the reach and the significance in one pass'
Assert-True ($foldText -match 'Get-EntryInsertOffset') 'and places the entry by that rank, so CHANGELOG.md stays ordered'
# THE FOLD STRIPS NOTHING FROM THE ENTRY ANY MORE, and this is asserted as an ABSENCE because it is a
# reversal rather than a gap. While the changelog had one section per tier, the heading above an entry stated
# its reach -- so the entry's own 'Tier: N' line was the same fact twice, and an unscored table was a question
# nobody had put. With the sections gone the entry is the only carrier of both, and either strip would be
# silent: the entry would read back as tier 0 and drop out of the release documents, or '### Who is this for'
# would carry a heading with its answer cut out. Matched on the CALL shape, not the bare name, so the comments
# explaining the reversal cannot satisfy the assert -- the "satisfied by a mention rather than a use" failure
# this repo has measured four times in one day.
Assert-True ($foldText -notmatch 'Remove-EntryTierLine -EntryText') 'the fold no longer consumes the legacy tier line -- nothing above the entry states it now'
Assert-True ($foldText -notmatch 'Remove-EntryImpactTable -EntryText') 'and no longer drops an unscored table, which would leave a named section unanswered'
# And it no longer asks any seam WHICH section: the list is flat, so the boundary is structural.
Assert-True ($foldText -notmatch 'Get-ChangelogTierSections') 'and reads no section map -- there are no sections left to file into'
Assert-True ($foldText -match 'Get-EntryHeadingLevel') 'the fold takes the entry heading level from the lib rather than counting hashes itself'
# The tier must be resolved BEFORE anything is written, or a bad tier leaves a half-folded changelog.
Assert-True ($foldText.IndexOf('Nothing was folded') -lt $foldText.IndexOf('Write-Utf8NoBom -Path $changelogPath')) `
    'the pre-pass refusal sits before the first changelog write'

# ==================================================================================================
# THE IMPACT TABLE (issue #467)
# ==================================================================================================
#
# Every assert below is a bug that was actually made while building this, or a failure mode whose whole
# danger is that it produces well-formed output. Two of them were caught by hand and are here so the next
# change cannot reintroduce them silently: the OrderedDictionary integer-indexing trap, and the tie
# direction in the insert offset.

function New-ImpactEntry {
    param([string]$Title = 'T', [string]$Rows = '', [string]$Body = 'Body.')
    $md = [char]0x00B7
    $table = if ($Rows) { "| Tier | Significance | Why |`n|---|---|---|`n$Rows`n`n" } else { '' }
    return "### $Title $md Feat`n`n$table$Body"
}

# --- Reading a table ------------------------------------------------------------------------------
$twoRow = New-ImpactEntry -Rows "| 2 | 5 | consumers must re-add the marketplace |`n| 1 | 4 | the bump stops needing a developer |"
$imp = Resolve-EntryImpact -EntryText $twoRow
Assert-True $imp.Table 'impact: a table outside a fence is recognised'
Assert-Equal 2 $imp.Tier 'and the reach is the HIGHEST row, not the first or the last'
Assert-True $imp.Declared 'and a table with rows counts as declared'
Assert-Equal 0 @($imp.Errors).Count 'and a well-formed table reports no errors'
Assert-Equal 5 (Get-EntryImpactScore -Impact $imp -Tier 2) 'the tier-2 row carries the consumer score'
Assert-Equal 4 (Get-EntryImpactScore -Impact $imp -Tier 1) 'the tier-1 row carries the organisation score'
Assert-Equal 0 (Get-EntryImpactScore -Impact $imp -Tier 0) 'a tier with no row scores 0 rather than throwing'

# ROWS IN EITHER ORDER GIVE THE SAME ANSWER. The parser sorts them; nothing may depend on the author
# having written the highest tier first.
$reversed = Resolve-EntryImpact -EntryText (New-ImpactEntry -Rows "| 1 | 4 | colleagues |`n| 2 | 5 | consumers |")
Assert-Equal 2 $reversed.Tier 'impact: row order does not change the reach'
Assert-Equal 5 (Get-EntryImpactScore -Impact $reversed -Tier 2) 'nor which score belongs to which tier'

# --- The legacy fallback --------------------------------------------------------------------------
# NOT tolerance -- correctness. Every entry in CHANGELOG.md and in every consumer's tree predates the
# table, and reading them as tier 0 would silently empty a release.
$legacy = Resolve-EntryImpact -EntryText "### T`n`nTier: 2`n`nBody."
Assert-True (-not $legacy.Table) 'impact: an entry with no table is not reported as having one'
Assert-Equal 2 $legacy.Tier 'and its old Tier: line is still read'
Assert-True $legacy.Declared 'and still counts as a declared reach'
Assert-Equal 0 (Get-EntryImpactScore -Impact $legacy -Tier 2) 'but it carries no score, because it never had one'
Assert-Equal 0 @(Get-EntryImpactFindings -EntryText "### T`n`nTier: 0`n`nBody.").Count 'a pre-table tier-0 entry is not retroactively faulted'

# --- Fence awareness ------------------------------------------------------------------------------
# The entry documenting this mechanism quotes the table. A parser that cannot tell a quote from a
# declaration gets disabled by whoever hits it first.
$fence = "### T`n`n" + '```text' + "`n| Tier | Significance | Why |`n|---|---|---|`n| 2 | 1 | quoted |`n" + '```' + "`n`nTier: 1`n`nBody."
$fenced = Resolve-EntryImpact -EntryText $fence
Assert-True (-not $fenced.Table) 'impact: a table inside a fence is a quote, not a declaration'
Assert-Equal 1 $fenced.Tier 'so the real declaration outside the fence is what is read'

# --- The ladder is enforced as a ladder -----------------------------------------------------------
$halfClaim = @(Get-EntryImpactFindings -EntryText (New-ImpactEntry -Rows '| 2 | 5 | consumers notice |'))
Assert-Equal 1 $halfClaim.Count 'impact: a tier-2 entry with no tier-1 row is one finding'
Assert-True ($halfClaim[0] -match 'reaches tier 2, so it also reaches tier 1') 'and the message names both tiers'
# $($impact.Tier) vs "$impact.Tier": the second interpolates the OBJECT then appends '.Tier'. It produced
# 'reaches tier @{Table=True; Rows=System.Object[]...}' -- valid output nobody would write on purpose.
Assert-True ($halfClaim[0] -notmatch 'System\.Object|@\{') 'and does not interpolate the object instead of its property'

# --- One mistake is reported once -----------------------------------------------------------------
# A bad cell reads back as unscored, so the completeness checks would pile "tier 2 has no significance"
# on top of "tier 2's significance 9 is off the scale". Measured: one bad cell produced three findings.
foreach ($case in @(
    @{ Row = '| 2 | 9 | x |';    Match = 'off the scale' },
    @{ Row = '| 2 | high | x |'; Match = 'is not a score' },
    @{ Row = '| 5 | 3 | x |';    Match = 'does not exist' }
)) {
    $found = @(Get-EntryImpactFindings -EntryText (New-ImpactEntry -Rows $case.Row))
    Assert-Equal 1 $found.Count "impact: '$($case.Row)' produces exactly one finding, not a pile"
    Assert-True ($found[0] -match $case.Match) "and it is the right one ($($case.Match))"
}
$noWhy = @(Get-EntryImpactFindings -EntryText (New-ImpactEntry -Rows '| 1 | 4 | |'))
Assert-Equal 1 $noWhy.Count 'impact: a score with no Why is one finding'
Assert-True ($noWhy[0] -match "no 'Why'") 'and it names the missing column'
$noScore = @(Get-EntryImpactFindings -EntryText (New-ImpactEntry -Rows '| 1 | - | - |'))
Assert-Equal 1 $noScore.Count 'impact: an empty score cell is one finding'

# --- The scaffold owes nothing --------------------------------------------------------------------
$scaffoldTable = @(Format-EntryImpactTable)
Assert-True ($scaffoldTable[0] -match '^\|\s*Tier\s*\|\s*Significance\s*\|\s*Why\s*\|$') 'the scaffold writes the three-column header'
Assert-Equal 3 $scaffoldTable.Count 'and exactly one data row -- header, separator, tier 0'
Assert-True ($scaffoldTable[2] -match '^\|\s*0\s*\|\s*-\s*\|\s*-\s*\|$') 'and that row is tier 0 with both cells empty, because any number would be a guess'
Assert-Equal 0 @(Get-EntryImpactFindings -EntryText (New-ImpactEntry -Rows '| 0 | - | - |')).Count 'a tier-0 entry is never asked for a score'

# --- Stripping ------------------------------------------------------------------------------------
$stripped = Remove-EntryImpactTable -EntryText $twoRow
Assert-True ($stripped -notmatch '\| Tier \| Significance \| Why \|') 'strip: the table is gone from an outward-facing rendering'
Assert-True ($stripped -match 'Body\.') 'and the body survives'
Assert-True ($stripped -notmatch "`n`n`n") 'and no triple blank line is left behind'
# A quoted table must survive stripping too, or rendering damages the entry that documents the mechanism.
Assert-True ((Remove-EntryImpactTable -EntryText $fence) -match 'quoted') 'strip: a fenced table is left alone'

# --- THE SECTION HEADING GOES WITH THE TABLE ------------------------------------------------------
# The fixture above puts the table bare under the entry heading, which is the pre-#467 shape and the reason
# this went unnoticed: in a REAL entry the table sits under its own '### Who is this for'. Stripping the
# table and keeping that heading left a named question with no answer under it, in every entry of every
# document that travels outward -- 17 per release card at v3.6.0, caught by -NoPush and not by these tests.
$sect = Get-EntrySectionHeadings
$h    = '#' * (Get-EntrySectionLevel)
function New-SectionedEntry {
    param([string]$SignificanceBody = "| Tier | Significance | Why |`n|---|---|---|`n| 2 | 4 | consumers |")
    return "## A title`n`n$h $($sect['What'])`n`nBody paragraph.`n`n$h $($sect['Significance'])`n`n$SignificanceBody`n`n$h $($sect['Type'])`n`nFix`n"
}
$sectioned = Remove-EntryImpactTable -EntryText (New-SectionedEntry)
Assert-True ($sectioned -notmatch [regex]::Escape($sect['Significance'])) 'strip: the section heading goes with the table it introduced'
Assert-True ($sectioned -match [regex]::Escape($sect['Type'])) 'and the section after it survives'
Assert-True ($sectioned -match [regex]::Escape($sect['What'])) 'and so does the one before it'
Assert-True ($sectioned -match 'Body paragraph\.') 'and the description is untouched'
Assert-True ($sectioned -match "Body paragraph\.`r?`n`r?`n$h ") 'and exactly one blank line separates the paragraph from the next heading'
Assert-True ($sectioned -notmatch "`n`n`n") 'and no triple blank line is left behind'

# THE HEADING ONLY GOES WHEN THE SECTION IS ACTUALLY EMPTY. The convention is that the table is the whole
# answer, but a strip that deletes a heading on the strength of a convention deletes somebody's prose the
# first time they write some -- so the emptiness is checked rather than assumed.
$withProse = Remove-EntryImpactTable -EntryText (New-SectionedEntry -SignificanceBody "| Tier | Significance | Why |`n|---|---|---|`n| 2 | 4 | consumers |`n`nAnd a sentence the author added.")
# Matched on the table's HEADER ROW, not on the word 'Significance': that word is now the section heading
# too, so a bare word match reports the heading as a surviving table and passes for the wrong reason.
Assert-True ($withProse -notmatch '\| Tier \| Significance \| Why \|') 'strip: the table still goes when the section holds prose as well'
Assert-True ($withProse -match [regex]::Escape($sect['Significance'])) 'but the heading stays, because the section is not empty'
Assert-True ($withProse -match 'And a sentence the author added\.') 'and the prose is untouched'

# An entry that QUOTES the section heading inside a fence keeps the quoted copy: the entries documenting
# this format do exactly that, and this is the fifth matcher in this lib that has to tell a use from a
# mention.
$quotedHeading = "## A title`n`n$h $($sect['What'])`n`nIt looks like this:`n`n``````text`n$h $($sect['Significance'])`n``````\n`n$h $($sect['Significance'])`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | 3 | colleagues |`n`n$h $($sect['Type'])`n`nDocs`n"
$quotedOut = Remove-EntryImpactTable -EntryText $quotedHeading
Assert-Equal 1 ([regex]::Matches($quotedOut, [regex]::Escape($sect['Significance'])).Count) 'strip: the fenced copy of the heading survives while the real one goes'
Assert-True ($quotedOut -notmatch '\| Tier \| Significance \| Why \|') 'and the real table is still removed'

# --- ONE FENCE READER, AND THE TILDE FORM IT USED NOT TO KNOW -------------------------------------
# There were FOUR fence walks across the two libs: Get-FencedLineFlags in release-lib, a second named one
# here, and two inline walks inside the removers below. They were not equivalent -- only release-lib's
# recognised '~~~' -- so an entry using tilde fences had its quoted content read as STRUCTURE by every
# reader in this file while release-lib's readers handled it correctly. Found by comparing the four, not by
# anything failing, which is why the asserts below are new rather than adjusted.
#
# One owner now, in this lib, because the dependency can only run this way: the fold and this suite load
# this lib standalone. Asserted from three angles -- the flags themselves, every reader that depends on
# them, and the absence of a second definition.
$tildeFlags = Get-FencedLineFlags -Lines @('prose', '~~~', 'Tier: 2', '~~~', 'after')
Assert-Equal $true  $tildeFlags[1] 'fences: a ~~~ marker is fenced'
Assert-Equal $true  $tildeFlags[2] 'fences: and so is the line between the markers -- the form this lib did not know'
Assert-Equal $true  $tildeFlags[3] 'fences: including the closing marker'
Assert-Equal $false $tildeFlags[4] 'fences: back outside afterwards'
$backtickFlags = Get-FencedLineFlags -Lines @('prose', '```', 'Tier: 2', '```', 'after')
Assert-Equal (($backtickFlags | ForEach-Object { [int]$_ }) -join '') (($tildeFlags | ForEach-Object { [int]$_ }) -join '') 'fences: both forms produce the same flags -- one rule, not two'
# An unclosed fence keeps the tail flagged: the safe direction, since it can only cause a missed finding.
Assert-Equal $true (Get-FencedLineFlags -Lines @('text', '~~~', 'Tier: 2'))[2] 'fences: an unclosed ~~~ keeps the tail fenced'
Assert-Equal 0 (@(Get-FencedLineFlags -Lines @())).Count 'fences: an empty list yields no flags rather than throwing'
Assert-Equal 1 (@(Get-FencedLineFlags -Lines @(''))).Count 'fences: a single empty line binds (a Mandatory [string[]] would reject it)'

# EVERY READER THAT DEPENDS ON THE FLAGS, on the tilde form. Each of these would previously have read the
# quoted text as a real declaration -- which is the same defect class four separate times.
$tildeEntry = "## T`n`n" + '~~~text' + "`n| Tier | Significance | Why |`n|---|---|---|`n| 2 | 1 | quoted |`n" +
              "Tier: 2`n" + '~~~' + "`n`nTier: 1`n`nBody."
Assert-True ((Get-EntryTextOutsideFences -EntryText $tildeEntry) -notmatch 'quoted') 'tilde: Get-EntryTextOutsideFences drops a ~~~ block'
Assert-Equal 1 (Resolve-EntryTier -EntryText $tildeEntry).Tier 'tilde: the tier reader takes the REAL line, not the one quoted in a ~~~ fence'
$tildeImpact = Resolve-EntryImpact -EntryText $tildeEntry
Assert-Equal $false $tildeImpact.Table 'tilde: a table quoted in a ~~~ fence is not read as a declaration'
Assert-Equal 1 $tildeImpact.Tier 'tilde: so the impact falls back to the real Tier line'
$tildeStripped = Remove-EntryTierLine -EntryText $tildeEntry
Assert-True ($tildeStripped -match '(?m)^Tier: 2$') 'tilde: Remove-EntryTierLine leaves the QUOTED line inside the fence alone'
Assert-True ($tildeStripped -notmatch '(?m)^Tier: 1$') 'tilde: and removes the real one'
Assert-True ((Remove-EntryImpactTable -EntryText $tildeEntry) -match 'quoted') 'tilde: Remove-EntryImpactTable leaves a ~~~-quoted table alone'

# --- Get-EntryCodeSpans / Remove-EntryCodeSpans -- the three exclusions, as OFFSETS (inbound #1052) ---
# The exclusion was three successive deletions, which is everything a reader needs and nothing a REWRITER
# can use: the cut has to hand the entry back with the illustrations still in it. So the two halves of one
# rule were a stripper and nothing, and links inside fences were rewritten by a cut that the gate judging
# those links never saw. Offsets are the form both halves can read.
Write-Host "Get-EntryCodeSpans -- where the code is, not the text without it (inbound #1052)" -ForegroundColor Cyan
$spanEntry = 'a `x` b' + "`n" + '```' + "`nfenced`n" + '```' + "`n<!-- c -->`nd"
$spans = @(Get-EntryCodeSpans -EntryText $spanEntry)
Assert-Equal 5 $spans.Count 'one inline span, three fenced lines (both markers included) and one comment'
foreach ($s in $spans) {
    Assert-True ($s.Start -ge 0 -and ($s.Start + $s.Length) -le $spanEntry.Length) 'every span lies inside the text it was measured over'
}
$ordered = $true
for ($i = 1; $i -lt $spans.Count; $i++) {
    if ($spans[$i].Start -lt $spans[$i - 1].Start) { $ordered = $false }
}
Assert-True $ordered 'the spans come back ordered by Start'

# THEY CAN OVERLAP, AND NOTHING CLAIMS OTHERWISE. Two stray single backticks on either side of a fenced
# block pair with each other ACROSS it, because the masking blanks a fence rather than closing it off --
# so the inline pass yields one span containing the fenced ones. That behaviour is inherited, not
# introduced: the three strippers this replaced did exactly the same, which is why it is asserted here as
# a property of the shape rather than repaired. Found in review before it shipped, on a docstring that
# had claimed non-overlap.
$straddle = @('text ` oops', '```', 'fenced', '```', 'and [a real link](../foo.md) after and ` closes it.') -join "`n"
$straddleSpans = @(Get-EntryCodeSpans -EntryText $straddle)
Assert-True ($straddleSpans[0].Length -gt ($straddle.Length / 2)) 'the paired stray backticks swallow the fence between them'
Assert-Equal 0 (@(Get-EntryLinkTargets -EntryText $straddle)).Count 'so the gate reads no link there -- the rewriter half of this pair is asserted in release-lib.tests.ps1, where both libs are loaded'
Assert-Equal 0 (@(Get-EntryCodeSpans -EntryText '')).Count 'an empty entry has no spans rather than throwing'
Assert-Equal 0 (@(Get-EntryCodeSpans -EntryText 'plain prose with [a](b.md)')).Count 'and prose with no code at all yields none'

# THE MASKING IS WHAT KEEPS THE OFFSETS TRUE, and this is the case that proves it: a lone backtick inside a
# fence must not pair with one in the prose after it. Stripping would have made them adjacent.
$strayTick = '```' + "`nsee ``pair`n" + '```' + "`nreal `code` here"
$strayOut = Remove-EntryCodeSpans -EntryText $strayTick
Assert-True ($strayOut -notmatch 'pair') 'a stray backtick inside a fence is masked with the fence'
Assert-True ($strayOut -match 'real') 'and the prose after it survives -- the stray tick found no partner outside'

# Remove-EntryCodeSpans is NOT Get-EntryTextOutsideFences: it cuts the spans, so a fenced line leaves its
# break behind and an inline span leaves the prose around it whole.
$removed = Remove-EntryCodeSpans -EntryText 'keep `drop` this'
Assert-Equal 'keep  this' $removed 'an inline span is cut out of its own line, not the line out of the entry'

# Test-EntryOffsetInCodeSpans -- the rewriter's half, on the START of a match.
$probe = @([pscustomobject]@{ Start = 4; Length = 3 })
Assert-Equal $false (Test-EntryOffsetInCodeSpans -Offset 3 -Spans $probe) 'the character before a span is outside it'
Assert-Equal $true  (Test-EntryOffsetInCodeSpans -Offset 4 -Spans $probe) 'its first character is inside'
Assert-Equal $true  (Test-EntryOffsetInCodeSpans -Offset 6 -Spans $probe) 'and so is its last'
Assert-Equal $false (Test-EntryOffsetInCodeSpans -Offset 7 -Spans $probe) 'the character after it is outside again'
Assert-Equal $false (Test-EntryOffsetInCodeSpans -Offset 0 -Spans @()) 'no spans means nothing is inside one'

# AND THE READER STILL ANSWERS WHAT IT ANSWERED, which is what makes swapping its three strippers for the
# shared function safe: the fixture below is the measured one, and the count is still zero.
$sharedQuoting = @(
    'Prose mentioning `[PR #N](url)` inline.', '',
    '```markdown', '- **[`scripts/x.ps1`](../../scripts/x.ps1)** an example', '```', '',
    '<!-- link to the PR in github: [PR #NN](url) - merged <date> -->', ''
) -join "`n"
Assert-Equal 0 (@(Get-EntryLinkTargets -EntryText $sharedQuoting)).Count 'the link gate reads the same set through the shared function'
# And the ranker, which is where a fence-blind read cost an ordering (PR #478).
$tildeList = @(
    '', 'Intro.', '',
    "$entryH #20 Tier 2, quoting the format in tilde fences", '',
    '~~~text', '## #19 A quoted heading', '', '| Tier | Significance | Why |', '|---|---|---|', '| 0 | - | - |', '~~~', '',
    '### Who is this for', '', '| Tier | Significance | Why |', '|---|---|---|', '| 2 | 4 | consumers notice |', '',
    '---', '',
    '## #18 Tier 0', '', '| Tier | Significance | Why |', '|---|---|---|', '| 0 | - | - |', ''
) -join "`n"
$tildeOff = Get-EntryInsertOffset -SectionText $tildeList -Tier 1 -Score 3
$tildeTop = ((($tildeList.Substring($tildeOff)) -split "`r?`n")[0]).Trim()
Assert-Equal "$entryH #20 Tier 2, quoting the format in tilde fences" $tildeTop 'tilde: the insert lands on the real first entry'
Assert-True ($tildeTop -ne '## #19 A quoted heading') 'tilde: a heading quoted in a ~~~ fence is not an entry boundary either'

# THE SECOND DEFINITION IS GONE. Asserted on absence, like the retired renderers in release-lib's suite:
# re-adding a per-lib copy is exactly the thing that produced the four-way divergence, and it should turn a
# test red rather than pass unnoticed. Read from the FILE rather than by Get-Command, because both libs are
# loaded together in every real caller -- so a duplicate definition would simply be shadowed and invisible.
$relLibText = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot '..\lib\release-lib.ps1'), [System.Text.Encoding]::UTF8)
Assert-True ($relLibText -notmatch '(?m)^function Get-FencedLineFlags') 'one owner: release-lib no longer DEFINES a fence reader'
Assert-True ($relLibText -match 'Get-FencedLineFlags') 'one owner: but it still calls it, by the same name, from the lib it dot-sources'
$escLibText = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1'), [System.Text.Encoding]::UTF8)
Assert-Equal 1 (@([regex]::Matches($escLibText, '(?m)^function Get-FencedLineFlags')).Count) 'one owner: and this lib defines it exactly once'

# THE RE-LEVELLER MOVED THE SAME WAY, for the same reason and with the same guard (inbound #953,
# August 27, 2026). Set-EntryHeadingLevel lived in release-lib, which the FOLD deliberately does not depend
# on -- so the fold carried a second, first-line-only answer to "bring this entry to the current level", and
# that answer was the wrong one. Asserted on absence for the reason above: with both libs loaded, a re-added
# copy would be shadowed and invisible.
Assert-True ($relLibText -notmatch '(?m)^function Set-EntryHeadingLevel') 'one owner: release-lib no longer DEFINES the re-leveller'
Assert-True ($relLibText -match 'Set-EntryHeadingLevel') 'one owner: but it still calls it from the lib it dot-sources'
Assert-Equal 1 (@([regex]::Matches($escLibText, '(?m)^function Set-EntryHeadingLevel')).Count) 'one owner: and this lib defines it exactly once'
Assert-Equal 1 (@([regex]::Matches($escLibText, '(?m)^function Get-EntryBlockHeadingLevel')).Count) 'one owner: and the level READER it measures with lives beside it, once'
# AND THE FOLD MUST NOT GO BACK TO DERIVING A LEGACY RANGE FROM TODAY'S LEVEL -- that is the defect itself,
# not a style point: '#{level,level+1}' was correct while the entry level was 2 and silently wrong the day it
# moved to 3.
$foldLibText = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot '..\release\fold-changelog-entry.ps1'), [System.Text.Encoding]::UTF8)
Assert-True ($foldLibText -match 'Set-EntryHeadingLevel') 'the fold re-levels through the shared function'
Assert-True ($foldLibText -notmatch [regex]::Escape('(Get-EntryHeadingLevel) + 1)')) 'the fold derives no legacy heading range from the current level any more'
# NO INLINE WALK LEFT ANYWHERE IN THE OWNER LIB: the two removers used to carry one each, and an inline
# walk is how the tilde gap survived unnoticed in the first place.
#
# BUILT AS A LITERAL AND FALSIFIED, because the first version of this assert was the trap it is guarding
# against. It was written as an escaped regex ('\^\\\\s\*```...') which matched NOTHING and therefore passed
# by looking at nothing -- the same class as the fixture that did not contain what it was written to
# contain, one screen up. Checked against the previous revision before being trusted: the old form appeared
# 3 times there and the union rule 0, which is what makes the counts below evidence rather than decoration.
$tick3 = ([string][char]0x60) * 3
$unionMatcher = "-match '^\s*(" + $tick3      # the one rule, inside Get-FencedLineFlags
$inlineMatcher = "-match '^\s*" + $tick3 + "'" # the shape the three walks used
Assert-Equal 1 (@([regex]::Matches($escLibText, [regex]::Escape($unionMatcher))).Count) 'one owner: the fence rule is written exactly once, and it is the union rule'
Assert-Equal 0 (@([regex]::Matches($escLibText, [regex]::Escape($inlineMatcher))).Count) 'one owner: and no reader tests for a fence inline any more'

# --- The entry-boundary readers moved down too, and for the same reason ----------------------------
# Get-EntryHeadingPattern and Split-EntryBlocks joined Get-FencedLineFlags here on August 10, 2026
# (inbound #561). The asserts mirror the three above exactly, because the failure they guard is the same
# one: a second copy in release-lib would be shadowed in every real caller and therefore invisible.
foreach ($moved in @('Get-EntryHeadingPattern', 'Split-EntryBlocks')) {
    Assert-True ($relLibText -notmatch ('(?m)^function ' + $moved)) "one owner: release-lib no longer DEFINES $moved"
    Assert-True ($relLibText -match $moved) "one owner: but it still calls $moved, from the lib it dot-sources"
    Assert-Equal 1 (@([regex]::Matches($escLibText, ('(?m)^function ' + $moved))).Count) "one owner: and this lib defines $moved exactly once"
}
# WHY THEY HAD TO COME DOWN, asserted rather than only written in the comment: the fold reads the shared
# refusal, and it deliberately does not load release-lib -- so if that dot-source ever appears, the whole
# reason for the move is gone and this test should be the thing that says so.
#
# KEYED ON THE DOT-SOURCE LINE, NOT ON THE NAME, and the first version of this assert was itself the defect
# class this file keeps catching: '-notmatch release-lib' failed on the fold's own HEADER, which explains at
# length why it does not load that lib. A matcher satisfied by a MENTION rather than a use -- the fifth
# instance in this repo, and this time it fired against a correct script.
$foldText = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot '..\release\fold-changelog-entry.ps1'), [System.Text.Encoding]::UTF8)
Assert-True ($foldText -notmatch '(?m)^\s*\.\s.*release-lib') 'the fold still does not DOT-SOURCE release-lib -- the dependency direction the move rests on'
Assert-True ($foldText -match 'Get-PreFlatChangelogRefusal') 'and it reads the shared pre-flat refusal'

# --- Get-PreFlatChangelogRefusal: the guardrail two scripts share (inbound #561) -------------------
# THE MEASURED DEFECT. A consumer on the pre-flat shape had their entry folded ABOVE '## Pull Requests'
# with exit 0 and no warning, because the fold read the first '## ' as the top of the list. cut-release
# refused over the identical assumption; the text is shared now so the two cannot drift.
$flatDoc = "# Changelog`n`nIntro.`n`n$pendH`n`n$entryH A real change`n`n$sectH What does this change do?`n`nBody.`n"
Assert-Equal '' (Get-PreFlatChangelogRefusal -Content $flatDoc -Consequence 'x') 'pre-flat: a current document produces no refusal'
# AND THE SHAPE THIS ONE REPLACED IS NOW REFUSED, which is the point of the shift rather than a side effect
# (August 26, 2026). Entries used to sit at the level the pending heading now occupies, so a document still in
# that shape has its entries read as part of the intro: invisible to the entry loop, preserved by every cut,
# and the document parses as holding nothing to release. Silent, and it would empty a consumer's changelog --
# so the head is scanned and the refusal names the way out.
$priorFlat = "# Changelog`n`nIntro.`n`n" + ('#' * (Get-ChangelogUnreleasedLevel)) +
             " A real change`n`n$entryH What does this change do?`n`nBody.`n"
$priorRef = Get-PreFlatChangelogRefusal -Content $priorFlat -Consequence 'x'
Assert-True ($priorRef -ne '') 'pre-flat: the shape written before the shift IS refused rather than silently emptied'
Assert-True ($priorRef -match [regex]::Escape($pendH)) 'pre-flat: and the refusal names the pending heading the document is missing'
Assert-Equal '' (Get-PreFlatChangelogRefusal -Content "# Changelog`n`nIntro only.`n" -Consequence 'x') 'pre-flat: a document with NO entries yields nothing -- there is no block to misread'
Assert-Equal '' (Get-PreFlatChangelogRefusal -Content '' -Consequence 'x') 'pre-flat: and an empty document does not throw'
# The consumer's actual document: both section headings, a real pre-format entry filed under the first.
$preFlatDoc = "# Changelog`n`nIntro.`n`n## Pull Requests`n`nMerged PRs land here.`n`n### An older change " +
              [char]0x00B7 + " Feat`n`nBody.`n`n## Releases`n`nThe recorded versions.`n"
$refusal = Get-PreFlatChangelogRefusal -Content $preFlatDoc -Consequence 'THE CALLER SAYS THIS'
Assert-True ($refusal -ne '') 'pre-flat: the pre-flat shape IS refused'
Assert-True ($refusal -match "'## Pull Requests'") 'pre-flat: the offending block is named'
Assert-True ($refusal -match "'## Releases'") 'pre-flat: and so is the second -- both, or a reader migrates half a document'
Assert-True ($refusal -match '2 heading') 'pre-flat: the COUNT is stated, which is the number the consumer saw go wrong'
Assert-True ($refusal -match 'THE CALLER SAYS THIS') 'pre-flat: the caller''s consequence clause is spliced in -- the one part that differs between the cut and the fold'
Assert-True ($refusal -match 'Migrate the document first') 'pre-flat: the way out is in the message, not only the diagnosis'
# THE PRE-FORMAT ENTRY UNDER THAT HEADING IS NOT ACCUSED. It declares its type in its heading, which is a
# legitimate shape -- so a refusal counting it would tell a consumer to migrate an entry that is already fine.
Assert-True ($refusal -notmatch 'An older change') 'pre-flat: a pre-format entry is not one of the findings'
# Fence-aware, like every reader here: a document DESCRIBING the pre-flat shape is not in it.
$quotedDoc = "# Changelog`n`nThe old shape was:`n`n" + '```text' + "`n$pendH`n## Pull Requests`n" + '```' + "`n`n$pendH`n`n$entryH A real change`n`n$sectH What does this change do?`n`nBody.`n"
Assert-Equal '' (Get-PreFlatChangelogRefusal -Content $quotedDoc -Consequence 'x') 'pre-flat: a section heading quoted in a fence is not a section heading'
# Get-ChangelogEntryBlocks, the boundary reader underneath it -- the intro is dropped, the entries are not.
$blocks = @(Get-ChangelogEntryBlocks -Content $flatDoc)
Assert-Equal 1 $blocks.Count 'blocks: the intro is not one of them'
Assert-True ($blocks[0].StartsWith("$entryH A real change")) 'blocks: and the block starts at the entry heading'
Assert-Equal 0 @(Get-ChangelogEntryBlocks -Content "# Changelog`n`nIntro only.`n").Count 'blocks: a document with no entry yields an empty array rather than the intro'

# --- The insert offset ----------------------------------------------------------------------------
# ENTRIES SIT AT THE ENTRY LEVEL HERE, and this fixture is where that has now mattered TWICE. First on
# August 5, 2026: the function's $EntryPattern default moved from '### ' to '## ', so a fixture left at H3
# stopped having any entry boundaries at all and every offset silently became "the end". Four asserts went red
# at once, which is the loud version of a failure that in the real document would have been one entry quietly
# appended at the bottom.
#
# AND AGAIN ON AUGUST 26, 2026, in exactly the same shape, because the fixture was repaired by typing '##'
# rather than by composing the level. When the pair shifted to H3 these eleven asserts went red for the
# identical reason -- and the default that moved under them was itself a literal, which is why it is now
# resolved from Get-EntryHeadingLevel in the function body. Composed here for the same reason: a fixture that
# states the format is a second definition of it, and this one has been wrong twice.
$section = "`nIntro.`n`n$entryH #10 Top`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | 5 | big |`n`n---`n`n" +
           "$entryH #11 Mid`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | 3 | ok |`n`n---`n`n"
function Get-InsertLabel {
    param([int]$Score, [int]$Tier = 1)
    $off = Get-EntryInsertOffset -SectionText $section -Score $Score -Tier $Tier
    if ($off -ge $section.Length) { return '<end>' }
    return (($section.Substring($off) -split "`r?`n")[0]).Trim()
}
# NEWEST FIRST SINCE AUGUST 16, 2026 (Dave): the answer is the TOP of the list, for every input. These
# asserts used to walk a (tier, significance) ranking; they now pin that the rank is IGNORED, which is the
# claim that can actually regress. Every score and tier the old table ranked differently is swept here, so
# a ranking creeping back in fails on the first row rather than on an edge case.
foreach ($case in @(
    @{ Score = 5; Tier = 1; What = 'the highest score' }
    @{ Score = 4; Tier = 1; What = 'a middling score, which used to land between the two' }
    @{ Score = 1; Tier = 1; What = 'the lowest score, which used to go last' }
    @{ Score = 0; Tier = 1; What = 'an unscored entry, which used to sink within its tier' }
    @{ Score = 5; Tier = 2; What = 'a further-reaching tier' }
    @{ Score = 5; Tier = 0; What = 'tier 0 on the highest score, which used to sink below tier 1' }
    @{ Score = 0; Tier = 0; What = 'a tier-0 entry declaring nothing' }
)) {
    Assert-Equal "$entryH #10 Top" (Get-InsertLabel -Score $case.Score -Tier $case.Tier) `
        "insert: $($case.What) still lands at the top -- the list is a record, not a ranking"
}
# AND THE SIGNIFICANCE IS STILL READ, somewhere else, which is what makes ignoring it here safe rather than
# careless: the release documents rank themselves on it and the version bump follows the highest tier
# pending. Asserted through the reader those two share, so "the score no longer orders CHANGELOG.md" cannot
# be mistaken for "the score stopped mattering".
$stillScored = Resolve-EntryImpact -EntryText "## #12 X`n`n#### Tier 2`n`nwhy`n`n**Score:** 4`n"
Assert-Equal 2 ([int]$stillScored.Tier) 'insert: the reach is still declared and still read'
Assert-Equal 4 ([int](Get-EntryImpactScore -Impact $stillScored -Tier 2)) 'and so is the score the release documents rank on'
# Compared against the fixture's own length rather than a literal: a hard-coded 8 describes this string,
# not the behaviour, and breaks the moment somebody edits the fixture's intro.
$emptySection = "`nIntro.`n`n"
Assert-Equal $emptySection.Length (Get-EntryInsertOffset -SectionText $emptySection -Score 4 -Tier 1) 'insert: a list with no entries yet appends at its end'

# --- The insert offset is FENCE-AWARE, like every other reader of this format ----------------------
# MEASURED ON A REAL FOLD (PR #477), in the document PR #476 had just created. That entry quotes an entry
# heading inside a ```text fence, as the worked example of the format it introduces -- exactly what an entry
# documenting this mechanism does, and what this suite's own $fence fixture does one screen up. This
# function was the one reader that split blocks with a plain regex, and the consequence was not a
# near-miss:
#
#   * the quoted heading was read as an entry boundary, SPLITTING the real entry in two;
#   * the fragment above the fence holds no impact table -- the table sits further down, under
#     '### Who is this for' -- so it read as tier 0, score 0;
#   * the loop meets that tier-0 fragment FIRST, so the tier-1 entry being folded was inserted above it,
#     at the very top of a list whose next six entries were tier 2.
#
# Well-formed markdown throughout, and the console line even reported it -- "placed above 8 existing
# entries" in a document that had 7. Asserted on the ORDER rather than on the block count, because the
# order is what the release documents inherit.
$fencedList = @(
    '', 'Intro.', '',
    "$entryH #20 Real, tier 2, and it documents the format", '',
    'The shape is:', '',
    '```text',
    '## #19 A quoted heading',
    '',
    '| Tier | Significance | Why |',
    '|---|---|---|',
    '| 0 | - | - |',
    '```', '',
    '### Who is this for', '',
    '| Tier | Significance | Why |', '|---|---|---|', '| 2 | 4 | consumers notice |', '',
    '---', '',
    '## #18 Real, tier 0', '',
    '| Tier | Significance | Why |', '|---|---|---|', '| 0 | - | - |', ''
) -join "`n"
function Get-FencedInsertLabel {
    param([int]$Score, [int]$Tier)
    $off = Get-EntryInsertOffset -SectionText $fencedList -Score $Score -Tier $Tier
    if ($off -ge $fencedList.Length) { return '<end>' }
    return (($fencedList.Substring($off) -split "`r?`n")[0]).Trim()
}
# THE ASSERT SURVIVES THE RANKING'S REMOVAL, AND IT HAD TO BE RE-AIMED TO DO SO (August 16, 2026). It used
# to prove fence-awareness through the RANK -- a tier-1 entry landing below the tier-2 entry whose body
# quotes a heading. With every entry landing at the top, that reasoning is gone and the danger is not: the
# top must be the REAL first entry, never the heading quoted inside the fence three lines into it. A
# fence-blind reader would still find a boundary there and split somebody's fenced block down the middle.
Assert-Equal "$entryH #20 Real, tier 2, and it documents the format" (Get-FencedInsertLabel -Score 3 -Tier 1) 'insert/fenced: the top is the real first entry'
Assert-Equal "$entryH #20 Real, tier 2, and it documents the format" (Get-FencedInsertLabel -Score 5 -Tier 2) 'insert/fenced: and the rank does not move it'
# THE ONE THAT NAMES THE DEFECT DIRECTLY: never the quoted heading. This is what the old rank-based assert
# was really protecting, said without going through the ranking.
Assert-True ((Get-FencedInsertLabel -Score 3 -Tier 1) -ne '## #19 A quoted heading') 'insert/fenced: and never the heading quoted inside the fence'
# The quoted table must not be read as the entry's declaration either -- it says tier 0 where the real
# declaration says tier 2, so a fence-blind read gets BOTH the boundary and the tier wrong.
$blockImpact = Resolve-EntryImpact -EntryText $fencedList.Substring($fencedList.IndexOf('## #20'))
Assert-Equal 2 $blockImpact.Tier 'insert/fenced: the entry reads as tier 2 from its real table, not tier 0 from the quoted one'
# CRLF: the offsets are rebuilt from the same split the fence flags come from, so a CRLF document must not
# be shifted by one byte per line. Asserted by the resulting label rather than the number.
$crlfList = $fencedList -replace "`n", "`r`n"
$crlfOff = Get-EntryInsertOffset -SectionText $crlfList -Score 3 -Tier 1
Assert-Equal "$entryH #20 Real, tier 2, and it documents the format" ((($crlfList.Substring($crlfOff)) -split "`r?`n")[0]).Trim() 'insert/fenced: a CRLF document lands in the same place -- the offsets keep step with the lines'

# --- The rubric -----------------------------------------------------------------------------------
$rubric = @(Get-EntrySignificanceRubric)
Assert-Equal 5 $rubric.Count 'rubric: five bands'
Assert-Equal 5 $rubric[0].Score 'and it reads highest first'
Assert-Equal 1 $rubric[4].Score 'down to the lowest'
Assert-True ($rubric[0].Test -match 'must act') 'and the top band is a TEST rather than a feeling'
# THE ORDEREDDICTIONARY TRAP, walked into on the first run of Get-EntrySignificanceRubric: an
# [ordered]@{ 5 = '...' } indexer takes a POSITIONAL index for an integer, so $map[5] asked for the sixth
# element of a five-element map and threw. On a longer map it would not throw -- it would silently return a
# neighbouring band's text, which is why this is asserted rather than trusted.
$range = Get-EntrySignificanceRange
Assert-Equal 1 $range.Min 'rubric: the scale starts at 1'
Assert-Equal 5 $range.Max 'and ends at 5'
foreach ($band in $rubric) {
    Assert-True ($band.Score -ge $range.Min -and $band.Score -le $range.Max) "rubric: band $($band.Score) is inside the declared scale"
    Assert-True ([bool]$band.Test) "rubric: band $($band.Score) has a test, so a gate printing it says something"
}
Assert-Equal 5 @(Format-EntrySignificanceRubricLines).Count 'rubric: one printable line per band'

# --- Whether the repo ranks at all ----------------------------------------------------------------
Write-Host "Test-EntrySignificanceActive (the off-switch, and its default)" -ForegroundColor Cyan
# ON BY DEFAULT SINCE THE SECTIONS WENT, and this assert is the guard on the landmine that change laid.
# The old answer read the changelog's section map and treated one section as "this repo never adopted
# tiers". The flat changelog has no map, so that read now returns a single built-in section in EVERY repo --
# which would have switched the scaffold's table, both validators and the cut's gate off everywhere, in the
# same commit that made the ranking the document's only ordering, without erroring.
Assert-Equal $true (Test-EntrySignificanceActive) 'no seam defined: ranking is ON, because there is no longer a section count to infer it from'
# THE OPT-OUT IS THE SEAM AND NOTHING ELSE, in both directions -- a knob that only turns one way is how a
# consumer ends up unable to decline a model it never adopted.
function Get-EntrySignificanceEnabled { return $false }
Assert-Equal $false (Test-EntrySignificanceActive) 'the repo seam can switch it off'
Remove-Item Function:\Get-EntrySignificanceEnabled
function Get-EntrySignificanceEnabled { return $true }
Assert-Equal $true (Test-EntrySignificanceActive) 'and back on'
Remove-Item Function:\Get-EntrySignificanceEnabled
# The retired parameter: a caller still passing the old section list must FAIL LOUDLY rather than have it
# silently ignored, because the value it used to pass is exactly the one that now means the opposite.
$sigCmd = Get-Command Test-EntrySignificanceActive
Assert-True (-not $sigCmd.Parameters.ContainsKey('TierSections')) 'and it takes no section list any more -- the retired argument cannot be passed unnoticed'

Write-Host "The Significance sections (the shape that replaced the impact table)" -ForegroundColor Cyan
$sigRows = @(
    [pscustomobject]@{ Tier = 2; Score = 5; Why = 'installs break until the marketplace is re-added' },
    [pscustomobject]@{ Tier = 0; Score = 2; Why = 'the lint gate follows the entry' },
    [pscustomobject]@{ Tier = 1; Score = 4; Why = 'the bump stops needing a developer' }
)
$sigText = (Format-EntrySignificanceSections -Rows $sigRows) -join "`n"
# LOWEST FIRST, which is the opposite of the table. These sections are walked by a person filling them in,
# and that walk starts at tier 0 -- each answer decides whether there is a next one.
Assert-True ($sigText.IndexOf(("$tierH Tier 0")) -lt $sigText.IndexOf(("$tierH Tier 1"))) 'sections: tier 0 comes first, because that is the order they are filled in'
Assert-True ($sigText.IndexOf(("$tierH Tier 1")) -lt $sigText.IndexOf(("$tierH Tier 2"))) 'sections: and tier 1 before tier 2'
Assert-True ($sigText -match ('(?m)^' + [regex]::Escape((Get-EntryScoreLabel)) + ' 5$')) 'sections: the score is its own line, echoing the retired Tier: line'
# THE ROUTING QUESTIONS BELONG TO THE TEMPLATE NOW (Dave, August 7, 2026). They are comments, and the file
# a branch gets carries none -- so the claim they were written for moved with them: it is the reference
# under branch/templates/ that has to keep asking whether there is a next tier. Asserted on the -WithGuidance
# rendering, which is the only one that produces them, and on the bare one NOT producing them. Matched on
# the question's FIRST line: the two are line arrays, and joining them would assert against a string
# nothing writes.
$sigWording = Get-EntrySignificanceWording
$sigTemplate = (Format-EntrySignificanceSections -Rows $sigRows -WithGuidance) -join "`n"
Assert-Equal 1 (@([regex]::Matches($sigTemplate, [regex]::Escape(@($sigWording.Route0)[0]))).Count) 'template: tier 0 carries its routing question even when tier 1 follows'
Assert-Equal 1 (@([regex]::Matches($sigTemplate, [regex]::Escape(@($sigWording.Route1)[0]))).Count) 'template: and tier 1 carries its own'
Assert-True (-not ($sigText -match [regex]::Escape(@($sigWording.Route0)[0]))) 'working file: and the bare rendering carries no question at all -- the templates are the reference'
Assert-True (-not ($sigText -match '<!--')) 'working file: no comment of any kind survives into the file a branch gets'
# ...and both are HTML comments, so the fold takes them out and the record never carries the form.
Assert-True (-not ((Remove-EntryHtmlComments -EntryText $sigText) -match [regex]::Escape(@($sigWording.Route0)[0]))) 'sections: the routing question is comment, so the fold strips it'
Assert-True (-not ($sigText -match 'continue to Tier 3')) 'sections: tier 2 carries none -- there is no successor to route to'

# The scaffold: tier 0 alone, why placeholdered, score EMPTY. A scaffolded score would be a guess at a
# ranking, which is the failure the retired remove-before-publishing marker was measured on.
$sigScaffold = (Format-EntrySignificanceSections) -join "`n"
# ALL THREE TIERS ARE SCAFFOLDED (Dave, August 7, 2026), which reverses what this asserted the day before.
# Tier 1 and 2 used to be left out, and their absence WAS the claim that the change reaches nobody there --
# but an absent section and an unfinished one look identical, so the gate could not tell "reaches no
# consumer" from "nobody got to tier 2 yet". Each tier is answered now: a score, or 'N/A' with a line
# saying why.
foreach ($t in 0..(Get-EntryTierMax)) {
    Assert-True ($sigScaffold -match (('(?m)^' + $tierH + ' Tier ') + $t + '$')) "scaffold: tier $t has a section of its own"
}
Assert-Equal 3 (@([regex]::Matches($sigScaffold, ('(?m)^' + $tierH + ' Tier \d+$'))).Count) 'scaffold: exactly the three the model has, no more'
Assert-True ($sigScaffold -match ('(?m)^' + [regex]::Escape((Get-EntryScoreLabel)) + '\s*$')) 'scaffold: the score is a question left standing, not a number nobody chose'
# BOTH DECORATIONS READ BACK, one is written. Every entry in CHANGELOG.md carries the plain 'Score:'.
Assert-True ([regex]::IsMatch('**Score:** 4', (Get-EntryScorePattern))) 'the bold form is read'
Assert-True ([regex]::IsMatch('Score: 4', (Get-EntryScorePattern))) 'and the plain form every existing entry carries'

Write-Host "Resolve-EntryImpact reads three shapes and writes one" -ForegroundColor Cyan
$sigRound = Resolve-EntryImpact -EntryText ((Format-EntryBlock -Branch 'feat/t' -Description 'T' -Type 'feat' -Body 'b' -ImpactRows $sigRows) -join "`n")
Assert-Equal 2 $sigRound.Tier 'sections round trip: the reach is the highest section'
Assert-Equal $true $sigRound.Declared 'sections round trip: declared'
Assert-Equal 0 @($sigRound.Errors).Count 'sections round trip: no complaints'
Assert-Equal 3 @($sigRound.Rows).Count 'sections round trip: one row per section'
Assert-Equal 4 ([int](@($sigRound.Rows | Where-Object { $_.Tier -eq 1 })[0].Score)) 'sections round trip: the score comes back'
Assert-True ((@($sigRound.Rows | Where-Object { $_.Tier -eq 1 })[0].Why) -match 'stops needing a developer') 'sections round trip: and the why with it'
# THE ROUTING QUESTION IS THE FORMAT'S PROSE, NOT THE AUTHOR'S ANSWER. Reading it as the Why would publish
# a form instruction as the reason a change matters.
Assert-True (-not ((@($sigRound.Rows | Where-Object { $_.Tier -eq 0 })[0].Why) -match 'continue to Tier')) 'sections round trip: the routing question is not mistaken for the why'

# Shape 2 and 3, still read. Every entry in CHANGELOG.md and in every consumer's tree is one of these.
$tableEntry = "## X`n`n### Who is this for`n`n| Tier | Significance | Why |`n|---|---|---|`n| 2 | 4 | consumers |`n"
Assert-Equal 2 (Resolve-EntryImpact -EntryText $tableEntry).Tier 'the impact table is still read'
Assert-Equal 1 (Resolve-EntryImpact -EntryText "### X`n`nTier: 1`n`nbody`n").Tier 'and the pre-table Tier: line'
# ...and the heading those entries carry is not reported as a misspelling by anything that matches names.
Assert-True ((Get-EntryRetiredSectionHeadings) -contains 'Who is this for') "the retired section heading is recognised, so 24 existing entries are not accused of a typo"

Write-Host "'N/A' is a tier declaring it reaches nobody" -ForegroundColor Cyan
# THE ASSERT THE WHOLE AUGUST 7 CHANGE RESTS ON. All three tiers are always in the document, so their
# PRESENCE says nothing about reach -- the answer inside does. Counting a section rather than its answer
# would file every entry as tier 2 and publish repo-internal work to consumers.
$naLabel = Get-EntryScoreNotApplicable
$naEntry = "$sectH Significance`n`n$tierH Tier 0`n`nmatters here`n`n**Score:** 3`n`n" +
           "$tierH Tier 1`n`nno colleague can observe it`n`n**Score:** $naLabel`n`n" +
           "$tierH Tier 2`n`nand no consumer either`n`n**Score:** $naLabel`n"
$naImpact = Resolve-EntryImpact -EntryText $naEntry
Assert-Equal 0 $naImpact.Tier "N/A: the reach is the highest SCORED tier, not the highest section present"
Assert-Equal $true $naImpact.Declared 'N/A: and the entry has still declared itself -- that is a decision, not a silence'
Assert-Equal 3 @($naImpact.Rows).Count 'N/A: all three rows are read'
Assert-Equal 0 @($naImpact.Errors).Count 'N/A: and none of them is an error -- N/A is a valid answer, not a malformed score'
Assert-Equal $true ([bool](@($naImpact.Rows | Where-Object { $_.Tier -eq 2 })[0].NotApplicable)) 'N/A: the row carries the flag, so a caller can tell it from an unanswered one'
Assert-Equal 0 @(Get-EntryImpactFindings -EntryText $naEntry).Count 'N/A: a fully answered entry has nothing outstanding'

# AN UNANSWERED TIER IS NOT AN N/A, and keeping those apart is the reason the flag exists at all. Both read
# back as score 0; only one of them is a decision somebody made.
$blankEntry = "$sectH Significance`n`n$tierH Tier 0`n`nmatters here`n`n**Score:** 3`n`n$tierH Tier 1`n`nsomething`n`n**Score:**`n"
$blankRow = @((Resolve-EntryImpact -EntryText $blankEntry).Rows | Where-Object { $_.Tier -eq 1 })[0]
Assert-Equal $false ([bool]$blankRow.NotApplicable) 'blank: an unanswered score is NOT flagged as N/A'
Assert-Equal 0 ([int]$blankRow.Score) 'blank: and reads as 0, the fail-safe direction'

# THE LADDER STILL CANNOT BE SKIPPED, and N/A is the new way to try it: tier 1 declaring it reaches nobody
# while tier 2 is scored says a change consumers notice gives this project's colleagues nothing.
$skipEntry = "$sectH Significance`n`n$tierH Tier 0`n`na`n`n**Score:** 2`n`n$tierH Tier 1`n`nb`n`n**Score:** $naLabel`n`n$tierH Tier 2`n`nc`n`n**Score:** 4`n"
$skipFindings = @(Get-EntryImpactFindings -EntryText $skipEntry)
Assert-True ($skipFindings.Count -gt 0) 'ladder: N/A under a scored tier is refused'
Assert-True (@($skipFindings -match 'cumulative').Count -gt 0) 'ladder: and the refusal names the reason rather than asking for a number'

# A score the rubric has no meaning for is still an error, and the message now offers N/A as the other
# legitimate answer -- a gate that says "write 1 to 5" at somebody who meant "this reaches nobody" is
# asking them to invent a number.
$badNa = Resolve-EntryImpact -EntryText "$sectH Significance`n`n$tierH Tier 1`n`nwhy`n`n**Score:** nvt`n"
Assert-True (@($badNa.Errors).Count -gt 0) 'a score that is neither a number nor N/A is reported'
Assert-True (@($badNa.Errors -match [regex]::Escape($naLabel)).Count -gt 0) 'and the message names N/A as the other way to answer'

Write-Host "A malformed section is reported rather than absorbed" -ForegroundColor Cyan
$badTier = "$sectH Significance`n`n$tierH Tier two`n`nwhy`n`nScore: 3`n"
Assert-True (@((Resolve-EntryImpact -EntryText $badTier).Errors).Count -gt 0) 'a non-numeric tier is an error, not a section that silently vanishes'
$badScore = "$sectH Significance`n`n$tierH Tier 0`n`nwhy`n`nScore: 9`n"
Assert-True (@((Resolve-EntryImpact -EntryText $badScore).Errors -match 'outside the rubric').Count -gt 0) 'a score outside the rubric is named as such'
$dupTier = "$sectH Significance`n`n$tierH Tier 0`n`na`n`nScore: 1`n`n$tierH Tier 0`n`nb`n`nScore: 2`n"
Assert-True (@((Resolve-EntryImpact -EntryText $dupTier).Errors -match 'a second time').Count -gt 0) 'the same tier twice is two answers to one question'

Write-Host "A reason below the score line is named as misplaced, not as missing (inbound #596)" -ForegroundColor Cyan
# THE DEFECT THIS GUARDS. The collecting loop read the lines under '**Score:**' and threw them away, so a
# tier whose reason was written one line too low reported as 'a tier with no reason' -- the one thing an
# author staring at their own three paragraphs can see is untrue, which makes distrusting the gate the
# natural next move instead of moving the text. Measured in the reporting repo: three tiers, all three
# answered, all three refused as unanswered.
$scoreLabel  = Get-EntryScoreLabel
$belowEntry  = "$sectH Significance`n`n$tierH Tier 0`n`n$scoreLabel 3`n`nthe reason, written under the score`n"
$belowRow    = @((Resolve-EntryImpact -EntryText $belowEntry).Rows | Where-Object { $_.Tier -eq 0 })[0]
Assert-Equal '' ([string]$belowRow.Why) 'below-score: the reason is still NOT the Why -- the gate must keep refusing, or the fold publishes that tier empty'
Assert-Equal 'the reason, written under the score' ([string]$belowRow.WhyBelowScore) 'below-score: but the text is kept, which is what lets the refusal name the real defect'

$belowFindings = @(Get-EntryScaffoldFindings -EntryText $belowEntry -Wording (Get-EntryScaffoldWording))
$belowTier     = @($belowFindings | Where-Object { $_.Marker -match 'Tier' })
Assert-Equal 1 $belowTier.Count 'below-score: the tier is still faulted -- naming it better is not excusing it'
Assert-True ($belowTier[0].Label -match 'BELOW') 'below-score: and the label says where the text is, rather than that there is none'
Assert-True ($belowTier[0].Label -match [regex]::Escape($scoreLabel)) 'below-score: naming the line to move it above, so the fix needs no second reading'

# THE OTHER HALF, and the reason this is two asserts rather than one: an entry with nothing written must
# STILL say 'no reason'. A change that renamed both cases to the same thing would pass a test that only
# checked the new wording, and would have thrown away the distinction it was built to make.
$emptyTierEntry = "$sectH Significance`n`n$tierH Tier 0`n`n$scoreLabel 3`n"
$emptyTierFind  = @(@(Get-EntryScaffoldFindings -EntryText $emptyTierEntry -Wording (Get-EntryScaffoldWording)) |
    Where-Object { $_.Marker -match 'Tier' })
Assert-Equal 1 $emptyTierFind.Count 'empty tier: still one finding'
Assert-Equal 'a tier with no reason' $emptyTierFind[0].Label 'empty tier: and it still reads as missing -- the two cases stay apart'

# THE FALSE-FINDING GUARD, which is why the filtering is one shared helper rather than two copies. The
# templates put guidance comments in the section, and a comment sitting under the score is this format's
# own prose -- counted as a misplaced reason it would accuse an entry nobody has written in yet of having
# put its answer in the wrong place, on every consumer, from the first branch.
$commentBelow = "$sectH Significance`n`n$tierH Tier 1`n`n$scoreLabel`n<!-- Why does this matter to a colleague? -->`n"
$commentRow   = @((Resolve-EntryImpact -EntryText $commentBelow).Rows | Where-Object { $_.Tier -eq 1 })[0]
Assert-Equal '' ([string]$commentRow.WhyBelowScore) 'guidance below the score is this format''s prose, not a misplaced reason'

# THE RELEASE GATE READS THE SAME ROW, so it carried the same misdiagnosis -- and it is the worse place to
# meet it: a cut happens days later, when whoever wrote the entry is not the one reading the refusal.
$belowRanked = "$sectH Significance`n`n$tierH Tier 0`n`nabove, correctly`n`n$scoreLabel 2`n`n" +
               "$tierH Tier 1`n`n$scoreLabel 3`n`nthe colleague-facing reason, one line too low`n"
$belowRankFindings = @(Get-EntryImpactFindings -EntryText $belowRanked)
Assert-Equal 1 $belowRankFindings.Count 'below-score: the ranking gate reports the tier once'
Assert-True ($belowRankFindings[0] -match 'BELOW') 'below-score: and names the placement rather than asking for a Why that is already written'

# THE LEGACY TABLE SHAPE CANNOT CARRY THE PROPERTY, so both gates ask before reading it. Without that guard
# every pre-section entry -- and CHANGELOG.md is full of them -- would throw on a property that is not there.
$tableNoWhy = "$sectH Significance`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | 3 | |`n"
$tableRow   = @((Resolve-EntryImpact -EntryText $tableNoWhy).Rows | Where-Object { $_.Tier -eq 1 })[0]
Assert-Equal $null $tableRow.PSObject.Properties['WhyBelowScore'] 'table shape: carries no WhyBelowScore -- there is no score LINE to be below'
$tableFindings = @(Get-EntryImpactFindings -EntryText $tableNoWhy)
Assert-Equal 1 $tableFindings.Count 'table shape: still reported'
Assert-True ($tableFindings[0] -match "no 'Why'") 'table shape: and in its own wording, which the new branch must not have swallowed'

Write-Host ""
Write-Host "Every refusal is worded in the shape the entry uses, not in the one it replaced" -ForegroundColor Cyan

# THE SHAPE IS RECORDED, which is what makes the wording possible at all. Asserted per shape rather than
# via one round trip: the property is read by a gate that must tell a real table from the two shapes that
# have no columns, and a stamp that were merely "not none" could not.
Assert-Equal 'sections' (Resolve-EntryImpact -EntryText "$tierH Tier 0`n`nr`n`n$scoreLabel 1`n").Shape 'shape: the sections are named as such'
Assert-Equal 'table' (Resolve-EntryImpact -EntryText "| Tier | Significance | Why |`n|---|---|---|`n| 1 | 3 | w |`n").Shape 'shape: the legacy table is named as such'
Assert-Equal 'line' (Resolve-EntryImpact -EntryText "### T`n`nTier: 2`n`nBody.").Shape 'shape: the pre-table line too -- "wrote it the old way"'
Assert-Equal 'none' (Resolve-EntryImpact -EntryText "### T`n`nBody only.").Shape 'shape: and an entry declaring nothing is not the same as one of the three'

# THE THREE REFUSALS, EACH IN BOTH BRANCHES. One assert pair per message, because they are three separate
# strings and a repair that fixed the reported one would leave the other two saying 'row' and 'column' to
# an author looking at headings. The section side must NOT name a column; the table side must still name
# one, since a table genuinely has three and its own wording is the accurate one there.
$sectionCases = @(
    @{ What  = 'no reason under a scored tier'
       Entry = "$sectH Significance`n`n$tierH Tier 0`n`nr`n`n$scoreLabel 2`n`n$tierH Tier 1`n`n$scoreLabel 3`n"
       Table = "$sectH Significance`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | 3 | |`n" }
    @{ What  = 'a tier with no score under a scored one'
       Entry = "$sectH Significance`n`n$tierH Tier 0`n`nr`n`n$scoreLabel 2`n`n$tierH Tier 1`n`nwritten`n`n$scoreLabel`n`n$tierH Tier 2`n`nconsumers`n`n$scoreLabel 4`n"
       Table = "$sectH Significance`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | - | written |`n| 2 | 4 | consumers |`n" }
    @{ What  = 'a rung of the ladder missing altogether'
       Entry = "$sectH Significance`n`n$tierH Tier 0`n`nr`n`n$scoreLabel 2`n`n$tierH Tier 2`n`nconsumers`n`n$scoreLabel 4`n"
       Table = "$sectH Significance`n`n| Tier | Significance | Why |`n|---|---|---|`n| 2 | 4 | consumers |`n" }
)
foreach ($case in $sectionCases) {
    $sec = @(Get-EntryImpactFindings -EntryText $case.Entry)
    Assert-Equal 1 $sec.Count "sections/$($case.What): reported once"
    Assert-True (-not ($sec[0] -match 'column|row')) "sections/$($case.What): and says nothing about rows or columns -- there are none"
    Assert-True ($sec[0] -match [regex]::Escape($scoreLabel)) "sections/$($case.What): it names the score line, which is where the answer actually goes"

    $tab = @(Get-EntryImpactFindings -EntryText $case.Table)
    Assert-Equal 1 $tab.Count "table/$($case.What): reported once"
    Assert-True ($tab[0] -match 'column|row') "table/$($case.What): and keeps the column wording -- a real table has them, so that advice is the accurate one"
}

# THE MISSING-SECTION REFUSAL NAMES THE HEADING THE FORMATTER WRITES, held against the formatter rather
# than against a literal. A refusal telling an author to add '$tierH Tier 1' while the writer emits something
# else is the same defect one level down, and only a shared source can rule it out.
$ladder = @(Get-EntryImpactFindings -EntryText $sectionCases[2].Entry)
Assert-True ($ladder[0].Contains((Get-EntryTierSectionMarker -Tier 1))) 'ladder: the refusal quotes the marker the formatter writes'
$written = @(Format-EntrySignificanceSections)
Assert-True ([bool](@($written | Where-Object { $_ -eq (Get-EntryTierSectionMarker -Tier 1) }).Count)) 'ladder: and the formatter writes that exact heading -- one source, so the two cannot drift'

# THE 'Tier: N' SHAPE GETS THE SECTION WORDING, deliberately, and this is the case that has no third
# variant. It has nowhere to put a score, so the only advice that resolves the refusal is the shape this
# format writes -- pointing at a table it does not have would be the reported defect with a longer history.
$lineShape = @(Get-EntryImpactFindings -EntryText "### T`n`nTier: 1`n`nBody.")
Assert-Equal 1 $lineShape.Count 'line shape: a pre-table entry claiming tier 1 is still asked for its score'
Assert-True (-not ($lineShape[0] -match 'column')) 'line shape: and not sent to a column, which that entry has never had either'

Write-Host "Stripping the declaration for the documents that travel outward" -ForegroundColor Cyan
$sigBlock = (Format-EntryBlock -Branch 'feat/t' -Description 'T' -Type 'feat' -Body 'body text' -ImpactRows $sigRows) -join "`n"
$sigStripped = Remove-EntrySignificanceDeclaration -EntryText $sigBlock
Assert-True (-not ($sigStripped -match '$tierH Tier')) 'stripped: every tier section is gone, not just the first'
Assert-True (-not [regex]::IsMatch($sigStripped, '(?m)' + (Get-EntryScorePattern))) 'stripped: and the scores with them -- a self-assigned number at a consumer is a marketing claim'
# THE HEADING GOES WITH THEM, and this assert is inherited rather than invented: leaving it standing was
# measured on the table this shape replaced, shipping a named question with nothing under it into 17
# sections per release card. The sub-sections ARE the section's content, so removing them empties it the
# same way.
Assert-True (-not ($sigStripped -match [regex]::Escape((Get-EntrySectionHeading -Key 'Significance')))) 'stripped: the section heading goes with them, or a consumer reads a question with no answer'
Assert-True ($sigStripped -match [regex]::Escape((Get-EntrySectionHeading -Key 'PullRequest'))) 'stripped: and a section that still has content keeps its heading'
Assert-True ($sigStripped -match 'body text') 'stripped: the entry itself is untouched'
# One call, three shapes: a migrating entry carrying both must come out clean.
$mixed = $sigBlock + "`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | 2 | leftover |`n"
Assert-True (-not ((Remove-EntrySignificanceDeclaration -EntryText $mixed) -match '\| Tier \| Significance \|')) 'stripped: an entry carrying both shapes loses both'

# Fence-aware, like every reader here: this repo's own README quotes the whole shape.
$fencedSig = "$sectH Significance`n`n" + '```text' + "`n$tierH Tier 2`n`nquoted`n`nScore: 5`n" + '```' + "`n`n$tierH Tier 0`n`nreal`n`nScore: 1`n"
$fencedRes = Resolve-EntryImpact -EntryText $fencedSig
Assert-Equal 0 $fencedRes.Tier 'fenced: a tier section QUOTED inside a fence is not a declaration'
Assert-Equal 1 @($fencedRes.Rows).Count 'fenced: only the real section is read'

Write-Host "Get-BranchProgressFindings (the step-list gate's matcher)" -ForegroundColor Cyan
$marks = Get-BranchProgressMarks
Assert-Equal '- [ ] ' $marks.Open    'the open mark is the ordinary unchecked task box'
Assert-Equal '- [x] ' $marks.Done    'the done mark is the ordinary checked one'
Assert-Equal '- [~] ' $marks.Dropped 'and the dropped mark is a third form, not a second meaning for one of the two'

$allResolved = "# Branch progress`n`n## Steps`n`n- [x] built it`n- [~] wire the second reader -- dropped: one reader turned out to be enough`n"
Assert-Equal 0 @(Get-BranchProgressFindings -Text $allResolved).Count 'a list of ticked and dropped steps is finished'

$oneOpen = "# Branch progress`n`n## Steps`n`n- [x] built it`n- [ ] write the tests`n"
$openFindings = @(Get-BranchProgressFindings -Text $oneOpen)
Assert-Equal 1 $openFindings.Count 'one open step is one finding'
Assert-Equal 'still open' $openFindings[0].Label 'and it is reported as open'
Assert-True ($openFindings[0].Line -match 'write the tests') 'the finding carries the step text, so the message says WHICH step'

# THE DROPPED MARK IS THE WHOLE REASON THE GATE IS SAFE TO MAKE UNFORCEABLE. Without it the only way past
# a step that turned out not to be needed is to tick it, which is a gate teaching people to report work
# they did not do.
$dropped = "## Steps`n`n- [~] the second reader -- dropped: one turned out to be enough`n"
Assert-Equal 0 @(Get-BranchProgressFindings -Text $dropped).Count 'a dropped step does not block'

# A TICKED SCAFFOLD IS STILL A FINDING, which is the v3.2.0 shape one level up: the author keeps what the
# scaffolder wrote and marks it done. That reports a plan as finished that was never written.
$tickedStub = "## Steps`n`n- [x] " + (Get-BranchFileWording).FirstStep + "`n"
$stubFindings = @(Get-BranchProgressFindings -Text $tickedStub)
Assert-Equal 1 $stubFindings.Count 'a TICKED scaffold placeholder is still a finding'
Assert-Equal 'still the scaffolded step' $stubFindings[0].Label 'and it is named as the scaffold rather than as an open step'

# ...and an UNticked one is reported once, not twice -- it is open, which is the more actionable of the
# two labels and the one that tells the author what to do.
$freshScaffold = ((Format-Development -Branch 'feat/fresh') -join "`n")

# THE STEP LIST CARRIES THE PLAN AND NOTHING ELSE (Dave, August 7, 2026). Description, ID and type briefly
# sat at the top of BOTH branch files so the pair would say whose it is; they were removed from this one,
# because the same information in two places is free to disagree and here it would be visible on every
# branch. Asserted rather than trusted: the three are still SECTIONS OF THE ENTRY, so a future change that
# reaches for Add-EntrySection here would put them back without anything else noticing.
foreach ($gone in @('Description', 'Id', 'Type')) {
    Assert-True (-not (Test-EntryHasSection -EntryText $freshScaffold -Key $gone)) `
        "the step list carries no '$gone' section -- that fact lives in the entry alone"
}
# What it DOES carry is the identifier every reader of it needs, in the one place a script looks.
Assert-Equal 'feat/fresh' (Get-BranchFileDeclaredBranch -Text $freshScaffold) 'and the heading still names the branch, which is what the fold reads back'

$freshFindings = @(Get-BranchProgressFindings -Text $freshScaffold)
Assert-Equal 1 $freshFindings.Count 'a freshly scaffolded list produces exactly one finding, not one per rule'
Assert-Equal 'still open' $freshFindings[0].Label 'and the open label wins, because that is the actionable one'

# The reset state carries NO steps, so a branch made by hand rather than by new-branch is not refused --
# the one-commit typo fix. Deliberate tolerance, asserted so it cannot be tightened by accident.
Assert-Equal 0 @(Get-BranchProgressFindings -Text ((Format-Development -Branch '') -join "`n")).Count 'the reset state has nothing to resolve -- an absent plan is not a refusal'

# --- The SDLC arc (#655) ------------------------------------------------------------------------------
# THE PHASES ARE DRAWN ON TOP OF THE GATE, NEVER INTO IT. Get-BranchProgressFindings reads step marks, so a
# heading is invisible to it -- which is the entire reason the arc could be added without touching the
# mechanism. Asserted in that order: the headings are there, AND they change no verdict.
Write-Host "the step list follows the SDLC arc (#655)" -ForegroundColor Cyan
$phases = @((Get-BranchFileWording).StepPhases)
# THREE IN THE SEAM, FOUR IN THE DOCUMENT (August 23, 2026). DEPLOY left this list when the entry became
# that phase: it is written by Format-EntryBlock, which owns what goes in it, rather than by the step
# formatter. So the arc is unchanged and the assert follows where each heading is produced.
Assert-Equal 3 $phases.Count 'three step phases are configured -- PLAN, CREATE, TEST'

# THE LEVEL IS READ, NOT TYPED, and that is the repair rather than a style point: these asserts were
# pinned on a literal '###' and went red the moment Dave promoted the file's whole structure by hand
# (August 19, 2026). A test that hardcodes the shape it is measuring reports a deliberate change as a
# defect, which is exactly the noise that gets a suite skipped.
$cycleSec = '#{' + (Get-BranchCycleSectionLevel) + '}'
Assert-True (((Format-Development -Branch 'feat/arc-v1') -join "`n") -match "(?m)^$cycleSec\s+DEPLOY:") 'and the document carries DEPLOY as its fourth, written by the entry formatter'
foreach ($phase in $phases) {
    Assert-True ($freshScaffold -match "(?m)^$cycleSec\s+$([regex]::Escape($phase))\s*$") "the scaffold carries a '$phase' heading"
}
# THE CYCLE FILE IS A DOCUMENT, NOT A BLOCK WAITING TO BE PASTED INTO ONE (Dave, August 19, 2026): its
# title is an H2 and its phases are the H3 sections under it, one level shallower than the entry beside
# it. Asserted as a RELATION as well as two numbers, because the numbers are the part a consumer may
# re-level and the relation is the part that must hold whatever they choose.
#
# BOTH NUMBERS MOVED ONE DOWN ON AUGUST 26, 2026 (Dave), with the entry pair and CONTRIBUTING.md's own
# sections. The relations below did not move, and that is the whole reason they are asserted separately.
Assert-Equal 2 (Get-BranchCycleHeadingLevel) "the cycle file's own heading is an H2 -- it is opened on its own and never travels"
Assert-Equal 3 (Get-BranchCycleSectionLevel) 'and its phases are the H3 sections of that document'
Assert-True ((Get-BranchCycleSectionLevel) -eq ((Get-BranchCycleHeadingLevel) + 1)) 'the sections sit exactly one level under the title'
Assert-True ((Get-BranchCycleHeadingLevel) -lt (Get-EntryHeadingLevel)) 'and the whole file sits shallower than the entry, which has to arrive at CHANGELOG.md its own level'
# THE INVARIANT THE WHOLE SHIFT TURNS ON, and the one assert that would have caught it going wrong. DEPLOY is
# a phase of the cycle file AND the entry that folds into CHANGELOG.md, so the fold is a verbatim paste only
# while those two levels are the same number. Nothing asserted this before August 26, 2026: the two pairs
# happened to line up, and a re-level of either one alone would have silently re-introduced the per-document
# re-levelling that the paste replaced.
Assert-Equal (Get-EntryHeadingLevel) (Get-BranchCycleSectionLevel) 'and the DEPLOY phase sits at exactly the entry level -- what makes the fold a verbatim paste rather than a re-level'

# A DOCUMENT SCAFFOLDED BEFORE THE SHIFT STILL FOLDS, and this is the assert the shift itself depends on
# rather than a courtesy to consumers. The branch that moved these levels was created before it moved them,
# so the fold that runs after its merge meets a cycle document at the OLD pair -- title one shallower, DEPLOY
# one shallower. If the readers had been pinned to the new pair, that fold would have found no DEPLOY heading
# and pasted nothing into CHANGELOG.md, silently. Every consumer holding a branch when the plugin updates
# under them is the same case, in bulk.
$priorPair = @(
    ('#' * ((Get-BranchCycleHeadingLevel) - 1)) + ' Development: `feat/before-the-shift-v1` ' + (Get-EntryIdSeparator) + ' 20260825-120000'
    ''
    ('#' * ((Get-BranchCycleSectionLevel) - 1)) + ' PLAN'
    ''
    ('#' * ((Get-BranchCycleSectionLevel) - 1)) + ' DEPLOY: `feat/before-the-shift-v1`'
    ''
    'What it deploys.'
) -join "`n"
Assert-Equal 'feat/before-the-shift-v1' (Get-BranchFileDeclaredBranch -Text $priorPair) 'a document at the PRE-SHIFT levels still names its branch -- the idempotency and fold-target test'
$priorHalves = Split-Development -Text $priorPair
Assert-True (([string]$priorHalves.Entry) -match 'DEPLOY: `feat/before-the-shift-v1`') 'and its DEPLOY section is still found, so the fold after THIS branch merges has something to paste'
Assert-True ((Get-DevelopmentEntryPattern) -ne '') 'and the pattern that finds it spans both levels rather than pinning one'
# DEPLOY CARRIES NO STEP, and this is the assert that records why (Dave, August 14, 2026; shown as a
# heading since August 19). It is not a step but the RESULT -- the deployment entry beside this file, which
# is the half that travels into CHANGELOG.md at the merge. A DEPLOY checkbox could only be unresolvable,
# since the list must be clear before open-pr will push, or ticked before it happened. So the heading is a
# pointer: if somebody scaffolds a step under it, this goes red.
$deployBlock = if ($freshScaffold -match "(?ms)^$cycleSec\s+DEPLOY\s*`$(.*?)(?=^$cycleSec\s|\z)") { $Matches[1] } else { '' }
Assert-Equal 0 @(Get-BranchProgressFindings -Text $deployBlock).Count 'DEPLOY is scaffolded with no step of its own'

# The placeholder sits under CREATE, not under PLAN: a fresh branch has just been planned, and a TODO under
# PLAN would say the opposite.
$createBlock = if ($freshScaffold -match "(?ms)^$cycleSec\s+CREATE\s*`$(.*?)(?=^$cycleSec\s|\z)") { $Matches[1] } else { '' }
Assert-True ($createBlock -match [regex]::Escape((Get-BranchFileWording).FirstStep)) 'the scaffolded step sits under CREATE'

# An empty phase is a statement, not a finding -- the same tolerance the absent-plan case gets above.
$emptyPhases = "### PLAN`n`n### CREATE`n`n- [x] did the thing`n`n### TEST`n"
Assert-Equal 0 @(Get-BranchProgressFindings -Text $emptyPhases).Count 'a phase with nothing under it is not a finding'

# THE REFERENCE COPY IS THE TRUNK STATE NOW, and it shows the arc but never a step -- an example whose
# first line is somebody else's TODO gets copied in, which is the rule the retired template lived by. A
# BRANCH's document does carry one open step, which is what gives the gate something to refuse; the two
# are asserted against each other rather than separately.
$phaseTemplate = ((Format-Development -Branch '') -join "`n")
Assert-True ($phaseTemplate -match "(?m)^$cycleSec\s+PLAN\s*`$") 'the reference copy carries the arc'
Assert-Equal 0 @(Get-BranchProgressFindings -Text $phaseTemplate).Count 'and still carries no step of its own'
Assert-Equal 1 @(Get-BranchProgressFindings -Text ((Format-Development -Branch 'x/y-v1') -join "`n")).Count 'while the file a branch gets carries exactly one, so the gate has something to refuse'

# Fence-aware, like every reader of this format: this repo's own branch/README.md quotes all three marks
# while teaching them, and a step list may legitimately do the same.
$quoted = "## Steps`n`n- [x] documented the marks`n`n" + '```text' + "`n- [ ] not done yet`n" + '```' + "`n"
Assert-Equal 0 @(Get-BranchProgressFindings -Text $quoted).Count 'an open step QUOTED inside a fence is not an open step'

# --- Get-BranchProgressTally (#960): the counting half of the same question --------------------------
# WHY IT IS ASSERTED AGAINST THE FINDINGS READER RATHER THAN ALONE. Both read the same prepared lines
# through Get-BranchProgressStepLines, and the failure worth catching is not a wrong number but the two
# DISAGREEING -- a gate refusing a step the report never counted, or a report calling a plan finished
# that the gate holds open. So each fixture below is measured both ways.
Write-Host ""
Write-Host "Get-BranchProgressTally (what the park commit's backing note counts)" -ForegroundColor Cyan

$tallyMixed = "## Steps`n`n- [x] built it`n- [~] second reader -- dropped: one was enough`n- [ ] write the tests`n"
$tMixed = Get-BranchProgressTally -Text $tallyMixed
Assert-Equal 1 $tMixed.Open     'one open step is counted open'
Assert-Equal 1 $tMixed.Done     'the ticked step is counted done'
Assert-Equal 1 $tMixed.Dropped  'and the dropped step is counted dropped rather than folded into done'
Assert-Equal 2 $tMixed.Resolved 'Resolved is done + dropped -- the two marks the gate lets through'
Assert-Equal 3 $tMixed.Total    'and Total is all three'
Assert-Equal $tMixed.Open @(Get-BranchProgressFindings -Text $tallyMixed | Where-Object { $_.Label -eq 'still open' }).Count `
    'the tally and the gate agree on how many steps are open'

# THE SHAPE #960 WAS MEASURED ON: every step resolved. Open == 0 with Resolved > 0 is what the note's
# alarm fires on, so it has to be distinguishable from a document with no steps at all.
$tallyFinished = "## Steps`n`n- [x] one`n- [x] two`n"
$tFin = Get-BranchProgressTally -Text $tallyFinished
Assert-Equal 0 $tFin.Open     'a finished list has nothing open'
Assert-Equal 2 $tFin.Resolved 'and two resolved'
Assert-Equal 0 @(Get-BranchProgressFindings -Text $tallyFinished).Count 'which is exactly what the gate lets through'

# AND THE SHAPE IT MUST NOT BE CONFUSED WITH. Total 0 is 'no plan written yet', which reads as finished
# on any test that only asks whether anything is open -- and would have the note announce an alarm about
# a document nobody has filled in.
$tEmpty = Get-BranchProgressTally -Text "### PLAN`n`n### CREATE`n`n### TEST`n"
Assert-Equal 0 $tEmpty.Total    'a document with no steps has Total 0'
Assert-Equal 0 $tEmpty.Resolved 'and nothing resolved -- so a caller can tell it apart from a finished plan'

# THE THREE PREPARATION RULES, ASSERTED ON THE TALLY TOO. They live in Get-BranchProgressStepLines now,
# and the reason to re-assert them here is that this reader is the one whose numbers a person reads: a
# quoted or commented example counted as a step would report a plan as bigger than it is, and a checkbox
# in the entry's prose would report it as unfinished forever.
Assert-Equal 1 (Get-BranchProgressTally -Text $quoted).Total 'a step QUOTED inside a fence is not counted'
$tallyCommented = "## Steps`n`n- [x] real`n`n<!--`n- [ ] an example in the guidance`n-->`n"
Assert-Equal 1 (Get-BranchProgressTally -Text $tallyCommented).Total 'nor is one inside an HTML comment'
$tallyProse = ((Format-Development -Branch 'feat/tally-v1') -join "`n") + "`n`n- [ ] a checkbox in the entry's prose`n"
Assert-Equal (Get-BranchProgressTally -Text ((Format-Development -Branch 'feat/tally-v1') -join "`n")).Total `
    (Get-BranchProgressTally -Text $tallyProse).Total 'and a checkbox BELOW the DEPLOY heading is prose, not a step'

# A TICKED STUB IS A TICK HERE AND A FINDING THERE, and that difference is deliberate rather than a gap:
# the gate refuses a plan that was never written, the note has to be able to DESCRIBE one. Asserted so
# nobody "fixes" the tally into agreeing with the gate and silently loses the shape it exists to report.
$tStub = Get-BranchProgressTally -Text ("## Steps`n`n- [x] " + (Get-BranchFileWording).FirstStep + "`n")
Assert-Equal 1 $tStub.Resolved 'a ticked scaffold placeholder counts as resolved in the tally'
Assert-Equal 1 @(Get-BranchProgressFindings -Text ("## Steps`n`n- [x] " + (Get-BranchFileWording).FirstStep + "`n")).Count `
    'while the gate still refuses it -- both readings are correct for their own caller'

# --- one document, and every older name still read (Dave, August 23, 2026) -------------------------
Write-Host ""
Write-Host "one development document, and the old names are still read" -ForegroundColor Cyan

$bfp = Get-BranchFilePaths
Assert-True ($bfp.File.EndsWith('development.md')) 'the branch document is development.md'
Assert-Equal $bfp.File $bfp.Cycle 'and both halves answer the same path -- the names are kept so a gate can say WHICH half it read'
Assert-Equal $bfp.File $bfp.Deployment 'the entry half too'
Assert-True ($bfp.LegacyCycle.EndsWith('branch-cycle.md')) 'the pre-merge step list is still named'
Assert-True ($bfp.LegacyDeployment.EndsWith('branch-deployment.md')) 'and so is the pre-merge entry'
Assert-True ($bfp.OlderCycle.EndsWith('branch-progress.md')) 'and the name before that'
Assert-True ($bfp.OlderDeployment.EndsWith('branch-changelog.md')) 'and its entry counterpart'
# THE NEAREST PREDECESSOR (#963/#958, August 27, 2026), and the one most likely to be carrying somebody's
# work right now: every branch open on the day of the rename has development-cycle.md and not
# development.md. Asserted on the current folder, because that pair is the one that existed -- there was
# never a workflow-davekjohn/development.md, the folder having been renamed the day before.
Assert-True ($bfp.PriorNameFile.EndsWith('contributing-davekjohn/development-cycle.md')) 'the pre-#963 filename is still named, under the CURRENT folder'
Assert-True ($bfp.PriorFolderFile.EndsWith('workflow-davekjohn/development-cycle.md')) 'and the pre-#886 folder still carries the pre-#963 filename, which is the pair that really existed'
Assert-True (-not (@($bfp.PSObject.Properties.Value) -contains 'workflow-davekjohn/development.md')) 'and the pair that never existed is NOT in the table -- a name to read that nothing can have written'

# THE DUAL-READ IS WHAT KEEPS A BRANCH IN FLIGHT WHOLE, so it is measured on a tree rather than asserted
# about the strings: a repo holding only an old name must resolve to that name, or its entry is invisible
# to the fold and its steps to the gate.
#
# AND EXISTENCE IS NOT THE TEST ANY MORE, which is the case this block had to gain (August 23, 2026). The
# new file lands on the TRUNK in its reset state, so a branch created before the merge has it -- empty --
# beside the pair holding its real work. A resolver keyed on Test-Path would hand that branch the empty
# document and call its entry missing. So the scenario below is the one that would have gone wrong:
# both present, and the OLD one is the one that names this branch.
$resolveFx = Join-Path ([System.IO.Path]::GetTempPath()) "branch-file-resolve-$PID"
if (Test-Path -LiteralPath $resolveFx) { Remove-Item -Recurse -Force -LiteralPath $resolveFx }
New-Item -ItemType Directory -Path (Join-Path $resolveFx ($bfp.Directory -replace '/', '\')) -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $resolveFx 'contributing-davekjohn\branch') -Force | Out-Null
try {
    Assert-Equal $bfp.File (Resolve-BranchFilePath -Kind Cycle -RepoRoot $resolveFx) 'nothing present: the resolver names the CURRENT one, so a writer creates that'
    [System.IO.File]::WriteAllText((Join-Path $resolveFx ($bfp.LegacyCycle -replace '/', '\')), "# ``feat/in-flight`` cycle`n")
    Assert-Equal $bfp.LegacyCycle (Resolve-BranchFilePath -Kind Cycle -RepoRoot $resolveFx) 'only the old name present, and it names a branch: the resolver finds it, so a branch in flight is not stranded'
    [System.IO.File]::WriteAllText((Join-Path $resolveFx ($bfp.File -replace '/', '\')), "# Development: ``main``$([char]0x00B7)`n")
    Assert-Equal $bfp.LegacyCycle (Resolve-BranchFilePath -Kind Cycle -RepoRoot $resolveFx) 'both present and the NEW one is the trunk reset: the old one still wins, because it is the one holding work'
    [System.IO.File]::WriteAllText((Join-Path $resolveFx ($bfp.File -replace '/', '\')), "# Development: ``feat/mine``$([char]0x00B7)`n")
    Assert-Equal $bfp.File (Resolve-BranchFilePath -Kind Cycle -RepoRoot $resolveFx) 'both naming a branch: the current name wins'

    # --- THE PRE-#963 FILENAME, MEASURED ON A TREE (August 27, 2026) --------------------------------
    # This is the case the rename itself had to survive, and the branch that performed it WAS the case:
    # its own document was scaffolded as development-cycle.md before the writer moved, so if this arm is
    # wrong the rename cannot ship -- its entry would be invisible to its own fold.
    Remove-Item -LiteralPath (Join-Path $resolveFx ($bfp.File -replace '/', '\')) -Force
    Remove-Item -LiteralPath (Join-Path $resolveFx ($bfp.LegacyCycle -replace '/', '\')) -Force
    [System.IO.File]::WriteAllText((Join-Path $resolveFx ($bfp.PriorNameFile -replace '/', '\')), "# Development cycle: ``feat/mid-rename``$([char]0x00B7)`n")
    foreach ($kind in @('File', 'Cycle', 'Deployment')) {
        Assert-Equal $bfp.PriorNameFile (Resolve-BranchFilePath -Kind $kind -RepoRoot $resolveFx) `
            "only the pre-#963 name present: -Kind $kind finds it, so a branch open across the rename is not stranded"
    }
    # AND IT LOSES TO A CURRENT FILE THAT CLAIMS THE BRANCH, while beating one that is only a trunk reset --
    # the same precedence the folder rename already had, asserted for this rename rather than assumed.
    [System.IO.File]::WriteAllText((Join-Path $resolveFx ($bfp.File -replace '/', '\')), "# Development: ``main``$([char]0x00B7)`n")
    Assert-Equal $bfp.PriorNameFile (Resolve-BranchFilePath -Kind Cycle -RepoRoot $resolveFx) 'new name present but only a trunk reset: the pre-#963 name still wins, because it holds the work'
    [System.IO.File]::WriteAllText((Join-Path $resolveFx ($bfp.File -replace '/', '\')), "# Development: ``feat/mine``$([char]0x00B7)`n")
    Assert-Equal $bfp.File (Resolve-BranchFilePath -Kind Cycle -RepoRoot $resolveFx) 'both naming a branch: the current name wins over the pre-#963 one too'
    # AND THE OLDER PAIR STILL OUTRANKS NOTHING IT SHOULD: with the branch/ step list back and naming this
    # branch, the CURRENT name keeps winning -- the prior-name row was inserted in front of branch/, not
    # in front of today's file.
    [System.IO.File]::WriteAllText((Join-Path $resolveFx ($bfp.LegacyCycle -replace '/', '\')), "# ``feat/in-flight`` cycle`n")
    Assert-Equal $bfp.File (Resolve-BranchFilePath -Kind Cycle -RepoRoot $resolveFx) 'all three present and all naming a branch: today the writer would create the current name, so it wins'
    Remove-Item -LiteralPath (Join-Path $resolveFx ($bfp.PriorNameFile -replace '/', '\')) -Force
    Assert-Equal $bfp.File (Resolve-BranchFilePath -Kind Cycle -RepoRoot $resolveFx) 'and removing the pre-#963 file changes nothing while today s file claims the branch'

    # --- -Reader: the same rule, against a tree the caller is not standing in (issue #970) ----------
    #
    # WHY THIS ARM EXISTS. ship-pr's gates before the merge must judge the document belonging to the PR
    # they are shipping, which is the branch's own COMMIT -- the run waits on CI, and a session that
    # backgrounds the ship and starts the next piece of work has moved the checkout by the time they look.
    # Reading the text out of that commit is not enough on its own: the choice between the candidate names
    # is made by READING each one, so the resolver has to answer for the same tree the reader does.
    #
    # THE FIXTURE ON DISK IS DELIBERATELY LEFT AS IT IS, and it is the assert. Its state right now is
    # "both files present, both naming a branch" -- the case that resolves to the CURRENT name one line
    # above. The reader below describes a different tree, in which only the OLD name exists, so the two
    # arms must disagree. Agreeing would mean the reader was being ignored.
    $readerTree = @{ $bfp.LegacyCycle = "# ``feat/in-flight-elsewhere`` cycle`n" }
    $readerCalls = @{}
    $treeReader = {
        param([string]$Rel)
        if (-not $readerCalls.ContainsKey($Rel)) { $readerCalls[$Rel] = 0 }
        $readerCalls[$Rel]++
        if ($readerTree.ContainsKey($Rel)) { return [string]$readerTree[$Rel] }
        return $null
    }
    Assert-Equal $bfp.LegacyCycle (Resolve-BranchFilePath -Kind Cycle -Reader $treeReader) 'the reader answers for ITS tree, not for the directory the caller is standing in'
    Assert-Equal $bfp.File (Resolve-BranchFilePath -Kind Cycle -RepoRoot $resolveFx) 'and the tree arm is unchanged beside it -- the two genuinely disagree'

    # ONE READ PER CANDIDATE. Both loops ask the same question, and on this arm one question is a child
    # process rather than a Test-Path -- so the memo is what keeps a resolve from spawning git twice per
    # name. Asserted on the name that the first loop rejects and the second loop reconsiders.
    $readerTree = @{ $bfp.File = "# Development: ``main```n" }
    $readerCalls = @{}
    Assert-Equal $bfp.File (Resolve-BranchFilePath -Kind Cycle -Reader $treeReader) 'nothing in that tree CLAIMS the branch: the resolver falls back to a name that at least exists'
    Assert-Equal 1 $readerCalls[$bfp.File] 'and it read that candidate once, though both loops asked for it'

    # $null MEANS ABSENT; EMPTY MEANS PRESENT AND DECLARING NOTHING. Both are falsy, and conflating them
    # is the silent-skip direction: a gate handed "absent" for a document that is there says nothing at all.
    $readerTree = @{ $bfp.File = '' }
    $readerCalls = @{}
    Assert-Equal $bfp.File (Resolve-BranchFilePath -Kind Cycle -Reader $treeReader) 'an EMPTY document exists, so the resolver names it rather than falling through to the writer default'

    # The two arms are mutually exclusive by parameter set, so a caller cannot pass a reader AND a root
    # and be left guessing which one answered.
    $bothArms = $false
    try { Resolve-BranchFilePath -Kind Cycle -RepoRoot $resolveFx -Reader $treeReader | Out-Null }
    catch { $bothArms = $true }
    Assert-True $bothArms '-RepoRoot and -Reader together are refused rather than silently resolved'
} finally {
    Remove-Item -Recurse -Force -LiteralPath $resolveFx -ErrorAction SilentlyContinue
}

# THE TWO STAMPS SIT AT THE TWO ENDS OF THE BRANCH'S LIFE. The creation stamp is the cycle file's, written
# by the scaffolder; the landing stamp is the entry's, written by the fold. Neither may appear in the
# other's document -- that is the whole reason the ID moved out of the entry heading.
$stampedCycle = ((Format-Development -Branch 'feat/x-v1' -Id '20260819-171500') -join "`n")
Assert-True ((($stampedCycle -split "`n")[0]) -match ('^#{' + (Get-BranchCycleHeadingLevel) + '} Development: `feat/x-v1` ' + [regex]::Escape((Get-EntryIdSeparator)) + ' 20260819-171500$')) 'the document heading carries its title, the branch and the creation stamp'
$bareEntry = ((Format-EntryBlock -Branch 'feat/x-v1' -Description 'A title' -Type 'Enhancement') -join "`n")
Assert-True (-not ($bareEntry -match '\d{8}-\d{6}')) 'and a freshly scaffolded entry carries no stamp anywhere -- the fold has not run'

# THE REFERENCE COPY SHOWS BOTH STAMPS AS PLACEHOLDERS, which is what separates it from a branch's file now
# that the guidance is unconditional: it is the only difference left, and it is the honest one -- neither
# moment exists for the trunk.
$templateCycle = ((Format-Development -Branch '') -join "`n")
Assert-True ($templateCycle.Contains((Get-EntryIdTemplatePlaceholder))) 'the reference copy shows the creation stamp as a placeholder'
Assert-True ($templateCycle.Contains((Get-EntryMergeStampTemplatePlaceholder))) 'and the landing stamp as one'

# THE RESTAMP, WHICH IS THE HALF A READER CAN BREAK. A stamped section heading is still the section: if
# any of the six matchers had kept its bare '\s*$', the entry would report the section as ABSENT -- read
# by the gates as "not answered yet" and by the fold as nothing to fill.
$stamped = Set-EntryMergeStamp -EntryText $bareEntry -Stamp '20260819-171500'
Assert-True ($stamped -match ('(?m)^' + ('#' * (Get-EntryHeadingLevel)) + ' DEPLOY: `feat/x-v1` ' + [regex]::Escape((Get-EntryIdSeparator)) + ' 20260819-171500$')) 'the fold stamps the landing moment onto the entry''s own heading'
Assert-True (-not ($stamped -match '(?m)^### Pull Request .+\d{8}-\d{6}')) 'and not onto the Pull Request heading, where it sat for four days'
# Get-EntrySectionAnswer, not -Body: the guidance comment is unconditional since August 23, 2026, so the
# RAW body opens with the form. The answer reader strips it, which is what open-pr composes the PR title
# from -- asserted here because that is the reader whose mistake would ship an HTML comment as a PR title.
Assert-Equal 'A title' (Get-EntrySectionAnswer -EntryText $stamped -Key 'PullRequest') 'and the section is still found under its stamped heading'
Assert-Equal 'A title' (Get-EntryPrTitle -EntryText $stamped) 'and the PR title reads past the guidance rather than out of it'
Assert-True (Test-EntryHasSection -EntryText $stamped -Key 'PullRequest') 'and still counts as present, so the emptiness gate does not accuse it'
Assert-True (Test-EntryDeclaresShape -EntryText $stamped) 'and the entry still declares its shape'

# Restamped rather than appended to, so folding twice cannot grow a line of timestamps -- and a heading
# still carrying the TEMPLATE's placeholder comes out with a real stamp.
$twice = Set-EntryMergeStamp -EntryText $stamped -Stamp '20260820-090000'
Assert-True ($twice -match ('(?m)^' + ('#' * (Get-EntryHeadingLevel)) + ' DEPLOY: .+ 20260820-090000$')) 'a second fold restamps'
Assert-True (-not ($twice -match '20260819-171500')) 'and does not leave the first stamp behind'
Assert-Equal $bareEntry (Set-EntryMergeStamp -EntryText $bareEntry -Stamp '') 'an empty stamp changes nothing -- a fold with no PR leaves the heading bare'

# AND THE SHAPE WITH NO SECTION AT ALL, which is the discriminator the fold reads before it decides where
# to put the date. A pre-dossier entry carried its title AS its heading; the stamp has nowhere to go, and
# the failure is silent rather than loud -- the text simply comes back unchanged. So the predicate is
# asserted beside the no-op, because the fold's correctness rests on the pair and not on either alone.
$preDossier = "### A title $md Feat $md 2026-08-05`n`nTier: 0`n`nSome body text.`n"
Assert-True (-not (Test-EntryHasSection -EntryText $preDossier -Key 'PullRequest')) 'a pre-dossier entry has no Pull Request section, so the fold knows the heading cannot hold the date'
# AND SINCE AUGUST 26, 2026 THE STAMP LANDS ON ITS HEADING RATHER THAN NOWHERE, because that shape's level
# and today's entry level are now the same number. The pre-dossier entry was an H3 while an entry was an H2;
# both pairs then moved one down, so H3 is what an entry IS. There is no way to tell the two apart by depth
# any more -- recorded here rather than worked around, because the alternative would be a reader guessing at
# an era.
#
# IT COSTS NOTHING IN PRACTICE, and that is why it is accepted rather than repaired. Set-EntryMergeStamp is
# only ever called by the fold, on the entry it is folding, which is a freshly written current-shape entry.
# No caller hands it a historical one. What the assert protects is the shape of the output -- a stamp on the
# entry's own heading, not a second one appended somewhere else.
$preStamped = Set-EntryMergeStamp -EntryText $preDossier -Stamp '20260819-171500'
Assert-True ($preStamped -match ('(?m)^' + ('#' * (Get-EntryHeadingLevel)) + ' A title .* 20260819-171500$')) 'and a shape sharing the entry level is stamped on its own heading -- the two are no longer distinguishable by depth'
Assert-Equal 1 (@([regex]::Matches($preStamped, '20260819-171500')).Count) 'once, not twice -- the stamp replaces rather than accumulates'

# THE ENTRIES ALREADY WRITTEN SAY 'changelog' IN THEIR HEADING, and every one of them is in CHANGELOG.md
# right now. The type is read off that word, and Test-EntryDeclaresShape ends on the type -- so a reader
# that knew only 'deployment' would make the whole existing changelog stop being entries.
$oldWorded = "## Branch ``feat/x`` changelog`n`n### What does the change on this branch deploy to main?`n`nA reason`n`n**Score:** 2`n"
$oldWordedType = Resolve-EntryType -EntryText $oldWorded
Assert-True $oldWordedType.Declared 'an entry headed `changelog` still declares a type off its branch prefix'
Assert-True (Test-EntryDeclaresShape -EntryText $oldWorded) 'and therefore still reads as an entry'
Assert-True ((Get-BranchFileRetiredChangelogTitles) -contains 'changelog') 'and the retired title word is registered'
$oldProgress = "## ``feat/x`` progress`n`n### PLAN`n`n- [x] done`n"
Assert-True (-not (Test-EntryDeclaresShape -EntryText $oldProgress)) 'while a step list headed `progress` is still not an entry'

# --- 'Branch description' -> 'Branch title' (#506) -------------------------------------------------
# The rename itself is one line; what needs asserting is that the old name keeps working and that adding
# it to the retired map did not quietly change the two readers that consume that map WHOLESALE.
Write-Host ""
Write-Host "the title section: renamed, and the old name still read" -ForegroundColor Cyan

Assert-Equal 'Branch title' ((Get-EntrySectionHeadings)['Description']) 'the section is written as Branch title'
Assert-True ((Get-EntrySectionRetiredNames -Key 'Description') -contains 'Branch description') 'and the retired name is registered against its own section'

# The entries in CHANGELOG.md and in every consumer's tree carry the old heading right now. A reader that
# knew only the new one would find no title on any of them -- silent, and wrong in the direction that
# empties a consumer document.
$oldNamed = "## ``feat/x`` changelog`n`n### Branch description`n`nThe old name still reads`n"
Assert-Equal 'The old name still reads' (Get-EntrySectionAnswer -EntryText $oldNamed -Key 'Description') 'an entry under the retired heading still yields its title'
Assert-True (Test-EntryHasSection -EntryText $oldNamed -Key 'Description') 'and it counts as HAVING the section, so the emptiness gate does not accuse it'

# THE REGRESSION THIS RENAME NEARLY INTRODUCED, asserted so it cannot come back. Test-EntryDeclaresShape
# separates an entry from a step list, and it used to accept EVERY retired heading as proof of "entry" --
# sound while every retired name belonged to a section no step list carried. 'Branch description' broke
# that: the step lists of early August carry it, on every branch in flight and in every consumer. A
# blanket retired list would read those as entries again, which is the exact confusion the two-file split
# was made to remove.
$oldStepList = "## ``feat/x`` progress`n`n### Branch description`n`nA title`n`n### Steps`n`n- [x] done`n"
Assert-True (-not (Test-EntryDeclaresShape -EntryText $oldStepList)) 'a step list carrying the retired title heading is still NOT an entry'

# AND THE TITLE SECTION STILL PROVES NOTHING BY ITSELF -- but the HEADING above it now does, since
# August 16, 2026. A branch heading that says 'changelog' is an entry, which is the fact the type reader
# takes the change type off; the step list one word away says 'progress' and is refused, which is the
# assert directly above. So this fixture is an entry for a reason its title section had nothing to do with.
Assert-True (Test-EntryDeclaresShape -EntryText $oldNamed) 'a changelog branch heading declares an entry, whatever sections follow it'
# THE FAILURE THIS WHOLE PREDICATE EXISTS FOR, asserted so widening the heading rule cannot quietly undo
# it: a leftover section heading from the pre-flat CHANGELOG must never read as a change. Measured on two
# real consumer shapes -- one of them swallowed an entire release history into the release notes and then
# deleted it from CHANGELOG.md, silently, because nothing refused.
Assert-True (-not (Test-EntryDeclaresShape -EntryText "## Pull Requests`n`nSome prose.`n")) 'a pre-flat section heading is still not an entry'
Assert-True (-not (Test-EntryDeclaresShape -EntryText "## Releases`n`nSome prose.`n")) 'and neither is the release-history heading'
$oldNamedFull = $oldNamed + "`n### Pull Request`n`n#12`n"
Assert-True (Test-EntryDeclaresShape -EntryText $oldNamedFull) 'while an entry-only section still proves an entry'

# And the pre-dossier entry stays recognised, which is what the dropped 'Type of change' would have been
# doing here: it is caught by its own entry-only sections instead, so nothing is lost by the narrowing.
$preDossier = "### Old entry - Feat - 2026-07-01`n`n### What does this change do?`n`nsomething`n"
Assert-True (Test-EntryDeclaresShape -EntryText $preDossier) 'a pre-dossier entry is still recognised by its retired entry-only heading'

# --- The trunk warning's opening sentence is seamable too (inbound #562) ---------------------------
# THE MEASURED DEFECT. Get-BranchFileWordingOverrides made the branch files translatable, and this one
# fragment was built inline by the formatter -- so a consumer who translated everything got a Dutch
# document whose FIRST sentence was English: '> **You are on `main`.** Schrijf hier nog niet -- ...'.
# Their only way out was forking new-branch.ps1, the duplication #410 had just removed.
Write-Host ""
Write-Host "the trunk warning: its lead is wording, not formatter output" -ForegroundColor Cyan
$defaultReset = (Format-Development -Branch '') -join "`n"
Assert-True ($defaultReset -match '(?m)^> \*\*You are on `main`\.\*\* Do not work in this file yet') 'default: the lead is unchanged, on one line with the first warning line'

# The override, injected the way the seam is reached in a real repo: repo-config.ps1 defines the function
# and Get-BranchFileWording probes for it with Get-Command. Both keys at once, because the point is that the
# whole sentence is now one repo's language rather than two halves owned by two parties.
function Get-BranchFileWordingOverrides {
    return @{
        TrunkWarningLead = 'LET OP: je zit op `{0}`.'
        TrunkWarning     = @('Schrijf hier nog niet -- maak eerst een branch.', 'De tweede regel.')
    }
}
$dutchReset = (Format-Development -Branch '') -join "`n"
Assert-True ($dutchReset -match '(?m)^> LET OP: je zit op `main`\. Schrijf hier nog niet') 'override: the lead is the consumer''s sentence, with the trunk name in the position THEY chose'
# SCOPED TO THE WARNING BLOCK, and the first version of this assert was not -- it read the whole document
# for 'You are on' and went red on the reset prose ('the changelog entry of the branch you are on'), which
# this override never touched. An assert has to look at the thing it is about; a document-wide search for a
# fragment of English cannot tell the sentence under test from the one beside it.
$dutchWarning = (@($dutchReset -split "`n") | Where-Object { $_ -like '> *' }) -join "`n"
Assert-True ($dutchWarning -notmatch 'You are on') 'override: no English survives in the WARNING -- which is the whole finding'
Assert-True ($dutchReset -match '(?m)^> De tweede regel\.$') 'override: the lines below the lead still come from TrunkWarning, unchanged'
Remove-Item -Path Function:\Get-BranchFileWordingOverrides

# A LEAD CONTAINING A LITERAL BRACE MUST NOT THROW, and that is why the trunk name is substituted by a
# string replace instead of -f / [string]::Format. A seam value is hand-written; '{' is an ordinary
# character in prose, and a format string would fail at scaffold time on somebody's translation.
function Get-BranchFileWordingOverrides { return @{ TrunkWarningLead = 'Pas op {let op} op `{0}`:' } }
$braceReset = ''
$threw = $false
try { $braceReset = (Format-Development -Branch '') -join "`n" } catch { $threw = $true }
Assert-Equal $false $threw 'brace: a lead carrying a literal brace does not throw'
Assert-True ($braceReset -match [regex]::Escape('Pas op {let op} op `main`:')) 'brace: the brace is passed through verbatim and the placeholder still resolves'
Remove-Item -Path Function:\Get-BranchFileWordingOverrides

# AN EMPTY OVERRIDE KEEPS THE DEFAULT, which is this seam's documented fail-safe for every key and not a
# special case for this one: a blank heading or a blank warning would produce a document with a gap where a
# sentence belongs, and nothing would report it. Asserted here because the first draft of this change claimed
# the opposite -- that an empty lead was a legitimate way to drop the sentence -- and this assert is what
# established it is not. The formatter's own guard against a dangling '> ' is therefore unreachable through
# the seam and stays as a guard on the DEFAULT being non-empty, which is worth having either way.
function Get-BranchFileWordingOverrides { return @{ TrunkWarningLead = '' } }
$noLead = (Format-Development -Branch '') -join "`n"
Assert-Equal $defaultReset $noLead 'empty lead: an empty override is ignored -- the default sentence stands, as for every other key'
Remove-Item -Path Function:\Get-BranchFileWordingOverrides
# The default is back, so nothing below inherits an override. Asserted rather than assumed: a leaked
# override would make every later assert read a document no repo produces.
Assert-Equal $defaultReset ((Format-Development -Branch '') -join "`n") 'teardown: the default reset is restored once the seam function is gone'

# --- A BLANK-ONLY LIST OVERRIDE IS EMPTY TOO (#927) -----------------------------------------------
# THE MEASURED DEFECT, and it is the fail-safe above asking the wrong question rather than a rule that was
# missing. An empty array is falsy, so a consumer who EMPTIES StepPhases keeps the three defaults -- which
# is why the state #927 reported, 'a consumer who empties the seam', turns out not to be reachable through
# the seam at all. A list of BLANKS is: two empty strings make a two-element array, which is TRUTHY, so it
# was honoured here and emptied AFTERWARDS, downstream, where every reader of a list filters blanks out.
# Format-Development was then left with no phase heading to write the scaffolded step under, wrote it
# bare, and that lands it in the preamble region check-branch-entry.ps1's #899 check refuses -- so such a
# repo's EVERY branch was blocked, with no way through but deleting the step the scaffolder wrote.
Write-Host ""
Write-Host "a blank-only list override is empty too (#927)" -ForegroundColor Cyan
$defaultArc = @((Get-BranchFileWording).StepPhases)
function Get-BranchFileWordingOverrides { return @{ StepPhases = @('', '') } }
$blankArc = @((Get-BranchFileWording).StepPhases | Where-Object { $_ })
Assert-Equal ($defaultArc -join '|') ($blankArc -join '|') 'blank-only StepPhases: ignored, so the default arc stands -- as an empty one already was'
# AND THE DOCUMENT IS THE ASSERT THAT MATTERS, because the seam is only the first of the two halves. #899
# reads the SHAPE, so this reads the shape too: nothing but guidance above the first phase heading. Written
# with -Intent, since a parked branch is where a dropped note would cost the most.
$blankDoc = (Format-Development -Branch 'feat/blank-arc-v1' -Intent 'parked mid-flight.') -join "`n"
Remove-Item -Path Function:\Get-BranchFileWordingOverrides
$arcTitleRx = '^#{1,' + (Get-BranchCycleHeadingLevel) + '}\s'
$arcPhaseRx = '^#{' + (Get-BranchCycleSectionLevel) + '}\s+\S'
$arcFence   = $false
$arcSeen    = $false
$arcStrays  = 0
foreach ($arcLine in @($blankDoc -split "`n")) {
    if ($arcLine -match '^\s{0,3}(?:`{3,}|~{3,})') { $arcFence = -not $arcFence; continue }
    if ($arcFence) { continue }
    if ($arcLine -match $arcPhaseRx) { $arcSeen = $true; continue }
    if ($arcLine -match $arcTitleRx) { continue }
    if ((-not $arcSeen) -and $arcLine.Trim() -ne '' -and $arcLine -notmatch '^\s*>') { $arcStrays++ }
}
Assert-Equal 0 $arcStrays 'and nothing but guidance stands above the first phase heading -- the shape #899 reads'
Assert-True ($blankDoc.Contains((Get-BranchProgressMarks).Open)) 'the scaffolded step is still written, under a phase rather than dropped'
Assert-True ($blankDoc.Contains('parked mid-flight.')) 'and so is the parking intent, which is the one thing in this file nobody can reconstruct'
# THE FALLBACK TAKES THE STEP'S PHASE WITH IT, and this is the assert for the hole that a half-fallback
# would open: an arc from the defaults with FirstStepPhase still on a consumer's own name matches nothing,
# and the step disappears without a word. A silent document is worse than a refused one.
function Get-BranchFileWordingOverrides { return @{ StepPhases = @('', ''); FirstStepPhase = 'BOUWEN' } }
$orphanDoc = (Format-Development -Branch 'feat/orphan-step-v1') -join "`n"
Remove-Item -Path Function:\Get-BranchFileWordingOverrides
Assert-True ($orphanDoc.Contains((Get-BranchProgressMarks).Open)) 'a FirstStepPhase naming no surviving phase still gets its step, under the default the arc fell back to'
# THE SAME HOLE WITHOUT #927 ANYWHERE NEAR IT, which is what makes it a defect of its own rather than a
# consequence: the arc is the untouched default and only this key is wrong. Before the membership anchor the
# step was dropped here too, and nothing said so.
function Get-BranchFileWordingOverrides { return @{ FirstStepPhase = 'CRAETE' } }
$typoDoc = (Format-Development -Branch 'feat/typo-phase-v1') -join "`n"
Remove-Item -Path Function:\Get-BranchFileWordingOverrides
Assert-True ($typoDoc.Contains((Get-BranchProgressMarks).Open)) 'a mistyped FirstStepPhase against the default arc still gets its step'
# A REAL OVERRIDE IS UNTOUCHED BY ALL OF THIS, which is the seam's whole purpose and the thing a fail-safe
# is most likely to break on its way past.
function Get-BranchFileWordingOverrides { return @{ StepPhases = @('ONTWERP', 'BOUW', 'TEST'); FirstStepPhase = 'BOUW' } }
$dutchArc = (Format-Development -Branch 'feat/dutch-arc-v1') -join "`n"
Remove-Item -Path Function:\Get-BranchFileWordingOverrides
foreach ($dutchPhase in @('ONTWERP', 'BOUW', 'TEST')) {
    Assert-True ($dutchArc -match "(?m)^#{$(Get-BranchCycleSectionLevel)}\s+$dutchPhase\s*$") "a renamed arc still writes its own '$dutchPhase' heading"
}
Assert-True ($dutchArc -notmatch '(?m)^#+\s+PLAN\s*$') 'and none of the English defaults leaks in beside them'
Assert-Equal $defaultReset ((Format-Development -Branch '') -join "`n") 'teardown: the default reset is restored once the seam functions are gone'

# --- ONE MERGE LOOP, NOT TWO (#941) ---------------------------------------------------------------
# WHAT WAS PROMOTED AND WHY. Get-EntrySignificanceWording and Get-BranchFileWording each merged a
# consumer's override map over a defaults map, and the loop was the same code line for line -- the
# container split, the PS 5.1 string-indexing note, and both fail-safes. The cost was measured rather
# than predicted: #927 above is a hole in the second fail-safe, and repairing it meant writing the
# identical guard into BOTH loops. Noticing the second one at all was luck, because the report named
# StepPhases while Route0 and Route1 are list-valued for exactly the same reason.
#
# SO THE ASSERTS BELOW RUN THE SAME THREE RULES DOWN BOTH SEAMS. That is the point of the block: a
# rule stated once has to be provably reachable from both callers, otherwise the promotion has only
# moved the duplication into the tests.
Write-Host ""
Write-Host "one merge loop, not two (#941)" -ForegroundColor Cyan

# The container walk on its own, which is the half all THREE getters share. A hashtable is what a
# consumer reaches for, an ordered dictionary is what copying a defaults block produces, and a
# pscustomobject is what a repo returning a literal object hands back.
Assert-Equal 'x' (Get-OverrideMapValue -Map @{ K = 'x' } -Key 'K')                  'map walk: a hashtable answers for a key it carries'
Assert-Equal $null (Get-OverrideMapValue -Map @{ K = 'x' } -Key 'Other')            'map walk: and $null for one it does not'
Assert-Equal 'x' (Get-OverrideMapValue -Map ([ordered]@{ K = 'x' }) -Key 'K')       'map walk: an ordered dictionary answers the same way'
# THE PS 5.1 PITFALL, ASSERTED RATHER THAN DESCRIBED. $o['Key'] on a pscustomobject returns $null
# SILENTLY, so a walk that indexed by string would read as "override absent" for every key such a
# consumer set -- their whole seam ignored, with nothing reporting it.
Assert-Equal 'x' (Get-OverrideMapValue -Map ([pscustomobject]@{ K = 'x' }) -Key 'K') 'map walk: a pscustomobject is read through PSObject, not by string index'
Assert-Equal $null (Get-OverrideMapValue -Map $null -Key 'K')                        'map walk: no map at all is not an error, it is simply no answer'
Assert-Equal $null (Get-OverrideMapValue -Map @{ K = $null } -Key 'K')               'map walk: present-but-null and absent are the same answer'

# RULE 1, DOWN BOTH SEAMS: a key present but EMPTY keeps the default.
$sigDefaults = Get-EntrySignificanceWording
function Get-EntrySignificanceWordingOverrides { return @{ Uncomment1 = '' } }
Assert-Equal $sigDefaults.Uncomment1 (Get-EntrySignificanceWording).Uncomment1 'significance seam: an empty override is ignored -- the same fail-safe the branch-file seam has'
Remove-Item -Path Function:\Get-EntrySignificanceWordingOverrides

# RULE 2, DOWN BOTH SEAMS: a LIST that leaves nothing usable behind keeps the default. Asserted on
# the significance side because that is the side nobody had measured -- #927 was reported against
# StepPhases, and Route0 was one key over with the identical shape.
function Get-EntrySignificanceWordingOverrides { return @{ Route0 = @('', '') } }
Assert-Equal (@($sigDefaults.Route0) -join '|') (@((Get-EntrySignificanceWording).Route0) -join '|') 'significance seam: a blank-only Route0 is ignored too -- the #927 rule, reached from the other caller'
Remove-Item -Path Function:\Get-EntrySignificanceWordingOverrides

# RULE 3, DOWN BOTH SEAMS: the pscustomobject shape is honoured, not silently dropped.
function Get-EntrySignificanceWordingOverrides { return [pscustomobject]@{ Uncomment1 = 'HUN EIGEN ZIN' } }
Assert-Equal 'HUN EIGEN ZIN' (Get-EntrySignificanceWording).Uncomment1 'significance seam: a pscustomobject override is honoured'
Remove-Item -Path Function:\Get-EntrySignificanceWordingOverrides
function Get-BranchFileWordingOverrides { return [pscustomobject]@{ TrunkWarningLead = 'PAS OP op `{0}`:' } }
$objLead = (Format-Development -Branch '') -join "`n"
Remove-Item -Path Function:\Get-BranchFileWordingOverrides
Assert-True ($objLead -match '(?m)^> PAS OP op `main`:') 'branch-file seam: and so is one on the other side of the same helper'

# AND A REAL OVERRIDE STILL WINS ON BOTH, which is the seam's purpose and the thing a shared fail-safe
# is most likely to break on its way past.
function Get-EntrySignificanceWordingOverrides { return @{ Route0 = @('Verder naar Tier 1?') } }
Assert-Equal 'Verder naar Tier 1?' (@((Get-EntrySignificanceWording).Route0) -join '|') 'significance seam: a real list override is untouched by either fail-safe'
# AND IT IS STILL A LIST, which is the other half of the trap the helper's comma-wrap exists for: a
# function returning a ONE-ELEMENT array unrolls it to the bare element, so this key would come back a
# string while every other consumer's two-element one came back an array. The two inline loops read the
# value directly and could not meet that; promoting them into a function is what created the risk.
Assert-True ((Get-EntrySignificanceWording).Route0 -is [Array]) 'significance seam: and a one-element list override is still a LIST, not the bare string'
Remove-Item -Path Function:\Get-EntrySignificanceWordingOverrides
Assert-Equal ($sigDefaults.Route0 -join '|') ((Get-EntrySignificanceWording).Route0 -join '|') 'teardown: the significance defaults are back once the seam function is gone'

# THE THIRD GETTER IS NOT THE SAME RULE, AND THAT IS THE POINT OF SPLITTING THE HELPER IN TWO.
# Get-EntryGuidance reads its map the same way and then answers differently: an empty block means
# "this repo wants no guidance", which is a documented answer rather than a missing one. Folding the
# wording fail-safe into it would have made that answer UNREACHABLE -- a consumer switching guidance
# off would silently get the English defaults back. Recounted while promoting the loop the issue
# named: the container walk is shared by three callers, the verdict by two.
$guidanceDefaults = Get-EntryGuidance
function Get-EntryGuidanceOverrides { return @{ What = @() } }
Assert-Equal 0 (@((Get-EntryGuidance).What).Count) 'guidance seam: an EMPTY block is honoured -- the opposite verdict, on purpose'
Assert-True ((@((Get-EntryGuidance).Type) -join '|') -eq (@($guidanceDefaults.Type) -join '|')) 'guidance seam: and a key the consumer did not mention keeps its default'
Remove-Item -Path Function:\Get-EntryGuidanceOverrides
Assert-Equal (@($guidanceDefaults.What) -join '|') (@((Get-EntryGuidance).What) -join '|') 'teardown: the guidance defaults are back once the seam function is gone'

Write-Host ""
Write-Host "Remove-EntryAdminSections" -ForegroundColor Cyan
# THE DEFECT THESE GUARD is not a missing stripper but a stripper aimed one level up: the heading rewrite
# dropped the PR number, type and date while they lived in the heading, and the dossier format moved them
# into '###' sections in August 2026 without the stripping following. Measured on the v4.2.0 consumer draft
# before the repair: 125 of 396 rendered lines were these four sections, with 'Branch title' printed
# directly under the heading it had just become.
$adminEntry = @(
    '## `fix/x` changelog'
    ''
    '### Branch title'
    ''
    'A readable name'
    ''
    '### Branch ID'
    ''
    '20260810-212615'
    ''
    '### Branch type'
    ''
    'fix'
    ''
    '### What does the change on this branch bring to main?'
    ''
    'The substance, which a consumer is here for.'
    ''
    '### Pull Request'
    ''
    'Plugins: contributing-davekjohn'
    ''
    '[PR #1](https://example.test/1) - merged 2026-08-10'
) -join "`n"

$stripped = Remove-EntryAdminSections -EntryText $adminEntry
Assert-True ($stripped -notmatch '(?m)^### Branch title')  'the title section goes -- by this point it IS the heading'
Assert-True ($stripped -notmatch '(?m)^### Branch ID')     'the creation timestamp goes'
Assert-True ($stripped -notmatch '(?m)^### Branch type')   'the branch prefix goes'
Assert-True ($stripped -notmatch '(?m)^### Pull Request')  'the PR section goes -- this reader has no PR numbers'
Assert-True ($stripped -notmatch 'PR #1')                  'and its BODY goes with it, not just the heading'
Assert-True ($stripped -notmatch '20260810-212615')        'the timestamp body goes too'
Assert-True ($stripped -match '(?m)^## `fix/x` changelog') "the entry's OWN heading is left standing -- a different function's job"
Assert-True ($stripped -match 'What does the change')      'the substance section survives'
Assert-True ($stripped -match 'The substance, which a consumer is here for\.') 'and so does its body'

# RETIRED NAMES ARE REMOVED, and a miss here is worse than a reader missing one: a reader returns nothing
# and its caller usually notices, while a remover leaves the section standing in the one document that
# travels outward. CHANGELOG.md and every consumer tree hold both names right now.
$retiredEntry = @(
    '## `fix/y` changelog'
    ''
    '### Branch description'
    ''
    'An older name for the title'
    ''
    '### Type of change'
    ''
    'fix'
    ''
    '### What does this change do?'
    ''
    'Still the substance.'
) -join "`n"
$strippedRetired = Remove-EntryAdminSections -EntryText $retiredEntry
Assert-True ($strippedRetired -notmatch 'Branch description')      'the retired title heading is removed too'
Assert-True ($strippedRetired -notmatch '(?m)^### Type of change') 'and the retired type heading'
Assert-True ($strippedRetired -match 'Still the substance\.')      "while the retired What section's body survives"

# FENCE-AWARE, and this function needs it more than most: the entry introducing it quotes these very
# headings to show what is dropped. A non-fence-aware remover would eat the illustration out of the entry
# that documents the mechanism -- and then out of every later entry that cites it.
$fencedEntry = @(
    '## `docs/z` changelog'
    ''
    '### What does the change on this branch bring to main?'
    ''
    'The four sections dropped are:'
    ''
    '```text'
    '### Branch title'
    '### Branch ID'
    '```'
    ''
    'That is the whole list.'
) -join "`n"
$strippedFenced = Remove-EntryAdminSections -EntryText $fencedEntry
Assert-True ($strippedFenced -match '(?m)^### Branch title') 'a heading QUOTED inside a fence is left alone'
Assert-True ($strippedFenced -match '(?m)^### Branch ID')    'both of them'
Assert-True ($strippedFenced -match 'That is the whole list\.') 'and the prose after the fence is not swallowed'

$noAdmin = "## `fix/w` changelog`n`n### What does the change on this branch bring to main?`n`nJust substance."
Assert-Equal $noAdmin (Remove-EntryAdminSections -EntryText $noAdmin) 'an entry carrying none of them is returned untouched'
Assert-Equal '' (Remove-EntryAdminSections -EntryText '') 'and an empty entry is not a special case'

# THE KEY LIST IS THE DECISION POINT. A seventh section added to the format defaults to being PUBLISHED,
# which is the safe direction -- but these two asserts are what make that a choice somebody made rather
# than a list nobody looked at.
$adminKeys = @(Get-EntryAdminSectionKeys)
Assert-Equal 4 $adminKeys.Count 'four sections are administration, not five'
Assert-True ($adminKeys -notcontains 'What') "'What' is the substance and is never dropped"
Assert-True ($adminKeys -notcontains 'Significance') 'Significance has its own remover -- a score is a different objection from administration'

# --- ONE AUDIENCE TIER PER REPO (Dave, August 12, 2026; inbound #620) -----------------------------
#     Tier 1 and tier 2 are two KINDS of reader rather than two rungs of a ladder, and a repo has exactly
#     one. The seam is injected the way a real repo reaches it -- repo-config.ps1 defines the function, and
#     this suite defines it in its own scope, as the wording override above already does -- and it is
#     REMOVED again at the end, because every assert before this point was written for the unstated case.
Write-Host "one audience tier per repo (Get-EntryAudienceTier / Get-EntryAskedTiers)" -ForegroundColor Cyan

# THE UNSTATED CASE FIRST, because it is the case every existing consumer is in and the one a later
# "simplification" would break. No seam means ask about everything -- identical to before the knob existed.
Assert-Equal $null (Get-EntryAudienceTier) 'no seam defined: no audience is stated'
Assert-Equal '0 1 2' ((@(Get-EntryAskedTiers)) -join ' ') 'and an unstated repo is asked about every tier the model has'

function Get-ReleaseAudienceTier { 2 }
Assert-Equal 2 (Get-EntryAudienceTier) 'a stated audience tier is read'
Assert-Equal '0 2' ((@(Get-EntryAskedTiers)) -join ' ') 'a tier-2 repo is asked about tier 0 and tier 2 -- not tier 1'

# AN OUT-OF-MODEL ANSWER DEGRADES TO 'UNSTATED' rather than being honoured. 0 is in the list on purpose:
# tier 0 is asked unconditionally, so naming it here would say nothing and is not a valid answer to THIS
# question. The alternative -- honouring it -- has the scaffolder write a section no validator accepts,
# and a gate refusing every entry in the repo is worse than a gate nobody configured.
foreach ($bad in @('0', '3', '7', '-1', 'two', '')) {
    Set-Item function:Get-ReleaseAudienceTier -Value ([scriptblock]::Create("return '$bad'"))
    Assert-Equal $null (Get-EntryAudienceTier) "an out-of-model answer ('$bad') is ignored rather than honoured"
}

function Get-ReleaseAudienceTier { 1 }
Assert-Equal '0 1' ((@(Get-EntryAskedTiers)) -join ' ') 'a tier-1 repo -- a shop whose buyers never read a note -- is asked about tier 0 and tier 1'

# THE MAX IS NOT THE AUDIENCE, and this single assert is what keeps one repo's history readable to another.
# A tier-1 repo must still PARSE the tier-2 entries in its own tree; collapsing the two would read every one
# of them as undeclared, silently, in the direction that empties a release.
Assert-Equal 2 (Get-EntryTierMax) 'the model still HAS three tiers while a tier-1 repo asks about two'

# WHAT THE SCAFFOLDER WRITES, AND WHERE THE ROUTING QUESTION POINTS. In a tier-2 repo the question under
# tier 0 has to say 'continue to Tier 2'; it said 'Tier 1' until the lookup was keyed on the TARGET rather
# than on a fixed pair -- form text sending an author to a heading that is not in the file.
function Get-ReleaseAudienceTier { 2 }
$audienceScaffold = (Format-EntrySignificanceSections -WithGuidance) -join "`n"
# NEITHER TIER NAMES ITSELF SINCE AUGUST 19, 2026, AND TIER 0 HAS NO HEADING AT ALL SINCE AUGUST 23. The
# question that headed it went away when the entry became the development cycle's DEPLOY section: that
# heading is now tier 0's section, one level up, and the audience tier's heading moved up with it -- an H3
# beside 'Pull Request' rather than an H4 nested under a question that no longer exists. What is unchanged
# is that no heading names a tier by number: a form saying 'Tier 2' is only right for a repo whose audience
# is 2, and this one ships to consumers who answer 1.
Assert-True ($audienceScaffold -notmatch ('(?m)^#+ ' + [regex]::Escape((Get-EntrySectionHeading -Key 'What')) + '$')) 'tier 0 gets no heading of its own -- the entry heading above it is its section'
Assert-Equal '' (Get-EntryTierSectionMarker -Tier 0) 'and the marker says so, so a writer cannot emit one'
Assert-True ($audienceScaffold -match ('(?m)^#{' + (Get-EntryTierSubLevel) + '} ' + [regex]::Escape((Get-EntryTierHigherHeading)) + '$')) 'and the audience tier is the entry''s first inner heading'
Assert-Equal (Get-EntrySectionLevel) (Get-EntryTierSubLevel) 'which is the entry''s own section level in the named shape -- asserted as the RELATION, because the number moved on August 26, 2026 and the relation did not'
Assert-True ($audienceScaffold -notmatch '(?m)^#{3,4} Tier \d+$') 'and no heading names a tier by its number at all'
foreach ($gone in @(Get-EntryTierHigherRetiredHeadings)) {
    Assert-True ($audienceScaffold -notmatch [regex]::Escape($gone)) "nor the retired wording '$gone' it replaced"
}
# NEITHER TIER NAMES ITSELF SINCE AUGUST 19, 2026, AND TIER 0 HAS NO HEADING AT ALL SINCE AUGUST 23.
Assert-Equal 0 ([regex]::Matches($audienceScaffold, 'continue to Tier').Count) 'no routing comment survives: the headings are the questions'
# THE GUIDANCE NAMES THIS REPO'S OWN READER, resolved rather than stored. A stored sentence would be wrong in
# every tier-1 repo -- which is the repo the knob exists for -- so the tier and its description are spliced in
# per repo. Asserted against the seam, not a literal, so the two cannot drift.
#
# READ FROM THE CYCLE DOCUMENT SINCE AUGUST 23, 2026, NOT FROM THE ENTRY SECTIONS (Dave). The sentence used to
# sit in the TierOptional comment under the second tier's heading; that block is empty now, because nothing
# inside the DEPLOY section may be a comment. The sentence itself was the one line naming WHO the audience
# tier is -- in a tier-1 consumer the only such line anywhere -- so it was hoisted into the visible block and
# the seam is read there instead. This assert follows it rather than being dropped with the block.
Assert-True (((Format-Development -Branch 'feat/x-v1' -Id '20260823-000000') -join "`n") -match [regex]::Escape("For tier 2 audiences: $(Get-EntryAudienceDescription -Tier 2)")) 'the audience guidance names this repo tier and who that tier is'
Assert-True ($audienceScaffold -notmatch '\{0\}') 'and the placeholder is resolved, not shipped'
# IT STILL RESOLVES TO A NUMBER, which is the half that would fail silently. A heading the parser cannot
# place reads as "no tier above 0" -- a claim about the change, made by a heading nobody read.
# TODAY'S SHAPE: the entry heading IS tier 0's section, and the audience tier is an H3 under it. Built from
# the seams rather than typed, so a level change cannot leave this assert testing yesterday.
$higherRead = Resolve-EntryImpact -EntryText (("#" * (Get-EntryHeadingLevel)) + " DEPLOY: ``feat/a`` " + (Get-EntryIdSeparator) + " 1`n`nwhy`n`n**Score:** 1`n`n" + ('#' * (Get-EntryTierSubLevel)) + ' ' + (Get-EntryTierHigherHeading) + "`n`nreaches them`n`n**Score:** 4`n")
Assert-Equal 0 @($higherRead.Errors).Count 'the current shape parses without complaint in a repo that has an audience tier'
Assert-Equal 2 (@($higherRead.Rows | Where-Object { [int]$_.Tier -eq 2 }).Count + 1) 'and resolve to this repo audience tier, so its score is not lost'
Assert-Equal 4 ([int](@($higherRead.Rows | Where-Object { [int]$_.Tier -eq 2 })[0].Score)) 'with the score the author actually wrote'
Assert-Equal 1 ([int](@($higherRead.Rows | Where-Object { [int]$_.Tier -eq 0 })[0].Score)) 'and the opening question reads back as tier 0, not as prose'
# THE RETIRED SHAPE IS STILL READ, which is the whole safety of the move: every entry in CHANGELOG.md and on
# every branch in flight carries the sub-headings right now, and they meet this parser through a plugin update.
# EVERY RETIRED WORDING, NOT JUST THE NEWEST. This read [0] until August 24, 2026, which asserted only the
# most recently retired one -- so the day a fourth wording was added (issue #865) the list grew and the
# assert kept measuring exactly one member of it. The list only ever grows, and each entry on it exists
# because entries carrying that wording are pending SOMEWHERE; a loop is the only shape that keeps saying so.
foreach ($retiredHigher in @(Get-EntryTierHigherRetiredHeadings)) {
    # THE RETIRED HEADING COMES OUT OF A VARIABLE, not out of '+' followed by an index. `"#### " + $a[0]`
    # concatenates the string with the ARRAY first and then indexes the RESULT, so the fixture silently
    # became '#### H' and the entry read as tier 0 -- a green-looking test of nothing.
    $retiredRead = Resolve-EntryImpact -EntryText ("## Branch ``feat/a`` changelog - '1'`n`n### What does the change on this branch bring to main?`n`n#### Tier 0`n`nwhy`n`n**Score:** 1`n`n#### ${retiredHigher}`n`nreaches them`n`n**Score:** 4`n")
    Assert-Equal 0 @($retiredRead.Errors).Count "the retired sub-heading '$retiredHigher' still parses without complaint"
    Assert-Equal 2 $retiredRead.Tier "and '$retiredHigher' still resolves to this repo audience tier"
}
# AND THE GUARD THAT MAKES THE OPENING QUESTION SAFE TO MATCH AT ALL. Every entry ever written carries that
# heading, including the ones declaring their reach in a table or in a 'Tier: N' line -- so without the score
# label as the discriminator, all of them would read as an unscored tier 0 and every release built from them
# would empty out. This is the assert that would catch that.
$tableUnderQuestion = Resolve-EntryImpact -EntryText ("### What does the change on this branch bring to main?`n`nA paragraph.`n`n### Significance`n`n| Tier | Significance | Why |`n|---|---|---|`n| 2 | 4 | consumers notice |`n")
Assert-Equal 'table' $tableUnderQuestion.Shape 'a table-shaped entry is NOT read as an unscored tier 0 by its opening question'
Assert-Equal 2 $tableUnderQuestion.Tier 'and keeps the reach its table declares'
$lineUnderQuestion = Resolve-EntryImpact -EntryText ("### What does this change do?`n`nA paragraph.`n`nTier: 2`n")
Assert-Equal 'line' $lineUnderQuestion.Shape 'and neither is a line-shaped one'

# THE TOLERANCE, WHICH IS THE LOAD-BEARING HALF OF THE WHOLE CHANGE. Six entries were pending in this repo
# when the knob landed, each carrying all three tiers under the cumulative model. A gate that started
# refusing an EXTRA answered tier would have turned six finished dossiers into six PRs that cannot be
# opened -- narrowing what is ASKED must not narrow what is ACCEPTED.
$threeTierEntry = @(
    '## `feat/x` changelog', '', '### Significance', '',
    '#### Tier 0', '', 'Developers see it.', '', '**Score:** 3', '',
    '#### Tier 1', '', 'Colleagues see it.', '', '**Score:** 2', '',
    '#### Tier 2', '', 'Subscribers see it.', '', '**Score:** 4', ''
) -join "`n"
Assert-Equal 0 (@(Get-EntryImpactFindings -EntryText $threeTierEntry)).Count `
    'an entry answering a tier this repo no longer asks about is not faulted for it'

# AND NARROWING IS NOT SWITCHING OFF. The audience tier is still required to carry its reason.
$audienceNoWhy = @(
    '## `feat/y` changelog', '', '### Significance', '',
    '#### Tier 0', '', 'Developers see it.', '', '**Score:** 3', '',
    '#### Tier 2', '', '**Score:** 4', ''
) -join "`n"
Assert-True ((@(Get-EntryImpactFindings -EntryText $audienceNoWhy)).Count -gt 0) `
    'the audience tier scored with no reason is still refused'

Remove-Item function:Get-ReleaseAudienceTier
Assert-Equal $null (Get-EntryAudienceTier) 'the seam is removed again, so nothing after this inherits it'

Write-Host ""
Write-Host "Get-EntryLinkTargets / Get-EntryLinkFindings -- the entry's links resolve at the DESTINATION (inbound #806)" -ForegroundColor Cyan
# The entry is folded verbatim into the changelog, so a relative link in it has to resolve from THAT file's
# directory -- which, where the two differ, means it looks wrong in the file being edited and only becomes
# right after it moves. A consumer merged two '../../scripts/...' links that landed at the root pointing
# outside the repo, with every gate green.
# WHICH DIRECTORY IT IS, IS A SEAM (inbound #967, August 27, 2026). It was the repo root in every repo until
# #914 made Get-ChangelogPath isolate-by-default, and the fixtures below cover both answers: the root, which
# is this repo's own, and the workflow folder, which is every consumer's default and is also the directory
# the entry itself sits in -- so there the correct link is the one that already reads correctly in the file.
# ONE '../' SINCE AUGUST 23, 2026, not two: the document sits directly in contributing-davekjohn/ rather than in
# a branch/ subdirectory of it, so the wrong-but-resolving form an author naturally writes is one level
# shallower. The depth comes from the seam (Get-BranchFilePaths.Directory), which is what the suggester
# reads -- so this fixture is the depth the suggester will actually try.
$linkEntry = @(
    '## DEPLOY: `fix/x-v1`', '',
    'See [the lib](scripts/lib/release-lib.ps1) and [the gate](../scripts/lint/check-plugin-integrity.ps1).',
    'Also [upstream](https://example.com/x), [an anchor](#somewhere) and [absolute](/etc/x).', '',
    '**Score:** 3', ''
) -join "`n"
$targets = @(Get-EntryLinkTargets -EntryText $linkEntry)
Assert-Equal 2 $targets.Count 'only the two RELATIVE targets are read -- http, a pure anchor and an absolute path cannot be broken by the move'
Assert-True ($targets -contains 'scripts/lib/release-lib.ps1') 'the root-relative one is read'
Assert-True ($targets -contains '../scripts/lint/check-plugin-integrity.ps1') 'and the branch-relative one, as written'

# THE ANCHOR AND THE TITLE ARE DROPPED: whether a heading exists is a different question with a different
# answer, and the repo's own link lint already asks it. This function answers only "is there a file there".
$anchored = '[a](scripts/lib/release-lib.ps1#get-bumptype) and [b](CHANGELOG.md "The changelog")'
$anchorTargets = @(Get-EntryLinkTargets -EntryText $anchored)
Assert-True ($anchorTargets -contains 'scripts/lib/release-lib.ps1') 'an anchor is stripped from the target'
Assert-True ($anchorTargets -contains 'CHANGELOG.md') 'and so is a link title'

# CODE AND COMMENTS ARE EXCLUDED, and this is the half that was MEASURED rather than assumed. Over the last
# 80 revisions of this repo's own entry file a naive scan produces exactly ONE finding, and it is false:
# '[PR #N](url)' inside INLINE backticks, in an entry explaining what the fold writes. So fences alone are
# not enough -- which is why all three strippers are here, matching the repo's own link lint.
$quoting = @(
    'Prose mentioning `[PR #N](url)` inline.', '',
    '```markdown', '- **[`scripts/x.ps1`](../../scripts/x.ps1)** an example', '```', '',
    '<!-- link to the PR in github: [PR #NN](url) - merged <date> -->', ''
) -join "`n"
Assert-Equal 0 (@(Get-EntryLinkTargets -EntryText $quoting)).Count 'a link quoted in inline code, in a fence, or in an html comment is illustration and is not read'

# The findings themselves, resolved against a real tree: this repo's own root.
$repoRootForLinks = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$findings = @(Get-EntryLinkFindings -EntryText $linkEntry -RepoRoot $repoRootForLinks)
Assert-Equal 1 $findings.Count 'the root-relative link resolves and is not reported; the branch-relative one is'
Assert-Equal '../scripts/lint/check-plugin-integrity.ps1' $findings[0].Target 'the finding names the link AS WRITTEN, which is what the author has to find in their file'
# THE SUGGESTION IS THE POINT, not decoration. A finding that only says "does not exist" sends the author to
# add another '../' -- the repo's own link lint had to learn the same lesson on August 19, 2026.
Assert-Equal 'scripts/lint/check-plugin-integrity.ps1' $findings[0].Suggested 'and it names the root-relative form, because the naive repair is to add another ../'
# A target that resolves from NEITHER base is a typo, and a typo gets no guess.
$typo = '[x](scripts/lint/no-such-file.ps1)'
$typoFindings = @(Get-EntryLinkFindings -EntryText $typo -RepoRoot $repoRootForLinks)
Assert-Equal 1 $typoFindings.Count 'a path that resolves from nowhere is still reported'
Assert-Equal '' $typoFindings[0].Suggested 'but no repair is suggested for it -- there is nothing to compute one from'
# TWO ROOT DOCUMENTS THAT REALLY ARE AT THE ROOT. This named CHANGELOG.md until August 27, 2026, when that
# file moved into contributing-davekjohn/ and the assert started reporting a finding it was written to prove
# absent -- correctly, since the default destination here IS the repo root. CLAUDE.md is the substitute
# because the point is a link that resolves at the destination, not which document it names.
Assert-Equal 0 (@(Get-EntryLinkFindings -EntryText '[ok](CLAUDE.md) and [ok2](README.md)' -RepoRoot $repoRootForLinks)).Count 'an entry whose links are all root-relative passes'

# THE GUIDANCE SAYS SO BEFORE THE GATE REFUSES, which is the half that reaches the author while they are
# still writing. IT MOVED TO 'StepsGuidance' ON AUGUST 23, 2026 (Dave): no comment may stand inside the
# DEPLOY section, because that section is what travels into CHANGELOG.md, so the 'Tier' block is empty and
# the rules with a SILENT failure mode were hoisted into the visible block above the phases. Asserted
# against that block by name rather than against 'some guidance somewhere', so a future move has to come
# back through this line.
# A TOKEN IN THE WORDING, RESOLVED AT RENDER (inbound #967). The sentence used to be two typed lines saying
# 'FROM THE REPO ROOT', which stopped being true for consumers when the changelog isolated -- so the block
# carries '{1}' and Format-EntryLinkGuidance fills it from the destination that actually applies. Asserted in
# both halves, because either one alone passes while the feature is broken: a token nobody resolves renders
# '{1}' into every branch document, and a resolver with no token in the block silently states nothing at all.
Assert-True ([string]((Get-BranchFileWording).StepsGuidance -join ' ') -match '\{1\}') 'the visible block carries the link token rather than a typed base'
Assert-True ([string](@(Format-EntryLinkGuidance -Lines @((Get-BranchFileWording).StepsGuidance) -DestDirRel '') -join ' ') -match 'FROM THE REPO ROOT') 'and it resolves to the root-relative convention where the changelog is at the root'
# AND IT REACHES THE FILE A BRANCH ACTUALLY GETS, which is where it did NOT reach until August 23, 2026:
# the guidance rendered into branch/templates/ and the working file was bare. That is what inbound #810
# measured, and this is the assert that keeps it repaired.
Assert-True (((Format-Development -Branch 'feat/x-v1' -Id '20260823-000000') -join "`n") -match 'FROM THE REPO ROOT') 'and it reaches the document a branch is handed, not a reference beside it'

Write-Host "Get-EntryLinkFindings -DestDirRel -- the base follows the CHANGELOG, not the root (inbound #967)" -ForegroundColor Cyan
# A BUILT TREE RATHER THAN THIS REPO'S OWN, and the reason is a lesson from writing these asserts. The
# section above resolves against the live checkout, which is fine while it only asks about paths that have
# been there for months -- and it silently answers the wrong question the moment a fixture file exists at
# BOTH bases. The first draft used CONTRIBUTING.md, which sits at the root AND in the workflow folder here,
# so the root case reported nothing and read as a broken repair rather than a badly chosen fixture. This
# tree states exactly which file is where, and it does not move when the repo's layout does.
$linkFixture = Join-Path ([System.IO.Path]::GetTempPath()) "entry-link-dest-$PID"
if (Test-Path -LiteralPath $linkFixture) { Remove-Item -Recurse -Force -LiteralPath $linkFixture }
$folderRel = (Get-BranchFilePaths).Directory
New-Item -ItemType Directory -Path (Join-Path $linkFixture $folderRel) -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $linkFixture 'scripts') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $linkFixture 'releases') -Force | Out-Null
# beside/ IS THE POINT OF THE THIRD FILE: a name that exists in the folder and NOT at the root, which is
# what makes the two destinations give different answers for one identical link.
$linkFixtureEnc = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $linkFixture "$folderRel\beside.md"), "x`n", $linkFixtureEnc)
[System.IO.File]::WriteAllText((Join-Path $linkFixture 'scripts\x.ps1'), "x`n", $linkFixtureEnc)
[System.IO.File]::WriteAllText((Join-Path $linkFixture 'CHANGELOG.md'), "x`n", $linkFixtureEnc)
try {
    # THE REVERSAL, IN ONE PAIR. Get-DefaultChangelogPath puts a consumer's CHANGELOG.md in the workflow
    # folder -- the same directory the cycle document sits in -- so on the shipped defaults the root base
    # refused the link form that is correct after the fold and demanded the one that is dead. Both asserts
    # take the same text and the same tree; only the destination differs, which is the whole bug.
    $sameDirLink = '[a neighbour](beside.md)'
    $fromRoot = @(Get-EntryLinkFindings -EntryText $sameDirLink -RepoRoot $linkFixture -DestDirRel '')
    Assert-Equal 1 $fromRoot.Count 'with the changelog at the root, a link written as it reads in the entry file is reported'
    Assert-Equal "$folderRel/beside.md" $fromRoot[0].Suggested 'and the root-relative form is what it is told to write -- #806, unchanged'
    Assert-Equal 0 (@(Get-EntryLinkFindings -EntryText $sameDirLink -RepoRoot $linkFixture -DestDirRel $folderRel)).Count 'with the changelog in that same directory the identical link PASSES -- there is nothing for the fold to break'

    # AND THE OTHER WAY ROUND, which is the finding a real consumer meets: they followed the old guidance,
    # wrote the link root-relative, and it is dead once the text sits in the folder. It must not merely be
    # refused -- the suggestion has to name the '../' form, or the one author who did as they were told gets
    # the only finding with no way out of it.
    $rootStyleLink = '[the script](scripts/x.ps1)'
    $fromFolder = @(Get-EntryLinkFindings -EntryText $rootStyleLink -RepoRoot $linkFixture -DestDirRel $folderRel)
    Assert-Equal 1 $fromFolder.Count 'a root-relative link is dead at a destination inside the folder, and is reported there'
    Assert-Equal '../scripts/x.ps1' $fromFolder[0].Suggested 'and the suggestion names the form that destination needs, computed from the repo root as the second candidate base'
    Assert-Equal 0 (@(Get-EntryLinkFindings -EntryText $rootStyleLink -RepoRoot $linkFixture -DestDirRel '')).Count 'while the same link passes for a repo whose changelog is at the root'

    # A TYPO IS STILL A TYPO AT EITHER DESTINATION, and gets no guess at either.
    $destTypo = @(Get-EntryLinkFindings -EntryText '[x](scripts/no-such-file.ps1)' -RepoRoot $linkFixture -DestDirRel $folderRel)
    Assert-Equal 1 $destTypo.Count 'a path that resolves from neither base is reported at an isolated destination too'
    Assert-Equal '' $destTypo[0].Suggested 'and still gets no suggestion -- there is nothing to compute one from'

    # THE DEFAULT IS THE ROOT, which is what keeps every other caller -- the suites included -- on the
    # behaviour #806 shipped. A parameter whose omission changed the answer would have made this a migration.
    Assert-Equal 1 (@(Get-EntryLinkFindings -EntryText $sameDirLink -RepoRoot $linkFixture)).Count 'omitting -DestDirRel is the repo root, exactly as before the parameter existed'

    Write-Host "Get-PathRelativeToDirectory -- the suggestion's form, including the case a substring could not reach" -ForegroundColor Cyan
    Assert-Equal 'scripts/x.ps1' `
        (Get-PathRelativeToDirectory -FullPath (Join-Path $linkFixture 'scripts\x.ps1') -Directory $linkFixture) `
        'a target UNDER the directory is its tail -- the only case the substring this replaced could answer'
    Assert-Equal '../scripts/x.ps1' `
        (Get-PathRelativeToDirectory -FullPath (Join-Path $linkFixture 'scripts\x.ps1') -Directory (Join-Path $linkFixture $folderRel)) `
        'a target BESIDE it needs a ../, which is the case that silently produced nothing before'
    Assert-Equal 'beside.md' `
        (Get-PathRelativeToDirectory -FullPath (Join-Path $linkFixture "$folderRel\beside.md") -Directory (Join-Path $linkFixture $folderRel)) `
        'a target IN it is the bare filename'
} finally {
    Remove-Item -Recurse -Force -LiteralPath $linkFixture -ErrorAction SilentlyContinue
}

# NO SHARED SEGMENT MEANS NO RELATIVE FORM AT ALL, and '' is the same answer the caller gives for a target it
# cannot name a form for -- not an exception, because a suggestion is a courtesy and a throw here would take
# down a gate over one unreachable path.
Assert-Equal '' (Get-PathRelativeToDirectory -FullPath 'Q:\elsewhere\x.md' -Directory (Join-Path $repoRootForLinks $folderRel)) `
    'another drive has no relative form, and that is reported as no suggestion rather than as an error'

Write-Host "Format-EntryLinkGuidance -- the sentence a branch document is handed states the base that applies" -ForegroundColor Cyan
$tokenBlock = @('> intro', '> {1}', '> outro')
$rootLines = @(Format-EntryLinkGuidance -Lines $tokenBlock -DestDirRel '')
Assert-Equal 4 $rootLines.Count 'the root sentence is two fragments wide, so the token line is emitted twice'
Assert-True ([string]($rootLines -join ' ') -match 'FROM THE REPO ROOT, not from this directory') 'and it is word for word what the block said before the token existed'
foreach ($line in $rootLines) { Assert-True ([bool]($line -match '^> ')) "every produced line keeps the blockquote prefix: '$line'" }
$sameLines = @(Format-EntryLinkGuidance -Lines $tokenBlock -DestDirRel $folderRel -EntryDirRel $folderRel)
Assert-True ([string]($sameLines -join ' ') -match 'FROM THIS DIRECTORY') 'a changelog in the entry''s own directory is told plainly, since the old wording said the opposite'
Assert-True ([string]($sameLines -join ' ') -notmatch 'never `\.\./') 'and the "never ../" advice is gone there -- it was the wrong instruction, not a shorter one'
$thirdLines = @(Format-EntryLinkGuidance -Lines $tokenBlock -DestDirRel 'releases' -EntryDirRel $folderRel)
Assert-True ([string]($thirdLines -join ' ') -match 'FROM `releases/`') 'a destination that is neither names itself'
# THE OVERRIDE CONTRACT, same as its '{0}' sibling: a repo that replaced the wording with its own prose gets
# exactly its own prose, and no token to fill means nothing is added or removed.
Assert-Equal 2 (@(Format-EntryLinkGuidance -Lines @('> our own words', '> in two lines') -DestDirRel $folderRel)).Count 'a block carrying no token comes back untouched'
Assert-True (((Format-Development -Branch 'feat/x-v1' -Id '20260827-000000' -LinkDestDirRel $folderRel) -join "`n") -match 'FROM THIS DIRECTORY') 'and the document a consumer''s branch is handed carries the base that repo actually folds into'

# #915 -- EVERY GUIDANCE ELEMENT IS A BLOCKQUOTE LINE, and this assert exists because nothing ever counted
# the array. In PowerShell ',' binds TIGHTER than '+', so an element written as 'a' + $H + 'b' inside the
# literal is ARRAY concatenation of its neighbours rather than string concatenation: the four composed lines
# became twelve elements, four of them a bare '###' or '####' alone, and check-branch-entry.ps1 read those as
# branch content in the generic region -- refusing the document new-branch had just written, on every branch
# in every consumer. It fails into WELL-FORMED output, so only a count catches it.
#
# ASSERTED AS A SHAPE, NOT AS A COUNT. Every element of this block opens the blockquote, so a split element
# shows up here as a line that does not -- and the assert needs no maintenance when the wording changes. A
# pinned element count would go red on every legitimate edit and be raised rather than read.
$guidanceElements = @((Get-BranchFileWording).StepsGuidance)
$notQuoted = @($guidanceElements | Where-Object { $_ -notmatch '^>' })
foreach ($stray in $notQuoted) { Write-Host "         stray element: '$stray'" -ForegroundColor Red }
Assert-Equal 0 $notQuoted.Count "every guidance element opens with '>' -- an element split by ',' binding over '+' surfaces here as a bare marker"
# AND THE COMPOSED LEVEL REACHES THE DOCUMENT INLINE, which is the reader-facing half of the same defect: a
# split element still renders, with the marker orphaned onto its own line where it reads as a heading.
$phaseHashes = '#' * (Get-BranchCycleSectionLevel)
Assert-True (((Format-Development -Branch 'feat/x-v1' -Id '20260826-000000') -join "`n") -match ('FOUR `' + $phaseHashes + '` HEADINGS')) 'and the level composed from the knob reaches the document on one line, not orphaned onto its own'

Write-Host ""
Write-Host "Remove-EntryAudienceGuidance -- a no-tier repo drops the audience PARAGRAPH, not one line of it (#928)" -ForegroundColor Cyan
# THE SEAM LINE OPENS A SENTENCE THE LINES BELOW IT FINISH. The call site used to filter '$_ -notmatch {0}',
# which is right about the seam and wrong about the sentence: in a repo with no Get-ReleaseAudienceTier the
# two continuation lines stayed, so every branch document carried a paragraph beginning mid-sentence and
# referring to "that reader" after the clause naming that reader had been dropped. Not reachable here --
# scripts/repo-config.ps1 states tier 2 -- so it reached consumers only and nothing in this repo caught it.
#
# THE PARAGRAPH IS COMPUTED FROM THE WORDING, NOT TYPED. Pinning the prose would make this assert go red on
# every legitimate edit of the guidance and be raised rather than read; deriving it means the assert follows
# the wording wherever it goes, and still fails the moment a continuation line survives the drop.
$sg = @((Get-BranchFileWording).StepsGuidance | ForEach-Object { [string]$_ })
$seamIdx = 0..($sg.Count - 1) | Where-Object { $sg[$_] -match '\{0\}' } | Select-Object -First 1
Assert-True ($null -ne $seamIdx) 'the guidance still carries the audience seam this case is about'

$isSep = { param([string]$l) ([string]($l -replace '^\s*>', '')).Trim() -eq '' }
$pStart = $seamIdx; while ($pStart -gt 0 -and -not (& $isSep $sg[$pStart - 1])) { $pStart-- }
$pEnd = $seamIdx; while ($pEnd -lt ($sg.Count - 1) -and -not (& $isSep $sg[$pEnd + 1])) { $pEnd++ }
Assert-True ($pEnd -gt $pStart) 'and that seam opens a MULTI-line paragraph -- the whole reason this case exists'

$dropped = @($sg[$pStart..$pEnd])
$kept = @(Remove-EntryAudienceGuidance -Lines $sg)
foreach ($line in $dropped) {
    Assert-True (-not ($kept -contains $line)) "the whole paragraph goes: '$($line.Substring(0, [Math]::Min(52, $line.Length)))...'"
}
# AND ONLY THE PARAGRAPH GOES. The paragraphs fencing it must survive, or a fix for a dangling sentence has
# quietly eaten the guidance around it.
if ($pStart -gt 1) { Assert-True ($kept -contains $sg[$pStart - 2]) 'the paragraph above it survives' }
if ($pEnd -lt ($sg.Count - 2)) { Assert-True ($kept -contains $sg[$pEnd + 2]) 'and the paragraph below it survives' }
Assert-Equal ($sg.Count - $dropped.Count - 1) $kept.Count 'exactly the paragraph plus ONE fencing separator is removed'
$doubled = @(0..($kept.Count - 2) | Where-Object { (& $isSep $kept[$_]) -and (& $isSep $kept[$_ + 1]) })
Assert-Equal 0 $doubled.Count 'and no doubled separator is left where the paragraph stood'

# A BLOCK CARRYING NO SEAM COMES BACK UNTOUCHED, which is what makes this safe over a consumer override: a
# repo that replaced the wording with its own prose gets exactly its own prose back.
$ownProse = @('> own prose', '>', '> a second paragraph')
Assert-Equal ($ownProse -join '~') ((@(Remove-EntryAudienceGuidance -Lines $ownProse)) -join '~') 'a block with no seam is returned as it came'
Assert-Equal 0 (@(Remove-EntryAudienceGuidance -Lines @())).Count 'and an empty block is not an error'

# THE DOCUMENT A NO-TIER CONSUMER IS ACTUALLY HANDED, which is the half that reaches a reader. The seam is
# unstated at this point in the suite -- Get-ReleaseAudienceTier was removed above -- so this renders the
# real fallback rather than a simulated one.
Assert-Equal $null (Get-EntryAudienceTier) 'the no-tier case is the one being rendered here'
$noTierDoc = (Format-Development -Branch 'feat/x-v1' -Id '20260826-000000') -join "`n"
Assert-True ($noTierDoc -notmatch '\{0\}') 'no dangling placeholder reaches the document'
foreach ($line in $dropped) {
    $needle = [regex]::Escape(($line -replace '^\s*>\s*', '').Trim())
    Assert-True ($noTierDoc -notmatch $needle) 'and no line of the audience paragraph reaches it either'
}

# THE TIER-STATED PATH IS UNCHANGED, so the repair cannot be mistaken for "drop it always".
function Get-ReleaseAudienceTier { 2 }
$tierDoc = (Format-Development -Branch 'feat/x-v1' -Id '20260826-000000') -join "`n"
Assert-True ($tierDoc -match 'For tier 2 audiences') 'a repo that STATES a tier still gets the sentence'
Assert-True ($tierDoc -match [regex]::Escape(($sg[$pEnd] -replace '^\s*>\s*', '').Trim())) 'and the lines finishing that sentence come with it'
Remove-Item function:Get-ReleaseAudienceTier
Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
