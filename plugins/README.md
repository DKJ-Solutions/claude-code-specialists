# The plugin source — teams and workflows

**Every plugin in this repo is one of two things, and this directory is organised around that
distinction.** A plugin answers either *who are the specialists in this repo* — then it is a **team**,
under [`teams/`](teams/) — or *how does work move through this repo* — then it is a **workflow**, under
[`workflows/`](workflows/). Nothing published here is both, and nothing is neither.

## The difference, side by side

| | A **team** | A **workflow** |
|---|---|---|
| **Answers** | who the specialists are | how work moves through the repo |
| **Ships** | `agents/` + `manuals/` — one subagent definition and one portable playbook per specialist | `skills/`, and the scripts and hooks behind them — no specialists at all |
| **Stacks?** | **Yes.** Enable the core team plus as many add-on teams as the repo's domain calls for; each one adds colleagues. | **No.** At most one may be enabled, because two would answer the same question differently. |
| **Named** | `team-<name>`, under `plugins/teams/` | `workflow-<name>`, under `plugins/workflows/` |
| **Enable none, and** | the repo has no specialists | the specialists use plain git/gh |

**The stacking row is the one that matters most**, and it is not a style preference. Two enabled
workflows would hand the specialists two contradicting answers to the same question — how a branch is
named, what a change owes before it can open a PR, what a release is — with nothing in the session
saying which one is this repo's; they would then pick, silently and differently each time. Two teams
raise no such conflict, because a second team hands the repo more colleagues rather than a second
answer.

## Which one am I making? The test question

> Does this describe a **craft**, or a **way of working**?

A craft is the same in every repo, so it can travel in a plugin and be enabled without a decision: how
a code reviewer reads a diff, how a technical writer sharpens a document. A way of working belongs to
one repo and has to be *chosen* — which is why the workflows are the only plugins here that carry an
owner's name, and why the default one imposes nothing at all.

That question is not a rhetorical device: it was arrived at by measurement. Of what the core team used
to ship before August 8, 2026, **9% described a craft and 47% was workflow machinery** — so most of
what a consumer received was a way of working they had never chosen. Splitting the two apart is what
this directory layout records. The full argument is in the root README under
[The plugin serves the consumer's repo](../README.md#the-plugin-serves-the-consumers-repo) and
[Teams and workflows — what's the difference?](../README.md#teams-and-workflows--whats-the-difference),
which also carries the **plugin table**: which plugins exist, and who each one is for. Read that table
there rather than expecting a copy of it here — a second copy would be free to disagree with the
first, and nobody reads both pages in one sitting.

## The two rules that guard the split, and where they are checked

- **A plugin's name says which kind it is, and it must sit in the directory that name claims.** Lint
  check 23 (`[plugin-kind]`) in
  [`../scripts/lint/check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1) holds
  every published plugin to both halves. The naming half is the load-bearing one: the count below keys
  on the `workflow-` prefix and nothing else.
- **At most one workflow may be enabled.** The `workflow-sessioncheck` SessionStart hook, in the
  **core team** rather than in the workflow plugins, counts the enabled ids beginning with
  `workflow-` and reports when there is more than one. It never blocks, and it is silent at zero as
  well as at one.

Both are stated in full where they apply: [`teams/README.md`](teams/README.md) and
[`workflows/README.md`](workflows/README.md).

**Not everything under a kind directory is a plugin.** The canonical source of the boundary blocks that
appear verbatim in many agent defs is
[`teams/agent-shared/`](teams/agent-shared/) — a generator writes those blocks *into* the team folders,
and it has [its own README](teams/agent-shared/README.md) for the
never-edit-between-the-sentinels rule and how to add a block. It sits inside `teams/` because every file
carrying such a block is a team's, and it is held to none of the rules above because it is in no
marketplace. See
[Shared agent-def blocks](../README.md#shared-agent-def-blocks--one-source-for-the-verbatim-boundaries).

## What else is in this directory

- **[`INSTALL.md`](../INSTALL.md)** — how to connect your own repo, in a
  [quickstart half](../INSTALL.md#quickstart--the-commands-and-nothing-else) and an
  [adoption half](../INSTALL.md#adoption--how-to-connect-your-repo). It sits here, beside the plugins it
  explains, rather than at the repo root.
- **[`UNINSTALL.md`](../UNINSTALL.md)** — its mirror: the repo teardown and the machine-side removal, in
  the order they have to happen.

Adding a plugin touches more than this directory, because the docs that enumerate the plugins go stale
silently if they are missed. The checklist is in the root README under
[Adding a new team](../README.md#adding-a-new-team). A new **product**, as opposed to a new plugin,
does not belong in this repo at all — it gets its own repository and its own marketplace; see
[One product, one repository](../README.md#one-product-one-repository).
