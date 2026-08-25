<#
.SYNOPSIS
    Regression tests for the config blueprint (issue #456): the Adopt axis in the contract registry,
    the generator that derives the artefact from this repo's own libs, and the adopt-config command
    that a consumer runs against it.

.DESCRIPTION
    Dependency-free: no Pester, plain PowerShell. Integration-style where it matters -- the adopt
    scenarios run the REAL script in a child process against throwaway consumer fixtures, and assert
    on what actually lands in the fixture's files.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/config-blueprint.tests.ps1

    THE TWO EXTRACTION BUGS BELOW WERE REAL, both found by reading the first generated artefact rather
    than by reasoning, and each has its own assert here:

      1. a structural walk that stopped only at the previous '}' swept up whatever sat between two
         functions -- Get-LiveStage came out carrying the retirement note of Get-ChangelogTierHeADINGS,
         a comment block about a different, deleted function;
      2. four functions in repo-config.ps1 share ONE assignment block, so three of them extracted
         without the '$script:' value they read -- copied on their own they would have returned $null
         in the consumer, a silent wrong answer where an absent function gets the documented fallback.

    Pure ASCII (repo convention for .ps1).

    Test-gaps (honest):
      - The blueprint is generated from THIS repo's real libs, so the generator is never exercised
        against a lib shaped differently (no '$script:' assignments at all, a function defined inside
        an if-block). That is deliberate: the generator is the source's own tool and only ever reads
        this tree.
      - adopt-config's "seam lib missing entirely" branch is exercised, but the pointer it prints at
        specialists-init is asserted only by its text, not by running that skill.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$Generator  = Join-Path $RepoRoot 'scripts\sync\build-config-blueprint.ps1'
$Adopt      = Join-Path $RepoRoot 'scripts\task\adopt-config.ps1'
$ContractLib = Join-Path $RepoRoot 'scripts\lib\script-contract-lib.ps1'
$Artefact   = Join-Path $RepoRoot 'plugins\workflows\workflow-davekjohn\blueprint\config-blueprint.json'
$Fixture    = Join-Path ([System.IO.Path]::GetTempPath()) "config-blueprint-test-fixture-$PID"

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

function Assert-Match {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -match $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern not found: '$Pattern'" -ForegroundColor Red
    }
}

function Assert-NotMatch {
    param([string]$Pattern, [string]$Text, [string]$Name)
    if ($Text -notmatch $Pattern) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name`n         pattern present but should not be: '$Pattern'" -ForegroundColor Red
    }
}

function New-ConsumerFixture {
    <# A throwaway consumer with a seam that predates most of the contract: it answers Get-RepoName
       with its OWN value, so the "never overwrites" rule has something real to protect. #>
    param([string]$Path, [switch]$NoRepoConfig)

    if (Test-Path -LiteralPath $Path) { Remove-Item -Recurse -Force -LiteralPath $Path }
    New-Item -ItemType Directory -Force -Path (Join-Path $Path 'scripts\lib') | Out-Null

    if (-not $NoRepoConfig) {
        Set-Content -LiteralPath (Join-Path $Path 'scripts\repo-config.ps1') -Encoding ascii -Value @(
            '# A consumer seam that predates most of the contract.',
            "`$script:RepoName = 'someone/their-repo'",
            'function Get-RepoName { return $script:RepoName }'
        )
    }
    Set-Content -LiteralPath (Join-Path $Path 'scripts\lib\branch-info.ps1') -Encoding ascii -Value @(
        'function Get-BranchInfo { param($Branch) return [pscustomobject]@{ Branch = $Branch } }'
    )
}

function Invoke-Adopt {
    param([string]$ConsumerRoot, [string[]]$ScriptArgs = @())
    $prev = $env:CLAUDE_PROJECT_DIR
    $env:CLAUDE_PROJECT_DIR = $ConsumerRoot
    try {
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Adopt @ScriptArgs
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
    } finally {
        $env:CLAUDE_PROJECT_DIR = $prev
    }
}

