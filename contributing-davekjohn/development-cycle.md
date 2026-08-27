## Development cycle: `docs/drop-root-contributing-v1` · 20260827-105016

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

Dave decided the root CONTRIBUTING.md goes, after the layering objection was raised and reaffirmed. Scope: delete it, repair 8 inbound links, drop it from ReservedRootMd in repo-config + the shipped blueprint, and withdraw this repo as the 'worked example' the plugin README points at. The plugin keeps teaching consumers the two-page model -- the plugin serves the consumer's repo, so this repo's choice is not a norm they inherit.

### CREATE

- [x] Delete `CONTRIBUTING.md` from the repo root
- [x] Repair the inbound references. Nine, not eight: `README.md` carries a third one that is not a
      link but a claim -- its root-documents list. `README.md` (3x), `SECURITY.md`, `CLAUDE.md`,
      `contributing-davekjohn/CONTRIBUTING.md`, `contributing-davekjohn/README.md`,
      `releases/README.md` -- each now points at the folder page or at `CLAUDE.md`, whichever
      actually holds the statement it was citing
- [x] Drop `CONTRIBUTING.md` from `$script:ReservedRootMd` in `scripts/repo-config.ps1`, by that
      list's own documented rule: an entry for an absent file is inert but makes the list describe a
      root that no longer exists, and it silences the one useful signal (the file reappearing).
      The script's built-in fallback keeps it, because that list serves consumers
- [x] Regenerate `plugins/workflows/contributing-davekjohn/blueprint/config-blueprint.json` via
      `scripts/sync/build-config-blueprint.ps1` -- lint check 21 holds it against a fresh generation
- [x] Withdraw this repo as the "worked example" of the root half in
      `plugins/workflows/contributing-davekjohn/README.md` -- that external link would 404
      and the dead-link check skips http, so nothing would catch it
- [x] `CONTRIBUTING-portable.md`: keep teaching consumers the two-page model, but stop asserting it
      as universal and name the source's own exception. It also now states the two reasons to keep a
      root page that have nothing to do with the gates -- GitHub's surfacing, and the name a
      drive-by contributor looks for
- [x] `adopt-workflow-folder.ps1` (source, then `scripts/sync/build-shared-scripts.ps1` for the
      mirror): its refusal named a root `CONTRIBUTING.md` the source no longer has -- and the same
      sentence was already stale on two other counts, claiming the source keeps `releases/` at its
      root and only a branch dossier in the folder, which #886 and #914 had already changed
- [x] Unlink two dead references in `contributing-davekjohn/releases/changelog/4.x/4.14.0.md`. Not
      foreseen, and found by the gate rather than by my own grep, which only reached three `../`
      levels. Unlinked rather than repointed: the note describes August 14, 2026 and must not be
      made to cite a page that did not hold that role

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` clean -- specifically checks 4 (dead links) and 21
      (the blueprint). It caught the two archived links above on the first run and reported 0 errors
      on the second
- [x] `scripts/tests/*.tests.ps1` run, and the fold suite in particular: it writes a fixture
      `CONTRIBUTING.md` to prove a root meta doc is never folded, which stays valid since the
      fixture is its own tree
- [x] 52 of the 53 suites pass here. `internal-note.tests.ps1` fails one assert, and that is
      [#959](https://github.com/DaveKJohn/claude-code-specialists/issues/959), not this branch: the same
      suite fails identically (1 failed, 94 passed) against the tip of `origin/main`, the very commit
      whose CI run is green. `Write-Warning` wraps at the console width, so at 107 columns the missing
      `**Date:**` message breaks after "date" and the assert matching `fill in the date by hand` is split
      across two lines. Nothing here touches that script, its suite, or the capture helper
- [~] Local gate pushed with `-SkipTests` because of the above. The lint gate still ran, and CI runs the
      suites inescapably -- it is the required `lint-en-tests` check the `main` ruleset gates the merge on

### DEPLOY: `docs/drop-root-contributing-v1`

The repo root has no `CONTRIBUTING.md` any more. Its floor -- never directly on `main`, a branch + PR,
the required `lint-en-tests` check -- was already stated in `CLAUDE.md`, on the path every session
loads, so the page was a second copy of three rules rather than the safety net it was built as in
August. `contributing-davekjohn/CONTRIBUTING.md` is now the only contributing page, and the layering it
sits in is unchanged: the always-on document holds what is true regardless of any plugin, the folder
page adds what the workflow brings, and the folder page still wins on conflict.

**Nine references moved rather than nine links being fixed**, which is the part worth knowing for the
next reader. Six were one-line repointings, but three were claims that had to be rewritten -- `README.md`
asserted the root page *was* the standard workflow, the folder page said it sat on top of *two* root
pages, and `README.md`'s layout list named the file among the root documents. A tenth turned up in
`adopt-workflow-folder.ps1`, whose refusal message described a source-repo layout that #886 and #914 had
already changed twice before this branch touched it.

**Score:** 3

#### What makes this deploy extra special

Nothing about the workflow changed, and the payload now says so out loud. `CONTRIBUTING-portable.md`
still recommends the two-layer shape and still expects a root `CONTRIBUTING.md` to carry the floor --
what it gained is the source's own exception, named as housekeeping rather than as the model, plus the
two reasons to keep a root page that no gate can express: GitHub only surfaces that file from the
root, `.github/` or `docs/`, and it is the name a contributor who has installed nothing looks for.
`adopt-workflow-folder` scaffolds exactly what it scaffolded before.

So a consumer inherits no change in behaviour and one genuine addition in advice. The `Get-ReservedRootMd`
edit reaches nobody: the contract marks it `decide`, so `adopt-config` never copies it into a seam, and
`cut-release.ps1`'s built-in fallback still lists `CONTRIBUTING.md` for a repo that declares no answer.

**Score:** 2

#### Pull Request

The root contributing page is gone, and the workflow folder's page is the only one

