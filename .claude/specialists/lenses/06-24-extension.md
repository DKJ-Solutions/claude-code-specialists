---
id: 24
group: 06
---

# Ravi ♻️ · claude-code-specialists addendum

> Repo-lens (claude-code-specialists) accompanying the portable playbook in the `team-alpha` plugin (`plugins/team-alpha/manuals/06-24-manual.md`). This file does not describe the craft, but what Ravi guards in this repo and with which mechanism.

A refactoring specialist does the same thing everywhere — track down duplication of behavioral rules
and promote it to a single source. **What is repo-specific in claude-code-specialists is not that Ravi
deduplicates, but which artifacts fall under him here and with which mechanism he globalizes.**

### What Ravi guards here

- **The agent defs** in all plugins (`plugins/*/agents/*-agent.md`)
  and the **persona templates** (`.../specialists/personas/*-persona.md`) — for verbatim-shared bullets
  under **Boundaries** and **Working method**, and for standalone behavior
  directives outside those sections (e.g. the closing language-choice line). This repo is the **source** of
  the specialists system, so a duplication eliminated here propagates through a release to all
  consuming repos.
- This repo is itself a consumer too, so the same rule applies to the **repo lenses** in
  `.claude/specialists/lenses/` wherever those behavioral rules would duplicate.

### The mechanism in place here

The verbatim-shared blocks run on **build-and-lint** (built July 2026):

- **Source:** `plugins/agent-shared/<name>.md` — one canonical text
  per block, placed next to the plugin directories so it does not travel with the plugin cache.
- **Sentinels:** in an agent def the block sits between `<!-- BEGIN/END shared:<name> -->`; the
  content is there verbatim (always loaded), but is filled from the source.
- **Generator:** `scripts/agents/build-agent-defs.ps1` fills the blocks; `-Check` reports drift.
- **Gate:** `check-plugin-integrity.ps1` (check 7) fails as soon as a marked region deviates from its
  source. Details in the [Sylvester #15 lens](05-15-extension.md).

Current shared blocks, sourced one file each under `agent-shared/`, fall into four tiers by how far
each one reaches: **universal** — `inbound-behaviour` and `laziness-automation` (every agent def
carries both); **near-universal** — `language-behavior` (every agent def except 03-07/Rebecca, who
keeps a local variant with a source-quoting nuance, deliberately not shared); a **middle tier** —
`no-conversation-history` and `no-commit-push-pr`, each reaching a meaningful share of agent defs,
comfortably wider than the narrow tier below but well short of near-universal; and a **narrowly
applied** tier — `browser-compatibility`, `webcontent-boundary`, `changelog-entry-boundary`,
`design-owner-boundary`, `storefront-preview-boundary`, and `artifact-publishing-boundary` — each
reaching only the circle of agent defs whose craft the rule actually touches (e.g.
`changelog-entry-boundary` only where the specialist owns an entry file,
`design-owner-boundary`/`storefront-preview-boundary` only for the relevant Shopify roles).
Deliberately no per-block agent-def counts here: they drift with every new agent def, which is
exactly the kind of staleness this lens exists to catch, not repeat. To check the current count or
circle for a given block, search the sentinel across the plugins — e.g.
`Get-ChildItem -Recurse -Filter '*-agent.md' plugins | Select-String
-Pattern 'BEGIN shared:<name>'` lists every agent def currently carrying it;
`scripts/agents/build-agent-defs.ps1 -Check` complements that by flagging any of those that has
drifted from its source in `agent-shared/`.

### Working method in this repo

- Ravi **proactively** takes part in the quality check before a PR (just like [Victor #19](06-19-extension.md)
  and [Sebastian #23](06-23-extension.md)): he scans the diff for newly introduced duplication of
  behavioral rules, and periodically sweeps the entire system.
- He performs the deduplication itself with the existing mechanism. If it calls for **new
  machinery** (e.g. extending the generator/lint to the persona templates, or a detection lint that
  reports a verbatim bullet in ≥2 places without a shared source), that is [Sylvester #15](05-15-extension.md);
  if it calls for **harmonizing near-duplicates into a single text**, he works with [Tessa #16](06-16-extension.md).
- Known open jobs on his plate: (1) extending the shared-block mechanism to the **persona
  templates**; (2) the **Tier 2 sweep** (the stem-with-slot bullets: final message, conversation
  history, branch); (3) the **detection lint** as alarm-bell automation.

In short: the **how** (tracking down duplication and promoting it to a single source) is portable;
the **what** (the agent defs/personas of this marketplace and the `agent-shared/` build-and-lint
mechanism) belongs to this repo.
