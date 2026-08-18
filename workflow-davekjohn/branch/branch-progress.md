## `docs/marker-literal-trap` progress

### Steps

#### PLAN

- [x] Establish where the trap is already documented. Result: fully explained in check 10's own comment
      in `check-plugin-integrity.ps1`, and nowhere an author writing prose would look. That comment
      names Tessa as the owner of the written convention, which did not exist.
- [x] Establish why it repeated. Result: both earlier repairs recorded the lesson in the branch's step
      list, which `fold-changelog-entry.ps1` resets -- so the record went out with the merge.

#### CREATE

- [x] A bullet in Tessa's lens (`06-16-extension.md`), beside the other sample conventions: what the
      check masks and why it cannot be widened, the two firings with dates, and the two ways past it.
- [~] A note in check 10's comment pointing at the lens -- dropped: the comment already names Tessa as
      the owner, so the pointer exists; what was missing was the document, which this branch writes.

#### TEST

- [x] `check-plugin-integrity.ps1` green -- including check 10 over the new bullet, which shows the
      bare marker text inside a fence and is therefore masked.
- [x] All suites in `scripts/tests/` green.

### Where I left off

Work is complete. Nothing beyond the ordinary PR -> CI -> merge -> fold.
