### Open the 3.x overview section, and make the guardrail honest in both directions · Docs · 2026-07-30

Preparation for the 3.0.0 milestone: `releases/README.md` now carries a `### 3.x` section above `### 2.x`,
so the first `3.0.0` row lands under its own major instead of being filed under the previous one. That is
the deliberate act [#269](https://github.com/DaveKJohn/davekjohns-workshop/pull/269)'s guardrail refuses to
perform on anyone's behalf, and the reason it refuses is now stated in the overview's own intro rather than
only in a code comment.

**Opening the section made a flaw in that guardrail reachable, so it is fixed here.** The check compares
the release's major against the section a new row would land in, and refuses a mismatch — correct in both
directions, but the message only described one of them. With `### 3.x` on top, a `-Bump minor`
(2.16.0 → 2.17.0) now mismatches too, and the message would have said *"releases/README.md has no
'### 2.x' section yet"*. That section exists; it simply is not on top. **A guardrail that misdescribes the
repo teaches people to bypass it**, so the message now states only what it knows — which section the row
would land in and which release this is — and branches on direction:

- **new major above the target** (the ordinary case): print the exact heading and table to add.
- **new major below the target**: say that the section does exist but sits under a higher one, and that
  releasing an older major after a newer one has been opened is a decision the script will not make —
  move the row by hand after cutting, or reconsider the version.

**One test changed value, and that is the test doing its job.** The assertion on the live document
answered `2` — the pin that made *"a 3.0.0 cut would misfile"* a stated fact rather than an observation.
Opening the section flipped it to `3`, so the suite failed until the new invariant was written down:
*a 3.0.0 cut now lands under its own major, and a 2.x cut would be refused.* An assertion against the real
document is worth exactly this: it does not let a deliberate change land silently. Its comment now says to
update it, with a reason, whenever a major section is opened.

The empty `3.x` table carries one line of prose saying it is open with nothing cut yet — so a reader
meeting a header with no rows knows it is deliberate rather than broken.
