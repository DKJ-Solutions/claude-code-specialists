<#
.SYNOPSIS
    Generates the config blueprint: the source's own answers to the script contract, shipped to
    consumers so adopt-config.ps1 can offer them (issue #456).

.DESCRIPTION
    The shared workflow scripts are repo-agnostic and dot-source two REPO-OWNED libs from the
    consumer: scripts/lib/branch-info.ps1 and scripts/repo-config.ps1. check-script-contract.ps1
    reports which of those functions a consumer is missing and what the shared script FALLS BACK TO --
    never what this repo chose, and never why. That gap is what this blueprint closes.

    The blueprint is DERIVED, never hand-written. It reads:

      - the contract registry (scripts/lib/script-contract-lib.ps1) for the function list plus the
        Adopt marker and its reason;
      - this repo's own libs for the actual answer, taken as the function's SOURCE TEXT rather than
        its return value.

    TEXT, NOT VALUE, and that is the load-bearing choice. A value has to be serialized and
    reconstructed, which loses a hashtable's shape, a script-block's logic and every comment above it
    -- and the comments are the half a consumer actually needs, since the blueprint's worth is the
    reasoning rather than the answer. Text is also exact: what the consumer adopts is byte-for-byte
    what this repo runs.

    NO TIMESTAMP AND NO VERSION STAMP IN THE ARTEFACT, deliberately. The lint gate holds the committed
    file against a fresh generation, so anything that changes on every run would report drift on every
    run -- a check that is always red is a check that gets skipped.

.PARAMETER Check
    Generate in memory and compare against the committed artefact instead of writing it. Exits 1 on
    drift. This is what the lint gate and CI run.

.PARAMETER OutputPath
    Where to write the artefact, repo-root-relative. Left empty it is DERIVED: the blueprint belongs to
    the workflow plugin, and where that plugin's folder sits is a question the marketplace already
    answers. A test points this at a throwaway file.

    It was a literal until August 9, 2026, and that literal is the reason this parameter is documented
    at all: it had to be edited when the plugins were renamed, and again when the tree was grouped into
    teams/ and workflows/. Two edits for a fact the repo states in one place.
#>

[CmdletBinding()]
param(
    [switch]$Check,
    [string]$OutputPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

. (Join-Path $PSScriptRoot '..\lib\script-contract-lib.ps1')
. (Join-Path $PSScriptRoot '..\repo-config.ps1')
# Which plugins this repo publishes, for resolving where the blueprint belongs (see $OutputPath below).
# This generator is the SOURCE's own tool and is deliberately not mirrored, so the sibling is always here.
. (Join-Path $PSScriptRoot '..\lib\plugin-tree-lib.ps1')

function Get-ScriptVarReferences {
    <#
        The '$script:' variables a piece of PowerShell actually READS, via the parser -- comments and
        docstrings excluded, because they are not AST nodes. Returns bare names ('LiveStage'), sorted
        and unique. Falls back to an empty list if the fragment does not parse on its own, which is the
        safe direction: nothing extra is pulled in.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text)

    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) { return @() }

    $vars = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)
    return @($vars |
        Where-Object { $_.VariablePath.UserPath -like 'script:*' } |
        ForEach-Object { $_.VariablePath.UserPath.Substring('script:'.Length) } |
        Sort-Object -Unique)
}

function Get-ScriptVarAssignment {
    <#
        The full text of a '$script:<Name> = ...' assignment, following it across lines until its
        brackets balance -- so an array or hashtable literal comes along whole rather than as its
        first line. Empty string when the file does not assign that variable.
    #>
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$Name
    )

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -notmatch ('^\s*\$script:' + [regex]::Escape($Name) + '\s*=')) { continue }

        $depth = 0
        for ($j = $i; $j -lt $Lines.Count; $j++) {
            $line = $Lines[$j]
            $depth += ([regex]::Matches($line, '[\(\[\{]')).Count
            $depth -= ([regex]::Matches($line, '[\)\]\}]')).Count
            if ($depth -le 0) { return (($Lines[$i..$j]) -join "`n") }
        }
        return (($Lines[$i..($Lines.Count - 1)]) -join "`n")
    }
    return ''
}

