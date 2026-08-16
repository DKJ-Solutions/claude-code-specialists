## `docs/gate-record-second-firing` changelog

### Branch title

The gate record's second firing, measured on this repo's own ship

### Branch ID

20260816-151316

### Branch type

docs

### What does the change on this branch bring to main?

The section merged in #735 rested on one firing in the wild (PR #734) plus a bench reconstruction, and said
so plainly. This branch supplies the second firing and corrects the sentence that claimed only one was
confirmed.

**The second firing was produced deliberately rather than waited for**, because the chain offers it free:
`ship-pr` calls `open-pr` internally, so running `open-pr` first and `ship-pr` afterwards *is* the
split-step case, and the gates had to run before the merge either way. On PR #735's own tree `open-pr` ran
both gates for real in **198.6s** (43/43 green); `ship-pr` minutes later printed both skip lines against the
unchanged fingerprint; and the merge landed **15s** after CI went green, against the 264.5s historical
median for that shape. #734 was 27s — so n=2, on two branches, both in the fast mode.

The 198.6s replaces the ~203s bench estimate as the figure to quote: it is a whole `open-pr` invocation
measured in the chain rather than a lint number and a suite number added together. The bench figures stay,
because they are what decompose it.

Two suite readings from that exercise are folded in as well (168s and 183s), moving the post-split band to
n=12 with a median near 172s. The spread is unchanged at 139.7–195.0s.

One constraint is recorded because it decides the order of operations: `Get-GateFingerprint` hashes HEAD, so
any further commit voids the evidence and the next run re-gates. Those two readings could be committed to
the document **or** be followed by a skipping ship, not both on one branch — which is why they arrive here
rather than in #735. And one limit is stated rather than left for a reader to assume: two firings confirm
the mechanism but are not a distribution, and since 27s and 15s differ by far more than the 162ms skip
itself costs, nearly all of that spread is merge work and network. The saving is the gate that did not run.

### Significance

#### Tier 0

Corrects a claim in a just-merged document — "one firing is confirmed" — and replaces the estimated gate
cost with one measured in the chain. A maintainer reading the section otherwise inherits both.

**Score:** 2

#### Tier 2

N/A — the lens under `.claude/specialists/` is this repo's own layer and is not plugin payload, so nothing
here reaches a consumer.

**Score:** N/A

### Pull Request

