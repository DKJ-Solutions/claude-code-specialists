## fix/1858-bidi-console-strip

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

#### What #1858 asked, and what was verified before repairing

The report was held against the tree first. `Format-ForConsole` did strip `[\x00-\x1F\x7F]` and only
that, so the symptom stood. The three checks the issue asked for were answered rather than assumed:

- **git already refuses some of this** -- true and unchanged. `check-ref-format` rejects `\p{Cc}` in a
  ref name and **accepts** `\p{Cf}`, which is #1617's own measurement in this tree. An issue title has
  no filter at all, and its author needs no push access: on a public tracker anybody can open one.
- **Stripping or escaping** -- settled by the argument already inside the function, rather than by a new
  one. Each character becomes a space so two words cannot be welded into a title that reads as a
  different sentence; that reasoning covers a bidi mark exactly as it covers a NUL.
- **The blast radius** -- it is a mirrored lib, so this lands in every consumer on the next release.
  Which is why the class chosen is the one this repo already ships in two other libs rather than a
  third, private answer.

#### And a gap the report did not name

The old class also missed **C1** (U+0080..U+009F), where some terminals read 0x9B as CSI. It is above
0x7F, so it fell in the same hole. `\p{Cc}` closes it for free.

### CREATE

- [x] `Format-ForConsole` strips `[\p{Cc}\p{Cf}]` instead of `[\x00-\x1F\x7F]`, with the reasoning,
      the rejected alternative and the third-copy declaration recorded in its docstring
- [x] `Format-AuthoredText`'s count block in `pr-issues-lib.ps1` updated -- the pin's own instruction
- [x] the `new-branch` skill page: **five** consoles, not four, and **three** libs, not two
- [x] both plugin mirrors regenerated via `build-shared-scripts.ps1`

### TEST

- [x] eight asserts in `claim-issue.tests.ps1` -- C1, U+202E, the isolate pair, a zero-width space,
      a leading U+FEFF proving nothing is trimmed, and printable text surviving verbatim
- [x] the cross-lib drift pin in `pr-issues.tests.ps1` widened to three libs, plus an assert that the
      old ASCII class no longer strips anything
- [x] `claim-issue.tests.ps1` 144/144, `pr-issues.tests.ps1` 906/906
- [x] `check-plugin-integrity.ps1`: 0 errors
- [~] no fixture suite needed -- the function is pure and the lib was already dot-sourceable

### DEPLOY: fix/1858-bidi-console-strip

`claim-issue` neutralised only the ASCII control range in the text it prints, so a Trojan-Source-shaped
spoof reached the terminal untouched: a U+202E RIGHT-TO-LEFT OVERRIDE, a bidi isolate pair or a
zero-width run in an issue title, a commit subject or a branch name could visually reorder the line
reporting it, without a single byte below 0x80. It now strips `[\p{Cc}\p{Cf}]` -- the same class
`pr-issues-lib.ps1` and `ref-print-lib.ps1` already apply to the other four consoles this workflow
writes foreign text to -- which closes the C1 range (0x9B reads as CSI in some terminals) in the same
move. Each character still becomes a space rather than vanishing, so nothing can be welded into a
title that reads as a different sentence, and nothing is collapsed or trimmed: a title is quoted
evidence. The cost is stated rather than hidden -- a title written in Arabic or Hebrew loses the marks
that order it, and an emoji joined by U+200D prints as its parts.

**Score:** 2

#### What makes this deploy extra special

N/A -- nothing outside this repo's own workflow surface changes. It hardens a console line a maintainer
reads; no subscriber of any service touches `claim-issue`.

**Score:** N/A

#### Pull Request

Format-ForConsole also neutralises Unicode bidi and zero-width controls
