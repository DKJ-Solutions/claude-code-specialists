# claude-specialists — the specialists family

The first product family of [davekjohns-workshop](../../README.md): the **Claude Specialists system**,
designed by Dave (DaveKJohn). Instead of one generic Claude, you work with a **team of specialized
Claudes** under one Chief of Staff: every assignment is classified and delivered to the specialist
(subagent) with the right playbook — a DevOps engineer for branches and PRs, a technical writer
for docs, a copy editor for the final pass, and so on.

This directory contains **four plugins** that together make up that system. A consuming repo
enables or disables them **individually** via the marketplace.

## The four sub-plugins — what's the difference?

| Plugin | What it is | Who it's for |
|---|---|---|
| [`specialists/`](specialists/) | **The shared core (group 1).** Eleven repo-neutral specialists who work the same way in *every* repo (research, systems administration, technical writing, copy editing, code review, security review, and testing, among others). Also carries the persona templates of the main loop (Chris/Derek/Rendall) and the bootstrap skill `specialists-init`. | **Every** consuming repo — this is the foundation, always enable it. |
| [`specialists-lifehub/`](specialists-lifehub/) | **Domain group 2.** Five specialists for a personal information hub / brain-based knowledge repo (Astrid, Fiona, Hugo, Ian, Onyx). Deliberately domain-flavored: they know their repo and teammates by name. | Only a life-hub-style repo. |
| [`specialists-shopify/`](specialists-shopify/) | **Domain group 3.** Three specialists for a Shopify store repo (Liam · Liquid, Sandra · store management, Steven · configuration) plus the domain skill `start-task`. Also deliberately domain-flavored. | Only a Shopify repo (e.g. smartwatchbanden). |
| [`specialists-ecomm/`](specialists-ecomm/) | **Domain group 4.** E-commerce specialists for a commercial webshop repo of any platform (Sergio · SEO, Craig · CRO, Sean · performance/SEA). Platform-agnostic, and complementary to a platform group rather than exclusive. | Any commercial webshop repo — including a Shopify repo alongside `specialists-shopify`. |

In short: **`specialists` is the foundation; the other three are optional domain extensions.**
`specialists-lifehub` and `specialists-shopify` describe what *kind* of repo it is, so a repo
enables at most one of those; `specialists-ecomm` is orthogonal — it applies to any commercial
webshop regardless of platform, so a webshop repo can enable it *on top of* a platform group (a
Shopify store repo, for instance, enables both `specialists-shopify` and `specialists-ecomm`). The
core is written repo-neutrally (no repo names, paths, or script names — that context comes from the
consumer's repo lens); the domain groups name their domain explicitly, because only a matching repo
enables them.

### The e-commerce-related plugins

Two of the four plugins serve a **commercial webshop** and are built to work together:

- **`specialists-shopify`** — the *platform* layer: theme code, store management, configuration for a Shopify store.
- **`specialists-ecomm`** — the platform-agnostic *disciplines* that any webshop needs: SEO, CRO, and performance/SEA.

They sit on different axes — one is "which platform," the other is "which marketing disciplines" — so they complement rather than replace each other. A **Shopify** store repo typically enables **both**; a **non-Shopify** webshop enables just `specialists-ecomm`. The other two plugins — `specialists` (the core) and `specialists-lifehub` — fall outside this e-commerce grouping. This is a reading aid, not a packaging change: every plugin is still enabled or disabled on its own.

## Manuals — the split model

Every specialist in these plugins is built from up to three files, physically split by audience and
by what's portable versus repo-specific: the **manual** (the portable playbook, split from the repo
lens), the **agent def** (the executable abbreviation), and — for the main-loop specialists only —
a **persona template**.

### The manual: portable craft + repo lens

A specialist handbook splits into a **portable** part (repo-neutral, identical in every repo: the
craft, the hard rules, the tone) and a **repo lens** (the `## Specific to this repo` part: which
content/context of that repo the specialist serves). The portable part lives in
`<plugin>/manuals/<group>-<id>-manual.md` in this marketplace; the consuming repo keeps only the
lens in `.claude/plugins/claude-specialists/specialists/<group>-<id>-extension.md`. The agent def points to both.

