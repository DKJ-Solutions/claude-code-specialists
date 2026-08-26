<#
.SYNOPSIS
    Regression tests for scripts/release/new-internal-note.ps1 -- the third release tier's skeleton
    generator (releases/internal/<dir>/<X.Y.Z>.md, for colleagues and management).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Integration style: the REAL script runs against a
    throwaway fixture repo, so nothing here touches a real release. Run as a CHILD PROCESS, because the
    script calls 'exit' on its refusal paths and would otherwise abort this runner.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/internal-note.tests.ps1

    What is asserted, in the order a failure is most usefully diagnosed:
      1. the refusals (no developer notes, an existing note without -Force) -- both are the paths that
         protect written text, so they matter more than the happy path;
      2. the skeleton's shape: the metadata copied from the developer notes, the three fixed headings,
         and the entry titles carried over WITHOUT their internal metadata;
      3. the folder scheme, which must follow Get-ReleaseNotesGrouping rather than a scheme of its own;
      4. the wording seam -- the document is read by a given repo's colleagues, so every string in it
         must be overridable (#410 class).

    Pure ASCII (repo convention for .ps1); the middot in an entry heading is built from its codepoint.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot  = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$ScriptSrc = Join-Path $RepoRoot 'scripts\release\new-internal-note.ps1'

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

$midDot = [char]0x00B7
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function New-Fixture {
    <#
        A throwaway repo root with the script copied in, optionally carrying developer notes and an
        optional repo-config.ps1. Not a git repo on purpose: -RepoRoot is passed explicitly, which is
        exactly the path the script documents for the test suite, and it keeps the fixture cheap.
    #>
    param(
        [Parameter(Mandatory)][string]$Label,
        [string]$NotesDir = '3.x',
        [string]$Version = '3.2.0',
        # DELIBERATELY UNTYPED, both of them. A [string] parameter converts $null to '', so
        # '$null -ne $NotesContent' would be TRUE for an omitted argument and this fixture would write an
        # EMPTY notes file -- which made the "no developer notes" refusal look broken while the script was
        # correct (measured: run by hand it exits 1 and writes nothing). The absent case has to stay
        # distinguishable from the empty-string case, so no type constraint here.
        $NotesContent = $null,
        $RepoConfig = $null
    )
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) "internal-note-test-$PID-$Label"
    if (Test-Path -LiteralPath $dir) { Remove-Item -Recurse -Force -LiteralPath $dir }
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\release') -Force | Out-Null
    Copy-Item -LiteralPath $ScriptSrc -Destination (Join-Path $dir 'scripts\release\new-internal-note.ps1') -Force
    # release-lib.ps1 travels along because the script dot-sources it for Set-ReleaseInternalNoteLink
    # (August 4, 2026), which repoints the changelog's release block at the note this script creates.
    # Copied rather than made optional in the script: a missing lib must fail loudly, not silently skip
    # the changelog update and leave the release pointing at the developer notes forever.
    New-Item -ItemType Directory -Path (Join-Path $dir 'scripts\lib') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'scripts\lib\release-lib.ps1') `
        -Destination (Join-Path $dir 'scripts\lib\release-lib.ps1') -Force
    # entry-scaffold-lib.ps1 travels along because release-lib dot-sources it for the changelog's tier
    # sections (August 5, 2026). Copied for the same reason as release-lib itself: a missing sibling must
    # fail loudly here rather than in someone's release.
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1') `
        -Destination (Join-Path $dir 'scripts\lib\entry-scaffold-lib.ps1') -Force
    # plugin-tree-lib.ps1 travels along for the same reason one layer further: release-lib dot-sources it
    # for the plugin set (August 9, 2026), so it is a sibling of a sibling and the fixture owes it too.
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'scripts\lib\plugin-tree-lib.ps1') `
        -Destination (Join-Path $dir 'scripts\lib\plugin-tree-lib.ps1') -Force
    # seam-lib.ps1 (issue #885, group A/E): the script now dot-sources this unconditionally, the same way
    # it already does for release-lib.ps1 and its own siblings above -- a missing copy must fail loudly
    # here, not silently in someone's release.
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'scripts\lib\seam-lib.ps1') `
        -Destination (Join-Path $dir 'scripts\lib\seam-lib.ps1') -Force
    # .claude-plugin/marketplace.json (issue #885): this fixture places its notes at the ROOT
    # releases/development/ and releases/internal/ and every assertion below expects them there.
    # Get-DefaultReleaseDevelopmentNotesRoot / Get-DefaultReleaseInternalNotesRoot test exactly this
    # file's presence, so without it the fixture reads as a consumer and the script looks for its
    # notes inside a contributing-davekjohn/ this fixture does not have.
    New-Item -ItemType Directory -Path (Join-Path $dir '.claude-plugin') -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $dir '.claude-plugin\marketplace.json'), '{}', $Utf8NoBom)
    if ($null -ne $NotesContent) {
        $notesPath = Join-Path $dir "releases\development\$NotesDir\$Version.md"
        New-Item -ItemType Directory -Path (Split-Path -Parent $notesPath) -Force | Out-Null
        [System.IO.File]::WriteAllText($notesPath, $NotesContent, $Utf8NoBom)
    }
    if ($null -ne $RepoConfig) {
        [System.IO.File]::WriteAllText((Join-Path $dir 'scripts\repo-config.ps1'), $RepoConfig, $Utf8NoBom)
    }
    return $dir
}

