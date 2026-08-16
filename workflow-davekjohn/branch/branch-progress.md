## `feat/compact-changelog-entry` progress

### Steps

#### PLAN

- [x] Read the hand-edited template as the spec, and settle the two questions it left open: where the PR
      title comes from (Dave: under `### Pull Request`, since it was always the PR title), and what the
      audience tier's heading says when the template must suit any repo
- [x] Measure the blast radius before touching anything -- 6 production files, 10 test suites

#### CREATE

- [x] Split written from recognised: `Get-EntryWrittenSectionKeys` is the two the scaffolder emits, while
      `Get-EntrySectionHeadings` keeps answering for all six so older entries stay readable
- [x] The heading carries the creation stamp and a `Branch` lead; `Get-BranchFileDeclaredBranch` reads
      past the lead, which is the idempotency test and would otherwise overwrite somebody's step list
- [x] `Format-EntryBlock` writes the two sections; the tier sub-sections sit under the question they answer
- [x] `#### Higher than tier 0?` for the audience tier, resolved on read from `Get-ReleaseAudienceTier`;
      a repo that has stated none keeps the numbered headings, so an unconfigured consumer sees no change
- [x] `Get-EntryPrTitle` reads the title from either home, skipping the two lines the fold appends
- [x] `Resolve-EntryType` reads the branch prefix off the heading, guarded to a `changelog` heading
- [x] The unknown-prefix fallback (#410) moves to the reader, with `Chore` as the lib's own default
- [x] `Get-EntryScaffoldFindings` measures the empty PR title -- the section is no longer empty by design
- [x] `Get-EntryOpeningSectionKeys`, after the split-entry rule accused all six pending entries
- [x] Regenerate the plugin mirrors, which is what a consumer actually receives
- [~] A migration of the entries already in `CHANGELOG.md` -- not needed and deliberately not built: every
      retired heading is still read, which is what the three untouched suites prove
- [x] Docs: Rendall's lens, `CONTRIBUTING-portable.md`, the `fold-changelog` skill and `CHANGELOG.md`'s intro

#### TEST

- [x] Hold the generated template against Dave's file: byte-identical
- [x] Round-trip the PR title across both shapes, the fold footer, the injection payload and the template
- [x] Update `entry-scaffold`, `new-branch` and `check-plugin-integrity-docs` to the new shape
- [x] Full gate: 43 suites green in 163s, lint 0 errors

### Where I left off

Done and green. The one thing worth a second pair of eyes is the design decision underneath the
compaction: the tier reasons are now the entry's description, so what a consumer-facing document
publishes is the audience tier's reason rather than a separate paragraph.
