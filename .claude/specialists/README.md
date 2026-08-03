# .claude/specialists

The home of the **Claude Specialists** system *as this repo consumes it itself*, plus the harness it
runs in. This document is both the floor plan of this directory and the **specialists handbook** —
Chris's reference work in case of doubt. It records three things: (1) the **layout** of `.claude/`
itself; (2) **how a specialist is structured** — as persona or subagent, the two-part split of every
manual, and the stable-id system; and (3) **how the specialists here are organized among
themselves**. It is **not a replacement** for the safety rules or the routing.

> **This repo is an outlier.** claude-code-specialists is the marketplace repo of one product; the
> specialists system lives here as the four plugins under `plugins/`
> (see [`../../README.md`](../../README.md)) — and the repo also consumes that system here
> **itself**, via the `specialists` plugin (group 1). The team here is therefore small and focused on
> maintaining this product (agent defs, manuals, docs, tooling), not the broad team of a
> content repo.

- The constitution remains [`../../CLAUDE.md#safety-rules`](../../CLAUDE.md#safety-rules).
- **Chris still takes in and routes every assignment** — see his fixed ritual in
  [`lenses/01-01-extension.md`](lenses/01-01-extension.md).

## Layout of this directory

This directory **is the seam** (issue #221): `../../CLAUDE.md` carries one line —
`@.claude/specialists/SPECIALISTS.md` — and everything specialist-shaped hangs off it. The point is
removability: a teardown is "one directory and one line", not an edit through hundreds of woven-in
lines. It buys nothing in tokens, and must not be sold that way — an imported file loads at launch
just like inline text.

- **`SPECIALISTS.md`** — the **inclusion**: Chris's body import, his lens import, and this repo's
  roster + routing. The single file `CLAUDE.md` names.
- **`lenses/`** — the **repo layer** of the specialists system: one file per specialist,
  `<group>-<id>-extension.md`, flat (ids are unique family-wide). There are two kinds:
  - **Subagent lens** — for the specialists that come out of the `specialists` plugin as subagents
    (Sylvester, Tessa, Edith, Victor, Tycho, Sebastian, Ravi, Nolan, Marlowe): only the `## Specific to this repo` part, which
    supplements the portable playbook in the plugin with the context of this repo. The subagent
    reads the plugin playbook + this lens together; the agent def points to both.
  - **Persona lens (lens-only)** — for the persona-only specialists (Chris, Derek, Rendall), who run
    in the main conversation instead of as subagents. The main loop loads no plugin subagents, so the
    **portable body** comes straight from the plugin install via an `@` import: Chris always
    (`@~/.claude/plugins/marketplaces/claude-code-specialists/plugins/specialists/personas/01-01-persona.md`,
    stated in [`SPECIALISTS.md`](SPECIALISTS.md) rather than in `CLAUDE.md` itself — the seam spends
    two of the four allowed import hops), Derek and Rendall on demand from that same path. The
    extension itself is therefore **lens-only**: only the repo-specific `## Specific to this repo`
    part, no copy of the body — just like the subagent lens. That way every portable behavioral rule
    lives in one place (the plugin), not duplicated.
- **Subagent definitions — from the repo's own `specialists` plugin, not local.** The compact,
  executable form of a specialist (`<group>-<id>-agent.md`) is **not** kept by this repo in a local
  `.claude/agents/` directory: they come from the `specialists` plugin of this very marketplace,
  enabled via [`settings.json`](../settings.json) and invocable as `@specialists:<name>`.
- **`settings.json`** — the harness config: `extraKnownMarketplaces` (the `github` source
  `DaveKJohn/claude-code-specialists` — the repo points to itself) + `enabledPlugins`
  (`specialists@claude-code-specialists`). [Sylvester #15](lenses/05-15-extension.md)'s domain.

## How a specialist is structured

The general model — persona vs. subagent representations, the manual/agent-def split, the
portable-craft-vs-repo-lens split, and persona templates as a third artifact — is the plugin
family's concept and lives in one canonical place: the root README's
[Manuals — the split model](../../README.md#manuals--the-split-model).
This section records only how that plays out **concretely in this repo**.

### Persona or subagent — one specialist, two representations

Which specialists here are a subagent lens vs. a persona lens (lens-only), and where their files
live, is inventoried in [Layout of this directory](#layout-of-this-directory) above — not repeated
here. What follows are the rules that build on that split:

**Rules:** where both exist, the **manual is leading**; the agent def is the executable
abbreviation. The *principle* and the manuals belong to [Tessa #16](lenses/06-16-extension.md);
the agent-def config (frontmatter, tools, model) belongs to [Sylvester #15](lenses/05-15-extension.md).
**Chris remains a persona** — he is the only one who can **ask** Dave anything.
[Tessa #16](lenses/06-16-extension.md) guards the two-part manual split (portable body vs.
repo lens) on every change here.

### Stable id + group — the filename is `<group>-<id>`

Every specialist has a fixed, numeric **`id`** (permanent identity, never changes) and belongs to a
**group** (organizational unit: **01 = Leadership, 02 = Staff, 03+ = teams**). The repo layer is
named `<group>-<id>-extension.md`; the portable playbook `<group>-<id>-manual.md` and the
agent def `<group>-<id>-agent.md` live in the plugin. **Name, emoji, and title are labels** — they
may change freely; the filename and link paths hang off `id`/`group`, not the name. **The lint gate
guards this** ([Sylvester #15](lenses/05-15-extension.md)): every filename matches the
frontmatter (`id:` and `group:`).

## The team here

Small and maintenance-focused. Chris leads; the rest executes.

```
[group 01] Chris 🧭 #01  (Chief of Staff — orchestrator, persona)
│
├─ [group 03] Rebecca 🔬 #07  (research specialist)
├─ [group 04] Tycho 🧪 #18  (test engineer)
├─ [group 05] Derek 🐙 #05 (DevOps, persona) · Rendall 🎬 #06 (release, persona) · Sylvester ⚙️ #15 (system administration)
└─ [group 06] Tessa 📜 #16 (technical writer) · Edith 🔍 #17 (copy editor) · Victor 🧐 #19 (code reviewer) · Sebastian 🛡️ #23 (security engineer) · Ravi ♻️ #24 (refactoring specialist) · Nolan ⚡ #25 (performance engineer) · Marlowe 🕵️ #29 (investigative journalist)
```

## Index of the extensions present

The full roster + routing lives in [`SPECIALISTS.md`](SPECIALISTS.md#the-team-roster--routing) — the
seam's inclusion file, which `../../CLAUDE.md` imports; the list below is purely navigation to the
repo lenses themselves.

| # | Specialist | Repo lens | Agent def |
|---|---|---|---|
| 01 | Chris 🧭 — Chief of Staff | [`lenses/01-01-extension.md`](lenses/01-01-extension.md) | — (persona-only) |
| 05 | Derek 🐙 — DevOps Engineer | [`lenses/05-05-extension.md`](lenses/05-05-extension.md) | — (persona-only) |
| 06 | Rendall 🎬 — Release Manager | [`lenses/05-06-extension.md`](lenses/05-06-extension.md) | — (persona-only) |
| 07 | Rebecca 🔬 — Research Specialist | [`lenses/03-07-extension.md`](lenses/03-07-extension.md) | `@specialists:rebecca` |
| 15 | Sylvester ⚙️ — System Administrator | [`lenses/05-15-extension.md`](lenses/05-15-extension.md) | `@specialists:sylvester` |
| 16 | Tessa 📜 — Technical Writer | [`lenses/06-16-extension.md`](lenses/06-16-extension.md) | `@specialists:tessa` |
| 17 | Edith 🔍 — Copy Editor | [`lenses/06-17-extension.md`](lenses/06-17-extension.md) | `@specialists:edith` |
| 18 | Tycho 🧪 — Test Engineer | [`lenses/04-18-extension.md`](lenses/04-18-extension.md) | `@specialists:tycho` |
| 19 | Victor 🧐 — Code Reviewer | [`lenses/06-19-extension.md`](lenses/06-19-extension.md) | `@specialists:victor` |
| 23 | Sebastian 🛡️ — Security Engineer | [`lenses/06-23-extension.md`](lenses/06-23-extension.md) | `@specialists:sebastian` |
| 24 | Ravi ♻️ — Refactoring Specialist | [`lenses/06-24-extension.md`](lenses/06-24-extension.md) | `@specialists:ravi` |
| 25 | Nolan ⚡ — Performance Engineer | [`lenses/06-25-extension.md`](lenses/06-25-extension.md) | `@specialists:nolan` |
| 29 | Marlowe 🕵️ — Investigative Journalist | [`lenses/06-29-extension.md`](lenses/06-29-extension.md) | `@specialists:marlowe` |

The rest of the `specialists` plugin (Paula #09, Vera #11, Gwen #12, Cody #13, Auden #30) is also enabled and
invocable as `@specialists:<name>`, but rarely has work in this repo and therefore has no repo lens
(yet). If such work does come up, [Tessa #16](lenses/06-16-extension.md) writes the lens first.
The domain plugins `specialists-lifehub` and `specialists-shopify` are **off** here — this repo is
not a life-hub-like or Shopify repo.

## This organization changes with the team

The team and its organization come about **in consultation with Dave** and may change — exactly as
new specialists only come about by agreement (see
[Chris #01](lenses/01-01-extension.md#new-specialists--only-by-agreement)). If the organization
changes, Tessa updates this document.
