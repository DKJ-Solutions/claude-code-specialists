# Development cycle: `docs/trim-branch-doc-steps-guidance-v1` · 20260823-212913

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own.** It is the result, and the one part of this file that
> travels verbatim into `CHANGELOG.md` at the merge. In each tier, write the reason **above**
> the `**Score:**` line -- anything below it is discarded. Links in that text resolve FROM THE
> REPO ROOT, so write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only inside this
> repo belongs under the first `**Score:**`. If the change reaches that reader not at all,
> N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

Take the guidance comments out of the instantiated branch document: comments belong in the template, and the DEPLOY section must be spotless before it travels into CHANGELOG.md.

## PLAN

- [x] Measure what the comments cost and whether anything needs them: 40 of 87 lines were comment, and the
  marks convention, the phase arc and the DEPLOY rule already live in `DEVELOPMENT-CYCLE-portable.md`,
  `workflow-davekjohn/CLAUDE.md` and three skill pages.
- [x] Decide per block rather than sweeping. Two rules have a SILENT failure mode -- text below the Score
  line is discarded without a word, and inbound #806 was a consumer merging two `../../scripts/...` links
  that landed outside the repo with every gate green -- so those were hoisted, not dropped.
- [~] Making the DEPLOY guidance visible instead of removing it: dropped, because it would have broken the
  gate. `Get-EntryScaffoldFindings` strips comments and THEN measures emptiness, so visible boilerplate in
  a tier section reads as an answer and a tier nobody filled in would reach `CHANGELOG.md` blank.

## CREATE

- [x] `StepsGuidance` becomes visible markdown -- a blockquote above the phases -- and is emitted as-is
  rather than through `Format-EntryGuidanceComment`.
- [x] `PullRequest`, `Tier` and `TierOptional` are empty, so no comment stands inside the DEPLOY section.
- [x] The per-repo audience sentence comes along rather than dying with `TierOptional`: the `{0}` seam is
  read at the new site through `Format-EntryAudienceGuidance`, and a repo asking about no audience tier
  gets the line removed rather than a dangling placeholder.
- [x] Both copies of `entry-scaffold-lib.ps1` held byte-identical, as `[shared-script]` requires.

## TEST

- [x] Fixed a bug the empty blocks exposed: the blank line between a tier heading and its `**Score:**`
  label used to ride on the guidance block, so tier 0 came out with two blanks and the tiers below it with
  none -- the shape the code's own comment calls "something was deleted here". The blank now belongs to the
  heading that emits it.
- [x] Three of the five failing asserts were failing on WORDING, not substance: the literal phrases had
  wrapped across lines. The document now carries them intact, so inbound #810 stays repaired -- the
  guidance still reaches the file a branch is handed.
- [x] Two asserts repointed to the new location rather than deleted, each with the move recorded above it.
- [x] Full gate green in the lane: lint 0 errors, all 52 suites, 481 asserts in `entry-scaffold`.

## DEPLOY: `docs/trim-branch-doc-steps-guidance-v1`

Every branch document here was born carrying 40 lines of guidance the author had already read -- half the
file -- restating rules that live in three other places. It is a blockquote of 17 visible lines now, the
DEPLOY section carries no comment at all, and a fresh document is 35 lines instead of 87. The part that
matters for this repo is the DEPLOY section being spotless: it is the text that travels verbatim into
`CHANGELOG.md`, and every entry written from here on is read out of that file.

**Score:** 3

### What makes this deploy extra special

A consumer meets this on their next plugin update, on every branch they open, and it changes what the
document in front of them looks like -- so they notice without being told. Two things were deliberately
kept rather than swept: the rules with a silent failure mode (text below the Score line is discarded; a
relative link in the entry resolves from the repo root, which inbound #806 measured as a consumer merging
two dead links with every gate green) and the per-repo sentence naming who their audience tier is, which in
a tier-1 repo is the only line that names their reader anywhere.

**Score:** 3

### Pull Request

The branch document stops restating the rules it already links
