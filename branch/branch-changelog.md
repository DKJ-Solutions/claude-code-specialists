## `feat/nolan-owns-cost-not-only-tokens` changelog

### Branch title

Nolan owns cost in whichever resource the repo spends, wall-clock included

### Branch ID

20260810-225007

### Branch type

feat

### What does the change on this branch bring to main?

The performance engineer owned **token and context budget** and nothing else. He now owns **cost**, in
whichever resource a repo actually spends — that budget, and **wall-clock**: test suites, lint gates, CI,
and any script a branch cannot avoid. The agent def, the portable playbook and the routing all say so.

**Not one word of his craft changed, which is what made this a widening rather than a new specialist.**
*Measure, name the location and the current cost, propose the saving, hand the fix to whoever owns that
surface* is silent about which resource is being counted. So the alternative — a separate build/CI
specialist — was declined: it would have duplicated an entire craft in order to change the unit.

**The measurement behind it, taken on pickup rather than assumed.** Nolan is named **12 times** in this
repo's record and **all 12 are in `1.x` and `2.x`**, the last around August 2 — nothing across the twelve
releases of `3.x` and `4.x`. That is not a specialist who does little: his roster-description finding is
still cited in `CLAUDE.md` today (~750 tokens per session). It is a proven craft whose **one resource ran
out of surface** — his lens now records two separate *leave it alone* verdicts, both reached by measuring —
while a second resource went unowned. Meanwhile a release here takes about thirty minutes, seventeen of it
gate time, and nobody was responsible for that number.

**Three craft rules travel with the widening, because wall-clock fails in ways tokens do not.**

- **Count the invocations, not the run.** A gate that runs locally, again on the way out, and again in CI
  costs three times per unit of work, so halving it buys three times what one run suggests — and this repo
  is the worked example: the same 30 suites run three times per release-with-documents, deliberately,
  because the release commit meets no CI.
- **Separate what blocks a person from what does not.** Eight minutes of CI a human waits on is a
  different cost from eight minutes running behind them, and a proposal that shortens the second is worth
  close to nothing.
- **Name the fixed cost and the frequency separately.** Where a cost is fixed per event, halving how often
  the event happens is as real a lever as making it faster, and usually needs no code. Live here: 16
  releases in 10 days, each carrying that fixed ~17 minutes.

**And one hard rule, stated as a prohibition because it is the obvious wrong answer.** The fastest way to
shorten any gate is to stop running it, and that is a transfer of risk rather than a reduction in cost.
Nolan may put a coverage-for-time trade on the table with both sides quantified and labelled as such; he
may never present it as a saving. Several of this repo's gates exist *because* of a measured failure, so
that call is not his.

His new working partner is the test engineer: a slow suite is a cost finding and a testing decision at the
same time, and which asserts can be narrowed requires knowing what each one protects.

### Significance

#### Tier 0

The thirty minutes a release costs here now has an owner, and the baseline is written down instead of
re-measured every time somebody wonders.

**Score:** 3

#### Tier 1

A specialist who had produced nothing in twelve releases is working again, on the bill the organisation
actually pays.

**Score:** 3

#### Tier 2

A consumer with a real test suite spends far more wall-clock than this repo does, and until now no
specialist in the team owned that. The three counting rules are the transferable part.

**Score:** 4

### Pull Request

