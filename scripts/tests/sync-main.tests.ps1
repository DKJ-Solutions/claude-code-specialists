<#
.SYNOPSIS
    Regression tests for scripts/task/sync-main.ps1 -- team-shopify's pre-task sync (inbound #787).

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell and git.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/sync-main.tests.ps1

    THE SUBJECT IS THE REFUSALS, AND THAT IS THE WHOLE POINT. The exclusion rule itself is covered by
    scripts/tests/sync-rules.tests.ps1, against the two queries directly. What this suite drives is the
    script around it -- and specifically every path where it declines to run, because each one exists to
    stop the same failure: a sync that proceeds on an assumption and silently hands somebody's unpushed
    work to the live theme. A refusal that regresses into a shrug does not break a test anywhere else;
    it just quietly starts losing work.

    WHAT IS DELIBERATELY NOT TESTED HERE, stated rather than left as a gap:

      * The Shopify pull. It needs a store, credentials and a network, so -SkipPull is what most of these
        cases use -- the pull is one line, and every line after it is what they exercise. Live's side of
        the drift is staged into the fixture's worktree by hand instead, which is precisely what
        -SkipPull declares the tree to hold.
      * The PR and the merge, which need a 'gh' that talks to GitHub. The seam defaults to not merging,
        so these cases never enter that branch.
      * The push is not ASSERTED, though it does run: the fixture's origin is a local bare repo, so the
        drift case genuinely pushes a sync branch into it. An assert on that would prove git can write to
        a directory, which is not a claim about this script.

    So the coverage boundary is honest: everything up to and including "what does the exclusion rule keep
    and hold back" is measured, and the network half is not.

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

function New-Consumer {
    <#
        A fixture Shopify consumer: a git repo on 'main' with a local bare origin it can fast-forward
        from, plus a scripts/repo-config.ps1 carrying whichever seam answers the case needs.

        THE ORIGIN IS REAL because the script fast-forwards the trunk before it measures anything, so a
        fixture without one cannot reach the interesting cases at all.
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

    Set-Content -LiteralPath (Join-Path $work 'theme.liquid') -Value 'v1' -Encoding ascii -NoNewline
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
    foreach ($rel in $Write.Keys) {
        Set-Content -LiteralPath (Join-Path $Dir $rel) -Value $Write[$rel] -Encoding ascii -NoNewline
    }
    foreach ($rel in $Delete) {
        $t = Join-Path $Dir $rel
        if (Test-Path -LiteralPath $t) { Remove-Item -LiteralPath $t -Force }
    }
    Invoke-Git -C $Dir add -A
    Invoke-Git -C $Dir commit -q -m $Message
    Invoke-Git -C $Dir push -q origin main
}

