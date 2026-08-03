<#
.SYNOPSIS
    Shared helper for the verbatim-shared blocks in the agent defs (build + lint).
.DESCRIPTION
    Some bullets under **Boundaries** are word-for-word identical across many agent defs (e.g. the
    inbound rule: 19/19). To maintain them in ONE place instead of in every agent def, they live as
    the canonical source in plugins/agent-shared/<name>.md and appear
    in an agent def between sentinel comments:

        <!-- BEGIN shared:inbound-behaviour -- GENERATED, edit agent-shared/inbound-behaviour.md -->
        - **You do not modify the shared core locally.** ...(canonical content)...
        <!-- END shared:inbound-behaviour -->

    The content really lives in the agent def (always-loaded, self-contained), but is filled in
    from the source by build-agent-defs.ps1 and checked against the source by
    check-plugin-integrity.ps1. A hand-edit inside the sentinels is thus caught as drift.

    Pure ASCII (repo convention for .ps1). This lib changes nothing; it only supplies the expansion.
#>

Set-StrictMode -Version Latest

function Get-AgentSharedDir {
    param([string]$RepoRoot)
    return (Join-Path $RepoRoot 'plugins\agent-shared')
}

function Get-SharedBlockText {
    # Canonical content of a shared block (LF, without trailing newline), or $null if the source is missing.
    param([string]$SharedDir, [string]$Name)
    $p = Join-Path $SharedDir "$Name.md"
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return $null }
    $t = ([System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)) -replace "`r`n", "`n"
    return $t.TrimEnd("`n")
}

function Expand-AgentDefShared {
    # Fills in every <!-- BEGIN shared:NAME --> ... <!-- END shared:NAME --> region with the canonical
    # source and returns the expected (expanded) content as a string (LF). A BEGIN without an END or
    # an unknown block (missing source) is reported as a problem and the region is left unchanged.
    param(
        [string]$Content,
        [string]$SharedDir,
        [System.Collections.Generic.List[string]]$Problems
    )
    $lines = ($Content -replace "`r`n", "`n") -split "`n"
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        $m = [regex]::Match($line, '^\s*<!-- BEGIN shared:(?<name>[A-Za-z0-9-]+)\b')
        if (-not $m.Success) { $out.Add($line); $i++; continue }
        $name = $m.Groups['name'].Value
        $endPat = '^\s*<!-- END shared:' + [regex]::Escape($name) + '\s*-->'
        $j = $i + 1
        while ($j -lt $lines.Count -and $lines[$j] -notmatch $endPat) { $j++ }
        if ($j -ge $lines.Count) {
            if ($null -ne $Problems) { [void]$Problems.Add("BEGIN shared:$name without a matching END sentinel") }
            for ($k = $i; $k -lt $lines.Count; $k++) { $out.Add($lines[$k]) }
            return ($out -join "`n")
        }
        $block = Get-SharedBlockText -SharedDir $SharedDir -Name $name
        if ($null -eq $block) {
            if ($null -ne $Problems) { [void]$Problems.Add("unknown shared block '$name' (source agent-shared/$name.md missing)") }
            for ($k = $i; $k -le $j; $k++) { $out.Add($lines[$k]) }
            $i = $j + 1
            continue
        }
        $out.Add($lines[$i])                                  # BEGIN sentinel unchanged
        foreach ($bl in ($block -split "`n")) { $out.Add($bl) }
        $out.Add($lines[$j])                                  # END sentinel unchanged
        $i = $j + 1
    }
    return ($out -join "`n")
}
