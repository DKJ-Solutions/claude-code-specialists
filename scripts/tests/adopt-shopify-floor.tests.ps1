<#
.SYNOPSIS
    Tests for scripts/task/adopt-shopify-floor.ps1 -- the command that places team-shopify's operational
    floor in a consuming Shopify repo.

.DESCRIPTION
    WHAT IS ACTUALLY AT RISK HERE, because it is not "does it write three files". This command writes
    into a file that belongs to somebody else (their scripts/repo-config.ps1) and it writes a
    PLACEHOLDER on purpose. Two ways that goes wrong:

      1. It overwrites or duplicates something the repo already has. Everything about the mechanism is
         additive, so every skip path is asserted rather than assumed.
      2. The placeholder it writes gets read as an ANSWER. That is the one failure the design exists to
         avoid -- a stub returning 'VUL-IN' would silence the session check while leaving the guard's id
         half inert -- so the block it writes unanswered must not define the function at all. Asserted
         here on the text, and asserted from the other side in guard-live-theme.tests.ps1, where the
         guard and the check are shown to read a non-numeric answer as unanswered.

    Every case runs against a scratch fixture tree via -RootOverride. Nothing in this suite touches the
    repo it runs in.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Continue'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Script   = Join-Path $RepoRoot 'scripts\task\adopt-shopify-floor.ps1'
# Fixture paths carry $PID: the test gate is a throttled PARALLEL scheduler, so two runs at one fixed
# temp path tear down each other's tree mid-assert.
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) "adopt-shopify-floor-fixture-$PID"

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
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

function New-ConsumerRepo {
    <# A consuming repo, with or without the seam lib the bootstrap owns. #>
    param([string]$Label, [string]$ConfigBody = $null)
    $root = Join-Path $Fixture "repo-$Label"
    if (Test-Path -LiteralPath $root) { Remove-Item -Recurse -Force -LiteralPath $root }
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'scripts') | Out-Null
    if ($null -ne $ConfigBody) {
        [System.IO.File]::WriteAllText((Join-Path $root 'scripts\repo-config.ps1'), $ConfigBody, $Utf8NoBom)
    }
    return $root
}

function Invoke-Adopt {
    <# Returns the printed output plus the exit code. Invoked as a child process, as a consumer runs it. #>
    param([string]$Root, [switch]$Apply, [string]$LiveThemeId = '')
    # Deliberately NOT named $args: that is an automatic variable inside a function, and assigning it
    # works right up until somebody adds a splat or a nested call and cannot see why.
    $argv = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Script, '-RootOverride', $Root)
    if ($Apply) { $argv += '-Apply' }
    if ($LiveThemeId) { $argv += @('-LiveThemeId', $LiveThemeId) }
    $out = & powershell @argv 2>&1
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = (($out | ForEach-Object { "$_" }) -join "`n") }
}

$seedConfig = @'
# A consumer's own seam lib, as the bootstrap leaves it.
function Get-RepoName { return 'someone/their-theme' }
'@

