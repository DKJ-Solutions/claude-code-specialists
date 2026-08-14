## `feat/chris-arrives-without-a-repo` progress

### Steps

- [x] Write `plugins/teams/team-alpha/skills/orchestrator/SKILL.md` -- read the persona, no script
- [x] Answer what the roster is without a repo, rather than leaving it silent
- [x] Say where the skill is the WRONG tool, so it cannot quietly compete with the `@`-import
- [x] `orchestrator-skill.tests.ps1`: the no-script property, the persona path, the repo pointer, and
      the deliberate absence of `disable-model-invocation`
- [x] Verify the no-script guard goes red when a script is added, then restore
- [x] Both `<!-- skills:all -->` spans in the README (the lint demanded them the moment the skill
      existed, which is the mechanism working)
- [x] Lint gate green
- [x] All 36 test suites green

### Where I left off

B1 is closed. Remaining in the yolo run: C3 (the vocabulary -- the shared blocks first, 751 of the
1,004 occurrences), then #657 and #655. #660 stays parked on Dave's word, and §E itself stays open:
this branch builds the recommendation's first step, not the second package.

