## fix/1665-working-copy-boundary

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
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

#1665: a dispatched review ran `git stash` and then `git checkout HEAD -- <file>` to settle the
conflict it caused, discarding four uncommitted edits belonging to the orchestrating session. The
boundary in the agent def forbids only *correcting* and *landing*, and a stash does neither -- so the
reviewer was reasoning correctly against the rule as written.

**The report's size was wrong in both directions, verified against the tree before anything was
written.** It names five reviewers holding `Bash`; Marlowe #29 holds
`Read, Grep, Glob, WebSearch, WebFetch, Skill` and no `Bash`, so four reviewers can do this. And the
hazard is not a review's: **11** agent defs hold `Bash`, **seven** of them writing specialists whose
`git stash` discards exactly the same files. So the circle is the capability, not the craft.

The worktree half of the report -- dispatching a review into `isolation: "worktree"` -- is a separate
decision with a real correctness cost (a worktree has no uncommitted work to review) and is filed as
[#1667](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1667) rather than taken here.

### CREATE

- [x] `plugins/dkj-teams/agent-shared/working-copy-boundary.md` -- the canonical block: the tree is not
      yours to move, the read-only route for reading another ref, and that a clean `git status` is what
      the damage looks like rather than evidence of innocence.
- [x] Sentinel pair added to the 11 agent defs holding `Bash` -- after `no-commit-push-pr` in the eight
      alpha ones, after `storefront-preview-boundary` in the three ecomm ones (they carry no
      `no-commit-push-pr`), then `build-agent-defs.ps1` to fill them.
- [x] `agent-shared/README.md`: the table row, plus the per-block width decision with #1665's
      measurement, both size corrections, and why no persona carries it (mutating the tree *is* the
      DevOps engineer's and the release manager's craft).
- [x] Chris's portable manual: the fan-out bullet claiming read-only parallel work is fine now says
      read-only describes the assignment and not the tools, and a new bullet says to commit before
      fanning out.
- [x] **The circle is kept by a gate, not by memory** -- `Get-ToolRequiredSharedBlocks` +
      `Get-AgentDefTools` in `scripts/lib/agent-shared-lib.ps1`, read by new **lint check 36**: an agent
      def naming a tool in that table and carrying no block is a finding. Check 7 could never serve this
      -- it compares the inside of a sentinel pair against its source and is silent on a pair that is
      absent, which is right for a craft block and wrong for one placed by capability. Without it a
      specialist gaining `Bash` later sat silently outside the boundary with every gate green: the same
      enforced-by-memory shape as the defect itself.
- [x] `agent-shared.tests.ps1`: 12 new asserts (38 total) -- the folded-`description:` case that caused a
      silent pass, that a `tools:` line in the BODY is not read, that both halves of the finding fire on
      an obliged def with no block, that a def without the tool is not obliged, that no persona declares
      tools, and that the gate's own coverage count equals the obliged set.
- [x] Review round applied: Sebastian (the catch-all now reaches **any ref** -- `git branch -f`/`-D`,
      `git tag -f`, `git update-ref` destroy work through a pointer while touching neither tree nor
      `HEAD`; and `git worktree add` is no longer listed as read-only, with a location and a cleanup
      named). Edith (one redundant sentence cut, `is not its to move` -> `its own`, and the three stale
      `DaveKJohn/` citations in the file this branch edits corrected, per `CLAUDE.md`'s edited-for-other-
      reasons rule). Victor (the "four writing specialists" count was wrong -- it is **seven**; the three
      `dkj-team-ecomm` specialists were missing, which is the same miscount by craft the section exists
      to correct, so it is recorded in the README rather than quietly fixed). Marlowe (the manual no
      longer presents "commit before you fan out" as costless).
- [~] Nolan's trim of bullet 1's rationale not taken. He measured it as the heaviest bullet and routed
      the call rather than making it; the clause he names -- *"this is not your editing boundary in
      another register"* -- is the defect's own mechanism, and it is what makes the block something other
      than a restatement of `no-commit-push-pr`. Always-on cost is unchanged at **0 bytes**, so nothing
      every session pays went up; the on-invoke figure is 623 tokens per carrier, paid only on dispatch.
- [x] Two findings outside this branch's scope filed rather than carried:
      [#1669](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1669) (this repair is prose
      only, while `guard-live-theme.ps1`'s own header says *"prose does not stop a command"* -- a
      `PreToolUse` hook is the stronger option and depends on a payload field nobody has verified) and
      [#1670](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1670) (nothing detects a
      mutation after the fact, so a repeat is as invisible as the original, which was found by accident).

### TEST

- [x] `check-plugin-integrity.ps1`: 0 errors, with `[shared] checked 30` and the new `[tool-block]
      checked 11`. That coverage figure is what caught check 36 shipping as a silent pass -- a
      frontmatter regex without `(?s)` matched nothing and reported `checked 0`.
- [x] `agent-shared.tests.ps1`: 38/38. All suites via `open-pr.ps1`'s own gate.

### DEPLOY: fix/1665-working-copy-boundary

A dispatched specialist holding `Bash` is now told, in its own always-loaded boundary, that the checkout
it stands in is not its own to move: no `git stash`, `checkout -- <path>`, `reset`, `clean`, `restore`,
branch switch, or anything else that mutates the tree, the index or **any ref** -- whatever files it may
legitimately edit. The block names the read-only way to read another ref instead, and says that a clean
`git status` proves nothing, because it is exactly what discarded uncommitted work looks like.

It closes a real loss rather than a hypothetical one: a review stashed, hit other sessions' stash
entries, and resolved the conflict with `git checkout HEAD -- <file>` on three files, taking four of the
orchestrator's uncommitted edits with it and reporting `No repo content was altered`. The old wording
did not reach that, because a stash corrects nothing and lands nothing.

**And the circle that carries it is now kept by a gate rather than by memory.** This is the first shared
block placed by **capability** instead of by craft -- it goes wherever `tools:` names `Bash` -- and that
is the one kind of circle a check can hold, so **lint check 36** reports any agent def that names the
tool and carries no block. Without it a specialist gaining `Bash` later would have sat silently outside
the boundary with every gate green, which is the same enforced-by-memory failure as the defect itself.

**Score:** 4

#### What makes this deploy extra special

N/A -- the block ships to every consumer of the four team plugins, but its reader is a subagent rather
than a subscriber of a service, and this repo publishes to none.

**Score:** N/A

#### Pull Request

A review may not mutate the working copy: no git stash, checkout --, reset or clean
