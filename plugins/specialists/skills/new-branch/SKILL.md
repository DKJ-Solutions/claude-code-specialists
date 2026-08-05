---
name: new-branch
description: >-
  Create (or idempotently resume) a git branch AND its changelog entry file in one move, via the
  shared, centralized new-branch script from the plugin (single source of truth, issue #81) -- so a
  consumer does not have to duplicate this script locally. Use this whenever a new piece of work
  starts: a branch is never entry-less -- creating it brings its changelog entry to life in the
  same step, instead of a separate later scaffolding step.
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
3. Immediately creates that branch's changelog entry file by calling the shared
   `new-changelog-entry.ps1` as a child step (own script, own mirror) -- so the branch and its
   entry come into existence in a single step. If the entry file already exists, that step is a
   no-op (same idempotence).

## The entry carries a tier, scaffolded at 0

The entry file gets a `Tier: 0` line under its heading. It says **how far the change reaches**, on one
scale:

| tier | who notices |
|---|---|
| `Tier: 0` | only this repo's own developers -- docs, config, internal work |
| `Tier: 1` | a colleague working on this project gets something out of it |
| `Tier: 2` | a consumer of the product notices it |

**Raise it by hand when the work deserves it.** Nothing breaks if you leave it at 0, which is exactly why
it is worth knowing what it costs: where the repo declares tier sections, the release cut reads them and
refuses a bump they have not earned -- a release needs at least one tier-1 entry, a minor needs a tier-2
one. So an entry left at 0 is work that cannot carry a release on its own. `open-pr` prints the tier it
read, so you learn that before the PR rather than at the cut.

**There is no `-Tier` parameter, deliberately.** Whoever finishes the branch already has to rewrite the
title and body before the PR (open-pr's scaffold gate refuses the stubs), so the tier is one more edit in a
file that is being edited anyway.

**Do not derive it from your branch prefix.** The prefix predicts the *category* an entry is grouped under,
not its impact: a `docs/` branch can carry a tier-2 change and a `feat/` branch a tier-0 one. The source
repo measured this -- its single most consequential change for a consumer, a rename that broke every
existing install, arrived on a `chore/` branch.

The tier's word (`Tier`) is a machine-read key and is **not** translated, unlike the four scaffold strings
below: the writer, the PR gate and the fold all match on the literal, so a translated key would make an
entry unreadable to your own fold.

## Recording intent and parking a branch (#162)

Two optional parameters cover the "start now, continue later (maybe on another device)" case:

- **`-Intent "<what is next / where I left off>"`** -- fills the changelog entry body with that
  text instead of a placeholder. If you omit it, the body falls back to a directional block
  (`**To do / where I left off:**` + a prompting TODO) rather than a bare one-line TODO, so a
  forgotten `-Intent` still leaves a "what is next" prompt. Either way it is a scaffold: whoever
  finishes the branch replaces the body with the final description before the PR.
  The stub wording quoted here is only the **default**. All four strings the entry is built from --
  the title placeholder, this heading, the fallback body, and the type an unknown prefix falls back
  to -- are repo-owned and can be set in your own `scripts/repo-config.ps1`
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
  table (`Get-BranchInfo`/`Test-BranchName`) and the branch-name-to-entry-filename conversion.
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
  locally and writes the entry file; nothing leaves the machine. With `-Park` it also commits the
  entry and pushes the branch to `origin` -- but still **opens no PR**. Opening a PR remains a
  separate, explicit step (the `open-pr` skill).
- **Idempotent repetition.** Running the script again on a branch that already exists, or for an
  entry file that is already there, does not fail or overwrite -- it simply resumes/no-ops.
- The source of this script lives in the workshop repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/task/new-branch.ps1`) and then travels via a release to
  the plugin mirror -- guarded by the shared-scripts drift lint.
