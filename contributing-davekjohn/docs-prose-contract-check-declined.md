## docs/prose-contract-check-declined

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

Inbound #1379 asked for three things; items 1 and 2 landed in PR #1381 and item 3 — a prose equivalent
of `check-script-contract.ps1` — was deferred to #1380 as needing its own design pass. That pass was a
measurement. It came back negative, was red-teamed, re-run with the source-repo guard applied, and came
back negative more clearly. Dave chose to record the decline rather than ship a weakened check.

### CREATE

- [x] Record the measured decline in `.claude/specialists/lenses/05-15-extension.md`, in the shape of the
      stale-path entry beside it — the corrected corpus, the four candidates, the structural reason, the
      11-law manifest preserved for a later revisit, and a closing "do not revive it behind a nearby-text
      rule"
- [x] Repair `CONTRIBUTING-portable.md`'s dangling sentence, which promised the check as "left as a
      follow-up" — it now states that it was measured and declined, and why, without shipping the numbers
      to consumers
- [x] Re-run the measurement after the red-team: subtract the corpus contamination the first pass named
      but never applied, split the suppressed sections properly, and measure the manually-run audit mode
      that #1380 explicitly asked about and the first pass never tested
- [~] Build the manifest + the check itself — dropped, and the drop IS the deliverable. The manifest is
      preserved in the lens entry; the check is not built, and the numbers saying why are there too

### TEST

- [x] Every figure in the lens entry and in this entry comes from the source-guarded re-run; the four
      claims the re-run retracted appear nowhere
- [x] Both new issue links resolve, and the portable page carries no relative link into
      `.claude/specialists/lenses/`, which is not shipped with the plugin

### DEPLOY: docs/prose-contract-check-declined

A manifest-driven prose contract check — the analogue of `check-script-contract.ps1` for the laws this
plugin legislates rather than the functions it calls — was measured against 11 laws over 8 consumer
documents in the two consuming repos, and declined in every deployment mode: as a gate, as a session-start
line, and as the deliberately-run advisory audit #1380 asked about. A verbatim cue fired once. Term
co-occurrence reached 12.5% precision, adding a normative marker 13%, and a declaration-based check
reported 88 of 88 laws undeclared because no consumer has the convention it looks for.

Two measurements carry the decline. **The law the check was written to catch has no standing violation
left:** `LAW-RELEASE-ORDER` was the acceptance test because #1378 had just made it the one known-real
defect, and #1378's repair then made the consumer's order a sanctioned answer rather than a divergence —
so the check's reason for existing was repaired out from under it mid-measurement. **And the detector
found one of the three defects that actually stand in the corpus:** one instance was flagged, one was
missed because the term list wanted a word that section does not use, and one was suppressed by the very
pointer test meant to prevent false alarms. That last case is the structural reason, measured: a section
that restates a law may also cite it, and a pointer test cannot tell correct deference from
restatement-with-citation-and-override — 1 of the 4 suppressed sections in the corpus was hiding a real
contradiction.

The 11-law manifest is kept in the lens entry rather than discarded with the check, so a later revisit
does not re-derive it. So is the proportionate alternative: two narrow literal greps, each aimed at one
law, rather than one framework carrying eleven at 12% precision.

**Score:** 3

#### What makes this deploy extra special

`CONTRIBUTING-portable.md` stops promising an enforcement mechanism that has come back negative. A
consumer reading the layering section now learns that the prose half of the corollary is unenforced by
design, and why in one sentence — so they can stop waiting for a gate that is not coming and lean on the
ranking itself, which is what #1379 said makes a divergence nameable. Small: it changes one paragraph of
a page they already have, and nothing they run.

**Score:** 2

#### Pull Request

The prose contract check is measured and declined rather than left open
