## docs/1699-policy-is-adopted-craft-adapts

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

Split the section's one claim in two: the teams adapt to the consumer, `dkj-policy` is adopted **by**
the consumer once chosen.

#### The reason was verified before the repair, and it held with one correction

#1699 says the README's *"not a standard a consumer is expected to adopt"* no longer describes
`dkj-policy`, because installing that plugin is choosing to follow its policy — while the teams still
adapt. Held against the tree, that is right, and the decisive evidence is a **mechanism** rather than a
sentence: [`check-consumer-prose.ps1`](../scripts/lint/check-consumer-prose.ps1) ships in the plugin
and runs as a SessionStart check **in a consumer**, whose supremacy detector reports that repo's own
always-on prose when it declares that *its* `CLAUDE.md` wins. A way of working that detects repos
claiming precedence over it does not yield to them.

**So this is a sharpening, not a decision for the owner.** Both supremacy statements are already in the
tree and already attributed to Dave — `dkj-policy/CONTRIBUTING.md`'s opening line and `CLAUDE.md`'s
restatement of it. Nothing new is being decided; a 2026-08-08 sentence written when one claim could
cover everything that shipped is being split now that it cannot.

### CREATE

- [x] The README section: the opening sentence's last clause becomes *"nothing travels outward
      **unasked** that assumes otherwise"*, followed by the two-bullet split and the paragraph saying
      that **opt-in describes the install, not the obedience**.
- [x] The **navigation table row** at the top of the README, which is where a reader meets that claim
      first and which repeated it verbatim.
- [x] `plugins/dkj-policy/README.md` — the plugin's own front page, which said *"not a baseline every
      consumer inherits and not a standard"* and stopped there. A consumer reading about the plugin
      meets the relation on that page, so the second half belongs there too.
- [x] The heading and its anchor are **left alone deliberately**: three places link to
      `#the-plugin-serves-the-consumers-repo` (`README.md` twice, `plugins/README.md` once), and a
      consumer's own docs may link it where this tree cannot see. The new paragraph says the title is
      half true instead.
- [~] `README.md`'s *"his branch discipline, not a standard"* and `plugins/dkj-policy/README.md`'s
      *"not a baseline every consumer inherits"* — both left as written. Checked, and both are about
      the **install** being a choice, which the repair confirms rather than contradicts.

### TEST

- [x] The lint gate caught a wrong citation immediately, which is the reason this branch has one fewer
      false claim in it: the first draft cited `CONTRIBUTING.md` beside the plugin README, and the
      file there is `CONTRIBUTING-portable.md`. Following the dead link showed the **quote was wrong
      too** — the supremacy sentence is in `dkj-policy/CONTRIBUTING.md` (this repo's own folder), while
      the portable page says the opposite-leaning *"your repo answers this document"* and names a seam.
      Both the link and the claim were rewritten to cite the mechanism instead.
- [x] Swept for the same stale claim across `README.md`, `CLAUDE.md`, `dkj-policy/`,
      `plugins/README.md` and `plugins/dkj-policy/README.md`: five hits, three of them correct as
      written (see the two dropped items above and the craft test question, which is untouched and is
      what the new bullets point at).
- [x] Lint gate: 0 errors, including check 34 — both new relative links in the plugin README resolve
      from that plugin's **own** root as well as in this tree, which is what a consumer gets.
- [x] The lint gate and every suite, via `open-pr.ps1`.

### DEPLOY: docs/1699-policy-is-adopted-craft-adapts

*"The plugin serves the consumer's repo"* is now only half the story, and the README says which half.
A specialist **team** adapts to the repo it lands in — that is a craft, and a craft that overrode its
host would be worth less. **`dkj-policy` runs the other way**: nothing arrives unasked, and enabling it
is choosing to be governed by it, with the consuming repo's own page yielding on conflict. The evidence
that this reaches outward rather than being a local arrangement is a mechanism the plugin ships — a
SessionStart check that reports a consumer's own prose when it claims precedence.

The August 8, 2026 sentence was written when one claim could still cover everything that shipped, and
its last clause now reads *"nothing travels outward **unasked** that assumes otherwise"*. The
craft-versus-way-of-working test question below it is untouched and is what both halves point at; what
#1699 adds is that **opt-in describes the install, not the obedience**.

**Score:** 3

#### What makes this deploy extra special

A consumer reading `dkj-policy`'s own front page now learns what installing it commits them to, in the
place they meet the plugin — that page said *"not a baseline every consumer inherits"* and stopped
there, which is true of the install and easy to read as a promise about the rest. Nothing they run
changes, and no value they set changes: the portable page still names a seam wherever the repo owns the
answer.

**Score:** 2

#### Pull Request

The plugin serves the consumer -- except the policy, which the consumer adopts
