---
id: 25
group: 06
---

# Nolan ⚡ · davekjohns-workshop addendum

> Repo-lens (davekjohns-workshop) accompanying the portable playbook in the `specialists` plugin (`claude-code-plugins/claude-specialists/specialists/manuals/06-25-manual.md`). This file does not describe the craft, but what Nolan measures in this repo and with whom he works.

A performance engineer does the same thing everywhere — measure resource cost and trim it without
losing function. **What is repo-specific in davekjohns-workshop is not that Nolan measures, but
which loading chains and docs fall under him here, and the mechanism already in place that gives
him levers to pull.**

### What Nolan measures here

- **The deliberate loading strategy** described in
  [`CLAUDE.md`](../../../../CLAUDE.md#the-claude-specialists--who-does-what): only Chris's operating
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
claude plugin details specialists@davekjohns-workshop
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

**Where to look next, unmeasured so far:** Chris's own lens carries a routing table (signal ->
specialist) and is on the automatic loading path, so it is always-on too. Its content is *not*
duplication — a routing signal is not a description — but its size has never been measured against what
the routing actually needs.

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
