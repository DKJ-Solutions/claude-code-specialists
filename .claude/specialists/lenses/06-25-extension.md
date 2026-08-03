---
id: 25
group: 06
---

# Nolan ⚡ · claude-code-specialists addendum

> Repo-lens (claude-code-specialists) accompanying the portable playbook in the `specialists` plugin (`claude-code-plugins/claude-specialists/specialists/manuals/06-25-manual.md`). This file does not describe the craft, but what Nolan measures in this repo and with whom he works.

A performance engineer does the same thing everywhere — measure resource cost and trim it without
losing function. **What is repo-specific in claude-code-specialists is not that Nolan measures, but
which loading chains and docs fall under him here, and the mechanism already in place that gives
him levers to pull.**

### What Nolan measures here

- **The deliberate loading strategy** described in
  [`CLAUDE.md`](../SPECIALISTS.md#the-claude-specialists--who-does-what): only Chris's operating
  manual loads automatically (via the `@` import at the bottom of `CLAUDE.md`, because he is
  involved in every assignment); every other specialist's portable playbook + repo lens is read
  **on demand**, at the moment Chris assigns work to them — "deliberate, to save context/tokens".
  Nolan checks whether that boundary still holds as the roster grows: does a new persona/subagent
  stay on-demand, or has something crept onto the automatic path that doesn't need to be there?
- **The size of agent-defs, manuals, and personas** across the plugins
  (`claude-code-plugins/claude-specialists/*/agents/*-agent.md`, `*/manuals/*-manual.md`,
  `specialists/personas/*-persona.md`): a manual/agent-def that has grown well past what its craft
  needs is a cost on every load, not a one-time read.
- **The `agent-shared/` mechanism** (see [Sylvester #15](05-15-extension.md) and
  [Ravi #24](06-24-extension.md)) as a *frugality lever*, not just a DRY tool: a rule that lives once
  in `agent-shared/<name>.md` and is filled into N agent-defs by the generator costs one edit instead
  of N, and Nolan can point to it as evidence when a savings proposal is "promote this to a shared
  block" rather than "trim this in each of the N places separately".
- **Repeated context across a chain**: whether a multi-specialist chain (see
  [Chris #01](01-01-extension.md#chains-multiple-specialists-in-sequence)) re-reads the same doc
  more than once where a single, targeted read would do.

### How to measure it — `claude plugin details` (July 28, 2026)

There is an authoritative measurement; do not estimate from file sizes:

```powershell
claude plugin details specialists@claude-code-specialists
```

It reports **Always-on** (tokens the plugin adds to *every* session through its listing text — skill
descriptions, agent descriptions, command names, whether or not anything fires) and **On-invoke** per
component, computed via the `count_tokens` API for the active model. The baseline measured at v2.10.0:

| | tokens |
|---|---|
| Plugin total, always-on | **~3.505** |
| — 15 agent descriptions | ~2.260 |
| — 7 skill descriptions | ~1.245 |
| SessionStart hook | 0 — reported as *"harness-only — no model context cost"* |

**The finding this produced, and the reason it is written down.** The `CLAUDE.md` roster used to spell
out all 15 subagents with their descriptions. Those descriptions are **already** in every session — the
~2.260 above — so the table was paying twice for the same information. Removing them shrank `CLAUDE.md`
by 2.799 characters, **~750 tokens per session**.

Be precise about that second number's provenance: `claude plugin details` uses the `count_tokens` API,
but it only measures *plugins*. A `CLAUDE.md` delta has no such command, so ~750 is a character-based
estimate — good enough to decide by, not a measured figure like the ~2.260. The first attempt landed at
~660 because the explanation that had to replace the rows was written *into* `CLAUDE.md`, which is
loaded every session; moving it into this lens (read only when Nolan is called in) recovered the rest.
That is the general lever: **the justification for a trim does not belong on the always-on path.**

Two things that make this generalizable rather than a one-off:

- **Personas are the opposite case.** Only *agents* appear in the always-on listing. The four
  persona-only specialists (Chris, Bianca, Derek, Rendall) appear in none, so the roster table is the
  only place they exist for a session — their rows are not duplication and must stay. Any future
  trimming has to keep that asymmetry.
- **The check constrains the shape of the trim.** `check-roster-sync` scans the roster text for each
  `<group>-<id>` token, so the ids have to stay present even when the prose goes. Dropping the rows
  entirely would have produced 15 false "no roster row" errors. Hence: keep a compact id line, drop the
  descriptions — a trim that needed no change to any shared script.

### Chris's always-on path — measured, verdict: leave it alone (July 28, 2026)

The open question from the roster trim, now answered. `CLAUDE.md` `@`-imports two files, so three
documents load in full on every session:

| always-on | characters | ~tokens |
|---|---|---|
| `CLAUDE.md` | 24.388 | ~6.600 |
| Chris's portable body (`personas/01-01-persona.md`) | 6.628 | ~1.800 |
| Chris's repo lens (`01-01-extension.md`) | 12.274 | ~3.300 |
| **documents total** | **43.290** | **~11.700** |
| plus the plugin listing (`claude plugin details`) | | ~3.505 |

So roughly **~15.200 tokens are spent before a single assignment is given.** Chris's lens, at ~3.300,
is the largest single specialist file in the repo and the only one on the automatic path.

Broken down by section: routing table 3.023 chars · chains 2.784 · gatekeepers 2.250 · Dave rules
1.589 · new-specialists 945 · intro 897.

**The verdict is that there is no free win here, and that is worth recording** — the roster case made
this look like the same kind of target, and it is not. Two traps, both hit while measuring:

- **The routing table's "Repo lens" column looks like duplication and is not.** Thirteen links of an
  apparently uniform `<g>-<id>-extension.md` shape, so the obvious trim is to state the pattern once and
  drop the column. That breaks it: the group prefix is **not** derivable from the display number.
  Derek #05 is `05-05`, but Rebecca #07 is `03-07`, Rendall #06 is `05-06` and Tycho #18 is `04-18`. That
  column is the only always-on place the group lives. Do not remove it.
- **The gatekeepers section restates safety rules `CLAUDE.md` already carries in full**, both always-on
  — the one genuinely reducible ~600 tokens. But it is deliberate reinforcement at the point of use, and
  Claude Code's own guidance is explicit that instructions are context rather than enforced
  configuration, so *how* they are written affects how reliably they are followed. Cutting it therefore
  trades tokens for adherence. That is a different kind of decision than removing a description that was
  already in context twice.
  **DECIDED (July 29, 2026): keep it. Do not revisit this as a token saving.** Dave deferred the call
  until after the trim; the trim happened (`CLAUDE.md` 328 → 282 lines, the language detail
  path-scoped), and the same session produced the evidence that settles it. The session-reply language
  rule sits in `CLAUDE.md`, always-on, never compacted away — and it was **broken anyway**, for an entire
  session, until Dave pointed it out. So always-on presence demonstrably does *not* guarantee adherence.
  That cuts one way: a second statement at the point of use is not redundancy, it is the second chance
  that the first statement measurably needs, and ~600 tokens is a cheap price for one. The reducible
  tokens are real; the thing they buy is more valuable. Reversible in one PR if Dave disagrees.

**The lever this leaves.** Reduce cost by moving content *off* the automatic path rather than deleting
it: `CLAUDE.md` at ~6.600 tokens is the biggest item and was 277 lines against the documented target of
under 200, and path-scoped `.claude/rules/` files load only when Claude touches matching files. That is
the direction with room in it — not Chris's lens.

### `.claude/rules/` — the verified rules of the lever (July 29, 2026)

The lever above rests on a claim that was **unverified** when it was written. It has now been checked
against the docs, and the answer constrains it in a way worth knowing *before* moving anything:

| at `/compact` | what happens |
|---|---|
| project-root `CLAUDE.md` and rules **without** `paths:` | re-injected from disk |
| rules **with** `paths:` frontmatter | **lost until a matching file is read again** |

Two consequences, and together they define the whole trade:

- **A rule without `paths:` saves nothing.** It loads unconditionally with the same priority as
  `CLAUDE.md`, so relocating text there is filing, not trimming. **The scoping is the saving** — if a
  candidate cannot be given a `paths:` list, it is not a candidate.
- **A `paths:`-scoped rule is not always-on, by design.** After a compaction it is gone until Claude
  reads a matching file. So the test for a candidate is: *is this content inert until someone opens a
  matching file?* If yes, the scoping is self-healing — touching the layer reloads the rule. If the
  content must hold regardless of which files a turn touches, it belongs in `CLAUDE.md` and no amount
  of tidiness changes that.

**Worked example, and the trap inside it.** The `### Language` section (65 lines, the largest in
`CLAUDE.md`) was mostly per-layer detail about `scripts/**`, `.github/**` and `releases/**` — textbook
path-scoped material, and it moved to `.claude/rules/language-layers.md`, taking `CLAUDE.md` from 328 to
**282 lines**. But the section also contained one sentence that had to stay: *the session-reply language
follows the user*. That governs every turn regardless of files touched, so path-scoping it would have
silently weakened it after the first compaction — and it is a rule that had already been broken in
practice earlier the same day. **Read a candidate section for the one sentence that is not about the
files, before moving the block.** The docs' own phrasing of the escape hatch is the tell: *"If a rule
must persist across compaction, drop the `paths:` frontmatter or move it to the project-root
`CLAUDE.md`."*

Remaining candidates in `CLAUDE.md`, by size, with the test applied: the roster/routing table (53 lines)
**fails** it — routing is needed at intake, before any file is read; the safety rules (34 + 31 lines)
**fail** it — they must survive compaction; `## The Claude Specialists` (46 lines) **fails** it. So the
easy room is now spent, and what is left is the judgement call recorded above rather than more
relocation.

### Boundaries with the other roles

- A duplication finding is still a duplication first: Nolan may flag the token cost, but the dedup
  act itself stays with [Ravi #24](06-24-extension.md).
- The loading mechanism itself — harness config, the generator/lint scripts, `settings.json` —
  stays with [Sylvester #15](05-15-extension.md); Nolan says *what* should get cheaper, Sylvester
  builds it if it is config/script work.
- Rewriting the actual doc/manual/agent-def text for leanness stays with
  [Tessa #16](06-16-extension.md); Nolan advises on where and how much, Tessa does the rewrite.

In short: the **how** (measuring cost, proposing savings, staying out of the execution) is portable;
the **what** (this repo's deliberate on-demand loading strategy, the size of its agent-defs/manuals,
and the `agent-shared/` lever) belongs to this repo.
