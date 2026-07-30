### A major bump would file its row under the previous major · Fix · 2026-07-30

Found by a question rather than a failure: *"is it correct that no `3.x` directory has been created yet?"*
The directory is fine — `cut-release.ps1` creates it itself. The **overview section** is not, and that one
does not create itself.

`releases/README.md` groups releases by major (`### 2.x`, `### 1.x`, newest first, each with its own
table), and the row inserter matches the **first** `| Version | Date | Type | Title |` header it finds.
That is correct for every minor and patch, because the current major's table sits at the top. On a **new
major** there is no table yet, so a `v3.0.0` row would be filed neatly under `### 2.x`. Nothing errors,
nothing looks wrong, and the one document whose entire job is to say which release is which would be
quietly incorrect.

**It has never been hit, and could not have been.** Grouping-by-major arrived in **v2.0.1** — one release
*after* `v2.0.0`, the only major this repo has ever cut. So a major has never met this structure. The code
knew: the comment above the inserter already said *"a brand-new major starts a new top section manually
first (a deliberate milestone moment)"*. A manual step that is documented in a code comment, needed once
per major, and silent when skipped is a step that will be skipped.

**So it now speaks up.** `Get-OverviewTargetMajor` (pure, in `release-lib.ps1`) answers where a row would
actually land, and `cut-release.ps1` refuses a mismatching major **before writing anything** — placed with
the other guardrails on purpose: the row insertion happens *after* the notes file exists, so failing there
would leave a release half-cut. The error prints the exact heading and table to add.

Two details in the pure function that are easy to get wrong:

- **The answer is the last section heading *before the first table*, not the first heading in the file.**
  That is precisely the section the inserter writes into; deriving it any other way would be a second
  definition of the same thing, free to drift from the first.
- **No table at all, or a table with no section heading above it, returns `$null` and the guardrail stays
  silent.** An ungrouped overview is a different shape, not this failure, and a guardrail that fires on it
  would block a release for no reason.

One assertion is deliberately about the live document: **this repo's own overview currently answers `2`** —
which is the test stating, in the suite, that a `3.0.0` cut *would* have misfiled until now.

**And one lesson from writing the test, which cost a failing assert to learn.** The header pattern requires
a newline *after* the separator row. A fixture built by joining lines without a trailing empty element has
no such newline, so the function correctly returned `$null` and the test read it as a bug in the function.
**A fixture that is not shaped like a real file will accuse the code of its own defect** — noted in the
test itself, next to the trailing `''`.