try {

Write-Host "`n== the Adopt axis in the contract registry ==" -ForegroundColor Cyan

. $ContractLib
$contract = Get-ScriptContract

# THE COMPLETENESS GUARD, and it is the whole reason the marker lives beside the registration rather
# than in a list of its own: a record added without an Adopt marker would otherwise be classified by
# whatever the reader defaults to, silently.
$noAdopt = @($contract | Where-Object { -not $_.ContainsKey('Adopt') })
Assert-Equal 0 $noAdopt.Count "every contract record declares Adopt (missing: $($noAdopt.Function -join ', '))"

$badValue = @($contract | Where-Object { $_.ContainsKey('Adopt') -and $_.Adopt -notin @('copy', 'decide') })
Assert-Equal 0 $badValue.Count 'every Adopt value is copy or decide'

$noWhy = @($contract | Where-Object { -not $_.ContainsKey('AdoptWhy') -or -not $_.AdoptWhy })
Assert-Equal 0 $noWhy.Count "every record explains its marker (missing AdoptWhy: $($noWhy.Function -join ', '))"

# The same rule the registry already states for Returns: a report marker inside a record's prose is
# counted by the session hook and by this repo's own asserts, so writing one here inflates the counts.
$markerInWhy = @($contract | Where-Object { $_.ContainsKey('AdoptWhy') -and $_.AdoptWhy -match '\[(ERROR|INFO|OK|BOOTSTRAP)\]' })
Assert-Equal 0 $markerInWhy.Count 'no AdoptWhy text contains a report marker that counters would pick up'

# The four the issue named, plus Get-RepoName -- the case that is obvious under this question and was
# absent from the issue's list because it answers a different one.
foreach ($fn in 'Get-ReservedRootMd', 'Get-ReleasePluginTier', 'Get-ReleaseConsumerBumps', 'Get-ReleaseMajorMinMinors', 'Get-RepoName') {
    $rec = $contract | Where-Object { $_.Function -eq $fn }
    Assert-Equal 'decide' $rec.Adopt "$fn is the consumer's to decide"
}

# AND THE ONE THAT WAS MARKED 'copy' UNTIL AUGUST 10, 2026 (inbound #560). It belongs in the family
# directly above -- same three functions, same question -- and was justified on the value being harmless
# rather than on the question being shared: 'major' is also the built-in fallback, so copying it "changes no
# behaviour". True of the value, false of the question. Measured in a consumer foldering per minor since
# v2.0.0: 'major' was placed into their seam unseen and their next cut would have started a second
# releases/development/ tree beside fourteen directories of history. Its own assert, with its own reason,
# because that reasoning is what has to fail if anyone reclassifies it back.
$grpRec = $contract | Where-Object { $_.Function -eq 'Get-ReleaseNotesGrouping' }
Assert-Equal 'decide' $grpRec.Adopt 'Get-ReleaseNotesGrouping describes a TREE, not a way of working -- so it is proposed, never placed'
Assert-Match 'releases/development' $grpRec.Returns 'and its Returns text names the tree the answer is read off, so a decider does not have to guess'

# branch-info.ps1 says of ITSELF that it is repo-owned and does not travel, and its refusal of 'chore/'
# is written down as this repo's rule. Both records were classified 'copy' on the first pass; this
# assert is what stops that returning.
foreach ($fn in 'Get-BranchInfo', 'Test-BranchName') {
    $rec = $contract | Where-Object { $_.Function -eq $fn }
    Assert-Equal 'decide' $rec.Adopt "$fn stays repo-owned -- branch-info.ps1 declares itself so"
}

Write-Host "`n== the generated artefact ==" -ForegroundColor Cyan

Assert-True (Test-Path -LiteralPath $Artefact -PathType Leaf) 'the blueprint artefact is committed'

$bp = Get-Content -LiteralPath $Artefact -Raw | ConvertFrom-Json
Assert-Equal $contract.Count $bp.records.Count 'the artefact carries exactly one record per contract entry'
Assert-Equal 'DaveKJohn/claude-code-specialists' $bp.sourceRepo 'the artefact names the repo it came from'

# In sync with the libs as they stand right now. This is the same thing the lint gate runs; asserting
# it here too means a stale artefact fails the suite rather than only the gate.
& powershell -NoProfile -ExecutionPolicy Bypass -File $Generator -Check | Out-Null
Assert-Equal 0 $LASTEXITCODE 'the committed artefact matches a fresh generation'

# --- Extraction bug 1: a foreign comment block must not travel as a function's reasoning ------------
$liveStage = $bp.records | Where-Object { $_.function -eq 'Get-LiveStage' }
Assert-Match 'go live' $liveStage.text 'Get-LiveStage carries its own reasoning'
Assert-NotMatch 'Get-ChangelogTierHeadings' $liveStage.text 'Get-LiveStage does NOT carry the retirement note of a different function'

$grouping = $bp.records | Where-Object { $_.function -eq 'Get-ReleaseNotesGrouping' }
Assert-NotMatch 'the LIVE marker' $grouping.text 'Get-ReleaseNotesGrouping does NOT carry the six-knob preamble above its block'

# --- Extraction bug 2: a function must carry every value it reads ----------------------------------
# Three of the four entry-wording functions sit BELOW the shared assignment block, so a contiguous walk
# alone leaves them without their value.
#
# Read through the PARSER here as well, deliberately duplicating the generator's approach rather than
# its code: a text scan reports a '$script:' name that a COMMENT points at (measured -- one block cites
# a variable living in another file entirely), and an assert built on that would fail on correct
# output. A test that re-derives the fact independently is worth more here than one sharing the helper.
function Get-ReadVars {
    param([string]$Text)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$t, [ref]$e)
    if ($e -and $e.Count -gt 0) { return @() }
    return @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) |
        Where-Object { $_.VariablePath.UserPath -like 'script:*' } |
        ForEach-Object { $_.VariablePath.UserPath.Substring(7) } | Sort-Object -Unique)
}

