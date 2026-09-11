## fix/1829-crlf-section-drift

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

Inbound #1829, verified in the tree before anything was changed. The report's reason was explicitly
filed as a hypothesis ("I did not read the comparison to confirm which side is normalized"), so it was
the first thing read.

#### What the report got right, and the one thing it did not know

`$nl = "``n"` at `scripts/task/adopt-workflow-folder.ps1:131` composes every generated document, which is
correct for a file this run **creates** and wrong for the one file it **compares against**: state 2 reads
the existing page with `ReadAllText` (byte-exact) and tests `$rebuilt -eq $existingReadme`. On a page
checked out CRLF every line of the composed block therefore differs from the identical committed line.
Reproduced on a fixture: the same page reads `already carries the current block` as LF and
`the plugin's block has drifted` as CRLF, with nothing else changed.

The half the report could not see from outside: `-Apply` does not rewrite the page to LF either. Head and
tail are `Substring`s of the original, so they keep their CRLF, and only the fresh block is written LF --
**19 CRLF above and below an all-LF block**. `core.autocrlf=true` normalises that away, which is why the
reporter's `git diff` came up empty and why the second dry run then agreed the block was current: the
defect was masking its own symptom. Without `autocrlf` the same write is a whole-file whitespace diff.

#### Scope checked, so the repair is not narrower than the class

- **State 4 (the append) has the same write half.** No verdict to get wrong, but it puts an LF block into
  a CRLF page the command has never touched -- a consumer's *first* adoption. Repaired in the same move.
- **The sibling adopt scripts do not carry it.** `adopt-config` and `adopt-shopify-floor` only append;
  `adopt-merge-queue` reads with `\r?\n` throughout and writes create-when-absent. Nothing to file.

### CREATE

- [x] Read the comparison in `adopt-workflow-folder.ps1` and reproduce both halves on a fixture, before
      touching anything -- the report's mechanism was inferred, not measured
- [x] State 2: read the page's own newline style off `$existingReadme` and compose the block with it, so
      the compare stops seeing a difference that is not there and the write stops introducing one
- [x] State 4: the same reading for the append, for the write half
- [x] Check the sibling adopt scripts for the same compare -- none has one
- [x] Mirror to `plugins/dkj-policy/scripts/task/` via `build-shared-scripts.ps1`

### TEST

- [x] `adopt-workflow-folder.tests.ps1` section 13: a CRLF page reads as current, `-Apply` over it is
      byte-for-byte, a genuinely stale CRLF block is still replaced, and the rewritten page carries **no
      bare LF** -- the assert that separates this repair from one that normalises both sides of the
      compare and then writes LF anyway
- [x] The LF page is asserted unchanged, so the style is read off the page rather than swapped per platform
- [x] Confirmed the section goes red without the repair: 4 failed, 108 passed
- [x] Full suite green with it: 112 asserts

#### The review round, and the two gaps it found in the above

Victor, Edith, Sebastian and Nolan read the diff in parallel. Edith reproduced every figure in this
document independently -- the 19 CRLF, the 4-of-112, the #788 wording, the v5.0.0 quote -- and Sebastian
found no widening of the write boundary and nothing in the diff that puts page content anywhere but a
`.Contains` / `.IndexOf` / `-eq`. Two of Victor's findings were real defects in the work above, not
polish:

- [x] **The append had no CRLF fixture at all.** Every state-2 assert needs a page that already carries
      both markers, and section 11's append fixture is pure LF -- so reverting the append's `$pageNl`
      alone would have passed the entire suite, in the one path a consumer's *first* adoption takes.
      Added, and verified to fail on its own: reverting only state 4 gives 2 failed, 116 passed.
- [x] **One of my own asserts could not fail.** `crlf: and the LF page this suite scaffolded has no CR`
      compared `$readme11`, captured 150 lines earlier in section 11, so it re-checked a fact that was
      already true before the `-Apply` it was placed after. It reads the file back from disk now and
      compares both the bytes and the CR count.
- [x] Named the whole-file `Contains` reading as the accepted limit it is: an already-mixed page has its
      mix relocated rather than removed, and the answer is deliberately the same one every other
      document-editing script in this tree gives.
- [x] Reworded the `#788` clause Edith flagged as parsing three ways.
- [~] The eight-site duplication of the newline reading is NOT repaired here -- filed as #1832. It spans
      three mirrored libs and five files, and my own sweep found a site the review did not name
      (`cut-release.ps1:1129`); repointing all eight is its own change, not a rider on a two-line fix.
- [x] Suite green after the round: 118 asserts

### DEPLOY: fix/1829-crlf-section-drift

`adopt-dkj-policy` Part 1's README top-up now judges the block it owns, not the line endings of the page
around it. It reads the page's own newline style and composes the block with it, so a page checked out
CRLF -- which is what `core.autocrlf=true` gives every Windows clone -- no longer reports
`the plugin's block has drifted` on every fresh checkout, and `-Apply` no longer leaves the page with LF
between CRLF. A genuinely stale block is still replaced, and an LF page is still written pure LF.

**Score:** 2

This repo refuses that scaffold outright -- it publishes the workflow -- so nothing here changes but the
suite. What it gains is the regression test: every fixture in it wrote LF until now, which is how a
Windows-only defect survived in the one block the suite pins hardest.

#### What makes this deploy extra special

Consumers on Windows get a verdict that carries information again. The failure was quiet and permanent
rather than one-off: the command said "drifted" every time, so a block that really was stale read exactly
like one that was current, and the only way to tell them apart was to run `-Apply` and check `git diff`
afterwards. That is the feature v5.0.0 announces as "can be kept current with one command".

**Score:** 3

#### Pull Request

The README block top-up preserves the page's own line endings

