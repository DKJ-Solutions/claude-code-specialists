## `docs/gate-record-measured` changelog

### Branch title

The gate record's saving, measured on the case it was built for

### Branch ID

20260816-145255

### Branch type

docs

### What does the change on this branch bring to main?

`v4.12.0`'s release note left one item open in its own words: the gate record had not been measured on the
case it was built for, because that release was shipped in one motion and so never produced the duplicate
gate run the record exists to absorb. PR #734 was that case. This branch measures it and writes the result
into [Nolan #25's lens](.claude/specialists/lenses/06-25-extension.md), beside the existing wall-clock
section.

Both halves of the difference are measured rather than one half and an assumption: the gate `ship-pr` would
have paid (lint 9.2–10.6s, n=3; 43 suites 139.7–195.0s, median 193.2s, n=6) against the path it paid
instead (one fingerprint plus one evidence read per gate, 130.9–249.5ms, n=10). **Roughly 203 seconds of
gate replaced by about a sixth of a second, a ratio near 1,250:1.** A second, independent method agrees:
#734's CI-green-to-merge gap was 27s against a historical slow-mode median of 264.5s for exactly that
shape, implying ~237s once the genuine merge-and-fold work is allowed for.

The historical comparator was recounted instead of quoted, and — unlike the four findings before it — it
**survived**: 187 fast merges at a median of 13s and 78 slow at 264.5s (27.8%) against the docstring's 205
/ 14s / 83 / 263s / 28.3%, same shape, same void, same interior peak. Recorded as a recount that held,
since that is the only thing distinguishing it from one that did not.

Three misreadings are closed off explicitly: the 249s-on-28.3% figure is the comparator and not the
result; the two "skipped" lines are one fingerprint decision printed twice rather than two data points;
and the six fast merges since the record shipped are consistent with it but are not six firings.

One side finding is kept separate rather than folded in. The four post-split suite runs already recorded
(142.4 / 145.5 / 170.3 / 169.9s) are the optimistic end of a wider band — combined with the six here,
n=10 spans 139.7–195.0s with a median near 172s, and four of the six sat at 193.0–195.0. The post-split
improvement is real; the "-25%" headline is the best case rather than the typical one. The summary table
is corrected accordingly (40 → 43 suites, and the lint row gets a number where it said "seconds").

### Significance

#### Tier 0

Closes a named open item from `v4.12.0`'s release note with a figure the repo can act on, and corrects two
stale numbers in the wall-clock table that a maintainer would otherwise read as current.

**Score:** 3

#### Tier 2

N/A — the lens under `.claude/specialists/` is this repo's own layer and is not plugin payload, so nothing
here reaches a consumer.

**Score:** N/A

### Pull Request

