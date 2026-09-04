## fix/1419-prose-echo-sanitize

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

Add Format-SafeProseToken to check-report-lib and apply it (plus Format-SafePathToken on the path) in check-retired-doc-name.ps1; extend the suites; mirror via build-shared-scripts.

#### What #1419 reported, and what the tree actually says

The issue names **two** checks. Only one of them exists: `check-supremacy-declaration.ps1` is #1415,
still open and unbuilt, with no PR. So the repair has one subject, not two -- and the way to keep the
issue's own concern (one sanitizing while the other does not is worse than both being consistent) is to
put the answer in the **shared lib**, where #1415's build inherits it by calling it rather than by
remembering to.

The issue also asks for a trade-off to be settled rather than assumed: `Format-SafePathToken` strips the
square brackets a reader might want to search for. Settled by measuring what the echo is actually for --
the caller prints `<file>:<line>` immediately above it, so the echoed text is a **preview for
recognition**, not the locator. That is what makes a cap affordable, and it is why the brackets are
**substituted rather than deleted**: the only property that has to hold is that no marker can form.

### CREATE

- [x] `scripts/lib/check-report-lib.ps1`: name the two classes once (`$script:CheckReportControlPattern`,
      `$script:CheckReportMarkerPattern`) so the three sanitizers argue about the same two things, and
      rewire `Format-SafePathToken` onto them -- identical behaviour, proven by its existing asserts.
- [x] Add `Format-SafeProseToken`: control characters removed **and announced**, square brackets
      substituted to round ones **uniformly and silently**, whitespace collapsed, capped at 200 with an
      ellipsis. The whole per-shape argument is in its docstring.
- [x] `scripts/lint/check-retired-doc-name.ps1`: dot-source the report lib, put `$f.Rel` through
      `Format-SafePathToken` and `$f.Text` through `Format-SafeProseToken`, and leave `$f.Name` /
      `$f.Since` raw with a comment saying why -- they are the plugin's own strings, and sanitizing
      them would be theatre that quietly caps text this repo controls.
- [x] Disclose the substitution in the check's footer, so the preview never silently misrepresents
      the file.
- [~] Nothing done for `check-supremacy-declaration.ps1` -- it does not exist (see PLAN). Reported
      back on #1419 and #1415 instead, so its build starts from a helper rather than from a rule.
- [x] Mirror to the three plugin payloads via `scripts/sync/build-shared-scripts.ps1`.

### TEST

- [x] `scripts/tests/check-report-lib.tests.ps1`: the new sibling end to end -- why it exists (both
      existing forms shown destroying the sentence), the bracket substitution, the note firing on a
      control character and **not** on a collapsed tab, the cap, the empty and wholly-unprintable cases.
- [x] The bidi assert failed on the first run and it was **right**: PowerShell's `-ne` compares strings
      culture-sensitively, and an invariant comparison treats format characters as IGNORABLE -- so
      `"start<U+202E>end" -ne 'startend'` is `$false`. The "shown sanitized" note would have stayed
      silent for exactly the class most worth announcing. Repaired with an ordinal comparison
      (`Test-TokenChanged`) and, since `Format-SuspectToken` carried the same line, applied there too
      with its own zero-width assert.
- [x] `scripts/tests/retired-doc-name-gate.tests.ps1`: the same thing end to end, because the defect was
      never in the helper -- it was this script printing around it. A consumer document carrying a
      forged `[ERROR]` and an ESC now yields exactly one marker in the report, no ESC, a legible
      `(ERROR)`, the note, and the footer.
- [x] Lint gate green (0 errors); full suite via `open-pr.ps1`.

### DEPLOY: fix/1419-prose-echo-sanitize

`check-retired-doc-name.ps1` echoes a line out of a consumer's own markdown so the reader can recognise
what to repair, and printed it raw -- into a report the SessionStart hook forwards into session context
and filters by matching `[ERROR]` over it. Untrusted text therefore chose how loudly it was reported,
and could repaint a terminal or reverse the reading order of the text around it on the way past. The
path and the line now go through `check-report-lib.ps1`; the plugin's own strings stay raw. A third
sanitizer, `Format-SafeProseToken`, was needed because a sentence is not a token: the id form eats its
punctuation and the path form eats the brackets that in prose are a markdown link, so brackets are
substituted rather than deleted and only that is disclosed in the footer. Building it surfaced a real
defect in the neighbouring `Format-SuspectToken`: its "say when the display differs" check used
PowerShell's culture-sensitive `-ne`, which treats format characters as ignorable, so a suspect id
containing a zero-width or bidi character had been reported as clean since #309. Both now compare
ordinally.

**Score:** 2

#### What makes this deploy extra special

Every repo with the workflow plugin runs this check at session start, so this is where a consumer's own
prose enters a session's context. Nothing is known to have gone wrong, and the named failure is
concrete: a line in a consumer's docs -- a repo whose pages discuss check output, which these repos do --
carrying a bracketed marker or an ANSI escape, shaping the report about itself.

**Score:** 2

#### Pull Request

The retired-name check sanitizes the consumer prose it echoes into session context

