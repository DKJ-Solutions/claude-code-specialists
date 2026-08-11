## `docs/a-release-is-timed-in-the-unit-that-was-asked` changelog

### Branch title

A release is timed end to end, in the unit the question was asked in

### Branch ID

20260811-094339

### Branch type

docs

### What does the change on this branch bring to main?

A cycle of work ran against the question *"why does a release take about thirty minutes"*, measurably
improved the release, and reported the result as **43% fewer words**. Words were what somebody had counted.
**Nobody timed the release**, before or after — so the question that started the work has no answer in its
own unit, and a baseline cannot be taken retroactively. This records that, in three places, each for a
different reason.

**The portable craft rule, in the performance engineer's manual: report in the unit the question was asked
in — a proxy is not the measurement.** It is two-sided, because only one half can be done afterwards:
capture the baseline in the asked-for unit *before* the change, and when reporting, name the unit in the same
breath as the number and say plainly where the asked-for unit has no post-change figure. A proxy reported
without its name reads as the measurement it is standing in for. This is the rule that specialist is most
likely to break himself, since the easy count is rarely the asked-for one — which is exactly what happened.

**The actionable half, as step 0a of the `cut-release` skill:** note the clock before the cut, note it again
when the Release is published, write the duration into the release document's organisational section. It is
step *zero* because a release is the most-repeated expensive procedure a repo has and because the number
cannot be recovered later. Two splits are asked for alongside the total, since a single figure hides both:
what blocked a person versus what ran behind them, and the fixed cost per release versus how often the repo
releases.

**And the three numbers the next release owes, in the performance engineer's repo lens:** the end-to-end
timing above, which of the 30 suites a markdown-only diff can affect, and the cadence against the fixed gate
cost. The lens also records what *was* measured properly at `v4.3.0`, because the gap is only meaningful
beside it: the gate time was re-measured and was unchanged at ~13 of the ~30 minutes.

**All three are conventions, and none is a gate.** A check refusing a release over a missing timestamp would
cost every release something in order to guard a decision nobody has made yet — and the same reasoning the
step-list gate records about ceremony applies: a number a person writes down is not a thing a script should
withhold a release for.

### Significance

#### Tier 0

The next cut is asked for the number this repo has been reasoning about all cycle, at the only moment it can
still be captured.

**Score:** 3

#### Tier 1

An improvement cycle that could not state its own result in the unit it was commissioned in is a reporting
failure, not a measurement one, and the correction is written down rather than remembered.

**Score:** 3

#### Tier 2

The craft rule and the checklist step both travel. A consuming repo runs the same procedure, and the failure
is not specific to releases: it is reaching for the count that is easy instead of the one that was asked for.

**Score:** 3

### Pull Request

