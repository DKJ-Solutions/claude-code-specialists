<#
.SYNOPSIS
    Regression tests for scripts/lib/release-lib.ps1 (the pure release helpers).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Dot-sources the lib and runs a series of
    asserts. Exit code 0 if everything passes, 1 on the first failure -- so usable as a CI gate.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/release-lib.tests.ps1

    Pure ASCII (repo convention for .ps1). Expected non-ASCII output characters (middot, em-dash)
    are built via [char]0x.. , just like in the lib itself.

    REWRITTEN FOR THE FLAT CHANGELOG (Dave, August 5, 2026), and rewritten rather than patched. Every
    fixture in the previous version was the old document shape -- '## Pull Requests' and '## Releases'
    sections, a release block, H3 entries carrying their type and date as heading fields -- and the
    machinery that varied which sections a repo declared existed to test a seam that is gone. Patching
    would have left a suite whose fixtures nothing in the repo writes any more, which passes by looking
    at a document that cannot occur.

    THE SHAPE UNDER TEST: CHANGELOG.md is an intro followed by ONE H2 PER CHANGE, each carrying three H3
    sections of its own ('What does this change do?', 'Who is this for' -- the impact table -- and 'Type
    of change'), with the 'Plugins:' line and the '[PR #NN](url) <middot> merged <date>' footer as plain
    lines at the end. New-FlatEntry below builds exactly that, and its own shape is asserted before the
    suite uses it.

    THE PRE-FORMAT SHAPE IS STILL TESTED, deliberately and in one direction only: this repo's whole
    history carries H3 entries whose type sits in the heading, the release documents are regenerated
    from that history, and every consumer's tree has the same. So the READERS are asserted on both
    shapes (Convert-EntryHeadingToTitle, Resolve-EntryImpact's 'Tier: N' fallback) while nothing here
    asserts that the writers still produce the old one. Recognise both, write one.

    NOTE (Sylvester, English script-layer sweep, #114 follow-up): both the DOCUMENT-GENERATING template
    strings this suite asserts against and the fixture sample strings (entry titles/bodies, link text)
    are English, matching release-lib.ps1's own follow-up -- see the NOTE in its file header. Fixture
    content is arbitrary stand-in text for contributor-authored PR entries; it is English for repo-wide
    consistency, not because its language is what is under test here.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\release-lib.ps1')

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

function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name (pattern '$Pattern' not found)" -ForegroundColor Red
    }
}

function Assert-NoMatch {
    param([string]$Text, [string]$Pattern, [string]$Name)
    Assert-Equal $false ([bool]($Text -match $Pattern)) $Name
}

function Assert-Throws {
    param([scriptblock]$Block, [string]$Name)
    try { & $Block; $script:fail++; Write-Host "  [FAIL] $Name (expected an exception)" -ForegroundColor Red }
    catch { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
}

function Assert-NoParameter {
    <#
        A retired parameter is asserted on its ABSENCE, not merely deleted from the calls. Every one of
        the parameters checked this way existed to describe the release block or the tier sections, so a
        caller passing one again means somebody is rebuilding a mechanism that was removed on purpose --
        which should turn a test red rather than be silently accepted and ignored.
    #>
    param([string]$Command, [string[]]$Names)
    $known = @((Get-Command $Command).Parameters.Keys)
    foreach ($n in $Names) {
        Assert-Equal $false ($known -contains $n) "$Command no longer takes -$n"
    }
}

$midDot = [char]0x00B7
$emDash = [char]0x2014

# ==================================================================================================
# THE FIXTURE BUILDER
# ==================================================================================================
# The entry shape is built from the format's OWN heading getters rather than from literals, for the
# reason documented at the live-overview assert further down: a test that restates a value the repo
# already answers passes by asserting against something nothing writes. The impact table's header IS
# written out, because its source is private to entry-scaffold-lib -- so the fixture's shape is
# asserted (via Resolve-EntryImpact) before anything else uses it.

function New-FlatEntry {
    <#
        One folded entry exactly as CHANGELOG.md carries it: the H2 heading the fold produced
        ('#22 <middot> A title'), the three named H3 sections, then the plain 'Plugins:' and PR lines.

        -Rows are the impact table's data rows; '' leaves the table out entirely, which is the
        pre-table entry (and, with -TierLine, the 'Tier: N' shape those entries carried).
    #>
    param(
        [Parameter(Mandatory)][string]$Heading,
        [string]$Body = 'What it does.',
        [string[]]$Rows = @('| 0 | - | - |'),
        [string]$Type = 'Feat',
        [string]$Plugins = '',
        [string]$TierLine = '',
        [int]$Pr = 0,
        [string]$ExtraBody = ''
    )
    $lines = @(('#' * (Get-EntryHeadingLevel)) + ' ' + $Heading, '')
    $lines += @((Get-EntrySectionHeading -Key 'What'), '')
    if ($TierLine) { $lines += @($TierLine, '') }
    $lines += $Body
    if ($ExtraBody) { $lines += @('', $ExtraBody) }
    $lines += @('', (Get-EntrySectionHeading -Key 'Significance'), '')
    if ($Rows.Count -gt 0 -and $Rows[0]) {
        $lines += @('| Tier | Significance | Why |', '|---|---|---|')
        $lines += $Rows
    } else {
        $lines += 'Nobody in particular.'
    }
    $lines += @('', (Get-EntrySectionHeading -Key 'Type'), '', $Type)
    if ($Plugins) { $lines += @('', "Plugins: $Plugins") }
    if ($Pr -gt 0) {
        $lines += @('', "[PR #$Pr](https://example.test/$Pr) $midDot merged 2026-08-05")
    }
    return (($lines -join "`n").Trim())
}

# THE SECTION NAMES COME FROM THE LIB, NOT FROM LITERALS IN THE ASSERTS. The fixture builder above already
# writes them that way; the asserts did not, so renaming two sections for the dossier form turned eight
# structural assertions ("the entry's sections sit one level under the entry") into failures about spelling.
# What those asserts are actually about is the LEVEL and the NESTING, and neither depends on the wording.
$WhatRx = [regex]::Escape((Get-EntrySectionHeadings)['What'])
$TypeRx = [regex]::Escape((Get-EntrySectionHeadings)['Type'])

# AND SO DO THE LEVELS, for exactly the same reason one paragraph up. The fixture builder has always composed
# its heading and section levels from the lib; the asserts wrote them out as '##' and '###', so shifting both
# pairs one level down on August 26, 2026 turned fourteen structural assertions into failures about depth. What
# each of them is about is the RELATIONSHIP -- an entry's own heading, its sections one under that -- and the
# absolute number was never the subject. Written as hash runs rather than counts because that is what the
# asserts splice into regexes.
$EntryH   = '#' * (Get-EntryHeadingLevel)
$EntryS   = '#' * (Get-EntrySectionLevel)
# One level SHALLOWER than an entry: what '## [Unreleased]' occupies, and what an entry written between
# August 5 and August 26, 2026 carries. Used by the legacy-shape asserts.
$EntryLeg = '#' * ((Get-EntryHeadingLevel) - 1)

function New-FlatChangelog {
    <# An intro plus the given entry blocks, '---'-separated, as the fold leaves the document. #>
    param([string[]]$Entries, [string]$Intro = '')
    $head = if ($Intro) { $Intro } else {
        @('# Changelog', '',
          'Everything merged since the last release, furthest reach first. Every release ever cut is',
          'listed in [releases/README.md](releases/README.md).') -join "`n"
    }
    return ($head + "`n`n" + (($Entries -join "`n`n---`n`n")) + "`n")
}

Write-Host "the fixture builder produces what the parsers expect" -ForegroundColor Cyan
# ASSERTED BEFORE IT IS USED, and that is not ceremony: this file has already paid once for a fixture
# that did not contain what it was written to contain (the em-dash heading split across three lines by
# the comma operator), and every assert in that section was running against a document nobody wrote.
$probe = New-FlatEntry -Heading "#99 $midDot A probe" -Rows @('| 2 | 4 | consumers notice |', '| 1 | 3 | colleagues too |') -Pr 99
Assert-Match $probe ('(?m)^' + $EntryH + ' #99 ') 'fixture: the entry heading is at the entry level'
Assert-Equal 3 (@([regex]::Matches($probe, ('(?m)^' + $EntryS + ' '))).Count) 'fixture: it carries exactly three sections at the section level'
$probeImpact = Resolve-EntryImpact -EntryText $probe
Assert-Equal $true $probeImpact.Table 'fixture: the impact table is found by the real parser'
Assert-Equal 2 $probeImpact.Tier 'fixture: and reads back the tier the rows declare'
Assert-Equal 4 (Get-EntryImpactScore -Impact $probeImpact -Tier 2) 'fixture: with the tier-2 score'
Assert-Equal 3 (Get-EntryImpactScore -Impact $probeImpact -Tier 1) 'fixture: and the tier-1 score'
Assert-Equal 'Feat' (Resolve-EntryType -EntryText $probe).Type 'fixture: the type section reads back'
Assert-Equal 0 @(($probe -split "`n") | Where-Object { $_.Trim() -eq $midDot -or $_.Trim() -eq $emDash }).Count 'fixture: no line consists of a bare separator'

Write-Host "Get-NextVersion" -ForegroundColor Cyan
Assert-Equal '0.2.0' (Get-NextVersion -Current '0.1.0' -BumpKind 'minor') 'minor bumps the second digit, zeroes patch'
Assert-Equal '0.1.1' (Get-NextVersion -Current '0.1.0' -BumpKind 'patch') 'patch bumps the third digit'
Assert-Equal '1.0.0' (Get-NextVersion -Current '0.9.9' -BumpKind 'major') 'major zeroes minor + patch'
Assert-Throws { Get-NextVersion -Current 'x.y.z' -BumpKind 'patch' } 'invalid current version throws'

Write-Host "Get-BumpType" -ForegroundColor Cyan
Assert-Equal 'major' (Get-BumpType -From '0.1.0' -To '1.0.0') '0.1.0->1.0.0 = major'
Assert-Equal 'minor' (Get-BumpType -From '1.0.0' -To '1.1.0') '1.0.0->1.1.0 = minor'
Assert-Equal 'patch' (Get-BumpType -From '1.1.0' -To '1.1.1') '1.1.0->1.1.1 = patch'

Write-Host "Get-LockstepVersion" -ForegroundColor Cyan
Assert-Equal '0.1.0' (Get-LockstepVersion -ManifestContents @{ a = '{"version": "0.1.0"}'; b = '{"version": "0.1.0"}' }) 'equal versions -> that version'
Assert-Throws { Get-LockstepVersion -ManifestContents @{ a = '{"version": "0.1.0"}'; b = '{"version": "0.2.0"}' } } 'unequal versions throws'
Assert-Throws { Get-LockstepVersion -ManifestContents @{ a = '{"name": "x"}' } } 'missing version throws'

# ==================================================================================================
# THE SHARED SAMPLE DOCUMENT
# ==================================================================================================
# Two entries, ranked as the fold left them: the tier-2 one first, the tier-1 one after it. Used by
# everything below, so a difference in output is a difference in the call rather than in the input.
$e22 = New-FlatEntry -Heading "#22 $midDot Consumer feature" -Body 'Body twenty-two.' `
    -Rows @('| 2 | 5 | consumers must re-add the marketplace |', '| 1 | 4 | the team stops doing it by hand |') `
    -Type 'Feat' -Plugins 'team-alpha' -Pr 22
$e21 = New-FlatEntry -Heading "#21 $midDot For colleagues only" -Body 'Body twenty-one.' `
    -Rows @('| 1 | 2 | a small convenience |') -Type 'Fix' -Pr 21
$e20 = New-FlatEntry -Heading "#20 $midDot Repo housekeeping" -Body 'Body twenty.' `
    -Rows @('| 0 | - | - |') -Type 'Chore' -Pr 20
$sample = New-FlatChangelog -Entries @($e22, $e21, $e20)

Write-Host "Get-EntryHeadingPattern -- the exact level, not a range" -ForegroundColor Cyan
# THE ONE DECISION IN THE PARSER THAT CANNOT BE LOOSENED. An entry carries H3 sections of its own, so a
# pattern accepting H3 as well reads every entry as four -- in well-formed markdown, with no error.
$rx = Get-EntryHeadingPattern
Assert-Equal $true  (($EntryH + ' #22 x') -match $rx) 'the entry level matches'
Assert-Equal $false (($EntryS + ' What does this change do?') -match $rx) 'a section-level heading does NOT match -- otherwise one entry reads as four'
Assert-Equal $false ('# Changelog' -match $rx) 'the document title does not match either'
Assert-Equal 3 (Get-EntryHeadingLevel) 'the level is 3, read from the format rather than counted here'

Write-Host "Get-FencedLineFlags -- one owner, reached from here through the lib below" -ForegroundColor Cyan
# THE FUNCTION MOVED DOWN A LAYER and this whole block is the proof that the move is invisible from here:
# every assert below is the one that ran when release-lib defined it itself, unchanged. It is in scope
# because this file dot-sources entry-scaffold-lib unconditionally -- so a broken import fails loudly here
# rather than at a release.
#
# WHY IT MOVED: there were four fence walks across the two libs and they were not equivalent -- only this
# lib's recognised '~~~', so an entry with tilde fences had its quoted content read as STRUCTURE by every
# reader in entry-scaffold-lib while the readers here handled it correctly. The tilde behaviour and the
# absence of a second definition are asserted in that lib's own suite, where the owner now lives.
Assert-Equal $null (Get-Command Get-FencedLineFlags -CommandType Function -ErrorAction SilentlyContinue |
    Where-Object { $_.ScriptBlock.File -and $_.ScriptBlock.File.EndsWith('release-lib.ps1') }) 'the fence reader is no longer defined by release-lib itself'
Assert-Equal $true ($null -ne (Get-Command Get-FencedLineFlags -ErrorAction SilentlyContinue)) 'but dot-sourcing release-lib still brings it into scope, so no call site changed'
$fenceLines = @('## real', 'text', '```', '## QUOTED', '---', '```', '---', '## real2')
$fenceFlags = Get-FencedLineFlags -Lines $fenceLines
Assert-Equal $false $fenceFlags[0] 'flags: a heading outside a fence is not fenced'
Assert-Equal $true  $fenceFlags[2] 'flags: the opening marker belongs to the block'
Assert-Equal $true  $fenceFlags[3] 'flags: a heading inside a fence IS fenced'
Assert-Equal $true  $fenceFlags[4] 'flags: a separator inside a fence IS fenced'
Assert-Equal $true  $fenceFlags[5] 'flags: the closing marker belongs to the block'
Assert-Equal $false $fenceFlags[6] 'flags: back outside after the fence closes'
Assert-Equal $false $fenceFlags[7] 'flags: a heading after the fence is not fenced'
# An unclosed fence leaves the tail flagged -- the safe direction, since it stops the parser
# inventing structure out of code.
$openFlags = Get-FencedLineFlags -Lines @('text', '```', '## QUOTED')
Assert-Equal $true $openFlags[2] 'flags: an unclosed fence keeps the tail fenced (safe direction)'
# A section can legitimately be a single empty line; a Mandatory [string[]] used to reject that.
Assert-Equal 1 (@(Get-FencedLineFlags -Lines @('')).Count) 'flags: an empty line binds without throwing'

Write-Host "Split-Changelog -- no sections at all" -ForegroundColor Cyan
$s = Split-Changelog -Content $sample
Assert-Equal 3 $s.Entries.Count 'every entry block below the intro is collected'
Assert-Match $s.Entries[0] ('^' + $EntryH + ' #22 ') 'the first entry is the first one in the document'
Assert-Match $s.Entries[2] ('^' + $EntryH + ' #20 ') 'and the last is the last'
Assert-Equal 'listed in [releases/README.md](releases/README.md).' $s.Head[-1] 'the head stops at the first entry heading, trailing blank stripped'
Assert-Equal "`n" $s.Nl 'an LF document reports LF'
Assert-Equal "`r`n" (Split-Changelog -Content ($sample -replace "`n", "`r`n")).Nl 'and a CRLF document reports CRLF'

# --- '## [Unreleased]' IS PART OF THE HEAD, which is what buys the fold and the cut their behaviour for
#     free (Dave, August 26, 2026). It sits one level shallower than an entry, so this splitter's boundary --
#     "the first entry heading" -- lands BELOW it without knowing it exists. Two consequences follow, and
#     both are asserted rather than described: a cut writes the head back, so the pending heading survives
#     with no entries under it; and a fold inserts at the top of the entry list, which is directly beneath
#     it. Neither needed a rule of its own, and this is the assert that says so -- if the pending heading
#     ever drifts to the entry level, the fold starts inserting above it and the cut starts deleting it.
Write-Host "'## [Unreleased]' sits in the head, not in the entries" -ForegroundColor Cyan
$pendDoc = New-FlatChangelog -Entries @($e22, $e21) -Intro (
    @('# Changelog', '', 'An intro.', '', (Get-ChangelogUnreleasedHeading)) -join "`n")
$pendSplit = Split-Changelog -Content $pendDoc
Assert-Equal (Get-ChangelogUnreleasedHeading) $pendSplit.Head[-1] 'the pending heading is the LAST line of the head, so a cut that rewrites the head keeps it'
Assert-Equal 2 $pendSplit.Entries.Count 'and it is not counted as one of the entries'
Assert-Match $pendSplit.Entries[0] ('^' + $EntryH + ' #22 ') 'the first entry is still the first real entry -- the fold inserts here, directly under the pending heading'
Assert-Equal ((Get-EntryHeadingLevel) - 1) (Get-ChangelogUnreleasedLevel) 'the pending heading sits exactly one level above an entry -- the property all of the above rests on'

# THE INVARIANT THE WHOLE SHIFT TURNS ON, asserted in the lib that folds and the lib that cuts. DEPLOY is a
# phase of the cycle document AND the entry pasted into CHANGELOG.md, so the fold is a verbatim paste only
# while those two levels are one number. Nothing held them together before August 26, 2026 -- they merely
# happened to agree, so re-levelling either alone would have silently restored per-document re-levelling.
Assert-Equal (Get-EntryHeadingLevel) (Get-BranchCycleSectionLevel) 'the cycle document DEPLOY phase and a changelog entry sit at ONE level -- what makes the fold a paste rather than a re-level'

# AND THE CUT LEAVES IT STANDING, which is the other half of the same property. Convert-ChangelogForRelease
# keeps the head and drops every entry, so the pending heading survives with nothing under it -- a fresh
# empty section rather than a bare intro somebody has to re-add a heading to. Asserted on the function rather
# than reasoned from the head assert above, because "the head is kept" is the claim that could change.
$pendReset = Convert-ChangelogForRelease -Content $pendDoc
Assert-Match $pendReset ('(?m)^' + [regex]::Escape((Get-ChangelogUnreleasedHeading)) + '$') 'a cut leaves a fresh pending heading behind, not a bare intro'
Assert-NoMatch $pendReset ('(?m)^' + $EntryH + ' #22 ') 'and the entries it released are gone from it'
# THE SEAM IS GONE, not merely unused: there is no map left to ask which headings count.
Assert-NoParameter -Command 'Split-Changelog' -Names @('TierSections', 'FallbackHeading', 'TierHeadings')
Assert-Equal $null (Get-Command 'Resolve-ChangelogTierSections' -ErrorAction SilentlyContinue) 'Resolve-ChangelogTierSections is retired with the sections it resolved'

# AN ENTRY'S OWN SECTIONS STAY INSIDE IT. This is the assert that catches "one entry rendering as
# four", which is well-formed markdown and therefore invisible to an eye.
Assert-Equal 3 (@([regex]::Matches($s.Entries[0], ('(?m)^' + $EntryS + ' '))).Count) "the entry keeps its three sections at the section level rather than being split at them"
Assert-Match $s.Entries[0] '(?m)^\[PR #22\]' 'and its PR footer'
Assert-Match $s.Entries[0] '(?m)^Plugins: team-alpha$' 'and its Plugins line'
# The '---' separators between entries are structure, not content.
Assert-NoMatch $s.Entries[0] '(?m)^---\s*$' 'the separator between entries is not carried into an entry'

# A PRE-FORMAT H3 ENTRY IS NOT A BOUNDARY, and that is exactly why the fold promotes one to H2 before
# pasting it in: left at H3 it is absorbed into the entry above and inherits that entry's PR link.
$withH3 = New-FlatChangelog -Entries @($e22 + "`n`n$EntryS #7 $midDot An older entry $midDot Fix $midDot 2026-01-01`n`nBody seven.")
Assert-Equal 1 (Split-Changelog -Content $withH3).Entries.Count 'a heading deeper than the entry level is absorbed, not counted -- the reason the fold promotes it'

Write-Host "Split-Changelog -- fenced code is not structure" -ForegroundColor Cyan
# TWO PLACES IT MATTERS, and the first is new with the flat model: the INTRO. This repo's own changelog
# documents the entry format, so its intro quotes an entry heading inside a fence -- and the boundary
# between intro and entries is now derived from the first entry heading, so a fence-blind scan would
# put that boundary inside a code block and turn the rest of the intro into entry one.
$introQuotes = @(
    '# Changelog', '',
    'Every change is an H2, like this:', '',
    '```', '## #1 ' + $midDot + ' An example', '', '### What does this change do?', '```', ''
) -join "`n"
$fencedIntro = Split-Changelog -Content (New-FlatChangelog -Entries @($e21) -Intro $introQuotes)
Assert-Equal 1 $fencedIntro.Entries.Count 'an intro that quotes an entry heading in a fence does not move the boundary'
Assert-Match $fencedIntro.Entries[0] ('^' + $EntryH + ' #21 ') 'the real first entry is still the first entry'
Assert-Match (($fencedIntro.Head -join "`n")) '(?m)^## #1 ' 'and the quoted heading stayed in the head, inside its fence'

# And the second: an entry body that quotes a heading -- the v2.13.3 defect, at the new level. Also
# covers the '---' separator inside a fence, which would otherwise strip a frontmatter example.
$quoted = @(
    'Shows what a broken structure looks like:', '',
    '```', '## #99 ' + $midDot + ' quoted heading', '---', 'id: 1', '```'
) -join "`n"
$e11 = New-FlatEntry -Heading "#11 $midDot Real entry" -Rows @('| 1 | 2 | fine |') -Pr 11 -ExtraBody $quoted
$fencedDoc = Split-Changelog -Content (New-FlatChangelog -Entries @($e11, $e21))
Assert-Equal 2 $fencedDoc.Entries.Count 'fenced: two entries, not three -- the quoted heading is not a new entry'
Assert-Match $fencedDoc.Entries[0] ('^' + $EntryH + ' #11 ') 'fenced: the first entry is the real one'
Assert-Match $fencedDoc.Entries[0] '## #99' 'fenced: the quoted heading is KEPT inside the entry body'
Assert-Match $fencedDoc.Entries[0] '(?m)^id: 1$' 'fenced: a --- inside the fence does not strip the lines after it'
Assert-Equal 2 (@([regex]::Matches($fencedDoc.Entries[0], '(?m)^```')).Count) 'fenced: the fence survives intact (both markers present)'
Assert-Match $fencedDoc.Entries[1] ('^' + $EntryH + ' #21 ') 'fenced: the second entry is the next real one'

Write-Host "Split-Changelog -- nothing to release" -ForegroundColor Cyan
# THIS REPLACES TWO RETIRED REFUSALS ("could not find the heading" and "this repo declares no section
# for tier N"), and it is the only one left: with no heading name to look up there is nothing to
# mismatch, so the single remaining error is the substantive one.
Assert-Throws { Split-Changelog -Content "# Changelog`n`nOnly an intro, nothing merged.`n" } 'an intro with no entry throws -- a cut would describe nothing'
$emptyErr = ''
try { Split-Changelog -Content "# Changelog`n`nNothing.`n" } catch { $emptyErr = $_.Exception.Message }
Assert-Match $emptyErr 'nothing to release' 'and the message says what is wrong rather than naming a heading'
Assert-Match $emptyErr ('H' + (Get-EntryHeadingLevel)) 'and states where an entry is expected'

Write-Host "Split-Changelog -- a leftover section heading is refused, not released" -ForegroundColor Cyan
# THE CONSUMER DEFECT THIS GUARDS, measured on both pre-flat shapes before the guard existed. Every '## '
# below the intro is read as one change now, and a document still carrying the old shape has headings at
# exactly that level -- reached through a plugin update rather than by that repo's choosing:
#
#   * single-section: '## Pull Requests' parsed as ONE entry swallowing every real entry, and '## Releases'
#     as a second -- so the whole release history was published outward as a "change" and then DELETED,
#     because the cut keeps only the intro;
#   * tier sections: three entries named after the three headings.
#
# AND NOTHING REFUSED: blocks like that declare no impact, so the bump gate reads the repo as never having
# adopted the model and reports itself inactive -- correctly, by its own rule -- and the release proceeds.
$legacySingle = @(
    '# Changelog', '', 'Intro of the file.', '',
    '## Pull Requests', '', 'Merged PRs land here.', '',
    "### #31 $midDot A consumer feature $midDot Feat $midDot 2026-07-01", '', 'Body 31.', '',
    '## Releases', '', 'Rel intro.', '', "### [v2.4.0] - 2026-06-01 $emDash Minor", ''
) -join "`n"
$legacyErr = ''
try { Split-Changelog -Content $legacySingle } catch { $legacyErr = $_.Exception.Message }
Assert-Match $legacyErr 'are neither an entry nor the pending section' 'a pre-flat single-section document is refused rather than parsed'
Assert-Match $legacyErr ([regex]::Escape("'## Pull Requests'")) 'and the refusal names the offending block'
Assert-Match $legacyErr ([regex]::Escape("'## Releases'")) 'including the release history, which the cut would have deleted'
Assert-Match $legacyErr 'Migrate the document first' 'and says what to do about it'
$legacyTiers = @(
    '# Changelog', '', 'Intro.', '',
    '## Tier 2 - Pull Requests', '', 'What a consumer notices.', '',
    "### #41 $midDot Something $midDot Feat $midDot 2026-07-01", '', 'Body 41.', '',
    '## Tier 1 - Pull Requests', '', 'What colleagues get.', ''
) -join "`n"
Assert-Throws { Split-Changelog -Content $legacyTiers } 'a document still carrying the tier sections is refused too'
# BOTH LEGITIMATE SHAPES STILL PASS, which is what makes the discriminator exact rather than a heuristic.
Assert-Equal 3 (Split-Changelog -Content $sample).Entries.Count 'the current format passes: the three named sections are the declaration'
$preFormatDoc = New-FlatChangelog -Entries @(
    "## #99 $midDot An entry from before the format $midDot Fix $midDot 2026-08-01`n`nBody prose, no named sections.")
Assert-Equal 1 (Split-Changelog -Content $preFormatDoc).Entries.Count 'a pre-format entry passes: it declares its type in its heading'
# AND IT IS NOT KEYED ON THE '#NN', deliberately: the fold cannot reach gh on a manual merge and then writes
# a legitimate entry with no number, saying so on the console. A gate keying on the number would report the
# fold's own documented output as a defect.
$noPrDoc = New-FlatChangelog -Entries @((New-FlatEntry -Heading 'An entry with no PR number' -Rows @('| 1 | 2 | fine |')))
Assert-Equal 1 (Split-Changelog -Content $noPrDoc).Entries.Count 'an entry with no PR number passes -- the manual-merge fold'
# The predicate itself, from both directions.
Assert-Equal $true  (Test-EntryDeclaresShape -EntryText $e22) 'Test-EntryDeclaresShape: a current entry declares its sections'
Assert-Equal $true  (Test-EntryDeclaresShape -EntryText "## #99 $midDot A title $midDot Fix`n`nBody.") 'a pre-format entry declares its type in the heading'
Assert-Equal $false (Test-EntryDeclaresShape -EntryText "## Pull Requests`n`nMerged PRs land here.") 'a section heading with prose under it declares nothing'
Assert-Equal $false (Test-EntryDeclaresShape -EntryText "## Releases`n`nThe recorded versions.") 'and so does a release-history heading'
# Fence-aware, so an entry that DOCUMENTS the format is judged by its real declaration rather than by the
# one it quotes -- and the mirror image: a block whose only sections are quoted is still not an entry.
Assert-Equal $false (Test-EntryDeclaresShape -EntryText "## Pull Requests`n`nThe shape is:`n`n``````text`n### Type of change`n``````") 'a quoted section heading does not make a section heading into an entry'

Write-Host "Get-PullRequestEntries -- document order IS the fold's ranking" -ForegroundColor Cyan
$entries = @(Get-PullRequestEntries -Content $sample)
Assert-Equal 3 $entries.Count 'three entries extracted'
Assert-Match $entries[0] '^## #22 ' 'first entry first'
Assert-Match $entries[0] '\[PR #22\]' 'first entry contains the PR link'
# THE FUNCTION MUST NOT SORT, and this is the assert that says so. The fold placed each entry at its
# ranked position when it landed -- the cut empties the list, so document order at cut time is what the
# release documents inherit. A "helpful" re-sort here would be a second opinion formed from the same
# numbers, and PowerShell's Sort-Object is not stable, so it could differ from the published one.
$outOfOrder = New-FlatChangelog -Entries @($e20, $e22)   # tier 0 first, tier 2 second
$keptOrder = @(Get-PullRequestEntries -Content $outOfOrder)
Assert-Match $keptOrder[0] '^## #20 ' 'a lower-ranked entry sitting first STAYS first -- the parser does not re-rank'

Write-Host "Get-PullRequestEntriesByTier -- the tier comes from the entry" -ForegroundColor Cyan
# THE REVERSAL THIS CHANGE IS ABOUT. This function's own header used to say deriving the tier from the
# entry was impossible on purpose, because the fold consumed the declaration the moment the section
# heading took over stating it. With no sections the fold consumes nothing and the entry is the carrier.
$byTier = @(Get-PullRequestEntriesByTier -Content $sample)
Assert-Equal 3 $byTier.Count 'one group per tier present'
Assert-Equal 2 $byTier[0].Tier 'highest tier first'
Assert-Equal 'Tier 2 - consumers' $byTier[0].Heading 'the group carries the heading a release document gives it'
Assert-Equal 1 $byTier[0].Entries.Count 'tier 2 holds the entry that claimed it'
Assert-Match $byTier[0].Entries[0] '^## #22 ' 'and it is the right one'
Assert-Equal 1 $byTier[1].Tier 'tier 1 second'
Assert-Equal 0 $byTier[2].Tier 'tier 0 last'
# GROUPED ON THE HIGHEST TIER CLAIMED, so the groups stay DISJOINT. #22 declares tier 2 AND tier 1; it
# belongs to the tier-2 group only, or the record would hold it twice.
Assert-Equal 1 $byTier[1].Entries.Count 'the entry claiming both tiers appears ONCE, in its highest group'
Assert-Match $byTier[1].Entries[0] '^## #21 ' 'so tier 1 holds only the entry whose highest claim is tier 1'
Assert-Equal 3 (@($byTier | ForEach-Object { $_.Entries }).Count) 'every entry is in exactly one group'

Write-Host "Get-PullRequestEntriesByTier -- Declared is a measurement, not bookkeeping" -ForegroundColor Cyan
# IT IS WHAT TELLS AN ADOPTING REPO FROM ONE THAT NEVER HEARD OF TIERS. An entry with no declaration
# reads as tier 0 exactly like a declared tier-0 entry, and the bump gate has to tell those apart or it
# refuses every release a non-adopting consumer ever cuts.
Assert-Equal 1 $byTier[2].Declared 'a declared tier-0 row counts as declared'
$noDecl = New-FlatEntry -Heading "#40 $midDot Says nothing" -Rows @('') -Type 'Docs' -Pr 40
$undeclared = @(Get-PullRequestEntriesByTier -Content (New-FlatChangelog -Entries @($noDecl)))
Assert-Equal 0 $undeclared[0].Tier 'an entry with no table reads as tier 0'
Assert-Equal 0 $undeclared[0].Declared 'but is NOT counted as declared -- the distinction the gate needs'
# The pre-table shape: 'Tier: N' is still read, and always will be. Every entry already in this
# repo's CHANGELOG.md and in every consumer's tree predates the table.
$legacyTier = New-FlatEntry -Heading "#41 $midDot Pre-table entry" -Rows @('') -TierLine 'Tier: 2' -Pr 41
$legacyGroups = @(Get-PullRequestEntriesByTier -Content (New-FlatChangelog -Entries @($legacyTier)))
Assert-Equal 2 $legacyGroups[0].Tier "the older 'Tier: N' line is still honoured"
Assert-Equal 1 $legacyGroups[0].Declared 'and counts as a declaration'

Write-Host "Convert-ChangelogForRelease -- it empties the document, and writes nothing" -ForegroundColor Cyan
# EVERY PARAMETER EXCEPT THE CONTENT IS GONE, because every one of them described a release block that
# no longer exists. Asserted on absence, so a caller cannot pass one and have it quietly ignored.
Assert-NoParameter -Command 'Convert-ChangelogForRelease' `
    -Names @('Version', 'Date', 'Type', 'NotesRelPath', 'LiveMarker', 'HistoryMode', 'HistoryRelPath', 'TierSections', 'Wording')
$emptied = Convert-ChangelogForRelease -Content $sample
Assert-Match $emptied '(?m)^# Changelog$' 'the title survives'
Assert-Match $emptied 'listed in \[releases/README\.md\]' "the intro's own pointer to the release history survives"
Assert-NoMatch $emptied '(?m)^## ' 'no entry heading is left'
foreach ($pr in 20, 21, 22) {
    Assert-NoMatch $emptied "#$pr $midDot" "entry #$pr is cleared out of the changelog"
}
# NOTHING IS WRITTEN IN THEIR PLACE. The release block is gone, so a cut leaves an intro and that is all
# -- asserted on the absence of every trace it used to leave.
Assert-NoMatch $emptied 'Latest Release' 'no release block heading is written'
Assert-NoMatch $emptied '(?m)^\*\*v\d' 'no bold version line'
Assert-NoMatch $emptied 'for the full release notes' 'and no pointer to a notes file'
# THE INTRO IS NOT REGENERATED -- it is the head as the document had it, which is what lets a repo say
# whatever it likes up there, in whatever language, and keep it across every cut.
$ownIntro = "# Journal de bord`n`nTout ce qui a ete fusionne depuis la derniere version."
Assert-Match (Convert-ChangelogForRelease -Content (New-FlatChangelog -Entries @($e21) -Intro $ownIntro)) `
    'Tout ce qui a ete fusionne' "a repo's own intro passes through verbatim -- no template rewrites it"
# CRLF is preserved: the root CHANGELOG is CRLF and a cut must not restyle the whole file.
$crlfOut = Convert-ChangelogForRelease -Content ($sample -replace "`n", "`r`n")
Assert-Match $crlfOut "`r`n" 'a CRLF document stays CRLF'

# BLANK LINES MUST NOT ACCUMULATE. The head as read ends with the blank separating it from the first
# heading and the caller adds its own, so every cut used to leave one more than the last (measured 2, 3,
# 4 over three cuts). It renders identically in markdown, which is exactly why nothing would look wrong.
# Asserted by cutting the OUTPUT again, not by inspecting one run.
function Get-TrailingBlanks([string]$text) {
    $l = @($text -split "`r?`n")
    $n = 0; $i = $l.Count - 1
    while ($i -ge 0 -and $l[$i].Trim() -eq '') { $n++; $i-- }
    return $n
}
$cut1 = Convert-ChangelogForRelease -Content $sample
$cut2 = Convert-ChangelogForRelease -Content ($cut1 + "`n" + $e21 + "`n")
Assert-Equal (Get-TrailingBlanks $cut1) (Get-TrailingBlanks $cut2) 'blank lines: a second cut leaves the same trailing gap as the first -- they do not accumulate'
Assert-Equal 1 (Get-TrailingBlanks $cut1) 'blank lines: and that gap is a single closing newline'

Write-Host "Set-EntryHeadingLevel -- the whole block shifts, not the first line" -ForegroundColor Cyan
# THE DEFECT THIS EXISTS FOR: re-levelling only the entry heading leaves its three H3 sections at the
# level of the entry ABOVE them -- one entry rendering as four, in markdown no parser complains about.
$shifted = Set-EntryHeadingLevel -EntryText $e22 -EntryLevel 3
Assert-Match $shifted '^### #22 ' 'the entry heading lands at the requested level'
Assert-Equal 3 (@([regex]::Matches($shifted, '(?m)^#### ')).Count) 'and its three sections moved with it, to one level below'
Assert-NoMatch $shifted ('(?m)^### ' + $WhatRx) 'no section is left at the entry level'
# SHIFTED BY A DELTA, so structure inside the entry survives whatever it is.
$withSub = New-FlatEntry -Heading "#50 $midDot Nested" -ExtraBody "#### A sub-heading in the body"
$deep = Set-EntryHeadingLevel -EntryText $withSub -EntryLevel 3
Assert-Match $deep '(?m)^##### A sub-heading in the body$' 'an H4 in a body keeps its relative depth'
# A delta of 0 changes nothing but the newline style.
Assert-Equal ($e22 -replace "`r`n", "`n") (Set-EntryHeadingLevel -EntryText $e22 -EntryLevel 2) 'a delta of 0 returns the block unchanged'
# THE DELTA IS MEASURED FROM THE BLOCK, NOT ASSUMED TO BE CANONICAL. It used to be computed as
# '$EntryLevel - Get-EntryHeadingLevel', which is the shift a block ALREADY at the canonical level needs --
# true of every caller in this file, since they read entries straight out of CHANGELOG.md, and false for
# the one caller that reads them back out of a rendered document. Normalising a deeper block to canonical
# computed a delta of ZERO and returned it untouched, silently: measured on new-internal-note.ps1, where
# every bullet came out without its type because the sections of the block handed to Resolve-EntryType were
# still one level below where that reader looks.
$deeper = Set-EntryHeadingLevel -EntryText $e22 -EntryLevel 3     # canonical -> deeper, as a renderer does
Assert-Match $deeper '(?m)^### #22 ' 'a canonical block still renders deeper'
$backAgain = Set-EntryHeadingLevel -EntryText $deeper -EntryLevel 2
Assert-Match $backAgain '(?m)^## #22 ' 'and a DEEPER block normalises back to canonical -- the case that silently did nothing'
Assert-Equal 3 (@([regex]::Matches($backAgain, '(?m)^### ')).Count) 'with its three sections coming back with it'
Assert-Equal ($e22 -replace "`r`n", "`n") $backAgain 'the round trip is lossless, which is what makes the reader downstream able to trust it'
# A block with no heading at all has nothing to measure from: returned normalised, not guessed at.
Assert-Equal "Just prose.`n`nMore prose." (Set-EntryHeadingLevel -EntryText "Just prose.`r`n`r`nMore prose." -EntryLevel 4) 'a block with no heading is left alone apart from the newline normalisation'
Assert-NoMatch (Set-EntryHeadingLevel -EntryText ($e22 -replace "`n", "`r`n") -EntryLevel 2) "`r" 'and normalizes CRLF to LF either way'
# FENCE-AWARE: an entry documenting the entry format quotes these headings, and shifting a quoted one
# corrupts the example.
$shiftedQuote = Set-EntryHeadingLevel -EntryText $e11 -EntryLevel 3
Assert-Match $shiftedQuote '(?m)^## #99 ' 'a heading quoted inside a fence is NOT shifted'
# CLAMPED AT H6, which markdown has no level beyond: the line stays a heading rather than becoming
# literal '#######' text.
$clamped = Set-EntryHeadingLevel -EntryText "## Top`n`n###### Already deep" -EntryLevel 6
Assert-Match $clamped '(?m)^###### Top$' 'the entry heading reaches H6'
Assert-Match $clamped '(?m)^###### Already deep$' 'and a heading that would pass H6 is clamped, not turned into text'

Write-Host "Format-RankedEntries -- one flat list, no categories" -ForegroundColor Cyan
# IT REPLACES Format-CategorizedEntries, AND THE DELETION IS THE POINT. That renderer grouped entries
# under headings derived from the BRANCH PREFIX, which this repo measured does not predict impact: at
# v3.2.0 the single most consequential change for a consumer arrived on a chore/ branch and was filed
# third under 'Maintenance'. Asserted on absence for the same reason as the retired HTML renderer --
# re-adding it should turn a test red rather than pass unnoticed.
foreach ($gone in @('Format-CategorizedEntries', 'Get-ReleaseCategories')) {
    Assert-Equal $null (Get-Command $gone -ErrorAction SilentlyContinue) "release-lib no longer defines $gone"
}
$flat = Format-RankedEntries -Entries @($e22, $e21) -EntryLevel 2
Assert-Match $flat '(?m)^## #22 ' 'the first entry sits at the requested level'
Assert-Match $flat '(?m)^## #21 ' 'and so does the second'
Assert-Match $flat '(?s)## #22 .*\n---\n.*## #21 ' 'entries are separated by a horizontal rule'
foreach ($label in 'Features', 'Fixes', 'Documentation', 'Maintenance', 'Other') {
    Assert-NoMatch $flat "(?m)^#+ $label$" "no '$label' category heading is invented"
}
Assert-NoMatch $flat "`r" 'output is pure LF even though an entry may arrive CRLF'
Assert-Match (Format-RankedEntries -Entries @(($e22 -replace "`n", "`r`n")) -EntryLevel 2) '(?m)^## #22 ' 'a CRLF entry is still parsed'
Assert-Equal '' (Format-RankedEntries -Entries @() -EntryLevel 2) 'an empty list renders as nothing rather than throwing'

Write-Host "Format-RankedEntries -RankByTier" -ForegroundColor Cyan
# THE DOCUMENT IS ORDERED BY WHAT ITS OWN READER GETS OUT OF EACH CHANGE, so the rank key is a tier
# number rather than an audience word: the internal note ranks on tier 1, the consumer document on tier 2.
$low  = New-FlatEntry -Heading "#1 $midDot Least" -Rows @('| 1 | 1 | cosmetic |') -Pr 1
$mid  = New-FlatEntry -Heading "#2 $midDot Middling" -Rows @('| 1 | 3 | a clear improvement |') -Pr 2
$high = New-FlatEntry -Heading "#3 $midDot Most" -Rows @('| 1 | 5 | the reader must act |') -Pr 3
$ranked = Format-RankedEntries -Entries @($low, $mid, $high) -EntryLevel 2 -RankByTier 1
Assert-Match $ranked '(?s)^## #3 .*## #2 .*## #1 ' 'ranked on the tier-1 score, highest first, whatever order they arrived in'
$arrival = Format-RankedEntries -Entries @($low, $mid, $high) -EntryLevel 2
Assert-Match $arrival '(?s)^## #1 .*## #2 .*## #3 ' 'without -RankByTier the arrival order is kept (which for the changelog IS the ranking)'
# IT READS THE NAMED TIER'S ROW, NOT THE HIGHEST ONE, and this pair asserts it from both directions with
# ONE fixture set -- so the two calls can only differ because of the -RankByTier argument. An entry that
# matters little to consumers may be the one the team most needed, and ranking a document on the wrong
# row answers its reader's question with a proxy. Both entries carry both rows, as the cumulative ladder
# requires of a tier-2 entry.
$flipA = New-FlatEntry -Heading "#4 $midDot Small outside, huge inside" -Rows @('| 2 | 1 | barely anything for consumers |', '| 1 | 5 | but the team must act |') -Pr 4
$flipB = New-FlatEntry -Heading "#5 $midDot Big outside, trivial inside" -Rows @('| 2 | 4 | consumers notice at once |', '| 1 | 1 | nothing for us |') -Pr 5
Assert-Match (Format-RankedEntries -Entries @($flipA, $flipB) -EntryLevel 2 -RankByTier 2) '(?s)^## #5 .*## #4 ' 'ranking on tier 2 reads the tier-2 cells (4 beats 1), so the tier-1 five does not win'
Assert-Match (Format-RankedEntries -Entries @($flipA, $flipB) -EntryLevel 2 -RankByTier 1) '(?s)^## #4 .*## #5 ' 'and ranking the SAME pair on tier 1 reverses it -- the row named is the row read'
# TIES KEEP ARRIVAL ORDER, and the second sort key is not decoration: PowerShell's Sort-Object is NOT
# stable, and on a five-point scale ties are the common case. Without it a regenerated release document
# could differ from the published one with nothing having changed.
$tieA = New-FlatEntry -Heading "#5 $midDot First of three ties" -Rows @('| 1 | 3 | same |') -Pr 5
$tieB = New-FlatEntry -Heading "#6 $midDot Second" -Rows @('| 1 | 3 | same |') -Pr 6
$tieC = New-FlatEntry -Heading "#7 $midDot Third" -Rows @('| 1 | 3 | same |') -Pr 7
$tied = Format-RankedEntries -Entries @($tieA, $tieB, $tieC) -EntryLevel 2 -RankByTier 1
Assert-Match $tied '(?s)^## #5 .*## #6 .*## #7 ' 'equal scores come out in arrival order, so the sort is total and reproducible'
# An unscored entry sinks BELOW everything scored at its tier -- the same answer the fold gives when it
# places one, so an entry does not rank differently on either side of the fold.
$unscored = New-FlatEntry -Heading "#8 $midDot Reaches but unweighed" -Rows @('| 1 | - | - |') -Pr 8
Assert-Match (Format-RankedEntries -Entries @($unscored, $low) -EntryLevel 2 -RankByTier 1) '(?s)^## #1 .*## #8 ' 'an unscored entry sinks to the bottom of its tier, not the top'

Write-Host "Format-RankedEntries -BareTitles / -StripSignificance" -ForegroundColor Cyan
$bare = Format-RankedEntries -Entries @($e22) -EntryLevel 2 -BareTitles
Assert-Match $bare '(?m)^## Consumer feature$' '-BareTitles reduces the heading to its title'
Assert-NoMatch $bare "#22 $midDot" 'and drops the PR number a stakeholder has no use for'
$stripped = Format-RankedEntries -Entries @($e22) -EntryLevel 2 -StripSignificance
Assert-NoMatch $stripped '\| Tier \| Significance \| Why \|' '-StripSignificance removes the impact table'
Assert-NoMatch $stripped '(?m)^\| 2 \| 5 \|' 'and its rows with it'
# THIS ASSERT USED TO SAY THE OPPOSITE, and the reversal is the finding rather than a preference
# (August 6, 2026). It read "the section heading stays -- an outward document keeps its structure", and it
# arrived in #476, the same PR that introduced the three named sections -- pinning what the code did, with
# the rationale stated only in the assert message and in no document anywhere. What it actually produces is
# a heading naming a question with nothing under it, because the entry format is explicit that the table IS
# the answer rather than prose beside it. That is a hole, not structure. Measured while cutting v3.6.0 with
# -NoPush: 17 empty sections per release card, 17 per per-plugin CHANGELOG, 16 in the consumer draft.
# It had never been seen in a real document -- v3.5.0 was cut hours BEFORE #476 landed, so v3.6.0 would
# have been the first release to ship it.
#
# READ FROM THE LIB, NOT WRITTEN OUT, since the heading was renamed to 'Significance' hours after this
# assert was fixed. A literal here would have gone on passing against a heading nothing writes any more --
# a green assert measuring nothing, which is the failure mode this whole section exists to catch.
Assert-NoMatch $stripped ('(?m)^' + [regex]::Escape((Get-EntrySectionHeading -Key 'Significance')) + '$') 'the section heading goes with the declaration it introduced, or the question is left unanswered'
Assert-Match $stripped ('(?m)^### ' + $TypeRx + '$') 'and the sections that still have content keep their headings'
# BOTH DECLARATIONS, and the second is new here: while the changelog had tier sections the fold consumed
# the 'Tier: N' line, so it could never reach a rendered document. The fold now carries it, which puts a
# self-assigned tier on the path to a consumer's plugin cache unless it is dropped here.
$strippedLegacy = Format-RankedEntries -Entries @($legacyTier) -EntryLevel 2 -StripSignificance
Assert-NoMatch $strippedLegacy '(?m)^Tier: ' "-StripSignificance removes the older 'Tier: N' line too"
Assert-Match $strippedLegacy '(?m)^## #41 ' 'and leaves the entry itself intact'
# THE SCORE IS READ BEFORE ANYTHING IS STRIPPED, which is what lets the two switches compose -- the
# consumer document needs both, and in the other order they would rank an unscored pile. The same trap the
# retired renderer was measured on with -BareTitles and the type.
$both = Format-RankedEntries -Entries @($low, $high) -EntryLevel 2 -RankByTier 1 -BareTitles -StripSignificance
Assert-Match $both '(?s)^## Most.*## Least' 'ranking survives -StripSignificance: the score is read before the table is deleted'
Assert-NoMatch $both '\| Tier \|' 'and the table really is gone in the same call'

Write-Host "Get-ReleaseChangeTypes" -ForegroundColor Cyan
# WHAT IS LEFT OF Get-ReleaseCategories: the type LIST, with no labels and no 'Other'. Its one reader is
# Convert-EntryHeadingToTitle, which can only recognise a type field in a pre-format heading by
# comparing it against the types that exist. That is recognition of history, not grouping.
$types = @(Get-ReleaseChangeTypes)
foreach ($t in 'Feat', 'Fix', 'Docs', 'Chore') {
    Assert-Equal $true ($types -contains $t) "the branch type $t is listed"
}
Assert-Equal $false ($types -contains 'Other') "no 'Other' -- it was a printed category label, never a value a branch table produces"
# Read from the repo's own branch table where that is reachable, so the two cannot disagree.
Assert-Equal ((Get-BranchTypes) -join ',') ($types -join ',') 'the list comes from Get-BranchTypes rather than a second copy'

Write-Host "Build-ReleaseNotes -TierGroups (the record)" -ForegroundColor Cyan
$groups = @(Get-PullRequestEntriesByTier -Content $sample)
$notes = Build-ReleaseNotes -TierGroups $groups -Version '3.5.0' -Date '2026-08-05' -Type 'Minor' -Title 'A title'
Assert-Match $notes '^# Release notes v3\.5\.0' 'heading with version'
Assert-Match $notes '\*\*Date:\*\* 2026-08-05' 'date line'
Assert-Match $notes '\*\*Type:\*\* Minor' 'type line'
Assert-Match $notes 'A title' 'title included'
# THE LEVELS ARE CHANGELOG.md'S OWN (#881, August 25, 2026): entries at '##' and their sections at
# '###', with NO grouping heading above them -- so an entry copied out of this document pastes at the
# level it was written at. The tier still decides the order; it simply no longer prints a heading.
foreach ($tierWord in 'Tier 2 - consumers', 'Tier 1 - colleagues', 'Tier 0 - developers') {
    Assert-NoMatch $notes "(?m)^#+ $tierWord`$" "no '$tierWord' grouping heading"
}
Assert-Match $notes ('(?s)(?m)^## #22 .*^### ' + $WhatRx) 'nesting: entry at ##, its sections at ###'
Assert-Match $notes '(?s)## #22 .*## #21 .*## #20 ' 'the tiers still decide the order, without a heading to announce it'
# EVERY ENTRY BOUNDARY READS THE SAME, the tier seam included: a group joined on a bare blank line would
# be the one place two entries are not divided by a rule, which is a heading in all but name.
Assert-Equal 2 (@([regex]::Matches($notes, '(?m)^---$')).Count) 'two rules for three entries -- one per boundary, inside a tier and between tiers alike'
# THE DEVELOPMENT NOTES ARE THE COMPLETE RECORD: tier 0 belongs in them, unlike in the other two
# documents, and so do the declarations -- the cut EMPTIES the changelog, so this is the last place each
# ranking's justification lives.
Assert-Match $notes '(?m)^## #20 ' 'tier-0 entries ARE in the developer notes -- this tier is the record'
Assert-Match $notes '\| Tier \| Significance \| Why \|' 'the impact table survives into the record'
Assert-Match $notes 'consumers must re-add the marketplace' "and so does each row's reason, which is the lasting half"
# NO CATEGORY HEADINGS ANYWHERE -- the type is stated inside each entry now.
foreach ($label in 'Features', 'Fixes', 'Maintenance') {
    Assert-NoMatch $notes "(?m)^#+ $label$" "no '$label' category heading"
}
Assert-Match $notes ('(?m)^### ' + $TypeRx + '$') 'the type is stated inside the entry instead'
# An empty tier is omitted rather than printed as a heading with nothing under it.
$sparse = @([pscustomobject]@{ Tier = 2; Entries = @($e22) }, [pscustomobject]@{ Tier = 1; Entries = @() })
$sparseNotes = Build-ReleaseNotes -TierGroups $sparse -Version '3.5.0' -Date '2026-08-05' -Type 'Minor'
Assert-Match $sparseNotes '(?m)^## #22 ' 'a tier with entries is rendered'
Assert-NoMatch $sparseNotes 'Tier 1' 'a tier with no entries contributes nothing, not an empty section'
Assert-NoMatch $sparseNotes '(?m)^---$' 'and no dangling rule where its boundary would have been'

Write-Host "Build-ReleaseNotes -- ranked from tier 1 up, and deliberately not at tier 0" -ForegroundColor Cyan
# TIER 0 IS THE RECORD: complete and chronological, which is what a record is for, and its entries are
# never asked for a score in the first place. Unranked means DOCUMENT ORDER -- the order the fold left --
# so tier 0 inherits a defined order rather than losing one.
$t1Group = @([pscustomobject]@{ Tier = 1; Entries = @($low, $high) })
Assert-Match (Build-ReleaseNotes -TierGroups $t1Group -Version '3.5.0' -Date '2026-08-05' -Type 'Minor') `
    '(?s)## #3 .*## #1 ' 'a tier-1 group is ranked by its own score'
$t0Group = @([pscustomobject]@{ Tier = 0; Entries = @($e20, $e21) })
Assert-Match (Build-ReleaseNotes -TierGroups $t0Group -Version '3.5.0' -Date '2026-08-05' -Type 'Minor') `
    '(?s)## #20 .*## #21 ' 'a tier-0 group keeps document order -- the record is not re-sorted'

Write-Host "Build-ReleaseNotes -Entries (arrival order, for a repo that declares no tier)" -ForegroundColor Cyan
# SINCE #881 THIS DIFFERS FROM -TierGroups IN ORDER ONLY. Both render at these levels; a repo whose
# entries declare nothing has no tier to rank on, so the arrival order is all there is to keep.
$flatNotes = Build-ReleaseNotes -Entries $entries -Version '3.5.0' -Date '2026-08-05' -Type 'Minor'
Assert-Match $flatNotes '(?m)^## #22 ' 'flat: entries sit at ##'
Assert-Match $flatNotes ('(?m)^### ' + $WhatRx + '$') 'flat: their sections at ###'
Assert-NoMatch $flatNotes 'Tier \d - ' 'flat: no tier heading is invented'
# -TierGroups wins when both arrive, which is what the doc promises.
$bothArgs = Build-ReleaseNotes -Entries @($e21) -TierGroups $sparse -Version '3.5.0' -Date '2026-08-05' -Type 'Minor'
Assert-Match $bothArgs '(?m)^## #22 ' '-TierGroups wins if both are given'
Assert-NoMatch $bothArgs '#21 ' 'and -Entries is then ignored rather than merged in'

Write-Host "Build-ReleaseNotes -- link rewriting" -ForegroundColor Cyan
$linkEntry = New-FlatEntry -Heading "#9 $midDot Something" -Rows @('| 1 | 2 | fine |') `
    -Body 'See [the lint](scripts/lint/x.ps1) and [the site](https://example.com) and [#heading](#heading).' -Pr 9
$ln = Build-ReleaseNotes -Entries @($linkEntry) -Version '0.2.1' -Date '2026-07-14' -Type 'Patch' -LinkPrefix '../../../'
Assert-Match $ln '\[the lint\]\(\.\./\.\./\.\./scripts/lint/x\.ps1\)' 'root-relative link gets the ../../../ prefix'
Assert-Match $ln '\[the site\]\(https://example\.com\)' 'external link untouched'
Assert-Match $ln '\[#heading\]\(#heading\)' 'anchor link untouched'
Assert-Match $ln '\[PR #9\]\(https://example\.test/9\)' 'PR link untouched'

# --- Get-RelativeLinkPath: the history row's anchor (August 14, 2026) ------------------------------
# The first two cases are the old `-replace '^releases/'` answers, byte for byte -- that identity is
# what made replacing the strip safe for this repo. The workflow-folder cases are the reason the strip
# had to go: a history README outside releases/ needs a '../' the strip could never produce.
Write-Host "Get-RelativeLinkPath -- computed relative to the history file's own directory" -ForegroundColor Cyan
Assert-Equal 'audience/4.x/4.9.0.md' (Get-RelativeLinkPath -FromDir 'releases' -To 'releases/audience/4.x/4.9.0.md') `
    'inside releases/: identical to the old prefix strip'
Assert-Equal 'development/4.x/4.9.0.md' (Get-RelativeLinkPath -FromDir 'releases' -To 'releases/development/4.x/4.9.0.md') `
    'a patch row in the default layout: identical to the old strip'
Assert-Equal 'audience/4.x/4.9.0.md' (Get-RelativeLinkPath -FromDir 'contributing-davekjohn/releases' -To 'contributing-davekjohn/releases/audience/4.x/4.9.0.md') `
    'workflow folder: the audience note sits under the same README'
Assert-Equal '../../releases/development/4.x/4.9.0.md' (Get-RelativeLinkPath -FromDir 'contributing-davekjohn/releases' -To 'releases/development/4.x/4.9.0.md') `
    'workflow folder: the development notes stay at the repo root, so the row climbs out'
Assert-Equal 'CHANGELOG.md' (Get-RelativeLinkPath -FromDir '' -To 'CHANGELOG.md') `
    'an empty from-dir returns the path itself'
$lnTier = Build-ReleaseNotes -TierGroups @([pscustomobject]@{ Tier = 1; Entries = @($linkEntry) }) -Version '3.5.0' -Date '2026-08-05' -Type 'Minor'
Assert-Match $lnTier '\[the lint\]\(\.\./\.\./\.\./scripts/lint/x\.ps1\)' 'root-relative links get the prefix inside a tier group too'

Write-Host "Build-ReleaseNotes -Summary (a milestone release carries an authored block)" -ForegroundColor Cyan
# The arc across many releases fits in neither -Title (one sentence) nor the entries (per-PR), and
# hand-editing a generated file is not a repeatable release. Assertions are about POSITION and
# BOUNDARY, because that is what makes an authored block readable as authored.
$plain = Build-ReleaseNotes -TierGroups $groups -Version '3.5.0' -Date '2026-08-05' -Type 'Minor' -Title 'A title'
Assert-Equal $plain (Build-ReleaseNotes -TierGroups $groups -Version '3.5.0' -Date '2026-08-05' -Type 'Minor' -Title 'A title' -Summary '') 'no -Summary: output byte-identical to the call without the parameter'
$sum = "## What 3.x was about`r`n`r`nA sentence with CRLF endings and a [root link](README.md)."
$ms = Build-ReleaseNotes -TierGroups $groups -Version '4.0.0' -Date '2026-08-05' -Type 'Major' -Title 'A milestone' -Summary $sum
Assert-Match $ms '## What 3\.x was about' 'summary: the authored heading is present'
Assert-Match $ms '(?s)\*\*Type:\*\* Major.*A milestone.*## What 3\.x was about' 'summary: sits after the header and the title line'
Assert-Match $ms '(?s)## What 3\.x was about.*\n---\n.*## #22 ' 'summary: separated from the generated entries by a horizontal rule'
Assert-NoMatch $ms "`r" 'summary: CRLF input is normalized to LF like every other block in this file'
# A root-relative link inside the SUMMARY is deliberately NOT rewritten: unlike an entry (which was
# authored in the root CHANGELOG and then moved three folders deeper), a summary is authored for this
# file and its links are already relative to it. Rewriting them would break the ones that were right.
Assert-Match $ms '\[root link\]\(README\.md\)' 'summary: its links are left exactly as authored -- it was written for this file, not moved into it'

Write-Host "Get-ReleaseTierHeading" -ForegroundColor Cyan
Assert-Equal 'Tier 2 - consumers'  (Get-ReleaseTierHeading -Tier 2) 'tier 2 is for consumers'
Assert-Equal 'Tier 1 - colleagues' (Get-ReleaseTierHeading -Tier 1) 'tier 1 is for colleagues'
Assert-Equal 'Tier 0 - developers' (Get-ReleaseTierHeading -Tier 0) 'tier 0 is for developers'
Assert-Equal 'Tier 7' (Get-ReleaseTierHeading -Tier 7) 'an unknown tier degrades to its number, not to a dangling separator'

Write-Host "Convert-EntryHeadingToTitle (the metadata a stakeholder does not have a branch for)" -ForegroundColor Cyan
# THE COMMON CASE IS NOW A HEADING WITH ONLY A LEADING '#NN', since the type moved into its own section.
# That case USED TO RETURN THE HEADING UNCHANGED -- the guard asked whether any TRAILING field had been
# dropped, which is a different question from whether anything had -- so the consumer document, whose
# whole reason for calling this is that its reader has no PR numbers, kept every one of them.
Assert-Equal '## Consumer feature' ((Convert-EntryHeadingToTitle -EntryText $e22) -split "`n")[0] 'the leading #NN is dropped even with no trailing field -- the current shape'
Assert-Match (Convert-EntryHeadingToTitle -EntryText $e22) ('(?m)^### ' + $WhatRx + '$') 'and the body is untouched'
$hIn = "### #426 $midDot Some title $midDot Feat $midDot 2026-08-03`n`nBody stays.`n`nAnd a second paragraph."
$hOut = Convert-EntryHeadingToTitle -EntryText $hIn
Assert-Equal '### Some title' (($hOut -split "`n")[0]) 'the fully-dated historical shape reduces to the bare title'
Assert-Match $hOut '(?s)Body stays\..*second paragraph' 'the body is untouched there too'
$hMid = Convert-EntryHeadingToTitle -EntryText "### #7 $midDot A title $midDot with a middot $midDot Fix $midDot 2026-01-01`n`nBody."
Assert-Equal "### A title $midDot with a middot" (($hMid -split "`n")[0]) 'a title containing a middot survives (rejoined, not truncated)'
$hNoNum = Convert-EntryHeadingToTitle -EntryText "### Titled $midDot Docs $midDot 2026-01-01`n`nBody."
Assert-Equal '### Titled' (($hNoNum -split "`n")[0]) 'a heading without a #NN field is handled too'
# The guards matter because this runs over contributor-authored headings. A shape it does not
# recognise must come through unchanged: a stakeholder reading an odd heading is a cosmetic problem,
# a stakeholder reading a truncated or empty one is a broken document.
$hPlain = Convert-EntryHeadingToTitle -EntryText "### Just a heading`n`nBody."
Assert-Equal '### Just a heading' (($hPlain -split "`n")[0]) 'a heading with no metadata at all is returned unchanged'
$hTwo = Convert-EntryHeadingToTitle -EntryText "### Only $midDot Two`n`nBody."
Assert-Equal "### Only $midDot Two" (($hTwo -split "`n")[0]) 'two fields, neither of them metadata: nothing to strip, so left alone'

# THE DATELESS HEADING, which is what the entries folded between the date move and the flat format look
# like. Both shapes have to keep working from one code path -- the new one for everything folded from
# here, the dated one because this repo's whole history carries it and the notes are regenerated from it.
$hNoDate = Convert-EntryHeadingToTitle -EntryText "### #426 $midDot Some title $midDot Feat`n`nBody."
Assert-Equal '### Some title' (($hNoDate -split "`n")[0]) 'dateless: the type is stripped without a date behind it'
$hNoDateNoNum = Convert-EntryHeadingToTitle -EntryText "### Titled $midDot Docs`n`nBody."
Assert-Equal '### Titled' (($hNoDateNoNum -split "`n")[0]) 'dateless: two fields ARE strippable when the second is a real type'
$hNoDateMid = Convert-EntryHeadingToTitle -EntryText "### #7 $midDot A title $midDot with a middot $midDot Fix`n`nBody."
Assert-Equal "### A title $midDot with a middot" (($hNoDateMid -split "`n")[0]) 'dateless: a middot in the title still survives'
# A title that IS a type name, which is the one collision content-matching can have. The LAST matching
# field is the type, so the title keeps its word.
$hTypeTitle = Convert-EntryHeadingToTitle -EntryText "### #12 $midDot Fix $midDot Fix`n`nBody."
Assert-Equal '### Fix' (($hTypeTitle -split "`n")[0]) 'dateless: a title that is itself a type name is not eaten'
# 'Other' is a printed catch-all label, never a value a branch table produces -- so a field reading
# 'Other' is a title, not administration. Now true by construction: Get-ReleaseChangeTypes omits it.
$hOther = Convert-EntryHeadingToTitle -EntryText "### Other $midDot Feat`n`nBody."
Assert-Equal '### Other' (($hOther -split "`n")[0]) "dateless: 'Other' is treated as a title, not as a type to strip"
$hOnlyMeta = Convert-EntryHeadingToTitle -EntryText "### #9 $midDot Fix $midDot 2026-01-01`n`nBody."
Assert-Equal "### #9 $midDot Fix $midDot 2026-01-01" (($hOnlyMeta -split "`n")[0]) 'a heading that is ONLY metadata keeps it rather than becoming empty'
$hLevel = Convert-EntryHeadingToTitle -EntryText "#### #5 $midDot Deeper $midDot Feat $midDot 2026-01-01`n`nBody."
Assert-Equal '#### Deeper' (($hLevel -split "`n")[0]) 'the heading level is preserved, not normalized'

Write-Host "Build-ConsumerNotes (the tier-2 entries, ranked and stripped)" -ForegroundColor Cyan
$tier2 = @($groups | Where-Object { $_.Tier -eq 2 })[0]
$hl = Build-ConsumerNotes -Entries $tier2.Entries -Version '3.5.0' -Date '2026-08-05' -Type 'Minor' -Title 'A release for people'
Assert-Match $hl '(?m)^# Release notes v3\.5\.0 ' 'header names the version'
Assert-Match $hl '\*\*Date:\*\* 2026-08-05' 'header carries the date'
Assert-Match $hl 'A release for people' 'the -Title line is included'
Assert-Match $hl '(?m)^## Consumer feature$' 'the entry is rendered with a bare title, at ##'
Assert-NoMatch $hl "#22 $midDot" 'entry metadata is stripped in the consumer document'
# THE SCORES AND THE TIER ARE STRIPPED, which is the whole reason -StripSignificance exists: a
# self-assigned number printed at a consumer is a marketing claim, and this repo has measured what a
# published guess costs (the retired remove-before-publishing marker). The reason stays in the development notes,
# where it is auditable by the people who can check it.
Assert-NoMatch $hl '\| Tier \| Significance \| Why \|' 'the impact table does not travel to the consumer'
Assert-NoMatch $hl 'consumers must re-add the marketplace' "and neither does the row's justification"
Assert-NoMatch $hl '(?m)^Tier: ' "nor the older 'Tier: N' line"
# ORDERED BY THE CONSUMER SCORE, not the internal one: 'what does a consumer notice' is a different
# question from 'what does the organisation get out of it', which is why they are separate documents.
$c1 = New-FlatEntry -Heading "#31 $midDot Barely noticed" -Rows @('| 2 | 1 | cosmetic for them |', '| 1 | 5 | but huge internally |') -Pr 31
$c2 = New-FlatEntry -Heading "#32 $midDot Must act" -Rows @('| 2 | 5 | they have to migrate |', '| 1 | 1 | nothing for us |') -Pr 32
$hlOrder = Build-ConsumerNotes -Entries @($c1, $c2) -Version '3.5.0' -Date '2026-08-05' -Type 'Minor'
Assert-Match $hlOrder '(?s)^# .*## Must act.*## Barely noticed' 'ordered by the tier-2 score, so the internal five does not lead a consumer document'
# THE CALLER SELECTS, so this function renders exactly what it is handed and derives no second half.
$hlOne = Build-ConsumerNotes -Entries @($e22) -Version '3.5.0' -Date '2026-08-05' -Type 'Minor'
Assert-Match $hlOne '(?m)^## Consumer feature$' 'a single tier-2 entry renders on its own'
Assert-NoMatch $hlOne 'For colleagues only' 'and nothing that was not handed in'
# THE RETIRED MARKER AND ITS KNOBS. Asserted on absence: the selection now happens before this function
# is called, and a marker reappearing here would mean the guess has been rebuilt.
Assert-NoParameter -Command 'Build-ConsumerNotes' -Names @('StakeholderTypes', 'DevBlockComment', 'DevBlockHeading', 'OnlyTypes')
Assert-NoMatch $hl 'For developers only' 'no remove-before-publishing marker is written'
# An empty selection must not throw: the cut never gets here with nothing (its bump gate refuses a minor
# without a tier-2 entry), so the only callers that can are a test and a hand run -- and for those a
# header with no body is a truthful answer where an exception is not.
$hlNone = Build-ConsumerNotes -Entries @() -Version '3.5.0' -Date '2026-08-05' -Type 'Minor'
Assert-Match $hlNone '(?m)^# Release notes v3\.5\.0 ' 'an empty selection still returns the header'
Assert-NoMatch $hlNone '(?m)^## ' 'and nothing under it'
# Links are rewritten from the consumer file's depth, which equals the developer notes' depth.
$hlLink = Build-ConsumerNotes -Entries @($linkEntry) -Version '3.5.0' -Date '2026-08-05' -Type 'Minor'
Assert-Match $hlLink '\[the lint\]\(\.\./\.\./\.\./scripts/lint/x\.ps1\)' 'root-relative links get the prefix here too'
Assert-Match $hlLink '\[the site\]\(https://example\.com\)' 'external links untouched'

# THE BRANCH ADMINISTRATION IS STRIPPED, and the fixtures above could not have caught its absence: they
# are pre-dossier entries, whose metadata sits in the HEADING. Convert-EntryHeadingToTitle handled that
# correctly all along -- the defect was that the August 6, 2026 format moved the same facts into named
# '###' sections and the stripping never followed. Measured on the real v4.2.0 draft before the repair:
# 125 of 396 rendered lines, including 'Branch title' printed directly under the heading it had become.
$dossier = @(
    '## `fix/dossier` changelog'
    ''
    '### Branch title'
    ''
    'A change with a readable name'
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
    'What the reader is actually here for.'
    ''
    '### Significance'
    ''
    '#### Tier 2'
    ''
    'They notice it.'
    ''
    '**Score:** 4'
    ''
    '### Pull Request'
    ''
    'Plugins: contributing-davekjohn'
    ''
    '[PR #99](https://example.test/99) - merged 2026-08-10'
) -join "`n"

$hlDossier = Build-ConsumerNotes -Entries @($dossier) -Version '4.2.0' -Date '2026-08-10' -Type 'Minor'
# READ BEFORE STRIP, and this is the assert that pins the ORDER rather than the removal. The heading is
# built FROM the 'Branch title' section that the same pass deletes, so a future edit that strips first
# would leave every change in this document listed as '`fix/dossier` changelog' -- a slug, published.
Assert-Match $hlDossier '(?m)^## A change with a readable name$' 'the heading is the readable title, so the strip ran AFTER the heading was built from it'
Assert-NoMatch $hlDossier '(?m)^### Branch title'  'the title section itself does not travel'
Assert-NoMatch $hlDossier '(?m)^### Branch ID'     'nor the creation timestamp'
Assert-NoMatch $hlDossier '20260810-212615'        'nor its value'
Assert-NoMatch $hlDossier '(?m)^### Branch type'   'nor the branch prefix'
Assert-NoMatch $hlDossier '(?m)^### Pull Request'  'nor the PR section'
Assert-NoMatch $hlDossier 'PR #99'                 'nor the PR number this reader has no use for'
Assert-NoMatch $hlDossier '(?m)^Plugins:'          "nor the 'Plugins:' line, which is this repo's own selection administration"
Assert-Match $hlDossier 'What the reader is actually here for\.' 'while the substance survives'
Assert-NoMatch $hlDossier '\*\*Score:\*\* 4'       'and the score is still stripped, by the switch that always did it'

# THE RECORD KEEPS EVERY ONE OF THEM -- the asymmetry IS the design, so it is asserted rather than assumed.
# The development notes are the last place an entry's administration and its ranking justification live once
# the cut has emptied CHANGELOG.md; a strip that reached them would delete the audit trail instead of
# sparing a reader.
$dossierGroups = @([pscustomobject]@{ Tier = 2; Heading = 'Tier 2 - consumers'; Entries = @($dossier); Declared = 1 })
$dossierNotes = Build-ReleaseNotes -TierGroups $dossierGroups -Version '4.2.0' -Date '2026-08-10' -Type 'Minor'
Assert-Match $dossierNotes 'Branch ID'   'the development notes KEEP the branch id'
Assert-Match $dossierNotes 'Branch type' 'and the branch type'
Assert-Match $dossierNotes 'PR #99'      'and the PR number'
Assert-Match $dossierNotes '(?m)^Plugins:' "and the 'Plugins:' line"

Write-Host "Build-ReleaseNoteDraft (one document, a named section per reader)" -ForegroundColor Cyan
$draft = Build-ReleaseNoteDraft -Entries @($dossier) -Version '4.3.0' -Date '2026-08-11' -Type 'Minor' `
    -Title 'A release title sentence'
Assert-Match $draft '(?m)^# Release notes v4\.3\.0 ' 'the header names the version'
Assert-Match $draft '\*\*Date:\*\* 2026-08-11' 'and carries the date'
Assert-Match $draft '(?m)^\*\*For whom:\*\* .*consumers.*colleagues' 'the audience line names BOTH readers, since the document has two'
Assert-Match $draft '(?m)^A release title sentence$' 'the title line is included'
Assert-Match $draft '(?m)^## What changed$' 'the audience section is present when an entry reached tier 2'
Assert-NoMatch $draft '(?m)^## For ' 'and it does not name its own reader -- the section below is the one that names a reader'
Assert-Match $draft '(?m)^### A change with a readable name$' 'its entries sit one level DEEPER than before -- they are under a section now, not under the H1'
Assert-Match $draft '(?m)^## What it is worth$' "the organisation's value section is present"
Assert-Match $draft '(?m)^## What was still open at this release$' 'and its open section'
# THE HEADING THAT WAS THE DUPLICATION. 'What is different now' held the same ground as the consumer
# section, in a second register, in the other document -- the ~365 words the merge measurement found
# written twice. It is gone rather than moved, and asserted on absence so it cannot grow back.
Assert-NoMatch $draft 'What is different now' "the internal note's 'what is different' heading is gone -- the consumer section IS it"
# The stripping is inherited from Format-RankedEntries, asserted once here so a caller that stopped
# passing the switches turns this red rather than publishing branch administration.
Assert-NoMatch $draft '(?m)^#### Branch ID' 'branch administration does not reach the draft'
Assert-NoMatch $draft '\*\*Score:\*\* 4' 'and neither does the self-assigned score'
# NO EMPTY CONSUMER SECTION -- the tier-1-only minor IN A TIER-2 REPO, and that qualifier is the whole
# lesson of #747. A named question with nothing under it looks written, which is the finding that retired
# the previous shape's empty impact heading, so this assert is still right about what it covers. What it
# was read as saying -- that a missing consumer section is always correct -- was never true: in a repo
# whose audience IS tier 1 the same suppression removed the only section describing the work, at every
# release rather than at an unlucky one. This assertion passed throughout, which is why it is worth
# stating out loud that its scope is the tier-2 repo and the tier-1 case is asserted separately below.
$draftNoTier2 = Build-ReleaseNoteDraft -Entries @() -Version '4.3.0' -Date '2026-08-11' -Type 'Minor'
Assert-NoMatch $draftNoTier2 '(?m)^## What changed$' 'a TIER-2 repo gets no audience section where no entry reached tier 2'
Assert-Match $draftNoTier2 '(?m)^## What it is worth$' 'while the organisation still gets its sections -- the document is still written'
Assert-Match $draftNoTier2 '(?m)^## What was still open at this release$' 'both of them'
# The guidance is an HTML comment, so the writer deletes it rather than working around it -- and the fold's
# comment stripper is not involved here, this document is not an entry.
Assert-Match $draft '<!-- DRAFT\.' 'the consumer guidance is an HTML comment'
Assert-Match $draft '<!-- FOR THE ORGANISATION' 'and so is the value-section guidance, which names who it is NOT for'
# WORDING MERGES OVER THE DEFAULTS, one key at a time: a repo renaming one heading must not have to
# restate the other five. Same contract the note script's seam already had.
$draftW = Build-ReleaseNoteDraft -Entries @($dossier) -Version '4.3.0' -Date '2026-08-11' -Type 'Minor' `
    -Wording @{ SectionConsumers = 'Voor klanten' }
Assert-Match $draftW '(?m)^## Voor klanten$' 'an overridden heading is used'
Assert-Match $draftW '(?m)^## What it is worth$' 'and the headings that were not overridden keep their defaults'
Assert-Match (Build-ReleaseNoteDraft -Entries @($dossier) -Version '4.3.0' -Date '2026-08-11' -Type 'Minor' -Wording @{ SectionConsumers = '' }) `
    '(?m)^## What changed$' 'an override that is present but EMPTY is ignored, like every other wording seam here'
# THE DEFAULT IS 2, so every assert above passes an -AudienceTier nobody wrote. Pinned, because the
# alternative -- making the parameter mandatory -- would have been a breaking change to a function a
# consumer's own scripts may call, and because 2 is what the caller hardcoded before the seam was read.
Assert-Match (Build-ReleaseNoteDraft -Entries @($dossier) -Version '4.3.0' -Date '2026-08-11' -Type 'Minor' -AudienceTier 2) `
    '(?m)^## What changed$' 'passing -AudienceTier 2 explicitly is what omitting it already did'

Write-Host "Build-ReleaseNoteDraft at tier 1 (inbound #747 -- the audience the repo actually has)" -ForegroundColor Cyan
# A tier-1 entry, scored on tier 1: the source a tier-1 repo has and the previous shape never read.
$dossier1 = $dossier -replace '(?m)^#### Tier 2$', '#### Tier 1'
$draft1 = Build-ReleaseNoteDraft -Entries @($dossier1) -Version '4.3.0' -Date '2026-08-11' -Type 'Minor' -AudienceTier 1
Assert-Match   $draft1 '(?m)^## What changed$' 'the audience section is present -- the SAME heading tier 2 gets, since neither names a reader'
Assert-NoMatch $draft1 '(?m)^## For consumers$' 'and the retired consumer heading does not come back at either tier'
Assert-Match   $draft1 '(?m)^### A change with a readable name$' 'it is PRE-FILLED from the tier-1 entry -- the half #747 thought impossible'
Assert-Match   $draft1 '(?m)^## What it is worth$' 'the section a changelog cannot produce still arrives'
Assert-Match   $draft1 '(?m)^## What was still open at this release$' 'and so does the open section'
Assert-NoMatch $draft1 '\*\*Score:\*\* 4' 'the self-assigned score is stripped here too'
Assert-NoMatch $draft1 '(?m)^#### Branch ID' 'and so is the branch administration'
# #747's SECOND finding: at tier 1 the default audience line was false on both halves -- it promised a
# reader the repo does not publish to, and one section each in a document rendering two for one reader.
Assert-NoMatch $draft1 'consumers of this product' 'the audience line no longer promises an audience the repo does not have'
Assert-Match   $draft1 '(?m)^\*\*For whom:\*\* colleagues in the organisation' 'it names the reader it does have'
# And the value hint stops asserting it is 'not for the consumer', which at tier 1 would deny the
# audience the very document they are reading.
Assert-NoMatch $draft1 'not for the consumer' "the value hint drops a distinction that does not exist at tier 1"
Assert-Match   $draft1 '<!-- WHAT THIS RELEASE BOUGHT' 'and keeps the part that is true at either tier'
# The empty gate is unchanged at tier 1 -- an empty heading is still worse than none.
$draft1None = Build-ReleaseNoteDraft -Entries @() -Version '4.3.0' -Date '2026-08-11' -Type 'Minor' -AudienceTier 1
Assert-NoMatch $draft1None '(?m)^## What changed$' 'no audience section at tier 1 either, where no entry reached that tier'
Assert-Match   $draft1None '(?m)^## What it is worth$' 'while the document is still written'
# RECOGNISE BOTH, WRITE ONE. SectionConsumers/HintConsumers are the retired key names, and this wording
# comes from a consumer-owned seam -- a repo that named the section under the old key receives the rename
# through a plugin update rather than by choosing to, so dropping it would silently revert their heading.
$draft1Alias = Build-ReleaseNoteDraft -Entries @($dossier1) -Version '4.3.0' -Date '2026-08-11' -Type 'Minor' `
    -AudienceTier 1 -Wording @{ SectionConsumers = 'Wat er is veranderd'; HintConsumers = 'Eigen uitleg.' }
Assert-Match $draft1Alias '(?m)^## Wat er is veranderd$' 'the retired SectionConsumers key still names the audience section'
Assert-Match $draft1Alias '<!-- Eigen uitleg\. -->' 'and the retired HintConsumers key still carries its hint'
$draft1Both = Build-ReleaseNoteDraft -Entries @($dossier1) -Version '4.3.0' -Date '2026-08-11' -Type 'Minor' `
    -AudienceTier 1 -Wording @{ SectionAudience = 'The current key'; SectionConsumers = 'The retired key' }
Assert-Match   $draft1Both '(?m)^## The current key$' 'the current key wins where a repo sets both'
Assert-NoMatch $draft1Both 'The retired key' 'and the retired one does not also appear'

Write-Host "Build-GitHubReleaseBody (generated, every release, every tier)" -ForegroundColor Cyan
# THE POINT OF GENERATING IT is that the Release page stops depending on which hand-written tier
# document happens to exist. The internal note was the body BECAUSE it was the only tier written at
# every release -- which is what made a note mandatory at a patch nobody wanted one for.
$bodyEntry2 = @(
    '## `feat/second` changelog'
    ''
    '### Branch title'
    ''
    'The second thing'
    ''
    '### What does the change on this branch bring to main?'
    ''
    'Body.'
    ''
    '### Pull Request'
    ''
    '[PR #12](https://example.test/pull/12) - merged 2026-08-10'
) -join "`n"
$body = Build-GitHubReleaseBody -Entries @($dossier, $bodyEntry2) -Version '4.3.0' `
    -Title 'A release with two things in it' -NotePointer 'See the attached notes.'
Assert-Match $body '(?m)^A release with two things in it$' 'the title line opens the body'
Assert-Match $body '(?m)^See the attached notes\.$' 'the pointer is included when one is given'
Assert-Match $body '(?m)^## What landed$' 'the list has a heading'
Assert-Match $body '(?m)^- \[A change with a readable name\]\(https://example\.test/99\)$' 'the readable title links to the PR'
Assert-Match $body '(?m)^- \[The second thing\]\(https://example\.test/pull/12\)$' 'every entry is listed, not just the first'
# EVERY TIER, because "what landed" is not a tier question -- a repo-internal change still landed. The
# tiers decide which DOCUMENT a change appears in, and this is not one of those documents.
$tier0Body = New-FlatEntry -Heading "#7 $midDot Internal only" -Rows @('| 0 | 2 | ours alone |') -Pr 7
$bodyAll = Build-GitHubReleaseBody -Entries @($dossier, $tier0Body) -Version '4.3.0'
Assert-Match $bodyAll 'Internal only' 'a tier-0 entry is in the body -- it landed'
# NO POINTER WHEN NONE IS GIVEN: naming an attachment that will not exist (a patch writes no
# hand-written document) is exactly the confidently-wrong published line this guards against.
Assert-NoMatch $bodyAll 'attached' 'no pointer is invented when the caller passes none'
Assert-NoMatch $bodyAll '(?m)^\s*$\r?\n\s*$\r?\n\s*$' 'and its absence leaves no gap where the sentence was'
# AN ENTRY WITH NO PR LINK IS LISTED WITHOUT ONE, never dropped -- a hand-filed entry, or one whose fold
# could not reach the PR, would otherwise vanish from the only COMPLETE list, and vanish silently.
$noPr = "## ``fix/nolink`` changelog`n`n### Branch title`n`nNo link for this one`n`n### Pull Request`n`nPlugins: team-alpha"
$bodyNoPr = Build-GitHubReleaseBody -Entries @($noPr) -Version '4.3.0'
Assert-Match $bodyNoPr '(?m)^- No link for this one$' 'an entry with no PR link is still listed, unlinked'
# A nameless entry falls back to its own heading rather than to nothing, for the same reason.
$noTitle = "## ``fix/untitled`` changelog`n`n### What does the change on this branch bring to main?`n`nBody."
Assert-Match (Build-GitHubReleaseBody -Entries @($noTitle) -Version '4.3.0') '(?m)^- `fix/untitled` changelog$' 'a title-less entry falls back to its heading'
# An empty release still returns a page rather than a blank: the cut can reach this only in a test or a
# hand run, and a sentence is a truthful answer where an empty document is not.
$bodyEmpty = Build-GitHubReleaseBody -Entries @() -Version '4.3.0' -Title 'Nothing pending'
Assert-Match $bodyEmpty 'No changes were pending' 'an empty release says so instead of returning an empty list'
# The entry body may quote a PR link of its own, so the link is read from the PullRequest SECTION rather
# than from the first match in the whole entry.
$quoting = @(
    '## `docs/quotes` changelog'
    ''
    '### Branch title'
    ''
    'Quotes another PR'
    ''
    '### What does the change on this branch bring to main?'
    ''
    'This follows up [PR #1](https://example.test/wrong/1).'
    ''
    '### Pull Request'
    ''
    '[PR #2](https://example.test/right/2) - merged 2026-08-10'
) -join "`n"
Assert-Match (Build-GitHubReleaseBody -Entries @($quoting) -Version '4.3.0') '\(https://example\.test/right/2\)' "the link comes from the PullRequest section, not from a link quoted in the body"

Write-Host "the consumer tier produces markdown ONLY (no HTML renderer)" -ForegroundColor Cyan
# Dave, August 3, 2026: the print-ready .html is not wanted anywhere, so ConvertTo-ReleaseHtml and
# Format-InlineMarkdown were removed the same day they were ported. ASSERTED ON THEIR ABSENCE rather
# than simply deleting the old asserts: a partial HTML renderer is exactly the kind of thing that gets
# helpfully reintroduced, and re-adding it should turn a test red rather than pass unnoticed.
foreach ($gone in @('ConvertTo-ReleaseHtml', 'Format-InlineMarkdown')) {
    Assert-Equal $null (Get-Command $gone -ErrorAction SilentlyContinue) "release-lib no longer defines $gone"
}
$tags = @([regex]::Matches($hl, '<[a-zA-Z/!][^>]*>') | ForEach-Object { $_.Value })
Assert-Equal 0 $tags.Count "the generated document carries no HTML tags (found: $($tags -join ', '))"

Write-Host "Set-ReleaseInternalNoteLink (the release history overview's Version cell)" -ForegroundColor Cyan
# WHAT MOVED (Dave, August 5, 2026): the target document, not the mechanism. This used to rewrite the
# notes line inside CHANGELOG.md's release block, and that block is gone -- which would have left the
# internal note with no inbound link anywhere, since the overview's rows point at the development notes.
# Left alone it would not have ERRORED either: the function returns its input unchanged when it finds
# nothing, so the step would simply have gone quiet.
#
# The fixture carries the REAL table header, because that shape is what $script:OverviewTableHeaderRe and
# its three readers depend on -- a hand-simplified table would test a document that cannot occur.
$overview = @(
    '# Release notes', '', '## Overview', '', 'Grouped by major version, newest first.', '',
    '### 3.x', '', '| Version | Date | Type | Title |', '|---|---|---|---|',
    '| [3.5.0](development/3.x/3.5.0.md) | 2026-08-05 | Minor | The newest |',
    '| [3.4.0](development/3.x/3.4.0.md) | 2026-08-04 | Minor | The one before |', ''
) -join "`n"
$intOut = Set-ReleaseInternalNoteLink -Content $overview -Version '3.5.0' `
    -InternalRelPath 'internal/3.x/3.5.0.md' -DevRelPath 'development/3.x/3.5.0.md'
Assert-Match $intOut ([regex]::Escape('| [3.5.0](internal/3.x/3.5.0.md) |')) "the row's Version cell now points at the internal note"
Assert-Match $intOut ([regex]::Escape('| [3.4.0](development/3.x/3.4.0.md) |')) 'the OTHER row is left exactly as it was'
Assert-Match $intOut ([regex]::Escape('| Version | Date | Type | Title |')) 'the table shape is unchanged -- no fourth column, so its three readers still match'
function Get-OverviewRowCount([string]$text) {
    # Data rows only: a line starting '| [' , which is the linked-version cell every row opens with.
    return @(($text -split "`r?`n") | Where-Object { $_ -match '^\|\s*\[' }).Count
}
Assert-Equal (Get-OverviewRowCount $overview) (Get-OverviewRowCount $intOut) 'the row count is unchanged -- the cell is rewritten, not the table'
# Idempotent, because this runs in a PR that may be re-run or rebased. The target is matched as
# 'anything' rather than as $DevRelPath, which makes the second call a no-op BY DECISION -- matching only
# the dev path would make it one by accident (nothing matched), and those look identical from outside.
Assert-Equal $intOut (Set-ReleaseInternalNoteLink -Content $intOut -Version '3.5.0' `
    -InternalRelPath 'internal/3.x/3.5.0.md' -DevRelPath 'development/3.x/3.5.0.md') 'idempotent -- a second call changes nothing'
# Unknown version: untouched and no throw. This runs AFTER a successful release, so failing here would
# make a completed release look broken over a cosmetic line.
Assert-Equal $overview (Set-ReleaseInternalNoteLink -Content $overview -Version '9.9.9' `
    -InternalRelPath 'x.md' -DevRelPath 'y.md') 'an unknown version leaves the content untouched'
# ONE match, by offset: a version string can legitimately appear again in prose or in an older major's
# row, and a global replace would rewrite those too.
$twice = $overview + "`n`nv3.5.0 is also mentioned in this sentence.`n"
Assert-Match (Set-ReleaseInternalNoteLink -Content $twice -Version '3.5.0' -InternalRelPath 'internal/3.x/3.5.0.md') `
    'v3\.5\.0 is also mentioned in this sentence\.' 'a mention outside the table is not rewritten'

Write-Host "Get-PluginManifestPaths" -ForegroundColor Cyan
# Pure (does not touch disk), so a fictional root suffices.
$fakeRoot = 'C:\fake-repo'
$goodJson = '{"plugins": [{"name": "a", "source": "./fam/a"}, {"name": "b", "source": "./fam/b"}]}'
$paths = @(Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson $goodJson)
Assert-Equal 2 $paths.Count 'two registered plugins -> two manifest paths'
Assert-Equal 'C:\fake-repo\fam\a\.claude-plugin\plugin.json' $paths[0] 'relative ./ source resolves within the repo'
Assert-Throws { Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson '{"plugins": [{"name": "x", "source": "../outside"}]}' } 'source with a ..-path outside the repo throws (containment)'
Assert-Throws { Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson '{"plugins": [{"name": "x", "source": "C:\\elsewhere"}]}' } 'absolute source throws (containment)'
Assert-Throws { Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson '{"plugins": [{"name": "x"}]}' } 'missing source throws'
Assert-Throws { Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson '{"name": "empty"}' } 'missing plugins list throws'
Assert-Throws { Get-PluginManifestPaths -RepoRoot $fakeRoot -MarketplaceJson 'not json' } 'corrupt JSON throws'

Write-Host "Get-TouchedPlugins" -ForegroundColor Cyan
# THE ROOTS ARE PASSED IN, so this suite states the layout it is testing against instead of inheriting
# whatever this repo's tree happens to be today. Two sets are used below: a FLAT one and a NESTED
# one -- neither of which has to be this repo's current shape, which is the point. Reading the
# marketplace rather than matching
# '^plugins/<name>/' is that depth stops mattering, and a claim like that is worth an assertion rather
# than a comment.
$flatRoots = @(Get-PluginRoots -RepoRoot $fakeRoot -MarketplaceJson (@'
{"plugins": [
  {"name": "team-alpha",         "source": "./plugins/team-alpha"},
  {"name": "team-lifehub", "source": "./plugins/team-lifehub"}
]}
'@))
$touchedFiles = @(
    'plugins/team-alpha/agents/01-01-chris.md',
    'plugins/team-alpha/manuals/01-01-manual.md',
    'plugins/team-lifehub/agents/foo.md',
    'plugins/agent-shared/inbound-behaviour.md',
    'connectors/some-repo.json',
    'README.md',
    'scripts/lib/release-lib.ps1'
)
$touched = @(Get-TouchedPlugins -Files $touchedFiles -PluginRoots $flatRoots)
Assert-Equal 2 $touched.Count 'two touched plugins (deduplicated + sorted)'
Assert-Equal 'team-alpha' $touched[0] 'first plugin name alphabetically'
Assert-Equal 'team-lifehub' $touched[1] 'second plugin name alphabetically'
# The two non-plugin directories, one on each side of the plugins root after the #405 flattening:
# agent-shared/ sits INSIDE it, connectors/ at the ROOT. Both are asserted, so neither half can quietly
# regress into counting as a plugin. Neither needs excluding by name any more -- a directory that is not
# in the marketplace is not a plugin, which is what makes the pair of assertions cheap to keep.
#
# THIS BLOCK'S LAYOUT IS THE FLAT ONE and is deliberately left that way: $flatRoots is a synthetic fixture
# for the shape this repo used to have, not a picture of the tree. The live position of agent-shared/ --
# one level further down, inside plugins/teams/ -- is asserted in the nested block below, which is the
# one that describes the repo as it is.
Assert-Equal $false ([bool]($touched -contains 'agent-shared')) 'agent-shared is plugin source, not a plugin'
Assert-Equal $false ([bool]($touched -contains 'connectors')) 'connectors folder does not count as a plugin'
Assert-Equal 0 (@(Get-TouchedPlugins -Files @('connectors/life-hub.json') -PluginRoots $flatRoots)).Count 'connectors at the repo root is under no plugin root'
Assert-Equal 0 (@(Get-TouchedPlugins -Files @())).Count 'empty input -> empty set'
Assert-Equal 0 (@(Get-TouchedPlugins -Files $touchedFiles)).Count 'no roots given (a repo that publishes nothing) -> empty set, whatever the paths look like'
Assert-Equal 0 (@(Get-TouchedPlugins -Files @('README.md', 'scripts/lib/release-lib.ps1') -PluginRoots $flatRoots)).Count 'non-plugin paths ignored'
Assert-Equal 0 (@(Get-TouchedPlugins -Files @('plugins/Team-Alpha/agents/x.md') -PluginRoots $flatRoots)).Count 'a differently-cased folder does not count (ordinal comparison)'
# The prefix match is on a whole path SEGMENT, so a sibling whose name merely STARTS WITH a declared
# plugin's name is not swallowed by it. 'plugins/team-alpha-extra' begins with 'plugins/team-alpha'.
#
# BOTH OF THESE HAD TO BE REWRITTEN WITH THE RENAME, and the reason is worth a line: they are the two
# asserts here whose subject is a RELATIONSHIP between two strings, not a string. The rename swept
# 'specialists-shopify' to 'team-shopify' and 'specialists' to 'team-alpha' -- each correct on its own,
# and together they left this pair comparing names that no longer share a prefix and no longer differ
# only in case. Both kept passing, testing nothing. A mechanical rename cannot see that; only reading
# what an assert is FOR can.
Assert-Equal 0 (@(Get-TouchedPlugins -Files @('plugins/team-alpha-extra/agents/x.md') -PluginRoots $flatRoots)).Count 'an unregistered sibling sharing a name prefix does not count as that plugin'
$dedupFiles = @(
    'plugins/team-alpha/agents/a.md',
    'plugins/team-alpha/agents/b.md',
    'plugins/team-alpha/manuals/c.md'
)
$dedupTouched = @(Get-TouchedPlugins -Files $dedupFiles -PluginRoots $flatRoots)
Assert-Equal 1 $dedupTouched.Count 'same plugin across multiple files -> once in the set'
Assert-Equal 'team-alpha' $dedupTouched[0] 'deduplicated name correct'

Write-Host "Get-TouchedPlugins -- a nested plugin tree" -ForegroundColor Cyan
# The layout this repo is moving to: plugins grouped by kind, so a plugin root sits TWO levels down and
# is no longer named after its parent directory. Asserted before that move happens, which is the whole
# reason the derivation landed on its own branch first.
#
# AND SINCE AUGUST 17, 2026 THE NON-PLUGIN SIBLING IS NESTED TOO. agent-shared/ moved from directly under
# plugins/ into plugins/teams/, beside the only plugins that consume its blocks -- so the file below is
# no longer a path that merely fails to reach a plugin root, it is a path that shares a PREFIX with the
# grouping directory the real plugins sit in. That is the harder case, and it is the one this repo now
# has: the old '^plugins/([a-z0-9][a-z0-9-]*)/' regex would have read it as a plugin called 'teams'.
$nestedRoots = @(Get-PluginRoots -RepoRoot $fakeRoot -MarketplaceJson (@'
{"plugins": [
  {"name": "team-alpha",         "source": "./plugins/teams/team-alpha"},
  {"name": "contributing-davekjohn", "source": "./plugins/workflows/contributing-davekjohn"}
]}
'@))
$nestedTouched = @(Get-TouchedPlugins -PluginRoots $nestedRoots -Files @(
    'plugins/teams/team-alpha/agents/06-16-agent.md',
    'plugins/workflows/contributing-davekjohn/skills/open-pr/SKILL.md',
    'plugins/teams/agent-shared/inbound-behaviour.md',
    'README.md'
))
Assert-Equal 2 $nestedTouched.Count 'a plugin two levels down is found'
# THE ORDER IS ALPHABETICAL, NOT INSERTION ORDER, and the #886 rename is what made that visible:
# 'contributing-davekjohn' sorted after 'team-alpha' and 'contributing-davekjohn' sorts before it, so these
# two asserts swapped places without Get-TouchedPlugins changing at all. Left as index asserts rather
# than turned into a set comparison: the ordering IS part of what the function returns, and a set
# comparison would have passed through the rename and told nobody.
Assert-Equal 'contributing-davekjohn' $nestedTouched[0] 'the NAME comes from the marketplace, not from the folder above it'
Assert-Equal 'team-alpha' $nestedTouched[1] 'and so does the second'
Assert-Equal $false ([bool]($nestedTouched -contains 'teams')) 'plugin source nested INSIDE a grouping directory is not read as a plugin named after that directory'
Assert-Equal 0 (@(Get-TouchedPlugins -PluginRoots $nestedRoots -Files @('plugins/teams/agent-shared/lens-optional.md'))).Count 'agent-shared beside the teams it feeds is still under no plugin root'
Assert-Equal 0 (@(Get-TouchedPlugins -PluginRoots $nestedRoots -Files @('plugins/teams/README.md'))).Count 'a file in the grouping directory itself belongs to no plugin'

Write-Host "Get-PluginRoots" -ForegroundColor Cyan
Assert-Equal 'plugins\teams\team-alpha' $nestedRoots[0].RelativeRoot 'RelativeRoot is repo-relative and separator-normalized'
Assert-Equal 'C:\fake-repo\plugins\teams\team-alpha\.claude-plugin\plugin.json' $nestedRoots[0].ManifestPath 'ManifestPath sits under the plugin root'
Assert-Equal './plugins/teams/team-alpha' $nestedRoots[0].Source 'Source is kept exactly as the marketplace wrote it'
Assert-Throws { Get-PluginRoots -RepoRoot $fakeRoot -MarketplaceJson '{"plugins": [{"name": "x", "source": "../outside"}]}' } 'source with a ..-path outside the repo throws (containment)'
Assert-Throws { Get-PluginRoots -RepoRoot $fakeRoot -MarketplaceJson '{"plugins": [{"name": "x", "source": "C:\\elsewhere"}]}' } 'absolute source throws (containment)'

Write-Host "Get-PluginRootByName" -ForegroundColor Cyan
Assert-Equal 'plugins\workflows\contributing-davekjohn' (Get-PluginRootByName -PluginRoots $nestedRoots -Name 'contributing-davekjohn').RelativeRoot 'resolves a name to its root'
Assert-Equal $null (Get-PluginRootByName -PluginRoots $nestedRoots -Name 'workflow-nobody') 'an unknown name resolves to $null rather than a guessed path'
Assert-Equal $null (Get-PluginRootByName -PluginRoots $nestedRoots -Name 'Team-Alpha') 'the lookup is case-sensitive -- a name is a path segment and an install id'
Assert-Equal $null (Get-PluginRootByName -PluginRoots @() -Name 'team-alpha') 'an empty set resolves to $null, it does not throw'

Write-Host "Get-EntryPlugins" -ForegroundColor Cyan
$entryWithPlugins = New-FlatEntry -Heading "#4 $midDot Something" -Rows @('| 1 | 3 | fine |') `
    -Plugins 'team-alpha, team-lifehub' -Pr 4
$plugs = @(Get-EntryPlugins -EntryText $entryWithPlugins)
Assert-Equal 2 $plugs.Count 'two plugins from the Plugins line'
Assert-Equal 'team-alpha' $plugs[0] 'first plugin name correct'
Assert-Equal 0 (@(Get-EntryPlugins -EntryText "## #5 x`n`nBody.")).Count 'no Plugins line -> empty list'

Write-Host "Remove-EntryPluginsLine" -ForegroundColor Cyan
$clean = Remove-EntryPluginsLine -EntryText $entryWithPlugins
Assert-NoMatch $clean '(?m)^Plugins:' 'Plugins line removed'
Assert-NoMatch $clean '(?m)^\s*$\r?\n\s*$\r?\n\s*$' 'no triple blank line left behind'
Assert-Equal "## #5 x`n`nBody." (Remove-EntryPluginsLine -EntryText "## #5 x`n`nBody.") 'entry without a Plugins line stays unchanged'

# RETIRED, AUGUST 8, 2026, with the functions they covered: Convert-EntryLinksForPluginChangelog,
# Build-PluginChangelogIntro, Build-PluginChangelogSection, Add-PluginChangelogSection and
# Build-PluginReleaseCard. The per-plugin CHANGELOG.md and RELEASE.md they built are gone -- a
# consumer already holds the root CHANGELOG.md and releases/ through the marketplace clone, so those
# ten files were a second copy that could disagree with the first. See the retirement note in
# scripts/lib/release-lib.ps1.
#
# Get-EntryPlugins and Remove-EntryPluginsLine above are NOT retired with them: the `Plugins:` line
# still records which plugins an entry touched, and the release notes still read it.
#
# AND SINCE AUGUST 10, 2026 Remove-EntryPluginsLine HAS A PRODUCTION CALLER AGAIN -- Format-RankedEntries
# under -StripAdminSections, for the consumer document. Worth recording because it kept the function alive
# for two days on the strength of a line that still existed rather than a reader that wanted it removed,
# and the reader it was originally written for describes the consumer document exactly.

Write-Host "Get-MarketplaceName" -ForegroundColor Cyan
Assert-Equal 'claude-code-specialists' (Get-MarketplaceName -MarketplaceJson '{ "name": "claude-code-specialists", "plugins": [] }') 'reads the name field'
# Throwing beats returning empty: the two callers write this name into a consumer-facing file and
# compare against it at the gate. An empty string would produce a plausible-looking '()' in the intro
# and a gate holding every file against it, i.e. a wrong answer delivered quietly.
$mpNoName = $false
try { Get-MarketplaceName -MarketplaceJson '{ "plugins": [] }' | Out-Null } catch { $mpNoName = $true }
Assert-Equal $true $mpNoName 'a manifest without a name throws instead of yielding an empty name'
$mpEmptyName = $false
try { Get-MarketplaceName -MarketplaceJson '{ "name": "", "plugins": [] }' | Out-Null } catch { $mpEmptyName = $true }
Assert-Equal $true $mpEmptyName 'an empty name throws too -- present-but-blank is not a name'
# v3.0.0 row lands under '### 2.x' and nothing errors -- a quietly wrong overview in the one document
# whose job is to say which release is which. Never hit before: grouping-by-major arrived in v2.0.1,
# one release AFTER the only major this repo ever cut.
$twoSections = @(
    '# Release notes', '', '## Overview', '', 'Grouped by major version, newest first.', '',
    '### 2.x', '', '| Version | Date | Type | Title |', '|---|---|---|---|',
    '| [2.16.0](development/2.x/2.16.0.md) | 2026-07-30 | Minor | Something |', '',
    '### 1.x', '', '| Version | Date | Type | Title |', '|---|---|---|---|',
    '| [1.18.0](development/1.x/1.18.0.md) | 2026-07-22 | Minor | Older |'
) -join "`n"
Assert-Equal '2' (Get-OverviewTargetMajor -ReadmeContent $twoSections) 'the row lands in the TOP section (2.x), not the last one in the file'
# The whole point: with a 3.x section added on top, the same content answers differently.
$withThree = $twoSections -replace '### 2\.x', "### 3.x`n`n| Version | Date | Type | Title |`n|---|---|---|---|`n`n### 2.x"
Assert-Equal '3' (Get-OverviewTargetMajor -ReadmeContent $withThree) 'once a 3.x section exists on top, that becomes the target -- the guardrail clears'
# It must be the LAST heading before the first table, not the first heading in the file: a document
# whose prose mentions a version heading before the sections start must not fool it.
# NB the trailing '' -- the header pattern requires a newline AFTER the separator row, which every real
# file has and a naively built fixture does not. Without it this asserts $null and blames the function.
$prosey = @('# Notes', '', '## Overview', '', '### 9.x', '', 'Prose only, no table here.', '',
            '### 2.x', '', '| Version | Date | Type | Title |', '|---|---|---|---|', '') -join "`n"
Assert-Equal '2' (Get-OverviewTargetMajor -ReadmeContent $prosey) 'a section heading with no table under it is not the target -- the last one before the first table is'
Assert-Equal $null (Get-OverviewTargetMajor -ReadmeContent "# Empty`n`nNo table at all.") 'no table anywhere -> $null, so the guardrail stays silent rather than guessing'
Assert-Equal $null (Get-OverviewTargetMajor -ReadmeContent "| Version | Date | Type | Title |`n|---|---|---|---|`n") 'a table with no section heading above it -> $null (an ungrouped overview is not this failure mode)'

# BOTH HEADING LEVELS, because the level is a layout choice and pinning one would let a cosmetic edit
# switch the guardrail off in silence. Measured August 4, 2026: this repo's list moved from '###' (a flat
# history page) to '####' (nested under a repo-specific section heading) the day the two release pages
# merged. Under the old '^###' pattern that promotion made this function return $null -- and
# cut-release.ps1 only refuses when a target was FOUND and differs, so no target means no refusal. The
# guardrail would have been off while the document still claimed to be protected.
$lvl3 = "### 2.x`n`n| Version | Date | Type | Title |`n|---|---|---|---|`n"
$lvl4 = "#### 7.x`n`n| Version | Date | Type | Title |`n|---|---|---|---|`n"
Assert-Equal '2' (Get-OverviewTargetMajor -ReadmeContent $lvl3) "a '###' major heading is still read (a flat history page)"
Assert-Equal '7' (Get-OverviewTargetMajor -ReadmeContent $lvl4) "a '####' major heading is read too (nested one deeper under a repo section)"
Assert-Equal $null (Get-OverviewTargetMajor -ReadmeContent "##### 5.x`n`n| Version | Date | Type | Title |`n|---|---|---|---|`n") 'five hashes is NOT accepted -- the tolerance is two levels, not any level'

# A heading that merely CONTAINS a number must not be mistaken for a major section. The merged page has
# '### Tier 1 - development' above the list, which is exactly this shape.
$tiers = "### Tier 1 - development`n`nProse.`n`n#### 3.x`n`n| Version | Date | Type | Title |`n|---|---|---|---|`n"
Assert-Equal '3' (Get-OverviewTargetMajor -ReadmeContent $tiers) "a 'Tier 1 - development' heading above the list is not read as a major"

# Get-OverviewSectionHeading: the literal heading, so a caller can quote it back at the level in use.
# cut-release.ps1's new-major refusal prints it AND derives the heading to add from it; hardcoding '###'
# there told the reader to add a heading the guardrail would not recognise.
Assert-Equal '### 2.x'  (Get-OverviewSectionHeading -ReadmeContent $lvl3)  'the heading is reported verbatim at three hashes'
Assert-Equal '#### 7.x' (Get-OverviewSectionHeading -ReadmeContent $lvl4)  'and verbatim at four'
Assert-Equal '#### 3.x' (Get-OverviewSectionHeading -ReadmeContent $tiers) 'the Tier heading is skipped here as well'
Assert-Equal $null (Get-OverviewSectionHeading -ReadmeContent "# Empty`n`nNo table.") 'no table -> $null, matching Get-OverviewTargetMajor'
# The two functions read the SAME match, so they can never disagree about which section is the target.
Assert-Equal "3" ((Get-OverviewSectionHeading -ReadmeContent $tiers) -replace '^#+\s+' -replace '\.x$') 'the heading and the major agree by construction'
# The live document, asserted on deliberately: this is the value the next release depends on, so it is
# pinned rather than left to inspection. It answered '2' until the 3.x section was opened, which is
# exactly what made a 3.0.0 cut misfile -- and this assertion is what forced that change to be stated
# instead of quietly landing. Update it, with a reason, whenever a new major section is opened.
#
# '3' -> '4' ON AUGUST 9, 2026, when the 4.x section was opened to cut v4.0.0. Recorded because the
# mechanism worked exactly as designed and that is worth one line: cut-release refused the cut rather
# than filing a v4.0.0 row under '#### 3.x', the section was opened by hand because opening a major is a
# milestone the script deliberately does not perform for you, and THIS assert then went red -- so the
# same edit could not land with only half of it done. The pairing is the point: the overview and this
# pin are one fact written twice, and a cut is the one moment they are allowed to disagree.
# The path comes from the repo's own Get-ReleaseHistoryPath rather than being written out again here, and
# that choice has now paid off TWICE IN OPPOSITE DIRECTIONS on the same day (August 4, 2026): the overview
# moved out of releases/README.md into its own HISTORY.md, and then back again when the pages were merged.
# A hardcoded copy would have broken on the first move and broken again on the second -- each time by
# asserting against a file that no longer holds the table, which passes by looking at nothing. That is the
# failure mode this file has caught repeatedly, and the reason a test may not restate a value the repo
# already answers. Probed in a child scope with StrictMode off, the way every other reader of repo-config
# does it.
$liveReadme = Join-Path $PSScriptRoot ('..\..\' + ((& {
    Set-StrictMode -Off
    . (Join-Path $PSScriptRoot '..\repo-config.ps1')
    if (Get-Command Get-ReleaseHistoryPath -ErrorAction SilentlyContinue) { Get-ReleaseHistoryPath } else { 'releases/README.md' }
}) -replace '/', '\'))
if (Test-Path -LiteralPath $liveReadme) {
    Assert-Equal '4' (Get-OverviewTargetMajor -ReadmeContent (Get-Content -LiteralPath $liveReadme -Raw -Encoding UTF8)) "this repo's own overview now targets 4.x -- a 4.0.0 cut lands under its own major, and a 3.x cut would be refused"
}

Write-Host "Get-OverviewLatestVersion -- the release the overview RECORDS as newest (inbound #802)" -ForegroundColor Cyan
# The baseline cut-release bumps from is read from the manifests or the tag line; this is the number the
# overview says the last release was. Where the two disagree the version can still be right while the
# TYPE is wrong in four places at once and in silence -- so the function that makes the comparison
# possible is pinned here.
Assert-Equal '2.16.0' (Get-OverviewLatestVersion -ReadmeContent $twoSections) 'the first row of the TOP table, not the newest row anywhere in the file'
Assert-Equal '1.18.0' (Get-OverviewLatestVersion -ReadmeContent ($twoSections -replace '(?s)^.*?### 1\.x', '### 1.x')) 'and with the 2.x section removed it reads the 1.x one -- same rule, one table down'
# THE EMPTY-TOP-TABLE CASE IS THE ONE THAT MATTERS, because it is not exotic: it is exactly the state a
# freshly opened major section is in, which is the highest-stakes cut there is. Stopping at the first
# table would switch the guardrail off precisely there.
Assert-Equal '2.16.0' (Get-OverviewLatestVersion -ReadmeContent $withThree) 'an empty 3.x table on top does not blind it -- it walks on to the 2.x row'
# Both row shapes, because the link target is a repo-owned layout decision while the version is the fact.
Assert-Equal '5.1.2' (Get-OverviewLatestVersion -ReadmeContent "### 5.x`n`n| Version | Date | Type | Title |`n|---|---|---|---|`n| 5.1.2 | 2026-08-21 | Patch | Bare, unlinked |`n") 'a bare version cell is read'
Assert-Equal '5.1.2' (Get-OverviewLatestVersion -ReadmeContent "### 5.x`n`n| Version | Date | Type | Title |`n|---|---|---|---|`n| ``5.1.2`` | 2026-08-21 | Patch | Backticked |`n") 'a backticked version cell is read'
Assert-Equal $null (Get-OverviewLatestVersion -ReadmeContent "# Empty`n`nNo table at all.") 'no table -> $null, so the guardrail stays silent rather than guessing'
Assert-Equal $null (Get-OverviewLatestVersion -ReadmeContent "| Version | Date | Type | Title |`n|---|---|---|---|`n") 'a header with no rows under it -> $null (a brand-new overview is not a disagreement)'
# The version is read from the FIRST CELL, not from anywhere in the row: a malformed version cell must
# come back as "nothing recorded" rather than as whatever number the Title column happens to carry.
Assert-Equal $null (Get-OverviewLatestVersion -ReadmeContent "| Version | Date | Type | Title |`n|---|---|---|---|`n| (pending) | 2026-08-21 | Patch | see 1.2.3 for the last one |`n") 'a version-less first cell is not rescued by a number later in the row'

# THE LIVE INVARIANT, and unlike the pin above it maintains itself: this repo's overview and its lockstep
# manifests must name the same release. That is precisely what the new guardrail refuses a cut over, so
# asserting it here means the repo cannot drift into the state that would block its own next release
# without a suite saying so first. No number is written down, so no cut has to come back and edit this.
if (Test-Path -LiteralPath $liveReadme) {
    $liveLatest = Get-OverviewLatestVersion -ReadmeContent (Get-Content -LiteralPath $liveReadme -Raw -Encoding UTF8)
    $liveManifests = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '..\..\plugins') -Recurse -Filter 'plugin.json' -File |
        ForEach-Object { if ((Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -match '"version"\s*:\s*"([^"]+)"') { $Matches[1] } } | Sort-Object -Unique)
    Assert-Equal 1 $liveManifests.Count 'the plugin manifests are in lockstep on one version (which is what makes a single baseline meaningful)'
    Assert-Equal $liveManifests[0] $liveLatest "the overview's newest row and the lockstep manifest version name the same release -- the disagreement inbound #802 reported would refuse a cut here"
}

Write-Host "Test-ReleaseBumpEarned -- the bump has to be earned" -ForegroundColor Cyan
function New-TierGroup {
    <# A pending-tier group as Get-PullRequestEntriesByTier returns one, Declared field included. #>
    param([int]$Tier, [int]$Count, [int]$Declared = -1)
    $items = @()
    for ($i = 1; $i -le $Count; $i++) { $items += "## #$i x" }
    if ($Declared -lt 0) { $Declared = $Count }
    return [pscustomobject]@{ Tier = $Tier; Entries = $items; Declared = $Declared }
}
$g210 = @((New-TierGroup 2 1), (New-TierGroup 1 1), (New-TierGroup 0 3))
$g10  = @((New-TierGroup 2 0), (New-TierGroup 1 2), (New-TierGroup 0 1))
$g0   = @((New-TierGroup 2 0), (New-TierGroup 1 0), (New-TierGroup 0 4))
# THE BUMP FOLLOWS THE HIGHEST TIER PENDING (Dave, August 7, 2026): tier 0 only -> patch; tier 1 or
# higher -> minor. Both rows below changed on that day, and both loosened by one step -- a tier-0-only
# release used to be refused outright, and a minor used to demand a tier-2 entry.
#
# A tier-2 entry pending: patch and minor are both allowed (a minor is not compulsory).
Assert-Equal $true (Test-ReleaseBumpEarned -BumpType patch -TierGroups $g210 -CurrentVersion '3.4.0').Earned 'tier 2 pending: a patch is allowed'
Assert-Equal $true (Test-ReleaseBumpEarned -BumpType minor -TierGroups $g210 -CurrentVersion '3.4.0').Earned 'tier 2 pending: a minor is earned'
Assert-Equal 'minor' (Test-ReleaseBumpEarned -BumpType patch -TierGroups $g210 -CurrentVersion '3.4.0').EarnedBump 'tier 2 pending: the work warrants a minor'
# Only tier 1: a MINOR is earned now, where this used to be a patch with the minor refused. The version
# here speaks to all stakeholders, colleagues included -- and the DOCUMENTS still follow the tier, so such
# a release writes the internal note and no consumer document (asserted on cut-release's own condition).
Assert-Equal $true (Test-ReleaseBumpEarned -BumpType patch -TierGroups $g10 -CurrentVersion '3.4.0').Earned 'tier 1 only: a patch is still allowed'
$minorTier1 = Test-ReleaseBumpEarned -BumpType minor -TierGroups $g10 -CurrentVersion '3.4.0'
Assert-Equal $true $minorTier1.Earned 'tier 1 only: a minor is EARNED -- something beyond this repo got value'
Assert-Equal 'minor' $minorTier1.EarnedBump 'and the work warrants exactly that'
Assert-Equal '' $minorTier1.Reason 'so there is nothing to refuse'
# Nothing but tier 0: a PATCH, where this used to be refused outright. Publishing to no audience is what
# a patch is for; the minor is what gets refused, by name.
$tier0Only = Test-ReleaseBumpEarned -BumpType patch -TierGroups $g0 -CurrentVersion '3.4.0'
Assert-Equal $true $tier0Only.Earned 'tier 0 only: a patch is earned -- a release with nothing to announce is a patch'
Assert-Equal 'patch' $tier0Only.EarnedBump 'and that is what the work warrants'
$tier0Minor = Test-ReleaseBumpEarned -BumpType minor -TierGroups $g0 -CurrentVersion '3.4.0'
Assert-Equal $false $tier0Minor.Earned 'tier 0 only: a minor is refused'
Assert-Equal 'patch' $tier0Minor.EarnedBump 'and the refusal names the bump that would work'
Assert-Match $tier0Minor.Reason 'everything pending is tier 0' 'the reason says what is missing'
# The major rule: ten minors in this major line, read off the version's minor component.
$majorEarly = Test-ReleaseBumpEarned -BumpType major -TierGroups $g210 -CurrentVersion '3.4.0'
Assert-Equal $false $majorEarly.Earned 'major at 3.4.0: four minors is not ten'
Assert-Equal $false $majorEarly.MajorAvailable 'and a major is reported unavailable'
Assert-Match $majorEarly.Reason 'had 4 of them' 'the reason counts the minors so far'
$majorReady = Test-ReleaseBumpEarned -BumpType major -TierGroups $g210 -CurrentVersion '3.10.0'
Assert-Equal $true $majorReady.Earned 'major at 3.10.0: ten minors, so it is allowed'
Assert-Equal $true $majorReady.MajorAvailable 'and reported available'
Assert-Equal 'minor' $majorReady.EarnedBump 'EarnedBump never says major -- ten minors is a milestone, not a size the work adds up to'
# A major still needs the general minimum: ten minors do not license a release made of nothing.
Assert-Equal $false (Test-ReleaseBumpEarned -BumpType major -TierGroups $g0 -CurrentVersion '3.10.0').Earned 'major at 3.10.0 with only tier 0: still refused'
# Tier 1 only, ten minors: a major is permitted (its justification is the minors, not a pending tier 2).
Assert-Equal $true (Test-ReleaseBumpEarned -BumpType major -TierGroups $g10 -CurrentVersion '3.10.0').Earned 'major needs no pending tier-2 entry -- the minors behind it are what earn it'
# The threshold is repo-owned.
Assert-Equal $true (Test-ReleaseBumpEarned -BumpType major -TierGroups $g210 -CurrentVersion '3.4.0' -MinMinorsForMajor 4).Earned 'the minors threshold is configurable'
Assert-Throws { Test-ReleaseBumpEarned -BumpType patch -TierGroups $g210 -CurrentVersion 'x.y.z' } 'a malformed current version throws rather than guessing the minor count'

Write-Host "Test-ReleaseBumpEarned -- Active keys on Declared, not on a section count" -ForegroundColor Cyan
# THE LANDMINE THIS REPLACES. The flag used to be "more than one tier section exists", which had a real
# basis while the changelog declared its tiers as headings. A flat changelog has none, so an unadopted
# repo and an adopting one both produce exactly one group -- and the old line would have read every repo
# as not adopting, switching the gate off in silence in the same change that made the tier the model's
# primary fact. Nothing would have errored.
$declaredZeroOnly = @((New-TierGroup 0 3 3))
$onT0 = Test-ReleaseBumpEarned -BumpType patch -TierGroups $declaredZeroOnly -CurrentVersion '3.4.0'
Assert-Equal $true $onT0.Active 'one group, but its entries DECLARED tier 0: the gate is active'
Assert-Equal $true $onT0.Earned 'and allows the PATCH it warrants -- a release with nothing to announce is what a patch is'
Assert-Equal $false (Test-ReleaseBumpEarned -BumpType minor -TierGroups $declaredZeroOnly -CurrentVersion '3.4.0').Earned 'while still refusing the minor, so being active still means something'
# AND OFF WHERE NOTHING DECLARED ANYTHING. This is what keeps the shared script safe for a consumer that
# never adopted the model: their entries have no table and no 'Tier:' line, every one reads as tier 0, and
# the opposite reading would refuse every release they ever cut.
$noneDeclared = @((New-TierGroup 0 3 0))
$off = Test-ReleaseBumpEarned -BumpType minor -TierGroups $noneDeclared -CurrentVersion '3.4.0'
Assert-Equal $false $off.Active 'nothing declared: the gate reports itself inactive'
Assert-Equal $true $off.Earned 'and does not refuse'
# A single declared entry anywhere is enough to switch it on -- adoption is a property of the repo, not
# of the individual entry being judged.
$mixed = @((New-TierGroup 2 1 1), (New-TierGroup 0 2 0))
Assert-Equal $true (Test-ReleaseBumpEarned -BumpType minor -TierGroups $mixed -CurrentVersion '3.4.0').Active 'one declared entry among undeclared ones switches the gate on'
# A GROUP BUILT WITHOUT THE FIELD must not throw or be read as declared. Callers and tests build these
# by hand, and $g.Declared on an object lacking it is $null -- read as 0, which is the silent direction,
# so the function tests PSObject.Properties instead of reading the property.
$noField = @([pscustomobject]@{ Tier = 1; Entries = @('## #1 x') })
$bare = Test-ReleaseBumpEarned -BumpType patch -TierGroups $noField -CurrentVersion '3.4.0'
Assert-Equal $false $bare.Active 'a group with no Declared field reads as undeclared rather than throwing'
Assert-Equal $true $bare.Earned 'so the gate stays out of the way'
# The real thing, end to end: groups straight out of the parser, on the shared sample.
$liveGate = Test-ReleaseBumpEarned -BumpType minor -TierGroups $groups -CurrentVersion '3.4.0'
Assert-Equal $true $liveGate.Active 'groups from Get-PullRequestEntriesByTier report themselves declared'
Assert-Equal $true $liveGate.Earned 'and the sample release earns its minor (it has a tier-2 entry)'
Assert-Equal 1 $liveGate.Counts[2] 'the counts come from the parsed groups'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
