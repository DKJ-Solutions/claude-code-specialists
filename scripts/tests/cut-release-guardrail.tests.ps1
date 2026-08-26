<#
.SYNOPSIS
    Drift guard for cut-release.ps1's stray-entry detection (issue #885, group D).

.DESCRIPTION
    cut-release.ps1 refuses to cut a release while an "unfolded changelog entry file" sits in the
    repo root. UNTIL AUGUST 25, 2026 it recognised an entry by exclusion: every root *.md that was NOT
    in the $reservedRootMd allowlist was treated as an entry, which meant every PERMANENT root doc
    (README, CONTRIBUTING, SECURITY, ...) had to be listed there too -- and that drift blocked a real
    release three times (#165; CONTRIBUTING.md/SECURITY.md in #405 with QUICKSTART.md/UNINSTALL.md;
    ADOPTION.md in #408).

    IT NOW RECOGNISES AN ENTRY BY CONTENT: a root *.md (not on $reservedRootMd, which survives as a
    manual override) is stray only if Test-BranchChangelogIsFilled says so -- the same predicate the
    branch's own live document is held to, true only for text that declares a non-trunk branch or opens
    with an entry-level heading (## or ###). A consumer's own permanent doc, which opens with a plain #
    title, never matches, so it needs no listing at all. This test asserts the mechanism (source-text,
    since cut-release.ps1 runs its guardrails on load and cannot be dot-sourced) and then proves it
    against this repo's own tracked root docs, for real, via the actual predicate.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/cut-release-guardrail.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot       = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$CutReleasePath = Join-Path $RepoRoot 'scripts\release\cut-release.ps1'
$SeamLibPath    = Join-Path $RepoRoot 'scripts\lib\seam-lib.ps1'
$EntryScaffoldLibPath = Join-Path $RepoRoot 'scripts\lib\entry-scaffold-lib.ps1'

$script:pass = 0
$script:fail = 0

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:pass++; Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:fail++; Write-Host "  [FAIL] $Name" -ForegroundColor Red
    }
}

Write-Host "cut-release.ps1 -- stray-entry detection reads content, not just the override list" -ForegroundColor Cyan

$cutReleaseText = [System.IO.File]::ReadAllText($CutReleasePath, [System.Text.Encoding]::UTF8)
$seamLibText    = [System.IO.File]::ReadAllText($SeamLibPath, [System.Text.Encoding]::UTF8)

# 1. WIRING: the check must actually call the content predicate, not just filter by name. Source-text
#    assert for the same reason as everywhere else in this file -- the script cannot be dot-sourced.
$strayBlock = [regex]::Match($cutReleaseText, '(?ms)\$strayEntries\s*=.*?^if \(\$strayEntries\.Count')
Assert-True $strayBlock.Success 'found the $strayEntries construction in cut-release.ps1'
Assert-True ($strayBlock.Success -and $strayBlock.Value -match 'Test-BranchChangelogIsFilled') `
    'stray-entry detection calls Test-BranchChangelogIsFilled -- content, not name-exclusion alone'
Assert-True ($strayBlock.Success -and $strayBlock.Value -match '\$reservedRootMd\s+-notcontains') `
    'the override list is still consulted first, as a manual exemption'
