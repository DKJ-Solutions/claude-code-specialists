## Development: `fix/the-quota-headline-stops-vouching-for-upstreams-reset-time-v1` · 20260829-214043

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

#### The finding, verified before it was routed

Issue [#1112](https://github.com/DaveKJohn/claude-code-specialists/issues/1112), filed while working #1103
and after PR #1110 had already closed it. The report is explicit that the relay #1110 built is the right
shape; the defect is the **sentence being relayed**.

Verified against the tree rather than taken from the report:

- The 429 headline in `.github/workflows/claude-code-review.yml` still told the reader the reason line names
  *"when it comes back"*. Read at HEAD — the symptom stood.
- The three cited runs are real. `33267175141` failed at 18:02 UTC on August 29, 2026; `33268549172` and
  `33269512129` succeeded at 18:43 and 18:55 the same evening.
- **And they were real reviews, not the nine-second workflow-validation skip** the top of that workflow
  describes — jobs of 2m40s and 1m20s. Checked because that skip exits GREEN, and if it were the explanation
  the finding would have collapsed.
- `Get-AuthoredFailureNote` appends the annotation message verbatim, so the operator does read that sentence.

### CREATE

- [x] `.github/workflows/claude-code-review.yml` — the 429 headline no longer vouches for the reset time, and
      the comment block above it records the measurement, why the repair went here and not into the relay,
      and the standing rule the three corrections leave behind.
- [x] `scripts/lib/pr-issues-lib.ps1` + its plugin mirror — the two comment blocks around the 500-character
      bound, one of which asserted the reset time was *"the only actionable word in the whole note"*.
- [x] `contributing-davekjohn/CONTRIBUTING.md` — the paragraph that restated the timing as reliable.
- [x] `.claude/specialists/lenses/05-15-extension.md` — the lesson, beside #1103's.
- [x] `scripts/tests/pr-issues.tests.ps1` — the assert description carrying the disproven claim, and a note
      that the captured fixture deliberately keeps a headline the workflow no longer writes.

#### What was deliberately NOT done

- [~] **No caveat in `Get-AuthoredFailureNote`.** Dropped on purpose: the relay repeats what an author wrote
      and cannot know which authors are reliable, so a hedge there would hedge every workflow in every
      consuming repo — including ones whose timings are exact. The over-claim was this repo's own sentence.
- [~] **No explanation of WHY the quota returned early.** The issue asks for exactly this restraint. A rolling
      window, a session window clearing, an account change are all plausible and none was measured.
- [~] **The archived release note `releases/changelog/4.x/4.23.0.md` is left alone.** It records what was true
      when it was written; a release history is not corrected in place.

### TEST

- [x] `check-plugin-integrity.ps1` — green.
- [x] All suites under `scripts/tests/` — green, including `pr-issues.tests.ps1`.
- [x] The new headline measured at **296 characters** against the old **285**, so the relay's 500-character
      cap behaves as it did. The workflow can already emit up to 586 (headline + a 300-char reason) and the
      relay caps at 500, so this repo's own note is truncatable today — a pre-existing mismatch this branch
      does not widen materially. Filed separately rather than fixed here.

### DEPLOY: `fix/the-quota-headline-stops-vouching-for-upstreams-reset-time-v1`

A red `claude-review` still tells you the account is out of quota and which limit it hit — but it no longer
tells you **when work resumes**, because that half is upstream's and has been measured wrong by 2.5 days.
The headline now names the discrepancy and attributes the time to upstream, so an operator reading `ship-pr`'s
relayed line does not write off three days that turn out to be forty minutes.

The repair went into the workflow that writes the sentence, not into the relay that carries it: the relay is
generic on purpose and cannot know which authors are reliable, so a caveat there would caveat every workflow
in every consuming repo.

**Score:** 3

#### What makes this deploy extra special

It is the third time a claim about upstream behaviour written into this workflow has been corrected by
measuring it — a run tally wrong by 3x (#974), the wrong clock entirely (#1055), and now a reset time wrong by
2.5 days. So the change is not only the sentence: the comment block now carries the rule the three of them
add up to. **The headline states only what the STATUS proves; everything the `result` STRING says is
attributed to upstream rather than asserted.** The status proves the account is out of quota and that a re-run
adds none. It proves nothing at all about when the quota comes back.

**Score:** 2

#### Pull Request

The quota headline stops vouching for upstream's reset time
