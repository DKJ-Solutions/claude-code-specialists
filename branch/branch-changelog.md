## `docs/gate-counts-and-runner-lesson` changelog

### Branch title

The gate documentation states the real suite count, and records the hand-rolled-runner lesson

### Branch ID

20260812-180637

### Branch type

docs

### What does the change on this branch bring to main?

The documentation that tells a developer what the gates run, and what to do when one goes red, now says
what is true — and carries the lesson that produced the correction.

**The lesson, which until now survived only in a commit message.** A hand-rolled `Start-Job` fan-out over
all 31 suites reported **6** failures — `agent-shared`, `bootstrap-drift`, `config-blueprint`,
`fix-mojibake`, `roster-sync`, `verify-resolved-issues` — two of them asserting *"lint gate green on the
repo"* in as many words, which reads like a finding about the repo rather than about the runner. Every one
passes when run alone, and `open-pr` then ran all 31 green in 218s. What the six share is that they scan the
**live repo** — three by invoking the lint gate over it, the other three by running their own repo-wide
scanner — so 31 at once collide over one tree. The written lesson keys on **the tree rather than the lint
gate** for that reason: keying it on the gate would have exempted half the affected suites. It is written
into
[Sylvester #15's lens](.claude/specialists/lenses/05-15-extension.md) beside the paragraph that already
describes that collision, because this is its strongest instance. Stated with both halves: the corollary is
**re-run a red suite alone before believing its assert**, and the rule is emphatically *not* "never
parallelise" — `open-pr` parallelises them, is the tested runner, and was checked against the two
conditions that make it safe before it did.

It had been written into `branch/branch-progress.md`, which the fold resets by design, so it existed
nowhere a reader would look before running the suites.

**Two stale counts, corrected in opposite directions — which is itself now the written rule.** There are
31 suites. `05-15-extension.md`'s *"only fails with 26 siblings"* is live advice about what to try next, so
it becomes **30**. `CLAUDE.md`'s *"`open-pr` runs the lint and all 26 suites"* sits under a **Measured on
August 7, 2026** stamp, and refreshing a dated sentence to today's figure is the very thing the same lens
forbids one paragraph earlier for its 27-suite measurement — so the count is **removed** instead: it
carried none of that sentence's argument, which is the coverage asymmetry between `open-pr` and
`cut-release`. It had read `26` for five days, wrong on the day it was written and wronger every suite
since.

**What was deliberately not touched.** The dated *"all 27 suites green"* measurement, whose 510s-vs-159s
spread means nothing paired with another count; `releases/development/3.x/3.8.0.md`'s *"all 26 suites"*,
under the published-record rule; and every other bare `26`, which governs a different noun — the lint's own
checks and the agent-def count are both 26 and both correct. A find-and-replace on the figure would have
broken three correct statements to repair one, so the lens now says which noun to establish first.

### Significance

#### Tier 0

The gate documentation is what a developer reads before running the suites and after one goes red, and both
of its numbers were wrong. The expensive half is the lesson: without it, the next person to fan the suites
out by hand gets six red asserts that name real suites, two of them phrased as a repo-wide lint failure, and
the cheapest reading of that is to start repairing a defect nobody has.

**Score:** 3

#### Tier 2

Nothing here ships. Both files are repo-local governance — `CLAUDE.md` and a lens under
`.claude/specialists/lenses/` — so no plugin payload, skill or script changes and no consumer receives
anything from this branch.

**Score:** N/A

### Pull Request
