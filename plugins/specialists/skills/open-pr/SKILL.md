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

This is the **plugin mirror** of `open-pr.ps1`: the same tested source as in the workshop repo,
shared here so consumers do not duplicate it. Background in
[issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81).

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/open-pr.ps1" -Title "feat: short title"
```

The script:

1. Asks `gh` whether this branch **already has an open PR**, once, because two later steps need the
   answer. See [Resuming a branch whose PR is already open](#resuming-a-branch-whose-pr-is-already-open)
   below. A failed query is treated as "no existing PR" rather than as a blocker.
2. Runs the **resolves gate**, before the slow gates and before anything has left the machine. See
   [The resolves gate](#the-resolves-gate-which-issues-does-this-pr-close) below.
3. Runs the **scaffold gate**: the branch's changelog entry must no longer carry the wording
   `new-changelog-entry.ps1` scaffolded it with. See
   [The scaffold gate](#the-scaffold-gate-has-the-entry-actually-been-written) below. On the same read of
   the same file it also runs the **impact gate** and prints the reach and significance it read. See
   [The impact gate](#the-impact-gate-how-far-does-this-change-reach-and-how-much-does-it-weigh) below.
4. Runs the **repo's own lint gate** (via `Get-LintScript` from `repo-config`) and then **all
   test suites** (`scripts/tests/*.tests.ps1`) -- exactly like CI. An error blocks: nothing is
   pushed and no PR is opened. `-SkipLint` / `-SkipTests` are the deliberate escape valves.
5. Pushes the current branch and opens a PR to `main` via `gh`, with a label based on the
   branch prefix and a pre-filled PR body from `.github/pull_request_template.md` +
   the changelog entry file. If the branch already had an open PR, the push **is** the update and
   the create is skipped.

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
costs — the title is at least visible on the PR. Use `gh pr edit` if you want the title changed.

**`-RefreshBody` rewrites the description from the entry, and only the description.** Pass it when you
extended the changelog entry after the PR was opened — routine on a branch that keeps growing, and
otherwise the PR keeps describing an earlier version of the work while the merged changelog gets the new
one. The "Type of change" boxes, the checklist, the `## Resolved issues` block and anything a reviewer
added all stay exactly as they are.

It is **opt-in** rather than automatic for the reason above: refreshing on every run would overwrite a
hand-edited body without being asked. And it is a no-op where there is nothing to do — no open PR, no
description in the entry, or a body that already matches, in which case nothing is sent to GitHub at all.

The heading it replaces under is the **first `## ` heading of your PR template**, so no extra
configuration is needed: that is where the description placeholder sits. If your template has no `## `
heading, the switch warns and changes nothing rather than guessing.

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

## The impact gate: how far does this change reach, and how much does it weigh?

The entry also carries an **impact table** — one row per tier it reaches, each row scored 1 to 5:

```text
| Tier | Significance | Why |
|---|---|---|
| 2 | 5 | consumers must re-add the marketplace under its new name |
| 1 | 4 | the routine version bump stops needing a developer |
```

The **tier** (`0` = only this repo's own developers notice, `1` = a colleague on the project gets something
out of it, `2` = a consumer notices) decides which changelog section the fold files the entry under, and
where the repo declares tier sections the release cut refuses a bump the pending tiers have not earned. The
**significance** decides where *in* that section and its release documents the entry sits, so the most
consequential change leads.

**What it read is printed on every run**, including when nothing was declared and the default applied. That
line is the point: an entry still sitting at tier 0 is work that cannot carry a release on its own, and this
is the last moment to raise it cheaply — after the merge it is a section move on the main branch.

**A malformed table is refused; a missing score is only reported.** That split is by kind of fault, not by
convenience:

- **Refused** — a cell the model has no meaning for (`| 2 | 9 | … |`, `| 5 | 3 | … |`). It reads back as
  unscored, which would sink the entry to the bottom of the document it matters most in — correct-looking
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
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/open-pr.ps1" -Title "fix: short title" -Resolves "331,332"

# this PR resolves no issue (they are cited as context)
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/open-pr.ps1" -Title "docs: short title" -NoResolves
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
with a clear pointer instead of a raw error (#86); fill them in first (see the workshop repo as a
model).

## Important

- **When a PR may be opened is governance, not script logic** -- the repo's own rule decides that;
  this script only executes. Under the shared rule a PR opens by default once the branch is done and
  the gates are green, and waits for the owner's word only for work with a visible result or work
  that is irreversible/outward-facing.
- The source of this script lives in the workshop repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/release/open-pr.ps1`) and then travels via a release to
  the plugin mirror -- guarded by the shared-scripts drift lint.
