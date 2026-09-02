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

# THE CI HALF NEEDS NO WORKSPACE (#1210): every call it makes addresses a task or a project by GID,
# so the parameter it used to declare had no reader, while the yml handed BOTH steps a variable
# nothing consumed -- which reads as a possible cause the next time a sweep reports 0 updated.
# Asserted over the source text and over the workflow, because this too is the absence of a thing.
$mirrorYml = Get-Content -LiteralPath (Join-Path $PluginRoot 'templates\asana-mirror.yml') -Raw
Assert-True ($mirrorSrc -notmatch 'WorkspaceGid')        'the script declares no workspace parameter'
Assert-True ($mirrorYml -notmatch 'ASANA_WORKSPACE_GID') 'and the workflow hands neither step a workspace variable'
Assert-True ($mirrorYml -match 'ASANA_PROJECT_GID')      'while the project variable it does read is still passed'

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

# --- the prio label ------------------------------------------------------------------------------
# Dave's mapping, September 2, 2026: 1.00-1.99 very low | 2.00-2.99 low | 3.00-3.99 high |
# 4.00-5.00 very high. EVERY boundary is asserted from both sides, because an off-by-a-hundredth
# here mislabels real work and nothing downstream would notice it had happened.
Assert-Equal 'very low'  (Get-PrioLabelForScore -Score 1)    'score 1.00 is very low -- the bottom of the scale'
Assert-Equal 'very low'  (Get-PrioLabelForScore -Score 1.99) 'and 1.99 is still very low'
Assert-Equal 'low'       (Get-PrioLabelForScore -Score 2)    '2.00 flips to low'
Assert-Equal 'low'       (Get-PrioLabelForScore -Score 2.99) 'and 2.99 is still low'
Assert-Equal 'high'      (Get-PrioLabelForScore -Score 3)    '3.00 flips to high'
Assert-Equal 'high'      (Get-PrioLabelForScore -Score 3.99) 'and 3.99 is still high'
Assert-Equal 'very high' (Get-PrioLabelForScore -Score 4)    '4.00 flips to very high'
Assert-Equal 'very high' (Get-PrioLabelForScore -Score 5)    'and 5.00, the top of the scale, is very high'

# no score and an out-of-range score give the same answer -- no label, never the nearest bucket
Assert-True ($null -eq (Get-PrioLabelForScore -Score $null)) 'a task with no score gets no label at all'
Assert-True ($null -eq (Get-PrioLabelForScore -Score 0.99))  'and a score below the scale gets none rather than the nearest one'
Assert-True ($null -eq (Get-PrioLabelForScore -Score 5.01))  'and one above the scale gets none either'

# THE MAPPING IS CULTURE-INVARIANT, which is not obvious and was measured rather than assumed: the
# machine this repo is maintained on runs nl-NL, where the decimal separator is a comma. A score
# arriving as a string must still read as three-and-a-half and not as thirty-five.
Assert-Equal 'high' (Get-PrioLabelForScore -Score '3.5') "a score arriving as the string '3.5' still reads as 3.5"

# every label the mapper can return is one the enforcer knows how to remove: if these two drift, a
# rescored ticket keeps a stale label forever and the issue claims two priorities at once
foreach ($s in @(1.5, 2.5, 3.5, 4.5)) {
    Assert-True ($script:PrioLabels -contains (Get-PrioLabelForScore -Score $s)) "the label for score $s is one PrioLabels knows"
}
Assert-Equal 4 $script:PrioLabels.Count 'and PrioLabels holds exactly the four buckets -- there is no medium'

# reading the score off a task object, past the other custom fields Asana returns beside it
$scoredTask = [pscustomobject]@{ custom_fields = @(
    [pscustomobject]@{ name = 'Type';       number_value = $null },
    [pscustomobject]@{ name = 'Prio-Score'; number_value = 3.8 }) }
Assert-Equal 3.8 (Get-PrioScoreFromTask -Task $scoredTask -FieldName 'Prio-Score') 'Get-PrioScoreFromTask finds the field by name, past another field'
Assert-True ($null -eq (Get-PrioScoreFromTask -Task $scoredTask -FieldName 'Nope'))      'and returns null for a field the task has not got'
Assert-True ($null -eq (Get-PrioScoreFromTask -Task $null       -FieldName 'Prio-Score')) 'and null for a task that could not be read at all'
$emptyScore = [pscustomobject]@{ custom_fields = @([pscustomobject]@{ name = 'Prio-Score'; number_value = $null }) }
Assert-True ($null -eq (Get-PrioScoreFromTask -Task $emptyScore -FieldName 'Prio-Score')) 'and null for a field that is present but empty'

