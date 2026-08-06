## The intro is separated from the list by a horizontal rule

### What does this change do?

`CHANGELOG.md`'s intro is now followed by a `---` rule, so it is separated from the ranked list the same way
every entry is separated from the next. Before this, the intro ran into the first `##` with nothing but a
blank line between them — the one boundary in the document that was not drawn, and the most consequential
one, because it is where prose about the format stops and the record itself begins.

**The rule is hand-written into the intro rather than emitted by a script, and that is what makes it stick.**
`Convert-ChangelogForRelease` keeps the head verbatim — it is the property that lets a repo say whatever it
wants up there — so a cut that empties the list leaves this rule in place, and the next fold appends below
it. No script had to learn anything. The separators *below* the intro are the mirror image: the fold writes
`<entry>` + `---` after every entry it inserts, so those are machine-written and this one is written once.

**Nothing in the machinery reads it as structure**, which is why one line in the head is the whole change.
`Split-Changelog` derives the intro/list boundary structurally, at the first `##` heading, and strips
trailing blanks from the head; `Split-EntryBlocks` skips `^---$` lines between entries. So the rule is part
of the head, is never mistaken for an entry boundary, and reaches no release document.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 0 | - | - |

### Type of change

Docs
