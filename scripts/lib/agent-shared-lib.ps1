<#
.SYNOPSIS
    Shared helper for the verbatim-shared blocks in the agent defs (build + lint).
.DESCRIPTION
    Some bullets under **Boundaries** are word-for-word identical across many agent defs (e.g. the
    inbound rule: 19/19). To maintain them in ONE place instead of in every agent def, they live as
    the canonical source in plugins/teams/agent-shared/<name>.md and appear
    in an agent def between sentinel comments:

        <!-- BEGIN shared:inbound-behaviour -- GENERATED, do not edit here -->
        - **You do not modify the shared core locally.** ...(canonical content)...
        <!-- END shared:inbound-behaviour -->

    The content really lives in the agent def (always-loaded, self-contained), but is filled in
    from the source by build-agent-defs.ps1 and checked against the source by
    check-plugin-integrity.ps1. A hand-edit inside the sentinels is thus caught as drift.

    THE BEGIN LINE IS OWNED BY THIS FILE TOO, and until August 14, 2026 it was not: Expand-AgentDefShared
    replaced the content between the sentinels and copied the BEGIN line through unchanged, so its wording
    sat hand-maintained in 178 places with nothing holding it. It read
    'GENERATED, edit agent-shared/<name>.md' -- a relative path that resolves in THIS repo and nowhere
    else, because plugins/teams/agent-shared/ sits outside every plugin root and therefore does not travel in
    the package. Inbound #669 C2 reported that as a dead pointer, which understates it: three lines below it,
    in the same agent def, the inbound-behaviour block says *"You do not modify the shared core locally"*
    and names the issue route. The pointer instructed a consumer to do what the paragraph it introduces
    forbids.

    IT IS REMOVED RATHER THAN REPOINTED, and #669's own two proposals were both weighed and declined.
    Shipping agent-shared/ in the package hands a consumer a file they may open but which is not the
    source -- exactly the confusion the inbound route exists to remove. Repointing it at this repo would
    add 178 references to a repo the reader cannot write to, straight against C4 on the same report.
    (That reason read "a personal repo" until 2026-09-02, when the repo was transferred from DaveKJohn
    into the DKJ-Solutions org. The account type was never what made the pointer wrong, and the other
    two reasons each carry the decision on their own.)
    And for the one reader who CAN act on it -- a maintainer of this repo -- the pointer
    is redundant: 'shared:<name>' maps to plugins/teams/agent-shared/<name>.md by construction, which is what
    Get-SharedBlockText does one function up. Measured: dropping it takes those 178 lines from 17,332 to
    13,027 bytes.

    Owning the line is what makes the wording single-source: the builder rewrites a drifted sentinel and
    the lint reports it, because both compare the whole file against this function's output. No new check.

    Pure ASCII (repo convention for .ps1). This lib changes nothing; it only supplies the expansion.
#>

Set-StrictMode -Version Latest

function Get-AgentSharedDir {
    param([string]$RepoRoot)
    return (Join-Path $RepoRoot 'plugins\teams\agent-shared')
}

function Format-SharedBeginSentinel {
    <#
        The one canonical BEGIN sentinel, so its wording has a single source instead of 178 hand-typed
        copies. $Indent is carried through rather than normalized away: no sentinel in this tree is
        indented today, but a shared block nested in a list would be, and silently unindenting it would
        change the markdown around content this function is not allowed to touch.
    #>
    param([string]$Name, [string]$Indent = '')
    return "$Indent<!-- BEGIN shared:$Name -- GENERATED, do not edit here -->"
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
        $m = [regex]::Match($line, '^(?<indent>\s*)<!-- BEGIN shared:(?<name>[A-Za-z0-9-]+)\b')
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
        # THE BEGIN SENTINEL IS REWRITTEN, not copied through. That is what gives its wording one source:
        # both the builder and the lint compare the whole file against this output, so a drifted sentinel
        # is rebuilt by the one and reported by the other, with no check of its own. Only on the success
        # path -- the two failure branches above deliberately leave their region exactly as they found it.
        $out.Add((Format-SharedBeginSentinel -Name $name -Indent $m.Groups['indent'].Value))
        foreach ($bl in ($block -split "`n")) { $out.Add($bl) }
        $out.Add($lines[$j])                                  # END sentinel unchanged
        $i = $j + 1
    }
    return ($out -join "`n")
}
