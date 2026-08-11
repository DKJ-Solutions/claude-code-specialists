---
id: 25
group: 06
---

# Nolan ⚡ · claude-code-specialists addendum

> Repo-lens (claude-code-specialists) accompanying the portable playbook in the `team-alpha` plugin (`plugins/teams/team-alpha/manuals/06-25-manual.md`). This file does not describe the craft, but what Nolan measures in this repo and with whom he works.

A performance engineer does the same thing everywhere — measure resource cost and trim it without
losing function. **What is repo-specific in claude-code-specialists is not that Nolan measures, but
which loading chains, docs and gates fall under him here, and the mechanism already in place that gives
him levers to pull.**

**Two resources since August 10, 2026, and the second one is why the widening happened.** Nolan owned
token/context budget alone, and the honest state of that half is that its easy room is spent — the
sections below record two verdicts of *leave it alone*, reached by measuring. Meanwhile a release here
takes about thirty minutes, of which roughly seventeen is gate time, and nobody owned that. Measured on
pickup: Nolan is named 12 times in this repo's record and **all 12 are in `1.x` and `2.x`**, the last
around August 2 — no work at all across the twelve releases of `3.x` and `4.x`. That is not a specialist
who does little; it is a proven craft whose one resource ran out of surface while a second was going
unmeasured. Decision by Dave, August 10, 2026, over the alternative of a separate build/CI specialist:
the craft is the same, only the bill differs.

### What Nolan measures here

