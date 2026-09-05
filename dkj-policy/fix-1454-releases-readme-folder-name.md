## fix/1454-releases-readme-folder-name

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

Rewrite the plugin name and the two consumer-facing folder paths in dkj-policy/releases/README.md to
dkj-policy, leaving the dated sentences alone.

#### The bound, and why it is exactly three lines

[#1454](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1454) names three undated,
present-tense statements in `releases/README.md`. They are neither history preserved under #952 nor
rename-tolerant fallbacks, which is the reason
[#1447](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1447) gave for scoping that
file's other occurrences out. Lines 137 and 143 are #1447's own stated scope and are **not** touched
here: that repair sits on the parked branch `fix/1447-release-page-path` and is still open.

### CREATE

- [x] `releases/README.md:5` -- the plugin is named `dkj-policy`, not `contributing-davekjohn`. This
      is the plugin's name rather than the folder's, so it is a distinct defect from #1437's folder
      rename rather than a missed occurrence of it.
- [x] `releases/README.md:51` -- the path the `adopt-workflow-folder` skill actually scaffolds is
      `dkj-policy/releases/README.md`, so the sentence no longer names a path the skill it cites does
      not write.
- [x] `releases/README.md:56` -- `Get-ReleaseHistoryPath`'s computed default composes the folder from
      `Get-WorkflowFolderName`, which returns `dkj-policy` for a repo that has none of the three
      folders. The sentence now names what a fresh consumer actually gets.

### TEST

- [x] Re-verified all three of the issue's cited evidence points in this checkout before editing:
      `.claude-plugin/marketplace.json:27` registers `"name": "dkj-policy"` and no
      `contributing-davekjohn` plugin; `adopt-workflow-folder.ps1:401` writes
      `dkj-policy/releases/README.md`; `seam-lib.ps1:188` iterates
      `@('dkj-policy', 'contributing-davekjohn', 'workflow-davekjohn')` first-hit-wins and falls
      through to `'dkj-policy'`.
- [x] The lint gate and the full suite, run through `open-pr.ps1` -- the same gate CI runs.

### DEPLOY: fix/1454-releases-readme-folder-name

`releases/README.md` told an agent setting this workflow up in another repo that the plugin is called
`contributing-davekjohn`, that the `adopt-workflow-folder` skill scaffolds a
`contributing-davekjohn/releases/README.md`, and that `Get-ReleaseHistoryPath` points at a
`contributing-davekjohn/releases/history.md` if left alone. All three are false, and false in the same
direction: a fresh consumer has none of the three folder names on disk, so every script hands them
`dkj-policy` while this page addressed them in the second person about a folder they do not have.

#1437 renamed the folder and #1447 covers the two `releases/page/` statements it left behind. These
three were scoped out of that branch because #1447 states its own bound -- and one of them is not a
folder-rename miss at all: line 5 names the **plugin**, which was never called `contributing-davekjohn`.

Three sentences rewritten. The dated sentences around them keep the name they were written with, and
lines 137 and 143 are left for #1447.

**Score:** 3

#### What makes this deploy extra special

The section these three sit in is `### How to build your own version of this page` -- the one document
that exists to answer *"what does this look like in my repo"*, addressed in the second person to a
consumer adopting the workflow. That is the worst place in the tree for a stale name, because the
reader has nothing of their own to check it against yet.

**Score:** 3

#### Pull Request

Correct three present-tense contributing-davekjohn references in the releases README

