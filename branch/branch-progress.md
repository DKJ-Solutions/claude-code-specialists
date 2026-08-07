## `feat/one-source-for-the-entry-shape` progress

### Steps

- [x] Measure which rule actually catches the drift #508 recorded, before building any of them
- [x] Build the check that survived the measurement: a claimed section COUNT is held to the scaffolder's
- [x] Repair the stale document the measurement found (`05-06-extension.md`, still describing the pre-dossier shape)
- [x] Test it: a wrong count is caught, a right one is silent, a count with no level marker is left alone
- [x] Record Dave's two decisions of August 7 -- the `origin-save` rename declined, and #508's direction
- [x] Mirrors, lint, suites

### Where I left off

Lint 0 findings (check 20 reports `checked 4`), all suites green.

**The measurement is the deliverable, not the check.** Three candidate rules were rejected by running them
against the real tree, and the one that reads best on paper -- match the retired section NAMES -- accuses
six correct documents. The reason is a collision nobody would predict: `What does this change do?` and
`Type of change` are retired entry sections AND live headings of `.github/pull_request_template.md`. If
this check is ever widened, run the candidate over the tree first; the scratch measurement scripts are
disposable and were exactly that.

**Two things bit during the wiring, both worth remembering.** `Get-BranchFilePaths` returns FORWARD slashes
while a scanned `$rel` is built from a Windows path, so an equality-based exclusion silently does nothing.
And a negative assert on `\[category\].*<filename>` can match the check's own COVERAGE line -- both new
negative asserts failed that way against a check that was correct. Match the finding's own words.

**The branch title was corrected mid-flight**: it promised the section NAMES would be held, and the
measurement moved the check to the COUNT. Since the title is now also the PR title (#506), leaving it would
have published a promise the change does not keep.

Next in the queue: #512 (gate time -- parallelising the suites) and #456 (the adoptable workflow blueprint).