foreach ($rec in @($bp.records | Where-Object { $_.declared -and $_.text })) {
    $reads = Get-ReadVars -Text $rec.text
    foreach ($name in $reads) {
        $assigned = $rec.text -match ('(?m)^\s*\$script:' + [regex]::Escape($name) + '\s*=')
        Assert-True $assigned "$($rec.function): carries the assignment for `$script:$name that it reads"
    }
}

# The source leaves nine contract functions at the built-in fallback: the two impact-table seams,
# Get-TestCommands since inbound #644 (this repo's suites are all PowerShell), Get-EntryGateExemptPrefixes
# since inbound #789 (this repo runs no mirror branches, so 'sync' being the default IS its answer), and
# Get-ReleasePageMasthead since inbound #809 (this repo has no wordmark to put on its page) -- five, until
# issue #885 added four more (Get-ChangelogPath, Get-ReleaseDevelopmentNotesRoot, Get-ReleaseGithubNotesRoot,
# Get-ReleaseInternalNotesRoot), each with a computed default that already states this repo's own answer
# without an explicit declaration (see each record's own AdoptWhy). Recorded as declared=false with no text
# rather than dropped, because "this repo does not state it either" is an answer -- and the honest one to
# hand a consumer.
$undeclared = @($bp.records | Where-Object { -not $_.declared })
Assert-Equal 9 $undeclared.Count 'the nine functions the source itself leaves at the fallback are recorded, not dropped'
foreach ($rec in $undeclared) {
    Assert-Equal '' $rec.text "$($rec.function): an undeclared record carries no text to copy"
}

Write-Host "`n== adopt-config against a fresh consumer ==" -ForegroundColor Cyan

New-ConsumerFixture -Path $Fixture
$repoConfig = Join-Path $Fixture 'scripts\repo-config.ps1'
$before = [System.IO.File]::ReadAllText($repoConfig)

# --- Dry run writes nothing -----------------------------------------------------------------------
$r = Invoke-Adopt -ConsumerRoot $Fixture
Assert-Equal 0 $r.Code 'dry run: exit 0'
Assert-Match 'DRY RUN' $r.Out 'dry run: says so'
# The copy example is Get-RosterPath. It was Get-ReleaseNotesGrouping until August 10, 2026, when that
# record became a decide one (#560) -- so this line asserted the classification the repair reverses.
Assert-Match '\[copy\]\s+Get-RosterPath' $r.Out 'dry run: names a value it would place'
Assert-Match '\[decide\]\s+Get-ReleasePluginTier' $r.Out 'dry run: names a value it would only propose'
Assert-Match '\[decide\]\s+Get-ReleaseNotesGrouping' $r.Out 'dry run: and the foldering scheme is among the ones it would only propose (#560)'
Assert-Equal $before ([System.IO.File]::ReadAllText($repoConfig)) 'dry run: the consumer lib is byte-identical afterwards'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture 'config-adoption-proposal.md'))) 'dry run: no proposal document is written'

# --- Apply ----------------------------------------------------------------------------------------
$r = Invoke-Adopt -ConsumerRoot $Fixture -ScriptArgs @('-Apply')
Assert-Equal 0 $r.Code 'apply: exit 0'

$after = [System.IO.File]::ReadAllText($repoConfig)
Assert-Match 'Get-RosterPath' $after 'apply: a copy record landed in the consumer lib'
Assert-Match 'Adopted from the DaveKJohn/claude-code-specialists config blueprint' $after 'apply: the placed block says where it came from'

# NEVER OVERWRITES: the consumer's own answer survives, and the source's is not appended beside it.
Assert-Match "someone/their-repo" $after "apply: the consumer's own Get-RepoName value is untouched"
Assert-NotMatch 'DaveKJohn/claude-code-specialists.{0,40}Single place this is stated' $after "apply: the source's repo name was not written into the consumer"