function Invoke-Sync {
    <# Runs the script in a child process against the fixture. -RootOverride both points it at the
       fixture and bypasses the marketplace refusal, exactly as the adopt-shopify-floor suite uses it. #>
    param([Parameter(Mandatory = $true)][string]$Dir, [string[]]$Extra = @(), [switch]$WithPull)
    # -WithPull drops the -SkipPull flag, for the cases that refuse BEFORE the pull is ever reached. It
    # cannot reach a 'shopify' call: the clean-tree refusal is step 1.
    if (-not $WithPull) { $Extra = @('-SkipPull') + $Extra }
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

    # --- The dirty tree ----------------------------------------------------------------------------
    Write-Host ''
    Write-Host 'the working-tree refusal'
    $dirty = New-Consumer -Label 'dirty' -ThemeId '123456' -StoreDomain 'a-store.myshopify.com'
    Set-Content -LiteralPath (Join-Path $dirty 'mine.liquid') -Value 'work in progress' -Encoding ascii -NoNewline
    $r = Invoke-Sync -Dir $dirty -WithPull
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'not clean') 'dirty: uncommitted work refuses -- it would be committed as third-party drift'
    Assert-True (Test-Path -LiteralPath (Join-Path $dirty 'mine.liquid')) 'dirty: and the uncommitted file is still there'
    # AND THE ONE CASE WHERE A DIRTY TREE IS THE INPUT. -SkipPull says "the tree already holds what the
    # pull would have produced", so refusing there would make the switch a contradiction with itself: it
    # warns and proceeds instead. The warning is the assert, because a silent downgrade of this check is
    # exactly how uncommitted work gets committed as somebody else's drift.
    $r = Invoke-Sync -Dir $dirty
    Assert-True ($r.Out -match 'read as third-party drift') 'dirty: -SkipPull warns and proceeds instead, saying what it is about to treat as drift'

    # --- No reference point ------------------------------------------------------------------------
    # THE MOST IMPORTANT REFUSAL. Without a floor every file looks untouched by the trunk, so the
    # exclusion rule passes everything through and the failure arrives as a green run.
    Write-Host ''
    Write-Host 'the reference-point refusal'
    $bare = New-Consumer -Label 'noref' -ThemeId '123456' -StoreDomain 'a-store.myshopify.com'
    $r = Invoke-Sync -Dir $bare
    Assert-True ($r.Code -eq 1 -and $r.Out -match 'No reference point') 'noref: no sync commit and no tag refuses'
    Assert-True ($r.Out -match 'sync by hand|Tag the current state') 'noref: and says what to do instead'

    # --- The rule, end to end ----------------------------------------------------------------------
    Write-Host ''
    Write-Host 'the exclusion rule, driven through the script'
    $live = New-Consumer -Label 'live' -ThemeId '123456' -StoreDomain 'a-store.myshopify.com'
    Add-FixtureCommit -Dir $live -Message 'sync: the floor' -Write @{ 'floor.liquid' = 'v1' }
    # Trunk work after the floor: one changed file and one deleted file. Both must be held back.
    Add-FixtureCommit -Dir $live -Message 'fix: the trunk changes a file' -Write @{ 'theme.liquid' = 'trunk-v2' }
    Add-FixtureCommit -Dir $live -Message 'chore: the trunk deletes a file' -Delete @('floor.liquid')

    # Now stand in for the pull: live's copy of theme.liquid is older, live still has floor.liquid, and
    # live has a file of its own that nobody on the trunk has touched.
    Set-Content -LiteralPath (Join-Path $live 'theme.liquid')  -Value 'live-older' -Encoding ascii -NoNewline
    Set-Content -LiteralPath (Join-Path $live 'floor.liquid')  -Value 'live-still-has-it' -Encoding ascii -NoNewline
    Set-Content -LiteralPath (Join-Path $live 'editor.liquid') -Value 'a third party wrote this' -Encoding ascii -NoNewline

    $r = Invoke-Sync -Dir $live
    Assert-True ($r.Out -match 'theme\.liquid \(main has a newer version; kept\)') 'rule/changed: the trunk''s newer version is kept, live''s is not taken'
    Assert-True ($r.Out -match 'floor\.liquid \(main deleted this; not restored\)') 'rule/deleted: a file the trunk deleted is NOT resurrected from live'
    Assert-True ($r.Out -match 'Third-party drift on 1 file') 'rule/kept: only the genuinely third-party file goes into the sync'
    Assert-True ((Get-Content -LiteralPath (Join-Path $live 'theme.liquid') -Raw) -eq 'trunk-v2') 'rule/changed: the file on disk is the trunk''s version afterwards'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $live 'floor.liquid'))) 'rule/deleted: and the resurrected file is gone from the worktree again'

    # No third-party drift at all: it says so and leaves the index clean rather than committing nothing.
    $quiet = New-Consumer -Label 'quiet' -ThemeId '123456' -StoreDomain 'a-store.myshopify.com'
    Add-FixtureCommit -Dir $quiet -Message 'sync: the floor' -Write @{ 'floor.liquid' = 'v1' }
    Add-FixtureCommit -Dir $quiet -Message 'fix: the trunk changes a file' -Write @{ 'theme.liquid' = 'trunk-v2' }
    Set-Content -LiteralPath (Join-Path $quiet 'theme.liquid') -Value 'live-older' -Encoding ascii -NoNewline
    $r = Invoke-Sync -Dir $quiet
    Assert-True ($r.Code -eq 0 -and $r.Out -match 'No third-party drift') 'quiet: everything held back means nothing to sync, and exit 0'
    $status = & git -C $quiet status --porcelain
    Assert-True (-not (@($status | Where-Object { $_ }).Count) ) 'quiet: and the tree is left clean, not half-staged'
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
