## Development: `docs/sandra-manual-content-rule-v1` · 20260901-180610

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

Issue #1197 verified against the tree: manual line 69 (the one-sentence rule) and lines 114-116 (the floor's consequence) are the two stale statements. The sweep the issue left undone is done -- 'exclusion rule' is still current terminology, and the other two time-window mentions in the tree name it as retired, correctly.

#### What was filed rather than folded in

`Get-SyncReferencePoint`'s docstring in `scripts/lib/sync-rules.ps1` (and its byte-identical plugin
mirror) carries the **same** retired consequence, one layer down. Filed as
[#1199](https://github.com/DaveKJohn/claude-code-specialists/issues/1199) rather than repaired here: a
script docstring in two mirrored copies under the shared-scripts drift lint is Sylvester's, not a
`docs/` branch on a portable manual.

### CREATE

- [x] Replace the one-sentence rule at the head of *The pre-task sync* with the content rule, worded to
      agree with `skills/sync-main/SKILL.md` and the `THE RULE THAT REPLACED IT` comment in
      `scripts/lib/sync-rules.ps1`.
- [x] Re-state the three destruction modes accurately under the new rule. Two are answered by content;
      the third (a path only the trunk has) the sentence never asks about, because `Get-SyncFileVerdict`
      returns `keep-trunk` for `D` unconditionally — so claiming all three are "the same case" was the
      framing's own half of the staleness.
- [x] Name the retired sentence as retired, with why it was the wrong measurement and where the numbers
      are, so a reader who remembers it is corrected rather than left to notice a silent swap.
- [x] Repair the floor's consequence: the floor is demoted, so a missing one costs a silently-taken
      conflict, not wholesale overwriting.
- [x] Finish the sweep the issue explicitly left undone — every other statement in the manual that could
      assume the time window.

### TEST

- [x] `check-plugin-integrity.ps1`: 0 errors (34 checks, 27 manuals, 319 links).
- [~] Dropped: running the suites here duplicates `open-pr.ps1`'s own gate, which runs them before the
      push. A copy set going ahead of it proves nothing that gate would not catch and records nothing it
      credits. No script changed on this branch in any case.
- [x] The sweep, as a measurement rather than a read-through: the old sentence now appears **twice** in
      the tree's markdown, at `05-21-manual.md:83` and `SKILL.md:90`, and both name it as replaced. The
      two `.ps1` mentions (`sync-rules.ps1:197`, `sync-main.ps1:20`) were checked and already did.
- [x] `exclusion rule` is still live terminology, not stale wording riding along — `sync-rules.ps1` uses
      it at lines 99, 113, 192, 236 and 658, and `SKILL.md` at 143. Left alone deliberately.
- [x] No mirror of this manual exists to keep in step (`find . -name "05-21*"` → the manual and the agent
      def; the agent def carries none of the rule).

### DEPLOY: `docs/sandra-manual-content-rule-v1`

Sandra's manual now teaches the sync rule the script actually runs. It is the page that exists to explain
*why the obvious implementation destroys work*, and it handed the reader a one-sentence rule to reason
with — the **time-window** sentence that inbound #807 retired on August 21, 2026, when content
provenance replaced it in the skill and the lib and this manual was never repointed. Both halves of that
staleness are repaired: the rule itself, and the floor's job one paragraph down, where a missing floor
was said to pass everything through and in fact now costs a silently-taken conflict. The three
destruction modes are re-stated honestly under the new rule rather than reprinted, because only two of
them are content questions and the third is unconditional. The retired sentence is kept on the page,
named as retired and with the disagreement stated — the two rules part company exactly where it costs
most, on a path live holds an older copy of, and that is the case #807 was filed about.

**Score:** 2

#### What makes this deploy extra special

A consumer running `team-shopify` reads this manual to decide whether a sync verdict looks right, and
until now it would have taught them to predict the wrong ones — most sharply on the path where the two
rules disagree and the retired one reverts merged work. The script's behaviour never changed and needed
no change; what changed is that the page a human reasons from now matches it.

**Score:** 3

#### Pull Request

Sandra's manual teaches the content rule, not the time window it replaced

