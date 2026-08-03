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

Write-Host "Build-PluginChangelogSection + Add-PluginChangelogSection" -ForegroundColor Cyan
$section = Build-PluginChangelogSection -Entries @($entryWithPlugins) -Version '1.5.0' -Date '2026-07-17'
Assert-Match $section '^## v1\.5\.0 ' 'section heading with version'
Assert-Match $section '(?m)^### Features' 'entries grouped under a category heading (### Features)'
Assert-Match $section '(?m)^#### #4 ' 'entry included in the section, demoted under its category'
Assert-Match $section '(?s)## v1\.5\.0 .*### Features.*#### #4 ' 'nesting: ## version -> ### category -> #### entry'
$sectionClean = Build-PluginChangelogSection -Entries @(Remove-EntryPluginsLine -EntryText $entryWithPlugins) -Version '1.5.0' -Date '2026-07-17'
Assert-Equal $false ([bool]($sectionClean -match '(?m)^Plugins:')) 'section via the cut-release path contains no Plugins line'
$fresh = Add-PluginChangelogSection -Existing '' -Section $section -PluginName 'specialists'
Assert-Match $fresh '^# Changelog .* specialists' 'new CHANGELOG gets an intro header'
Assert-Match $fresh '(?s)# Changelog.*## v1\.5\.0' 'section comes after the intro'
$section2 = Build-PluginChangelogSection -Entries @($entryWithPlugins) -Version '1.6.0' -Date '2026-07-18'
$appended = Add-PluginChangelogSection -Existing $fresh -Section $section2 -PluginName 'specialists'
Assert-Match $appended '(?s)## v1\.6\.0.*## v1\.5\.0' 'newest release is at the top'
Assert-Equal 1 (@([regex]::Matches($appended, '(?m)^# Changelog')).Count) 'intro header not duplicated'

Write-Host "Add-PluginChangelogSection (tightened ## v match, #103)" -ForegroundColor Cyan
# A non-version '## ' heading (e.g. a manually added '## Notes') must not disturb the insertion
# position: the new section should land BEFORE the first REAL '## vX.Y.Z' heading, not before the
# Notes heading or in the middle of it.
$existingWithNotes = "# Changelog $emDash specialists`n`n## Notes`n`nManual note, no version.`n`n## v1.0.0 $emDash 2026-01-01`n`nOld content.`n"
$sectionForNotesTest = "## v1.1.0 $emDash 2026-01-02`n`nNew content."
$withNotesResult = Add-PluginChangelogSection -Existing $existingWithNotes -Section $sectionForNotesTest -PluginName 'specialists'
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
$onlyVersionsResult = Add-PluginChangelogSection -Existing $fresh -Section $section2 -PluginName 'specialists'
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
Assert-Match $card '\[The version is not the code\]\(https://gh\.test/blob/main/QUICKSTART\.md\#staying-up-to-date\)' 'the "where am I" question is handed to the check that can answer it, as an absolute URL (the card is read from a plugin cache)'
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

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
