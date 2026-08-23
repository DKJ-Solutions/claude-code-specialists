# Working in `workflow-davekjohn/`

This folder belongs to the `workflow-davekjohn` plugin's way of working, and **it is the layer on top
of the repo's own [`CLAUDE.md`](../CLAUDE.md)** — the same split
[`CONTRIBUTING.md`](CONTRIBUTING.md) already makes over the root
[`CONTRIBUTING.md`](../CONTRIBUTING.md), applied to the operating guide. The root page states what
holds in this repo whether or not the plugin is installed: never directly on `main`, branch + PR, CI
green, and the three direct-on-`main` exceptions together with their bounds. **This page carries the
workflow's own mechanics** — the gates it adds on top, how those three exceptions actually run, and the
measurements behind them. Where the two disagree, this page wins.

The split is worth what it costs for the reason the root page gives for the two moves before it: the
root loads on **every** session, this page loads only when a session touches this folder. A rule that
bites only while the workflow is in play does not belong on the always-on path.

## The files in this folder

- [`development-cycle.md`](development-cycle.md) belongs to the **current branch**. On the trunk it sits
  in its reset state, with the trunk's name in its heading — never write there until a branch exists
  (`new-branch` creates one and fills the document in).
- It has two halves and two readers. **PLAN / CREATE / TEST** carry the steps and gate the PR and the
  merge (`- [x]` done, `- [~]` dropped with the reason on the line). The fourth phase,
  **`` ## DEPLOY: `<branch>` ``**, IS the changelog entry: it folds **verbatim** into `CHANGELOG.md` at
  the merge. A checkbox inside that section is prose, and no gate reads it as a step.
- **Its links are written root-relative**, the whole document, because the DEPLOY section lands at the
  repo root. `scripts/x.ps1`, never `../scripts/x.ps1` — the second reads correctly here and is dead
  once it lands, and `open-pr`'s link gate refuses it.
- **The HTML comments are the form, not somebody's notes.** They say what a good answer looks like, and
  the fold strips them on the way to `CHANGELOG.md`, so leaving one standing is not a defect. There is
  no template beside the file any more; the trunk copy is the reference.
- **Re-read it after a script has touched it.** `new-branch` writes the document and the fold resets it,
  so it is the only file here rewritten out of band — twice per cycle — and an editor tracking what it
  last read refuses the next write until it has read again. One read fixes it, nothing is lost, and both
  scripts say so where they print the path. The portable statement, with the measurement, is in
  [`DEVELOPMENT-CYCLE-portable.md`](../plugins/workflows/workflow-davekjohn/DEVELOPMENT-CYCLE-portable.md#the-file-is-rewritten-under-you-twice-per-cycle).
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
- **There is no `branch/templates/` any more** (Dave, August 23, 2026). Two generated reference copies
  sat there because the working files were deliberately bare; the merged document carries its own
  guidance, so the reference and the file you write in are the same page. What the lint holds to the
  formatter instead is the document's **reset state** — the copy on the trunk, which is what a reader
  opens to see the whole form at once.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) here is the workflow's layer and **wins over the root
  [`CONTRIBUTING.md`](../CONTRIBUTING.md) on conflict**; the root page is the standard workflow that
  holds without the plugin.

## The three gates this workflow adds on top

The repo's own lint and test gates are stated in the [root `CLAUDE.md`](../CLAUDE.md) and run in CI
whether or not this plugin is installed. The three below arrive **with the workflow**, and all of them
read `development-cycle.md`. Two run locally, before the push and before the merge; the third runs in
CI, and it exists because the first two cannot.

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
`branch/` split moved the step list out of the entry, so the entry is no longer scaffolded with a
to-do heading over a to-do placeholder — its placeholder asks what the change *does*. The gate keeps
refusing the retired wording, and that is not politeness towards history: every branch in flight,
here and in every consumer, carries an entry with those strings right now, and consumers receive the
new scripts through a plugin update rather than by choosing to. A gate that forgot them would wave
exactly those entries through. **Recognise both, write one** — the same rule the `Tier: N` line gets.

### The step-list gate, on the branch's own plan

**Dave, August 6, 2026.** A branch reaches a PR when its own plan is finished, so `open-pr.ps1` refuses
to push and `ship-pr.ps1` refuses to merge while the step half of `development-cycle.md` has an
unresolved step.
**Both**, deliberately: the requirement Dave gave is about the *merge*, and `open-pr` has a `-Force` —
a PR opened through that valve, or by hand on github.com, would otherwise land with an unfinished plan.

**Three marks, not two.** `- [x]` is done, `- [~]` is dropped with the reason kept on the line, and a
step still carrying the scaffold's placeholder is refused whether or not it is ticked. The third mark
is what makes the gate safe to leave **un-`-Force`-able**: without it the only way past a step that
turned out not to be needed is to tick it, which teaches people to report work they did not do — a
gate that then says success is worse than no gate. **A branch with no step list at all is not
refused**: that is the one-commit typo fix, and refusing it would make the mechanism ceremony.

