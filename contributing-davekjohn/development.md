## Development: `docs/the-adoption-commit-lands-on-the-trunk-v1` · 20260829-152454

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

The adoption commit cannot travel through the cycle it is installing, and nothing says so. A reader
is handed two documents on their first day that state the opposite as a rule -- the portable
contributing page describes a cycle where every change goes through a branch and a PR, and the
`CLAUDE.md` scaffolding carries "never directly on `main`" as a safety rule -- so day one is a
contradiction with no stated resolution (inbound #1085).

#### Verified, because "it is not a choice" is the whole claim

`new-branch.ps1` refuses before it touches HEAD when `scripts/lib/branch-info.ps1` is absent
(its pre-flight at :138, with a message naming the bootstrap scaffold), and that file is one of the
two scaffolds `bootstrap.ps1` writes -- and only when the workflow plugin is enabled. So before the
bootstrap there is no branch to make, and after it the tree already holds the adoption. Every other
route is downstream of the same commit: the lint gate needs the repo to have answered
`Get-LintScript`, the test gate needs a suite, and the CI entry gate needs the workflow file
`adopt-workflow-folder` places.

#### Two homes, because the contradiction has two halves

The reader meets it while adopting, and again later when someone asks why the repo's history opens
with a trunk commit. So: the adoption page, at the step where the bootstrap runs, and the **portable
contributing page**, which is the document that states the rule -- an exception written anywhere
else is an exception the reader has to find.

### CREATE

- [x] `plugins/ADOPTION.md`: at Step 1, say the adoption commit lands on the trunk, why it is forced,
      and that the cycle starts with the next change
- [x] `CONTRIBUTING-portable.md`: the same exception beside the rule it contradicts, so a consumer's
      own contributors find it a year later without reading the adoption page

### TEST

`check-plugin-integrity.ps1`: 0 errors. The two checks that matter for this change are the link scan
and the plugin-relative link resolution -- the new block in `CONTRIBUTING-portable.md` carries an
issue link and sits in a file that is resolved against its own plugin root rather than against
`plugins/`, which is the check that would catch a link that works here and breaks in a consumer.
Full suite run green.

The claim was verified against the tree rather than taken from the report: `new-branch.ps1`'s
pre-flight refuses on a missing `scripts/lib/branch-info.ps1` before touching HEAD, and
`bootstrap.ps1` is what writes that file. If that dependency ever goes away, this paragraph is what
has to change with it.

No suite is added. What changed is prose, and the mechanism behind it -- new-branch refusing without
the branch lib -- is already pinned by `new-branch.tests.ps1`.

### DEPLOY: `docs/the-adoption-commit-lands-on-the-trunk-v1`

The adoption now says that **the adoption commit itself lands on the trunk**, and why that is not a
choice: `new-branch` refuses without `scripts/lib/branch-info.ps1`, which is one of the files the
bootstrap writes, so before it there is no branch to put the work on -- and the lint, test and CI
gates are all downstream of the same commit. It is one exception, and it is spent by using it.

Written in two places, because the reader meets the contradiction twice: `plugins/ADOPTION.md` at
the step where the bootstrap runs, and `CONTRIBUTING-portable.md` beside the rule it contradicts, so
a consumer's own contributors find it a year later without reading the adoption page.

**Score:** 2

#### What makes this deploy extra special

Nothing is broken and nothing needed bridging -- the adoption works, and the very next change on the
measured repo went through the full cycle. What this costs a consumer is confidence on the first
day, in a repo where they have no prior for which rules are firm: they are handed a cycle that says
every change goes through a branch and a PR, and a `CLAUDE.md` that says never directly on `main`,
and then the only act available to them contradicts both. Both exits from that were wrong, and the
one that was taken had to write the reason into a commit message by hand.

**Score:** 3

#### Pull Request

the adoption page says that the adoption commit itself cannot travel through the cycle it installs

