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

    IT ALSO SUPPLIES THE REACHABILITY MODEL (inbound #580, August 10, 2026): Test-ContractLibReachable
    and the AST walk under it. A record says a shared script CALLS a repo-owned function; whether that
    claim can hold at all is whether the script ever dot-sources the lib the function lives in, and
    until #580 nothing anywhere modelled it. The walk lives HERE rather than in the check because the
    claim it tests is the record's, and because the suite has to be able to test it without running the
    check -- the same two reasons the records themselves moved out of the check.

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
# Get-ReleasePluginTier, Get-ReleaseConsumerBumps (then still named ...HighlightsBumps) and
# Get-ReleaseMajorMinMinors. That list answered a neighbouring question -- which values a SCRIPT cannot
# judge from the outside -- so it never mentioned
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
    # THE RECORD INBOUND #580 WAS FILED ABOUT, and it is the first one declared for a function nothing
    # CALLS directly: entry-scaffold-lib's Get-ReleaseChangeTypes PROBES for it with Get-Command and falls
    # back to the canonical four. That probe is the right design -- branch-info.ps1 is repo-owned and does
    # not travel, so 'absent' is the ordinary case in a consumer -- and it is precisely why the gap was
    # silent for so long: nothing crashes, nothing warns, the fallback simply answers a question it was
    # never asked.
    #
    # WHAT THE FALLBACK COSTS IS NOT A DEGRADED FOLD BUT A REFUSED ONE, which is why the Default below says
    # so in those words. A consumer whose branch table produces types outside Feat/Fix/Docs/Chore ('Liquid',
    # 'Tooling') gets every such entry read as declaring no type at all: under 4.0.0 that was silent -- the
    # internal note dropped the type off every bullet it took from a historical heading -- and since 4.1.0
    # the fold names those H2 blocks and refuses the document. The refusal is an improvement over the
    # silence; what was missing is any way to learn it before the fold.
    #
    # AND IT IS THE RECORD THE REACHABILITY WALK EXISTS FOR. Declaring it fixes one function; it is
    # reported unreachable wherever the calling script never loads branch-info.ps1, which is what turns the
    # class from invisible into a named line. A consumer closes it by making the seam reachable through the
    # one file every shared script loads -- chaining branch-info.ps1 from their own repo-config.ps1, the
    # repair the reporting consumer made -- or leaves it, which is correct wherever the canonical four ARE
    # the repo's types.
    @{ Lib = 'scripts\lib\branch-info.ps1'; Function = 'Get-BranchTypes'; Scripts = @('fold-changelog-entry', 'cut-release', 'new-internal-note');
       Adopt = 'decide'; AdoptWhy = "the same reason as the two records above: it is a projection of the branch-prefix table, which branch-info.ps1 says of itself is repo-owned and does not travel. Copying this repo's four types into a repo that produces 'Liquid' or 'Tooling' states somebody else's table as theirs, and the value is indistinguishable from the built-in fallback, so a copy also hides whether the seam was ever answered";
       ViaLib = 'entry-scaffold-lib';
       Optional = $true; Default = "the canonical four (Feat, Fix, Docs, Chore) -- which REFUSES the fold for a repo whose types differ, rather than degrading it";
       Returns = "the changelog types this repo's own branch table produces, as an array of strings in the order the release documents should read them -- a projection of that table, never a second list beside it. Two readers, and they use it differently: recognition (which H2 blocks in CHANGELOG.md are entries, and what the type field of a pre-format heading says) falls back to Feat/Fix/Docs/Chore where this function is out of scope, so a repo producing other types has every such entry read as typeless and its fold REFUSED by name; validation (is a declared type one this repo produces) only fires where the function is genuinely reachable. Being present is not enough -- the script that reads it has to load the lib" },
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-RepoName';    Scripts = @('open-pr', 'fold-changelog-entry', 'ship-pr', 'verify-resolved-issues');
       Adopt = 'decide'; AdoptWhy = "the one value here where copying is actively destructive rather than merely wrong: it would point every gh call in the consumer at the SOURCE repo, so a PR or a merge lands in somebody else's repository";
       Returns = "this repo as 'owner/name', the form ``gh --repo`` takes" },
    # TWO CALLERS SINCE AUGUST 5, 2026, and the second one is the repair rather than a note (inbound
    # #464): cut-release resolved the gate by a fixed path into the SOURCE repo, so a consumer's release
    # ran without one. Both routes now ask this function, which is the point of having it.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-LintScript';  Scripts = @('open-pr', 'cut-release');
       Adopt = 'decide'; AdoptWhy = 'it names a file that exists only in this repo. Every consumer has its own lint, and a cut REFUSES when the file named here is absent -- so a copied value turns the gate into a blocker';
       Returns = 'the repo-root-relative path to the lint script that runs before a PR and before a release cut; a release refuses to cut when the file it names is absent, since a gate that skips itself is not a gate' },
    # THE TEST GATE'S OWN SEAM (inbound #644, August 13, 2026). The gate globbed scripts\tests\*.tests.ps1
    # and nothing else, while both callers call it "all test suites green" -- an overstatement in any repo
    # whose stack is not all PowerShell (the reporting consumer: 4 PowerShell suites beside 605 Vitest
    # tests, of which the gate saw the first number only). Read INSIDE Invoke-TestSuiteGate rather than at
    # the call sites, so open-pr's gate and the cut's gate cannot drift into checking different things --
    # the function's founding rule. The release route is where the gap bites: it is the one route with no
    # later gate that can still stop anything, since CI fires after the tag is pushed.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-TestCommands'; Scripts = @('open-pr', 'cut-release');
       Adopt = 'decide'; AdoptWhy = 'which commands test this repo is a fact about its stack that no script can read from the tree. The source answers none (its suites are all PowerShell, and the gate already runs those); copying that none into a repo with an app layer leaves the release gate blind to exactly the tests that layer needs';
       Optional = $true; Default = 'no extra commands -- the *.tests.ps1 suites in scripts/tests are the whole gate, unchanged from before the seam existed';
       Returns = "extra command lines the test gate runs alongside the *.tests.ps1 suites, e.g. @('npm test') -- each runs as its own child with the exit code propagated, and a non-zero exit fails the gate exactly like a failing suite" },
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
       Adopt = 'copy'; AdoptWhy = 'the one function whose body is workshop-shaped and still safe to copy, because every directory it adds sits behind its own Test-Path: in a repo without plugins/ or releases/ it reduces to the root glob plus workflow-davekjohn/, a superset of the fallback that costs an absent directory nothing. A copy taken before August 14, 2026 still names the retired root branch/ location -- re-adopt to bring the moved folder back under coverage';
       Optional = $true; Default = 'every *.md in the repo root';
       Returns = "the absolute paths fix-mojibake examines when called without -Path, given a -RepoRoot parameter; without it the tool falls back to every *.md in the repo root, which silently skips whatever else this repo keeps markdown in" },
    # cut-release became shared in #417. All optional, every fallback the behaviour the script had while
    # it was workshop-only -- declared here for the same reason the entry stubs above are: none of them
    # crashes when absent, so a consumer would discover the wrong one at release time, which is the worst
    # moment this repo has. An [INFO] naming the default makes it a thing you were told.
    #
    # Six landed in phase 1. Phase 2 added the consumer tier as three functions -- whether, for whom,
    # and in whose words -- of which only 'whether' survives: the tier model answered the other two at
    # the source (see the retirement note below). Get-ReleaseMajorMinMinors joined in the same movement,
    # because the bump gate it feeds is a hard refusal and a shared script must not pin every consumer to
    # one repo's release cadence.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReservedRootMd'; Scripts = @('cut-release');
       Adopt = 'decide'; AdoptWhy = "an allowlist entry for a file that is not there is inert, so copying does no damage -- what it does is look complete while missing the consumer's OWN permanent root docs, and each one missing refuses a release over a document nobody failed to fold. This list has gone stale three times in the source alone";
       Optional = $true; Default = "this workshop's own root docs (CHANGELOG, CLAUDE, README, LICENSE, CONTRIBUTING, SECURITY, QUICKSTART, ADOPTION, UNINSTALL)";
       Returns = 'the root *.md file names that are permanent docs rather than unfolded changelog entries; every other root *.md blocks the cut, so a permanent doc missing from this list refuses a release over a file nobody failed to fold' },
    # DECIDE, NOT COPY, AND THE MARKER WAS WRONG UNTIL AUGUST 10, 2026 (inbound #560). It was justified on
    # 'major' also being the built-in fallback, so copying it "changes no behaviour" -- true of the value and
    # false of the question. This function does not state how anyone WORKS; it states what the consumer's
    # releases/ tree looks like, which is the definition of a decide record and puts it in the same family as
    # Get-ReleaseConsumerBumps and Get-ReleaseMajorMinMinors, both of which were always decide.
    #
    # MEASURED IN A CONSUMER: smartwatchbanden has foldered per MINOR since v2.0.0 -- fourteen directories,
    # releases/development/2.0/ through 2.13/. adopt-config placed 'major' into their seam unseen, so their
    # next cut would have started a SECOND tree beside the first (releases/development/2.x/) and written an
    # overview row pointing at a path holding none of their history. Nothing fails at adoption time and the
    # contract check reports [OK] afterwards, because the value is valid -- it is simply not theirs. The
    # failure surfaces one release later, in the form of a directory nobody asked for.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseNotesGrouping'; Scripts = @('cut-release');
       Adopt = 'decide'; AdoptWhy = "it describes this repo's TREE, not a way of working -- and copying a description of somebody else's tree is exactly what the decide marker exists to prevent. Measured: a consumer foldering per minor since v2.0.0 (fourteen directories) had 'major' placed into their seam unseen, which would have started a second tree beside their history at their next cut and pointed the overview row at a path none of it lives in. It fails at neither adoption nor the contract check, because 'major' is a valid answer -- just not theirs";
       Optional = $true; Default = 'major';
       Returns = "'major' for releases/development/<X>.x/ or 'minor' for releases/development/<X.Y>/ -- where the generated notes are foldered, and therefore what the overview row links to. READ IT OFF YOUR EXISTING TREE rather than choosing: a directory named <X>.x (3.x) means major, one named <X.Y> (2.13) means minor, so for any repo that has cut a release before this is a fact to look up, not a decision to make. Answering it differently from the tree you already have starts a second tree beside the first" },
    # RETIRED, AUGUST 5, 2026: Get-ReleaseLiveMarker and Get-ReleaseHistoryMode. The first marked the
    # currently-live release on the newest release heading; the second chose whether that section
    # accumulated a block per release or kept only the newest behind a pointer. A cut writes no release
    # block into CHANGELOG.md at all now -- it empties the document down to its intro -- so both describe
    # machinery that is gone. Removed rather than left declared, for the reason the retired tier-2 knobs below
    # were: a contract record for a knob nothing reads sends a consumer off to write a function that will
    # never be called.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseHistoryPath'; Scripts = @('cut-release', 'new-internal-note');
       Adopt = 'copy'; AdoptWhy = 'a location convention rather than a fact about the repo: since August 14, 2026 the convention is the workflow folder (workflow-davekjohn/releases/README.md), the same file the adopt-workflow-folder scaffold places -- the shared DEFAULT stays at the old root location, because an unstated seam has to keep meaning what it meant yesterday. What does NOT travel with the copy is the precondition: since the changelog stopped carrying release blocks this file is the only list of releases there is, so the consumer has to keep it complete';
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
    # RENAMED FROM Get-ReleaseHighlightsBumps, AUGUST 10, 2026. The record names only the current name,
    # because that is what a consumer should now write -- but cut-release READS BOTH, and it has to: the
    # fallback for an undefined seam is @(), the tier switched off, so a repo still carrying the old name
    # would cut a minor with no document for its consumer and nothing would err. The contract check
    # therefore reports the old name as a missing optional record rather than as an error, which is the
    # correct signal: it is defined-but-retired, not broken.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseConsumerBumps'; Scripts = @('cut-release');
       Adopt = 'decide'; AdoptWhy = 'it declares that this repo wants a stakeholder-facing document at all, and for which bumps. Whether there is an audience outside the developers is a fact about the organisation around the repo, which no script can read from the tree';
       Optional = $true; Default = 'no consumer tier at all';
    # THE QUESTION THIS KNOB ASKS CHANGED IN v4.3.0 WHILE ITS VALUES STAYED VALID (inbound #605), which is
    # why nothing reported the drift: the contract check compares which functions exist against which are
    # requested, and this record's TEXT was the only thing that was wrong. Under the two-document model
    # @() meant "no consumer document", harmless for a repo whose tier 2 was always empty. Under the one
    # -document model it means "no hand-written document at all" -- so the same value now switches off the
    # only note the release gets. A consumer reading the old text was told the opposite of what it does,
    # and adopt-config places this text VERBATIM into their own repo-config, so being wrong shipped as
    # their own committed documentation.
       Returns = "the bump types that get the hand-written release note (<note root>/<dir>/<X.Y.Z>.md, markdown only), e.g. @('minor','major'); @() switches the tier off, and since v4.3.0 that means those bumps get NO hand-written document at all rather than merely no consumer half. ONE document with a named section per reader, not two: this knob decides WHETHER it is written, while the release's tier-2 entries decide whether that document gets a consumer section. Where that document goes is Get-ReleaseNoteRoot's answer, not this one's. The retired name Get-ReleaseHighlightsBumps is still read as a fallback" },
    # AND WHO THAT DOCUMENT IS FOR, WHICH IS A REPO-LEVEL FACT RATHER THAN A PER-ENTRY ONE (Dave, August 12,
    # 2026; inbound #620). Tier 1 and tier 2 are two KINDS of audience rather than two rungs of a ladder: 1 is
    # management and the employer/commissioner, 2 is the subscriber of a service. A repo has exactly one, and
    # which one it is decides what every entry in that repo is asked.
    #
    # 'decide', AND AFTER Get-RepoName THIS IS THE CLEAREST CASE IN THE TABLE. Copying the source's 2 into a
    # webshop asserts that its product buyers read release notes -- false, and unfalsifiable by any script.
    # The reporting consumer measured 37 open entries, 15 at tier 1 and zero ever at tier 2, and that zero is
    # structural rather than a backlog. A copied value is also indistinguishable from a considered one once
    # written, so it hides whether the question was ever put.
    #
    # THE DEFAULT IS 'ASK ABOUT ALL OF THEM', DELIBERATELY, and it is the half most likely to be
    # "simplified" later by somebody reading the policy as the mechanism. Treating absence as "no audience
    # enabled" would switch the audience tier off in every consumer the moment they take the plugin update,
    # silently, in the direction that empties a release document -- the same failure class the rename above
    # is written about. Absent means unchanged; this record is what makes the question loud instead.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseAudienceTier'; Scripts = @('new-branch', 'open-pr', 'cut-release');
       Adopt = 'decide'; AdoptWhy = "it states WHO this repo publishes to, which is a fact about the organisation around the repo rather than a way of working. Copying the source's 2 tells a webshop that its product buyers read release notes; copying a 1 tells a service that its subscribers do not. Both are wrong in the direction nobody notices, because either value is valid and neither errors";
       Optional = $true; Default = 'every tier the model has (0, 1 and 2) -- unchanged from before the knob existed, so a repo that never answers keeps asking every entry about both audiences';
       Returns = "1 or 2: the one audience tier this repo's entries are asked about, on top of tier 0 which every repo asks unconditionally. 1 is management and the employer/commissioner (a repo delivering work, or selling a product whose buyers never read a note); 2 is the subscriber of a service. It decides which '#### Tier N' sections new-branch scaffolds and which ones open-pr and cut-release require -- NOT which tier numbers are valid to READ: a tier-1 repo must still parse the tier-2 entries already in its own history, and that is Get-EntryTierMax's job, which stays at 2" },
    # AND WHERE THAT DOCUMENT GOES (inbound #616). Declared because the knob above was UNANSWERABLE
    # without it for a repo whose hand-written notes live somewhere else: naming the bumps would point
    # the cut at a directory that does not exist there, so the only safe value was @() -- the tier
    # switched off, which is not an answer to the question the knob asks. Two scripts read it, and both
    # matter: the cut writes the note, session-status looks for the newest one. A seam reaching only the
    # writer would have the notes written to the new root and looked for in the old, reported as "no
    # release note was found" -- which reads like a repo that has not cut one yet.
    # ADOPT FLIPPED FROM 'copy' TO 'decide' ON AUGUST 12, 2026, and the trigger was this repo's own value
    # moving off the default. The old AdoptWhy justified copying on the grounds that the source's answer
    # WAS the default, so copying it changed nothing -- a true sentence that expired the moment the source
    # renamed its root to releases/audience. Copying now would write a directory the consumer does not have
    # into a consumer that already has notes in releases/notes/, and the miss reports as "no release note
    # was found", which reads as a repo that has not cut one yet. This is where the documents already live,
    # which only the consumer can say. The DEFAULT deliberately stays releases/notes for the same reason:
    # a repo that answers nothing must keep meaning what it meant yesterday.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseNoteRoot'; Scripts = @('cut-release', 'session-status');
       Adopt = 'decide'; AdoptWhy = 'where your hand-written notes already live, which is a fact about your tree rather than a convention to inherit. Answer the default releases/notes if you have never cut one; repoint it if they are already somewhere else. The source repo answers releases/audience, so that every root under its releases/ names its READER rather than the form of the document -- copy that rename only if it suits you';
       Optional = $true; Default = 'releases/notes';
       Returns = "the repo-root-relative directory the hand-written release note is written into and read back from. The per-release folder INSIDE it is Get-ReleaseNotesGrouping's answer (<X>.x or <X.Y>), so this is the root alone, with no trailing slash. releases/development/ deliberately has no equivalent knob: nobody has been able to show a repo that differs on it" },
    # Get-ReleaseHighlightsStakeholderTypes and Get-ReleaseHighlightsWording USED TO BE DECLARED HERE and
    # are gone (August 5, 2026). Both configured the consumer document's "remove before publishing"
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
    # TWO WORDING MAPS, FOR TWO DIFFERENT DOCUMENTS, AND THE CANONICAL NAME CHANGED (inbound #605).
    # cut-release reads Get-ReleaseNoteWording FIRST and falls back to Get-InternalNoteWording, so a repo
    # carrying only the old name still gets its language -- and therefore never finds out that the name it
    # should now write is a different one. It works, which is exactly why it was undeclared for two
    # releases: nothing errs, so nothing asks. Declared now so a consumer is told rather than left on a
    # fallback, with the honest note that the two maps have DIFFERENT key sets, because they belong to
    # different documents rather than being two names for one.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-ReleaseNoteWording'; Scripts = @('cut-release');
       Adopt = 'copy'; AdoptWhy = 'empty means the English defaults, which is exactly what a consumer gets without the function. Copying puts the (empty) override map in their own file under the name the cut actually looks for first, so a repo whose readers need another language fills in keys rather than discovering English headings in a published document';
       Optional = $true; Default = 'the English headings and hints, via Get-InternalNoteWording if that is defined';
       Returns = "overrides for the hand-written release note's own text, merged over the English defaults: Title, AudienceLabel, Audience, SectionConsumers, HintConsumers, SectionValue, HintValue, SectionOpen and HintOpen. NOT the same key set as Get-InternalNoteWording, which belongs to the retired two-document flow -- SectionConsumers and HintConsumers are this document's consumer section and exist nowhere else, while that map's SkeletonNote, SectionChanged, NoEntries and Unknown are read only by new-internal-note.ps1. Overriding by the wrong list configures a flow you are not running" },
    # STILL DECLARED, AND NOT AS LEGACY TOLERANCE: new-internal-note.ps1 is still shipped for a repo running
    # the two-document flow, and it reads all eleven keys below. Nothing in THIS repo calls it.
    @{ Lib = 'scripts\repo-config.ps1';     Function = 'Get-InternalNoteWording'; Scripts = @('new-internal-note');
       Adopt = 'copy'; AdoptWhy = 'empty means the English defaults, which is exactly what a consumer gets without the function. Copying puts the (empty) override map in their own file, where a repo whose colleagues read another language fills in the keys it needs';
       Optional = $true; Default = 'the English headings and hints';
       Returns = "overrides for the internal note's own text, merged over the English defaults: Title, AudienceLabel, Audience, SkeletonNote, SectionChanged, SectionValue, HintValue, SectionOpen, HintOpen, NoEntries and Unknown -- the document is read by this repo's own colleagues, so its language is the repo's rather than the script's. This is new-internal-note.ps1's map, i.e. the two-document flow; cut-release reads Get-ReleaseNoteWording first and only falls back to this one" }
)

