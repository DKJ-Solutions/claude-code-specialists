## `docs/rejected-path-check` changelog

### Branch title

The path-existence check, measured and declined

### Branch ID

20260809-194003

### Branch type

docs

### What does the change on this branch bring to main?

A README sweep found a title naming `specialists/scripts/`, a directory the plugin reorganisation had
removed. No gate sees that class: lint check 4 reads markdown **links**, and this was a path in inline code.
The obvious repair is a check — "a path in backticks must resolve against the tree" — and this branch
records why it is not being built.

**Five candidates, measured over 120 documents** with history excluded as in checks 11 and 12, each given
the most generous resolver a checker could honestly use (repo root, the document's own directory, and every
ancestor between): separator **and** extension → **124** findings; separator alone → **349**; extension
alone → **621**; either → **736**. Not one of the 124 was a true finding, and the narrowest rule does not
even reach the defect that prompted it — `specialists/scripts/` has no extension. Catching the one real
instance means adopting a rule born with 349.

**The reason is structural rather than a matter of tuning, and that is the half worth keeping.** Being a
plugin source, most paths this repo names correctly describe somebody else's repo: `.claude/extensions/…`
is the legacy lens location deliberately still documented for unmigrated consumers,
`config/settings_data.json` is a Shopify store's file in `team-shopify`'s manual, `PRETTY/[Emotie]/README.md`
is a life-hub folder. Each answers "no such file here" exactly as the stale title does — and the difference
is *whose repo the line is about*, which the line never states. An existence check reads "describes a
consumer" as "stale", and no regex recovers that.

**One narrow rule survived and is deliberately left unbuilt**: a title claiming a path must name its own
location. It needs no anchor guessing, because a document knows where it sits. Four subjects tree-wide, zero
findings today, and verified against commit `33a41a2` that it fires on the real defect. Four subjects is too
little to guard; the note says when to revisit.

Recorded rather than dropped so the next sweep does not re-propose what has already been weighed — the same
reason the entry-shape check's four rejected candidates are kept beside it.

### Significance

#### Tier 0

The proposal is an obvious one and will come back. Without the numbers beside it, the next person to notice
a stale path in prose — including whoever wrote this — reaches the same conclusion and spends the same
afternoon measuring it.

**Score:** 3

#### Tier 1

N/A — a rejected internal gate reaches nobody outside this repo's own maintenance, and nothing about the
product changes.

#### Tier 2

N/A — no consumer can observe a check that was not built. The documents they receive are unchanged.

### Pull Request