Assert-True ($cutReleaseText.Contains('lib\entry-scaffold-lib.ps1')) `
    'and cut-release.ps1 dot-sources the lib that predicate lives in'

# 2. The fallback literal still parses, so the override mechanism itself has not silently broken.
$m = [regex]::Match($cutReleaseText, '\$reservedRootMd\s*=\s*@\(Get-SeamValue[^@]*@\(([^)]*)\)')
if (-not $m.Success) { $m = [regex]::Match($cutReleaseText, '\$reservedRootMd\s*=\s*@\(([^)]*)\)') }
Assert-True $m.Success 'found the $reservedRootMd fallback literal in cut-release.ps1'
$fallback = @([regex]::Matches($m.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
Assert-True ($fallback.Count -gt 0) 'fallback literal parsed to at least one entry'

# The EFFECTIVE override list -- the seam where this repo defines one, the fallback literal where it
# does not -- because $reservedRootMd in the real script is this value, not the bare fallback.
$repoConfig = Join-Path $RepoRoot 'scripts\repo-config.ps1'
$allowlist = $fallback
if (Test-Path -LiteralPath $repoConfig) {
    . $repoConfig
    if (Get-Command -Name 'Get-ReservedRootMd' -ErrorAction SilentlyContinue) {
        $allowlist = @(Get-ReservedRootMd)
    }
}
Assert-True ($allowlist.Count -gt 0) 'the effective override list has at least one entry'

# 3. PROVE THE PREDICATE AGAINST THIS REPO'S OWN TRACKED ROOT DOCS -- for real, not by name, and
#    through the SAME two-step filter the script itself applies (override list first, content check
#    only for what survives it). This is what replaces the old "every permanent doc must be listed"
#    assertion: a doc that is NOT on the override list no longer needs to be added there, it needs to
#    not LOOK like an entry -- and this checks that every such doc this repo actually has genuinely does
#    not, so this repo's own next release is not the one that finds out the hard way.
#
#    CHANGELOG.md ITSELF IS THE WORKED CASE FOR WHY THE OVERRIDE STEP CANNOT BE SKIPPED: read on its
#    own, outside that filter, it fails the content check -- it IS a concatenation of pending entries,
#    each opening with its own '## DEPLOY: `<branch>`' heading and naming that branch, which is exactly
#    the shape Test-BranchChangelogIsFilled exists to recognise. It is correct that CHANGELOG.md reads
#    as "full of entries"; it is also on $reservedRootMd unconditionally, so the real script never runs
#    the content check on it at all. Measured while writing this test: omitting the override step here
#    made this assert fail on exactly that file, for exactly that reason.
. $EntryScaffoldLibPath
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $tracked = @(& git -C $RepoRoot ls-files -- '*.md' 2>$null)
} finally {
    $ErrorActionPreference = $prevEap
}
$rootMd = @($tracked | Where-Object { $_ -and ($_ -notmatch '/') })
# A branch changelog entry file is named after its branch: <prefix>-<name>.md with a known prefix --
# excluded here not because the content check can't see it (it can, and should), but because a file of
# that shape genuinely IS meant to be read as an entry, so it belongs in the positive-case test below
# instead of the negative one here.
$entryPattern = '^(feat|fix|docs|chore)-.*\.md$'
$permanentDocs = @($rootMd | Where-Object { $_ -notmatch $entryPattern })
Assert-True ($permanentDocs.Count -gt 0) 'found tracked permanent root docs to check'
$scanned = @($permanentDocs | Where-Object { $allowlist -notcontains $_ })
Assert-True ($scanned.Count -lt $permanentDocs.Count) `
    'at least one tracked root doc (CHANGELOG.md) is override-exempted rather than content-scanned'
$falsePositives = @($scanned | Where-Object {
    $text = [System.IO.File]::ReadAllText((Join-Path $RepoRoot $_), [System.Text.Encoding]::UTF8)
    Test-BranchChangelogIsFilled -Text $text
})
Assert-True ($falsePositives.Count -eq 0) `
    "no content-scanned root doc reads as a stray entry (false positives: $($falsePositives -join ', '))"

# 4. THE POSITIVE CASE: a genuine legacy root entry -- opens with its own title as an H2, names no
#    branch -- must still be caught, or the inversion traded a false-positive bug for a false-negative
#    one. This is exactly the pre-split shape entry-scaffold-lib.ps1's own docstring describes.
$legacyEntryText = "## feat: something a branch once did`n`nSome body text.`n"
Assert-True (Test-BranchChangelogIsFilled -Text $legacyEntryText) `
    'a legacy pre-split root entry (H2 title, no declared branch) still reads as stray'
$normalDocText = "# Just a Title`n`nSome body text that is not an entry.`n"
Assert-True (-not (Test-BranchChangelogIsFilled -Text $normalDocText)) `
    'and an ordinary document (H1 title) does not'

Write-Host "cut-release.ps1 -- every planned file is checked before the first one is written" -ForegroundColor Cyan
# WHY THIS IS A TEXT ASSERT AND NOT A BEHAVIOUR ONE: cut-release.ps1 runs its guardrails on load (it
# refuses to be anywhere but a clean main), so it cannot be dot-sourced and the collision path cannot
# be exercised in-process -- the same constraint the allowlist check above works around.
#
# WHAT IT PROTECTS. With the consumer tier on (#417) a cut writes TWO files, and the order is
# load-bearing: collect every target, check them all, then write. Checking each one just before its own
# write would leave a release whose developer notes exist and whose stakeholder document does not --
# half a release, discovered by the release manager rather than by a guard, on an action that has
# already committed nothing and cannot be re-run because the first file now exists.
$planned = [regex]::Match($cutReleaseText, '(?m)^\$plannedFiles\s*=')
Assert-True $planned.Success 'cut-release.ps1 collects its write targets in $plannedFiles'
$guardLoop = [regex]::Match($cutReleaseText, '(?ms)foreach \(\$rel in \$plannedFiles\).*?Nothing was written')
Assert-True $guardLoop.Success 'the collision guard loops over that whole collection and says nothing was written'
$firstWrite = $cutReleaseText.IndexOf('Write-Utf8NoBom -Path')
Assert-True ($firstWrite -gt 0) 'found the first content write in cut-release.ps1'
Assert-True ($guardLoop.Success -and $firstWrite -gt ($guardLoop.Index + $guardLoop.Length)) `
    'the guard runs BEFORE any file is written, so a collision leaves the tree untouched'
