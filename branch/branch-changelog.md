## `fix/the-gate-names-the-shape-it-refuses` changelog

### Branch title

The significance gate names sections instead of columns in the shape that replaced the table

### Branch ID

20260811-195856

### Branch type

fix

### What does the change on this branch bring to main?

`Get-EntryImpactFindings` refused a section-shaped entry with table vocabulary: `fill in the third
column`, `in that row's second column`, and `add a '| 1 | <1-5> | <why> |' row` — three separate
strings, all pointing at a table this format replaced on August 6, 2026. The author meeting that
refusal is the one person who cannot check the claim, because the file in front of them has no
columns to count. Same class as inbound #596: a refusal naming something that is not there.

**All three are now worded in the shape the entry actually uses**, and the discriminator is a new
`Shape` property on `Resolve-EntryImpact` (`sections` / `table` / `line` / `none`). It was needed
because the nearest existing discriminator, `WhyBelowScore`, lives on a **row** — so the one refusal
that fires when a tier has no row at all had nothing to read. `Table` keeps its meaning, since every
existing caller asks it *"is there a declaration"* rather than *"which one"*.

**The test is "is it a table", not "is it the current shape."** A real table has the three columns, so
its own wording is the accurate one and keeps it — "recognise both, write one" applies to the advice as
much as to the parsing, and every pre-section entry in `CHANGELOG.md` and in every consumer's tree is
still read. The `Tier: N` line and an entry declaring nothing get the **section** wording rather than a
third variant: neither has anywhere to put a score, so the only move that resolves the refusal is to
write the shape this format writes.

The missing-section refusal quotes `Get-EntryTierSectionMarker`, a new helper the **formatter** writes
its headings from as well — a refusal telling an author to add a heading the writer spells differently
would be the same defect one level down. It replaces the last two hand-built copies of that string.

### Significance

#### Tier 0

The three strings and the marker helper are all in one shared lib, so a developer here now gets advice
that matches the file they are editing — and the two hand-built heading copies that could have drifted
from the formatter are gone.

**Score:** 3

#### Tier 1

A colleague writing an entry on this project meets the refusal at `open-pr`, days before the cut would
meet it again. Previously it sent them looking for columns in a file made of headings; now it names the
`**Score:**` line the answer actually goes above.

**Score:** 3

#### Tier 2

The lib is mirrored into `workflow-davekjohn`, so a consumer running `open-pr` or `cut-release` on an
entry in the current shape received the same misdirection — and they receive these scripts through a
plugin update rather than by choosing to. Noticed the moment they hit the gate.

**Score:** 3

### Pull Request

