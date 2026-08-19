## `docs/handover-transcription` progress

### Steps

#### PLAN

- [x] Decide which layer owns the lesson: the shipped `/handover` page or the repo lens
- [x] Portable, per the standing rule -- every repo using `/lock` can produce this failure

#### CREATE

- [x] Add the fifth verify question plus its measurement to `skills/handover/SKILL.md`
- [x] Keep only a pointer and the one repo-specific note in Chris's lens, rather than the rule twice
- [~] No mirror rebuild needed -- a skill page is not a shared script, and `build-shared-scripts -Check`
      confirms the script mirrors are untouched by this branch

#### TEST

- [x] Lint gate, including the dead-link check that reads both edited files
- [x] The suites that read the skill pages and the lens

### Where I left off

Done; gates green.
