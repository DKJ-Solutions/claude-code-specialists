## feat/1766-plugin-owned-region

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

Inbound #1766, from smartwatchbanden: `dkj-policy/` has no plugin-owned surface. Every page the scaffold
places is the consumer's to write and is never touched again, so nothing in a consumer's folder can be
kept identical across consumers -- and a colleague browsing the repo on GitHub reaches none of the ~203 KB
of portable pages at all.

#### One of the report's load-bearing claims does not stand

It measures its own folder README as carrying no `<!-- dkj-policy:update-section -->` marker and concludes
that *"the section designed to reach us has not reached us"*, adding that *"a top-up needs to work for
repos that adopted before the marker existed"*. That case is already built and already tested:
`adopt-workflow-folder.ps1`'s append-when-absent branch handles exactly it, and
`adopt-workflow-folder.tests.ps1` pins it as `$c12`, *"a repo that adopted BEFORE the section existed --
its README is its own writing with no marker anywhere"*. Their page has no marker because Part 1 has not
been re-run there, not because it cannot reach them.

#### What does stand is sharper than either shape the report proposes

The scaffolded `dkj-policy/README.md` is **already the plugin's writing** -- the intro, the layout table
and the update section are all generated from arrays in `adopt-workflow-folder.ps1` -- sitting in a file
the scaffold promised never to touch again. That is why the reporter's copy still names the branch
document `development.md` and still lists two pre-rename plugin ids. The marker closed *"a section added
later never arrives"*; it never closed **"a section that arrived is never corrected"**, and that second
half is the defect they actually hit.

#### Both proposed shapes are declined, with reasons

- **Shape 1, a vendored `HELP/` subtree.** Duplicates ~203 KB of portable prose into every consumer,
  reverses the governing rule outright, and repeats the defect #664 closed -- publishing plumbing to an
  audience that cannot act on it.
- **Shape 2, a separate pointer page.** Duplicates what the folder README's intro already says (it names
  all three portable pages today), creating a second drift surface inside one folder: the exact
  complaint the issue is about.
- **Neither repairs the staleness that was measured**, because both leave the stale README standing.

#### So: fence the block that is already the plugin's

A closing marker beside the opening one. Everything between them is the plugin's and is replaced on
`-Apply`; everything outside is the repo's and is never read. That is the surface #1766 asks for --
identical across consumers, kept current -- at ~2 KB rather than ~203 KB, in the file that already carries
it, with no new page and no new category of file.

### CREATE

- [x] `scripts/task/adopt-workflow-folder.ps1` -- `$updateSectionEndMarker` added; the block gains what
      the report actually asked for: what this workflow is, the three portable pages named **in code**
      (the install path differs per machine, so they cannot be links), and the version question answered
      by `/dkj-policy:plugin-versions` rather than by a number, with the per-checkout reasoning stated.
- [x] The write block answers **four** states where it answered three, read in an order where two are
      told apart only by the closing marker: no page; **both markers** -> replace between them; **opening
      marker only** -> a pre-fence section, left alone and reported; neither -> appended as before.
- [x] A closing marker with no opening one is refused rather than guessed at -- the same reasoning
      reached from the other side.
- [x] `plugins/dkj-policy/skills/adopt-dkj-policy/SKILL.md` -- the governing rule now reads *"no FILE is
      ever rewritten"* with the one region named, and the reader is given all three ways out: write
      outside the block, delete both markers to own it, or edit inside it knowing it is replaced.
- [x] `scripts/sync/build-shared-scripts.ps1` run.

### TEST

- [x] `scripts/tests/adopt-workflow-folder.tests.ps1` -- section 12 added. The replace is asserted with
      the repo's own writing on **both** sides of a hand-corrupted block: the stale content goes, both
      sides survive byte for byte, and exactly one block remains.
- [x] **Idempotence is asserted separately**, because a refresh that rewrote on every run would re-encode
      a file it has no other reason to touch, on every adoption in every repo. A current block prints
      *"already carries the current block"* and the bytes are unchanged.
- [x] The pre-fence page is asserted **untouched**, including a section the repo wrote *after* the
      marker -- the case that makes the fence safe rather than a licence.
- [x] Three existing assertions moved to the new printed wording: the block is no longer only the UPDATE
      section, so *"the plugin's block"* is the accurate noun.
- [x] `adopt-workflow-folder.tests.ps1` 97 passed / 0 failed.

### DEPLOY: feat/1766-plugin-owned-region

`dkj-policy/README.md` now carries a **fenced block that belongs to the plugin and is kept current**.
Everything between `<!-- dkj-policy:update-section -->` and `<!-- /dkj-policy:update-section -->` is
replaced by a re-run of the `adopt-dkj-policy` skill's Part 1; everything outside those two markers is
yours and is never read. The block says what this workflow is, names the three portable pages in code,
and answers *"which version am I on?"* with `/dkj-policy:plugin-versions` rather than a number -- a
version is per (plugin, checkout), so a number committed into a repo is right for at most one clone.
Fixes inbound #1766.

**This is the one place the scaffold rewrites anything**, and it exists because everything in that block
was always the plugin's writing sitting in a file the plugin had promised not to touch. A consumer's page
went on naming the branch document `development.md` and listing two pre-rename plugin ids, with no way to
correct it and no way for a reader to tell whose sentence had gone stale. Three ways out, all the
consumer's: write outside the block, delete both markers to own the paragraphs, or edit inside and know
they are replaced. **A page from before the fence is left exactly as it is** -- an opening marker with no
closing one has no machine-readable end, so the run reports it and names the edit that opts in.

**Score:** 3

#### What makes this deploy extra special

Neither shape the issue proposed was built, and the reasons are measurements rather than preferences. A
vendored `HELP/` subtree duplicates ~203 KB into every consumer and repeats the defect #664 closed; a
separate pointer page duplicates what the folder README's intro already says, creating a second drift
surface inside one folder -- which is the complaint itself. Neither would have fixed the staleness that
was actually measured, because both leave the stale README standing.

One of the report's supporting claims also failed on contact with the tree: it treats pre-marker repos as
unreachable, and that case has been built and tested since the marker existed
(`adopt-workflow-folder.tests.ps1`, `$c12`). Their page carries no marker because Part 1 has not been
re-run there.

**Score:** 2

#### Pull Request

A refreshable plugin-owned region in the consumer's dkj-policy/README.md

