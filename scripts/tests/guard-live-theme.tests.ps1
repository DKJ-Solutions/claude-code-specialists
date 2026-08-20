<#
.SYNOPSIS
    Tests for plugins/teams/team-shopify/hooks/guard-live-theme.ps1 -- the PreToolUse hook that holds
    the live Shopify theme -- and for the session check that says when it is only half armed.

.DESCRIPTION
    THE GUARD IS THE ONE FILE IN THIS PLUGIN WHERE BEING WRONG IS EXPENSIVE IN BOTH DIRECTIONS: too
    loose and a stray command reaches a revenue-serving theme, too tight and the deliberate live push a
    consumer's own rules describe cannot be executed at all. Everything else team-shopify ships is
    instruction text, which no test can hold.

    Each case feeds a realistic hook payload to the guard on stdin and asserts the exit code
    (2 = blocked, 0 = allowed). No mocking: the guard is invoked as the harness invokes it.

    FOUR GROUPS, AND EACH ONE ANSWERS A DIFFERENT WAY THIS CAN GO WRONG.
      1. The real commands must be blocked, INCLUDING when wrapped in a shell invocation -- that
         wrapper is exactly what a permission deny list cannot see, and the reason the hook exists.
      2. Mentioning the rule must NOT be blocked. Both cases here happened for real, on the day the
         reporting consumer installed their own version: the heredoc that wrote the rule into their
         CLAUDE.md, and the perl one-liner that edited that sentence afterwards.
      3. The exemptions in group 2 must not become a hole. A heredoc fed to an interpreter, text piped
         into a shell, xargs, and a real command sitting next to a harmless one are all still caught.
         GROUP 3 IS WHAT MAKES GROUP 2 SAFE TO HAVE -- an exemption without a counter-case is a hole
         with a comment on it.
      4. The seam, which is this version's own addition and therefore has no field history behind it:
         the id half of the live-push rule only exists where the repo answered, the marker default
         accepts what both existing consumers already write, and a configured marker narrows it.

    Groups 1 to 3 are ported from the reference implementation the reporting consumer offered
    (BWJ-ecommerce/xoxowildhearts, inbound #769), which is where the false-positive lesson was paid
    for. Group 4 and the session-check cases are new here, because the shipped version reads a seam
    that the single-repo original did not have.

    Pure ASCII (repo convention for .ps1).
#>
# 'Continue', not 'Stop': the guard writes its refusal to stderr, and PowerShell 5.1 turns native
# stderr from a child process into a terminating NativeCommandError when the preference is 'Stop'.
# That stderr IS the expected output of a blocking case, so it must not end the run.
$ErrorActionPreference = 'Continue'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Guard    = Join-Path $RepoRoot 'plugins\teams\team-shopify\hooks\guard-live-theme.ps1'
$Check    = Join-Path $RepoRoot 'plugins\teams\team-shopify\hooks\shopify-floor-sessioncheck.ps1'
# Fixture paths carry $PID: the test gate is a throttled PARALLEL scheduler, so two runs at one fixed
# temp path tear down each other's tree mid-assert.
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) "guard-live-theme-fixture-$PID"

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:pass = 0
$script:fail = 0
$LF = "`n"
$LIVE = '190793613653'

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

function New-FixtureRepo {
    <# A consuming repo with the seam answers under test, or none at all. #>
    param([string]$Label, [string]$ConfigBody = $null)
    $root = Join-Path $Fixture "repo-$Label"
    if (Test-Path -LiteralPath $root) { Remove-Item -Recurse -Force -LiteralPath $root }
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'scripts') | Out-Null
    if ($null -ne $ConfigBody) {
        [System.IO.File]::WriteAllText((Join-Path $root 'scripts\repo-config.ps1'), $ConfigBody, $Utf8NoBom)
    }
    return $root
}

function Invoke-Guard {
    <# Returns the exit code. The payload is the shape the harness sends, built rather than typed. #>
    param([string]$Command, [string]$Root)
    $payload = @{ tool_name = 'Bash'; tool_input = @{ command = $Command } } | ConvertTo-Json -Compress -Depth 5
    $prev = $env:CLAUDE_PROJECT_DIR
    $env:CLAUDE_PROJECT_DIR = $Root
    try {
        $payload | & powershell -NoProfile -ExecutionPolicy Bypass -File $Guard 2>&1 | Out-Null
        return $LASTEXITCODE
    } finally {
        if ($null -eq $prev) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prev }
    }
}

