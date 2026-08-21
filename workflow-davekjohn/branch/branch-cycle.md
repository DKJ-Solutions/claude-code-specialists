# `docs/v4-18-0-timing-total` cycle · 20260821-221409

## PLAN

- [x] Read the three legs the first pass could not see from their own timestamps rather than reconstructing
      them: the note's gates and push, PR #828's `createdAt`/`mergedAt`, and the Release's `publishedAt`.
- [x] Check the legs sum to the total before writing either -- 43m 55s + 4m 37s + 14m 19s + 42s = 63m 33s.
- [x] Re-read PR #828's own check timings, which is what turned this from an addition into a correction.

## CREATE

- [x] Add the total and the three legs to the release note.
- [x] State the two inverted readings as mechanisms rather than numbers: a blocked cut moves work into the
      head, and the unmeasurable share only looks small because the head was large.
- [x] Correct the first pass's claim about which check governs the merge wait, in both the timing block and
      the open section, rather than leaving an even split that one more reading contradicts.
- [x] Extend the standing attachment line to say the second pass corrected a reading, not only that it added
      a number.

## TEST

- [x] Every figure traceable to a timestamp or a `gh` reading, not to a stopwatch impression.
- [x] The corrected paragraph names both pull requests and both check durations, so the tally can be checked
      rather than taken.

## DEPLOY

## Where I left off

Done. This is the last step of the v4.18.0 cut. Publishing the marketplace to the business organisation is a
separate decision and was not asked for.
