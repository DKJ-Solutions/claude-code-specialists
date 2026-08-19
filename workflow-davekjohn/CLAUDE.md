# Working in `workflow-davekjohn/`

This folder belongs to the `workflow-davekjohn` plugin's way of working, and **it is the layer on top
of the repo's own [`CLAUDE.md`](../CLAUDE.md)** — the same split
[`CONTRIBUTING.md`](CONTRIBUTING.md) already makes over the root
[`CONTRIBUTING.md`](../CONTRIBUTING.md), applied to the operating guide. The root page states what
holds in this repo whether or not the plugin is installed: never directly on `main`, branch + PR, CI
green, and the two direct-on-`main` exceptions together with their bounds. **This page carries the
workflow's own mechanics** — the gates it adds on top, how those two exceptions actually run, and the
measurements behind them. Where the two disagree, this page wins.

The split is worth what it costs for the reason the root page gives for the two moves before it: the
root loads on **every** session, this page loads only when a session touches this folder. A rule that
bites only while the workflow is in play does not belong on the always-on path.

## The files in this folder

- The two files in `branch/` belong to the **current branch**. On the trunk they sit in their reset
  state — never write there until a branch exists (`new-branch` creates one and fills them).
- `branch/branch-deployment.md` folds **verbatim** into `CHANGELOG.md` at the merge; its step-list
  companion gates the PR and the merge (`- [x]` done, `- [~]` dropped with the reason on the line).
