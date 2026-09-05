# `scripts/` — the canonical source of everything this repo runs

**This directory is the source. Everything else is a copy of it.** Most of the files here are mirrored
into the plugins for consumers to run — scripts, plus one HTML template — and the mirror is generated
rather than maintained, so a change lands *here* and travels outward, never the other way around. The
authoritative list is the registry itself: `Get-SharedScriptPairs` in
[`lib/shared-scripts-lib.ps1`](lib/shared-scripts-lib.ps1), which
[`sync/build-shared-scripts.ps1`](sync/build-shared-scripts.ps1) generates from and lint check 8 holds
the mirrors to. **This page deliberately states no count**, because it kept getting one wrong: a prose
tally of a machine-held list is wrong when typed and wrong again after the next entry, which is the
lesson the root [`CLAUDE.md`](../CLAUDE.md) records about counting a name inside the document that
carries it. Ask the registry. The mirror's own page, written for the
consumer who only has the copy, is
[`plugins/dkj-policy/scripts/README.md`](../plugins/dkj-policy/scripts/README.md).

Three consequences worth knowing before you touch anything:

- **Never *run* a shared script from the plugin cache while you are in this repo — run the copy here.**
  The cache holds the last *released* mirror, so it lags this directory by however many merges have landed
  since. Two silent failures measured on one day; see below. **Every shared entry point refuses outright**
  ([`lib/source-repo-guard-lib.ps1`](lib/source-repo-guard-lib.ps1)) and names the local path to run
  instead — except the handful that the **harness** invokes from the plugin, a SessionStart or Stop hook,
  where a refusal would fire on every session start or every turn in this repo. That reason is specific to
  being a hook and extends to nothing else.
  **The exempt scripts are deliberately not listed here** — they are named in
  [`tests/source-repo-guard.tests.ps1`](tests/source-repo-guard.tests.ps1) and nowhere else, so adding one
  is a decision that has to be argued in a file that fails when it is wrong. This page named two of them
  until September 3, 2026, and by then there were five.
  **The rule itself is held by that test rather than by this sentence** — it derives the entry points from
  the registry and fails on any that lacks the guard, so a new one is caught on the day it is registered.
  That assert exists because this line previously carried a hand-typed ratio and was wrong: the suite had
  always tested whether the guard *decides* correctly and never whether it is *called*, and
  `maintenance/measure-always-on.ps1` had gone into the registry without it (#897). It reads the parsed
  syntax rather than the file's text, which is the second repair of the same class
  ([#1321](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1321)): a whole-file match on
  the lib's *name* could not tell loading the guard from talking about it, so a comment explaining why a
  script deliberately has no guard counted as having one — and two entry points passed that assert for
  months without meeting it.
- **Never edit a file under `plugins/*/scripts/`.** Change the source here and run
  [`sync/build-shared-scripts.ps1`](sync/build-shared-scripts.ps1). Lint check 8 reports a hand-edited
  mirror as drift.
- **CI runs these from a bare checkout, with no plugin cache.** Anything the lint gate or a test suite
  reaches has to be resolvable from this directory alone — which is why a few files
  [deliberately cannot move](../plugins/dkj-policy/scripts/README.md#what-deliberately-stays-in-the-consumers-root-cannot-move-here)
  into a plugin.

**Why the first of those needs saying, measured on August 12, 2026 against mirror `4.5.0`.** Every skill
page prints `${CLAUDE_PLUGIN_ROOT}/scripts/…`, because that is the only path that resolves for a consumer
— and the harness expands it to your own cache **before you read the page**, so the command in front of
you looks authoritative and points at a release. That mirror was missing two seams this repo had already
adopted. `new-branch` scaffolded the retired three-tier ladder instead of this repo's `Tier 0` + `Tier 2`,
and rewrote `branch/templates/branch_template_changelog.md` — a file the merged development document
retired — back into the pre-audience shape;
`session-status` reported no release note under `releases/notes/` and therefore printed an **empty** "what
the last release left open" block. Neither errored, because the mirror contains no
`Get-ReleaseAudienceTier` and no `Get-ReleaseNoteRoot` at all, so each silently used its pre-seam default.
Both land on the commands that *start* a piece of work, where a wrong answer propagates into everything
downstream. **Re-syncing or bumping the mirror is not the repair** — the lag is structural, because the
cache holds a release and this directory is by definition ahead of it between releases.

## The directories

| directory | what lives there |
|---|---|
| [`lib/`](lib/) | the shared helpers every other directory dot-sources — no standalone entry points |
| [`task/`](task/) | starting and parking work: the branch and its `dkj-policy/<branch>.md` |
| [`release/`](release/) | moving work to the trunk and beyond: the PR, the merge, the fold, the cut |
| [`lint/`](lint/) | the gates that run before a PR and in CI |
| [`sync/`](sync/) | keeping the generated artefacts and the connected repos honest |
| [`agents/`](agents/) | the agent-def generator that fills in the shared blocks |
| [`maintenance/`](maintenance/) | run by hand, on demand rather than on a schedule: the one-off repairs, and the **measurements** — what a skill costs, what the always-on document path costs. None of it is a gate, and none of it should become one |
| [`tests/`](tests/) | the suites CI runs, one per subject. **A new suite's temp fixture path carries `$PID`** — see below |

**Writing a new suite: put `$PID` in its temp fixture path.** The test gate is a throttled *parallel*
scheduler, so two runs overlapping is ordinary rather than exotic — a gate run beside a developer running
one suite by hand is enough. Two runs that build a fixture at the same fixed temp path tear down each
other's tree mid-assert, and the visible result is a red gate naming a subject that is perfectly fine.
Measured on August 11, 2026: `connectors.tests.ps1` passes alone and reported **two** failures when run
twice at once. `$PID` (or a fresh GUID, where one file per child invocation is created) is enough; a
per-case `$Label` is not, because it repeats across runs. `test-suite-gate.tests.ps1` enforces this and
names the offending `file:line`.

`repo-config.ps1` sits at the top level rather than in a directory, deliberately: it is **not machinery
but data** — this repo's own answers to the seam the shared scripts read (the trunk name, the lint script,
the release grouping, the merge method). A consuming repo has its own, and that is the whole point of the
file existing.

## The entry points

The scripts a person or a specialist actually invokes. Everything not listed here is either a lib, a
generator or a test — reached by one of these rather than run directly — or one of the hook-invoked
scripts named below the table, which nothing in this table reaches at all.

| script | what it does | skill |
|---|---|---|
| [`task/claim-issue.ps1`](task/claim-issue.ps1) | assigns an issue to the account this checkout **commits** as, and refuses one that is closed or already somebody else's — the step before the branch | `claim-issue` |
| [`task/new-branch.ps1`](task/new-branch.ps1) | creates the branch **and** its `dkj-policy/<branch>.md`, in one move — a branch is never entry-less | `new-branch` |
| [`task/worktree-lane.ps1`](task/worktree-lane.ps1) | opens a branch in its own git worktree — a "lane" — so one branch can be built while another ships, and hands a lane back when it is ready | `worktree-lane` |
| [`task/park-branch.ps1`](task/park-branch.ps1) | commits outstanding work and pushes, with no PR — for handing a branch to another machine | `park` |
| [`task/prune-merged.ps1`](task/prune-merged.ps1) | fast-forwards the trunk and deletes the local branches that are **provably** merged; one without that proof is left alone | `prune-merged` |
| [`task/adopt-config.ps1`](task/adopt-config.ps1) | reads the config blueprint and places or proposes each seam answer | `adopt-dkj-policy` (Part 2) |
| [`task/adopt-workflow-folder.ps1`](task/adopt-workflow-folder.ps1) | scaffolds `dkj-policy/` in a consumer — the folder docs, the releases root and the branch dossier | `adopt-dkj-policy` (Part 1) |
| [`task/adopt-shopify-floor.ps1`](task/adopt-shopify-floor.ps1) | places team-shopify's floor in a consumer: the live-theme guard's seams, a starter theme-check config and the CI workflow that runs it | `adopt-shopify-floor` |
| [`task/check-policy-drift.ps1`](task/check-policy-drift.ps1) | lays out every document that legislates here — the plugins' portable pages against this repo's own prose — so the two can be read against each other; it decides nothing | `check-policy-drift` |
| [`task/push-preview.ps1`](task/push-preview.ps1) | pushes the branch to its own **unpublished** preview theme, creating that theme on the first push rather than at branch creation | `push-preview` |
| [`task/sync-main.ps1`](task/sync-main.ps1) | mirrors the live Shopify theme into the trunk without letting live overwrite the trunk's own work | `sync-main` |
| [`release/open-pr.ps1`](release/open-pr.ps1) | the four gates, the push and the PR; the body and title come from the entry | `open-pr` |
| [`release/ship-pr.ps1`](release/ship-pr.ps1) | open → wait for CI → merge → fold, in one motion | `ship-pr` |
| [`release/verify-resolved-issues.ps1`](release/verify-resolved-issues.ps1) | checks that a merged PR closed the issues it declared, and closes any it did not — `ship-pr.ps1` runs it as its own process after the merge | `ship-pr` |
| [`release/fold-changelog-entry.ps1`](release/fold-changelog-entry.ps1) | folds the entry into `CHANGELOG.md` at its ranked position and removes the branch document | `fold-changelog` |
| [`release/cut-release.ps1`](release/cut-release.ps1) | the lockstep version bump, the release notes and the tag — **only on Dave's explicit request** | `cut-release` |
| [`release/new-internal-note.ps1`](release/new-internal-note.ps1) | the tier-1 note's skeleton; needs the development notes, so it runs *after* the cut | `cut-release` |
| [`release/build-release-notes-page.ps1`](release/build-release-notes-page.ps1) | builds the hand-written notes into one browsable page, and with `-Worker` the Cloudflare Worker that serves it — it publishes nothing | `release-notes-page` |
| [`release/publish-to-business.ps1`](release/publish-to-business.ps1) | publishes the marketplace subset to the business repo Claude Enterprise syncs from — a separate, deliberate step after a cut | `cut-release` (Block 3) |
| [`lint/check-plugin-integrity.ps1`](lint/check-plugin-integrity.ps1) | the lint gate — the manifests, the frontmatter, dead links, and the two dozen checks named in its own docstring | — |
| [`sync/check-connectors.ps1`](sync/check-connectors.ps1) | the two-way registry check across every connected repo | — |
| [`sync/find-specialist-mentions.ps1`](sync/find-specialist-mentions.ps1) | every live mention of a specialist's **name**, grouped by layer — the tool you run *at* a rename | — |
| [`sync/build-shared-scripts.ps1`](sync/build-shared-scripts.ps1) | regenerates the plugin mirrors from this directory | — |
| [`agents/build-agent-defs.ps1`](agents/build-agent-defs.ps1) | writes the shared blocks from `plugins/dkj-teams/agent-shared/` into the agent defs and personas | — |
| [`maintenance/fix-mojibake.ps1`](maintenance/fix-mojibake.ps1) | repairs encoding damage in the markdown this repo names | `fix-mojibake` |
| [`maintenance/measure-skill.ps1`](maintenance/measure-skill.ps1) | what a skill costs — always-on and on-invoke tokens against a stored baseline, and the wall-clock of the script behind it | `measure-skill` |
| [`maintenance/measure-always-on.ps1`](maintenance/measure-always-on.ps1) | what the always-on **document** path costs — `CLAUDE.md` plus everything it `@`-imports, per document and per section | `measure-skill` |

**Five scripts here are invoked by something other than a person**, and their absence from the table above
is a fact about how they are reached, not an omission.

Four are **read-only checks a SessionStart hook runs**: `sync/check-roster-sync.ps1`,
`sync/check-script-contract.ps1`, `sync/build-config-blueprint.ps1` (run by the lint's blueprint check) and
`lint/check-consumer-drift.ps1` (run per consumer by `check-connectors.ps1`).

The fifth **acts rather than reports**: `task/park-cycle.ps1` pushes the branch's development document to
origin until a PR publishes it, and the `cycle-autopark` **Stop** hook is what runs it. It is the automatic
half of parking — `task/park-branch.ps1` in the table above is the half a person invokes.

## The gates, and what each one refuses

`open-pr.ps1` runs all four before it pushes anything, and CI runs the first two again on the PR and on
every push to `main`. `-SkipLint` / `-SkipTests` / `-Force` are the escape valves, deliberately separate
from one another because they overrule different kinds of judgement.

1. **The lint gate** — `check-plugin-integrity.ps1`. Manifests, frontmatter, dead links, the generated
   blocks, the shared-script mirrors, and the staleness classes this repo has been bitten by.
2. **The test gate** — every `tests/*.tests.ps1` suite.
3. **The scaffold gate** — refuses an entry still carrying the wording `new-branch.ps1` wrote, or one whose
   description, body or any tier reason is still empty once HTML comments are stripped.
4. **The step-list gate** — refuses while `dkj-policy/<branch>.md` has an unresolved step above its DEPLOY heading. `ship-pr.ps1`
   refuses at the merge for the same reason, and **this one has no `-Force`**: the `- [~]` dropped mark is
   the way past a step that turned out not to be needed.

## Owners

Scripts, manifests and harness config are [Sylvester #15](../.claude/specialists/lenses/05-15-extension.md)'s
work; the test suites are [Tycho #18](../.claude/specialists/lenses/04-18-extension.md)'s; the release
scripts are [Rendall #06](../.claude/specialists/lenses/05-06-extension.md)'s craft even where Sylvester
maintains them. The documentation *about* them is
[Tessa #16](../.claude/specialists/lenses/06-16-extension.md)'s — including this page.
