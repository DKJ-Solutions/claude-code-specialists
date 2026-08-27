## Development cycle: `docs/an-inconsistency-is-a-kind-of-finding-v1` · 20260827-182922

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

Issue #981: Dave's rule -- an inconsistency is ALWAYS filed as an issue. The filing rule is stated in terms of findings, and an inconsistency does not read as a finding while you are the one who created it. Add one bullet beside the existing ones, plus the sentence that closes the gap: scoping a contradiction out of the work is a reason not to edit the file, never a reason not to file it.

### CREATE

- [x] Find the lever before writing. Issue #981 says the rule goes in Chris's persona body, and the
      block it names is marked `GENERATED, do not edit here`. The editable source is
      `plugins/teams/agent-shared/findings-become-issues.md`; the persona is one of its outputs.
- [x] Write one bullet beside the existing ones, in the shape the issue asks for: an inconsistency named
      as a kind of finding, the sentence that closes the gap, and both wording points it flags -- that an
      inconsistency your own change created is filed anyway and says so, and that *always filed* is not
      *always a new issue*.
- [x] Regenerate the carriers with `build-agent-defs.ps1`: 30 files updated across all four team plugins.
- [x] Measure what the addition costs on the always-on path rather than assuming it is free -- see TEST.

### TEST

- [x] The reach is wider than the issue describes, and it is the right reach. The block is carried by 30
      files: 15 agent defs and 4 personas in `team-alpha`, plus 3 in `team-ecomm`, 5 in `team-lifehub`
      and 3 in `team-shopify`. A filing rule is every specialist's, so the shared source is both the only
      editable lever and the correct one.
- [x] Always-on cost, measured with `measure-always-on.ps1` and `wc -c` rather than estimated: Chris's
      persona goes from 24,316 B to 25,822 B, so **+1,506 B, about 482 tokens per session** once the
      marketplace clone catches up. The other 29 carriers are agent defs and non-Chris personas, which
      load on demand and cost a session nothing until they are read.
- [x] Encoding checked on a generated carrier after the build: the em dashes in the new bullet survive
      round-trip, so `fix-mojibake` has nothing to do here.
- [x] The full gate (`check-plugin-integrity.ps1` + all suites) via `open-pr` -- the agent-def frontmatter
      and the shared-block drift check are part of it, so a carrier left unregenerated would fail there.

### DEPLOY: `docs/an-inconsistency-is-a-kind-of-finding-v1`

The filing rule now names an **inconsistency** as a kind of finding, and says it is always filed. The
rule was already stated in terms of findings -- a bug, a stale doc, a decision that is not yours -- and
that list did not catch the case Dave was reacting to: two statements in the tree that cannot both be
true, noticed by the session that created the second one. The measured instance is PR #980, where the
branch retired the source's root `CONTRIBUTING.md` and left the portable page prescribing a two-page
arrangement the source no longer runs. The session saw it, reasoned about it correctly, decided
(rightly) that changing it was not this branch's call -- and then handed it to Dave as prose in the
close-out, which is the one thing the filing rule exists to prevent. The bullet supplies the missing
third half: **scoping a contradiction out of the work is a reason not to edit the file; it is never a
reason not to file it.**

**Score:** 3

#### What makes this deploy extra special

**It is written where it can actually be edited, which is not where the issue pointed.** #981 asks for
the bullet in Chris's persona body. That block is generated and carries a `do not edit here` marker; the
source is `plugins/teams/agent-shared/findings-become-issues.md`, and the build fans it out to **30**
carriers -- 19 in `team-alpha`, and 11 more across `team-ecomm`, `team-lifehub` and `team-shopify`. The
wider reach is correct rather than incidental: a filing rule belongs to every specialist who can find
something, not to the orchestrator alone.

**The cost is measured and stated, because this one is paid every session.** Chris's persona is on the
always-on path, so the bullet is **+1,506 B, roughly 482 tokens per session** -- the other 29 carriers
load on demand and cost nothing until read. Worth it for a rule whose failure mode is a contradiction
leaving the session as something the owner has to answer, but the number belongs in the record rather
than in somebody's estimate later.

**Score:** 3

#### Pull Request

the filing rule names an inconsistency as a kind of finding

Plugins: team-alpha, team-ecomm, team-lifehub, team-shopify