function Get-FunctionBlock {
    <#
        The source text of one function, together with the comment block and any $script: assignment
        that sits directly above it -- which is where this repo keeps the reasoning and the value.

        WALKS BACK OVER ONE CONTIGUOUS BLOCK, stopping at the first blank line above it, and that
        boundary is a bug fix rather than a simplification. A structural walk that stopped only at the
        previous '}' swept up whatever else sat between two functions -- measured on the first run:
        Get-LiveStage came out carrying the RETIREMENT NOTE of Get-ChangelogTierHeadings, a comment
        block about a different, deleted function, and Get-ReleaseNotesGrouping carried the whole
        six-knob preamble of issue #417. Both would have been shipped to consumers as that function's
        reasoning. In this file a function's own block is always contiguous -- comment lines, then the
        '$script:X = ...' value, then the function -- and anything before it is separated by a blank.

        A comment-only scan would not do either: the value lives in the assignment line BETWEEN the
        comment and the function, so stopping at the first non-comment line ships the reasoning without
        the answer.
    #>
    param(
        # AllowEmptyString, because the array IS the file and a file has blank lines: PowerShell's
        # mandatory validation rejects an empty element inside a [string[]] without it.
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Lines,
        [Parameter(Mandatory = $true)][int]$StartLine,   # 1-based, from the parser
        [Parameter(Mandatory = $true)][int]$EndLine      # 1-based, inclusive
    )

    $first = $StartLine - 1   # to 0-based
    $i = $first - 1

    # Step over blank lines directly above the function, then take the contiguous run above it.
    while ($i -ge 0 -and $Lines[$i].Trim() -eq '') { $i-- }
    while ($i -ge 0) {
        $line = $Lines[$i]
        if ($line.Trim() -eq '') { break }                  # the block boundary
        if ($line -eq '}') { break }                        # end of the previous function
        if ($line -match '^\s*function\s') { break }         # start of another one
        $i--
    }
    $blockStart = $i + 1
    while ($blockStart -lt $first -and $Lines[$blockStart].Trim() -eq '') { $blockStart++ }

    $block = ($Lines[$blockStart..($EndLine - 1)]) -join "`n"

    # COMPLETE THE BLOCK WITH THE VALUES IT READS BUT DOES NOT CARRY. Four of this file's functions
    # share one assignment block (the entry-scaffold wording), so the contiguous run above the FIRST of
    # them holds all four values and the other three hold none. Copied on its own, such a function
    # returns $null in the consumer -- a silent wrong answer where an absent function would have got the
    # documented fallback. So any $script: variable the block reads without assigning is pulled in.
    # READ THROUGH THE PARSER, NOT BY REGEX, for the same reason check 19 was rewritten that way: a
    # text scan cannot tell code from prose. Measured here -- Get-EntryTitlePlaceholder's comment block
    # points the reader at '$script:EntryScaffoldDefaults in entry-scaffold-lib.ps1', a variable that
    # lives in a different file entirely, and a regex reported it as a value this function reads.
    $needed = @(Get-ScriptVarReferences -Text $block)
    $prefix = @()
    foreach ($name in $needed) {
        # (?m) so '^' means start-of-LINE: $block is a multi-line string, and without it this would
        # only ever match an assignment on the block's very first line.
        if ($block -match ('(?m)^\s*\$script:' + [regex]::Escape($name) + '\s*=')) { continue }
        $assignment = Get-ScriptVarAssignment -Lines $Lines -Name $name
        if ($assignment) { $prefix += $assignment }
    }
    if ($prefix.Count -gt 0) {
        $block = (($prefix -join "`n") + "`n" + $block)
    }

    return $block
}

function Get-LibFunctions {
    <# Every function definition in a file, by name, with its extent -- read through the PowerShell
       parser rather than by regex. A regex over 'function X' matches the word in a docstring too,
       which is how check 19 was first measured wrong. #>
    param([Parameter(Mandatory = $true)][string]$Path)

    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) {
        throw "cannot parse '$Path': $($errors[0].Message)"
    }

    $map = @{}
    foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        $map[$fn.Name] = @{
            StartLine = $fn.Extent.StartLineNumber
            EndLine   = $fn.Extent.EndLineNumber
        }
    }
    return $map
}

# --- Build ----------------------------------------------------------------------------------------

$contract = Get-ScriptContract
$libCache = @{}
$records  = @()

