<#
.SYNOPSIS
    Gate: does this branch carry a written changelog entry? For CI, so the branch-entry convention is
    enforced by something other than goodwill (inbound #789).

.DESCRIPTION
    THE CONVENTION SHIPPED WITH NOTHING ENFORCING IT. open-pr refuses to push an unwritten entry and
    ship-pr refuses to merge with unresolved steps -- but both are local, and a branch pushed by hand or
    a PR opened in the GitHub UI meets neither. So both consumers wrote a CI gate for this, from scratch,
    against the same convention. That is a second definition of the format in every consumer, free to
    drift from the fold that reads the first one, and it HAD drifted: measured on pickup, both
    hand-written gates refuse a merge over a missing significance score, which is a refusal Dave
    deliberately placed at the release cut instead (open-pr.ps1, August 5, 2026 -- "an author who has not
    settled it should not be blocked from merging over it"), justified in one of them by "tier 0 can
    never legitimately stay empty" while this system's own rule reads TIER 0 OWES NOTHING.

    SO THIS SCRIPT ADDS NO RULE OF ITS OWN. It calls the two functions open-pr already calls -- there is
    exactly one definition of "written" in the system and this is not a second one:

        Test-BranchChangelogIsFilled   is the file an entry at all, or the reset state the fold leaves?
        Get-EntryScaffoldFindings      which fields is the scaffolder still waiting for?

    That second one is why no test on the score is needed. A freshly scaffolded entry already carries an
    H2 and a title, so a heading test passes it -- the case the hand-written gates reached for the score
    to catch. Get-EntryScaffoldFindings answers it properly: it measures the fields the scaffolder left,
    names each one, and catches an untouched entry AND one whose prompt was deleted rather than answered.
    The gate that reuses it is therefore SIMPLER than the one written by hand, not more complex.

    THE SIGNIFICANCE IS REPORTED, NEVER REFUSED, for the reason above. An entry whose scores are not
    settled is a branch that can merge and a release that cannot be cut from it; this prints what the cut
    will say, so the author learns it here rather than at the cut, and merges anyway.

    THE DEPLOY LOCK, AND IT IS WHY THIS SCRIPT NOW READS A PR BODY AT ALL (Dave, issue #884,
    August 25, 2026). The DEPLOY section travels four times -- development.md, the PR body,
    CHANGELOG.md, the release notes -- and is fixed at the moment the PR opens, because that is what the
    review approved and what the fold takes. ship-pr refuses the merge on divergence, and ship-pr is
    local, which is this gate's whole reason for existing. It ADDS NO RULE HERE EITHER: the comparison is
    Test-DeployLock in pr-body-lib, the same function ship-pr calls.

    ONLY WITH -Pr, AND SILENT-BUT-SAID WITHOUT IT. This paragraph replaces one that read "It reads no PR
    body and knows nothing about labels, previews or review state" -- and the half of that which was
    load-bearing is kept rather than quietly dropped: the entry checks above still need no token, no
    network and no PR, so the gate stays runnable on a branch that has none. The lock is therefore
    OPT-IN by parameter rather than resolved from the branch. What has genuinely changed is only that a
    caller may now hand it a PR number, and what has NOT is review state: a text comparison against a
    published copy is not a judgement a visitor makes. A repo whose merge rule turns on something a
    visitor can SEE still gates that separately -- one consumer does, against its own PR template, and
    that template is its own rather than anything this plugin ships.

    AN UNREADABLE BODY IS NOT A FINDING, the same tolerance ship-pr applies: gh failing says something
    about the token or the network, not about the section, and a gate that refused on that would be
    refusing on no evidence.

    RUN IT FROM CI, and from the command line whenever you want the answer early:

        powershell -NoProfile -File scripts/lint/check-branch-entry.ps1
        powershell -NoProfile -File scripts/lint/check-branch-entry.ps1 -Branch feat/something

    Exit 0 when the entry is written or the branch is exempt; exit 1 with an actionable message otherwise.

    SEAM IT READS, from the consumer's own scripts/repo-config.ps1, probed with Get-Command like every
    other optional knob:

      Get-EntryGateExemptPrefixes   branch prefixes that owe no entry. Default: 'sync'. A mirror branch
                                    carries somebody else's work rather than this repo's, so there is
                                    nothing for it to declare -- both consumers reached that answer
                                    independently, with nothing recording that it was the expected one.

    Pure ASCII, per this repo's script-layer convention.

.PARAMETER Branch
    The branch to judge. Defaults to the current one. CI passes the PR's head ref, because a pull_request
    checkout is a detached merge commit and 'git rev-parse --abbrev-ref HEAD' answers 'HEAD' there.

.PARAMETER Pr
    The PR number to hold the DEPLOY section against, enabling the lock. Omitted, the lock is skipped and
    the run says so -- every other check here needs no PR, no token and no network, and that stays true.
    CI passes the pull_request event's own number; on the command line it is what makes "does my PR still
    match my document?" answerable before the merge refuses it.

.PARAMETER RootOverride
    Repo root to operate on, for the test suite. A consumer never types this: the root is resolved
    dual-context like every other shared script.

.EXAMPLE
    powershell -NoProfile -File scripts/lint/check-branch-entry.ps1 -Branch fix/something
#>
[CmdletBinding()]
param(
    [string]$Branch = '',
    [string]$Pr = '',
    [string]$RootOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# THE SOURCE-REPO GUARD: refuses this script when it is a released copy running in the repo that
# maintains it. Guarded dot-source, so a tree without the lib behaves as before. Why: the lib's header.
# It cannot fire in a consumer's CI, and that is by its own design rather than by luck -- its second
# condition is that the repo being operated on publishes plugins, which a consumer does not.
$guardLib = Join-Path $PSScriptRoot '..\lib\source-repo-guard-lib.ps1'
if (Test-Path -LiteralPath $guardLib -PathType Leaf) { . $guardLib; Assert-OwnCopy -ScriptPath $PSCommandPath }

# Dual-context repo root: a consumer running the plugin mirror gets it from CLAUDE_PROJECT_DIR, the
# source root copy falls back to the git root. Same resolution as every other mirrored script.
$repoRoot = if ($RootOverride) { $RootOverride } elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (git rev-parse --show-toplevel).Trim() }

# repo-config.ps1 first and optional, exactly as new-branch and adopt-workflow-folder load it. It is not
# only the seam above: entry-scaffold-lib reads the wording overrides from it, and a gate that judged an
# entry against the ENGLISH scaffold wording in a repo that translated it would accuse a finished entry.
$repoConfig = Join-Path $repoRoot 'scripts\repo-config.ps1'
if (Test-Path -LiteralPath $repoConfig -PathType Leaf) {
    try { . $repoConfig } catch { Write-Warning "scripts/repo-config.ps1 failed to load ($($_.Exception.Message)) -- the built-in wording is used." }
}

. (Join-Path $PSScriptRoot '..\lib\entry-scaffold-lib.ps1')

# For the DEPLOY lock, and only reached when -Pr is given. Loaded AFTER entry-scaffold-lib, because
# Get-PrDescription probes the section-heading seams with Get-Command: a repo that renamed a heading is
# read by its own names only while that lib is already in the session. native-capture-lib is what keeps
# the gh call out of PowerShell 5.1's native-stderr trap, where a zero exit code still sets $? to false.
. (Join-Path $PSScriptRoot '..\lib\pr-body-lib.ps1')
# Test-IsWorkflowSourceRepo, for the heading rule's source-repo scoping (#898). The one-file test -- a repo
# with .claude-plugin/marketplace.json is the workflow's source -- already factored out here rather than
# repeated a fifth time. Both issues that asked for this scoping named it 'Test-SourceRepo', which exists
# nowhere; the mechanism is real and this is its name.
. (Join-Path $PSScriptRoot '..\lib\seam-lib.ps1')
. (Join-Path $PSScriptRoot '..\lib\native-capture-lib.ps1')

# branch-info.ps1 is REPO-OWNED and does not travel with the plugin -- every consumer keeps their own
# prefix table -- so it is loaded from the repo being judged, guarded. All this gate wants from it is
# SafeName for the legacy entry path, which is one substitution, so a repo without the lib degrades to
# computing it here rather than to a failure.
$branchInfoLib = Join-Path $repoRoot 'scripts\lib\branch-info.ps1'
if (Test-Path -LiteralPath $branchInfoLib -PathType Leaf) {
    try { . $branchInfoLib } catch { Write-Warning "scripts/lib/branch-info.ps1 failed to load ($($_.Exception.Message)) -- the legacy entry path is resolved without it." }
}

if (-not $Branch) {
    $Branch = (git -C $repoRoot rev-parse --abbrev-ref HEAD).Trim()
}
if (-not $Branch -or $Branch -eq 'HEAD') {
    Write-Host '[ERROR] Could not tell which branch to judge, and refusing to guess.' -ForegroundColor Red
    Write-Host '        A pull_request checkout is a detached merge commit, so pass the head ref explicitly:'
    Write-Host '        -Branch "${{ github.head_ref }}"'
    exit 1
}

$trunk = if (Get-Command Get-TrunkBranchName -ErrorAction SilentlyContinue) {
    $t = ([string](Get-TrunkBranchName)).Trim(); if ($t) { $t } else { 'main' }
} else { 'main' }

if ($Branch -eq $trunk) {
    # The trunk is where the fold REMOVES the document, so judging it would report the trunk's own normal
    # state as a defect on every push. Said out loud rather than silently passing: a gate that answers 0 for
    # a reason it does not name is a gate somebody will point at the trunk and believe.
    Write-Host "[OK] '$Branch' is the trunk, where the fold removes the document by design."
    Write-Host '     Nothing to judge here -- point this at a branch, or run it on pull_request only.'
    exit 0
}

# --- Exempt prefixes -------------------------------------------------------------------------------
$exempt = if (Get-Command Get-EntryGateExemptPrefixes -ErrorAction SilentlyContinue) {
    @(Get-EntryGateExemptPrefixes)
} else { @('sync') }

$prefix = if ($Branch -match '/') { ($Branch -split '/')[0] } else { ($Branch -split '-')[0] }
if ($exempt -contains $prefix) {
    Write-Host "[OK] '$Branch' carries the exempt prefix '$prefix', which owes no entry."
    exit 0
}

# --- The entry --------------------------------------------------------------------------------------
# Same resolution open-pr uses, and for the same reason: the file has moved twice and a branch created
# before a move carries the older path. Preferring the current one and falling back is what lets a
# branch cut over mid-flight without this gate suddenly finding nothing -- which would not merely warn,
# it would PASS, since a gate with nothing to read reports nothing.
$safeName = if (Get-Command Get-BranchInfo -ErrorAction SilentlyContinue) {
    (Get-BranchInfo -Branch $Branch).SafeName
} else { $Branch -replace '/', '-' }

# -Branch IS PASSED AND NOT GUESSED (#1255), for the reason this whole script takes it as a parameter: a
# pull_request checkout is a detached merge commit, so the resolver's own fallback -- rev-parse HEAD -- reads
# 'HEAD' here and would find no per-branch file at all.
$entryRel  = Resolve-BranchFilePath -Kind Deployment -RepoRoot $repoRoot -Branch $Branch
$entryPath = Join-Path $repoRoot $entryRel
if (-not (Test-Path -LiteralPath $entryPath)) {
    $entryPath = Join-Path $repoRoot ($safeName + '.md')
    $entryRel  = $safeName + '.md'
} elseif (-not (Test-BranchChangelogIsFilled -Text ([System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)))) {
    # Present but in its reset state: this branch may still be carrying a legacy root entry, and the
    # reset file must not be read as an empty one.
    $legacyPath = Join-Path $repoRoot ($safeName + '.md')
    if (Test-Path -LiteralPath $legacyPath) { $entryPath = $legacyPath; $entryRel = $safeName + '.md' }
}

if (-not (Test-Path -LiteralPath $entryPath)) {
    Write-Host "[ERROR] '$entryRel' does not exist, so this branch declares nothing." -ForegroundColor Red
    Write-Host '        The new-branch skill creates the branch and both of its files in one step; run it'
    Write-Host '        on this branch (it is idempotent) and write what the change does.'
    exit 1
}

# THE DEPLOY SECTION, NOT THE WHOLE DOCUMENT. The entry is a section of development.md since
# August 23, 2026, and every reader below is entry-shaped -- handed the plan as well, the scaffold check
# would accuse the step list of being an unfinished entry. Get-DevelopmentEntryText hands back the
# whole text for a legacy file that IS an entry, so a branch created before the merge is read as it was.
$fileText  = [System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)
$entryText = Get-DevelopmentEntryText -Text $fileText

# "IS THIS THE RESET STATE" IS A QUESTION ABOUT THE DOCUMENT, NOT ABOUT THE SECTION -- and asking it of the
# section is a measured defect rather than a hypothetical. A reset document's DEPLOY section opens with a
# heading of its own, so the level half of Test-BranchChangelogIsFilled reads it as an entry: the gate then fell
# through to the scaffold check and refused a reset file with "has not been written yet" instead of "still
# in its reset state". Correct verdict, wrong reason, and the wrong reason sends the reader to write in a
# file they should not be writing in at all. Caught by branch-entry-gate.tests.ps1.
if (-not (Test-BranchChangelogIsFilled -Text $fileText)) {
    Write-Host "[ERROR] '$entryRel' is still in its empty reset state, so this branch has no entry." -ForegroundColor Red
    Write-Host '        The reset state is what the fold leaves behind after a merge; its heading names the'
    Write-Host '        TRUNK, and a written one names your branch. Run the new-branch skill on this branch'
    Write-Host '        and write what the change does.'
    exit 1
}

$scaffoldFindings = @(Get-EntryScaffoldFindings -EntryText $entryText -Wording (Get-EntryScaffoldWording))
if ($scaffoldFindings.Count -gt 0) {
    Write-Host "[ERROR] '$entryRel' has not been written yet:" -ForegroundColor Red
    foreach ($f in $scaffoldFindings) { Write-Host "          - $($f.Label): '$($f.Marker)'" -ForegroundColor Red }
    Write-Host '        Each line is a field the scaffolder left for you with nothing in it, wording it'
    Write-Host '        wrote that is still standing, or -- for a tier -- an answer written one line too'
    Write-Host '        low. The guidance comments do not count as an answer: the fold strips them, so a'
    Write-Host '        section that looks filled in on the branch lands in the changelog empty.'
    exit 1
}

Write-Host "[OK] '$entryRel' carries a written entry."

# --- The document's SHAPE: four phases (#898) and a generic preamble (#899) ---------------------------
# TWO RULES DAVE ENFORCED BY READING, on a document a session writes, with no signal in between. Both were
# caught by eye on August 26, 2026, on the same document, within one afternoon -- and the second one had
# been introduced by the session before, in the same position, which is what makes it a shape the document
# invites rather than a slip.
#
# THEY ARE SCOPED DIFFERENTLY, AND THAT ASYMMETRY IS THE DESIGN rather than an inconsistency:
#
#   #898, the heading count, is the SOURCE REPO's rule. DEVELOPMENT-portable.md states heading-blindness
#   as a FEATURE -- "the gate reads step marks only, so a heading of any level is invisible to it" -- and
#   the reason it is a feature is that a consumer may keep headings of their own in a document they
#   adopted. Refusing those everywhere would break correct files in somebody else's repo, which is the
#   shape this house declined once already at 124 findings, all false. So it runs behind
#   Test-IsWorkflowSourceRepo and this family is held to its own rule.
#
#   #899, the preamble, holds EVERYWHERE, because it reads the SHAPE and not the text. The region between
#   the title and the first phase heading is the scaffolder's guidance, which is blockquoted whatever language it has
#   been translated into -- so "a non-blank line that does not start with '>'" survives translation. A byte
#   comparison against StepsGuidance could not: it carries a '{0}' seam the consumer answers themselves,
#   and inbound #562 is the measured consumer who translated the block around it.
#
# WHY THE PREAMBLE ONE IS NOT MERELY TIDINESS. The measured paragraph sat flush under the guidance with no
# heading between them, so it READ as guidance -- and guidance is generic by construction. A reader who
# finds one branch's status inside it learns to distrust the whole region, including the rules that do
# apply everywhere.
#
# NEITHER RE-DERIVES WHERE THE ENTRY BEGINS. Split-Development is the one splitter three readers
# already share, and it is fence-aware because a document explaining this format quotes its own headings.
# A second parser here is exactly the drift entry-scaffold-lib.ps1 exists to prevent.
$shapeFindings = @()
$cycleHalves = Split-Development -Text $fileText
$headText = [string]$cycleHalves.Head

# Fence tracking, so a quoted heading is illustration rather than a phase. Same rule check 4 of the lint gate
# argues for links and check 28 for imports.
#
# THE LEVELS ARE READ OFF THE DOCUMENT, NOT PINNED, and a range would be wrong rather than merely loose
# (August 26, 2026). Both levels shifted one down that day: the title went H1 -> H2 and the phases H2 -> H3.
# So the new TITLE level and the old PHASE level are the same number, and a gate accepting '^#{2,3}' as a
# phase would read a post-shift title as a fifth phase -- refusing a correct document, which is the one
# failure mode this gate must not have. Reading the first heading as the title and the phases as exactly one
# level under it needs no era flag and no list of levels to maintain: it is the invariant the format has
# always had, and the one the suite already asserts as "the sections sit exactly one level under the title".
$titleLevel = 0
$inTitleProbe = $false
foreach ($probeLine in [regex]::Split($fileText, '\r?\n')) {
    if ($probeLine -match '^\s{0,3}(?:`{3,}|~{3,})') { $inTitleProbe = -not $inTitleProbe; continue }
    if ($inTitleProbe) { continue }
    if ($probeLine -match '^(#{1,6})\s+\S') { $titleLevel = $Matches[1].Length; break }
}
# No heading at all: fall back to the written pair, so a malformed document is judged by today's shape
# rather than skipping the check entirely.
if ($titleLevel -le 0) { $titleLevel = Get-BranchCycleHeadingLevel }
$phaseLevel = $titleLevel + 1
$phaseRx    = '^#{' + $phaseLevel + '}\s+(\S.*)$'
$titleRx    = '^#{1,' + $titleLevel + '}\s'
# AND EVERY FINDING BELOW QUOTES THESE INSTEAD OF TYPING A LEVEL (#924, August 26, 2026). The reasoning is
# already written out at the [OK] line further down -- "the level in this line is the one that was actually
# READ, not a literal" -- and it held for that one line only. Six markers on the FAILURE path were typed,
# so on the day the shape shifted one level down the gate refused a document for the new levels while
# reporting the old ones: it told a reader to demote a '###' to a '###', and pointed at "the first '##'"
# in a document whose phases are '###'. That is the worse way round of the two, because the failure
# message is the one somebody reads while they cannot yet see what is wrong.
$phaseMark = '#' * $phaseLevel
$subMark   = '#' * ($phaseLevel + 1)

$inShapeFence = $false
$shapeLineNo = 0
$topHeadings = @()
$preambleStrays = @()
$seenFirstTop = $false
foreach ($shapeLine in [regex]::Split($fileText, '\r?\n')) {
    $shapeLineNo++
    if ($shapeLine -match '^\s{0,3}(?:`{3,}|~{3,})') { $inShapeFence = -not $inShapeFence; continue }
    if ($inShapeFence) { continue }
    if ($shapeLine -match $phaseRx) {
        $seenFirstTop = $true
        $topHeadings += [pscustomobject]@{ Line = $shapeLineNo; Text = $Matches[1].Trim() }
        continue
    }
    if ($shapeLine -match $titleRx) { continue }
    # The preamble region: everything after the title and before the first phase heading. Blank lines and blockquote
    # lines are the guidance block; anything else is this branch's own content, sitting where the text is
    # supposed to be identical in every branch document in every repo.
    if (-not $seenFirstTop -and $shapeLine.Trim() -ne '' -and $shapeLine -notmatch '^\s*>') {
        $preambleStrays += [pscustomobject]@{ Line = $shapeLineNo; Text = $shapeLine.Trim() }
    }
}

# The arc is PLAN / CREATE / TEST / DEPLOY. Held only in the source repo -- see the block above.
#
# THE PHASES ARE NAMED, NOT COUNTED, and the first draft of this check got that wrong in a way worth
# recording: it reported "everything past the fourth heading", which named '## DEPLOY' as the extra the
# moment the stray sat ABOVE '## PLAN' -- which is exactly where both measured instances sat. A count
# cannot say WHICH heading does not belong; only the names can. Read from Get-BranchFileWording, the
# same source the scaffolder writes them from, so a repo that renames a phase is judged by its own names
# rather than by three literals typed here.
$knownPhases = @()
if (Get-Command Get-BranchFileWording -ErrorAction SilentlyContinue) {
    $knownPhases = @((Get-BranchFileWording).StepPhases | Where-Object { $_ })
}
if ($knownPhases.Count -eq 0) { $knownPhases = @('PLAN', 'CREATE', 'TEST') }

# DEPLOY is matched on its PREFIX, because its heading carries the branch name (DEPLOY: feat/x).
$strayHeadings = @($topHeadings | Where-Object {
    ($knownPhases -notcontains $_.Text) -and ($_.Text -notmatch '^DEPLOY\b')
})

if ($strayHeadings.Count -gt 0 -and (Test-IsWorkflowSourceRepo -RepoRoot $repoRoot)) {
    $shapeFindings += "carries $($topHeadings.Count) '$phaseMark' headings, and the arc is $($knownPhases -join ' / ') / DEPLOY -- four, never a fifth."
    foreach ($h in $strayHeadings) {
        $shapeFindings += "  extra heading, line $($h.Line): '$phaseMark $($h.Text)'"
    }
    $shapeFindings += "  Demote it to '$subMark' under whichever of the four it belongs to."
}

if ($preambleStrays.Count -gt 0) {
    $shapeFindings += "carries branch content above the first '$phaseMark', where the block is generic guidance:"
    foreach ($s in $preambleStrays) {
        $trimmed = if ($s.Text.Length -gt 72) { $s.Text.Substring(0, 72) + '...' } else { $s.Text }
        $shapeFindings += "  line $($s.Line): $trimmed"
    }
    $shapeFindings += '  That region is identical in every branch document in every repo, so a status note'
    $shapeFindings += "  there reads as guidance. Move it under one of the '$phaseMark' phases, as a '$subMark'."
}

if ($shapeFindings.Count -gt 0) {
    Write-Host "[ERROR] '$entryRel' $($shapeFindings[0])" -ForegroundColor Red
    foreach ($f in ($shapeFindings | Select-Object -Skip 1)) { Write-Host "        $f" -ForegroundColor Red }
    exit 1
}
# The level in this line is the one that was actually READ, not a literal: the checks above derive the phase
# level from the document's own title, so a message naming '##' would have described the wrong shape for every
# document written after August 26, 2026 -- and a coverage line that misreports what it read is worse than
# none, because it reads as confirmation. It quotes $phaseMark rather than composing a second time, which is
# what made the findings above disagree with this line for one day.
Write-Host "[OK] '$entryRel' keeps its shape: $($topHeadings.Count) '$phaseMark' heading(s), and nothing but guidance above the first."

# --- The DEPLOY lock: is the section still what the PR published? ------------------------------------
# Refused, not reported, which puts it with the checks above rather than with the significance below. The
# distinction is who the judgement belongs to: a significance score is the author's call about a finished
# change, so this gate names it and merges anyway; a section that no longer matches the PR is not a
# judgement at all, it is two copies of one text disagreeing, and the fold is about to pick one.
if ($Pr) {
    # -Utf8 for the same reason ship-pr.ps1 passes it (issue #907): this body is COMPARED against the
    # document, so it must not be decoded with whatever console code page the run inherited. CI runs
    # UTF-8 and would not have shown it; a local run of this gate is where it bites.
    $lockView = Invoke-NativeCapture -Utf8 -FilePath 'gh' -Arguments @('pr', 'view', "$Pr", '--json', 'body')
    if ($lockView.ExitCode -ne 0) {
        Write-Host "[INFO] PR #$Pr's body could not be read, so the DEPLOY lock was not checked." -ForegroundColor DarkYellow
        Write-Host '       That is a statement about the token or the network, not about the section.' -ForegroundColor DarkYellow
    } else {
        $lockBody = ''
        try { $lockBody = [string](($lockView.Output -join "`n") | ConvertFrom-Json).body } catch { $lockBody = '' }
        $lock = Test-DeployLock -EntryText $entryText -PrBody $lockBody
        if (-not $lock.Applicable) {
            Write-Host "[OK] nothing to lock against PR #$Pr -- this entry carries no DEPLOY heading of its own."
        } elseif ($lock.Locked) {
            Write-Host "[OK] the DEPLOY section still matches what PR #$Pr published."
        } else {
            Write-Host "[ERROR] '$entryRel' has changed since PR #$Pr was opened." -ForegroundColor Red
            if ($lock.FirstDrift -eq $lock.Heading) {
                Write-Host "        PR #$Pr's body does not carry the section at all -- its heading is missing:" -ForegroundColor Red
                Write-Host "          $($lock.Heading)" -ForegroundColor Red
            } else {
                Write-Host '        The first line the PR body does not have is:' -ForegroundColor Red
                Write-Host "          $($lock.FirstDrift)" -ForegroundColor Red
            }
            Write-Host '        The DEPLOY section is fixed when the PR opens: it is what the review approved,'
            Write-Host '        and the fold puts it verbatim into CHANGELOG.md and from there into the release'
            Write-Host '        notes. Put it back to what the PR published, or republish it deliberately with'
            Write-Host '        open-pr.ps1 -RefreshBody so the change is reviewable where the review happens.'
            exit 1
        }
    }
} else {
    Write-Host '[INFO] no -Pr given, so the DEPLOY lock was not checked (every check above needs none).' -ForegroundColor DarkGray
}

# --- The significance: reported, never refused ------------------------------------------------------
if (Test-EntrySignificanceActive) {
    $impactFindings = @(Get-EntryImpactFindings -EntryText $entryText)
    if ($impactFindings.Count -gt 0) {
        Write-Host '[INFO] the significance is not settled yet -- the RELEASE CUT will refuse until it is,' -ForegroundColor DarkYellow
        Write-Host '       and this gate deliberately will not: a score is a judgement about a finished' -ForegroundColor DarkYellow
        Write-Host '       change, and an author who has not settled it is not blocked from merging over it.' -ForegroundColor DarkYellow
        foreach ($f in $impactFindings) { Write-Host "         $f" -ForegroundColor DarkYellow }
    } else {
        $impact = Resolve-EntryImpact -EntryText $entryText
        $scored = @($impact.Rows | Where-Object { [int]$_.Score -gt 0 } | ForEach-Object { "tier $($_.Tier): $($_.Score)" })
        if ($scored.Count -gt 0) { Write-Host "[OK] significance -- $($scored -join ', ')" }
    }
}

exit 0
