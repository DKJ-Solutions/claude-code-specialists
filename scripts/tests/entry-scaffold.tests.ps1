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
      3. THE ROUND TRIP, which is the real point: an entry written by the actual new-changelog-entry.ps1
         must be seen as scaffolded by the actual matcher. That is the assert that makes the writer and
         the guard incapable of disagreeing -- the whole reason the wording became one shared source
         rather than a copy in each script.

    Pure ASCII (repo convention for .ps1). The middot in an entry heading is built from its codepoint.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot        = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibSrc          = Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1'
$NewChangelogSrc = Join-Path $RepoRoot 'scripts\release\new-changelog-entry.ps1'
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
Write-Host "the round trip (new-changelog-entry writes what the gate refuses)" -ForegroundColor Cyan
# THE ASSERT THIS SUITE EXISTS FOR. Both scripts read the wording from the lib, so they cannot disagree
# -- but "cannot" is a claim about code, and this measures it by running the real writer and handing its
# output to the real matcher. If someone reintroduces a literal in either place, this goes red.
$fixture = Join-Path ([System.IO.Path]::GetTempPath()) "entry-scaffold-test-$PID"
if (Test-Path -LiteralPath $fixture) { Remove-Item -Recurse -Force -LiteralPath $fixture }
New-Item -ItemType Directory -Path (Join-Path $fixture 'scripts\release') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $fixture 'scripts\lib') -Force | Out-Null
Copy-Item -LiteralPath $NewChangelogSrc -Destination (Join-Path $fixture 'scripts\release\new-changelog-entry.ps1') -Force
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
    # The writer takes no -Branch/-RepoRoot: it derives both from git, so the fixture must actually BE on
    # the branch. CLAUDE_PROJECT_DIR is what the shared scripts read for their repo root (the dual-context
    # contract), and it is set for the child only rather than for this runner.
    & git -C $fixture checkout -q -b 'feat/round-trip' 2>$null | Out-Null
    # No -Title and no -Intent: that is the path that writes every one of the three scaffold strings.
    Push-Location $fixture
    try {
        $env:CLAUDE_PROJECT_DIR = $fixture
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fixture 'scripts\release\new-changelog-entry.ps1') 2>$null | Out-Null
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

