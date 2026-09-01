<#
.SYNOPSIS
    Regression tests for the bwj-codex plugin: its structure, its marketplace registration, and
    the pure helpers of the asana-mirror CI script it ships as a template.

.DESCRIPTION
    Dependency-free: no Pester, only PowerShell. Exit 0 if everything passes, 1 on a failure.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/bwj-codex.tests.ps1

    The asana-mirror helpers are exercised by dot-sourcing the template: it runs its main flow only
    when invoked directly, so a dot-source loads the functions and does nothing else.

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'
$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$PluginRoot = Join-Path $RepoRoot 'plugins\workflows\bwj-codex'

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

function Assert-Throws {
    param([scriptblock]$Block, [string]$Name)
    try { & $Block; $script:fail++; Write-Host "  [FAIL] $Name (no exception)" -ForegroundColor Red }
    catch { $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green }
}

# --- 1. Plugin structure -------------------------------------------------------------------------
Write-Host "`n-- structure --" -ForegroundColor Cyan

$manifestPath = Join-Path $PluginRoot '.claude-plugin\plugin.json'
Assert-True (Test-Path -LiteralPath $manifestPath) 'plugin.json is present'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
Assert-Equal 'bwj-codex' $manifest.name 'plugin.json name is bwj-codex'

foreach ($rel in @('README.md', 'WORKFLOW-portable.md',
                   'skills\report-issue\SKILL.md', 'skills\adopt-bwj-asana\SKILL.md',
                   'templates\asana-mirror.yml', 'templates\asana-mirror.ps1')) {
    Assert-True (Test-Path -LiteralPath (Join-Path $PluginRoot $rel)) "ships $rel"
}

Assert-True (-not (Test-Path -LiteralPath (Join-Path $PluginRoot 'agents'))) 'carries no agents/ (workflow rule)'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $PluginRoot 'manuals'))) 'carries no manuals/ (workflow rule)'

# skill folder name matches its frontmatter name:
foreach ($skill in @('report-issue', 'adopt-bwj-asana')) {
    $txt = Get-Content -LiteralPath (Join-Path $PluginRoot "skills\$skill\SKILL.md") -Raw
    $nm  = [regex]::Match($txt, '(?m)^name:\s*(\S+)\s*$')
    Assert-Equal $skill $nm.Groups[1].Value "skill '$skill' frontmatter name matches its folder"
}

# --- 2. Marketplace registration + lockstep version --------------------------------------------
Write-Host "`n-- marketplace --" -ForegroundColor Cyan

$marketplace = Get-Content -LiteralPath (Join-Path $RepoRoot '.claude-plugin\marketplace.json') -Raw | ConvertFrom-Json
$entry = $marketplace.plugins | Where-Object { $_.name -eq 'bwj-codex' }
Assert-True ($null -ne $entry) 'bwj-codex is listed in marketplace.json'
Assert-Equal './plugins/workflows/bwj-codex' $entry.source 'marketplace source points at the plugin folder'

$alphaManifest = Get-Content -LiteralPath (Join-Path $RepoRoot 'plugins\teams\team-alpha\.claude-plugin\plugin.json') -Raw | ConvertFrom-Json
Assert-Equal $alphaManifest.version $manifest.version 'version is in lockstep with team-alpha'

# --- 3. asana-mirror pure helpers ------------------------------------------------------------------
Write-Host "`n-- asana-mirror helpers --" -ForegroundColor Cyan

. (Join-Path $PluginRoot 'templates\asana-mirror.ps1')

# GID extraction
Assert-Equal '1201234567890123' (Get-AsanaTaskGid -IssueBody "text`n<!-- asana-task: 1201234567890123 -->`nmore") 'Get-AsanaTaskGid reads the marker'
Assert-Equal '1201234567890123' (Get-AsanaTaskGid -IssueBody '<!--asana-task:1201234567890123-->') 'Get-AsanaTaskGid tolerates no inner spaces'
Assert-True  ($null -eq (Get-AsanaTaskGid -IssueBody 'no marker here')) 'Get-AsanaTaskGid returns null when absent'
Assert-True  ($null -eq (Get-AsanaTaskGid -IssueBody '<!-- asana-task: not-a-number -->')) 'Get-AsanaTaskGid rejects a non-numeric marker'
Assert-True  ($null -eq (Get-AsanaTaskGid -IssueBody '')) 'Get-AsanaTaskGid handles an empty body'


# matcher 2 -- the header row of a ticket imported FROM Asana (the intake shape). This is the case the
# marker alone could not reach: issue #388 in smartwatchbanden closed with its Asana task untouched,
# and the CI log said so in as many words -- "No <!-- asana-task: ... --> marker ... nothing to mirror".
$intake = @'
# 0150 CRO WIN | Lieferdatum unter ATC-button

