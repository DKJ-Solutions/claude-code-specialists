### a round's step-table totals are counted, not typed · Feat · 2026-08-02

`#371` fixed a hand-typed figure in a round's baseline table by measuring it. The table beside it —
the step table, whose totals line is what a whole round is hung on — was still counted by hand, and
was wrong in exactly the same way (inbound
[#387](https://github.com/DaveKJohn/davekjohns-workshop/issues/387)): the v12 line read *3 wrijving,
38 groen, 2 niet gemeten* over 43 rows while its own column held **4, 39 and 3 over 46**. One short
in every category — three rows added without the totals line following — and v13's assignment then
inherited it, naming three friction rows where the column had four.

`scripts/tests/round-tally.measure.ps1` counts the column instead, and prints the tally with the same
*generated, do not retype* marker the baseline block carries. Verified against the real v13 papers:
it reproduces v13's own line exactly (0 / 1 / 43 / 2 over 46) and independently confirms the v12
figures the finding reported.

**It has no vocabulary of its own.** No hardcoded status names, no hardcoded language, no hardcoded
markers: a cell that opens with a non-ASCII text element carries that marker, and the words after it
are that marker's label, taken from the table. So the tally cannot drift from the papers by holding a
stale idea of what "green" looks like, and a round scored in any symbols, in any language, counts the
same way. The totals come out as a table — one row per round — which is what makes comparing rounds
an output rather than a memory exercise.

Two properties are load-bearing rather than incidental, and both are pinned by tests:

- **Emphasis does not hide a cell.** The papers bold exactly the rows a round turned around, so
  reading `*` as the opening character would drop the four rows v13 was *about* while looking right
  everywhere else.
- **A markerless cell is reported, never dropped.** Older columns hold bare prose (`niet gemeten`,
  `niet opgetreden`). Counting them in no category is correct; staying quiet about them would produce
  a total that looks complete and is not — the same no-silent-caps rule the teardown's audit follows.

`-OutFile` writes UTF-8 without BOM, because a Windows PowerShell 5.1 redirect re-encodes stdout in
the console codepage and would put mojibake into the very block a reader pastes from.
