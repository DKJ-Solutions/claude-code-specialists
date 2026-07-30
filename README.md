# davekjohns-workshop

The **workshop of Dave (DaveKJohn)**: the marketplace repo where all of his Claude Code plugins are
built and maintained — designed by a human, executed with his team of specialists. The first
product family is the **Claude Specialists system** in
[`claude-code-plugins/claude-specialists/`](claude-code-plugins/claude-specialists/), split into **four plugins**: the shared,
portable core plus three domain groups. This repo is the **single source of truth** for all shareable
subagent definitions — every consuming repo points to it instead of maintaining its own copies, and
enables or disables **per plugin** which groups it needs.

## The plugin families

Every plugin family lives in its own folder under `claude-code-plugins/`, with its **own README**
that explains what the family does and how its sub-plugins differ. For now there is one family:

- **[`claude-specialists/`](claude-code-plugins/claude-specialists/README.md)** — the
  Claude Specialists system: the shared, repo-neutral core `specialists` (group 1, for every
  repo) plus the three deliberately domain-flavored groups `specialists-lifehub` (group 2),
  `specialists-shopify` (group 3), and `specialists-ecomm` (group 4). Which specialists sit in
  which sub-plugin, who they are meant for, and how to invoke them is in that README — this file
  doesn't repeat it.

## What lives here and what doesn't

