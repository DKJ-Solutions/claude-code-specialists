## fix/1424-superseded-entry-note

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

#### What #1424 reports, and what was verified before anything was written

Three entries sit under `## [Unreleased]` in `CHANGELOG.md` and will ship in the same release. Two of
them say `new-branch.ps1` only warns on a stale base; the third is the branch that made it refuse. Read
as history all three are accurate. Read as a release note -- which is what `cut-release.ps1` builds out
of this block -- the release tells a consumer both things, and offers no way to tell which sentence
describes the version they installed.

Verified against the tree on September 5, 2026 rather than taken from the report: all three entries are
still pending, no release has been cut against the block, and both warn-statements read exactly as the
issue quotes them.

#### The shape chosen, of the three the issue lists

Shape 2 -- **the superseding entry names what it overtakes** -- and written as a convention rather than
one edit, which is the part the issue asked to have settled.

It is the same principle `RELEASES-portable.md` already states one stage later for published notes: a
line that was **true when written** goes stale and is left untouched, and the correction travels with the
newer document. The superseded entries were true on their own day, and an entry is the only durable
record of why a branch held back -- so rewriting them destroys history to repair a rendering. Shape 1
leaves the contradiction in the release note; shape 3 needs the fold to learn a concept it does not have,
for a shape measured once.

The convention goes in the **portable** layer: every consumer's changelog has this shape, this repo is
the source, and the lens is for what a consumer would have to differ on -- here nothing differs.

### CREATE

- [x] `CHANGELOG.md`: one paragraph inside the `fix/1417-new-branch-refuse-stale-base` entry naming the
      two pending entries it overtakes, and saying which sentence is the current one
- [x] `DEVELOPMENT-portable.md`: state the convention under the DEPLOY section, citing the
      published-record rule it derives from
- [x] Leave both superseded entries byte-identical -- that is the decision, not an omission

### TEST

- [x] Lint + tests green via `open-pr.ps1`

### DEPLOY: fix/1424-superseded-entry-note

The release note stops contradicting itself. Three entries pending in one `## [Unreleased]` block will
ship together, and two of them tell the reader that `new-branch.ps1` warns on a stale base while the third
is the branch that made it refuse. The `fix/1417-new-branch-refuse-stale-base` entry now names the two it
overtakes, quotes the claim it supersedes, and says which sentence describes the version you installed.

**The two superseded entries are byte-identical, and that is the decision rather than an omission.** They
were true on the day each branch merged, and an entry is the only durable record of *why* a branch held
back -- #1416 declined to settle the warn-versus-refuse asymmetry and filed #1417 for it, which is exactly
the reasoning the next reader needs. Amending them would write a decision into history that was never
taken there. This is the published-record rule stated one stage earlier: a line true when written goes
stale rather than false, and the correction travels with the newer document.

So the general half ships too, in `DEVELOPMENT-portable.md` beside the rest of the DEPLOY form -- because
the shape recurs by construction. A question filed out of one branch and answered in another lands in the
same block whenever both merge between two cuts, the changelog has no notion of one entry superseding
another, and nothing detects it. The rule is a habit at the moment DEPLOY is written, not a gate: before
writing that a behaviour changed, grep `[Unreleased]` for what it used to be. A gate would have to read
prose for contradiction, which this repo declined at 12.5% precision.

Reason: the contradiction is invisible to every gate the block passes through, and it only becomes
legible at the cut -- when the note is generated and nobody is reading the three entries side by side any
more.

**Score:** 2

#### What makes this deploy extra special

A consumer reads the generated release note and nothing else; this repo's own maintainers can always fall
back to the issue numbers. So the entry that gets repaired here is the one that reaches them, and the
convention that keeps it repaired arrives at their next plugin update as one more paragraph in the DEPLOY
form -- the page an author of theirs is already reading when the mistake is available to make.

**Score:** 2

#### Pull Request

The superseding changelog entry names the pending entries it overtakes
