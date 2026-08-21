# `docs/v4-18-0-release-note` cycle · 20260821-214844

## PLAN

- [x] Read the generated draft end to end -- all fifteen entries, 1,100 lines -- rather than skimming, since
      the rewrite has to be faithful to substance it is compressing by three quarters.
- [x] Take v4.17.0's note as the structural model: front matter, the audience section, the two organisational
      sections, and where the timing paragraphs sit.
- [x] Decide the ordering. The four sync repairs merge into one section (one script, one update, one dry run);
      the two items that change what a consumer's tooling REFUSES rank above the ones that only add a
      capability.

## CREATE

- [x] Rewrite the audience section against the seven tests: second person, what the reader can now do, most
      urgent first, "no action needed" said out loud rather than inferred.
- [x] Verify every mechanism the page tells a reader to invoke against the tree, not against the entry body it
      came from.
- [x] Write *What it is worth* and *What was still open*, with each figure read at its source
      (`check-connectors.ps1`, the publication target's own `plugin.json` files, `gh issue list`).
- [x] Write the first timing pass: the clock start, the four measured legs, the subtotal, and which of them
      blocked a person.

## TEST

- [x] No link into `releases/development/` or `releases/internal/` -- test 7 is the one the lint gate enforces.
- [x] No leftover draft comment or `DRAFT` marker from the generated file.
- [x] 1,100 lines to 304, with the tier-0 material that the audience section may not contain left out rather
      than reworded.

## DEPLOY

## Where I left off

The note is written and the entry with it. What remains after the merge is the second timing pass -- the total
cannot exist until the publish has happened -- and then the GitHub Release with this document attached.
