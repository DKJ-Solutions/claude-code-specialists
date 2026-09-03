## Development: `fix/pr-placeholder-list-append-only-v1` · 20260903-093620

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

#### Where this came from

Issue #1262 asked which of two implementations of #1255 is wanted. Answering it meant reading both,
and the read turned up something neither PR body mentions: the merged one, #1261, **replaced** a
string in `Get-PrDescriptionPlaceholderDefaults` where that list is documented append-only. That is
the same defect #952 was filed about, committed a second time, and it shipped green.

### CREATE

- [x] Restore `contributing-davekjohn/development.md` to the recognised list, above the per-branch
      form so the written one stays last
- [x] Correct the docstring's rename narrative -- it read `development.md -> development.md` since
      August 27 -- and add the September 3 per-branch rename to it
- [x] Mirror both into `plugins/workflows/contributing-davekjohn/scripts/lib/pr-body-lib.ps1`

### TEST

- [x] `pr-body.tests.ps1`: pin every published form as a superset assert, plus a named assert for the
      dropped one, so a REMOVAL fails while an append needs no edit here
- [x] Proved the guard fires: with the string removed again, 2 failed / 195 passed
- [x] Full suite green with it restored: 197 asserts

### DEPLOY: `fix/pr-placeholder-list-append-only-v1`

`Get-PrDescriptionPlaceholderDefaults` recognises the pre-#1255 placeholder again. That string --
`contributing-davekjohn/development.md` -- was the WRITTEN one from August 27 to September 3, 2026, so
it is what every PR template scaffolded in that week carries right now, here and in every consumer
that adopted a release in it. #1255 replaced it rather than appending, and an unrecognised placeholder
is not a warning: open-pr leaves it in place and the PR body ships with no description at all. That is
the exact outcome measured in #952, at 0 matches in smartwatchbanden, and the exact list that exists to
prevent it.

Nothing asserted the removal, and the reason is worth naming: the append-only guard added after #952
derives the migrated string from the pre-`workflow-davekjohn` one, so it can only speak for forms that
have a partner under the old folder name. Document renames have none -- the asymmetry is deliberate and
correct -- so every rename of the document itself walked through the gap. The guard here is keyed on
history instead: every form this family has ever published is pinned as a set, and the list must be a
superset of it. Appending needs no edit; removing is the only thing that fails.

**Score:** 3

#### What makes this deploy extra special

This reaches consumers, and it reaches the ones who did nothing wrong. A repo that adopted a release
between August 27 and September 3 has the affected string checked into its own
`.github/pull_request_template.md`, where an update does not rewrite it -- so without this the list
tolerates only the templates that need no tolerance, which is the inversion #952 named. No migration to
perform: the string is recognised again on the next update.

**Score:** 3

#### Pull Request

the PR placeholder list is append-only again

