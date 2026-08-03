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

1. Runs the **resolves gate** first, because it needs no network and nothing has left the machine
   yet. See [The resolves gate](#the-resolves-gate-which-issues-does-this-pr-close) below.
2. Runs the **scaffold gate**: the branch's changelog entry must no longer carry the wording
   `new-changelog-entry.ps1` scaffolded it with. See
   [The scaffold gate](#the-scaffold-gate-has-the-entry-actually-been-written) below.
3. Runs the **repo's own lint gate** (via `Get-LintScript` from `repo-config`) and then **all
   test suites** (`scripts/tests/*.tests.ps1`) -- exactly like CI. An error blocks: nothing is
   pushed and no PR is opened. `-SkipLint` / `-SkipTests` are the deliberate escape valves.
4. Pushes the current branch and opens a PR to `main` via `gh`, with a label based on the
   branch prefix and a pre-filled PR body from `.github/pull_request_template.md` +
   the changelog entry file.

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
