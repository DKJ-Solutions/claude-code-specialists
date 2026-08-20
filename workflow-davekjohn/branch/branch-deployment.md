## `feat/release-page-design` deployment

### What does the change on this branch deploy to main?

The release-notes page stops being a viewer and becomes a **document**. It showed one release at a time
behind a `<select>` with prev/next buttons; it now shows every release as a **collapsed row** — version,
one chip, title, date — and the row *is* the index. The reasoning is the reader's rather than the
builder's: somebody opening this wants the shape of a quarter before they want one version, and a picker
hides exactly that.

Reworked from the hand-edited *management edition* a consumer had already put through several editorial
rounds and offered as reference material on inbound
[#759](https://github.com/DaveKJohn/claude-code-specialists/issues/759). What came across, and why each
one is a decision rather than a preference:

- **Every row starts closed.** Their own last correction: four expanded notes at the top buried the other
  thirty-six.
- **At most one chip per row** — `live` where the history table marks it, the bump type otherwise, never
  both. Forty rows carrying two chips each read as a table of metadata rather than as a list of changes,
  and the version number already says whether a release was major or patch.
- **The summary reflows to two lines under 38rem**, the title taking the full second line because it is
  the longest field, the date staying on the first because on this page it carries the ordering. The tap
  target gets *larger*, which is the point.
- **A serif heading over a sans page**, because this is a record somebody reads rather than an interface
  they operate — and no web font, so it is the platform serif stack, which is what makes it usable at all.
- **The date is reformatted**, `2026-08-14` to `14 Aug 2026`. Parsed exactly and with the invariant
  culture so the output cannot change with the machine that built the page; anything that does not parse
  is passed through untouched rather than guessed at.

**The index is built server-side, and that is the structural half.** Version, date, type and title all
come from the history table, so the whole index is now static HTML — it reads with JavaScript off or
broken, where this page previously rendered **nothing at all**.

**One half-measure, stated rather than hidden.** The note *bodies* are markdown and are still rendered in
the browser, on first open, by the same small renderer as before — carried over unchanged, because it is
the tested part. Going fully script-free would need a markdown implementation in PowerShell beside the one
in the template: two renderers for one format, which is a bigger change than a design pass and the one
place the reference edition had it easy by being hand-written. So without JavaScript you get the complete
index and empty notes, and a `<noscript>` block on the page says so instead of leaving an empty panel to
be read as a failure.

**This does not merge on its own.** It produces a visible result, and no gate can prove that a page looks
right — so the branch stops here and reports. Built from this repo's own notes for that purpose:
`workflow-davekjohn/releases/page/release-notes.html`, 24 rows, 259 KB, every row closed.

**Score:** 4

#### What makes this change extra special

The page is the artefact a consumer hands to management and a commissioner, and its whole shape changes:
where they had a picker they now have an index, and the link they hold keeps working because the deep-link
fragment is still `#v4.11.0` — the id is written verbatim rather than slugified for exactly that reason.

It also completes what the palette seam started earlier tonight. #759 was one request with two halves, and
the seam alone was not enough: handing a generated page to the worker that serves the hand-edited edition
would have given management a **branded page with a picker where they had an index**. With both halves, the
hand-edited copy can be deleted — which ends a second source that has already drifted once, serving
pre-renumbering version numbers to management for five days.

**And the suite is the part worth reading twice.** All 65 asserts passed before this branch changed a line
of layout, because every one of them reads the *data* — order, dates, types, the escaping — and none could
see a `<select>` become a list. A design decision no test can fail is one the next change quietly reverts,
so this adds 19: one row per release, all closed, one chip, the reformatted date, the static markup, the
absent picker, and the unparseable date passed through. The last of them strips HTML comments before
looking, because the template's doc comment *names* the `<select>` it replaced — mention versus use, for
the third time in this page's history.

**Score:** 4

### Pull Request

the release-notes page becomes one scannable index