# --- Reachability: is a record's Lib in scope for the script that reads it? (inbound #580) ---------
#
# A CONTRACT RECORD MAKES TWO CLAIMS AND ONLY ONE OF THEM WAS EVER CHECKED. "Get-RepoName lives in
# scripts\repo-config.ps1" is presence, which the check probes by dot-sourcing that lib in isolation.
# "fold-changelog-entry calls it" is REACHABILITY, and a lib the calling script never dot-sources is not
# in scope at runtime however present it is. The reported instance is Get-BranchTypes: a consumer whose
# branch table produces types outside the canonical four had every folded entry read as typeless, then --
# once the fold learned to say so -- a refused fold, while a record declaring the function would have
# reported [OK] the whole time.
#
# WHY IT MUST BE THE AST AND NOT A TEXT MATCH, measured over this tree on August 10, 2026 before any of
# it was built. Three candidate rules were run over the declared records and over the reported defect:
#
#   rule                                     findings  true  why it lost
#   text mention of the lib leaf                    0     0  fold-changelog-entry.ps1 NAMES branch-info.ps1
#                                                            in a comment, so the defect reports green
#   ViaLib may satisfy reachability                 0     0  fold reaches entry-scaffold-lib, which merely
#                                                            PROBES for the function -- green on the one
#                                                            record the rule exists for
#   AST, literals and named variables only          3     0  false on the '& { . $args[0] }' child-scope
#                                                            idiom (check-roster-sync x2, fix-mojibake)
#
# So ViaLib is deliberately NOT an escape hatch here: it names the PLUGIN lib a function is reached
# through, which is a different question from whether the CONSUMER lib is loaded, and letting it answer
# both is how the rule would have been born blind to its own case.
#
# PATHS, NOT LEAF NAMES, and that distinction is the whole difference between telling a consumer the
# truth about their repo and telling them the truth about this one. release-lib.ps1 dot-sources its
# SIBLING branch-info.ps1 behind a Test-Path: in this workshop the two are siblings and the sibling is
# there, so new-internal-note genuinely reaches Get-BranchTypes here -- and in the plugin mirror
# branch-info.ps1 is absent (it is repo-owned and does not travel), so the same script does not. A walk
# collecting leaf NAMES would report this repo's answer at every consumer.