if (Test-Path -LiteralPath $writtenEntry) {
    $text = [System.IO.File]::ReadAllText($writtenEntry, [System.Text.Encoding]::UTF8)
    $roundTrip = @(Get-EntryScaffoldFindings -EntryText $text -Wording (Get-EntryScaffoldWording))
    Assert-True ($roundTrip.Count -gt 0) 'the matcher sees the writer output as scaffolded -- writer and guard share one source'
    Assert-Equal 2 $roundTrip.Count 'and it finds both strings the writer wrote (the to-do heading is no longer one of them)'
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
    foreach ($key in @('What', 'Significance', 'Type')) {
        Assert-True ($text -match ('(?m)^' + [regex]::Escape((Get-EntrySectionHeading -Key $key)) + '\s*$')) `
            "the '$key' section heading is written verbatim as the parser expects it"
    }
    # ORDER, not just presence: the parser finds a section wherever it is, but a reader meets them in the
    # order they are written, and the three answer the questions in the order somebody arrives with them.
    $posWhat = $text.IndexOf((Get-EntrySectionHeading -Key 'What'))
    $posWho  = $text.IndexOf((Get-EntrySectionHeading -Key 'Significance'))
    $posType = $text.IndexOf((Get-EntrySectionHeading -Key 'Type'))
    Assert-True ($posWhat -lt $posWho -and $posWho -lt $posType) 'and the three sections are written in reading order'
    # The type is STATED in its own section now rather than parsed out of the heading as a middot field.
    $writtenType = Resolve-EntryType -EntryText $text
    Assert-Equal $true $writtenType.Declared 'the type is declared in its own section'
    Assert-Equal $null $writtenType.Error 'and is a type this repo actually produces'
    Assert-True ($entryLines[0] -notmatch [regex]::Escape($writtenType.Type)) 'and it is no longer a field in the heading'
    # The table is NOT scaffold prose: a tier-0 row is a legitimate final answer, so the gate must never
    # treat it as evidence of an unedited entry -- the reasoning that keeps Get-EntryFallbackType out too.
    $tierAsFinding = @($roundTrip | Where-Object { $_.Marker -match 'Tier' })
    Assert-Equal 0 $tierAsFinding.Count 'the impact table is not one of the scaffold findings -- a low tier is a decision, not a stub'
}
Remove-Item -Recurse -Force -LiteralPath $fixture -ErrorAction SilentlyContinue

# --- 4. The wiring: the gate is really installed in open-pr --------------------------------------
Write-Host "the wiring (open-pr installs the gate, new-changelog-entry keeps no copy)" -ForegroundColor Cyan
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

$writerText = [System.IO.File]::ReadAllText($NewChangelogSrc)
Assert-True ($writerText -match 'entry-scaffold-lib\.ps1') 'new-changelog-entry reads the wording from the shared lib'
# The literals must be GONE as VALUES, not absent as words. Matched on an ASSIGNMENT rather than on the
# bare string, because the writer legitimately names 'TODO: title' in a comment explaining why its -Title
# default is an empty sentinel -- prose about a historical value is not a second copy of it, and an
# assert that cannot tell those apart would push someone to delete a useful comment to get green.
foreach ($literal in @('TODO: title', '**To do / where I left off:**', 'TODO: what still needs to happen')) {
    $assignment = "=\s*'" + [regex]::Escape($literal)
    Assert-True ($writerText -notmatch $assignment) "new-changelog-entry assigns no literal '$literal'"
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
Assert-True ($foldText -match 'Get-ImpactInsertOffset') 'and places the entry by that rank, so CHANGELOG.md stays ordered'
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
Assert-True ($stripped -notmatch 'Significance') 'strip: the table is gone from an outward-facing rendering'
Assert-True ($stripped -match 'Body\.') 'and the body survives'
Assert-True ($stripped -notmatch "`n`n`n") 'and no triple blank line is left behind'
# A quoted table must survive stripping too, or rendering damages the entry that documents the mechanism.
Assert-True ((Remove-EntryImpactTable -EntryText $fence) -match 'quoted') 'strip: a fenced table is left alone'

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
$tildeOff = Get-ImpactInsertOffset -SectionText $tildeList -Tier 1 -Score 3
Assert-Equal '## #18 Tier 0' ((($tildeList.Substring($tildeOff)) -split "`r?`n")[0]).Trim() 'tilde: a heading quoted in a ~~~ fence is not an entry boundary either'

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
    $off = Get-ImpactInsertOffset -SectionText $section -Score $Score -Tier $Tier
    if ($off -ge $section.Length) { return '<end>' }
    return (($section.Substring($off) -split "`r?`n")[0]).Trim()
}
Assert-Equal '## #10 Top' (Get-InsertLabel -Score 5) 'insert: a TIE goes above its equal, preserving the newest-first order the list had'
Assert-Equal '## #10 Top' (Get-InsertLabel -Score 6) 'insert: a higher score leads'
Assert-Equal '## #11 Mid' (Get-InsertLabel -Score 4) 'insert: a middling score lands between'
Assert-Equal '<end>'      (Get-InsertLabel -Score 1) 'insert: the lowest score goes last'
# UNSCORED SINKS TO THE BOTTOM OF ITS TIER, not to the top of it, and the reason is symmetry with the
# entries it is being ranked against: this function already reads an entry ALREADY in the changelog that
# declares no score as 0 and sorts it below everything scored at its tier, so a new one has to land in the
# same place or the same entry would rank differently depending on which side of the fold it was on. It is
# not buried either -- open-pr reports the missing score and the cut refuses over it by name.
Assert-Equal '<end>' (Get-InsertLabel -Score 0) 'insert: an unscored entry sinks within its tier -- 0 is the lowest rank, not the absence of one'
# THE TIER IS THE FIRST KEY, which is what replaced the three section headings. Asserted in both directions,
# because getting this backwards is the bug that was measured on this function's first run: a repo-internal
# change leading the document.
Assert-Equal '## #10 Top' (Get-InsertLabel -Score 1 -Tier 2) 'insert: a further-reaching tier leads even on the LOWEST score'
Assert-Equal '<end>'      (Get-InsertLabel -Score 5 -Tier 0) 'insert: and tier 0 sinks below tier 1 even on the highest'
# A DECLARED TIER 0 IS NOT "DECLARED NOTHING". Both are tier 0 with no score here, and both belong at the
# bottom -- the -Undeclared switch that used to send the second case to the TOP of the list is gone, because
# in a flat list there is no such thing as an unplaced entry.
Assert-Equal '<end>'      (Get-InsertLabel -Score 0 -Tier 0) 'insert: an unscored tier-0 entry sinks too, rather than leading the document'
# Compared against the fixture's own length rather than a literal: a hard-coded 8 describes this string,
# not the behaviour, and breaks the moment somebody edits the fixture's intro.
$emptySection = "`nIntro.`n`n"
Assert-Equal $emptySection.Length (Get-ImpactInsertOffset -SectionText $emptySection -Score 4 -Tier 1) 'insert: a list with no entries yet appends at its end'

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
    $off = Get-ImpactInsertOffset -SectionText $fencedList -Score $Score -Tier $Tier
    if ($off -ge $fencedList.Length) { return '<end>' }
    return (($fencedList.Substring($off) -split "`r?`n")[0]).Trim()
}
# The bug, as the assert that would have caught it: a tier-1 entry must land BELOW the tier-2 entry whose
# body quotes a heading, not above it. Under the plain-regex split this returned '## #20 ...' -- the top.
Assert-Equal '## #18 Real, tier 0' (Get-FencedInsertLabel -Score 3 -Tier 1) 'insert/fenced: a quoted entry heading is not a boundary, so the tier-2 entry above it is not split into a tier-0 fragment'
# And the mirror image from the same fixture: a tier-2 entry scoring higher still leads.
Assert-Equal '## #20 Real, tier 2, and it documents the format' (Get-FencedInsertLabel -Score 5 -Tier 2) 'insert/fenced: a higher-scoring tier-2 entry still leads'
# The quoted table must not be read as the entry's declaration either -- it says tier 0 where the real
# declaration says tier 2, so a fence-blind read gets BOTH the boundary and the tier wrong.
$blockImpact = Resolve-EntryImpact -EntryText $fencedList.Substring($fencedList.IndexOf('## #20'))
Assert-Equal 2 $blockImpact.Tier 'insert/fenced: the entry reads as tier 2 from its real table, not tier 0 from the quoted one'
# CRLF: the offsets are rebuilt from the same split the fence flags come from, so a CRLF document must not
# be shifted by one byte per line. Asserted by the resulting label rather than the number.
$crlfList = $fencedList -replace "`n", "`r`n"
$crlfOff = Get-ImpactInsertOffset -SectionText $crlfList -Score 3 -Tier 1
Assert-Equal '## #18 Real, tier 0' ((($crlfList.Substring($crlfOff)) -split "`r?`n")[0]).Trim() 'insert/fenced: a CRLF document lands in the same place -- the offsets keep step with the lines'

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
Assert-True ($sigText -match '(?m)^Score: 5$') 'sections: the score is its own line, echoing the retired Tier: line'
# The routing question is under EVERY tier 0 and 1, including one whose successor is already there. An
# author who has answered does not need it; a reader at the fold, the cut or in the record needs to see
# that it WAS asked.
Assert-Equal 1 (@([regex]::Matches($sigText, [regex]::Escape((Get-EntrySignificanceWording).Route0))).Count) 'sections: tier 0 carries its routing question even when tier 1 follows'
Assert-Equal 1 (@([regex]::Matches($sigText, [regex]::Escape((Get-EntrySignificanceWording).Route1))).Count) 'sections: and tier 1 carries its own'
Assert-True (-not ($sigText -match 'continue to Tier 3')) 'sections: tier 2 carries none -- there is no successor to route to'