The full convention ships with the plugin as
[`DEVELOPMENT-CYCLE-portable.md`](../plugins/workflows/workflow-davekjohn/DEVELOPMENT-CYCLE-portable.md).
**This repo keeps no local half of it any more** (Dave, August 23, 2026): the page that held this repo's
answers was `branch/README.md`, and when the two files merged, its prose would have had to be reproduced
byte-for-byte by the scaffolder inside every branch's own document. Repo-specific prose generated by a
portable formatter cannot be right, so the answers moved to the pages that already own them, split by what
kind of answer they are: the **file rules** a session needs are in [the list above](#the-files-in-this-folder),
and the **seam answers** — the audience tier and what it makes of the entry's headings, the version suffix,
and which of the shape's rules this repo's lint enforces — are in
[`CONTRIBUTING.md`](CONTRIBUTING.md#the-development-cycle--what-this-repos-answers-make-of-it). Since
August 14, 2026 (Dave) the file itself sits inside `workflow-davekjohn/`, the workflow's own root folder —
the start of gathering everything portable in one place at a consumer instead of scattering it through
their root.

### The CI gate, because the two above are local

**August 20, 2026** (inbound
[#789](https://github.com/DaveKJohn/claude-code-specialists/issues/789)). Both gates above live in
`open-pr` and `ship-pr`, so both are escapable by not using them: a branch pushed by hand, or a PR opened
in the GitHub UI, meets neither. The convention was therefore enforced by whoever remembered the scripts —
and a convention that enforces nothing rots quietly, which matters here because `CHANGELOG.md` is the only
readable answer to "what is merged but not yet released".

[`check-branch-entry.ps1`](../scripts/lint/check-branch-entry.ps1) closes that, and
[`.github/workflows/branch-entry.yml`](../.github/workflows/branch-entry.yml) is the six lines that call
it on every PR. **It adds no rule of its own** — it calls the same `Test-BranchChangelogIsFilled` and
`Get-EntryScaffoldFindings` that `open-pr` calls, so there is one definition of "written" in the system
rather than a second one in CI.

**Two consumers had already written this gate by hand, and both had drifted from the convention** —
that is the measurement behind shipping it rather than documenting it. Each refuses a merge over a missing
significance score, justified in one of them by *"tier 0 can never legitimately stay empty"*, while
`entry-scaffold-lib.ps1` reads **TIER 0 OWES NOTHING** and Dave placed that refusal at the release cut on
August 5, 2026, precisely so an author who has not settled a score is not blocked from merging over it. So
the shipped gate **reports** the significance and names the cut as where the refusal lives. It is simpler
than the hand-written version, not more complex: `Get-EntryScaffoldFindings` already catches the case those
gates reached for the score to catch — a freshly scaffolded entry, which carries an H2 and a title and so
passes any heading test.

**Its own workflow file, not a job in `ci.yml`**, and the trigger is the reason: `ci.yml` also runs on
`push: branches: [main]`, where the entry sits in its reset state by design after every fold. A job there
would be red on the trunk after every merge. The script answers the trunk case gracefully as well, but a
gate should not need that grace to be pointed correctly.

**It is not in the `main` ruleset.** Making a check required is a repo-settings change and therefore
Dave's, so today it reports on every PR and blocks nothing.

## How the three direct-on-`main` exceptions actually run

The root page states **that** the three exceptions exist and **what bounds them**; that half is
governance and stays there, because a session has to know the bound whether or not it ever opens this
folder. What follows is the mechanics and the reasoning behind them.

### 1. The fold commit, after a merge

[`fold-changelog-entry.ps1`](../scripts/release/fold-changelog-entry.ps1) folds the entry into
`CHANGELOG.md` and clears it, and with `-Commit`/`-Push` makes that commit itself — scope limited to
`CHANGELOG.md` + `development-cycle.md`, which the same run resets, and since
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

### 3. The release-notes commit, after the tag

`cut-release.ps1` generates the development notes and the consumer **draft**, then names the
documents it deliberately did not write. The internal note has its own script
([`new-internal-note.ps1`](../scripts/release/new-internal-note.ps1)), which needs the development
notes as input and so can only run *after* the cut. Both are hand-written, and since
**August 23, 2026 (Dave)** both are committed **straight onto `main`** in the commit after the tag —
the third exception, bounded to those documents and to a cut that was actually asked for.

**This reverses the August 4, 2026 answer, and the reversal is worth reading with what it reverses.**
That day Dave was offered the wider version — the release exception covering "the release *and* its
written notes" — and declined it, on the reasoning that already carries the bounds on the root page:
an exception is only safe while it stays the size it was granted at, which is what had to be repaired
in `ship-pr.ps1` two days earlier. **That argument was not overturned; it is why the third exception
arrives with its paths written out.** What changed is the judgement about which size is right. A
release is one procedure, and running it across two routes left the trunk holding a tagged release
whose own notes were still in review — visible in the artefact rather than only in the process,
because `CHANGELOG.md` is empty from the cut onward and the document that replaces it is elsewhere.

**The measured instance behind the old route stays true and stays here**, because it is what a future
reader will reach for if the question reopens:
[PR #432](https://github.com/DaveKJohn/claude-code-specialists/pull/432) shipped `v3.2.0`'s internal
note through a branch + PR, gates green and entry folded, with nothing about being post-tag causing
friction. So the PR route was never *failing* — it was working and split in two, which is a different
complaint and the one that decided it.

**What does not change with the route.** The tag still holds the *draft*: the cut commits and tags in
one motion, so the written version lands in the following commit either way. And the gates still run —
being off a branch skips `open-pr`, not the lint and the suites.
