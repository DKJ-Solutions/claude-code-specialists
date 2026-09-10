# Changelog

Everything merged since the last release sits under **`## [Unreleased]`**, **newest first**: **one `###` per
change**, and under it two named `####` sections. The `###` heading is the change's own —
`` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `#### What makes this deploy extra special` for the second audience, and `#### Pull Request`.
Every level here moved one deeper on August 26, 2026, when the pending section above them was introduced and
the development cycle beside them shifted to match; entries written before that day carry the whole set one
level shallower and are read exactly as they always were.
The tier numbers live in the parser rather than in any heading. That second heading said `PR` rather than
`deploy` for one day, August 24 to 25, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was — including the four written under `PR`, which are in the list below right now. Entries written
before August 23, 2026 carry that first answer under a `###` question of its own with the second nested
at `####` beneath it; entries before August 16 carry the longer set of headings that shape replaced, and
every earlier shape is read exactly as it always was. Every release ever cut is listed in
[`releases/history.md`](releases/history.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`dkj-policy/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

**The line directly under `## [Unreleased]` is a tally, and nobody types it.** It reads
`**4 / 9 minor entries**`: how many of the pending entries reach the audience this repo publishes to, out of
how many are waiting for the next release, and which bump that work has earned. The two numbers answer
different questions and may differ — the fraction counts tier 2 and above, the bump follows tier 1 and
above — so `**0 / 8 minor entries**` says nothing reaches a subscriber while the version still owes a minor
for what reaches management. It is
**derived from the entries below it every time it is written**, by the fold that adds one and the cut that
removes them all, so it holds no state of its own and a hand-edited count is simply corrected on the next
fold. It ends with an HTML comment that marks it as machine-written; that marker is what the next run
replaces, so anything else written in this space is left alone.

---

## [Unreleased]

**5 / 18 minor entries** <!-- pending-tally -->

### DEPLOY: fix/1771-plugin-details-agent-count · 20260910-113257

`measure-skill` no longer refuses a plugin that ships only subagents. `claude plugin details` prints no
per-component table for a plugin whose inventory is all zeroes, and reading that as a CLI format change
put an `[ERROR]` on two of this repo's six enabled plugins — `dkj-subagents-ecomm` and
`dkj-subagents-lifehub` — over output that was entirely intact. The emptiness is now judged against the
inventory's own counts, so nothing owed is an `[INFO]` naming why, something owed is still an `[ERROR]`,
and an unreadable inventory stays the `[ERROR]` the check exists for.

It also says what its figures do not cover. The inventory's `Agents (N)` counts only defs discovered by
convention in a plugin's default `agents/` directory; a def named by the manifest's `agents` key loads in
a session and is counted as 0. Every always-on figure for such a plugin is therefore skills only, which
made the report read as *"the skill descriptions account for effectively ALL of this plugin's always-on
cost"* over `dkj-subagents-alpha`, whose 15 uncounted agent descriptions are roughly three times the
figure printed. Both readings are now stated in the output — including that `Agents (0)` means *not
counted here*, never *ships none*, which is the misreading #1771 was filed on.

**Score:** 3

#### What makes this deploy extra special

N/A — the tool measures what a plugin costs a session; it ships to no subscriber and changes nothing a
consumer's own repo does.

**Score:** N/A

#### Pull Request

measure-skill stops misreading an agents-only plugin as a CLI format change

Plugins: dkj-policy

[PR #1788](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1788)

---

### DEPLOY: feat/1766-plugin-owned-region · 20260910-111206

`dkj-policy/README.md` now carries a **fenced block that belongs to the plugin and is kept current**.
Everything between `<!-- dkj-policy:update-section -->` and `<!-- /dkj-policy:update-section -->` is
replaced by a re-run of the `adopt-dkj-policy` skill's Part 1; everything outside those two markers is
yours and is never read. The block says what this workflow is, names the three portable pages in code,
and answers *"which version am I on?"* with `/dkj-policy:plugin-versions` rather than a number -- a
version is per (plugin, checkout), so a number committed into a repo is right for at most one clone.
Fixes inbound #1766.

**This is the one place the scaffold rewrites anything**, and it exists because everything in that block
was always the plugin's writing sitting in a file the plugin had promised not to touch. A consumer's page
went on naming the branch document `development.md` and listing two pre-rename plugin ids, with no way to
correct it and no way for a reader to tell whose sentence had gone stale. Three ways out, all the
consumer's: write outside the block, delete both markers to own the paragraphs, or edit inside and know
they are replaced. **A page from before the fence is left exactly as it is** -- an opening marker with no
closing one has no machine-readable end, so the run reports it and names the edit that opts in.

**Score:** 3

#### What makes this deploy extra special

Neither shape the issue proposed was built, and the reasons are measurements rather than preferences. A
vendored `HELP/` subtree duplicates ~203 KB into every consumer and repeats the defect #664 closed; a
separate pointer page duplicates what the folder README's intro already says, creating a second drift
surface inside one folder -- which is the complaint itself. Neither would have fixed the staleness that
was actually measured, because both leave the stale README standing.

One of the report's supporting claims also failed on contact with the tree: it treats pre-marker repos as
unreachable, and that case has been built and tested since the marker existed
(`adopt-workflow-folder.tests.ps1`, `$c12`). Their page carries no marker because Part 1 has not been
re-run there.

**Score:** 2

#### Pull Request

A refreshable plugin-owned region in the consumer's dkj-policy/README.md

Plugins: dkj-policy

[PR #1794](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1794)

---

### DEPLOY: fix/1786-stale-test-docstring · 20260910-110446

`connector-sessioncheck.tests.ps1`'s header said its first two branches drive the hook against this
repo's own root `scripts/task/plugin-versions.ps1`. They drive the plugin mirror beside the hook --
the `$cwd` candidate that once made the header true was removed on review. The docstrings now name
the mirror, and state the consequence the wrong name hid: after editing the source engine, rebuild
the mirror before running this suite standalone, or it reports on the previous version and says
nothing about having done so.

A test suite's own account of what it measures was wrong, and it cost one session a false all-clear
(47/0 against an unrebuilt mirror, then 41/6 from the same suite once it was rebuilt). Small because
the gate was never exposed to it -- the drift check errors on a stale mirror before the suites run,
so only a standalone run could be fooled. Noticed the moment somebody edits `plugin-versions.ps1`
and reaches for this suite.

**Score:** 2

#### What makes this deploy extra special

A docstring inside this repo's own test suite. Nothing here ships, and no consumer reads it.

**Score:** N/A

#### Pull Request

connector-sessioncheck.tests.ps1's header names the mirror it actually drives

[PR #1793](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1793)

---

### DEPLOY: docs/1784-measured-figure-gate-line-counts · 20260910-104705

The proposed line-count gate from #1784 is **declined on measurement**, and the measurement is recorded
where the gate's other declined rules live. **The reason that settles it is not the one the proposal
argues about: the defect it was filed over carries no digit** -- #1779's seven sites read "three thousand
lines" in words -- so no digit-anchored pattern can see it, check 16's own included, however precisely
tuned. For the figures such a pattern *can* see, extending check 16 (`[measured-figure]`) to line counts
produces 16 findings across the trunk of which exactly **1** is a real defect, in six classes no regex
separates from it; and writing the decline up with each instance cited verbatim, as a measurement here
must be, took the same rule from 16 findings to 26 -- so it penalises measuring and recording the result,
which is what the gate's other rules exist to encourage. One narrow variant **is** green -- a backticked
filename immediately before a present-tense copula, 1 of 1 on the trunk -- and it is recorded as measured
and left **unbuilt**, with its revisit condition, rather than declined: one subject tree-wide, blind to
the motivating defect, and still firing on the prose that cites it. Check 16's unit list stays
byte-shaped, deliberately. Its *file set* is a separate and real gap -- no figure gate reaches a `.ps1`
comment, which is where both recorded instances of this class happened -- filed as #1790. The one real
defect the measurement found is repaired.

**Score:** 2

#### What makes this deploy extra special

N/A -- nothing here reaches a consumer. The declined rule, its measurement and the repaired figure are all
this repo's own maintenance prose; no plugin payload, script or manifest changes.

**Score:** N/A

#### Pull Request

Record the measurement that declines a line-count figure gate, and the writing convention behind it

[PR #1791](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1791)

---

### DEPLOY: fix/1768-path-paste-one-answer · 20260910-103648

A filesystem path printed into a paste-ready command now has **one** answer again, the shared allowlist
`Get-PasteableRef -Kind Path`. Two branches answered #1762 eleven minutes apart and both landed;
`tidy-lib.ps1`'s `Format-PasteablePathToken` -- which quoted the path as a PowerShell literal rather than
judging it -- is retired, and `tidy-machine.ps1` joins `sync-main.ps1` and `check-plugin-integrity.ps1`
on the allowlist. Fixes inbound #1768.

The literal lost on the destination, which is the one thing a printed remedy does not know. It is exact
in PowerShell and silently wrong in Git Bash, which reads its doubled quote as close-then-open and turns
`C:\it's\here` into `C:\its\here` -- a different, plausible path, with no error to notice -- while cmd
splits any spaced path in two. `tidy-machine.ps1` prints a PowerShell-only `worktree-lane.ps1 -HandBack`
and a bare `git worktree remove` from the same call, one line apart, and the second is exactly what a
reader pastes into Git Bash. Its own justification had also expired before it was read: it argued no
absolute path could pass the allowlist, which #1765 had fixed eleven minutes earlier.

**Score:** 2

#### What makes this deploy extra special

The report's own proposed alternative is declined with a measurement rather than adopted: *"if the
allowlist wins, it needs at least a space"* would break the guard rather than widen it, because the token
is printed **unquoted** by design and a spaced path splits in all three shells, not one. A space is the
one character an allowlist over an unquoted token can never admit -- so the refusal plus the note is the
answer, and the suite has asserted it since #1762.

That is the second of #1768's two halves to fail on contact with the tree. The first is its claim that
`tidy-lib.ps1` cites #1762 as open and carries a sentence about where the reasoning belongs; neither is
in the repo. The symptom it reports -- two mechanisms for one question -- was real and is what got fixed.

**Score:** 3

#### Pull Request

One answer for a path in a printed command: the allowlist, not the PowerShell literal

Plugins: dkj-policy, dkj-subagents-shopify

[PR #1789](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1789)

---

### DEPLOY: fix/1779-stale-lib-line-count · 20260910-101138

Seven docstring sentences across five libs sized `entry-scaffold-lib.ps1` at "three thousand lines" where it
measures 8,289 -- each of them in the sentence carrying a layer or dependency decision, so the stale figure
argued for the decision at a third of its real strength. They now say "thousands", which cannot go stale
upward, and `release-lib.ps1` records why the number is deliberately absent. The two sites that sized the
load of `release-lib` rather than the lib itself named a figure that understated either reading; both now
name the dependency chain instead.

The defect class is the point rather than the arithmetic: a size written into prose drifts with every commit
to the file it describes, and it gets copied rather than re-measured -- `check-connectors.ps1` declined to
call into `release-lib` and cited this docstring as its evidence (#1775), which is how one stale number
became two.

**Score:** 2

#### What makes this deploy extra special

N/A -- comments inside this repo's own script layer. No behaviour changes, no consumer-facing text moves,
and nothing a subscriber of a service could notice.

**Score:** N/A

#### Pull Request

Correct the stale entry-scaffold-lib line count in the layer-decision docstrings

Plugins: dkj-policy

[PR #1787](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1787)

---

### DEPLOY: docs/1774-settings-reflow · 20260910-100232

Every `claude plugin install`/`uninstall --scope project` rewrites the tracked `.claude/settings.json`
and strips the blank lines that group its 60-entry `permissions.allow` into git / gh / scripts /
release blocks -- measured over nine such commands with `enabledPlugins` byte-identical before and
after. It is the CLI's own settings writer doing a JSON round trip, so there is nothing in this repo to
repair; what there was, was a session meeting an unexplained diff with no warning and having to work out
from it that the tool and not the work had caused it.

So it is written down twice, split the way this repo's own rule splits a lesson. The **portable** half
is in Sylvester's manual, because the mechanism belongs to any repo whose settings file is tracked and
that does plugin administration at all: what the round trip loses, that `git checkout -- <file>` is the
remedy and re-serialising the captured content is not, and that a `git add -A` in the same sitting
commits the reflow silently -- valid JSON, functionally identical, past every check there is. The
**local** half is in his lens, beside the `claude plugin marketplace remove` bullet it is the sibling
of: the measurement, why this repo meets it routinely rather than once (it consumes its own marketplace
with all six plugins enabled), and what the never-commit-on-`main` rule adds to the cost of a stray
diff.

Both halves say why the two mechanical repairs were declined. Dropping the grouping would pay for
round-trip stability with the readability the blocks exist for; a gate refusing a whitespace-only diff
on one file is the shape this lens already records as measured and declined for the control-character
rule. Neither would change the CLI, which is the only thing that could actually stop it.

**Score:** 2

#### What makes this deploy extra special

N/A -- this repo publishes a plugin rather than a subscribed service. The reader who gains something is
a consumer developer, who now receives the portable half with the next release instead of nothing at
all, and that is the score above.

**Score:** N/A

#### Pull Request

plugin administration reflows the tracked settings.json -- recorded where it is met

Plugins: dkj-subagents-alpha

[PR #1785](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1785)

---

### DEPLOY: fix/1773-retired-plugin-name-records · 20260910-095038

`tidy-machine` gained an eleventh lane, and it closes the half of a defect lane 8 could never see: an
install record naming a **plugin the marketplace no longer lists**, for a checkout that is still there.
Lane 8 probes the record's `projectPath`, so a rename -- a deliberate act this workflow performs, twice
in two days in #1697 and #1698 -- silently turned every existing record into dead weight that no lane
reported. Measured on the machine this landed from: seven such records, under two retired naming
generations. The lane names each one, hands over the uninstall, and says which checkout it has to be run
from, because an uninstall is keyed on the directory it runs in.

Three decisions inside it are worth naming. The authority is **each marketplace's own clone** under
`~/.claude`, per marketplace, which is the caveat #1773 raised: a name alive in one marketplace says
nothing about a record naming another, and a clone this run could not parse produces silence rather than
a verdict. The printed `--scope` is the **record's own** and never a fixed `project`, because an
uninstall at `project` refuses a record sitting at `local` (inbound #315) and a session start alone is
enough to create one. And the lane is numbered 11 rather than slotted in beside its sibling: lane
numbers are cited in the changelog, the skill page and a sibling suite, so adjacency would have cost
more than it bought.

Lane 8 also stopped printing findings with the plugin name missing. It read a `Plugin` field on the
install record, which nothing writes -- the projection carries `Id` -- so every finding it has ever made
named a path and no plugin. Its own fixture hand-wrote that field and no assert read the value back,
which is exactly why the suite was green; the id is asserted now.

**Score:** 3

#### What makes this deploy extra special

N/A -- this repo publishes a plugin rather than a subscribed service, so no subscriber sees a
maintenance lane. The reader who does is a consumer developer running `dkj-policy`, and that is the
score above.

**Score:** N/A

#### Pull Request

tidy-machine reports install records under a retired plugin name

Plugins: dkj-policy

[PR #1783](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1783)

---

### DEPLOY: fix/1775-connector-unregistered-plugin · 20260910-095035

`check-connectors.ps1` no longer goes silent about a plugin that a consumer has **enabled** but that
consumer's `connectors/<repo>.json` does not **list**. Such a plugin was never handed to the per-plugin
loop, so nothing about it was checked -- not the extension inventory, not the machine version -- and
nothing was printed either, which made the register unauditable against the settings file it exists to
describe. A new check 5 reports each one as an `[INFO]`, and adds a non-counting `[UNLISTED]` line for
the repo the session is actually in, on the same terms and with the same `Test-IsSessionRepo` scoping as
`[INVENTORY]`. Only ids naming this repo's own marketplace are in scope; a retired id still counts,
because the register records what a consumer has.

Measured here before the change: of the six plugins this repo enables, exactly one produced a line --
the other five, one of them merely coinciding with a differently-named retired entry, were checked by
nothing and reported by nothing. The asymmetry had been written down as acceptable on the ground that
its population was zero; that stopped being true on September 8, 2026, and this is the repair rather
than a second note saying so.

**Score:** 3

#### What makes this deploy extra special

A consumer running `dkj-policy` gets the new verdict at session start through
`connector-sessioncheck.ps1`: where their own register entry is behind their own enabled set, the
session now says so in one line instead of saying nothing. It changes nothing that was working and
adds no failure -- the marker is non-counting, so it never turns a clean run red.

**Score:** 2

#### Pull Request

check-connectors reports a plugin enabled in a consumer but absent from its register

Plugins: dkj-policy

[PR #1782](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1782)

---

### DEPLOY: docs/1769-marketplace-rename-prep · 20260910-093800

The `claude-code-specialists` -> `dkj-claude-plugins` rename (#1769) now has a recorded decision and a
phased migration plan on the issue, and `scripts/repo-config.ps1`'s carve-out comment no longer
contradicts it. No rename has been performed -- this is the reversible fase 0 groundwork only.

**Score:** 2

#### What makes this deploy extra special

N/A -- no subscriber of any consuming service sees a prep branch. The rename itself reaches tier 2 at
significance 5, but that lands in fase 3, not here.

**Score:** N/A

#### Pull Request

Prepare the claude-code-specialists to dkj-claude-plugins rename

[PR #1778](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1778)

---

### DEPLOY: fix/1772-plugin-versions-noop-action · 20260910-093114

`plugin-versions` no longer tells a checkout that is simply sitting between two releases that it is
behind, and no longer hands it a command that cannot act. An install whose recorded commit is an
ancestor of the marketplace clone's HEAD **while both sides carry the same version string** is now
reported as what it is -- the released version, with unreleased commits in the clone -- in its own
summary bucket, with no command at all. `claude plugin update` arbitrates on the version string, so
across that boundary it reports *"already at the latest version"* and moves nothing; measured on
`dkj-policy` and `dkj-policy-bwj` at `4.33.0` on both sides, September 10, 2026
([#1772](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1772)).

The half that reaches furthest is `-Brief`, which `connector-sessioncheck` forwards into a session's
context at every start: that verdict was an `[ERROR]` carrying the no-op, so the loudest marker this
tool has fired at every session start of every checkout in the most ordinary state one can be in. It is
`[INFO]` now, by the same rule #1591 wrote for a stale clone -- an `[ERROR]` is for the verdict a reader
closes with a command here and now, and this one has no command.

Nothing was prescribed in its place, deliberately. An `uninstall` + `install` would cross a same-version
boundary, but it would put a consumer on code no release has shipped, and this branch has not measured
that it works -- so the report says the gap closes at the next release cut and stops there. Two wrong
statements inside the same block went with it: the *"same version string"* claim that fired when it was
the clone's `plugin.json` that had no version, and the *"none confirmed up to date"* summary sentence
that fired on runs which had confirmed several.

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo publishes a plugin rather than a subscribed service, so no subscriber sees this. The
reader who does is a consumer developer running `dkj-policy`, and that is the score above.

**Score:** N/A

#### Pull Request

plugin-versions no longer prescribes a no-op update for the same-version-newer-commit case

Plugins: dkj-policy

[PR #1777](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1777)

---

### DEPLOY: fix/connector-record-catch-up · 20260910-092155

This repo's own connector record described two plugins while the repo runs six, so five of them sat outside `check-connectors.ps1` entirely -- one skipped behind an `[INFO]` for the retired `dkj-team-alpha@` id, and four never looped over at all because a plugin absent from the array is silent rather than reported. The record now names all six at the ids the 4.33.0 rename gave them, with each inventory counted from the marketplace clone's payload rather than carried forward, and the note says what the two gaps cost in the register of the repo that owns the check. The half this does not do is the checker itself: the 2026-08-21 argument for leaving the silent route unreported rested on its population being zero, that stopped being true on 2026-09-08, and #1775 carries it.

**Score:** 3

#### What makes this deploy extra special

N/A -- `connectors/` is this repo's own register of who consumes what, read by a maintenance script here. It ships in no plugin and reaches no consumer of the specialists system.

**Score:** N/A

#### Pull Request

Catch this repo's own connector record up to the six plugins it has

[PR #1776](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1776)

---

### DEPLOY: fix/1764-agents-manifest-file-list · 20260910-085218

The four team plugins can be installed again. Every one of them shipped `v4.33.0` with
`"agents": "./subagents/"`, which the installer refuses outright -- `agents: Invalid input` -- so four
of the six plugins in this marketplace could not be installed by anybody for a whole release, while
this repo's own lint gate and CI both reported `0 error(s)` over them. Each manifest now lists its
subagent files, which is the only shape the field accepts, and check 38 holds the class shut at both
ends: an entry that is not an existing `.md` file inside the plugin (what #1764 measured) and a def on
disk that no entry names (what a hand-maintained list of 26 paths is exposed to next).

**Score:** 5

#### What makes this deploy extra special

A consumer on `v4.33.0` cannot install four of the six plugins at all, and the failure is a validation
error rather than a missing feature -- so there is no partial state to work around. After a
`claude plugin marketplace update` the installs succeed again. Nothing else about the plugins changes:
the `subagents/` directory keeps its name, every specialist keeps its id, and no consumer has to edit
anything of their own.

**Score:** 5

#### Pull Request

The four team plugins install again -- the agents key lists its subagent files, and the gate holds it to the directory

Plugins: dkj-subagents-alpha, dkj-subagents-ecomm, dkj-subagents-lifehub, dkj-subagents-shopify

[PR #1770](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1770)

---

### DEPLOY: feat/tidy-machine-skill · 20260910-084037

A new `tidy-machine` skill and script clear the clutter this workflow leaves on a machine, in one
command and ten lanes: stale worktree lanes, branches whose pull request was CLOSED without merging,
expired `backup/*` branches, old stashes, an unfolded changelog entry, the `~/.claude` plugin
administration, install records pointing at a checkout that has moved, plugin staleness, and fixture
trees under the scratch root.

It is a conductor rather than a second implementation: six of the ten lanes call a script that
already exists and already has its own suite, and the new logic is pure and testable in
`tidy-lib.ps1`. The one thing it adds to the workflow's vocabulary is a **second proof** -- a pull
request CLOSED without merging, which is the only evidence that separates abandoned work from
unfinished work without guessing from a date. That proof is held to the same name-AND-tip pair test
as the merged one, through the same shared functions, because a name-only match is what inbound
#1190 and #1191 both cost.

It deletes only what `prune-merged` can already prove, on Dave's answer of September 10, 2026;
everything else is classified and handed over with the command. Lane 1 runs first because git
refuses to delete a branch held by a worktree, and that refusal outranks the merge question (#1760).

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo publishes a plugin rather than a subscribed service, so no subscriber notices a
maintenance command. The reader who does is a consumer developer, and that is the tier-0 answer above.

**Score:** N/A

#### Pull Request

A machine-wide tidy: one command for the clutter this workflow leaves behind

Plugins: dkj-policy

[PR #1767](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1767)

---

### DEPLOY: fix/1762-pasteable-path-absolute · 20260910-082956

`Get-PasteableRef -Kind Path` now judges a filesystem path against its own allowlist
(`$PathPasteSafePattern`) instead of the ref one, so an **absolute** path can pass: the pattern adds the
drive/scheme `:` and a leading `/` for a POSIX root, and `ConvertTo-PastePath` folds `\` to `/` first so
the one printed token is correct in Git Bash as well as PowerShell and cmd. Everything the ref allowlist
refuses -- a space, `$`, a backtick, a quote, `;`, `&`, `|` -- is still refused, and the deliberately
narrow `-Kind Ref` axis (#1594, #1617) is unchanged. Fixes inbound #1762: the `-Kind Path` callers that
carry an absolute path -- `check-plugin-integrity.ps1`'s nested-worktree remedy today, `tidy-machine` and
`worktree-lane` next -- were getting the `<path>` placeholder for every real path.

**Score:** 3

#### What makes this deploy extra special

N/A -- an internal formatter for the workflow's own printed remedies; no subscriber of a service reaches it.

**Score:** N/A

#### Pull Request

Get-PasteableRef -Kind Path accepts an absolute filesystem path

Plugins: dkj-policy, dkj-subagents-shopify

[PR #1765](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1765)

---

### DEPLOY: fix/1760-prune-merged-worktree-held-branch · 20260910-081941

`prune-merged.ps1` no longer attempts a delete git is certain to refuse. A branch that is provably
merged but checked out in another worktree is reported kept in the script's own vocabulary, naming
the directory holding it and the `worktree-lane.ps1 -HandBack` command that frees it -- the sentence
#1069 already gives for a lane holding the trunk. `-DryRun` answers the same question, so the
look-first run no longer promises a delete the real run cannot perform.

The seam this closes: `worktree-lane.ps1` states that branch cleanup is `prune-merged.ps1`'s, and
`prune-merged.ps1` removes no worktree -- so a lane whose work had landed was owned by neither, and
the hand-back was a manual act nothing prompted for.

Small, and only visible to somebody running lanes: it prevents a confusing report rather than a loss.
The failure it prevents, named because the tier asks for it -- a session reads `git branch -D
refused: error: cannot delete branch 'x' used by worktree at '...'`, which is git's vocabulary rather
than this script's proofs, and has to work out for itself that the way out is a hand-back.

**Score:** 2

#### What makes this deploy extra special

Nothing reaches a subscriber: this is a maintainer's tidy-up command in the workflow plugin.

**Score:** N/A

#### Pull Request

prune-merged: a merged branch held by another worktree is kept with the hand-back, not handed git's refusal

Plugins: dkj-policy

[PR #1763](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1763)

---

### DEPLOY: docs/release-title-convention · 20260910-080700

From `v4.33.0` on, this repo titles every release `Release version X.Y.Z` and stops composing a
one-sentence summary that a large multi-theme cut makes meaningless. The decision and its reasoning are
in `dkj-policy/releases/README.md`'s *Local decisions* section; Rendall's lens carries the operating
instruction. The `-Title` parameter is untouched — a descriptive sentence is still valid for a repo
whose releases each carry one theme, and `-SummaryFile` still handles a genuine milestone.

**Score:** 1

The failure it prevents: a `history.md` title column and a GitHub Release heading filling up with
forced one-liners that describe none of the dozens of unrelated entries beneath them.

#### What makes this deploy extra special

One portable clause reaches a consumer, in the `cut-release` skill they read: a stable
`Release version X.Y.Z` is named as a legitimate title rather than something to apologise for. It
changes no command and no behaviour — the entries and attachments carry the detail either way.

**Score:** 1

#### Pull Request

Record that this repo titles every release Release version X.Y.Z

Plugins: dkj-policy

[PR #1761](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1761)

---

### DEPLOY: docs/1719-concurrent-pair-voiding-rate · 20260910-075556

Anyone changing `ship-pr.ps1`'s staleness gate now reads why it refuses, not just how often. The
block already carried the rate and (since #1750) its predicate; what it did not carry is the driver.
Issue #1719 measured it while being closed: the refusal tracks two branches CERTIFYING at the same
time -- 2 of 5 tight concurrent pairs lost a lap against 0 of 10 PRs outside such a pair -- and not
the trunk's own commit rate, which the paragraph above it had reached for. The practical consequence
is recorded with it: shipping one branch at a time drives the row to zero at no cost, which is why
#1719 closed against its own ranked converger options instead of building one. The measurement's
window, population and discount are stated, so the next reader can compare rather than re-argue.

**Score:** 3

#### What makes this deploy extra special

N/A -- a comment block inside a maintenance script. No consumer of this repo's plugins reads it and
no released behaviour changes; the mirror moves only so the drift lint stays green.

**Score:** N/A

#### Pull Request

Record the concurrent-pair voiding rate beside the step-3b predicate

Plugins: dkj-policy

[PR #1759](https://github.com/DKJ-Solutions/claude-code-specialists/pull/1759)

---

