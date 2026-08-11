## `docs/the-reason-goes-above-the-score` changelog

### Branch title

Both guidance surfaces say the tier reason goes above the score line

### Branch ID

20260811-192004

### Branch type

docs

### What does the change on this branch bring to main?

The second half of inbound [#596](https://github.com/DaveKJohn/claude-code-specialists/issues/596): making a
tier reason written *below* its `**Score:**` line harder to write in the first place, rather than only
naming it once the gate refuses. The gate half shipped in `fix/tier-reason-below-score`; this is the half
that arrives before the author writes.

**Why the obvious implementation was not built, which is the part worth recording.** #596 suggested putting
the blank space above `**Score:**`, and that turned out to collide with a decision already written into
`Format-EntrySignificanceSections`: *"Not two blanks: the guidance used to occupy that space, and leaving its
surrounding whitespace behind is the shape that reads as 'something was deleted here'."* Reversing a recorded
decision is Dave's call, so it is reported rather than quietly overruled -- and the measurement that would
inform it is in the record now: one blank line on **each** side of the score, which is the whole reason the
two places read identically.

**#596's description of the scaffold was also measured rather than inherited**, and it was loose: it says the
score sits *directly* under the tier heading, so the only visible space is below it. Against the current
scaffold there is a blank line above too -- markdown requires one -- which is exactly what makes the two gaps
symmetric. The observation stands and its explanation needed correcting, the same discipline the three
inbound repairs on August 11 needed.

So the goal is delivered through the two places that already exist to say this kind of thing:

- **The tier guidance** now reads "Write it ABOVE the Score line -- everything below that line is
  discarded", and the `N/A` block says its reason goes above the line too. That text is an HTML comment
  standing exactly where the reason belongs in `branch/templates/`, regenerated from the wording rather than
  edited beside it, and overridable per repo through `Get-EntryGuidanceOverrides` like the rest.
- **`new-branch`'s scaffold-time printout** says it as one line under the rubric it already prints. This is
  the surface that matters most here: the working file carries no comments by decision (Dave, August 7,
  2026), so an author who never opens `branch/templates/` had nowhere to learn it. The argument is the one
  the rubric printout already makes in its own comment -- a gate that first states the rule when it blocks
  you has already let the guess happen.

**The assert is on the OUTPUT, not on the script's source.** A text assert keyed on an expression is what
made a correct change fail a test during #598's repair, so this one runs `new-branch` in a fixture and reads
what the author actually sees: that it says ABOVE, that it says what happens to text below, and that it names
the score label so the reader knows which line is meant. Nothing asserted that printout at all before.

**What is still open, and deliberately so.** Two shapes would make the mistake structurally impossible
rather than merely well-signposted: inverting the sub-section to score-then-reason, so the only empty space
IS the reason's; or giving the reason its own label the way the score has one. Both change the entry format
that folds verbatim into `CHANGELOG.md` and travels to consumers in the release documents, and both would
need the parser to read the old and new shapes side by side. Neither is built without Dave's word.

### Significance

#### Tier 0

An author here meets the rule at the moment the file is created instead of at the PR refusal, and the
printout is now guarded where it was previously asserted nowhere. It prevents the half hour #596 measured
elsewhere from being spent here.

**Score:** 2

#### Tier 1

A colleague on this project gains the same signposting, and -- more usefully -- the reasoning for why the
whitespace fix was declined is now in the record rather than being re-derived by whoever reads #596 next and
reaches for the obvious change.

**Score:** 2

#### Tier 2

Consumers receive both surfaces through a plugin update: the regenerated template and the scaffolder's
printout. The reporting repo wrote a local documentation block to stand in for exactly this, closing with a
note that it should disappear once the fix returns -- it can go now.

**Score:** 3

### Pull Request
