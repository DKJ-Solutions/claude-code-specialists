## fix/1897-reupload-stale-attachment

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

#### What the report got right, and the two questions it left open

#1897 is exact on both halves: step 0a prescribes a second timing pass *after* step 5, and step 5 is
where the hand-written documents are uploaded — so the published asset is one revision behind the tree
by construction, and nothing in the checklist says to re-upload. Verified against the tree: no
`--clobber` appears anywhere in the workflow scripts or skill pages, and `v5.1.0`'s own asset is
12,275 bytes only because it was re-uploaded by hand after the timing commit (`fc81029a`, which touched
`releases/audience/5.x/5.1.0.md` and nothing else).

The report explicitly left two things unverified, and both are answered in the repair rather than
repeated as open questions:

- **the development notes** — not exposed. The cut generates them at step 1, step 0a says in so many
  words that the generated tier-0 note is not where the figure goes, and nothing between step 1 and
  step 7 edits them;
- **a third attachment in the two-document flow** — exposed, and it is the *other* document.
  `new-internal-note.ps1` writes *What it is worth* and *What was still open* into
  `releases/internal/<dir>/<X.Y.Z>.md`, so in that flow the organisational section — where the figure
  goes — sits in the internal note, and it is the consumer document that stays current.

#### Where the repair goes, and why not step 5

At step 0a, as the report argues: it is that step's own consequence. A reader reaches step 5, publishes,
and then comes back to 0a to learn what the second pass must contain — so the line lands where it is
read. Step 5 is left alone.

### CREATE

- [x] Step 0a's second pass names the re-upload, with `--clobber` and the reason it is needed
- [x] The flow-dependent target named: the merged flow's consumer note against the two-document flow's
      internal note — whichever this pass actually edited
- [x] The development notes explicitly ruled out, with the reason (it is the editing that creates the
      exposure, not the attaching), so the next document a later step edits inherits the rule

### TEST

- [x] Lint gate + all suites, via `open-pr.ps1` at the PR step

### DEPLOY: fix/1897-reupload-stale-attachment

The `cut-release` checklist now says to re-upload the release attachment the timing pass edits. Step 0a
prescribes a second timing pass *after* step 5, and step 5 is where the hand-written documents are
attached — so the published asset was one revision behind the tree by construction and permanently
lacked the end-to-end duration that step exists to capture. Measured at `v5.1.0`: 11,487 bytes published
against 12,275 committed, caught only because somebody was watching the byte count. The step now carries
the `gh release upload --clobber` line, names which document is the stale one in each flow (the consumer
note in the merged flow, the internal note in the two-document flow), and rules the generated development
notes out with the reason — it is the editing that creates the exposure, not the attaching.

**Score:** 3

#### What makes this deploy extra special

A consumer running this workflow publishes a Release whose attached note is missing the one figure the
checklist told them to measure, and nothing reports it — the tree, the tag and the commit are all
correct. They find out when somebody downloads the note and the total is not in it.

**Score:** 3

#### Pull Request

The second timing pass re-uploads the attachment it just edited