# an issue that already reads correctly is not written to -- what keeps the daily re-run quiet. This
# path returns before any gh call, so it is safe to assert here with no network and no repo.
Assert-True (-not (Set-IssuePrioLabel -Repo 'o/r' -Number 1 -Label 'high' -Current @('high', 'tier-1'))) 'an issue already carrying the right prio label is left alone'

# --- the stage sections --------------------------------------------------------------------------
# The board's six sections are the cycle's stages, and a section is recognised by the NUMBER its name
# starts with -- the words after it belong to the board and may change any day.
Assert-Equal 3 (Get-StageFromSectionName -Name '3. In development - branch open') 'a numbered section yields its stage'
Assert-Equal 3 (Get-StageFromSectionName -Name '3. Building it')                  'and still does after the words are rewritten -- the number is the only machine-read half'
Assert-Equal 6 (Get-StageFromSectionName -Name '  6. Completed')                   'leading whitespace does not hide the number'
Assert-Equal 2 (Get-StageFromSectionName -Name '2.')                               'a bare number and dot is enough'
Assert-True ($null -eq (Get-StageFromSectionName -Name 'Waiting for more info'))   'an unnumbered section is on no pipeline'
Assert-True ($null -eq (Get-StageFromSectionName -Name 'Stap 3: bouwen'))          'and a number that is not the prefix does not count -- the anchor is the start of the name'
Assert-True ($null -eq (Get-StageFromSectionName -Name ''))                        'an empty name yields nothing rather than throwing'

# --- the stage MAP ------------------------------------------------------------------------------
# The number convention says how a section is RECOGNISED; the map says what each one MEANS. They were
# one question until the board this was written against grew a section the same afternoon, shifting
# every stage above it by one -- silently, since nothing failed and every card would simply have been
# filed a column early. The map is now a repo seam, and the default is what a repo stating none gets.
$map = Get-DefaultAsanaStageMap
Assert-Equal '1/2/3/4/5/6/7' ((Get-StageMapNumbers -Map $map) -join '/') 'the default map is the seven-section board, in cycle order'
Assert-Equal 'needs-info' $map.NeedsInfoLabel 'and it names the label that drives the Need more info column'
Assert-Equal 0 (Test-AsanaStageMap -Map $map).Count 'the default map validates'

# Three ways a hand-written map goes wrong, and all three are SILENT at runtime rather than loud:
# a missing key reads as stage 0, a non-numeric one as 0 too, and a duplicate makes two stages one
# column so a card can never leave one of them.
$noKey = $map.Clone(); $noKey.Remove('InReview')
Assert-True (((Test-AsanaStageMap -Map $noKey) -join ' ') -match 'InReview') 'a map missing a stage is refused, naming which'
$notNum = $map.Clone(); $notNum['Filed'] = 'three'
Assert-True ((Test-AsanaStageMap -Map $notNum).Count -gt 0) 'a stage that is not a section number is refused'
$dupe = $map.Clone(); $dupe['InReview'] = $dupe['Filed']
Assert-True (((Test-AsanaStageMap -Map $dupe) -join ' ') -match 'more than one stage') 'two stages naming one section is refused -- a card could never leave one of them'
Assert-True ((Test-AsanaStageMap -Map $null).Count -gt 0) 'and an empty map is refused rather than treated as a default'

# The two ends of the board, asserted rather than assumed -- the same treatment the 'completes
# nothing' guarantee gets. Requests is the submitter's inbox; Completed is their verdict.
Assert-True (-not (Test-StageIsWritable -Stage $map.Requests  -Map $map)) 'Requests is the submitter inbox and is never a target'
Assert-True (-not (Test-StageIsWritable -Stage $map.Completed -Map $map)) 'Completed is NEVER a target -- the section-move twin of never completing a task'
Assert-True (Test-StageIsWritable -Stage $map.NeedsInfo   -Map $map) 'Need more info is ours to set, because a label drives it'
Assert-True (Test-StageIsWritable -Stage $map.Filed       -Map $map) 'Filed is ours'
Assert-True (Test-StageIsWritable -Stage $map.ReadyToTest -Map $map) 'and so is Ready to test, the last one that is'
Assert-True (-not (Test-StageIsWritable -Stage $null -Map $map)) 'no stage at all is not writable either'
Assert-Equal 5 (Get-WritableStages -Map $map).Count 'five writable stages -- the whole board minus its two ends'

