## Development: `docs/a-notification-names-where-it-came-from-v1` · 20260828-152346

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

#### What issue #1029 turned out to be

*"ntfy updates does not tell which repo it comes from"* — filed with an empty body, so the title is the
whole report. Verified against the tree before routing: `ntfy` appears nowhere in the working tree and
nowhere in the history (`git log -S"ntfy"` across all refs is empty), no hook this repo ships sends a push,
and the machine-wide tree here holds no hooks at all. Dave confirmed the sender lives in `~/.claude` on
another machine.

So the sender is repaired where it lives, and **what belongs here is the portable lesson** — the
source-is-the-default rule: craft that every consumer meets goes in the plugin manual, not in a lens. One
bullet, in Sylvester's hard rules, beside the two that already govern getting a hook's message delivered.

### CREATE

- [x] Add the bullet to `plugins/teams/team-alpha/manuals/05-15-manual.md`, directly after *"The exit code
      says the hook RAN; only the receiver says it ARRIVED"* — the next question at the same receiving end.

### TEST

- [x] Confirmed the manual has no mirror (`find -name 05-15-manual.md` returns one path) and the lens
      `.claude/specialists/lenses/05-15-extension.md` says nothing about notifications, so there is no
      second copy to drift and no repo-specific half to split off.
- [x] Lint + test gates via `open-pr.ps1`.

### DEPLOY: `docs/a-notification-names-where-it-came-from-v1`

Sylvester's hook craft gains the rule that closes the gap between a notification that *arrives* and one
that can be *acted on*: the payload names where it came from. A phone shows one stream — every machine
somebody runs, every repo checked out on each, every session inside those — and none of that context rides
along, because a push has no working directory, no branch and no terminal title. So the same sentence sent
by four sessions is four identical messages, and the only way to learn which one is waiting is to walk to
each machine.

It sits directly after *"the exit code says the hook RAN; only the receiver says it ARRIVED"*, because it
is the next question at that same receiving end: the bullet above establishes there is a channel, this one
that what lands on it is attributable. The sender itself stays personal and stays in `~/.claude`, exactly
as the bullet below it already says — which is why the lesson had to be written here rather than fixed
there. It is not one machine's misconfiguration; it is what every consumer meets the moment a second repo
starts sending into the same topic.

**Score:** 2

#### What makes this deploy extra special

Nothing reaches a service subscriber here — this is a manual bullet for whoever wires a hook to a phone.

**Score:** N/A

#### Pull Request

A notification names the repo and machine it came from