# And the consumer document is really in that collection -- a guard over one path would pass the
# asserts above while protecting nothing new.
$plannedBlock = [regex]::Match($cutReleaseText, '(?ms)^\$plannedFiles\s*=.*?^foreach \(\$rel in \$plannedFiles\)')
Assert-True ($plannedBlock.Success -and $plannedBlock.Value -match 'noteRelPath') `
    'the hand-written note joins the collection when the seam names this bump'
# AND the generated body, which is written unconditionally: it is the one artefact every release has, so
# leaving it out of the pre-flight would let a re-cut clobber a published Release body without a word.
Assert-True ($plannedBlock.Success -and $plannedBlock.Value -match 'bodyRelPath') `
    'the generated GitHub Release body is guarded too, at every release'
# THE TIER-0 NOTES' LINK PREFIX IS DERIVED, NOT DEFAULTED (issue #914, August 26, 2026). Build-ReleaseNotes
# defaults $LinkPrefix to '../../../', the depth of a root sitting directly under releases/ -- and #914 moved
# this repo's root one level deeper, into contributing-davekjohn/. The call had been relying on that default
# since the function existed, so the move would have written every root-relative link in every note one
# directory short, with nothing erroring: a dead relative link inside a tagged, immutable document, found by
# a reader. Asserted on the CALL, because that is where the mistake was, and on the derivation rather than on
# a count of '../' -- pinning four would turn red for the next repo whose root sits somewhere else, which is
# the whole reason the root is a seam.
Assert-True ($cutReleaseText -match '(?m)^\$notesDepth\s*=\s*@\(\$notesRelPath -split') `
    "the tier-0 notes' link depth is derived from the note path the seam produced"
Assert-True ($cutReleaseText -match "-LinkPrefix \('\.\./' \* \`$notesDepth\)") `
    'and Build-ReleaseNotes is called with it rather than left on its shallowest-shape default'
# THE BODY HAS ITS OWN ROOT SINCE AUGUST 12, 2026 (Dave). Asserted on the ROOT rather than on the whole
# literal, so a grouping change (<X>.x -> <X.Y>) does not turn this red for a reason it is not about. It
# used to be written into releases/development/ with a '-github-body' suffix: the one generated document
# that IS published, sitting in the directory whose whole job is the record nobody publishes.
#
# SEAMED SINCE ISSUE #885, GROUP E: the literal 'releases/github/' is gone from this assignment, replaced
# by $githubNotesRootRelPath, whose own computed default lives in seam-lib.ps1
# (Get-DefaultReleaseGithubNotesRoot). Asserted in two parts so a regression in either half is
# attributable: the assignment reads the seam variable, and that variable's default really resolves where
# this repo's tree is.
#
# THE DEFAULT MOVED INTO THE WORKFLOW FOLDER IN #914 (August 26, 2026) and stopped branching on the
# source, which is why the second assert is on the COMPOSED path and not on a literal any more. The
# source-versus-consumer half is asserted where it belongs, in seam-lib.tests.ps1.
Assert-True ($cutReleaseText -match '(?m)^\$bodyRelPath\s*=\s*"\$githubNotesRootRelPath/') `
    'the generated body is written from the seamed github-notes root'
Assert-True ($seamLibText -match [regex]::Escape('/releases/github"')) `
    "and that seam's computed default composes the workflow folder with releases/github"
