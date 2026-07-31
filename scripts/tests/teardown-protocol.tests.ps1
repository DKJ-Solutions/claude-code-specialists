<#
.SYNOPSIS
    Tests for the operator protocol printed in specialists-teardown/SKILL.md: the version-control
    pre-flight and the round-trip inventory block.

.DESCRIPTION
    These are not tests of the teardown script -- they are tests of the COMMANDS the skill tells an
    operator to run. That distinction is the whole point: three of the four findings of test round v5
    (inbound #283, #285, #286) were documented checks that silently reported the wrong answer, and none
    of them was visible to any existing gate, because a document cannot fail a suite that never runs it.

    So the pre-flight case does not re-type the doc's filter -- it EXTRACTS the Where-Object from
    SKILL.md and executes it against real git fixtures. Rewrite the doc into something broken and these
    cases go red; delete the filter and the extraction itself fails.

    The CRLF artefact being tested (inbound #283): in a .gitignore with CRLF line endings and at least
    one blank line, git reads the blank line as a pattern of a single CR, which matches every path with
    a trailing slash. `git check-ignore -v` then reports a hit whose PATTERN FIELD IS EMPTY, and the
    pre-flight's verdict for a hit is "there is NO undo, stop here" -- handed, unfiltered, to a repo that
    ignores nothing. Both real consumers are Windows repos, where a CRLF .gitignore with a blank line is
    the normal state.

    Dependency-free (no Pester), exit 1 on failure, same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Skill    = Join-Path $RepoRoot 'claude-code-plugins\claude-specialists\specialists\skills\specialists-teardown\SKILL.md'
$Fixture  = Join-Path ([System.IO.Path]::GetTempPath()) 'specialists-preflight-fixture'

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Label)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label" -ForegroundColor Red }
}
function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ("$Expected" -eq "$Actual") { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}

# The text between a heading and the next one of the same level. Used to assert against the section that
# owns a claim rather than against the whole document, where an unrelated mention would satisfy a match.
function Get-Section {
    param([string]$Text, [string]$Heading)
    $i = $Text.IndexOf($Heading)
    if ($i -lt 0) { return '' }
    $rest = $Text.Substring($i + $Heading.Length)
    $j = $rest.IndexOf("`n## ")
    if ($j -ge 0) { $rest = $rest.Substring(0, $j) }
    return $rest
}

# A throwaway git repo whose .gitignore bytes are written EXACTLY as given -- no line-ending
# normalisation, because the line endings are the subject.
function New-IgnoreFixture {
    param([string]$Name, [string]$Content)
    $dir = Join-Path $Fixture $Name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $init = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $dir, 'init', '-q')
    if ($init.ExitCode -ne 0) { throw "git init failed in $dir : $($init.Output -join ' ')" }
    [System.IO.File]::WriteAllBytes((Join-Path $dir '.gitignore'), [System.Text.Encoding]::ASCII.GetBytes($Content))
    return $dir
}

function Invoke-CheckIgnore {
    param([string]$Dir, [string]$RelPath)
    $r = Invoke-NativeCapture -FilePath 'git' -Arguments @('-C', $Dir, 'check-ignore', '-v', $RelPath) -DiscardStderr
    return @($r.Output | Where-Object { $_ -ne $null -and "$_" -ne '' } | ForEach-Object { "$_" })
}

