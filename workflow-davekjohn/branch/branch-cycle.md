# `docs/lens-inbound-to-skill` cycle · 20260822-130440

## PLAN

- [x] Measured the always-loaded memory chain: 74,499 B / ~18.6k est. tokens across `CLAUDE.md`,
      `01-01-extension.md`, `01-01-persona.md` and `SPECIALISTS.md`. Largest single lever: the five
      inbound failure-pattern case studies in Chris's lens, 94 lines / 9,142 B, read only during a triage.
- [x] Confirmed the move fits the repo's own convention rather than only the size argument —
      `CLAUDE.md` already records that skills carry the evidence behind a procedure while personas and
      manuals carry none of it.

## CREATE

- [x] New skill `.claude/skills/triage-inbound/SKILL.md` — frontmatter plus the five case studies moved
      **verbatim**, so no measurement is re-worded in transit.
- [x] Lens `01-01-extension.md`: the 94-line block replaced by one bullet that keeps the rule resident,
      names all five patterns in a clause each, and points at the skill.
- [x] Fixed the forward reference the move broke — the `/lock` bullet said "the fifth inbound pattern
      **below**", which is no longer below.

## TEST

- [x] Verified no dead anchor: every inbound link into this lens targets `#the-dave-rules`,
      `#new-specialists--only-by-agreement` or `#chains-multiple-specialists-in-sequence`, all three kept.
- [x] `check-plugin-integrity.ps1` green -- 0 errors. It caught one real defect first: the moved block
      carried a sibling-relative link (`06-25-extension.md#...`) that broke on changing directory, now
      rebased to `../../specialists/lenses/`. Exactly the class of thing this gate exists for.
- [x] All 51 suites green, 208 asserts, 0 fail, 214s -- run via `Invoke-TestSuiteGate` at 18-way
      parallelism, the way ci.yml does it. 214s sits inside the 196-235s baseline Nolan re-measured
      on August 16, 2026. A first attempt spawned one cold process per suite and blew past 600s
      without finishing one; the gate function exists precisely so nobody does that twice.
- [x] Re-measured, and the estimate was wrong: net **~1,782 est. tokens**, not the ~2,255 projected.
      The projection counted the 94 removed lines and not the 15-line bullet replacing them, nor the
      126 tokens the skill description costs as resident. Corrected in the entry.

## DEPLOY

- [x] Nothing to deploy: the change is entirely repo-local under `.claude/`. No plugin payload moves,
      so no consumer receives anything and no version bump is implied.

## Where I left off

Gates, then PR + merge + fold. The one open judgement for Dave, recorded because it outlives this
branch: the evidence now lives in a **repo-local** skill. If he would rather consuming repos receive
these patterns too, the same block ships as `team-alpha` payload instead — that is a different change
and a different branch, not a widening of this one.
