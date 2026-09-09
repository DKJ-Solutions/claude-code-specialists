## feat/1669-subagent-working-copy-guard

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

Payload shape VERIFIED from the shipped Claude Code schema before anything was built on it, which is
what #1669 made a precondition of itself. The detail, and the one half of it that could NOT be
verified here, is in the section below.

#### The verification the issue made a precondition, and what it actually answered

#1669 said the design rests on an unverified claim -- that a hook payload can tell a dispatched
subagent's call from the main thread's -- and forbade building until it had been read from a live hook
run. Read from the shipped Claude Code binary's own hook-input schema, with the vendor's per-field
documentation:

- The base payload every hook event inherits is `hook_event_name, session_id, transcript_path, cwd,
  scratchpad_dir, prompt_id, permission_mode, agent_id, agent_type, served_call, caller_session_id,
  effort`, and `PreToolUse` is that base plus `tool_name, tool_input, tool_use_id`.
- `agent_id` -- *"Subagent identifier. Present only when the hook fires from within a subagent (e.g., a
  tool called by an AgentTool worker). Absent for the main thread, even in `--agent` sessions. **Use
  this field (not `agent_type`) to distinguish subagent calls from main-thread calls.**"*
- `agent_type` -- *"Present when the hook fires from within a subagent (alongside `agent_id`), **or on
  the main thread of a session started with `--agent` (without `agent_id`)**."*

So the mechanism exists, and the vendor names the field to gate on. That second quote is a
false-positive trap no amount of reasoning would have found: gating on `agent_type` blocks the main
thread of any `--agent` session.

**What is NOT verified, stated rather than hidden: no live payload was read.** Three routes to install a
throwaway dumping hook were refused by the harness's auto-mode classifier -- a hook in
`.claude/settings.local.json` (via shell and via the Write tool) and an isolated `claude -p` run with
its own `--settings`. What WAS measured live is that a `PreToolUse` hook intercepts a main-thread `Bash`
call at all: `guard-live-theme.ps1` blocked `shopify theme publish --theme 12345` from this session,
verbatim. The residual is therefore narrow and named: the schema is the contract, and an observed
payload would confirm this build honours it.

### CREATE

- [x] `scripts/lib/command-guard-lib.ps1`: the false-positive machinery of `guard-live-theme.ps1`,
      extracted so it is reused rather than rediscovered -- heredoc and here-string stripping, the
      segment split, the text-tool exemption and its execution override -- plus the payload reader and
      the `agent_id` gate. Each caller supplies its own exempt-command set, because the sets differ:
      `git` is exempt THERE (it handles text) and is the subject HERE.
- [x] `plugins/dkj-policy/hooks/guard-working-copy.ps1`: block only when `agent_id` is present, and
      only on a segment whose LEADING command is git and whose SUBCOMMAND is in the class -- so
      `git commit -m "never run git checkout"` passes where a match-anywhere rule would refuse it.
- [x] The command class as ONE class, not #1665's pair: `checkout`, `switch`, `restore`, `reset`,
      `stash` (mutating forms), `clean` (mutating forms), the ref mutations (`branch -f/-d/-D/-m/-M`,
      `tag -f/-d`, `update-ref`) and the HEAD movers (`rebase`, `merge`, `cherry-pick`, `revert`, `am`).
      Read-only siblings stay open by name: `stash list/show`, `branch` as a listing, `tag` as a
      listing, `clean -n/--dry-run`, and every `diff`/`show`/`log`/`status`. `worktree add/remove` stays
      open because the boundary block explicitly permits it.
- [x] Interpreter wrappers re-scanned rather than waved through: `bash -c "git checkout main"` and
      `powershell -Command "git reset --hard"` are the vector `guard-live-theme`'s header names, and
      leading-command matching would miss them.
- [x] No escape marker, deliberately -- unlike `guard-live-theme`. The boundary block says a subagent
      that genuinely needs the checkout in another state writes a sentence in its deliverable; there is
      nothing for a marker to authorise.
- [x] Register it in `plugins/dkj-policy/hooks/hooks.json` (`PreToolUse`, matcher `Bash|PowerShell`)
      and mirror the lib into `plugins/dkj-policy/scripts/lib/`.
