## Development: `fix/fresh-adoption-note-root-agrees-v1` · 20260830-152441

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

Issue #1150: adopt-workflow-folder writes the Get-ReleaseNoteRoot answer for a fresh consumer only; drop the unjustified .gitkeep.

#### What the verification changed about the reported options

The issue named three shapes and declined to pick. Two facts measured on pickup settled it:

- **Its option C is unsafe.** "Fall back to the scaffolded folder if it exists" flips the answer for a
  *re-adopting existing* consumer too, since the same run creates that folder -- orphaning the notes the
  flat default exists to protect.
- **Its option B is cheaper than reported.** The `.gitkeep`'s stated reason -- *"the audience root must
  exist before the first cut writes into it"* -- is false: `cut-release.ps1` creates the note's parent
  before writing, and its own comment there says why that line had to be added.

Dave chose the narrowed write: answer the seam, but only for the repo that provably has nothing to lose.

### CREATE

- [x] `adopt-workflow-folder.ps1`: resolve the note root through the seam, like the changelog and history roots beside it
- [x] Write `Get-ReleaseNoteRoot` into `scripts/repo-config.ps1` under three conditions (lib exists, unanswered, no note at the fallback)
- [x] Report the branch taken in every case, including the three that decline
- [x] Drop the `releases/audience/.gitkeep` target, its premise being false
- [x] Make the scaffolded pages name the resolved root instead of asserting `releases/audience/` flatly
- [x] Amend the `Get-ReleaseNoteRoot` contract record and regenerate the shipped config blueprint
- [x] Update the `adopt-workflow-folder` skill page; sync both plugin mirrors byte-for-byte

### TEST

- [x] Four fixture branches exercised by hand before writing asserts -- which caught the generated lib not parsing
- [x] Suite extended to all four branches, asserting the declines as well as the write (55 asserts green)
- [x] The generated lib is **parsed**, not just grepped -- the defect found by hand would pass a regex assert
- [x] Lint gate green; the stale config blueprint it caught was regenerated

### DEPLOY: `fix/fresh-adoption-note-root-agrees-v1`

`adopt-workflow-folder` no longer scaffolds a directory the release cut will not use. It resolves
`Get-ReleaseNoteRoot` through the seam -- the same treatment the changelog and history roots beside it
already got -- and **writes the answer into `scripts/repo-config.ps1`** where, and only where, all three
of these hold: the lib exists, it defines no answer, and no hand-written note sits at the shared
`releases/notes` fallback. That is the freshly scaffolded repo and nothing else; every other repo is
reported and left untouched. The `releases/audience/.gitkeep` is gone, its stated premise having turned
out to be false -- `cut-release.ps1` creates the note's parent directory itself -- and the scaffolded
pages now name whichever root the seam actually resolves to instead of asserting one flatly.

This is the first `decide` seam any command in this workflow answers on its own, and the three
conditions are the whole safety argument: `adopt-config` never places one because copying the source's
answer would assert something about a repo it merely *found*, whereas this run **creates** the folder.

**Score:** 3

#### What makes this deploy extra special

A consumer who adopts the folder and then cuts a release gets their release note inside the folder the
adoption just built, instead of at `releases/notes/` in the repo root with the history table linking back
out to reach it -- and without an empty committed directory promising a destination nothing wrote to.
Reported from a testrun that followed the documented path literally (#1150), where every individual step
behaved as documented and the two halves of one run still disagreed. Nothing changes for a consumer who
already answered the seam or already has notes on disk: their answer wins, and nothing is ever moved.

**Score:** 3

#### Pull Request

A fresh adoption's note root and its scaffolded folder now agree

