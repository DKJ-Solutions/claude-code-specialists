## Development cycle: `feat/release-roots-changelog-move-v1` · 20260826-205418

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

Issue [#914](https://github.com/DaveKJohn/claude-code-specialists/issues/914): rename the tier-0 note root
`development` -> `changelog`, and move it and `github/` out of the repo root into
`contributing-davekjohn/releases/`, beside `audience/`. The issue is one sentence and the work is not: the
roots are seams read by two scripts, the overview at `releases/README.md` links every one of them, and 116
existing notes carry relative links whose depth changes with the move.

#### What the issue got right, and the one thing it did not

Verified before anything was written. The tree is as reported -- `releases/development/` (99 notes) and
`releases/github/` (17) at the repo root, `audience/` alone under the workflow folder -- and so is the reach
("a move touches the lib, the cut, the overview and every existing note's path"). The one miss is a
mechanism: the roots are **not** resolved in `scripts/lib/release-lib.ps1`. `Get-ReleaseNoteRoot` lives in
`scripts/repo-config.ps1` and the computed defaults for the two moving roots live in
`scripts/lib/seam-lib.ps1`. Following the citation would have edited a file that answers a different
question.

#### The reversal this carries, stated rather than slipped in

`scripts/repo-config.ps1` said, in Dave's name (August 14, 2026), that the generated trees stay at the repo
root **deliberately** -- "the machine-written record and the publish artefact", with "roots hardcoded by
design". Both halves of that reason had expired before this branch opened: #885 gave each root a seam, so
nothing is hardcoded, and once they are seams the question stops being what this repo does and becomes what
every repo's default should be. A tree nothing writes but a cut exists only because the workflow does, which
is the same argument that put `audience/` in the folder in the first place. The record is amended in place at
every site that carried it, not overwritten.

### CREATE

- [x] `git mv` both trees: `releases/development` -> `contributing-davekjohn/releases/changelog`,
      `releases/github` -> `contributing-davekjohn/releases/github`. 72 renames, detected as renames.
- [x] Repoint the relative links inside the moved notes: 133 three-level prefixes to four, plus one
      pre-existing two-level link (`1.5.2.md` -> `../../CLAUDE.md`, which resolved to a
      `releases/CLAUDE.md` that never existed) repaired to the real target. 134 links, no prose touched.
- [x] Rewrite `releases/README.md`: 71 `development/` rows and 1 `github/` row become
      `../contributing-davekjohn/releases/...`, and the page's own subject changes -- it described "the
      documents a release generated" and now holds nothing but the release list.
- [x] `scripts/lib/seam-lib.ps1`: `Get-DefaultReleaseDevelopmentNotesRoot` becomes
      `Get-DefaultReleaseChangelogNotesRoot` and, with `Get-DefaultReleaseGithubNotesRoot`, stops branching
      on `Test-IsWorkflowSourceRepo` -- one answer for both kinds of repo, the branch deleted rather than
      left returning the same string twice.
- [x] `scripts/release/cut-release.ps1`: derive the tier-0 notes' `-LinkPrefix` from the note's own depth,
      the way the hand-written draft already did. This was the one call still relying on
      `Build-ReleaseNotes`' `'../../../'` default, which the move makes one directory short.
- [x] `scripts/lint/check-plugin-integrity.ps1`: teach check 25 the new directory name. Its matcher is a
      literal `(development|internal)/`, so the rename would have taken the gate silent on exactly the class
      it exists for, with its coverage count still reading healthy. Both names are recognised now.
- [x] The contract records (`scripts/lib/script-contract-lib.ps1`): the two `Default` strings, the amended
      `AdoptWhy`, and the stale claim in `Get-ReleaseNoteRoot`'s `Returns` that the tier-0 tree "has no
      equivalent knob" -- untrue since #885 gave it one.
- [x] The docs: `CLAUDE.md`, `releases/README.md`, `contributing-davekjohn/CONTRIBUTING.md` (section 3's
      preamble, which was *about* this issue), `contributing-davekjohn/README.md`, the `cut-release` and
      `adopt-workflow-folder` skill pages, `.claude/rules/language-layers.md` (including its `paths:` scope,
      which no longer matched where the notes live) and the lenses of Rendall #06 and Sylvester #15.
- [x] Regenerate the shared-script mirror and the config blueprint.
- [~] The seam FUNCTIONS keep their names (`Get-ReleaseDevelopmentNotesRoot`). Dropped deliberately:
      renaming one is a contract change a consumer has to act on, and #914 asked for the directory. Filed as
      a follow-up rather than done here.
- [~] `Get-DefaultReleaseInternalNotesRoot` keeps its source-versus-consumer branch. Dropped for the same
      reason: #914 named two roots, and `releases/internal/` does not exist in this repo at all since the
      two-document flow was retired.

### TEST

- [x] `check-plugin-integrity.ps1`: 0 errors. The link scan reads all 291 files including the moved notes
      and the rewritten overview, so every one of the 134 repointed links and 102 rows is proven to resolve
      rather than assumed to.
- [x] All 53 suites green.
- [x] `check-script-contract.ps1`: 0 errors.
- [x] New asserts where this branch removed something that nothing was watching:
      - `seam-lib.tests.ps1` gains a section on the computed defaults -- that the two collapsed roots return
        the *same* answer for source and consumer, and that the three which still branch still do. The
        file's synopsis said those functions were out of scope; the absence of a branch is invisible
        otherwise, because a reinstated one would go on returning a valid path.
      - `cut-release-guardrail.tests.ps1` pins the derived `-LinkPrefix` on the call rather than counting
        `../` -- a fixed count would turn red for the next repo whose root sits somewhere else, which is
        the whole reason the root is a seam.
      - `release-lib.tests.ps1` gains the layout this repo actually has: a row computed from `releases/` to
        a note inside the workflow folder. The pre-#914 cases stay, because a consumer may still have one.

### DEPLOY: `feat/release-roots-changelog-move-v1`

The three note roots are siblings. `releases/development/` is `contributing-davekjohn/releases/changelog/`
and `releases/github/` is `contributing-davekjohn/releases/github/`, joining `audience/`, which has been
there since August 14. `releases/` at the repo root now holds one file: the list of every release ever cut,
which stays because a repo that has cut releases has a history whichever tooling cut it.

`changelog` rather than `development` because the name should say what the document **is** -- the changelog
for that version, the entries at the levels the fold left them -- not which stage of the work produced it.
That is the same correction `notes/` -> `audience/` made two weeks ago in the sibling root, and this was the
last root still named after something other than its reader or its content.

Two computed defaults stopped branching on `Test-IsWorkflowSourceRepo`, and the branch is gone rather than
left returning one string twice. The other three keep it, and the line between them is not symmetry: a
repo's changelog and its release list exist whichever tooling cut them, so a source keeps those at its root,
while a tree nothing writes but a cut belongs to the workflow in every repo.

**Score:** 3

#### What makes this deploy extra special

**A consumer who has answered neither root seam gets one migration, not two.** #885 moved their default from
the repo root into `contributing-davekjohn/releases/development/` and has not been released yet, so both
changes reach them in the same version and the tree they never saw is the only one that never existed. The
accepted cost recorded at #885 -- old notes stay where they are, new ones land in the folder -- is paid once,
and repointing the seam at the tree they already have still keeps a single tree for anyone who would rather
have that. The seam **names** are unchanged, so nothing in a consumer's `repo-config.ps1` has to move on the
same day the default under it does.

**And the shipped lint gate would have gone quiet without being asked to.** Check 25 holds every
hand-written note against linking its reader into a tier the note was not written for, and it matched the
tier-0 tree by the literal directory name `development/`. Renaming the directory and shipping that check
unchanged would have left a gate that finds nothing, reports a healthy count, and is discovered by whoever
reads a released document. Both names are matched now -- which is also what keeps an unmigrated consumer
covered, so the fix and the compatibility are one line. That is the third time this repo has paid for a path
written as a literal in a place that reads a seam everywhere else: `releases/notes` in this very check
(August 12), the overview row at the v4.6.0 cut, and this.

**Score:** 3

#### Pull Request

the release-note roots become siblings: development -> changelog, and the generated trees move into the workflow folder
