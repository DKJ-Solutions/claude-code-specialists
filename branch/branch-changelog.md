## `docs/score-1-names-what-it-prevents` changelog

### Branch title

The score-1 band asks what a change prevents instead of accepting that nothing changes

### Branch ID

20260807-201019

### Branch type

docs

### What does the change on this branch bring to main?

The bottom band of the significance rubric now reads *"cosmetic, or prevents a failure that has not
happened yet -- then name the failure, because that is the only part a later reader can use"*. It read
*"cosmetic or preventative -- nothing changes for them today"*.

**The old half-sentence invited the exact sentence the rubric exists to prevent.** Measured on
[PR #503](https://github.com/DaveKJohn/claude-code-specialists/pull/503)'s own entry, whose tier 0 read
"Nothing changes here" -- technically inside the band, and worth nothing to a reader a year later. Four of
the five bands describe something the reader can **observe**; this one describes an **absence**, and an
absence has to be named or it cannot be told apart from having nothing to say. So the band now asks for the
one thing that survives: what did not happen because of this.

**The gate that was NOT built, recorded so nobody builds it later.** Dave's question behind the issue was
whether tier 0 scoring below tier 1 should be refused at all -- if nothing changes for this repo's own
developers, how can it change for anyone further out? The general claim does not hold, and PR #503 is the
counterexample: that defect existed **only outside this repo** (consumers had no `branch/templates/`; this
repo always did), so it was worth 4 to a consumer and almost nothing here. **The tiers are not nested
audiences** -- a consumer is not a colleague of this project -- so the gate would have refused a correct
entry. The instinct behind it is already encoded one level down and correctly: **tier 0 is the one tier
that cannot be `N/A`**, because every change reaches this repo's own developers at least a little. The
floor is a score of 1, and band 1 now asks what that 1 buys.

The reasoning sits in three places on purpose, each for its own reader: beside the rubric in
`entry-scaffold-lib.ps1` for whoever edits a band, in `CLAUDE.md` for whoever wonders why the scores may
run the "wrong" way, and in the issue for the audit trail. The band text itself is written **once** and
read everywhere -- `CONTRIBUTING.md`, the `new-branch` skill and the contract's default summary quote it,
and all three were brought along.

### Significance

#### Tier 0

Every entry written here starts from this rubric, and the band that was easiest to satisfy without saying
anything is the one that got harder in the only way that matters.

**Score:** 3

#### Tier 1

A changelog full of "nothing changes here" is a changelog that answers no question later. The prevented
failure is the half a colleague reads for.

**Score:** 2

#### Tier 2

The rubric is plugin-carried and printed by a consumer's own gates when they refuse, so their scaffolder
and their refusals ask the sharper question too.

**Score:** 2

### Pull Request