# The parse cache for the walk below -- see Get-ScriptDotSourceTargets for what it costs without one.
# Assigned here rather than on first use because every caller runs under Set-StrictMode -Version Latest.
$script:DotSourceCache = @{}

function Get-AstPathHints {
    <# The string literals and the base a path expression is built from, as
       @{ Literals = @(...); FromScriptRoot = $bool; FromRepoRoot = $bool }. $VarMap carries the same
       shape per variable name so '. $configPath' resolves through its assignment, which is how three of
       the four dot-source shapes in this tree are written. #>
    param($Ast, [hashtable]$VarMap, [hashtable]$ArgMap, [int]$Depth = 0)

    $hints = @{ Literals = @(); FromScriptRoot = $false; FromRepoRoot = $false }
    if ($null -eq $Ast -or $Depth -gt 4) { return $hints }

    foreach ($n in $Ast.FindAll({ $true }, $true)) {
        if ($n -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
            $hints.Literals += $n.Value
            continue
        }
        if ($n -isnot [System.Management.Automation.Language.VariableExpressionAst]) { continue }

        $name = $n.VariablePath.UserPath
        if ($name -eq 'PSScriptRoot' -or $name -eq 'PSCommandPath') { $hints.FromScriptRoot = $true; continue }
        if (@('repoRoot', 'RepoRoot') -contains $name) { $hints.FromRepoRoot = $true; continue }

        # '. $args[0]' inside a '& { ... } $libPath' block -- the child-scope idiom the checks use to
        # dot-source a consumer lib with StrictMode off. Resolved through the arguments the '&' call
        # passed, which are themselves the variables handled above. This is the shape whose absence made
        # the third candidate rule report three findings and get all three wrong.
        if ($name -eq 'args') {
            foreach ($a in @(Resolve-EnclosingBlockArgs -Ast $n -ArgMap $ArgMap)) {
                $inner = Get-AstPathHints -Ast $a -VarMap $VarMap -ArgMap $ArgMap -Depth ($Depth + 1)
                $hints.Literals += $inner.Literals
                if ($inner.FromScriptRoot) { $hints.FromScriptRoot = $true }
                if ($inner.FromRepoRoot) { $hints.FromRepoRoot = $true }
            }
            continue
        }

        if ($VarMap.ContainsKey($name)) {
            $v = $VarMap[$name]
            $hints.Literals += $v.Literals
            if ($v.FromScriptRoot) { $hints.FromScriptRoot = $true }
            if ($v.FromRepoRoot) { $hints.FromRepoRoot = $true }
        }
    }
    return $hints
}

