## fix/1762-pasteable-path-absolute

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

Inbound #1762: `Get-PasteableRef -Kind Path` (`scripts/lib/ref-print-lib.ps1`) judges the path against
`$RefPasteSafePattern`, which admits neither `:` nor `\`, so no absolute path can pass -- and a lane, a
worktree or a scratch tree is always absolute. The one `-Kind Path` caller carrying such a path today,
`check-plugin-integrity.ps1`'s nested-worktree remedy, therefore always prints the placeholder for the
very path it exists to hand the reader; `tidy-machine` and `worktree-lane` want the same.

Verified on pickup against the six inbound checks -- symptom, reasoning, repair, subject, size, repo --
all stand. The one correction: the title slightly overstates the size. The two current `-Kind Path`
callers (`check-plugin-integrity.ps1:497`, `sync-main.ps1:1167`) both pass repo-relative paths and keep
working; the block is for callers passing an absolute path.

Chosen repair: a per-kind pattern (issue option B), not the single-quote rewrite (option C). Option C
rests on "every command this workflow prints a path into runs in PowerShell", which contradicts the
lib's own header -- its remedies are "pasted into PowerShell, Git Bash and cmd alike". The per-kind
pattern keeps the allowlist discipline and leaves the deliberately-narrowed `-Kind Ref` axis untouched.

### CREATE

- [x] `ref-print-lib.ps1`: add `$script:PathPasteSafePattern` (the ref pattern plus `:` and a leading
  `/`), `ConvertTo-PastePath` (fold `\` to `/` -- `\` is bash's escape character, `/` is literal in all
  three shells and git accepts it on Windows), and `Test-PathPasteSafe`.
- [x] `Get-PasteableRef`: judge and carry the token per-`$Kind` -- a path passes as its slash-folded
  form, a ref unchanged. Header block and the two implementation comments updated to say three things
  differ now (pattern, noun, strip), not two.
- [x] `scripts/sync/build-shared-scripts.ps1`: mirrors regenerated (`dkj-policy`, `dkj-subagents-shopify`).

### TEST

- [x] `ref-print-lib.tests.ps1`: absolute Windows / already-forward-slash / POSIX-root / UNC paths pass
  and carry the folded token; an absolute path with a space or a shell metacharacter is still refused
  with the note showing the real backslash path; the ref axis still refuses `:` and `\`;
  `ConvertTo-PastePath` and `Test-PathPasteSafe` covered directly. 444 pass, 0 fail.
- [x] `check-plugin-integrity.ps1` green -- `[script-ascii]` 0 findings (the `\` escapes are ASCII),
  `[shared-script]` mirrors in sync.
- [x] Full lint + test gate via `open-pr.ps1`.

### DEPLOY: fix/1762-pasteable-path-absolute

`Get-PasteableRef -Kind Path` now judges a filesystem path against its own allowlist
(`$PathPasteSafePattern`) instead of the ref one, so an **absolute** path can pass: the pattern adds the
drive/scheme `:` and a leading `/` for a POSIX root, and `ConvertTo-PastePath` folds `\` to `/` first so
the one printed token is correct in Git Bash as well as PowerShell and cmd. Everything the ref allowlist
refuses -- a space, `$`, a backtick, a quote, `;`, `&`, `|` -- is still refused, and the deliberately
narrow `-Kind Ref` axis (#1594, #1617) is unchanged. Fixes inbound #1762: the `-Kind Path` callers that
carry an absolute path -- `check-plugin-integrity.ps1`'s nested-worktree remedy today, `tidy-machine` and
`worktree-lane` next -- were getting the `<path>` placeholder for every real path.

**Score:** 3

#### What makes this deploy extra special

N/A -- an internal formatter for the workflow's own printed remedies; no subscriber of a service reaches it.

**Score:** N/A

#### Pull Request

Get-PasteableRef -Kind Path accepts an absolute filesystem path

