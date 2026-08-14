## `fix/a-description-names-the-work-not-the-repo` changelog

### Branch title

a specialist description says what the work is before it says which repo instrument carries it

### Branch ID

20260814-222603

### Branch type

fix

### What does the change on this branch bring to main?

Item **C3** of inbound [#669](https://github.com/DaveKJohn/claude-code-specialists/issues/669) — *"the
vocabulary excludes the audience"* — built at a twentieth of the size the report estimated, because the
estimate counted the wrong surface.

**#669 priced this as making 15 agent defs, 4 personas, 15 manuals and 4 skills bilingual**, from a
sample of 68 passages carrying repo/branch/PR/lens language. Two measurements against the tree say
otherwise. First, **751 of the 1,004** occurrences across all 26 agent defs sit inside the shared
blocks — five source files, one edit each — and only 253 in a specialist's own text. Second, and this
is the one that decided the change: of those, exactly **42 sit in the `description`**, which is the only
part always loaded and therefore the only part a reader sees *before* deciding whether a specialist is
for them. That is the surface C3 is actually about. The rest of a body is read after the choice has been
made, where it costs nothing and buys nothing.

**The repair is not bilingual text. It is one sentence that is true in both worlds**, and the rule that
produced it is: **name the work, then the repo instrument as an example rather than as the definition.**
The two shapes were already both present, which is what made the rule findable — Edith's *"Use to
proofread a branch diff before the merge"* made the diff the definition of her craft, while Nolan's
*"when a diff measurably touches loading strategy"* used it as an occasion. The first kind says a
specialist has no work without a repo; the second does not. Only the first kind was rewritten.

So the reviewers now read *"the independent final look at changed content before it goes out … where the
work sits on a branch that is the diff before the merge"*. A developer loses nothing — the repo answer is
still there, one clause later — and a reader without a repo gets a description that includes them.

**Measured: 42 repo-bound words down to 20, for +268 bytes** across the always-loaded descriptions.

**The 20 that stayed are correct and were left deliberately.** They are the ones where a repo is
genuinely the subject rather than the instrument: the data analyst turning *this repo's* source data into
overviews, the front-end designer's *components this repo uses*, the systems administrator's safety
rules, the research specialist's codebase exploration, the technical writer not touching `git`. Removing
those would not widen the audience, it would make the description less true.

### Significance

#### Tier 0

The always-loaded description block grew by 268 bytes and nothing else here changes. What survives is the
rule and the measurement behind it, which is what a later reader needs when the next specialist is
written.

**Score:** 2

#### Tier 2

Every consumer's specialist list stops telling a reader without a branch workflow that four of the
reviewers have nothing for them. It is the layer they see first and the one they judge the team by, and
it now describes the craft before the plumbing. Nothing they wrote changes.

**Score:** 3

### Pull Request

