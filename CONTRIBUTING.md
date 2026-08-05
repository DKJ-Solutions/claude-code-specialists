# Contributing — changelog & PR workflow

Changes to this repo go through a branch + Pull Request to `main`, with a folded
changelog entry — the same workflow as the consuming repos. The steps:

1. **Branch — its changelog entry comes along in the same move:**
   [`scripts/task/new-branch.ps1`](scripts/task/new-branch.ps1)`-Name <prefix>/<short-name> -Title "…"`
   creates (or idempotently resumes) the `<prefix>/<short-name>` branch and, as a child step,
   scaffolds `<branch-name>.md` in the repo root (heading + type already filled in; the **merge date is
   added by the fold**, at the bottom, because a date written now would be the branch's birth date) via
   [`scripts/release/new-changelog-entry.ps1`](scripts/release/new-changelog-entry.ps1) — a branch is
   never entry-less. Valid prefixes (prefix → label → changelog type): `feat/` → enhancement → Feat ·
   `fix/` → bug → Fix · `docs/` → documentation → Docs · `chore/` → documentation → Chore
   (maintenance: scripts, tooling, config). The table is in
   [`scripts/lib/branch-info.ps1`](scripts/lib/branch-info.ps1).
2. **Work + commit** on the branch: write the entry file's description, then commit it along with
   the rest of the work.
3. **Open the PR:** [`scripts/release/open-pr.ps1`](scripts/release/open-pr.ps1)`-Title "…"` first runs
   the **lint gate** [`scripts/lint/check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1)
   (valid manifests, agent-def frontmatter, no dead links, and the flags on every printed
   `claude plugin install`/`update`/`uninstall`) and then the **test gate** (all
   `scripts/tests/*.tests.ps1`, exactly as CI does); on an error or a failing suite nothing is pushed and
   no PR is opened. If both gates pass, the script pushes and opens the PR with label + auto-filled body.
   The same gate also runs as **CI** on GitHub ([`.github/workflows/ci.yml`](.github/workflows/ci.yml):
   lint + all test suites, on every PR and every push to `main`) — so a PR created outside the
   scripts still passes through it all the same.
4. **Merge** — after the required CI check `lint-en-tests` has gone green. Branch protection on
   `main` blocks the merge until then (a merge attempt before it passes returns `BLOCKED`); wait for
   CI, then merge. This step does not wait for Dave: under
   [the safety rules](CLAUDE.md#never-directly-on-the-main-branch--via-branch--pr) a finished branch
   opens, merges, and folds in one motion, and only work with a **visible result** — or work that is
   **irreversible/outward-facing** — stops for his word first.
5. **Fold:** on `main`, right after the merge,
   [`scripts/release/fold-changelog-entry.ps1`](scripts/release/fold-changelog-entry.ps1)`-Branch <name>`
   folds the entry file into the **tier section** of [`CHANGELOG.md`](CHANGELOG.md) that the entry's own
   impact table names (with `#NN` + PR link), derives a `Plugins:` line from the PR's files along the way
   (for the per-plugin CHANGELOGs — see [Cutting a release](releases/README.md#cutting-a-release)), and
   removes the entry file; commits that directly on `main`.

### One thing to do while writing the entry: fill in its impact table

Every entry carries an impact table, scaffolded at tier 0. Filling it in is an edit in a file you are already
editing before the PR:

```text
| Tier | Significance | Why |
|---|---|---|
| 0 | - | - |
```

The **tier** says how far the change reaches, and therefore which release document the entry appears in:

| tier | who notices |
|---|---|
| `0` | only this repo's own developers — docs, config, repo-internal work |
| `1` | a colleague working on this project gets something out of it |
| `2` | a consumer of the product notices it |

The **significance** says how much it weighs for that reader, and therefore where in the document it sits —
the most consequential change leads. Score it against this rubric:

| | |
|---|---|
| `5` | the reader must act — a breaking change, a required migration, or a long-standing blocker that is now gone |
| `4` | materially changes how they work; they notice within a day without being told |
| `3` | a clear improvement, noticed the moment they touch that part |
| `2` | small; noticed if somebody points it out |
| `1` | cosmetic or preventative — nothing changes for them today |

**Every tier you claim needs its own row, with a score and a `Why`.** The ladder is cumulative — a change
consumers notice is also a change colleagues get something out of — so a tier-2 entry owes a tier-1 row:

```text
| Tier | Significance | Why |
|---|---|---|
| 2 | 5 | consumers must re-add the marketplace under its new name; installs break without it |
| 1 | 4 | the routine version bump stops needing a developer |
```

**Why it matters even though nothing breaks if you leave it at 0:** the release cut refuses a bump the tiers
have not earned — a release needs at least one tier-1 entry, a minor needs a tier-2 one — and it also refuses
a release whose tier-1-or-higher entries carry no significance, because an unscored entry cannot be placed.
So an entry left at 0 is work that cannot carry a release on its own. `open-pr.ps1` prints what it read and
names anything unsettled, so you find out before the PR rather than at the cut; it refuses a cell the model
has no meaning for (`| 2 | 9 | … |`) outright.

**The score cells are empty on purpose.** The tier defaults to 0 because 0 is a harmless final answer; a
*score* has no harmless value, so any number scaffolded for you would be a guess at a ranking. The rubric is
what makes it a measurement rather than a mood, and the `Why` is what makes the resulting order auditable —
it says why *this* change is in that band.

**Do not infer it from your branch prefix.** This repo has measured that the prefix does not predict
impact: the single most consequential change for a consumer in v3.2.0 — renaming the marketplace, which
breaks every existing install — arrived on a `chore/` branch. A `docs/` branch can carry a tier-2 change and
a `feat/` branch a tier-0 one.

The full model, and what each tier means for the release documents, is in
[`releases/README.md`](releases/README.md#the-tier-model).

## Releases — a different cycle, described elsewhere

Everything above is the **contribution cycle**: everyone runs it, on every branch, and it does not wait
for Dave. Cutting a release is a separate cycle with different rules — only the release manager, only on
Dave's explicit request, and under a **direct-on-`main` exception that deliberately does not apply to
ordinary contributions**. Keeping the two apart is the point; do not read the exception below as
something this page grants.

It is described in full in [`releases/README.md`](releases/README.md#cutting-a-release): what a release
is, the `cut-release.ps1` steps, [what a bump must earn](releases/README.md#what-a-release-must-earn), the
three release documents, the per-plugin `CHANGELOG.md`s and `RELEASE.md` cards, and the guardrails. That
same page carries the list of releases actually cut, at the end.

**The one thing worth knowing from here:** a release is repo-wide and in lockstep, which works because
this repository holds **one** product whose four plugins are one system — see
[One product, one repository](README.md#one-product-one-repository). A second, unrelated product would
get its own repository and marketplace rather than joining this release train.
