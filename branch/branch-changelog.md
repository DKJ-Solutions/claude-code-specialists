## `docs/check-20-and-inbound-catch-up` changelog

### Branch title

The check-20 paragraph and the inbound rule catch up with what shipped

### Branch ID

20260808-190626

### Branch type

docs

### What does the change on this branch bring to main?

Two documents said less than the mechanisms they describe now do, and one of them said it in the paragraph
that exists to explain a gate against exactly this.

**`CLAUDE.md`'s #508 paragraph.** It described check 20 as it was born — the section COUNT, not the names —
and stopped there, while [#525](https://github.com/DaveKJohn/claude-code-specialists/pull/525) had given the
check a separate pass over `CHANGELOG.md`'s intro with the level marker optional, and moved matching from
per-line to whole-text. Both are now stated, with the measurements that chose them: whole-text finds the
same **4** claims in the scanned tree as per-line, while dropping the marker tree-wide would find **50** —
which is why it is dropped across a dozen lines and nowhere else.

**A figure in that same sentence was wrong from birth.** It read that a name-matching rule *"accuses six
correct documents, because `What does this change do?` and `Type of change` …"*, pairing one measurement
with the other's reason. The lint's own candidate table has them apart: **6** was that rule's finding count
(all six false), **2** is the number of correct documents the PR-template collision accuses. Both numbers
entered the tree in the same commit, `e285c9b`, so the doc and the code have disagreed since the day the
check was written, with nothing to catch it: check 20 holds section counts and check 16 holds byte counts
and file sizes, and a finding count is neither.

**Chris's lens gains the second inbound failure pattern.** It documented one: the item was already
repaired, so verifying it closes it (#469). [#456](https://github.com/DaveKJohn/claude-code-specialists/issues/456)
is the other shape — everything it asks for still open, while three of its own load-bearing facts had
expired in the four days since filing. A standing item is therefore not automatically a routable one, and
the lens now says to check the reasoning as well as the symptom.

Plugins: none

### Significance

#### Tier 0

The paragraph explaining this repo's newest gate is the one place a developer looks before touching it, and
it described a version of that gate that stopped existing the day before. The wrong figure is the sharper
half: it is a measurement citing a real table, so it reads as verified.

**Score:** 3

#### Tier 1

Nothing here is legible outside this repo's own developers — `CLAUDE.md`'s gate paragraph and Chris's repo
lens are both this checkout's own governance, and neither travels to a consumer or to a colleague on
another project.

**Score:** N/A

#### Tier 2

No consumer-facing surface is touched: no plugin, no manual, no portable persona, no script.

**Score:** N/A

### Pull Request

