## docs/dkj-policy-folder-update-section

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

`dkj-policy/README.md` is the folder index a session in this repo reads, and it said nothing about
updating the plugins this repo consumes — from itself. That is the one repo where the omission costs
most: **this repo consumes its own marketplace**, so a session here runs the *installed* copy of the
workflow rather than the tree it is standing in, and a merge advances neither. Add an UPDATE section
between the seam table and the pointer list.

#### Why it goes here and not only in the plugin page

The plugin's own README got the consumer-facing version in #1565. This page is the source repo's own
answer: it names the two plugins this repo enables, the self-consumption trap (a push does not advance
the marketplace clone, and between two releases no version check can tell you it is behind), the
connector register as the only place a lagging machine is visible, and `sync-roster` as the catch-up a
new specialist needs. None of that is portable, so none of it belongs on the plugin page.

### CREATE

- [x] Add `## Updating the plugins — in every other checkout of this repo` to `dkj-policy/README.md`,
      before `## Where the rest lives`.
- [x] Correct this page's own intro, which claimed the folder index carries **two** sections below the
      divider. It carries three now; the historical claim about `CONTRIBUTING.md` is narrowed to the
      first and the last, which are the two that actually moved there on August 26, 2026.

### TEST

- [x] `check-plugin-integrity.ps1` + every suite, via `open-pr.ps1` — the printed
      `claude plugin update` lines carry `--scope project` and sit under the marketplace refresh
      (check 11), and every new link is relative and resolves in-tree (check 4).

### DEPLOY: docs/dkj-policy-folder-update-section

`dkj-policy/README.md` now says how to **update** the plugins, not only how the folder is arranged — a
section between the seam table and the pointer list, written for the case this repo is peculiarly
exposed to: it consumes its own marketplace, so a session here runs the installed copy and **a push does
not advance the local clone**. It carries the two commands per plugin, the session restart, and then the
three things that make an update invisible until somebody looks: between two releases no version check
can tell you the clone is behind, the install record is per-checkout and keyed on its folder path
(#1449), and the only place a lagging machine is actually visible is the connector register. It closes
on the two catch-ups an update can require — the seam function `script-contract-sessioncheck` reports,
and the roster row and lens a newly arrived specialist needs.

The same edit narrows this page's intro, which called the index **two** sections below the divider and
is now three.

**Score:** 3

#### What makes this deploy extra special

N/A — this is the source repo's own folder index, and nothing here travels to a subscriber. The
consumer-facing half of the same subject shipped in #1565, on the plugin's own page.

**Score:** N/A

#### Pull Request

Say how to update the plugins in another checkout of this repo