# THE NEGATIVE HALF IS SCOPED TO THE ASSIGNMENT, and that is not fussiness -- the WHY comment three lines
# above the assignment quotes the retired filename, so a check over the whole script text would fail on the
# sentence explaining the move. Assert on the line that decides, not on the file that mentions.
$bodyAssign = [regex]::Match($cutReleaseText, '(?m)^\$bodyRelPath\s*=.*$')
Assert-True ($bodyAssign.Success -and $bodyAssign.Value -notmatch 'github-body') `
    'and no longer carries the -github-body suffix: the root says it, and both siblings are <X.Y.Z>.md'
# ITS DIRECTORY IS DERIVED FROM ITS OWN PATH. While the body shared releases/development/ the single
# New-Item for the notes covered it; now that the roots differ, a second hand-built path would be a second
# definition of where this file goes -- and the FIRST CUT INTO A FRESH MAJOR is the only run that would find
# out, because it is the only one where the directory does not exist yet.
Assert-True ($cutReleaseText -match 'New-Item -ItemType Directory -Force -Path \(Split-Path -Parent \$bodyAbs\)') `
    "the body's directory is created from the body's own path, so a fresh major cannot fail on a missing folder"
# No .html anywhere in the cut: the tier is markdown-only (Dave, August 3, 2026). Asserted on the script
# text because the removal is the feature -- a reintroduced HTML write should turn this red.
Assert-True ($cutReleaseText -notmatch 'ConvertTo-ReleaseHtml') 'cut-release calls no HTML renderer'
Assert-True ($cutReleaseText -notmatch "\.html") 'cut-release writes no .html path at all'

Write-Host "cut-release.ps1 -- the release passes the same test gate every PR does" -ForegroundColor Cyan
# ISSUE #510. Until August 7, 2026 the cut ran the LINT ALONE, which made the release commit the
# least-checked commit in the workflow -- every ordinary PR passes the lint AND all the suites locally, and
# CI runs both again before the merge is allowed. Wiring-level asserts for the reason the block below gives:
# this script refuses to run anywhere but a clean main, so the gate cannot be exercised in-process.
Assert-True ($cutReleaseText -match 'Invoke-TestSuiteGate') 'cut-release runs the test suites'
Assert-True ($cutReleaseText -match '(?m)\[switch\]\$SkipTests') 'and declares -SkipTests as the escape valve'
# ONE OWNER FOR THE LOOP. open-pr had run the suites since PR #54; copying its fifteen lines into the cut
# would have been two copies of one rule, free to drift. Both call the same shared helper -- asserted here
# because a later "simplification" that inlines either one is exactly how that drift starts.
$openPrForGate = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'scripts\release\open-pr.ps1'))
Assert-True ($openPrForGate -match 'Invoke-TestSuiteGate') 'and open-pr runs the SAME shared gate, not a copy of it'
$captureLib = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'scripts\lib\native-capture-lib.ps1'))
Assert-True ($captureLib -match '(?m)^function Invoke-TestSuiteGate') 'which is defined once, in the lib both of them already load'
# AND CI IS THE THIRD CALLER, not the third copy (issue #512, August 7, 2026). ci.yml carried its own
# inline foreach over scripts/tests until that date, which is how a gate improvement can reach both local
# callers and silently miss the one that actually blocks the merge -- the required check. Asserted on the
# workflow text because nothing else in this repo can: CI is the one caller no suite gets to run.
$ciYml = [System.IO.File]::ReadAllText((Join-Path $RepoRoot '.github\workflows\ci.yml'))
Assert-True ($ciYml -match 'Invoke-TestSuiteGate') 'CI runs the same shared gate as well'
Assert-True ($ciYml -notmatch 'Get-ChildItem[^\r\n]*tests') 'and no longer walks scripts/tests itself'
# BEFORE THE FIRST WRITE, like the lint above it: a release that fails halfway leaves a half-bumped tree on
# main under one of this repo's two direct-commit exceptions, which is where a failure costs most to undo.
#
# ANCHORED ON THE FIRST CALL OF THE WRITE HELPER, not on 'WriteAllText'. The first version searched for
# that string and failed -- because it matches the DEFINITION of Write-Utf8NoBom near the top of the file,
# which sits before the gate while writing nothing. A position assert has to point at the thing that
# happens, not at the thing that is declared.
$gateIdx  = $cutReleaseText.IndexOf('Invoke-TestSuiteGate')
$writeIdx = $cutReleaseText.IndexOf('Write-Utf8NoBom -Path')
Assert-True ($gateIdx -gt 0 -and $writeIdx -gt 0 -and $gateIdx -lt $writeIdx) 'and it runs before the first write'

