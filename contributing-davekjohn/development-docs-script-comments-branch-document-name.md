## Development: `docs/script-comments-branch-document-name` · 20260903-193401

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

Issue [#1337](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1337): about 30 comment
lines across the shared workflow scripts still named the branch's development document by the retired
fixed path `development.md`. Two made a claim that is now false (`fold-changelog-entry.ps1`'s "FIXED
path", `open-pr.ps1`'s "Every branch's document is called development.md"). Scoped out of the #1335
branch deliberately and handed here.

Since the issue was filed, #1335 and its follow-up #1339 landed: the document is now
`contributing-davekjohn/<branch>.md` (bare slug, no `development-` prefix). This branch's base was
brought up to that tip before the sweep, so the target name is `<branch>.md`, not the interim
`development-<branch>.md`.

### CREATE

- [x] Read each of the ~40 `development.md` mentions in `scripts/**/*.ps1` and split them into stale
  references vs. deliberate history (rename records in `Get-BranchFilePaths` /
  `Get-PrTemplateRecognisedPlaceholders`, the `SharedFile` field, legacy placeholder strings, the
  glob-reachability notes) -- 15 stale, the rest kept.
- [x] Update the 15 stale mentions: narrative comments to the name-free "the branch's development
  document", docstrings/examples to a concrete `contributing-davekjohn/<branch>.md`. Also corrected
  the two false claims and, in `check-plugin-integrity.ps1`, a stale "opens with an H1" that came
  with the same line.
- [x] Regenerate the plugin mirror (`scripts/sync/build-shared-scripts.ps1`) -- 9 mirrored scripts
  updated, drift check clean.

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors, mirror in sync.
- [~] No test suite change: the edits are comments only, no code path moves. `open-pr.ps1` runs the
  full suite as the gate of record.

### DEPLOY: `docs/script-comments-branch-document-name`

Fifteen comment lines across nine shared workflow scripts stopped naming the branch's development
document by the retired fixed path `development.md`. Narrative comments now say "the branch's
development document"; docstrings and worked examples name the current `contributing-davekjohn/<branch>.md`.
Two comments that did not merely name the old path but argued from it -- `fold-changelog-entry.ps1`
calling it "a FIXED path" and `open-pr.ps1` giving "every branch's document is called development.md"
as the reason for a repo-relative path -- were rewritten to hold. Deliberate history (the six/seven
rename records, the `SharedFile` legacy-name field, the append-only placeholder list, the
glob-reachability notes) keeps the old spellings. Asked for in
[#1337](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1337).

**Score:** 2

#### What makes this deploy extra special

N/A -- comment accuracy in the workflow scripts; no consumer-visible behaviour changes.

**Score:** N/A

#### Pull Request

Script comments name the branch document by its current per-branch path
