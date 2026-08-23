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

    WHAT IT DOES NOT DO. It reads no PR body and knows nothing about labels, previews or review state. A
    repo whose merge rule turns on something a visitor can see gates that separately -- one consumer does,
    against its own PR template, and that template is its own rather than anything this plugin ships.

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

.PARAMETER RootOverride
    Repo root to operate on, for the test suite. A consumer never types this: the root is resolved
    dual-context like every other shared script.

.EXAMPLE
    powershell -NoProfile -File scripts/lint/check-branch-entry.ps1 -Branch fix/something
#>
[CmdletBinding()]
param(
    [string]$Branch = '',
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
    # The trunk is where the fold RESETS the entry, so judging it would report the reset state as a
    # defect on every push. Said out loud rather than silently passing: a gate that answers 0 for a
    # reason it does not name is a gate somebody will point at the trunk and believe.
    Write-Host "[OK] '$Branch' is the trunk, where the fold leaves the entry in its reset state by design."
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

$entryRel  = Resolve-BranchFilePath -Kind Deployment -RepoRoot $repoRoot
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

# THE DEPLOY SECTION, NOT THE WHOLE DOCUMENT. The entry is a section of development-cycle.md since
# August 23, 2026, and every reader below is entry-shaped -- handed the plan as well, the scaffold check
# would accuse the step list of being an unfinished entry. Get-DevelopmentCycleEntryText hands back the
# whole text for a legacy file that IS an entry, so a branch created before the merge is read as it was.
$fileText  = [System.IO.File]::ReadAllText($entryPath, [System.Text.Encoding]::UTF8)
$entryText = Get-DevelopmentCycleEntryText -Text $fileText

# "IS THIS THE RESET STATE" IS A QUESTION ABOUT THE DOCUMENT, NOT ABOUT THE SECTION -- and asking it of the
# section is a measured defect rather than a hypothetical. A reset document's DEPLOY section opens with its
# own '##', so the level half of Test-BranchChangelogIsFilled reads it as an entry: the gate then fell
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