# The scaffold: tier 0 alone, why placeholdered, score EMPTY. A scaffolded score would be a guess at a
# ranking, which is the failure the retired highlights marker was measured on.
$sigScaffold = (Format-EntrySignificanceSections) -join "`n"
Assert-True ($sigScaffold -match '(?m)^#### Tier 0$') 'scaffold: tier 0 is the only section'
Assert-True (-not ($sigScaffold -match '(?m)^#### Tier [12]$')) 'scaffold: no tier 1 or 2 -- not every change has one, which is why the table went'
Assert-True ($sigScaffold -match '(?m)^Score:\s*$') 'scaffold: the score is a question left standing, not a number nobody chose'

Write-Host "Resolve-EntryImpact reads three shapes and writes one" -ForegroundColor Cyan
$sigRound = Resolve-EntryImpact -EntryText ((Format-EntryBlock -Title 'T' -Type 'Feat' -Body 'b' -ImpactRows $sigRows) -join "`n")
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

Write-Host "A malformed section is reported rather than absorbed" -ForegroundColor Cyan
$badTier = "### Significance`n`n#### Tier two`n`nwhy`n`nScore: 3`n"
Assert-True (@((Resolve-EntryImpact -EntryText $badTier).Errors).Count -gt 0) 'a non-numeric tier is an error, not a section that silently vanishes'
$badScore = "### Significance`n`n#### Tier 0`n`nwhy`n`nScore: 9`n"
Assert-True (@((Resolve-EntryImpact -EntryText $badScore).Errors -match 'outside the rubric').Count -gt 0) 'a score outside the rubric is named as such'
$dupTier = "### Significance`n`n#### Tier 0`n`na`n`nScore: 1`n`n#### Tier 0`n`nb`n`nScore: 2`n"
Assert-True (@((Resolve-EntryImpact -EntryText $dupTier).Errors -match 'a second time').Count -gt 0) 'the same tier twice is two answers to one question'

