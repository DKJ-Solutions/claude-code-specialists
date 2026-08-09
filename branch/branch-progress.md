## `docs/v3-10-0-release-documents` progress

### Steps

- [x] `releases/internal/3.x/3.10.0.md` -- what the organisation gets, not what changed. Its "what was
      still open" section is written as a snapshot of today, per the skeleton's own warning
- [x] `releases/highlights/3.x/3.10.0.md` rewritten from the 593-line draft to 92 (Tessa): the action
      first, then what is new, then the repairs. Everything internal stripped -- tiers, scores, branch
      names, PR numbers, gate names
- [x] The highlights carry the trap a mechanical rename hides: no old id was a workflow, so a consumer
      who never ran the old workflow plugin gets every team back and silently none
- [x] Stated as a property of the mechanism rather than by naming which repos are in that position --
      who is in it is this project's register, not the reader's business
- [x] Gates green: lint 0 errors, all 30 suites
- [x] Changelog entry: body + a score per tier

### Where I left off

The release documents for `v3.10.0`, cut and tagged earlier today (`3ee1f99`, tag pushed).

**Still to do, and covered by the instruction to cut the release:** publish the GitHub Release. The body
is the highest tier this repo has -- the highlights -- with the other notes attached; `gh`'s
release-notes body has a hard 125,000-character limit, which 92 lines are nowhere near.

**An operational lesson from this branch, worth more than it looks.** `new-branch` appeared to create
only the changelog and not the step list, and the cause was not the scaffolder: the run was piped
through `Select-Object -First 3`, which CLOSES the pipeline once it has its objects and can terminate
the child process with it. So a scaffolder that writes two files wrote one, and the truncation looked
like ordinary output trimming. Piping a script that WRITES through `Select-Object -First` is not a way
of shortening its output -- it is a way of stopping it early. Use `-Last`, or capture first and trim
after. The idempotent resume is what recovered it: a second run kept the written entry and created the
missing step list, which is exactly the property that made the mistake cheap.

**Not this repo's to do:** the three connected consumer repos and the second checkout on another
machine all still run the old plugin ids. Correct until each migrates, and the migration page is what
they follow.
