## `docs/a-per-run-cost-is-counted-over-its-population` changelog

### Branch title

A cost that varies per run is counted over its population, not cited from one run

### Branch ID

20260811-143647

### Branch type

docs

### What does the change on this branch bring to main?

The performance engineer carries a new hard rule: **a cost that varies per run is counted over its
population, not cited from one run.** It sits directly beside *report in the unit the question was asked
in*, because the two are siblings — there the easy number is the wrong **unit**, here it is the wrong
**sample**.

The measured instance behind it, which is what makes it a rule rather than an opinion: a CI gate was
written into a cost model as the fixed cost of a release, taken from one carefully measured run and cited
correctly. The next run came in **25% below it**. Counting every successful run of that workflow — 63
blocking ones — put the recorded figure **exactly on the p90**: the slow tail recorded as the typical,
from a citation that was entirely accurate. Accurate and unrepresentative are not the same property, and
only one of them is visible when you hold a single sample.

Four practices come with it. Ask whether the history is **queryable** before writing a per-run cost as a
fixed number — CI providers, job runners and build systems keep it, so the population is usually one
command away, and collecting a *second* run is the wrong instinct because two anecdotes are not a
distribution. Report an **n, a median and a range**, since a bare point value invites being quoted as
though it had no spread. **Compare sub-populations** where they exist, which separates environmental
variance from a real difference and kills a plausible explanation before somebody builds on it. And then
say **whether the conclusion moved** — in that instance the correction shifted every derived figure by
~7% and changed nothing concluded from them, which is worth stating outright: a model whose shape
survives a large error in its largest input is one worth deciding on, and that is a different claim from
the model being precise.

This repo's lens keeps the measured instance and now points at the rule, matching how the unit rule is
already split between the two layers: the manual carries the craft, the lens carries the evidence.

### Significance

#### Tier 0

The lens had recorded this as a one-off correction to one number. Promoting it to the manual means the
next per-run cost measured here — a suite, a build, a script — meets the rule before the figure is
written down, rather than after it has already been quoted. It also closes the split honestly: the
instance and the rule now point at each other, instead of this repo holding both halves in its own layer
where nobody downstream would ever receive the rule.

**Score:** 2

Is this change also relevant to colleagues and employers? Yes — continue to Tier 1.

#### Tier 1

Cost figures are what delivery and capacity arguments get built on, and a single-run figure is the most
citable and least reliable form they come in. The rule prevents the specific failure that was caught
here: a tail value entering a decision document as the typical cost, with a correct citation attached
that makes it look verified. The reassurance travels with it — the conclusions survived the correction,
so the lesson is about how to report a cost, not a warning that the cost model was unsound.

**Score:** 2

Is this change also relevant to customers and users? Yes — continue to Tier 2.

#### Tier 2

The rule ships in the performance engineer's manual, so every consumer receives it on their next plugin
update and it applies to every cost question they put to him — not only to CI, and not only to releases.
A consumer measuring their own test suite, build or gate gets the discipline that turns one stopwatch
reading into a defensible figure, including the instruction to report an n and a range so their own
readers can judge it. Nothing they run changes and no command moves; this is craft their specialist did
not have before.

**Score:** 3

### Pull Request
