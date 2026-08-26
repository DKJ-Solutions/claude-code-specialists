# Contributing as DaveKJohn

**This is the one page this folder has.** It was two — a `CONTRIBUTING.md` holding this repo's answers and
a `CLAUDE.md` holding the workflow's mechanics — and they merged on August 26, 2026
([#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886), Dave): *"The CLAUDE.md in the
contributing-davekjohn folder has no use as well. I want to merge that file with CONTRIBUTING as one
complete CONTRIBUTING file. Because that should be the center of this folder."*

**It sits on top of two root pages, and wins over both on conflict** (Dave, August 14, 2026): the repo's own
[`CONTRIBUTING.md`](../CONTRIBUTING.md) and its [`CLAUDE.md`](../CLAUDE.md). Those two describe what holds
here whether or not this plugin is installed — never directly on `main`, branch + PR, CI green, and the three
direct-on-`main` exceptions with their bounds. This page carries what the **workflow** adds: the four gates,
how those three exceptions actually run, and the measurements behind them.

The split is worth what it costs for the reason the root pages give: the root loads on **every** session,
this page only when a session touches this folder. A rule that bites only while the workflow is in play does
not belong on the always-on path.

**The cycle itself is described once, with the plugin**, naming the *seam* wherever a repo owns the answer
instead of asserting one repo's answer as the rule:

📄 **[The contribution cycle — the portable half](../plugins/workflows/contributing-davekjohn/CONTRIBUTING-portable.md)**

Read that first. **This page is this repo's set of answers to it, arranged as the four steps work actually
moves through** (Dave, [#894](https://github.com/DaveKJohn/claude-code-specialists/issues/894)). That
arrangement is why there are exactly four numbered `##` sections below and nothing else, why each carries its
substeps as `###`, and why every gate sits as a `####` under the step where it fires rather than in a list of
its own.

**Four `##` sections *in total*, which is why this page now begins at step 1.** The two sections that used to
sit between the title and step 1 — the seam table and the pointer list — were `##` as well, so the page read
as six top-level sections of which two were not steps. They moved to
[`README.md`](README.md) on August 26, 2026 (Dave), where a folder index is what they always were.

**The levels here moved twice in two days, in opposite directions, and both moves were right.** On
August 26, 2026 the four steps first became the document's own top level (`#`), while the cycle document and
`CHANGELOG.md` moved one *deeper* — those two gained a heading above their contents (`## [Unreleased]`, and a
document title that is no longer an H1). Later the same day this page moved one deeper again, to the numbered
`##` the spec asks for, which is what leaves its `#` for the page title alone.

---

## 1. NEW DEVELOPMENT TASK

### 1.1. Create the branch and the empty `development-cycle.md`

**Two steps, one command, and that is the point rather than a shortcut.** `new-branch` does both: a branch is
never entry-less, so there is no moment at which the branch exists and its document does not. They are
numbered separately because the *order* matters to a reader — the branch is what the document belongs to —
not because anybody performs them apart.

`new-branch` creates the branch **and** its document in one move: a branch is never entry-less. The document
belongs to the **current branch** and exists only while one is open — the fold removes it at the merge, so on
the trunk it is simply not there. That absence is the trunk's normal state, not a file somebody deleted, and
it is why the file is named here without a link.

**Four `###` headings and never a fifth**, and nothing branch-specific above `### PLAN` (Dave, August 26, 2026).
PLAN, CREATE, TEST and DEPLOY are the whole top level; a section needing its own heading goes in as a `####`
under whichever of the four owns it, and everything between the title and `### PLAN` is the scaffolder's generic
guidance. No gate reads a heading, so both are conventions a writer keeps — measured the day they were
stated: `check-branch-entry.ps1` gives byte-identical output at four headings and at five. Recorded, with
that measurement, in
[`DEVELOPMENT-portable.md`](../plugins/workflows/contributing-davekjohn/DEVELOPMENT-portable.md).

**Pick the prefix by what actually changes**, not by which files move along: `docs/` is purely text, `feat/`
is a capability that is new or larger than it was, even when documentation comes with it.

| Type of work | Branch name | GitHub label | Changelog type |
|---|---|---|---|
| New or extended capability | `feat/<description>` | `enhancement` | Feat |
| Correction of an error in something existing | `fix/<description>` | `bug` | Fix |
| Documentation, workflow explanation, manual content | `docs/<description>` | `documentation` | Docs |

**There is no `chore/`, and `Test-BranchName` refuses it outright.** Chore is the name for work that lands
*directly on the trunk* under one of the named exceptions, so a chore branch is a contradiction. `Chore`
stays a recognised changelog **type** — every entry already written under it must still validate, and it is
what an unknown prefix falls back to. Recognise both, write one.

**Every branch name carries a version, and `new-branch` completes it.** `docs/thing` becomes `docs/thing-v1`;
a second cycle on the same subject is `docs/thing-v2`, typed deliberately rather than guessed — a rerun of
`new-branch` resumes the branch it named rather than opening the next one. The refusal on `final` in
[`branch-info.ps1`](../scripts/lib/branch-info.ps1) is the same rule from the other end: a name claiming to be
the last word is a prediction, and the number is the honest form.

**Re-read the file after `new-branch` has written it.** It is the only file here written out of band, and an
editor tracking what it last read refuses the next write until it has read again — one read fixes it and
nothing is lost. The fold no longer joins that list: it removes the document rather than rewriting it, so
there is nothing left to re-read. The portable statement, with the measurement, is in
[`DEVELOPMENT-portable.md`](../plugins/workflows/contributing-davekjohn/DEVELOPMENT-portable.md#the-file-is-written-under-you-once-per-cycle).

**The HTML comments are the form, not somebody's notes.** They say what a good answer looks like, and the fold
strips them on the way to `CHANGELOG.md`, so leaving one standing is not a defect. There is no template beside
the file and no empty copy on the trunk — the portable page is where the whole form can be read without a
branch open. **There is no `branch/templates/` any more either** (Dave, August 23, 2026): two generated
reference copies sat there because the working files were deliberately bare, and the merged document carries
its own guidance, so the reference and the file you write in are the same page.

### 1.2. Write `### PLAN`, `### CREATE`, `### TEST`

**Three phases, written in order, and each one is a list of `- [ ]` steps.** PLAN is what the work turns out
to be once it has been looked at rather than guessed at; CREATE is the steps that build it; TEST is the steps
that prove it. A step is open until it is resolved — `- [x]` done, or `- [~]` dropped **with the reason on the
line**, which exists so nobody ticks a box for work they did not do.

**A section needing its own heading goes in as a `####` under whichever phase owns it.** That is how the four
top-level headings stay four.

### 1.3. Write `### DEPLOY`

Its own step because it is written **last** and from a different question: the three phases above say what
must *happen*, DEPLOY says what the change *does*. See 1.5 for what "secured" means, and why the two are
separate numbers rather than one.

### 1.4. Verify every checkbox is resolved

**Nothing here is on your memory.** `open-pr` and `ship-pr` both refuse while a step above DEPLOY is still
open, and there is no `-Force`. This step is the moment to read the list rather than the moment to discover
one was missed — the step-list gate under 2.2 is the same question asked by a machine.

### 1.5. Wrap and secure DEPLOY: the development cycle is complete

**DEPLOY is written LAST, once TEST says so.** The other three phases carry the steps (`- [x]` done, `- [~]`
dropped with the reason on the line); `` ### DEPLOY: `<branch>` `` **is** the changelog entry and folds
**verbatim** into `CHANGELOG.md` at the merge. Written while steps above it are still open it states an
intention, and no gate holds it against what landed. A checkbox inside that section is prose, and no gate
reads it as a step.

**Its links are written root-relative, the whole document**, because the DEPLOY section lands at the repo
root. `scripts/x.ps1`, never `../scripts/x.ps1` — the second reads correctly here and is dead once it lands,
and `open-pr`'s link gate refuses it.

**The audience tier is `2` here, so the entry asks two questions rather than four.** Tier 0 needs no heading —
the `` ### DEPLOY: `<branch>` `` line is its section and its answer goes directly underneath — and the one
audience tier gets `#### What makes this deploy extra special`. Both sit at the entry's own section level,
beside `#### Pull Request`. A repo that has stated *no* audience tier gets the older shape instead, a
`##### Tier N` sub-section per tier, nested one level deeper; that is the portable half's fallback and not what
you will see here.

**In each tier, the reason goes ABOVE the `**Score:**` line** — anything below it is discarded.

**And then the development cycle is complete, and the branch waits.** Nothing else happens on it until an
explicit *open the PR* command, which is step 2.1. That wait is short and usually implicit — see
[`CLAUDE.md`](../CLAUDE.md) for the two narrow classes of change where it is a real stop, and why everything
else runs straight through.

---

## 2. PULL REQUEST

### 2.1. Open the PR

**This is where the waiting ends.** Step 1.5 leaves the cycle complete and the branch parked on an explicit
*open the PR* command — see [`CLAUDE.md`](../CLAUDE.md) for the narrow set of changes that genuinely wait on
Dave's word, and for why the default is that they do not.

`open-pr.ps1` is the one entry point: it runs the lint and test gates first, then pushes, then opens the PR.
On an error or a failing suite **nothing is pushed and no PR is opened** — `-SkipLint` / `-SkipTests` are the
escape valves, and using one is a decision rather than a convenience.

Its own number because the three gates below fire *here*, at the push, and because what it publishes is fixed
at this moment: 2.2 is what it puts in the body, and 2.2.3 locks that body against later edits to the
document.

### 2.2. Copy the last DEPLOY into the PR

`open-pr.ps1` composes the PR body from the document, and **four gates read it on the way**. Three run
locally, before the push and before the merge; the fourth runs in CI, and it exists because the first three
cannot. The repo's own lint and test gates are separate and stated in the [root `CLAUDE.md`](../CLAUDE.md):
`open-pr.ps1` runs [`check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1) and then every
`scripts/tests/*.tests.ps1`, refusing to push on any error or failing suite.

#### 2.2.1. the scaffold gate, on the changelog entry itself

**August 3, 2026.** `open-pr.ps1` refuses to push a branch whose entry still carries the wording
`new-branch.ps1` scaffolded it with — the placeholder title, the "to do / where I left off" heading, or the
fallback body. **Measured, after it had already shipped:** three of v3.2.0's twenty-one entries kept that
heading with a status appended behind it, and it reached the release notes *and* the per-plugin `CHANGELOG.md`
files that travel to consumers in the plugin cache. The window closes at the merge and closes **invisibly** —
the fold moves the entry into `CHANGELOG.md`, the next release moves it on into `releases/`, so by then the
place a reviewer would look is the one place it no longer is. Fenced code is excluded, so an entry documenting
this mechanism is not accused of it; the escape valve is deliberately separate from the lint and test skips,
because it overrules a judgement about content rather than skipping a tool. The wording lives in **one**
shared source ([`entry-scaffold-lib.ps1`](../scripts/lib/entry-scaffold-lib.ps1)) read by both the script that
writes it and the gate that refuses it — a copy in each would make the gate silently miss whatever the writer
changed.

**Two of those three strings are now recognised without being written** (August 6, 2026). The `branch/` split
moved the step list out of the entry, so the entry is no longer scaffolded with a to-do heading over a to-do
placeholder — its placeholder asks what the change *does*. The gate keeps refusing the retired wording, and
that is not politeness towards history: every branch in flight, here and in every consumer, carries an entry
with those strings right now, and consumers receive the new scripts through a plugin update rather than by
choosing to. A gate that forgot them would wave exactly those entries through. **Recognise both, write one** —
the same rule the tier line gets, and the same rule the folder rename got in step 3 below.

#### 2.2.2. the step-list gate, on the branch's own plan

**Dave, August 6, 2026.** A branch reaches a PR when its own plan is finished, so `open-pr.ps1` refuses to
push and `ship-pr.ps1` refuses to merge while the step half of `development-cycle.md` has an unresolved step.
**Both**, deliberately: the requirement Dave gave is about the *merge*, and `open-pr` has an escape valve — a
PR opened through it, or by hand on github.com, would otherwise land with an unfinished plan.

**Three marks, not two.** `- [x]` is done, `- [~]` is dropped with the reason kept on the line, and a step
still carrying the scaffold's placeholder is refused whether or not it is ticked. The third mark is what makes
the gate safe to leave with no override at all: without it the only way past a step that turned out not to be
needed is to tick it, which teaches people to report work they did not do — and a gate that then says success
is worse than no gate. **A branch with no step list at all is not refused**: that is the one-commit typo fix,
and refusing it would make the mechanism ceremony.

#### 2.2.3. the DEPLOY lock, on the section the PR published

**Dave, issue [#884](https://github.com/DaveKJohn/claude-code-specialists/issues/884), August 25, 2026.** The
DEPLOY section travels four times — this document, the PR body, `CHANGELOG.md`, the developer release notes —
and it has to be the same thing at every stop. So it is **fixed at the moment the PR opens**: `ship-pr.ps1`
refuses the merge when the document has since diverged from what the PR carries. No override, like the
step-list gate beside it.

**What it closes is a window that shuts invisibly.** An edit made after the review lands in `CHANGELOG.md` and
from there in the release notes having been seen by nobody — and the fold *removes* this document at the
merge, so the place a reviewer would compare the two is the one place it no longer is. The same shape as the
scaffold gate's own measurement, one document further along.

**The PR is the recorded copy, so the lock stores nothing.** Three mechanisms were weighed and Dave chose this
one: compare against the open PR. A fingerprint stamped into the document would add an artefact to the file
the fold consumes and have to be stripped again on the way out; a silent re-sync at merge time refuses nothing
and is therefore not a lock. `open-pr` already publishes the section, and reading it back *is* the comparison.

**It is checkable at all only because the section now travels verbatim.** Until the same issue,
`Get-PrDescription` dropped the `### DEPLOY:` heading and promoted every remaining one — so body and document
were two *renderings* of one section, and a comparison would have had to reproduce that transform to make
sense. The heading travels now, which reverses the August 9, 2026 promotion **on today's shape only**; the
legacy path keeps promoting, because there the H2 genuinely stays behind. The reasoning sits at both branches
in `pr-body-lib.ps1`. **An unreadable body is not a finding** — `gh` failing says something about the token or
the network, not about the section, and a gate that refused on that would be refusing on no evidence.

#### 2.2.4. the CI gate, because the three above are local

**August 20, 2026** (inbound
[#789](https://github.com/DaveKJohn/claude-code-specialists/issues/789)). The three gates above live in
`open-pr` and `ship-pr`, so all three are escapable by not using them: a branch pushed by hand, or a PR opened
in the GitHub UI, meets none of them. The convention was therefore enforced by whoever remembered the
scripts — and a convention that enforces nothing rots quietly, which matters here because `CHANGELOG.md` is
the only readable answer to "what is merged but not yet released".

[`check-branch-entry.ps1`](../scripts/lint/check-branch-entry.ps1) closes that, and
[`.github/workflows/branch-entry.yml`](../.github/workflows/branch-entry.yml) is the handful of lines that call
it on every PR. **It adds no rule of its own** — it calls the same `Test-BranchChangelogIsFilled` and
`Get-EntryScaffoldFindings` that `open-pr` calls, and, given the PR number, the same `Test-DeployLock` that
`ship-pr` calls. So there is one definition of "written" in the system and one of "diverged", rather than a
second pair in CI. **Reading a PR body is why the workflow carries read access to pull requests** — the entry
checks themselves need no token, no network and no PR, so the lock is opt-in by parameter and the gate stays
runnable on a branch that has none.

**Two consumers had already written this gate by hand, and both had drifted from the convention** — that is
the measurement behind shipping it rather than documenting it. Each refuses a merge over a missing significance
score, justified in one of them by *"tier 0 can never legitimately stay empty"*, while
`entry-scaffold-lib.ps1` reads **TIER 0 OWES NOTHING** and Dave placed that refusal at the release cut on
August 5, 2026, precisely so an author who has not settled a score is not blocked from merging over it. So the
shipped gate **reports** the significance and names the cut as where the refusal lives. It is simpler than the
hand-written version, not more complex: `Get-EntryScaffoldFindings` already catches the case those gates
reached for the score to catch — a freshly scaffolded entry, which carries an H2 and a title and so passes any
heading test.

**Its own workflow file, not a job in `ci.yml`**, and the trigger is the reason: `ci.yml` also runs on a push
to `main`, where there is no branch document at all. A job there would be red on the trunk after every merge.
The script answers the trunk case gracefully as well, but a gate should not need that grace to be pointed
correctly. **It is not in the `main` ruleset** — making a check required is a repo-settings change and
therefore Dave's, so today it reports on every PR and blocks nothing.

### 2.3. Check whether another PR is already merging

**One merge at a time, and a PR that arrives second waits its turn** (Dave,
[#912](https://github.com/DaveKJohn/claude-code-specialists/issues/912), August 26, 2026). Before the merge,
look at what else is open and green: `gh pr list --base main --state open`. If nothing else is on its way in,
this step costs one command and you move on.

**No gate enforces this, so it is on you.** Nothing in `open-pr.ps1` or `ship-pr.ps1` looks at the other open
PRs, and GitHub is happy to merge two at once — the same shape as the four-headings rule in the branch
document, and stated here for the same reason: a convention nobody writes down is a convention nobody keeps.

#### 2.3.1. Nothing else merging — go to 2.4

The normal case. The queue exists for the moment two pieces of work finish together, not as a step every
branch performs.

#### 2.3.2. Something else is merging — this PR joins the QUEUE and waits

**Two PRs cannot merge at the same time, and `CHANGELOG.md` is why.** Every branch's fold writes into the
same file at the same place — the top of `## [Unreleased]`, newest to oldest — and it writes there *after*
the merge, on `main`. Two folds racing each other break in the gap between the merge and the fold, which is
the state nothing reports: the PR is already merged, the entry has not landed, and every gate stays green
until a release trips over it.

**Two ways it breaks, and the second is worse than the first.** The later run's fold push is rejected as
non-fast-forward, so the entry sits unpushed on a local `main`; or `ship-pr.ps1` step 5 aborts on
`git merge --ff-only origin/main` before the fold runs at all, leaving the merge done and the entry still in
the branch document. Both are recoverable and neither announces itself. Waiting is cheaper than either.

**Waiting is the whole mechanism — there is no queue file and no lock.** The PR stays open and green; the
merge is simply not performed yet. A branch that waits costs nothing, because the DEPLOY lock
([2.2.3](#223-the-deploy-lock-on-the-section-the-pr-published)) has already fixed what this PR publishes:
time passing does not change it.

#### 2.3.3. The queue ahead has drained — sync with `main`, then merge

**Bring the branch up to date with `main` before merging it.** The PRs ahead have each folded an entry onto
the trunk, so `main` carries `CHANGELOG.md` content this branch has never seen. Fetch and merge `origin/main`
into the branch, and let CI run once more against the result.

**What that buys is hygiene, not ordering — and the distinction matters.** The fold always inserts at the top
of `## [Unreleased]` on whatever `main` it is standing on, so the order entries end up in follows the order
the PRs *merged*, not how fresh either branch was. Syncing a stale branch does not move its entry up. **The
queue is the thing that keeps the order**; this step keeps the branch from merging a tree it was never tested
against.

**And `ship-pr.ps1` step 5 is not this step.** It checks out `main`, fetches, and ff-merges `origin/main`
before folding — so the fold itself is never performed against a stale trunk. What it does not do is bring
the *branch* forward, which is what this step is.

### 2.4. Merge the PR

**The merge does not wait, with two exceptions.** The portable half leaves this to each repo, because it is a
governance decision rather than a configuration value. Here, a finished branch **opens, merges and folds in one
motion without waiting for Dave**. The lint gate, the test gate and CI prove this class of change is sound, and
anything that does turn out wrong is one revert PR away.

Two kinds of change stop and wait for his word: work with a **visible result** that has to be judged by eye,
and work that is **irreversible or outward-facing** (a release, a version bump, a tag, repo settings, or
publishing beyond the normal PR flow). The full statement is in
[the safety rules](../CLAUDE.md#never-directly-on-the-main-branch--via-branch--pr).

**The merge waits on one CI check and only one.** Both gates run as CI in
[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) — on every PR and every push to `main` — under the
job id **`lint-en-tests`**, which is the exact name the `main` ruleset requires as a passing status check. A
merge attempted before it goes green returns `BLOCKED`. That job id is deliberately not English, and renaming
it would silently break the ruleset binding — every future PR would sit unmergeable, waiting on a check that no
longer exists. See [`.claude/rules/language-layers.md`](../.claude/rules/language-layers.md).

**A second check appears on every PR and does not block.**
[`.github/workflows/claude-code-review.yml`](../.github/workflows/claude-code-review.yml) runs an automated
review over the diff and posts inline comments, under the job id `claude-review`. It is advisory: the ruleset
names `lint-en-tests` and nothing else, so a red `claude-review` is a finding to read rather than a merge
blocker. On a pull request from a fork it fails by construction — GitHub withholds secrets from fork-triggered
workflows, which is the safe outcome and not a defect to work around.

Merge method: **`merge`** — a merge commit, not a squash (`Get-PrMergeMethod`).

### 2.5. Copy the last DEPLOY into `CHANGELOG.md` under `## [Unreleased]`, newest to oldest

### 2.6. Delete `development-cycle.md`

**2.5 and 2.6 are one command, and the first direct-on-`main` exception.**
[`fold-changelog-entry.ps1`](../scripts/release/fold-changelog-entry.ps1) folds the entry into `CHANGELOG.md`
and clears it, and on request makes that commit itself — **bounded to `CHANGELOG.md` plus
`development-cycle.md`**, which the same run removes. Since August 2, 2026 that bound is enforced rather than
merely intended: the commit names its paths, so nothing else in the tree can ride along. Committing stays
opt-in, because it is this exception being used.

**The scope grew by one path on August 6, 2026 and the exception did not widen with it**: the step list is
cleared by this run, so leaving it out would produce a commit that clears half the pair — the entry gone from
`main` while the step list still shows the merged branch's ticked boxes. That argument now only reaches a branch
cut before the two files merged, since one document is cleared in one move. See
[Rendall #06](../.claude/specialists/lenses/05-06-extension.md#changelog).

The pending entries, ranked furthest-reach-first, are in [`CHANGELOG.md`](../CHANGELOG.md).

---

## 3. CUT RELEASE

A release here is **repo-wide and in lockstep**, which works because this repository holds *one* product whose
plugins are one system — see [One product, one repository](../README.md#one-product-one-repository). A second,
unrelated product would get its own repository and marketplace rather than joining this release train.

**A release only ever happens on Dave's explicit request.** It is the irreversible, outward-facing class from
step 2.4. Once asked for, the closing steps of that same checklist are covered by the request — including
publishing the GitHub Release. Step 4 below is the one part that is **not**.

**The step numbers below match [#894](https://github.com/DaveKJohn/claude-code-specialists/issues/894)
exactly, and they did not before.** That issue used to ask for a step creating *three* kinds of release note
under one root — `releases/changelog/`, `releases/github/` and `releases/audience/` inside this folder — where
`releases/development/` and `releases/github/` sit at the repo root and only `audience` sits here. Its
August 26, 2026 edit dropped that step, so section 3 is seven steps on both sides and nothing is pending
between them.

**The subject itself did not go away with it.** The rename (`development` -> `changelog`) and the relocation
of two roots is a real open question about the release-note layout; it is simply no longer part of #894, and
it now stands on its own in
[#914](https://github.com/DaveKJohn/claude-code-specialists/issues/914).

### 3.1. The bump: tier 0 only is a PATCH, anything higher is a MINOR

This repo runs the shared floor unchanged. The portable half asks each repo to say so out loud where its own
rule is stricter than the gate's, because a contributor otherwise picks their bump type from the wrong rule.
**Here there is no stricter rule:** tier 0 only is a patch, tier 1 or higher earns a minor, and a major
additionally needs ten minors in the current major line. In code that is one line — the `EarnedBump` that
`Get-PendingRelease` computes in [`release-lib.ps1`](../scripts/lib/release-lib.ps1).

The audience of each release document follows the **tier**, not the bump, which is what keeps that looser rule
honest: a tier-1-only minor writes the internal note and no consumer document, so nobody outside is handed a
document about work they cannot see. Full model:
[the tier model](../plugins/workflows/contributing-davekjohn/RELEASES-portable.md#the-tier-model) and
[what a release must earn](../plugins/workflows/contributing-davekjohn/RELEASES-portable.md#what-a-release-must-earn).

### 3.2. Cut the `## [Unreleased]` section out of the changelog

### 3.3. Paste it into the development notes

### 3.4. Write the GitHub version

### 3.5. Publish it as a new tag

**3.2 through 3.5 are one command, and the second direct-on-`main` exception.**
[`cut-release.ps1`](../scripts/release/cut-release.ps1) bumps all plugin versions in lockstep, generates the
release notes, **empties `CHANGELOG.md` down to its intro**, commits that on `main`, and tags the version.
Deliberately no branch or PR — just like the fold. See
[Rendall #06](../.claude/specialists/lenses/05-06-extension.md#versioning--releases).

**Where those documents live in THIS repo**, since the step names and the tree do not line up by themselves:
the developer notes are `releases/development/<major>.x/<version>.md` and the GitHub notes
`releases/github/<major>.x/<version>.md`, both at the **repo root**. This repo is the workflow's *source*, and
`Test-IsWorkflowSourceRepo` deliberately keeps a source's root files at the root. A **consumer** gets the same
two trees inside their own `contributing-davekjohn/`, which is what the seams
`Get-ReleaseDevelopmentNotesRoot` and `Get-ReleaseGithubNotesRoot` answer per repo.

**A major needs two commits ahead of it, and they run under this same exception** (Dave, August 9, 2026).
`cut-release.ps1` refuses to file a new major's row under the previous major's section and does not open the
new section itself, and the live assert in
[`release-lib.tests.ps1`](../scripts/tests/release-lib.tests.ps1) pins which major
[`releases/README.md`](releases/README.md) targets — so cutting `v4.0.0` took `b2cea9c` (the `#### 4.x` heading
plus its empty table header) and `1d2d3ff` (that pin, with the reason written above it) before the cut would
run at all. Both were made by hand, on `main`, while the exception on paper covered only the release commit
itself.

**Neither half is automated, and that is the decision rather than a gap.** Opening the section by hand is the
milestone moment the script deliberately leaves to a person, and the assert is the same fact written a second
time on purpose — a script that repointed it would remove the tripwire that caught the half-done edit here.
**A major is not rare**: `v1.0.0` through `v4.0.0` fell on July 14, July 23, July 30 and August 9, 2026, one
every nine days or so.

**Why this exception exists in this shape, and every alternative that was weighed and declined, is in
[Rendall #06](../.claude/specialists/lenses/05-06-extension.md#the-release-craft-received-from-claudemd-august-15-2026)**
— the entry format, the tier model and its audience knob, the significance rubric, the release documents and
their writing norm, the bump rules, and the measurements behind each. It was moved off the always-on path on
August 15, 2026, where it was 41,168 B and 32% of everything loaded before a word of work. **Read it before
changing any rule above**: most of what looks arbitrary here was measured there.

### 3.6. Write the audience version

**This is the third direct-on-`main` exception.** The cut generates the development notes and the audience
**draft**, then names the documents it deliberately did not write. The internal note has its own script
([`new-internal-note.ps1`](../scripts/release/new-internal-note.ps1)), which needs the development notes as
input and so can only run *after* the cut. Both are hand-written, and since **August 23, 2026 (Dave)** both are
committed **straight onto `main`** in the commit after the tag — bounded to those documents and to a cut that
was actually asked for. In this repo the audience note lands under [`releases/audience/`](releases/audience/)
in this folder, which is what `Get-ReleaseNoteRoot` answers.

**This reverses the August 4, 2026 answer, and the reversal is worth reading with what it reverses.** That day
Dave was offered the wider version — the release exception covering "the release *and* its written notes" — and
declined it, on the reasoning that already carries the bounds on the root page: an exception is only safe while
it stays the size it was granted at, which is what had to be repaired in `ship-pr.ps1` two days earlier. **That
argument was not overturned; it is why the third exception arrives with its paths written out.** What changed is
the judgement about which size is right. A release is one procedure, and running it across two routes left the
trunk holding a tagged release whose own notes were still in review — visible in the artefact rather than only
in the process, because `CHANGELOG.md` is empty from the cut onward and the document that replaces it is
elsewhere.

**The measured instance behind the old route stays true and stays here**, because it is what a future reader
will reach for if the question reopens:
[PR #432](https://github.com/DaveKJohn/claude-code-specialists/pull/432) shipped the `v3.2.0` internal note
through a branch and PR, gates green and entry folded, with nothing about being post-tag causing friction. So
the PR route was never *failing* — it was working and split in two, which is a different complaint and the one
that decided it.

**What does not change with the route.** The tag still holds the *draft*: the cut commits and tags in one
motion, so the written version lands in the following commit either way. And the gates still run — being off a
branch skips `open-pr`, not the lint and the suites.

**The `releases/README.md` in this folder is the living index** — the cut inserts its own row, so never add one
by hand for a release a script will write. The list of releases actually cut is on
[this repo's own release page](../releases/README.md#the-release-list).

**Everything under `releases/audience/` is a published record**: links may be repointed when a target moves,
prose is never rewritten. **What that protects is a line that was TRUE when it was published** — going stale
afterwards is the record working. A line that was **false when it was written** is not protected by it, and
correcting one restores the record rather than breaking it; the rule, and how to mark the correction, is in
[`RELEASES-portable.md`](../plugins/workflows/contributing-davekjohn/RELEASES-portable.md#once-it-has-landed-it-is-a-published-record--and-that-protects-only-what-was-true).
**The worked example is one sentence carried across two adjacent notes**: the publication item in `4.10.0.md`
was true at its merge and overtaken an hour later — stale, deliberately untouched — while `4.11.0.md` inherited
it, updated the count without re-reading the target, and was therefore false on arrival and is corrected. That
is the failure to watch for here: **a stale line copied forward becomes a false line.**

### 3.7. Optional: wait for a `SHIP MAIN` or `PUSH LIVE` command

**Optional because it depends on one seam answer, and here that answer is no** (Dave,
[#894](https://github.com/DaveKJohn/claude-code-specialists/issues/894), August 26, 2026). Where
`Get-LiveStage` names a stage — a Shopify repo, where `main` still has to be pushed to a live theme before a
customer sees anything — the cut **stops here** and waits. Where it is empty, as it is in this repo, merging to
`main` already is publication and there is nothing to wait for.

**It sits at the end of step 3 rather than at the start of step 4, and the distinction is the point.** The
waiting is the last thing the *cut* does; what follows the command is step 4's single act. Putting the
condition inside step 4 read as though the cut had already finished, which is what this move corrects.

**That command is never covered by the request that authorised the cut.** A Release document describes a
version; a live push changes what customers see. Decision by Dave, August 5, 2026 — restated under 4.1, where
it bites.

---

## 4. SHIP MAIN / PUSH LIVE

### 4.1. Publish and distribute the audience release notes

**The waiting moved up to 3.7, and this step is what happens after it** (Dave,
[#894](https://github.com/DaveKJohn/claude-code-specialists/issues/894), August 26, 2026). It used to be two
steps here — wait for `main` to be live, *then* publish — which put the condition and the act in the same
section as though the cut had already ended. It has not: 3.7 is the last thing the cut does, and it is where
the checklist stops and waits for a `SHIP MAIN` or `PUSH LIVE` command. So this section is now the single act
that command releases.

The ordering argument below is unchanged and is the reason the two are separate steps at all rather than one.

**This step is a no-op in this repo, and that is an answer rather than an omission.** `Get-LiveStage` returns
empty here: there is no separate live stage between `main` and the audience. Merging to `main` *is* publication
— the marketplace is read from this repository, so the next `claude plugin marketplace update` a consumer runs
sees whatever the trunk holds.

**It is not a no-op in every repo that runs this workflow, which is why the step exists.** A consumer with a
live stage — a Shopify repo, where `main` still has to be pushed to a live theme before a customer sees
anything — answers `Get-LiveStage` with that stage, and then the order in step 4 is load-bearing: the audience
notes describe what the audience can see, so publishing them before the push describes something that is not
there yet.

**Where a repo does have a live stage, that push is its own class of action.** A Release document describes a
version; a live push changes what customers see. So it is **never** covered by the request that authorised the
cut — it needs Dave's word of its own, separately, however far the release checklist has already run. Decision
by Dave, August 5, 2026.