**Does live here:** the three plugin folders with **subagent definitions** (`agents/`); for a
migrated domain group also the **portable playbook** (`manuals/<group>-<id>-manual.md`) that the
agent def reads in via `${CLAUDE_PLUGIN_ROOT}/manuals/`. Group 1 additionally carries two things
that cover the **main-loop layer** (see the family README's
[Adoption: the bootstrap path](claude-code-plugins/claude-specialists/README.md#adoption-the-bootstrap-path)):
the **persona templates** (`personas/<group>-<id>-persona.md`) of the orchestrator + main-loop specialists
(Chris, Bianca, Derek, Rendall), and the **repo-neutral bootstrap skill** `specialists-init`.

**Doesn't:** governance (`CLAUDE.md`, the workflow rules), safety hooks, or MCP config. Those stay
at repo level deliberately, because they differ per repo (or are safety-critical). The plugins
deliberately carry **no safety/guardrail hooks** and **no repo-specific skills** — with a few named,
repo-neutral exceptions: the skill `specialists-init` (the adoption path itself) and three
informational, read-only SessionStart hooks that never block — `connector-sessioncheck` (sync
signaling), `roster-sessioncheck` (roster-drift signaling), and `script-contract-sessioncheck`
(signals when a repo's own workflow libs no longer expose a function the shared scripts call; see the
[connectors README](claude-code-plugins/claude-specialists/connectors/README.md)); domain groups
2/3 may carry domain skills that a repo shares.

### Repo layout

The full picture, top-level folder by folder:

- **`.claude-plugin/marketplace.json`** — the marketplace definition: the plugins with their `source`.
- **`claude-code-plugins/`** — the home of the plugin families. See the family
  [README](claude-code-plugins/claude-specialists/README.md) for what a plugin folder carries
  (`agents/`/`manuals/`/`personas/`/skills) and its
  [Manuals — the split model](claude-code-plugins/claude-specialists/README.md#manuals--the-split-model)
  section for the manual/agent-def/persona split and the
  [Shared agent-def blocks](claude-code-plugins/claude-specialists/README.md#shared-agent-def-blocks--one-source-for-the-verbatim-boundaries)
  mechanism. Next to the plugin folders — deliberately *not* inside them, so it doesn't travel along
  with the plugin cache — live `connectors/` (the register of which repos have each plugin
  installed and whether they are in sync; see its own
  [README](claude-code-plugins/claude-specialists/connectors/README.md)) and `agent-shared/` (the
  canonical source of the shared agent-def blocks referenced above).
- **`scripts/lib/`, `scripts/lint/`, `scripts/release/`, `scripts/sync/`, `scripts/agents/`,
  `scripts/tests/`** — the shared helpers (`branch-info.ps1`, `release-lib.ps1`,
  `agent-shared-lib.ps1`), the lint gate + drift check, the changelog/PR/release scripts (incl.
  `cut-release.ps1`), the connectors check (`check-connectors.ps1`), the agent-def generator
  (`build-agent-defs.ps1` — fills in the shared blocks from `agent-shared/`), and the tests. A
  mirrored copy for consumers lives inside the `specialists` plugin — see its own
  [README](claude-code-plugins/claude-specialists/specialists/scripts/README.md).
- **`releases/`** — the release history: `development/<X>.x/<X.Y.Z>.md` (full notes per version) +
  `README.md` (overview table + the full cutting-a-release mechanics) — see
  [`releases/README.md`](releases/README.md). The `## Releases` section of `CHANGELOG.md` points here.
- **`.claude/`** — the repo layer: `plugins/claude-specialists/` (the repo lenses + persona manuals
  in `specialists/` on the **plugin path** — the standard location — and the Specialists handbook
  `README.md` next to them), and `settings.json` (harness config; see [Consumption](#consumption)).
- **`CLAUDE.md`, `README.md`, `CHANGELOG.md`** — the root docs — and **`.github/`**
  (`pull_request_template.md` + `workflows/ci.yml`, the CI gate that runs the lint + test suites on
  every PR and push to `main`; see [`CONTRIBUTING.md`](CONTRIBUTING.md)).

## Consumption

A consuming repo adds this marketplace via `extraKnownMarketplaces` in `.claude/settings.json` and
enables the desired plugins via `enabledPlugins` — and then, because an install is **project-scoped**,
runs `claude plugin install <plugin>@<marketplace>` from that repo's root for each of them; the
settings keys alone install nothing. The canonical enable-a-plugin walkthrough (the settings snippet,
the per-plugin install, the restart, the `claude plugin list` self-check, running the bootstrap skill)
is in the family
[Quickstart](claude-code-plugins/claude-specialists/QUICKSTART.md) — connect in three steps, for
those who didn't build the system. This root README keeps only the two marketplace-wide facts that
matter beyond any one consumer:

**Seeing which release you're on — `RELEASE.md`.** Each plugin folder carries a `RELEASE.md` card
(version + date/type, a one-line summary, and the entries for that version) that travels with the
plugin cache exactly like its `CHANGELOG.md`. Because `claude plugin update` pins the cache to a
specific version (see [Versioning](#versioning)), the cached `RELEASE.md` copy is always *exactly*
the installed release — a consumer opens it under the plugin path in their own cache to see which
release they're on, without cross-referencing this workshop's own `releases/` history.

**One canonical channel — mind the old repo name.** The marketplace is named `davekjohns-workshop`
(repo `DaveKJohn/davekjohns-workshop`) and that is the only channel; use that name in
`extraKnownMarketplaces`. This repo used to be named `claude-specialists`: that old
name keeps pointing to the same repo via a **GitHub rename redirect**, so a marketplace still
registered under `claude-specialists` refers to exactly the same repo — there is **no
second source** to mirror to. However, the local marketplace clone of such an old registration can
lag behind (it was once cloned at an older commit and doesn't converge to the new
`HEAD` on its own), so an install on that channel silently yields an older plugin version. If you
run into this: update the marketplace registration (a marketplace update) or re-add it under
`davekjohns-workshop` — a fresh install should always use `DaveKJohn/davekjohns-workshop`.

## Versioning

Every plugin (one folder per group under `claude-code-plugins/claude-specialists/`) carries its own
`version` in its `plugin.json`. On a release those versions move **in lockstep** — they all get the
same number under one repo-wide tag `vX.Y.Z`. **That version number is also the update gate**:
`claude plugin update` compares nothing but version numbers, so a consuming repo (including this
repo itself, which consumes itself) only pulls in merged changes after the `version` has been
bumped — a merge without a release stays invisible to consumers, and a shared agent-def change
therefore always lands here first, never the other way around. The full mechanics — cutting a
release, the per-plugin `CHANGELOG.md`s and `RELEASE.md` cards, the lint guardrails — are in
[`releases/README.md`](releases/README.md#cutting-a-release).

## Contributing

Changes to this repo go through a branch + Pull Request to `main`, with a folded changelog entry —
the branch/entry-file/PR/merge/fold workflow, and how a release is cut on top of it, are described
in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Want to know more?

- **The Claude Specialists family** — the four sub-plugins, the manual/agent-def/persona split, the
  shared agent-def blocks, where the system runs (Chat/Cowork/Claude Code), how skills are (and
  aren't) used, the adoption/bootstrap path, and adding a new plugin group — all in the
  [family README](claude-code-plugins/claude-specialists/README.md).
- **Releases** — the full version history and the cutting-a-release mechanics are in
  [`releases/README.md`](releases/README.md).
