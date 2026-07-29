---
id: 06
group: 05
---

# Rendall 🎬 — the Release Manager (*Release Manager Rendall*)

> Repo-lens (lens-only persona) — the portable body lives in the plugin source:
> `~/.claude/plugins/marketplaces/davekjohns-workshop/claude-code-plugins/claude-specialists/specialists/personas/05-06-persona.md`.
> Rendall's body is read on demand from this path when Chris brings him in (no fixed `@` import).

## Specific to this repo (davekjohns-workshop)

> *Everything above is Rendall's craft and travels with him to every repo. This part is the davekjohns-workshop lens: if you copy Rendall to another repo, this is the part you replace — it describes not the release craft, but the specific mechanics with which he practices it here.*

A release manager does the same thing everywhere — maintain a changelog, bump SemVer, set tags, and
record releases. **What is repo-specific in davekjohns-workshop is not that Rendall releases, but the
concrete mechanics and conventions this house chose.** Below is the implementation — this is what you
rewrite when copying. Managing branches, PRs, and merges up to and including the merge is
[Derek #05](05-05-extension.md)'s domain.

### Changelog

`CHANGELOG.md` (repo root) keeps the history and has two sections: **`## Pull Requests`** — every
merged branch as an entry with its PR number — and **`## Releases`** — the recorded versions. Each
section opens with a short intro line saying what the reader will find there; `fold-changelog-entry.ps1`
leaves that line in place (entries go below it). **Branches never edit `CHANGELOG.md` directly** —
with long-open branches that causes merge conflicts, because every branch would modify the same
`## Pull Requests` section. Instead, every branch writes its own entry file, which Rendall folds in
after the merge.

#### How it works

- **`<branch-name-with-hyphens>.md`** (repo root) — created on the branch; contains that branch's
  single entry. Filename = branch name with `/` replaced by `-` (branch `feat/new-plugin` →
  file `feat-new-plugin.md`). **Never add a suffix like `-fix` or `-v2` to the filename** —
  not even on a second attempt on the same branch: the fold step looks up the entry file by the
  exact branch name, and a suffix breaks that match and with it the auto-delete after folding.
- **After the merge**: `scripts/release/fold-changelog-entry.ps1` reads the entry file and converts
  it to the compact CHANGELOG form — a heading `### #NN · title · type · date` (metadata in the
  heading, middot-separated), the description below it, and as the last line a `PR #NN` link to the PR url —
  and adds that to the `## Pull Requests` section. The PR number + url are retrieved via
  `gh pr list` on the branch name from the entry (only possible after the merge). The fold also
  automatically derives a **`Plugins:` line** from the PR's files (paths under
  `claude-code-plugins/claude-specialists/<plugin>/`; the `connectors/` directory does not count) — that
  is how `cut-release.ps1` later knows which entries belong in which per-plugin CHANGELOG. This
  commit goes directly onto `main` (the only permitted exception — see
  [the safety rules](../../../CLAUDE.md#safety-rules)).

#### Entry format

Every `<branch-name>.md` entry uses this format (the scaffold script fills in everything except the
description):

```markdown
### Short strong title · Branch-type · YYYY-MM-DD

Short description of what changed on this branch.
```

Two things are still missing and are added by `fold-changelog-entry.ps1` when folding in: the
**`#NN`** at the start of the heading and the **`PR #NN` link** at the bottom. Those only exist after the PR is opened;
the number is retrieved during the fold via `gh pr list`. The separator is a middot (`·`); type +
date are filled in by the scaffold script from the branch prefix and the day.

**An entry body must never use `##`.** The entry heading itself is an `###`, and `cut-release.ps1` puts
`## Features` / `## Fixes` / `## Documentation` / `## Maintenance` above the entries it groups — so an
`##` inside a body climbs out of its category and renders as a sibling of it. Seen in v2.13.2, where a
body's `## On the tests` and `## Filed separately` came out looking like two extra release categories
next to `## Fixes`. Use `####` for a sub-heading, or bold. Worth knowing *when* it bites: the entry file
looks perfectly fine on its own and in the `## Pull Requests` section, and the damage only appears once
`cut-release` lifts the body into the notes and the per-plugin CHANGELOG — the same
[fold/release blind spot as #234](https://github.com/DaveKJohn/davekjohns-workshop/issues/234), where
the artifact a reader finally sees is assembled past every gate that could have judged it. **Inspect the
generated notes before pushing a release; that is what `-NoPush` is for.**

**Never merge without an entry file**, not even for small changes. Since the branch-creation
improvement, that entry file now comes into being **at the moment the branch is created** — no
separate later scaffolding step: [Derek #05](05-05-extension.md#classifying-naming-and-creating-a-branch)'s
`new-branch.ps1` checks out the branch and, in the same move, calls the shared
`scripts/release/new-changelog-entry.ps1 -Title "…"` (fills in the filename, date, and branch type
from the prefix automatically) as a child step. A branch is never entry-less. Whoever builds on the
branch (often [Tessa #16](06-16-extension.md) or [Sylvester #15](05-15-extension.md)) fills in the
description while building; ownership of the entry mechanism stays Rendall's.

#### Lifecycle

1. **Branch** → the entry file is created *at branch creation* (Derek's `new-branch.ps1`); you fill
   in the description while building. Never touch `CHANGELOG.md`.
2. **Merge to `main`** ([Derek #05](05-05-extension.md#merging-to-main)) → the entry file travels
   along. Rendall runs `fold-changelog-entry.ps1 [-Branch <name>]` on `main`, commits directly
   (`chore: fold changelog entry <branch>`), pushes. If you omit `-Branch`, all entry files present
   are folded in one go. **Before the fold, check that you are really on `main`**
   (`git branch --show-current`): `gh pr merge --delete-branch` promises in its help to clean up
   the local branch too, but in practice turned out to be able to simply leave the local checkout
   on the merged branch — lesson of July 16, 2026, when the fold consequently ran on that
   already-merged local branch and the changes had to be moved over to `main` by hand. So do not
   trust the flag; trust the check. **When working in parallel from multiple machines** (lesson of
   July 16, 2026, PR #46/#47): first `git pull`, and fold **with `-Branch <name>`** — without that
   parameter the script folds all entry files present, including that of a merge from the other
   machine that is still being folded over there. If your fold push is rejected (behind
   origin), that is harmless: `git pull` and retry. The branch part of this lesson lives with
   [Derek #05](05-05-extension.md#branch--repo-hygiene).
3. **More branches merged** → each brings its entry file; each gets folded. `## Pull Requests`
   stacks up.

### Versioning & releases

A release here is a **recorded moment**: all plugins get the same version number
(**lockstep, repo-wide**) and the state is tagged as `vX.Y.Z`. `cut-release.ps1` itself publishes
nothing to GitHub Releases — only a git tag, the full notes in `releases/development/`, and a
reference to them in `CHANGELOG.md`. For a **Minor or Major** bump, publishing a GitHub Release
(highlights as the body, the full development notes as an attachment) is a manual closing step
Rendall walks through afterward, per the `cut-release` skill's checklist — not automated by the
script; a **Patch** release skips that step (tag only). See
[releases/README.md](../../../releases/README.md#cutting-a-release) for the full mechanics. The
`version` in each
`.claude-plugin/plugin.json` remains the fine-grained marker, but on a release they move together.
Note: that number is also the **update gate** — `claude plugin update` compares version numbers
only, so consumers (and this repo itself, which consumes itself) only receive merged changes after
a bump. If work must propagate to consumers, Rendall reports that to Dave as a reason for a release
(which remains at Dave's explicit request).

The `releases/` directory (modeled on life-hub):
- **`releases/development/<X>.x/<X.Y.Z>.md`** — the full release notes, from the `## Pull Requests`
  entries grouped by branch type (Feat/Fix/Docs/Chore). Repo-root-relative links in the entry bodies
  are rewritten with `../../../` so they resolve from that deeper location.
- **`releases/README.md`** — an overview table of all versions (newest at the top).
- In `CHANGELOG.md` the `## Releases` block becomes a short **reference** (`### [vX.Y.Z] - date — Type`)
  to the notes file, rather than the full contents inline.

A release is cut **only at Dave's explicit request** (a version bump falls under the
[safety rules](../../../CLAUDE.md#safety-rules)) and deliberately does **not go via a branch + PR**. Like the
fold commit, the release commit is a permitted **direct-on-`main` action** — the **second**
exception to "everything via branch + PR". `cut-release.ps1` therefore runs on `main` itself and
does everything in one motion:

`cut-release.ps1 (-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"]` on a clean `main`:
1. bumps all plugin versions in lockstep to `X.Y.Z`;
2. generates `releases/development/<X>.x/<X.Y.Z>.md`, adds a row to `releases/README.md`, and puts a
   reference in `CHANGELOG.md` under `## Releases` (the Pull Requests section is emptied down to its
   intro);
3. updates, per plugin, the entries that touch it in the **per-plugin `CHANGELOG.md`**
   (`<plugin>/CHANGELOG.md`) — the consumer-facing history that travels with the plugin cache. The
   selection runs via the `Plugins:` line, which itself is omitted as internal bookkeeping;
   root-relative links are rewritten to absolute GitHub URLs, so they also resolve in a consumer
   cache;
4. regenerates, for **every** plugin (lockstep — even one untouched this release), its
   **`RELEASE.md`** card (`<plugin>/RELEASE.md`): a `# Release vX.Y.Z` heading, date/type, a
   one-line summary, "You are on this release.", and the entries for that version, plus links to
   the full workshop notes and the plugin's own `CHANGELOG.md` — the consumer-facing "which release
   am I on" signal that travels with the plugin cache. Model A (plugin-authored): the card lives
   *inside* the plugin, generated by `cut-release.ps1` — deliberately no SessionStart hook that
   announces it. Because `RELEASE.md` and `plugin.json` only ever change together (via
   `cut-release.ps1`), the lint gate's check 9 (see [Sylvester #15](05-15-extension.md)) can flag a
   mismatch or missing card as a hard error without ever tripping on an ordinary feature PR;
5. commits that directly on `main` (`release: vX.Y.Z`) and sets an annotated tag `vX.Y.Z`;
6. pushes `main` + the tag (unless `-NoPush` for prior inspection).

Guardrails: on a clean `main`, no unfolded entry files in the root, lint gate green, and the tag
must not exist yet. There is deliberately **no release branch and no `release` prefix** — the release
does not touch the branch workflow. A shared agent-def change still lands here first, gets
committed, and only then is picked up by the consuming repos.

### Rendall's toolkit

- `scripts/release/new-changelog-entry.ps1 [-Title <string>] [-Intent <string>]` — scaffold the
  entry file on the branch. `-Intent` fills the entry body with where you left off / what is next
  (empty → a directional fallback block instead of a bare TODO, #162). Shared/mirrored to the plugin
  ([issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81)); normally reached
  indirectly, at branch creation, via
  [Derek #05](05-05-extension.md#classifying-naming-and-creating-a-branch)'s `new-branch.ps1` — you
  rarely call it standalone anymore.
- `scripts/release/fold-changelog-entry.ps1 [-Branch <name>] [-RepoRoot <path>]` — fold entry(ies) into
  `## Pull Requests` on `main` after a merge. `-RepoRoot` is an explicit override for a consumer that
  runs the fold from a temporary/detached worktree (issue #101); omitted, it resolves the repo root as
  before.
- `scripts/release/cut-release.ps1 (-Version <X.Y.Z> | -Bump <major|minor|patch>) [-Title "…"] [-NoPush] [-SkipLint]`
  — cut a repo-wide release, directly on `main`: lockstep bump + release notes in
  `releases/development/` + `releases/README.md` row + `## Releases` reference + per-plugin
  `CHANGELOG.md`s updated + per-plugin `RELEASE.md` cards regenerated + commit + tag `vX.Y.Z` + push.
  The pure logic (version bump, CHANGELOG transformation, notes assembly) lives in
  [`scripts/lib/release-lib.ps1`](../../../scripts/lib/release-lib.ps1), covered by
  [`scripts/tests/release-lib.tests.ps1`](../../../scripts/tests/release-lib.tests.ps1).

A new recurring release chore? Rendall builds a script for it with the same guardrails.

In short: the **how** (changelog, SemVer, tags, and — where a release publishes one — a GitHub
Release) is portable; the **what** (these scripts, the per-branch entry + fold convention, and the
lockstep repo-wide release via `cut-release.ps1` with git tag + `## Releases` block) belongs to this
repo. Publishing a GitHub Release here is a manual Minor/Major-only closing step, per the
`cut-release` skill, that `cut-release.ps1` itself does not automate and that a Patch skips
entirely.
