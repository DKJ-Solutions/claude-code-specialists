## Development: `docs/consumer-bumps-default-is-empty-v1` · 20260829-122521

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

Inbound [#1070](https://github.com/DaveKJohn/claude-code-specialists/issues/1070): two shipped texts
state a `Get-ReleaseConsumerBumps` default that `cut-release.ps1` does not have. Fix the wording, not
the fallback -- an unstated seam has to keep meaning what it meant yesterday.

#### The report was verified against the tree before it was routed

All six checks. The symptom stands (`cut-release.ps1:314` is `-Default @()`), the reason holds (the
comment above that line calls the `@()` fallback load-bearing for the two-name read), the proposed
repair names a mechanism that exists, and the subject and repo are both this one.

**The size needed correcting in both directions.** The report named two texts and a repo-wide grep found
two more mentions, both correctly left alone: `releases/changelog/4.x/4.21.0.md:449` is an archived note
(history, per the language rule's own exception) and `repo-config.ps1:702` is **this repo's own answer**
to the seam -- accurate, and the likeliest origin of the misreading. Against that, the report counted
two files where the tree has three: `plugins/workflows/.../build-release-notes-page.ps1` is a generated
mirror of the root copy, so it is one edit plus `build-shared-scripts.ps1` rather than two edits.

Tessa's lens says to grep the claim across the page before editing the reported line, because claims
here come in pairs. That turned up a third candidate -- `lenses/05-06-extension.md:716` -- which is
**already right**: *"The fallback for an undefined seam is `@()` -- the tier switched off."* Third model
text beside `script-contract-lib.ps1:329`, and no change.

### CREATE

- [x] `skills/cut-release/SKILL.md` step 0a: the premise corrected, and the conclusion widened with it.
      The old sentence reasoned that a *patch* has nowhere for the timing figure to land; with the real
      `@()` fallback, a repo that never answered the seam has nowhere on **any** bump, so the
      conditional it was drawing is not conditional at all there. Both shapes are now named -- the
      unanswered repo and one that answered it the way this source does -- and a second paragraph
      records what the page claimed until #1070, in the same form as the `#988` note four paragraphs up.
- [x] `scripts/release/build-release-notes-page.ps1`, `Test-ReleaseVersionTrimmable`'s docstring: the
      "always zero in practice" paragraph now attributes the missing patch note to *the consumer's
      answer* rather than to a shipped default, and says the measured consumer had answered it. A second
      paragraph states the real fallback and what it implies -- no note for any bump, and a row exists
      only where a note file does, so such a page has no rows rather than `.0` rows.
- [x] `build-shared-scripts.ps1` re-run: the plugin mirror updated from the root copy.

#### What was deliberately not changed

The fallback itself. Making it `('minor','major')` would start writing a document in every consumer that
has never answered this knob -- the thing `SKILL.md:643` argues against for `Get-ReleaseNoteRoot` in the
same breath. `build-release-notes-page.ps1` computes nothing wrong and its computation is untouched; the
wrong premise sat only in the paragraph justifying why its observation holds.

### TEST

- [x] Covered by the standing gates, which the push runs: `check-plugin-integrity.ps1` (dead links, and
      check 27 `[script-ascii]` -- load-bearing here, since the new docstring text lands in a `.ps1`
      and had to be written with `--` rather than dashes) plus every suite in `scripts/tests/`.
      `build-shared-scripts.ps1 -Check` is part of that gate and is what holds the mirror I regenerated.
- [~] No new suite. Both changes are prose inside a docstring and a skill page; nothing executable
      moved, so there is no behaviour for an assert to pin. The claim that *was* worth pinning is
      already pinned: `cut-release-guardrail.tests.ps1:306-311` asserts the two-name read whose `@()`
      fallback this branch is about, and `repo-config.tests.ps1:207-217` pins this repo's own answer.

### DEPLOY: `docs/consumer-bumps-default-is-empty-v1`

Two shipped texts stated that `Get-ReleaseConsumerBumps` defaults to `('minor','major')`. It defaults to
`@()` -- the consumer tier switched off -- so in a repo that has never answered that seam, `cut-release`
drafts the hand-written note for **no** bump at all. `('minor','major')` is this source repo's own answer
in `repo-config.ps1`, and both texts had promoted it to the shipped fallback. The `cut-release` skill
page said it while reasoning that a patch has nowhere for the release-timing figure to land, and
`Test-ReleaseVersionTrimmable`'s docstring said it while explaining why every version on a built page
ends in `.0`. Neither computes anything from it — the fallback and the function are unchanged, and the
repair is the wording, because an unstated seam has to keep meaning what it meant yesterday. Both
paragraphs now name the real fallback and say what each shape produces, and both record what they
claimed until [#1070](https://github.com/DaveKJohn/claude-code-specialists/issues/1070).

**Score:** 3

#### What makes this deploy extra special

This is the page a release manager has open **while** they cut, and it told a repo in exactly the wrong
shape that its minors and majors already produce a draft. `thumbnail-generator` reported it from that
position: audience tier stated, note root stated, the directory present, its contributing page telling
the reader where the draft lands — and this one knob never answered, which `adopt-config` legitimately
marks `decide`. Three places said the document existed; one absent line switched it off, and both
pending entries carried a scored tier-1 section that would never have reached a note.

**Nothing was going to catch it.** `check-script-contract` reports a missing optional seam together with
its declared fallback and never judges whether that fallback suits the repo — so it printed the *correct*
text (`no consumer tier at all`) while the skill page said the opposite. The gate accurate and silent,
the page confidently wrong, and nothing comparing the two. Any consumer on 4.22.0 reading that page is
reading it wrong today.

**Score:** 3

#### Pull Request

The Get-ReleaseConsumerBumps default is empty, not minor and major

