<#
.SYNOPSIS
    Regression tests for scripts/lib/release-lib.ps1 (the pure release helpers).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Dot-sources the lib and runs a series of
    asserts. Exit code 0 if everything passes, 1 on the first failure -- so usable as a CI gate.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/release-lib.tests.ps1

    Pure ASCII (repo convention for .ps1). Expected non-ASCII output characters (middot, em-dash)
    are built via [char]0x.. , just like in the lib itself.

    NOTE (Sylvester, English script-layer sweep, #114 follow-up): both the DOCUMENT-GENERATING
    template strings this suite asserts against (category headings, the reference/date labels, the
    ## Releases genesis intro) and the fixture sample strings (entry titles/bodies, link text) are
    English, matching release-lib.ps1's own follow-up -- see the NOTE in its file header. Fixture
    content is arbitrary stand-in text for contributor-authored PR entries; it is English for
    repo-wide consistency, not because its language is what is under test here.
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

function Assert-Throws {
    param([scriptblock]$Block, [string]$Name)
    try { & $Block; $script:fail++; Write-Host "  [FAIL] $Name (expected an exception)" -ForegroundColor Red }
    catch { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
}

$midDot = [char]0x00B7
$emDash = [char]0x2014

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

# Shared sample CHANGELOG for the transformation tests.
$sample = @"
# Changelog

Intro line of the file.

## Pull Requests

Intro of the PR section.

### #2 $midDot Second feature $midDot Feat $midDot 2026-01-02

Body two.

[PR #2](https://example.com/2)

---

### #1 $midDot First fix $midDot Fix $midDot 2026-01-01

Body one.

[PR #1](https://example.com/1)

## Releases

No releases recorded yet. Versioning runs per plugin.
"@

Write-Host "Get-PullRequestEntries" -ForegroundColor Cyan
$entries = @(Get-PullRequestEntries -Content $sample)
Assert-Equal 2 $entries.Count 'two entries extracted'
Assert-Match $entries[0] '^### #2 ' 'first entry starts with ### #2'
Assert-Match $entries[0] '\[PR #2\]' 'first entry contains the PR link'
Assert-Throws { Get-PullRequestEntries -Content "# Changelog`n`n## Pull Requests`n`nIntro.`n`n## Releases`n" } 'empty PR section throws'

Write-Host "Get-FencedLineFlags" -ForegroundColor Cyan
$fenceLines = @('### real', 'text', '```', '### QUOTED', '---', '```', '---', '### real2')
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
$openFlags = Get-FencedLineFlags -Lines @('text', '```', '### QUOTED')
Assert-Equal $true $openFlags[2] 'flags: an unclosed fence keeps the tail fenced (safe direction)'
# A section can legitimately be a single empty line; a Mandatory [string[]] used to reject that.
Assert-Equal 1 (@(Get-FencedLineFlags -Lines @('')).Count) 'flags: an empty line binds without throwing'

Write-Host "Get-PullRequestEntries -- fenced code is not structure" -ForegroundColor Cyan
# The v2.13.3 defect: an entry body that QUOTES a '### #NN' heading inside a fence produced a third
# entry from two, split the fence open, and duplicated a category heading in the generated notes.
# Also covers the '---' separator, which was skipped anywhere -- including inside a fence, which would
# strip a YAML frontmatter example out of a quoted block.
$fencedSample = @(
    '# Changelog', '', '## Pull Requests', '', 'Intro.', '',
    '### #11 ' + [char]0x00B7 + ' Real entry ' + [char]0x00B7 + ' Fix ' + [char]0x00B7 + ' 2026-07-29', '',
    'Shows what a broken structure looks like:', '',
    '```', '## Fixes', '### #99 ' + [char]0x00B7 + ' quoted heading', '---', 'id: 1', '```', '',
    '[PR #11](https://example.test/11)', '',
    '---', '',
    '### #12 ' + [char]0x00B7 + ' Second entry ' + [char]0x00B7 + ' Docs ' + [char]0x00B7 + ' 2026-07-29', '',
    'Body.', '', '[PR #12](https://example.test/12)', '',
    '## Releases', '', 'Rel intro.', '', '### [v1.0.0] - 2026-01-01 - Minor', ''
) -join "`n"
$fencedEntries = @(Get-PullRequestEntries -Content $fencedSample)
Assert-Equal 2 $fencedEntries.Count 'fenced: two entries, not three -- the quoted heading is not a new entry'
Assert-Match $fencedEntries[0] '^### #11 ' 'fenced: the first entry is the real one'
Assert-Match $fencedEntries[0] '### #99' 'fenced: the quoted heading is KEPT inside the entry body'
Assert-Match $fencedEntries[0] '(?m)^id: 1$' 'fenced: a --- inside the fence does not strip the lines after it'
$fenceCount = @([regex]::Matches($fencedEntries[0], '(?m)^```')).Count
Assert-Equal 2 $fenceCount 'fenced: the fence survives intact (both markers present)'
Assert-Match $fencedEntries[1] '^### #12 ' 'fenced: the second entry is the next real one'

Write-Host "Convert-ChangelogForRelease (reference)" -ForegroundColor Cyan
$notesPath = 'releases/development/0.x/0.2.0.md'
$result = Convert-ChangelogForRelease -Content $sample -Version '0.2.0' -Date '2026-07-14' -Type 'Minor' -NotesRelPath $notesPath
Assert-Match $result '### \[v0\.2\.0\] - 2026-07-14 .* Minor' 'reference heading with version/date/type'
Assert-Match $result ([regex]::Escape("[$notesPath]($notesPath)")) 'reference to the notes file'
$prSection = ($result -split '## Releases')[0]
Assert-Equal $false ([bool]($prSection -match '(?m)^### ')) 'Pull Requests section no longer contains entries'
Assert-Match $result '(?s)Intro of the PR section' 'PR intro remains'
Assert-Equal $false ([bool]($result -match '(?m)^- #\d')) 'no inline PR bullets anymore (reference only)'

Write-Host "Convert-ChangelogForRelease (genesis intro, no prior releases)" -ForegroundColor Cyan
$genesisResult = Convert-ChangelogForRelease -Content $sample -Version '0.1.0' -Date '2026-07-14' -Type 'Minor' -NotesRelPath $notesPath
Assert-Match $genesisResult 'The recorded versions of the marketplace .* newest at the top' 'genesis ## Releases intro (no prior releases yet) is English'

Write-Host "Get-OverviewTargetMajor (where a new row would actually land)" -ForegroundColor Cyan
# The row inserter matches the FIRST '| Version | Date | Type | Title |' header, so on a major bump a
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
# The live document, asserted on deliberately: this is the value the next release depends on, so it is
# pinned rather than left to inspection. It answered '2' until the 3.x section was opened, which is
# exactly what made a 3.0.0 cut misfile -- and this assertion is what forced that change to be stated
# instead of quietly landing. Update it, with a reason, whenever a new major section is opened.
$liveReadme = Join-Path $PSScriptRoot '..\..\releases\README.md'
if (Test-Path -LiteralPath $liveReadme) {
    Assert-Equal '3' (Get-OverviewTargetMajor -ReadmeContent (Get-Content -LiteralPath $liveReadme -Raw -Encoding UTF8)) "this repo's own overview now targets 3.x -- a 3.0.0 cut lands under its own major, and a 2.x cut would be refused"
}

Write-Host "Build-ReleaseNotes" -ForegroundColor Cyan
$notes = Build-ReleaseNotes -Entries $entries -Version '0.2.0' -Date '2026-07-14' -Type 'Minor' -Title 'Test-release'
Assert-Match $notes '^# Release notes v0\.2\.0' 'heading with version'
Assert-Match $notes '\*\*Date:\*\* 2026-07-14' 'date line'
Assert-Match $notes '\*\*Type:\*\* Minor' 'type line'
Assert-Match $notes 'Test-release' 'title included'
Assert-Match $notes '## Features' 'Feat category section'
Assert-Match $notes '## Fixes' 'Fix category section'
Assert-Match $notes '(?s)## Features.*## Fixes' 'Feat comes before Fix (category order)'
Assert-Match $notes '### #2 .* Second feature' 'entry #2 present with full heading'
Assert-Match $notes '\[PR #1\]' 'PR link of entry #1 preserved'
# -Summary is opt-in: an ordinary release must be byte-identical to before the parameter existed.
$notesNoSummary = Build-ReleaseNotes -Entries $entries -Version '0.2.0' -Date '2026-07-14' -Type 'Minor' -Title 'Test-release' -Summary ''
Assert-Equal $notes $notesNoSummary 'no -Summary: output byte-identical to the call without the parameter'

Write-Host "Build-ReleaseNotes -Summary (a milestone release carries an authored block)" -ForegroundColor Cyan
# The arc across many releases fits in neither -Title (one sentence) nor the entries (per-PR), and
# hand-editing a generated file is not a repeatable release. Assertions are about POSITION and
# BOUNDARY, because that is what makes an authored block readable as authored.
$sum = "## What 2.x was about`r`n`r`nA sentence with CRLF endings and a [root link](README.md)."
$ms = Build-ReleaseNotes -Entries $entries -Version '3.0.0' -Date '2026-07-30' -Type 'Major' -Title 'A milestone' -Summary $sum
Assert-Match $ms '## What 2\.x was about' 'summary: the authored heading is present'
Assert-Match $ms '(?s)\*\*Type:\*\* Major.*A milestone.*## What 2\.x was about' 'summary: sits after the header and the title line'
Assert-Match $ms '(?s)## What 2\.x was about.*\n---\n.*## Features' 'summary: separated from the generated entries by a horizontal rule'
Assert-Equal $false ([bool]($ms -match "`r")) 'summary: CRLF input is normalized to LF like every other block in this file'
# A root-relative link inside the SUMMARY is deliberately NOT rewritten: unlike an entry (which was
# authored in the root CHANGELOG and then moved three folders deeper), a summary is authored for this
# file and its links are already relative to it. Rewriting them would break the ones that were right.
Assert-Match $ms '\[root link\]\(README\.md\)' 'summary: its links are left exactly as authored -- it was written for this file, not moved into it'

Write-Host "Build-ReleaseNotes (full category label coverage: Docs, Chore, Other)" -ForegroundColor Cyan
# Feat/Fix are already covered above; this closes the gap for the other two canonical category
# labels (Docs, Chore) plus the 'Other' catch-all for an entry whose type is not a known branch
# type at all -- guards the category order/labels (Get-ReleaseCategories) staying in sync.
$docsEntry  = "### #10 $midDot Docs sample $midDot Docs $midDot 2026-01-10`n`nBody docs.`n`n[PR #10](https://example.com/10)"
$choreEntry = "### #11 $midDot Chore sample $midDot Chore $midDot 2026-01-11`n`nBody chore.`n`n[PR #11](https://example.com/11)"
$otherEntry = "### #12 $midDot Other sample $midDot Weird $midDot 2026-01-12`n`nBody weird.`n`n[PR #12](https://example.com/12)"
$catEntries = @($entries[0], $entries[1], $docsEntry, $choreEntry, $otherEntry)
$catNotes = Build-ReleaseNotes -Entries $catEntries -Version '0.3.0' -Date '2026-07-21' -Type 'Minor'
Assert-Match $catNotes '## Documentation' 'Docs category renders as Documentation'
Assert-Match $catNotes '## Maintenance' 'Chore category renders as Maintenance'
Assert-Match $catNotes '## Other' 'unrecognized type falls into the Other catch-all category'
Assert-Match $catNotes '(?s)## Features.*## Fixes.*## Documentation.*## Maintenance.*## Other' 'category order: Feat, Fix, Docs, Chore, Other (canonical branch types + catch-all)'
Assert-Match $catNotes '### #12 .* Other sample' 'entry with an unrecognized type still included under Other (not dropped)'

# Link rewriting: repo-root-relative links get the prefix, external/anchor do not.
$linkEntry = @("### #3 $midDot Something $midDot Fix $midDot 2026-01-03", '', 'See [the lint](scripts/lint/x.ps1) and [the site](https://example.com) and [#heading](#heading).', '', '[PR #3](https://example.com/3)') -join "`n"
$ln = Build-ReleaseNotes -Entries @($linkEntry) -Version '0.2.1' -Date '2026-07-14' -Type 'Patch' -LinkPrefix '../../../'
Assert-Match $ln '\[the lint\]\(\.\./\.\./\.\./scripts/lint/x\.ps1\)' 'root-relative link gets the ../../../ prefix'
Assert-Match $ln '\[the site\]\(https://example\.com\)' 'external link untouched'
Assert-Match $ln '\[#heading\]\(#heading\)' 'anchor link untouched'
Assert-Match $ln '\[PR #3\]\(https://example\.com/3\)' 'PR link untouched'

Write-Host "Get-ReleaseCategories + Format-CategorizedEntries (shared grouping, short labels)" -ForegroundColor Cyan
$cats = Get-ReleaseCategories
Assert-Equal 'Features' $cats.Title['Feat'] 'short label: Feat -> Features'
Assert-Equal 'Fixes' $cats.Title['Fix'] 'short label: Fix -> Fixes'
Assert-Equal 'Documentation' $cats.Title['Docs'] 'short label: Docs -> Documentation'
Assert-Equal 'Maintenance' $cats.Title['Chore'] 'short label: Chore -> Maintenance'
Assert-Equal 'Other' $cats.Order[$cats.Order.Count - 1] 'Other is the last (catch-all) category'
# $entries[0] is #2 (Feat), $entries[1] is #1 (Fix) from the shared $sample above.
$fce2 = Format-CategorizedEntries -Entries @($entries[0], $entries[1]) -CategoryLevel 2
Assert-Match $fce2 '(?m)^## Features' 'CategoryLevel 2 -> ## category heading'
Assert-Match $fce2 '(?m)^### #2 ' 'CategoryLevel 2 -> entries stay at ### (one level under the ## category)'
Assert-Match $fce2 '(?s)## Features.*## Fixes' 'categories rendered in canonical order (Feat before Fix)'
$fce3 = Format-CategorizedEntries -Entries @($entries[0]) -CategoryLevel 3
Assert-Match $fce3 '(?m)^### Features' 'CategoryLevel 3 -> ### category heading'
Assert-Match $fce3 '(?m)^#### #2 ' 'CategoryLevel 3 -> entry demoted to #### (one level under the ### category)'
$fceUnknown = Format-CategorizedEntries -Entries @("### #99 $midDot Mystery $midDot Weird $midDot 2026-01-09`n`nBody.") -CategoryLevel 2
Assert-Match $fceUnknown '(?m)^## Other' 'unknown type falls into the Other catch-all'

Write-Host "issue #417 -- the two halves of Get-ReleaseCategories are repo-owned and probed" -ForegroundColor Cyan
# THE OVERRIDE IS MERGED, NOT SUBSTITUTED. A repo that renames one category must not have to restate
# the other four, and 'Other' has to keep a label whatever the repo says -- an entry with an unknown
# type is exactly the one a reader most needs a heading for.
function Get-ReleaseCategoryTitles { return @{ Fix = 'Bugs'; Chore = 'Overig' } }
$catsOverridden = Get-ReleaseCategories
Assert-Equal 'Bugs' $catsOverridden.Title['Fix'] 'category titles: the repo override wins for the type it names'
Assert-Equal 'Overig' $catsOverridden.Title['Chore'] 'category titles: and for the second one'
Assert-Equal 'Features' $catsOverridden.Title['Feat'] 'category titles: a type the override does not mention keeps the default -- merged, not substituted'
Assert-Equal 'Other' $catsOverridden.Title['Other'] 'category titles: the catch-all keeps a label whatever the repo overrides'
$fceNl = Format-CategorizedEntries -Entries @($entries[1]) -CategoryLevel 2
Assert-Match $fceNl '(?m)^## Bugs' 'category titles: the override reaches the rendered heading, not just the map'
Remove-Item Function:\Get-ReleaseCategoryTitles
Assert-Equal 'Fixes' (Get-ReleaseCategories).Title['Fix'] 'category titles: with the repo function gone, the English default is back'

Write-Host "issue #417 -- Convert-ChangelogForRelease and the LIVE marker" -ForegroundColor Cyan
# The marker MOVES: it is stripped wherever it sits and re-applied to the new heading. A marker that
# accumulated would say two releases are live at once, which is worse than saying none is.
# INTERPOLATED, not concatenated -- and that is load-bearing rather than style.
#
# THE MECHANISM, because "use interpolation here" is a rule nobody can apply elsewhere: in PowerShell
# the comma operator binds TIGHTER than '+'. So inside a comma-separated array literal the '+' does not
# join its two neighbouring strings at all -- it joins the ARRAY on its left to the ARRAY on its right:
#
#     @( 'H', '', 'A' + $x + 'B', '', 'T' )   is   ( ('H','','A') + $x + ('B','','T') )
#
# which is 7 elements where 5 were written, verified element-for-element against that regrouping. The
# following -join "`n" then puts newlines exactly where the concatenation was meant to be. Both headings
# below used to reach Split-Changelog already broken across three lines, with the middot and the em-dash
# each alone on one, and the function passed that through faithfully.
#
# THE SECOND FORM IS QUIETER AND HAS NO LOOSE LINE TO SPOT. When there is no comma to the LEFT, the
# left operand is a plain string, so string concatenation wins and the array on the right is flattened
# into it with $OFS (a space) between the parts:
#
#     @( 'A' + $x + 'B', 'T' )   ->   ONE element, the string "A<em-dash>B T"
#
# That one produces no bare-separator line, so the checks below would not catch it -- it just silently
# swallows the next element. Assigning the concatenation to a variable first, or interpolating as this
# fixture now does, gives the elements that were written in both shapes.
#
# Searched across every .ps1 in the repo when this was found: no other instance of either shape. The
# other '+'-built strings are assignments or single expressions, where there is no comma to bind to.
# See the comment above the strong assert further down for what this one cost.
$clLive = @(
    '# Changelog', '',
    '## Pull Requests', '',
    'Merged PRs land here.', '',
    "### #7 $midDot An entry $midDot Fix $midDot 2026-02-01", '',
    'Body.', '',
    '## Releases', '',
    'The recorded versions.', '',
    "### [v1.0.0] - 2026-01-01 $emDash Minor <- **LIVE**", '',
    'See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.'
) -join "`n"
# The fixture is asserted before it is used. This whole section was built on a fixture that did not
# contain what it was written to contain, and nothing said so -- so the shape gets a check of its own.
$clLiveLines = @($clLive -split "`n")
Assert-Equal 17 $clLiveLines.Count 'LIVE fixture: 17 lines, i.e. each heading is ONE line rather than split at its separator'
Assert-Equal 0 @($clLiveLines | Where-Object { $_ -eq $emDash -or $_ -eq $midDot }).Count 'LIVE fixture: no line consists of a bare separator'
$outLive = Convert-ChangelogForRelease -Content $clLive -Version '1.1.0' -Date '2026-02-02' -Type 'Minor' `
    -NotesRelPath 'releases/development/1.x/1.1.0.md' -LiveMarker '<- **LIVE**'
Assert-Match $outLive '(?m)^### \[v1\.1\.0\] - 2026-02-02 .* Minor <- \*\*LIVE\*\*$' 'LIVE marker: the new release heading carries it'
Assert-Equal 1 ([regex]::Matches($outLive, [regex]::Escape('<- **LIVE**')).Count) 'LIVE marker: exactly one, so it moved rather than accumulated'
Assert-Equal $false ([bool]($outLive -match '(?m)^### \[v1\.0\.0\].*LIVE')) 'LIVE marker: the previous release no longer claims to be live'
# And the default is byte-for-byte what this workshop has always produced -- the knob is inert unless
# a repo asks for it, which is the whole contract of every optional seam function.
$outPlain = Convert-ChangelogForRelease -Content $clLive -Version '1.1.0' -Date '2026-02-02' -Type 'Minor' `
    -NotesRelPath 'releases/development/1.x/1.1.0.md'
Assert-Equal $false ([bool]($outPlain -match '(?m)^### \[v1\.1\.0\].*LIVE')) 'no LIVE marker: none is written'
# The invariant is that the marker is NOT stripped -- a repo that does not use the knob must not have
# an existing marker quietly removed by a release. Asserted on the WHOLE heading line, anchored.
#
# This assert used to stop at the marker substring, "deliberately NOT on the whole heading line",
# because an em-dash in an existing '## Releases' heading came back on a line of its own -- said to
# reproduce against release-lib on main, and therefore not that change's doing. The SYMPTOM was real.
# The CAUSE was this fixture, and release-lib never had anything to do with it.
#
# Measured August 4, 2026: the fixture above was built as `'...' + $emDash + '...'` inside a
# comma-separated array literal, which PowerShell reads as THREE elements rather than one concatenation
# -- 7 elements where 5 were written -- after which `-join "`n"` turned the seams into newlines. Both
# headings reached Split-Changelog already broken across three lines. So the function was handed a
# document whose heading really did have a bare em-dash on line 2, and it passed that through faithfully.
#
# That is also why it never reproduced against the repo's real CHANGELOG.md, which was checked three
# times and taken as evidence that "the cause is not isolated": that file is READ FROM DISK, so it never
# passes through the construction that caused it. Fed straight through Convert-ChangelogForRelease the
# real document comes out clean -- the '## Releases' section goes from 73 em-dashes to 74, exactly the
# one new heading, with all 72 existing headings returned character-for-character and zero lines holding
# a lone em-dash.
#
# The cost of the weakening was real: the test asserted only that the marker survived, not that the
# heading carrying it came over intact -- and the thing hiding behind that gap was a broken fixture, i.e.
# every assertion in this section was running against a document nobody had written. The strong form runs
# now, the fixture is checked before it is used, and the assert below turns the original report into a
# standing check: if a bare separator line is ever produced for real, it fails here instead of being
# explained here.
$strongHeading = '(?m)^### \[v1\.0\.0\] - 2026-01-01 ' + [regex]::Escape($emDash) + ' Minor <- \*\*LIVE\*\*$'
Assert-Match $outPlain $strongHeading 'no LIVE marker: the carried-over heading comes over intact, em-dash and marker inline'
Assert-Equal 1 ([regex]::Matches($outPlain, [regex]::Escape('<- **LIVE**')).Count) 'no LIVE marker: and it is still the only one'
# The reported defect, as a test: no output line may consist of an em-dash on its own. Asserted on both
# branches, because the report never said which one it was supposed to happen on.
foreach ($probe in @(@{ N = 'knob off'; V = $outPlain }, @{ N = 'knob on'; V = $outLive })) {
    $lonely = @(($probe.V -split "`r?`n") | Where-Object { $_.Trim() -eq $emDash })
    Assert-Equal 0 $lonely.Count "$($probe.N): no line consists of an em-dash alone (the reported defect, as a check)"
}

Write-Host "history mode + section order (August 4, 2026)" -ForegroundColor Cyan
# One fixture, used for every case below, so a difference in output is a difference in the argument
# rather than in the input. Built with interpolation for the reason documented at $clLive above.
$hmBase = @(
    '# Changelog', '',
    'Intro line.', '',
    '## Pull Requests', '',
    'Merged PRs land here.', '',
    "### #7 $midDot An entry $midDot Fix $midDot 2026-02-01", '',
    'Body.', '',
    '## Releases', '',
    'The recorded versions.', '',
    "### [v1.0.0] - 2026-01-01 $emDash Minor", '',
    'See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.'
) -join "`n"
$hmArgs = @{ Version = '1.1.0'; Date = '2026-02-02'; Type = 'Minor'; NotesRelPath = 'releases/development/1.x/1.1.0.md' }

# 'all' is the default AND is byte-for-byte the old behaviour -- asserted by comparing an explicit
# 'all' against omitting the parameter entirely. Without this, a later change to the default would
# silently rewrite every consumer's changelog that never asked for anything.
$hmAll     = Convert-ChangelogForRelease -Content $hmBase @hmArgs -HistoryMode 'all'
$hmDefault = Convert-ChangelogForRelease -Content $hmBase @hmArgs
Assert-Equal $hmAll $hmDefault "history: omitting -HistoryMode is byte-identical to 'all'"
Assert-Match $hmAll '(?m)^## Releases$' "history 'all': the heading stays '## Releases'"
Assert-Match $hmAll ([regex]::Escape('### [v1.0.0]')) "history 'all': the previous release is still there"
Assert-Equal 2 ([regex]::Matches($hmAll, '(?m)^### \[v')).Count "history 'all': two blocks, the new one and the old"

$hmLatest = Convert-ChangelogForRelease -Content $hmBase @hmArgs -HistoryMode 'latest' -HistoryRelPath 'releases/HISTORY.md'
Assert-Match $hmLatest '(?m)^## Latest Release$' "history 'latest': the heading becomes '## Latest Release'"
Assert-Equal $false ([bool]($hmLatest -match '(?m)^## Releases$')) "history 'latest': and the old heading is gone, not both"
Assert-Equal 1 ([regex]::Matches($hmLatest, '(?m)^### \[v')).Count "history 'latest': exactly one block"
Assert-Match $hmLatest ([regex]::Escape('### [v1.1.0]')) "history 'latest': and it is the NEW release, not the old one"
Assert-Equal $false ([bool]($hmLatest -match [regex]::Escape('### [v1.0.0]'))) "history 'latest': the previous block is dropped"
Assert-Match $hmLatest ([regex]::Escape('[releases/HISTORY.md](releases/HISTORY.md)')) "history 'latest': the pointer names the repo's own history file"
# The pointer is the whole safety argument for dropping blocks, so a 'latest' section without one would
# be a section that silently deletes history. Asserted separately from the path above: that one checks
# the value, this one checks that a link is emitted at all.
Assert-Match $hmLatest '(?m)^is in \[' "history 'latest': the intro really links out rather than only naming a file"

# BOTH ORDERS survive a cut, in the order the document already had. The old code threw unless Releases
# came second; a consumer's layout must not be silently reordered by a release.
$hmRelFirst = @(
    '# Changelog', '',
    'Intro line.', '',
    '## Latest Release', '',
    'The most recent release.', '',
    "### [v1.0.0] - 2026-01-01 $emDash Minor", '',
    'See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.', '',
    '## Pull Requests', '',
    'Merged PRs land here.', '',
    "### #7 $midDot An entry $midDot Fix $midDot 2026-02-01", '',
    'Body.'
) -join "`n"
$hmOut = Convert-ChangelogForRelease -Content $hmRelFirst @hmArgs -HistoryMode 'latest'
$relPos = ($hmOut -split "`n") | Select-String -Pattern '^## Latest Release$' | ForEach-Object { $_.LineNumber }
$prPos  = ($hmOut -split "`n") | Select-String -Pattern '^## Pull Requests$'  | ForEach-Object { $_.LineNumber }
Assert-Equal $true ($relPos -lt $prPos) 'section order: a releases-first document stays releases-first'
Assert-Match $hmOut ([regex]::Escape('### [v1.1.0]')) 'section order: releases-first still gets the new block'
Assert-Match $hmOut '(?m)^Merged PRs land here\.$' 'section order: releases-first keeps its Pull-Requests intro'
Assert-Match $hmOut '(?m)^Intro line\.$' "section order: releases-first keeps the document's own head"
# And the mirror image, from the same call: a PR-first document stays PR-first.
$hmOut2 = Convert-ChangelogForRelease -Content $hmBase @hmArgs -HistoryMode 'latest'
$relPos2 = ($hmOut2 -split "`n") | Select-String -Pattern '^## Latest Release$' | ForEach-Object { $_.LineNumber }
$prPos2  = ($hmOut2 -split "`n") | Select-String -Pattern '^## Pull Requests$'  | ForEach-Object { $_.LineNumber }
Assert-Equal $true ($prPos2 -lt $relPos2) 'section order: a PR-first document stays PR-first'

Write-Host "Set-ReleaseInternalNoteLink" -ForegroundColor Cyan
$intBase = @(
    '# Changelog', '',
    '## Latest Release', '',
    'The most recent release.', '',
    "### [v1.1.0] - 2026-02-02 $emDash Minor", '',
    'See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.'
) -join "`n"
$intOut = Set-ReleaseInternalNoteLink -Content $intBase -Version '1.1.0' `
    -InternalRelPath 'releases/internal/1.x/1.1.0.md' -DevRelPath 'releases/development/1.x/1.1.0.md'
Assert-Match $intOut ([regex]::Escape('[releases/internal/1.x/1.1.0.md](releases/internal/1.x/1.1.0.md)')) 'internal link: the internal note is now linked'
Assert-Match $intOut ([regex]::Escape('[releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md)')) 'internal link: the developer notes are kept as the secondary reference'
Assert-Equal 1 ([regex]::Matches($intOut, '(?m)^See \[')).Count 'internal link: one notes line, replaced rather than appended'
# Idempotent, because this runs in a PR that may be re-run or rebased.
Assert-Equal $intOut (Set-ReleaseInternalNoteLink -Content $intOut -Version '1.1.0' `
    -InternalRelPath 'releases/internal/1.x/1.1.0.md' -DevRelPath 'releases/development/1.x/1.1.0.md') 'internal link: idempotent -- a second call changes nothing'
# Unknown version: untouched and no throw. This runs AFTER a successful release, so failing here would
# make a completed release look broken over a cosmetic line.
Assert-Equal $intBase (Set-ReleaseInternalNoteLink -Content $intBase -Version '9.9.9' `
    -InternalRelPath 'x.md' -DevRelPath 'y.md') 'internal link: an unknown version leaves the content untouched'
# And in 'all' mode, where several blocks sit together, only the named version is rewritten.
$intMulti = @(
    '## Releases', '',
    "### [v2.0.0] - 2026-03-01 $emDash Major", '',
    'See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.', '',
    '---', '',
    "### [v1.1.0] - 2026-02-02 $emDash Minor", '',
    'See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.'
) -join "`n"
$intMultiOut = Set-ReleaseInternalNoteLink -Content $intMulti -Version '1.1.0' `
    -InternalRelPath 'releases/internal/1.x/1.1.0.md' -DevRelPath 'releases/development/1.x/1.1.0.md'
Assert-Match $intMultiOut ([regex]::Escape('[releases/internal/1.x/1.1.0.md]')) 'internal link: the named block is rewritten'
Assert-Match $intMultiOut ([regex]::Escape('See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.')) 'internal link: the OTHER block is left exactly as it was'

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
$touchedFiles = @(
    'plugins/specialists/agents/01-01-chris.md',
    'plugins/specialists/manuals/01-01-manual.md',
    'plugins/specialists-lifehub/agents/foo.md',
    'plugins/agent-shared/inbound-behaviour.md',
    'connectors/some-repo.json',
    'README.md',
    'scripts/lib/release-lib.ps1'
)
$touched = @(Get-TouchedPlugins -Files $touchedFiles)
Assert-Equal 2 $touched.Count 'two touched plugins (deduplicated + sorted)'
Assert-Equal 'specialists' $touched[0] 'first plugin name alphabetically'
Assert-Equal 'specialists-lifehub' $touched[1] 'second plugin name alphabetically'
# The two non-plugin directories, one on each side of the plugins root after the #405 flattening:
# agent-shared/ sits INSIDE it and has to be excluded by name, connectors/ sits at the ROOT and can no
# longer match at all. Both are asserted, so neither half can quietly regress into counting as a plugin.
Assert-Equal $false ([bool]($touched -contains 'agent-shared')) 'agent-shared is plugin source, not a plugin'
Assert-Equal $false ([bool]($touched -contains 'connectors')) 'connectors folder does not count as a plugin'
Assert-Equal 0 (@(Get-TouchedPlugins -Files @('connectors/life-hub.json'))).Count 'connectors at the repo root does not match the plugins pattern at all'
Assert-Equal 0 (@(Get-TouchedPlugins -Files @())).Count 'empty input -> empty set'
Assert-Equal 0 (@(Get-TouchedPlugins -Files @('README.md', 'scripts/lib/release-lib.ps1'))).Count 'non-plugin paths ignored'
Assert-Equal 0 (@(Get-TouchedPlugins -Files @('plugins/Specialists/agents/x.md'))).Count 'uppercase plugin slug does not count (-cmatch lowercase rule)'
$dedupFiles = @(
    'plugins/specialists/agents/a.md',
    'plugins/specialists/agents/b.md',
    'plugins/specialists/manuals/c.md'
)
$dedupTouched = @(Get-TouchedPlugins -Files $dedupFiles)
Assert-Equal 1 $dedupTouched.Count 'same plugin across multiple files -> once in the set'
Assert-Equal 'specialists' $dedupTouched[0] 'deduplicated name correct'

Write-Host "Get-EntryPlugins" -ForegroundColor Cyan
$entryWithPlugins = @("### #4 $midDot Something $midDot Feat $midDot 2026-01-04", '', 'Body four.', '', 'Plugins: specialists, specialists-lifehub', '', '[PR #4](https://example.com/4)') -join "`n"
$plugs = @(Get-EntryPlugins -EntryText $entryWithPlugins)
Assert-Equal 2 $plugs.Count 'two plugins from the Plugins line'
Assert-Equal 'specialists' $plugs[0] 'first plugin name correct'
Assert-Equal 0 (@(Get-EntryPlugins -EntryText "### #5 x`n`nBody.")).Count 'no Plugins line -> empty list'

Write-Host "Remove-EntryPluginsLine" -ForegroundColor Cyan
$clean = Remove-EntryPluginsLine -EntryText $entryWithPlugins
Assert-Equal $false ([bool]($clean -match '(?m)^Plugins:')) 'Plugins line removed'
Assert-Match $clean '(?s)Body four\.\n\n\[PR #4\]' 'no double blank line left behind'
Assert-Equal "### #5 x`n`nBody." (Remove-EntryPluginsLine -EntryText "### #5 x`n`nBody.") 'entry without a Plugins line stays unchanged'

Write-Host "Convert-EntryLinksForPluginChangelog" -ForegroundColor Cyan
$conv = Convert-EntryLinksForPluginChangelog -EntryText 'See [the lint](scripts/lint/x.ps1) and [site](https://example.com) and [#heading](#heading).' -RepoBlobUrl 'https://gh.test/blob/main/'
Assert-Match $conv '\[the lint\]\(https://gh\.test/blob/main/scripts/lint/x\.ps1\)' 'root-relative link becomes a GitHub URL'
Assert-Match $conv '\[site\]\(https://example\.com\)' 'external link untouched (plugin variant)'
Assert-Match $conv '\[#heading\]\(#heading\)' 'anchor link untouched (plugin variant)'

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

Write-Host "Build-PluginChangelogIntro" -ForegroundColor Cyan
# THE WHOLE POINT OF THIS FUNCTION EXISTING SEPARATELY (measured August 3, 2026): the intro is written
# once, at file creation, and never revisited -- so it is the one generated string in this library that
# cannot self-heal on the next release. Extracting it gives check 17 of check-plugin-integrity.ps1 a
# single source to hold the four existing CHANGELOGs against.
$intro = Build-PluginChangelogIntro -PluginName 'specialists' -MarketplaceName 'claude-code-specialists'
Assert-Match $intro '^# Changelog .* specialists' 'intro opens with the plugin title'
Assert-Match $intro '\(claude-code-specialists\)' 'intro names the marketplace it was given'
Assert-Equal $false ([bool]($intro -match 'workshop')) 'intro carries no trace of the retired workshop framing'
# The name is a parameter, not a literal: a different marketplace must produce a different intro, which
# is what lets the gate derive its expectation from marketplace.json instead of hardcoding a copy.
$introOther = Build-PluginChangelogIntro -PluginName 'specialists' -MarketplaceName 'some-other-marketplace'
Assert-Match $introOther '\(some-other-marketplace\)' 'the marketplace name is injected, not baked in'
Assert-Equal $false ($intro -eq $introOther) 'a different marketplace name yields a different intro'
# Add-PluginChangelogSection must emit exactly this text for a new file -- if the two ever diverge, the
# gate would hold the real CHANGELOGs against a string cut-release.ps1 no longer writes.
$freshForIntro = Add-PluginChangelogSection -Existing '' -Section '## v1.0.0 - 2026-01-01' -PluginName 'specialists' -MarketplaceName 'claude-code-specialists'
Assert-Equal $true $freshForIntro.StartsWith($intro) 'a new CHANGELOG begins with exactly Build-PluginChangelogIntro output'

Write-Host "Build-PluginChangelogSection + Add-PluginChangelogSection" -ForegroundColor Cyan
$section = Build-PluginChangelogSection -Entries @($entryWithPlugins) -Version '1.5.0' -Date '2026-07-17'
Assert-Match $section '^## v1\.5\.0 ' 'section heading with version'
Assert-Match $section '(?m)^### Features' 'entries grouped under a category heading (### Features)'
Assert-Match $section '(?m)^#### #4 ' 'entry included in the section, demoted under its category'
Assert-Match $section '(?s)## v1\.5\.0 .*### Features.*#### #4 ' 'nesting: ## version -> ### category -> #### entry'
$sectionClean = Build-PluginChangelogSection -Entries @(Remove-EntryPluginsLine -EntryText $entryWithPlugins) -Version '1.5.0' -Date '2026-07-17'
Assert-Equal $false ([bool]($sectionClean -match '(?m)^Plugins:')) 'section via the cut-release path contains no Plugins line'
$fresh = Add-PluginChangelogSection -Existing '' -Section $section -PluginName 'specialists' -MarketplaceName 'fixture-marketplace'
Assert-Match $fresh '^# Changelog .* specialists' 'new CHANGELOG gets an intro header'
Assert-Match $fresh '(?s)# Changelog.*## v1\.5\.0' 'section comes after the intro'
$section2 = Build-PluginChangelogSection -Entries @($entryWithPlugins) -Version '1.6.0' -Date '2026-07-18'
$appended = Add-PluginChangelogSection -Existing $fresh -Section $section2 -PluginName 'specialists' -MarketplaceName 'fixture-marketplace'
Assert-Match $appended '(?s)## v1\.6\.0.*## v1\.5\.0' 'newest release is at the top'
Assert-Equal 1 (@([regex]::Matches($appended, '(?m)^# Changelog')).Count) 'intro header not duplicated'

Write-Host "Add-PluginChangelogSection (tightened ## v match, #103)" -ForegroundColor Cyan
# A non-version '## ' heading (e.g. a manually added '## Notes') must not disturb the insertion
# position: the new section should land BEFORE the first REAL '## vX.Y.Z' heading, not before the
# Notes heading or in the middle of it.
$existingWithNotes = "# Changelog $emDash specialists`n`n## Notes`n`nManual note, no version.`n`n## v1.0.0 $emDash 2026-01-01`n`nOld content.`n"
$sectionForNotesTest = "## v1.1.0 $emDash 2026-01-02`n`nNew content."
$withNotesResult = Add-PluginChangelogSection -Existing $existingWithNotes -Section $sectionForNotesTest -PluginName 'specialists' -MarketplaceName 'fixture-marketplace'
Assert-Match $withNotesResult '(?s)## Notes.*Manual note.*## v1\.1\.0.*## v1\.0\.0' 'new section inserted after the Notes heading, before the first real version heading'
$notesHeadingMatches = @([regex]::Matches($withNotesResult, '(?m)^## Notes'))
Assert-Equal 1 $notesHeadingMatches.Count 'Notes heading stays present exactly once (not duplicated or overwritten)'
$notesIdx = $withNotesResult.IndexOf('## Notes')
$v11Idx = $withNotesResult.IndexOf('## v1.1.0')
$v10Idx = $withNotesResult.IndexOf('## v1.0.0')
Assert-Equal $true ($notesIdx -lt $v11Idx -and $v11Idx -lt $v10Idx) 'order is Notes, then the new v1.1.0 section, then the existing v1.0.0 section'
# Normal case (only version headings, no non-version heading) still works -- the same outcome as
# the existing 'newest release is at the top' test above, here as an explicit regression guard
# for the tightened regex.
$onlyVersionsResult = Add-PluginChangelogSection -Existing $fresh -Section $section2 -PluginName 'specialists' -MarketplaceName 'fixture-marketplace'
Assert-Match $onlyVersionsResult '(?s)## v1\.6\.0.*## v1\.5\.0' 'normal case (only version headings) keeps inserting correctly'

Write-Host "Build-PluginChangelogSection (LF normalization, point e, #103)" -ForegroundColor Cyan
$crlfEntry = "### #7 $midDot CRLF-test $midDot Fix $midDot 2026-01-07`r`n`r`nBody with`r`nCRLF lines.`r`n`r`n[PR #7](https://example.com/7)"
$lfSection = Build-PluginChangelogSection -Entries @($crlfEntry) -Version '1.7.0' -Date '2026-07-20'
Assert-Equal $false ($lfSection.Contains("`r")) 'Build-PluginChangelogSection output contains no CR, even with a CRLF input entry'
Assert-Match $lfSection '#### #7 .* CRLF-test' 'entry content still included correctly despite the normalization'
$cardWithCrlf = Build-PluginReleaseCard -PluginName 'specialists' -Version '1.7.0' -Date '2026-07-20' -Type 'Fix' -Entries @($crlfEntry)
Assert-Equal $false ($cardWithCrlf.Contains("`r")) 'Build-PluginReleaseCard stays pure LF despite a CRLF input entry'

Write-Host "Build-PluginReleaseCard" -ForegroundColor Cyan
$cardEntries = @($linkEntry)
$card = Build-PluginReleaseCard -PluginName 'specialists' -Version '1.5.0' -Date '2026-07-19' -Type 'Minor' -Title 'Test-title' -Entries $cardEntries -RepoBlobUrl 'https://gh.test/blob/main/'
Assert-Match $card '^# Release v1\.5\.0' 'heading with version'
Assert-Match $card '\*\*Date:\*\* 2026-07-19' 'date line'
Assert-Match $card '\*\*Type:\*\* Minor' 'type line'
Assert-Match $card 'Test-title' 'title included'
Assert-Match $card 'This card describes v1\.5\.0, the version your plugin manifest carries\.' 'the card states what it describes rather than where the reader is (#384)'
Assert-Equal $false ([bool]($card -match 'You are on this release')) 'and does not claim the reader is on it -- v13 measured that false in the ordinary case'
Assert-Match $card '\[The version is not the code\]\(https://gh\.test/blob/main/ADOPTION\.md\#staying-up-to-date\)' 'the "where am I" question is handed to the check that can answer it, as an absolute URL (the card is read from a plugin cache); ADOPTION.md since the page was renamed (#408)'
Assert-Match $card '(?s)Test-title.*This card describes v1\.5\.0' 'title comes before the describes-line'
Assert-Match $card '(?m)^## Fixes' 'card groups entries under a category heading (## Fixes), single-release view'
Assert-Equal $false ([bool]($card -match '(?m)^## v1\.5\.0 ')) 'card carries no redundant inner ## vX.Y.Z heading (the # Release header already states the version)'
Assert-Match $card '(?m)^### #3 .* Something' 'entry fragment included in the body, at ### under the ## category'
Assert-Match $card '\[the lint\]\(https://gh\.test/blob/main/scripts/lint/x\.ps1\)' 'root-relative link in the body rewritten as Convert-EntryLinksForPluginChangelog does'
Assert-Match $card '\[the site\]\(https://example\.com\)' 'external link in the body stays untouched'
$card2 = Build-PluginReleaseCard -PluginName 'specialists' -Version '1.5.0' -Date '2026-07-19' -Type 'Minor' -Entries @() -RepoBlobUrl 'https://gh.test/blob/main/'
Assert-Match $card2 "No changes to this plugin in this release $([char]0x2014) see the full notes\." 'empty-entries branch: exactly the no-changes block'
Assert-Equal $false ([bool]($card2 -match '(?m)^## v')) 'empty-entries branch: no section heading'
Assert-Match $card2 '\*\*Type:\*\* Minor' 'empty-entries branch: heading stays intact'
Assert-Match $card '\[releases/development/1\.x/1\.5\.0\.md\]\(https://gh\.test/blob/main/releases/development/1\.x/1\.5\.0\.md\)' 'footer: blob URL to the full release notes'
Assert-Match $card '\[CHANGELOG\.md\]\(CHANGELOG\.md\)' 'footer: folder-relative link to CHANGELOG.md'
Assert-Match $card2 '\[releases/development/1\.x/1\.5\.0\.md\]\(https://gh\.test/blob/main/releases/development/1\.x/1\.5\.0\.md\)' 'empty-entries branch: footer links stay correct'

$cardNoTitle = Build-PluginReleaseCard -PluginName 'specialists' -Version '2.0.0' -Date '2026-07-19' -Type 'Major' -Entries @()
Assert-Match $cardNoTitle '(?s)\*\*Type:\*\* Major\n\nThis card describes v2\.0\.0' 'without -Title exactly one blank line (no extra) before the describes-line'

# ==================================================================================================
# THE HIGHLIGHTS TIER (#417 phase 2)
# ==================================================================================================
# This repo generates no highlights document (empty seam = tier off), so every assert below runs
# against the LIB rather than against a release this repo cuts. That is the point: the tier's only
# consumer is another repo, and a feature no local release exercises is exactly the one that has to be
# tested here rather than discovered there.

Write-Host "Format-CategorizedEntries -OnlyTypes (the filter the two halves share)" -ForegroundColor Cyan
$halfEntries = @($entries[0], $entries[1], $docsEntry, $choreEntry, $otherEntry)
$onlyFeat = Format-CategorizedEntries -Entries $halfEntries -CategoryLevel 2 -OnlyTypes @('Feat', 'Fix')
Assert-Match $onlyFeat '(?m)^## Features' 'OnlyTypes: a named category is rendered'
Assert-Match $onlyFeat '(?m)^## Fixes' 'OnlyTypes: and the second named one'
Assert-Equal $false ([bool]($onlyFeat -match 'Documentation')) 'OnlyTypes: an unnamed category is dropped, not reported'
Assert-Equal $false ([bool]($onlyFeat -match 'Maintenance')) 'OnlyTypes: and so is the next one'
Assert-Equal $false ([bool]($onlyFeat -match '(?m)^## Other')) 'OnlyTypes: the catch-all is not exempt from the filter'
# The complement must be exhaustive: whatever the stakeholder half drops, the developer half shows.
# If both halves could drop the same entry, an entry would vanish between the changelog and the
# document generated from it -- silently, since nothing counts the two halves against the input.
$onlyRest = Format-CategorizedEntries -Entries $halfEntries -CategoryLevel 3 -OnlyTypes @('Docs', 'Chore', 'Other')
Assert-Match $onlyRest '(?m)^### Documentation' 'OnlyTypes: the complement renders what the first half dropped'
Assert-Match $onlyRest '(?m)^#### #12 ' 'OnlyTypes: at CategoryLevel 3 its entries sit at ####'
$allShown = @(1, 2, 10, 11, 12) | Where-Object { ($onlyFeat + $onlyRest) -notmatch "#$_ " }
Assert-Equal 0 $allShown.Count 'OnlyTypes: every input entry appears in exactly one of the two halves (nothing lost between them)'
$onlyNone = Format-CategorizedEntries -Entries $halfEntries -CategoryLevel 2 -OnlyTypes @()
Assert-Match $onlyNone '(?s)## Features.*## Other' 'OnlyTypes: empty means every category -- the unchanged behaviour'

Write-Host "Convert-EntryHeadingToTitle (the metadata a stakeholder does not have a branch for)" -ForegroundColor Cyan
$hIn = "### #426 $midDot Some title $midDot Feat $midDot 2026-08-03`n`nBody stays.`n`nAnd a second paragraph."
$hOut = Convert-EntryHeadingToTitle -EntryText $hIn
Assert-Equal '### Some title' (($hOut -split "`n")[0]) 'heading reduced to the bare title'
Assert-Match $hOut '(?s)Body stays\..*second paragraph' 'the body is untouched'
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
Assert-Equal "### Only $midDot Two" (($hTwo -split "`n")[0]) 'two fields: no (title, type, date) triple to strip, so left alone'
$hOnlyMeta = Convert-EntryHeadingToTitle -EntryText "### #9 $midDot Fix $midDot 2026-01-01`n`nBody."
Assert-Equal "### #9 $midDot Fix $midDot 2026-01-01" (($hOnlyMeta -split "`n")[0]) 'a heading that is ONLY metadata keeps it rather than becoming empty'
$hLevel = Convert-EntryHeadingToTitle -EntryText "#### #5 $midDot Deeper $midDot Feat $midDot 2026-01-01`n`nBody."
Assert-Equal '#### Deeper' (($hLevel -split "`n")[0]) 'the heading level is preserved, not normalized'

# THE ORDER IS LOAD-BEARING, and this pair is here because the first implementation got it wrong.
# Format-CategorizedEntries reads the branch type OFF the heading this function strips, so stripping
# first destroys the very field the grouping needs -- and it does not fail loudly: every entry lands in
# the 'Other' catch-all, the stakeholder half comes out empty, and the whole release ends up under the
# "remove before publishing" marker. A generated document that says the entire release is internal is
# the kind of wrong that gets published. Hence -BareTitles INSIDE the renderer, asserted from both
# directions so a future refactor that moves the strip back out turns this red.
$strippedFirst = Convert-EntryHeadingToTitle -EntryText $entries[0]
$fceStripped = Format-CategorizedEntries -Entries @($strippedFirst) -CategoryLevel 2
Assert-Match $fceStripped '(?m)^## Other' 'order: a PRE-stripped entry has lost its type and falls into Other (the bug this guards)'
$fceBare = Format-CategorizedEntries -Entries @($entries[0]) -CategoryLevel 2 -BareTitles
Assert-Match $fceBare '(?m)^## Features' 'order: -BareTitles strips AFTER the type is read, so the category survives'
Assert-Match $fceBare '(?m)^### Second feature$' 'order: and the rendered entry heading is the bare title'

Write-Host "Build-HighlightsNotes (stakeholder first, the rest under a marker)" -ForegroundColor Cyan
$hl = Build-HighlightsNotes -Entries $halfEntries -Version '1.2.0' -Date '2026-08-03' -Type 'Minor' `
    -Title 'A release for people' -StakeholderTypes @('Feat', 'Fix')
Assert-Match $hl '(?m)^# Release notes v1\.2\.0 ' 'header names the version'
Assert-Match $hl '\*\*Date:\*\* 2026-08-03' 'header carries the date'
Assert-Match $hl 'A release for people' 'the -Title line is included'
Assert-Match $hl '(?s)## Features.*## Fixes.*For developers only.*### Documentation' 'stakeholder categories come first, the developer block after them'
Assert-Match $hl '<!-- Remove this block before sharing the highlights with non-developers\. -->' 'the marker carries its HTML comment'
Assert-Match $hl '(?m)^## For developers only -- remove before publishing$' 'the marker heading sits at ## (containing its categories)'
Assert-Match $hl '(?m)^### Documentation$' 'a developer category sits one level UNDER the marker, not beside it'
Assert-Equal $false ([bool]($hl -match "#426 $midDot")) 'entry metadata is stripped in the highlights document'
# The words are the consumer's, in the consumer's language -- the #410 class. A hardcoded English
# heading in a Dutch stakeholder document is the wrong word rather than a missing one.
$hlNl = Build-HighlightsNotes -Entries $halfEntries -Version '1.2.0' -Date '2026-08-03' -Type 'Minor' `
    -StakeholderTypes @('Feat') -DevBlockComment 'Verwijder dit blok.' -DevBlockHeading 'Alleen voor developers'
Assert-Match $hlNl '<!-- Verwijder dit blok\. -->' 'the marker comment is overridable'
Assert-Match $hlNl '(?m)^## Alleen voor developers$' 'the marker heading is overridable'
Assert-Match $hlNl '(?s)## Fixes' 'a type left OUT of StakeholderTypes lands in the developer half rather than vanishing'
# No split asked for = no marker at all. A repo can want the second document without wanting the cut.
$hlAll = Build-HighlightsNotes -Entries $halfEntries -Version '1.2.0' -Date '2026-08-03' -Type 'Minor'
Assert-Equal $false ([bool]($hlAll -match 'For developers only')) 'no StakeholderTypes: no marker block is written'
Assert-Match $hlAll '(?s)## Features.*## Documentation.*## Other' 'no StakeholderTypes: every category is rendered at ## instead'
# All-stakeholder input: the marker must not appear with an empty body under it.
$hlNoDev = Build-HighlightsNotes -Entries @($entries[0]) -Version '1.2.0' -Date '2026-08-03' -Type 'Minor' -StakeholderTypes @('Feat', 'Fix')
Assert-Equal $false ([bool]($hlNoDev -match 'For developers only')) 'nothing in the developer half: the marker is omitted, not written empty'
# Links are rewritten from the highlights file's depth, which equals the developer notes' depth.
$hlLink = Build-HighlightsNotes -Entries @($linkEntry) -Version '1.2.0' -Date '2026-08-03' -Type 'Minor' -StakeholderTypes @('Fix')
Assert-Match $hlLink '\[the lint\]\(\.\./\.\./\.\./scripts/lint/x\.ps1\)' 'root-relative links get the prefix here too'
Assert-Match $hlLink '\[the site\]\(https://example\.com\)' 'external links untouched'

Write-Host "the highlights tier produces markdown ONLY (no HTML renderer)" -ForegroundColor Cyan
# Dave, August 3, 2026: the print-ready .html is not wanted anywhere, so ConvertTo-ReleaseHtml and
# Format-InlineMarkdown were removed the same day they were ported. ASSERTED ON THEIR ABSENCE rather
# than simply deleting the old asserts: a partial HTML renderer is exactly the kind of thing that gets
# helpfully reintroduced, and re-adding it should turn a test red rather than pass unnoticed.
foreach ($gone in @('ConvertTo-ReleaseHtml', 'Format-InlineMarkdown')) {
    Assert-Equal $null (Get-Command $gone -ErrorAction SilentlyContinue) "release-lib no longer defines $gone"
}
# The document itself must carry no HTML beyond the one comment the marker is built from -- that comment
# is markdown-legal and is the whole point of the marker, so it is excluded by name rather than by a
# looser pattern that would also let a stray <div> through.
$hlNoHtml = Build-HighlightsNotes -Entries $halfEntries -Version '1.2.0' -Date '2026-08-03' -Type 'Minor' -StakeholderTypes @('Feat', 'Fix')
$tags = @([regex]::Matches($hlNoHtml, '<[a-zA-Z/!][^>]*>') | ForEach-Object { $_.Value } | Where-Object { $_ -notmatch '^<!--' })
Assert-Equal 0 $tags.Count "the generated document carries no HTML tags (found: $($tags -join ', '))"
Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