- **The deliberate loading strategy** described in
  [`CLAUDE.md`](../SPECIALISTS.md#the-claude-specialists--who-does-what): only Chris's operating
  manual loads automatically (via the `@` import at the bottom of `CLAUDE.md`, because he is
  involved in every assignment); every other specialist's portable playbook + repo lens is read
  **on demand**, at the moment Chris assigns work to them — "deliberate, to save context/tokens".
  Nolan checks whether that boundary still holds as the roster grows: does a new persona/subagent
  stay on-demand, or has something crept onto the automatic path that doesn't need to be there?
- **The size of agent-defs, manuals, and personas** across the plugins
  (`plugins/*/agents/*-agent.md`, `*/manuals/*-manual.md`,
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
claude plugin details team-alpha@claude-code-specialists
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

### Wall-clock here — the gates, and the baseline measured at v4.2.0 (August 10, 2026)

Nolan owns wall-clock as of this date, and this repo spends it almost entirely on **gates**. There is no
application to profile: what costs time is what runs before work is allowed to land. Measured during the
`v4.2.0` cut rather than estimated:

| what runs | measured | when it runs |
|---|---|---|
| `check-plugin-integrity.ps1` (26 checks) | seconds | before every push, and inside the cut |
| the 30 test suites (210 asserts) | **205–232s** | inside `cut-release`, inside `open-pr`, and again in CI |
| CI `lint-en-tests` | **8m41s–8m42s**, four runs | every PR; blocks the merge |
| a full release, end to end | **28m 03s**, measured at `v4.4.0` (August 11, 2026) — all of it blocking | per release, ~1.6× per day at the August cadence |

**Apply the count-the-invocations rule before proposing anything here, because this repo trips it.** The
same 30 suites run **three times** per release-with-documents — once in the cut, once in `open-pr`, once in
CI — so a change that halves the suite saves three times what a single run suggests, and a change that
skips one run saves a third while proving less. That triple is **deliberate**: the release commit does not
travel via a PR and therefore meets no CI, which is why the cut runs the suites itself
([`CLAUDE.md`](../../../CLAUDE.md#claude-code-specialistss-safety-implementation) records that the cut used
to run the lint alone and was the least-gated commit in the workflow). Do not propose removing it without
reading that decision.

**The blocking/non-blocking split matters more here than the totals.** The release commit's own CI runs
*after* the push and blocks nobody; the PR's `lint-en-tests` blocks the merge and is the single largest
thing a person waits on. A proposal that shortens the first is worth close to nothing.

**And the frequency lever is live in this repo, which is unusual.** 16 releases in the 10 days to August 10,
2026, each carrying ~17 minutes of fixed gate time — so batching entries per cut is a real reduction that
needs no code at all. The counterweight is recorded and belongs to Dave: `plugin.json`'s version is one of
the two update gates, so releasing less often is delivering later.

**THE NEXT RELEASE OWES THREE NUMBERS, and the first is a gap Nolan left himself** (August 11, 2026). All
three are counting, not building.

1. **ANSWERED at `v4.4.0`, August 11, 2026: a release takes 28m 03s, and 15m 44s of that is gates.** Clock
   started at 10:24:11 before the cut and stopped at 10:52:14 when the Release was published; every leg came
   from a git or CI timestamp rather than from recall. **All 28 minutes blocked a person**, in one serial
   chain — the only non-blocking cost was the release commit's own CI run on `main` (7m 48s), which finished
   inside the writing and nobody waited for. The gate share breaks down as 231s of suites inside the cut,
   200s of the same suites when the note's pull request opened, and 8m 36s of `lint-en-tests` on that pull
   request, which is **56%** of the release and the only place a real reduction can come from. The full table
   is in [`releases/notes/4.x/4.4.0.md`](../../../releases/notes/4.x/4.4.0.md).

   **Two cautions travel with the number, and they matter more than it does.** That release carried **two**
   entries against `v4.2.0`'s seven, so it measures the clock well and the writing gain not at all — less to
   read is less to write, and nothing here shows the merged-document model is faster than the two-document
   one. And ~30 min was the figure being reasoned about all along: 28m 03s **confirms** the estimate rather
   than improving on it, which is the honest reading of a first measurement.

   **What running it exposed: the document cannot time its own publication.** The note is frozen for its
   pull request while its CI, merge and publish are still running, so the frozen subtotal was 9m 42s of the
   28m 03s — two thirds of the release unmeasurable from inside the file. Step 0a is split into two passes
   now, the second adding the total in its own pull request afterwards. Recorded because the instinctive
   repair — publish the Release earlier — is the wrong one, and is refused in the skill.

   The original reason this was first: **`v4.3.0` improved the release and produced no post-change figure in minutes.**
   The whole cycle ran against *"why does a release take about thirty minutes"*, the hand-written half
   measurably shrank, and the result was reported as **43% fewer words** — a proxy, reported because words
   were what somebody had counted. The gate time *was* re-measured and was unchanged (~13 of the ~30
   minutes); the end-to-end figure was captured neither before nor after, and a baseline cannot be taken
   retroactively. The portable half of that lesson is in
   [Nolan's manual](../../../plugins/teams/team-alpha/manuals/06-25-manual.md) under *report in the unit the
   question was asked in*.
2. **Which of the 30 suites can change behaviour on a markdown-only diff?** (Proposed August 10, 2026, not
   approved.) If the answer is few, the second local run has room; if it is "most of them", it does not —
   several suites read documents rather than scripts, so "markdown-only, therefore skip" is exactly the sort
   of assumption this repo has been bitten by. Count before proposing.
3. **The cadence, against the fixed cost.** 16 releases in the 10 days to August 10, 2026, each carrying
   ~17 minutes of gate time that does not shrink with the number of entries in it. Batching is a lever
   needing no code; the counterweight is Dave's and it is real — `plugin.json`'s version is one of the two
   update gates, so releasing less often is delivering later.

**None of the three is a gate, deliberately.** They are measurements whose answers decide what is worth
building; a check refusing a release over a missing number would cost every release something in order to
guard a decision nobody has made yet.

### Boundaries with the other roles

- A duplication finding is still a duplication first: Nolan may flag the token cost, but the dedup
  act itself stays with [Ravi #24](06-24-extension.md).
- The loading mechanism itself — harness config, the generator/lint scripts, `settings.json` —
  stays with [Sylvester #15](05-15-extension.md); Nolan says *what* should get cheaper, Sylvester
  builds it if it is config/script work.
- Rewriting the actual doc/manual/agent-def text for leanness stays with
  [Tessa #16](06-16-extension.md); Nolan advises on where and how much, Tessa does the rewrite.
- A **test suite's** duration is a cost finding and a testing decision at once: Nolan reports the
  seconds and how often they are spent, [Tycho #18](04-18-extension.md) decides what an assert
  protects and whether narrowing it gives something up. The suites here are `scripts/tests/*.tests.ps1`
  and the gate that runs them is `open-pr.ps1`, so the *script* half of any repair is
  [Sylvester #15](05-15-extension.md)'s and the *coverage* half is Tycho's.
- **The safety rules are not Nolan's to trade.** The three gates exist because
  [`CLAUDE.md`](../../../CLAUDE.md#claude-code-specialistss-safety-implementation) says so, and several
  of them were built after a measured failure. Nolan may quantify what one costs and put a
  coverage-for-time trade on the table with both sides numbered; whether to take it is Dave's.

In short: the **how** (measuring cost, proposing savings, staying out of the execution) is portable;
the **what** (this repo's deliberate on-demand loading strategy, the size of its agent-defs/manuals,
the `agent-shared/` lever, and the three-times-per-release gate bill) belongs to this repo.