try {
    Write-Host "== teardown-protocol.tests: the commands SKILL.md tells an operator to run ==" -ForegroundColor Cyan
    Assert-True (Test-Path -LiteralPath $Skill -PathType Leaf) 'setup: specialists-teardown/SKILL.md is where it is expected'
    $skillText = [System.IO.File]::ReadAllText($Skill, [System.Text.Encoding]::UTF8)

    # --- 1. inbound #283: the pre-flight filters its own output --------------------------------------
    Write-Host 'inbound #283 -- the version-control pre-flight' -ForegroundColor Cyan
    $preflight = Get-Section -Text $skillText -Heading '### Pre-flight: is your lens tree actually under version control?'
    Assert-True ($preflight.Length -gt 0) 'pre-flight: the section still exists under its known heading'

    # The trailing slash is load-bearing and the tempting "simpler fix" is to drop it. Measured: in a
    # CRLF repo that genuinely ignores node_modules/, `check-ignore -v node_modules` (no slash, directory
    # absent from disk) exits 1 -- so dropping the slash trades this false positive for a false NEGATIVE.
    Assert-True ($preflight -match [regex]::Escape('git check-ignore -v .claude/specialists/lenses/')) `
        'pre-flight: still asks about the path WITH its trailing slash (dropping it trades a false positive for a false negative)'

    # Extract the doc's own filter and run THAT. Binding the test to the printed text is the point: a
    # copy here would keep passing while the document drifted back to the unfiltered command.
    #
    # Yes, this compiles a scriptblock out of a document. Weighed deliberately: the source is a
    # version-controlled file in this repo that every PR reviews, so anyone who could plant code here
    # could equally edit any .ps1 the suite already runs -- no privilege is added. What IS constrained is
    # the shape: only the pre-flight section, only a Where-Object body, and only one containing no braces
    # of its own. Do not widen this into "run the doc's code blocks"; the value is one known predicate
    # being the same object in the doc and in the test, not a document that executes.
    $filterMatch = [regex]::Match($preflight, 'Where-Object\s*\{(?<body>[^{}]+)\}')
    Assert-True $filterMatch.Success 'pre-flight: the command still filters its output with a Where-Object'
    $docFilter = $null
    if ($filterMatch.Success) {
        $docFilter = [scriptblock]::Create($filterMatch.Groups['body'].Value)
        Write-Host "         doc filter: {$($filterMatch.Groups['body'].Value.Trim())}" -ForegroundColor DarkGray
    }

    # Six fixtures. The verdict column is what the operator acts on, and it must be right in all six
    # regardless of which of them git decides to answer with an artefact.
    #   Content                                        | genuinely ignores .claude/specialists/lenses/?
    $cases = @(
        @{ Name = 'lf-blank';           Content = "node_modules/`n`ndist/`n";                      Ignored = $false; Why = 'LF endings with a blank line -- the control' }
        @{ Name = 'crlf-blank';         Content = "node_modules/`r`n`r`ndist/`r`n";                 Ignored = $false; Why = 'CRLF + blank line -- the false hit of #283' }
        @{ Name = 'crlf-no-blank';      Content = "node_modules/`r`ndist/`r`n";                     Ignored = $false; Why = 'CRLF without a blank line -- no artefact to filter' }
        @{ Name = 'genuine-glob';       Content = "node_modules/`r`n`r`n.claude/*`r`n";              Ignored = $true;  Why = 'a real .claude/* rule, artefact present too' }
        @{ Name = 'genuine-then-blank'; Content = ".claude/specialists/lenses/`r`n`r`n";            Ignored = $true;  Why = 'a real exact-path rule BEFORE the blank line -- must not be masked' }
        @{ Name = 'blank-then-genuine'; Content = "node_modules/`r`n`r`n.claude/specialists/`r`n";  Ignored = $true;  Why = 'a real rule AFTER the blank line -- must not be masked either' }
    )

    $artefactSeen = 0
    foreach ($c in $cases) {
        $dir  = New-IgnoreFixture -Name $c.Name -Content $c.Content
        # @() at the call site, not only inside the function: `return @($one)` unrolls to a scalar, and
        # indexing a scalar string yields its first CHARACTER -- a silent wrong answer, in a suite whose
        # whole subject is silent wrong answers.
        $raw  = @(Invoke-CheckIgnore -Dir $dir -RelPath '.claude/specialists/lenses/')
        $kept = if ($docFilter) { @($raw | Where-Object $docFilter) } else { $raw }
        $verdict = ($kept.Count -gt 0)
        Assert-Equal $c.Ignored $verdict ("pre-flight [$($c.Name)]: verdict is " + $(if ($c.Ignored) { 'ignored -> stop' } else { 'not ignored -> proceed' }) + " ($($c.Why))")
        # An empty pattern field is the artefact's signature: '<source>:<line>:' + TAB, nothing between
        # the second colon and the tab. Counted rather than asserted -- see the note printed at the end.
        if (@($raw | Where-Object { ($_ -split '\t')[0] -match ':$' }).Count -gt 0) { $artefactSeen++ }
    }

    # Proof the filter is load-bearing rather than decorative: without it, the CRLF fixture returns the
    # verdict that stops an adoption. Skipped (not failed) if a future git stops producing the artefact.
    $crlfDir = Join-Path $Fixture 'crlf-blank'
    $crlfRaw = @(Invoke-CheckIgnore -Dir $crlfDir -RelPath '.claude/specialists/lenses/')
    if ($crlfRaw.Count -gt 0) {
        Assert-True ($crlfRaw.Count -gt 0 -and @($crlfRaw | Where-Object $docFilter).Count -eq 0) `
            'pre-flight: the filter is doing real work -- unfiltered, the CRLF fixture reports the "stop here" hit'
        Assert-True ((($crlfRaw[0] -split '\t')[0]) -match ':$') `
            'pre-flight: and that hit is recognisable by its EMPTY pattern field, which is the whole criterion'
    }

    # --- 2. inbound #285: the round-trip inventory measures THIS repo --------------------------------
    #     Both defects failed to GREEN: a relative path in a .NET static call resolves against
    #     [Environment]::CurrentDirectory (which Set-Location does not update), and
    #     [regex]::Matches($null, ...) returns zero matches instead of throwing. A 0 reads as "the import
    #     was removed cleanly" and as "no line-ending pollution" -- the two defects the block exists for.
    Write-Host 'inbound #285 -- the round-trip inventory block' -ForegroundColor Cyan
    $roundTrip = Get-Section -Text $skillText -Heading 'Take a **filesystem** inventory at each stage instead, and compare the numbers:'
    Assert-True ($roundTrip.Length -gt 0) 'inventory: the block still introduces itself the same way'
    # Scoped to the fenced command block, not the section: the prose below it QUOTES the old broken call
    # while explaining why it was wrong, and an assert that cannot tell a command from its post-mortem
    # would forbid documenting the defect at all.
    $invBlock = ''
    $mFence = [regex]::Match($roundTrip, '(?s)```powershell\r?\n(?<code>.*?)```')
    if ($mFence.Success) { $invBlock = $mFence.Groups['code'].Value }
    Assert-True ($invBlock.Length -gt 0) 'inventory: the fenced command block is still there'
    Assert-True (-not ($invBlock -match [regex]::Escape("ReadAllLines('CLAUDE.md')"))) `
        'inventory: the commands hold no .NET static call with a RELATIVE path -- that one line measured whatever directory the process started in'
    Assert-True ($invBlock -match [regex]::Escape('Get-Content (Join-Path $root ''CLAUDE.md'') -Raw')) `
        'inventory: CLAUDE.md is read once, anchored to the repo root, with a cmdlet that follows Set-Location'
    # $text must be ASSIGNED before it is USED, in that order -- an unassigned $text is exactly how the
    # lone-LF counter printed the green answer without reading a byte.
    $iAssign = $invBlock.IndexOf('$text = ')
    $iUse    = $invBlock.IndexOf('[regex]::Matches($text')
    Assert-True ($iAssign -ge 0) 'inventory: $text is assigned inside the block'
    Assert-True ($iUse -ge 0) 'inventory: the lone-LF counter lives in the block, not in a bullet of its own'
    Assert-True ($iAssign -ge 0 -and $iUse -gt $iAssign) 'inventory: and it is assigned BEFORE the lone-LF counter uses it'

    # --- 3. inbound #286: the doc names the counting unit -------------------------------------------
    #     The note is a two-line block, so "count the note line" was ambiguous: a reader who counts from
    #     the teardown report finds 2 in a HEALTHY repo -- the first value of the defective series
    #     1 -> 2 -> 3 that this very check exists to detect.
    Write-Host 'inbound #286 -- the note counter names its unit' -ForegroundColor Cyan
    $noteBullet = ''
    $mb = [regex]::Match($skillText, "(?m)^- \*\*Count the bootstrap's note.*?(?=\r?\n- \*\*)", 'Singleline')
    if ($mb.Success) { $noteBullet = $mb.Value }
    Assert-True ($noteBullet.Length -gt 0) 'note counter: the bullet is still there'
    Assert-True ($noteBullet -match '\bhead\b') 'note counter: names the HEAD line as the unit to count'
    Assert-True ($noteBullet -match 'two-line block|two \*\*\[remove\]\*\*|\*\*two\*\*') `
        'note counter: warns that a healthy repo shows TWO lines in the teardown report'

    Write-Host ''
    if ($artefactSeen -eq 0) {
        Write-Host "   note: this git no longer produces the empty-pattern artefact in any fixture. The filter is then" -ForegroundColor DarkGray
        Write-Host "   harmless but no longer necessary -- worth re-reading SKILL.md's #283 paragraph before trusting it." -ForegroundColor DarkGray
    } else {
        $gitVer = (Invoke-NativeCapture -FilePath 'git' -Arguments @('--version')).Output -join ' '
        Write-Host "   note: the empty-pattern artefact is still produced by $($gitVer.Trim()) in $artefactSeen of $($cases.Count) fixture(s)." -ForegroundColor DarkGray
    }
}
finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
