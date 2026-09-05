## fix/1444-stranded-page-token

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

#1444 reports the gitignored `releases/page/` folder -- the built page, the worker bundle and the path
token -- left behind by the `contributing-davekjohn/` -> `dkj-policy/` rename of #1437, and proposes
moving it.

#### The symptom was checked first, and the move it asks for has nothing to move

The folder is not in this checkout under either name, and no `worker-path-token.txt` exists anywhere
under this machine's home tree. The build's own tree-wide search -- added on this branch -- finds none
either, which is the same question asked by the code rather than by hand. So the token this machine
once held is not recoverable from an orphan, because there is no orphan; that is reported on the issue
rather than repaired here, since only Dave can say whether the URL survives outside the repo.

#### What does stand is the class the issue names in its second half

Nothing said the folder had stayed behind, and one guard is what makes that silence expensive.
`-InitToken` refuses to replace a token, which reads as the whole safety property -- but it refuses on
`$tokenPath` alone, the path derived from the *current* note root. Move the folder and it finds no
token, mints a second one, and the deploy that follows 404s every link already sent while the build and
the deploy both report success. That refusal was exactly as strong as the assumption that nobody moves
the folder, and #1437 is the day somebody did.

### CREATE

- [x] `Find-StrayPathToken` in `scripts/release/build-release-notes-page.ps1` -- every
      `worker-path-token.txt` in the tree that is not the expected one, `.git` skipped. It runs on the
      two failure paths only, so the repo-wide walk costs nothing on a normal run.
- [x] `-InitToken` refuses on a copy found **anywhere**, not just at the expected path, and names it.
      This is the repair the report did not ask for and the one that matters: it is the only guard whose
      failure mints a second token.
- [x] The missing-token refusal under `-Worker` names the copy where the tree holds one, and names the
      move that hides one where it does not -- so the reader who has been renaming folders is told what
      to look for before they reach for `-InitToken`.
- [x] Docs, both halves: the portable
      [`release-notes-page` skill page](../plugins/workflows/dkj-policy/skills/release-notes-page/SKILL.md)
      (why an ignored sibling cannot travel with a `git mv`, and that a found copy is named rather than
      adopted) and this repo's own `.gitignore` comment, which is where a reader lands when they meet
      the path.
- [x] Mirror regenerated from the registry (`build-shared-scripts.ps1`, 1 updated).

### TEST

- [x] `scripts/tests/release-notes-page.tests.ps1`: **150 asserts, all passing**, seven of them new --
      a stray copy makes `-Worker` name it and refuse, makes `-InitToken` refuse and mint nothing, and
      leaves the copy byte-identical; with no copy anywhere the refusal still names the move.
- [x] The fixture puts the stray in `old-releases/page/`, which is the shape of the defect rather than
      its instance: what is under test is a token outside the derived path, not one particular rename.
- [x] Lint gate green (`check-plugin-integrity.ps1`, 0 errors); all suites green.
- [x] Read for real in this repo: `-Worker` against the live tree refuses, names
      `dkj-policy/releases/page/worker-path-token.txt`, and says the copy may still sit in the folder
      the rename left -- which is also how the absence above was confirmed by the code.

### DEPLOY: fix/1444-stranded-page-token

The release page's path token is the one file in this system that cannot be rebuilt: it is the only
lock on a public page, it is deliberately uncommitted in a public repo, and nothing in git remembers
the URL it forms. It lives in a directory derived from the note root and ignored by git -- two good
decisions that meet badly, because renaming the folder above it moves every tracked file and leaves the
token where it was. `git mv` cannot see an ignored sibling by construction, so the miss is silent on
the day it happens, and what is left over reads like rename debris.

`build-release-notes-page.ps1` now asks whether a token exists **anywhere in the tree** rather than
whether one exists at the derived path. A copy found elsewhere is named and never adopted: `-Worker`
points at the folder to move, and `-InitToken` -- whose refusal was the design's whole safety property
and which read the derived path alone -- refuses on it too. Where no copy is found, the refusal still
names the move that hides one, because the operator who has just renamed a folder is the reader most
likely to be looking at it.

Measured on this repo: #1437's rename left exactly that orphan (#1444), and the token is gone from this
machine with it.

**Score:** 2

#### What makes this deploy extra special

N/A -- the person who reads a release page never sees any of this. It is a guard between the operator
and one irreversible mistake.

**Score:** N/A

#### Pull Request

The missing-token refusal points at the copy a folder move left behind
