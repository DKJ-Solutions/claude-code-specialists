---
name: new-branch
description: >-
  Create (or idempotently resume) a git branch AND its two files in branch/ -- the changelog entry
  and the step list -- in one move, via the shared, centralized new-branch script from the plugin
  (single source of truth, issue #81), so a consumer does not have to duplicate this script locally.
  Use this whenever a new piece of work starts: a branch is never entry-less -- creating it brings
  both files to life in the same step, instead of a separate later scaffolding step.
---

# new-branch -- the shared branch+entry creator for consumers

This is the **plugin mirror** of `new-branch.ps1`: the same tested source as in the workshop repo,
shared here so consumers do not duplicate it. Background in
[issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81).

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/new-branch.ps1" -Name "<prefix>/<short-name>" -Title "short title"
```

The script:

1. Validates the branch name via the shared SSOT helper `Test-BranchName`
   (`scripts/lib/branch-info.ps1`) -- hard-rejects an empty name, `main`, or a name containing
   `final`; soft-warns (but proceeds) on an unknown prefix.
2. Creates the branch (`git checkout -b`), or checks it out if it already exists -- **idempotent**:
   running it again on the same branch simply resumes it instead of failing.
3. Immediately writes that branch's **two files in `branch/`** by calling the shared
   `new-changelog-entry.ps1` as a child step (own script, own mirror) -- so the branch and its files
   come into existence in a single step. Idempotent **per file**: a file that already belongs to this
   branch is left exactly as it is.

## The two files, and why there are two

```text
branch/
  branch-changelog.md   what the change DOES  -- nothing but the entry, so it pastes into CHANGELOG.md
  branch-progress.md    what still MUST HAPPEN -- the branch's name, its step list, where you left off
```

**Fixed names, not one per branch.** Git already tracks these per branch, so two branches in flight
cannot collide on them and the repo root stops filling up with other people's work. On the trunk both
sit in an empty **reset state**, with a warning saying not to write there until a branch exists; the
fold puts them back in that state after the merge.

**Why the split earns its keep.** One file used to do both jobs — it was scaffolded with a
`**To do / where I left off:**` heading *and* folded verbatim into `CHANGELOG.md`, so "replace this
whole block before the PR" had to be a written instruction. Two files make it obvious. The entry now
prompts for what the change does, and nothing else.

**`branch-changelog.md` holds the entry block and nothing around it** — no title, no branch line. That
is what makes it pasteable in one go; the branch name lives in `branch-progress.md`, which has room for
it, and the fold reads it back from there to find the PR.

## The entry carries an impact table, scaffolded at tier 0

The entry file gets this under its heading:

```text
| Tier | Significance | Why |
|---|---|---|
| 0 | - | - |
```

Two questions in one table. **The tier says how far the change reaches**, and therefore which release
document the entry appears in:

| tier | who notices |
|---|---|
| `0` | only this repo's own developers -- docs, config, internal work |
| `1` | a colleague working on this project gets something out of it |
| `2` | a consumer of the product notices it |

**The significance says how much it weighs for that reader**, and therefore where in the document it sits --
the most consequential change leads instead of sitting third under whichever heading its branch prefix
produced. Score it 1 to 5 against this rubric:

| | |
|---|---|
| `5` | the reader must act -- a breaking change, a required migration, or a long-standing blocker that is now gone |
| `4` | materially changes how they work; they notice within a day without being told |
| `3` | a clear improvement, noticed the moment they touch that part |
| `2` | small; noticed if somebody points it out |
| `1` | cosmetic or preventative -- nothing changes for them today |

**Raising the reach is adding a row, and every row needs a score and a `Why`.** The ladder is cumulative: a
change consumers notice is also a change this project's colleagues get something out of, so a tier-2 entry
owes a tier-1 row too. Each row is one document's reader answering their own question.

```text
| Tier | Significance | Why |
|---|---|---|
| 2 | 5 | consumers must re-add the marketplace under its new name; installs break without it |
| 1 | 4 | the routine version bump stops needing a developer |
```

**What it costs to leave it at tier 0.** Nothing breaks, which is exactly why it is worth knowing: where the
repo's entries declare their impact at all, the release cut refuses a bump the entries have not earned -- a
release needs at least one tier-1 entry, a minor needs a tier-2 one -- and it **also** refuses a release whose
tier-1-or-higher entries carry no significance, because an unscored entry cannot be placed. So an entry left at 0 is work that
cannot carry a release on its own. `open-pr` prints what it read and names anything still unsettled, so you
learn that before the PR rather than at the cut.

**The score cells are empty on purpose.** The tier defaults to 0 because 0 is a harmless final answer; a
*score* has no harmless value, so any number scaffolded here would be a guess at a ranking. The rubric is
what makes it a measurement rather than a mood, and the `Why` is what makes the resulting order auditable.

**There is no `-Tier` parameter, deliberately.** Whoever finishes the branch already has to rewrite the title
and body before the PR (open-pr's scaffold gate refuses the stubs), so the table is one more edit in a file
that is being edited anyway.

**A repo that switches the mechanism off (`Get-EntrySignificanceEnabled`) gets the older single `Tier: 0`
line instead**, and that line is still read everywhere -- "recognise both, write one", so entries written
before the table keep folding correctly.

**Do not derive it from your branch prefix.** The prefix decides the entry's *type*, which the entry states
under its own heading -- it predicts nothing about impact: a `docs/` branch can carry a tier-2 change and a
`feat/` branch a tier-0 one. The source
repo measured this -- its single most consequential change for a consumer, a rename that broke every
existing install, arrived on a `chore/` branch.

The tier's word (`Tier`) is a machine-read key and is **not** translated, unlike the four scaffold strings
below: the writer, the PR gate and the fold all match on the literal, so a translated key would make an
entry unreadable to your own fold.

## Recording intent and parking a branch (#162)

Two optional parameters cover the "start now, continue later (maybe on another device)" case:

- **`-Intent "<what is next / where I left off>"`** -- recorded in **`branch-progress.md`**, under
  its "where I left off" section. Omit it and that section carries a prompting placeholder instead,
  so a forgotten `-Intent` still leaves the question standing.
  **It deliberately does not touch the entry.** An intent is a status, and the entry's text folds
  verbatim into `CHANGELOG.md` -- this repo measured three released entries that shipped a progress
  note that way. The entry always scaffolds with its own placeholder, and the PR gate keeps refusing
  it until somebody writes what the change does.
  The stub wording quoted here is only the **default**. The strings the entry is built from --
  the title placeholder, the body placeholder, the retired to-do heading (still refused by `open-pr`
  wherever it survives), and the type an unknown prefix falls back to -- are repo-owned and can be
  set in your own `scripts/repo-config.ps1`
  (`Get-EntryTitlePlaceholder`, `Get-EntryBodyHeading`, `Get-EntryBodyPlaceholder`,
  `Get-EntryFallbackType`; issue #410). Define none of them and you get exactly the English text
  above. That exists so a repo whose changelog is not in English does not have to keep a private
  copy of the script to change four strings -- which is the duplication this skill exists to
  prevent.
- **`-Park`** -- after creating the branch + entry, commits the entry (the intent carrier) and
  pushes the branch to `origin` with `git push -u`. **This opens no PR.** Push is not a PR: parking
  makes the branch reachable from another device, while the PR rule stays intact and separate.

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/new-branch.ps1" `
  -Name "feat/spotify-dashboard" -Title "Spotify dashboard" `
  -Intent "Skeleton + routing done; next: wire the API client." -Park
```

Parking additionally needs a configured, reachable `origin` (git only -- no `gh`, no PR).

## Requirements in the consumer

The script is repo-agnostic, but reads its repo data from the **root** of the consumer
(dual-context via `${CLAUDE_PROJECT_DIR}`):

- `scripts/lib/branch-info.ps1` (dot-sourced) -- the single source of truth for the branch-prefix
  table (`Get-BranchInfo`/`Test-BranchName`).
- `git`.
- `scripts/repo-config.ps1` -- **optional here**, unlike in `open-pr`/`fold-changelog-entry`, which
  pre-flight on it. If present, its four `Get-Entry*` functions set the stub wording (#410); if it
  is absent or fails to load, the entry is written with the built-in English defaults and a
  warning. This is the lightest script in the set, and every string it reads from there has a
  working fallback.

If `branch-info.ps1` is missing -- typical on a clean consumer -- the script stops before the
dot-source with a clear pointer instead of a raw error (#86); fill it in first (see the workshop
repo as a model, or use the `VUL-IN` scaffold the `specialists-init` bootstrap places).

## Important

- **No push, no PR by default.** Without `-Park` the script only runs `git checkout`/`checkout -b`
  locally and writes the two branch files; nothing leaves the machine. With `-Park` it also commits
  **both** of them and pushes the branch to `origin` -- but still **opens no PR**. Both, because the
  step list is the half that says what was still in flight, and that is what parking hands over.
  Opening a PR remains a separate, explicit step (the `open-pr` skill).
- **Idempotent repetition, per file.** Running the script again on a branch that already exists does
  not fail or overwrite -- it resumes. The two branch files are judged **separately**, and on what
  each one says it belongs to rather than on whether it exists (both exist on the trunk by design):
  an entry that has been written stays written, and a step list you have been ticking off is never
  clobbered by a rerun.
- The source of this script lives in the workshop repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/task/new-branch.ps1`) and then travels via a release to
  the plugin mirror -- guarded by the shared-scripts drift lint.
