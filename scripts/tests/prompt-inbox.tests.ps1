<#
.SYNOPSIS
    Regression tests for the prompt inbox (Dave, August 15, 2026): prompt-inbox-lib.ps1's readers and
    formatters, and the prompt-inbox.ps1 place -> read -> archive -> reset cycle end to end.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell. Exit code 0 if everything passes, 1 on a failure.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/prompt-inbox.tests.ps1

    THE INVARIANT THIS SUITE EXISTS FOR is scenario A's last assert: the reset state the formatter
    writes must read back as EMPTY through the same lib's reader. Formatter and reader are two halves of
    one claim -- "an inbox holding only scaffold is not waiting" -- and nothing else in the tree would
    notice them drifting apart. The visible failure would be a session announcing a prompt at every
    session start and then finding nothing to hand over.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot '..\lib\prompt-inbox-lib.ps1')

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

# A SHORT scratch root, on purpose. Windows PowerShell 5.1 raises a DirectoryNotFoundException past 260
# characters -- naming a directory that exists -- and the archive path adds ~90 characters of its own,
# so a suite rooted under a long per-session temp folder would fail on the path rather than on the code.
# Measured August 15, 2026: exactly that, under a 147-character root.
$scratch = Join-Path $env:TEMP ('pi-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$null = New-Item -ItemType Directory -Path $scratch -Force

try {
    # --- A. The formatters and the readers agree ---------------------------------------------------
    Write-Host "`n== A. reset state, body and the empty test ==" -ForegroundColor Cyan

    $reset = (Format-PromptReset) -join "`n"
    Assert-True ($reset -match '<!--') 'A1: the reset state is an HTML comment block'
    Assert-Equal '' (Get-PromptBody -Text $reset) 'A2: the reset state reads back as an empty body'

    Assert-Equal 'do the thing' (Get-PromptBody -Text "<!-- scaffold -->`n`ndo the thing`n") `
        'A3: a comment is stripped and the prose survives'
    Assert-Equal 'after' (Get-PromptBody -Text "<!-- a -->`n<!-- b -->`nafter") `
        'A4: several comments are stripped'
    Assert-Equal '' (Get-PromptBody -Text '') 'A5: an empty file has an empty body'
    Assert-Equal '' (Get-PromptBody -Text "   `n `n") 'A6: whitespace only has an empty body'

    # A half-typed comment must not hand the scaffold's own words over as an assignment.
    Assert-Equal 'keep' (Get-PromptBody -Text "keep`n<!-- opened and never closed`nwrite here") `
        'A7: an unclosed comment runs to the end of the file'

    # --- B. First line, slug and archive name ------------------------------------------------------
    Write-Host "`n== B. announcing and naming ==" -ForegroundColor Cyan

    Assert-Equal 'first' (Get-PromptFirstLine -Body "`n`n  first  `nsecond") 'B1: the first NON-EMPTY line, trimmed'
    Assert-Equal '' (Get-PromptFirstLine -Body '') 'B2: no body, no first line'
    $long = 'x' * 200
    Assert-True ((Get-PromptFirstLine -Body $long).Length -le 100) 'B3: a long first line is shortened'
    Assert-True ((Get-PromptFirstLine -Body $long).EndsWith('...')) 'B4: and says it was shortened'

    Assert-Equal 'doe-dit-eens' (ConvertTo-PromptSlug -Text 'Doe dit eens!') 'B5: the slug is lower-case kebab'
    Assert-Equal 'prompt' (ConvertTo-PromptSlug -Text '!!! ???') 'B6: a slug with nothing in it falls back to prompt'
    Assert-True ((ConvertTo-PromptSlug -Text (('woord ' * 40))).Length -le 40) 'B7: the slug is capped'
    Assert-True ((ConvertTo-PromptSlug -Text 'ruim de release op') -notmatch '[^a-z0-9-]') 'B8: the slug is filename-safe'

    $stamp = [datetime]'2026-08-15 14:57'
    Assert-Equal '2026-08-15-1457-ruim-de-release-op' `
        ((Get-PromptArchiveName -Body 'Ruim de release op' -Now $stamp) -replace '\.md$', '') `
        'B9: the archive name leads with the date, so the folder sorts chronologically'

    # --- C. Age ------------------------------------------------------------------------------------
    Write-Host "`n== C. how old is it ==" -ForegroundColor Cyan
    $now = [datetime]'2026-08-15 12:00'
    Assert-Equal 'less than a minute ago' (Format-PromptAge -Written $now.AddSeconds(-20) -Now $now) 'C1: seconds'
    Assert-Equal '1 minute ago'  (Format-PromptAge -Written $now.AddMinutes(-1) -Now $now) 'C2: one minute is singular'
    Assert-Equal '5 minutes ago' (Format-PromptAge -Written $now.AddMinutes(-5) -Now $now) 'C3: minutes'
    Assert-Equal '2 hours ago'   (Format-PromptAge -Written $now.AddHours(-2) -Now $now)   'C4: hours'
    Assert-Equal '3 days ago'    (Format-PromptAge -Written $now.AddDays(-3) -Now $now)    'C5: days -- the stale case'
    Assert-Equal 'just now'      (Format-PromptAge -Written $now.AddMinutes(5) -Now $now)  'C6: a clock skew reads forward, not negative'

    # --- D. Paths ----------------------------------------------------------------------------------
    Write-Host "`n== D. where the inbox lives ==" -ForegroundColor Cyan
    $paths = Get-PromptInboxPaths -RepoRoot 'C:\repo'
    Assert-Equal 'workflow-davekjohn/prompts/prompt.md' $paths.PromptRel 'D1: inside the workflow folder'
    Assert-True ($paths.Prompt -like '*prompts\prompt.md') 'D2: the absolute path joins the repo root'
    Assert-True ($paths.ArchiveRel.EndsWith('prompts/archive')) 'D3: the archive sits beside it'
    # The tracked pair. Without the .gitignore a consumer's first prompt shows up in their next diff.
    Assert-True ($paths.IgnoreRel.EndsWith('prompts/.gitignore')) 'D4: the folder carries its own gitignore'

    $ignore = (Format-PromptInboxIgnore) -join "`n"
    Assert-True ($ignore -match '(?m)^prompt\.md$') 'D5: the gitignore covers the inbox'
    Assert-True ($ignore -match '(?m)^archive/$')   'D6: and the archive'

    # --- E. The script, end to end -----------------------------------------------------------------
    Write-Host "`n== E. place -> read -> archive -> reset ==" -ForegroundColor Cyan
    $script:inbox = Join-Path $PSScriptRoot '..\task\prompt-inbox.ps1'

    function Invoke-Inbox {
        param([string[]]$ExtraArgs = @())
        $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $script:inbox -RootOverride $scratch @ExtraArgs 2>&1)
        return @{ Out = ($out -join "`n"); Code = $LASTEXITCODE }
    }

    $r = Invoke-Inbox
    $sp = Get-PromptInboxPaths -RepoRoot $scratch
    Assert-True (Test-Path -LiteralPath $sp.Prompt)   'E1: the first run places the inbox'
    Assert-True (Test-Path -LiteralPath $sp.Ignore)   'E2: and its gitignore'
    Assert-True (Test-Path -LiteralPath $sp.Template) 'E3: and the tracked template reference'
    Assert-True ($r.Out -match 'Nothing is waiting')  'E4: a fresh inbox reports nothing waiting'

    # An existing inbox is NEVER overwritten -- the rule the whole mechanism rests on.
    Add-Content -LiteralPath $sp.Prompt -Value "`nRuim de release op`n`nEn kijk naar de lint." -Encoding UTF8
    $r = Invoke-Inbox
    Assert-True ($r.Out -match '\[WAITING\]')          'E5: a written assignment is reported as waiting'
    Assert-True ($r.Out -match 'Ruim de release op')   'E6: and handed over verbatim'
    Assert-True ($r.Out -match 'En kijk naar de lint') 'E7: including the lines past the first'

    $r = Invoke-Inbox
    Assert-True ($r.Out -match 'Ruim de release op') 'E8: reading twice does not consume it -- only -Archive does'

    $r = Invoke-Inbox -ExtraArgs @('-Archive')
    $archived = @(Get-ChildItem -LiteralPath $sp.Archive -Filter '*.md' -File)
    Assert-Equal 1 $archived.Count 'E9: -Archive files exactly one document'
    Assert-True ($archived[0].Name -match '^\d{4}-\d{2}-\d{2}-\d{4}-ruim-de-release-op\.md$') `
        'E10: named by date and the first line'
    $body = [System.IO.File]::ReadAllText($archived[0].FullName, [System.Text.Encoding]::UTF8)
    Assert-True ($body -match 'En kijk naar de lint') 'E11: the archive holds what was written'
    Assert-True ($body -notmatch 'Write your assignment') 'E12: and not the scaffold comments'

    $state = Get-PromptState -RepoRoot $scratch
    Assert-True ($state.Exists)   'E13: the inbox still exists after archiving'
    Assert-True (-not $state.Waiting) 'E14: and is back to empty'

    $r = Invoke-Inbox -ExtraArgs @('-Archive')
    Assert-Equal 1 $r.Code 'E15: archiving an empty inbox is refused, not a no-op'
    Assert-True ($r.Out -match 'REFUSED') 'E16: and says so in one readable line'
    Assert-Equal 1 (@(Get-ChildItem -LiteralPath $sp.Archive -Filter '*.md' -File)).Count `
        'E17: the refusal wrote nothing'

    # A drifted generated reference is rewritten; the inbox beside it is not.
    Set-Content -LiteralPath $sp.Template -Value 'stale' -Encoding UTF8
    Add-Content -LiteralPath $sp.Prompt -Value "`nnog een opdracht" -Encoding UTF8
    $null = Invoke-Inbox
    Assert-True ((Get-Content -LiteralPath $sp.Template -Raw) -notmatch 'stale') 'E18: a drifted template is refreshed'
    Assert-True ((Get-PromptState -RepoRoot $scratch).Waiting) 'E19: and the inbox beside it is left alone'

} finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host "prompt-inbox tests: $script:pass passed, $script:fail failed." -ForegroundColor $(if ($script:fail) { 'Red' } else { 'Green' })
if ($script:fail) { exit 1 }
exit 0
