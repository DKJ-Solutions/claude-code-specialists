## `docs/doctrine-layer-and-evidence` progress

### Steps

#### PLAN

- [x] Measure the layer table's claim against its own wording before repairing it — the claim names
      four categories and dates are not among them, which is what showed the report had over-counted
- [x] Measure the block to be moved before moving it: 9,440 B over 102 lines, 26% of `CLAUDE.md`

#### CREATE

- [x] `#701` — re-measure the counts (15/4/4, 250 references), state the date and the method in the
      table, and record the superseded figures as the instructive failure rather than deleting them
- [x] `#701` — make the claim true: move the two person names to the lenses that should hold them;
      note the one `vX.Y.Z` that is an invented example rather than a real version
- [x] `#715` — move the 102-line evidence block verbatim to Sylvester's lens under its own heading,
      leaving the operative rule and a pointer in `CLAUDE.md`
- [x] `#712` — the portable rule into Tessa's manual, the measured instance and the two at-risk
      figures into her lens
- [~] Add the writing rule to `CLAUDE.md` as well — dropped: it would grow the always-on path in the
      same commit that trims it, and the manual is where a convention about writing belongs

#### TEST

- [x] The gate caught a wrong anchor on the first run -- the heading carried an em dash and an
      apostrophe; simplified the heading rather than guessing the slug, and it passes
- [x] Re-measured after the edits: 0 issue numbers, 0 person names, 0 repo names across the 19
      manuals and personas, so the table claim now holds
- [x] `check-plugin-integrity.ps1` green (0 errors)
- [x] full test suite green

### Where I left off