Write-Host "cut-release.ps1 -- the bump gate runs before the first write, and only its own flag skips it" -ForegroundColor Cyan
# The RULES are unit-tested where they live (Test-ReleaseBumpEarned, release-lib.tests.ps1). What can only
# be checked here is the WIRING, and the same constraint applies as above: this script refuses to be
# anywhere but a clean main, so it cannot be dot-sourced and the gate cannot be exercised in-process.
Assert-True ($cutReleaseText -match 'Test-ReleaseBumpEarned') 'cut-release asks whether the bump was earned'
Assert-True ($cutReleaseText -match '(?m)\[switch\]\$SkipTierGate') 'and declares -SkipTierGate as the escape valve'
# ITS OWN FLAG, NOT -SkipLint. The two overrule different things -- a tool versus a judgement about content
# -- and sharing one flag would let somebody skipping a slow lint run also, silently, cut a minor with
# nothing in it for a consumer.
$gateBlock = [regex]::Match($cutReleaseText, '(?ms)if \(-not \$SkipTierGate\).*?^\}')
Assert-True $gateBlock.Success 'the gate is guarded by -SkipTierGate alone'
Assert-True ($gateBlock.Success -and $gateBlock.Value -notmatch '\$SkipLint') 'and -SkipLint does not reach into it'
# BEFORE ANY WRITE, for the same reason as the collision guard above: a refusal must leave the tree exactly
# as it was, with no notes file, no version bump and no half-cut release to unpick on main.
Assert-True ($gateBlock.Success -and $firstWrite -gt ($gateBlock.Index + $gateBlock.Length)) `
    'the bump gate runs BEFORE any file is written'
# It reads the changelog per TIER; the flat accessor would give it entries with no tier to judge.
Assert-True ($cutReleaseText -match 'Get-PullRequestEntriesByTier') 'it reads the pending entries per tier'
# The audience section is a TIER selection, not a category guess -- and the two retired seam knobs must not
# come back with it.
#
# THE TIER IS THE REPO'S OWN ANSWER SINCE INBOUND #747, not the literal 2, so this asserts on the selection
# variable and separately on the seam being consulted. The previous form matched 'tier2Entries', and it
# passed for the whole life of the defect: a hardcoded 2 is exactly what it was written to describe. That is
# the shape worth naming here -- a source-text assert pins the mechanism it was written against, so it goes
# green on the bug it is closest to rather than red.
Assert-True ($cutReleaseText -match 'audienceEntries') 'the audience section is built from a tier selection'
Assert-True ($cutReleaseText -match 'Get-EntryAudienceTier') "and the tier comes from the repo's own seam, not a hardcoded 2"
Assert-True ($cutReleaseText -match '\$_\.Tier -eq \$audienceTier') 'the selection compares against that resolved tier'
Assert-True ($cutReleaseText -notmatch '\$_\.Tier -eq 2') 'and no literal tier-2 comparison survives'
# MATCHED AGAINST CODE ONLY, with comments stripped first. The script explains WHY those knobs were
# retired, and it names them to do so -- so a plain -notmatch fails on the explanation rather than on a
# use. That is this repo's own "a matcher satisfied by a mention rather than a use" defect, in reverse:
# here the mention is the legitimate thing and the use is what must be gone.
$cutReleaseCode = ($cutReleaseText -replace '(?s)<#.*?#>', '') -split "`r?`n" |
    Where-Object { $_ -notmatch '^\s*#' } | ForEach-Object { $_ -replace '\s#.*$', '' }
$cutReleaseCode = $cutReleaseCode -join "`n"
Assert-True ($cutReleaseCode -match 'Get-PullRequestEntriesByTier') 'the comment-stripped view still contains real code (the strip did not empty it)'
foreach ($gone in 'Get-ReleaseHighlightsStakeholderTypes', 'Get-ReleaseHighlightsWording', '-StakeholderTypes', '-DevBlockHeading') {
    Assert-True ($cutReleaseCode -notmatch [regex]::Escape($gone)) "cut-release no longer CALLS '$gone' -- the marker it configured is retired"
}
# The threshold behind the major rule is repo-owned rather than hardcoded: a shared script must not pin
# every consumer to one repo's release cadence.
Assert-True ($cutReleaseText -match 'Get-ReleaseMajorMinMinors') 'the minors-before-a-major threshold comes from the seam'

