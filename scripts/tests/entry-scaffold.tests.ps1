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
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fixture 'scripts\task\new-branch.ps1') -Name 'feat/round-trip' 2>$null | Out-Null
    } finally {
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        Pop-Location
    }
} finally {
    $ErrorActionPreference = $prevEap
}

# branch/branch-changelog.md, not feat-round-trip.md in the root: since the branch/ split the writer uses
# fixed paths, and the path it uses comes from the same lib the readers use.
$writtenEntry = Join-Path $fixture ((Get-BranchFilePaths).Changelog)
Assert-True (Test-Path -LiteralPath $writtenEntry) 'the writer produced an entry file in the fixture'

# THE SECOND FILE, which is the half of the split the entry itself can no longer be asked about: the step
# list exists, names the branch it was created on, and is a separate document rather than a section of the
# entry. Asserted on the real writer's output for the same reason the entry is.
$writtenProgress = Join-Path $fixture ((Get-BranchFilePaths).Progress)
Assert-True (Test-Path -LiteralPath $writtenProgress) 'the writer produced the step list beside it'
if (Test-Path -LiteralPath $writtenProgress) {
    $progressText = [System.IO.File]::ReadAllText($writtenProgress, [System.Text.Encoding]::UTF8)
    Assert-Equal 'feat/round-trip' (Get-BranchFileDeclaredBranch -Text $progressText) 'the step list names the branch it belongs to -- the fold reads this back to find the PR'
    Assert-True ($progressText -match '(?m)^- \[ \] ') 'and it opens its list with an unticked item'
    Assert-Equal 0 @(Get-EntryScaffoldFindings -EntryText $progressText -Wording (Get-EntryScaffoldWording)).Count 'the step list carries no entry-scaffold markers -- it is not an entry and must not be judged as one'
}

# --- THE TEMPLATES ARE WRITTEN INTO THE REPO THE WRITER RUNS IN ------------------------------------
# THE FIXTURE IS A CONSUMER, and that is the whole point of asserting it here. It holds the shared scripts
# and nothing else -- no lint, no hand-written templates -- which is exactly what a consuming repo has.
#
# THE REGRESSION THIS PINS. Until August 7, 2026 nothing created branch/templates/ anywhere: they existed
# in the source repo because they were written by hand there, and the check that holds them to
# Get-BranchTemplates is repo-owned. When the working files became bare, the source repo's guidance moved
# to those templates and a consumer's went away entirely -- their only remaining description of the form
# was the skill page. Found by asking whether "see the templates" resolves in a consumer repo.
foreach ($tpl in (Get-BranchTemplates)) {
    $tplPath = Join-Path $fixture ($tpl.Path -replace '/', '\')
    Assert-True (Test-Path -LiteralPath $tplPath) "the writer created $($tpl.Path) -- a consumer has no other source for the guidance"
    if (Test-Path -LiteralPath $tplPath) {
        $onDisk = ([System.IO.File]::ReadAllText($tplPath, [System.Text.Encoding]::UTF8)) -replace "`r`n", "`n"
        Assert-Equal ($tpl.Content -replace "`r`n", "`n") $onDisk "and $($tpl.Path) is exactly what the formatters produce"
    }
}

# REFRESHED, NOT MERELY CREATED. A template that has drifted -- a consumer carrying last release's copy --
# is rewritten, which is what carries a format change into their reference through the same plugin update
# that carries it into their scripts. Without this they would be correct on the day branch/ appeared and
# stale from the next release on, which is the drift the whole mechanism exists to prevent.
$driftTpl = Join-Path $fixture ((Get-BranchTemplates)[0].Path -replace '/', '\')
[System.IO.File]::WriteAllText($driftTpl, "stale content from an older release`n", (New-Object System.Text.UTF8Encoding $false))
$prevEap2 = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    Push-Location $fixture
    try {
        $env:CLAUDE_PROJECT_DIR = $fixture
        # Same branch again: new-branch is idempotent, so this is the rerun that has to refresh the drifted
        # template while leaving the entry and the step list exactly as the author left them.
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fixture 'scripts\task\new-branch.ps1') -Name 'feat/round-trip' 2>$null | Out-Null
    } finally {
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
        Pop-Location
    }
} finally { $ErrorActionPreference = $prevEap2 }
$refreshed = ([System.IO.File]::ReadAllText($driftTpl, [System.Text.Encoding]::UTF8)) -replace "`r`n", "`n"
Assert-Equal ((Get-BranchTemplates)[0].Content -replace "`r`n", "`n") $refreshed 'a drifted template is rewritten, so a format change reaches a consumer reference too'

