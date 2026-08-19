<#
.SYNOPSIS
    Tests for scripts/release/build-release-notes-page.ps1 -- the browsable page built from the
    hand-written release notes, and the Cloudflare Worker that serves it.

.DESCRIPTION
    IT TESTS THE GENERATED PAGE, NOT THE SCRIPT'S INTERNALS, and that is deliberate rather than
    stylistic. The consumer this capability was ported from found its live-marker bug exactly that
    way: the script was internally consistent and the page pointed at three live versions. So the
    asserts here parse the data block out of the output and ask it questions a reader would ask.

    What is covered, and why these:
      1. the page is built from the HISTORY TABLE -- order, date, type and title come from there,
         which is the only thing that knows them;
      2. the live marker is matched case-sensitively, the bug that consumer paid for: a release
         whose TITLE merely contains the word 'live' must not mark itself;
      3. a release with no note is skipped rather than rendered empty, and the two kinds of absence
         are reported differently (a gap inside the covered range is named, older ones are counted);
      4. a note containing a closing script tag cannot end the page's data block early -- the
         failure that renders an empty page with nothing erroring;
      5. the grouping seam really is read, so a repo foldering per minor is not silently given an
         empty page;
      6. the path token is an INPUT: -Worker refuses without one instead of inventing one, and
         -InitToken refuses to replace one. That refusal is the whole safety property, because an
         invented token means every link already sent 404s while everything reports success;
      7. wrangler.toml is written once and never overwritten, since a consumer edits it.

    Fixture paths carry $PID: the test gate is a throttled PARALLEL scheduler, so two runs at one
    fixed temp path tear down each other's tree mid-assert.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\release\build-release-notes-page.ps1'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) "release-notes-page-test-fixture-$PID"

. (Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1')

$script:pass = 0
$script:fail = 0
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

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

function Assert-Match {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern not found: '$Pattern'" -ForegroundColor Red
    }
}

function Write-FixtureFile {
    param([string]$Path, [string]$Content)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function New-FixtureRepo {
    <#
        A minimal consuming repo: a seam file, a history table and a note per release. The notes are
        deliberately small -- what is under test is the assembly, and the renderer runs in a browser
        rather than here.
    #>
    param(
        [string]$Label,
        [string]$Grouping = 'major',
        [string]$WorkerName = '',
        [switch]$OmitTitle,
        [switch]$NoteWithScriptTag,
        [string]$ThemeBody = ''
    )
    $root = Join-Path $Fixture "repo-$Label"
    if (Test-Path -LiteralPath $root) { Remove-Item -Recurse -Force -LiteralPath $root }
    New-Item -ItemType Directory -Force -Path $root | Out-Null

    $titleFn = if ($OmitTitle) { '' } else { "function Get-ReleasePageTitle { return 'Fixture Product' }" }
    $config = @"
function Get-RepoName { return 'fixture-owner/fixture-repo' }
function Get-ReleaseNoteRoot { return 'releases/audience' }
function Get-ReleaseNotesGrouping { return '$Grouping' }
function Get-ReleaseHistoryPath { return 'releases/README.md' }
function Get-ReleasePageWorkerName { return '$WorkerName' }
$titleFn
$(if ($ThemeBody) { "function Get-ReleasePageTheme { $ThemeBody }" } else { '' })
"@
    Write-FixtureFile (Join-Path $root 'scripts\repo-config.ps1') $config

    # 2.1.0 has no note on purpose: it sits BETWEEN two releases that do, so it is the gap case.
    # 1.0.0 is older than every note, so it is the counted case.
    $history = @"
# Releases

#### 2.x

| Version | Date | Type | Title |
|---|---|---|---|
| [2.2.0](audience/2.x/2.2.0.md) | 2026-08-14 | Minor | The live push moved to a new stage |
| [2.1.0](audience/2.x/2.1.0.md) | 2026-08-12 | Patch | A release with no note |
| [2.0.0](audience/2.x/2.0.0.md) <- **LIVE** | 2026-08-10 | Major | The first one |

#### 1.x

| Version | Date | Type | Title |
|---|---|---|---|
| [1.0.0](audience/1.x/1.0.0.md) | 2026-07-01 | Major | Older than any note |
"@
    Write-FixtureFile (Join-Path $root 'releases\README.md') $history

    $folder = { param($v) if ($Grouping -eq 'minor') { ($v.Split('.')[0..1] -join '.') } else { "$($v.Split('.')[0]).x" } }
    $extra = if ($NoteWithScriptTag) { "`n`nA literal closing script tag follows: </script> and the page must survive it." } else { '' }
    foreach ($v in @('2.2.0', '2.0.0')) {
        Write-FixtureFile (Join-Path $root "releases\audience\$(& $folder $v)\$v.md") "# Release notes v$v`n`n**Date:** x`n`nBody of $v.$extra"
    }
    return $root
}

function Invoke-Build {
    param([string]$Root, [string[]]$ScriptArgs = @())
    $all = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Script, '-RootOverride', $Root) + $ScriptArgs
    $r = Invoke-NativeCapture -FilePath 'powershell' -Arguments $all
    return [pscustomobject]@{ Code = $r.ExitCode; Out = (($r.Output | ForEach-Object { "$_" }) -join "`n") }
}