# THE RENAMED SEAM IS READ UNDER BOTH NAMES (August 10, 2026). The knob was Get-ReleaseHighlightsBumps
# before the tier was named after its reader, and this is the one rename in the set that can break a
# consumer in SILENCE: the fallback for an undefined seam is @(), which is the tier switched OFF, so a repo
# still carrying the old name would cut a minor, write no document for the very consumer it was cut for,
# and report success. Consumers receive the rename through a plugin update rather than by choosing to.
# Asserted on the CODE view, so a mention in the explaining comment cannot satisfy it -- the same trap the
# retired-knob check two blocks up is written around.
Assert-True ($cutReleaseCode -match 'Get-ReleaseConsumerBumps') 'the current seam name is read'
Assert-True ($cutReleaseCode -match 'Get-ReleaseHighlightsBumps') `
    'the retired seam name is STILL read as a fallback -- dropping it silently switches the tier off for a consumer'
# ORDER MATTERS, not just presence: the current name has to be tried FIRST, or a repo that defines both
# (mid-migration, which is exactly when this runs) would keep answering from the retired one.
$newIdx = $cutReleaseCode.IndexOf('Get-ReleaseConsumerBumps')
$oldIdx = $cutReleaseCode.IndexOf('Get-ReleaseHighlightsBumps')
Assert-True ($newIdx -ge 0 -and $oldIdx -gt $newIdx) 'the current name is tried before the retired one'

# THE SECOND RENAMED SEAM, SAME SHAPE (issue #947, August 26, 2026). The tier-0 notes root was
# Get-ReleaseDevelopmentNotesRoot until the directory rename of #914 caught up with it. It breaks LOUDER
# than the one above rather than in silence -- a cut that resolves the wrong root writes its note into a
# second tree beside the consumer's own, which they see -- but it breaks in the same way, so it is read
# under both names in the same order. Asserted on the CODE view, so the explaining comment above the read
# cannot satisfy it.
Assert-True ($cutReleaseCode -match 'Get-ReleaseChangelogNotesRoot') 'the current tier-0 root seam name is read'
Assert-True ($cutReleaseCode -match 'Get-ReleaseDevelopmentNotesRoot') `
    'the retired tier-0 root seam name is STILL read as a fallback -- dropping it starts a second notes tree for a consumer'
$newRootIdx = $cutReleaseCode.IndexOf('Get-ReleaseChangelogNotesRoot')
$oldRootIdx = $cutReleaseCode.IndexOf('Get-ReleaseDevelopmentNotesRoot')
Assert-True ($newRootIdx -ge 0 -and $oldRootIdx -gt $newRootIdx) 'the current tier-0 root name is tried before the retired one'
# And the reader itself must accept more than one name, or the pair above is two arguments to a parameter
# that only ever looks at the first. Get-SeamValue ITSELF MOVED OUT OF THIS FILE (issue #885, group A) into
# seam-lib.ps1, so the signature is asserted there now -- plus that this file actually reads through it
# rather than carrying a private copy again.
Assert-True ($seamLibText -match '\[string\[\]\]\$Name') 'Get-SeamValue takes a LIST of names, so a renamed seam can be read under both'
Assert-True ($cutReleaseText -notmatch '(?m)^function Get-SeamValue') `
    'cut-release.ps1 no longer carries its own private copy of Get-SeamValue'
Assert-True ($cutReleaseText.Contains('lib\seam-lib.ps1')) `
    'and dot-sources the shared one instead'

