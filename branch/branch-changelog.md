## Four entries that never scored themselves get their scores and their place

### What does this change do?

**Four pending entries carried an impact table whose score cells were still `-`, and they sat at the
bottom of tier 2 because of it.** The scaffold writes those cells empty on purpose — a guessed ranking
is worse than none — so an entry that is never filled in ranks last by default. That is the right
default at fold time and the wrong state at cut time: `cut-release.ps1` refuses a release whose
tier-1-or-higher entries have not said how much they weigh, and it refuses before writing anything.
The v3.6.0 cut hit exactly that.

**One of the four is the reason this was repaired rather than waved through with
`-SkipSignificanceGate`.** *The lens scaffold's title carries no (VUL-IN)* fixes a defect where
`specialists-teardown -Apply` deletes lenses a consumer has written, and it is not retroactive — a repo
bootstrapped before this release has to strip the marker from its filled lens titles by hand. That is a
required migration whose failure mode is silent data loss, so it scores tier 2 / 5 and belongs at the
top of the document a consumer reads to decide whether to update. Unscored, it would have been the
*last* of sixteen tier-2 entries in the highlights draft. The other three score 2/4, 2/3 and 2/3.

**The scores had to be accompanied by a move, because nothing downstream re-sorts.**
`Get-PullRequestEntriesByTier` returns each tier's entries *in document order* and
`Split-Changelog` is explicit that it must not sort — the fold's ranked insert is the only moment the
order is decided, so document order at cut time is what the release documents inherit. Adding scores
without moving the entries would have produced four correct-looking numbers and the same wrong order.

**The move is a stable sort on (tier, score, existing position), and that choice is what makes it
reviewable.** The twelve already-scored tier-2 entries were in correct relative order already
(5, 4, 4, 3×5, 2×4), so a stable sort provably cannot disturb them: it only opens the four slots the new
scores ask for. Verified in both directions before the write — the parse-and-reassemble round trip was
asserted byte-identical over all 21 entries first, and afterwards a re-parse confirmed 21 entries in and
21 out with exactly four whose text differs. Tier 1 and tier 0 are untouched; tier 0 is never ranked.

**One hazard worth recording for the next person who scripts an edit to this file.** Windows PowerShell's
`Get-Content -Raw` misreads the document's UTF-8 middots as `Â·`, so a read-modify-write through it would
have committed mojibake across all 88 KB while every diff line looked plausible. The edit reads and
writes through `UTF8Encoding($false)` explicitly, and the result was scanned for `Â`/`â€` before commit.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 1 | 3 | the release this unblocks is the visible half; the lasting half is that the four entries now rank where they belong instead of where the absence of a score put them |
| 0 | 2 | no script changed -- the gate did its job and the entries were brought up to it |

### Type of change

Chore
