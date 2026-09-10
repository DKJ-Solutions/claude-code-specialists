## fix/1813-safe-prose-docstring

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

Correct the docstring's false invariant: it claims one caller that pre-splits into lines, while five scripts call it and two deliberately send it un-split text. State the guarantee the code actually makes -- whitespace is collapsed first, so no newline survives, for any caller -- and drop the census. Also correct the same docstring's stale caller name (check-retired-doc-name.ps1, merged into check-consumer-prose.ps1 by #1421). Rebuild the two mirrors.

#### Verified before repairing, and the report's own census was short

The symptom stands: the sentence is in `scripts/lib/check-report-lib.ps1` and both halves of it are
false. `grep -rn "Format-SafeProseToken" --include=*.ps1 scripts/` gives **five** call-site scripts,
not the four the issue counted -- it missed `scripts/task/plugin-versions.ps1`, which calls it six
times. That only strengthens what #1813 asked for: drop the count rather than correct it, the way
`command-probe-lib.ps1` already records ("a list of sites in a docstring is a snapshot, it goes stale
silently ... `grep` is the inventory").

`scripts/lint/check-claude-home.ps1:241` is the measured counter-example the issue names, and its
comment says so in as many words. `scripts/sync/check-connectors.ps1:518` is the second non-splitting
caller, a raw GraphQL `errors[].message`.

#### A second staleness in the same docstring, found on the way

Three lines above the false sentence, the docstring names `check-retired-doc-name.ps1` as the caller
it was written for. That script no longer exists: it was merged into `check-consumer-prose.ps1` by
#1421 (commit `cd9505b1`). Repaired here because it is the same defect class in the same paragraph of
the same file -- not swept: the retired name is still cited in six other places, three of them in the
present tense and one of those consumer-facing plugin payload. Filed as **#1816**.

### CREATE

- [x] Correct the invariant in `scripts/lib/check-report-lib.ps1`: state that no newline survives the
      function **for any caller**, name the `'\s+'` collapse that guarantees it and why it is
      therefore load-bearing, cite the measured un-split caller, and carry no census.
- [x] Correct the same docstring's stale caller name to `check-consumer-prose.ps1`.
- [x] Rebuild the two mirrors -- `scripts/sync/build-shared-scripts.ps1`, 2 updated
      (`dkj-policy` and `dkj-subagents-alpha`).

### TEST

- [x] `scripts/tests/check-report-lib.tests.ps1` -- pinned the invariant the docstring now claims:
      `\n`, `\r\n` and `\r` each fold to a space, and a whole embedded multi-line document leaves as
      one line with no marker formed. The suite already pinned U+2028/2029 for this exact reason
      ("reorder or drop that pass and these two asserts are what fail") and a plain newline was the
      gap. **220 pass, 0 fail.**
- [x] Full gate: `check-plugin-integrity.ps1` + every suite, via `open-pr.ps1`.

### DEPLOY: fix/1813-safe-prose-docstring

`Format-SafeProseToken`'s docstring told the next reader that a newline could not reach the function,
because "the caller has already split the document into lines". Five scripts call it, two of them
never split -- and one of those, `check-claude-home.ps1`, has a comment recording the measurement that
`ConvertFrom-Json`'s parse error embeds the offending document whole, newlines and all. Two comments
in one tree, one of them with a measurement behind it, saying opposite things.

Nothing was broken and nothing is fixed in the code: the `'\s+'` collapse runs before the
control-character strip and `\s` matches a newline, so multi-line input has always been handled
correctly. What is repaired is the invariant the docstring hands over. A sentence saying *a newline
cannot reach here* reads as licence to drop that collapse as cosmetic or move it behind a condition --
and the caller that would then break is the one whose subject is an attacker-shaped string. The
sentence now states what the code guarantees, for any caller, says why the collapse is load-bearing,
and carries no census. The suite pins it, so the next reader who reorders that pass gets a red test
instead of a comment they can talk themselves out of.

**Score:** 2

#### What makes this deploy extra special

Nothing reaches a subscriber: this is a comment and a test in a check library, with no behaviour
change of any kind.

**Score:** N/A

#### Pull Request

Format-SafeProseToken's docstring states what the function guarantees, for any caller