function Resolve-EnclosingBlockArgs {
    <# The arguments the '&' call passed to the script block this AST node sits in, so a '$args' inside
       it can be resolved. Walks up the parent chain: the block is the invoking command's first element
       and its arguments are the rest. Returns @() when the node is not inside an invoked block, which is
       the honest answer rather than a guess. #>
    param($Ast, [hashtable]$ArgMap)

    $node = $Ast
    while ($null -ne $node) {
        if ($node -is [System.Management.Automation.Language.ScriptBlockExpressionAst] -and $ArgMap.ContainsKey($node)) {
            return @($ArgMap[$node])
        }
        $node = $node.Parent
    }
    return @()
}

function Get-ScriptDotSourceTargets {
    <# Every EXISTING file this script dot-sources, as absolute paths. Resolved from the AST, so a
       comment naming a lib is not mistaken for loading it -- the failure the text-match candidate showed
       on the very record this exists for. A target that resolves to no existing file is dropped rather
       than reported: an unresolvable path is not evidence that the lib IS loaded, and the caller's
       question is only ever "is it". #>
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$RepoRoot)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }

    # MEMOISED, AND IT IS NOT AN OPTIMISATION THAT CAN BE SKIPPED. This check runs from a SessionStart
    # hook, so its runtime is paid at every session. Measured when the walk was first wired in: 3,625 ms
    # over the 23 records, essentially the whole cost of the check -- because the transitive closure
    # re-parses the same libs for every record that reaches them, and entry-scaffold-lib.ps1 alone is
    # over three thousand lines. The recursive directory scan was NOT the cost (108 ms per forty calls);
    # re-parsing was. Keyed on the repo root too, since the same file resolves differently against a
    # different consumer.
    # DECLARED AT LOAD TIME, NOT LAZILY, and that is a strict-mode requirement rather than a style
    # choice: every caller of this walk runs under Set-StrictMode -Version Latest, where reading an
    # unset variable throws -- so even the "is it initialised yet" test would have to be the first
    # thing to fail. See the assignment beside the records above.
    $cacheKey = "$Path|$RepoRoot"
    if ($script:DotSourceCache.ContainsKey($cacheKey)) { return @($script:DotSourceCache[$cacheKey]) }

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    if ($null -eq $ast) { return @() }

    $fileDir = Split-Path -Parent $Path

    # var name -> the hints of whatever it was assigned. Built before the dot-sources are walked, so the
    # order inside the file does not matter.
    $varMap = @{}
    foreach ($a in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true)) {
        if ($a.Left -isnot [System.Management.Automation.Language.VariableExpressionAst]) { continue }
        $varMap[$a.Left.VariablePath.UserPath] = (Get-AstPathHints -Ast $a.Right -VarMap @{} -ArgMap @{})
    }

    # script block -> the arguments it is invoked with, for the '$args' shape above.
    $argMap = @{}
    foreach ($c in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)) {
        if ($c.CommandElements.Count -lt 2) { continue }
        if ($c.CommandElements[0] -isnot [System.Management.Automation.Language.ScriptBlockExpressionAst]) { continue }
        $argMap[$c.CommandElements[0]] = @($c.CommandElements[1..($c.CommandElements.Count - 1)])
    }

    $found = @()
    foreach ($c in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)) {
        if ($c.InvocationOperator -ne [System.Management.Automation.Language.TokenKind]::Dot) { continue }
        if ($c.CommandElements.Count -lt 1) { continue }

        $hints = Get-AstPathHints -Ast $c.CommandElements[0] -VarMap $varMap -ArgMap $argMap
        foreach ($lit in @($hints.Literals)) {
            if ($lit -notmatch '\.ps1$') { continue }

            # Both bases are tried when the expression named neither -- a bare literal is ambiguous, and
            # picking one base would invent an answer.
            $bases = @()
            if ($hints.FromScriptRoot) { $bases += $fileDir }
            if ($hints.FromRepoRoot) { $bases += $RepoRoot }
            if ($bases.Count -eq 0) { $bases = @($fileDir, $RepoRoot) }

            foreach ($b in $bases) {
                $resolved = Resolve-Path -LiteralPath (Join-Path $b $lit) -ErrorAction SilentlyContinue
                if ($resolved) { $found += $resolved.Path }
            }
        }
    }
    $result = @($found | Sort-Object -Unique)
    $script:DotSourceCache[$cacheKey] = $result
    return $result
}

