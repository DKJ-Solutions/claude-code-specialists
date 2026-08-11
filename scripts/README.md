# `scripts/` — the canonical source of everything this repo runs

**This directory is the source. Everything else is a copy of it.** Twenty-three of the scripts here are
mirrored into the plugins for consumers to run, and the mirror is generated rather than maintained — so a
change lands *here* and travels outward, never the other way around. The mirror's own page, written for the
consumer who only has the copy, is
[`plugins/workflows/workflow-davekjohn/scripts/README.md`](../plugins/workflows/workflow-davekjohn/scripts/README.md).

Two consequences worth knowing before you touch anything:

- **Never edit a file under `plugins/*/scripts/`.** Change the source here and run
  [`sync/build-shared-scripts.ps1`](sync/build-shared-scripts.ps1). Lint check 8 reports a hand-edited
  mirror as drift.
- **CI runs these from a bare checkout, with no plugin cache.** Anything the lint gate or a test suite
  reaches has to be resolvable from this directory alone — which is why a few files
  [deliberately cannot move](../plugins/workflows/workflow-davekjohn/scripts/README.md#what-deliberately-stays-in-the-consumers-root-cannot-move-here)
  into a plugin.

## The directories

| directory | what lives there |
|---|---|
| [`lib/`](lib/) | the shared helpers every other directory dot-sources — no standalone entry points |
| [`task/`](task/) | starting and parking work: the branch and its two `branch/` files |
| [`release/`](release/) | moving work to the trunk and beyond: the PR, the merge, the fold, the cut |
| [`lint/`](lint/) | the gates that run before a PR and in CI |
| [`sync/`](sync/) | keeping the generated artefacts and the connected repos honest |
| [`agents/`](agents/) | the agent-def generator that fills in the shared blocks |
| [`maintenance/`](maintenance/) | one-off repairs run by hand |
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

The scripts a person or a specialist actually invokes. Everything not listed here is a lib, a generator or
a test, reached by one of these rather than run directly.

| script | what it does | skill |
|---|---|---|
| [`task/new-branch.ps1`](task/new-branch.ps1) | creates the branch **and** both `branch/` files plus the reference templates, in one move — a branch is never entry-less | `new-branch` |
| [`task/park-branch.ps1`](task/park-branch.ps1) | commits outstanding work and pushes, with no PR — for handing a branch to another machine | `park` |
| [`task/adopt-config.ps1`](task/adopt-config.ps1) | reads the config blueprint and places or proposes each seam answer | `adopt-config` |
| [`release/open-pr.ps1`](release/open-pr.ps1) | the four gates, the push and the PR; the body and title come from the entry | `open-pr` |
| [`release/ship-pr.ps1`](release/ship-pr.ps1) | open → wait for CI → merge → fold, in one motion | `ship-pr` |
| [`release/fold-changelog-entry.ps1`](release/fold-changelog-entry.ps1) | folds the entry into `CHANGELOG.md` at its ranked position and resets both branch files | `fold-changelog` |
| [`release/cut-release.ps1`](release/cut-release.ps1) | the lockstep version bump, the release notes and the tag — **only on Dave's explicit request** | `cut-release` |
| [`release/new-internal-note.ps1`](release/new-internal-note.ps1) | the tier-1 note's skeleton; needs the development notes, so it runs *after* the cut | `cut-release` |
| [`lint/check-plugin-integrity.ps1`](lint/check-plugin-integrity.ps1) | the lint gate — the manifests, the frontmatter, dead links, and the two dozen checks named in its own docstring | — |
| [`sync/check-connectors.ps1`](sync/check-connectors.ps1) | the two-way registry check across every connected repo | — |
| [`sync/build-shared-scripts.ps1`](sync/build-shared-scripts.ps1) | regenerates the plugin mirrors from this directory | — |
| [`agents/build-agent-defs.ps1`](agents/build-agent-defs.ps1) | writes the shared blocks from `plugins/agent-shared/` into the agent defs and personas | — |
| [`maintenance/fix-mojibake.ps1`](maintenance/fix-mojibake.ps1) | repairs encoding damage in the markdown this repo names | `fix-mojibake` |

Four scripts here are **read-only checks a SessionStart hook invokes** rather than something anyone runs by
hand: `sync/check-roster-sync.ps1`, `sync/check-script-contract.ps1`, `sync/build-config-blueprint.ps1`
(run by the lint's blueprint check) and `lint/check-consumer-drift.ps1` (run per consumer by
`check-connectors.ps1`). Their absence from the table above is a fact about how they are reached, not an
omission.

## The gates, and what each one refuses

`open-pr.ps1` runs all four before it pushes anything, and CI runs the first two again on the PR and on
every push to `main`. `-SkipLint` / `-SkipTests` / `-Force` are the escape valves, deliberately separate
from one another because they overrule different kinds of judgement.

1. **The lint gate** — `check-plugin-integrity.ps1`. Manifests, frontmatter, dead links, the generated
   blocks, the shared-script mirrors, and the staleness classes this repo has been bitten by.
2. **The test gate** — every `tests/*.tests.ps1` suite.
3. **The scaffold gate** — refuses an entry still carrying the wording `new-branch.ps1` wrote, or one whose
   description, body or any tier reason is still empty once HTML comments are stripped.
4. **The step-list gate** — refuses while `branch/branch-progress.md` has an unresolved step. `ship-pr.ps1`
   refuses at the merge for the same reason, and **this one has no `-Force`**: the `- [~]` dropped mark is
   the way past a step that turned out not to be needed.

## Owners

Scripts, manifests and harness config are [Sylvester #15](../.claude/specialists/lenses/05-15-extension.md)'s
work; the test suites are [Tycho #18](../.claude/specialists/lenses/04-18-extension.md)'s; the release
scripts are [Rendall #06](../.claude/specialists/lenses/05-06-extension.md)'s craft even where Sylvester
maintains them. The documentation *about* them is
[Tessa #16](../.claude/specialists/lenses/06-16-extension.md)'s — including this page.
