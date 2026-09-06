## fix/1500-stale-check-citations

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### What #1500 asked for, and what was verified before touching it

Two comment blocks in `scripts/lint/check-plugin-integrity.ps1` -- the changelog-path resolver at
`:771` and the lifecycle block at `:1482` -- label the readers of the resolved changelog path as
`(check 19)` and `(check 20b)`. Both labels name the wrong pass:

- The "entry-heading pass" is the section headed `# --- 13.`; the file itself calls it **check 13**
  at `:2507` ("derived the way check 13 and Split-Changelog derive it"), and so do
  `check-plugin-integrity-entries.tests.ps1` and `Get-EntrySectionLevel`'s callers. `(check 19)` is
  a different check entirely: `[consumer-doc]`, "a named consumer-facing document that is not there",
  which does not read the changelog path at all.
- The "shape-claim pass" is the section headed `# --- Check 20:` (`Test-EntryShapeClaims`); the
  tests call it **check 20**. `20b` is a real sub-name for its CHANGELOG-intro sub-pass, but the
  prose names the whole pass, so the whole pass's number is what belongs there.

The four readers of `$changelogRel` / `$changelogRelWin` / `$changelogFull` were confirmed against
the code, not inferred from section titles: check 4 (`$changelogDirForLinks`, `:806`), check 11
(`:1488`), check 13 (`$clForHeadings`, `:1814`), check 20 (`:2478`, `:2516`, `:2524`). That is
exactly the list the `:771` prose enumerates.

#### The third `check 19` match, at `:2354`, is NOT a defect and is left alone

`# --- Check 20:`'s own header block explains why that section is numbered 20 and not 19: "the
consumer-doc guard above carries no numbered header of its own, but the suite already calls it
check 19". That is still true -- the `[consumer-doc]` check at `:2146` has no `# --- N.` header, and
the tests do call it check 19 -- so this line is a correct, deliberate reference, not a stale
pointer. Renumbering the header system is #1494's scope (the duplicate `# --- 30.`), deliberately
kept separate.

#### Not in scope

The issue's second bullet -- extend the (proposed) section-number check to citations, or record
that it deliberately does not -- depends on #1494's check 34, which does not exist yet. It stays
with #1494.

### CREATE

- [x] `:772-773` -- `the entry-heading pass (check 19) and the shape-claim pass (check 20b)` ->
      `... (check 13) and the shape-claim pass (check 20)`.
- [x] `:1482` -- `so this check, check 19 and check 20b read $changelogRel,` ->
      `so this check, check 13 and check 20 read $changelogRel,`.

### TEST

- [x] `check-plugin-integrity.ps1` run whole against this repo: 0 errors, every coverage line
      unchanged from baseline. It is a comment-only edit, so behaviour cannot move -- the run is the
      proof that the file still parses (check 5 parses every `.ps1`, itself included).
- [x] `check-plugin-integrity-docs`, `-entries`, `-commands` suites: all green (97 / 85 / 59
      asserts). `-links` green under the full `open-pr` gate. No suite asserts on these comment
      strings, so none needed changing.
- [x] `grep -n "check 19\|check 20b"` on the file afterwards: the only remaining hit is `:2353-2354`,
      which is the deliberate reference documented in PLAN.

### DEPLOY: fix/1500-stale-check-citations

Two stale check-number citations in `scripts/lint/check-plugin-integrity.ps1` now name the pass they
point at. The changelog-path resolver (`:771`) and the lifecycle block (`:1482`) both listed the
readers of the resolved changelog path as `(check 19)` and `(check 20b)`; the entry-heading pass is
**check 13** (the file names it that itself at `:2507`) and the shape-claim pass is **check 20**, so
a reader grepping `check 19` to find the entry-heading pass was landed on an unrelated
`[consumer-doc]` check, and `check 20b` -- a real sub-name -- was standing in for the whole pass.
Comment-only; no behaviour changes. The remaining `check 19` at `:2354` is left as-is: it is the
`# --- Check 20:` header explaining, correctly, why 19 was skipped as a header number (the headerless
`[consumer-doc]` check already answers to it). Renumbering the section headers -- including the
duplicated `# --- 30.` -- stays with #1494.

**Score:** 2

#### What makes this deploy extra special

Nothing reaches a consumer. `check-plugin-integrity.ps1` is not a shared script -- one copy, in
`scripts/lint/`, run only where this product is maintained and in CI. A consumer never runs it and
never reads its comments.

**Score:** N/A

#### Pull Request

check-plugin-integrity.ps1: stale 'check 19' / 'check 20b' citations point at the wrong pass

