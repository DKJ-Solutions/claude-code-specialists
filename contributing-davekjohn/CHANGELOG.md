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
[`contributing-davekjohn/CONTRIBUTING.md`](CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `##### Tier N`
sub-section per tier where a repo writes them numbered, each closing with its score; here the audience tier
carries a named heading beside the others instead. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---

## [Unreleased]

### DEPLOY: `docs/sync-main-trigger-v1` · 20260901-182430

`sync-main` now states **when it fires**, in one place, and the two pages that used to restate it link
there instead. The trigger: before a live push, and before work that will edit theme files -- not before a
branch that cannot touch one.

The gap was never that the trigger was unwritten. It was written **three times**, differently, and each
copy looked authoritative from where it sat: the skill's frontmatter said *"any theme task"*, `start-task`
step 2 made a sync an unconditional gatekeeper, and Sandra's manual said *"before every task ... which is
the definition of a hook"*. Two Shopify consumers of one owner then read the same step as
mandatory-always, mandatory-for-theme-work and optional -- and neither of them had drifted; each had
picked up a different one of the plugin's own wordings faithfully.

What that cost, measured on September 1, 2026 in the strict consumer: a session picked up an issue whose
entire content was a paste of `.claude/settings.json`, ran the sync first because its `CLAUDE.md` said to
before *any* task, pulled the live theme, classified 25 paths held back and 4 to take, and reported that a
real run would have refused on a standing predecessor branch. **That refusal is the structural half.**
Inbound #1021 made a standing sync branch stop the run, on the reasoning that refusing costs nothing
because the drift already sits on the predecessor -- and that holds only while the sync is a step in theme
work. Mandate it before every task and one unmerged sync PR becomes a gate on the start of *all* work in
the repo, documentation and permission changes included.

The narrowing is the owner's, twice over: his instruction is quoted in the issue, and the plugin already
carried the precedent -- inbound #805 moved the preview theme out of `start-task` on the same argument, at
6 of 12 previews belonging to branches that never needed one. A preview theme is a consequence of *"I want
to show this"*; this sync is a consequence of *"I am about to touch the theme"*.

The skill's section also says out loud that the trigger lives there and nowhere else, and that the name
*pre-task sync* is a label rather than the trigger -- because the name is what every paraphrase reached
for.

**Score:** 4

#### What makes this deploy extra special

A Shopify consumer stops running a live theme pull, a full-theme comparison and a possible hard refusal at
the start of documentation, tooling, CI and config work that cannot touch a theme file -- and stops having
one unmerged sync PR block the start of that work. It also gives their `CLAUDE.md` a section to point at
instead of a fourth paraphrase to write.

**Score:** 3

#### Pull Request

state when the pre-task sync fires, once, in the skill both other pages point at

Plugins: team-shopify

[PR #1198](https://github.com/DaveKJohn/claude-code-specialists/pull/1198)

---

### DEPLOY: `fix/merged-pr-proof-shared-v1` · 20260901-164752

The proof that a merged PR is about **this ref** and not merely about a branch that once wore its
name now lives once, in `scripts/lib/merged-pr-lib.ps1`, and both scripts that need it call it.

It had lived twice since September 1, 2026, when two branches open at the same time repaired the
same defect class independently and correctly -- inbound #1190 in team-shopify's `sync-main.ps1`,
#1191 in the workflow plugin's `prune-merged.ps1`. The copies diverged the same day, on the guard
that is easiest to leave out because nothing fails without it yet: one keyed its lookup with
`[System.StringComparer]::Ordinal` and wrote down why git refs are case-sensitive, the other used a
bare `@{}`, whose comparer is not. A merged `Sync/live-x` could therefore be found under a standing
`sync/live-x` in one script and not in the other.

The lib carries the map, the sha-shape validation, the ordinal comparer and the two-part test; each
caller keeps its own gh transport, because each has a written reason for the one it uses that does
not travel to the other. It is registered twice in `Get-SharedScriptPairs` and mirrored into both
plugins rather than reached across between them -- they are separately versioned and separately
installed, so a cross-plugin path is a dependency a version mismatch breaks silently.

**Score:** 2

#### What makes this deploy extra special

It is #81's and #815's argument arriving from the inside, with a date on it. The case for a single
source is normally made in hindsight, about a copy that drifted over months; this one drifted in
hours, between two branches that were both right, and the half that went missing was the half whose
absence changes nothing today. That is the shape worth recording: duplication does not announce
itself by failing.

The behavioural change in this repo is one sentence in one report. In `prune-merged.ps1` a
case-differing merged name was *found* under the default comparer and the tip comparison then
failed, so the branch was kept with the reason *"the name was recycled"* rather than *"no merged
PR"* -- a wrong sentence, not a wrong action, and a false delete would additionally have needed two
branches differing only in case sitting on the same commit, where nothing is lost. Neither case was
constructed; the comparer difference was verified directly, and it is now pinned by a test on both
transports.

**Score:** 1

#### Pull Request

The merged-PR proof lives once, in a lib both plugins mirror

Plugins: contributing-davekjohn, team-shopify

[PR #1195](https://github.com/DaveKJohn/claude-code-specialists/pull/1195)

---

### DEPLOY: `fix/prune-merged-proof-by-oid-v1` · 20260901-155946

`prune-merged.ps1` proved a merge by branch **name**, so a name that had been merged once and then
recreated inherited the old branch's proof forever -- and its new, unmerged commits were force-deleted
with `merged PR` printed beside them. That is not hypothetical recycling: `deleteBranchOnMerge`, which
this script's own header leans on for the remote half, is exactly what frees a name for reuse. Measured
in a consumer whose pre-task sync names its branches `sync/live-<date>`, where a second sync the same day
reuses the name: `sync/live-2026-09-01` was deleted on PR #141's merge while the commit it stood on
belonged to #159, still open. Both passes now require the branch's tip to BE the merged PR's head commit,
and a recycled name is kept with a reason saying so. It matters most in `-IncludeRemote`, which hands over
a `git push --delete` line for the copy of last resort.

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo's own maintenance tooling. No subscriber of a service notices a local branch-reaping
script, and nothing about the consumer-facing product changes.

**Score:** N/A

#### Pull Request

prune-merged proves a merge by the PR's head commit, not by its branch name

Plugins: contributing-davekjohn, team-alpha

[PR #1193](https://github.com/DaveKJohn/claude-code-specialists/pull/1193)

---

### DEPLOY: `fix/sync-guard-merged-by-oid-v1` · 20260901-152556

The pre-task sync's standing-predecessor guard now proves that the *ref* was merged, not merely that
something once carried its name. Branch names are date-stamped and get reused, so a `sync/live-<date>`
branch that merged and was deleted used to vouch for the brand-new, unmerged branch that took its name
later the same day: the guard reported `all merged`, found nothing standing, and pushed a `-2` branch onto
exactly the pile it exists to prevent. It now compares the standing ref's current tip against the tip the
merged PR carried (`headRefOid`), which also declines a branch somebody pushed one more commit to after
its PR landed, and still recognises the squash-merged ref that lingers on a repo without
`delete_branch_on_merge` -- the case the name match was added for.

**Score:** 3

#### What makes this deploy extra special

A consumer running the pre-task sync gets a guard that fires on the case it was silently missing, so
unmerged sync branches stop stacking behind a name collision. The failure needed no unusual setup -- two
syncs on one day, which is what a busy live theme produces -- and it was invisible from the outside, since
a run that misses a predecessor looks exactly like a run that had none. Measured in
BWJ-ecommerce/xoxowildhearts on September 1, 2026: `4.27.0` reported `1 found on origin, all merged` while
that branch had an open PR. It also unblocks that repo's own issue #57, the retirement of the local
`sync-main.ps1` fork it has been carrying as a bridge.

**Score:** 4

#### Pull Request

The standing-predecessor guard proves the ref was merged, not just its name

Plugins: team-shopify

[PR #1192](https://github.com/DaveKJohn/claude-code-specialists/pull/1192)

---

### DEPLOY: `fix/sync-main-checks-poll-bounded-v1` · 20260901-134631

`sync-main.ps1`'s `gh pr checks` polling loop -- the last network call in that script outside
`Invoke-NativeCapture` -- now runs through it with the shared 120-second bound, so a poll that hangs is
killed and reported instead of stopping the run dead. **The loop was bounded and the call was not, and
those are different bounds:** `-ChecksTimeoutMinutes` is re-read only at the top of the `while`, so it
limits how many times the script asks, not how long any one ask may take. A single `gh pr checks` that
never returned never reached that condition again, and a run that had already opened the sync PR sat
there for as long as the process lived. That is the same class inbound
[#1179](https://github.com/DaveKJohn/claude-code-specialists/issues/1179) and
[#1181](https://github.com/DaveKJohn/claude-code-specialists/issues/1181) closed, arriving through the
one call that looked as though it had been handled.

**A timeout is not a verdict**, and preserving that is most of the change. The run warns, treats the
poll as unanswered and keeps polling until the deadline, because a slow answer is not a red check. Two
things would each have turned a stall into a wrong answer and neither is visible in a call count: the
bounded arm *appends* two `[timeout]` lines to its output, which parsed as check states match nothing
and read as CI failure; and `gh pr checks` exits 8 while checks are pending and 1 when one has failed,
so gating the parse on a zero exit would have thrown away a real red and sat out the whole timeout
before reporting "not green" for a PR that was already broken. The exit code is therefore deliberately
not judged here, exactly as before -- this loop has always read the states.

**This reverses the last sentence of the entry above it**, which recorded the poll as deliberately
untouched. Both reasons #1184 gave for that turned out not to hold: "it is bounded already" was true of
the loop and not of the call, and "a bound per call is the mistake the lib warns about by name" pointed
at `gh pr checks --watch` in `ship-pr.ps1`, which blocks for as long as CI takes by design. What was
true is that the hand-rolled `$ErrorActionPreference` bracket was load-bearing -- it had to swallow the
stderr a pending run writes while still reading states off stdout -- and `-DiscardStderr` does that
half, measured rather than assumed. With the poll routed, the lib's own docstring claim that *every*
git and gh call in the workflow scripts comes through this one function is true in this tree, and the
script now carries no hand-rolled EAP bracket at all.

**Score:** 3

#### What makes this deploy extra special

N/A -- a consumer running `sync-main.ps1` is the reader, and this repo's subscriber never sees it. The
change is invisible until the day a `gh` poll stalls, and on that day it is the difference between a
15-minute silence and a named failure.

**Score:** N/A

#### Pull Request

sync-main.ps1's CI poll is bounded per call, not only across the loop

Plugins: team-shopify

[PR #1189](https://github.com/DaveKJohn/claude-code-specialists/pull/1189)

---

### DEPLOY: `fix/shopify-cli-calls-not-bare-v1` · 20260901-131625

Every Shopify CLI call in `team-shopify` — the live-theme pull in `sync-main.ps1` and the three in
`push-preview.ps1` — was invoked bare under `$ErrorActionPreference = 'Stop'`. In Windows PowerShell 5.1
a single stderr line from the CLI is a **terminating** `ErrorRecord`, at exit code 0 as much as any
other, so the run died on the line *after* the call and the `$LASTEXITCODE` block below it never ran.
For the pull that block is the one that deletes the temp mirror and says `The Shopify pull failed.
Nothing was touched.` — so the failure mode was not a slower failure but a different one: a mirror left
behind and a message nobody saw. All four now go through `Invoke-ShopifyCli`
(`scripts/lib/shopify-cli-lib.ps1`), which lowers the preference for the duration of the call, restores
it in a `finally`, and hands back the exit code.

The half that makes it stick is lint check 31: every `.ps1` in the tree is parsed for a command named
`shopify`, and the two files allowed to hold one are named. **The dangerous form is the ABSENCE of a
wrapper** — there is no redirect to grep for and no suspicious flag, the wrong spelling is simply the
shorter one, which is how four bare sites accumulated without anyone noticing.

The part worth reading twice is where the `ErrorRecord` actually comes from. On Windows `shopify` is
npm's generated PowerShell shim, and `& shopify` runs it **in-process**, so it inherits the caller's
preference — measured, and pinned by the suite. That is why a `try/catch` at the call site would not
have fixed this, and why the report's distinction between its confirmed captured call and the
"not separately reproduced" uncaptured one does not hold: the frame that wraps stderr is one level in,
below both.

**Score:** 3

#### What makes this deploy extra special

A Shopify consumer running `team-shopify` gets this on their next update with nothing to configure, and
they are the only ones who can meet the failure — both scripts refuse to run in a repo that publishes
plugins. What changes for them is that a Shopify call that goes wrong now **reports itself**. The pull
that fails cleans up its mirror and says so; the preview push that fails says `Push failed.` instead of
ending on a `NativeCommandError` naming a file inside `AppData\Roaming\npm`.

It matters now rather than in the abstract because **the environment changed, not the code**: the CLI
writes a `claude-code-hint` line to stderr *while succeeding* when it runs under Claude Code. Nothing in
these scripts was wrong yesterday and nothing in them was edited to break — a bare native call is only
safe while the exe never writes to stderr, and that is not a property any calling script controls.

**Nothing to adopt and no flag to set**, and no behaviour changes on a successful run: the pull and the
preview push still stream their progress as they always did. The one visible difference is on failure,
which is the point.

**Score:** 3

#### Pull Request

the Shopify CLI is never invoked bare

Plugins: team-shopify

[PR #1188](https://github.com/DaveKJohn/claude-code-specialists/pull/1188)

---

### DEPLOY: `fix/sync-main-gh-calls-bounded-v1` · 20260901-124921

`sync-main.ps1`'s four `gh` network calls -- `pr list`, `pr create`, `pr view`, `pr merge` -- now run
through `Invoke-NativeCapture` with the shared 120-second bound, so each one gets the non-interactive
environment (`GIT_TERMINAL_PROMPT=0`, `GCM_INTERACTIVE=never`) and a stall is killed and reported as
exit 124 instead of sitting there looking like a run still in progress. That makes the lib's own claim --
every git *and* gh call comes through this one function -- true in this script for the first time. The
`gh pr checks` polling loop is deliberately untouched.

The repair also closed a defect the report did not name: `gh pr view` had no exit-code check, so an
unreadable PR number became an empty string and the checks loop then polled with no PR for the whole
timeout before handing the operator a `gh pr merge` line with no number in it.

**Score:** 3

A consumer running `sync-main.ps1` is the reader here, and the change is invisible until the day a `gh`
call stalls -- at which point it is the difference between a 120-second error naming the call and a run
that never returns. The `gh pr view` half is a real failure that could already happen: the PR opens, the
script waits out the full `-ChecksTimeoutMinutes`, and the instruction it prints is unusable.

#### What makes this deploy extra special

That the report was wrong in three places and still worth acting on. Its symptom stood, its line numbers
had moved, its size was overstated by four to one, its stated reason was weaker than the real one, and
its one explicit exclusion was correct for the wrong reason. Repairing to the report would have produced
a change that satisfies it and misses the actual defect -- the unjudged `gh pr view` -- which nothing in
the report mentions.

**Score:** 2

Method rather than payload: it is `triage-inbound`'s recount discipline applied to a report this repo
filed against itself an hour earlier, and it went wrong in three of six dimensions even then.

#### Pull Request

sync-main.ps1's four gh network calls go through Invoke-NativeCapture

Plugins: team-shopify

[PR #1186](https://github.com/DaveKJohn/claude-code-specialists/pull/1186)

---

### DEPLOY: `fix/sync-main-network-calls-bounded-v1` · 20260901-121405

`sync-main.ps1` — the pre-task sync `team-shopify` ships to the Shopify consumers — reached the network
five times with neither the non-interactive guard nor the bound that #1179 added, because that repair
landed at a choke point this script was not a caller of. All five now go through
`Invoke-NativeCapture`: they run with `GIT_TERMINAL_PROMPT=0` and `GCM_INTERACTIVE=never`, and a stall
kills the process tree after two minutes and reports itself instead of reading as a run still in
progress. Two calls also stop failing **silently**: an `ls-remote` or `fetch` that cannot reach origin
used to leave the standing-predecessor guard reporting `none on origin`, and the post-merge pull had no
exit-code check at all. The lib now travels in `team-shopify`'s own payload, so a consumer without the
workflow plugin gets it too.

For this repo the reach is narrow, and worth saying plainly: `sync-main.ps1` **refuses to run here** —
a repo that publishes plugins is its source, not a Shopify store. So nobody maintaining this repo will
meet the hang. What they meet is the maintenance shape: a second mirror entry for a lib that now travels
in two payloads, and a `the network guard` section in the suite that pins the five calls at five, so a
sixth added without a bound fails a test rather than shipping.

The part worth reading twice is not the bound. It is that two of these calls ran through a wrapper that
swallows stderr *by design*, and the guard reading them errs toward refusing — so a network failure
arrived as the one answer that guard treats as safe. Bounding them and stopping there would have made the
*hang* diagnosable and left the *silence* exactly where it was.

**Score:** 2

#### What makes this deploy extra special

A Shopify consumer running `team-shopify` gets this the moment they update, without configuring
anything — and they are the only ones who can meet the failure, because they are the only ones for whom
this script runs at all. The hang is not hypothetical for them: #1179 measured it on `DAVE-KOK-BWJ`,
fifteen minutes on a `git push` whose credential helper was drawing a window nothing was listening to.
This is that same push, in the script whose commit holds a third party's in-flight edits to the live
theme — taken out of a mirror the `finally` block then deletes, so until the push lands the only copy of
that work is a local branch nobody is looking at, presented as a push still running.

**One thing to know if you run this script on a flaky connection**, because the behaviour genuinely
changed rather than only got safer: a `git ls-remote` or `git fetch` that cannot reach origin now
**refuses the run**, where it used to continue. That includes `-DryRun`. Nothing is written either way, so
the cost is re-running it; what you get back is that the standing-predecessor guard can no longer report
`none on origin` when what it actually means is that it could not ask. There is nothing to adopt and no
flag to set.

**Score:** 3

#### Pull Request

sync-main.ps1's network calls run non-interactively and bounded

Plugins: team-shopify

[PR #1185](https://github.com/DaveKJohn/claude-code-specialists/pull/1185)

---

### DEPLOY: `fix/git-calls-noninteractive-and-bounded-v1` · 20260901-114244

Closes inbound #1179. A git call made by the workflow scripts can no longer hang on a credential
prompt nothing will answer: every child now runs non-interactively, and the three calls that reach
the network are bounded so any other stall reports itself instead of reading as work in progress.

**Score:** 4

A hang here is not a slow run -- it is a run that never ends and says nothing, and it costs whatever
the gates had already paid for. The reporting machine lost a lint + 13-suite gate that way. Every
consumer of the workflow plugin gets this the moment they update, without configuring anything.

#### What makes this deploy extra special

The repair is at the choke point rather than at the two call sites the report named, so all 111
git and gh calls in the workflow are guarded rather than the two that happened to be measured.

**Score:** 3

#### Pull Request

git calls in the shared workflow scripts fail fast instead of hanging on a credential prompt

Plugins: contributing-davekjohn

[PR #1182](https://github.com/DaveKJohn/claude-code-specialists/pull/1182)

---

### DEPLOY: `feat/bwj-codex-rename-v1` · 20260901-104018

The `workflow-bwj` plugin is renamed to `bwj-codex` throughout the tree: its folder
(`plugins/workflows/bwj-codex/`), its `marketplace.json` name and source, its `plugin.json` name, its
test file (`scripts/tests/bwj-codex.tests.ps1`), and every current-tense reference in the root and
plugin READMEs, the `contributing-davekjohn` portable pages, and the plugin's own skill and template
text. The marketplace and plugin descriptions are reframed from "a narrow ticket-work workflow" to
"BWJ's codex -- the binding rules its two Shopify store repos operate under"; no capability is added,
the plugin still ships exactly the Asana ticket seam. Lint check 23 (`[plugin-kind]`) learns `*-codex`
as a third way-of-working name shape, the same accommodation it already makes for `contributing-*`.
The v4.28.0 release record is left intact except for one dead relative link, whose href is repointed
at the moved README. The one pending `## [Unreleased]` entry that names the plugin (PR #1176,
`fix/checkout-v5-node20-deprecation-v1`) is repointed `workflow-bwj` -> `bwj-codex` in its prose and
its machine-read `Plugins:` trailer, so the next cut attributes that work to a plugin name still in
`marketplace.json`.

**Score:** 1

A published plugin changes identity. Any repo that enabled `workflow-bwj@claude-code-specialists` in
`.claude/settings.json` must rename that entry to `bwj-codex@claude-code-specialists` or the plugin
silently stops loading. The plugin is one release old and opt-in, so the set of affected repos is
small-to-empty, but the change is breaking for an adopter rather than invisible plumbing -- above
tier 0.

#### What makes this deploy extra special

A consumer who had enabled `workflow-bwj` (BWJ's two store repos are the only intended adopters) needs
a one-line settings change to `bwj-codex` after taking the release carrying this. Nothing migrates
automatically and nothing warns; a session in a repo whose settings still name `workflow-bwj` just
loses the two skills and the CI template reference. Small, mechanical, but real for that reader.

**Score:** 1

#### Pull Request

Rename the workflow-bwj plugin to bwj-codex

Plugins: bwj-codex, contributing-davekjohn

[PR #1180](https://github.com/DaveKJohn/claude-code-specialists/pull/1180)

---

### DEPLOY: `docs/testrun-series-tail-1168-v1` · 20260901-084902

Close out the end-to-end testrun series ([#1135] → [#1157] → [#1168]). Run 5 met the series exit
criterion for the first time — **0 HARD, 0 FRICTION against `v4.27.0`, no inbound issue needed** — so
the series ends here. The residue the closed issues would otherwise have carried only as comments is
recorded below instead, in the changelog, where a future runbook author will find it.

**The one open measurement — the permission-classifier residue probe.** The same-shape A/B on the
permission classifier is one probe short. Both halves of the classifier already read PASS; this probe
only excludes *command shape* as an alternative explanation for one contrast. It is a tightening, not a
gate.

- **What:** `adopt-config.ps1` under the deny-everything protocol — deny the next two commands; a denial
  arrives back in the session, an `allow`-covered command simply runs.
- **Where:** a Claude Code session opened **inside `DaveKJohn/ccs-testrun-4`**, out of auto mode. A
  session in the source repo is structurally the wrong instrument — a model observes results, not
  prompts, so "asked and approved" and "never asked" are one event from its side unless the run is
  inside the consumer with the runner denying.
- **Status:** stays open on [#1168]. `ccs-testrun-4` is kept standing as the only place it can be
  measured.

**The amendment for the next step-4 runbook.** Run 5 did not walk step 4. Whenever step 4 is next
walked, it inherits this rather than re-deriving it:

1. **Name both permission layers and say they are different.** `permissions.defaultMode` in
   `settings.json` decides what a session **starts** in; the shift+tab toggle (*manual mode /
   auto-accept edits / plan mode*, where `default` is only the internal name for the first) is a
   separate layer. A runner who reads "manual" off the status line has recorded a true fact about the
   second and nothing about the first.
2. **Measure by denying, not by asking.** Asking the runner whether a prompt appeared does not work —
   where there are many prompts they get approved on autopilot. Deny everything for the next two
   commands and the outcomes become distinguishable with nothing resting on recollection: a denial
   arrives back in the session; a command covered by `allow` simply runs.

**Teardown of the test repos** (decision by Dave, August 31, 2026): `ccs-testrun-1`, `ccs-testrun-3`
(which takes [`ccs-testrun-3#5`](https://github.com/DaveKJohn/ccs-testrun-3/issues/5) with it) and
`ccs-testrun-5` are deleted; `ccs-testrun-2` (cited by `runlog-3.md`) and `ccs-testrun-4` (the residue
probe) are kept. The deletions are run outside this branch — they need the `delete_repo` gh scope.

[#1135]: https://github.com/DaveKJohn/claude-code-specialists/issues/1135
[#1157]: https://github.com/DaveKJohn/claude-code-specialists/issues/1157
[#1168]: https://github.com/DaveKJohn/claude-code-specialists/issues/1168

**Score:** 2

#### What makes this deploy extra special

N/A — internal QA bookkeeping; no subscriber of any consuming repo notices this.

**Score:** N/A

#### Pull Request

Testrun series tail: closeout plan for the #1168 residue

[PR #1173](https://github.com/DaveKJohn/claude-code-specialists/pull/1173)

---

### DEPLOY: `fix/shopify-floor-checkout-v5-consistency-v1` · 20260831-225420

`adopt-shopify-floor.ps1` scaffolded `theme-check.yml` with `actions/checkout@v7`, the one pin in the
repo not on `@v5` after the #1175 sweep. Both mirrored copies now pin `@v5`, and the test suite
asserts the scaffolded version so it cannot drift again.

**Score:** 2

#### What makes this deploy extra special

A consumer adopting the Shopify floor gets a `theme-check.yml` whose checkout pin now matches every
other workflow in the tree; no functional change while `@v7` still resolves, but the inconsistency is
gone. N/A — no service subscriber notices this.

**Score:** N/A

#### Pull Request

Shopify floor scaffolds actions/checkout@v5, matching the rest of the repo

Plugins: team-shopify

[PR #1178](https://github.com/DaveKJohn/claude-code-specialists/pull/1178)

---

### DEPLOY: `fix/checkout-v5-node20-deprecation-v1` · 20260831-223457

`actions/checkout@v4` targets Node 20, which GitHub now force-runs on Node 24 while emitting a
deprecation notice on every run. This bumps every `@v4` pin in the repo's shared workflow surface to
`@v5` (Node 24 native): the `bwj-codex` `asana-mirror.yml` template a consumer copies, the repo's
own `ci.yml` and `branch-entry.yml`, and the `branch-entry.yml` body `adopt-workflow-folder.ps1`
scaffolds into a consumer (both the script and its plugin mirror). Behaviour is unchanged; the
Actions log loses the deprecation line.

**Score:** 1

Cosmetic today -- the runs still succeed. It forecloses one failure: when GitHub retires the Node 24
fallback for actions still targeting Node 20, every `@v4` `checkout` step stops running, and every
`asana-mirror` run plus this repo's CI would break until someone traced it to the pin.

#### What makes this deploy extra special

A `bwj-codex` consumer who has copied `asana-mirror.yml` sees the deprecation line drop out of
their own Actions log (the reporter, BWJ-ecommerce/smartwatchbanden, filed it for exactly that), and
inherits the same foreclosed future break. Still cosmetic for them until that fallback is retired.

**Score:** 1

#### Pull Request

Bump actions/checkout@v4 to @v5 across shared workflow templates and CI

Plugins: contributing-davekjohn, bwj-codex

[PR #1176](https://github.com/DaveKJohn/claude-code-specialists/pull/1176)

---

### DEPLOY: `fix/score-line-trailing-reason-v1` · 20260831-211004

`**Score:** N/A -- <reason>` written on one line used to parse as *unanswered* (score 0, not N/A)
because the value has to be the last token on the line; a reason trailing on the score line now reads
the value and is named as a misplaced reason, the way one written below the line already was. Names
the failure it forecloses: an audience-tier entry written as `**Score:** 3 -- <reason>` would have
had its score ignored, resolved to tier 0, and silently under-bumped a release from minor to patch.

**Score:** 2

#### What makes this deploy extra special

Internal changelog-tooling fix; no subscriber of the service observes it.

**Score:** N/A

#### Pull Request

The score-line parser reads the value when a reason trails on the same line

Plugins: contributing-davekjohn

[PR #1174](https://github.com/DaveKJohn/claude-code-specialists/pull/1174)

---