**All four groups have now been migrated** — every handbook lives here in the `manuals/` folder of
its plugin, and every consuming repo keeps only its repo lens in `.claude/plugins/claude-specialists/specialists/`:

- **`specialists` (group 1)** → `specialists/manuals/` (Paula, Rebecca, Vera, Gwen, Cody, Tycho,
  Sylvester, Tessa, Edith, Victor, Sebastian, Ravi, Nolan, Marlowe, Auden).
- **`specialists-lifehub` (group 2)** → `specialists-lifehub/manuals/` (Astrid, Fiona, Hugo, Ian, Onyx).
- **`specialists-shopify` (group 3)** → `specialists-shopify/manuals/` (Liam, Sandra, Steven).
- **`specialists-ecomm` (group 4)** → `specialists-ecomm/manuals/` (Sergio, Craig, Sean).

### Agent def vs. manual — two files, one specialist

Every specialist in these plugins consists of two files, each with its own job:

- **`agents/<group>-<id>-agent.md` — the agent definition**, the executable form. The frontmatter
  (`name`, `description`, `tools`, `model`) is what Claude Code reads to register the subagent;
  the `description` is also the routing signal the main loop uses to pick a subagent. The body is
  deliberately just a compact operational core (working method, boundaries, deliverable format) and
  refers to the playbook for the actual craft.
- **`manuals/<group>-<id>-manual.md` — the playbook**, the full description of the craft: the
  hard rules, the trade-offs behind them, and the personality & tone. It is read on demand — by the
  subagent itself when in doubt, and by the main loop (the orchestrator that assigns the work and
  the personas that are not subagents).

**The manual is leading; the agent def is the executable abbreviation.** You change a craft rule in
the manual; you only touch the agent def when the operational core or the tool set changes. The two
are kept deliberately separate: they serve different readers (the harness vs. humans and the main
loop), the router-critical `description` and tool set should not sway along with every textual
refinement, and the portable-vs-repo-lens model above relies on manuals as standalone, lintable
documents. Moreover, the manual format is the common denominator across the whole team: the
persona-only specialists (Chris, Derek, Rendall) have no agent def, but do have a full playbook as a
template in `personas/` (see below).

### Persona templates — a third artifact alongside agent def and manual

