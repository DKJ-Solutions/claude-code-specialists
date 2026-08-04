# Contributing — changelog & PR workflow

Changes to this repo go through a branch + Pull Request to `main`, with a folded
changelog entry — the same workflow as the consuming repos. The steps:

1. **Branch — its changelog entry comes along in the same move:**
   [`scripts/task/new-branch.ps1`](scripts/task/new-branch.ps1)`-Name <prefix>/<short-name> -Title "…"`
   creates (or idempotently resumes) the `<prefix>/<short-name>` branch and, as a child step,
   scaffolds `<branch-name>.md` in the repo root (heading + date + type already filled in) via
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
   folds the entry file into the `## Pull Requests` section of [`CHANGELOG.md`](CHANGELOG.md) (with
   `#NN` + PR link), derives a `Plugins:` line from the PR's files along the way (for the per-plugin
   CHANGELOGs — see [Cutting a release](releases/README.md#cutting-a-release)), and removes the entry file;
   commits that directly on `main`.

## Releases — a different cycle, described elsewhere

Everything above is the **contribution cycle**: everyone runs it, on every branch, and it does not wait
for Dave. Cutting a release is a separate cycle with different rules — only the release manager, only on
Dave's explicit request, and under a **direct-on-`main` exception that deliberately does not apply to
ordinary contributions**. Keeping the two apart is the point; do not read the exception below as
something this page grants.

It is described in full in [`releases/README.md`](releases/README.md#cutting-a-release): what a release
is, the `cut-release.ps1` steps, the three note tiers, the per-plugin `CHANGELOG.md`s and `RELEASE.md`
cards, and the guardrails. That same page carries the list of releases actually cut, at the end.

**The one thing worth knowing from here:** a release is repo-wide and in lockstep, which works because
this repository holds **one** product whose four plugins are one system — see
[One product, one repository](README.md#one-product-one-repository). A second, unrelated product would
get its own repository and marketplace rather than joining this release train.