| | |
|---|---|
| **Asana** | [1216905543348385](https://app.asana.com/1/1199613597897177/project/1214594032889511/task/1216905543348385) - project Development BWJ |
| **State** | buildable |

A sibling ticket is https://github.com/BWJ-ecommerce/smartwatchbanden/issues/390.
'@
$ref = Resolve-AsanaTaskRef -IssueBody $intake
Assert-Equal '1216905543348385' $ref.Gid    'header row of an imported ticket resolves its task'
Assert-Equal 'header-row'       $ref.Source 'and reports header-row as the source'

# the header row wins over any other Asana link in the body -- it is the ticket's own task
$sibling = "| **Asana** | [a](https://app.asana.com/1/9/project/8/task/111) |`nalso https://app.asana.com/1/9/project/8/task/222"
Assert-Equal '111' (Get-AsanaTaskGid -IssueBody $sibling) 'the header row wins over a sibling link further down'

# the marker wins over everything, so an issue that carries one is never re-matched
$both = "| **Asana** | [a](https://app.asana.com/1/9/project/8/task/111) |`n<!-- asana-task: 999 -->"
Assert-Equal 'marker' (Resolve-AsanaTaskRef -IssueBody $both).Source 'the marker outranks the header row'
Assert-Equal '999'    (Get-AsanaTaskGid    -IssueBody $both)        'and it is the marker GID that is used'

# matcher 3 -- a single Asana task URL anywhere, in either URL shape Asana hands out
Assert-Equal '1216905543348385' (Get-AsanaTaskGid -IssueBody 'see https://app.asana.com/1/9/project/8/task/1216905543348385') 'a sole modern task URL resolves'
Assert-Equal '1216905543348385' (Get-AsanaTaskGid -IssueBody 'see https://app.asana.com/0/1214594032889511/1216905543348385/f') 'a sole classic task URL resolves'
Assert-Equal 'sole-url'         (Resolve-AsanaTaskRef -IssueBody 'https://app.asana.com/1/9/project/8/task/77').Source 'and reports sole-url as the source'

# several DIFFERENT tasks and no marker -- reported, never guessed
$ambiguous = Resolve-AsanaTaskRef -IssueBody 'a https://app.asana.com/1/9/project/8/task/111 b https://app.asana.com/1/9/project/8/task/222'
Assert-True  ($null -eq $ambiguous.Gid)   'two different linked tasks resolve to nothing'
Assert-Equal 'ambiguous' $ambiguous.Source 'and are reported as ambiguous'
Assert-Equal 2 $ambiguous.Candidates.Count 'with both candidates named for the log'

# the same task linked twice is not ambiguous
Assert-Equal '111' (Get-AsanaTaskGid -IssueBody 'a https://app.asana.com/1/9/project/8/task/111 b https://app.asana.com/1/9/project/8/task/111') 'the same task linked twice still resolves'

# a project link names no task
Assert-True ($null -eq (Get-AsanaTaskGid -IssueBody 'board: https://app.asana.com/1/9/project/8')) 'a project link contributes no task GID'

# a non-numeric task GID can never reach a request URL
Assert-Throws { Get-AsanaTaskState -Gid 'abc' -Pat 'x' } 'Get-AsanaTaskState throws on a non-numeric GID'

# THE CENTRAL GUARANTEE (Dave, 2026-09-01): automation never resolves a mirrored ticket -- the
# colleague who filed it does, after testing. So the script must carry no way to write 'completed'
# at all. This is asserted over the source text rather than over behaviour, because the guarantee is
# the ABSENCE of a code path and no call can demonstrate an absence.
$mirrorSrc = Get-Content -LiteralPath (Join-Path $PluginRoot 'templates\asana-mirror.ps1') -Raw
Assert-True (-not (Get-Command -Name 'New-AsanaCompleteRequest' -ErrorAction SilentlyContinue)) 'no request builder for completing a task exists'
Assert-True (-not (Get-Command -Name 'Set-AsanaTaskCompleted'   -ErrorAction SilentlyContinue)) 'no helper for completing a task exists'
Assert-True ($mirrorSrc -notmatch "completed\s*=\s*\`$(true|false)") 'the script never builds a completed=true/false payload'
Assert-True ($mirrorSrc -notmatch "(?m)^\s*[^#]*-Method\s+PUT")      'the script issues no PUT at all -- the only write it knows is a comment'

# comment request -- the only write this script builds
Assert-Throws { New-AsanaCommentRequest -Gid 'abc' -Text 'x' }             'New-AsanaCommentRequest throws on a non-numeric GID'
Assert-Throws { New-AsanaCommentRequest -Gid '123; rm -rf /' -Text 'x' }   'and on a GID carrying a shell payload'
$c = New-AsanaCommentRequest -Gid '123' -Text 'GitHub issue owner/repo#7 is closed'
Assert-Equal 'POST' $c.Method 'comment request is a POST'
Assert-True  ($c.Uri.EndsWith('/tasks/123/stories')) 'comment request posts to the stories endpoint'

# the update text -- what a colleague actually reads
$pr = [pscustomobject]@{ number = 434; url = 'https://github.com/BWJ-ecommerce/smartwatchbanden/pull/434'; title = 'fix: close the delivery-date element' }
$closed = New-MirrorComment -IssueRef 'BWJ-ecommerce/smartwatchbanden#388' -Event 'closed' -ClosedBy @($pr) -StateReason 'completed'
Assert-True ($closed -match 'ready to test')                'the close update says the work is ready to test'
Assert-True ($closed -match 'stays open on purpose')        'and says the ticket deliberately stays open'
Assert-True ($closed -match 'Tick it off yourself')         'and puts the resolving in the requester hands'
Assert-True ($closed -match 'https://github\.com/BWJ-ecommerce/smartwatchbanden/issues/388') 'and carries the issue URL'
Assert-True ($closed -notmatch '(?i)resolved|completed|done\b') 'and never claims the ticket itself is resolved'

# the closing pull request -- the first thing somebody about to test wants
Assert-True ($closed -match 'Closed by pull request:')   'the close update names the pull request that closed the issue'
Assert-True ($closed -match '#434')                      'by number'
Assert-True ($closed -match 'close the delivery-date element') 'with its title'
Assert-True ($closed -match 'https://github\.com/BWJ-ecommerce/smartwatchbanden/pull/434') 'and its URL, so it is one click away'

$two = New-MirrorComment -IssueRef 'o/r#1' -Event 'closed' -StateReason 'completed' -ClosedBy @(
    [pscustomobject]@{ number = 1; url = 'https://github.com/o/r/pull/1'; title = 'a' },
    [pscustomobject]@{ number = 2; url = 'https://github.com/o/r/pull/2'; title = 'b' })
Assert-True ($two -match 'Closed by pull requests:') 'two closing PRs are announced in the plural'
Assert-True ($two -match '#1' -and $two -match '#2')  'and both are listed'

# closed by hand -- say so rather than imply a PR that is not there
$byHand = New-MirrorComment -IssueRef 'o/r#1' -Event 'closed' -StateReason 'completed'
Assert-True ($byHand -match 'Closed by hand')            'an issue with no linked PR says it was closed by hand'
Assert-True ($byHand -notmatch '/pull/' -and $byHand -notmatch 'Closed by pull request') 'and links none, rather than inventing a reference'
Assert-True ($byHand -match 'ready to test')             'while still saying the ticket is ready to test'

# closed as not planned -- the opposite update, because nothing was built
$notPlanned = New-MirrorComment -IssueRef 'o/r#1' -Event 'closed' -StateReason 'not_planned'
Assert-True ($notPlanned -match 'as not planned')        'a not-planned close says so'
Assert-True ($notPlanned -match 'nothing to test')       'and tells the requester there is nothing to test'
Assert-True ($notPlanned -notmatch 'ready to test')      'rather than asking them to test something that was never built'
Assert-True ($notPlanned.StartsWith((Get-MirrorCommentMarker -IssueRef 'o/r#1'))) 'and it still carries the de-duplication marker'

$reopened = New-MirrorComment -IssueRef 'BWJ-ecommerce/smartwatchbanden#388' -Event 'reopened'
Assert-True ($reopened -match 'reopened')            'the reopen update says so'
Assert-True ($reopened -match 'hold off on testing') 'and tells the requester not to test yet'

# the de-duplication key is the close update's own opening sentence, and it names the issue --
# so two issues mirrored onto one task never mask each other
$marker = Get-MirrorCommentMarker -IssueRef 'BWJ-ecommerce/smartwatchbanden#388'
Assert-True ($closed.StartsWith($marker)) 'the marker is the first thing the close update says'
Assert-True ($marker -match '#388')       'and it names the issue'
Assert-True ($marker -ne (Get-MirrorCommentMarker -IssueRef 'BWJ-ecommerce/smartwatchbanden#390')) 'two issues get two different markers'

# issue-ref parsing for the reconciliation sweep
Assert-Equal 'BWJ-ecommerce/smartwatchbanden#42' (Get-IssueRefFromNotes -Notes 'see https://github.com/BWJ-ecommerce/smartwatchbanden/issues/42 for detail') 'Get-IssueRefFromNotes pulls owner/repo#n from a GitHub URL'
Assert-True  ($null -eq (Get-IssueRefFromNotes -Notes 'no link at all')) 'Get-IssueRefFromNotes returns null without a GitHub issue URL'

# --- done ---------------------------------------------------------------------------------------
Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
