<#
.SYNOPSIS
    Regression tests for the PER-BRANCH name of the branch's development document (#1255) -- the naming
    itself, the predicate that recognises it, and the resolver that chooses between it and every name
    that came before.

.DESCRIPTION
    Dependency-free: no Pester needed, only PowerShell.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/branch-document-path.tests.ps1

    WHAT THIS SUITE EXISTS TO HOLD, because the change it guards reversed a decision. The document used
    to be one fixed path on every branch, on the argument that git tracks it per branch and a checkout
    swaps them. That is true of CHECKOUT and says nothing about MERGE: every merge to the trunk left
    every other open pull request conflicting on that one path, and a conflicting pull request gets no
    check suite at all -- so it could never go green and never merge. The naming is the repair.

    FOUR LAYERS, in the order a failure is most usefully diagnosed:

      1. Get-BranchFilePaths -- the name itself, with and without a branch. The no-branch arm is the
         back-compat arm and is asserted deliberately: several callers ask this function for the SHAPE
         of the layout and have no branch to give it.
      2. Test-IsPerBranchDocumentPath -- the predicate two lint checks read. It replaced a literal LIST
         in each of them, and a list cannot answer a pattern, so the failure it guards against is the
         silent one: every per-branch document falling out of both checks at once.
      3. Resolve-BranchFilePath -- the reader, against a real fixture tree. The exact-branch pass is the
         assert that matters most: it is what stops a trunk carrying several documents from handing the
         fold somebody else's entry, which is the stranding hazard reported on #1255.
      4. THE REGRESSION ITSELF -- two branches, two names, no collision. One assert, and it is the whole
         point of the change.

    Pure ASCII (repo convention for .ps1). Backticks in fixture headings are built from their codepoint,
    so no string literal here has to escape one.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1')

$script:pass = 0
$script:fail = 0
function Assert-Equal {
    param($Expected, $Actual, [string]$Label)
    if ("$Expected" -eq "$Actual") {
        $script:pass++
        Write-Host "  [PASS] $Label" -ForegroundColor DarkGreen
    } else {
        $script:fail++
        Write-Host "  [FAIL] $Label" -ForegroundColor Red
        Write-Host "         expected: '$Expected'" -ForegroundColor Red
        Write-Host "         actual  : '$Actual'" -ForegroundColor Red
    }
}
function Assert-True {
    param($Condition, [string]$Label)
    if ($Condition) {
        $script:pass++
        Write-Host "  [PASS] $Label" -ForegroundColor DarkGreen
    } else {
        $script:fail++
        Write-Host "  [FAIL] $Label" -ForegroundColor Red
    }
}

