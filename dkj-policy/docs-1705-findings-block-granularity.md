## docs/1705-findings-block-granularity

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

Measure all eight bullets against the 31 carriers; split only if a bullet is genuinely narrow, and
install a bar for future additions.

#### The answer is a decline, and the bar is what the measurement was worth

#1705 asked whether every bullet of `findings-become-issues` is one every carrier needs. Measured per
bullet: **seven of eight are universal on their face**, and the eighth — read the issue that produced a
**guardrail** before proposing to change it — reads narrow and generalises to *"read why a thing exists
before proposing to change it"*, which no carrier is exempt from. So the split is declined: a block
whose every bullet answers one question (*how do I file what I found*) is coherent, and splitting it to
save one bullet's bytes trades a real cost for a real seam.

**What the measurement did turn up is a cost fact the lens's tier model does not carry**, and that is
the deliverable instead.

### CREATE

- [x] Ravi's lens gains the asymmetry: of the block's 30 carriers exactly **one** is on the always-on
      path — Chris's persona body — while the other 29 are paid per invocation, because the agent defs
      carry these blocks in the **body** rather than in the frontmatter `description` that Claude Code
      loads for every enabled plugin. The word *universal* makes that sound cheaper than it is.
- [x] And the bar it implies, stated as a test rather than a principle: **would you put this bullet in
      Chris's body on its own?** If no, it belongs in a narrower block — the generator already supports
      several independently-named regions per file, so a new circle costs a name and a source file.
- [x] The reason there is no cheap middle, which was checked rather than assumed:
      `Get-SharedBlockText` reads the source file **whole**, so a source cannot carry a header that
      stays behind. Anything written into `agent-shared/<name>.md` travels to all 30 carriers — which
      is why this bar lives in Ravi's lens (on-demand, repo-local) and not in the block it governs.
- [~] Splitting the guardrail-intent bullet into its own region — dropped, per the measurement above.
- [~] Touching the block itself — dropped for the same reason, and because any edit there would have
      cost the always-on path the very bytes this issue was about.

### TEST

- [x] Both load-path claims verified against the tree rather than carried over from the cost pass that
      raised them: `.claude/specialists/SPECIALISTS.md` holds exactly **two** `@` imports (Chris's
      persona body and his lens), and in `05-15-agent.md` the block's `BEGIN` sentinel is at line 117
      while the frontmatter ends at line 13 — so the block is body, not `description`.
- [x] The carrier count read off the tree at the time of writing (30 defs and personas plus the
      source), and **not written into the lens as a per-block number** — that file's own rule is that
      per-block counts drift with every new agent def and are exactly the staleness it exists to
      catch. The 30 appears only in the sentence about which single one is always-on.
- [x] The lint gate and every suite, via `open-pr.ps1`.

### DEPLOY: docs/1705-findings-block-granularity

Ravi's lens now records that a **universal shared block does not cost uniformly**. Of
`findings-become-issues`'s thirty carriers exactly one sits on the always-on path — Chris's persona
body, imported on every turn — while the other twenty-nine are paid per invocation, since the agent
defs carry these blocks in the body rather than in the frontmatter description. A bullet appended to a
universal block is therefore paid once per session in every consuming repo, and the word *universal*
hides that.

So the lens carries the test that follows from it: **would you put this bullet in Chris's body on its
own?** If not, it belongs in a narrower circle, which the generator already supports. And there is no
cheap middle — the source file is copied whole, so nothing written into it stays behind.

**The question #1705 actually asked was answered by measuring and declining.** Seven of the eight
bullets are universal on their face; the eighth reads narrow and generalises. The block stays as it is.

**Score:** 2

#### What makes this deploy extra special

N/A — a repo-local lens, read on demand, and nothing in any plugin changed. A consumer receives no
byte of this.

**Score:** N/A

#### Pull Request

What earns a place in the findings block, measured per bullet
