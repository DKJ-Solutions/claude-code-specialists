<#
.SYNOPSIS
    Regression tests for scripts/lib/measure-skill-lib.ps1 -- the parsing and formatting half of
    measure-skill.ps1 -- plus the registry invariants that keep its wall-clock pass from running
    something destructive.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/measure-skill.tests.ps1

    IT DOES NOT RUN `claude`, AND THAT IS THE POINT OF THE LIB. The parse is the one fragile thing in
    the measurement -- it reads a human-formatted table whose shape the CLI owns -- so the functions
    that do the reading take strings and are pinned here against CAPTURED output. The fixture below is
    the real `claude plugin details team-alpha@claude-code-specialists` output at v4.17.0, all 19 rows,
    so the sum cross-check is genuinely exercised rather than mocked to agree with itself.

    THE THREE THINGS THIS FILE EXISTS TO CATCH, each of which was a live defect during the build:

      1. THE THOUSANDS TRAP. One table carries two notations -- '~3.031' is 3031 (the dot separates
         thousands) while '~1.3k' is 1300 (a k suffix on a decimal). Reading the first as 3.031
         under-reports by a factor of a thousand and still looks plausible.
      2. THE LOCALE TRAP, the same failure in the other direction. On a Dutch machine '{0:N0}' renders
         13700 as '13.700', which an English reader of this repo reads as 13.7. The first baseline this
         script wrote carried figures formatted that way. So the formatters are asserted UNDER a Dutch
         culture, not merely under the default one -- a test that only ran in en-US would have passed
         while the bug shipped.
      3. THE SAFETY INVARIANT. Pass 2 times a script by RUNNING it, so it runs only what the registry
         declares safe. `cut-release` must never be declared, and every declared flag must actually
         exist on the script it is declared for -- a MeasureArgs naming a renamed switch would invoke
         the script with an unknown argument.

    Pure ASCII (repo convention for .ps1). The fixture's header uses a hyphen where the real output has
    an em dash; nothing under test reads that character.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibSrc     = Join-Path $RepoRoot 'scripts\lib\measure-skill-lib.ps1'
$SharedSrc  = Join-Path $RepoRoot 'scripts\lib\shared-scripts-lib.ps1'

. $LibSrc
. $SharedSrc

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Name)
    if ($Expected -eq $Actual) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------------------------------------
# The fixture: real output, all 19 rows. Its rows sum to 3,010 against a printed total of 3,031 -- the
# 21-token gap being the two-significant-figure rounding the tolerance exists for.
# ---------------------------------------------------------------------------------------------------
$script:Fixture = @(
    'Claude Specialists - team alpha (the core team) (team-alpha) 4.17.0',
    '  Description: Portable executable core of the Claude Specialists system.',
    '  Source: team-alpha@claude-code-specialists',
    '',
    'Component inventory',
    '  Skills (4)  orchestrator, specialists-init, specialists-teardown, sync-roster',
    '  Agents (15)  02-09-agent, 03-07-agent, 04-11-agent, 04-12-agent, 04-13-agent, 04-18-agent, 05-15-agent, 06-16-agent, 06-17-agent, 06-19-agent, 06-23-agent, 06-24-agent, 06-25-agent, 06-29-agent, 06-30-agent',
    '  Hooks (1)  SessionStart  (harness-only - no model context cost)',
    '  MCP servers (0)',
    '  LSP servers (0)',
    '',
    'Projected token cost',
    '  Always-on:   ~3.031 tok   added to every session',
    '',
    'Per-component (rounded)',
    '  component             always-on  on-invoke',
    '  orchestrator               ~160      ~1.3k',
    '  specialists-init           ~200     ~13.7k',
    '  specialists-teardown       ~190     ~12.4k',
    '  sync-roster                ~150      ~2.6k',
    '  02-09-agent                 ~90        ~2k',
    '  03-07-agent                ~160      ~2.3k',
    '  04-11-agent                ~130      ~2.4k',
    '  04-12-agent                ~140      ~2.5k',
    '  04-13-agent                ~140      ~2.5k',
    '  04-18-agent                ~130      ~2.1k',
    '  05-15-agent                ~100      ~2.6k',
    '  06-16-agent                ~110      ~2.4k',
    '  06-17-agent                ~130      ~2.2k',
    '  06-19-agent                ~120      ~2.2k',
    '  06-23-agent                ~170      ~2.3k',
    '  06-24-agent                ~160      ~2.6k',
    '  06-25-agent                ~230      ~2.7k',
    '  06-29-agent                ~280      ~2.9k',
    '  06-30-agent                ~220      ~2.6k',
    '',
    '  On-invoke cost is paid each time a skill or agent fires.',
    '  Token counts are estimates and may differ from actual usage.'
)

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host '== ConvertTo-TokenCount -- the two notations that share one table ==' -ForegroundColor Cyan

