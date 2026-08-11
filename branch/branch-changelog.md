## `docs/the-cadence-is-counted` changelog

### Branch title

The cadence is counted against the fixed gate cost

### Branch ID

20260811-135241

### Branch type

docs

### What does the change on this branch bring to main?

Nolan's third open number — the release cadence against the fixed gate cost — is counted, and his lens
carries the measurement instead of the question. The decision it feeds is deliberately left open: it is
Dave's, and counting it does not make it.

What is now written down rather than estimated: the cadence recount (**16 releases in the 10 days to
August 11, 2026** — the same number as the previous window over a different mix, 13 minor, 1 major, 2
patch, with **no patch at all** in the last seven days), the fixed gate cost **split by bump type**
(**15m 47s** blocking for a minor or major, **3m 51s** for a patch, which writes no document and so opens
no pull request and meets no blocking CI), and what the window cost at that price: **3h 48m 40s of
blocking gate time in 10 days, 22.9 minutes per day**.

Both sides of the trade are priced in the same table, because `plugin.json`'s version is one of the two
update gates and releasing less often is delivering later. The saving is simulated against the **real 73
merge timestamps** in the window; the delivery cost is **measured** as merge → next tag (mean 7.45h today).
Two findings come out of it and neither is the choice: the **ceiling is low** — the entire lever is worth
under four hours per ten days — and the **first step is the efficient one**, 16 → 8 releases capturing 48%
of that ceiling at 29.5 minutes saved per added hour of delivery delay, against 2.4 minutes at weekly.

Measured rather than assumed at four points, each of which could have gone the other way. The patch cost
rests on `releases/consumer/3.x/` and `releases/internal/3.x/` holding documents for every minor in the
window and **none** for `3.1.1` or `3.1.2`. The merge list and the release list cross-check: exactly **4**
of the window's 77 merges are unreleased, matching the four entries pending in `CHANGELOG.md`. The
window's releases are re-priced at **today's** gate cost, with the note that nine of the sixteen predate
`fix/release-runs-the-suites` (#514) and so historically paid less — a re-pricing of past volume, which is
the only pricing a forward cadence decision can use. And a **3-second discrepancy is left standing**: the
`v4.4.0` note states 15m 44s of gates while its own components sum to 15m 47s, so the separately measured
components are what the lens uses.

The paragraph that estimated "~17 minutes of fixed gate time" is repointed at the measurement that
replaced it.

### Significance

#### Tier 0

An open question in a lens has become a citable cost model: a developer opening Nolan's lens now finds
what a release costs, split by bump type, instead of the question of what it costs. It also removes an
estimate that was quietly wrong in a way that mattered — "~17 minutes" averaged two bump types whose real
costs differ by a factor of four, so any reasoning that used it under-priced a minor and over-priced a
patch.

**Score:** 3

Is this change also relevant to colleagues and employers? Yes — continue to Tier 1.

#### Tier 1

The organisation now knows what its delivery rhythm costs and what changing it would buy, in minutes and
in hours of delivery delay, on the same table. The useful half for a colleague is the shape rather than
any single figure: the whole lever is worth under four hours per ten days, and its steps are sharply
diminishing, so a cadence decision is not a slider where further is better. That is the kind of finding
that stops a plausible efficiency drive before it costs engineering time.

**Score:** 2

Is this change also relevant to customers and users? No — see Tier 2.

#### Tier 2

Nothing here reaches a consumer. The measurement lives in `.claude/specialists/lenses/`, which is this
repo's own layer and never travels in the plugin; no shipped script, skill, manual or manifest changes,
and the cadence decision that could eventually affect delivery timing is deliberately not made on this
branch.

**Score:** N/A

### Pull Request
