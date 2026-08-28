<#
.SYNOPSIS
    Tests for the backing gate -- Get-BranchBackingFinding in scripts/lib/park-lib.ps1, and the
    refusal open-pr.ps1 builds on it (issue #1026).

.DESCRIPTION
    WHAT THIS EXISTS FOR. PR #1025 merged a changelog entry describing two new rules in a manual whose
    edit was never committed. The branch's whole diff was its development document; the fold then removed
    that file, so the merge delivered an entry and no content. Every gate was green -- the four that read
    the development document are all satisfied by an entry with nothing behind it, because none of them
    reads the diff.

    THE MEASUREMENT ALREADY EXISTED AND WENT TO THE WRONG READER. park-cycle's backing note (#960/#976)
    named the count and the state and gave the instruction that would have prevented the merge -- in a
    COMMIT BODY. That is right for the reader on a second device and invisible to the session holding the
    uncommitted file. This gate is the same measurement, delivered where it can still be acted on.

    SO THE PROPERTY UNDER TEST IS THE NARROWNESS, not the refusal. A gate that fires whenever a resolved
    step has no commit behind it would fire on nearly every early branch -- a planning step ticked before
    a line of code exists is the ordinary case -- and a gate firing on almost every run is one nobody
    reads by the time it matters. Most cases below assert SILENCE.

    AND THE CONDITION HAS TWO CALLERS, which is why it is a function rather than two inline tests. The
    park note describes both shapes; the gate refuses one and warns on the other. Case 5 pins that they
    still agree, because a park that alarms over a gate that stays silent is the drift this repo pays for.

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibPath  = Join-Path $RepoRoot 'scripts\lib\park-lib.ps1'

$script:pass = 0
$script:fail = 0

function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ("$Expected" -eq "$Actual") { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label`n         expected: '$Expected'`n         got:      '$Actual'" -ForegroundColor Red }
}
function Assert-True {
    param([bool]$Condition, [string]$Label)
    if ($Condition) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label" -ForegroundColor Red }
}

Assert-True (Test-Path -LiteralPath $LibPath) 'park-lib.ps1 exists at its registered source path'
. (Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1')
. $LibPath

# The two inputs are duck-typed, so the fixtures are the shapes the real callers hand over and nothing
# more: Get-BranchProgressTally's counts, and Get-GitParkBacking's object.
function New-Steps {
    param([int]$Total, [int]$Open, [int]$Resolved)
    return [pscustomobject]@{ Total = $Total; Open = $Open; Resolved = $Resolved }
}
function New-Backing {
    param(
        [int]$Committed = 0, [bool]$CommittedKnown = $true,
        [int]$Uncommitted = 0, [bool]$UncommittedKnown = $true
    )
    return [pscustomobject]@{
        Committed = $Committed; CommittedKnown = $CommittedKnown
        Uncommitted = $Uncommitted; UncommittedKnown = $UncommittedKnown
        Trunk = 'main'
    }
}

# --- 1. THE CASE THIS FILE EXISTS FOR: PR #1025's exact shape ----------------------------------
Write-Host "`n== 1. a finished plan with the work still uncommitted here ==" -ForegroundColor Cyan
$f1 = Get-BranchBackingFinding -Steps (New-Steps -Total 3 -Open 0 -Resolved 3) -Backing (New-Backing -Committed 0 -Uncommitted 1)
Assert-True ([bool]$f1) 'the finding is raised'
Assert-Equal 'UncommittedHere' $f1.Kind 'and it names the repairable shape'
Assert-Equal 1 $f1.Uncommitted 'carrying the count the author needs'
Assert-Equal 3 $f1.Resolved 'and the plan state that makes it legible'
Assert-Equal 3 $f1.Total 'both halves of it'

# --- 2. the other shape: the work is not on this machine at all --------------------------------
# Different fault, different answer at the caller -- open-pr warns rather than refusing, because from
# here it is indistinguishable from a branch that legitimately ships its entry alone.
Write-Host "`n== 2. a finished plan with nothing uncommitted either ==" -ForegroundColor Cyan
$f2 = Get-BranchBackingFinding -Steps (New-Steps -Total 3 -Open 0 -Resolved 3) -Backing (New-Backing -Committed 0 -Uncommitted 0)
Assert-True ([bool]$f2) 'still a finding'
Assert-Equal 'NotInThisCheckout' $f2.Kind 'but a different kind'
Assert-Equal 0 $f2.Uncommitted 'with nothing to point the author at'

# --- 3. THE NARROWNESS, which is the property that would break silently ------------------------
# Each of these is the ordinary state of a branch mid-flight. A gate firing on any of them is one
# nobody reads by the time it matters.
Write-Host "`n== 3. everything ordinary stays silent ==" -ForegroundColor Cyan
Assert-True ($null -eq (Get-BranchBackingFinding -Steps (New-Steps -Total 3 -Open 1 -Resolved 2) -Backing (New-Backing -Uncommitted 4))) 'a half-done plan is silent, however much is uncommitted'
Assert-True ($null -eq (Get-BranchBackingFinding -Steps (New-Steps -Total 0 -Open 0 -Resolved 0) -Backing (New-Backing -Uncommitted 4))) 'a document with no steps yet is silent'
Assert-True ($null -eq (Get-BranchBackingFinding -Steps (New-Steps -Total 3 -Open 0 -Resolved 3) -Backing (New-Backing -Committed 2 -Uncommitted 1))) 'a finished plan WITH work committed is silent -- the entry has content behind it'
Assert-True ($null -eq (Get-BranchBackingFinding -Steps (New-Steps -Total 3 -Open 0 -Resolved 3) -Backing (New-Backing -Committed 1))) 'one committed file is enough to be content'

# A plan whose steps were all DROPPED rather than done still counts as resolved -- that is the marks
# rule, and it is a legitimate finished plan, so the gate must judge it on its backing like any other.
Assert-True ([bool](Get-BranchBackingFinding -Steps (New-Steps -Total 2 -Open 0 -Resolved 2) -Backing (New-Backing -Uncommitted 1))) 'resolved-by-dropping is still a finished plan'

# --- 4. an unmeasured figure is not a measured zero --------------------------------------------
# CommittedKnown is $false on a checkout with no trunk ref -- configured differently, not defective.
# Reading that as "nothing is committed" would raise the alarm on every such repo.
Write-Host "`n== 4. not measured is never treated as zero ==" -ForegroundColor Cyan
Assert-True ($null -eq (Get-BranchBackingFinding -Steps (New-Steps -Total 3 -Open 0 -Resolved 3) -Backing (New-Backing -Committed 0 -CommittedKnown $false -Uncommitted 1))) 'an unmeasurable committed count raises nothing'
$f4 = Get-BranchBackingFinding -Steps (New-Steps -Total 3 -Open 0 -Resolved 3) -Backing (New-Backing -Committed 0 -Uncommitted 9 -UncommittedKnown $false)
Assert-True ([bool]$f4) 'an unmeasurable UNCOMMITTED count still leaves a finding -- nothing is committed, which is established'
Assert-Equal 'NotInThisCheckout' $f4.Kind 'and it degrades to the warning shape rather than refusing on a number it does not have'

# --- 5. the park note and the gate read the SAME condition -------------------------------------
# The whole reason this is a function. Two spellings over one tree is how a park that alarms and a
# gate that stays silent end up disagreeing, with nothing to say which is right.
Write-Host "`n== 5. one condition, both callers ==" -ForegroundColor Cyan
$libText = [System.IO.File]::ReadAllText($LibPath)
Assert-True ($libText -match 'function Get-BranchBackingFinding') 'the condition is a named function'
# THE VERDICT, not the prose. Both functions read $Backing.CommittedKnown -- Format- to choose its
# wording, Get-BranchBackingFinding to decide -- and that is two readers of one field, not two
# conditions. What must exist exactly once is the FINISHED test itself: total/open/resolved together.
Assert-Equal 1 ([regex]::Matches($libText, '\$open -eq 0').Count) 'the finished test is spelled exactly once in the lib'
Assert-True ($libText -match '\$finding = Get-BranchBackingFinding') 'and Format-GitParkBacking asks for it rather than repeating it'

$alarmed = Format-GitParkBacking -Steps (New-Steps -Total 3 -Open 0 -Resolved 3) -Backing (New-Backing -Committed 0 -Uncommitted 1)
Assert-True ($alarmed -match 'reads as FINISHED') 'the park note alarms on the shape the gate refuses'
Assert-True ($alarmed -match 'do not open a PR') 'and still tells that reader what not to do'
$quiet = Format-GitParkBacking -Steps (New-Steps -Total 3 -Open 1 -Resolved 2) -Backing (New-Backing -Committed 0 -Uncommitted 1)
Assert-True (-not ($quiet -match 'reads as FINISHED')) 'and stays quiet on the shape the gate lets through'

# --- 6. open-pr wires it in ---------------------------------------------------------------------
# The lib being right proves nothing about it being REACHED -- the lesson pr-issues-lib cost this repo.
Write-Host "`n== 6. open-pr.ps1 reaches the gate ==" -ForegroundColor Cyan
$openPr = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'scripts\release\open-pr.ps1'))
Assert-True ($openPr -match "lib\\park-lib\.ps1") 'open-pr dot-sources park-lib'
Assert-True ($openPr -match 'Get-BranchBackingFinding -Steps \$tally -Backing \$backing') 'it asks the shared condition'
# The CALL exactly once -- the name also appears in the comment above it, which is the point of the
# comment, so counting bare mentions would pin the prose instead of the wiring.
Assert-Equal 1 ([regex]::Matches($openPr, '\$backingFinding = Get-BranchBackingFinding').Count) 'called exactly once'
Assert-Equal 0 ([regex]::Matches($openPr, '\$tally\.Open -eq 0').Count) 'and open-pr does not re-spell the condition it just asked for'
Assert-True ($openPr -match 'backing gate: the plan reads as FINISHED') 'and refuses in words naming the state'
Assert-True ($openPr -match "NotInThisCheckout") 'the other kind is handled separately'