Assert-Equal 3031  (ConvertTo-TokenCount '~3.031') 'a dot is a THOUSANDS separator: ~3.031 is 3031, not 3'
Assert-Equal 3031  (ConvertTo-TokenCount '3,031')  'a comma separator reads the same way: 3,031 is 3031'
Assert-Equal 1300  (ConvertTo-TokenCount '~1.3k')  'a k suffix makes the dot a DECIMAL point: ~1.3k is 1300'
Assert-Equal 13700 (ConvertTo-TokenCount '~13.7k') '~13.7k is 13700'
Assert-Equal 2000  (ConvertTo-TokenCount '~2k')    'a k with no decimal: ~2k is 2000'
Assert-Equal 160   (ConvertTo-TokenCount '~160')   'a plain figure passes through'
Assert-Equal 160   (ConvertTo-TokenCount '160')    'the tilde is optional'
Assert-Equal 1300  (ConvertTo-TokenCount '~1.3K')  'the k suffix is case-insensitive'
Assert-True  ($null -eq (ConvertTo-TokenCount ''))      'an empty value is $null, not 0 -- absent and zero are different answers'
Assert-True  ($null -eq (ConvertTo-TokenCount '-'))     'a dash is $null'
Assert-True  ($null -eq (ConvertTo-TokenCount 'n/a'))   'an unparseable value is $null rather than a guess'
Assert-True  ($null -eq (ConvertTo-TokenCount $null))   '$null in, $null out'

Write-Host ''
Write-Host '== The formatters, UNDER A DUTCH CULTURE (the locale trap) ==' -ForegroundColor Cyan

$prevCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
try {
    [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo('nl-NL')
    Assert-Equal '13,700' (Format-Tok 13700) 'Format-Tok is invariant: 13700 is 13,700 even under nl-NL (not 13.700)'
    Assert-Equal '3,031'  (Format-Tok 3031)  'Format-Tok: 3031 is 3,031 under nl-NL'
    Assert-Equal '8.9'    (Format-Pct 8.9)   'Format-Pct uses a decimal POINT under nl-NL (not 8,9)'
    Assert-Equal '11'     (Format-Pct 11)    'Format-Pct drops a trailing zero: 11, not 11.0'
    Assert-Equal '2.72'   (Format-Sec 2.72)  'Format-Sec uses a decimal point under nl-NL'
    Assert-Equal '1.30'   (Format-Sec 1.3)   'Format-Sec always shows two decimals'
} finally {
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $prevCulture
}
Assert-Equal 'n/a' (Format-Tok $null) 'Format-Tok says n/a for a figure that was not measured'

Write-Host ''
Write-Host '== Expand-ListArgument -- the -File invocation splits nothing itself ==' -ForegroundColor Cyan

$split = Expand-ListArgument -Value @('a,b,c')
Assert-Equal 3 $split.Count 'one comma-separated string becomes three values'
Assert-Equal 'b' $split[1]  'and in order'
Assert-Equal 2 (Expand-ListArgument -Value @('a', 'b')).Count      'two real values stay two'
Assert-Equal 2 (Expand-ListArgument -Value @('a, b ,')).Count      'whitespace is trimmed and an empty item dropped'
Assert-Equal 0 (Expand-ListArgument -Value $null).Count            '$null becomes an empty set, not a set containing $null'
Assert-Equal 0 (Expand-ListArgument -Value @()).Count              'an empty set stays empty'
Assert-Equal 3 (Expand-ListArgument -Value @('a,b', 'c')).Count     'the two forms mix'

Write-Host ''
Write-Host '== Read-PluginDetailsOutput -- against captured output ==' -ForegroundColor Cyan

$parsed = Read-PluginDetailsOutput -Lines $script:Fixture

Assert-Equal '4.17.0' $parsed.Version 'the version comes off the header line'
Assert-Equal 3031 $parsed.AlwaysOnTotal 'the printed Always-on total is read as 3031, not 3'
Assert-Equal 4 @($parsed.InventorySkills).Count 'the component inventory names four skills'
Assert-True (@($parsed.InventorySkills) -contains 'specialists-teardown') 'and they are split on the comma, trimmed'
Assert-Equal 19 @($parsed.Rows).Count 'nineteen component rows -- the table stops before the note under it'

$row = @($parsed.Rows | Where-Object { $_.Component -eq 'specialists-init' })[0]
Assert-Equal 200 $row.AlwaysOn 'a row reads its always-on figure'
Assert-Equal 13700 $row.OnInvoke 'and its on-invoke figure through the k suffix'

$sum = (@($parsed.Rows) | Measure-Object -Property AlwaysOn -Sum).Sum
Assert-Equal 3010 $sum 'the rows sum to 3,010 -- 21 short of the printed total, which IS the rounding'

Assert-True (-not (@($parsed.Rows | Select-Object -ExpandProperty Component) -contains 'On-invoke')) `
    'the prose line under the table did not become a row'
Assert-True (-not (@($parsed.Rows | Select-Object -ExpandProperty Component) -contains 'Hooks')) `
    'the inventory lines above the table did not become rows either'

Write-Host ''
Write-Host '== Get-PluginDetailsParseProblems -- a drifted parse refuses, it does not report ==' -ForegroundColor Cyan

Assert-Equal 0 (Get-PluginDetailsParseProblems -Details $parsed).Count `
    'the real output parses with no problems'

# A row dropped from the table while the inventory still names it: the shape a row-regex change takes.
$dropped = @($script:Fixture | Where-Object { $_ -notmatch 'specialists-teardown\s+~190' })
$droppedParsed = Read-PluginDetailsOutput -Lines $dropped
$droppedProblems = @(Get-PluginDetailsParseProblems -Details $droppedParsed)
Assert-True ($droppedProblems.Count -ge 1) 'a skill named in the inventory with no row is a problem'
Assert-True ((($droppedProblems -join ' ') -match 'specialists-teardown')) `
    'and the problem names which skill went missing'

# A total that does not agree with the rows: the shape a misread notation takes.
$wrongTotal = @($script:Fixture | ForEach-Object {
    if ($_ -match '^\s*Always-on:') { '  Always-on:   ~9.999 tok   added to every session' } else { $_ }
})
$wrongParsed = Read-PluginDetailsOutput -Lines $wrongTotal
$wrongProblems = @(Get-PluginDetailsParseProblems -Details $wrongParsed)
Assert-True ($wrongProblems.Count -ge 1) 'rows that do not sum to the printed total are a problem'
Assert-True (($wrongProblems -join ' ') -match 'tolerance') 'and the problem states the tolerance it broke'

# The rounding gap itself must NOT be a problem, or the check would refuse every real run.
Assert-Equal 0 (Get-PluginDetailsParseProblems -Details $parsed).Count `
    'the 21-token rounding gap is inside tolerance -- the check is not slack, but it is not brittle either'

$emptyParsed = Read-PluginDetailsOutput -Lines @()
Assert-True ((Get-PluginDetailsParseProblems -Details $emptyParsed).Count -ge 2) `
    'no output at all yields both problems (no rows, no total) rather than a clean pass'

Write-Host ''
Write-Host '== The registry safety invariants for pass 2 ==' -ForegroundColor Cyan

$pairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot)