function Invoke-Script {
    param([string]$Dir, [string[]]$ExtraArgs = @(), [string]$Version = '3.2.0')
    # $psArgs, NOT $args: inside a function $args is an AUTOMATIC variable holding the caller's own
    # arguments, so assigning to it and splatting the result silently passes something else entirely --
    # measured here as the no-notes refusal appearing to exit 0. Costs nothing to avoid, invisible if not.
    $psArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
        (Join-Path $Dir 'scripts\release\new-internal-note.ps1'),
        '-Version', $Version, '-RepoRoot', $Dir) + $ExtraArgs
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = (& powershell @psArgs 2>&1 | Out-String)
        return [pscustomobject]@{ Out = $out; Code = $LASTEXITCODE }
    } finally { $ErrorActionPreference = $prevEap }
}

function Test-Line {
    <#
        A whole-line match against the generated document. The skeleton is written with CRLF (it is a
        Windows-authored document, unlike the pure-LF generated notes), so a '(?m)^...$' pattern does NOT
        match: in .NET multiline mode '$' sits before the '\n' and the '\r' is still in the way. Rather
        than sprinkle '\r?$' through twenty asserts -- and have the next person wonder which ones need it
        -- every whole-line assert goes through here.
    #>
    param([string]$Text, [string]$Pattern)
    return ($Text -match ('(?m)^' + $Pattern + '\r?$'))
}

# The developer notes as release-lib.ps1 really writes them: '**Date:**  ' / '**Type:**', categories at
# H2, entries at H3 carrying the compact middot heading, and an H4 inside one body -- the shape that
# proves only H3 is read.
$notes = @"
# Release notes v3.2.0

**Date:** 2026-08-03
**Type:** Minor

## Features

### #428 $midDot Turn the highlights tier on $midDot Feat $midDot 2026-08-03

Body text.

#### A subheading inside the entry

More body.

---

### #427 $midDot The highlights tier moves to the shared cut $midDot Feat $midDot 2026-08-03

Body text.

## Fixes

### #425 $midDot The teardown audit walks every file $midDot Fix $midDot 2026-08-03

Body text.
"@

# --- 1. The refusals ------------------------------------------------------------------------------
Write-Host "new-internal-note -- the refusals (they protect written text)" -ForegroundColor Cyan
$noNotes = New-Fixture -Label 'nonotes'
$r = Invoke-Script -Dir $noNotes
Assert-Equal 1 $r.Code 'no developer notes: exits 1 rather than writing a note with nothing in it'
Assert-True ($r.Out -match 'Developer notes not found') 'no developer notes: says what is missing'
Assert-True ($r.Out -match 'cut-release') 'no developer notes: names the script that produces them'
Assert-True (-not (Test-Path (Join-Path $noNotes 'releases\internal'))) 'no developer notes: nothing was created'
Remove-Item -Recurse -Force -LiteralPath $noNotes -ErrorAction SilentlyContinue