function Invoke-FloorCheck {
    param([string]$Root)
    $prev = $env:CLAUDE_PROJECT_DIR
    $env:CLAUDE_PROJECT_DIR = $Root
    try {
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Check 2>&1
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = (($out | ForEach-Object { "$_" }) -join "`n") }
    } finally {
        if ($null -eq $prev) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prev }
    }
}

try {
    Write-Host "== guard-live-theme.tests: the live-theme guard and its session check ==" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $Fixture | Out-Null
    Assert-True (Test-Path -LiteralPath $Guard) 'the guard is where hooks.json says it is'
    Assert-True (Test-Path -LiteralPath $Check) 'and so is the session check beside it'

    # A repo that answered both seams: the ordinary, fully configured consumer.
    $configured = New-FixtureRepo -Label 'configured' -ConfigBody @"
function Get-ShopifyLiveThemeId { return '$LIVE' }
"@

    # --- group 1: the real thing, blocked ---------------------------------------------------------
    Write-Host "group 1 -- the real commands are blocked, wrapper and all" -ForegroundColor Cyan
    $blocked = @(
        @{ n = 'publish';                      c = "shopify theme publish --store x.myshopify.com --theme 123" },
        @{ n = 'publish through a wrapper';    c = 'powershell -Command "shopify theme publish --theme 123"' },
        @{ n = 'delete';                       c = "shopify theme delete --store x.myshopify.com --theme 123" },
        @{ n = 'live push by id, no marker';   c = "shopify theme push --store x.myshopify.com --theme $LIVE --only assets/x.css" },
        @{ n = 'live push by --allow-live';    c = "shopify theme push --store x.myshopify.com --allow-live" },
        @{ n = 'live push through a wrapper';  c = 'powershell -Command "shopify theme push --allow-live"' }
    )
    foreach ($case in $blocked) { Assert-Equal 2 (Invoke-Guard -Command $case.c -Root $configured) "blocked: $($case.n)" }

    # --- group 1b: what must stay possible --------------------------------------------------------
    Write-Host "group 1b -- and the work that must stay possible is untouched" -ForegroundColor Cyan
    $allowed = @(
        @{ n = 'live push WITH the marker';        c = "shopify theme push --theme $LIVE --only assets/x.css --allow-live # LIVE-PUSH-AUTHORIZED" },
        @{ n = 'preview push by id';               c = "shopify theme push --store x.myshopify.com --theme 987654321" },
        @{ n = 'unpublished preview creation';     c = "shopify theme push --store x.myshopify.com --unpublished --theme-name feat-x --json" },
        @{ n = 'pull from live (pre-task sync)';   c = "shopify theme pull --store x.myshopify.com --theme $LIVE" },
        @{ n = 'pull --live';                      c = "shopify theme pull --store x.myshopify.com --live" },
        @{ n = 'theme list';                       c = "shopify theme list --store x.myshopify.com" },
        @{ n = 'an ordinary command';              c = "git status --short" }
    )
    foreach ($case in $allowed) { Assert-Equal 0 (Invoke-Guard -Command $case.c -Root $configured) "allowed: $($case.n)" }

    # --- group 2: talking about the rule is not performing it -------------------------------------
    # THE TWO THAT HAPPENED FOR REAL are the heredoc and the perl one-liner. They are the reason the
    # matching asks where the words sit rather than whether they occur.
    Write-Host "group 2 -- mentioning the rule is not performing it" -ForegroundColor Cyan
    $mentions = @(
        @{ n = 'a commit message mentioning publish'; c = 'git commit -m "document how theme publish is gated"' },
        @{ n = 'grepping for the phrase';             c = 'grep -n "shopify theme publish" CLAUDE.md' },
        @{ n = 'a perl one-liner editing it';         c = "perl -0pi -e 's/shopify theme publish/a theme publish/' CLAUDE.md" },
        @{ n = 'a sed one-liner writing it';          c = "sed -i 's/x/shopify theme delete/' notes.md" },
        @{ n = 'docs mentioning publish';             c = "cat > CLAUDE.md <<'EOF'${LF}Never run shopify theme publish yourself.${LF}EOF" },
        @{ n = 'docs mentioning a live push';         c = "cat > CLAUDE.md <<'EOF'${LF}shopify theme push --theme $LIVE --allow-live${LF}EOF" },
        @{ n = 'docs mentioning delete';              c = "cat > notes.md <<'EOF'${LF}shopify theme delete --theme 1${LF}EOF" },
        @{ n = 'an indented heredoc terminator';      c = "cat > notes.md <<-EOF${LF}shopify theme publish --theme 1${LF}    EOF" }
    )
    foreach ($case in $mentions) { Assert-Equal 0 (Invoke-Guard -Command $case.c -Root $configured) "mention: $($case.n)" }

    # --- group 3: the exemptions are not a hole ---------------------------------------------------
    Write-Host "group 3 -- and every exemption in group 2 has its counter-case" -ForegroundColor Cyan
    $holes = @(
        @{ n = 'a real command AFTER a heredoc';        c = "cat > notes.md <<'EOF'${LF}harmless text${LF}EOF${LF}shopify theme publish --theme 1" },
        @{ n = 'a heredoc fed to bash IS a script';     c = "bash <<'EOF'${LF}shopify theme publish --theme 1${LF}EOF" },
        @{ n = 'a heredoc fed to powershell likewise';  c = "powershell -Command - <<'EOF'${LF}shopify theme delete --theme 1${LF}EOF" },
        @{ n = 'echo piped into a shell executes';      c = 'echo "shopify theme publish --theme 1" | bash' },
        @{ n = 'cat piped into a shell';                c = 'cat script.sh | sh   # shopify theme publish --theme 1' },
        @{ n = 'xargs disables the exemption';          c = 'echo "shopify theme delete --theme 1" | xargs -I{} {}' },
        @{ n = 'a real command after a harmless one';   c = 'grep -n foo CLAUDE.md; shopify theme publish --theme 1' },
        @{ n = 'a live push after a harmless one';      c = "git status && shopify theme push --theme $LIVE --allow-live" }
    )
    foreach ($case in $holes) { Assert-Equal 2 (Invoke-Guard -Command $case.c -Root $configured) "counter-case: $($case.n)" }

    # A payload the guard cannot parse must fail towards CHECKING, not towards allowing.
    $prev = $env:CLAUDE_PROJECT_DIR
    $env:CLAUDE_PROJECT_DIR = $configured
    try {
        'this is not json but it says shopify theme publish' |
            & powershell -NoProfile -ExecutionPolicy Bypass -File $Guard 2>&1 | Out-Null
        Assert-Equal 2 $LASTEXITCODE 'an unparseable payload still blocks a publish -- it fails towards checking'
    } finally {
        if ($null -eq $prev) { Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue }
        else { $env:CLAUDE_PROJECT_DIR = $prev }
    }

    # --- group 4: the seam, which is this version's own addition -----------------------------------
    # THE SHIPPED GUARD READS A REPO'S ANSWERS, and the single-repo original it was ported from
    # hardcoded them. So this group has no field history behind it and is the part most worth asserting.
    Write-Host "group 4 -- the seam: what a repo answers, and what it gets when it does not" -ForegroundColor Cyan

    # No config file at all: the two absolute rules still hold, and so does the self-declaring flag.
    $bare = New-FixtureRepo -Label 'bare'
    Assert-Equal 2 (Invoke-Guard -Command 'shopify theme publish --theme 1' -Root $bare) 'no config: publish is still blocked -- rule 1 needs no answer'
    Assert-Equal 2 (Invoke-Guard -Command 'shopify theme delete --theme 1' -Root $bare) 'no config: delete is still blocked -- nor does rule 2'
    Assert-Equal 2 (Invoke-Guard -Command 'shopify theme push --allow-live' -Root $bare) 'no config: --allow-live still blocks, because the flag declares itself'
    # AND THE HOLE, ASSERTED RATHER THAN LEFT IMPLIED. This is the case the session check exists for:
    # the guard is installed, so it reads as protection, while a push aimed at live BY ID passes.
    Assert-Equal 0 (Invoke-Guard -Command "shopify theme push --theme $LIVE" -Root $bare) 'no config: a push aimed at live BY ID passes -- the id half cannot fire, which is what the session check reports'

    # A configured id is what closes it.
    Assert-Equal 2 (Invoke-Guard -Command "shopify theme push --theme $LIVE" -Root $configured) 'configured id: the same push is blocked'

    # THE DEFAULT MARKER IS A SUFFIX, so both existing consumers' spellings are accepted without either
    # of them configuring anything -- 'recognise both, write one', applied to a marker.
    Assert-Equal 0 (Invoke-Guard -Command "shopify theme push --theme $LIVE --allow-live # SWB-LIVE-PUSH-AUTHORIZED" -Root $configured) "default marker: one consumer's existing 'SWB-' spelling authorises"
    Assert-Equal 0 (Invoke-Guard -Command "shopify theme push --theme $LIVE --allow-live # XOXO-LIVE-PUSH-AUTHORIZED" -Root $configured) "default marker: and the other's 'XOXO-' spelling"
    Assert-Equal 2 (Invoke-Guard -Command "shopify theme push --theme $LIVE --allow-live # NOT-THE-MARKER" -Root $configured) 'default marker: an unrelated comment does not authorise'

    # A configured marker NARROWS it: the repo's own spelling only.
    $narrow = New-FixtureRepo -Label 'narrow' -ConfigBody @"
function Get-ShopifyLiveThemeId { return '$LIVE' }
function Get-ShopifyLivePushMarker { return 'ONLY-THIS-ONE' }
"@
    Assert-Equal 0 (Invoke-Guard -Command "shopify theme push --theme $LIVE --allow-live # ONLY-THIS-ONE" -Root $narrow) 'configured marker: the repo spelling authorises'
    Assert-Equal 2 (Invoke-Guard -Command "shopify theme push --theme $LIVE --allow-live # LIVE-PUSH-AUTHORIZED" -Root $narrow) 'configured marker: and the generic default no longer does -- configuring it NARROWS'

    # A broken config must not take the guard down with it: the absolute rules are the floor.
    $broken = New-FixtureRepo -Label 'broken' -ConfigBody "function Get-ShopifyLiveThemeId { this is not powershell"
    Assert-Equal 2 (Invoke-Guard -Command 'shopify theme publish --theme 1' -Root $broken) 'broken config: publish is still blocked rather than the guard erroring open'

    # --- the session check ------------------------------------------------------------------------
    Write-Host "the session check -- the half-armed state is the only thing it speaks about" -ForegroundColor Cyan
    $c1 = Invoke-FloorCheck -Root $bare
    Assert-Equal 0 $c1.Code 'floor check: never blocks a session, whatever it finds'
    Assert-True ($c1.Out -match '\[ERROR\]') 'floor check: an unanswered live theme id IS reported -- [ERROR] is the level the hook forwards'
    Assert-True ($c1.Out -match 'Get-ShopifyLiveThemeId') 'floor check: naming the function to add, not just the problem'
    Assert-True ($c1.Out -match 'publish, delete') 'floor check: and saying which rules DO hold, so it does not read as "unprotected"'

    $c2 = Invoke-FloorCheck -Root $configured
    Assert-Equal 0 $c2.Code 'floor check: exit 0 on a configured repo too'
    Assert-True (-not ($c2.Out -match '\[ERROR\]')) 'floor check: silent once the repo answered -- the ordinary state says nothing'

    # NO CONFIG FILE AT ALL IS ALSO SILENT, and that is a decision rather than an oversight: a repo that
    # has not run specialists-init already gets the one message naming its actual state.
    $noConfig = Join-Path $Fixture 'repo-noconfig'
    New-Item -ItemType Directory -Force -Path $noConfig | Out-Null
    $c3 = Invoke-FloorCheck -Root $noConfig
    Assert-Equal 0 $c3.Code 'floor check: exit 0 with no repo-config at all'
    Assert-True (-not ($c3.Out -match '\[ERROR\]')) 'floor check: and silent -- the bootstrap owns that message, not this hook'

} finally {
    Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Summary: $script:pass passed, $script:fail failed" -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
