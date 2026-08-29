---
name: open-pr
description: >-
  Push the current branch and open a Pull Request to main via the shared, centralized
  open-pr script from the plugin (single source of truth, issue #81) -- so a consumer does not have
  to duplicate this script locally. Runs the repo's own lint and test gate first; on an error,
  nothing is pushed and no PR is opened. Also forces the issue-closing decision: a branch that
  mentions an open issue must pass -Resolves or -NoResolves, so a repaired issue cannot stay open
  after the merge. And it refuses a changelog entry that still carries its scaffold wording, which
  would otherwise become permanent in the release notes and the consumer-facing plugin CHANGELOGs.
  Use this when a branch is ready and the repo's governance rule allows the PR to be opened.
disable-model-invocation: true
---

# open-pr — the shared PR opener for consumers

This is the **plugin mirror** of `open-pr.ps1`: the same tested source as in the source repo,
shared here so consumers do not duplicate it. Background in
[issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81).

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/open-pr.ps1"
```

**In the source repo, run its own copy instead — `scripts/release/open-pr.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own, so
for them the line above is the correct one.

**No title is passed, and that is the change of August 7, 2026 ([#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506)
+ [#505](https://github.com/DaveKJohn/claude-code-specialists/issues/505)).** The PR is called
`<branch type>: <the entry's Branch title>` — the type off the branch prefix, the words out of
the DEPLOY section of `contributing-davekjohn/development.md`. So the sentence is written **once**, when the branch is created
(`new-branch -Title`), and the PR, `CHANGELOG.md` and the release documents cannot disagree about what the
change is called. It also cannot lose its type prefix, which the five PRs before this change all had.

`-Title` is still **accepted and ignored** — passing one prints a warning naming the title the entry
actually gives. It was kept rather than removed because every branch in flight, here and in every
consumer, calls this script with `-Title` right now, and consumers receive the new script through a plugin
update rather than by choosing to; a removed parameter would turn all of those into a hard
"A parameter cannot be found" at the end of a finished branch. An **override** was the alternative and was
declined: an override is a second source of the title, which is the thing this change removes.

**A PR is never created nameless.** If the entry's title section is empty, the script stops and says so —
the emptiness gate normally catches that earlier, but `-Force` can wave that gate through, and an empty
title would otherwise reach `gh` as a complaint about a flag rather than about the entry.

The script:

1. Asks `gh` whether this branch **already has an open PR**, once, because two later steps need the
   answer. See [Resuming a branch whose PR is already open](#resuming-a-branch-whose-pr-is-already-open)
   below. A failed query is treated as "no existing PR" rather than as a blocker.
2. Runs the **resolves gate**, before the slow gates and before anything has left the machine. See
   [The resolves gate](#the-resolves-gate-which-issues-does-this-pr-close) below.
3. Runs the **scaffold gate**: the branch's changelog entry must no longer carry the wording
   `new-branch.ps1` scaffolded it with. See
   [The scaffold gate](#the-scaffold-gate-has-the-entry-actually-been-written) below. On the same read of
   the same file it also runs the **impact gate** and prints the reach and significance it read. See
   [The impact gate](#the-impact-gate-how-far-does-this-change-reach-and-how-much-does-it-weigh) below.
   And the **link gate**: a relative link in the entry must resolve from the **repo root**, because that
   is where the entry's text lands. See
   [The link gate](#the-link-gate-do-the-entrys-links-survive-the-fold) below.
   Then the **step-list gate**: the branch's own plan must be finished. See
   [The step-list gate](#the-step-list-gate-is-the-branchs-own-plan-finished) below.
4. Runs the **repo's own lint gate** (via `Get-LintScript` from `repo-config`) and then **all
   test suites** (`scripts/tests/*.tests.ps1`) -- exactly like CI. An error blocks: nothing is
   pushed and no PR is opened. `-SkipLint` / `-SkipTests` are the deliberate escape valves.
5. Pushes the current branch and opens a PR to `main` via `gh`, with a label based on the
   branch prefix and a pre-filled PR body from `.github/pull_request_template.md` +
   the changelog entry file. If the branch already had an open PR, the push **is** the update and
   the create is skipped.

## A branch whose PR is already MERGED stops the run, and that is good news

**The lookup above asks for an *open* PR, and until [inbound
#1077](https://github.com/DaveKJohn/claude-code-specialists/issues/1077) that was the only question
asked.** For a branch whose PR has been *merged* it answers "none", so the script took the create path
and GitHub refused it — and what the reader saw was a PowerShell error naming `gh` authentication, on a
branch that was in fact completely finished. `gh` had just listed PRs, pushed and read the issue list in
the same run: the one hypothesis offered was the one thing that was demonstrably fine.

So a merged PR is now its own outcome, asked for as a fallback when the open lookup finds nothing:

```text
PR #9 for 'docs/audience-note-v1' is already merged -- nothing to open. https://github.com/.../pull/9
A follow-up cycle on the same subject gets its own branch: new-branch completes the name with -v2.
```

It exits **0** — nothing failed — and it stops **before** the gates, the push and the create, because
there is nothing to lint, push or open for work that has landed. The state is not exotic: a second
session, a hand-merge on github.com, or simply re-running `ship-pr` all produce it, and the local branch
survives a merge because `--delete-branch-on-merge` removes the remote one only.

**And where a create does still fail, the message is gh's own.** The old line replaced it with a fixed
`(is gh logged in?)` guess; that hint is kept only for the one case it is the best available answer — a
`gh` that printed nothing at all.

## Resuming a branch whose PR is already open

**Running this on a branch that already has an open PR is a normal, supported case** — it runs the
gates against the new commits, pushes them, and exits 0 with the PR number. Only the `gh pr create` is
skipped, because a push is what updates an existing PR.

That matters most for [`ship-pr`](../ship-pr/SKILL.md), which calls this script as its step 1. Until
August 4, 2026 the create was unconditional: a duplicate made `gh` return non-zero, step 1 failed, and
**steps 2-6 — the CI watch, the merge, the fold, and the issue verification — never ran.** A branch
whose PR had been opened in an earlier session therefore had to be merged and folded by hand, which is
the five-step sequence `ship-pr` exists to remove. Measured on
[PR #457](https://github.com/DaveKJohn/claude-code-specialists/pull/457).

**Title and body are left alone by default.** The body may have been edited on github.com since it was
opened, and overwriting someone's edits with a freshly generated template loses more than a stale title
costs — the title is at least visible on the PR. Use `gh pr edit` if you want the title changed. Since
[#506](https://github.com/DaveKJohn/claude-code-specialists/issues/506) that holds for every PR rather
than only a resumed one: the title is composed once, at creation, and no later run rewrites it. Rewriting
a rewritten entry's title into an open PR was weighed and left out — a title is what people refer to a PR
by, and quietly renaming one mid-review is the same class of surprise as overwriting the body.

**`-RefreshBody` rewrites the description from the entry, and only the description.** Pass it when you
extended the changelog entry after the PR was opened — routine on a branch that keeps growing, and
otherwise the PR keeps describing an earlier version of the work while the merged changelog gets the new
one. The `## Resolved issues` block, anything a reviewer added, and any section your template carries that
the script did not write — "Type of change" boxes, a checklist — all stay exactly as they are.

**Which heading carries the description is read from your template's first heading line, at any level**,
so renaming it needs no configuration. One wrinkle worth knowing if you do rename it: a PR opened *before* the rename
still holds the old heading in its published body. The script therefore falls back to the headings it has
shipped before (`## What does this change do?` and its Dutch predecessor) when the current one is not
found, so an older PR stays refreshable instead of silently reporting that it already matches.

It is **opt-in** rather than automatic for the reason above: refreshing on every run would overwrite a
hand-edited body without being asked. And it is a no-op where there is nothing to do — no open PR, no
description in the entry, or a body that already matches, in which case nothing is sent to GitHub at all.

The heading it replaces under is the **first heading of your PR template, at any level** (`#` through
`######`), so no extra configuration is needed: that is where the description placeholder sits. If your
template has no heading at all, the switch warns and changes nothing rather than guessing. It matched
`## ` exactly until August 9, 2026, which meant a template promoted to `#` silently lost the whole
feature — worth knowing if your own template starts at a different level than it used to.

## Your PR template — the two promises this script relies on

`.github/pull_request_template.md` is **your** file: GitHub reads it only from that path in your own
repo, so unlike the rest of this workflow it cannot live in the plugin and cannot be `@`-imported. What
the plugin ships instead is a **reference to copy and to diff against**:

```text
${CLAUDE_PLUGIN_ROOT}/templates/pull_request_template.md
```

Everything `open-pr` needs from that file is two lines, and they are the whole interface:

| the promise | what depends on it |
|---|---|
| a **first heading**, at any level | `-RefreshBody` replaces the description under it |
| a **placeholder line** the matcher recognises, verbatim | the description is inserted there when the PR is created |

Break either and nothing errors — you get a PR whose body has no description, or a `-RefreshBody` that
politely reports it changed nothing. Everything else in the file is yours: add sections, checklists and
headings freely, and the script leaves them exactly as they are.

**Why the reference is only two lines — read the reasoning, not the answer.** This family's template
carried a "Type of change" block and a six-item checklist until August 9, 2026, and they were removed
after a measurement rather than on taste: over 60 PRs, "Type of change" had exactly one of four boxes
ticked *every single time* — a fact the changelog entry already states under `### Branch type`, and which
the GitHub label takes from `Get-BranchInfo` rather than from the tick — while two checklist items were
ticked 60/60 by the script itself and two were ticked 0/60 by anyone, ever, though both were already
enforced by gates that block the PR. A box that is always ticked and a box that is never ticked carry the
same information. The rule that survives is **"keep what is neither restated by the entry nor proven by a
gate"**, and in that repo nothing survived it.

**In yours something may.** The consumer who reported this ran the same measurement over their own 60
PRs and found one box of eight that genuinely varied: a preview-URL approval, on a repo whose result has
to be judged by eye and which no gate can prove. They kept it, correctly, and dropped the other seven. So
run the measurement on your own history — the method travels, the answer does not.

**No `## Specific to this repo` slot is pre-written**, unlike `CONTRIBUTING-portable.md`. The difference
is what the file is: a contributing guide is read once, while every heading in a PR template is repeated
in every PR body forever, so an empty slot would be a permanent empty section in your PR list. Add one
when you have something to put in it.

**If your template's placeholder LINE differs, define `Get-PrDescriptionPlaceholder`.** The description
is inserted by an exact whole-line match against three built-in strings, so a template one word away
from one of them gets a PR body with no description at all. Since
[#573](https://github.com/DaveKJohn/claude-code-specialists/issues/573) a run that matched no
placeholder **warns** and prints the strings it compared against — before that it was silent, and a
consumer merged 12 of 60 PRs with an empty description before anyone noticed. Your own line is the
answer: return it from `Get-PrDescriptionPlaceholder` in `scripts/repo-config.ps1`, or make the template
carry one of the built-in strings verbatim. `check-script-contract.ps1` cannot catch this for you — the
function is optional, so a repo that does not define it is correct.

**The one exception appends rather than replaces: a `-Resolves` the existing body does not carry yet.**
Dropping it would be the whole point of the resolves gate failing from the other side — GitHub closes
what the body says *at merge time*, so the issue would stay open, and `ship-pr`'s step 6 reads that
same body back and would confirm the same silence. The `Closes #<n>` line is appended (idempotent per
issue, so nothing is duplicated). If that append fails the script **stops with exit 1**: the branch is
pushed by then, and merging it would publish the loss.

An existing body that already says `Closes #332` also satisfies the resolves gate on its own, so you do
not have to repeat a decision that is already published on the PR.

## The scaffold gate: has the entry actually been written?

`new-branch` creates a changelog entry as a **scaffold** — a placeholder title, a
`**To do / where I left off:**` heading and a prompting body — for whoever finishes the branch to
replace. This gate refuses to push while that wording is still there.

**It is not a hypothetical.** In the source repo, three of one release's twenty-one entries kept that
heading with a status appended behind it (`**To do / where I left off:** done -- lint gate green`). A
progress note: correct on the branch, wrong the moment it is published. It reached the release notes
*and* the per-plugin `CHANGELOG.md` files that travel to consumers in the plugin cache.

**The window closes at the merge, and it closes invisibly.** The fold moves the entry into
`CHANGELOG.md`; the next release moves it on into `releases/` and empties the Pull-Requests section. So
by the time anyone would review it, the place they would look is the one place it no longer is.

The wording is **repo-owned** — whatever `Get-EntryTitlePlaceholder`, `Get-EntryBodyHeading` and
`Get-EntryBodyPlaceholder` say in your `scripts/repo-config.ps1`, or the English defaults. The gate and
the script that writes the scaffold read it from the same shared library, so they cannot disagree.

- **Fenced code is excluded**, so an entry that documents this mechanism is not accused of it.
- **`-Force` ships anyway** (a warning instead of a block), for the rare entry that legitimately quotes
  the wording outside a fence. Deliberately separate from `-SkipLint`/`-SkipTests`: those skip a tool,
  this overrules a judgement about content.

## The link gate: do the entry's links survive the fold?

The entry is the DEPLOY section of `contributing-davekjohn/development.md`, and the fold copies its text
**verbatim** into your `CHANGELOG.md`. So a relative link in it has to resolve from **that file's directory**,
which is not necessarily the one you are typing in — and where the two differ, the correct link looks wrong
until it moves.

**The base is your `Get-ChangelogPath`, read the same way the fold reads it.** Left unset, a repo that
publishes no plugin marketplace gets `contributing-davekjohn/CHANGELOG.md` — the same directory as the
document — so there the link that already reads correctly in front of you is the correct one. The source repo
keeps its changelog at the root, and there it is the other way round:

```markdown
See [the lib](scripts/lib/release-lib.ps1).       <- correct where the changelog is at the ROOT
See [the lib](../scripts/lib/release-lib.ps1).    <- correct where it sits BESIDE the document
```

This gate refuses to push while a relative link in the entry does not resolve at that destination, and it
prints **the form the destination needs** rather than only the dead one. That second half is the point: a
finding that says only *"does not exist"* sends the author to add another `../`, which breaks a link that was
right.

**It tries two bases for that suggestion** — the document's own directory first, then the repo root. The
second exists for the author who followed the older wording: a root-relative link, correct everywhere until
the changelog isolated, would otherwise be the one finding with no way out named (inbound
[#967](https://github.com/DaveKJohn/claude-code-specialists/issues/967)).

**And the refusal names the two directories it actually compared**, rather than restating the convention.
Until #967 it named the repo root and `contributing-davekjohn/branch/`, and on the shipped defaults neither
was in play: the first was the seam's old default, and the second was where the entry sat before it became a
section of the cycle document.

- **Only relative targets are judged.** `http(s):`, `mailto:`, a pure `#anchor` and an absolute `/path`
  are not resolved against a directory, so the move cannot break them.
- **Code and comments are excluded** — fenced blocks, inline backticks and HTML comments alike. Measured
  on the source repo's own entry file: across its last 80 revisions a scan without the *inline* exclusion
  produces exactly one finding, and it is false — `` `[PR #N](url)` `` in an entry explaining what the
  fold writes.
- **The anchor is dropped**, so `file.md#section` is judged as `file.md`. Whether the heading exists is a
  different question, and your own linter is the one that answers it.
- **Not `-Force`-able**, like the impact gate: `-Force` exists for text somebody legitimately wrote, and
  there is no legitimate dead link. The fix the message spells out is a one-line edit.
- **Refused here and not at the fold**, which is where inbound
  [#806](https://github.com/DaveKJohn/claude-code-specialists/issues/806) asked for it. A defect decidable
  before the merge is caught while the branch is still the only thing affected; refusing an
  already-merged branch's fold would leave an unfolded entry on the trunk with `main` looking finished. A
  fold-time *rewrite* is declined for a second reason — the fold copies the entry verbatim on purpose, and
  an author whose link is silently corrected writes the same link again into the next document, where
  nothing corrects it.

The convention is also stated in the guidance comment above the section you type the body into, so it
arrives before the gate does -- in the document itself since August 23, 2026, where it used to live in a
reference copy one directory away.

## The step-list gate: is the branch's own plan finished?

A branch carries one document with two halves. The DEPLOY section says what the change does; the PLAN,
CREATE and TEST phases above it say what still has to happen. **A branch reaches a PR when its own plan is
finished**, so this gate refuses to push while any step is unresolved -- counting only above the DEPLOY
heading, because a checkbox inside an entry's prose is prose. Three marks:

```text
- [ ] not done yet          -> blocks the PR
- [x] done
- [~] dropped -- <why it turned out not to be needed>
```

**The third mark is the reason the gate is safe to make unforceable.** A plan legitimately grows items
that stop making sense. A gate offering only "tick it" teaches people to tick boxes for work they did
not do — and then reports success, which is worse than no gate at all. A dropped step keeps its line and
its reason on the page, which is the half worth reading later.
- **A step still carrying the scaffold's placeholder is refused, ticked or not.** Ticking the
  scaffolded first step without replacing it reports a plan as finished that was never written — the
  same shape the scaffold gate above was measured on, one file over. **No mark resolves this one**, and
  the refusal now says so on the finding's own line: the fix is to replace the placeholder text with the
  step you actually took, or to delete the line if the plan grew past it. Both findings printed the same
  advice until [inbound #1081](https://github.com/DaveKJohn/claude-code-specialists/issues/1081), which
  was measured on a virgin repo as a loop — the author followed the marks it offered, was refused again
  by the same gate, and read "there is no `-Force` for this gate" as *you are stuck* rather than as
  *you have used the wrong tool for this finding*.
- **No step list at all is not a finding.** A branch created by hand rather than by `new-branch` has no
  document at all, and so no steps. That is the one-commit typo fix; refusing it would
  make the mechanism ceremony rather than a tool.
- **Fenced code is excluded**, so a step list that quotes the convention is not accused of following it.
- **There is no `-Force`**, deliberately, unlike the scaffold gate. `-Force` exists for text somebody
  legitimately wrote and wants to keep; here `- [~]` already is the sanctioned way past a step that
  should not be done, and a second escape valve would only ever be used to skip the first. That reasoning
  covers an *open* step; a scaffolded one is not stuck behind a missing escape valve either, it simply
  needs its text rewritten rather than marked.

`ship-pr` runs this check **again** before the merge. Not belt-and-braces: the requirement is about the
merge, and a PR opened through `-Force`, by hand on github.com, or days ago and resumed would otherwise
land with an unfinished plan.

## The impact gate: how far does this change reach, and how much does it weigh?

The **DEPLOY section holds the tiers** the repo asks about, each with a reason and a score from 1
to 5. That is **tier 0 plus the single audience tier** `Get-ReleaseAudienceTier` names — and since
August 19, 2026 neither says so out loud:

```text
## DEPLOY: `feat/short-name`

The routine version bump stops needing a developer.

**Score:** 4

### What makes this deploy extra special

Consumers must re-add the marketplace under its new name.

**Score:** 5
```

**Tier 0 is in every entry and is the one tier that can never be `N/A`** — every change reaches the people
maintaining the repo at least a little. It answers directly under the DEPLOY heading; the `###` heading
beside it means whichever audience tier the repo stated. A repo that has stated **none** gets the
older shape instead, a `#### Tier N` sub-section per tier the model has, tier 0 among them. This block
showed `#### Tier 1` above `#### Tier 2` and no tier 0 at all until August 13, 2026, which is a shape the
scaffolder writes under no configuration.

The **tier** (`0` = only this repo's own developers notice, `1` = management and the employer/commissioner
get something out of it, `2` = a subscriber of the service notices it) decides which release documents the
entry appears in, and where the
repo's entries declare their impact at all the release cut refuses a bump the pending tiers have not earned.
The **significance** decides where *in* the list the entry sits — `CHANGELOG.md` is one flat ranked list, and
the release documents inherit the order the fold leaves — so the most consequential change leads.

**What it read is printed on every run**, including when nothing was declared and the default applied. That
line is the point: an entry still sitting at tier 0 is work that cannot carry a release on its own, and this
is the last moment to raise it cheaply — the fold ranks the entry as it lands, and after that a correction is
a re-insert on the main branch.

**A malformed table is refused; a missing score is only reported.** That split is by kind of fault, not by
convenience:

- **Refused** — a cell the model has no meaning for (`| 2 | 9 | … |`, `| 5 | 3 | … |`). It reads back as
  unscored, which would sink the entry to the bottom of the list it matters most in — correct-looking
  and silent. Here it is a one-cell fix; after the merge it is an edit on the main branch.
- **Reported, not refused** — a row or score that is simply missing. The score is a judgement about a
  finished change, and an author who has not settled it should not be blocked from merging over it. The
  **release cut** is the refusal point instead, and the message names every entry and every missing cell.
- **A low score is never refused.** Like `Tier: 0`, a significance of 1 is a legitimate, common and final
  answer, which is why this is a separate gate rather than part of the scaffold one.

- **Fenced code is excluded here too**, so an entry that documents the impact format is read by its real
  declaration rather than by the one it quotes.
- **`-Force` does not apply.** It exists for text somebody legitimately wrote; there is no legitimate
  `| 2 | 9 | … |`. Correct the cell — it is a one-character edit.
- **`Tier: N` is still read**, so an entry written before the table folds and ships exactly as it did.

## The resolves gate: which issues does this PR close?

**A plain `#332` in a PR body closes nothing.** GitHub only auto-closes an issue when the body uses a
*closing keyword* (`Closes #332`), so a PR that repairs an issue and merely mentions it leaves that
issue open — and the changelog then says "done" about something the tracker still lists as open. That
is not hypothetical: three consecutive PRs in the source repo did exactly this and left **eight**
repaired findings open.

So the decision is forced rather than remembered:

```powershell
# this PR resolves them -- each gets its own 'Closes #<n>' line in the body
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/open-pr.ps1" -Resolves "331,332"

# this PR resolves no issue (they are cited as context)
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/open-pr.ps1" -NoResolves
```

- **Neither flag, while the changelog entry mentions an issue that is currently open** → the script
  stops **before** the lint, the tests, and the push, and names the issues it saw.
- **PR references do not count.** `PR #341`, `PRs #341-#343` and `/pull/341` links are excluded, so
  citing the PR you follow on from does not trip the gate. A gate that fires on every branch gets
  bypassed, which is how it would quietly stop working.
- **A `-Body` you supply that already says `Closes #332`** satisfies the gate on its own.
- **If the open/closed state cannot be determined** (no `gh`, or it errors), the gate **warns and
  lets the PR through**. Wedging the PR flow on a network hiccup would be worse than the bookkeeping
  slip it guards against.
- `-Resolves` takes a **string** (`"331,332"`; a leading `#`, spaces or semicolons are fine).
  Deliberately not an array: across `powershell -File` a comma list is cast to a single number via
  the thousands separator, so `-Resolves 332,340` would silently become issue `332340`.

## Requirements in the consumer

The script is repo-agnostic, but reads its repo data from the **root** of the consumer
(dual-context via `${CLAUDE_PROJECT_DIR}`):

- `scripts/repo-config.ps1` with `Get-RepoName` (the `gh --repo` target) and `Get-LintScript`
  (repo-root-relative path to the repo's own lint gate).
- `scripts/lib/branch-info.ps1` (label/type from the branch prefix).
- `scripts/tests/*.tests.ps1` (the test gate; convention, not config).
- `.github/pull_request_template.md`, `git`, and a logged-in `gh` CLI.

The `specialists-init` bootstrap puts `repo-config.ps1` + `branch-info.ps1` in place as a `VUL-IN`
scaffold. If they are missing -- or still set to `VUL-IN` -- the script stops before the dot-source
with a clear pointer instead of a raw error (#86); fill them in first (see the source repo as a
model).

## Important

- **When a PR may be opened is governance, not script logic** -- the repo's own rule decides that;
  this script only executes. Under the shared rule a PR opens by default once the branch is done and
  the gates are green, and waits for the owner's word only for work with a visible result or work
  that is irreversible/outward-facing.
- This script is maintained in the source repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/release/open-pr.ps1`) and then travels via a release to
  the plugin mirror -- guarded by the shared-scripts drift lint.
