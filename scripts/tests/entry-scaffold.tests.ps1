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
Assert-Equal 'TODO: what still needs to happen on this branch, and where you left off.' $bare.BodyPlaceholder 'no getters: the default fallback body'

function Get-EntryTitlePlaceholder { return 'TE DOEN: titel' }
function Get-EntryBodyHeading { return '**Nog te doen:**' }
$overridden = Get-EntryScaffoldWording
Assert-Equal 'TE DOEN: titel' $overridden.Title 'override: the repo answer wins for the title'
Assert-Equal '**Nog te doen:**' $overridden.BodyHeading 'override: and for the body heading'
Assert-Equal 'TODO: what still needs to happen on this branch, and where you left off.' $overridden.BodyPlaceholder 'override: an unmentioned string keeps its default -- probed per key, not all-or-nothing'
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

$untouched = "### TODO: title $midDot Chore $midDot 2026-08-03`n`n**To do / where I left off:**`n`nTODO: what still needs to happen on this branch, and where you left off.`n"
$allThree = @(Get-EntryScaffoldFindings -EntryText $untouched -Wording $wording)
Assert-Equal 3 $allThree.Count 'a completely untouched scaffold produces all three findings'
Assert-True (@($allThree | ForEach-Object { $_.Label }) -contains 'the placeholder title') 'the placeholder title is named'
Assert-True (@($allThree | ForEach-Object { $_.Label }) -contains 'the scaffold body heading') 'the body heading is named'
Assert-True (@($allThree | ForEach-Object { $_.Label }) -contains 'the fallback body') 'the fallback body is named'
Assert-True ($allThree[0].Marker -is [string] -and $allThree[0].Marker.Length -gt 0) 'each finding carries the literal marker it matched, for the error message'

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

$writtenEntry = Join-Path $fixture 'feat-round-trip.md'
Assert-True (Test-Path -LiteralPath $writtenEntry) 'the writer produced an entry file in the fixture'
if (Test-Path -LiteralPath $writtenEntry) {
    $text = [System.IO.File]::ReadAllText($writtenEntry, [System.Text.Encoding]::UTF8)
    $roundTrip = @(Get-EntryScaffoldFindings -EntryText $text -Wording (Get-EntryScaffoldWording))
    Assert-True ($roundTrip.Count -gt 0) 'the matcher sees the writer output as scaffolded -- writer and guard share one source'
    Assert-Equal 3 $roundTrip.Count 'and it finds all three strings the writer wrote'
    # THE SAME ROUND TRIP FOR THE TIER LINE, and it is the assert that matters most for the tier model: the
    # writer, the validator (open-pr) and the fold all read this one format, and a real file written by the
    # real writer is the only thing that proves they agree. 'Tier: 0' is DECLARED, not merely defaulted --
    # the difference is what lets the fold tell "somebody chose 0" from "somebody forgot".
    $writtenTier = Resolve-EntryTier -EntryText $text
    Assert-Equal 0 $writtenTier.Tier 'the writer writes the harmless default tier'
    Assert-Equal $true $writtenTier.Declared 'and writes it as an explicit declaration, not an omission'
    Assert-Equal $null $writtenTier.Error 'the written line parses without complaint'
    # The line sits directly under the heading, where whoever edits the entry will meet it.
    $entryLines = @(($text -split "`r?`n") | Where-Object { $_.Trim() -ne '' })
    Assert-True ($entryLines[0] -match '^### ') 'the entry still opens with its heading'
    Assert-Equal (Format-EntryTierLine -Tier 0) $entryLines[1] 'and the tier line is the first thing under it'
    # It is NOT scaffold prose: 'Tier: 0' is a legitimate final value, so the gate must never treat it as
    # evidence of an unedited entry -- exactly the reasoning that keeps Get-EntryFallbackType out too.
    $tierAsFinding = @($roundTrip | Where-Object { $_.Marker -match 'Tier' })
    Assert-Equal 0 $tierAsFinding.Count 'the tier line is not one of the scaffold findings -- a low tier is a decision, not a stub'
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

Write-Host "the wiring (open-pr validates the tier, the fold consumes it)" -ForegroundColor Cyan
# Text asserts for the same reason as the scaffold gate above: open-pr drives a live push and gh.
Assert-True ($openPrText -match 'Resolve-EntryTier') 'open-pr resolves the entry tier'
Assert-True ($openPrText -match 'tier gate:') 'and reports under a named gate, so a block is attributable'
# NOT -Force-able, deliberately: -Force exists for text somebody legitimately wrote, and there is no
# legitimate 'Tier: 5'. Asserted by reading the refusal block rather than the whole file.
$tierGateIdx = $openPrText.IndexOf('tier gate:')
$tierGateBlock = $openPrText.Substring($tierGateIdx, [Math]::Min(900, $openPrText.Length - $tierGateIdx))
Assert-True ($tierGateBlock -notmatch '\$Force') 'the tier gate has no -Force escape -- a meaningless tier is never legitimate'
$foldText = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'scripts\release\fold-changelog-entry.ps1'))
Assert-True ($foldText -match 'entry-scaffold-lib\.ps1') 'the fold dot-sources the shared entry-format lib'
Assert-True ($foldText -match 'Resolve-EntryTier') 'the fold reads the tier'
Assert-True ($foldText -match 'Remove-EntryTierLine') 'and removes the line once the section states it'
Assert-True ($foldText -match 'Get-ChangelogTierSections') 'and asks the shared resolver which section that is'
# The tier must be resolved BEFORE anything is written, or a bad tier leaves a half-folded changelog.
Assert-True ($foldText.IndexOf('Nothing was folded') -lt $foldText.IndexOf('Write-Utf8NoBom -Path $changelogPath')) `
    'the pre-pass refusal sits before the first changelog write'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
