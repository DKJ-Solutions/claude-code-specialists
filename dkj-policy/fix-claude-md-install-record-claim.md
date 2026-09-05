## fix/claude-md-install-record-claim

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

Inbound [#1449](https://github.com/DaveKJohn/claude-code-specialists/issues/1449) reported that
`CLAUDE.md:177` claims *"this repo carries an install record keyed on its folder path"* while the
reporter's machine held none, at any scope, for `team-alpha` or `dkj-policy`.

#### What was measured here (2026-09-05)

Verified against this machine (`DaveKJohn` identity) rather than taken on trust:
`~/.claude/plugins/installed_plugins.json` carries a **live** project-scoped record for
`team-alpha@claude-code-specialists`, keyed to this exact checkout's path, `installedAt: 2026-08-31`,
still current. `claude plugin list` confirms it. So "none, at any scope" does not hold here.

The precedent #1449 cites (#1371, "closed exactly this contradiction for README.md and INSTALL.md")
doesn't establish what it's cited for either: that branch's own dossier
(`fix/readme-keys-install-claim.md`) found the opposite on pickup — a live record, dated three days
before that report was filed — and its actual fix was unrelated to record-presence (a stale absolute
about session-start behaviour).

`installed_plugins.json` lives under each machine's own home directory, outside the repo, so its
content is a fact about the **(repo, machine)** pair, not the repo alone. Both snapshots — no record on
the reporter's machine, a live record on this one — can be true at once. #1449 closed with this
evidence rather than routed as filed.

#### The real, narrower defect

`CLAUDE.md:177` states record-presence as a fixed property of the repo in present tense. The mechanism
is real (measured August 3, 2026, in the neighbouring system-administration lens) but conditional: a
record exists on a machine only once `claude plugin install ... --scope project` has run there. The fix
is to reword the claim as conditional on per-machine install state, not to replace one absolute with the
opposite one.

### CREATE

- [x] Reword `CLAUDE.md`'s self-consumption paragraph: install-record presence is per-machine state
      (present once `--scope project` install has run there), not a fixed repo fact
- [x] Cite inbound #1449 in the reworded sentence
- [x] Leave the neighbouring clone-refresh-lag sentence in the same paragraph untouched — a separate,
      still-accurate claim
- [x] Post verification findings on #1449 and close it, rather than let a refuted premise sit open

### TEST

- [x] `check-plugin-integrity.ps1` — reviewed the touched paragraph for dead links (the new `#1449`
      link resolves) and the ~100-char wrap the page already uses
- [~] A new or changed automated test — dropped: the change is prose in `CLAUDE.md`, and no suite
      asserts on that text; the lint's link/wrap checks are the coverage it has, same as #1371's fix

### DEPLOY: fix/claude-md-install-record-claim

`CLAUDE.md` no longer states that this repo carries an install record as a settled fact. Inbound #1449
measured the opposite on one machine and cited a precedent (#1371) that, on inspection, measured the
opposite of what it was cited for too — the record's presence is real but per-machine, and the paragraph
now says so, rather than asserting either "always present" or "always absent".

**Score:** 1

#### What makes this deploy extra special

N/A — internal documentation accuracy, no subscriber of the service is affected.

**Score:** N/A

#### Pull Request

CLAUDE.md states an install record's presence as a fixed repo fact, not a per-machine one