function Get-PageData {
    <# The data block the page carries, parsed -- the questions below are a reader's, not the script's. #>
    param([string]$PagePath)
    $html = [System.IO.File]::ReadAllText($PagePath, [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($html, '(?s)<script type="application/json" id="release-data">(.*?)</script>')
    if (-not $m.Success) { throw "no data block in $PagePath" }
    return [pscustomobject]@{ Html = $html; Json = $m.Groups[1].Value; Data = ($m.Groups[1].Value | ConvertFrom-Json) }
}

try {
    Write-Host "== release-notes-page.tests: scripts/release/build-release-notes-page.ps1 ==" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $Fixture | Out-Null

    # --- 1. The page is built from the history table ----------------------------------------------
    Write-Host "build -- the history table is the source of order, date, type and title" -ForegroundColor Cyan
    $r1 = New-FixtureRepo -Label 'basic'
    $b1 = Invoke-Build -Root $r1
    Assert-Equal 0 $b1.Code 'basic: exit 0'

    $page1 = Join-Path $r1 'releases\page\release-notes.html'
    Assert-True (Test-Path -LiteralPath $page1) 'basic: the page is written beside the note root, in page/'

    $p1 = Get-PageData -PagePath $page1
    Assert-Equal 2 $p1.Data.documentCount 'basic: two releases carry a note'
    Assert-Equal '2.2.0' $p1.Data.releases[0].version 'basic: newest first, as the table reads'
    Assert-Equal '2.0.0' $p1.Data.releases[1].version 'basic: oldest last'
    Assert-Equal '2026-08-14' $p1.Data.releases[0].date 'basic: the date comes from the table'
    Assert-Equal 'Major' $p1.Data.releases[1].type 'basic: the type comes from the table'
    Assert-Match 'Body of 2\.2\.0' $p1.Data.releases[0].body 'basic: the note body travels into the page'
    Assert-Match 'Fixture Product' $p1.Html 'basic: Get-ReleasePageTitle is the page title'
    Assert-True (-not ($p1.Html -match '@@[A-Z_]+@@')) 'basic: no template placeholder survives'

    # --- 2. The live marker, case-sensitively -----------------------------------------------------
    # THE BUG THE CONSUMER PAID FOR. 2.2.0's title is 'The live push moved to a new stage'; under
    # PowerShell's default case-insensitive -match it marks itself, and the page then claims two
    # live versions.
    Write-Host "build -- the live marker is matched case-sensitively" -ForegroundColor Cyan
    Assert-Equal $false $p1.Data.releases[0].live 'live: a title containing the word "live" does NOT mark itself'
    Assert-Equal $true  $p1.Data.releases[1].live 'live: the row carrying **LIVE** does'
    Assert-Equal 1 (@($p1.Data.releases | Where-Object { $_.live }).Count) 'live: exactly one release is live'

    # --- 3. A release without a note --------------------------------------------------------------
    Write-Host "build -- the two kinds of missing note are reported differently" -ForegroundColor Cyan
    Assert-True (-not (@($p1.Data.releases | Where-Object { $_.version -eq '2.1.0' }).Count)) 'skip: a release with no note is not on the page'
    Assert-Match '2\.1\.0' $b1.Out 'skip: a gap INSIDE the covered range is named'
    Assert-Match 'earlier\s*:\s*1 release' $b1.Out 'skip: releases older than the first note are counted, not named'

    # --- 4. A note that contains a closing script tag ---------------------------------------------
    # The silent failure: the data block ends early and the page renders empty, with nothing here
    # erroring. The script asserts on a raw '<' rather than trusting the serializer; this holds it to
    # that on real input.
    Write-Host "build -- a note cannot close the page's data block early" -ForegroundColor Cyan
    $r4 = New-FixtureRepo -Label 'scripttag' -NoteWithScriptTag
    $b4 = Invoke-Build -Root $r4
    Assert-Equal 0 $b4.Code 'scripttag: exit 0'
    $p4 = Get-PageData -PagePath (Join-Path $r4 'releases\page\release-notes.html')
    Assert-Equal 0 ([regex]::Matches($p4.Json, '<').Count) 'scripttag: no raw "<" survives into the data block'
    Assert-Equal 2 $p4.Data.documentCount 'scripttag: the page still parses and carries both releases'
    Assert-Match 'closing script tag follows' $p4.Data.releases[0].body 'scripttag: the text itself is preserved'

    # --- 5. The grouping seam is really read ------------------------------------------------------
    Write-Host "build -- Get-ReleaseNotesGrouping decides which folder is read" -ForegroundColor Cyan
    $r5 = New-FixtureRepo -Label 'minor' -Grouping 'minor'
    $b5 = Invoke-Build -Root $r5
    Assert-Equal 0 $b5.Code 'grouping: a repo foldering per minor builds'
    $p5 = Get-PageData -PagePath (Join-Path $r5 'releases\page\release-notes.html')
    Assert-Equal 2 $p5.Data.documentCount 'grouping: both notes found under <X.Y>/'

    # A repo whose seam disagrees with its tree finds nothing, and the error has to say which of the
    # two it looked for -- otherwise the reader is told only that something is empty.
    $r5b = New-FixtureRepo -Label 'mismatch'
    Write-FixtureFile (Join-Path $r5b 'scripts\repo-config.ps1') (
        ((Get-Content -LiteralPath (Join-Path $r5b 'scripts\repo-config.ps1') -Raw) -replace "return 'major'", "return 'minor'"))
    $b5b = Invoke-Build -Root $r5b
    Assert-Equal 1 $b5b.Code 'grouping mismatch: refuses rather than writing an empty page'
    Assert-Match 'Get-ReleaseNotesGrouping' $b5b.Out 'grouping mismatch: the error names the seam it read'

    # --- 6. The title fallback --------------------------------------------------------------------
    Write-Host "build -- the title falls back to the repo name" -ForegroundColor Cyan
    $r6 = New-FixtureRepo -Label 'notitle' -OmitTitle
    $b6 = Invoke-Build -Root $r6
    Assert-Equal 0 $b6.Code 'title fallback: exit 0'
    $p6 = Get-PageData -PagePath (Join-Path $r6 'releases\page\release-notes.html')
    Assert-Match '<title>fixture-repo</title>' $p6.Html 'title fallback: the name half of Get-RepoName, not the owner/name pair'

    # --- 7. The path token is an input ------------------------------------------------------------
    Write-Host "worker -- the path token is never invented" -ForegroundColor Cyan
    $r7 = New-FixtureRepo -Label 'worker' -WorkerName 'fixture-release-notes'
    $pageDir7 = Join-Path $r7 'releases\page'

    $w1 = Invoke-Build -Root $r7 -ScriptArgs @('-Worker')
    Assert-Equal 1 $w1.Code 'token: -Worker without a token refuses'
    Assert-Match 'does NOT invent one' $w1.Out 'token: the refusal says why, not just that'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $pageDir7 'worker-path-token.txt'))) 'token: the refusal created no token'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $pageDir7 'worker.js'))) 'token: and no worker bundle'
    Assert-True (Test-Path -LiteralPath (Join-Path $pageDir7 'release-notes.html')) 'token: the page half still ran -- the refusal is the worker half only'

    $w2 = Invoke-Build -Root $r7 -ScriptArgs @('-Worker', '-InitToken')
    Assert-Equal 0 $w2.Code 'token: -InitToken creates one and the worker builds'
    $token = ([System.IO.File]::ReadAllText((Join-Path $pageDir7 'worker-path-token.txt'), [System.Text.Encoding]::UTF8)).Trim()
    Assert-Match '^[0-9a-f]{32}$' $token 'token: 32 hex characters'

    $workerJs = [System.IO.File]::ReadAllText((Join-Path $pageDir7 'worker.js'), [System.Text.Encoding]::UTF8)
    Assert-Match ([regex]::Escape("/notes/$token")) $workerJs 'worker: the route carries the token'
    Assert-Match 'x-robots-tag' $workerJs 'worker: the response is marked noindex'
    Assert-Match 'status: 404' $workerJs 'worker: everything off the route is a 404'

    $w3 = Invoke-Build -Root $r7 -ScriptArgs @('-InitToken')
    Assert-Equal 1 $w3.Code 'token: a second -InitToken refuses'
    Assert-Equal $token ([System.IO.File]::ReadAllText((Join-Path $pageDir7 'worker-path-token.txt'), [System.Text.Encoding]::UTF8)).Trim() 'token: and leaves the existing one exactly as it was'

    # --- 8. -Worker without the seam --------------------------------------------------------------
    Write-Host "worker -- hosting needs the worker name" -ForegroundColor Cyan
    $w4 = Invoke-Build -Root $r1 -ScriptArgs @('-Worker')
    Assert-Equal 1 $w4.Code 'worker name: an empty seam refuses -Worker'
    Assert-Match 'Get-ReleasePageWorkerName' $w4.Out 'worker name: the error names the function to add'

    # --- 9. wrangler.toml is written once ---------------------------------------------------------
    Write-Host "worker -- wrangler.toml is the consumer's file after the first write" -ForegroundColor Cyan
    $wrangler = Join-Path $pageDir7 'wrangler.toml'
    Assert-True (Test-Path -LiteralPath $wrangler) 'wrangler: written on the first -Worker run'
    Assert-Match 'name = "fixture-release-notes"' ([System.IO.File]::ReadAllText($wrangler, [System.Text.Encoding]::UTF8)) 'wrangler: carries the seam name'
    [System.IO.File]::WriteAllText($wrangler, "name = `"fixture-release-notes`"`nmain = `"worker.js`"`n# EDITED BY HAND", $Utf8NoBom)
    $w5 = Invoke-Build -Root $r7 -ScriptArgs @('-Worker')
    Assert-Equal 0 $w5.Code 'wrangler: a later run succeeds'
    Assert-Match 'EDITED BY HAND' ([System.IO.File]::ReadAllText($wrangler, [System.Text.Encoding]::UTF8)) 'wrangler: a hand edit survives the rebuild'

    # A name that has drifted from the seam is reported rather than corrected: which of the two is
    # wrong is not the script's to decide.
    [System.IO.File]::WriteAllText($wrangler, "name = `"something-else`"`nmain = `"worker.js`"", $Utf8NoBom)
    $w6 = Invoke-Build -Root $r7 -ScriptArgs @('-Worker')
    Assert-Equal 0 $w6.Code 'wrangler: a drifted name does not fail the build'
    Assert-Match 'something-else' $w6.Out 'wrangler: but it is reported'

    # --- 10. A missing history file ----------------------------------------------------------------
    Write-Host "build -- the release history has to be there" -ForegroundColor Cyan
    $r10 = New-FixtureRepo -Label 'nohistory'
    Remove-Item -LiteralPath (Join-Path $r10 'releases\README.md') -Force
    $b10 = Invoke-Build -Root $r10
    Assert-Equal 1 $b10.Code 'no history: refuses'
    Assert-Match 'Get-ReleaseHistoryPath' $b10.Out 'no history: the error names the seam that points at it'

    # --- 11. The palette seam (inbound #759) -------------------------------------------------------
    # WHY THE ASSERTS ARE ABOUT POSITION AND NOT ONLY PRESENCE. The override has to beat the
    # '@media (prefers-color-scheme: dark)' block, which means being LATER in the stylesheet -- a
    # palette emitted above it is silently ignored on a dark-mode machine and correct everywhere else,
    # which is the worst kind of wrong: it works on the developer's screen.
    Write-Host "build -- the repo's own palette (Get-ReleasePageTheme)" -ForegroundColor Cyan
    $r11 = New-FixtureRepo -Label 'theme' -ThemeBody "return @{ '--accent' = '#FF4F01'; 'color-scheme' = 'light' }"
    $b11 = Invoke-Build -Root $r11
    Assert-Equal 0 $b11.Code 'theme: exit 0'
    $p11 = Get-PageData -PagePath (Join-Path $r11 'releases\page\release-notes.html')
    Assert-Match '--accent:\s*#FF4F01;' $p11.Html 'theme: the custom property reaches the page'
    Assert-Match 'color-scheme:\s*light;' $p11.Html "theme: 'color-scheme' is accepted, which is how a brand with no dark variant says so"
    Assert-True (-not ($p11.Html -match '@@[A-Z_]+@@')) 'theme: no template placeholder survives'
    # The position assert: the LAST occurrence of the override must come after the media query.
    $darkAt  = $p11.Html.IndexOf('prefers-color-scheme: dark')
    $themeAt = $p11.Html.IndexOf('#FF4F01')
    Assert-True ($darkAt -ge 0 -and $themeAt -gt $darkAt) 'theme: the palette is written AFTER the dark-mode block, so it wins on a dark machine too'
    # EXACTLY ONE OVERRIDE BLOCK, which is the assert that names the defect this pair caught: the
    # template's doc comment used to spell the placeholder in full, String.Replace hit that occurrence
    # too, and the palette was written twice -- once inside an HTML comment, above the dark-mode block.
    # The page still rendered correctly, so only position and count could see it.
    # ANCHORED ON THE LINE START, so the count measures CSS rules and not prose. The unanchored version
    # counted the comment three lines above this one, which QUOTES ':root { ... }' while explaining the
    # defect -- the mention-versus-use question this repo's lint has now answered four times, arriving
    # in a test.
    Assert-Equal 3 ([regex]::Matches($p11.Html, '(?m)^\s*:root \{').Count) 'theme: three :root blocks -- the two shipped ones plus this palette, written ONCE'

    # NO SEAM, NO BLOCK. The placeholder must vanish rather than leave an empty ':root {}' behind, and
    # the shipped palette must still be there -- a page whose accent went missing because a repo
    # declined to override it would be the seam breaking the default it exists to extend.
    $r11b = New-FixtureRepo -Label 'nopalette'
    $b11b = Invoke-Build -Root $r11b
    Assert-Equal 0 $b11b.Code 'no palette: exit 0'
    $p11c = Get-PageData -PagePath (Join-Path $r11b 'releases\page\release-notes.html')
    # COUNTED RATHER THAN MATCHED ON THE FUNCTION NAME, which is what the first version of this assert
    # did and could never pass: the template's own doc comment names the seam, so the string is in every
    # page whether a repo answered or not. Two ':root {' blocks is the shipped shape -- light, then the
    # dark override -- and a third is a palette.
    Assert-Equal 2 ([regex]::Matches($p11c.Html, '(?m)^\s*:root \{').Count) 'no palette: the page carries the two shipped :root blocks and no third'
    Assert-True (-not ($p11c.Html -match "own palette --")) 'no palette: and no override comment either'
    Assert-Match '--accent: #b8562f' $p11c.Html 'no palette: the shipped palette is untouched'

    # --- 12. The palette is validated, not escaped ------------------------------------------------
    # THE VECTOR THIS EXISTS FOR. These values land in a <style> element, so a value carrying a closing
    # style tag ends the element and everything after it is markup. Escaping is not the remedy here --
    # an escaped '#' is not a colour -- so the value is dropped, and the page is still built, because a
    # report about releases must not be stopped by one bad colour.
    Write-Host "build -- a palette value cannot reach the markup raw" -ForegroundColor Cyan
    $evil = "return @{ '--accent' = 'red</style><script>alert(1)</script>'; '--ink' = 'blue; }'; 'position' = 'fixed'; '--line' = '#123456' }"
    $r12 = New-FixtureRepo -Label 'evil' -ThemeBody $evil
    $b12 = Invoke-Build -Root $r12
    Assert-Equal 0 $b12.Code 'hostile palette: the page is still generated'
    $p12 = Get-PageData -PagePath (Join-Path $r12 'releases\page\release-notes.html')
    Assert-True (-not ($p12.Html -match 'alert\(1\)')) 'hostile palette: the injected script never reaches the page'
    Assert-True (-not ($p12.Html -match '(?m)^\s*--ink: blue;')) 'hostile palette: a value carrying a brace-escape is dropped'
    Assert-True (-not ($p12.Html -match '(?m)^\s*position: fixed;')) 'hostile palette: a name that is not a custom property is dropped'
    Assert-Match '--line:\s*#123456;' $p12.Html 'hostile palette: and the SOUND value in the same map still lands -- one bad key costs one colour'
    Assert-Match 'Get-ReleasePageTheme' $b12.Out 'hostile palette: each drop is warned about, naming the function'
    Assert-Match "'--accent'" $b12.Out 'hostile palette: and naming the key, so a silently ignored setting is impossible'

} finally {
    Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Summary: $script:pass passed, $script:fail failed" -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
