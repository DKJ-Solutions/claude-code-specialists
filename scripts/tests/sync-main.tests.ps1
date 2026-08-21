<#
.SYNOPSIS
    Regression tests for scripts/task/sync-main.ps1 -- team-shopify's pre-task sync (inbound #787,
    rewritten for the content rule on inbound #807).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell and git.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/sync-main.tests.ps1

    THE SUBJECT IS THE REFUSALS AND THE VERDICTS. The rules themselves are covered by
    scripts/tests/sync-rules.tests.ps1, against each query directly. What this suite drives is the script
    around them -- every path where it declines to run, and every path where it decides who wins a file --
    because each one exists to stop the same failure: a sync that proceeds on an assumption and silently
    reverts somebody's merged work. A refusal that regresses into a shrug does not break a test anywhere
    else; it just quietly starts losing work.

    THE HEADLINE CASE IS 'ours/buried'. It is the whole reason the rule moved from time to content: the
    trunk changed a file, a later sync commit buried that change below the floor, and live still holds the
    trunk's OLD copy. The time rule reports "the trunk has not touched this since the floor" and hands
    live's older content back -- forever, on every future run. The content rule recognises live's bytes as
    ours and holds the file back. If that assert ever flips, the sync has gone back to losing merged work.

    WHAT IS DELIBERATELY NOT TESTED HERE, stated rather than left as a gap:

      * The Shopify pull. It needs a store, credentials and a network, so every case passes -MirrorPath
        and stands in for live with a directory of its own. The pull is one line; every line after it is
        what these cases exercise.
      * The PR and the merge, which need a 'gh' that talks to GitHub. The seam defaults to not merging, so
        these cases never enter that branch.
      * The push is not ASSERTED, though it does run: the fixture's origin is a local bare repo, so the
        drift case genuinely pushes a sync branch into it. An assert on that would prove git can write to
        a directory, which is not a claim about this script.

    So the coverage boundary is honest: everything from "which paths differ" through "what happens to
    each one" is measured, and the network half is not.

    Fixture paths carry $PID (repo convention): the test gate is a throttled parallel scheduler, so two
    runs overlapping is ordinary, and two runs sharing one fixed temp path tear down each other's tree
    mid-assert.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\task\sync-main.ps1'

$script:pass = 0
$script:fail = 0
$script:trees = @()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor DarkGreen }
    else { $script:fail++; Write-Host "  [FAIL] $Message" -ForegroundColor Red }
}

function Invoke-Git {
    <# git with the EAP lowered: git writes ordinary progress to stderr, and under EAP=Stop that is a
       terminating NativeCommandError. #>
    $prevEap = $ErrorActionPreference
    try { $ErrorActionPreference = 'Continue'; & git @args 2>$null | Out-Null } finally { $ErrorActionPreference = $prevEap }
}

function Set-FixtureFile {
    <# Writes a file (creating its directory) with the bytes given, LF endings preserved. #>
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Rel,
        [Parameter(Mandatory = $true)][string]$Value
    )
    $target = Join-Path $Root ($Rel -replace '/', '\')
    $parent = Split-Path -Parent $target
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    # WriteAllText rather than Set-Content: the CRLF case needs the bytes it was given, and Set-Content's
    # encoding handling is one more thing between the test and what it claims to assert.
    [System.IO.File]::WriteAllText($target, $Value, (New-Object System.Text.ASCIIEncoding))
}

