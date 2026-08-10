## `fix/no-skill-ships-with-a-byte-order-mark` progress

### Steps

- [x] Verify #581 against the tree: confirm the BOM byte, confirm the symptom, and close the causal claim the reporter deliberately left open
- [x] Rule out the one alternative explanation (description length) before accepting the BOM as the reason
- [x] Strip the three bytes from `adopt-config/SKILL.md` at byte level, leaving the rest of the file untouched
- [x] Measure BOMs tree-wide to size the guard: 232 `.md` plus every `.ps1`/`.json`
- [x] Add lint check 26, reading the first three bytes so a BOM is visible to the gate for the first time
- [x] Prove the check fires by reintroducing the BOM, then restore the fix
- [x] Narrow the check to the BOM after the suite showed a "must have frontmatter" rule is born with two false findings
- [x] Complete the gate's docstring list, which had stopped at 22 while checks 23-25 were live
- [x] Regression test: BOM reported, cleared when stripped, frontmatter-less page not accused, `references/` page out of scope
- [x] Rewrite the check's comment block, which had accreted into a stale header and two contradictory "THE SUBJECT IS" paragraphs across successive edits
- [x] Lint + all 30 suites green

### Where I left off

**Work is finished and gates are green — parked on origin, no PR opened yet.** The lint reports 0 findings
over 69 documents on the real tree, `check-plugin-integrity.tests.ps1` passes 210/210 asserts (7 new), and
all 30 suites pass with 0 failing.

Next step when you resume: `open-pr` (it re-runs both gates), then merge and fold. Nothing else is
outstanding on this branch.

Note for whoever picks up the release: `plugins/.../adopt-config/SKILL.md` is plugin payload, so the fix
reaches consumers only on the next cut — a fresh consumer cannot reach the skill until then. And check 26
lives in this repo's own gate, which is **not** mirrored into any plugin: it guards the source, which is
where the byte was introduced, so consumers are protected by us no longer shipping one rather than by
running the check themselves.