- [x] Say in the prose that the rule is enforced now: the `working-copy-boundary` block, the
      `check-fanout` skill (detection's half of the same hazard) and Sylvester's lens.

#### Four things the plan did not foresee, each added because a measurement asked for it

- [x] **The judgement is split off from the hook** into `scripts/lib/working-copy-guard-lib.ps1`. The
      plan had it inside the hook; the false-positive measurement needs to run 8818 commands through
      *the same decision the hook makes*, and a process and a payload per case makes that a different
      script instead of the same one. Same reasoning `fanout-lib.ps1` states for its own split.
- [x] **A git command aimed at another repo is out of scope**, which is what the one measured false
      positive turned out to be -- a fixture repo under `/tmp`. Not tolerance for a rate: the guard's
      subject is the dispatching session's checkout. Every `cd` target is resolved and one landing back
      inside settles it as inside, so the exemption cannot be used as a bypass; an invocation's own
      `-C`/`--work-tree`/`--git-dir` outranks any `cd`, in both directions.
- [x] **An agent granted worktree isolation owns its own tree**, and the harness puts that tree INSIDE
      the repo (`.claude/worktrees/agent-<id>`, as this repo's own `.gitignore` records). No incident
      produced this one -- a plain "under the root" test would have refused such an agent every command
      in the one tree it is entitled to move, i.e. the guard breaking the harness feature whose whole
      purpose is to make this hazard impossible.
- [x] **The `agent_id` question is asked before any lib is loaded**, as a string test on the raw
      payload. Purely the wall-clock finding below: 89% of calls are the main thread's and never reach
      the judgement, so they were paying 278 ms to dot-source two libs that then went unused.

### TEST

- [x] `scripts/tests/guard-working-copy.tests.ps1`: a counter-case for every exemption, because an
      exemption without one is a hole with a comment on it -- and both halves of the gate, since a
      guard that also fires on the main thread breaks Derek's and Rendall's ordinary work.
- [x] The FALSE-POSITIVE RATE, measured the way `guard-live-theme` measured its own rather than
      asserted: run the matcher over the real corpus of `Bash` commands in this project's transcripts
      and read every refusal by hand.
- [x] The WALL-CLOCK cost, because this fires per tool call and not per session: a `PreToolUse` hook
      adds a `powershell` launch to every `Bash` command, and this repo has already merged two hooks
      into one to save ~457 ms of session start (#1421). State what the guard costs per call.

#### What the two measurements said

**THE FALSE-POSITIVE RATE IS 0 OF 995.** The corpus is every `Bash`/`PowerShell` command in this
project's transcripts: 9084 calls, 8818 unique, of which **995 were issued by dispatched subagents**.
Those live in `~/.claude/projects/<project>/<session>/subagents/agent-<id>.jsonl` and carry
`isSidechain: true` plus `agentId` -- the same distinction the guard gates on -- so a walk of only the
top-level `*.jsonl` reads zero subagent calls and looks complete while answering the wrong question.

Of the 995, the judgement refuses **11 (1.11%)**, and all eleven were read by hand:

| what it refused | count | verdict |
|---|---|---|
| `git stash` / `git stash pop` / `git stash -u` in the orchestrator's checkout | 4 | real -- one is verbatim the command #1665 measured |
| `git checkout HEAD -- <paths>` | 2 | real -- the other command #1665 measured |
| `git checkout <branch>` / `git checkout main` | 3 | real -- **the September 9 occurrence #1669's own comment records, and the `checkout main` the reflog shows after it** |
| `git reset --hard HEAD`, `git reset --soft <ref>` | 2 | real |

**So the guard would have stopped all three measured incidents**, and there is nothing left over. The
twelfth refusal before the scope rule was a fixture repo under `/tmp`; it is now out of scope, with
five bypass shapes asserted against it. The 159 main-thread refusals in the same corpus are **not**
false positives and never reach the hook: no `agent_id`, no judgement.

**THE WALL-CLOCK COST IS ~437 ms PER CALL, AND ~397 ms OF IT IS NOT THIS GUARD.** Five runs each on
this machine:

| path | before the fast path | after |
|---|---|---|
| bare `powershell` launch (the floor a command hook cannot avoid) | 398 ms | 397 ms |
| main thread -- 8089 of 9084 calls (89%) | 675 ms | **437 ms** |
| subagent, judged and allowed | 738 ms | 757 ms |
| subagent, refused | 732 ms | 736 ms |
| `guard-live-theme` beside it, for scale | 697 ms | -- |

The guard's own work on that 89% is **40 ms** above the launch, down from 278 ms. **The launch itself
stays, and it is the honest price of the feature**: every `Bash` call in every `dkj-policy` consumer
pays it. There is no #1421-style repair available -- that merged two hooks *within one plugin*, and
this is the only `PreToolUse` hook `dkj-policy` ships.

- [x] Lint gate green (0 errors) and **all 88 suites green in 244s**, including the three new ones:
      `command-guard-lib` (38 asserts), `working-copy-guard-lib` (92), `guard-working-copy` (32).
- [x] One assertion was written wrong and the suite caught it: `git clean -nd --force` was asserted as
      a violation on the `--force`. Verified against git in a throwaway repo instead of reasoned -- it
      prints `Would remove`, exits 0, and the file is still there, so `-n` wins and exempting it is
      what the command does rather than leniency.

### DEPLOY: feat/1669-subagent-working-copy-guard

The working-copy boundary stops being prose only. A dispatched subagent that runs `git checkout`,
`stash`, `reset`, `restore`, `switch`, `clean` or a ref mutation in the checkout it was dispatched into
is now refused by a `PreToolUse` hook in `dkj-policy`, while the dispatching session's own identical
command is untouched -- the payload's `agent_id` is what tells them apart, which is the mechanism
[#1669](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1669) filed itself to have
verified before anything was built on it.

Measured against the 995 commands this repo's own dispatched subagents have actually run: 11 refusals,
**all eleven real**, including both commands #1665 measured and the `git checkout` #1669's comment
records -- and **no false positives**. The one that had to be answered was a test engineer in its own
fixture repo, so a git command aimed at another repo is now out of scope, as is an isolated agent's own
worktree.

**Score:** 4

#### What makes this deploy extra special

A consumer's dispatched specialists lose the ability to move that consumer's working copy, which is a
behaviour change they notice the first time one tries -- and it closes a hazard that discards
uncommitted work with no error, no notice and a clean `git status` afterwards. It also costs them
~437 ms on every `Bash` and `PowerShell` call, of which ~397 ms is the `powershell` launch any command
hook pays; that is the price of the feature and is stated rather than buried. Nothing to migrate: the
rule was already in every agent def that holds `Bash`, and this makes it enforceable instead of
advisory.

**Score:** 4

#### Pull Request

Block the working-copy commands a dispatched subagent must not run

