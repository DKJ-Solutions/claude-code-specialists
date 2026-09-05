## fix/1447-release-page-path

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

#### What this branch is

Issue #1447. The #1437 rename `contributing-davekjohn/` -> `dkj-policy/` left two statements in
`releases/README.md` naming a path that exists nowhere. The second is the one that matters: it tells
the reader that `.gitignore` keeps the release page's path token out of git, while naming a path
`.gitignore` does not cover. A reader who follows it and drops a token there commits it, into a
**public** repository -- the exact outcome the surrounding paragraph exists to prevent.

Scope is those two lines, as the issue scopes it. The file's three remaining
`contributing-davekjohn` mentions were checked and are a separate finding, filed rather than swept
here.

### CREATE

- [x] `releases/README.md:137` -- the *where the output lands* table row now reads
      `dkj-policy/releases/page/`
- [x] `releases/README.md:143` -- the path-token paragraph now reads
      `dkj-policy/releases/page/worker-path-token.txt`

### TEST

- [x] `git check-ignore -v dkj-policy/releases/page/worker-path-token.txt` -> matched by
      `.gitignore:55`, so the document's claim is now true of the path it names. The old path matches
      nothing, which is what made the sentence dangerous rather than merely stale.
- [x] `grep -n 'contributing-davekjohn/releases/page' releases/README.md` -> no hits.
- [x] `build-release-notes-page.ps1:727` derives the page directory from `Get-ReleaseNoteRoot`, which
      returns `dkj-policy/releases/audience` -- so the next build writes under `dkj-policy/`, which is
      what the table row now says.
- [x] Lint gate + all suites, via `open-pr.ps1`.

### DEPLOY: fix/1447-release-page-path

Two path statements in `dkj-policy/releases/README.md` repaired after the #1437 folder rename. The
table row for the release page's output directory and the path-token paragraph both still named
`contributing-davekjohn/releases/page/`, which exists nowhere. The second one was actively misleading:
it told the reader `.gitignore` keeps that path out of git, while `.gitignore` covers
`dkj-policy/releases/page/` only -- so a token dropped where the document pointed would have been
committed into a public repository, which is precisely what that paragraph is there to prevent.

**Score:** 1 -- documentation-only, and the failure it prevents has not happened. Naming it, because
that is the part a later reader can use: publishing a no-login URL token into a public repo, on the
document's own instruction.

#### What makes this deploy extra special

A stale path is normally cosmetic. This one had inverted its own safety claim: the sentence warning
that the token must stay out of git named the one directory `.gitignore` does not cover. The repair is
two words; what it is worth is that the document's guarantee is checkable again --
`git check-ignore` now agrees with the path the prose names.

**Score:** N/A -- internal to this repo's own release tooling; no subscriber of a service reads it.

#### Pull Request

the release-page path in dkj-policy/releases/README.md