# WHERE THE NOTE GOES IS A SEAM TOO (inbound #616), and this assert exists because the knob above was
# unanswerable without it: for a repo whose hand-written notes live elsewhere, naming the bumps pointed
# the cut at a directory that does not exist there, so the only safe value was @() -- the tier switched
# off. Asserted on the CODE view so an explaining comment cannot satisfy it, and on the ABSENCE of the
# literal too, because adding the seam beside a hardcoded path would read as adopted while changing
# nothing.
Assert-True ($cutReleaseCode -match 'Get-ReleaseNoteRoot') 'the note root comes from the seam'
# NOT "the literal is absent" -- it must appear exactly once, as the seam's own -Default, which is what
# keeps this change invisible to every repo that does not repoint it. So the assert is on the COUNT and
# on where that one occurrence sits: a second use is a path built by hand behind the seam's back, which
# would read as adopted while changing nothing.
#
# BOTH SLASH SPELLINGS, and that widening is the transferable half of this file. This matched
# 'releases/notes' alone until August 13, 2026, and it was CORRECT and PASSING while the note's own
# directory was built from "releases\notes\$notesDirName" twenty lines below the write -- a third escape
# of the same seam, invisible here purely because PowerShell accepts a backslash in a path literal.
# Verified RED against that line before being trusted: with the backslash form matched, the count came to
# 2 and the second line carried no -Default. The lesson is the one this repo keeps paying for -- a matcher
# that knows one spelling while the code uses another reads as thorough and sees nothing -- so match the
# separator as a CLASS rather than adding a third assert per spelling somebody thinks of next.
$noteRootLiteralLines = @($cutReleaseCode -split "`n" | Where-Object { $_ -match 'releases[\\/]notes' })
Assert-True ($noteRootLiteralLines.Count -eq 1) 'the default note root is written exactly once in the code'
Assert-True ($noteRootLiteralLines.Count -eq 1 -and $noteRootLiteralLines[0] -match '-Default') `
    'and that one occurrence is the seam default, not a path built behind the seam'
# AND THE OVERVIEW ROW'S VERSION CELL IS WHERE THE SEAM ESCAPED ANYWAY, which is the reason this assert
# exists beside the two above rather than trusting them. They were written to catch exactly this class of
# defect and they PASSED while the row was built from a bare 'notes/': they match the FULLY-QUALIFIED form,
# and the escape was the short one. That is this repo's own recurring failure -- a matcher that reads as
# thorough and cannot see the instance -- caught here only because the cut was run with -NoPush and a person
# read the row.
#
# MEASURED AT THE v4.6.0 CUT (August 12, 2026): the row pointed at notes/4.x/4.6.0.md, which did not exist,
# while the same run wrote releases/audience/4.x/4.6.0.md. Nothing errored. Every neighbouring row was
# correct, because a PR had repointed them by hand the day before -- so the one row a script wrote was the
# only wrong one, in the document a reader uses to find any release note at all.
$versionCell = [regex]::Match($cutReleaseCode, '(?m)^\s*\$versionTarget\s*=.*$')
Assert-True $versionCell.Success "found the line that builds the overview row's Version cell"
Assert-True ($versionCell.Success -and $versionCell.Value -notmatch '"notes/') `
    'the Version cell carries no bare "notes/" literal -- the short form the two asserts above cannot see'
# SINCE AUGUST 14, 2026 THE CELL IS A COMPUTED RELATIVE PATH, not a leaf stripped with
# `-replace '^releases/'`: a consumer whose history lives at contributing-davekjohn/releases/README.md is
# the root-outside-releases/ case the old line's own comment said no repo had asked for yet. The cell
# must come from Get-RelativeLinkPath, anchored on the history file's directory, fed by the seam.
Assert-True ($versionCell.Success -and $versionCell.Value -match 'Get-RelativeLinkPath') `
    'and is computed relative to the history file rather than by stripping a hardcoded prefix'
# ON THE DERIVATION, NOT JUST THE FUNCTION NAME: the target handed to that computation must carry the
# note-root seam variable, or a literal behind the call would read as adopted while changing nothing --
# the same trap the seam-default count guards.
Assert-True ($cutReleaseCode -match '\$rowTargetRel\s*=.*\$noteRootRelPath') `
    'and the row target is derived from the seam variable, so repointing the root moves the row with it'
# A SEAM THAT REACHES ONLY THE WRITER IS THE FAILURE THIS ONE HAD TO AVOID: session-status.ps1 looks for
# the newest note, so a repo that repointed the root would have it written to the new place and looked
# for in the old, reported as "no release note was found". Pinned here rather than only in that script's
# own suite, because the pair is what makes the seam true -- and nothing else compares the two files.
$sessionStatusPath = Join-Path $RepoRoot 'scripts\task\session-status.ps1'
$sessionStatusText = [System.IO.File]::ReadAllText($sessionStatusPath, [System.Text.Encoding]::UTF8)
Assert-True ($sessionStatusText -match 'Get-ReleaseNoteRoot') 'the reader of those notes reads the same seam as the writer'

