## `feat/the-step-list-follows-the-sdlc-arc` progress

### Steps

#### PLAN

- [x] Answer the three questions #655 deliberately left open, against the code rather than by argument
- [x] Establish where the phases can live without touching the gate: `Get-BranchProgressFindings`
      reads step marks only, so headings are invisible to it
- [~] Treat DEPLOY as a fourth phase of this file -- dropped: Dave's answer is that DEPLOY is the
      result, not a step, so it is the changelog entry beside this file. Three phases here, the
      fourth across the pair.

#### CREATE

- [x] `StepPhases` + `FirstStepPhase` in the wording defaults, so a consumer can rename or disable them
- [x] `Format-BranchProgressScaffold` writes the headings into both the branch file and the template,
      and only the branch file gets the placeholder step
- [x] Extend the Steps guidance with the arc and with why DEPLOY is absent
- [x] `BRANCH-portable.md`: the convention, for every consumer
- [x] Regenerate the two templates and rebuild the plugin mirror

#### TEST

- [x] Prove the headings change no verdict: fresh scaffold 1 finding, resolved 0, template 0
- [x] Pin the phases, the placeholder's position, the empty-phase tolerance, and DEPLOY's absence
- [x] Lint gate green
- [x] All 36 test suites green

### Where I left off

#655 done, and this file is its own first application. Remaining in the yolo run: #657 (update Nolan's
measurement -- the always-on path has grown 158% since July 28) and #660 (blocked on a `read:project`
scope only Dave can grant; I deliver the design plus the script that runs the moment he does). Then
#669 closes with its evidence.
