## `docs/releases-readme-split` progress

### Steps

#### PLAN

- [x] Measure both trees before designing: root holds `development/` (104 notes) and `github/` (11
      bodies); the workflow folder holds `audience/`, `page/` and the release list.
- [x] Find the boundary that produces no overlap: the root page describes the **artefacts**, the
      workflow page keeps the **index, the seam values and the local decisions**, and
      `RELEASES-portable.md` keeps the **process**.
- [x] Safety check before adding a file at that path: confirm `Get-ReleaseHistoryPath` is set
      explicitly to the workflow page and not left at its shared default of `releases/README.md`,
      which would make the next cut write a release row into the new page.

#### CREATE

- [x] `releases/README.md`: the two directories, who writes them, the published-record rule by
      reference rather than restated, and the Dutch-history exception — verified against
      `1.x/1.0.0.md`, which is Dutch.
- [x] `workflow-davekjohn/releases/README.md`: one paragraph pointing down at the root page, saying
      why that page is the root's and not the folder's.
- [x] Root `README.md`: the `releases/` bullet corrected — it named a README that did not exist,
      linked it to a different path than its own label, credited it with cutting mechanics that moved
      to `RELEASES-portable.md` on August 13, and never mentioned `github/`.

#### TEST

- [x] Duplication measured, not assumed: 424 eight-word passages in the root page, 11 shared, 9 of
      them the same link path in sliding windows. The two real overlaps were removed, leaving 0.
- [x] `check-plugin-integrity.ps1`: 0 errors, and the new page is picked up by the gates — link-scan
      273 -> 274, mojibake 248 -> 249.
- [x] Full test suites.

### Where I left off

Nothing open.

One question deliberately not answered here, because it is a decision rather than a repair: **should
`adopt-workflow-folder` scaffold a root `releases/README.md` for a consumer too?** Their
`releases/development/` appears at their first cut and would be equally undescribed. Two things make
it a real decision rather than an obvious yes — a consumer who leaves `Get-ReleaseHistoryPath` at its
default puts the release **list** at exactly that path, so a scaffolded page there would have to be
the index rather than this artefact page; and the scaffolder never overwrites, so it reaches new
consumers only. That is Sylvester's, and Dave's to want.
