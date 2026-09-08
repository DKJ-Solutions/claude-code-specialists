## fix/1637-sync-main-path-print

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

Two issues, one repair, because they are the same wall at the same script. #1637 is the **paste**
axis: `sync-main.ps1`'s conflict remedy printed a paste-ready `git diff --no-index` carrying a raw
file path twice -- the mirror operand is derived from the repo operand, so one hostile path poisoned
both -- and it printed them double-quoted, which is the exact spelling `ref-print-lib.ps1`'s own
header was written to reject. #1638 is the **display** axis: the take / hold-back / conflict listings,
the run's primary report, printed a raw path through a padded `{1,-46}` format.

The design call #1638 asked to be made once: the ref allowlist did NOT need widening (a theme path
passes it as written), so the paste axis takes a parameter rather than a near-copy of the function.
The display axis does need a second function, because the ref strip collapses space runs and trims
and a path may legitimately carry a space where a ref may not.

#### What is deliberately NOT in this branch

`#1629` -- the same display axis at this script's predecessor paths (line 556, another branch's file
set). It is unclaimed, so it keeps its own route; `Get-DisplayPath` now exists for it, which makes its
repair the one-line substitution its own body asked for.

### CREATE

- [x] `ref-print-lib.ps1`: `Get-DisplayPath` -- the prose strip for a path. Replaces `[\p{Cc}\p{Cf}]`
      with one space per character and, unlike `Get-DisplayRef`, does NOT collapse runs or trim. An
      all-invisible path is named rather than blanked.
- [x] `ref-print-lib.ps1`: `Get-PasteableRef -Kind Ref|Path`. It selects the noun the refusal note
      speaks in and the strip that renders the value there, and nothing else -- the allowlist, the
      placeholder and the reasoning are unchanged.
- [x] `sync-main.ps1`: the three padded listings go through `Get-DisplayPath`.
- [x] `sync-main.ps1`: the conflict remedy judges the path once with `-Kind Path` and answers both
      operands from that one verdict, so the two holes are visibly one substitution.
- [x] The lib's own description records the new axis, the provenance argument, and why the two axes
      stay two.
- [x] Mirrors regenerated (`build-shared-scripts.ps1`): `dkj-policy` and `dkj-team-shopify`.

### TEST

- [x] `ref-print-lib.tests.ps1`: 398 asserts, 0 fail. The three properties that make `Get-DisplayPath`
      a second function are each asserted **against `Get-DisplayRef`'s own answer** on the same input,
      so a later collapse of the two into one function goes red and says why.
- [x] Both mirrors asserted to carry the new function -- the failure the drift lint cannot see.
- [x] `sync-main.tests.ps1`: 126 asserts, 0 fail.
- [x] The removed spelling is asserted ABSENT, so the double-quoted raw path cannot come back quietly.

### DEPLOY: fix/1637-sync-main-path-print

`sync-main` no longer prints a file path raw. Its primary report -- the take, hold-back and conflict
listings -- goes through a new path-shaped display strip, and its conflict remedy no longer
interpolates a path into a paste-ready `git diff` at all: the path is judged against the same
allowlist a branch name is, and a refused one is replaced by `<path>` in **both** operands with a note
naming the real path outside any command context.

Two things make this more than a sweep. The double quotes that were there were the defect rather than
the guard -- command substitution runs inside double quotes in bash and PowerShell alike, so the line
read as protected while closing nothing, which is worse than a bare interpolation because the next
reader sees quotes and stops looking. And the display strip had to be a second function rather than a
reuse: `Get-DisplayRef` collapses space runs and trims, which is right for a ref (git forbids a space
in one) and wrong for a path, where a doubled or trailing space is part of the name. Preserving one
space per removed character is also what fixes the alignment -- a zero-width run spends format width
without spending display columns, so a padded row used to slide against its neighbours.

**Score:** 3

#### What makes this deploy extra special

The paths are the point. They come from this repo's own `HEAD` and from a filesystem walk of the
pulled **live theme** -- which third parties edit through the Shopify theme editor, outside any
review, and which is the entire reason that sync exists. Measured for #1637: `git ls-tree -r` and
`git diff --name-only` hand back `assets/x$(id -un).js` and `assets/z;touch owned.js` unquoted in
every `core.quotePath` setting, because git quotes control characters and high bytes and not shell
metacharacters. So the consumer running this sync against a real store is the reader who was being
handed a command to paste, built from a name they do not control.

**Score:** 3

#### Pull Request

sync-main stops printing raw file paths: a faithful display strip and a paste refusal for the conflict remedy