try {
    Write-Host "== adopt-shopify-floor.tests: placing the Shopify floor ==" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $Fixture | Out-Null
    Assert-True (Test-Path -LiteralPath $Script) 'the script is where the registry says it is'

    # --- the dry run is the default ---------------------------------------------------------------
    # THE FIRST RUN OF A COMMAND THAT ADDS FILES TO YOUR REPO SHOWS YOU THE LIST. Same default as
    # adopt-config and adopt-workflow-folder, and the assert is that it wrote NOTHING -- a dry run that
    # quietly creates one of the three is worse than no dry run at all.
    Write-Host "the dry run -- prints the plan, touches nothing" -ForegroundColor Cyan
    $dry = New-ConsumerRepo -Label 'dry' -ConfigBody $seedConfig
    $r = Invoke-Adopt -Root $dry
    Assert-Equal 0 $r.Code 'dry run: exits 0'
    Assert-True ($r.Out -match '\[append\]') 'dry run: announces the seam block it would append'
    Assert-True ($r.Out -match '\[create\].*theme-check\.yml') 'dry run: and the starter config it would create'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $dry '.theme-check.yml'))) 'dry run: wrote no .theme-check.yml'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $dry '.github\workflows\theme-check.yml'))) 'dry run: wrote no workflow'
    Assert-True ((Get-Content -LiteralPath (Join-Path $dry 'scripts\repo-config.ps1') -Raw) -notmatch 'Shopify') 'dry run: left repo-config.ps1 untouched'
    Assert-True ($r.Out -match '-LiveThemeId') 'dry run: points at the parameter that arms the guard in the same move'

    # --- apply, unanswered ------------------------------------------------------------------------
    # THE CENTRAL CASE. Without -LiveThemeId the block must NOT define the function: a stub returning
    # 'VUL-IN' would silence the session check while the guard's id half stayed inert. So the placeholder
    # is present as guidance and the function is absent as behaviour, and both halves are asserted.
    Write-Host "apply without an id -- the block lands as a comment, on purpose" -ForegroundColor Cyan
    $plain = New-ConsumerRepo -Label 'plain' -ConfigBody $seedConfig
    $r = Invoke-Adopt -Root $plain -Apply
    Assert-Equal 0 $r.Code 'apply: exits 0'
    $cfg = Get-Content -LiteralPath (Join-Path $plain 'scripts\repo-config.ps1') -Raw
    Assert-True ($cfg -match 'Get-RepoName') 'apply: the consumer''s own content is still there -- appended, not rewritten'
    Assert-True ($cfg -match 'VUL-IN') 'apply: the placeholder is present as guidance'
    Assert-True ($cfg -notmatch '(?m)^\s*function\s+Get-ShopifyLiveThemeId') 'apply: and the function is NOT defined -- a stub would silence the check while the hole stayed'
    Assert-True ($cfg -match '(?m)^\s*#\s*function\s+Get-ShopifyLiveThemeId') 'apply: it is there commented out, one keystroke from an answer'
    Assert-True ($cfg -match 'shopify theme list') 'apply: with the command that produces the id, so nobody has to go looking'
    Assert-True ($r.Out -match 'id half inert') 'apply: and the closing report says the guard is not armed yet'

    # The other two files, and the content that has to be right rather than merely present.
    $yml = Get-Content -LiteralPath (Join-Path $plain '.theme-check.yml') -Raw
    Assert-True ($yml -match '(?m)^extends:\s*nothing') 'starter config: extends nothing -- the recommended set is red on arrival in a real theme'
    Assert-True ($yml -match 'LiquidHTMLSyntaxError' -and $yml -match 'JSONSyntaxError') 'starter config: the two checks both existing consumers independently arrived at'
    Assert-True ($yml -match 'assets/\*\.js\.liquid') 'starter config: carrying the false-positive exemption both of them needed'
    Assert-True ($yml -match '1504 offenses') 'starter config: and the measurement, so a later reader does not read minimal as lazy'

    $wf = Get-Content -LiteralPath (Join-Path $plain '.github\workflows\theme-check.yml') -Raw
    Assert-True ($wf -match 'Shopify/theme-check-action@v2') 'CI workflow: the action both consumers run'
    Assert-True ($wf -match 'actions/checkout@v5') 'CI workflow: checkout pinned at v5 -- the version every other pin in this repo carries'
    Assert-True ($wf -match '--fail-level error') 'CI workflow: at error level -- the two enabled checks are declared at error severity'
    Assert-True ($wf -match 'pull_request') 'CI workflow: on every PR rather than on a push'

    # --- apply with an id -------------------------------------------------------------------------
    Write-Host "apply with an id -- the guard is armed in the same move" -ForegroundColor Cyan
    $armed = New-ConsumerRepo -Label 'armed' -ConfigBody $seedConfig
    $r = Invoke-Adopt -Root $armed -Apply -LiveThemeId '190793613653'
    $cfg = Get-Content -LiteralPath (Join-Path $armed 'scripts\repo-config.ps1') -Raw
    Assert-True ($cfg -match '(?m)^function\s+Get-ShopifyLiveThemeId\s*\{\s*return\s*''190793613653''') 'answered: the function is defined with the id given'
    Assert-True ($cfg -notmatch 'VUL-IN.*numeric id') 'answered: and no placeholder is left beside it for the id'
    Assert-True ($r.Out -match 'armed on all three rules') 'answered: the report says the guard is now whole'
    # The function must actually LOAD, which asserting on the text alone would not prove.
    $loaded = & { Set-StrictMode -Off; . (Join-Path $armed 'scripts\repo-config.ps1'); return [string](Get-ShopifyLiveThemeId) }
    Assert-Equal '190793613653' $loaded 'answered: and the file still dot-sources, returning that id'

    # --- additive: a re-run finds nothing to do ---------------------------------------------------
    # NOTHING IS EVER OVERWRITTEN is the property that makes this safe to re-run, so it is asserted on
    # the bytes rather than on the printout.
    Write-Host "a re-run -- additive means idempotent" -ForegroundColor Cyan
    $before = @{}
    foreach ($rel in @('scripts\repo-config.ps1', '.theme-check.yml', '.github\workflows\theme-check.yml')) {
        $before[$rel] = Get-Content -LiteralPath (Join-Path $armed $rel) -Raw
    }
    $r = Invoke-Adopt -Root $armed -Apply -LiveThemeId '999'
    Assert-True ($r.Out -match 'Nothing to do') 're-run: reports that the floor is already adopted'
    foreach ($rel in $before.Keys) {
        Assert-Equal $before[$rel] (Get-Content -LiteralPath (Join-Path $armed $rel) -Raw) "re-run: $rel is byte-identical -- a different -LiveThemeId does not overwrite an answered seam"
    }

    # A repo that answers the seam from somewhere else is not told to add it twice either: the question
    # is asked of the LOADED function, not of the file text.
    $elsewhere = New-ConsumerRepo -Label 'elsewhere' -ConfigBody @'
