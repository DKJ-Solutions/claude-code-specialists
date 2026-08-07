<#
.SYNOPSIS
    Registry + helpers for the shared workflow scripts (root copy <-> plugin mirror).

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\shared-scripts-lib.ps1')

    Some workflow scripts are repo-agnostic and are mirrored into the plugin as a shared source, so
    consumers do not duplicate them (issue #81). The model: the **workshop root copy is the
    canonical, tested source**; the **plugin mirror** is what a consumer runs via a skill. Both are
    LF-normalized identical -- made possible because the scripts resolve their repo root
    dual-context (CLAUDE_PROJECT_DIR for a consumer, otherwise the git root).

    Supplies Get-SharedScriptPairs (the registry) and Get-NormalizedScriptContent (LF-normalized
    read). The generator (scripts/sync/build-shared-scripts.ps1), the lint gate
    (check-plugin-integrity.ps1), and the test (scripts/tests/shared-scripts.tests.ps1) share this
    one source.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function Get-SharedScriptPairs {
    <#
        The registry of shared scripts. Each pair: the canonical root source (Source) and the
        plugin mirror (Mirror), both repo-root-relative. Extend per centralized script.

        LibOnly = $true marks a DOT-SOURCED library rather than a standalone entry point. Such a
        file never resolves a repo root of its own -- it is reached via a $PSScriptRoot-relative
        dot-source from a caller that already resolved one -- so the dual-context invariant does not
        apply to it. The flag lives HERE, next to the registration, because the test used to keep
        its own hand-written list of lib names: a second literal that a new lib silently fell out of
        (the accumulation shape of #275/#331). Registering a lib now declares its own exception.

        Skill names the plugin skill that DOCUMENTS this script for a consumer, and it is REQUIRED on
        every non-LibOnly entry -- '' means "no skill documents this", which is a declaration rather
        than an omission. The lint gate's parameter check (check 18) reads it: a consumer who only has
        the mirror plus its skill cannot use a parameter the skill never names. Measured August 4,
        2026: three were missing that way, and -NoPush -- the one inspection step before a release is
        pushed -- was among them. Same reasoning as LibOnly: declared next to the registration, so a
        newly shared script cannot fall out of the check silently.

        SkillParamsExempt lists parameters that deliberately do NOT belong in a skill, each with a
        reason at the registration. Without it the check would be bypassed wholesale the first time it
        fired on a test-only override, and a gate that gets bypassed guards nothing.
    #>
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $pairs = @(
        @{
            Name   = 'fold-changelog-entry'
            Source = 'scripts\release\fold-changelog-entry.ps1'
            Mirror = 'plugins\specialists\scripts\release\fold-changelog-entry.ps1'
            Skill  = 'fold-changelog'
        },
        @{
            Name   = 'open-pr'
            Source = 'scripts\release\open-pr.ps1'
            Mirror = 'plugins\specialists\scripts\release\open-pr.ps1'
            Skill  = 'open-pr'
        },
        @{
            Name   = 'check-roster-sync'
            Source = 'scripts\sync\check-roster-sync.ps1'
            Mirror = 'plugins\specialists\scripts\sync\check-roster-sync.ps1'
            Skill  = 'sync-roster'
            # All three exist so the test suite can point the check at a fixture instead of the real
            # machine. A consumer never types them, and documenting them would invite someone to.
            SkillParamsExempt = @('ConsumerPathOverride', 'CacheRootOverride', 'UserHomeOverride')
        },
        @{
            Name   = 'check-script-contract'
            Source = 'scripts\sync\check-script-contract.ps1'
            Mirror = 'plugins\specialists\scripts\sync\check-script-contract.ps1'
            # No skill, and none is wanted: this runs from a SessionStart hook and reports. Nobody
            # invokes it as a procedure, so there is no procedure to write down.
            Skill  = ''
        },
        # RETIRED, AUGUST 7, 2026: 'new-changelog-entry'. It was new-branch's child step, and this entry
        # noted that it had no skill of its own because that skill documented both. The name stopped being
        # true when the branch/ split gave it a step list to write, and again when it gained the templates
        # -- it described one of four outputs. Merged into new-branch.ps1, which is the one concept it was
        # ever a half of. Nothing else called it and no document told anyone to run it.
        @{
            Name   = 'new-branch'
            Source = 'scripts\task\new-branch.ps1'
            Mirror = 'plugins\specialists\scripts\task\new-branch.ps1'
            Skill  = 'new-branch'
        },
        @{
            Name   = 'park-branch'
            Source = 'scripts\task\park-branch.ps1'
            Mirror = 'plugins\specialists\scripts\task\park-branch.ps1'
            Skill  = 'park'
        },
        @{
            # Issue #411. Was excluded as "workshop-only" on the reasoning that merge policy and the CI
            # check name are repo-specific. Only the first half held: the check NAME never entered the
            # logic (step 3 watches whatever checks exist and reads the exit code), and the merge METHOD
            # moved into the seam as the optional Get-PrMergeMethod. Without this mirror, merge + fold is
            # hand work in every consumer -- and it is the one sequence classified safety-critical,
            # because it merges to main and then commits directly to main.
            Name   = 'ship-pr'
            Source = 'scripts\release\ship-pr.ps1'
            Mirror = 'plugins\specialists\scripts\release\ship-pr.ps1'
            # The gap declared here on August 4, 2026 is closed: the route the cut-release skill sends
            # the reader to ("the normal new-branch -> ship-pr route") now has a page. It documents
            # verify-resolved-issues too, which is why that entry points here rather than at one of
            # its own.
            Skill  = 'ship-pr'
        },
        @{
            # Travels with ship-pr rather than on its own merit: it IS ship-pr's step 6, and a consumer
            # whose ship-pr calls a file that is not in the mirror would fail at the last step of a
            # sequence that has already merged. Portable as it stands -- dual-context root, Get-RepoName,
            # and pr-issues-lib/native-capture-lib are both mirrored already.
            Name   = 'verify-resolved-issues'
            Source = 'scripts\release\verify-resolved-issues.ps1'
            Mirror = 'plugins\specialists\scripts\release\verify-resolved-issues.ps1'
            # No skill of its own, and that is right: it IS ship-pr's step 6 and runs from there, so
            # whatever documents ship-pr documents this. That page now exists and carries a section for
            # running this step on its own, so the inherited gap is closed with ship-pr's rather than
            # by giving a step of a sequence a procedure page of its own.
            Skill  = 'ship-pr'
        },
        @{
            # Issue #413. Three repos had written their own copy of this repair tool, which is the
            # argument for one source rather than for a fourth. Its workshop-shaped default file set --
            # the part that made it unusable elsewhere -- moved into the seam as Get-MojibakePaths.
            Name   = 'fix-mojibake'
            Source = 'scripts\maintenance\fix-mojibake.ps1'
            Mirror = 'plugins\specialists\scripts\maintenance\fix-mojibake.ps1'
            # The gap declared here on August 4, 2026 is closed. It was mirrored because three repos had
            # each written their own copy -- three people needing it and none with a page to read -- and
            # that same argument is why the page had to follow the mirror rather than wait for someone to
            # ask for it. With this, check 18 covers every shared entry point except check-script-contract,
            # whose empty Skill is a statement rather than a gap.
            Skill  = 'fix-mojibake'
        },
        @{
            Name    = 'check-report-lib'
            Source  = 'scripts\lib\check-report-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\check-report-lib.ps1'
            LibOnly = $true
        },
        @{
            Name    = 'native-capture-lib'
            Source  = 'scripts\lib\native-capture-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\native-capture-lib.ps1'
            LibOnly = $true
        },
        @{
            Name    = 'pr-issues-lib'
            Source  = 'scripts\lib\pr-issues-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\pr-issues-lib.ps1'
            LibOnly = $true
        },
        @{
            # The PR-body helpers open-pr.ps1 dot-sources: Get-EntryDescription (shared by the fresh and
            # the -RefreshBody path) and Update-PrBodySection. Mirrored for the same reason as the two libs
            # above -- open-pr is mirrored and would otherwise dot-source a file the consumer does not have.
            Name    = 'pr-body-lib'
            Source  = 'scripts\lib\pr-body-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\pr-body-lib.ps1'
            LibOnly = $true
        },
        @{
            # The one implementation of parking (#507): Invoke-GitPark, dot-sourced by BOTH parking entry
            # points -- park-branch.ps1 and new-branch.ps1 -Park. Mirrored for the same reason as the libs
            # above: both callers are mirrored and would otherwise dot-source a file the consumer does not
            # have.
            #
            # ITS OWN FILE RATHER THAN native-capture-lib.ps1, where Invoke-TestSuiteGate landed the same
            # week. That one documents its fit as imperfect and asks the next person not to widen the file
            # again; a park is not a gate, and the cost here is this entry and one mirror -- nothing in it
            # is repo-owned, so no contract row follows.
            Name    = 'park-lib'
            Source  = 'scripts\lib\park-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\park-lib.ps1'
            LibOnly = $true
        },
        @{
            # The third release tier (August 3, 2026). Its own script rather than part of cut-release, and
            # the reason changed on the way: the source repo kept it separate because cut-release was
            # "temporarily diverged" and must not be extended, which #417 settled. What holds instead is
            # that cut-release COMMITS AND TAGS in one motion, so a skeleton generated there would put an
            # empty document inside the release tag while the written version landed afterwards anyway.
            Name   = 'new-internal-note'
            Source = 'scripts\release\new-internal-note.ps1'
            Mirror = 'plugins\specialists\scripts\release\new-internal-note.ps1'
            # Documented inside the cut-release skill (step 2) rather than separately: it is a step of
            # cutting a release, and it cannot run before the cut has produced its input.
            Skill  = 'cut-release'
        },
        @{
            # The changelog entry's scaffold wording, needed by TWO shared scripts that must not be able
            # to disagree about it: new-changelog-entry.ps1 writes it, open-pr.ps1's scaffold gate refuses
            # to ship it. A copy in each would make the gate silently miss whatever the writer changed --
            # a drift guard that drifts. So it travels with both rather than living in either.
            Name    = 'entry-scaffold-lib'
            Source  = 'scripts\lib\entry-scaffold-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\entry-scaffold-lib.ps1'
            LibOnly = $true
        },
        @{
            # Issue #417, phase 1. Two repos ran two independently evolved files of this name, and the
            # owner's goal is one release workflow rather than two that resemble each other. The audit
            # that produced the issue named three divergences; reading both files found six, and the
            # largest -- the whole plugin/marketplace half -- was not among them. All six now sit in the
            # seam (scripts\repo-config.ps1), each optional, each falling back to what this script did
            # unshared, so registering it here changes nothing about how the workshop cuts a release.
            #
            # The highlights tier the other repo generates is NOT part of this entry: porting it is
            # phase 2, and it renders stakeholder-facing HTML, which under the safety rules is work that
            # waits for Dave's own eye rather than merging on the gates.
            Name   = 'cut-release'
            Source = 'scripts\release\cut-release.ps1'
            Mirror = 'plugins\specialists\scripts\release\cut-release.ps1'
            Skill  = 'cut-release'
        },
        @{
            # Travels with cut-release for the same reason verify-resolved-issues travels with ship-pr:
            # cut-release dot-sources it as a $PSScriptRoot sibling, so a mirror without it would fail
            # on the first line that matters. Its one repo-owned dependency, branch-info.ps1, does NOT
            # travel -- the branch table differs per repo -- so the dot-source of that sibling is
            # guarded and Get-ReleaseChangeTypes probes for Get-BranchTypes, which cut-release loads
            # from the consumer's own root before calling in.
            Name    = 'release-lib'
            Source  = 'scripts\lib\release-lib.ps1'
            Mirror  = 'plugins\specialists\scripts\lib\release-lib.ps1'
            LibOnly = $true
        }
    )

    foreach ($p in $pairs) {
        [pscustomobject]@{
            Name       = $p.Name
            SourceRel  = $p.Source
            MirrorRel  = $p.Mirror
            SourcePath = Join-Path $RepoRoot $p.Source
            MirrorPath = Join-Path $RepoRoot $p.Mirror
            # Absent on an entry-point script -- normalized to $false so a caller can test the
            # property without ContainsKey gymnastics under StrictMode.
            LibOnly    = [bool]($p.ContainsKey('LibOnly') -and $p.LibOnly)
            # Normalized for the same reason. A LibOnly entry carries no Skill at all: it is never
            # invoked, so there is nothing for a skill to document. $null therefore means "not
            # applicable", while '' on an entry point means "declared as having none" -- and check 18
            # tells those two apart rather than treating both as nothing to do.
            Skill      = if ($p.ContainsKey('Skill')) { [string]$p.Skill } else { $null }
            SkillParamsExempt = if ($p.ContainsKey('SkillParamsExempt')) { [string[]]$p.SkillParamsExempt } else { @() }
        }
    }
}

function Get-ScriptParameterNames {
    <#
        The parameter names of a script's top-level param() block, via the PowerShell parser rather
        than a regex. That is not fussiness: a regex over the param block missed a parameter carrying
        a [Parameter(Mandatory = $true)] attribute when this was first measured, which would have left
        the gate with a blind spot of exactly the kind it exists to close. Returns @() for a file with
        no param block (every LibOnly entry) and for a file that cannot be parsed.
    #>
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
    if (-not $ast -or -not $ast.ParamBlock) { return @() }
    return @($ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
}

function Get-NormalizedScriptContent {
    <# Reads a script LF-normalized (CRLF -> LF); $null if the file is missing. #>
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    return ($raw -replace "`r`n", "`n")
}