if (Test-Path -LiteralPath $writtenEntry) {
    $text = [System.IO.File]::ReadAllText($writtenEntry, [System.Text.Encoding]::UTF8)
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
    Assert-Equal 'feat/round-trip' (Get-BranchFileDeclaredBranch -Text $text) 'the entry heading names the branch, and reads back as it'
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
Write-Host "the fold footer (Format-EntryFoldFooter)" -ForegroundColor Cyan
$footer = Format-EntryFoldFooter -Number 468 -Url 'https://gh.test/pr/468' -MergedAt '2026-08-05T09:14:00Z' -FallbackDate '2099-01-01'
Assert-Equal "[PR #468](https://gh.test/pr/468) $md merged 2026-08-05" $footer 'the footer carries the PR link and the merge date on one line'
Assert-True ($footer -notmatch '2099') 'the PR timestamp wins over the fallback -- the clock is not consulted when gh answered'
# THE CASE THE WHOLE CHANGE IS ABOUT: a fold that runs the day after the merge must still date the
# entry by the merge, not by the run. Measured in this repo -- unfolded entries were once found in the
# root the morning after they landed.
$footerLate = Format-EntryFoldFooter -Number 12 -Url 'u' -MergedAt '2026-08-05T23:30:00Z' -FallbackDate '2026-08-07'
Assert-True ($footerLate -match 'merged 2026-08-0[56]$') 'a late fold still dates the entry by the merge, not by the day it was folded'
# No timestamp: a PR found but not yet merged, which -Branch mode can reach. Then "now" really is the
# best available answer, so the fallback is used rather than the line being dropped.
$footerNone = Format-EntryFoldFooter -Number 5 -Url 'u' -FallbackDate '2026-08-05'
Assert-Equal "[PR #5](u) $md merged 2026-08-05" $footerNone 'no merge timestamp: the caller-supplied date is used'
# A malformed timestamp must not turn a completed fold into a failure over a cosmetic line.
$footerBad = Format-EntryFoldFooter -Number 6 -Url 'u' -MergedAt 'not-a-date' -FallbackDate '2026-08-05'
Assert-Equal "[PR #6](u) $md merged 2026-08-05" $footerBad 'an unparseable timestamp degrades to the fallback instead of throwing'

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
# And the ranker, which is where a fence-blind read cost an ordering (PR #478).
$tildeList = @(
    '', 'Intro.', '',
    '## #20 Tier 2, quoting the format in tilde fences', '',
    '~~~text', '## #19 A quoted heading', '', '| Tier | Significance | Why |', '|---|---|---|', '| 0 | - | - |', '~~~', '',
    '### Who is this for', '', '| Tier | Significance | Why |', '|---|---|---|', '| 2 | 4 | consumers notice |', '',
    '---', '',
    '## #18 Tier 0', '', '| Tier | Significance | Why |', '|---|---|---|', '| 0 | - | - |', ''
) -join "`n"
$tildeOff = Get-EntryInsertOffset -SectionText $tildeList -Tier 1 -Score 3
$tildeTop = ((($tildeList.Substring($tildeOff)) -split "`r?`n")[0]).Trim()
Assert-Equal '## #20 Tier 2, quoting the format in tilde fences' $tildeTop 'tilde: the insert lands on the real first entry'
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
$flatDoc = "# Changelog`n`nIntro.`n`n## A real change`n`n### What does this change do?`n`nBody.`n"
Assert-Equal '' (Get-PreFlatChangelogRefusal -Content $flatDoc -Consequence 'x') 'pre-flat: a flat document produces no refusal'
Assert-Equal '' (Get-PreFlatChangelogRefusal -Content "# Changelog`n`nIntro only.`n" -Consequence 'x') 'pre-flat: a document with NO entries yields nothing -- there is no block to misread'
Assert-Equal '' (Get-PreFlatChangelogRefusal -Content '' -Consequence 'x') 'pre-flat: and an empty document does not throw'
# The consumer's actual document: both section headings, a real pre-format entry filed under the first.
$preFlatDoc = "# Changelog`n`nIntro.`n`n## Pull Requests`n`nMerged PRs land here.`n`n### An older change " +
              [char]0x00B7 + " Feat`n`nBody.`n`n## Releases`n`nThe recorded versions.`n"
$refusal = Get-PreFlatChangelogRefusal -Content $preFlatDoc -Consequence 'THE CALLER SAYS THIS'
Assert-True ($refusal -ne '') 'pre-flat: the pre-flat shape IS refused'
Assert-True ($refusal -match "'## Pull Requests'") 'pre-flat: the offending block is named'
Assert-True ($refusal -match "'## Releases'") 'pre-flat: and so is the second -- both, or a reader migrates half a document'
Assert-True ($refusal -match '2 H2 block') 'pre-flat: the COUNT is stated, which is the number the consumer saw go wrong'
Assert-True ($refusal -match 'THE CALLER SAYS THIS') 'pre-flat: the caller''s consequence clause is spliced in -- the one part that differs between the cut and the fold'
Assert-True ($refusal -match 'Migrate the document first') 'pre-flat: the way out is in the message, not only the diagnosis'
# THE PRE-FORMAT ENTRY UNDER THAT HEADING IS NOT ACCUSED. It declares its type in its heading, which is a
# legitimate shape -- so a refusal counting it would tell a consumer to migrate an entry that is already fine.
Assert-True ($refusal -notmatch 'An older change') 'pre-flat: a pre-format entry is not one of the findings'
# Fence-aware, like every reader here: a document DESCRIBING the pre-flat shape is not in it.
$quotedDoc = "# Changelog`n`nThe old shape was:`n`n" + '```text' + "`n## Pull Requests`n" + '```' + "`n`n## A real change`n`n### What does this change do?`n`nBody.`n"
Assert-Equal '' (Get-PreFlatChangelogRefusal -Content $quotedDoc -Consequence 'x') 'pre-flat: a section heading quoted in a fence is not a section heading'
# Get-ChangelogEntryBlocks, the boundary reader underneath it -- the intro is dropped, the entries are not.
$blocks = @(Get-ChangelogEntryBlocks -Content $flatDoc)
Assert-Equal 1 $blocks.Count 'blocks: the intro is not one of them'
Assert-True ($blocks[0].StartsWith('## A real change')) 'blocks: and the block starts at the entry heading'
Assert-Equal 0 @(Get-ChangelogEntryBlocks -Content "# Changelog`n`nIntro only.`n").Count 'blocks: a document with no entry yields an empty array rather than the intro'

# --- The insert offset ----------------------------------------------------------------------------
# ENTRIES ARE H2 HERE, matching the flat list the fold writes since August 5, 2026 -- and this fixture is
# where that mattered first: the function's $EntryPattern default moved from '### ' to '## ', so a fixture
# left at H3 stopped having any entry boundaries at all and every offset silently became "the end". Four
# asserts went red at once, which is the loud version of a failure that in the real document would have been
# one entry quietly appended at the bottom.
$section = "`nIntro.`n`n## #10 Top`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | 5 | big |`n`n---`n`n" +
           "## #11 Mid`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | 3 | ok |`n`n---`n`n"
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
    Assert-Equal '## #10 Top' (Get-InsertLabel -Score $case.Score -Tier $case.Tier) `
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
    '## #20 Real, tier 2, and it documents the format', '',
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
Assert-Equal '## #20 Real, tier 2, and it documents the format' (Get-FencedInsertLabel -Score 3 -Tier 1) 'insert/fenced: the top is the real first entry'
Assert-Equal '## #20 Real, tier 2, and it documents the format' (Get-FencedInsertLabel -Score 5 -Tier 2) 'insert/fenced: and the rank does not move it'
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
Assert-Equal '## #20 Real, tier 2, and it documents the format' ((($crlfList.Substring($crlfOff)) -split "`r?`n")[0]).Trim() 'insert/fenced: a CRLF document lands in the same place -- the offsets keep step with the lines'

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
Assert-True ($sigText.IndexOf('#### Tier 0') -lt $sigText.IndexOf('#### Tier 1')) 'sections: tier 0 comes first, because that is the order they are filled in'
Assert-True ($sigText.IndexOf('#### Tier 1') -lt $sigText.IndexOf('#### Tier 2')) 'sections: and tier 1 before tier 2'
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
    Assert-True ($sigScaffold -match ('(?m)^#### Tier ' + $t + '$')) "scaffold: tier $t has a section of its own"
}
Assert-Equal 3 (@([regex]::Matches($sigScaffold, '(?m)^#### Tier \d+$')).Count) 'scaffold: exactly the three the model has, no more'
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
$naEntry = "### Significance`n`n#### Tier 0`n`nmatters here`n`n**Score:** 3`n`n" +
           "#### Tier 1`n`nno colleague can observe it`n`n**Score:** $naLabel`n`n" +
           "#### Tier 2`n`nand no consumer either`n`n**Score:** $naLabel`n"
$naImpact = Resolve-EntryImpact -EntryText $naEntry
Assert-Equal 0 $naImpact.Tier "N/A: the reach is the highest SCORED tier, not the highest section present"
Assert-Equal $true $naImpact.Declared 'N/A: and the entry has still declared itself -- that is a decision, not a silence'
Assert-Equal 3 @($naImpact.Rows).Count 'N/A: all three rows are read'
Assert-Equal 0 @($naImpact.Errors).Count 'N/A: and none of them is an error -- N/A is a valid answer, not a malformed score'
Assert-Equal $true ([bool](@($naImpact.Rows | Where-Object { $_.Tier -eq 2 })[0].NotApplicable)) 'N/A: the row carries the flag, so a caller can tell it from an unanswered one'
Assert-Equal 0 @(Get-EntryImpactFindings -EntryText $naEntry).Count 'N/A: a fully answered entry has nothing outstanding'

# AN UNANSWERED TIER IS NOT AN N/A, and keeping those apart is the reason the flag exists at all. Both read
# back as score 0; only one of them is a decision somebody made.
$blankEntry = "### Significance`n`n#### Tier 0`n`nmatters here`n`n**Score:** 3`n`n#### Tier 1`n`nsomething`n`n**Score:**`n"
$blankRow = @((Resolve-EntryImpact -EntryText $blankEntry).Rows | Where-Object { $_.Tier -eq 1 })[0]
Assert-Equal $false ([bool]$blankRow.NotApplicable) 'blank: an unanswered score is NOT flagged as N/A'
Assert-Equal 0 ([int]$blankRow.Score) 'blank: and reads as 0, the fail-safe direction'

# THE LADDER STILL CANNOT BE SKIPPED, and N/A is the new way to try it: tier 1 declaring it reaches nobody
# while tier 2 is scored says a change consumers notice gives this project's colleagues nothing.
$skipEntry = "### Significance`n`n#### Tier 0`n`na`n`n**Score:** 2`n`n#### Tier 1`n`nb`n`n**Score:** $naLabel`n`n#### Tier 2`n`nc`n`n**Score:** 4`n"
$skipFindings = @(Get-EntryImpactFindings -EntryText $skipEntry)
Assert-True ($skipFindings.Count -gt 0) 'ladder: N/A under a scored tier is refused'
Assert-True (@($skipFindings -match 'cumulative').Count -gt 0) 'ladder: and the refusal names the reason rather than asking for a number'

# A score the rubric has no meaning for is still an error, and the message now offers N/A as the other
# legitimate answer -- a gate that says "write 1 to 5" at somebody who meant "this reaches nobody" is
# asking them to invent a number.
$badNa = Resolve-EntryImpact -EntryText "### Significance`n`n#### Tier 1`n`nwhy`n`n**Score:** nvt`n"
Assert-True (@($badNa.Errors).Count -gt 0) 'a score that is neither a number nor N/A is reported'
Assert-True (@($badNa.Errors -match [regex]::Escape($naLabel)).Count -gt 0) 'and the message names N/A as the other way to answer'

Write-Host "A malformed section is reported rather than absorbed" -ForegroundColor Cyan
$badTier = "### Significance`n`n#### Tier two`n`nwhy`n`nScore: 3`n"
Assert-True (@((Resolve-EntryImpact -EntryText $badTier).Errors).Count -gt 0) 'a non-numeric tier is an error, not a section that silently vanishes'
$badScore = "### Significance`n`n#### Tier 0`n`nwhy`n`nScore: 9`n"
Assert-True (@((Resolve-EntryImpact -EntryText $badScore).Errors -match 'outside the rubric').Count -gt 0) 'a score outside the rubric is named as such'
$dupTier = "### Significance`n`n#### Tier 0`n`na`n`nScore: 1`n`n#### Tier 0`n`nb`n`nScore: 2`n"
Assert-True (@((Resolve-EntryImpact -EntryText $dupTier).Errors -match 'a second time').Count -gt 0) 'the same tier twice is two answers to one question'

Write-Host "A reason below the score line is named as misplaced, not as missing (inbound #596)" -ForegroundColor Cyan
# THE DEFECT THIS GUARDS. The collecting loop read the lines under '**Score:**' and threw them away, so a
# tier whose reason was written one line too low reported as 'a tier with no reason' -- the one thing an
# author staring at their own three paragraphs can see is untrue, which makes distrusting the gate the
# natural next move instead of moving the text. Measured in the reporting repo: three tiers, all three
# answered, all three refused as unanswered.
$scoreLabel  = Get-EntryScoreLabel
$belowEntry  = "### Significance`n`n#### Tier 0`n`n$scoreLabel 3`n`nthe reason, written under the score`n"
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
$emptyTierEntry = "### Significance`n`n#### Tier 0`n`n$scoreLabel 3`n"
$emptyTierFind  = @(@(Get-EntryScaffoldFindings -EntryText $emptyTierEntry -Wording (Get-EntryScaffoldWording)) |
    Where-Object { $_.Marker -match 'Tier' })
Assert-Equal 1 $emptyTierFind.Count 'empty tier: still one finding'
Assert-Equal 'a tier with no reason' $emptyTierFind[0].Label 'empty tier: and it still reads as missing -- the two cases stay apart'

# THE FALSE-FINDING GUARD, which is why the filtering is one shared helper rather than two copies. The
# templates put guidance comments in the section, and a comment sitting under the score is this format's
# own prose -- counted as a misplaced reason it would accuse an entry nobody has written in yet of having
# put its answer in the wrong place, on every consumer, from the first branch.
$commentBelow = "### Significance`n`n#### Tier 1`n`n$scoreLabel`n<!-- Why does this matter to a colleague? -->`n"
$commentRow   = @((Resolve-EntryImpact -EntryText $commentBelow).Rows | Where-Object { $_.Tier -eq 1 })[0]
Assert-Equal '' ([string]$commentRow.WhyBelowScore) 'guidance below the score is this format''s prose, not a misplaced reason'

# THE RELEASE GATE READS THE SAME ROW, so it carried the same misdiagnosis -- and it is the worse place to
# meet it: a cut happens days later, when whoever wrote the entry is not the one reading the refusal.
$belowRanked = "### Significance`n`n#### Tier 0`n`nabove, correctly`n`n$scoreLabel 2`n`n" +
               "#### Tier 1`n`n$scoreLabel 3`n`nthe colleague-facing reason, one line too low`n"
$belowRankFindings = @(Get-EntryImpactFindings -EntryText $belowRanked)
Assert-Equal 1 $belowRankFindings.Count 'below-score: the ranking gate reports the tier once'
Assert-True ($belowRankFindings[0] -match 'BELOW') 'below-score: and names the placement rather than asking for a Why that is already written'

# THE LEGACY TABLE SHAPE CANNOT CARRY THE PROPERTY, so both gates ask before reading it. Without that guard
# every pre-section entry -- and CHANGELOG.md is full of them -- would throw on a property that is not there.
$tableNoWhy = "### Significance`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | 3 | |`n"
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
Assert-Equal 'sections' (Resolve-EntryImpact -EntryText "#### Tier 0`n`nr`n`n$scoreLabel 1`n").Shape 'shape: the sections are named as such'
Assert-Equal 'table' (Resolve-EntryImpact -EntryText "| Tier | Significance | Why |`n|---|---|---|`n| 1 | 3 | w |`n").Shape 'shape: the legacy table is named as such'
Assert-Equal 'line' (Resolve-EntryImpact -EntryText "### T`n`nTier: 2`n`nBody.").Shape 'shape: the pre-table line too -- "wrote it the old way"'
Assert-Equal 'none' (Resolve-EntryImpact -EntryText "### T`n`nBody only.").Shape 'shape: and an entry declaring nothing is not the same as one of the three'

# THE THREE REFUSALS, EACH IN BOTH BRANCHES. One assert pair per message, because they are three separate
# strings and a repair that fixed the reported one would leave the other two saying 'row' and 'column' to
# an author looking at headings. The section side must NOT name a column; the table side must still name
# one, since a table genuinely has three and its own wording is the accurate one there.
$sectionCases = @(
    @{ What  = 'no reason under a scored tier'
       Entry = "### Significance`n`n#### Tier 0`n`nr`n`n$scoreLabel 2`n`n#### Tier 1`n`n$scoreLabel 3`n"
       Table = "### Significance`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | 3 | |`n" }
    @{ What  = 'a tier with no score under a scored one'
       Entry = "### Significance`n`n#### Tier 0`n`nr`n`n$scoreLabel 2`n`n#### Tier 1`n`nwritten`n`n$scoreLabel`n`n#### Tier 2`n`nconsumers`n`n$scoreLabel 4`n"
       Table = "### Significance`n`n| Tier | Significance | Why |`n|---|---|---|`n| 1 | - | written |`n| 2 | 4 | consumers |`n" }
    @{ What  = 'a rung of the ladder missing altogether'
       Entry = "### Significance`n`n#### Tier 0`n`nr`n`n$scoreLabel 2`n`n#### Tier 2`n`nconsumers`n`n$scoreLabel 4`n"
       Table = "### Significance`n`n| Tier | Significance | Why |`n|---|---|---|`n| 2 | 4 | consumers |`n" }
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
# than against a literal. A refusal telling an author to add '#### Tier 1' while the writer emits something
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
Assert-True (-not ($sigStripped -match '#### Tier')) 'stripped: every tier section is gone, not just the first'
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
$fencedSig = "### Significance`n`n" + '```text' + "`n#### Tier 2`n`nquoted`n`nScore: 5`n" + '```' + "`n`n#### Tier 0`n`nreal`n`nScore: 1`n"
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
$freshScaffold = ((Format-BranchProgressScaffold -Branch 'feat/fresh') -join "`n")

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
Assert-Equal 0 @(Get-BranchProgressFindings -Text ((Format-BranchProgressReset) -join "`n")).Count 'the reset state has nothing to resolve -- an absent plan is not a refusal'

# --- The SDLC arc (#655) ------------------------------------------------------------------------------
# THE PHASES ARE DRAWN ON TOP OF THE GATE, NEVER INTO IT. Get-BranchProgressFindings reads step marks, so a
# heading is invisible to it -- which is the entire reason the arc could be added without touching the
# mechanism. Asserted in that order: the headings are there, AND they change no verdict.
Write-Host "the step list follows the SDLC arc (#655)" -ForegroundColor Cyan
$phases = @((Get-BranchFileWording).StepPhases)
Assert-Equal 3 $phases.Count 'three phases are configured -- PLAN, CREATE, TEST'
foreach ($phase in $phases) {
    Assert-True ($freshScaffold -match "(?m)^#{4}\s+$([regex]::Escape($phase))\s*$") "the scaffold carries a '$phase' heading"
}
# DEPLOY IS ABSENT ON PURPOSE, and this is the assert that records why (Dave, August 14, 2026). It is not a
# step but the RESULT -- the changelog entry beside this file, which is the half that travels into
# CHANGELOG.md at the merge. A DEPLOY checkbox could only be unresolvable, since the list must be clear
# before open-pr will push, or ticked before it happened. If somebody adds one, this goes red.
Assert-True (-not ($freshScaffold -match '(?im)^#{2,4}\s+DEPLOY')) 'DEPLOY is NOT a phase of the step list -- it is the changelog entry, the other file'

# The placeholder sits under CREATE, not under PLAN: a fresh branch has just been planned, and a TODO under
# PLAN would say the opposite.
$createBlock = if ($freshScaffold -match '(?ms)^####\s+CREATE\s*$(.*?)(?=^####\s|\z)') { $Matches[1] } else { '' }
Assert-True ($createBlock -match [regex]::Escape((Get-BranchFileWording).FirstStep)) 'the scaffolded step sits under CREATE'

# An empty phase is a statement, not a finding -- the same tolerance the absent-plan case gets above.
$emptyPhases = "### Steps`n`n#### PLAN`n`n#### CREATE`n`n- [x] did the thing`n`n#### TEST`n"
Assert-Equal 0 @(Get-BranchProgressFindings -Text $emptyPhases).Count 'a phase with nothing under it is not a finding'

# The template shows the arc but never a step -- an example whose first line is somebody else's TODO gets
# copied in, which is the rule the template already lived by before the phases existed.
$phaseTemplate = ((Format-BranchProgressScaffold -Branch 'x/y' -Template) -join "`n")
Assert-True ($phaseTemplate -match '(?m)^####\s+PLAN\s*$') 'the template carries the arc'
Assert-Equal 0 @(Get-BranchProgressFindings -Text $phaseTemplate).Count 'and still carries no step of its own'

# Fence-aware, like every reader of this format: this repo's own branch/README.md quotes all three marks
# while teaching them, and a step list may legitimately do the same.
$quoted = "## Steps`n`n- [x] documented the marks`n`n" + '```text' + "`n- [ ] not done yet`n" + '```' + "`n"
Assert-Equal 0 @(Get-BranchProgressFindings -Text $quoted).Count 'an open step QUOTED inside a fence is not an open step'

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
$defaultReset = (Format-BranchChangelogReset) -join "`n"
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
$dutchReset = (Format-BranchChangelogReset) -join "`n"
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
try { $braceReset = (Format-BranchChangelogReset) -join "`n" } catch { $threw = $true }
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
$noLead = (Format-BranchChangelogReset) -join "`n"
Assert-Equal $defaultReset $noLead 'empty lead: an empty override is ignored -- the default sentence stands, as for every other key'
Remove-Item -Path Function:\Get-BranchFileWordingOverrides
# The default is back, so nothing below inherits an override. Asserted rather than assumed: a leaked
# override would make every later assert read a document no repo produces.
Assert-Equal $defaultReset ((Format-BranchChangelogReset) -join "`n") 'teardown: the default reset is restored once the seam function is gone'

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
    'Plugins: workflow-davekjohn'
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
Assert-True ($audienceScaffold -match '(?m)^#### Tier 0$') 'the scaffold writes tier 0'
# AND THE AUDIENCE TIER IS HEADED WITH THE QUESTION SINCE AUGUST 16, 2026, not with its number. That is
# what took the routing comment out of the file: the heading asks it, in the one place a reader cannot
# skip. The number is not written at all -- which is the point, because a template naming 'Tier 2' is only
# right for a repo whose audience is 2, and this one ships to consumers who may answer 1.
Assert-True ($audienceScaffold -match ('(?m)^#### ' + [regex]::Escape((Get-EntryTierHigherHeading)) + '$')) 'and the audience tier, headed with the question'
Assert-True ($audienceScaffold -notmatch '(?m)^#### Tier 1$') 'and NOT the tier this repo does not publish to'
Assert-True ($audienceScaffold -notmatch '(?m)^#### Tier 2$') 'and not by its number either -- the heading is repo-neutral'
Assert-Equal 0 ([regex]::Matches($audienceScaffold, 'continue to Tier').Count) 'no routing comment survives: the heading is the question'
# IT STILL RESOLVES TO A NUMBER, which is the half that would fail silently. A heading the parser cannot
# place reads as "no tier above 0" -- a claim about the change, made by a heading nobody read.
$higherRead = Resolve-EntryImpact -EntryText ("## Branch ``feat/a`` changelog - '1'`n`n### What does the change on this branch bring to main?`n`n#### Tier 0`n`nwhy`n`n**Score:** 1`n`n#### " + (Get-EntryTierHigherHeading) + "`n`nreaches them`n`n**Score:** 4`n")
Assert-Equal 0 @($higherRead.Errors).Count 'the question heading parses without complaint in a repo that has an audience tier'
Assert-Equal 2 (@($higherRead.Rows | Where-Object { [int]$_.Tier -eq 2 }).Count + 1) 'and resolves to this repo audience tier, so its score is not lost'
Assert-Equal 4 ([int](@($higherRead.Rows | Where-Object { [int]$_.Tier -eq 2 })[0].Score)) 'with the score the author actually wrote'

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
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