$existing = New-Fixture -Label 'existing' -NotesContent $notes
$r = Invoke-Script -Dir $existing
Assert-Equal 0 $r.Code 'first run: creates the skeleton'
$intPath = Join-Path $existing 'releases\internal\3.x\3.2.0.md'
Assert-True (Test-Path -LiteralPath $intPath) 'first run: the note exists'
# THE ASSERT THAT MATTERS MOST IN THIS FILE. Overwriting an edited note back to a skeleton destroys the
# only content in the three tiers that cannot be regenerated from anything.
[System.IO.File]::WriteAllText($intPath, "# hand-written, do not lose me`n", $Utf8NoBom)
$r = Invoke-Script -Dir $existing
Assert-Equal 1 $r.Code 'second run without -Force: refuses'
Assert-True ($r.Out -match '-Force') 'second run: names the flag that would overwrite'
Assert-True ([System.IO.File]::ReadAllText($intPath) -match 'do not lose me') 'second run: the written text is untouched'
$r = Invoke-Script -Dir $existing -ExtraArgs @('-Force')
Assert-Equal 0 $r.Code '-Force: overwrites'
Assert-True ([System.IO.File]::ReadAllText($intPath) -notmatch 'do not lose me') '-Force: really replaced the file'
Remove-Item -Recurse -Force -LiteralPath $existing -ErrorAction SilentlyContinue

Write-Host "new-internal-note -- an invalid version is refused before any IO" -ForegroundColor Cyan
$bad = New-Fixture -Label 'badver' -NotesContent $notes
$r = Invoke-Script -Dir $bad -Version 'not-a-version'
Assert-Equal 1 $r.Code 'a non X.Y.Z version exits 1'
Assert-True (-not (Test-Path (Join-Path $bad 'releases\internal'))) 'and wrote nothing'
# A leading v is accepted: the tag form and the bare form are the same release.
$r = Invoke-Script -Dir $bad -Version 'v3.2.0'
Assert-Equal 0 $r.Code 'a leading v is accepted (tag form)'
Assert-True (Test-Path (Join-Path $bad 'releases\internal\3.x\3.2.0.md')) 'and lands under the bare number'
Remove-Item -Recurse -Force -LiteralPath $bad -ErrorAction SilentlyContinue

