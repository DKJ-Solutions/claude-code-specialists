# .claude/specialists

The home of the **Claude Specialists** system *as this repo consumes it itself*, plus the harness it
runs in. This document is both the floor plan of this directory and the **specialists handbook** —
Chris's reference work in case of doubt. It records three things: (1) the **layout** of `.claude/`
itself; (2) **how a specialist is structured** — as persona or subagent, the two-part split of every
manual, and the stable-id system; and (3) **how the specialists here are organized among
themselves**. It is **not a replacement** for the safety rules or the routing.

> **This repo is an outlier.** claude-code-specialists is the marketplace repo of one product; the
> specialists system lives here as the plugins under `plugins/` — a stack of teams plus an opt-in
> workflow (see [`../../README.md`](../../README.md)) — and the repo also consumes that system here
> **itself**, via the `team-alpha` plugin (the core team). The team here is therefore small and focused
> on maintaining this product (agent defs, manuals, docs, tooling), not the broad team of a
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
  - **Subagent lens** — for the fifteen specialists that come out of the `team-alpha` plugin as
    subagents (the full list is in the [index below](#index-of-the-extensions-present)): only the
    `## Specific to this repo` part, which
    supplements the portable playbook in the plugin with the context of this repo. The subagent
    reads the plugin playbook + this lens together; the agent def points to both.
  - **Persona lens (lens-only)** — for the persona-only specialists (Chris, Bianca, Derek, Rendall), who run
    in the main conversation instead of as subagents. The main loop loads no plugin subagents, so the
    **portable body** comes straight from the plugin install via an `@` import: Chris always
    (`@~/.claude/plugins/marketplaces/claude-code-specialists/plugins/teams/team-alpha/personas/01-01-persona.md`,
    stated in [`SPECIALISTS.md`](SPECIALISTS.md) rather than in `CLAUDE.md` itself — the seam spends
    two of the four allowed import hops), Derek and Rendall on demand from that same path. **Bianca
    is the fourth persona and currently has no trigger**: her body would load the same way, but
    nothing in [Chris's lens](lenses/01-01-extension.md) routes an assignment to her, so in practice
    she is never read here. That is a statement of the present, not a defect to route around — this
    repo does no intake interviews. The day it does, she needs a routing row like Derek's and
    Rendall's, and until then the honest reading of the table below is "has a lens, has no caller".
    The
    extension itself is therefore **lens-only**: only the repo-specific `## Specific to this repo`
    part, no copy of the body — just like the subagent lens. That way every portable behavioral rule
    lives in one place (the plugin), not duplicated.
- **Subagent definitions — from the repo's own `team-alpha` plugin, not local.** The compact,
  executable form of a specialist (`<group>-<id>-agent.md`) is **not** kept by this repo in a local
  `.claude/agents/` directory: they come from the `team-alpha` plugin of this very marketplace,
  enabled via [`settings.json`](../settings.json) and invocable as `@team-alpha:<name>`.
- **`settings.json`** — the harness config: `extraKnownMarketplaces` (the `github` source
  `DaveKJohn/claude-code-specialists` — the repo points to itself) + `enabledPlugins`
  (`team-alpha@claude-code-specialists`). [Sylvester #15](lenses/05-15-extension.md)'s domain.

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

### Where a new rule goes — the source is the default, the lens is the exception

**This repo is the source of the specialists system, so a lesson learned here belongs in the shared
source unless it genuinely only applies here** (Dave, August 4, 2026). The lens exists for what a
*consumer* would have to differ on — not as the convenient place to write things down because it is the
file already open. Writing a portable rule into the lens is how the source ends up thinner than the repo
that maintains it: measured that day, Rendall #06's portable persona was **1,700 bytes** while his repo
lens had grown to **26,914** — sixteen times larger, holding the release craft itself rather than
anything specific to this repo.

**Which of the three layers a rule belongs in follows from what the layer already carries**, a
convention the repo has held consistently rather than one invented here. Re-measured **August 15,
2026** across `team-alpha`'s **15 manuals, 4 personas and 4 skills** — count each category with
`grep -rho` over `manuals/`, `personas/` and `skills/`, and the table reproduces:

| layer | holds | repo-specific detail (measured) |
|---|---|---|
| **persona / manual** | the craft itself, stated timelessly | **none** across all 19 files — 0 issue numbers, 0 repo names, 0 person names. The one `vX.Y.Z` a regex finds is Rendall's *"How he sounds"* line, an invented example of speech rather than a real version |
| **skill** | a procedure, with the evidence that shaped it | **yes** — **250** such references across the 4 skills (137 issue numbers, 93 repo names, 15 versions, 5 person names), e.g. a measured character limit attributed to the consumer repo it was hit in |
| **repo lens** | what this repo does differently, and the local measurement | yes |

**The previous figures are kept here as the thing that went wrong, because the failure is instructive**:
this table read *"14 manuals, 4 personas and 9 skills"* and *"103 references across the 9 skills"*, and
by August 15 none of the three counts held — a manual had been added, and the August 8 workflow split
had moved nine of `team-alpha`'s skills into `contributing-davekjohn`, leaving four. **`CLAUDE.md` points at
this table as the evidence for the whole source-vs-lens doctrine**, so a reader who checked it found the
numbers wrong and had no way to tell whether the doctrine was wrong with them. The claim itself was
false too, by exactly two person names — both now moved to the lens that should have held them, which
is the convention this table describes, applied to itself.

**A measurement in a document that nothing regenerates goes stale silently.** State the date and the
method, as above, so the next reader can re-run it in one command instead of trusting it.

So the practical test for a lesson learned: **is it a timeless statement about the craft** → persona or
manual, stripped of every number. **Is it a procedure step someone will walk, whose reason rests on a
measurement** → the skill, measurement included; that is why the skills carry evidence and the manuals
do not. **Is it only true here** → the lens. When the same rule has both a portable half and a local
half, split it: the rule and its generic reason go to the source, and the lens keeps a short citation
naming where it was measured.

**A consequence worth knowing before you reach for the lens out of habit:** a rule written in the source
reaches every consumer through the next release, while the same rule in the lens reaches nobody but this
repo — and the two are indistinguishable while you are typing.

### Stable id + group — the filename is `<group>-<id>`

Every specialist has a fixed, numeric **`id`** (permanent identity, never changes) and belongs to a
**group** (organizational unit: **01 = Leadership, 02 = Staff, 03+ = teams**). The repo layer is
named `<group>-<id>-extension.md`; the portable playbook `<group>-<id>-manual.md` and the
agent def `<group>-<id>-agent.md` live in the plugin. **Name, emoji, and title are labels** — they
may change freely; the filename and link paths hang off `id`/`group`, not the name. **The lint gate
guards this** ([Sylvester #15](lenses/05-15-extension.md)): every filename matches the
frontmatter (`id:` and `group:`).

**So a rename never breaks a reference — it only leaves the name behind in prose**, and
[`scripts/sync/find-specialist-mentions.ps1`](../../scripts/sync/find-specialist-mentions.ps1) is the
tool for that half. Run it bare for the overview (which rename is cheap and which is not), or with
`-Name <specialist>` for every live mention grouped by the layer it sits in: **context** (read by a
model each session), **docs** (read by a human on GitHub), **scripts** and **tests** (where the one
rename this repo has done deliberately *kept* the old name as attribution), and **history** (counted,
never rewritten — the published-record rule). It also splits each layer into **link text** and
**prose**, because those are two different decisions: the link target already carries the id, so the
text beside it is reading aid, while a name in prose is the content itself.

**It is a tool, not a gate, and that was decided rather than defaulted into** (August 13, 2026). A
check matching on names is the shape this repo has already been bitten by — the name-matching
candidate measured for the entry-format check produced six findings, all six false. Worse, Sean →
Sebastian (`a437df9`, July 22, 2026) deliberately left mentions standing, so a gate would need an
exemption list holding exactly what that rename decided to keep. **A gate that is argued with is a
gate that gets switched off.** This one prints; the reader decides.

**The measurement that made it worth building:** a rename's cost is not uniform. Measured with the
script itself, against the tree as it stood before the branch that added it, Chris had **179** live
mentions across 59 files against Sebastian's **46** across 18 — a factor of four. Nothing before this
could tell you that number *before* you started.

**The same pass answered the question that prompted it**, which was whether the name in a link should
become the id (`[#16]`) or the filename (`[06-16-extension]`) so a rename would need no edit there.
Three measurements against that same tree said no:

| | |
|---|---|
| link text is a small share | **97 of 1,291** live mentions — 7.5%, so it reaches a fourteenth of the problem |
| `#16` is already taken | **2,404** `#nnn` references outside `releases/` and `CHANGELOG.md`; `#12` is both Gwen and a PR number |
| the filename form costs more | 88 link texts of the form `[Name #NN]` average **10.3** characters against 15 for `<gg>-<ii>-extension` — **+46%**, in files loaded every session |

And roughly a quarter of those link texts are grammatically part of the sentence
(`[Rendall #06](…)'s domain`, `[Tessa #16](…) guards the split`), where a bare id or filename reads as
a file doing a person's work.

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

**This tree is who has work here, not who is available.** Six more arrive with the plugin, whose
crafts this maintenance repo rarely calls on. They are in the index below with their lenses — but
they are not reachable the same way, and the difference is worth knowing before you type a name:

- **Invocable today as subagents** — Paula 📅 #09, Vera 📊 #11, Gwen 🎨 #12, Cody 💻 #13 and
  Auden 🖋️ #30. Each ships an agent def, so `@team-alpha:<name>` reaches them.
- **Not invocable** — Bianca 🎙️ #02, who ships as a **persona** (`personas/03-02-persona.md`, no
  agent def). Personas run in the main conversation, and the only one loaded here is Chris; Derek and
  Rendall are read on demand when work reaches them. Nothing reaches Bianca — see the persona-lens
  note above.

## Index of the extensions present

The full roster + routing lives in [`SPECIALISTS.md`](SPECIALISTS.md#the-team-roster--routing) — the
seam's inclusion file, which `../../CLAUDE.md` imports; the list below is purely navigation to the
repo lenses themselves.

**Every specialist the enabled plugin ships has a lens file**, so this table is complete. A lens marked
*scaffold* is an empty `VUL-IN` template waiting for that specialist's first work here — **the intended
state, not a backlog item**, exactly as
[`SPECIALISTS.md`](SPECIALISTS.md#the-team-roster--routing) states it.

| # | Specialist | Repo lens | Agent def |
|---|---|---|---|
| 01 | Chris 🧭 — Chief of Staff | [`lenses/01-01-extension.md`](lenses/01-01-extension.md) | — (persona-only) |
| 02 | Bianca 🎙️ — Biographer | [`lenses/03-02-extension.md`](lenses/03-02-extension.md) *(scaffold)* | — (persona-only) |
| 05 | Derek 🐙 — DevOps Engineer | [`lenses/05-05-extension.md`](lenses/05-05-extension.md) | — (persona-only) |
| 06 | Rendall 🎬 — Release Manager | [`lenses/05-06-extension.md`](lenses/05-06-extension.md) | — (persona-only) |
| 07 | Rebecca 🔬 — Research Specialist | [`lenses/03-07-extension.md`](lenses/03-07-extension.md) | `@team-alpha:rebecca` |
| 09 | Paula 📅 — Project Planner | [`lenses/02-09-extension.md`](lenses/02-09-extension.md) *(scaffold)* | `@team-alpha:paula` |
| 11 | Vera 📊 — Data Analyst | [`lenses/04-11-extension.md`](lenses/04-11-extension.md) *(scaffold)* | `@team-alpha:vera` |
| 12 | Gwen 🎨 — Graphic & Front-end Designer | [`lenses/04-12-extension.md`](lenses/04-12-extension.md) *(scaffold)* | `@team-alpha:gwen` |
| 13 | Cody 💻 — App Developer | [`lenses/04-13-extension.md`](lenses/04-13-extension.md) *(scaffold)* | `@team-alpha:cody` |
| 15 | Sylvester ⚙️ — System Administrator | [`lenses/05-15-extension.md`](lenses/05-15-extension.md) | `@team-alpha:sylvester` |
| 16 | Tessa 📜 — Technical Writer | [`lenses/06-16-extension.md`](lenses/06-16-extension.md) | `@team-alpha:tessa` |
| 17 | Edith 🔍 — Copy Editor | [`lenses/06-17-extension.md`](lenses/06-17-extension.md) | `@team-alpha:edith` |
| 18 | Tycho 🧪 — Test Engineer | [`lenses/04-18-extension.md`](lenses/04-18-extension.md) | `@team-alpha:tycho` |
| 19 | Victor 🧐 — Code Reviewer | [`lenses/06-19-extension.md`](lenses/06-19-extension.md) | `@team-alpha:victor` |
| 23 | Sebastian 🛡️ — Security Engineer | [`lenses/06-23-extension.md`](lenses/06-23-extension.md) | `@team-alpha:sebastian` |
| 24 | Ravi ♻️ — Refactoring Specialist | [`lenses/06-24-extension.md`](lenses/06-24-extension.md) | `@team-alpha:ravi` |
| 25 | Nolan ⚡ — Performance Engineer | [`lenses/06-25-extension.md`](lenses/06-25-extension.md) | `@team-alpha:nolan` |
| 29 | Marlowe 🕵️ — Investigative Journalist | [`lenses/06-29-extension.md`](lenses/06-29-extension.md) | `@team-alpha:marlowe` |
| 30 | Auden 🖋️ — Academic & Long-form Writer | [`lenses/06-30-extension.md`](lenses/06-30-extension.md) *(scaffold)* | `@team-alpha:auden` |

The six scaffolds mark specialists who rarely have work in this maintenance repo — Bianca's intake
interviews, Paula's timelines, Vera's dashboards, Gwen's visuals, Cody's application code, Auden's
long-form writing. On the day one of them first has work here,
[Tessa #16](lenses/06-16-extension.md) fills the lens in before that specialist is deployed.
The add-on teams `team-lifehub` and `team-shopify` are **off** here — this repo is
not a life-hub-like or Shopify repo.

## This organization changes with the team

The team and its organization come about **in consultation with Dave** and may change — exactly as
new specialists only come about by agreement (see
[Chris #01](lenses/01-01-extension.md#new-specialists--only-by-agreement)). If the organization
changes, Tessa updates this document.
