## Branch `feat/changelog-newest-first` changelog - 20260816-185937

### What does the change on this branch bring to main?

#### Tier 0

`CHANGELOG.md` reads **newest first**. It was ordered on reach and significance -- furthest-reaching change
at the top, highest score within a tier -- which is a ranking, and the document is a record. The fold now
inserts every entry at the top of the list, and the seven entries pending from before the change were
re-sorted once into the order they actually landed, taken from the fold commits on `main` rather than from
PR numbers in the entry text (an entry body may quote another PR's number, and two of these do).

**The ranking looked load-bearing and was not, which is the part worth keeping.** Its whole argument was
that the cut *empties* this list, so document order at cut time is what the release documents inherit.
That held for exactly one section: `Build-ReleaseNotes` passes `-RankByTier` for every tier from 1 up and
`Build-ConsumerNotes` always ranks at tier 2, so both re-rank from the scores themselves and inherit
nothing. The one section that does inherit is the development notes' **tier 0** -- whose own comment asks
for *"complete and chronological, which is what a record is for"* and which was quietly receiving
score-descending order instead. So this makes that comment true rather than removing a guarantee. Before
removing a mechanism, check which of its stated consumers actually consume it.

The significance scores are untouched and still decide both what the release documents lead with and the
version bump. `Get-ImpactInsertOffset` is renamed `Get-EntryInsertOffset` -- a function that ignores impact
should not be named for it -- and still accepts `-Score`/`-Tier`, which it ignores, because every
consumer's fold passes them today and a removed parameter would throw on the trunk right after a merge.

**And the entry heading's stamp lost its quotes**, which it had carried since that morning.

The fence-awareness asserts had to be re-aimed rather than deleted: they proved it through the *rank* -- an
entry landing below the one whose body quotes a heading -- and with every entry landing at the top, that
reasoning is gone while the danger is not. They now pin that the top is the real first entry and never the
heading quoted three lines into it.

**Score:** 2

#### Higher than tier 0?

A consumer's own changelog starts reading newest-first at their next plugin update. The seven-entry
re-sort here is not something they inherit -- their pending entries stay where their own folds put them,
and every future one lands on top. Their release documents are unaffected, because those already rank
themselves. No migration, and nothing they have to do.

**Score:** 2

### Pull Request

CHANGELOG.md reads newest first, and the entry stamp drops its quotes
