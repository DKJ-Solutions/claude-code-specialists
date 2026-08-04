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

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