# A REMAPPED board is the real test of the seam: the same assertions must hold against numbers this
# suite never mentions, or the map is decoration over hard-coded literals.
$shifted = @{ Requests = 10; NeedsInfo = 20; Filed = 30; InDevelopment = 40
              InReview = 50; ReadyToTest = 60; Completed = 70; NeedsInfoLabel = 'blocked' }
Assert-Equal 0 (Test-AsanaStageMap -Map $shifted).Count 'a board numbered any other way validates too'
Assert-True (Test-StageIsWritable -Stage 30 -Map $shifted)        'and its Filed stage is writable'
Assert-True (-not (Test-StageIsWritable -Stage 3 -Map $shifted))  'while the DEFAULT Filed number is not, under that map'
Assert-True (-not (Test-StageIsWritable -Stage 70 -Map $shifted))  'and its Completed stage is still the untouchable end'

# The derivation. A FLOOR and not a position: CI cannot see a branch with no pull request behind it,
# so a card a session moved to InDevelopment must not be dragged back by a sweep that knows less.
$prOpen   = [pscustomobject]@{ number = 1; state = 'OPEN';   merged = $false }
$prMerged = [pscustomobject]@{ number = 2; state = 'MERGED'; merged = $true }
Assert-Equal $map.Filed       (Get-StageFloorForIssue -State 'OPEN' -Map $map)                            'an open issue with nothing linked floors at Filed'
Assert-Equal $map.InReview    (Get-StageFloorForIssue -State 'OPEN' -PullRequests @($prOpen)   -Map $map) 'an open pull request floors at In review'
Assert-Equal $map.InReview    (Get-StageFloorForIssue -State 'OPEN' -PullRequests @($prMerged) -Map $map) 'and a MERGED one on a still-open issue floors there too -- Dave, September 2, 2026: his board has no column between the two'
Assert-Equal $map.ReadyToTest (Get-StageFloorForIssue -State 'CLOSED' -StateReason 'completed' -Map $map) 'closed as completed floors at Ready to test -- the submitter turn'
Assert-True ($null -eq (Get-StageFloorForIssue -State 'CLOSED' -StateReason 'not_planned' -Map $map)) 'closed as not planned floors nowhere -- nothing was built, so there is nothing to test'
Assert-Equal $map.ReadyToTest (Get-StageFloorForIssue -State 'closed' -StateReason 'COMPLETED' -Map $map) 'and the state is read case-insensitively, since two GitHub surfaces disagree on it'

# InDevelopment is NEVER derived, and that is the design rather than a gap: it is the one hop only a
# session can see, and forward-only is what protects it.
$derived = @()
foreach ($case in @(@('OPEN', '', @()), @('OPEN', '', @($prOpen)), @('OPEN', '', @($prMerged)), @('CLOSED', 'completed', @($prMerged)))) {
    $f = Get-StageFloorForIssue -State $case[0] -StateReason $case[1] -PullRequests $case[2] -Map $map
    $derived += $f
    Assert-True (Test-StageIsWritable -Stage $f -Map $map) "the derivation never leaves the writable range ($($case[0])/$($case[1]))"
}
Assert-True ($derived -notcontains $map.InDevelopment) 'and it never derives InDevelopment -- that hop belongs to the session at new-branch'

# --- the target, and the two answers that may go BACKWARD -----------------------------------------
# Everything else is a floor, and floors only rise. These two are a person saying something.
$t = Resolve-TargetStage -State 'OPEN' -PullRequests @($prOpen) -Labels @('tier-1', 'needs-info') -Map $map
Assert-Equal $map.NeedsInfo $t.Stage         'the needs-info label OUTRANKS the issue state -- an open pull request does not unblock a card somebody blocked'
Assert-True  $t.AllowBackward                'and it may move the card backward, because a person set it'
Assert-True  ($t.Why -match 'needs-info')    'and the log says which label decided it'

