## `fix/a-description-names-the-work-not-the-repo` progress

### Steps

- [x] Measure which surface C3 is really about: 751 of 1,004 occurrences are in shared blocks, and
      only 42 are in the always-loaded descriptions
- [x] Find the rule by comparing the two shapes already present: instrument-as-definition (Edith)
      versus instrument-as-occasion (Nolan). Rewrite only the first kind.
- [x] Rewrite the four reviewers plus Ravi, and normalise the landing boundary across the rest
- [x] Re-measure: 42 -> 20, +268 bytes
- [x] Establish that the remaining 20 are correct -- a repo genuinely being the subject -- rather
      than leftovers
- [x] Lint gate green
- [x] All 36 test suites green
- [~] The 253 occurrences in the bodies -- dropped: a body is read after the specialist has been
      chosen, so it neither excludes anybody nor costs a reader anything.
- [~] The five shared blocks -- dropped for this branch: they carry the family's constitution
      (inbound route, way of working), which is repo-shaped because the rule itself is. Rewriting
      them is a change to what the rules SAY, not to how they are worded, and that is Dave's call.

### Where I left off

C3 done. Remaining in the yolo run: #657 (Claude Code best practices measured against what this repo
already does) and #655 (the four SDLC phases in the step list). #660 stays parked; §E stays open with
its decision note.

