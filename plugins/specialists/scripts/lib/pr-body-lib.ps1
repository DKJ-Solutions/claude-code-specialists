<#
.SYNOPSIS
    Helpers for assembling and updating a Pull Request body from a changelog entry.

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\pr-body-lib.ps1')

    Why this exists: open-pr.ps1 fills a fresh PR body by replacing the TEMPLATE PLACEHOLDER with the
    changelog entry's description. That works exactly once. On a resumed branch -- one whose PR is
    already open -- the placeholder is long gone, replaced by the previous description, so refreshing a
    rewritten entry needs a different operation: replace the section under a heading, leaving every
    other part of the body alone.

    Both functions here are PURE functions of their input -- no git, no gh, no filesystem -- so the
    suite (scripts/tests/pr-body.tests.ps1) can assert them without a remote. That split is not a
    nicety: open-pr.ps1 drives a live remote and carries a documented test gap, and the defect found in
    ship-pr.ps1 on August 4, 2026 was in an inline parse rather than in the orchestration the gap note
    excused. Anything in those scripts that is a pure function of text belongs here for that reason.

    Shared with the plugin mirror (registered in scripts/lib/shared-scripts-lib.ps1), because
    open-pr.ps1 is itself mirrored and dot-sources this file.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function Get-EntryDescription {
    <#
    .SYNOPSIS
        The body of a changelog entry: everything after its compact '### title - type - date' heading.

    .DESCRIPTION
        The description open-pr.ps1 puts under "What does this change do?", extracted here so the fresh
        path and the refresh path read it the SAME way. It lived inline in open-pr.ps1 until August 4,
        2026; adding a second reader would have meant a second copy of the same rule, which is how this
        repo's accumulation bugs start.

        Only the FIRST '### ' line counts as the heading. An entry routinely contains further '###' or
        deeper headings in its own prose, and treating a later one as the boundary would silently cut the
        description short -- returning something plausible rather than failing, which is the worst shape.

        Returns '' when there is no heading, or nothing after it. The caller decides what that means:
        open-pr.ps1 leaves the placeholder in place rather than writing an empty description.
    #>
    param([string]$EntryText)

    if (-not $EntryText) { return '' }

    $lines = $EntryText -split "\r?\n"
    $h3 = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^###\s') { $h3 = $i; break }
    }
    if ($h3 -lt 0 -or ($h3 + 1) -ge $lines.Count) { return '' }

    return (($lines[($h3 + 1)..($lines.Count - 1)]) -join "`n").Trim()
}

function Update-PrBodySection {
    <#
    .SYNOPSIS
        Replaces the content under one heading of a PR body, leaving the rest of the body untouched.

    .DESCRIPTION
        The section runs from the heading line to the next heading AT THE SAME LEVEL OR HIGHER, or to the
        end of the body. Same-level-or-higher rather than "the next heading of any kind" is the whole
        subtlety: a description may contain its own deeper headings, and stopping at the first of those
        would leave half the old description stranded below the new one -- a body that reads as though it
        says two things.

        Fenced code is skipped when looking for the boundary, because a description explaining this
        mechanism will contain a '##' inside a fence. Not hypothetical: this repo's own entry for this
        feature does.

        Returns the body UNCHANGED and reports it via -Changed when the heading is absent or the content
        already matches, so a caller can skip the API call entirely rather than publishing a no-op edit.

    .PARAMETER Body
        The current PR body.

    .PARAMETER Heading
        The literal heading line, e.g. '## What does this change do?'. Matched at the start of a line,
        whole-line, so a heading quoted mid-sentence elsewhere in the body cannot be mistaken for it.

    .PARAMETER Content
        The replacement content for that section, without the heading.

    .PARAMETER Changed
        [ref] set to $true when the returned body differs from the input.
    #>
    param(
        [string]$Body,
        [Parameter(Mandatory)][string]$Heading,
        [string]$Content,
        [ref]$Changed
    )

    if ($null -ne $Changed) { $Changed.Value = $false }
    if (-not $Body) { return $Body }

    # EMPTY CONTENT IS A NO-OP, NOT AN INSTRUCTION TO CLEAR THE SECTION. There is no reason to want a
    # blank description, while there are several ways to arrive here with nothing: an entry with no body,
    # a heading that did not parse, or a failed read upstream. On August 4, 2026 exactly that shape --
    # a string operation quietly yielding nothing -- published an EMPTY PR body by hand, so the rule is
    # that this function cannot be the thing that removes text without putting text back. Caught by its
    # own suite before it shipped.
    if (-not $Content -or -not $Content.Trim()) { return $Body }

    $nl = if ($Body.Contains("`r`n")) { "`r`n" } else { "`n" }
    $lines = $Body -split "\r?\n"

    # The heading's own level, so the boundary search knows what counts as "the next section".
    $level = ([regex]::Match($Heading, '^(#+)')).Groups[1].Value.Length
    if ($level -eq 0) { return $Body }

    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimEnd() -eq $Heading.TrimEnd()) { $start = $i; break }
    }
    if ($start -lt 0) { return $Body }

    # Where the section ends: the next heading at $level or shallower, ignoring anything inside a fence.
    $end = $lines.Count
    $inFence = $false
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*(```|~~~)') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        $m = [regex]::Match($lines[$i], '^(#+)\s')
        if ($m.Success -and $m.Groups[1].Value.Length -le $level) { $end = $i; break }
    }

    $before = if ($start -gt 0) { $lines[0..($start - 1)] } else { @() }
    $after  = if ($end -lt $lines.Count) { $lines[$end..($lines.Count - 1)] } else { @() }

    $middle = @($Heading.TrimEnd())
    if ($Content) { $middle += ($Content.Trim() -split "\r?\n") }
    # One blank line before the next section, and only when there IS a next section.
    if ($after.Count -gt 0) { $middle += '' }

    $rebuilt = (@($before) + $middle + @($after)) -join $nl
    if ($rebuilt -ne $Body -and $null -ne $Changed) { $Changed.Value = $true }
    return $rebuilt
}