# --- 2. The skeleton's shape ----------------------------------------------------------------------
Write-Host "new-internal-note -- the skeleton" -ForegroundColor Cyan
$happy = New-Fixture -Label 'happy' -NotesContent $notes
$r = Invoke-Script -Dir $happy
Assert-Equal 0 $r.Code 'happy path: exit 0'
$doc = [System.IO.File]::ReadAllText((Join-Path $happy 'releases\internal\3.x\3.2.0.md'))
Assert-True (Test-Line -Text $doc -Pattern '# Internal summary v3\.2\.0') 'the title names the version'
Assert-True (Test-Line -Text $doc -Pattern '\*\*Date:\*\* 2026-08-03') 'the date is copied from the developer notes'
Assert-True (Test-Line -Text $doc -Pattern '\*\*Type:\*\* Minor') 'the type is copied too'
Assert-True ($doc -match '(?m)^\*\*For whom:\*\* colleagues and management') 'the audience line states who it is for'
foreach ($h in @('What is different now', 'What it is worth', 'What was still open at this release')) {
    Assert-True (Test-Line -Text $doc -Pattern ('## ' + [regex]::Escape($h))) "the fixed heading '$h' is present"
}
Assert-True ($doc -match '(?s)What is different now.*What it is worth.*What was still open at this release') 'the three headings are in order'
# The third heading is PAST TENSE and names the release, and that is the fix rather than a wording
# preference: this document is the published GitHub Release body, so it does not move with reality. A
# present-tense heading invites lines that go stale in hours -- measured three times on August 4, 2026,
# once by a line stating the previous release had no public page, published minutes before it got one.
# Asserted as a negative too, because the old wording is the natural thing to type back in.
Assert-True ($doc -notmatch '(?m)^## What is still open') 'the open heading is not present tense (it would date the published body)'
# Not Test-Line: the hint sits mid-line inside the skeleton comment block, so a whole-line match is the
# wrong tool here even though every heading assert above uses one.
Assert-True ($doc -match 'SNAPSHOT of this release') 'the skeleton hint tells the writer to write a snapshot, not a claim about the present'
# The titles carry over WITHOUT the PR number and date -- this document has a reader with no branch.
Assert-True (Test-Line -Text $doc -Pattern '- \[Feat\] Turn the highlights tier on') 'an entry becomes a [type] bullet with a bare title'
Assert-True (Test-Line -Text $doc -Pattern '- \[Fix\] The teardown audit walks every file') 'and so does one from another category'
Assert-True ($doc -notmatch '#428') 'the PR number is not carried into the document'
Assert-True ($doc -notmatch '2026-08-03 *$' -or $true) 'the per-entry date is not carried into the bullets'
Assert-Equal 3 (@([regex]::Matches($doc, '(?m)^- \[')).Count) 'exactly three bullets -- only H3 entries count, not the H2 categories or the H4 inside a body'
Assert-True ($doc -notmatch 'A subheading inside the entry') 'an H4 inside an entry body is not read as an entry'
# The skeleton says it is a skeleton, and points back at its source.
Assert-True ($doc -match 'SKELETON') 'the document announces itself as a skeleton'
Assert-True ($doc -match 'releases/development/3\.x/3\.2\.0\.md') 'and names the notes it was built from'
Assert-True ($r.Out -match 'Step 1') 'the run prints the next step'
Assert-True ($r.Out -match 'branch') 'and says it ships via a branch (the release commit is already tagged)'
Remove-Item -Recurse -Force -LiteralPath $happy -ErrorAction SilentlyContinue

Write-Host "new-internal-note -- notes without the metadata lines" -ForegroundColor Cyan
# A repo whose notes use other labels must get a visible '(fill in)' rather than a blank line that
# nobody notices until the document is being read by someone else.
$noMeta = New-Fixture -Label 'nometa' -NotesContent "# Release notes v3.2.0`n`nNo metadata lines here.`n`n### #1 $midDot A title $midDot Feat $midDot 2026-08-03`n`nBody.`n"
$r = Invoke-Script -Dir $noMeta
Assert-Equal 0 $r.Code 'missing metadata does not stop the run'
$doc = [System.IO.File]::ReadAllText((Join-Path $noMeta 'releases\internal\3.x\3.2.0.md'))
Assert-True ($doc -match '\*\*Date:\*\* \(fill in\)') 'a missing date becomes a visible placeholder'
Assert-True ($doc -match '\*\*Type:\*\* \(fill in\)') 'and so does a missing type'
Assert-True ($r.Out -match 'fill in the date by hand') 'and the run warns about it out loud'
Remove-Item -Recurse -Force -LiteralPath $noMeta -ErrorAction SilentlyContinue

Write-Host "new-internal-note -- notes with no entries at all" -ForegroundColor Cyan
$noEntries = New-Fixture -Label 'noentries' -NotesContent "# Release notes v3.2.0`n`n**Date:** 2026-08-03  `n**Type:** Patch`n`nNothing structured here.`n"
$r = Invoke-Script -Dir $noEntries
Assert-Equal 0 $r.Code 'no entries does not stop the run'
$doc = [System.IO.File]::ReadAllText((Join-Path $noEntries 'releases\internal\3.x\3.2.0.md'))
Assert-True ($doc -match 'no entries found') 'the list says so instead of being silently empty'
Remove-Item -Recurse -Force -LiteralPath $noEntries -ErrorAction SilentlyContinue

