<#
.SYNOPSIS
    Drift guard for cut-release.ps1's stray-entry allowlist ($reservedRootMd).

.DESCRIPTION
    cut-release.ps1 refuses to cut a release while an "unfolded changelog entry file" sits in the
    repo root. It recognises an entry by exclusion: every root *.md that is NOT in the $reservedRootMd
    allowlist is treated as an entry. That is deliberately catch-all (so an entry with an unknown
    branch prefix is never missed), but it means every PERMANENT root doc (README, CONTRIBUTING,
    SECURITY, ...) must be listed in the allowlist -- otherwise a release falsely refuses to cut the
    moment such a doc is added. That drift once blocked a real release (CONTRIBUTING.md/SECURITY.md
    were added to the root but not to the allowlist).

    This test catches that drift automatically: every TRACKED root *.md that is not a branch-prefixed
    changelog entry (feat-/fix-/docs-/chore-*.md) must appear in cut-release.ps1's $reservedRootMd.
    Reads the allowlist straight out of the script text (cut-release.ps1 runs its guardrails on load,
    so it cannot be dot-sourced) and compares it against the actual tracked root docs via git.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/cut-release-guardrail.tests.ps1

    Pure ASCII (repo convention for .ps1).
#>
$ErrorActionPreference = 'Stop'

$RepoRoot       = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$CutReleasePath = Join-Path $RepoRoot 'scripts\release\cut-release.ps1'

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

Write-Host "cut-release.ps1 -- reserved-root-md allowlist covers every permanent root doc" -ForegroundColor Cyan

# 1. Parse the allowlist literal out of the script text.
$cutReleaseText = [System.IO.File]::ReadAllText($CutReleasePath, [System.Text.Encoding]::UTF8)
$m = [regex]::Match($cutReleaseText, '\$reservedRootMd\s*=\s*@\(([^)]*)\)')
Assert-True $m.Success 'found the $reservedRootMd allowlist literal in cut-release.ps1'
$allowlist = @([regex]::Matches($m.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
Assert-True ($allowlist.Count -gt 0) 'allowlist parsed to at least one entry'

# 2. Tracked root *.md files (no directory separator = repo root), excluding branch-prefixed entries.
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $tracked = @(& git -C $RepoRoot ls-files -- '*.md' 2>$null)
} finally {
    $ErrorActionPreference = $prevEap
}
$rootMd = @($tracked | Where-Object { $_ -and ($_ -notmatch '/') })
# A branch changelog entry file is named after its branch: <prefix>-<name>.md with a known prefix.
$entryPattern = '^(feat|fix|docs|chore)-.*\.md$'
$permanentDocs = @($rootMd | Where-Object { $_ -notmatch $entryPattern })
Assert-True ($permanentDocs.Count -gt 0) 'found tracked permanent root docs to check'

# 3. Every permanent root doc must be covered by the allowlist -- otherwise a release would falsely
#    flag it as an unfolded entry and refuse to cut.
$uncovered = @($permanentDocs | Where-Object { $allowlist -notcontains $_ })
Assert-True ($uncovered.Count -eq 0) "every permanent root doc is in `$reservedRootMd (uncovered: $($uncovered -join ', '))"

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
# The consumer document is the tier-2 selection now, not a category guess -- and the two retired seam
# knobs must not come back with it.
Assert-True ($cutReleaseText -match 'tier2Entries') 'the consumer document is built from the tier-2 entries'
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
# And the reader itself must accept more than one name, or the pair above is two arguments to a parameter
# that only ever looks at the first.
Assert-True ($cutReleaseText -match '\[string\[\]\]\$Name') 'Get-SeamValue takes a LIST of names, so a renamed seam can be read under both'

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
if ($script:fail -gt 0) {
    Write-Host "FAILS: $($script:fail) failed, $($script:pass) passed." -ForegroundColor Red
    exit 1
}
Write-Host "OK: all $($script:pass) asserts passed." -ForegroundColor Green
exit 0
