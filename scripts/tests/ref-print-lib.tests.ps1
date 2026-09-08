<#
.SYNOPSIS
    Tests for scripts/lib/ref-print-lib.ps1 -- the paste-safety verdict on a ref name that is about to be
    interpolated into a printed command (issue #1594).

.DESCRIPTION
    THE HOSTILE NAMES ARE SPLIT ON GIT'S OWN ACCEPTANCE, measured rather than assumed, because the two
    halves prove different things:

      - REACHABLE -- `git check-ref-format --branch` returns 0, so a repo can genuinely hold the name and
        nothing upstream of the print site refuses it. This half carries the finding, and each case
        asserts git's acceptance as an explicit premise: if a future git tightened its rules, that assert
        is the one that should go red, because at that point the case has stopped testing anything real.
      - UNREACHABLE -- git rejects the name ('^', '*', '~', ':', '[', '\', '?', whitespace and every
        ASCII control character). Asserted anyway, and not as padding: the guard has to be a property of
        the STRING, not an inference from git's rules. sync-main.ps1 hands it a name built from a seam
        answer a consumer wrote, which git has never seen.

    THE SPLIT IS ON `\p{Cc}` VERSUS `\p{Cf}`, AND THAT IS THE #1617 CORRECTION. git enforces only the
    ASCII control class, so the format characters -- U+202E, U+200D, U+200B, U+2066 -- are REACHABLE
    and belong in the first half. They sat in the second until September 8, 2026, under a header
    saying git refuses them, which mirrored the same wrong claim in the lib's own scope note.

    THE STRUCTURAL HALF IS AS LOAD-BEARING AS THE UNIT HALF. The lib is correct and unreachable if a call
    site still interpolates the raw ref, so all seven sites #1594 measured are asserted to name the token
    -- and asserted to carry no remaining raw `$branch` inside a printed command. That assert is what
    would catch the eighth site somebody adds next year, which is the failure mode the issue itself
    demonstrated: it reported three of the seven.

    Dependency-free (no Pester), same style as the rest of the suite.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$LibPath  = Join-Path $RepoRoot 'scripts\lib\ref-print-lib.ps1'

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

Assert-True (Test-Path -LiteralPath $LibPath) 'ref-print-lib.ps1 exists at its registered source path'
. $LibPath
# For the premise checks below. `git check-ref-format` writes its refusal to stderr, and a bare native
# call under $ErrorActionPreference = 'Stop' turns that into a NativeCommandError in Windows PowerShell
# 5.1 -- the exact pitfall this repo's own guidance names. -DiscardStderr is the answer already in the
# tree, so the premise check reads an exit code rather than fighting the host.
. (Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1')

function Test-GitAcceptsRef {
    param([string]$Ref)
    $r = Invoke-NativeCapture -FilePath 'git' -Arguments @('check-ref-format', '--branch', $Ref) -DiscardStderr
    return ($r.ExitCode -eq 0)
}

# --- the names this workflow actually uses are all safe -------------------------------------------
# THE REGRESSION THAT MATTERS MOST. A guard that refused an ordinary branch name would break every
# remedy in the workflow, so the ordinary shapes are asserted first and explicitly.
Write-Host ''
Write-Host 'Safe names -- every shape this workflow creates' -ForegroundColor Cyan

foreach ($ok in @(
    'fix/1594-printed-command-ref-safety',
    'feat/branch-document-name-and-headings',
    'docs/prose-phase-heading-levels',
    'sync/live-2026-09-08',
    'sync/live-2026-09-08-2',
    'fix/template-newline-v2',
    'main',
    'release/4.32.0',
    'a',
    '9lives/thing_one.two-three'
)) {
    Assert-True (Test-RefPasteSafe -Ref $ok) "safe: '$ok'"
    $v = Get-PasteableRef -Ref $ok
    Assert-Equal $ok $v.Token "...and its token is the name itself: '$ok'"
    Assert-Equal '' $v.Note   "...and it carries no note: '$ok'"
    Assert-True $v.IsSafe     "...and IsSafe is true: '$ok'"
}

# --- the hostile names, each one legal to git ------------------------------------------------------
Write-Host ''
Write-Host 'Refused names -- and git accepts every one of them, which is the finding' -ForegroundColor Cyan

# MEASURED, September 8, 2026, and split on the measurement rather than on intuition. git rejects
# '^', '*', '~', ':', '[', '\' and '?' in a branch name (exit 128) and ACCEPTS everything below -- so
# only these are reachable through a real ref, and only these carry the finding. The rejected set is
# exercised separately further down, because the guard must not depend on git having filtered first.
#
# `.Contains()` RATHER THAN -like, and the backtick case is why. In a -like pattern the backtick is the
# escape character and '*', '?' and '[' are wildcards, so "*$bad*" silently stops being a substring test
# for exactly the names this suite exists to cover: the first run of this file passed every case except
# the backtick one, for that reason and not because the lib was wrong.
$hostileReachable = @(
    'fix/evil;touch',
    'fix/evil&touch',
    'fix/evil|touch',
    'fix/evil$(touch)',
    'fix/evil`touch`',
    "fix/it's-fine",
    'fix/a"b',
    'fix/a>b',
    'fix/a<b',
    'fix/a!b',
    'fix/a%b',
    'fix/a{b}',
    'fix/a(b)',
    'fix/a=b',
    'fix/a,b',
    'fix/a@b',
    'fix/a+b'
)

$gitAvailable = [bool](Get-Command git -ErrorAction SilentlyContinue)
foreach ($bad in $hostileReachable) {
    if ($gitAvailable) {
        # THE PREMISE, CHECKED RATHER THAN ASSUMED. If a future git tightened its ref rules this assert is
        # the one that should fail, and it should fail LOUDLY -- at that point the character is no longer
        # reachable and the case below has stopped testing anything real.
        Assert-True (Test-GitAcceptsRef -Ref $bad) "git accepts '$bad' as a branch name (the premise of this whole guard)"
    }
    Assert-True (-not (Test-RefPasteSafe -Ref $bad)) "refused: '$bad'"
    $v = Get-PasteableRef -Ref $bad
    Assert-Equal '<branch>' $v.Token "...and its token is the placeholder, so the name never enters the command: '$bad'"
    Assert-True (-not $v.IsSafe) "...and IsSafe is false: '$bad'"
    Assert-True ([bool]$v.Note) "...and it carries a note: '$bad'"
    Assert-True ($v.Note.Contains($bad)) "...whose note names the real branch, so the reader can still act: '$bad'"
    Assert-True ($v.Note.Contains('1594')) "...and cites the issue: '$bad'"
}

# --- the characters git itself refuses, refused here too ------------------------------------------
# BELT AND BRACES, ASSERTED ON PURPOSE. None of these can arrive through `git rev-parse`, so this block
# is not about reachability -- it is about the guard being a property of the STRING rather than an
# inference from git's rules. sync-main.ps1 hands it a name built from a seam answer a consumer wrote,
# which git has never seen, so a guard that leaned on "git filtered it already" would be wrong there.
Write-Host ''
Write-Host 'Characters git rejects in a ref -- refused here independently of git' -ForegroundColor Cyan

foreach ($unreachable in @('fix/a^b', 'fix/a*b', 'fix/a~b', 'fix/a:b', 'fix/a[b]', 'fix/a\b', 'fix/a?b')) {
    if ($gitAvailable) {
        Assert-True (-not (Test-GitAcceptsRef -Ref $unreachable)) "git itself rejects '$unreachable' (so this case is defence in depth, not a hole)"
    }
    Assert-True (-not (Test-RefPasteSafe -Ref $unreachable)) "refused here anyway: '$unreachable'"
}

# --- the space and the CONTROL characters: git refuses them, and so does this ---------------------
# NOT REACHABLE THROUGH A REF, and asserted anyway. Get-PasteableRef takes a string, and a caller that
# hands it something other than `git rev-parse`'s output (a seam answer, a -Name parameter) is not bound
# by git's rules at all -- so the guard must not depend on git having filtered first.
#
# THE FORMAT CHARACTERS ARE NOT IN THIS GROUP AND USED TO BE (#1617). U+202E sat here under a header
# saying git refuses it, which is false: git enforces `\p{Cc}` and not `\p{Cf}`. It has moved to the
# reachable block below, where its premise is measured like every other reachable case.
Write-Host ''
Write-Host 'Whitespace and ASCII control characters -- refused here too, independently of git' -ForegroundColor Cyan

foreach ($ws in @('fix/a b', "fix/a`tb", "fix/a`nb", "fix/a$([char]0x1B)[31mb")) {
    if ($gitAvailable) {
        Assert-True (-not (Test-GitAcceptsRef -Ref $ws)) "git itself rejects this whitespace/control name (so this case is defence in depth, not a hole)"
    }
    Assert-True (-not (Test-RefPasteSafe -Ref $ws)) 'refused: a name carrying whitespace or an ASCII control character'
}

# --- the FORMAT characters: git ACCEPTS them, which is the #1617 finding --------------------------
# MEASURED, September 8, 2026. `git check-ref-format --branch` returns 0 for every code point below, a
# branch so named is creatable and checkout-able, and `git rev-parse --abbrev-ref HEAD` returns it
# verbatim -- which is the source every print site reads its branch from. They are `\p{Cf}` (format),
# not `\p{Cc}` (control), and git enforces only the second class. U+202E and U+200D are the two #1446
# was filed for, where they bypassed the #1439 tip sanitiser on a non-UTF-8 console.
#
# THE PREMISE IS ASSERTED THE SAME WAY THE SHELL-METACHARACTER CASES ASSERT THEIRS: if a future git
# tightened its ref rules this is the assert that should go red, because at that point ref-print-lib's
# scope note has stopped describing a live gap and should be re-read.
Write-Host ''
Write-Host 'Format characters -- git accepts them in a ref, and this guard refuses them anyway' -ForegroundColor Cyan

foreach ($cf in @(
    @{ Ref = "fix/a$([char]0x202E)b"; Label = 'U+202E RIGHT-TO-LEFT OVERRIDE' },
    @{ Ref = "fix/a$([char]0x200D)b"; Label = 'U+200D ZERO WIDTH JOINER' },
    @{ Ref = "fix/a$([char]0x200B)b"; Label = 'U+200B ZERO WIDTH SPACE' },
    @{ Ref = "fix/a$([char]0x2066)b"; Label = 'U+2066 LEFT-TO-RIGHT ISOLATE' }
)) {
    if ($gitAvailable) {
        Assert-True (Test-GitAcceptsRef -Ref $cf.Ref) "git ACCEPTS $($cf.Label) in a branch name (the #1617 premise)"
    }
    Assert-True (-not (Test-RefPasteSafe -Ref $cf.Ref)) "refused on the paste axis anyway: $($cf.Label)"
    $v = Get-PasteableRef -Ref $cf.Ref
    Assert-Equal '<branch>' $v.Token "...and its token is the placeholder: $($cf.Label)"
    Assert-True ($v.Note -notmatch '[\p{Cf}]') "...and the format character does not survive into the note: $($cf.Label)"
}

# AND THE SCOPE NOTE SAYS SO, rather than claiming git closed this class. The lib's own reasoning is
# what #1617 was filed against -- the guard was already right and the sentence explaining it was not --
# so the correction is pinned here, where a rewrite that quietly restores the old claim goes red.
$libText = [System.IO.File]::ReadAllText($LibPath)
Assert-True ($libText -match [regex]::Escape('1617')) 'ref-print-lib.ps1 cites #1617 where it scopes display out'
Assert-True ($libText -notmatch [regex]::Escape('git already rejects the control characters that would make prose deceptive')) 'and no longer claims git closes the deceptive class for a ref name'

# AND THE NOTE ITSELF IS NOT AN INJECTION SURFACE. The one place this lib prints is the refusal path, so
# a control or format character surviving into it would mean the guard's own output could repaint a
# terminal or wear this workflow's warning prefix -- remote-ahead-lib.ps1's lesson (#1439, #1446) applied
# to this lib's output. Belt-and-braces for a name from `git rev-parse`, load-bearing for sync-main's
# seam-derived one, which git has never filtered.
foreach ($esc in @("fix/a$([char]0x1B)[31mb", "fix/a$([char]0x202E)b", "fix/a$([char]0x0D)b", "fix/a$([char]0x07)b")) {
    $n = (Get-PasteableRef -Ref $esc).Note
    Assert-True ([bool]$n) 'the refusal still carries a note for a control-character name'
    # THE NOTE'S OWN LINE BREAKS ARE NOT THE SUBJECT -- it is a multi-line message and CR/LF are control
    # characters, so they come out before the assert. What must not survive is a control or format
    # character carried in from the NAME.
    $body = $n -replace "`r", '' -replace "`n", ''
    Assert-True ($body -notmatch '[\p{Cc}\p{Cf}]') 'and no control or format character from the name survives into it'
}

# --- the empty case ------------------------------------------------------------------------------
Write-Host ''
Write-Host 'The empty ref -- a caller that lost its branch' -ForegroundColor Cyan

foreach ($empty in @('', $null)) {
    Assert-True (-not (Test-RefPasteSafe -Ref $empty)) 'an empty or null ref is NOT paste-safe'
    $v = Get-PasteableRef -Ref $empty
    Assert-Equal '<branch>' $v.Token 'an empty ref yields the placeholder rather than a command with a hole in it'
    Assert-True ($v.Note -like '*could not read it*') 'and its note says the run could not read the name, not that the name is ""'
}

# --- the placeholder is caller-chosen ------------------------------------------------------------
Write-Host ''
Write-Host 'The placeholder' -ForegroundColor Cyan

$custom = Get-PasteableRef -Ref 'fix/evil;touch' -Placeholder '<your branch>'
Assert-Equal '<your branch>' $custom.Token 'a caller may choose the placeholder'
Assert-True ($custom.Note -like '*<your branch>*') 'and the note quotes the placeholder it actually used, so the two agree'

# --- the seven call sites #1594 measured ----------------------------------------------------------
Write-Host ''
Write-Host 'The call sites -- the lib is unreachable if one still interpolates the raw ref' -ForegroundColor Cyan

$shipPath = Join-Path $RepoRoot 'scripts\release\ship-pr.ps1'
$syncPath = Join-Path $RepoRoot 'scripts\task\sync-main.ps1'
Assert-True (Test-Path -LiteralPath $shipPath) 'ship-pr.ps1 exists'
Assert-True (Test-Path -LiteralPath $syncPath) 'sync-main.ps1 exists'

$shipText = [System.IO.File]::ReadAllText($shipPath)
$syncText = [System.IO.File]::ReadAllText($syncPath)

Assert-True ($shipText -match [regex]::Escape("ref-print-lib.ps1")) 'ship-pr.ps1 dot-sources the lib'
Assert-True ($syncText -match [regex]::Escape("ref-print-lib.ps1")) 'sync-main.ps1 dot-sources the lib'
Assert-True ($shipText -match [regex]::Escape('$branchPaste = Get-PasteableRef -Ref $branch')) 'ship-pr.ps1 judges the ref once, beside the read that produced it'
Assert-True ($syncText -match [regex]::Escape('$branchPaste = Get-PasteableRef -Ref $branch')) 'sync-main.ps1 judges the ref once, beside the composition that produced it'

# Site by site, by the exact printed text -- five in ship-pr, two in sync-main.
foreach ($site in @(
    @{ Text = $shipText; Needle = '  git checkout $($branchPaste.Token)'; Label = 'ship-pr: the stale-CI remedy checkout' },
    @{ Text = $shipText; Needle = 'fold-changelog-entry.ps1 -Branch $($branchPaste.Token) -Commit -Push'; Label = 'ship-pr: the under-a-queue fold-by-hand line' },
    @{ Text = $shipText; Needle = '& "$foldScript" -Branch $($branchPaste.Token) -RepoRoot <that worktree> -Push'; Label = 'ship-pr: the fold-from-the-worktree-that-holds-main line' },
    @{ Text = $shipText; Needle = '& "$foldScript" -Branch $($branchPaste.Token) -Push'; Label = 'ship-pr: the fold-by-hand line after a failed worktree add' },
    @{ Text = $shipText; Needle = 'checkout $($branchPaste.Token)"'; Label = 'ship-pr: the "move this tree off main" warning' },
    @{ Text = $syncText; Needle = 'git push -u origin $($branchPaste.Token)'; Label = 'sync-main: the push-by-hand remedy' },
    @{ Text = $syncText; Needle = 'gh pr create --base $trunk --head $($branchPaste.Token)'; Label = 'sync-main: the gh pr create hand-over line' }
)) {
    Assert-True ($site.Text.Contains($site.Needle)) "names the token, not the raw ref -- $($site.Label)"
}

# AND THE NOTE IS PRINTED AT EVERY ONE OF THEM. A placeholder with no explanation is worse than the
# original defect: the reader is handed a command that cannot work and told nothing about why.
Assert-True (([regex]::Matches($shipText, [regex]::Escape('$branchPaste.Note'))).Count -ge 3) 'ship-pr.ps1 prints the note at its Write-Host/Write-Warning sites'
Assert-True ($shipText -match [regex]::Escape('$branchPasteNoteBlock = if ($branchPaste.Note)')) 'ship-pr.ps1 defines the here-string note block once'
Assert-True (([regex]::Matches($shipText, [regex]::Escape('$branchPasteNoteBlock'))).Count -ge 4) 'and appends it to each of its three here-string remedies'
Assert-True (([regex]::Matches($syncText, [regex]::Escape('$branchPaste.Note'))).Count -ge 2) 'sync-main.ps1 prints the note at both of its sites'

# THE EIGHTH SITE, WHICH IS THE ONE THIS ASSERT EXISTS FOR. #1594 reported three of seven, so the guard
# against the next one is a scan rather than a list: no printed line in either script may put the raw
# $branch straight after a command word. Prose that merely QUOTES the name ('$branch' inside a sentence)
# is deliberately not a subject -- git rejects the control characters that would make prose deceptive,
# and remote-ahead-lib.ps1 owns that half.
Write-Host ''
Write-Host 'No raw ref left in a printed command, in either script' -ForegroundColor Cyan

$rawInCommand = @(
    'git checkout $branch',
    'git push -u origin $branch',
    '--head $branch',
    '-Branch $branch -Commit',
    '-Branch $branch -Push',
    '-Branch $branch -RepoRoot'
)
foreach ($raw in $rawInCommand) {
    Assert-True (-not $shipText.Contains($raw)) "ship-pr.ps1 no longer carries the raw interpolation: '$raw'"
    Assert-True (-not $syncText.Contains($raw)) "sync-main.ps1 no longer carries the raw interpolation: '$raw'"
}

# --- the mirrors carry it too --------------------------------------------------------------------
# A CONSUMER RUNS THE MIRROR, so a repair present only in the root copy is a repair no consumer has. The
# drift lint proves the copies match; these asserts prove the lib was REGISTERED in the first place,
# which is the failure the drift lint cannot see.
Write-Host ''
Write-Host 'The mirrors' -ForegroundColor Cyan

foreach ($m in @(
    @{ Path = 'plugins\dkj-policy\scripts\lib\ref-print-lib.ps1';      Label = 'dkj-policy (ship-pr)' },
    @{ Path = 'plugins\dkj-teams\dkj-team-shopify\scripts\lib\ref-print-lib.ps1'; Label = 'dkj-team-shopify (sync-main)' }
)) {
    $full = Join-Path $RepoRoot $m.Path
    Assert-True (Test-Path -LiteralPath $full) "the lib is mirrored into $($m.Label)"
    if (Test-Path -LiteralPath $full) {
        Assert-True (([System.IO.File]::ReadAllText($full)) -match 'function Get-PasteableRef') "...and that mirror carries the function: $($m.Label)"
    }
}

# --- the creation-side half ----------------------------------------------------------------------
# THE OTHER HALF OF #1594, and it is asserted here rather than only in branch-info.tests.ps1 because the
# two halves are one decision: neither closes the hole alone, and a later reader removing one should see
# the other fail.
Write-Host ''
Write-Host 'Test-BranchName holds the same allowlist (the creation-side half)' -ForegroundColor Cyan

. (Join-Path $RepoRoot 'scripts\lib\branch-info.ps1')
foreach ($bad in @('fix/evil;touch', 'fix/evil$(touch)', "fix/it's-fine", 'fix/a b', '-fix/leading-dash')) {
    $r = Test-BranchName -Branch $bad
    Assert-True (-not $r.IsValid) "Test-BranchName refuses '$bad'"
    Assert-True ($r.Reason -like '*1594*') "...and its reason cites the issue: '$bad'"
}
foreach ($ok in @('fix/1594-printed-command-ref-safety', 'feat/a_b.c-d/e')) {
    Assert-True ((Test-BranchName -Branch $ok).IsValid) "Test-BranchName still accepts '$ok'"
}

Write-Host ''
Write-Host "Result: $script:pass pass, $script:fail fail." -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
if ($script:fail -gt 0) { exit 1 }
exit 0
