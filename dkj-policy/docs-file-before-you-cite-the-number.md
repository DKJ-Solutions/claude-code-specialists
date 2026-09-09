## docs/file-before-you-cite-the-number

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Add the file-first rule to the `findings-become-issues` shared block and regenerate the defs.

#### Where the lesson came from

Two branches shipped today wrote an issue number into a file **before** the issue existed, predicting
it, and both were wrong because another worker filed in between. `git-porcelain-lib.ps1`'s header
cited `#1688` for the follow-up that turned out to be **#1689** — a pull request had taken the number,
since issues and PRs share one counter — and `fix-1682-porcelain-line-parse.md` cited `#1690` for what
turned out to be **#1693**. Both had to be corrected after the fact, in the source file, its plugin
mirror and once in an issue body.

The repo's own rule is that a lesson is secured in the docs rather than in a memory note, and the layer
that owns it is the **shared source**: the filing rules live in
`plugins/dkj-teams/agent-shared/findings-become-issues.md`, one source copied verbatim into every def
that carries it, so the rule travels to every consuming repo instead of stopping at this one.

### CREATE

- [x] One bullet in the shared block, placed among the filing *mechanics* — after **"The bar"** and
      before **"Filing needs no permission"** — because that is what it is: how to file, not whether.
- [x] `scripts/agents/build-agent-defs.ps1` run, propagating it verbatim into 30 more files (31 total).
      No hand edit to any generated def.
- [x] Verified the bullet's own measurement against the history before it shipped, rather than
      asserting it: both corrections are in the log, in the two branches named.

### TEST

- [x] Cost pass (Nolan) on the always-on half, which is the only real question a six-line doc change
      raises. His model, verified against the tree rather than taken from the prompt: of the 31 touched
      files exactly **one** rides the always-on path — Chris's persona body, which `CLAUDE.md` imports
      through `SPECIALISTS.md` every turn. The other three personas are on-demand, and the 26 agent
      defs carry it in the **body** rather than the frontmatter `description`, so they are paid per
      invocation.
- [x] Acted on his trim: the bullet came down from **587 to 441 bytes** (-25%), and the always-on
      floor grows by that 441 (~110 tokens) on a measured 101,877-byte (~25,470-token) path — **+0.43%**.
      His shortest version was 381 bytes; the extra 60 keep *"in two branches"*, which is the half of
      the measurement that says it was not one slip twice.
- [~] His cheaper placement — a narrower shared region imported only by the specialists who write
      citations, which would take the always-on cost to **zero** — dropped here and filed as
      [#1705](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1705). It is a change to
      the shared-block architecture (Ravi's), not to this rule, and **its correctness argument does not
      hold as given**: it rests on Chris never writing a lib header or a commit message himself, while
      his own body covers the no-subagents case where he does exactly that — which is the session both
      of today's corrections happened in. The cost figures stand; the granularity question needs
      measuring per bullet, which is what the issue asks for.
- [x] The lint gate and every suite, via `open-pr.ps1` — check 7 holds each generated region against
      its source, so a hand edit to any of the 30 would turn it red.

### DEPLOY: docs/file-before-you-cite-the-number

The filing rules now say that an issue's number does not exist until the issue does: file first, read
the number back, then write it into the header, the step list or the commit message. Issues and pull
requests share one counter, so a predicted number is taken by whichever of the two lands first —
measured twice in one session, in two branches, both times as a citation that had to be corrected after
it was already written.

It goes in the shared `findings-become-issues` block rather than in a lens, so it reaches every
consuming repo through the same release as the rules it sits beside. Thirty-one files carry it; one of
them is on the always-on path, and the bullet was trimmed 25% on a cost measurement before it landed.

**Score:** 2

#### What makes this deploy extra special

N/A — a consumer receives one more bullet in a boundaries block they already carry, worth ~110 tokens
on the one always-on body. It changes no behaviour they can observe and no command they run.

**Score:** N/A

#### Pull Request

A finding's issue number does not exist until the issue does
