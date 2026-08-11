## `fix/the-ci-leg-is-a-distribution` changelog

### Branch title

The CI leg of the gate cost is a distribution, not a single run

### Branch ID

20260811-141746

### Branch type

fix

### What does the change on this branch bring to main?

The largest component of the release gate cost — `lint-en-tests` on a pull request — was recorded in
Nolan's lens as **8m 36s**, correctly cited from the `v4.4.0` release but taken from one run. It is now
recorded as what it is: **median 7m 23s, range 5m 17s–9m 27s over 63 blocking runs**.

**The figure was the p90 presented as the fixed cost.** The pull request that recorded it came in at
6m 25s, 25% below the number it had just written down, which prompted counting every successful run of
`ci.yml` instead of collecting a second anecdote. `v4.4.0`'s run sits **exactly on the p90** of that
population. The 6m 25s was never an outlier — it falls between the minimum and the median.

Two things the population settles that a second sample could not. The `pull_request` and `push`
distributions are near-identical (median 7m 23s against 7m 16s, over 63 and 134 runs), so this is **runner
variance and not a property of the event type** — which rules out the tempting explanation that a
docs-only diff runs faster. And a cost with a 4m 10s spread is now written with its range beside it, so it
cannot be quoted as a point again.

**Every derived figure moved by about 7% and no conclusion moved at all**, which is recorded as a finding
rather than quietly patched: a minor now costs 14m 34s instead of 15m 47s, the 10-day window 3h 31m 38s
instead of 3h 48m 40s, and the ceiling of the whole batching lever 3h 17m instead of 3h 32m. The scenarios
scale by a common factor, so the ceiling stays under four hours, the 48% capture at one-release-per-day is
unchanged, and the first step remains worth roughly twelve times the last. A model whose shape survives a
25% error in its largest input is one worth deciding on — a different claim from the model being precise.

**What was deliberately not done.** The two local suite legs (231s in the cut, 200s and 226s at `open-pr`)
are left exactly as measured. They are an n=1 and an n=2 standing next to an n=63, and manufacturing a
distribution from two points would repeat at smaller scale the error this change corrects. The 3-second
discrepancy in `v4.4.0`'s own stated gate total is kept as a live note about that document, now that the
total it concerns is no longer what the model uses.

### Significance

#### Tier 0

The number a developer opens Nolan's lens to find is the one they would build a cost argument on, and it
was the slow tail of its own distribution. It now carries an n, a median and a range, so the next reader
can see how much confidence it deserves without re-deriving it. The correction also demonstrates the check
that produced it: where a cost varies per run and the history is queryable, the population is one command
away and beats a second anecdote.

**Score:** 3

Is this change also relevant to colleagues and employers? Yes — continue to Tier 1.

#### Tier 1

It prevents a specific and likely failure rather than improving anything observable: quoting 8m 36s as
"what CI costs" in an organisational discussion about delivery, when that is the p90 and the typical run
is a minute and a quarter shorter. Nobody had made that argument yet, which is exactly why the repair is
cheap now. What a colleague gains beyond the corrected number is the reassurance that the cadence
conclusions never depended on it.

**Score:** 1

Is this change also relevant to customers and users? No — see Tier 2.

#### Tier 2

Nothing reaches a consumer. The change is confined to `.claude/specialists/lenses/`, this repo's own
layer, which never travels in the plugin; no shipped script, skill, manual or manifest is touched. The
portable half of the lesson — that a per-run cost is counted over its population rather than cited from
one run — is deliberately left for a separate decision about Nolan's shipped manual.

**Score:** N/A

### Pull Request
