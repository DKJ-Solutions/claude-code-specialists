## `feat/bump-follows-the-tiers` changelog

### Branch description

The bump follows the tiers, and so does the audience of each note

### Branch ID

20260807-153354

### Branch type

feat

### What does the change on this branch bring to main?

The release bump is now read straight off the highest tier pending:

| highest tier pending | bump | documents |
|---|---|---|
| `0` | patch | the development notes |
| `1` | minor | + the internal note |
| `2` | minor | + the highlights, for consumers |

**Two rows changed, and both loosen the ladder by one step.** A release made entirely of tier-0 work used
to be **refused outright** -- the gate's reason was that such a release "has nobody to announce it to".
Dave's answer is that announcing nothing is precisely what a patch is for: the version moves, the record
is written, and no announcement is owed. And a **minor** used to demand a tier-2 entry, so tier-1 work
earned only a patch.

**The second was weighed rather than waved through.** It means a release can bump the minor with nothing
in it for a consumer, which is the opposite of what a minor usually promises. It was put to Dave that way
and chosen knowingly: the version here speaks to *all* stakeholders, colleagues included, not to consumers
alone.

**What keeps that honest is that the documents follow the TIER, not the bump.** A tier-1-only minor writes
the internal note and no highlights, so nobody outside is handed a document about work they cannot see.
That needed no change -- the highlights condition already required a tier-2 entry alongside the bump type.
What changed is its standing: it was belt-and-braces while a minor demanded tier 2, and is now the only
thing holding that line.

**A defect went in and came straight back out, caught by the suite.** The new refusal was written for
`minor` alone, which would have let a **major** through on tier-0-only work -- a bigger claim than the one
being refused beside it. Eight asserts failed the moment the rule changed, exactly the ones that encoded
it, and that was one of them.

### Significance

#### Tier 0

Two release outcomes that used to be impossible are now ordinary, so a maintenance week no longer sits
unreleasable waiting for something notable to land.

**Score:** 3

#### Tier 1

This is the rule that decides which release documents get written at all, and therefore what a colleague
ever hears about. Tier-1 work now earns a version of its own instead of riding along as a patch.

**Score:** 4

#### Tier 2

A consumer's version number will move for releases that contain nothing for them -- that is the deliberate
cost of the looser rule. What protects them is unchanged: they still receive a highlights document only
when a tier-2 entry exists, so the version moves without a document that has nothing to say.

**Score:** 2

### Pull Request