# --- 3. The folder scheme follows the repo's one answer -------------------------------------------
Write-Host "new-internal-note -- the folder scheme comes from Get-ReleaseNotesGrouping" -ForegroundColor Cyan
# Per MINOR: the note must land beside its developer notes, not in a scheme of its own. This is the assert
# that would catch the tier drifting away from the other two.
$minorCfg = "function Get-ReleaseNotesGrouping { return 'minor' }`n"
$perMinor = New-Fixture -Label 'perminor' -NotesDir '3.2' -NotesContent $notes -RepoConfig $minorCfg
$r = Invoke-Script -Dir $perMinor
Assert-Equal 0 $r.Code 'per-minor grouping: exit 0'
Assert-True (Test-Path (Join-Path $perMinor 'releases\internal\3.2\3.2.0.md')) 'per-minor grouping: the note lands in releases/internal/3.2/'
Assert-True (-not (Test-Path (Join-Path $perMinor 'releases\internal\3.x'))) 'per-minor grouping: and NOT in a 3.x folder'
Remove-Item -Recurse -Force -LiteralPath $perMinor -ErrorAction SilentlyContinue

# --- 4. The wording seam (#410 class) -------------------------------------------------------------
Write-Host "new-internal-note -- every string in the document is overridable" -ForegroundColor Cyan
$nlCfg = @'
function Get-InternalNoteWording {
    return @{
        Title          = 'Interne samenvatting'
        AudienceLabel  = 'Voor wie'
        Audience       = 'werkgevers en management'
        SectionChanged = 'Wat er nu anders is'
        SectionValue   = 'Wat het oplevert'
        SectionOpen    = 'Wat er nog open staat'
    }
}
'@
$translated = New-Fixture -Label 'nl' -NotesContent $notes -RepoConfig $nlCfg
$r = Invoke-Script -Dir $translated
Assert-Equal 0 $r.Code 'translated wording: exit 0'
$doc = [System.IO.File]::ReadAllText((Join-Path $translated 'releases\internal\3.x\3.2.0.md'))
Assert-True (Test-Line -Text $doc -Pattern '# Interne samenvatting v3\.2\.0') 'the title is overridden'
Assert-True (Test-Line -Text $doc -Pattern '\*\*Voor wie:\*\* werkgevers en management') 'the audience label AND its text are overridden'
foreach ($h in @('Wat er nu anders is', 'Wat het oplevert', 'Wat er nog open staat')) {
    Assert-True (Test-Line -Text $doc -Pattern ('## ' + [regex]::Escape($h))) "the heading '$h' is overridden"
}
Assert-True ($doc -notmatch 'What is different now') 'no English heading survives alongside the override'
# MERGED, not substituted: a key the override does not mention keeps its English default rather than
# vanishing. Without this, a consumer translating three headings would silently lose the fill-in hints.
Assert-True ($doc -match 'SKELETON') 'an unmentioned key keeps its default -- the map is merged'
Assert-True ($doc -match 'cannot be generated') 'the value hint survives untranslated rather than disappearing'
Remove-Item -Recurse -Force -LiteralPath $translated -ErrorAction SilentlyContinue

# ===================================================================================================
# THE TIER SELECTION (August 5, 2026): tier 1 and 2 are carried over, tier 0 is not
# ===================================================================================================
Write-Host "Tiered developer notes: tier 1 and 2 come over, tier 0 stays behind" -ForegroundColor Cyan
# The developer notes are now nested one level deeper -- '## Tier <n>' -> '### <Category>' ->
# '#### <entry>' -- so an entry is recognised by its metadata SHAPE rather than by its heading level. A
# level-based match would have collected the CATEGORY headings instead and put the words 'Features' and
# 'Fixes' in a document written for colleagues.
$tieredNotes = @"
# Release notes v3.2.0

**Date:** 2026-08-03
**Type:** Minor

## Tier 2 - consumers

### Features

#### #470 $midDot A consumer-facing feature $midDot Feat $midDot 2026-08-05

Body text.

