## Development: `fix/a-retirement-is-tier-2-news-v1` · 20260829-102029

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

Inbound #1061: `/lock` and `/handover` were retired in v4.21.0 and scored `N/A` at tier 2, with the
reasoning "never anything an end user of a published product could see" -- the tier-1 test, applied in
a tier-2 repo, where the person running the workflow *is* the subscriber. No audience note carried the
removal, while four earlier notes (4.13.0-4.16.0, 13 mentions) had announced the convention's arrival.
The reporter's proposed location (the seven tests in `cut-release`'s consumer-section step) is half
right: those tests govern *how* an item already on the page is written, not *which* items reach it --
that selection happens upstream, at the tier question in `DEVELOPMENT-portable.md`. Two edits, both
portable-first: the tier rule itself, and a last-chance check at the point selection actually happens.
No script, gate or lint check -- a regex cannot tell whether an earlier note announced something.

### CREATE

- [x] Add the retirement rule to `DEVELOPMENT-portable.md`'s `### The two tiers` section, at the
  "`N/A` needs its reason too" paragraph: an entry retiring something an earlier note told the reader to adopt
  is never `N/A` at tier 2, with the #1061 measurement (13 mentions across four notes vs. zero) and the
  reason the asymmetry is the tell -- an arrival is news that writes itself, a retirement leaves nothing
  behind to describe, and nothing in the adoption path cleans up a consumer's tree.
- [x] Add the cut's own last-chance check to `cut-release/SKILL.md` step 3, ahead of the seven-tests
  table: before rewriting, ask whether a pending entry retires something an earlier note announced, and
  fix its tier score if so -- and say why this stays a selection check rather than an eighth test, so
  the seven's own measured provenance (five dev-tool changelogs, two declined neighbour rules) is not
  diluted and the count both citing pages give stays true.
- [x] Score this branch's own DEPLOY section, tier 2 included -- the branch is itself the case in point,
  since the mechanism being repaired has to deliver the notice 4.21.0's note never did.

### TEST

- [x] The quoted 4.21.0 reasoning and the mention counts checked against the tree rather than the
  report: `contributing-davekjohn/releases/changelog/4.x/4.21.0.md:1352-1353` carries the quoted
  sentence verbatim; `grep -i handover` over `releases/audience/4.x/{4.13.0,4.14.0,4.15.0,4.16.0,4.21.0,4.22.0}.md`
  reproduces 4/5/1/3/0/0.
- [x] Every new relative link resolves from its own file's directory -- the `SKILL.md` link to
  [Rendall's lens](../.claude/specialists/lenses/05-06-extension.md) needed five `../` segments, not
  four, checked against a neighbouring link in the same file rather than assumed.
- [x] The seven-tests count is unchanged in both places that cite it -- `cut-release/SKILL.md` and
  [Rendall's lens](../.claude/specialists/lenses/05-06-extension.md) still say seven; the new check was
  placed beside the table, not inside it.
- [~] No test suite covers prose content in these two files, so there is nothing to run beyond the lint
  gate's dead-link and heading checks at the PR step -- dropped rather than invented, per the repo's
  standing rule against a pre-emptive gate for a risk that has not repeated.

### DEPLOY: `fix/a-retirement-is-tier-2-news-v1`

The audience-tier question in `DEVELOPMENT-portable.md` now names the case it was silent on: an entry
that *retires* something an earlier release note told the reader to adopt is never `N/A` at tier 2. The
question to apply is "did an earlier note tell them to adopt this?", not "could an end user of a
published product see it?" -- the second is the tier-1 webshop-customer test, and reaching for it in a
tier-2 repo is exactly what produced inbound #1061: the entry retiring `/lock` and `/handover` in
v4.21.0 scored `N/A` on that test, so no audience note carried the removal, while the convention's
arrival had earned 13 mentions across four earlier notes (one of them the front-of-note item a reader
had to act on). The rule also states why a retirement is always actionable for the reader: nothing in
the adoption path reaches into a consumer's tree to clean up, so a retired convention leaves live
artefacts behind that only the note can flag as stale.

`cut-release/SKILL.md` gets the matching backstop, at the point the consumer section is actually
assembled rather than at the seven tests that govern its prose: before rewriting, check whether a
pending entry retires something an earlier note announced, and treat an `N/A` score there as wrong
rather than working around a page that is missing the item. The seven tests stay at seven -- this is a
selection question, not a writing one, and folding it into that list would borrow a provenance (five
dev-tool changelogs, two declined neighbour rules) it does not share and would falsify the count both
citing pages give.

**Score:** 3

#### What makes this deploy extra special

This is tier-2 news, not `N/A`, and the branch is itself the demonstration the rule argues for. As of
v4.21.0, `/lock` and `/handover` are retired: nothing you have written stops working, but if you had
adopted the convention while it existed, a `.claude/handover.md` still sitting in your repo is a stale
artefact -- nothing in a plugin update reaches into your tree to remove it, and nothing else in the
system would have told you it is now dead weight rather than live session context. Measured on the
consumer side: in a life-hub session on 2026-08-29, two days after the removal, exactly that file was
read as live context and then updated, because it was still there and no note said the mechanism was
gone. The tier question that let that pass is repaired now, so the next retirement announces itself in
the audience note the way this one should have.

**Score:** 3

#### Pull Request

A retirement of something consumers were told to adopt is tier-2 news, and the tier question now says so

