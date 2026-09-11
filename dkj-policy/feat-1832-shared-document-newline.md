## feat/1832-shared-document-newline

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

#### What the issue asked, and where its inventory was off

#1832 reports the document-newline reading hand-typed at eight call sites across five files. Measured on
the trunk it is **nine sites across six files** -- the report predates `fix/1829-crlf-section-drift`
merging (#1834), which put its own two `adopt-workflow-folder.ps1` sites on `main`, and it never counted
`fold-changelog-entry.ps1:686`. `scripts/tests/pr-body.tests.ps1:171` matches the same grep and is NOT a
site: it is an assertion about an output, not a reading of an input.

#### Where the helper lives, and why its own file

`park-lib`'s manifest banner is the precedent: a distinct concern gets its own leaf lib rather than
widening an ill-fitting neighbour. A newline reading is not a function-table probe, so it does not belong
in `command-probe-lib.ps1`; `document-newline-lib.ps1` follows that lib's shape exactly -- a leaf with no
dependencies of its own, dot-sourced unconditionally and `$PSScriptRoot`-relative so it resolves in the
plugin mirror as well as here.

**Two dot-sources reach all six files**, and neither adds a dependency the file did not already have:
`entry-scaffold-lib.ps1` (which `release-lib`, `cut-release`, `fold-changelog-entry` and
`adopt-workflow-folder` all already load) and `pr-body-lib.ps1`. That is the same transitive reach
`command-probe-lib` already relies on -- `adopt-workflow-folder.ps1` calls `Test-FunctionDefined` without
loading that lib itself.

#### The name is the one the reporter grepped for

`Get-DocumentNewline` -- #1832's own probe was
`function Get-DocumentNewline\|function Get-NewlineStyle\|function Get-PageNewline`, and the first of the
three is what a future document-editing script looks for.

#### What the helper carries, and what it deliberately does not change

The whole-file reading classifies an already-mixed page by "does it contain any CRLF at all", which
relocates a local mix rather than removing it. That limit is written down at
`adopt-workflow-folder.ps1:717-723` today and is the same in all nine sites; it moves INTO the helper
rather than being quietly answered differently. The helper takes `[string]$Content` and returns the style;
whether a caller wants a fallback of its own stays the caller's business, so
`adopt-workflow-folder.ps1`'s `else { $nl }` spelling is not a behaviour question to settle first.

### CREATE

- [x] `scripts/lib/document-newline-lib.ps1` -- `Get-DocumentNewline`, carrying the whole-file limit note
- [x] Register it in `Get-SharedScriptPairs` (`scripts/lib/shared-scripts-lib.ps1`), `dkj-policy`, `LibOnly`
- [x] Dot-source it from `entry-scaffold-lib.ps1` and `pr-body-lib.ps1`
- [x] Replace the nine call sites across the six files
- [x] Add the mirror-table row in `plugins/dkj-policy/scripts/README.md` (lint check 32 reads it)
- [x] Regenerate the mirror (`scripts/sync/build-shared-scripts.ps1`)

### TEST

- [x] `scripts/tests/document-newline.tests.ps1` -- CRLF, LF, empty, mixed, no-newline
- [x] The suite carries a tree-wide AST gate, so a tenth hand-typed site cannot land -- proven to FAIL by
      reintroducing the idiom in `pr-body-lib.ps1` (it named the site and exited 1), then restored
- [x] NOT IN THE PLAN, and found by the gate that exists for exactly this: `entry-scaffold-lib.ps1`
      gaining a second unconditional leaf means every fixture that hand-copies its dependencies owes the
      new file too. `fixture-lib-deps.tests.ps1` went red; eight fixtures now copy it, on ref-print-lib's
      own #1650 precedent, and that suite is green again at 23/23
- [x] The lint + test gate green: `check-plugin-integrity.ps1` 0 errors -- check 32 reads 61 rows against
- [x] The fixture-dependency gate green on the new dot-source -- 23/23, after the eight fixture copies
### DEPLOY: feat/1832-shared-document-newline

`Get-DocumentNewline` is now the one place this workflow reads a document's own newline style, in
`scripts/lib/document-newline-lib.ps1`. It was hand-typed at nine call sites across six files -- six
carrying the one-liner verbatim and three spelling the same answer over two statements, which is why a
grep for the one-liner undercounted it. Nothing about the answer changed: every caller reads the same
whole-file question it read before, and the six files' behaviour is identical.

What the absence cost is inbound #1829, one merge earlier: `adopt-workflow-folder.ps1` composed its one
rewritten block with a hardcoded LF while comparing it against a page read byte-exact, so the verdict
read `drifted` on every CRLF checkout. Four scripts in this tree already knew the answer to that exact
question; the fifth did not, and nothing connected them. A named helper is what the sixth one finds.

Inside this repo the gain is the guard rather than the tidy-up. The suite carries a tree-wide AST gate,
so a tenth hand-typed reading cannot land quietly -- and it pins the whole-file limit that #1829
accepted deliberately, which was previously a comment beside one of the nine sites and is now the
banner of the answer itself. That matters because the limit is the kind of thing a later reader
"improves" in one caller, and a local answer in one file would break the argument the other eight rest
on. A second thing surfaced on the way, from the gate built for exactly it: giving
`entry-scaffold-lib.ps1` a second unconditional leaf means every fixture that hand-copies its
dependencies owes the new file, so `fixture-lib-deps.tests.ps1` went red and eight fixtures were
repaired on `ref-print-lib`'s own #1650 precedent.

**Score:** 2

#### What makes this deploy extra special

Nothing a consumer runs behaves differently -- the mirror carries one more dot-sourced lib and every
command gives the same answers it gave before -- so the reach here is genuinely nil rather than small.
Worth saying because the change is adjacent to a v5.0.0 consumer-facing repair and could be mistaken for
part of it: #1829 fixed the drifting verdict, and this one only makes sure the next document-editing
script cannot reintroduce it.

**Score:** N/A

#### Pull Request

one helper for reading a document's own newline style
