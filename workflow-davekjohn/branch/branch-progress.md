## `fix/dave-count` progress

### Steps

#### PLAN

- [x] Apply the same law to all three `CONTRIBUTING` layers and measure before concluding: root page,
      workflow layer, portable half.
- [x] Re-measure the disputed count with a command that counts occurrences and excludes the GitHub
      org, against the commit that was live when the claim was written (`5c1d1e4`), not against now.

#### CREATE

- [~] Change something in `CONTRIBUTING` — dropped: all three layers pass the law. The portable half
      measures 0 hardcoded trunk names, 0 mentions of `lint-en-tests`, 16 seam functions. Inventing a
      change here would be repairing to the assignment rather than to a defect.
- [x] `CLAUDE.md`: *fifteen times* becomes *throughout*, and the note against self-referential counts
      now covers the name as well as the word *portable* — one warning, both cases.
- [x] `CHANGELOG.md`: the folded #750 entry corrected to *fourteen*, with a dated correction note
      saying what it first said and where the figure came from.

#### TEST

- [x] `check-plugin-integrity.ps1`: 0 errors.
- [x] Full test suites.

### Where I left off

Nothing open.

For a later reader: the correction rule was checked before touching `CHANGELOG.md` rather than
assumed. `RELEASES-portable.md` distinguishes a line that **went** stale (protected — going stale is
the record working) from one that was **false when written** (not protected — correcting it restores
the record). This was the second kind, and the correction carries its date and its original wording
as that rule requires.