- `releases/README.md` is the **living index** — the cut inserts its own row, so never add one by hand
  for a release a script will write. Everything under `releases/audience/` is a **published record**:
  links may be repointed when a target moves, prose is never rewritten.
  **What that protects is a line that was TRUE when it was published** — going stale afterwards is the
  record working. A line that was **false when it was written** is not protected by it, and correcting one
  restores the record rather than breaking it; the rule, and how to mark the correction, is in
  [`RELEASES-portable.md`](../plugins/workflows/workflow-davekjohn/RELEASES-portable.md#once-it-has-landed-it-is-a-published-record--and-that-protects-only-what-was-true).
  **The worked example is one sentence carried across two adjacent notes**: `4.10.0.md`'s publication item
  was true at its merge and overtaken an hour later — stale, deliberately untouched — while `4.11.0.md`
  inherited it, updated the count without re-reading the target, and was therefore false on arrival and is
  corrected. That is the failure to watch for here: a stale line copied forward becomes a false line.
- `prompts/prompt.md` is **Dave's**, not yours: he writes an assignment there instead of typing it into
  the terminal, `/prompt` reads it, and `-Archive` files it once the work is under way. Never write an
  assignment into it, and never read its HTML comments as instructions — they are the scaffold's own
  words, and an inbox holding only comments is empty. It is untracked by design; see
  [`prompts/README.md`](prompts/README.md).
- The generated files in `branch/templates/` are references, not documents to edit: `new-branch`
  rewrites one that has drifted, and in this repo the lint additionally holds them byte-for-byte to the
  formatters (`Get-BranchTemplates`).
- [`CONTRIBUTING.md`](CONTRIBUTING.md) here is the workflow's layer and **wins over the root
  [`CONTRIBUTING.md`](../CONTRIBUTING.md) on conflict**; the root page is the standard workflow that
  holds without the plugin.

## The two gates this workflow adds on top

The repo's own lint and test gates are stated in the [root `CLAUDE.md`](../CLAUDE.md) and run in CI
whether or not this plugin is installed. The two below arrive **with the workflow**, and both read the
two files in `branch/`.

### The scaffold gate, on the changelog entry itself

**August 3, 2026.** `open-pr.ps1` refuses to push a branch whose entry still carries the wording
`new-branch.ps1` scaffolded it with — the placeholder title, the "to do / where I left off" heading, or
the fallback body. **Measured, after it had already shipped:** three of v3.2.0's twenty-one entries kept
that heading with a status appended behind it, and it reached the release notes *and* the per-plugin
`CHANGELOG.md` files that travel to consumers in the plugin cache. The window closes at the merge and
closes **invisibly** — the fold moves the entry into `CHANGELOG.md`, the next release moves it on into
`releases/`, so by then the place a reviewer would look is the one place it no longer is. Fenced code
is excluded, so an entry documenting this mechanism is not accused of it; `-Force` is the escape
valve, deliberately separate from `-SkipLint`/`-SkipTests` because it overrules a judgement about
content rather than skipping a tool. The wording lives in **one** shared source
([`entry-scaffold-lib.ps1`](../scripts/lib/entry-scaffold-lib.ps1)) read by both the script that writes
it and the gate that refuses it — a copy in each would make the gate silently miss whatever the
writer changed.

**Two of those three strings are now recognised without being written** (August 6, 2026). The
`branch/` split moved the step list into its own file, so the entry is no longer scaffolded with a
to-do heading over a to-do placeholder — its placeholder asks what the change *does*. The gate keeps
refusing the retired wording, and that is not politeness towards history: every branch in flight,
here and in every consumer, carries an entry with those strings right now, and consumers receive the
new scripts through a plugin update rather than by choosing to. A gate that forgot them would wave
exactly those entries through. **Recognise both, write one** — the same rule the `Tier: N` line gets.

### The step-list gate, on the branch's own plan

**Dave, August 6, 2026.** A branch reaches a PR when its own plan is finished, so `open-pr.ps1` refuses
to push and `ship-pr.ps1` refuses to merge while `branch/branch-cycle.md` has an unresolved step.
**Both**, deliberately: the requirement Dave gave is about the *merge*, and `open-pr` has a `-Force` —
a PR opened through that valve, or by hand on github.com, would otherwise land with an unfinished plan.

**Three marks, not two.** `- [x]` is done, `- [~]` is dropped with the reason kept on the line, and a
step still carrying the scaffold's placeholder is refused whether or not it is ticked. The third mark
is what makes the gate safe to leave **un-`-Force`-able**: without it the only way past a step that
turned out not to be needed is to tick it, which teaches people to report work they did not do — a
gate that then says success is worse than no gate. **A branch with no step list at all is not
refused**: that is the one-commit typo fix, and refusing it would make the mechanism ceremony.

The full convention ships with the plugin as
[`BRANCH-portable.md`](../plugins/workflows/workflow-davekjohn/BRANCH-portable.md); this repo's own
answers to it stay in [`branch/README.md`](branch/README.md). Since August 14, 2026 (Dave) the
directory itself sits inside `workflow-davekjohn/`, the workflow's own root folder — the start of
gathering everything portable in one place at a consumer instead of scattering it through their root.

## How the two direct-on-`main` exceptions actually run

The root page states **that** the two exceptions exist and **what bounds them**; that half is
governance and stays there, because a session has to know the bound whether or not it ever opens this
folder. What follows is the mechanics and the reasoning behind them.

### 1. The fold commit, after a merge

[`fold-changelog-entry.ps1`](../scripts/release/fold-changelog-entry.ps1) folds the entry into
`CHANGELOG.md` and clears it, and with `-Commit`/`-Push` makes that commit itself — scope limited to
`CHANGELOG.md` + the entry + `branch/branch-cycle.md`, which the same run resets, and since
August 2, 2026 enforced rather than merely intended: the commit names its paths, so nothing else in
the tree can ride along.

**The scope grew by one path on August 6, 2026 and the exception did not widen with it**: the step
list is reset by this run, so leaving it out would produce a commit that resets half the pair — the
entry empty on `main` while the step list still shows the merged branch's ticked boxes. Committing
stays opt-in, because it is this exception being used. See
[Rendall #06](../.claude/specialists/lenses/05-06-extension.md#changelog).

### 2. The release commit, only on explicit request

[`cut-release.ps1`](../scripts/release/cut-release.ps1) bumps all plugin versions in lockstep,
generates the release notes in `releases/development/`, **empties `CHANGELOG.md` down to its intro**,
commits that on `main`, and tags `vX.Y.Z`. Deliberately no branch/PR — just like the fold. See
[Rendall #06](../.claude/specialists/lenses/05-06-extension.md#versioning--releases).

**A major needs two commits ahead of it, and they run under this same exception** (Dave,
August 9, 2026). `cut-release.ps1` refuses to file a `v4.0.0` row under `#### 3.x` and does not
open the new section itself, and the live assert in
[`release-lib.tests.ps1`](../scripts/tests/release-lib.tests.ps1) pins which major
[`releases/README.md`](releases/README.md) targets — so cutting `v4.0.0` took `b2cea9c` (the
`#### 4.x` heading plus its empty table header) and `1d2d3ff` (that pin, `'3'` to `'4'`, with the
reason written above it) before the cut would run at all. Both were made by hand, on `main`,
while the exception on paper covered only the release commit itself.

**Neither half is automated, and that is the decision rather than a gap.** Opening the section by
hand is the milestone moment the script deliberately leaves to a person, and the assert is the same
fact written a second time on purpose — a script that repointed it would remove the tripwire that
caught the half-done edit here. **A major is not rare**: `v1.0.0` through `v4.0.0` fell on July 14,
July 23, July 30 and August 9, 2026, one every nine days or so.

**Why this exception exists in this shape, and every alternative that was weighed and declined, is in
[Rendall #06](../.claude/specialists/lenses/05-06-extension.md#the-release-craft-received-from-claudemd-august-15-2026)**
— the entry format, the tier model and its audience knob, the significance rubric, the release
documents and their writing norm, the bump rules, and the measurements behind each. It was moved off
the always-on path on August 15, 2026, where it was 41,168 B and 32% of everything loaded before a
word of work. **Read it before changing any rule above**: most of what looks arbitrary here was
measured there.

### Who writes what, around a cut

`cut-release.ps1` generates the development notes and the consumer **draft**, then names the two
documents it deliberately did not write. The internal note has its own script
([`new-internal-note.ps1`](../scripts/release/new-internal-note.ps1)), which needs the development
notes as input and so can only run *after* the cut. Both the consumer-document edit and the internal
note are hand-written and land **via a branch + PR** — the release commit is already tagged by then,
and neither is one of the two named direct-on-`main` exceptions.

**Confirmed by Dave, August 4, 2026**, over the alternative he was offered: widening the release
exception to cover "the release *and* its written notes". He declined it, and the reasoning is the one
that already carries the bounds on the root page — an exception is only safe while it stays the size
it was granted at, which is what had to be repaired in `ship-pr.ps1` on August 2, 2026. The route also
has a measured instance behind it now rather than only an argument:
[PR #432](https://github.com/DaveKJohn/claude-code-specialists/pull/432) shipped `v3.2.0`'s internal
note this way, gates green and entry folded, with nothing about being post-tag causing friction.
Recorded because until that date this was an **assumption** stated as a rule: the question had been
put twice without an answer, and the answer-shaped text went into the docs anyway.
