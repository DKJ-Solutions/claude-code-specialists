## `docs/chain-route-readable` progress

### Steps

#### PLAN

- [x] Verify #731 against `main`: subject, symptom, reason, proposed repair
- [x] Recount the flagged skills (report said 6; measured 10 of 13, 14 of 19 across six plugins)
- [x] Answer the harness question the report left open — `skillOverrides` does not affect plugin skills
- [x] Choose the target: `team-alpha` personas and `workflow-davekjohn/CLAUDE.md` both rejected, with reasons

#### CREATE

- [x] `new-branch/SKILL.md`: add the section listing the four following commands, route-not-licence framing
- [x] `INSTALL.md`: correct the `team-alpha` mis-attribution and replace "several" with the measured 14 of 19
- [~] No flag, script or governance change — dropped deliberately: the decision was to leave every flag as it is

#### TEST

- [x] `check-plugin-integrity.ps1` green locally — 0 findings, `[skill-command]` covering the 4 new command lines

### Where I left off

The full suite runs inside `open-pr.ps1`, so it is not a step here — the gate reads this list before the
push, and a step that can only be true afterwards has no honest mark. Remaining after the merge: the
fold, and a comment under
[#731](https://github.com/DaveKJohn/claude-code-specialists/issues/731) carrying the corrected counts,
since the report's own numbers are wrong and closing it in silence would teach its author nothing.