The orchestrator and the main-loop specialists (Chris #01, Bianca #02, Derek #05, Rendall #06) run in
the **main loop**, not as subagents — a plugin cannot inject always-on main-loop context, and an
intake conversation moreover requires direct back-and-forth with the client. They therefore
deliberately have **no** agent def; their portable source lives in
`specialists/personas/<group>-<id>-persona.md` as a **self-contained template** (portable body + a
repo-lens placeholder). The consumer loads the **portable body straight from the plugin install**
via an `@` import in its `CLAUDE.md` (the orchestrator always, the other personas on demand). The
local extension `.claude/plugins/claude-specialists/specialists/<group>-<id>-extension.md` is
therefore **lens-only**: only the repo-specific `## Specific to this repo` part, no body copy. The
drift lint (see the [connectors README](connectors/README.md#maintenance-drift-lint)) recognizes
such a lens-only extension and reports it as `LENS-ONLY`. The lint's agent-def↔manual coupling
deliberately leaves personas alone (they have no agent def).

## Shared agent-def blocks — one source for the verbatim boundaries

A number of bullets in the **Boundaries** section are word-for-word identical across
many agent defs — the **inbound rule** and the **automation-first rule** even across all 26 (every
agent def in every plugin). Such governance belongs *in* the
agent-def body (always loaded, also for a directly invoked worker subagent), but Claude Code has no
native transclusion in an agent def — what's written there is there, literally. To still maintain
those blocks in **one place** instead of in every agent def, a **build-and-lint** model applies:

- The canonical text of each shared block lives in `agent-shared/<name>.md` (a sibling of the plugin
  folders in this directory).
- In an agent def the block appears between sentinels:
  `<!-- BEGIN shared:<name> … -->` … `<!-- END shared:<name> -->`. The content really is there (self-contained), but is marked as generated.
- **Never edit between the sentinels.** Change the source file and run
  [`scripts/agents/build-agent-defs.ps1`](../../scripts/agents/build-agent-defs.ps1) — all agent defs
  carrying the block are updated. The lint gate
  ([`check-plugin-integrity.ps1`](../../scripts/lint/check-plugin-integrity.ps1), check 7) fails as
  soon as a marked region deviates from its source (a hand edit or a forgotten rebuild), just like
  the drift lint for consumers.

Current blocks — one canonical source file each under `agent-shared/`, so the directory listing is
always the up-to-date enumeration: `inbound-behaviour`, `laziness-automation`, `language-behavior`,
`no-conversation-history`, `no-commit-push-pr`, `browser-compatibility`, `webcontent-boundary`,
`changelog-entry-boundary`, `design-owner-boundary`, `storefront-preview-boundary`, and
`artifact-publishing-boundary`. This way changing a shared boundary costs one edit + one build, not a
manual change in every agent def that carries it.

## Marking a complete skill enumeration

The skill set is spread across several plugin folders, which makes "list/count all skills" a
recurring way for prose to drift out of sync. The same sentinel idea as the shared agent-def blocks
above applies here, one level lighter: an author who writes a prose enumeration that is meant to be
**the complete skill set** wraps it in a BEGIN/END HTML-comment marker:

```
<!-- skills:all -->
- `skill-name`
...
<!-- /skills:all -->
```

and the lint gate ([`check-plugin-integrity.ps1`](../../scripts/lint/check-plugin-integrity.ps1),
check 10) then verifies the span's backtick-quoted names against the real skill set on every run.
Three rules govern when and how to reach for it:

- **Wrap tightly.** The extraction is character-based (so the sentinels may sit inline, mid-sentence,
  not just around a standalone bullet list as shown above), but *every* backtick-quoted term inside
  the span counts as a claimed skill name — so the span must close around just the skill names,
  nothing else in backticks.
- **Only for a genuinely complete enumeration.** A deliberately partial or illustrative list (e.g.
  QUICKSTART.md's slash-only subset) gets no marker — marking it would turn an intentional subset
  into a permanent false positive.
- **Showing the syntax literally needs a fence, not inline code.** The check masks fenced code
  blocks before it looks for markers, precisely so a paragraph like this one can show the literal
  syntax without being misread as a real span (as happened once during development). A single pair of
  backticks does *not* get that treatment — a claimed skill name inside a real span is itself
  backtick-delimited, so there is no way to tell "this is an example" apart from "this is a claimed
  name" in inline code. A fence is the only safe way to display the marker literally.

This is opt-in, not a generic prose scan: a doc with zero spans passes silently. See the check's
docstring in `check-plugin-integrity.ps1` for the full mechanics.

## Where this runs: Chat, Cowork, and Claude Code

Anthropic's Claude product has three relevant surfaces: **Chat** (a conversation), **Cowork** (a
working-session mode — desktop generally available, web/mobile in beta as of July 2026 — for
non-code knowledge work, positioned alongside Claude Code, which stays the tool for software
engineering), and **Claude Code** itself. See
[claude.com/product/cowork](https://claude.com/product/cowork) for Cowork's own positioning. This
matters operationally for the skills/subagents/hooks split described in the root README's
[What lives here and what doesn't](../../README.md#what-lives-here-and-what-doesnt): a **skill**
bundled in a plugin works across all three surfaces, but a **subagent** or a **hook** runs only in
Cowork and in Claude Code — in a plain Claude.ai Chat session they show up grayed out (see
[Use plugins in Claude](https://support.claude.com/en/articles/13837440-use-plugins-in-claude)).
Concretely for davekjohns-workshop: the specialists roster (the subagents under Chris) and the three
SessionStart hooks (`connector-sessioncheck`, `roster-sessioncheck`, `script-contract-sessioncheck`)
function in Claude Code and in Cowork, but not in a plain Claude.ai Chat session — only the skills
<!-- skills:all -->(`fold-changelog`, `open-pr`, `new-branch`, `park`, `specialists-init`, `sync-roster`, `start-task`,
`cut-release`)<!-- /skills:all --> remain available there.

Skills themselves are Anthropic's general **Agent Skills** mechanism — organized folders of
instructions/scripts/resources that an agent discovers and loads progressively (name + description
always loaded, the `SKILL.md` body only on trigger, other resources on demand) — exactly what
davekjohns-workshop already uses to distribute its skills via the marketplace (see the
[Anthropic engineering post](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
and the [docs](https://code.claude.com/docs/en/skills)). Not confirmed: whether Cowork runs on the
Claude Agent SDK, or whether a Cowork subagent shares its definition format with — or is
interchangeable with — a Claude Code subagent.

## How we use skills — and what we deliberately don't

<!-- skills:all -->Most skills in davekjohns-workshop today (`fold-changelog`, `open-pr`, `new-branch`, `park`,
`specialists-init`, `sync-roster`, `start-task`) are a thin wrapper around a script — procedural
**mechanism** (branch, PR, fold, bootstrap, roster-sync). `cut-release`<!-- /skills:all --> is the deliberate exception:
a checklist with no script of its own (see below). Either way, the specialists' craft and judgment
live in the persona/manual context (agent defs), not in skills. That's a deliberate split, but it
also means we currently use only one half of what Agent Skills can carry.

The unused half is a noted opportunity, not an open task: of the three progressive-disclosure levels
described in [Where this runs](#where-this-runs-chat-cowork-and-claude-code) above, none of our
skills use level 3 (bundled reference material/templates/examples) — all of them sit at level 1/2. A
repeatable specialist *procedure* — a review or copy-edit checklist, for instance — could become a
knowledge-skill with bundled reference material, which would then work on every surface, including a
plain Chat session where subagents and hooks are unavailable.

That doesn't mean maximizing skill usage everywhere. The discipline is: add a skill only where it
makes a repeatable procedure or piece of knowledge genuinely portable, and where that value covers
the maintenance cost. Living example: `cut-release` shows both sides of that discipline at once. Its
**script**, `scripts/release/cut-release.ps1`, stays workshop-only and is deliberately not mirrored —
marketplace-specific machinery that reads `.claude-plugin/marketplace.json` as the source of truth
for what a plugin is and bumps every `plugin.json` it lists in lockstep, a structure only this
marketplace has (see the "out of scope" note in
[`scripts/sync/check-script-contract.ps1`](../../scripts/sync/check-script-contract.ps1)). Its
**procedure** — the closing steps every release shares once the version bump is committed (tag +
push, branch cleanup) — was genuinely portable, so it shipped as the `cut-release` **skill**
instead: a checklist with no script of its own (issue #177). That checklist also covers a
Minor/Major GitHub Release, with its highlights-as-body/notes-as-attachment split — a manual
closing step this workshop's own Minor/Major releases go through too (see
[releases/README.md](../../releases/README.md#cutting-a-release)), just not one `cut-release.ps1`
itself automates.

Cowork is positioned for non-code knowledge work; davekjohns-workshop is a code/plugin-maintenance
repo, so Claude Code is the right tool here and the repo stays deliberately Claude-Code-centric.
Cowork's value sits in other, non-code work — not in this workshop.

## Invocation

Once enabled, the specialists can be invoked with the **plugin name as namespace**:
`@specialists:<name>`, `@specialists-lifehub:<name>`, `@specialists-shopify:<name>`, or `@specialists-ecomm:<name>`.

## Which release am I on?

Every plugin folder carries a `RELEASE.md` card (version, a one-line summary, and the entries for
that version) right next to its `CHANGELOG.md`. It travels with the plugin cache, so once
`claude plugin update` has pinned your install to a version, the cached copy of `RELEASE.md` is
exactly that release — open it under the plugin path in your own cache to see which one you're on.
See [Consumption](../../README.md#consumption) in the root README for the mechanics.

A newly added **skill** additionally needs a session restart before it becomes visible, and the
skill counters `/reload-plugins`/`/reload-skills` print are not reliable evidence either way — see
[Staying up to date](QUICKSTART.md#staying-up-to-date) in the Quickstart for the full detail.

## Adoption: the bootstrap path

> **New here?** The shareable beginner route is in the
> [Quickstart](QUICKSTART.md) — get connected in three steps,
> for those who didn't build the system. Below is the underlying explanation.

Enabling the plugin delivers the **worker subagents**, but not the **conductor** (Chris) or the
governance/hooks layer — those cannot come from a plugin (a plugin injects no
main-loop context and edits no `CLAUDE.md`). The skill **`specialists-init`** (group 1) closes that
gap in a consuming repo. Because a plugin skill cannot hook itself in, the path is
two-stage:

- **Step 0 (manual).** Put the marketplace source + `enabledPlugins` in `.claude/settings.json`
  (see [Consumption](../../README.md#consumption) in the root README) and **restart** the session —
  only then is the skill available.
- **Step 1 (the skill).** Invoke `specialists-init`. The bundled
  [`bootstrap.ps1`](specialists/skills/specialists-init/bootstrap.ps1) performs only **additive**
  actions: it copies the persona templates to `.claude/plugins/claude-specialists/specialists/<group>-<id>-extension.md`
  (never overwriting), places an **empty lens scaffold** for every subagent of the enabled
  plugin(s) (`VUL-IN` — the spot where repo-specific tasks per specialist are
  filled in), adds the `@.claude/plugins/claude-specialists/specialists/01-01-extension.md` import at the bottom of `CLAUDE.md`
  (or creates a scaffold), and writes a `settings.suggested.jsonc` with a `permissions.deny` +
  hooks **stub**. It does not touch `settings.json` — that merge and filling in the repo lens are
  manual work afterwards (repo-specific), after which one more **restart** activates the new context.

## Adding a new plugin group

A domain group is its own plugin folder — but adding one touches more than that folder. The drift
lint and the family docs enumerate the plugins and go stale silently if you forget them. The full
checklist (learned from adding `specialists-ecomm`):

1. **The plugin folder** `<plugin>/` (a sibling of this README, directly under
   `claude-code-plugins/claude-specialists/`) with `.claude-plugin/plugin.json` (the lockstep
   `version`, matching the other plugins), a `CHANGELOG.md` intro, and a `RELEASE.md` card whose
   `# Release vX.Y.Z` heading matches `plugin.json` (lint check 9).
2. **The marketplace entry** — register the plugin in
   [`.claude-plugin/marketplace.json`](../../.claude-plugin/marketplace.json) with a repo-relative
   `source`.
3. **The specialists** — `agents/<group>-<id>-agent.md` + `manuals/<group>-<id>-manual.md` per
   member, following the `<group>-<id>` convention (a globally unique `id`).
4. **The drift lint** — add the plugin's `agents` folder to `$SourceDirs` in
   [`scripts/lint/check-consumer-drift.ps1`](../../scripts/lint/check-consumer-drift.ps1), or a
   consumer's drift check never covers the new ids.
5. **The family docs** that enumerate the plugins — the workshop's
   [root `README.md`](../../README.md) (the plugin count + the family bullet), this family README
   (the manuals list above, the sub-plugins table, the invocation list, and whether the group is
   mutually exclusive with the others or complementary), and [`QUICKSTART.md`](QUICKSTART.md).
6. **The gates** — `scripts/agents/build-agent-defs.ps1 -Check`,
   [`scripts/lint/check-plugin-integrity.ps1`](../../scripts/lint/check-plugin-integrity.ps1), and
   the `scripts/tests/*.tests.ps1` suites, all green.

## Want to know more?

**Connecting your own repo?** Follow the [Quickstart](QUICKSTART.md) — connect in three steps, for
those who didn't build the system.

How a repo consumes these plugins (marketplace source, `enabledPlugins`) is covered in the
workshop's [root README](../../README.md), which also holds the marketplace-wide `RELEASE.md`/
channel facts under [Consumption](../../README.md#consumption) and the full versioning/release
mechanics in [`releases/README.md`](../../releases/README.md).
