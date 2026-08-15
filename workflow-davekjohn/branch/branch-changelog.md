## `docs/two-decisions-recorded` changelog

### Branch title

Deliberate restatement and the surviving role word are written down as decisions

### Branch ID

20260815-235703

### Branch type

docs

### What does the change on this branch bring to main?

Two findings from the review of August 15, 2026 that turned out to be **decisions rather than defects**.
Neither file changes behaviour; both stop the same finding being re-filed every time somebody sweeps.

**"Workshop" survives as a role word, and the README now says so.** The retirement of August 3 killed
the *framing* — this repo as the workshop for every future product — and the review found the *name*
still alive in 32 places, which shipped as a correction. What it also found, and undercounted at first,
is **310 further uses of "workshop" as a role word**: `workshop root`, `workshop-side`, "covered from
the workshop by check-connectors". Those are not the retired framing. They describe what this side of
the marketplace does, which is still exactly what it does. Sweeping them is a prose-sensitive rewrite
across 61 files of shipped plugin content, and it buys consistency at the price of worse sentences. So
the distinction is recorded where a reader already goes to understand the retirement, with the three
`davekjohns-workshop` references named as the historical record they are.

**Restating a rule for a different reader is legitimate — but only when it is marked.** The review
reported the "chore is a contradiction" rule as duplication across three documents plus a code comment,
and it was right that nothing said otherwise. It is deliberate: four readers arrive at four different
doors, and the rule is the kind people work around when it is not in front of them — a `chore/` branch
looks reasonable until you know why it cannot exist. The general form is now a rule in Tessa's manual,
with its honest limit attached (restate the *rule*, keep any *measurement* in one place), and the two
measured instances are named in her lens.

**One of the two is recorded as the weaker case rather than defended.** The "81 of 89" figure sits in
two shipped portable documents, and it is a *number*, not a rule — so a re-measurement has to be applied
twice, which is the exact failure the new rule says to avoid. It stays because both documents serve a
reader who needs the figure at a different moment, and the lens now says what to do if that stops being
practical: keep it in one and point at it from the other.

### Significance

#### Tier 0

A sweep that keeps finding the same three things and re-deriving the same answer costs a pickup every
time. Both are now written where the next reader looks, including the one that is a compromise.

**Score:** 2

#### Tier 2

Tessa's manual ships, so the restatement rule travels to every repo that works this way — and it is a
rule about documentation debt that most repos have and few name.

**Score:** 2

### Pull Request

