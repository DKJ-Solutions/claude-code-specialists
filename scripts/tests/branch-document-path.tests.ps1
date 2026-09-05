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
    # The smallest document the declare-test recognises, in TODAY's shape (#1335): an opening heading
    # that is the branch name and nothing else, and a DEPLOY heading carrying the title word.
    param([string]$Path, [string]$Branch)
    $lines = @('## ' + $Branch, '', '### PLAN', '', '### DEPLOY: ' + $Branch, '')
    [System.IO.File]::WriteAllText($Path, ($lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
}
function New-LegacyBranchDoc {
    # The pre-#1335 shape: a title word, the branch in backticks, and the creation stamp. Every branch
    # open on the day of that change carries one, here and in every consumer, so the reader must keep
    # recognising it.
    param([string]$Path, [string]$Branch)
    $heading = '## Development: ' + $BT + $Branch + $BT + ' * 20260903-000000'
    $lines = @($heading, '', '### PLAN', '', '### DEPLOY: ' + $BT + $Branch + $BT, '')
    [System.IO.File]::WriteAllText($Path, ($lines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
}

Write-Host "layer 1 -- the name IS the branch"
$p = Get-BranchFilePaths -Branch 'fix/thing-v1'
Assert-Equal 'dkj-policy/fix-thing-v1.md' $p.File 'a branch gets a document named after it, slashes flattened and nothing else'
Assert-Equal $p.File $p.Cycle      'Cycle answers the same document'
Assert-Equal $p.File $p.Deployment 'and so does Deployment -- two jobs, one file'
Assert-Equal 'dkj-policy/development-fix-thing-v1.md' $p.PriorPerBranchFile 'the pre-#1335 prefixed name is read and never written'
Assert-Equal 'dkj-policy/development.md' $p.SharedFile 'SharedFile is the pre-#1255 name, which is read and never written'
Assert-Equal '*.md' $p.Pattern 'and the pattern every per-branch document matches -- widened with the prefix gone'
Assert-True (@($p.ReservedNames) -contains 'CHANGELOG.md') 'the widened pattern comes with the exclusion that makes it safe'
# THE NO-BRANCH ARM IS BACK-COMPAT AND IS ASSERTED ON PURPOSE. Callers that want the layout's shape --
# the directory, the sweep list -- have no branch to offer, and making the parameter mandatory would have
# forced a branch lookup into every one of them.
$n = Get-BranchFilePaths
Assert-Equal 'dkj-policy/development.md' $n.File 'omitting the branch answers the shared name, unchanged from before #1255'
Assert-Equal 'dkj-policy' $n.Directory 'the directory is the same either way'
Assert-Equal '' $n.PriorPerBranchFile 'and it names no prefixed predecessor, because there is no branch to build one from'
# A branch name is the only thing here that can carry a path separator; Windows forbids the rest.
Assert-Equal 'dkj-policy/feat-a-b-c.md' (Get-BranchFilePaths -Branch 'feat/a/b/c').File 'every slash is flattened, not only the first'
# THE LEGACY LIST IS ORDERED NEWEST-PREDECESSOR FIRST, and since #1335 its first entry is branch-dependent
# -- which is why it takes -Branch at all. A caller that omits it simply gets the constants.
$legacy = @(Get-BranchFileLegacyNames -Kind 'Cycle' -Branch 'fix/thing-v1')
Assert-Equal 'dkj-policy/development-fix-thing-v1.md' $legacy[0] 'the newest predecessor leads the legacy list'
Assert-Equal 'dkj-policy/development.md' $legacy[1] 'and the pre-#1255 shared name follows it'
Assert-True (@(Get-BranchFileLegacyNames -Kind 'Cycle') -notcontains 'dkj-policy/development-.md') 'omitting the branch never fabricates a prefixed name'

# THE PRE-#1437 FOLDER IS IN THE LIST, AND ITS PER-BRANCH NAME IS THE ONE THAT MATTERS (September 5, 2026).
# The folder rename before this one landed while the document was still one shared file, so PriorFolder*
# needed only 'development-cycle.md' and the branch/ pair. This one lands three days after #1255/#1335, so
# a branch stranded in the old folder is carrying 'contributing-davekjohn/<slug>.md' -- a name that exists
# in every open branch and every consumer on the day of the change. Asserted by MEMBERSHIP rather than by
# index: the position is a preference the declare-test overrides, and pinning it would turn a reordering
# into a failure without anything being broken.
$legacyContrib = @(Get-BranchFileLegacyNames -Kind 'Cycle' -Branch 'fix/thing-v1')
Assert-True ($legacyContrib -contains 'contributing-davekjohn/fix-thing-v1.md') 'the pre-#1437 folder''s per-branch name is read'
Assert-True ($legacyContrib -contains 'contributing-davekjohn/development.md') 'and so is its pre-#1255 shared name'
Assert-True ($legacyContrib -contains 'contributing-davekjohn/development-cycle.md') 'and its pre-#963 filename'
Assert-True ($legacyContrib -contains 'contributing-davekjohn/branch/branch-cycle.md') 'and its branch/ pair, on the Cycle arm'
Assert-True (@(Get-BranchFileLegacyNames -Kind 'Deployment' -Branch 'fix/thing-v1') -contains 'contributing-davekjohn/branch/branch-deployment.md') 'and the Deployment arm reads the Deployment-named one'
Assert-True ($legacyContrib -contains 'workflow-davekjohn/development-cycle.md') 'the pre-#886 folder is still read, so a rename never drops the one before it'
Assert-True (@(Get-BranchFileLegacyNames -Kind 'Cycle') -notcontains 'contributing-davekjohn/.md') 'omitting the branch fabricates no per-branch name in the old folder either'

Write-Host ""
Write-Host "layer 2 -- the predicate the two lint checks read"
Assert-True (Test-IsPerBranchDocumentPath -RelativePath 'dkj-policy/fix-x-v1.md') 'a per-branch document is recognised'
Assert-True (Test-IsPerBranchDocumentPath -RelativePath '\dkj-policy\fix-x-v1.md') 'separators are normalised -- one check builds its path from a Windows path, the other from the seam'
Assert-True (Test-IsPerBranchDocumentPath -RelativePath './dkj-policy/fix-x-v1.md') 'and a leading ./ does not hide it'
Assert-True (Test-IsPerBranchDocumentPath -RelativePath 'dkj-policy/development-fix-x-v1.md') 'the pre-#1335 prefixed name still matches, so a branch open across the rename keeps its exclusions'
# THE SHARED NAME FALLS INSIDE THE PATTERN SINCE #1335, where the prefixed glob excluded it, and that is
# accepted rather than special-cased back out. It is a branch development document -- the pre-#1255 one --
# and both callers of this predicate use it to exempt exactly that kind of file; both also list the shared
# name themselves, so nothing downstream changes either way. Asserted so the widening is a decision on the
# record rather than a side effect nobody noticed.
Assert-True (Test-IsPerBranchDocumentPath -RelativePath 'dkj-policy/development.md') 'the pre-#1255 shared name now falls inside the pattern too, which costs nothing at either caller'
Assert-True (-not (Test-IsPerBranchDocumentPath -RelativePath 'docs/fix-x-v1.md')) 'a same-named file elsewhere in the tree is not swept in'
Assert-True (-not (Test-IsPerBranchDocumentPath -RelativePath '')) 'an empty path is not a document'
# THE THREE PERMANENT PAGES, and this is the half the widened pattern made necessary. Both callers use this
# predicate to EXEMPT a file from a check, so a wrong true is silence rather than noise.
foreach ($reserved in @('CHANGELOG.md', 'README.md', 'CONTRIBUTING.md')) {
    Assert-True (-not (Test-IsPerBranchDocumentPath -RelativePath "dkj-policy/$reserved")) "the folder's own $reserved is not a branch document"
}
# THE SUBDIRECTORY, MEASURED RATHER THAN IMAGINED. '*' in -like matches a '/' like any other character, so
# the anchored form 'dkj-policy/*.md' also matched 'dkj-policy/releases/history.md'
# -- which then resolved its links from the wrong base and reported 26 of them dead. Caught by the lint gate
# on this change's first run.
Assert-True (-not (Test-IsPerBranchDocumentPath -RelativePath 'dkj-policy/releases/history.md')) 'a file in a SUBDIRECTORY of the folder is not a branch document'
Assert-True (-not (Test-IsPerBranchDocumentPath -RelativePath 'dkj-policy/releases/audience/4.x/4.0.0.md')) 'and neither is one further down'

Write-Host ""
Write-Host "layer 3 -- the resolver, against a real tree"
$fx = Join-Path ([System.IO.Path]::GetTempPath()) ("bdp-" + [guid]::NewGuid().ToString('N'))
$fxDir = Join-Path $fx 'dkj-policy'
$null = New-Item -ItemType Directory -Path $fxDir -Force
try {
    $mine   = Join-Path $fxDir 'fix-mine-v1.md'
    $other  = Join-Path $fxDir 'fix-other-v1.md'
    $prior  = Join-Path $fxDir 'development-fix-inflight-v1.md'
    $shared = Join-Path $fxDir 'development.md'

    # Nothing written yet: a writer must be sent to the name it should CREATE, not to a path that exists.
    Assert-Equal 'dkj-policy/fix-mine-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/mine-v1') `
        'an empty tree sends the caller to this branch own name'

    New-BranchDoc -Path $mine -Branch 'fix/mine-v1'
    Assert-Equal 'dkj-policy/fix-mine-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/mine-v1') `
        'the branch own document is found'

    # THE ASSERT THIS SUITE EXISTS FOR. A trunk carrying several documents is the state a run of blocked
    # folds leaves behind. Before the exact-branch pass the resolver returned whichever declared ANY
    # non-trunk branch -- on that trunk, whichever sorted first -- and the fold would then fold somebody
    # else's entry under this branch's name. That is the stranding hazard reported on #1255.
    New-BranchDoc -Path $other -Branch 'fix/other-v1'
    Assert-Equal 'dkj-policy/fix-mine-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/mine-v1') `
        'with another branch document beside it, the exact branch still wins'
    Assert-Equal 'dkj-policy/fix-other-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/other-v1') `
        'and the other branch gets its own, from the same tree'

    # THE DESTRUCTIVE DIRECTION OF #1335, and the reason ReservedNames exists. A changelog is full of folded
    # DEPLOY headings, so it DECLARES a branch by every test in this lib. Swept in, it would be handed to the
    # fold as this branch's document -- and the fold moves the document into the changelog and then deletes
    # it. The exclusion is what stops the sweep reaching it; this assert is what stops the exclusion being
    # tidied away later.
    [System.IO.File]::WriteAllText((Join-Path $fxDir 'CHANGELOG.md'),
        "# Changelog`r`n`r`n## [Unreleased]`r`n`r`n### DEPLOY: fix/already-folded-v1 * 20260903-101010`r`n`r`nbody`r`n",
        (New-Object System.Text.UTF8Encoding($false)))
    Assert-Equal 'dkj-policy/fix-mine-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/mine-v1') `
        'a changelog full of folded entries is never mistaken for a branch document'
    # The any-branch pass takes the first candidate declaring A branch, and the sweep is sorted -- so
    # 'CHANGELOG.md' would come before every real document if it were in the sweep at all. It is not, so
    # what answers is a real one. The assert is on what it is NOT, because which of the two real documents
    # wins is the renamed-branch behaviour asserted a few lines down and not this test's subject.
    Assert-True ((Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/nothing-here-v1') -ne 'dkj-policy/CHANGELOG.md') `
        'and a branch with no document of its own is not handed the changelog by the any-branch pass'

    # A branch RENAMED after its document was written declares its old name. Refusing to see it would
    # strand exactly the half-finished work the dual-read exists to protect, so the any-branch pass stays.
    Remove-Item -LiteralPath $mine -Force
    Assert-Equal 'dkj-policy/fix-other-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/renamed-v1') `
        'no document names this branch, so one naming A branch is still found -- the renamed-branch case'
    Remove-Item -LiteralPath $other -Force

    # THE #1335 MIGRATION ARM. Every branch open on the day of the change is working in the prefixed name,
    # and it has to keep resolving or its entry is stranded unfolded. The document is in the LEGACY shape
    # too, headings and all, because that is what such a branch actually carries.
    New-LegacyBranchDoc -Path $prior -Branch 'fix/inflight-v1'
    Assert-Equal 'dkj-policy/development-fix-inflight-v1.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/inflight-v1') `
        'a branch still on the pre-#1335 prefixed name resolves to it'
    Remove-Item -LiteralPath $prior -Force

    # THE #1255 MIGRATION ARM, unchanged: the shared name, one rename further back.
    New-LegacyBranchDoc -Path $shared -Branch 'fix/older-v1'
    Assert-Equal 'dkj-policy/development.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/older-v1') `
        'a branch still on the pre-#1255 shared name resolves to it'

    # A document declaring the TRUNK is a reset leftover and claims no branch, so neither pass accepts it.
    # What answers then is the resolver's documented last resort -- PREFER A PATH THAT EXISTS over one that
    # does not, so a reader opening the result finds the reset document rather than a missing file. That
    # behaviour predates #1255 and is deliberately unchanged; park-cycle depends on it to report 'in its
    # reset state' instead of 'nothing to park'. Asserted here so a later reading of the fallback as a bug
    # has to argue with a test rather than with a comment.
    Remove-Item -LiteralPath $shared -Force
    New-BranchDoc -Path $shared -Branch (Get-BranchTrunkName)
    Assert-Equal 'dkj-policy/development.md' `
        (Resolve-BranchFilePath -Kind Deployment -RepoRoot $fx -Branch 'fix/mine-v1') `
        'a trunk-declaring leftover claims no branch, so the reader is sent to the file that at least exists'

    # THE READER ARM resolves against a tree the caller is not standing in -- ship-pr judging a commit.
    # It deliberately does NOT default to HEAD, so the branch has to be handed in; without it the shared
    # name would be answered and this branch's document missed silently, which is the dangerous direction.
    # IT CANNOT SWEEP A DIRECTORY, which is why the prefixed predecessor is NAMED in the legacy list rather
    # than left to the Pattern -- the second assert here is that half.
    Remove-Item -LiteralPath $shared -Force
    $readerDocs = @{ 'dkj-policy/fix-mine-v1.md' = '## fix/mine-v1' }
    $reader = {
        param([string]$Rel)
        if ($readerDocs.ContainsKey($Rel)) { return $readerDocs[$Rel] }
        return $null
    }
    Assert-Equal 'dkj-policy/fix-mine-v1.md' `
        (Resolve-BranchFilePath -Kind Cycle -Reader $reader -Branch 'fix/mine-v1') `
        'the Reader arm finds the per-branch document when the caller names the branch'
    $readerDocs = @{ 'dkj-policy/development-fix-mine-v1.md' = ('## Development: ' + $BT + 'fix/mine-v1' + $BT) }
    Assert-Equal 'dkj-policy/development-fix-mine-v1.md' `
        (Resolve-BranchFilePath -Kind Cycle -Reader $reader -Branch 'fix/mine-v1') `
        'and it finds the pre-#1335 name too, which only the named candidate can reach on this arm'
}
finally {
    Remove-Item -LiteralPath $fx -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "layer 4 -- the sweep, and what it refuses to see"
$sx = Join-Path ([System.IO.Path]::GetTempPath()) ("bdp-sweep-" + [guid]::NewGuid().ToString('N'))
$sxDir = Join-Path $sx 'dkj-policy'
$null = New-Item -ItemType Directory -Path $sxDir -Force
$null = New-Item -ItemType Directory -Path (Join-Path $sxDir 'releases') -Force
try {
    $enc = New-Object System.Text.UTF8Encoding($false)
    foreach ($name in @('CHANGELOG.md', 'README.md', 'CONTRIBUTING.md')) {
        [System.IO.File]::WriteAllText((Join-Path $sxDir $name), "# $name`r`n", $enc)
    }
    [System.IO.File]::WriteAllText((Join-Path $sxDir 'releases\history.md'), "# History`r`n", $enc)
    New-BranchDoc -Path (Join-Path $sxDir 'feat-one-v1.md') -Branch 'feat/one-v1'
    New-LegacyBranchDoc -Path (Join-Path $sxDir 'development-feat-two-v1.md') -Branch 'feat/two-v1'

    $swept = @(Get-PerBranchDocumentRels -RepoRoot $sx)
    Assert-Equal 2 $swept.Count 'the sweep sees both branch documents and none of the permanent pages'
    Assert-True ($swept -contains 'dkj-policy/feat-one-v1.md') 'today name is swept'
    Assert-True ($swept -contains 'dkj-policy/development-feat-two-v1.md') 'and so is the pre-#1335 one, at no extra cost'
    Assert-Equal 0 @(Get-PerBranchDocumentRels -RepoRoot (Join-Path $sx 'nowhere')).Count 'a tree with no workflow folder answers empty rather than throwing'
}
finally {
    Remove-Item -LiteralPath $sx -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "layer 5 -- the regression itself"
# ONE ASSERT, AND IT IS THE WHOLE OF #1255. Two branches, two paths: a merge of one cannot conflict the
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
