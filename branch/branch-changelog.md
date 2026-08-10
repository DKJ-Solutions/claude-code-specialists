## `fix/notes-grouping-is-a-decide-record` changelog

### Branch title

Get-ReleaseNotesGrouping is a decide record, because it describes a repo's tree

### Branch ID

20260810-095725

### Branch type

fix

### What does the change on this branch bring to main?

`Get-ReleaseNotesGrouping` moves from `copy` to `decide` in the script contract, so `adopt-config` asks a
consumer where their release notes are foldered instead of writing this repo's answer into their seam
unseen (inbound [#560](https://github.com/DaveKJohn/claude-code-specialists/issues/560)).

**The old marker was justified on the value, not on the question.** `'major'` is also the built-in fallback,
so copying it "changes no behaviour" — true of the value, and beside the point. The skill defines the two
markers sharply, and by its own definition this record was on the wrong side of the line: `copy` is *the
shared way of working, which asserts nothing about your repo*, `decide` is *what a repo is*. This function
states what a consumer's `releases/development/` tree looks like, which puts it in exactly the family of
`Get-ReleaseHighlightsBumps` and `Get-ReleaseMajorMinMinors` — both `decide` from the start.

**Measured in a consumer, which is what makes it more than a taxonomy argument.** `smartwatchbanden` has
foldered per **minor** since `v2.0.0` — fourteen directories, `releases/development/2.0/` through `2.13/`.
`adopt-config` placed `'major'` into their seam, so their next cut would have started a **second** tree
beside the first (`releases/development/2.x/`) and written an overview row pointing at a path holding none
of their history. Nothing fails at adoption, and the contract check reports `[OK]` afterwards, because
`'major'` is a perfectly valid answer — just not theirs. The failure surfaces one release later, as a
directory nobody asked for.

**The `Returns` text now says the answer is a lookup rather than a choice**, which is the half that saves a
decider from guessing: a directory named `<X>.x` (`3.x`) means `major`, one named `<X.Y>` (`2.13`) means
`minor`. For any repo that has cut a release before, the tree already contains the answer — so the proposal
document asks a question that can be verified instead of one that has to be decided.

**What did not change:** the value this repo uses, the 22 contract records, and the check that reads them.
Only which document the record lands in — the consumer's seam, or the proposal a person answers.

### Significance

#### Tier 0

This repo folders per major and states so itself, so nothing here observes it. What it buys locally is one
fewer record whose marker contradicts the definition the skill prints two paragraphs above it.

**Score:** 2

#### Tier 1

The `copy`/`decide` split is the whole doctrine `adopt-config` rests on, and a misclassified record is worse
than a missing one: it makes the mechanism look like it asked. One record put back on the right side of a
line this project wrote down itself.

**Score:** 3

#### Tier 2

For a consumer this is the difference between adopting a value that is theirs and one that is this repo's,
with no signal either way until a release day. It also lands as *"you can read this off your own
directories"*, so answering it costs a look rather than a judgement. A consumer who already ran
`adopt-config` should check that one value — the reporting repo did, and corrected it locally.

**Score:** 4

### Pull Request