# The three-state distinction. An `if` expression returning @() unrolls to nothing, which is why
# MeasureDeclared exists at all -- without it, "declared safe with no arguments" and "not declared"
# would both read as $null and the first would silently never be timed.
$declared = @($pairs | Where-Object { $_.MeasureDeclared })
Assert-True ($declared.Count -ge 1) 'at least one script declares a read-only invocation'

$withEmptyArgs = @($declared | Where-Object { @($_.MeasureArgs).Count -eq 0 })
Assert-True ($withEmptyArgs.Count -ge 1) `
    'a script declared safe with NO arguments is still reported as declared -- the @()-unrolls-to-$null trap'

$undeclared = @($pairs | Where-Object { -not $_.MeasureDeclared })
Assert-True ($undeclared.Count -ge 1) 'and the default is undeclared, i.e. never run'
Assert-True (@($undeclared | Where-Object { $null -ne $_.MeasureArgs }).Count -eq 0) `
    'an undeclared entry carries no MeasureArgs at all'

# THE SAFETY CANARY. cut-release is the example the whole design is argued from: timing it by running
# it would cut a release. If it ever acquires a MeasureArgs, this must fail.
$cutRelease = @($pairs | Where-Object { $_.Skill -eq 'cut-release' })
Assert-True ($cutRelease.Count -ge 1) 'cut-release is in the registry (otherwise this canary tests nothing)'
Assert-True (@($cutRelease | Where-Object { $_.MeasureDeclared }).Count -eq 0) `
    'NOTHING behind cut-release declares a read-only invocation, so pass 2 can never run it'

# Every declared flag must exist on the script it is declared for. A MeasureArgs naming a switch that
# was renamed would invoke the script with an unknown argument -- read via the PowerShell parser, the
# same way check 18 reads a script's parameters.
foreach ($p in $declared) {
    $params = @(Get-ScriptParameterNames -Path $p.SourcePath)
    foreach ($arg in @($p.MeasureArgs)) {
        if ($arg -notmatch '^-') { continue }
        $name = $arg.TrimStart('-')
        Assert-True ($params -contains $name) `
            "$($p.Name): its declared MeasureArgs flag -$name is a real parameter of $($p.SourceRel)"
    }
}

# measure-skill itself: registered, documented, and not timeable by its own pass 2.
$ms = @($pairs | Where-Object { $_.Name -eq 'measure-skill' })
Assert-Equal 1 $ms.Count 'measure-skill is registered as a shared entry point'
Assert-Equal 'measure-skill' $ms[0].Skill 'and names the skill page that documents it'
Assert-True (-not $ms[0].MeasureDeclared) `
    'measure-skill declares no read-only invocation of its own -- timing it would measure the CLI, not the script'
Assert-True (Test-Path -LiteralPath (Join-Path $RepoRoot $ms[0].SkillRel)) `
    'and that skill page is on disk'

$msLib = @($pairs | Where-Object { $_.Name -eq 'measure-skill-lib' })
Assert-Equal 1 $msLib.Count 'measure-skill-lib is registered'
Assert-True $msLib[0].LibOnly 'as a dot-sourced lib, so the dual-context invariant does not apply to it'
Assert-True ($null -eq $msLib[0].Skill) 'and a LibOnly entry declares no skill'

# ---------------------------------------------------------------------------------------------------
Write-Host ''
Write-Host "Result: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
