<#
.SYNOPSIS
    The parsing and formatting half of measure-skill.ps1 -- everything that turns `claude plugin
    details` output into figures, with no I/O of its own.

.DESCRIPTION
    Dot-source this file from a sibling of the script that needs it, relative to $PSScriptRoot (NOT
    $repoRoot) -- like scripts/lib/check-report-lib.ps1 and unlike scripts/repo-config.ps1, this lib is
    not repo-owned, so it does not need a consumer-side scaffold. It travels as part of the SAME
    plugin/mirror payload as its caller (registered in scripts/lib/shared-scripts-lib.ps1):

        . (Join-Path $PSScriptRoot '..\lib\measure-skill-lib.ps1')   -- from scripts/maintenance/*

    WHY IT IS A LIB AND NOT PART OF THE SCRIPT. The parse is the one fragile thing in the whole
    measurement: it reads a human-formatted table whose shape the CLI owns and may change. A parser
    that cannot be tested without shelling out to `claude` is one nobody pins, so the functions that
    do the reading live here, take strings, and return objects. scripts/tests/measure-skill.tests.ps1
    dot-sources this file and asserts against captured output -- the same reasoning that put the entry
    format in entry-scaffold-lib.ps1, so a format change breaks the script and its test together
    instead of leaving the test asserting a shape nothing writes.

    Contains NO Write-Host, no exit, and no counter. Reporting belongs to the caller, which owns the
    [OK]/[INFO]/[ERROR] vocabulary from check-report-lib.ps1.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

# EVERY FIGURE IS FORMATTED INVARIANTLY, and that is not a style choice. Formatted on a Dutch machine,
# '{0:N0}' renders 13700 as '13.700' -- which an English reader of this repo reads as 13.7, off by a
# factor of a thousand and still plausible. That is the same trap ConvertTo-TokenCount guards against in
# the other direction. Same reasoning as Get-EnabledPlugins sorting ordinally: a figure must not depend
# on the machine that printed it.
$script:MeasureSkillInvariant = [System.Globalization.CultureInfo]::InvariantCulture

function Format-Tok {
    <# A token count with thousands separators, invariantly. 'n/a' for $null. #>
    param($Value)
    if ($null -eq $Value) { return 'n/a' }
    return ([string]::Format($script:MeasureSkillInvariant, '{0:N0}', $Value))
}

function Format-Pct {
    <# A percentage to at most one decimal, invariantly. #>
    param($Value)
    return ([string]::Format($script:MeasureSkillInvariant, '{0:0.#}', $Value))
}

function Format-Sec {
    <# A duration in seconds to two decimals, invariantly. #>
    param($Value)
    return ([string]::Format($script:MeasureSkillInvariant, '{0:0.00}', $Value))
}

function ConvertTo-TokenCount {
    <#
        THE TWO NOTATIONS THAT SHARE ONE TABLE, in one place.

            '~3.031'  -> 3031     the dot is a THOUSANDS separator
            '~1.3k'   -> 1300     a k suffix on a DECIMAL
            '~160'    -> 160
            '', '-'   -> $null

        A parser that read '~3.031' as 3.031 would under-report by a factor of a thousand and still
        look entirely plausible, which is why the caller cross-checks the row sum against the printed
        total rather than trusting this function on its own.

        A value below 10 with a decimal point cannot be a token count -- '1.3' is 13, not 1.3 -- so the
        thousands reading is the safe one wherever there is no k.
    #>
    param([string]$Raw)
    if ($null -eq $Raw) { return $null }
    $t = $Raw.Trim().TrimStart([char]0x7E).Trim()
    if ($t -eq '' -or $t -eq '-') { return $null }
    if ($t -match '^([0-9]+(?:[.,][0-9]+)?)[kK]$') {
        $decimal = $Matches[1].Replace(',', '.')
        $value = [double]::Parse($decimal, [System.Globalization.CultureInfo]::InvariantCulture)
        return [int][math]::Round($value * 1000)
    }
    $digits = $t -replace '[.,]', ''
    if ($digits -match '^[0-9]+$') { return [int]$digits }
    return $null
}

function Expand-ListArgument {
    <#
        Splits a comma-separated value, because of how every script in this repo is invoked.
        `powershell -NoProfile -File <script> -Skill a,b,c` does NOT parse PowerShell syntax for the
        arguments after the script path, so the whole of 'a,b,c' arrives as ONE element of the
        [string[]]. Measured on the first run that used the filter: three skills were named, nothing
        matched, and the report said "0 of 14" -- true, and reading as if the plugin had no such skills.
    #>
    param([string[]]$Value)
    if (-not $Value) { return @() }
    return @($Value |
        ForEach-Object { $_ -split ',' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' })
}

function Read-PluginDetailsOutput {
    <#
        Parses the output of `claude plugin details <id>` into the four things a measurement needs:
        the version, the printed Always-on total, the skills the component inventory names, and one row
        per component. Takes LINES rather than running the command, so it can be pinned by a suite
        against captured output.

        Returns a pscustomobject: Version, AlwaysOnTotal, InventorySkills, Rows (Component, AlwaysOn,
        OnInvoke). Anything it could not find is $null or an empty array -- judging that is
        Get-PluginDetailsParseProblems' job, not this function's.
    #>
    param([string[]]$Lines)

    $version         = $null
    $alwaysOnTotal   = $null
    $inventorySkills = @()
    $rows            = @()
    $inTable         = $false

    foreach ($line in @($Lines)) {
        if ($null -eq $line) { continue }

        # The header line ends in the version: '... (team-alpha) 4.17.0'. First match only, so a
        # version-looking string further down cannot overwrite it.
        if ($null -eq $version -and $line -match '\s(\d+\.\d+\.\d+)\s*$') { $version = $Matches[1] }

        if ($line -match '^\s*Skills\s*\(\d+\)\s+(.+)$') {
            $inventorySkills = @($Matches[1] -split ',' |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ -ne '' })
        }

        if ($line -match '^\s*Always-on:\s*(\S+)') { $alwaysOnTotal = ConvertTo-TokenCount $Matches[1] }

        # The per-component table starts at its own header and ends at the first line that is not a
        # row -- a blank line, or the 'On-invoke cost is paid...' note under it.
        if ($line -match '^\s*component\s+always-on\s+on-invoke\s*$') { $inTable = $true; continue }
        if ($inTable) {
            if ($line -match '^\s{2,}(\S+)\s{2,}([~0-9.,kK]+)\s+([~0-9.,kK]+)\s*$') {
                $rows += [pscustomobject]@{
                    Component = $Matches[1]
                    AlwaysOn  = ConvertTo-TokenCount $Matches[2]
                    OnInvoke  = ConvertTo-TokenCount $Matches[3]
                }
            } elseif ($rows.Count -gt 0) {
                $inTable = $false
            }
        }
    }

    return [pscustomobject]@{
        Version         = $version
        AlwaysOnTotal   = $alwaysOnTotal
        InventorySkills = $inventorySkills
        Rows            = $rows
    }
}

function Get-PluginDetailsParseProblems {
    <#
        THE TWO CROSS-CHECKS, and the reason no figure is reported without them. The table above is
        human-formatted output whose shape the CLI owns, so a drifted parse is a question of when
        rather than whether -- and a drifted parse that still produces numbers is the dangerous
        outcome, not a crash.

          1. The rows must SUM to the printed Always-on total, within tolerance. This is what catches a
             misread notation: reading '~3.031' as 3 would leave the sum a thousandfold short.
          2. Every skill the component inventory names must have produced a ROW. This is what catches a
             row-regex that stopped matching -- a table that silently yields fewer rows than it has.

        Returns the problems as strings; an empty array means the parse can be trusted. Reporting and
        refusing belong to the caller.

        THE TOLERANCE IS NOT SLACK. Every printed figure is rounded to two significant figures, so the
        sum CANNOT equal the total: measured on this repo, 19 rows summing to 3,010 against a printed
        3,031. 5% of the total with a floor of 100 covers that rounding across a plugin of any size and
        nothing larger -- a misread notation is off by orders of magnitude, not by 5%.
    #>
    param([Parameter(Mandatory = $true)]$Details)

    $problems = @()
    if (@($Details.Rows).Count -eq 0) { $problems += 'the per-component table produced no rows' }
    if ($null -eq $Details.AlwaysOnTotal) { $problems += 'no Always-on total was found' }

    if (@($Details.Rows).Count -gt 0 -and $null -ne $Details.AlwaysOnTotal) {
        $sum = ($Details.Rows | Measure-Object -Property AlwaysOn -Sum).Sum
        $tolerance = [math]::Max(100, [int][math]::Round($Details.AlwaysOnTotal * 0.05))
        $drift = [math]::Abs($sum - $Details.AlwaysOnTotal)
        if ($drift -gt $tolerance) {
            $problems += ("rows sum to $(Format-Tok $sum) against a printed total of " +
                "$(Format-Tok $Details.AlwaysOnTotal) -- off by $(Format-Tok $drift), over a tolerance " +
                "of $(Format-Tok $tolerance)")
        }
    }

    $named = @($Details.Rows | Select-Object -ExpandProperty Component)
    $missing = @($Details.InventorySkills | Where-Object { $named -notcontains $_ })
    if ($missing.Count -gt 0) {
        $problems += "the inventory names $($missing.Count) skill(s) that produced no row: $($missing -join ', ')"
    }

    return @($problems)
}