# A decide record is proposed and NEVER placed -- the assert that protects the whole doctrine.
# Get-ReleaseNotesGrouping joined the list on August 10, 2026 (#560), and it is the case that shows what the
# doctrine is FOR: this is the value a consumer was measured to have received wrongly, and the only signal
# would have been a second releases/development/ tree appearing at their next cut.
foreach ($fn in 'Get-ReleasePluginTier', 'Get-ReservedRootMd', 'Get-PrMergeMethod', 'Get-LintScript', 'Get-ReleaseNotesGrouping') {
    Assert-NotMatch ("(?m)^\s*function\s+$fn\b") $after "apply: '$fn' was NOT defined in the consumer lib"
}

$proposal = Join-Path $Fixture 'config-adoption-proposal.md'
Assert-True (Test-Path -LiteralPath $proposal -PathType Leaf) 'apply: the proposal document exists'
$prop = [System.IO.File]::ReadAllText($proposal)
Assert-Match '## `Get-ReleasePluginTier`' $prop 'proposal: one section per decision'
Assert-Match 'Why this is yours to decide' $prop 'proposal: each section carries the reason'
Assert-Match 'do not paste this in unadapted' $prop "proposal: the source's version is marked as reference"
# #560's user-visible half: the reclassified record now reaches the document a person actually answers, and
# it arrives with the way to look the answer up rather than only the question.
Assert-Match '## `Get-ReleaseNotesGrouping`' $prop 'proposal: the foldering scheme is asked rather than assumed (#560)'
Assert-Match 'READ IT OFF YOUR EXISTING TREE' $prop 'proposal: and it says the answer is readable off the existing directories, so it is a lookup rather than a choice'

# The placed functions must actually ANSWER in the consumer -- the thing extraction bug 2 broke.
$answers = & {
    Set-StrictMode -Off
    . $args[0]
    [pscustomobject]@{
        RepoName    = Get-RepoName
        RosterPath  = Get-RosterPath
        # Get-ReleaseNotesGrouping used to be read here as a third adopted answer. It is a decide record
        # since August 10, 2026 (#560), so it is deliberately NOT defined in the consumer and calling it
        # would fail on a command that does not exist -- which is the correct outcome, asserted in the
        # not-placed loop above rather than by reading a value that should not be there.
        HistoryPath = Get-ReleaseHistoryPath
        BodyHolder  = Get-EntryBodyPlaceholder
        Fallback    = Get-EntryFallbackType
    }
} $repoConfig
Assert-Equal 'someone/their-repo' $answers.RepoName 'the consumer keeps its own repo name'
Assert-Equal '.claude/specialists/SPECIALISTS.md' $answers.RosterPath 'an adopted function answers'
Assert-Equal 'releases/README.md' $answers.HistoryPath 'an adopted function answers (back at the shared default since August 19, 2026: a repo''s release HISTORY is the repo''s, not the workflow''s, so it does not live in a folder a teardown removes)'
Assert-Equal 'Chore' $answers.Fallback 'an adopted function answers'
Assert-True ($null -ne $answers.BodyHolder -and $answers.BodyHolder.Length -gt 0) 'a function that sits below the shared assignment block still answers (extraction bug 2)'

# --- Idempotent -----------------------------------------------------------------------------------
$r = Invoke-Adopt -ConsumerRoot $Fixture -ScriptArgs @('-Apply')
Assert-Equal 0 $r.Code 're-run: exit 0'
Assert-Match 'to place \(copy\):\s+0' $r.Out 're-run: nothing left to place'
Assert-Equal $after ([System.IO.File]::ReadAllText($repoConfig)) 're-run: the lib is byte-identical -- nothing was appended twice'

# --- A repo that has not been bootstrapped at all --------------------------------------------------
$bare = Join-Path $Fixture '..\config-blueprint-test-bare'
New-ConsumerFixture -Path $bare -NoRepoConfig
$r = Invoke-Adopt -ConsumerRoot (Resolve-Path -LiteralPath $bare).Path
Assert-Equal 1 $r.Code 'missing seam lib: exits non-zero'
Assert-Match 'specialists-init' $r.Out 'missing seam lib: points at the bootstrap rather than half-creating one'
Remove-Item -Recurse -Force -LiteralPath $bare -ErrorAction SilentlyContinue

} finally {
    if (Test-Path -LiteralPath $Fixture) { Remove-Item -Recurse -Force -LiteralPath $Fixture -ErrorAction SilentlyContinue }
}

Write-Host "`nResult: $($script:pass) pass, $($script:fail) fail." -ForegroundColor $(if ($script:fail -gt 0) { 'Red' } else { 'Green' })
if ($script:fail -gt 0) { exit 1 }
exit 0
