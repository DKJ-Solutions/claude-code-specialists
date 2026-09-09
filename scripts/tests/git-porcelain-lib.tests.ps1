<#
.SYNOPSIS
    Tests for scripts/lib/git-porcelain-lib.ps1 -- the one reading of `git status --porcelain` (issue
    #1682): the line parse, and the read that wraps it.

.DESCRIPTION
    THE LINE PARSE IS TESTED AS A TABLE, because that is what it is. ConvertFrom-GitPorcelainLine takes a
    string and returns an object or $null, with no I/O of its own, so every git quirk the lib was
    extracted to own can be stated as one line of porcelain output and its expected reading. That is also
    the half a fixture repo cannot reach: producing a rename, an accented path and an unmerged entry on
    demand in a real repo is several commits of setup for cases that are, in the end, string handling.

    THE TWO CALLERS' OWN USES ARE ASSERTED HERE TOO, and not only in their suites. park-lib wants a COUNT
    with a pathspec excluded and ignores From; fanout-lib wants a MAP keyed on the new path and depends on
    From. Both are one line each against the parse's output, and they are what would go red if a later
    tidy-up decided the rename's old path was surplus again -- which is exactly the divergence #1682 was
    filed about, arriving from the other direction.

    IT USES NO FIXTURE REPO AND NO TEMP DIRECTORY, deliberately. The parse needs none, and the two
    Get-GitPorcelainStatus cases are read-only: this repo itself for the success path, and a directory
    that is not a repository for the failure path. That keeps the suite out of the predictable-temp-path
    class issue #1664 is closing (108 composed paths, 53 of them opening with a recursive delete) instead
    of adding a 109th to it while that work is in flight.

    THE SUCCESS PATH ASSERTS SHAPE, NOT CONTENT. Read against this repo, the entry list is whatever the
    working copy happens to hold -- which during a branch is a moving target and on a clean trunk is
    empty. So the assert is that Known is true and that every entry that came back parses into the four
    fields with a non-empty Path, which is true of both.

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibPath  = Join-Path $RepoRoot 'scripts\lib\git-porcelain-lib.ps1'

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
function Assert-Null {
    param($Actual, [string]$Label)
    if ($null -eq $Actual) { $script:pass++; Write-Host "  [PASS] $Label" -ForegroundColor Green }
    else { $script:fail++; Write-Host "  [FAIL] $Label`n         expected: `$null`n         got:      '$Actual'" -ForegroundColor Red }
}

Assert-True (Test-Path -LiteralPath $LibPath) 'git-porcelain-lib.ps1 exists at its registered source path'
. (Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1')
. $LibPath

Write-Host ''
Write-Host 'ConvertFrom-GitPorcelainLine -- the status halves' -ForegroundColor Cyan

# ' M path': index clean, worktree modified. The two columns are what separate a recoverable `git reset`
# from a destructive `git checkout -- <path>`, which is why they never come back as one string.
$e = ConvertFrom-GitPorcelainLine -Line ' M scripts/lib/park-lib.ps1'
Assert-Equal 'scripts/lib/park-lib.ps1' $e.Path 'worktree-modified: the path'
Assert-Equal ' ' $e.Index 'worktree-modified: the index half is a space, not trimmed away'
Assert-Equal 'M' $e.Worktree 'worktree-modified: the worktree half'
Assert-Equal '' $e.From 'worktree-modified: From is empty, not $null'

$e = ConvertFrom-GitPorcelainLine -Line 'M  scripts/lib/park-lib.ps1'
Assert-Equal 'M' $e.Index 'staged: the index half'
Assert-Equal ' ' $e.Worktree 'staged: the worktree half is a space'

$e = ConvertFrom-GitPorcelainLine -Line 'MM a.txt'
Assert-Equal 'M' $e.Index 'staged AND modified again: index half'
Assert-Equal 'M' $e.Worktree 'staged AND modified again: worktree half'

$e = ConvertFrom-GitPorcelainLine -Line '?? new/file.txt'
Assert-Equal '?' $e.Index 'untracked: both halves are the question mark'
Assert-Equal '?' $e.Worktree 'untracked: both halves are the question mark (worktree)'

# An unmerged path. Neither caller acts on 'U' today, and the parse must not swallow it: a conflict is
# outstanding work for park-lib's count and a live entry for fanout-lib's map.
$e = ConvertFrom-GitPorcelainLine -Line 'UU conflicted.txt'
Assert-Equal 'conflicted.txt' $e.Path 'unmerged: the path survives'
Assert-Equal 'U' $e.Index 'unmerged: index half'
Assert-Equal 'U' $e.Worktree 'unmerged: worktree half'

Write-Host ''
Write-Host 'ConvertFrom-GitPorcelainLine -- the rename, which is lesson 3' -ForegroundColor Cyan

# THE CASE THE LIB EXISTS FOR. park-lib's copy discarded the old path and fanout-lib's kept it; keeping
# it is what stops an ordinary `git mv` inside a snapshot window from reading as a lost edit.
$e = ConvertFrom-GitPorcelainLine -Line 'R  old/name.txt -> new/name.txt'
Assert-Equal 'new/name.txt' $e.Path 'rename: Path is the NEW path, the one that exists on disk'
Assert-Equal 'old/name.txt' $e.From 'rename: From is the OLD path, kept rather than discarded'
Assert-Equal 'R' $e.Index 'rename: index half'

# Quoted on both sides -- what core.quotePath produces once a path needs escaping. The quotes come off
# both halves, or the map keys on a path with a stray quote and no comparison ever matches.
$e = ConvertFrom-GitPorcelainLine -Line 'R  "old name.txt" -> "new name.txt"'
Assert-Equal 'new name.txt' $e.Path 'rename, quoted: the surrounding quotes come off the new path'
Assert-Equal 'old name.txt' $e.From 'rename, quoted: and off the old path'

# A copy detection line reads the same way. Asserted so the arrow split is not read as rename-only.
$e = ConvertFrom-GitPorcelainLine -Line 'C  a.txt -> b.txt'
Assert-Equal 'b.txt' $e.Path 'copy: the arrow split is not rename-specific'
Assert-Equal 'a.txt' $e.From 'copy: From carries the source'

Write-Host ''
Write-Host 'ConvertFrom-GitPorcelainLine -- quoting and separators' -ForegroundColor Cyan

$e = ConvertFrom-GitPorcelainLine -Line ' M "path with spaces.txt"'
Assert-Equal 'path with spaces.txt' $e.Path 'quoted path: quotes stripped, inner spaces kept'

# core.quotePath escapes a non-ASCII byte rather than emitting it, which is the whole point of lesson 2:
# the escape sequence is ASCII and every candidate code page agrees on it. The parse must leave it
# alone -- decoding it would put the guess back that the flag exists to remove.
$e = ConvertFrom-GitPorcelainLine -Line ' M "caf\303\251.txt"'
Assert-Equal 'caf\303\251.txt' $e.Path 'quoted non-ASCII: the escape is carried through, not decoded'

$e = ConvertFrom-GitPorcelainLine -Line ' M scripts\lib\park-lib.ps1'
Assert-Equal 'scripts/lib/park-lib.ps1' $e.Path 'backslashes are normalised to forward slashes'

$e = ConvertFrom-GitPorcelainLine -Line 'R  old\name.txt -> new\name.txt'
Assert-Equal 'new/name.txt' $e.Path 'rename: the new path is normalised'
Assert-Equal 'old/name.txt' $e.From 'rename: and so is the old one -- both halves get compared'

Write-Host ''
Write-Host 'ConvertFrom-GitPorcelainLine -- the lines that carry no path' -ForegroundColor Cyan

# $null rather than an object with an empty Path, so a caller's loop can `continue` on the falsy result
# without knowing which of the two guards fired.
Assert-Null (ConvertFrom-GitPorcelainLine -Line '') 'the empty line the trailing newline produces'
Assert-Null (ConvertFrom-GitPorcelainLine -Line $null) 'a $null line'
Assert-Null (ConvertFrom-GitPorcelainLine -Line ' M ') 'three characters: no path to read'
Assert-Null (ConvertFrom-GitPorcelainLine -Line ' M  ') 'a path that is empty once trimmed'
Assert-Null (ConvertFrom-GitPorcelainLine -Line ' M ""') 'a path that is empty once unquoted'

Write-Host ''
Write-Host "What each caller does with the parse -- park-lib's count" -ForegroundColor Cyan

# park-lib's own shape: a skip map keyed on forward-slashed paths, and a count. It ignores From, so a
# rename is one outstanding path whichever name it is counted under.
$lines = @(
    ' M dkj-policy/fix-1682-porcelain-line-parse.md',
    ' M scripts/lib/park-lib.ps1',
    'R  old.txt -> new.txt'
)
$skip = @{ 'dkj-policy/fix-1682-porcelain-line-parse.md' = $true }
$count = 0
foreach ($line in $lines) {
    $p = ConvertFrom-GitPorcelainLine -Line $line
    if (-not $p) { continue }
    if ($skip.ContainsKey($p.Path)) { continue }
    $count++
}
Assert-Equal 2 $count 'the excluded path is not counted, and a rename counts once'

# And the exclusion still matches when the caller holds the path with backslashes, which is what the
# normalisation in the lib buys: park-lib's own map is normalised on the way in for the same reason.
$skip = @{ 'scripts/lib/park-lib.ps1' = $true }
$p = ConvertFrom-GitPorcelainLine -Line ' M scripts\lib\park-lib.ps1'
Assert-True ($skip.ContainsKey($p.Path)) 'a backslashed line still matches a forward-slashed exclusion'

Write-Host ''
Write-Host "What each caller does with the parse -- fanout-lib's map" -ForegroundColor Cyan

$entries = @{}
foreach ($line in @(' M a.txt', 'R  was.txt -> is.txt')) {
    $p = ConvertFrom-GitPorcelainLine -Line $line
    if (-not $p) { continue }
    $entries[$p.Path] = [pscustomobject]@{ Index = $p.Index; Worktree = $p.Worktree; From = $p.From }
}
Assert-Equal 2 $entries.Count 'two entries, keyed on the path that exists on disk'
Assert-True ($entries.ContainsKey('is.txt')) 'the rename is keyed on its NEW path'
Assert-Equal 'was.txt' $entries['is.txt'].From 'and the map can still follow the file back to its old name'
Assert-True (-not ($entries.ContainsKey('was.txt'))) 'the old name is not a second key'

Write-Host ''
Write-Host 'Get-GitPorcelainStatus -- the read around it' -ForegroundColor Cyan

$st = Get-GitPorcelainStatus -RepoRoot $RepoRoot
Assert-True ([bool]$st.Known) 'this repo can be read: Known is true'
Assert-True ($null -ne $st.Entries) 'Entries is always present, even when nothing is outstanding'
# Shape, not content: what the working copy holds during a branch is a moving target.
$badEntry = @($st.Entries) | Where-Object {
    -not $_.Path -or
    $null -eq $_.Index -or $null -eq $_.Worktree -or $null -eq $_.From -or
    $_.Index.Length -ne 1 -or $_.Worktree.Length -ne 1
} | Select-Object -First 1
Assert-Null $badEntry 'every entry read from this repo carries a path and two single-character halves'

# THE FAILURE PATH, WHICH IS NOT AN EMPTY LIST. A directory outside any repository: git exits non-zero,
# so Known must be false rather than reporting a clean working copy.
$notARepo = [Environment]::GetFolderPath('Windows')
if (-not $notARepo) { $notARepo = $env:SystemRoot }
$st = Get-GitPorcelainStatus -RepoRoot $notARepo
Assert-True (-not $st.Known) 'a directory outside any repository reports Known false'
Assert-Equal 0 (@($st.Entries).Count) '...and hands back no entries rather than a guess'

Write-Host ''
Write-Host 'The callers actually dot-source it -- the structural half' -ForegroundColor Cyan

# The lib is correct and unreachable if a caller still carries its own parse. Asserted on the source
# text, because this is the duplication #1682 was filed about and the suite is where its return would
# be caught.
foreach ($caller in @('park-lib', 'fanout-lib')) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot "scripts\lib\$caller.ps1") -Raw
    Assert-True ($text -match "git-porcelain-lib\.ps1") "$caller dot-sources git-porcelain-lib.ps1"
    Assert-True ($text -match 'Get-GitPorcelainStatus') "$caller calls Get-GitPorcelainStatus"
    Assert-True ($text -notmatch "status',\s*'--porcelain'") "$caller no longer spawns its own porcelain read"
    Assert-True ($text -notmatch "IndexOf\('\s->\s'\)") "$caller no longer carries its own rename split"
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
