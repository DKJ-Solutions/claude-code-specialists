---
name: fold-changelog
description: >-
  Fold a branch's changelog entry into CHANGELOG.md via the shared, centralized fold script from the
  plugin (single source of truth, issue #81) -- so a consumer does not have to duplicate this script
  locally. Use this on main, immediately after merging a branch, to fold the entry
  (the DEPLOY section of workflow-davekjohn/development-cycle.md, or an older branch/ pair, or a pre-split
  <branch-name>.md in the repo root) into CHANGELOG.md --
  a flat ranked list with no section headings, where each entry lands at the position its own
  Significance sections rank it at (furthest reach first, highest significance first within a tier) -- and then
  clear it: every folded entry's file is deleted, the development cycle included, so the trunk carries no branch document between branches.
disable-model-invocation: true
---

# fold-changelog — the shared fold for consumers

This is the **plugin mirror** of `fold-changelog-entry.ps1`: the same tested source as in the
source repo, shared here so consumers (life-hub, smartwatchbanden, …) do not duplicate it.
The background is in [issue #81](https://github.com/DaveKJohn/claude-code-specialists/issues/81).

## Why the entry file exists at all

**A branch never edits `CHANGELOG.md` directly.** Every branch would be modifying the *same* section of
the same file, so with more than one branch open at a time that guarantees merge conflicts — on a file
where a conflict is pure noise, because the two entries never actually disagree. Instead each branch
writes its **own** entry file, and this skill folds it in after the merge, when the conflict window is
already closed.

**The entry is the DEPLOY section of `workflow-davekjohn/development-cycle.md`** — a fixed path, the same on
every branch. Git tracks it per branch, so branches in flight cannot collide on it. The phases above that
section are the step list; they are never folded, and the document's own heading is what the fold reads the
branch name back off in order to find the PR.

**Which means the fold splits before it folds** (August 23, 2026). It takes the section from the DEPLOY
heading down and leaves the plan where it is — publishing somebody's ticked checkboxes as a change
description is exactly what that boundary prevents. Older shapes still fold whole: a `branch/` pair, and a
pre-split root entry file, are entries from their first line and have no boundary to find.

**Every one of them is deleted, and none is rewritten** (Dave, August 23, 2026). The document exists for
the lifetime of a branch: `new-branch` creates it and the fold removes it, so between branches the trunk
carries no branch document at all. It used to be rewritten to an empty **reset state** instead — opening
with an H1 and carrying a warning not to write there — and that H1 was load-bearing, because it stopped the
trunk's own empty file being folded as if it were a change. Nothing has to do that job now: a second fold
finds no file.

**A pre-split entry still folds.** Before August 6, 2026 the entry was a `<branch-name>.md` in the repo
root — branch `feat/new-plugin` → `feat-new-plugin.md` — and any branch created before that date still
carries one. The fold finds both forms and **deletes** the root one, since it is named after a branch that
is now merged. If you are on such a branch: **never add a suffix** like `-fix` or `-v2`, not even on a
second attempt. Without `-Branch` the fold recovers the branch from the file name, so a suffix breaks the
PR lookup.

**The entry body carries the description; the fold adds what only exists after the PR.** An entry is one
`##` heading naming the branch, with two named `###` sections under it — the same block in the entry file
and in `CHANGELOG.md`, so what a contributor writes is exactly what lands. The fold **strips the guidance
comments** on the way and writes the PR line into `### Pull Request`:

```markdown
## `feat/short-name` deployment

### What does the change on this branch deploy to main?

…why it matters at this reach…

**Score:** 2

#### What makes this change extra special

…or one line saying why it reaches nobody there…

**Score:** N/A

### Pull Request · 20260806-114230

Short strong title

[PR #123](https://github.com/…/pull/123)
```

**The opening section holds the change's two audiences, lowest first, and neither names a tier number.**
Tier 0 answers directly under the question; the audience tier answers under
`#### What makes this change extra special`, which means whichever single tier the repo has stated
(`Get-ReleaseAudienceTier`). **Not every change reaches that audience** — that is why these are blocks rather
than the table they replaced, where a missing row read as an omission, and why the second one can answer
`N/A` with a line saying why. Where a repo has stated no audience tier, each tier the model has gets a
`#### Tier N` sub-section instead, tier 0 among them, exactly as before.

**It was six sections until August 16, 2026 and is two since** (Dave). The heading absorbed the branch ID
and, through the branch it names, the type; the PR title moved into the section that already held the PR's
other facts; and `Significance` lost a heading that only asked again what the section above it asks.
**Every retired heading is still read**, so an entry written before this — in your changelog or on a branch
in flight — folds unchanged.

The scaffolder fills in the heading and the PR title. The fold adds what does not exist until the merge,
one fact per place: the **`PR #NN` link** as the last line of the entry's own `### Pull Request` section,
and the **moment it landed** stamped on that section's heading. The separator is a middot in both.
**The ENTRY heading is left exactly as its author wrote it**, and so is everything else — the fold
rewrites nothing but the comments it strips.

**The consumer document is the exception, and only for the heading.** Its reader is a consumer, who has no
branch — so there the heading is replaced by the entry's PR title, exactly as the PR number and
the merge date are dropped there for being internal administration. `CHANGELOG.md` and the developer notes
keep the branch heading.

**An entry file written before this format still folds.** It carries an `###` heading with the type as a
middot field and, where the repo had adopted tiers, an impact table or a `Tier: N` line. An entry file
lives only on a branch, so that shape is not distant history — any branch opened before the format
changed still has one. The fold **promotes the heading to `##`** as it lands, and says so on the console:
an `###` in a flat list of `##`s is not an entry boundary to any reader of it, so it would otherwise be
absorbed into the entry above and inherit that entry's PR link.

**The date is the fold's** (Dave, August 5, 2026). The scaffolder runs when
the *branch* is created, so any date it wrote was the branch's birth date — a branch opened on Monday and
merged on Thursday was filed as Monday's work, in the one document whose subject is when things landed.
So the entry carries what the author knows and the fold adds what only the merge knows. It comes
from the PR's own merge timestamp rather than from the clock, because a fold does not always run in the
same minute as its merge.

**And since August 23, 2026 it stands on the `## DEPLOY:` heading** (Dave), where it stood on the
`Pull Request` heading for four days and on the closing line before that. It is the date the change
*landed*, and that is the line saying *what* landed — the counterpart of the creation stamp on the
document's own `#` heading, so the two ends of a branch's life are stamped where they belong. Both are
read back: an entry carrying the stamp on `Pull Request` still parses. The closing line keeps the clickable
`[PR #N](url)` and nothing else: one fact, one place. An entry folded without a PR gets neither, because
there is nothing to read either off.

## The one formatting rule: a body sub-heading is `####`, never `##` or `###`

**`##` makes it a separate change.** Every `##` in `CHANGELOG.md` is read as one entry, so a body
sub-heading at that level becomes a phantom entry — one that declares no impact, therefore reads as an
undeclared tier 0, and gets its own block in the release record.

**`###` makes it a seventh section, and can cost the entry a declaration.** The named sections sit at
that level, and a section ends at the next heading of that level or above — so a stray `###` truncates
whichever section it lands in. The dangerous version is a *misspelled* section heading (`Branch Type`):
the parser looks for the exact text, so the entry silently loses the declaration the tier and significance
gates read.

Use `####`, or bold. The lint gate checks both halves in the entry file and in `CHANGELOG.md`.

**What makes this worth a rule is *when* it bites.** The entry file looks perfectly fine on its own, and
fine in the changelog after folding. The damage only appears once the release cut lifts the body into the
release notes and any per-plugin changelog — in the artifact a reader finally sees. Measured on a real
release, where a body's two subheadings came out looking like two extra release categories.
**Inspect the generated notes before pushing a release**; that is what the cut's `-NoPush` is for.

## What the skill does

Run the shared script from the **root of the consuming repo**:

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/fold-changelog-entry.ps1" -Branch <prefix>/<name>
```

**In the source repo, run its own copy instead — `scripts/release/fold-changelog-entry.ps1`.**
`${CLAUDE_PLUGIN_ROOT}` resolves into the plugin cache, which holds the last *released* mirror and so
lags its own source by however many merges have landed since. A consumer keeps no copy of their own, so
for them the line above is the correct one.

Without `-Branch` it folds everything it finds: `workflow-davekjohn/development-cycle.md` if it holds an entry, plus
any pre-split entry file in the root. An optional `-RepoRoot <path>`
overrides which repo root the script writes to — for a consumer that runs the fold from a
temporary/detached worktree (e.g. a `ship-pr.ps1` that checks out main elsewhere) and wants the fold
to land there instead of wherever `CLAUDE_PROJECT_DIR`/git-root would otherwise resolve to (issue
#101); omitted, behavior is unchanged. The script:

1. Folds each entry into `CHANGELOG.md`, with the PR number + link included (retrieved via
   `gh pr list` — keyed on `-Branch`, or on the name in the document's heading, or for a pre-split entry
   on its file name).
2. Clears it afterwards: **`workflow-davekjohn/development-cycle.md` is removed** — one deletion, which
   clears the plan along with the entry since they are sections of one file. A pre-split root entry file is
   removed as it always was, and an older `branch/` step list is removed beside it.

**Where it lands is the top of the list.** `CHANGELOG.md` is an intro followed by a flat list of `##`
entries, **newest first**: the entry being folded is the most recently merged one, so it leads. Everything
above the first `##` is the intro and is never written into; a document with no entries yet simply gets the
first one.

**It ranked on the Significance sections until August 16, 2026**, and the argument for that was that the
cut empties this list, so document order at cut time is what the release documents inherit. That held for
one section only: the release notes rank themselves from tier 1 up and the consumer document always ranks
at tier 2, so both read the scores rather than the order. The one section that does inherit is the
development notes' tier 0 — which asks to be chronological, and was getting score order instead. The
scores are untouched and still decide both the release documents' order and the version bump.

**Nothing is consumed.** The `Tier: N` line of a pre-format entry, and the Significance sections of a current one,
both travel into `CHANGELOG.md` intact. That is a change from when the document had one section per tier: the
*section heading* stated the reach then, so the fold stripped the line. With no heading above the entry,
stripping it would leave the entry declaring nothing — and every downstream reader would take it as tier 0,
which is silent, correct-looking, and wrong in the direction that empties a release document. The documents
that travel outward strip both declarations themselves, at the moment they render.

**An entry that declares nothing is tier 0**, the harmless end: forgetting to classify can never promote
work into a consumer-facing document. The run says so out loud, because such work cannot carry a release on
its own where the repo's release cut checks tiers. **An entry that declares a reach but no significance is
also reported and still folds** — it sinks to the bottom of its tier, which is exactly where a reader of an
unranked entry would put it, and the same place it would rank from if it were scored last.

**What stops the fold before it touches anything**, reported for every entry at once rather than one file at
a time — a fold-all that failed halfway would leave earlier entries folded and their source files deleted:

- a tier the model has no meaning for (`Tier: 5`, `Tier: two`, or an impact row `| 5 | 3 | … |`);
- a significance cell off the scale (`| 2 | 9 | … |`).

**Two refusals disappeared with the sections, and both are structural rather than relaxed:** "could not find
the heading — stopping" (issue #178) has no heading name left to mismatch, and "this repo declares no section
for tier N" has no mapping left to miss — a tier the repo does not use is now a position in the list rather
than an error.

**The script can make that commit itself, and normally should: `-Commit`, or `-Push` to commit and push
in one step.** Both are **opt-in**, so without either the fold is left in the working tree for you to
commit by hand — which is how it ran until August 2, 2026, and four hand-typed fold commits in a single
session is what earned the flags. Committing stays opt-in deliberately: on most repos this commit lands
directly on the main branch, which is a governance exception the repo grants, not something a script
should assume.

```powershell
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/release/fold-changelog-entry.ps1" `
  -Branch <prefix>/<name> -Push
```

**The subject is typed `fold:`, and names the branch and its PR:**

```text
fold: <branch> changelog (#NN)                     one entry
fold: 3 changelogs: a (#1), b (#2), c (#3)         a fold-all run
```

The PR number is looked up from the merge; a fold whose PR cannot be determined simply drops it, and a
fold whose *branch* cannot be determined falls back to the entry's file name — the subject always names
something. It was typed `chore:` until August 10, 2026: folding is a named act with its own script and
its own governance exception, while `chore` said only "housekeeping", and `fold:` is the same choice
[`ship-pr`](../ship-pr/SKILL.md) made for `merge: <branch> (#NN)` one commit earlier, so a merge and its
fold read as a pair. **Nothing parses this subject**, so every `chore: fold ...` in your existing log
stays exactly as valid as it was and there is nothing to migrate.

**The commit names its paths**, so `CHANGELOG.md`, the entries it folded and any legacy step list it removed are
the only things that can land in it however messy the working tree is. That scope limit is the point rather than tidiness: where this
commit runs under a "never commit directly to main, except the fold" exception, an unscoped
`git add -A` would let anything else in the tree ride along under that exception. It is enforced by git
now instead of by care.

## Two things that go wrong in practice

**Check that you are really on the main branch before folding** (`git branch --show-current`).
`gh pr merge --delete-branch` promises in its help to clean up the local branch too, and in practice
turned out to be able to simply leave the local checkout **on the merged branch**. Measured July 16,
2026: the fold then ran there, and the changes had to be moved over by hand afterwards. Do not trust the
flag; trust the check.

**Working from more than one machine: always fold with `-Branch`.** Without it the script folds
*everything* it finds — including a pre-split entry file belonging to a merge that another machine is
still folding, which then lands twice. So `git pull` first, then fold your own branch by name. If your
fold push is rejected because you are behind origin, that is harmless: pull and retry.

## Closing step: branch cleanup (#163)

The fold is the **last step of the PR chain**, so branch cleanup belongs here as its fixed
closing step -- not something to remember per repo or per time:

- **Remote** -- a well-configured repo deletes the head branch automatically on merge (the GitHub
  setting *"Automatically delete head branches"*, `deleteBranchOnMerge: true`; see the
  `specialists-init` setup checklist). Nothing to do by hand. **`ship-pr` now tells you when that
  setting is off**, right after the merge that left a branch behind, with the one-line `gh api` command
  to switch it on -- because being named in a setup checklist read once at init turned out not to reach
  anybody ([#815](https://github.com/DaveKJohn/claude-code-specialists/issues/815)).
- **Local** -- GitHub never touches your own clone, and since
  [#815](https://github.com/DaveKJohn/claude-code-specialists/issues/815) this is a script rather than
  two commands to remember: the [`prune-merged`](../prune-merged/SKILL.md) skill. It fast-forwards the
  trunk, drops stale remote-tracking refs, and deletes only the local branches whose merge it can
  **prove** -- an ancestor of the trunk, or a branch whose PR is merged. Anything else, including a
  parked branch, is kept and reported. `-DryRun` looks first.

  By hand, if you would rather, it is these two on `main` after the fold:

  ```powershell
  git fetch --prune            # drop stale remote-tracking refs (origin/<merged-branch>, ...)
  git branch -d <merged-branch>  # remove the merged local branch
  ```

  `git fetch --prune` matters even when the remote branch was auto-deleted: the stale
  remote-tracking refs otherwise pile up in the local clone until pruned. And note what it does *not*
  prove -- it only drops refs for branches **already gone** from the remote, so a clean local list is no
  evidence at all that the remote is clean. That is `git ls-remote --heads origin`.

## Requirements in the consumer

The script is repo-agnostic, but reads a small block of repo data from the **root** of the consumer
(dual-context: it resolves the repo root via `${CLAUDE_PROJECT_DIR}`):

- `scripts/repo-config.ps1` with `Get-RepoName` (for the `gh --repo` calls). This is the only
  repo-specific file fold needs -- it derives the PR number via `gh pr list` and the entry file name, and
  thus does not dot-source `branch-info.ps1` (unlike `open-pr`). **No changelog-structure seam is read any
  more**: `Get-ChangelogTierHeadings` and the legacy `Get-ChangelogHeading` are retired, because a flat
  document has no section headings to configure. A consumer that still defines either is unaffected --
  nothing calls them.
- A `CHANGELOG.md`. Its intro may be anything the repo likes; the fold only needs to find where the intro
  ends, which is the first `##` heading.
- `git` and a logged-in `gh` CLI.

If `repo-config.ps1` is missing -- typical on a clean consumer -- the script stops before the
dot-source with a clear pointer instead of a raw error (#86). The `specialists-init` bootstrap
puts it in place as a `VUL-IN` scaffold; fill it in (see the source repo as a model) before you use
this skill.

## Important

- **Run this on main, after the merge** (after the PR has been merged) — then the PR number exists.
- The script only touches `CHANGELOG.md` and the entries it folds -- which since the merge is one file
  fewer, because the step list is a section of the document it already removes; nothing else.
- This script is maintained in the source repo; do not modify it locally in the consumer. A
  change lands first in the source (`scripts/release/fold-changelog-entry.ps1`) and then travels via
  a release to the plugin mirror — guarded by the shared-scripts drift lint.
