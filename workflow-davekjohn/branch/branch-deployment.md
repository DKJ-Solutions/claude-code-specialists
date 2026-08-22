## `feat/measure-skill` deployment

### What does the change on this branch deploy to main?

A new `measure-skill` skill in `workflow-davekjohn`, which prices what a skill costs and times the
script behind it. Two passes: **cost** (always-on and on-invoke tokens per skill, ranked, with the
delta against a committed baseline) and **speed** (wall-clock of the script a skill drives, `n` runs,
min/median/max, machine state stated).

It drives `claude plugin details` -- the `count_tokens` API -- rather than estimating from file sizes,
so the figure it reports is the authoritative one and not a second, disagreeing estimate. It checks no
correctness: frontmatter, dead links and parameter coverage stay `check-plugin-integrity.ps1`'s, and
duplicating one of its 26 checks here would put two verdicts on one subject. It is not a gate and the
page says why: `lint-en-tests` already blocks every merge for a median of 7m 23s, and a skill's cost
changes on the scale of releases rather than commits.

**Why now, measured rather than assumed.** 24 skills across four plugins had never been measured on
cost, speed or effect. Seven skill descriptions cost ~1,245 tokens at `v2.10.0`; 18 across the two
plugins enabled here cost **~3,650** at `v4.17.0` -- nearly 3x, never re-measured in between. And the
first run found something no estimate would have: `workflow-davekjohn`'s **entire** always-on cost is
its 14 skill descriptions, within rounding. The committed baseline is what makes the next growth
visible instead of discovered.

**Pass 2 will not run a script that has no declared read-only mode, and that is the whole safety
model.** Timing the script behind `cut-release` by invoking it would cut a release. So a script is
timed only where its own registration carries a `MeasureArgs` key naming a harmless invocation --
declared beside the registration rather than in a list inside the measuring script, because a second
hand-written list is one a newly shared script falls out of silently. Two scripts qualify today;
everything else is reported as not measured, by name, with the reason. A test pins `cut-release` as
never declarable.

**Pass 3 -- whether a skill actually earns its tokens -- is designed and deliberately not built.**
`claude plugin eval` already carries the engine, including a `--ablation with-without` arm that scores
the same cases with the plugin removed. The four flags this repo would need are recorded on the skill
page so the first person to wire it up does not rediscover them, `--no-publish` among them: the report
otherwise goes to claude.ai, which is not a side effect a measurement gets to have.

Three defects were found by running it rather than by reading it, and each is written up where it
happened: figures formatted on a Dutch machine rendered 13,700 as `13.700` (a factor of a thousand to
an English reader, and the mirror image of the parse trap the tolerance guards); `-UpdateBaseline`
reduced an 18-skill baseline to 4 and reported success, because a scoped run replaced the file instead
of merging into it; and an `if` expression returning `@()` unrolled to `$null`, so "declared safe with
no arguments" read as "not declared" and was silently skipped.

**Score:** 3

#### What makes this change extra special

A consumer gains a skill that answers "what is this plugin costing my sessions, and which skills carry
it?" -- and pass 1 works there, since it needs nothing but the `claude` CLI. Pass 2 needs the
shared-scripts registry and reports `[SKIP]` with the reason where there is none, so the boundary is
stated rather than met as a failure. Nothing existing changes behaviour: one skill and one script are
added, and the only edit to a shared file is an optional registry key that is absent everywhere it was
not declared.

**Score:** 3

### Pull Request

Measure a skill's token cost and speed