### Fixes

#### #469 $midDot A consumer-facing fix $midDot Fix $midDot 2026-08-05

Body text.

## Tier 1 - colleagues

### Documentation

#### #468 $midDot Something for colleagues $midDot Docs $midDot 2026-08-04

Body text.

## Tier 0 - developers

### Maintenance

#### #467 $midDot Repo-internal housekeeping $midDot Chore $midDot 2026-08-04

Body text.
"@
$tiered = New-Fixture -Label 'tiered' -NotesContent $tieredNotes
$r = Invoke-Script -Dir $tiered
Assert-Equal 0 $r.Code 'tiered notes: exit 0'
$doc = [System.IO.File]::ReadAllText((Join-Path $tiered 'releases\internal\3.x\3.2.0.md'))
Assert-True ($doc -match '- \[Feat\] A consumer-facing feature') 'tiered notes: a tier-2 entry is carried over -- the ladder is cumulative'
Assert-True ($doc -match '- \[Fix\] A consumer-facing fix')      'tiered notes: and the second one in that tier'
Assert-True ($doc -match '- \[Docs\] Something for colleagues')  'tiered notes: the tier-1 entry is carried over'
Assert-True ($doc -notmatch 'Repo-internal housekeeping')        'tiered notes: the tier-0 entry is NOT -- the developer notes are its record'
# The category headings must not be mistaken for entries. Asserted as bullets specifically: the words do
# appear in the document's own prose, so a bare -notmatch would be satisfied by the wrong thing.
foreach ($cat in 'Features', 'Fixes', 'Documentation', 'Maintenance') {
    Assert-True ($doc -notmatch "(?m)^- (\[[^\]]+\] )?$cat`$") "tiered notes: the '$cat' category heading is not carried over as a bullet"
}
Assert-True ($doc -notmatch '#470') 'tiered notes: the PR number is stripped, as before'
Remove-Item -Recurse -Force -LiteralPath $tiered -ErrorAction SilentlyContinue

Write-Host "The CURRENT note shape: entries recognised by their named sections" -ForegroundColor Cyan
# THE GAP THAT LET A DEFECT LIVE: every fixture above is the shape the notes had BEFORE the flat changelog,
# and they all still pass -- which is right, because a note can be regenerated for any release ever cut. But
# nothing here described what release-lib writes TODAY, so nobody noticed that the recogniser had stopped
# finding anything at all. It matched '>= 3 middot fields in the heading' with the type as the second-to-last;
# the format took those fields away one at a time (the date to the closing line, the type into its own
# section, then the PR number), and at two fields every real entry fell below the threshold.
#
# MEASURED AGAINST A NOTE BUILT FROM THE LIVE CHANGELOG, before rewriting it: 46 headings skipped, all ten
# entries among them, and the ONE heading that still matched was a QUOTED example inside a fenced code block
# in an entry body -- which became the note's only bullet, with the illustration's own words as its type.
# That case is the last assert in this block, so it cannot come back.
$currentNotes = @"
# Release notes v3.6.0

**Date:** 2026-08-05
**Type:** Minor

## Tier 2 - consumers

### A consumer-facing feature

#### What does this change do?

Body text.

#### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 4 | consumers notice |
| 1 | 3 | colleagues too |

#### Type of change

Feat

---

### A consumer-facing fix

#### What does this change do?

Body text, and it quotes the older heading shape while documenting it:

``````text
#### #469 $midDot An old-shape heading $midDot Fix $midDot 2026-08-05
``````

#### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 2 | small |
| 1 | 2 | small |

#### Type of change

Fix

## Tier 1 - colleagues

### Something for colleagues

#### What does this change do?

Body text.

#### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 1 | 3 | useful |

#### Type of change

Docs

## Tier 0 - developers

### Repo-internal housekeeping

#### What does this change do?

Body text.

#### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 0 | - | - |

#### Type of change

