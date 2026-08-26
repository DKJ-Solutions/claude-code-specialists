## Development cycle: `fix/the-guidance-array-parenthesises-its-levels-v1` · 20260826-150215

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
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### Where this branch stands

Repairing the four unparenthesised concatenations in `StepsGuidance`, mirroring the fix into the plugin copy,
and adding the asserts that would have caught it. Filed as
[#915](https://github.com/DaveKJohn/claude-code-specialists/issues/915) by Dave.

#### The report, verified before it was routed

All five checks stand. **Symptom:** reproduced by creating this very branch -- the scaffolded document carried
a bare `###` on line 8 and a bare `####` on line 11, and `check-branch-entry.ps1` reported them as branch
content in the generic region. **Reason:** verified in the parser, not accepted from the report -- `,` binds
tighter than `+`, so `'a' + $H + 'b'` inside an array literal is array concatenation of its neighbours.
**Repair:** every mechanism the report names exists -- the four sites are at `entry-scaffold-lib.ps1:4321`,
`4322`, `4325`, `4327`, and the mirror at
`plugins/workflows/contributing-davekjohn/scripts/lib/entry-scaffold-lib.ps1` was byte-identical (347,235 B).
**Subject:** `StepsGuidance` and both files exist. **Size:** the report said 38 elements against "~34"; the
measured intent is **30** -- four sites at +2 each -- and the array really did hold 38 with four bare markers.
The count in the code comment is the measured one.

#### And the class is exactly four sites, not more

Scanned `scripts/**` for the same shape -- a single-quoted literal concatenated with a `$`-variable on a line
ending in `',` inside an array literal. Four hits, all of them the four the report names. So the repair is
scoped to the subject rather than to a proxy, and there is no wider sweep hiding behind it.

### CREATE

- [x] Parenthesise the four concatenations in `scripts/lib/entry-scaffold-lib.ps1` (4321, 4322, 4325, 4327).
- [x] Apply the identical edit to the plugin mirror and confirm the two files stay byte-identical.
- [x] Record why the parentheses are load-bearing, in the comment block that already explains why the lines
      are concatenated rather than interpolated -- otherwise the next reader tidies them away.
- [x] Add the guard to `scripts/tests/entry-scaffold.tests.ps1`: every `StepsGuidance` element opens the
      blockquote, and the composed level reaches the rendered document inline.
- [x] Add scenario 8 to `scripts/tests/branch-entry-gate.tests.ps1`: the gate is fed the preamble the
      scaffolder actually writes, which is the one shape none of the seven scenarios before it ever used.
- [x] Regenerate this branch's own document with the repaired generator.

### TEST

- [x] The array measures **30 elements, 0 bare markers** after the repair (38 and 4 before it).
- [x] `entry-scaffold.tests.ps1`: 495 asserts pass.
- [x] `branch-entry-gate.tests.ps1`: 27 asserts pass.
- [x] **The asserts were proved red before they were trusted.** One site was reverted in the working copy
      and all three new asserts failed -- naming the two stray elements in the output -- then the file was
      restored and they went green. A guard that has never been seen to fail is not a guard.
- [x] `check-branch-entry.ps1` accepts this document's own preamble, which is the end-to-end proof.
- [x] The full gate: `check-plugin-integrity.ps1` plus every suite, via `open-pr.ps1`.

### DEPLOY: `fix/the-guidance-array-parenthesises-its-levels-v1`

`new-branch.ps1` writes a usable `development-cycle.md` again. Four lines of `$script:BranchFileDefaults.StepsGuidance`
composed their heading levels as `'opening text' + $script:BranchCyclePhaseHashes + 'closing text'` inside a
comma-separated array literal -- and in PowerShell `,` binds tighter than `+`, so that is not string
concatenation at all. It parses as *array* concatenation of the neighbouring elements --
`('previous', 'opening text') + '###' + ('closing text', 'next')` -- turning one element into three. The array held **38
elements where 30 are written**, four of them a naked `###` or `####` alone on a line. `check-branch-entry.ps1`
read those four as branch-specific content in the region that must be generic and exited 1 -- so the
scaffolder wrote a document the gate refuses, and `open-pr.ps1` would not push it. That blocked **every**
branch, here and in every consumer taking the workflow plugin; the branch that hit it first was unblocked by
repairing its own document by hand, which left the generator untouched. Introduced by
[#911](https://github.com/DaveKJohn/claude-code-specialists/pull/911), reported as
[#915](https://github.com/DaveKJohn/claude-code-specialists/issues/915), and reproduced here by creating this
branch before touching anything.

**The repair is four pairs of parentheses, and the comment beside them is the durable half.** `+` is settled
before `,` ever sees it. The same edit lands in the byte-identical plugin mirror
`plugins/workflows/contributing-davekjohn/scripts/lib/entry-scaffold-lib.ps1`, because that is the copy a
consumer actually runs. What the note above the lines now records is that the parentheses are load-bearing --
without it they read as redundant grouping, and the next editor tidying them away reproduces the defect
exactly.

**Why it shipped green is the part worth keeping.** The composition fails into *well-formed* output: a
document that renders, with four markers merely orphaned onto lines of their own. Nothing read the array
back. Two guards now do. `entry-scaffold.tests.ps1` asserts that every element of the block opens the
blockquote -- a **shape**, deliberately not a count, because a pinned count goes red on every legitimate
wording edit and gets raised rather than read. And `branch-entry-gate.tests.ps1` gains scenario 8, which feeds
the gate the preamble `Format-DevelopmentCycle` actually produces. That is the real gap: the suite's own
header states that entry states come from the real formatters and never from a literal, and the seven shape
scenarios were the documented exception -- they spell their head out by hand, for a stated reason. That
exemption is why a generator writing a broken preamble passed a suite whose whole subject is that preamble.
Both guards were confirmed to fail against the defect before being trusted.

**Score:** 4

#### What makes this deploy extra special

`entry-scaffold-lib.ps1` is plugin payload: the `contributing-davekjohn` workflow ships it, so a consumer that
takes this plugin gets a scaffolder writing a document its own CI gate refuses -- every new branch, with no
way past it, since neither `open-pr.ps1` nor the gate has a `-Force`. The failure arrives at branch creation,
before any work is done, and the visible symptom is a document that looks fine. Nothing needs migrating: the
next branch after the update is written correctly, and a document already repaired by hand stays valid.

**Score:** 4

#### Pull Request

the scaffolded cycle document composes its heading levels without splitting the guidance array
