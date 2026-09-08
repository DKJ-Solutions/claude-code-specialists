---
name: plugin-versions
description: >-
  Show, per enabled plugin, the version installed IN THIS CHECKOUT against the version the local
  marketplace clone holds, and a verdict on whether a plugin update is due -- so you can tell, on this
  machine, whether to run `claude plugin update` or `claude plugin marketplace update`. Read-only, no
  arguments, runs in any checkout on any machine. Use it when you are unsure whether this checkout is
  on the current plugin release, when a session behaves as if it loaded an older plugin, or before
  deciding to refresh the marketplace.
---

# plugin-versions -- installed here vs. the marketplace clone

This is the **plugin mirror** of `plugin-versions.ps1`: the same tested source as in the source repo,
shared here so consumers do not duplicate it -- the same argument as
[issue #81](https://github.com/DKJ-Solutions/claude-code-specialists/issues/81).

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/task/plugin-versions.ps1"
```

**In the source repo, run its own copy instead -- `scripts/task/plugin-versions.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own, so
for them the line above is the correct one.

**Read-only.** It opens `~/.claude/plugins/installed_plugins.json` and the marketplace clone, shells to
`git` inside that clone to read HEAD, and prints. Nothing is written, nothing is pushed, nothing is
persisted -- the `syncedVersion` bookkeeping this repo removed on July 20, 2026 is deliberately **not**
brought back.

## The question it answers, and why nothing else does

"Is the plugin version this checkout loads the same as the one the marketplace clone holds, and if not,
which command closes the gap?" The connector session check is the nearest existing signal, and it goes
**inert** on a plain consumer with no sibling source checkout beside it. Two files, and it is worth
keeping them apart: the hook (`connector-sessioncheck.ps1`) prints
*"no verified workshop checkout found -- check skipped"* on its own early-exit path, so
`check-connectors.ps1` -- and with it the check 4 that compares versions -- is never invoked. That
string is the hook's own; grepping the check for it finds nothing. Either way you get no version
answer. This skill needs no source checkout: it reads what every consumer machine has.

Two facts make the reading trustworthy:

- **The install record is per checkout.** A record in `installed_plugins.json` is keyed on the plugin
  id **and** the `projectPath`, so this reports the version *this folder on this machine* actually
  loaded -- `version`, short `gitCommitSha`, and `scope` (`project` / `local` / `user`).
- **The marketplace clone advances only on `claude plugin marketplace update <marketplace>`** -- not on
  a push and not on a merge. So the clone's per-plugin `plugin.json` `version` is **cut-granular** and
  its git **HEAD sha** is the finer truth. Between two releases the `version` string cannot move, so it
  cannot show your install lagging the clone; the HEAD sha still can, and that is what the verdict
  compares. Whether the clone itself trails `origin` is a further gap this skill does not close -- it
  reads the clone as it stands.

## The output

A one-line summary, then one block per enabled plugin (every plugin is listed even under lockstep, so a
partial or split install state is visible):

```text
5 of 7 plugin(s) behind -- run the update command shown for each (1 could not be determined).
  clone 'claude-code-specialists': <path>  [HEAD 437366a44132, committed 2026-09-08T08:33:02Z, last fetch 2026-09-08T10:37:39]

dkj-policy@claude-code-specialists
  installed here     4.32.0  437366a44132  project
  marketplace clone  4.32.0  HEAD 437366a44132
  verdict            up to date -- your install is at the clone's HEAD
                     -> the clone advances only on: claude plugin marketplace update claude-code-specialists

dkj-team-alpha@claude-code-specialists
  installed here     4.32.0  3e13000b3fbe  project
  marketplace clone  4.32.0  HEAD 437366a44132
  verdict            the clone is AHEAD of your install (same version string 4.32.0, newer commit)
                     -> claude plugin update dkj-team-alpha@claude-code-specialists --scope project
```

**Before pasting this output into a public issue, redact the paths.** The checkout root, the
install-administration path and the marketplace clone path are absolute, and on Windows they carry
your OS username -- replace each with a placeholder like the `<path>` above.

## The verdict, per plugin

| what it reads | verdict |
|---|---|
| install `gitCommitSha` **==** clone HEAD | **up to date.** The clone itself may still lag origin -- `claude plugin marketplace update <marketplace>` refreshes it if you expect newer. |
| install `gitCommitSha` is an **ancestor** of clone HEAD | **the clone is AHEAD of your install** -> `claude plugin update <id> --scope project`. Fires even when the two `version` strings are equal -- the sha is the finer truth. |
| install `gitCommitSha` exists but is **not** an ancestor of clone HEAD, or is unknown to the clone | **your install is ahead, or the clone is stale** -> `claude plugin marketplace update <marketplace>`. If the install `version` is also behind, it says so and names `claude plugin update` first. |
| **no `gitCommitSha`** on one side (an older record shape, or a non-git marketplace fetch) | the two `version` strings are compared instead, and the line says a sha was not available. |
| a whole side is **missing** -- no marketplace clone, no install record for this checkout, conflicting records | **cannot determine**, and the line says which side and the command that would fix it. |

## What it handles without failing

| state | what you see |
|---|---|
| no marketplace clone on this machine | every plugin: *"cannot determine -- no marketplace clone"*, with `claude plugin marketplace add`. |
| no `installed_plugins.json` at all | *"no install administration on this machine"*, verdict *cannot determine*. |
| enabled in settings but **no record for this checkout** (declarative enable only) | *"no install record in this checkout"* -> `claude plugin install <id> --scope project`. |
| only a path-less (machine-wide, `user`-scope) record | reported as such -- it is not read as this checkout's version. |
| several conflicting records for this checkout | all of them are shown, verdict *cannot determine*, with the repair install. |
| the checkout was moved or renamed | the `projectPath` no longer matches, so it reads as *not installed here* -- which is the true state after a move. |
| a non-git marketplace fetch (`.gcs-sha`, no `.git`) | the recorded sha is still read; ancestry is skipped and the verdict falls back to the `version` comparison. |
| no plugins enabled | one line saying so, exit 0. |

Non-Windows path separators are handled: every path is composed with `Join-Path` and the install-record
match normalises both sides.

## Parameters

Both parameters are **test seams** -- a consumer never types either, and the default view takes no
arguments.

| parameter | what it does |
|---|---|
| `-RootOverride` | the repo root to resolve the enable state and the install record against. |
| `-UserHomeOverride` | the home directory `~/.claude` hangs off -- points the enable state's user layer, the install record, and the marketplace clone at one fixture tree. |

## Requirements in the consumer

`git` (to read the marketplace clone's HEAD; a non-git fetch degrades gracefully). Nothing is
repo-owned -- there is no seam to scaffold. It resolves its repo root dual-context via
`${CLAUDE_PROJECT_DIR}`.

## Important

- **Read-only, and it persists nothing.** It reports a comparison; acting on it (`claude plugin update`
  / `claude plugin marketplace update`) stays a deliberate, separate step you run yourself.
- This script is maintained in the source repo; do not modify it locally in the consumer. A change
  lands first in the source (`scripts/task/plugin-versions.ps1`) and then travels via a release to the
  plugin mirror -- guarded by the shared-scripts drift lint.
