# Contributing — changelog & PR workflow

Changes to this repo go through a branch + Pull Request to `main`, with a folded
changelog entry — the same workflow as the consuming repos. The steps:

1. **Branch — its two files in `branch/` come along in the same move:**
   [`scripts/task/new-branch.ps1`](scripts/task/new-branch.ps1)`-Name <prefix>/<short-name> -Title "…"`
   creates (or idempotently resumes) the `<prefix>/<short-name>` branch and, as a child step,
   writes both files via
   [`scripts/task/new-branch.ps1`](scripts/task/new-branch.ps1) — a branch is
   never entry-less:

   | file | subject | lifetime |
   |---|---|---|
   | `branch/branch-changelog.md` | what the change **does** — the entry that folds into `CHANGELOG.md` | folded at the merge, then reset |
   | `branch/branch-progress.md` | what still **must happen** — the branch's name, its step list, where you left off | reset at the merge; never folded |

   **Fixed names, not one per branch.** Git already tracks these per branch, so branches in flight
   cannot collide on them. On `main` both sit in an empty **reset state** carrying a warning not to
   write there until a branch exists — that state opens with an `#`, which is exactly what stops the
   fold mistaking it for an entry. The full convention, including the three step marks, is in
   [`branch/README.md`](branch/README.md).

   **`branch-changelog.md` holds the entry block and nothing around it**, so it pastes into the
   changelog in one go. **The entry is one `##` heading with six `###` sections under it**, and that is
   exactly the block that lands there:

   ```text
   ## `<your branch>` changelog

   ### Branch title

   … the title you gave -Title — and the title the PR gets …

   ### Branch ID

   20260806-114230

   ### Branch type

   feat

   ### What does the change on this branch bring to main?

   … the description you write …

   ### Significance

   #### Tier 0

   … why it matters to this repo's own developers …

   **Score:** <1-5>

   #### Tier 1

   … why it matters to colleagues, or why it does not …

   **Score:** <1-5, or N/A>

   #### Tier 2

   … why it matters to customers and users, or why it does not …

   **Score:** <1-5, or N/A>

   ### Pull Request
   ```

   **The heading, the ID and the type arrive filled in**, and the file is otherwise **bare** — headings and
   the space under them. The guidance for each field lives in
   [`branch/templates/`](branch/templates/), which is what those copies are for. An empty field is refused
   at step 3, which is what replaced the old `TODO:` placeholders.
   **The PR number and the merge date are added by the fold** into `### Pull Request`:
   neither exists yet, and a date written now would be the branch's birth date rather than its landing date. Valid prefixes (prefix → label → changelog type): `feat/` → enhancement → Feat ·
   `fix/` → bug → Fix · `docs/` → documentation → Docs. **There is no `chore/`** — chore work goes
   directly on the trunk under one of the named exceptions, so `new-branch` refuses that prefix. The table
   is in [`scripts/lib/branch-info.ps1`](scripts/lib/branch-info.ps1).
2. **Work + commit** on the branch: keep the step list current as you go, write the entry's
   description, then commit both along with the rest of the work. **Every step must be resolved before
   the PR** — `- [x]` done, or `- [~]` dropped with the reason on the line. Steps 3 and 4 both refuse
   while anything is still `- [ ]`, and there is no `-Force` for it: the dropped mark already is the way
   past a step that should not be done.
3. **Open the PR:** [`scripts/release/open-pr.ps1`](scripts/release/open-pr.ps1) — no title is passed,
   it is composed as `<branch type>: <the entry's Branch title>` — first runs
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
   folds the entry into [`CHANGELOG.md`](CHANGELOG.md) — which is **one flat list with no section
   headings at all**, so the fold does not pick a section: it inserts the block at the **position its own
   Significance sections rank it at**, furthest reach first and, within a tier, highest significance first. It
   appends the PR link and the merge date as the entry's closing line, derives a `Plugins:` line from the PR's files
   along the way (for the per-plugin CHANGELOGs — see
   [Cutting a release](releases/README.md#cutting-a-release)), and **resets both `branch/` files** to
   their empty state — so the trunk is ready for the next branch and the merged branch's ticked-off steps
   do not greet whoever opens it. Commits that directly on `main`, naming exactly those three paths.

   **The fold is the only moment that order can be decided**, which is why the Significance sections have
   to be right before the merge: the cut empties the list, so whatever order the fold leaves is what the release
   documents inherit. Nothing is re-sorted afterwards.

### One thing to do while writing the entry: fill in its Significance sections

Every entry carries a `### Significance` section with a `#### Tier N` sub-section for each of the three
reaches. Filling them in is an edit in a file you are already editing before the PR:

```text
#### Tier 0

… why it matters at this reach …

**Score:** <1-5>
```

**All three tiers are in the file, and each one is answered.** Tier 0 can always be scored. For the two
above it the answer may well be *"this reaches nobody here"* — write `N/A` in the score and say in one line
why. **That is an answer, not a gap:** a blank means both "reaches nobody" and "nobody has got to this yet",
and the gate has to be able to tell those apart. The reach is the **highest tier with a number**, so an
`N/A` costs nothing but a sentence.

The **tier** says how far the change reaches, and therefore which release document the entry appears in:

| tier | who notices |
|---|---|
| `0` | only this repo's own developers — docs, config, repo-internal work |
| `1` | a colleague working on this project gets something out of it |
| `2` | a consumer of the product notices it |

The **significance** says how much it weighs for that reader, and therefore **where in the list** the entry
sits — first in `CHANGELOG.md` at the fold, and then in the release document that inherits that order. The
most consequential change leads. Score it against this rubric:

| | |
|---|---|
| `5` | the reader must act — a breaking change, a required migration, or a long-standing blocker that is now gone |
| `4` | materially changes how they work; they notice within a day without being told |
| `3` | a clear improvement, noticed the moment they touch that part |
| `2` | small; noticed if somebody points it out |
| `1` | cosmetic, or prevents a failure that has not happened yet — then name the failure, because that is the only part a later reader can use |

**Every tier needs a why, including the ones you answer `N/A`.** The ladder is cumulative — a change
consumers notice is also a change colleagues get something out of — so a scored tier 2 obliges a scored
tier 1:

```text
#### Tier 1

The routine version bump stops needing a developer.

**Score:** 4

#### Tier 2

Consumers must re-add the marketplace under its new name; installs break without it.

**Score:** 5
```

**The ladder cannot be skipped.** `N/A` at tier 1 with a score at tier 2 says a change consumers notice
gives this project's colleagues nothing, and `open-pr.ps1` refuses that by name rather than asking you for
a number.

**Why it matters even though nothing breaks if you leave it at 0:** the release cut refuses a bump the tiers
have not earned — the bump follows the highest tier pending: tier 0 only is a patch, tier 1 or higher earns a minor — and it also refuses
a release whose tier-1-or-higher entries carry no significance, because an unscored entry cannot be placed.
So an entry left at 0 is work that cannot carry a release on its own. `open-pr.ps1` prints what it read and
names anything unsettled, so you find out before the PR rather than at the cut; it refuses a score the
rubric has no meaning for (`**Score:** 9`) outright.

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
this repository holds **one** product whose five plugins are one system — see
[One product, one repository](README.md#one-product-one-repository). A second, unrelated product would
get its own repository and marketplace rather than joining this release train.