. (Join-Path $PSScriptRoot 'shopify-answers.ps1')
'@
    [System.IO.File]::WriteAllText((Join-Path $elsewhere 'scripts\shopify-answers.ps1'), "function Get-ShopifyLiveThemeId { return '1' }", $Utf8NoBom)
    $r = Invoke-Adopt -Root $elsewhere
    Assert-True ($r.Out -match 'already answered here') 'seam answered from a sibling file: recognised, not duplicated'

    # An existing .theme-check.yml is somebody's own tuned file and must survive untouched.
    $tuned = New-ConsumerRepo -Label 'tuned' -ConfigBody $seedConfig
    [System.IO.File]::WriteAllText((Join-Path $tuned '.theme-check.yml'), "extends: theme-check:recommended`n", $Utf8NoBom)
    $r = Invoke-Adopt -Root $tuned -Apply
    Assert-Equal "extends: theme-check:recommended`n" (Get-Content -LiteralPath (Join-Path $tuned '.theme-check.yml') -Raw) 'an existing .theme-check.yml is left exactly as it is, however strict it happens to be'
    Assert-True ($r.Out -match 'already exists') 'and the skip is reported rather than passed over in silence'

    # --- not a bootstrap --------------------------------------------------------------------------
    # A MISSING SEAM LIB IS SOMEBODY ELSE'S JOB, and the interesting half is that the other two files
    # still land: refusing everything would make a repo run two commands to get one floor.
    Write-Host "no repo-config.ps1 -- reported, and the other two still land" -ForegroundColor Cyan
    $noLib = New-ConsumerRepo -Label 'nolib'
    Remove-Item -Recurse -Force -LiteralPath (Join-Path $noLib 'scripts')
    $r = Invoke-Adopt -Root $noLib -Apply
    Assert-True ($r.Out -match 'specialists-init') 'no seam lib: points at the skill that owns that file''s existence'
    Assert-True (Test-Path -LiteralPath (Join-Path $noLib '.theme-check.yml')) 'no seam lib: the starter config lands anyway'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $noLib 'scripts\repo-config.ps1'))) 'no seam lib: and nothing half-created the file itself'

} finally {
    Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Summary: $script:pass passed, $script:fail failed" -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