foreach ($rec in $contract) {
    $libRel  = $rec.Lib
    $libPath = Join-Path $repoRoot $libRel

    if (-not $libCache.ContainsKey($libRel)) {
        if (-not (Test-Path -LiteralPath $libPath -PathType Leaf)) {
            throw "the blueprint cannot be built: this repo is missing '$libRel', which the contract declares. The source must answer its own contract before it can offer the answers to anyone else."
        }
        $libCache[$libRel] = @{
            Lines     = @(Get-Content -LiteralPath $libPath)
            Functions = Get-LibFunctions -Path $libPath
        }
    }

    $lib      = $libCache[$libRel]
    $declared = $lib.Functions.ContainsKey($rec.Function)

    # A record the SOURCE itself leaves at the fallback. Recorded as declared=false with no text rather
    # than skipped: "this repo does not state it either" is an answer a consumer can act on, and a
    # silently shorter blueprint is not.
    $text = ''
    if ($declared) {
        $ext = $lib.Functions[$rec.Function]
        $text = Get-FunctionBlock -Lines $lib.Lines -StartLine $ext.StartLine -EndLine $ext.EndLine
    }

    $records += [ordered]@{
        lib       = $libRel
        function  = $rec.Function
        adopt     = $rec.Adopt
        adoptWhy  = $rec.AdoptWhy
        optional  = [bool]($rec.ContainsKey('Optional') -and $rec.Optional)
        default   = $(if ($rec.ContainsKey('Default')) { $rec.Default } else { '' })
        returns   = $(if ($rec.ContainsKey('Returns')) { $rec.Returns } else { '' })
        declared  = $declared
        text      = $text
    }
}

$blueprint = [ordered]@{
    schema     = 1
    sourceRepo = Get-RepoName
    note       = 'Generated by scripts/sync/build-config-blueprint.ps1 from the source repo own libs. Do not edit by hand: the lint gate regenerates this file and reports any difference.'
    records    = $records
}

$json = ($blueprint | ConvertTo-Json -Depth 6)
# LF, and a trailing newline -- the same normalization the shared-scripts mirror uses, so a checkout
# with autocrlf does not read as drift.
$json = ($json -replace "`r`n", "`n")
if (-not $json.EndsWith("`n")) { $json += "`n" }

# THE DESTINATION, ASKED OF THE MARKETPLACE when the caller did not name one. The blueprint lives in
# whichever plugin already ships one; that is a fact about the tree, and the tree is described in
# .claude-plugin/marketplace.json rather than in this parameter's default. Refuses rather than guessing
# if no plugin carries a blueprint/ directory -- writing one into a folder chosen by fallback would
# produce an artefact no consumer ever receives, silently.
if (-not $OutputPath) {
    $bpPlugin = @(Get-RepoPluginRoots -RepoRoot $repoRoot |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.Root 'blueprint') -PathType Container })
    if ($bpPlugin.Count -ne 1) {
        Write-Error "cannot decide where the config blueprint belongs: $($bpPlugin.Count) published plugin(s) carry a blueprint/ directory, expected exactly 1. Pass -OutputPath explicitly."
        exit 1
    }
    $OutputPath = Join-Path $bpPlugin[0].RelativeRoot 'blueprint\config-blueprint.json'
}
$outPath = Join-Path $repoRoot $OutputPath

if ($Check) {
    if (-not (Test-Path -LiteralPath $outPath -PathType Leaf)) {
        Write-Error "config blueprint missing: '$OutputPath' has never been generated. Run scripts/sync/build-config-blueprint.ps1 and commit the result."
        exit 1
    }
    $current = [System.IO.File]::ReadAllText($outPath) -replace "`r`n", "`n"
    if ($current -ne $json) {
        Write-Error "config blueprint is stale: '$OutputPath' does not match what the source's own libs and contract registry produce right now. Run scripts/sync/build-config-blueprint.ps1 and commit the result. This is the artefact consumers adopt from, so a stale one hands them last week's answers with this week's reasoning."
        exit 1
    }
    Write-Host "config blueprint: up to date ($($records.Count) records)." -ForegroundColor Green
    exit 0
}

$outDir = Split-Path -Parent $outPath
if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
[System.IO.File]::WriteAllText($outPath, $json)

$copyCount   = @($records | Where-Object { $_.adopt -eq 'copy' }).Count
$decideCount = @($records | Where-Object { $_.adopt -eq 'decide' }).Count
$undeclared  = @($records | Where-Object { -not $_.declared }).Count

Write-Host "config blueprint written: $OutputPath" -ForegroundColor Green
Write-Host "  $($records.Count) records -- $copyCount copy, $decideCount decide, $undeclared left at the built-in fallback by this repo too."