Write-Host "Stripping the declaration for the documents that travel outward" -ForegroundColor Cyan
$sigBlock = (Format-EntryBlock -Title 'T' -Type 'Feat' -Body 'body text' -ImpactRows $sigRows) -join "`n"
$sigStripped = Remove-EntrySignificanceDeclaration -EntryText $sigBlock
Assert-True (-not ($sigStripped -match '#### Tier')) 'stripped: every tier section is gone, not just the first'
Assert-True (-not ($sigStripped -match '(?m)^Score:')) 'stripped: and the scores with them -- a self-assigned number at a consumer is a marketing claim'
Assert-True ($sigStripped -match [regex]::Escape((Get-EntrySectionHeading -Key 'Significance'))) 'stripped: the section heading stays, because the renderers lay out around it'
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
$freshFindings = @(Get-BranchProgressFindings -Text $freshScaffold)
Assert-Equal 1 $freshFindings.Count 'a freshly scaffolded list produces exactly one finding, not one per rule'
Assert-Equal 'still open' $freshFindings[0].Label 'and the open label wins, because that is the actionable one'

# The reset state carries NO steps, so a branch made by hand rather than by new-branch is not refused --
# the one-commit typo fix. Deliberate tolerance, asserted so it cannot be tightened by accident.
Assert-Equal 0 @(Get-BranchProgressFindings -Text ((Format-BranchProgressReset) -join "`n")).Count 'the reset state has nothing to resolve -- an absent plan is not a refusal'

# Fence-aware, like every reader of this format: this repo's own branch/README.md quotes all three marks
# while teaching them, and a step list may legitimately do the same.
$quoted = "## Steps`n`n- [x] documented the marks`n`n" + '```text' + "`n- [ ] not done yet`n" + '```' + "`n"
Assert-Equal 0 @(Get-BranchProgressFindings -Text $quoted).Count 'an open step QUOTED inside a fence is not an open step'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
