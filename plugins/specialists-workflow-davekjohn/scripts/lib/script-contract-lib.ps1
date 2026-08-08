<#
.SYNOPSIS
    The declared script contract: which repo-owned functions the shared workflow scripts call, and
    what a consumer must know to answer each one.

.DESCRIPTION
    Dot-source this file:

        . (Join-Path $PSScriptRoot '..\lib\script-contract-lib.ps1')

    Supplies Get-ScriptContract (the registry). THREE things read it and each needs a different half,
    which is why it lives here rather than inside the check that used to own it:

      - scripts/sync/check-script-contract.ps1  -- reports what a consumer is missing (Optional/Default/Returns)
      - scripts/sync/build-config-blueprint.ps1 -- ships the source's answers to consumers (Adopt/AdoptWhy)
      - scripts/tests/script-contract.tests.ps1 -- holds the registry to its own rules

    Extracted on August 8, 2026 (issue #456). Before that the blueprint generator would have had to
    re-declare the function list, which is the second-literal shape this repo has been bitten by often
    enough to have a name for it: a new record silently falls out of one of the two copies.

    No Set-StrictMode here: dot-sourcing would change the strict mode of the calling script.
    Pure ASCII (repo convention for .ps1).
#>

function Get-ScriptContract {
    <# The contract records. One hashtable per (lib, function); see the comment block below for what
       each key means. Returned as an array so a caller can filter it without mutating the source. #>
    return @($script:ContractRecords)
}
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
#
# 'Adopt' IS A SECOND, INDEPENDENT AXIS (issue #456, Dave August 8, 2026), and the whole point of it is
# that it does NOT line up with the roster/workflow split #522 introduced. That split classifies a
# function by WHICH PLUGIN READS IT. This one classifies it by WHETHER THE SOURCE'S VALUE IS SAFE TO
# COPY -- and Get-ReleasePluginTier is the proof they are different questions: it sits squarely in the
# workflow half, so #522 says "this travels", and it is exactly the value that must not, because $true
# asserts the consuming repo publishes plugins. One field could not carry both answers without pressing
# two independent facts into one.
#
#   'copy'   -- the value states the shared WAY OF WORKING. Adopting it asserts nothing about the
#               consuming repo, so build-config-blueprint.ps1 ships the source's own function text and
#               adopt-config.ps1 writes it in.
#   'decide' -- the value states WHAT THIS REPO IS. Copying it would assert something about the
#               consumer that may be false, so the blueprint ships the source's answer and its reasoning
#               as GUIDANCE and adopt-config.ps1 writes a scaffold the consumer fills in. Proposed,
#               never placed.
#
# AdoptWhy carries the reason per record, and it is the half that has to survive: the blueprint's value
# to a consumer is not the source's answer but why the source gave it. Every [INFO] this check prints
# today ends in the DEFAULT the shared script falls back to and never in what the source chose or why --
# which is the gap #456 was filed about.
#
# TEN ARE 'decide' AND SIX OF THEM WERE NOT ON THE ISSUE'S LIST, which named Get-ReservedRootMd,
# Get-ReleasePluginTier, Get-ReleaseHighlightsBumps and Get-ReleaseMajorMinMinors. That list answered a
# neighbouring question -- which values a SCRIPT cannot judge from the outside -- so it never mentioned
# Get-RepoName, Get-LintScript, Get-LiveStage or Get-PrMergeMethod: nobody would think to have a script
# guess a repo's name. Under THIS question they are the clearest cases in the table, Get-RepoName most
# of all, where copying does not merely assert something false but points every gh call in the consumer
# at the source repo.
#
# THE OTHER TWO WERE CLASSIFIED 'copy' FIRST AND THE REPO OVERRULED IT. Both branch-info.ps1 records
# looked like the shared way of working -- a prefix table and a name validator. That file states the
# opposite about itself in its own comments: it "is repo-owned and does not travel into the plugin:
# every consumer has their own copy with their own table", and its refusal of 'chore/' is written down
# as this repo's rule, deliberately phrased so it does not reach "a consumer who legitimately runs
# chore/ branches of their own". Copying either would have imposed precisely what that sentence exists
# to prevent. Recorded because it is the axis's own failure mode: a value can look portable and be
# governed by a decision somebody already wrote down somewhere else.
$script:ContractRecords = @(
    @{ Lib = 'scripts\lib\branch-info.ps1'; Function = 'Get-BranchInfo';  Scripts = @('new-branch', 'open-pr');
       Adopt = 'decide'; AdoptWhy = "branch-info.ps1 says of itself that it is repo-owned and does not travel: 'every consumer has their own copy with their own table'. The table is three rows of THIS repo's policy -- feat/fix/docs, and no release/ prefix because a release lands directly on the trunk here";
       Returns = "an object for a branch name with at least Prefix, Label and ChangelogType, derived from this repo's own branch-prefix table" },
    @{ Lib = 'scripts\lib\branch-info.ps1'; Function = 'Test-BranchName'; Scripts = @('new-branch');
       Adopt = 'decide'; AdoptWhy = "the validation logic is generic, but one of its hard rejects is not: it refuses 'chore/' outright, which is this repo's rule and was written down as one that must NOT reach a consumer who legitimately runs chore/ branches. Copying the function would impose exactly that";
       Returns = 'an object with IsValid plus a Reason when invalid; reject an empty name and the main branch' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-RepoName';    Scripts = @('open-pr', 'fold-changelog-entry', 'ship-pr', 'verify-resolved-issues');
       Adopt = 'decide'; AdoptWhy = "the one value here where copying is actively destructive rather than merely wrong: it would point every gh call in the consumer at the SOURCE repo, so a PR or a merge lands in somebody else's repository";
       Returns = "this repo as 'owner/name', the form ``gh --repo`` takes" },
    # TWO CALLERS SINCE AUGUST 5, 2026, and the second one is the repair rather than a note (inbound
    # #464): cut-release resolved the gate by a fixed path into the SOURCE repo, so a consumer's release
    # ran without one. Both routes now ask this function, which is the point of having it.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-LintScript';  Scripts = @('open-pr', 'cut-release');
       Adopt = 'decide'; AdoptWhy = 'it names a file that exists only in this repo. Every consumer has its own lint, and a cut REFUSES when the file named here is absent -- so a copied value turns the gate into a blocker';
       Returns = 'the repo-root-relative path to the lint script that runs before a PR and before a release cut; a release refuses to cut when the file it names is absent, since a gate that skips itself is not a gate' },
    # OPTIONAL SINCE AUGUST 4, 2026, and the reason is a shape rather than a preference (inbound #445).
    # Measured across this table that day: 6 of 23 entries were required, and four of those six serve a
    # script the consumer INVOKES -- Get-BranchInfo, Test-BranchName, Get-RepoName, Get-LintScript. Don't
    # want the script, don't call it. These two were the only required entries whose sole caller is
    # check-roster-sync, which runs from a SessionStart hook: nothing in the repo invokes it and nothing
    # can decline it. So the only demands a consumer could not opt out of were these.
    #
    # Making them optional costs nothing, because check-roster-sync never hard-required them: it carries
    # its own sane defaults (roster 'CLAUDE.md', no ignored ids) and runs to completion without either
    # function. The [ERROR] pair came from this table alone, declaring a requirement the reading script
    # does not have. An [INFO] naming the default is the accurate report.
    #
    # This does NOT give a consumer a way to say "I have no roster at all" -- that was the larger ask in
    # #445, and it was deliberately not built: by the time it was measured, the consumer that filed it had
    # bootstrapped the full system 52 minutes later, so nothing was left to build it against. What is
    # repaired here is the asymmetry, which stands on its own regardless of who wants which adoption shape.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-RosterPath';  Scripts = @('check-roster-sync');
       Adopt = 'copy'; AdoptWhy = "'.claude/specialists/SPECIALISTS.md' is where specialists-init puts the roster in EVERY repo it bootstraps, so the source's answer IS the bootstrap's answer -- and the built-in fallback (CLAUDE.md) is the one that reads the wrong file (inbound #333)";
       Optional = $true; Default = 'CLAUDE.md';
       Returns = "the repo-root-relative path to the file holding the specialist roster -- '.claude/specialists/SPECIALISTS.md' for a repo set up by specialists-init, since that is where the bootstrap puts the roster slot; something else only if this repo keeps its roster elsewhere. Pointing it at CLAUDE.md when the roster lives in the seam makes the check read a file holding only the @-import and report every specialist as missing (inbound #333)" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-RosterIgnoredIds'; Scripts = @('check-roster-sync');
       Adopt = 'copy'; AdoptWhy = 'empty is the normal state for a fresh consumer as much as for the source. A non-empty list is a deliberate, self-authored exception, which is precisely the kind nobody inherits';
       Optional = $true; Default = 'no ignored ids';
       Returns = "an array of '<group>-<id>' ids deliberately kept out of the roster -- normally empty, @(), since every enabled specialist belongs in the roster" },
    # RETIRED, AUGUST 5, 2026: Get-ChangelogTierHeadings and the legacy single Get-ChangelogHeading (#178).
    # Both answered which '## ' heading a merged entry is filed under, and CHANGELOG.md has no section
    # headings any more -- an entry IS an H2 and the document is an intro plus a flat ranked list of them.
    # The fold and release-lib derive the intro/list boundary structurally now (the first entry heading),
    # so nothing reads either function.
    #
    # NO REPORT MARKER IN A Returns TEXT, and that is a rule for every record here rather than a detail of
    # one. A finding's message is scanned for those markers by counters that decide things: the session
    # hook surfaces a run by counting ERROR markers, and this suite's asserts count OK/INFO lines. Writing
    # one into a Returns line inflates those counts -- measured on the first draft of the record that used
    # to sit here, which spelled the info marker out and made five findings count as six. With ERROR it
    # would have raised a blocking session signal for a repo with nothing wrong. Guarded by an assert in
    # script-contract.tests.ps1 so the next one fails a test instead of a hook. Kept here rather than
    # deleted with the records, because the rule outlived them.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-LiveStage'; Scripts = @('cut-release skill');
       Adopt = 'decide'; AdoptWhy = "'' says this repo has no live stage, which is true of a marketplace and false of a theme or storefront repo. Copying it silently removes the cut-release skill's live-push block from a repo whose release is not finished without one";
       Optional = $true; Default = '';
       Returns = "a short description of this repo's separate go-live target, or '' when it has none" },
    # The stub wording open-pr.ps1 REFUSES (issue #410) -- nothing writes it any more. Declared here rather than left
    # undeclared precisely because the failure mode is not a crash: a consumer that never defines these
    # gets working English stubs in a repo whose changelog is in another language, and discovers it at
    # entry time, once per branch, forever. An [INFO] naming the default turns that into a thing you
    # were told rather than a thing you noticed.
    # THREE OF THE FOUR ARE NOW READ BY TWO SCRIPTS, and the second one is why the attribution matters:
    # open-pr.ps1's scaffold gate REFUSES a PR whose entry still carries this wording, reading it through
    # the shared entry-scaffold-lib.ps1 exactly as the writer does. A consumer that configures the wording
    # but is told only about the writer would not know the gate follows its answer too -- and a
    # finding here has to be self-contained (Dave, July 28, 2026).
    # ViaLib names the shared library through which these scripts reach the function, because NEITHER of
    # them names it directly any more -- both call Get-EntryScaffoldWording. Declared rather than left
    # implicit so the completeness guard can still prove the reference is real: it checks that each script
    # dot-sources that lib AND that the lib names the function, which is a stricter test than the direct
    # text match it replaces (that one was satisfiable by a mere mention in a docstring).
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-EntryTitlePlaceholder'; Scripts = @('open-pr');
       Adopt = 'copy'; AdoptWhy = "copying changes no behaviour -- the value IS the built-in fallback -- and that is the point: it puts the string in the consumer's own file, which is the whole reason this seam exists. A non-English repo translates it there instead of forking new-branch.ps1 (inbound #410)";
       ViaLib = 'entry-scaffold-lib';
       Optional = $true; Default = 'TODO: title';
       Returns = 'the placeholder title for an entry created without an explicit -Title; open-pr refuses to ship an entry that still carries it' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-EntryBodyHeading'; Scripts = @('open-pr');
       Adopt = 'copy'; AdoptWhy = 'same as the title placeholder, and it matters more here: nothing writes this string any more, but open-pr still REFUSES an entry carrying it. A consumer who translated the wording keeps a gate that recognises their words rather than only the English ones';
       ViaLib = 'entry-scaffold-lib';
       Optional = $true; Default = '**To do / where I left off:**';
       Returns = 'the to-do line the entry USED to be scaffolded with; no longer written since the branch/ split, still refused by open-pr wherever it survives' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-EntryBodyPlaceholder'; Scripts = @('open-pr');
       Adopt = 'copy'; AdoptWhy = 'as the two above -- the value is the fallback, and having it stated locally is what makes it translatable';
       ViaLib = 'entry-scaffold-lib';
       Optional = $true; Default = 'TODO: what this change does, for whoever reads CHANGELOG.md later.';
       Returns = 'the placeholder body an entry is scaffolded with -- a prompt for what the change does, since the step list moved to branch/branch-progress.md; open-pr refuses to ship an entry that still carries it' },
    # The impact table's two knobs (issue #467). Declared for the reason the stub wording above is: neither
    # failure is a crash. A consumer that has adopted tier sections gets the ranking switched ON by that
    # fact alone, and would discover it when a cut refuses; a consumer whose readers are not developers gets
    # a rubric written for developers and would discover that when somebody scores against the wrong test.
    # An [INFO] naming both defaults turns each into a thing they were told.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-EntrySignificanceEnabled'; Scripts = @('new-branch', 'open-pr', 'fold-changelog-entry', 'cut-release');
       Adopt = 'copy'; AdoptWhy = 'the significance model is the shared way of working rather than a fact about a repo. The source does not declare this function at all, so the blueprint carries no text for it and adopt-config leaves it alone -- which is itself the honest report';
       ViaLib = 'entry-scaffold-lib';
       Optional = $true; Default = 'on';
       Returns = "$true to rank changelog entries by significance, $false to switch the whole mechanism off. On, an entry declares an impact table -- one row per tier it reaches, each with a significance from 1 to 5 and a Why -- and the release cut REFUSES a release whose tier-1-or-higher entries have not scored themselves. Off, nothing is required and no gate speaks. It does NOT switch off the fold's ordering of CHANGELOG.md, which is structural: the tier decides where an entry lands, which is what the retired tier sections used to say visually. On by default since the sections went -- the old default inferred adoption from how many changelog sections a repo declared, and a flat changelog gives every repo the same answer to that" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-EntrySignificanceRubricLevels'; Scripts = @('new-branch', 'open-pr', 'cut-release');
       Adopt = 'copy'; AdoptWhy = "the rubric bands are the shared model; the source leaves them at the built-in five, so there is nothing to copy. A repo whose readers are not developers rewords a band -- but that is its own text, not the source's";
       ViaLib = 'entry-scaffold-lib';
       Optional = $true; Default = "the five built-in bands, 5 = 'the reader must act' down to 1 = 'cosmetic, or names the failure it prevents'";
       Returns = "a map from significance level to the TEST for that level, e.g. @{ 5 = 'the reader must act -- a breaking change or a required migration' }. Override the bands a repo has to word differently: 'the reader must act' means something else to a marketplace than to a storefront, and a repo whose consumers are not developers needs its own wording. A level left out keeps its built-in text, so one band can be retuned without restating five. The rubric is what makes the number a measurement rather than a mood, and both gates print it when they refuse" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-EntryFallbackType'; Scripts = @('new-branch');
       Adopt = 'copy'; AdoptWhy = "'Chore' has to be a type this repo's own branch table produces, and that table travels under the same marker -- so the pair stays consistent, which it would not if one half were copied and the other decided";
       Optional = $true; Default = 'Chore';
       Returns = "the changelog type an unknown branch prefix falls back to; it must be one of the types this repo's own branch table produces, since the release cut groups entries by it" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-PrMergeMethod'; Scripts = @('ship-pr');
       Adopt = 'decide'; AdoptWhy = "a merge POLICY, not a convention. The source merges; the consumer whose inbound issue created this knob squashes. Copying is the hardcoded --merge the knob was built to remove -- one repo's policy imposed on another (inbound #411)";
       Optional = $true; Default = 'merge';
       Returns = "'merge', 'squash' or 'rebase' -- how this repo merges a PR; ship-pr rejects any other value rather than handing it to gh" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-MojibakePaths'; Scripts = @('fix-mojibake');
       Adopt = 'copy'; AdoptWhy = 'the one function whose body is workshop-shaped and still safe to copy, because every directory it adds sits behind its own Test-Path: in a repo without plugins/ or releases/ it reduces to the root glob plus branch/, a superset of the fallback that costs an absent directory nothing';
       Optional = $true; Default = 'every *.md in the repo root';
       Returns = "the absolute paths fix-mojibake examines when called without -Path, given a -RepoRoot parameter; without it the tool falls back to every *.md in the repo root, which silently skips whatever else this repo keeps markdown in" },
    # cut-release became shared in #417. All optional, every fallback the behaviour the script had while
    # it was workshop-only -- declared here for the same reason the entry stubs above are: none of them
    # crashes when absent, so a consumer would discover the wrong one at release time, which is the worst
    # moment this repo has. An [INFO] naming the default makes it a thing you were told.
    #
    # Six landed in phase 1. Phase 2 added the highlights tier as three functions -- whether, for whom,
    # and in whose words -- of which only 'whether' survives: the tier model answered the other two at
    # the source (see the retirement note below). Get-ReleaseMajorMinMinors joined in the same movement,
    # because the bump gate it feeds is a hard refusal and a shared script must not pin every consumer to
    # one repo's release cadence.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReservedRootMd'; Scripts = @('cut-release');
       Adopt = 'decide'; AdoptWhy = "an allowlist entry for a file that is not there is inert, so copying does no damage -- what it does is look complete while missing the consumer's OWN permanent root docs, and each one missing refuses a release over a document nobody failed to fold. This list has gone stale three times in the source alone";
       Optional = $true; Default = "this workshop's own root docs (CHANGELOG, CLAUDE, README, LICENSE, CONTRIBUTING, SECURITY, QUICKSTART, ADOPTION, UNINSTALL)";
       Returns = 'the root *.md file names that are permanent docs rather than unfolded changelog entries; every other root *.md blocks the cut, so a permanent doc missing from this list refuses a release over a file nobody failed to fold' },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseNotesGrouping'; Scripts = @('cut-release');
       Adopt = 'copy'; AdoptWhy = "'major' is also the built-in fallback, so adopting it states the source's foldering without changing any behaviour; a repo that cuts often enough for per-minor folders to help sets 'minor' and nothing else moves";
       Optional = $true; Default = 'major';
       Returns = "'major' for releases/development/<X>.x/ or 'minor' for releases/development/<X.Y>/ -- where the generated notes are foldered, and therefore what the overview row links to" },
    # RETIRED, AUGUST 5, 2026: Get-ReleaseLiveMarker and Get-ReleaseHistoryMode. The first marked the
    # currently-live release on the newest release heading; the second chose whether that section
    # accumulated a block per release or kept only the newest behind a pointer. A cut writes no release
    # block into CHANGELOG.md at all now -- it empties the document down to its intro -- so both describe
    # machinery that is gone. Removed rather than left declared, for the reason the highlights knobs below
    # were: a contract record for a knob nothing reads sends a consumer off to write a function that will
    # never be called.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseHistoryPath'; Scripts = @('cut-release', 'new-internal-note');
       Adopt = 'copy'; AdoptWhy = 'a location convention rather than a fact about the repo, and it is already the default. What does NOT travel with it is the precondition: since the changelog stopped carrying release blocks this file is the only list of releases there is, so the consumer has to keep it complete';
       Optional = $true; Default = 'releases/README.md';
       Returns = "the repo-root-relative path to the file that lists every release this repo has cut. Since the changelog stopped carrying release blocks it is the ONLY such list, so it must genuinely be complete. Three things read it: the guardrail refusing a new major whose section does not exist yet, the inserter that writes the row, and new-internal-note.ps1, which repoints that row's Version cell at the internal note once the note exists" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleasePluginTier'; Scripts = @('cut-release');
       Adopt = 'decide'; AdoptWhy = 'THE case this whole axis exists for. It sits in the workflow half, so the roster/workflow split of #522 says it travels, and $true asserts the consuming repo publishes plugins -- which a storefront does not. Its fallback is COMPUTED (does .claude-plugin/marketplace.json exist), so a consumer that states nothing already gets the right answer, and a copied $true overrides a correct computation with a false claim';
       Optional = $true; Default = 'whether .claude-plugin/marketplace.json exists';
       Returns = '$true if this repo publishes plugins whose versions the cut must bump in lockstep; $false makes the newest vX.Y.Z tag the version record instead of the manifests' },
    # RETIRED, AUGUST 5, 2026: Get-ReleaseCategoryTitles. Display labels for the release-notes category
    # headings (Feat -> Features, Fix -> Fixes, ...), for a repo whose headings are in another language. The
    # release documents have no category headings any more -- they are ranked lists of changes, and each
    # change states its own type inside it under a '### Type of change' section. The grouping went because
    # it was derived from the BRANCH PREFIX, which this repo measured does not predict what a change is
    # worth: the most consequential change for a consumer at v3.2.0 arrived on a chore/ branch and was
    # therefore filed third, under whichever label its prefix produced.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseHighlightsBumps'; Scripts = @('cut-release');
       Adopt = 'decide'; AdoptWhy = 'it declares that this repo wants a stakeholder-facing document at all, and for which bumps. Whether there is an audience outside the developers is a fact about the organisation around the repo, which no script can read from the tree';
       Optional = $true; Default = 'no highlights tier at all';
       Returns = "the bump types that also get a stakeholder-facing highlights document (releases/highlights/<dir>/<X.Y.Z>.md, markdown only), e.g. @('minor','major'); @() switches the tier off, which is what the cut did before this knob existed. The document is the release's TIER-2 entries, so it is only written when there are some" },
    # Get-ReleaseHighlightsStakeholderTypes and Get-ReleaseHighlightsWording USED TO BE DECLARED HERE and
    # are gone (August 5, 2026). Both configured the highlights document's "remove before publishing"
    # marker: which branch types to promote above it, and in whose words to label it. That marker existed
    # because the branch prefix does not predict impact, so the generator wrote out both halves and left
    # the release manager to cut one. The tier model asks the entry's author instead, which removed the
    # marker and with it everything these two configured. Removed rather than left declared: a contract
    # record for a knob nothing reads sends a consumer off to write a function that will never be called.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseMajorMinMinors'; Scripts = @('cut-release');
       Adopt = 'decide'; AdoptWhy = "release cadence. Ten is measured against THIS repo's own history -- the 1.x line ran to 1.18 and the 2.x line to 2.16 before each was recapped -- and a repo that cuts minors rarely would be pinned to a major it never reaches";
       Optional = $true; Default = '10';
       Returns = 'how many minors a major line must have had before a major may be cut -- a major recaps the minors before it, so their accumulation is what earns it. Read off the minor component of the current version (within major 3 the minors are 3.1 .. 3.10, so the component IS the count). A repo that cuts minors rarely sets this lower; it is only read when a tier split is declared, since the whole bump gate is off without one' },
    # The third tier. Declared for the same reason as the two above: nothing crashes without it, so a
    # consumer would discover English headings in a document written for its own management -- at the
    # moment it is being shared, which is the worst one available.
    # RETIRED, AUGUST 5, 2026: Get-ChangelogReleaseWording (inbound #462). Four strings a release wrote into
    # CHANGELOG.md -- the release section's two intros, the notes pointer, and the sentence repointing that
    # pointer at the internal note. All four described the release BLOCK, and a cut writes none of it now.
    #
    # WHAT THE CONSUMER WHO ASKED FOR #462 LOSES, stated rather than glossed: nothing, because the OUTPUT is
    # what went rather than the capability. That inbound issue came from a non-English repo and made these
    # strings repo-owned because they were the most visible generated text in the file. What replaced the
    # block is the changelog intro's own one-line pointer to the release history -- hand-written prose in a
    # file the repo owns outright, which is in the repo's language by construction and needs no seam.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-InternalNoteWording'; Scripts = @('new-internal-note');
       Adopt = 'copy'; AdoptWhy = 'empty means the English defaults, which is exactly what a consumer gets without the function. Copying puts the (empty) override map in their own file, where a repo whose colleagues read another language fills in the keys it needs';
       Optional = $true; Default = 'the English headings and hints';
       Returns = "overrides for the internal note's own text, merged over the English defaults: Title, AudienceLabel, Audience, SkeletonNote, SectionChanged, SectionValue, HintValue, SectionOpen, HintOpen, NoEntries and Unknown -- the document is read by this repo's own colleagues, so its language is the repo's rather than the script's" }
)
