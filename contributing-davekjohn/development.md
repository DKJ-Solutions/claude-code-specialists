## Development: `fix/testrun-2-cut-release-and-adoption-defects-v1` · 20260829-180650

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

Three inbound findings from testrun 2 (test plan #1079), all in the layer a virgin consumer meets first:
[#1098](https://github.com/DaveKJohn/claude-code-specialists/issues/1098) (the scaffolded CHANGELOG intro
states `##` where the fold writes `###`),
[#1099](https://github.com/DaveKJohn/claude-code-specialists/issues/1099) (the release cut reads an
ordinary root doc as an unfolded entry, and the remedy it prints is the destructive one for that case) and
[#1100](https://github.com/DaveKJohn/claude-code-specialists/issues/1100) (every generated release document
carries trailing whitespace, on a gate that runs before those documents exist).

#### Two of the three proposed repairs did not survive verification

Both were checked against the tree before anything was built, which is the standing rule, and both had to
change:

- **#1099 proposed anchoring a lead word in the branch-name test.** That test's own documentation forbids
  exactly that: its width is the idempotency test, and a narrowed read answers *"still in its reset state"*
  for a document somebody has been writing in. The repair belongs at the **root scan**, which asks a
  different question, and it is a switch on the shared predicate rather than a second one beside it.
- **#1100's first option -- "drop the hard break, it changes nothing a reader sees" -- is wrong.** A single
  newline inside a markdown paragraph is a *soft* break, so dropping the two spaces renders `**Date:**` and
  `**Type:**` on one line. Its second option, a trailing backslash, is the one taken.

### CREATE

- [x] #1098: compose the scaffolded intro's heading level from `Get-EntryHeadingLevel` instead of typing it
- [x] #1099: `-OpeningHeadingOnly` on `Get-BranchFileDeclaredBranch` / `Test-BranchChangelogIsFilled`, asked for by the root scan only
- [x] #1099: the refusal names `Get-ReservedRootMd` as well as the fold, so it covers both ways the gate fires
- [x] #1100: backslash hard break in all four emitting lines, and `Get-MetaLine` reads both spellings
- [x] Mirror the five changed scripts into the plugin (`build-shared-scripts.ps1`)

### TEST

- [x] `cut-release-guardrail.tests.ps1`: the backticked-heading doc, both directions of the switch, every entry shape still read, and the wiring (root scan asks, branch guard does not)
- [x] `release-lib.tests.ps1`: no generated document carries trailing whitespace, per builder
- [x] `internal-note.tests.ps1`: both spellings of the hard break read back, and the marker never reaches the published document
- [x] `adopt-workflow-folder.tests.ps1`: the scaffolded intro states the level `Get-EntryHeadingLevel` gives
- [x] Repaired a fixture the new assert exposed: `New-FlatEntry` hit PowerShell's comma-precedence trap (`@(A + ' ' + $Heading, '')` is `A + ' ' + ($Heading, '')`), so every fixture heading carried a trailing space and lost its blank line

### DEPLOY: `fix/testrun-2-cut-release-and-adoption-defects-v1`

Three defects testrun 2 found in the layer a fresh consumer meets first, all of them in the release cut and
the folder adoption.

The cut no longer reads an ordinary root document as an unfolded changelog entry. Its branch-name test scans
every heading, so a single backticked word in any heading below the title declared a branch and stopped the
release -- which in a technical repo is close to unavoidable. The root scan now reads only the document's
opening heading, which is where every real entry declares itself. And when it does refuse, it names `Get-ReservedRootMd` alongside the fold,
because *"fold them first"* is the right remedy for one of the two ways that gate fires and a destructive one
for the other.

Every release document the cut generates is now free of trailing whitespace. The markdown hard break under
`**Date:**` was two trailing spaces, which fails an ordinary lint rule -- and the cut runs its gate *before*
those documents exist, so it cannot catch its own output: the failure surfaced on the next branch, on files
that branch had not written. The break is kept, spelled as the backslash CommonMark also allows.

And the `CHANGELOG.md` that `adopt-workflow-folder` scaffolds now states the heading level the fold actually
writes, composed from `Get-EntryHeadingLevel` so the sentence cannot drift from the constant again.

**Score:** 3

#### What makes this deploy extra special

A consumer cutting their first release meets two of these three on that one command: the cut refuses over a
run log or an `ADOPTION.md` and tells them to fold it -- which would paste that file into their changelog and
delete it -- and once past that, their trunk fails its own lint gate on files the release wrote, at the one
moment the tree is least inspectable. Both were measured on a real first release, and the third quietly
misinforms every consumer about the shape of their own changelog.

**Score:** 4

#### Pull Request

cut-release stops misreading an ordinary root doc, stops leaving the trunk red, and the adopted CHANGELOG intro states the level the fold writes
