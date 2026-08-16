## `feat/gate-evidence-not-a-flag` changelog

### Branch title

The gate records what it proved, so the merge stops re-proving it

### Branch ID

20260816-093210

### Branch type

feat

### What does the change on this branch bring to main?

`open-pr.ps1` now records what its gates proved and against which exact working state, and skips a
gate only while that state is unchanged. `ship-pr.ps1` calls `open-pr.ps1`, so a branch opened in one
step and shipped in a later one used to run the full lint and test gate a second time on a commit
nothing had touched.

**Measured before it was built, and the figure in circulation was wrong.** Across 293 merged pull
requests the gap between the gating CI run going green and the merge landing is sharply bimodal: 205
land within 60s (median 14s), 83 land at a median of 263s, with a void between 60s and 180s and an
interior peak at 240-300s. A void followed by an interior peak is a fixed-cost operation; human delay
produces a monotonic tail with no interior peak. The one confound that could fake it was ruled out --
zero of the 83 have a `push`-event CI run on the same sha, so none of the gap is time spent waiting on
a second CI run. **So the excess is 249s on 28.3% of merges**, not the "3m 27s, 3m 18s, about three
minutes, 4m 02s and 4m 18s across five consecutive releases" the last two release notes carried. That
series conflates the whole merge-with-fold leg with the gate re-run inside it; only `v4.9.0` separates
the two, at *"3m 27s of the 3m 53s merge leg"*. The release-document pull requests are where it lands
reliably -- #692, #693 and #694 paid 819s between them for `v4.11.0` -- because that procedure opens
the note's pull request in one step and ships it in another, so it can never be a one-motion ship.

**The workaround was the actual defect.** Every one of the nine pull requests shipped on August 15 used
`ship-pr.ps1 -SkipLint -SkipTests`, deliberately, because the identical commit had passed both gates
minutes earlier. That is correct exactly while the commit is unchanged and dangerous the moment it is
not, and nothing checked which. The flag was doing the design's job without the design's safety, so the
repair makes the unchanged case provably not need it rather than making the flag more comfortable.

**The evidence is the content, not the clock and not a promise.** A passing gate is recorded against a
fingerprint of what it actually judged -- `HEAD`, plus the content hash of every dirty and untracked
file. `HEAD` plus `git status --porcelain` would have been the obvious shortcut and is wrong: porcelain
reports *that* a file is modified and never what it was modified *to*, so a file edited, gated and
edited again presents a byte-identical status line over different content. Each gate records
separately, `-SkipLint`/`-SkipTests` record nothing (a skipped gate proves nothing about the tree), and
every failure path -- no record, malformed record, no git, a clock that moved backwards -- refuses,
because a false refusal costs one gate run while a false skip costs an ungated merge. A four-hour age
bound covers the environment drifting underneath a tree that has not moved.

The record lives in the git directory: guaranteed present, local, per-worktree and never committable,
which is four properties a tracked file plus a `.gitignore` entry would each have to be given in every
consumer. **CI is untouched** -- a fresh checkout has no record, so `lint-en-tests` always runs the gate
for real, and a suite pins that it never learns to consult one.

New shared lib `scripts/lib/gate-lib.ps1`, mirrored to `workflow-davekjohn`; `gate-lib.tests.ps1` adds
46 asserts, including the edit-gate-edit sequence that a porcelain-only fingerprint would wave through.

### Significance

#### Tier 0

Removes a redundant four-minute gate run from roughly a quarter of all merges, and retires a habit --
shipping with both gates disabled by hand -- that was safe only by the practitioner remembering why.
The release procedure, where it lands most reliably, gets ten to fourteen minutes back per cut.

**Score:** 4

#### Tier 2

Consumers receive the same change through `open-pr.ps1` and the new lib in the `workflow-davekjohn`
mirror: their merge path stops re-proving commits nothing has touched, with no flag to remember and no
configuration to answer.

**Score:** 3

### Pull Request

