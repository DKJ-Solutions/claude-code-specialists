<#
.SYNOPSIS
    Script-contract check: detects when a consumer's repo-owned workflow libs (scripts/lib/branch-
    info.ps1, scripts/repo-config.ps1) lag behind the function contract that the shared, mirrored
    workflow scripts (issue #81) actually call at runtime (LAYER 1 -- detection only, no fixes).

.DESCRIPTION
    The shared workflow scripts are centralized in the plugin, but dot-source REPO-OWNED libs from
    the consumer: scripts/lib/branch-info.ps1 and scripts/repo-config.ps1. After a plugin update
    these libs can lag the contract the shared scripts expect -- the real incident this check exists
    for (issue #147): after updating the plugin, the first `new-branch` run crashed with
    "The term 'Test-BranchName' is not recognized" because the consumer's branch-info.ps1 predated
    that helper. There was a roster-drift guard (check-roster-sync + roster-sessioncheck) but no
    equivalent guard for the repo-owned SCRIPT CONTRACT. This mirrors that architecture exactly.

    The declared contract (mandatory repo-owned functions per mirrored, consumer-run shared script):
      - new-changelog-entry -> branch-info.ps1: Get-BranchInfo
                               repo-config.ps1: Get-EntryTitlePlaceholder, Get-EntryBodyHeading,
                                                Get-EntryBodyPlaceholder, Get-EntryFallbackType
                                                (all OPTIONAL -- see below)
      - new-branch          -> branch-info.ps1: Test-BranchName
      - open-pr             -> branch-info.ps1: Get-BranchInfo
                               repo-config.ps1: Get-RepoName, Get-LintScript
      - fold-changelog-entry -> repo-config.ps1: Get-RepoName
                                repo-config.ps1: Get-ChangelogHeading (OPTIONAL -- see below)
      - check-roster-sync   -> repo-config.ps1: Get-RosterPath, Get-RosterIgnoredIds
      - cut-release skill   -> repo-config.ps1: Get-LiveStage (OPTIONAL -- see below)
      - ship-pr             -> repo-config.ps1: Get-RepoName
                               repo-config.ps1: Get-PrMergeMethod (OPTIONAL -- see below)
      - verify-resolved-issues -> repo-config.ps1: Get-RepoName
      - fix-mojibake        -> repo-config.ps1: Get-MojibakePaths (OPTIONAL -- see below)

    OPTIONAL contract entries are declared with Optional = $true and report [INFO] instead of
    [ERROR] when absent, naming the default that will be used. Get-ChangelogHeading (issue #178) is
    the case this exists for: fold-changelog-entry.ps1 falls back to '## Pull Requests', so a
    consumer without the function is not broken -- but a consumer whose CHANGELOG names its section
    differently DOES need it, and silence would leave them to discover that at fold time.
    Get-LiveStage (issue #177) is the same pattern for the cut-release skill: it falls back to an
    empty string (no separate live stage, Block 2 of the checklist never applies), so a consumer
    without the function is not broken either -- but a repo that DOES have a live stage needs it
    filled in, or the skill would silently never print that block.
    The four Get-Entry* functions (issue #410) are the third instance and the clearest case for
    declaring an optional: nothing crashes without them, so the only signal a consumer would ever get
    is reading English stubs in a repo that is not English -- one branch at a time, indefinitely.

    Note that new-changelog-entry.ps1 treats repo-config.ps1 ITSELF as optional (Test-Path + a
    try/catch that degrades to a warning), unlike open-pr/fold, which pre-flight on it. That is
    deliberate: it is the lightest script in the set and every string it reads from there has a working
    default. The contract records above therefore describe wording that CAN be configured, not a
    dependency that must exist.

    Deliberately OUT of the contract entirely: the optional repo-config functions that open-pr.ps1
    guards via Get-Command (Get-PrDescriptionPlaceholder, Get-PrApprovalPattern, Get-PrAssignee,
    Get-PrMilestone) -- those are per-repo taste with no wrong-by-default failure mode, so they are
    never declared here.
    cut-release.ps1 USED TO BE OUT OF SCOPE HERE, described as "genuinely workshop-only... not mirrored
    and not part of the consumer contract" because lockstep across a marketplace's plugins is meaningless
    in a consumer. It became a shared, mirrored script in #417, and the eight cut-release records below
    are the consumer contract this paragraph said did not exist -- so the paragraph is now the drift it
    was written to prevent, one file over. Corrected here rather than left standing: a reader who takes it
    at face value concludes those records are a mistake.

    What was true in it survives, and it is the reason the sharing worked: the lockstep bump IS
    marketplace-specific. It just did not need the script to be forked -- it needed one seam function
    (Get-ReleasePluginTier), after which a repo with no marketplace manifest simply skips that half.

    Two 'cut-release' things are named in this file and they are NOT the same, which is worth keeping
    straight: the shared cut-release SCRIPT (the eight repo-config records below) and the shared
    cut-release SKILL (issue #177), a checklist that reads Get-LiveStage to decide whether its Block 2
    applies. The Get-LiveStage record is attributed to 'cut-release skill' for exactly that reason.

    ship-pr.ps1 USED TO BE LISTED HERE and no longer is (issue #411). The stated reason -- "merge policy
    and the CI check name are repo-specific" -- was half right, and the half that was wrong was load-
    bearing: the check name never entered the script's logic at all. Merge policy is real and became
    Get-PrMergeMethod. What the exclusion cost in the meantime was the whole merge + fold sequence being
    retyped by hand in every consumer, on the one flow classified safety-critical precisely because it
    merges to main and then commits directly to main.

    For each repo-owned lib in the contract:
      - lib file MISSING            -> [ERROR] naming the file and every function/shared-script that
                                        depends on it (nothing to dot-source, so nothing more to check
                                        for that lib).
      - lib present but dot-sourcing it THROWS -> [ERROR] naming the lib and the error (e.g. a syntax
                                        error), rather than letting this script crash.
      - lib present, a required function MISSING -> [ERROR] naming the function, the lib it must
                                        live in, and which shared script(s) call it -- the same
                                        information the runtime crash would have surfaced, but before
                                        it happens.
      - lib present, function present -> [OK] (detail visible on a deliberate run, like
                                        check-roster-sync.ps1).

    A repo-config.ps1 that still contains VUL-IN placeholders (an unfilled specialists-init scaffold)
    is not, by itself, a contract violation here -- Get-RepoName/Get-LintScript etc. still exist as
    functions (they just return placeholder text), so open-pr.ps1's own VUL-IN pre-flight catches
    that case. This check's job is narrower and stays that way: function PRESENCE, not content.

    Soft/read-only, mirroring check-roster-sync.ps1: this script changes nothing, in any repo.
    [OK]/[INFO]/[ERROR] convention shared via check-report-lib.ps1 (issue #114).

    StrictMode note: this script itself runs under Set-StrictMode -Version Latest, but each
    consumer lib (branch-info.ps1 / repo-config.ps1) is dot-sourced and probed in a child scope with
    StrictMode explicitly OFF. The real runtime callers this check models (open-pr.ps1,
    new-branch.ps1, new-changelog-entry.ps1, fold-changelog-entry.ps1) never call Set-StrictMode, and
    both consumer libs are deliberately written on that no-strict-mode assumption (harmless loose
    top-level code is expected there). Do NOT "helpfully" move the dot-source into strict scope --
    that produces false [ERROR]s for legacy-but-working consumer libs that never crash at real
    runtime (see issue tracker: reported by code review).

    Exit code: 0 = no errors, 1 = at least one error.

.PARAMETER ConsumerPathOverride
    (Optional, for tests) Use this path as the consumer repo root instead of the dual-context default.

.EXAMPLE
    .\scripts\sync\check-script-contract.ps1
#>
param(
    [string]$ConsumerPathOverride = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:errors = 0
$script:infos  = 0

# Write-Ok/Write-Info/Write-Failure/Write-CheckSummary/Resolve-CheckRoot/Write-CheckScope: shared
# with check-roster-sync.ps1 (single source, issue #114). $PSScriptRoot-relative (NOT $repoRoot --
# this lib is not repo-owned, unlike branch-info.ps1/repo-config.ps1), so it resolves correctly from
# the workshop root or the plugin mirror. Dot-sourced BEFORE the repo-root resolution below, which
# now comes from that same shared lib.
. (Join-Path $PSScriptRoot '..\lib\check-report-lib.ps1')

# Repo-root -- dual-context via the shared Resolve-CheckRoot: a consumer running the plugin mirror
# gets its repo-root from CLAUDE_PROJECT_DIR; in the workshop-root (or outside a session) it falls
# back to the git-root. This keeps the root-copy and the plugin-mirror byte-identical (guarded by the
# shared-scripts drift-lint). -ConsumerPathOverride wins so a fixture can point the check at a
# throwaway consumer. The returned Source/Note travel into the [SCOPE] line below, so a finding
# surfaced by the session hook always names the repo it is about (inbound #203).
$scope = Resolve-CheckRoot -Override $ConsumerPathOverride
if (-not $scope.Path) {
    Write-Host '== check-script-contract ==' -ForegroundColor Cyan
    Write-Failure "no repo root could be resolved ($($scope.Note)) -- nothing was checked."
    Write-CheckSummary
}
$repoRoot = $scope.Path

# The declared contract: one record per (lib, required function), grouped by lib for the report.
# Each record names the shared script(s) that call the function at runtime, so an [ERROR] here reads
# like the actionable runtime crash it prevents. Optional = $true downgrades a missing function to
# [INFO] and names the Default the caller falls back to (issue #178).
# 'Returns' states, in one line, what the function must give back. It exists so a finding is
# SELF-CONTAINED (Dave, July 28, 2026: a consumer must be served by the plugin, not put to work for
# it). The message used to end with "update it from the workshop's own scripts\repo-config.ps1" --
# useless advice for the reader most likely to hit it: someone who installed the plugin, has no copy of
# that source repo, and no reason to know it exists. With 'Returns' in the finding, the reader can write
# the function from the report alone.
$script:Contract = @(
    @{ Lib = 'scripts\lib\branch-info.ps1'; Function = 'Get-BranchInfo';  Scripts = @('new-changelog-entry', 'open-pr');
       Returns = "an object for a branch name with at least Prefix, Label and ChangelogType, derived from this repo's own branch-prefix table" },
    @{ Lib = 'scripts\lib\branch-info.ps1'; Function = 'Test-BranchName'; Scripts = @('new-branch');
       Returns = 'an object with IsValid plus a Reason when invalid; reject an empty name and the main branch' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-RepoName';    Scripts = @('open-pr', 'fold-changelog-entry', 'ship-pr', 'verify-resolved-issues');
       Returns = "this repo as 'owner/name', the form ``gh --repo`` takes" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-LintScript';  Scripts = @('open-pr');
       Returns = 'the repo-root-relative path to the lint script to run before a PR' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-RosterPath';  Scripts = @('check-roster-sync');
       Returns = "the repo-root-relative path to the file holding the specialist roster -- '.claude/specialists/SPECIALISTS.md' for a repo set up by specialists-init, since that is where the bootstrap puts the roster slot; something else only if this repo keeps its roster elsewhere. Pointing it at CLAUDE.md when the roster lives in the seam makes the check read a file holding only the @-import and report every specialist as missing (inbound #333)" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-RosterIgnoredIds'; Scripts = @('check-roster-sync');
       Returns = "an array of '<group>-<id>' ids deliberately kept out of the roster -- normally empty, @(), since every enabled specialist belongs in the roster" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ChangelogHeading'; Scripts = @('fold-changelog-entry');
       Optional = $true; Default = '## Pull Requests';
       Returns = "the literal '## ' heading line a merged entry is folded under" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-LiveStage'; Scripts = @('cut-release skill');
       Optional = $true; Default = '';
       Returns = "a short description of this repo's separate go-live target, or '' when it has none" },
    # The stub wording new-changelog-entry.ps1 writes (issue #410). Declared here rather than left
    # undeclared precisely because the failure mode is not a crash: a consumer that never defines these
    # gets working English stubs in a repo whose changelog is in another language, and discovers it at
    # entry time, once per branch, forever. An [INFO] naming the default turns that into a thing you
    # were told rather than a thing you noticed.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-EntryTitlePlaceholder'; Scripts = @('new-changelog-entry');
       Optional = $true; Default = 'TODO: title';
       Returns = 'the placeholder title for an entry created without an explicit -Title' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-EntryBodyHeading'; Scripts = @('new-changelog-entry');
       Optional = $true; Default = '**To do / where I left off:**';
       Returns = 'the single bold line written above the entry body' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-EntryBodyPlaceholder'; Scripts = @('new-changelog-entry');
       Optional = $true; Default = 'TODO: what still needs to happen on this branch, and where you left off.';
       Returns = 'the fallback body used when no -Intent was given -- a directional prompt, not an empty line' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-EntryFallbackType'; Scripts = @('new-changelog-entry');
       Optional = $true; Default = 'Chore';
       Returns = "the changelog type an unknown branch prefix falls back to; it must be one of the types this repo's own branch table produces, since the release cut groups entries by it" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-PrMergeMethod'; Scripts = @('ship-pr');
       Optional = $true; Default = 'merge';
       Returns = "'merge', 'squash' or 'rebase' -- how this repo merges a PR; ship-pr rejects any other value rather than handing it to gh" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-MojibakePaths'; Scripts = @('fix-mojibake');
       Optional = $true; Default = 'every *.md in the repo root';
       Returns = "the absolute paths fix-mojibake examines when called without -Path, given a -RepoRoot parameter; without it the tool falls back to every *.md in the repo root, which silently skips whatever else this repo keeps markdown in" },
    # cut-release became shared in #417. Eight knobs, all optional, every fallback the behaviour the
    # script had while it was workshop-only -- declared here for the same reason the entry stubs above
    # are: none of them crashes when absent, so a consumer would discover the wrong one at release
    # time, which is the worst moment this repo has. An [INFO] naming the default makes it a thing you
    # were told. Six landed in phase 1; the last three below are the highlights tier from phase 2,
    # which is one knob in the issue's numbering and three functions here -- whether, for whom, and in
    # whose words. Folding them into one config object would have left this contract a single record
    # whose Returns line could not name an actionable default for any of the three.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReservedRootMd'; Scripts = @('cut-release');
       Optional = $true; Default = "this workshop's own root docs (CHANGELOG, CLAUDE, README, LICENSE, CONTRIBUTING, SECURITY, QUICKSTART, ADOPTION, UNINSTALL)";
       Returns = 'the root *.md file names that are permanent docs rather than unfolded changelog entries; every other root *.md blocks the cut, so a permanent doc missing from this list refuses a release over a file nobody failed to fold' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseNotesGrouping'; Scripts = @('cut-release');
       Optional = $true; Default = 'major';
       Returns = "'major' for releases/development/<X>.x/ or 'minor' for releases/development/<X.Y>/ -- where the generated notes are foldered, and therefore what the overview row links to" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseLiveMarker'; Scripts = @('cut-release');
       Optional = $true; Default = '';
       Returns = "the suffix marking the currently-live release on the newest '## Releases' heading, moved off the previous one at each cut; '' means this repo has no live stage and neither writes nor strips a marker" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleasePluginTier'; Scripts = @('cut-release');
       Optional = $true; Default = 'whether .claude-plugin/marketplace.json exists';
       Returns = '$true if this repo publishes plugins that the cut must version in lockstep and card (per-plugin CHANGELOG.md + RELEASE.md); $false makes the newest vX.Y.Z tag the version record instead of the manifests' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseCategoryTitles'; Scripts = @('cut-release');
       Optional = $true; Default = "the English labels (Feat -> Features, Fix -> Fixes, Docs -> Documentation, Chore -> Maintenance)";
       Returns = 'a type -> label map merged over those defaults, for a repo whose category headings are in another language; a type with no label falls back to the type name itself, which is the wrong word rather than a missing one' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseHighlightsBumps'; Scripts = @('cut-release');
       Optional = $true; Default = 'no highlights tier at all';
       Returns = "the bump types that also get a stakeholder-facing highlights document (releases/highlights/<dir>/<X.Y.Z>.md plus a print-ready .html), e.g. @('minor','major'); @() switches the tier off, which is what the cut did before this knob existed" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseHighlightsStakeholderTypes'; Scripts = @('cut-release');
       Optional = $true; Default = 'no split -- every category is stakeholder-facing';
       Returns = 'the branch types a non-developer reader is the audience for; every OTHER category present lands under the remove-before-publishing marker, so a type left out of this list is reviewed rather than published, and @() writes no marker block at all' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseHighlightsWording'; Scripts = @('cut-release');
       Optional = $true; Default = "the English marker text plus lang='en'";
       Returns = "overrides for the highlights document's own text, merged over those defaults: DevBlockComment (the HTML comment above the marker), DevBlockHeading (the marker heading) and HtmlLang (the <html lang> attribute) -- a repo whose stakeholders read another language needs all three, and an unset one is the wrong word rather than a missing one" }
)

# An optional record reports [INFO] (with the fallback the caller uses) where a required one reports
# [ERROR]. ContainsKey rather than dot-access on a possibly-absent key: this script runs under
# Set-StrictMode -Version Latest.
function Test-OptionalRecord {
    param([hashtable]$Record)
    return ($Record.ContainsKey('Optional') -and $Record.Optional)
}

function Get-RecordDefault {
    param([hashtable]$Record)
    if ($Record.ContainsKey('Default')) { return $Record.Default }
    return ''
}

function Get-RecordReturns {
    <# The one-line "what it must give back" for a record, as ' It must return <...>.' ready to append
       to a finding -- empty when a record has no Returns yet, so an un-annotated record degrades to the
       old, shorter message instead of printing a dangling sentence. ContainsKey rather than dot-access:
       this script runs under Set-StrictMode -Version Latest. #>
    param([hashtable]$Record)
    if ($Record.ContainsKey('Returns') -and $Record.Returns) { return " It must return $($Record.Returns)." }
    return ''
}

# One finding line for a contract record that could not be satisfied: [ERROR] when required, [INFO]
# when optional (the caller has a documented fallback, so it is a signal, not a breach).
function Write-ContractGap {
    param([hashtable]$Record, [string]$Message)
    if (Test-OptionalRecord -Record $Record) {
        $def = Get-RecordDefault -Record $Record
        $suffix = if ($def) { " -- optional; the shared script falls back to '$def'." } else { ' -- optional; the shared script has a built-in fallback.' }
        Write-Info ($Message + $suffix)
    } else {
        Write-Failure $Message
    }
}

Write-Host '== check-script-contract ==' -ForegroundColor Cyan
Write-CheckScope -Scope $scope -CheckName 'check-script-contract'

# --- Is this repo set up at all? (issue #225) -----------------------------------------------------
# When EVERY contract lib is absent, the repo has not been through specialists-init: the scaffolds are
# exactly what the bootstrap puts down. Reporting each required function separately then produces a
# list of errors about files that were never meant to exist yet -- 6 [ERROR] lines on a fresh
# consumer, phrased as "this lib predates the contract", which is the wrong story for a repo that has
# no lib at all. A missing lib is only drift once the repo has been set up.
#
# Strict on purpose: if even one lib is present, this is a set-up repo with a real gap and every
# finding stands. Only the all-absent case is "never bootstrapped".
$contractLibs = @($script:Contract.Lib | Sort-Object -Unique)
$presentLibs = @($contractLibs | Where-Object { Test-Path -LiteralPath (Join-Path $repoRoot $_) -PathType Leaf })

if ($contractLibs.Count -gt 0 -and $presentLibs.Count -eq 0) {
    # Same non-counting shape as the roster check's marker, and for the same reason: nothing is
    # broken, the repo-side setup simply has not happened.
    Write-Host ("  [BOOTSTRAP] this repo has none of the libs the shared workflow scripts expect (" + ($contractLibs -join ', ') + ") -- it has not been set up yet. Nothing is broken: those files are what the 'specialists-init' skill puts down as scaffolds for you to fill in. Run that skill; until then this check reports nothing further, because every required function would otherwise be listed against a file that does not exist yet.") -ForegroundColor Yellow
    Write-CheckSummary
    exit 0
}

foreach ($libRel in $contractLibs) {
    $records = @($script:Contract | Where-Object { $_.Lib -eq $libRel })
    $libPath = Join-Path $repoRoot $libRel

    Write-Host "`n-- lib: $libRel" -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $libPath -PathType Leaf)) {
        foreach ($r in $records) {
            $scriptList = $r.Scripts -join ', '
            Write-ContractGap -Record $r -Message "'$libRel' not found -- '$($r.Function)' (required by: $scriptList) cannot be checked; the shared script(s) will crash on first use."
        }
        continue
    }

    # Dot-source + probe the consumer lib in a CHILD scope with StrictMode explicitly OFF -- the real
    # runtime callers this check models (open-pr.ps1, new-branch.ps1, new-changelog-entry.ps1,
    # fold-changelog-entry.ps1) never call Set-StrictMode, and branch-info.ps1/repo-config.ps1 are
    # written on that no-strict-mode assumption (harmless loose top-level code is expected). Probing
    # inside the same block keeps the dot-sourced functions visible to Get-Command while nothing
    # leaks into this script's own strict scope.
    $probe = & {
        Set-StrictMode -Off
        $result = [pscustomobject]@{ Loaded = $true; Error = $null; Present = @{} }
        try {
            . $args[0]
        } catch {
            $result.Loaded = $false
            $result.Error = $_.Exception.Message
            return $result
        }
        foreach ($fn in $args[1]) {
            $result.Present[$fn] = [bool](Get-Command -Name $fn -ErrorAction SilentlyContinue)
        }
        return $result
    } $libPath (@($records.Function))

    if (-not $probe.Loaded) {
        foreach ($r in $records) {
            $scriptList = $r.Scripts -join ', '
            Write-ContractGap -Record $r -Message "'$libRel' failed to load ($($probe.Error)) -- '$($r.Function)' (required by: $scriptList) cannot be checked."
        }
        continue
    }

    foreach ($r in $records) {
        $scriptList = $r.Scripts -join ', '
        $needed = if (Test-OptionalRecord -Record $r) { 'used by' } else { 'required by' }
        if ($probe.Present[$r.Function]) {
            Write-Ok "'$($r.Function)' present in $libRel"
        } else {
            Write-ContractGap -Record $r -Message "'$($r.Function)' missing from $libRel ($needed`: $scriptList) -- this lib predates the contract the shared script(s) call; add the function.$(Get-RecordReturns -Record $r)"
        }
    }
}

Write-CheckSummary