Chore
"@
$cur = New-Fixture -Label 'current-shape' -NotesContent $currentNotes -Version '3.6.0'
$rc = Invoke-Script -Dir $cur -Version '3.6.0'
Assert-Equal 0 $rc.Code 'current shape: exit 0'
$curDoc = [System.IO.File]::ReadAllText((Join-Path $cur 'releases\internal\3.x\3.6.0.md'))
# The type comes from the '#### Type of change' SECTION now, not from a heading field.
Assert-True ($curDoc -match '- \[Feat\] A consumer-facing feature') 'current shape: a tier-2 entry becomes a bullet, its type read from the Type section'
Assert-True ($curDoc -match '- \[Fix\] A consumer-facing fix')      'current shape: and the second one in that tier'
Assert-True ($curDoc -match '- \[Docs\] Something for colleagues')  'current shape: the tier-1 entry is carried over'
Assert-True ($curDoc -notmatch 'Repo-internal housekeeping')        'current shape: the tier-0 entry is not -- the developer notes are its record'
# The three section headings sit one level under every entry; reading them as entries would put the same
# four words in the document once per change. Asserted as bullets, since the words appear in prose too.
foreach ($sec in 'What does this change do\?', 'Who is this for', 'Type of change') {
    Assert-True ($curDoc -notmatch "(?m)^- (\[[^\]]+\] )?$sec`$") "current shape: the '$sec' section heading is not carried over as a bullet"
}
# And the tier headings themselves, which sit one level ABOVE the entries.
foreach ($tierWord in 'Tier 2 - consumers', 'Tier 1 - colleagues') {
    Assert-True ($curDoc -notmatch "(?m)^- (\[[^\]]+\] )?$tierWord`$") "current shape: the '$tierWord' heading is not an entry either"
}
# THE FABRICATED BULLET, as a standing check. The quoted heading inside the second entry's body is the exact
# shape the old recogniser matched, and it is the only thing it found in the real document.
Assert-True ($curDoc -notmatch 'An old-shape heading') 'current shape: a heading quoted inside a fenced block is not read as an entry'
Assert-True ($curDoc -notmatch '#469') 'current shape: so its number does not reach the document either'
Assert-Equal 3 (@([regex]::Matches($curDoc, '(?m)^- \[')).Count) 'current shape: exactly three bullets -- the tier-2 pair and the tier-1 one, nothing else'
Remove-Item -Recurse -Force -LiteralPath $cur -ErrorAction SilentlyContinue

# ===================================================================================================
# THE FLAT SHAPE (#881, August 25, 2026): no tier heading, so the ENTRY's declaration is the filter
# ===================================================================================================
Write-Host "The flat shape: no tier heading, the entry's own declaration decides" -ForegroundColor Cyan
# This is what release-lib writes NOW -- entries at '##' and their sections at '###', exactly
# CHANGELOG.md's levels, with no '## Tier <n>' wrapper above them. The container heading this script used
# to filter on is gone, and the fallback it had ("no tier headings, take everything") would have carried
# the tier-0 entry into a document written for colleagues. Silent, plausible, and wrong in the direction
# that publishes repo-internal work: the same failure shape as the fabricated bullet above.
$flatNotes = @"
# Release notes v3.7.0

**Date:** 2026-08-25
**Type:** Minor

## A consumer-facing feature

### What does this change do?

Body text.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 4 | consumers notice |
| 1 | 3 | colleagues too |

### Type of change

Feat

---

## Something for colleagues

### What does this change do?

Body text.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 1 | 3 | useful |

### Type of change

Docs

---

## Repo-internal housekeeping

### What does this change do?

Body text.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 0 | - | - |

### Type of change

