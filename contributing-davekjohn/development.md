## Development: `fix/a-lane-must-not-hold-the-trunk-hostage-v1` · 20260829-120059

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

Issue #1069: ship-pr step 5 checks out main in whatever tree it runs in and leaves it there, so a lane takes the global main lock and the NEXT chain's fold dies after its merge has landed.

#### What the report got right, and the one thing it did not

Verified against the tree before anything was written. The symptom stands, the reflog reading is
correct, and the size is binary as reported -- one lane parked on the trunk is enough.

The one correction is to the repair sketch. Its second option -- have step 5 detect a lane and fold
via `-RepoRoot` against the primary -- collides with a decline `worktree-lane.ps1` states in as many
words, and it is not merely a matter of taste: `git worktree add <path> main` is refused for the same
reason `git checkout main` is, so the throwaway-worktree arm ship-pr already carries provably cannot
rescue the reported case. Its own comment says so. So the repair is the report's first and third
options together -- release the lock at the source, and refuse before the merge rather than after --
and the existing arm is left exactly as it is.

### CREATE

- [x] `scripts/lib/worktree-lib.ps1`: the porcelain reader, four pure functions, no git.
- [x] ship-pr step 0: refuse before step 1 when another worktree holds `main`, naming the directory
      and the two commands that release it.
- [x] ship-pr step 5, in-place arm: the same hand-fold instruction the worktree arm already gave,
      because a bare "git checkout main failed" is at its most expensive on the one line the merge has
      already run past.
- [x] ship-pr step 5b: a non-primary tree hands the trunk back after a successful fold. The root
      cause, and the only place a lane's lock is actually released.
- [x] `prune-merged.ps1`: name the worktree that holds the trunk instead of relaying git's message.
- [x] Registry + mirror: `worktree-lib` as a `LibOnly` row, mirrored into the plugin.
- [~] `worktree-lane.ps1` left unchanged. Its hand-back already does the right thing; what was broken
      was that a lane never reached it, which step 5b fixes upstream of the script.

### TEST

- [x] `scripts/tests/worktree-lib.tests.ps1` -- 26 asserts, all green, including the two cases that
      would each break an ordinary run: a lone checkout on the trunk must not report itself, and the
      stanzas must not separate on the blank line.
- [x] The refusal proved live: a real second worktree on `main`, `ship-pr -NoMerge`, exit 1 before
      step 1 with nothing pushed.
- [x] `prune-merged` proved live against that same worktree.
- [x] Full suite + lint gate via `open-pr`.
- [~] No suite for ship-pr itself. It drives live git and gh against a real remote and has never had
      one; that gap is documented in its own header, and the answer to it here is that the decision
      this repair turns on was extracted into a lib that does.

### DEPLOY: `fix/a-lane-must-not-hold-the-trunk-hostage-v1`

A finished worktree lane no longer holds the trunk hostage for the rest of the machine, and a chain
that cannot fold now says so before it merges instead of after.

`ship-pr.ps1`'s step 5 checks `main` out in whatever tree it runs in, so that it can fold. In the
primary checkout that is deliberate. In a lane it took a lock that is global to the clone -- git
allows one worktree per branch -- and nothing warned: the bill was paid by an unrelated branch,
later, at the one moment it costs most. On PR #1068 that produced the half-state the fold script
exists to prevent, with the merge irreversible and the changelog unfolded.

Three changes, in the order they fire. A **step 0** now asks whether another worktree holds `main`
and refuses there, before any gate has run and before anything is pushed or merged -- naming the
directory and the commands that release it. Step 5's **in-place arm** carries the same hand-fold
instruction its worktree arm always had, for the narrow window step 0 cannot cover (another session
taking `main` while CI is watched). And **step 5b** gives the trunk back: a tree that is not the
primary checkout returns to its own branch once the fold has succeeded, which is where the lock was
being created in the first place. `prune-merged.ps1` -- the branch-hygiene script that was
unavailable in exactly the situation that produces stray branches -- now names the worktree holding
the trunk instead of relaying git's message.

The reading behind all four lives in `scripts/lib/worktree-lib.ps1`, a new shared lib, because
`ship-pr.ps1` drives live git and gh and carries no suite of its own; its own header asks for exactly
this, and the lib has 26 asserts.

**Score:** 4

#### What makes this deploy extra special

Every consumer of the `contributing-davekjohn` workflow runs both scripts, and any consumer using
worktree lanes was carrying the same trap silently. It arrives by plugin update with no action
needed. Consumers who do not use lanes see no behaviour change at all.

**Score:** 3

#### Pull Request

A finished lane hands the trunk back, and ship-pr refuses before the merge rather than failing after it
