## docs/dkj-policy-update-section

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

The plugin README explains how to *enable* the workflow and never how to *update* it. That gap is not
cosmetic: both things an update touches — the cached marketplace clone and the install record — are
**per-machine** state, so a consumer who updated on one machine is still on the old version everywhere
else, and nothing in a session says so. The workflow keeps working at whatever version that machine
last installed. Add an UPDATE section beside `## Enabling it`, pointing at the family's measurements
rather than restating them.

#### What this branch deliberately does NOT do

It states no measurement of its own. The two-command procedure and every measurement behind it already
live in the family's `INSTALL.md` under *Staying up to date*; this section names the per-machine
consequence, the dkj-policy-specific catch-up after an update, and links there for the rest. A second
copy of a measurement is a second thing that can go stale.

### CREATE

- [x] Append `## Updating it` to `plugins/dkj-policy/README.md`, after `## Enabling it`: the two
      commands, the session restart, the ministry's own pair, the per-machine reasoning, why neither
      part of the pair is optional, the script-contract catch-up, and what an update never touches.
- [x] Correct the 13 `DaveKJohn/claude-code-specialists` citations in that same file to
      `DKJ-Solutions/…` — the repo-citation rule in `CLAUDE.md` corrects them when a file is edited
      for other reasons rather than sweeping the tree, and this file was being edited.

### TEST

- [x] `check-plugin-integrity.ps1` + every suite, via `open-pr.ps1` — the printed
      `claude plugin update` carries `--scope project` and sits under the marketplace refresh, which
      is what check 11 holds a lifecycle command to; the new relative links stay inside the plugin
      root, which is what the `[plugin-link]` check holds a plugin page to.

### DEPLOY: docs/dkj-policy-update-section

The `dkj-policy` plugin page now says how to **update** the plugin, not only how to enable it — a
`## Updating it` section beside `## Enabling it`. It carries the two commands, the session restart, and
the ministry's own pair; then the reason the section has to exist at all: the cached marketplace clone
and the install record are both **per-machine** state keyed on the checkout's folder path, so a version
picked up on one machine changes nothing on the next one and no session says so. It closes on what a
consumer needs afterwards: the script-contract catch-up an update can require — the shared scripts may
call a repo-owned function that checkout has never had (#147), which `script-contract-sessioncheck`
reports and `adopt-dkj-policy` Part 2 fills in — and the assurance that an update never touches the
consumer's own `dkj-policy/` folder, so work in flight cannot be lost.
No measurement is restated: the page links the family's `INSTALL.md` for those.

The same edit corrects that file's 13 `DaveKJohn/claude-code-specialists` citations to the canonical
`DKJ-Solutions/…`, under the rule that corrects them in a file being edited anyway.

**Score:** 3

#### What makes this deploy extra special

For a consumer running this workflow in more than one checkout — which is every consumer with a laptop
and a desktop — the page they read now answers the question that sends them to the wrong tree: *why is
this machine behind, and what do I run here?* The answer was only ever in the family's adoption page,
one repo away from the plugin they had just installed.

**Score:** 2

#### Pull Request

Say how to update dkj-policy on every other machine
