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

Inbound #1379 asked for three things; its items 1 and 2 landed in PR #1381 and item 3 — a prose
equivalent of `check-script-contract.ps1` — was deferred here as needing its own design pass. That pass
was a measurement, and it came back negative: all four candidate detectors measure like the stale-path
check this repo already declined. Dave chose to record the decline rather than ship a weakened version.

### CREATE

- [x] Record the measured decline in `.claude/specialists/lenses/05-15-extension.md`, in the shape of the
      stale-path entry beside it — corpus, the four candidates' counts, the structural reason, and a
      closing "do not revive it behind a nearby-text rule"
- [x] Repair `CONTRIBUTING-portable.md`'s dangling sentence, which promised the check as "left as a
      follow-up" — it now states that it was measured and declined, and why, without shipping the numbers
      to consumers
- [~] Build the manifest + the check itself — dropped, and the drop IS the deliverable: measured over 11
      laws and 13 documents in 3 real repos, no candidate is shippable (the numbers are in the lens entry)

### TEST

- [x] Both new issue links resolve, and the portable page carries no relative link into
      `.claude/specialists/lenses/`, which is not shipped with the plugin

### DEPLOY: docs/prose-contract-check-declined

A manifest-driven prose contract check — the analogue of `check-script-contract.ps1` for the laws this
plugin legislates rather than the functions it calls — was measured against 11 laws over 13 documents in
three real repos, and declined. Four candidate detectors were measured: a verbatim cue (1 finding), term
co-occurrence (27 findings, ~17 false in English), the same with a normative marker (19 findings, ~11
false), and a declaration-based check (110 findings, 100% undeclared and so born red on day one).

The reason it is declined is structural rather than a matter of tuning: **a section that restates a law
almost always also names the mechanism it is talking about**, so a pointer test cannot tell correct
deference from restatement-with-citation-and-override. The cleanest real divergence in the corpus is
suppressed by every candidate for exactly that reason — a consumer names `CONTRIBUTING-portable.md` as a
pointer into the plugin and overrides it four lines later. That is the same failure shape as the
stale-path check declined on August 9, 2026, where the difference was whose repo the line was about.

`CONTRIBUTING-portable.md` stops promising the check as a follow-up and states the outcome instead. The
measurement, both caveats and the by-products are in the system-administration lens, beside the other
declines, so the rule is not revived blind.

**Score:** 3

#### What makes this deploy extra special

A consumer reading the layering section no longer meets a promise of enforcement that has come back
negative. The paragraph now says the prose half of the corollary is unenforced by design, and names the
reason in one sentence, so a consumer can stop waiting for a gate that is not coming and rely on the
ranking itself — which is what #1379 said was the part that closes the gap. Small: it changes one
paragraph of a page they already have, and nothing they run.

**Score:** 2

#### Pull Request

The prose contract check is measured and declined rather than left open