# THE VALVE, and that it is a valve rather than a bypass: -Force must WARN, not fall silent. A gate
# whose escape valve says nothing is a gate that quietly stopped existing.
$gateBlock = [regex]::Match($openPr, '(?s)if \(\$backingFinding\).*?\n        \}').Value
Assert-True ([bool]$gateBlock) 'the gate block is findable'
Assert-True ($gateBlock -match '\$Force') 'the refusal has a -Force valve'
Assert-True ($gateBlock -match 'but -Force was given') 'and the valve still says so out loud'
Assert-True ($gateBlock -match 'exit 1') 'the un-forced path stops the run'

# It must sit AFTER the step gate: a plan with open steps is refused there first, and reporting
# "your finished plan has nothing behind it" about an unfinished plan would be nonsense.
Assert-True ($openPr.IndexOf('step-list gate:') -lt $openPr.IndexOf('backing gate:')) 'the backing gate runs after the step-list gate'
# And BEFORE the push, which is the only placement that makes it a gate at all.
Assert-True ($openPr.IndexOf('backing gate:') -lt $openPr.IndexOf("'push', '-u', 'origin'")) 'and before the push'

# --- 7. the lib travels to the consumer ---------------------------------------------------------
Write-Host "`n== 7. mirrored into the plugin ==" -ForegroundColor Cyan
. (Join-Path $RepoRoot 'scripts\lib\shared-scripts-lib.ps1')
$pairs = @(Get-SharedScriptPairs -RepoRoot $RepoRoot)
foreach ($name in @('park-lib', 'open-pr')) {
    $pair = @($pairs | Where-Object { $_.Name -eq $name })
    Assert-Equal 1 $pair.Count "$name is registered exactly once"
    if ($pair.Count -eq 1) {
        Assert-True (Test-Path -LiteralPath $pair[0].MirrorPath) "$name's mirror exists in the plugin tree"
        $mir = [System.IO.File]::ReadAllText($pair[0].MirrorPath)
        Assert-True ($mir -match 'Get-BranchBackingFinding') "$name's mirror carries the new condition"
    }
}

Write-Host ''
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