# The seam has to reach the message that fires when the history file is MISSING, which is the one moment
# the reader is about to go looking for the path it names. It was the single literal left among three
# messages about the same file.
$historyMissing = [regex]::Match($cutReleaseText, '(?m)^\s*Write-Warning "[^"]*row not added[^"]*"$')
Assert-True $historyMissing.Success 'found the missing-history warning'
Assert-True ($historyMissing.Success -and $historyMissing.Value -match '\$historyRelPath') `
    'the missing-history warning names the seam, not the default path'

Write-Host "cut-release.ps1 -- the new-major refusal names BOTH edits a major needs" -ForegroundColor Cyan
# WHY THIS IS PINNED AT ALL. Opening a new major takes two hand edits, not one: the overview section, and
# the test that pins which major the overview targets. The refusal used to name only the first, so on
# August 9, 2026 cutting v4.0.0 meant following advice that read as complete and then hitting a red test
# nobody had been warned about -- two commits where the message promised one. The advice is prose, so
# nothing but a check like this keeps it from being trimmed back to the shorter, wronger version.
#
# ASSERTED ON THE ADVICE BLOCK, NOT ON THE WHOLE FILE, and that distinction is the point: the file also
# EXPLAINS this repair in a comment, so a file-wide match would pass on the explanation while the message
# itself said nothing -- exactly the "satisfied by a mention rather than a use" defect the block above
# guards against in the other direction.
$adviceBlock = [regex]::Match($cutReleaseText, '(?s)"Add the section first.*?is not done for you\."')
Assert-True $adviceBlock.Success 'found the new-major advice block in cut-release.ps1'
Assert-True ($adviceBlock.Success -and $adviceBlock.Value -match 'pins the targeted major in a test') `
    'the advice tells the reader the pinned assert has to be repointed too'
# The advice must keep saying WHERE these commits go, because that is the half the safety rules answer:
# they run on the trunk ahead of the release commit, under the same request that authorised the cut.
Assert-True ($adviceBlock.Success -and $adviceBlock.Value -match 'trunk ahead of') `
    'and that both edits belong to this cut, on the trunk ahead of the release commit'
# The milestone sentence is the DECISION not to automate any of this. If it ever disappears, the next
# reader has a checklist with no reason attached, which is how a deliberate manual step gets "fixed".
Assert-True ($adviceBlock.Success -and $adviceBlock.Value -match 'deliberate milestone moment') `
    'and it still says why none of it is done for you'

Write-Host ""
Write-Host "cut-release.ps1 -- a repo that runs what it releases is reminded its install is behind" -ForegroundColor Cyan
# WHY THIS IS A SOURCE-TEXT ASSERT AND NOT A RUN. Driving the whole script needs a repo to cut, and the
# rest of this suite reads the source for exactly that reason. What is pinned here is that the reminder
# EXISTS, is REACHED from the closing block, and stays CONDITIONAL -- the three properties that make it
# a reminder rather than noise for a consumer who releases a product they do not themselves run.
$cutSrc = $cutReleaseText
Assert-True ($cutSrc -match 'function Write-SelfConsumptionReminder') `
    'cut-release defines the self-consumption reminder'
Assert-True ($cutSrc -match 'Write-SelfConsumptionReminder\s*[\r\n]') `
    'and calls it from the follow-up block, so it is actually reached'
Assert-True ($cutSrc -match 'claude plugin marketplace update') `
    'and it names the marketplace refresh, which is the step the plugin update alone does not do'
Assert-True ($cutSrc -match '--scope project') `
    'and the per-plugin update carries --scope project, the scope lesson this repo already paid for'
Assert-True ($cutSrc -match "like \`"\*@\`$marketplaceName\`"") `
    'and it fires only for plugins from the marketplace THIS repo declares -- a repo that does not run what it releases gets nothing'
Assert-True ($cutSrc -match '(?s)function Write-SelfConsumptionReminder.*?catch \{') `
    'and it is wrapped so a reminder can never break a cut that has already committed and tagged'

if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
