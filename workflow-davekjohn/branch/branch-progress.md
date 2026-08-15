## `docs/v4-11-0-note-correction` progress

### Steps

#### PLAN

- [x] Verify the reported line at the target rather than against the previous note --
      `BWJ-ecommerce/claude-plugins-bwj` head `07a1eb9`, 2026-08-15T10:56:22Z, `team-alpha` at 4.10.0.
- [x] Grep the claim across the tree before editing the reported line (Tessa's rule): two sites only,
      `4.11.0.md:158` (false when written) and `4.10.0.md:116` (true when written, since overtaken).

#### CREATE

- [x] Correct the publication item in `workflow-davekjohn/releases/audience/4.x/4.11.0.md` and give the
      page a `## Correction to this page` section naming the date, the original wording, and the frozen
      attachment.
- [x] Write the distinction into `workflow-davekjohn/CLAUDE.md` beside the published-record rule it
      qualifies: the rule protects a line that was true when published, not one that was false when
      written.
- [x] Fix the same wrong characterisation in the pending `CHANGELOG.md` intro paragraph, which is not
      yet a published record.
- [x] Leave `4.10.0.md` untouched -- it is the stale twin and the worked example.
- [~] No check built for "a prose claim about an external repo's state must be verified". Dropped
      deliberately: this repo has already priced that shape twice (the 124-findings path check, the six
      false name-matching findings). The transferable part is the habit, and it is now written down.

#### TEST

- [x] Lint + test gates green before the PR.

### Where I left off

Correction and rule both written; the chain runs on to Edith, Derek and Rendall.

Two things deliberately left for the requester, both restated from the lock: **publishing v4.11.0 to
the organisation** has not been asked for, and if it is done the corrected line goes stale in turn --
which is now the documented, protected case rather than a defect. And **a cut** is not proposed; the
pending entries are all documents about v4.11.0.
