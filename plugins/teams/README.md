# The teams — who the specialists are

**Every plugin in this directory is a team: a set of specialists a repo can enable.** Its sibling
[`../workflows/`](../workflows/) holds the other kind of plugin, which answers a different question —
not *who* the specialists are, but *how* work moves through the repo. That split is the organising
idea behind both directories: it is put side by side one level up, in
[`../README.md`](../README.md), and argued in full in the root README under
[Teams and workflows — what's the difference?](../../README.md#teams-and-workflows--whats-the-difference).

## What is in here

| Folder | The specialists it adds |
|---|---|
| [`team-alpha/`](team-alpha/) | The **core team** — the repo-neutral specialists who work the same way in every repo, plus the persona templates of the main loop and the bootstrap skill `specialists-init`. |
| [`team-lifehub/`](team-lifehub/) | An **add-on team** for a personal information hub / brain-based knowledge repo. |
| [`team-shopify/`](team-shopify/) | An **add-on team** for a Shopify store repo: theme code, store management, configuration. |
| [`team-ecomm/`](team-ecomm/) | An **add-on team** for a commercial webshop of any platform: SEO, CRO, performance/SEA. |

**Which repo enables which is stated once, and not here.** The root README's
[plugin table](../../README.md#teams-and-workflows--whats-the-difference) carries the "who it's for"
column, how the two add-on axes relate, and how many specialists each team ships. This page names the
folders so the directory is readable on its own; it deliberately stops short of restating that table,
because a second copy of it is free to disagree with the first — and the disagreement would be
invisible, since nobody reads both pages in one sitting.

## Teams stack; a repo enables as many as its domain calls for

`team-alpha` is the foundation and belongs in every consuming repo. Each further team **adds
specialists**, so enabling two of them raises no conflict — a Shopify store repo that is also a
commercial webshop legitimately enables `team-shopify` and `team-ecomm` alongside the core. That is
the property that separates this directory from `../workflows/`, where **at most one** plugin may be
enabled at a time: a team hands the repo more colleagues, while a workflow hands it an answer to a
question that can only have one.

## The name is load-bearing, and so is sitting here

A team is named `team-<name>` and lives under `plugins/teams/`; a workflow is named
`workflow-<name>` and lives under `plugins/workflows/`. Since August 9, 2026 that pairing is checked
rather than merely conventional — lint check 23 (`[plugin-kind]`) in
[`check-plugin-integrity.ps1`](../../scripts/lint/check-plugin-integrity.ps1) holds every published
plugin to it.

The half that matters is the naming, and the reason sits one directory over: the core team's
`workflow-sessioncheck` hook
([`team-alpha/hooks/workflow-sessioncheck.ps1`](team-alpha/hooks/workflow-sessioncheck.ps1)) counts
enabled workflows **by the `workflow-` prefix and nothing else**. So the rule is not tidiness about
where files live — a plugin whose name does not say which kind it is would be invisible to that count.

## What a team folder holds

- **`.claude-plugin/plugin.json`** — the manifest, carrying the `version` that is bumped in lockstep
  with every other plugin in this repo.
- **`agents/<group>-<id>-agent.md`** — the subagent definition per specialist, which Claude Code loads
  into every session of a repo that has the plugin enabled.
- **`manuals/<group>-<id>-manual.md`** — the portable playbook the agent def reads in on demand. The
  split between the two, and the repo lens that completes it on the consumer's side, is described under
  [Manuals — the split model](../../README.md#manuals--the-split-model).
- **`skills/`, `hooks/`, `scripts/`, `personas/`** — optional, and only where a team genuinely needs
  them. In practice `team-alpha` is the one carrying all four, because the adoption path, the roster
  and workflow session checks and the sync scripts belong to the core rather than to any domain team;
  `team-shopify` ships one domain skill, and the other two teams are specialists and manuals only.

## `agent-shared/` — in this directory, and not a team

The verbatim boundary blocks shared across agent defs live in
[`agent-shared/`](agent-shared/), here beside the teams rather than one level up. It is **not** a
plugin and never travels as one: it is the source a generator writes *into* these folders. See
[Shared agent-def blocks](../../README.md#shared-agent-def-blocks--one-source-for-the-verbatim-boundaries).

**Why here and not under `plugins/`, where it sat until August 17, 2026.** Every file that carries a
shared block is a team agent def or a team persona — 30 of them across all four teams, and **zero** in
either workflow plugin. So the folder's reach already ended at this directory, and sitting a level up
described a scope it does not have. Two things follow from the move, one of them a behaviour change:

- **It travels with the teams it feeds.** `publish-to-business.ps1` removes a kind-directory once it
  holds no plugin, so a publish carrying no team no longer carries the source of those teams' blocks
  either. Before, it travelled unconditionally.
- **Nothing had to learn where it went.** Every script that asks which plugins exist reads
  `.claude-plugin/marketplace.json` through `plugin-tree-lib.ps1`, so a directory that is in no
  marketplace is not a plugin wherever it sits — including here, sharing a prefix with the four that
  are. That is also why the `[plugin-kind]` rule below does not read this folder as a team missing its
  `team-` prefix: it is anchored on the published set, not on a sweep of this directory.

## Adding a team

A new team is its own folder here, but adding one touches more than this directory — the docs that
enumerate the plugins go stale silently if they are missed. The checklist is in the root README under
[Adding a new team](../../README.md#adding-a-new-team). A new **product**, as opposed to a new team,
does not belong in this repo at all; see
[One product, one repository](../../README.md#one-product-one-repository).

## Enabling one in your own repo

Adding this marketplace and enabling the teams you want is the adoption path, described end to end in
[`../INSTALL.md`](../../INSTALL.md) — its
[quickstart half](../../INSTALL.md#quickstart--the-commands-and-nothing-else) if you only want the
commands, its [adoption half](../../INSTALL.md#adoption--how-to-connect-your-repo) if you want the
reasoning with them. [`../UNINSTALL.md`](../../UNINSTALL.md) is the mirror.
