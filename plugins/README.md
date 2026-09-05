# The plugin source — teams and workflows

**Every plugin in this repo is one of two things, and this directory is organised around that
distinction.** A plugin answers either *who are the specialists in this repo* — then it is a **team**,
under [`dkj-teams/`](dkj-teams/) — or *how does work move through this repo* — then it is a **workflow**, and the
one family of those this repo publishes lives under [`dkj-policy/`](dkj-policy/). Nothing published here
is both, and nothing is neither.

**Neither directory names a kind and nothing else any more — both now say whose kind it is.**
`dkj-teams/` holds the teams *of this family*, and `dkj-policy/` names the **government** — the prime
ministry `dkj-policy` at its root and each ministry a level inside it. The workflow side got there first,
when [#1467](https://github.com/DaveKJohn/claude-code-specialists/issues/1467) renamed `workflows/` and
lifted the prime ministry's files up into it; the team side followed with
[#1480](https://github.com/DaveKJohn/claude-code-specialists/issues/1480), which renamed `teams/` and gave
each of the four teams the same `dkj-` prefix. The distinction this page is organised around is unchanged.
What changed is who the directory says the plugins belong to — and that is not decoration: a plugin
published from **anybody else's** marketplace can now be called `team-*` or `workflow-*` without colliding
with a name this repo has claimed, which is exactly why the
[`[plugin-kind]` check](../scripts/lint/check-plugin-integrity.ps1) holds `dkj-team-*` and the policy
shapes to a directory and lets a bare `team-*` or `workflow-*` through on its name alone.

## The difference, side by side

| | A **team** | A **workflow** |
|---|---|---|
| **Answers** | who the specialists are | how work moves through the repo |
| **Ships** | `agents/` + `manuals/` — one subagent definition and one portable playbook per specialist | `skills/`, and the scripts and hooks behind them — no specialists at all |
| **Stacks?** | **Yes.** Enable the core team plus as many add-on teams as the repo's domain calls for; each one adds colleagues. | **In practice, no** — there is one, and it is opt-in. Two would answer the same question differently, but nothing checks it any more; see below. |
| **Named** | `team-<name>`, under `plugins/dkj-teams/` | `<owner>-policy` and `<owner>-policy-<ministry>`, under `plugins/dkj-policy/`; `workflow-*`, `contributing-*` and `*-codex` are still accepted names but sit nowhere in particular |
| **Enable none, and** | the repo has no specialists | the specialists use plain git/gh |

**The stacking row is the one that matters most**, and it is not a style preference. Two enabled
workflows would hand the specialists two contradicting answers to the same question — how a branch is
named, what a change owes before it can open a PR, what a release is — with nothing in the session
saying which one is this repo's; they would then pick, silently and differently each time. Two teams
raise no such conflict, because a second team hands the repo more colleagues rather than a second
answer.

**That said, the conflict is currently unreachable and the check that guarded it is gone**
([#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886), August 26, 2026). There is one
workflow plugin left, so there is no second answer to collide with, and a repo's own way of working is
not a plugin — it is what the repo already had. The paragraph above is kept as the reason the rule would
have to be re-answered the day a second workflow is added, not as a description of a live guard.

## Which one am I making? The test question

> Does this describe a **craft**, or a **way of working**?

A craft is the same in every repo, so it can travel in a plugin and be enabled without a decision: how
a code reviewer reads a diff, how a technical writer sharpens a document. A way of working belongs to
one repo and has to be *chosen* — which is why the workflows are the only plugins here that carry an
owner's name, and why there is no default one to receive instead: a repo that enables none keeps the way
of working it already had.

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

- **A plugin's name says which kind it is, and where a name claims a directory it must sit there.** Two
  shapes claim one: `dkj-team-*` claims `plugins/dkj-teams/`, and `*-policy` / `*-policy-*` claim
  `plugins/dkj-policy/`. Bare `team-*`, `workflow-*`, `contributing-*` and `*-codex` are recognised as
  names and claim no directory — they are what a plugin from **outside** this family is called, and
  sending one into this family's tree is worse than saying nothing about it. Lint
  check 23 (`[plugin-kind]`) in
  [`../scripts/lint/check-plugin-integrity.ps1`](../scripts/lint/check-plugin-integrity.ps1) holds
  every published plugin to both halves. The naming half is the load-bearing one, and since
  [#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886) it carries its own reason
  rather than a borrowed one: the directory half is **derived** from the prefix, so a plugin matching
  neither is held to no location rule at all.
- **~~At most one workflow may be enabled.~~ Retired August 26, 2026 (#886).** The
  `workflow-sessioncheck` SessionStart hook counted the enabled ids beginning with `workflow-` and
  reported above one. It went with `workflow-default`, whose existence was the only thing that made two
  reachable. Recorded rather than deleted, because the question comes back the day a second workflow
  does.

Both are stated in full where they apply: [`dkj-teams/README.md`](dkj-teams/README.md) and
[`dkj-policy/README.md`](dkj-policy/README.md) — the second of which is now the **plugin's own** page
rather than a page about the kind, because #1467 merged the two into it.

**Not everything under a kind directory is a plugin.** The canonical source of the boundary blocks that
appear verbatim in many agent defs is
[`dkj-teams/agent-shared/`](dkj-teams/agent-shared/) — a generator writes those blocks *into* the team folders,
and it has [its own README](dkj-teams/agent-shared/README.md) for the
never-edit-between-the-sentinels rule and how to add a block. It sits inside `dkj-teams/` because every file
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
