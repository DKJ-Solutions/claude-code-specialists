## `fix/a-missing-lens-is-not-a-gap` changelog

### Branch title

a specialist stops hunting for a repo lens that was never promised

### Branch ID

20260814-201852

### Branch type

fix

### What does the change on this branch bring to main?

Item **C1** of inbound [#669](https://github.com/DaveKJohn/claude-code-specialists/issues/669), and it is
the item with the strongest evidence in the whole report: **all four** specialists put on that assessment
hit the same friction first, independently and in the same order — look for the repo lens, fail to find
it, continue on the plugin source. Every agent def opens by naming
`.claude/specialists/lenses/<id>-extension.md` *"of the consuming repo — read that if you are unsure"*,
and in a session with no repo there is nothing for that file to sit in. Every specialist started on what
it read as half an instruction.

**Two halves, and neither works alone.** The pointer now says the lens is in the consuming repo **"if it
has one"** — a per-file edit, on the one string that turned out to be byte-identical in all 26 defs. And a
new shared block, `lens-optional`, says what to do about it: a lens you cannot find is an ordinary state,
so do not search for a substitute, do not report it as a defect, and do not treat the instruction as
half-delivered. Fixing only the pointer would leave each specialist deciding for itself what an absent
file means; adding only the block would put it under **Boundaries** contradicting a sentence twenty lines
above it.

**The carrier set is 26 agent defs and no persona, which is the mirror image of `filecontent-boundary`'s
reasoning rather than a copy of it.** A persona is loaded *through* the consuming repo's `CLAUDE.md`, so a
persona reading this block would already be proof that a repo exists — it would be reassured about a state
it cannot be in. Asserted in both directions, because a scope decision that is only checked one way is how
a per-block circle quietly becomes "everyone".

**Both edits were made by script rather than by hand**, which is the house rule and also the only honest
way to claim 26 of 26: the anchor was measured first (26 files, 26 occurrences, one per file), and the
sentinel insertion keyed on `filecontent-boundary` being the first block in every def — also measured,
26 of 26 — rather than on a line number.

### Significance

#### Tier 0

A specialist invoked here already finds its lens, so the hunt this removes is not one this repo sees. What
it does get is the scope decision written down beside the block and pinned by a test in both directions.

**Score:** 2

#### Tier 2

Every consumer of every team plugin gets specialists that no longer open on a promise the repo may not be
able to keep — and for a consumer *without* a lens tree, or without a repo at all, that is the difference
between a specialist that starts working and one that starts searching. Measured at four out of four in
the environment that reported it. They receive it through a plugin update rather than by choosing to.

**Score:** 4

### Pull Request

