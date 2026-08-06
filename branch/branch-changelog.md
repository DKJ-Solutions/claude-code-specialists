## The impact table becomes a Significance section with one sub-heading per tier

### What does this change do?

`### Who is this for` and its impact table are replaced by `### Significance`, holding one
`#### Tier N` sub-section per reach the change claims -- each with why it matters at that reach, then
its score, then a question asking whether there is a next tier:

```text
#### Tier 0

The routine version bump stops needing a developer.

Score: 4

Is this change also relevant to colleagues and employers? Then continue to Tier 1.
If not, stop here and move on to the next section.
```

**The table went because it forced a rectangle onto something that is not always rectangular.** Not
every change has a tier 1 or a tier 2. In a table that absence is a missing row, which reads as an
omission; as a section it is simply absent, which reads as an answer. The heading stopped naming an
audience for the same reason the shape changed: each sub-section names its own by its number, and what
the section carries is how much the change *weighs* for each of them.

**Every section closes by asking whether there is a next one, including one whose successor is already
below it.** An earlier draft wrote the question only under the last section, reasoning that a tier
whose successor exists has been answered. True of the author, false of every later reader: the entry is
walked again at the fold, at the cut and in the record, and a question that disappears once answered
leaves them unable to see that it was asked.

**Three shapes are read and one is written.** The sub-sections, the impact table, and the older
`Tier: N` line -- because `CHANGELOG.md` holds all three right now, every consumer's tree holds at
least one, and they reach the new parser through a plugin update rather than by choosing to. A parser
that knew only the newest shape would read every other entry as tier 0: silent, correct-looking, and
wrong in the direction that empties a release.

**The retired section heading is recognised too, and that one was measured rather than foreseen.** The
moment `Who is this for` became `Significance`, the lint reported all 24 pending entries in this repo's
own changelog as *misspelled* section headings -- its most alarming finding and its least true. Twenty-four
false accusations at once is how a check gets switched off rather than heeded, so a name-matcher now
accepts the retired names alongside the current ones.

Two defects were found by their own tests while building this, both worth naming because both fail
silently:

- **`[ref]` to a property of a `pscustomobject` writes to a copy.** The section reader collected its
  complaints through one, so every malformed section parsed, reported nothing, and fell through to the
  legacy reader as an undeclared tier 0 -- the exact failure class this parser exists to prevent, inside
  the parser. It returns the pair instead now, which cannot go wrong at all.
- **An entry whose every section is malformed has zero rows**, and falling through on that count alone
  would have discarded the complaints with it. Errors now count as "this entry used the section shape"
  just as rows do.

### Significance

#### Tier 0

Four readers of the entry format changed together -- the writer, the parser, the strippers and the lint
gate -- and the parser now recognises three shapes where it recognised two.

Score: 3

Is this change also relevant to colleagues and employers? Then continue to Tier 1.
If not, stop here and move on to the next section.

#### Tier 1

The declaration stops pretending every change reaches every audience. An entry that matters only to this
repo says so by having one section, instead of by leaving two rows visibly blank in a table that asked
for them.

Score: 3

Is this change also relevant to the people who consume this product? Then continue to Tier 2.
If not, stop here and move on to the next section.

#### Tier 2

Every consumer's entry format changes shape, and their existing entries keep working only because all
three shapes are still read and the retired heading is still recognised. Nothing they have written needs
rewriting; the next entry they write looks different.

Score: 3

### Type of change

Feat