function Test-ContractLibReachable {
    <# Is $LibRelPath (a record's Lib, relative to the consumer repo root) in scope for $ScriptPath at
       runtime? Transitive: a script reaches a lib directly or through any lib it loads, which is the
       route new-internal-note takes to entry-scaffold-lib (through release-lib) and the route a consumer
       opens when they chain branch-info.ps1 from their own repo-config.ps1 -- the repair the consumer who
       reported #580 made on their side, and the one this returns $true for. #>
    param(
        [Parameter(Mandatory)][string]$ScriptPath,
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$LibRelPath
    )

    $target = Resolve-Path -LiteralPath (Join-Path $RepoRoot $LibRelPath) -ErrorAction SilentlyContinue
    # No such lib in this repo: absence is what the presence half of the check already reports, and
    # calling it unreachable as well would print one gap twice under two names.
    if (-not $target) { return $true }
    $targetPath = $target.Path

    $start = Resolve-Path -LiteralPath $ScriptPath -ErrorAction SilentlyContinue
    if (-not $start) { return $true }

    $seen = @{}
    $queue = New-Object System.Collections.Queue
    $queue.Enqueue($start.Path)

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($null -eq $current -or $seen.ContainsKey($current)) { continue }
        $seen[$current] = $true

        foreach ($t in @(Get-ScriptDotSourceTargets -Path $current -RepoRoot $RepoRoot)) {
            if ($t -eq $targetPath) { return $true }
            if (-not $seen.ContainsKey($t)) { $queue.Enqueue($t) }
        }
    }
    return $false
}

function Resolve-SharedScriptPath {
    <# The file behind a record's Scripts name ('fold-changelog-entry'), searched under the scripts tree
       this lib sits in -- the workshop's scripts/ at the source and the plugin's scripts/ in a consumer,
       so one lookup serves both. Returns '' when there is no such file, and the caller then makes NO
       reachability claim: check-roster-sync ships in a DIFFERENT plugin and 'cut-release skill' is not a
       script at all, so an unresolvable name is a normal state rather than a finding. #>
    param([Parameter(Mandatory)][string]$Name, [string]$ScriptsRoot = '')

    if (-not $ScriptsRoot) { $ScriptsRoot = Split-Path -Parent $PSScriptRoot }
    if (-not (Test-Path -LiteralPath $ScriptsRoot)) { return '' }

    $hit = @(Get-ChildItem -LiteralPath $ScriptsRoot -Filter "$Name.ps1" -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1)
    if ($hit.Count -gt 0) { return $hit[0].FullName }
    return ''
}
