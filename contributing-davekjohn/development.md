## Development: `fix/measure-line-ending-unit-v1` · 20260831-124232

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

The byte column reports the working copy as it sits on disk (Get-Item.Length); on a CRLF checkout that is one byte per line above the repo's LF form, and nothing in the output says so. Add a label line plus, where the two forms differ, the LF size beside the on-disk one. Inbound #1162.

### CREATE

- [x] `scripts/lib/measure-context-lib.ps1`: add `Get-CrlfPairCount` (raw byte scan, counts a 0x0D
  only when it precedes 0x0A). `Get-AlwaysOnDocuments` rows now carry `CrlfLines` and
  `LfBytes` (`Bytes - CrlfLines`); `Bytes` is unchanged — still `Get-Item .Length`, the copy that
  loads. Docstring gains the byte-count / line-ending note.
- [x] `scripts/maintenance/measure-always-on.ps1`: the always-present provenance line now reads
  "a MEASUREMENT of the working copy on disk"; a new block prints, per document and (for >1) as a
  total, `N B on disk, M B stored LF` wherever `CrlfLines > 0`, with a note that reading the working
  copy is correct and the LF column is what the next reader compares against. Nothing prints on an
  all-LF path.
- [x] Mirror both to `plugins/workflows/contributing-davekjohn/scripts/**` via
  `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] `scripts/tests/measure-always-on.tests.ps1`: new section — `Get-CrlfPairCount` (LF → 0, CRLF →
  one per line, a lone CR not counted), the new row fields (`Bytes` still on-disk, `LfBytes =
  Bytes - CrlfLines`, `LfBytes` equals the same content stored LF), and the script's CRLF-vs-LF
  block firing on a crafted CRLF fixture / absent on an all-LF path. Suite: 61 passed, 0 failed.
- [x] `scripts/lint/check-plugin-integrity.ps1`: 0 errors — `[script-ascii]`, `[shared-script]`
  mirror sync, `[import]` parser all green.
- [x] Full test-suite gate (`Invoke-TestSuiteGate`, all `scripts/tests/*.tests.ps1`): green.

### DEPLOY: `fix/measure-line-ending-unit-v1`

`measure-always-on.ps1` now names the unit of its byte column. The column is still `Get-Item .Length`
— the working copy on disk, the copy a session actually loads — but on a CRLF checkout (Windows,
`core.autocrlf`, no `.gitattributes` pinning `eol=lf`) that is one byte per line above the LF form the
repository stores. The always-present provenance line says so, and where any document on the path is
CRLF a new block prints the LF size beside the on-disk one, per document and as a total, with the note
that the LF column is the number the next reader will compare against. Reading the working copy is
unchanged; only the unit is now labelled. Inbound #1162.

This repo's own always-on path is LF (its `.gitattributes` pins `* text=auto eol=lf`), so the new
block never fires here — it is a latent clarification for the source tree and a real one for a
consumer on a CRLF checkout.

**Score:** 2

#### What makes this deploy extra special

A consumer runs this tool via the `contributing-davekjohn` plugin skill against their own `CLAUDE.md`,
and a Windows consumer with no `eol=lf` in `.gitattributes` is exactly who hit this: a byte series
that mixed a fresh-checkout (CRLF) baseline with an editor-rewritten (LF) reading overstated one step
by one byte per line — ~1.4% on a 1,346-line file, plausible enough to reach a folded changelog entry
and need a correcting PR. They receive the label and the LF column through the plugin update.

**Score:** 3

#### Pull Request

measure-always-on: name the line-ending unit of the byte column

Plugins: contributing-davekjohn

