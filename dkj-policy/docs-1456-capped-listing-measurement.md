## docs/1456-capped-listing-measurement

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

Issue #1456 collapsed on pickup. It reported that no issue in this repo's history has ever been
assigned to `DaveKJohn` -- 0 of 67 assigned issues -- against 132 PRs and 83 authored issues. All three
figures come from one `gh` listing capped at `--limit 200`/`300`, and the headline is `DaveKJohn`'s own
count inside that window reported as the count that excluded them. Over the full history `DaveKJohn` is
the most-assigned identity of the three.

Nothing to repair in the tree: the closure is the deliverable, and the lesson is the mechanism. Pattern
five in the `triage-inbound` skill already covers a real finding whose size is wrong; this is the
variant where the mis-measurement IS the finding, and it fails one step earlier than the four already
recorded there.

### CREATE

- [x] Re-measure #1456's three figures over the full history (`gh issue list`/`gh pr list`, uncapped)
- [x] Reproduce the reported figures from a capped window, to name the mechanism rather than infer it
- [x] Verify the report's identity bullet against `gh auth status` and `git config user.name`
- [x] Record the instance and the cap mechanism under pattern five in
      `.claude/skills/triage-inbound/SKILL.md`

### TEST

- [x] `check-plugin-integrity.ps1` + the full suite pass via `open-pr.ps1`
- [x] The skill's frontmatter still describes **six** patterns -- this adds an instance to the fifth,
      not a seventh mode, so no `description` change and no roster/lint impact

### DEPLOY: docs/1456-capped-listing-measurement

A fifth measured instance under the `triage-inbound` skill's fifth pattern, plus the mechanism behind
it. #1456 reported an absence that does not exist -- `DaveKJohn` is in fact the most-assigned identity
here, 88 of 221 assigned issues -- and all three of its figures reproduce exactly from a single `gh`
listing capped at `--limit 200`/`300`. The headline `67` was that account's own assignee count inside
the window, reported as the count that excluded it.

The four instances already recorded are reports that were real and mis-sized. This one is the variant
where the mis-measurement is the whole finding, so the pattern's intro now says so rather than leaving
its name to carry it.

**Score:** 2 -- a skill only a pickup reads, and it changes no gate. It earns more than cosmetic because
the mechanism is reproducible and silent: `gh issue list`/`gh pr list` return the newest `--limit` rows
and say nothing about what they left out, so a windowed figure is indistinguishable from a full-history
one in the report that quotes it.

#### What makes this deploy extra special

One capped window produced **three** mutually consistent figures, all three wrong. That is the part
worth carrying: a report whose numbers agree with each other is not thereby corroborated -- they can
share a single bad window. The report also carried its own counterexample, citing #1450 as claimed by
the filing session while #1450 is assigned to `DaveKJohn`, one of the 88 it argued do not exist.

**Score:** N/A -- internal triage evidence for this repo's own pickups; no subscriber of a service
reads it.

#### Pull Request

Record the capped-listing measurement failure in triage-inbound
