## Branch `feat/agent-shared-under-teams` changelog - 20260817-091318

### What does the change on this branch bring to main?

#### Tier 0

`plugins/agent-shared/` moves to `plugins/teams/agent-shared/`, beside the only plugins that consume it
(Dave, August 17, 2026). The folder holds the canonical text of the boundary blocks a generator writes
into the agent defs, and **every file carrying one of those blocks is a team's** — measured before the
move: 30 agent defs and personas across all four teams, and **zero** in either workflow plugin. Sitting a
level up, beside `teams/` and `workflows/`, claimed a reach the folder does not have.

**Nothing in the tooling had to learn the new address, and that is the point worth recording rather than
the move itself.** Every script that asks which plugins exist reads `.claude-plugin/marketplace.json`
through `plugin-tree-lib.ps1`, so a directory in no marketplace is not a plugin wherever it sits —
including inside `teams/`, sharing a path prefix with the four directories that are. The `[plugin-kind]`
check that requires `team-*` under `plugins/teams/` is likewise anchored on the published set, so it does
not read `agent-shared/` as a team whose prefix is missing. Under the shape these replaced, this exact
folder had to be excluded **by name**, and that exclusion had already gone stale once — it named
`connectors/` for months after `connectors/` had left `plugins/` entirely. `plugin-tree-lib.ps1` was
extracted to have this property and this is the first layout change to exercise it; the two asserts that
prove it are widened rather than repathed, so the nested case now covers a non-plugin **inside** a
grouping directory instead of only one beside it.

**One behaviour does change, and it is an improvement.** `publish-to-business.ps1` prunes a
kind-directory once it holds no plugin. While `agent-shared/` sat directly under `plugins/` it was in no
kind-directory and therefore travelled on **every** publish — including one carrying no team at all,
where the source of the team agent defs' blocks is payload about plugins that are not there. Inside
`teams/` it travels exactly when at least one team does. No code was added for that: the pruning asks
whether a directory still holds a `plugin.json`, which is a question about the directory rather than
about a list of exceptions.

**What was checked and needed no change:** the marketplace manifest (no plugin source moved), the
generator (it resolves through `Get-AgentSharedDir`), and the plugin package boundary — the folder sat
outside every plugin root before and still does, so it continues not to travel in the plugin cache.
The archived notes under `releases/` mention the old path in prose only, never as a link, so history is
left untouched as the record rule requires.

**One stale claim found in passing and corrected here**, because it sits in the sentence being repathed:
the root README's enumeration of the shared blocks named **twelve** of them while the directory holds
**fourteen** — `filecontent-boundary` and `lens-optional` were missing. Nothing checks that list against
the directory, which is how it drifted; the sentence now says so, so the next reader knows the directory
is the authority and the list is a convenience.

**Score:** 3

#### Tier 2

Reaches a consumer only as bytes. Two shipped documents name the folder — Ravi's agent def
(`06-24-agent.md`, in `team-alpha`) and `workflow-default`'s README and `discover-workflow` skill page —
and the path they name has never resolved in a consumer's tree, because `agent-shared/` sits outside
every plugin root and does not travel in the plugin cache. It was a maintainer-only pointer before the
move and still is. Nothing a consumer runs, reads for an answer, or can act on changes.

**Score:** 1

### Pull Request

agent-shared moves under plugins/teams/, beside the plugins that consume it