function New-Consumer {
    <#
        A fixture Shopify consumer: a git repo on 'main' with a local bare origin it can fast-forward
        from, plus a scripts/repo-config.ps1 carrying whichever seam answers the case needs.

        THE ORIGIN IS REAL because the script fast-forwards the trunk before it measures anything, so a
        fixture without one cannot reach the interesting cases at all.

        THE THEME FILE SITS UNDER sections/, NOT AT THE ROOT, and that is not decoration: the script
        compares only the directories a Shopify pull writes, so a fixture file at the root is invisible to
        it -- which would make every verdict assert here vacuously green.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [string]$ThemeId = '',
        [string]$StoreDomain = '',
        [string]$ExtraSeams = ''
    )
    $base = Join-Path ([System.IO.Path]::GetTempPath()) ("syncmain-$PID-$Label-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    $work = Join-Path $base 'work'
    $bare = Join-Path $base 'origin.git'
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    New-Item -ItemType Directory -Path $bare -Force | Out-Null
    $script:trees += $base

    Invoke-Git -C $bare init --bare --quiet
    Invoke-Git -C $work init --quiet
    Invoke-Git -C $work config user.name  'sync-main test'
    Invoke-Git -C $work config user.email 'sync@test.invalid'
    Invoke-Git -C $work config core.autocrlf false
    Invoke-Git -C $work checkout -q -b main

    $seams = @('# fixture repo-config')
    if ($ThemeId)     { $seams += "function Get-ShopifyLiveThemeId { return '$ThemeId' }" }
    if ($StoreDomain) { $seams += "function Get-ShopifyStoreDomain { return '$StoreDomain' }" }
    if ($ExtraSeams)  { $seams += $ExtraSeams }
    New-Item -ItemType Directory -Path (Join-Path $work 'scripts') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $work 'scripts\repo-config.ps1') -Value ($seams -join "`n") -Encoding ascii

    Set-FixtureFile -Root $work -Rel 'sections/theme.liquid' -Value 'v1'
    Invoke-Git -C $work add -A
    Invoke-Git -C $work commit -q -m 'initial'
    Invoke-Git -C $work remote add origin $bare
    Invoke-Git -C $work push -q -u origin main

    return $work
}

function Add-FixtureCommit {
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][string]$Message,
        [hashtable]$Write = @{},
        [string[]]$Delete = @()
    )
    foreach ($rel in $Write.Keys) { Set-FixtureFile -Root $Dir -Rel $rel -Value $Write[$rel] }
    foreach ($rel in $Delete) {
        $t = Join-Path $Dir ($rel -replace '/', '\')
        if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Force }
    }
    Invoke-Git -C $Dir add -A
    Invoke-Git -C $Dir commit -q -m $Message
    Invoke-Git -C $Dir push -q origin main
}

function New-Mirror {
    <# A stand-in for the live theme: a directory holding whatever live is supposed to have. #>
    param([Parameter(Mandatory = $true)][string]$Label, [hashtable]$Files = @{})
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("syncmirror-$PID-$Label-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $script:trees += $dir
    foreach ($rel in $Files.Keys) { Set-FixtureFile -Root $dir -Rel $rel -Value $Files[$rel] }
    return $dir
}

function Invoke-Sync {
    <# Runs the script in a child process against the fixture. -RootOverride both points it at the
       fixture and bypasses the marketplace refusal, exactly as the adopt-shopify-floor suite uses it. #>
    param([Parameter(Mandatory = $true)][string]$Dir, [string]$Mirror = '', [string[]]$Extra = @())
    if ($Mirror) { $Extra = @('-MirrorPath', $Mirror) + $Extra }
    # The EAP is lowered for the call, and this is the merged-stream pitfall rather than caution: git
    # writes ordinary lines like "Already on 'main'" to stderr, and '2>&1' under EAP=Stop wraps each one
    # in a NativeCommandError that terminates the suite. The redirection is what the assertions read, so
    # it stays and the preference gives way.
    $prevEap = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -RootOverride $Dir @Extra 2>&1
    } finally { $ErrorActionPreference = $prevEap }
    return @{ Out = ($out | Out-String); Code = $LASTEXITCODE }
}