$BT = [char]96
function New-BranchDoc {
    # The smallest document the declare-test recognises: an opening heading naming its branch.
    param([string]$Path, [string]$Branch)
    $heading = '# Development: ' + $BT + $Branch + $BT + ' * 20260903-000000'
    $lines = @($heading, '', '### PLAN', '', '### DEPLOY: ' + $BT + $Branch + $BT, '')
    [System.IO.File]::WriteAllText($Path, ($lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
}

Write-Host "layer 1 -- the name carries the branch"
$p = Get-BranchFilePaths -Branch 'fix/thing-v1'
Assert-Equal 'contributing-davekjohn/development-fix-thing-v1.md' $p.File 'a branch gets a document named after it, slashes flattened'
Assert-Equal $p.File $p.Cycle      'Cycle answers the same document'
Assert-Equal $p.File $p.Deployment 'and so does Deployment -- two jobs, one file'
Assert-Equal 'contributing-davekjohn/development.md' $p.SharedFile 'SharedFile is the pre-#1255 name, which is read and never written'
Assert-Equal 'development-*.md' $p.Pattern 'and the pattern every per-branch document matches'
# THE NO-BRANCH ARM IS BACK-COMPAT AND IS ASSERTED ON PURPOSE. Callers that want the layout's shape --
# the directory, the sweep list -- have no branch to offer, and making the parameter mandatory would have
# forced a branch lookup into every one of them.
$n = Get-BranchFilePaths
Assert-Equal 'contributing-davekjohn/development.md' $n.File 'omitting the branch answers the shared name, unchanged from before #1255'
Assert-Equal 'contributing-davekjohn' $n.Directory 'the directory is the same either way'
# A branch name is the only thing here that can carry a path separator; Windows forbids the rest.
Assert-Equal 'contributing-davekjohn/development-feat-a-b-c.md' (Get-BranchFilePaths -Branch 'feat/a/b/c').File 'every slash is flattened, not only the first'

Write-Host ""
Write-Host "layer 2 -- the predicate the two lint checks read"
Assert-True (Test-IsPerBranchDocumentPath -RelativePath 'contributing-davekjohn/development-fix-x-v1.md') 'a per-branch document is recognised'
Assert-True (Test-IsPerBranchDocumentPath -RelativePath '\contributing-davekjohn\development-fix-x-v1.md') 'separators are normalised -- one check builds its path from a Windows path, the other from the seam'
Assert-True (Test-IsPerBranchDocumentPath -RelativePath './contributing-davekjohn/development-fix-x-v1.md') 'and a leading ./ does not hide it'
Assert-True (-not (Test-IsPerBranchDocumentPath -RelativePath 'contributing-davekjohn/development.md')) 'the shared name is NOT a per-branch one -- each caller still lists that itself'
Assert-True (-not (Test-IsPerBranchDocumentPath -RelativePath 'contributing-davekjohn/CHANGELOG.md')) 'a neighbour in the same folder is not swept in'
Assert-True (-not (Test-IsPerBranchDocumentPath -RelativePath 'docs/development-x.md')) 'and neither is a same-named file elsewhere in the tree'
Assert-True (-not (Test-IsPerBranchDocumentPath -RelativePath '')) 'an empty path is not a document'

Write-Host ""
Write-Host "layer 3 -- the resolver, against a real tree"
$fx = Join-Path ([System.IO.Path]::GetTempPath()) ("bdp-" + [guid]::NewGuid().ToString('N'))
$fxDir = Join-Path $fx 'contributing-davekjohn'
$null = New-Item -ItemType Directory -Path $fxDir -Force
try {
    $mine  = Join-Path $fxDir 'development-fix-mine-v1.md'
    $other = Join-Path $fxDir 'development-fix-other-v1.md'
    $shared = Join-Path $fxDir 'development.md'

    # Nothing written yet: a writer must be sent to the name it should CREATE, not to a path that exists.
    Assert-Equal 'contributing-davekjohn/development-fix-mine-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/mine-v1') `
        'an empty tree sends the caller to this branch own name'

    New-BranchDoc -Path $mine -Branch 'fix/mine-v1'
    Assert-Equal 'contributing-davekjohn/development-fix-mine-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/mine-v1') `
        'the branch own document is found'

    # THE ASSERT THIS SUITE EXISTS FOR. A trunk carrying several documents is the state a run of blocked
    # folds leaves behind. Before the exact-branch pass the resolver returned whichever declared ANY
    # non-trunk branch -- on that trunk, whichever sorted first -- and the fold would then fold somebody
    # else's entry under this branch's name. That is the stranding hazard reported on #1255.
    New-BranchDoc -Path $other -Branch 'fix/other-v1'
    Assert-Equal 'contributing-davekjohn/development-fix-mine-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/mine-v1') `
        'with another branch document beside it, the exact branch still wins'
    Assert-Equal 'contributing-davekjohn/development-fix-other-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/other-v1') `
        'and the other branch gets its own, from the same tree'

    # A branch RENAMED after its document was written declares its old name. Refusing to see it would
    # strand exactly the half-finished work the dual-read exists to protect, so the any-branch pass stays.
    Remove-Item -LiteralPath $mine -Force
    Assert-Equal 'contributing-davekjohn/development-fix-other-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/renamed-v1') `
        'no document names this branch, so one naming A branch is still found -- the renamed-branch case'

    # THE MIGRATION ARM. Every branch open on the day of the change is working in the shared name, and it
    # has to keep resolving or its entry is stranded unfolded.
    Remove-Item -LiteralPath $other -Force
    New-BranchDoc -Path $shared -Branch 'fix/inflight-v1'
    Assert-Equal 'contributing-davekjohn/development.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/inflight-v1') `
        'a branch still on the pre-#1255 shared name resolves to it'

    # A document declaring the TRUNK is a reset leftover and claims no branch, so neither pass accepts it.
    # What answers then is the resolver's documented last resort -- PREFER A PATH THAT EXISTS over one that
    # does not, so a reader opening the result finds the reset document rather than a missing file. That
    # behaviour predates #1255 and is deliberately unchanged; park-cycle depends on it to report 'in its
    # reset state' instead of 'nothing to park'. Asserted here so a later reading of the fallback as a bug
    # has to argue with a test rather than with a comment.
    Remove-Item -LiteralPath $shared -Force
    New-BranchDoc -Path $shared -Branch (Get-BranchTrunkName)
    Assert-Equal 'contributing-davekjohn/development.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/mine-v1') `
        'a trunk-declaring leftover claims no branch, so the reader is sent to the file that at least exists'

    # THE READER ARM resolves against a tree the caller is not standing in -- ship-pr judging a commit.
    # It deliberately does NOT default to HEAD, so the branch has to be handed in; without it the shared
    # name would be answered and this branch's document missed silently, which is the dangerous direction.
    Remove-Item -LiteralPath $shared -Force
    $readerDocs = @{ 'contributing-davekjohn/development-fix-mine-v1.md' = ('# Development: ' + $BT + 'fix/mine-v1' + $BT) }
    $reader = {
        param([string]$Rel)
        if ($readerDocs.ContainsKey($Rel)) { return $readerDocs[$Rel] }
        return $null
    }
    Assert-Equal 'contributing-davekjohn/development-fix-mine-v1.md' `
        (Resolve-BranchFilePath -Kind Cycle -Reader $reader -Branch 'fix/mine-v1') `
        'the Reader arm finds the per-branch document when the caller names the branch'
}
finally {
    Remove-Item -LiteralPath $fx -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "layer 4 -- the regression itself"
# ONE ASSERT, AND IT IS THE WHOLE CHANGE. Two branches, two paths: a merge of one cannot conflict the
# other on this document, which is what left every open pull request without a check suite.
$a = (Get-BranchFilePaths -Branch 'fix/first-v1').File
$b = (Get-BranchFilePaths -Branch 'fix/second-v1').File
Assert-True ($a -ne $b) 'two branches never write the same path -- the collision #1255 measured cannot happen'

Write-Host ""
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