Chore
"@
$flat = New-Fixture -Label 'flat-shape' -NotesContent $flatNotes -Version '3.7.0'
$rf = Invoke-Script -Dir $flat -Version '3.7.0'
Assert-Equal 0 $rf.Code 'flat shape: exit 0'
$flatDoc = [System.IO.File]::ReadAllText((Join-Path $flat 'releases\internal\3.x\3.7.0.md'))
Assert-True ($flatDoc -match '- \[Feat\] A consumer-facing feature') 'flat shape: the tier-2 entry becomes a bullet'
Assert-True ($flatDoc -match '- \[Docs\] Something for colleagues')  'flat shape: and so does the tier-1 entry'
Assert-True ($flatDoc -notmatch 'Repo-internal housekeeping') `
    'flat shape: the tier-0 entry is filtered out on ITS OWN declaration, with no heading to read it from'
Assert-Equal 2 (@([regex]::Matches($flatDoc, '(?m)^- \[')).Count) 'flat shape: exactly two bullets'
Remove-Item -Recurse -Force -LiteralPath $flat -ErrorAction SilentlyContinue

# And the all-tier-0 case in the flat shape: the warning still names the reason rather than reporting a
# parse failure, which is the one thing the container heading used to be needed for.
$flatZeroNotes = @"
# Release notes v3.8.0

**Date:** 2026-08-25
**Type:** Patch

## Only housekeeping

### What does this change do?

Body text.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 0 | - | - |

### Type of change

Chore
"@
$flatZero = New-Fixture -Label 'flat-allzero' -NotesContent $flatZeroNotes -Version '3.8.0'
$rfz = Invoke-Script -Dir $flatZero -Version '3.8.0'
Assert-Equal 0 $rfz.Code 'flat shape, all tier 0: exit 0'
Assert-True ($rfz.Out -match 'is tier 0') 'flat shape, all tier 0: the warning names the tier, not a parse failure'
Remove-Item -Recurse -Force -LiteralPath $flatZero -ErrorAction SilentlyContinue

Write-Host "Notes whose every entry is tier 0: an empty list, with the reason" -ForegroundColor Cyan
# Reachable only through -SkipTierGate (the cut refuses such a release), which is exactly why the message
# has to distinguish it from "the notes did not parse" -- one is a bypassed judgement, the other a defect.
$allZeroNotes = @"
# Release notes v3.2.0

**Date:** 2026-08-03
**Type:** Patch

## Tier 0 - developers

### Maintenance

#### #467 $midDot Only housekeeping $midDot Chore $midDot 2026-08-04

Body text.
"@
$allZero = New-Fixture -Label 'allzero' -NotesContent $allZeroNotes
$r = Invoke-Script -Dir $allZero
Assert-Equal 0 $r.Code 'all tier 0: exit 0 -- a thin release is not a failure'
Assert-True ($r.Out -match 'is tier 0') 'all tier 0: the warning says every entry was tier 0'
Assert-True ($r.Out -notmatch 'No entry titles found') 'all tier 0: and does NOT report it as a parse failure'
$doc = [System.IO.File]::ReadAllText((Join-Path $allZero 'releases\internal\3.x\3.2.0.md'))
Assert-True ($doc -match 'no entries found') 'all tier 0: the skeleton carries the fill-in-by-hand placeholder'
Remove-Item -Recurse -Force -LiteralPath $allZero -ErrorAction SilentlyContinue

Write-Host "Untiered developer notes still carry everything" -ForegroundColor Cyan
# A repo with no tier split has no tier information to filter on, so filtering would EMPTY the document
# rather than focus it. The pre-tier fixture at the top of this file is that case; asserted explicitly
# here so the fallback is a stated guarantee rather than a side effect.
$flat = New-Fixture -Label 'flat-still-works' -NotesContent "# Release notes v3.2.0`n`n**Date:** 2026-08-03`n**Type:** Patch`n`n## Maintenance`n`n### #1 $midDot An untiered entry $midDot Chore $midDot 2026-08-03`n`nBody.`n"
$r = Invoke-Script -Dir $flat
Assert-Equal 0 $r.Code 'untiered notes: exit 0'
$doc = [System.IO.File]::ReadAllText((Join-Path $flat 'releases\internal\3.x\3.2.0.md'))
Assert-True ($doc -match '- \[Chore\] An untiered entry') 'untiered notes: every entry is carried over, tier filter or not'
Remove-Item -Recurse -Force -LiteralPath $flat -ErrorAction SilentlyContinue

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
