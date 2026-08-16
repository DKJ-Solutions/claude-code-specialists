## `docs/gate-wall-clock-is-one-suite` progress

### Steps

#### PLAN

- [x] Verify #714 still stands before repairing it — re-measure the gate instead of accepting the number
- [x] Measure per-suite start/duration in the gate's own pool, so work distribution AND packing are visible

#### CREATE

- [x] Nolan #25's lens: the n=4 re-measure, the one-suite finding, the 8-lane result, the split's ceiling
- [x] Nolan #25's lens: correct the wall-clock table row (suite count, timing, the assert figure)
- [x] Chris #01's lens: fourth instance of the fifth intake pattern, plus "a timing is a count too"
- [~] Repair the gate itself — dropped here on purpose: splitting `check-plugin-integrity.tests.ps1`
      is a project on the most load-bearing suite in the repo, so it is proposed to Dave with its
      measured ceiling (-25%) rather than built inside a docs branch

#### TEST

- [x] Four repeat runs at `MaxParallel 16` plus one at 8 and one standalone — 40/40 suites green in each

### Where I left off

The lint and the suites run inside `open-pr` itself, so they are deliberately not a step here — the
gate reads this list before the push, and a box ticked for work that has not happened yet is the one
thing the third mark exists to prevent.

Open for Dave, both from today's pickup:

1. **#714's remaining half** — split `check-plugin-integrity.tests.ps1` so the gate stops being one
   suite (measured ceiling: 213s → ~153s locally, twice per release-with-document, nothing for CI).
   A project, not an edit; his call.
2. **#698** — the public repo description needs admin, which `davekokbwj` does not have (`gh repo edit`
   returns HTTP 404). Re-verified today; only Dave, signed in as the owner, can change it.

