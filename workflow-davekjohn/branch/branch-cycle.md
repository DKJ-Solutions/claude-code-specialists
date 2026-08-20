# `feat/release-page-design` cycle · 20260820-050630

## PLAN

- [x] Read the reference edition the consumer offered, not the description of it -- its CSS is where
      the editorial decisions actually live
- [x] Decide how far to go on "no JavaScript at all", which is the one ask with a real cost behind it

## CREATE

- [x] The template rebuilt: collapsible index, one chip per row, serif masthead, the reflow, the
      `noscript` block -- and the tested markdown renderer carried over BYTE-FOR-BYTE rather than retyped
- [x] `Format-ReleaseIndexRows` builds the index server-side; `Format-ReleaseDate` makes the date
      readable with an invariant-culture parse and a pass-through fallback
- [x] `@@RELEASE_ROWS@@` added to the placeholder list the script asserts, so a template that loses it
      fails loudly
- [~] Rendering the note BODIES server-side -- not done: it needs a markdown implementation in PowerShell
      beside the one in the template, i.e. two renderers for one format. Stated on the page in `noscript`
      rather than left for a reader to discover
- [~] The logos the reference carries in its masthead -- dropped: they are that consumer's brand, and the
      palette seam is where a consumer's identity belongs now

## TEST

- [x] 19 new asserts on the index itself: one row per release, ALL closed, one chip, the reformatted
      date, static markup, the picker gone, an unparseable date passed through
- [x] The whole suite green: 84 asserts, 0 failed
- [x] `check-plugin-integrity.ps1` green, mirror rebuilt
- [x] Built from this repo's own 24 notes and inspected: 24 rows, 0 open, 0 placeholders left

## DEPLOY

- [~] Merging -- deliberately NOT done: this produces a visible result and no gate can prove a page looks
      right, so the branch reports and waits for Dave's eye

## Where I left off

The PR is open and not merged, which is the rule for a visible result rather than caution.

**Open it here:** `workflow-davekjohn/releases/page/release-notes.html` (gitignored, so it is a local
build). Worth checking three things by eye that no assert can reach: whether 24 closed rows read as an
index or as a wall, whether the serif heading over a sans page is right for this document, and the reflow
under about 600px, where the title moves to its own line.

Two things I did NOT do, both on purpose. The note bodies are still rendered in the browser -- going fully
script-free means a second markdown implementation, and that is not a design pass. And no artifact was
published: that would put the content on an external service, which needs your word.

One mistake worth recording: I started writing this design on the guard branch while that branch was being
merged. Caught before anything rode along -- stashed, then popped onto this branch -- but the tree was
briefly dirty on a branch mid-ship, which is exactly the state `ship-pr` steps through.
