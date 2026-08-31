## Development: `docs/deploy-links-folder-relative-v1` · 20260831-135506

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

Issue #1158: Section 2.5 still tells authors DEPLOY links are root-relative (scripts/x.ps1). Since #1041 the link gate judges a branch document's DEPLOY links against the changelog's own directory (contributing-davekjohn/), so the correct form is ../scripts/x.ps1. Rewrite 2.5's example and 'root-relative' framing to folder-relative, matching development.md's own 'FROM THIS DIRECTORY' boilerplate.

### CREATE

- [x] Rewrite Section 2.5's link paragraph in `contributing-davekjohn/CONTRIBUTING.md`: "root-relative,
      because the DEPLOY section lands at the repo root" → "folder-relative to `contributing-davekjohn/`,
      because the DEPLOY section folds into `CHANGELOG.md` there"; flip the example from `scripts/x.ps1` to
      `../scripts/x.ps1`; cite #1041 and `development.md`'s "FROM THIS DIRECTORY" boilerplate.

### TEST

- [x] Verified the reversed claim against `scripts/lint/check-plugin-integrity.ps1` (check 4): the base
      for a branch document's DEPLOY-section links is `$changelogDirForLinks = Split-Path -Parent
      $changelogFull`, i.e. `contributing-davekjohn/` since #1041, not `$RepoRoot`.
- [x] Confirmed the scaffolder wording matched (`scripts/lib/entry-scaffold-lib.ps1` line 534): this
      repo's `development.md` header reads "Relative links in that text resolve FROM THIS DIRECTORY".

### DEPLOY: `docs/deploy-links-folder-relative-v1`

Section 2.5 of `contributing-davekjohn/CONTRIBUTING.md` still told a DEPLOY author to write links
root-relative (`scripts/x.ps1`) "because the DEPLOY section lands at the repo root". That has been the
wrong instruction since issue
[#1041](https://github.com/DaveKJohn/claude-code-specialists/issues/1041): when `CHANGELOG.md` moved into
`contributing-davekjohn/`, `check-plugin-integrity.ps1` was repaired to judge a branch document's
DEPLOY-section links against the changelog's own directory, so `../scripts/x.ps1` is the form that
survives the fold and `scripts/x.ps1` is the one the link gate now refuses. The section's example and its
"root-relative" framing are rewritten to folder-relative, matching `development.md`'s own header
boilerplate. Docs only; the lint gate enforces the rule the prose now describes.

**Score:** 2 — noticed by the next author who writes a DEPLOY section and cross-checks the guide against
the gate; harmless until then because the gate already enforces the correct form.

#### What makes this deploy extra special

**Score:** N/A — internal contributor-guide wording; does not reach a subscriber of any consuming repo.

#### Pull Request

CONTRIBUTING.md 2.5: DEPLOY links resolve folder-relative to contributing-davekjohn/, not root-relative

