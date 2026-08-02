### A measured figure in prose names what it was measured on · Feat · 2026-08-02

Check 16 (`[measured-figure]`), and the decision the previous entry deliberately left open. That entry
recorded round v12's lesson as a craft rule and said the narrow, buildable half — *a measured figure in
prose names what it was measured on* — was a separate call. Dave made it; this is it.

**The gap it closes.** Check 15 holds captured samples **inside a fence**, because a fence is a markup
boundary a gate can see. Round v12 found the identical staleness class in running prose, where there is
none: [#374](https://github.com/DaveKJohn/davekjohns-workshop/issues/374) and its unfiled twin one section
further down, which carried three byte figures from a single machine — including `~/.claude/settings.json`
at 22 bytes, on a page read by consumers whose profile had never created that file. Accurate when captured;
unfalsifiable by the reader, because nothing said whose machine it was.

**Why this half is gateable where "is this prose accurate" is not.** The check judges no claim. It asks
whether a binding sits near a figure whose *shape* is unambiguous: a byte count or a file size is always a
measurement of something, so there is no authored, non-measured reason to write `939,860 bytes`. The
haystack was enumerated before the rule was written, exactly as check 15's was — **9 figures across 8 lines
in the three consumer-facing documents**, small enough to check by hand and compare against what the gate
then said.

**What it found on its first run, and both were real.** `(measured: 2.9 MB, gone)` in the opening warning —
a decorative figure whose size was never the point, now replaced by a pointer to the #339 table where the
same measurement sits *with* its profile. And a figure leaning on `on the same profile`, whose antecedent
lived two blocks up: true, but the kind of binding that dies the next time a section is edited in
isolation. Both are now self-sufficient. Seven of the nine passed and were left alone.

**Three design decisions, each pinned by a test rather than left to erode.** The window is the *block
neighbourhood* — the paragraph either side of the figure's own block — so a table row is bound by its
intro paragraph or by the note beneath it, without a line count that has to guess how many rows a table
has; and it **stops there**, so a date in an unrelated subsection cannot satisfy the gate. A figure inside a
fence is check 15's and is not counted twice. And `measured` on its own is **not** a binding, for the same
reason check 15 rejects it: it says the author saw the number, which was true of every finding either check
exists for. A false-positive guard is pinned too — `byte-identical` carries no leading digit and is not a
figure, because a gate that flagged a plain English word would train writers to paste opt-outs over prose.

Fourteen asserts, in both failure directions. The opt-out (`<!-- unbound-figure: <reason> -->`) must name a
reason, mirroring check 15's, and the coverage line reports figures examined rather than times the check
ran — so the gate cannot report green while asserting nothing.

**One thing tidied in passing.** Checks 15 and 16 hold the same class on the same three documents and
differ only in where they look, so the document list is now **one** `$consumerDocs` variable instead of two
identical arrays. Two copies would have drifted the moment a fourth document joined — this round's own
lesson, arriving in the source of the check written to enforce it.