$t = Resolve-TargetStage -State 'OPEN' -PullRequests @($prOpen) -Labels @('tier-1') -Map $map
Assert-Equal $map.InReview $t.Stage          'removing the label hands the card back to its state-derived floor'
Assert-True  (-not $t.AllowBackward)         'which is forward, so it needs no permission'

$t = Resolve-TargetStage -State 'OPEN' -Labels @() -Map $map -Reopened
Assert-Equal $map.Filed $t.Stage             'a reopen lands the card wherever the issue now is'
Assert-True  $t.AllowBackward                'and is the other answer allowed to go backward -- it is a real state change'
Assert-True  ($t.Why -match 'reopen')        'and says so'

$t = Resolve-TargetStage -State 'CLOSED' -StateReason 'not_planned' -Labels @('needs-info') -Map $map
Assert-Equal $map.NeedsInfo $t.Stage 'the label still answers for an issue whose state answers nothing'

$t = Resolve-TargetStage -State 'OPEN' -Labels @('blocked') -Map $shifted
Assert-Equal 20 $t.Stage 'the label name comes from the map too, so a repo may call it anything'
$noLabel = $map.Clone(); $noLabel['NeedsInfoLabel'] = ''
$t = Resolve-TargetStage -State 'OPEN' -Labels @('needs-info') -Map $noLabel
Assert-Equal $map.Filed $t.Stage 'and a map naming no label switches the column off -- a real answer for a board without one'

# Which board -- read off the task's own memberships, so no repo keeps six section GIDs in its config.
# A task on an unnumbered board only is on no pipeline, which is how any other board is left alone.
$onBoard = @(
    [pscustomobject]@{ project = [pscustomobject]@{ gid = '1201907543904785' }; section = [pscustomobject]@{ gid = '11'; name = 'Backlog' } },
    [pscustomobject]@{ project = [pscustomobject]@{ gid = '1216936502427971' }; section = [pscustomobject]@{ gid = '22'; name = '4. Development done' } })
$sel = Select-StageMembership -Memberships $onBoard
Assert-Equal 'stage-section'    $sel.Source                'a numbered section past an unnumbered one still resolves'
Assert-Equal 4                  $sel.Membership.Stage      'and reports the stage the card is in now'
Assert-Equal '1216936502427971' $sel.Membership.ProjectGid 'and the board it read that from'
Assert-Equal '22'               $sel.Membership.SectionGid 'and that section GID, which is what a move needs'

Assert-Equal 'none' (Select-StageMembership -Memberships $onBoard[0]).Source 'a task on an unnumbered board only is on no pipeline'
Assert-Equal 'none' (Select-StageMembership -Memberships @()).Source         'and a task on no board at all is the same answer'
$twoBoards = @(
    [pscustomobject]@{ project = [pscustomobject]@{ gid = '111' }; section = [pscustomobject]@{ gid = '1'; name = '2. Filed' } },
    [pscustomobject]@{ project = [pscustomobject]@{ gid = '222' }; section = [pscustomobject]@{ gid = '2'; name = '5. Testing' } })
Assert-Equal 'ambiguous' (Select-StageMembership -Memberships $twoBoards).Source 'two numbered boards is two answers, and neither is taken'
Assert-Equal 2           (Select-StageMembership -Memberships $twoBoards).Candidates.Count 'and both are named for the log'

# The move request. Pure, and it refuses non-numeric input on BOTH sides -- a section name is read out
# of Asana and a GID out of an issue body, and neither may reach a request URL unchecked.
$move = New-AsanaSectionMoveRequest -Gid '1216905543348385' -SectionGid '1217315819287423'
Assert-Equal 'POST' $move.Method 'a section move is a POST'
Assert-Equal 'https://app.asana.com/api/1.0/sections/1217315819287423/addTask' $move.Uri 'to the section addTask endpoint -- the task is the payload, not the path'
Assert-Equal '{"data":{"task":"1216905543348385"}}' $move.Body 'and the body carries the task GID'
Assert-Throws { New-AsanaSectionMoveRequest -Gid 'abc' -SectionGid '123' } 'a non-numeric task GID is refused'
Assert-Throws { New-AsanaSectionMoveRequest -Gid '123' -SectionGid 'x/y' } 'and so is a non-numeric section GID'

# --- done ---------------------------------------------------------------------------------------
Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