try {
    # --- The seam refusals, both before anything is touched -----------------------------------------
    Write-Host 'the seam refusals'

    $noId = New-Consumer -Label 'noid' -StoreDomain 'a-store.myshopify.com'
    $r = Invoke-Sync -Dir $noId
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'Get-ShopifyLiveThemeId') 'seam/no-id: an unanswered theme id refuses, naming the seam'

    # A PLACEHOLDER IS NOT AN ANSWER. The same rule the guard applies, and the reason is the same: a
    # 'VUL-IN' left behind reads as answered to anything testing for emptiness.
    $vulIn = New-Consumer -Label 'vulin' -ThemeId 'VUL-IN' -StoreDomain 'a-store.myshopify.com'
    $r = Invoke-Sync -Dir $vulIn
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'does not answer with a theme id') 'seam/placeholder: a non-numeric id counts as no answer'

    $noStore = New-Consumer -Label 'nostore' -ThemeId '123456'
    $r = Invoke-Sync -Dir $noStore
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'Get-ShopifyStoreDomain') 'seam/no-store: an unanswered store refuses rather than guessing'
    $r = Invoke-Sync -Dir $noStore -Extra @('-Store', 'given.myshopify.com')
    Assert-True ($r.Out -notmatch 'Get-ShopifyStoreDomain is unanswered') 'seam/no-store: -Store gets past it for one run'

    # --- The retired switch ------------------------------------------------------------------------
    # -SkipPull meant "run the rule over the working tree", which cannot mean anything now that the pull
    # goes to a mirror. It is accepted purely so the refusal can name what replaced it, instead of leaving
    # a consumer with PowerShell's own "cannot find a parameter named" and no route forward.
    Write-Host ''
    Write-Host 'the retired -SkipPull switch'
    $r = Invoke-Sync -Dir $noStore -Extra @('-SkipPull')
    Assert-True ($r.Code -eq 1 -and $r.Out -match '-DryRun') 'retired/skippull: it refuses by name and points at -DryRun and -MirrorPath'
    Assert-True ($r.Out -match 'Nothing was changed') 'retired/skippull: and says nothing was changed'

    # --- The dirty tree ----------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'the working-tree refusal'
    $dirty = New-Consumer -Label 'dirty' -ThemeId '123456' -StoreDomain 'a-store.myshopify.com'
    Set-FixtureFile -Root $dirty -Rel 'sections/mine.liquid' -Value 'work in progress'
    $dirtyMirror = New-Mirror -Label 'dirty' -Files @{ 'sections/theme.liquid' = 'v1' }
    $r = Invoke-Sync -Dir $dirty -Mirror $dirtyMirror
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'not clean') 'dirty: uncommitted work refuses -- it would be committed as third-party drift'
    Assert-True (Test-Path -LiteralPath (Join-Path $dirty 'sections\mine.liquid')) 'dirty: and the uncommitted file is still there'
    # AND THE ONE CASE WHERE A DIRTY TREE IS THE INPUT. -DryRun writes nothing at all, so a dirty tree is
    # exactly when somebody wants to ask what the sync would do to it -- refusing there would make the
    # check unavailable at the one moment it is worth running.
    $r = Invoke-Sync -Dir $dirty -Mirror $dirtyMirror -Extra @('-DryRun')
    Assert-True ($r.Out -notmatch 'not clean') 'dirty: -DryRun does not refuse on a dirty tree'
    Assert-True ($r.Out -match 'DRY RUN') 'dirty: and says so, so nobody reads it as a real run'

    # --- No reference point ------------------------------------------------------------------------
    # It no longer decides who wins a file, but it is what notices that BOTH sides moved -- and without
    # it such a conflict would be taken silently, which is the failure this refusal exists for.
    Write-Host ''
    Write-Host 'the reference-point refusal'
    $bare = New-Consumer -Label 'noref' -ThemeId '123456' -StoreDomain 'a-store.myshopify.com'
    $bareMirror = New-Mirror -Label 'noref' -Files @{ 'sections/theme.liquid' = 'v1' }
    $r = Invoke-Sync -Dir $bare -Mirror $bareMirror
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'No reference point') 'noref: no sync commit and no tag refuses'
    Assert-True ($r.Out -match 'sync by hand|Tag the current state') 'noref: and says what to do instead'

    # --- The content rule, end to end --------------------------------------------------------------
    Write-Host ''
    Write-Host 'the content rule, driven through the script'
    $live = New-Consumer -Label 'live' -ThemeId '123456' -StoreDomain 'a-store.myshopify.com'
    # THE ACCENTED PATH IS A PIN, NOT DECORATION. git quotes any path with a byte above 0x7F by default --
    # 'assets/cafe.js' with an accent comes out of ls-tree as '"assets/caf\303\251.js"' -- and that string
    # matches nothing the mirror walk produces. The trunk's copy would then read as a path live does not
    # have while live's IDENTICAL file read as content the trunk has never held: foreign, taken, trunk
    # overwritten. The name is built from a code point because this layer is ASCII (repo convention), which
    # is the same reason the scaffolder writes its middle dot as [char]0x00B7.
    $accented = 'sections/caf' + [char]0x00E9 + '.liquid'
    $floorFiles = @{
        'sections/editor.liquid'  = 'e1'
        'sections/dropped.liquid' = 'was here once'
        'sections/crlf.liquid'    = "a`nb"
    }
    $floorFiles[$accented] = 'an accented filename, identical on both sides'
    Add-FixtureCommit -Dir $live -Message 'sync: the first floor' -Write $floorFiles
    # Trunk work: one file changed, one deleted, one added that live has never seen.
    Add-FixtureCommit -Dir $live -Message 'fix: the trunk changes a file' -Write @{ 'sections/theme.liquid' = 'trunk-v2' }
    Add-FixtureCommit -Dir $live -Message 'chore: the trunk drops a file'  -Delete @('sections/dropped.liquid')
    Add-FixtureCommit -Dir $live -Message 'feat: a file only the trunk has' -Write @{ 'sections/only-trunk.liquid' = 'not live yet' }
    # AND THEN A LATER SYNC, which is what buries all of that below the floor. This is the state the time
    # rule cannot survive: from here on it reports every one of those paths as untouched-since.
    Add-FixtureCommit -Dir $live -Message 'sync: a later sync that buries the trunk work' -Write @{ 'sections/unrelated.liquid' = 'u1' }

    $liveMirror = New-Mirror -Label 'live' -Files @{
        # live still holds the trunk's OLD copy of a file the trunk has since fixed -- ours, so held back.
        'sections/theme.liquid'     = 'v1'
        # live still holds a file the trunk deliberately deleted -- ours, so NOT resurrected.
        'sections/dropped.liquid'   = 'was here once'
        # a third party edited this one in the theme editor -- foreign, and the trunk has not touched it.
        'sections/editor.liquid'    = 'a third party wrote this'
        # a file only live has, that this repo has never held -- foreign, so taken.
        'sections/brand-new.liquid' = 'made in the theme editor'
        # the same text with CRLF endings: a line-ending difference is not drift.
        'sections/crlf.liquid'      = "a`r`nb"
        'sections/unrelated.liquid' = 'u1'
    }
    Set-FixtureFile -Root $liveMirror -Rel $accented -Value 'an accented filename, identical on both sides'

    $r = Invoke-Sync -Dir $live -Mirror $liveMirror
    Assert-True ($r.Out -match 'sections/theme\.liquid\s+live holds a version this repo has had before') 'ours/buried: live''s older copy of OUR file is held back, though the floor no longer covers it'
    Assert-True ($r.Out -match 'sections/dropped\.liquid\s+the trunk deleted this file') 'ours/deleted: a file the trunk deleted is NOT resurrected from live'
    Assert-True ($r.Out -match 'sections/only-trunk\.liquid\s+only the trunk has this file') 'never-deletes: a file live does not have is kept and reported, never deleted'
    Assert-True ($r.Out -match 'sections/editor\.liquid\s+content this repo has never held') 'foreign/changed: a third party''s edit to an untouched file is taken'
    Assert-True ($r.Out -match 'sections/brand-new\.liquid\s+content this repo has never held') 'foreign/added: a file only live has and we never held is taken'
    Assert-True ($r.Out -notmatch 'sections/crlf\.liquid') 'crlf: a line-ending-only difference is not a difference at all'
    Assert-True ($r.Out -notmatch 'caf') 'quotepath: a path with a non-ASCII byte is compared, not read as a new file'
    Assert-True ($r.Out -match 'drift on 2 file\(s\)') 'take: exactly the two foreign files go into the sync'
    # THE MIRROR MODEL'S OWN GUARANTEE: a held-back file is never written, so it cannot be damaged by a
    # rule that got it wrong or by a failure halfway. The wholesale version overwrote first and restored
    # afterwards, so every bug in the rule was a bug that had already happened.
    Assert-True ([System.IO.File]::ReadAllText((Join-Path $live 'sections\theme.liquid')) -eq 'trunk-v2') 'ours/buried: the trunk''s version is still the one on disk'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $live 'sections\dropped.liquid'))) 'ours/deleted: and the deleted file was never written back'
    Assert-True (Test-Path -LiteralPath (Join-Path $live 'sections\brand-new.liquid')) 'take: the taken file IS written'

    # --- Both sides moved: a conflict, and nothing written -----------------------------------------
    # The one thing the floor still decides. It can only ever escalate to a human, which is why a wrong
    # floor now costs an extra conflict report instead of silent data loss.
    Write-Host ''
    Write-Host 'the conflict refusal'
    $clash = New-Consumer -Label 'clash' -ThemeId '123456' -StoreDomain 'a-store.myshopify.com'
    Add-FixtureCommit -Dir $clash -Message 'sync: the floor' -Write @{ 'sections/both.liquid' = 'b1' }
    Add-FixtureCommit -Dir $clash -Message 'fix: the trunk changes it too' -Write @{ 'sections/both.liquid' = 'trunk-b2' }
    $clashMirror = New-Mirror -Label 'clash' -Files @{
        'sections/theme.liquid' = 'v1'
        'sections/both.liquid'  = 'a third party changed it as well'
    }
    $r = Invoke-Sync -Dir $clash -Mirror $clashMirror
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'REFUSING TO SYNC') 'conflict: both sides changed one path, so nothing is decided'
    Assert-True ($r.Out -match 'git diff --no-index') 'conflict: and it hands over the command that compares the two'
    Assert-True ([System.IO.File]::ReadAllText((Join-Path $clash 'sections\both.liquid')) -eq 'trunk-b2') 'conflict: the trunk''s version is untouched on disk'
    $branchNow = ([string](& git -C $clash rev-parse --abbrev-ref HEAD)).Trim()
    Assert-True ($branchNow -eq 'main') 'conflict: and no sync branch was created'

    # --- Nothing foreign at all --------------------------------------------------------------------
    Write-Host ''
    Write-Host 'the quiet run'
    $quiet = New-Consumer -Label 'quiet' -ThemeId '123456' -StoreDomain 'a-store.myshopify.com'
    Add-FixtureCommit -Dir $quiet -Message 'sync: the floor' -Write @{ 'sections/floor.liquid' = 'f1' }
    Add-FixtureCommit -Dir $quiet -Message 'fix: the trunk changes a file' -Write @{ 'sections/theme.liquid' = 'trunk-v2' }
    $quietMirror = New-Mirror -Label 'quiet' -Files @{
        'sections/theme.liquid' = 'v1'
        'sections/floor.liquid' = 'f1'
    }
    $r = Invoke-Sync -Dir $quiet -Mirror $quietMirror
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'No third-party drift') 'quiet: everything held back means nothing to sync, and exit 0'
    $status = & git -C $quiet status --porcelain
    Assert-True (-not (@($status | Where-Object { $_ }).Count)) 'quiet: and the tree is left clean, not half-written'

    # --- A gitignored path is not the sync's business ----------------------------------------------
    # config/settings_data.json is the case this exists for: a repo that ignores the live theme's settings
    # would otherwise see it arrive as a brand-new foreign file on every single run and capture it forever.
    # The filter is also where a measured trap sits -- 'check-ignore --stdin <paths>' exits 128 and reports
    # nothing ignored, so this assert is what proves the argument form is the one in use.
    Write-Host ''
    Write-Host 'the gitignore filter'
    $ign = New-Consumer -Label 'ignored' -ThemeId '123456' -StoreDomain 'a-store.myshopify.com'
    Add-FixtureCommit -Dir $ign -Message 'sync: the floor' -Write @{ '.gitignore' = "config/settings_data.json`n" }
    $ignMirror = New-Mirror -Label 'ignored' -Files @{
        'sections/theme.liquid'      = 'v1'
        'config/settings_data.json'  = '{"live":"settings"}'
    }
    $r = Invoke-Sync -Dir $ign -Mirror $ignMirror
    Assert-True ($r.Out -match 'gitignored here and are left alone') 'ignored: the filter reports what it excluded'
    Assert-True ($r.Out -notmatch 'settings_data\.json\s+content this repo has never held') 'ignored: and the ignored file is not captured as drift'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $ign 'config\settings_data.json'))) 'ignored: nor written into the repo'
}
finally {
    foreach ($d in $script:trees) {
        if ($d -and (Test-Path -LiteralPath $d)) {
            Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILED: $($script:fail) of $($script:pass + $script:fail) asserts." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
