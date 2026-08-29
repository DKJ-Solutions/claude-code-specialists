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

# WHERE THE PLUGINS ARE, so this registry does not have to know. A pair names the plugin it travels in
# and nothing about the layout; Get-PluginRootByName turns that name into a folder. Unconditional and
# unguarded: this lib is workshop-only (it is not itself mirrored), so the sibling is always there.
. (Join-Path $PSScriptRoot 'plugin-tree-lib.ps1')

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
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        # The plugin set, when the caller has already resolved it. Optional, and it exists for exactly
        # one caller: the lint gate derives the set once at its top, inside a try/catch, so that a
        # marketplace.json it cannot parse degrades to an empty set instead of aborting a run that has
        # nineteen more checks to report. Without this it would resolve the set a SECOND time in here,
        # unguarded -- measured before the parameter was added: a corrupt marketplace killed the gate at
        # check 8, so checks 9 through 22 never ran and no Summary was printed at all. One read per run,
        # one place that decides what a parse failure means.
        [AllowNull()][AllowEmptyCollection()][object[]]$PluginRoots
    )

    $pairs = @(
        @{
            Name   = 'fold-changelog-entry'
            Source = 'scripts\release\fold-changelog-entry.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'fold-changelog'
        },
        @{
            Name   = 'open-pr'
            Source = 'scripts\release\open-pr.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'open-pr'
        },
        @{
            Name   = 'check-roster-sync'
            Source = 'scripts\sync\check-roster-sync.ps1'
            Plugin = 'team-alpha'
            Skill  = 'sync-roster'
            # All three exist so the test suite can point the check at a fixture instead of the real
            # machine. A consumer never types them, and documenting them would invite someone to.
            SkillParamsExempt = @('ConsumerPathOverride', 'CacheRootOverride', 'UserHomeOverride')
        },
        @{
            # Travels in the WORKFLOW plugin, not the core team (August 8, 2026). What it checks is that the
            # consumer's branch-info.ps1 and repo-config.ps1 expose every function the branch/release
            # scripts call -- so a repo that never enabled the workflow plugin was being told at every
            # session start to configure scripts it does not have. That is the exact defect the
            # plugin-serves-the-consumer doctrine names, arriving from the checker rather than the
            # scripts.
            Name   = 'check-script-contract'
            Source = 'scripts\sync\check-script-contract.ps1'
            Plugin = 'contributing-davekjohn'
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
            Plugin = 'contributing-davekjohn'
            Skill  = 'new-branch'
        },
        @{
            # Shared for the same reason new-branch is: the `git checkout main` collision that makes a
            # lane necessary is a property of ship-pr.ps1, which every consumer of this workflow runs.
            # A repo-local copy would be a copy of the answer to a shared problem.
            Name   = 'worktree-lane'
            Source = 'scripts\task\worktree-lane.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'worktree-lane'
        },
        @{
            Name   = 'park-branch'
            Source = 'scripts\task\park-branch.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'park'
        },
        @{
            # THE AUTOMATIC HALF OF PARKING (#900, August 26, 2026), invoked by the Stop hook
            # cycle-autopark.ps1 -- which is why this row exists at all: the hook runs from
            # ${CLAUDE_PLUGIN_ROOT}, so a consumer whose plugin carried the hook but not this script
            # would have a hook that silently does nothing.
            #
            # DOCUMENTED IN THE 'park' SKILL RATHER THAN ITS OWN, beside park-branch. The three parking
            # moments -- at creation, deliberately mid-work, and automatically -- are one subject, and a
            # reader deciding between them wants them on one page. It also means the model does not
            # reach for this: the page carries disable-model-invocation, and the hook is what runs it.
            Name   = 'park-cycle'
            Source = 'scripts\task\park-cycle.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'park'
        },
        @{
            # CENTRALIZED FROM TWO CONSUMER COPIES (inbound #815, August 21, 2026) -- the #81 argument
            # again: a mechanism several repos need, living as a hand-written copy in each, is a
            # mechanism that will drift. Nothing in the plugin deleted a branch anywhere before this.
            Name   = 'prune-merged'
            Source = 'scripts\task\prune-merged.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'prune-merged'
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
            Plugin = 'contributing-davekjohn'
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
            Plugin = 'contributing-davekjohn'
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
            Plugin = 'contributing-davekjohn'
            # The gap declared here on August 4, 2026 is closed. It was mirrored because three repos had
            # each written their own copy -- three people needing it and none with a page to read -- and
            # that same argument is why the page had to follow the mirror rather than wait for someone to
            # ask for it. With this, check 18 covers every shared entry point except check-script-contract,
            # whose empty Skill is a statement rather than a gap.
            Skill  = 'fix-mojibake'
            # -Check is this script's documented report-only mode ("change nothing, exit 1 if any file
            # would change"), so it can be timed without repairing anything.
            MeasureArgs = @('-Check')
        },
        @{
            # What a skill COSTS and how fast the script behind it runs. It drives `claude plugin
            # details` (the count_tokens API) rather than counting anything itself, so the figure it
            # reports is the authoritative one and not a second, disagreeing estimate.
            #
            # IT TRAVELS IN contributing-davekjohn, and the alternative was cheaper: a repo-level skill
            # would cost every consumer nothing, since only the repo that AUTHORS skills ever runs
            # this. Dave chose the plugin on August 22, 2026 -- the standing portable-first rule for
            # ways of working, against a precisely known ~200 always-on tokens, and against
            # .claude/skills/ being a pattern no gate here scans.
            #
            # NO MeasureArgs, deliberately, and it is the one entry where that is worth a sentence:
            # a plain run shells out to `claude plugin details` once per enabled plugin, so timing it
            # would measure the CLI and the network rather than this script. It is also the only
            # registered script that could time itself, which is a good enough reason on its own.
            Name   = 'measure-skill'
            Source = 'scripts\maintenance\measure-skill.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'measure-skill'
            # A fixture root, so the suite can drive the script against a scratch tree. A consumer
            # never types it, and documenting it would invite someone to.
            SkillParamsExempt = @('RootOverride')
        },
        @{
            # measure-skill's parsing and formatting half. It is a lib for one reason: the parse reads a
            # human-formatted table whose shape the CLI owns, and a parser that cannot be tested without
            # shelling out to `claude` is one nobody pins. Pinned by
            # scripts/tests/measure-skill.tests.ps1 against captured output.
            Name    = 'measure-skill-lib'
            Source  = 'scripts\lib\measure-skill-lib.ps1'
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            # The ALWAYS-ON DOCUMENT PATH -- CLAUDE.md plus everything it '@'-imports -- measured per
            # document and per section, so the figure stops being produced by hand.
            #
            # IT IS REGISTERED UNDER measure-skill's PAGE, not one of its own (issue #875). Same
            # subject (what a session pays), same owner (the performance specialist), and only a
            # skill's DESCRIPTION is paid by every session -- so an existing page adds nothing to what
            # a consumer pays for it. That is the "which skill, not whether" half of the shared
            # automation-first rule, applied to the first script the rule was written against.
            #
            # THE #876 ENTRY IN CHANGELOG.md SAID THE OPPOSITE, and was corrected on this branch: it
            # declared the script deliberately repo-local because consumers do not share this repo's
            # condition. That argument was #861's, and #861 was about a SKILL -- a new always-on
            # description that would have judged an instruction document block by block. Packaging
            # deterministic code under a description that already exists is a different act, and the
            # boundary it drew (portable-first applies to rules, not to tooling with a per-session
            # cost) is not crossed by a mirror that costs nothing per session.
            #
            # NO MeasureArgs, and the reason is not safety: a plain run only reads. What it would time
            # is a repo reading its OWN documents, so the median would move with the repo measured
            # rather than with this script -- a figure nobody could reproduce, which is exactly what
            # pass 2 refuses to store.
            Name   = 'measure-always-on'
            Source = 'scripts\maintenance\measure-always-on.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'measure-skill'
        },
        @{
            # measure-always-on's engine: the import walk, the section split, and the calibrated
            # chars-per-token factor. A lib because the factor is the thing that went wrong -- it was
            # inherited unexamined at 3.70 through three hand measurements and was ~19% too generous,
            # so every token figure derived from it was under-stated while looking precise. A constant
            # nothing pins is a constant that drifts again; pinned by
            # scripts/tests/measure-always-on.tests.ps1.
            Name    = 'measure-context-lib'
            Source  = 'scripts\lib\measure-context-lib.ps1'
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            Name    = 'check-report-lib'
            Source  = 'scripts\lib\check-report-lib.ps1'
            Plugin  = 'team-alpha'
            LibOnly = $true
        },
        @{
            # THE LIB WITH A READER IN MORE THAN ONE PLUGIN, and therefore the entry with a second
            # mirror of the same source (August 8, 2026). check-roster-sync stays in the core while
            # check-script-contract went to the workflow plugin, and both dot-source this file as a
            # $PSScriptRoot-relative sibling. The alternative -- the workflow mirror reaching into the
            # core plugin's cache directory -- was rejected on sight: the two plugins are separately
            # versioned and separately installed, so that builds a runtime dependency on a path a
            # version mismatch silently breaks.
            #
            # A SECOND ENTRY RATHER THAN A LIST OF MIRRORS, because every consumer of this registry
            # already loops per pair and copies Source -> Mirror; two entries need no new machinery in
            # the generator, in the lint's check 8, or in check 18 (which skips LibOnly entirely). What
            # the loops do NOT tolerate is a duplicate Name: the test suite looks pairs up with
            # Where-Object { $_.Name -eq ... } and would get an array back, so the second entry carries
            # the plugin in its name. That was verified against all three readers before it was written,
            # not assumed from the absence of a uniqueness assertion.
            Name    = 'check-report-lib-workflow'
            Source  = 'scripts\lib\check-report-lib.ps1'
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            Name    = 'native-capture-lib'
            Source  = 'scripts\lib\native-capture-lib.ps1'
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            # Get-SeamValue + Get-DefaultChangelogPath (issue #885, group A): the one definition
            # cut-release.ps1, new-internal-note.ps1 and fold-changelog-entry.ps1 all read an optional
            # repo-config seam through now, where two of them used to carry their own private copy of the
            # function and the third probed inline instead of calling either. session-status.ps1 was a
            # fourth until #957 removed it with /lock and /handover.
            # TWO MORE READERS SINCE INBOUND #967: new-branch.ps1 and open-pr.ps1, both for the changelog
            # seam and both for the same reason -- the base an entry's relative links resolve from is the
            # directory that seam names, and both used to assume the repo root. Already mirrored, so
            # nothing about the payload changed; what changed is that a consumer running either one
            # without this lib present would now fail, which is why the list is kept current.
            Name    = 'seam-lib'
            Source  = 'scripts\lib\seam-lib.ps1'
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            # Gate evidence (August 16, 2026): what the gates proved, and against which exact working
            # state. Mirrored because open-pr.ps1 dot-sources it as a $PSScriptRoot sibling, and the
            # redundancy it removes -- ship-pr calling open-pr, which re-gates a commit nothing has
            # touched -- is the consumer's redundancy just as much as this repo's.
            #
            # ITS OWN FILE RATHER THAN native-capture-lib.ps1, following park-lib's precedent and
            # native-capture-lib's own request not to be widened again. NO CONTRACT ROW FOLLOWS:
            # nothing in it is repo-owned -- it asks git about the tree and writes inside the git
            # directory, so there is no seam a consumer has to answer.
            Name    = 'gate-lib'
            Source  = 'scripts\lib\gate-lib.ps1'
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            Name    = 'pr-issues-lib'
            Source  = 'scripts\lib\pr-issues-lib.ps1'
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            # The PR-body helpers open-pr.ps1 dot-sources: Get-EntryDescription (shared by the fresh and
            # the -RefreshBody path) and Update-PrBodySection. Mirrored for the same reason as the two libs
            # above -- open-pr is mirrored and would otherwise dot-source a file the consumer does not have.
            Name    = 'pr-body-lib'
            Source  = 'scripts\lib\pr-body-lib.ps1'
            Plugin = 'contributing-davekjohn'
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
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            # Issue #1069, August 29, 2026. Mirrored because BOTH its callers are: ship-pr.ps1 asks it
            # whether another worktree holds the trunk (before the merge, and again when handing the trunk
            # back afterwards), and prune-merged.ps1 asks it which worktree to name when its own checkout
            # is refused. A consumer whose ship-pr dot-sources a file the mirror does not carry would fail
            # at the step that has just merged.
            #
            # ITS OWN FILE, for the reason park-lib's entry gives one line up: native-capture-lib asks not
            # to be widened again, and reading `git worktree list --porcelain` is neither a capture helper
            # nor a park. Nothing in it is repo-owned -- it takes lines and returns strings -- so no
            # contract row follows.
            Name    = 'worktree-lib'
            Source  = 'scripts\lib\worktree-lib.ps1'
            Plugin = 'contributing-davekjohn'
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
            Plugin = 'contributing-davekjohn'
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
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            # The contract registry, extracted from check-script-contract.ps1 on August 8, 2026 (#456)
            # once a THIRD reader appeared: the check reports what a consumer is missing, the blueprint
            # generator ships what the source answered, and the test suite holds the registry to its own
            # rules. Mirrored because the check that dot-sources it is mirrored -- a consumer running the
            # mirror would otherwise load a file it does not have.
            Name    = 'script-contract-lib'
            Source  = 'scripts\lib\script-contract-lib.ps1'
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            # The consumer's side of the blueprint (#456): it reads the artefact this repo generates and
            # places what is safe to copy, proposing the rest. Shared for the reason every script here is
            # -- the alternative is each consumer hand-deriving the source's answers, which is what the
            # issue measured them doing.
            #
            # THE GENERATOR IS NOT REGISTERED, deliberately: scripts/sync/build-config-blueprint.ps1 reads
            # THIS repo's libs to produce the artefact, so it is the source's own tool. A consumer running
            # it would generate a blueprint of itself and overwrite the one it adopts from.
            Name   = 'adopt-config'
            Source = 'scripts\task\adopt-config.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'adopt-config'
            # A test points the command at a fixture blueprint instead of the shipped one. A consumer
            # never types it, and documenting it would invite someone to.
            SkillParamsExempt = @('BlueprintPath')
        },
        @{
            # The workflow's own root folder (Dave, August 14, 2026): a plugin install writes nothing
            # into a consumer's repo, so the folder that gathers everything portable arrives through
            # this command -- and check-script-contract reports at session start while it is missing.
            # Additive-only sibling of adopt-config: that one fills the seam libs, this one puts the
            # folder down.
            Name   = 'adopt-workflow-folder'
            Source = 'scripts\task\adopt-workflow-folder.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'adopt-workflow-folder'
        },
        @{
            # Issue #417, phase 1. Two repos ran two independently evolved files of this name, and the
            # owner's goal is one release workflow rather than two that resemble each other. The audit
            # that produced the issue named three divergences; reading both files found six, and the
            # largest -- the whole plugin/marketplace half -- was not among them. All six now sit in the
            # seam (scripts\repo-config.ps1), each optional, each falling back to what this script did
            # unshared, so registering it here changes nothing about how the workshop cuts a release.
            #
            # The consumer tier the other repo generates is NOT part of this entry: porting it is
            # phase 2, and it renders stakeholder-facing HTML, which under the safety rules is work that
            # waits for Dave's own eye rather than merging on the gates.
            Name   = 'cut-release'
            Source = 'scripts\release\cut-release.ps1'
            Plugin = 'contributing-davekjohn'
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
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            # The hosted reading copy of the hand-written notes (Dave, August 15, 2026). Shared rather
            # than workshop-only because nothing in it is repo-specific: it reads the release history and
            # the note root through seams that already exist, and the two knobs it adds are optional with
            # working fallbacks. The consumer this was ported from had written its own, which is the
            # argument for one source rather than for a second.
            Name   = 'build-release-notes-page'
            Source = 'scripts\release\build-release-notes-page.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'release-notes-page'
            # A fixture root, so the suite can build a page from a synthetic tree instead of this repo's
            # real notes. A consumer never types it.
            SkillParamsExempt = @('RootOverride')
        },
        @{
            # THE ONE PAIR WHOSE SOURCE IS NOT A SCRIPT, and the flag is a stretch that is worth naming
            # rather than hiding. LibOnly is documented as marking a DOT-SOURCED library, and this is an
            # HTML template -- but what the flag actually declares is "this file never resolves a repo
            # root of its own", which is the invariant the test enforces and which a template satisfies
            # more completely than a lib does. The alternative was a third flag whose only member would
            # be this entry.
            #
            # A PAIR RATHER THAN A PLUGIN-ONLY FILE, because the script reaches the template as a
            # $PSScriptRoot sibling: it has to exist beside BOTH copies, which is precisely what this
            # registry is for. Without it the mirror would build a page from a template it does not have.
            Name    = 'release-notes-page-template'
            Source  = 'scripts\release\release-notes-page-template.html'
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            # Which plugins a repo publishes, and where each one's folder is (August 9, 2026). Travels
            # because release-lib dot-sources it as a $PSScriptRoot sibling: Get-PluginManifestPaths --
            # which cut-release calls in a consumer that publishes plugins -- is a wrapper over it, and
            # Get-TouchedPlugins reads the roots it returns.
            #
            # DEPENDENCY-FREE ON PURPOSE, and that is what makes it cheap enough to sit this low. The
            # alternative was putting these functions in check-report-lib, which every SessionStart check
            # already loads -- but that lib is about a CONSUMER's install state (the settings chain, the
            # plugin cache), while this one is about a repo that PUBLISHES plugins. Two different
            # questions that happen to both say 'plugin', and merging them would have put a marketplace
            # reader into every consumer session that has no marketplace.
            Name    = 'plugin-tree-lib'
            Source  = 'scripts\lib\plugin-tree-lib.ps1'
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            # The source-repo guard (August 12, 2026). IT HAS TO TRAVEL, and that is the whole reason it is
            # a pair rather than a source-only helper: the guard fires from inside the copy a reader
            # wrongly ran, so one that stayed behind in this tree could never fire. Eleven entry points
            # dot-source it $PSScriptRoot-relative and GUARDED, so a mirror built before this pair existed
            # degrades to the previous behaviour instead of throwing.
            #
            # DEPENDENCY-FREE, like plugin-tree-lib and for the same reason: it is dot-sourced on the first
            # line that runs, before any script has resolved anything, so it can rely on nothing being
            # loaded yet.
            Name    = 'source-repo-guard-lib'
            Source  = 'scripts\lib\source-repo-guard-lib.ps1'
            Plugin = 'contributing-davekjohn'
            LibOnly = $true
        },
        @{
            # The Shopify floor's install path (inbound #769 + #776, August 20, 2026). The guard shipped
            # in 4.15.0 and started working on its own for two of its three rules; the third needs the
            # consumer to name the live theme, and NO INSTALL STEP OWNED THAT ANSWER -- an install is a
            # clone into the plugin cache and writes nothing into a repo. So every refreshed consumer met
            # a standing [ERROR] and a guard with a known hole in it.
            #
            # IT TRAVELS IN team-shopify RATHER THAN IN THE CORE TEAM, and that is the same call issue
            # #776 argued from both directions: specialists-init is team-alpha's skill, so teaching it the
            # two Shopify seam functions would give the core team knowledge of an add-on it must not
            # depend on. The plugin that owns the guard owns the answer to the guard.
            Name   = 'adopt-shopify-floor'
            Source = 'scripts\task\adopt-shopify-floor.ps1'
            Plugin = 'team-shopify'
            Skill  = 'adopt-shopify-floor'
            # A fixture root, so the suite can adopt into a scratch tree instead of a real Shopify repo --
            # and so the marketplace refusal can be bypassed in a repo that is one. A consumer never types
            # it, and documenting it would invite someone to.
            SkillParamsExempt = @('RootOverride')
        },
        @{
            # THE GUARD LIB HAS TO REACH team-shopify TOO, now that a shared script travels there. It only
            # ever fires from inside the copy a reader wrongly ran, so a version that stayed behind in
            # contributing-davekjohn's mirror could never fire for adopt-shopify-floor. Registered per plugin
            # rather than per script for the same reason check-report-lib is: the pair names a destination,
            # and one destination cannot serve two.
            Name    = 'source-repo-guard-lib'
            Source  = 'scripts\lib\source-repo-guard-lib.ps1'
            Plugin  = 'team-shopify'
            LibOnly = $true
        },
        @{
            # The branch-entry CI gate (inbound #789, August 20, 2026). The convention shipped with
            # nothing enforcing it: open-pr and ship-pr both refuse locally, and a branch pushed by hand
            # or a PR opened in the GitHub UI meets neither. So both consumers wrote one from scratch --
            # a second definition of the format in every consumer, and both had already drifted, refusing
            # a merge over a missing significance score that Dave placed at the release cut instead.
            #
            # IT DECLARES A SKILL, and it was registered without one until the suite refused: every shared
            # entry point must name a documenting page, and shared-scripts.tests.ps1 asserts exactly that.
            # The reasoning against was "nothing types this command, a workflow runs it" -- which is true
            # of the CI route and beside the point for the question a person does ask on a finished branch,
            # "is my entry written?". A page that answers it before the push is worth more than the
            # exemption was.
            Name   = 'check-branch-entry'
            Source = 'scripts\lint\check-branch-entry.ps1'
            Plugin = 'contributing-davekjohn'
            Skill  = 'check-branch-entry'
            # A fixture root, so the suite can judge scratch trees. A consumer never types it.
            SkillParamsExempt = @('RootOverride')
            # Timeable with no arguments: this script reads the branch dossier and reports. Verified
            # rather than assumed from its check- prefix -- it contains no write of any kind.
            MeasureArgs = @()
        },
        @{
            # The pre-task sync (inbound #787, August 20, 2026). THE HIGHEST-RISK SCRIPT IN A SHOPIFY
            # CONSUMER, and it was written twice by hand before it shipped -- destructively the first
            # time, in both repos. A live theme has no locking and no merge, so work starts by mirroring
            # live into the trunk, and the obvious wholesale implementation overwrites whatever the trunk
            # has done since. One consumer recorded that procedure reverting merged work three times in
            # one week.
            #
            # IT TRAVELS IN team-shopify, like adopt-shopify-floor and for the same reason: the plugin
            # that owns the live theme owns the step that reads from it. It depends on NO workflow plugin
            # at all -- every seam it reads is fetched through Get-Command, so a consumer that enables no
            # workflow gets identical behaviour. That was written when a second workflow existed to name
            # as the comparison; the guarantee is the same one, stated against the case that remains.
            Name   = 'sync-main'
            Source = 'scripts\task\sync-main.ps1'
            Plugin = 'team-shopify'
            Skill  = 'sync-main'
            # A fixture root, so the suite can drive the script against a scratch tree instead of a real
            # store -- and so the marketplace refusal can be bypassed in a repo that is one. A consumer
            # never types it, and documenting it would invite someone to.
            SkillParamsExempt = @('RootOverride')
        },
        @{
            # The sync's QUERIES, as a lib of their own (inbound #787). The policy is one sentence; what
            # the risk sits in is when it fires -- whether a path has ever held live's bytes (inbound
            # #807, which is what decides now), whether a line-ending difference is a difference at all,
            # and where to measure a both-sides-moved conflict from. A deletion is also a touch, and that
            # is the case BOTH hand-written implementations got wrong. Every one of them is testable only
            # if it loads without running a sync, which is the whole reason this is a separate file rather
            # than a handful of functions at the top of sync-main.ps1.
            #
            # DEPENDENCY-FREE, and specifically NOT a reader of repo-config.ps1: the live-theme guard
            # dot-sources that file on every command inside a catch that returns no live theme id, so
            # anything it pulls in is a way to silently disarm the guard. The seam answers are read by the
            # script and passed in.
            Name    = 'sync-rules'
            Source  = 'scripts\lib\sync-rules.ps1'
            Plugin  = 'team-shopify'
            LibOnly = $true
        },
        @{
            # The preview push (inbound #805, August 21, 2026). IT TRAVELS IN team-shopify for the same
            # reason sync-main does: the plugin that owns the live theme owns the estate around it. It
            # depends on NEITHER workflow plugin -- every seam it reads, the branch-name flattening
            # included, is fetched through Get-Command.
            #
            # THE CASE FOR SHARING IT WAS MADE BY THE FAILURE. A consumer's own copy built its create call
            # as '--unpublished --theme-name <name>'; there is no --theme-name flag in the Shopify CLI, and
            # the call failed the FIRST time anybody needed a preview theme created -- the path had been
            # written the day before and no branch had wanted one in between. Nothing was wrong with the
            # reasoning; the code had simply never run, and a per-consumer copy means every consumer gets
            # to discover that independently.
            #
            # start-task DELIBERATELY REMAINS UNSHIPPED, and that is not inconsistent with this. Its page
            # declines to ship a script because creating a preview theme was bound up with the store
            # estate -- and lazy creation is what separated the two: the branch step no longer touches a
            # theme at all, so what is left to share is a push, which is the same call everywhere.
            Name   = 'push-preview'
            Source = 'scripts\task\push-preview.ps1'
            Plugin = 'team-shopify'
            Skill  = 'push-preview'
            # A fixture root, as for sync-main: a consumer never types it, and documenting it would invite
            # someone to.
            SkillParamsExempt = @('RootOverride')
        },
        @{
            # The preview push's ARGUMENT LISTS and the two readers of the CLI's own output, as a lib of
            # its own (inbound #805) -- for the same reason sync-rules is one: they are the only halves
            # that can be judged without a store, a network or a theme, and they are exactly the halves
            # that were wrong. The flag whitelist earned its place on its first run in the consumer, by
            # refusing the lib's own call because '--unpublished' had been left out of the list.
            #
            # THE WHITELIST ANSWERS 'IS THIS A REAL CLI FLAG', NEVER 'MAY THIS REPO USE IT' -- so it admits
            # --allow-live. Refusing a live push is the guard hook's job, and a validator answering both
            # questions would give two different answers to the same one.
            Name    = 'preview-theme'
            Source  = 'scripts\lib\preview-theme.ps1'
            Plugin  = 'team-shopify'
            LibOnly = $true
        }
    )

    # WHERE EACH PLUGIN'S FOLDER IS, asked of the marketplace rather than spelled out per pair.
    #
    # TWO DIFFERENT ABSENCES, AND THEY GET DIFFERENT ANSWERS. A repo that declares NO plugins at all
    # mirrors nothing -- an empty registry is the correct answer there, and it is what the lint's
    # minimal fixture is: a synthetic tree with no marketplace.json, where check 8 then reports
    # 'checked 0' through the note it already carries for exactly this case. But a repo that DOES
    # publish plugins and does not have the one a pair names is a defect in this registry, and it has to
    # stop the run: the generator would otherwise compose a mirror path under a folder nobody publishes
    # and create it, which is a copy of a shared script in a place no consumer will ever receive.
    #
    # That every pair resolves in THIS repo is asserted in scripts/tests/shared-scripts.tests.ps1 rather
    # than left to the throw, so a typo is caught where the claim is actually checkable.
    # THE OUTER @() IS LOAD-BEARING, and an @() inside each branch is not enough: the output of an if
    # STATEMENT is unrolled on assignment, so the inner wrap is undone on the way out and an empty set
    # arrives as $null -- which then fails .Count under StrictMode. Same unrolling this lib's own
    # $PluginRoots parameters guard against, one level up.
    $pluginRoots = @(
        if ($PSBoundParameters.ContainsKey('PluginRoots')) { $PluginRoots }
        else { Get-RepoPluginRoots -RepoRoot $RepoRoot }
    )
    if ($pluginRoots.Count -eq 0) { return }

    foreach ($p in $pairs) {
        # THE PLUGIN IS THE ONE THING A PAIR STATES ABOUT ITS DESTINATION, and the mirror path is
        # composed from it. This is the inverse of what stood here until August 9, 2026, and the
        # reasoning is the one that was already written down: the plugin used to be read OFF a full
        # mirror literal, precisely so a second field naming it could not disagree with the path beside
        # it. That instinct was right and the direction was wrong -- every one of the 21 mirrors was
        # exactly '<plugin root>\<Source>', verified across all of them before this was changed, so the
        # literal restated the source path and the layout on every line. Naming the plugin and deriving
        # the rest keeps one statement per fact and removes the layout from this file altogether: the
        # plugin tree moved twice in 2026, and neither move should be legible here.
        $root = Get-PluginRootByName -PluginRoots $pluginRoots -Name $p.Plugin
        if (-not $root) {
            # THE MESSAGE LISTS THE WHOLE SET, and that is the repair for a trap rather than politeness
            # (Tycho, August 9, 2026). This throw is deliberate and stops the run -- see above -- but its
            # commonest reader is not someone who made a typo: it is someone building a fixture
            # marketplace, who has to declare every plugin the registry names and has no way to know
            # what those are except by reading this file. Tycho hit it, went looking with a grep for
            # "Plugin = '" and missed the entries written with two spaces, which is precisely the sort
            # of near-miss a list in the error makes impossible.
            $needed = (@($pairs | ForEach-Object { $_.Plugin } | Sort-Object -Unique) -join ', ')
            $have = (@($pluginRoots | ForEach-Object { $_.Name } | Sort-Object) -join ', ')
            throw ("shared-scripts registry: pair '$($p.Name)' names plugin '$($p.Plugin)', which " +
                   ".claude-plugin/marketplace.json does not declare. This registry needs all of: $needed. " +
                   "The marketplace declares: $have.")
        }
        $mirrorRel = Join-Path $root.RelativeRoot $p.Source
        [pscustomobject]@{
            Name       = $p.Name
            SourceRel  = $p.Source
            MirrorRel  = $mirrorRel
            SourcePath = Join-Path $RepoRoot $p.Source
            MirrorPath = Join-Path $RepoRoot $mirrorRel
            # The plugin whose payload this pair travels in (the core, or the workflow plugin).
            Plugin     = $p.Plugin
            # Where the documenting skill lives, under the same resolved root so a plugin that moves
            # takes its page lookup along. $null when there is no skill to document (LibOnly, or
            # Skill = '').
            SkillRel   = if ($p.ContainsKey('Skill') -and -not [string]::IsNullOrEmpty($p.Skill)) {
                             Join-Path $root.RelativeRoot "skills\$($p.Skill)\SKILL.md"
                         } else { $null }
            # Absent on an entry-point script -- normalized to $false so a caller can test the
            # property without ContainsKey gymnastics under StrictMode.
            LibOnly    = [bool]($p.ContainsKey('LibOnly') -and $p.LibOnly)
            # Normalized for the same reason. A LibOnly entry carries no Skill at all: it is never
            # invoked, so there is nothing for a skill to document. $null therefore means "not
            # applicable", while '' on an entry point means "declared as having none" -- and check 18
            # tells those two apart rather than treating both as nothing to do.
            Skill      = if ($p.ContainsKey('Skill')) { [string]$p.Skill } else { $null }
            SkillParamsExempt = if ($p.ContainsKey('SkillParamsExempt')) { [string[]]$p.SkillParamsExempt } else { @() }
            # HOW THIS SCRIPT MAY BE INVOKED HARMLESSLY, for measure-skill.ps1's wall-clock pass. Three
            # states, and the middle one is why this is $null rather than @() when absent: $null means
            # "no read-only invocation is declared, so it is NEVER RUN to be timed", while @() means
            # "declared safe with no arguments at all" (a check-* script that writes nothing). Same
            # $null-vs-empty distinction Skill above already makes, for the same reason -- a
            # not-applicable and a declared-none are different answers.
            #
            # It lives HERE, beside the registration, rather than in a table inside measure-skill.ps1:
            # a second hand-written list is one a newly shared script falls out of silently, which is
            # the accumulation shape of #275/#331 that LibOnly and Skill above were both moved here to
            # escape. And the safety is the whole point -- timing cut-release by running it would cut a
            # release, so the default of "not declared" must mean "not executed".
            # DECLARED-ness is its own boolean, and it has to be: an `if` expression returning @()
            # unrolls to nothing, so the property below would be $null for BOTH "not declared" and
            # "declared safe with no arguments" -- collapsing exactly the distinction this key exists
            # to make. Measured the first time it ran: check-branch-entry, declared with @(), was
            # reported as undeclared and skipped. Same reasoning as LibOnly being normalized to [bool].
            MeasureDeclared = [bool]$p.ContainsKey('MeasureArgs')
            MeasureArgs = if ($p.ContainsKey('MeasureArgs')) { [string[]]$p.MeasureArgs } else { $null }
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
