## docs/1470-sessionstart-hooks-sentence

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

Repair the sentence at `plugins/teams/team-alpha/skills/specialists-init/SKILL.md:50`, reported as
issue #1470: *"The two SessionStart hooks, `adopt-config.ps1` and `orchestrator/SKILL.md` name the
command and the actor for that reason."*

**It is a punctuation defect, not a factual one, and the tree proves the intent.** Read as written the
list is an appositive -- it claims `adopt-config.ps1` and `orchestrator/SKILL.md` ARE the two
SessionStart hooks, which neither is. The comment directly above one of the lines it cites says
otherwise: `adopt-config.ps1:176-178` reads *"NAMES THE COMMAND AND WHO TYPES IT (inbound #1093 /
#1096 / #1104). Not a SessionStart hook like the roster check, but the same trap"*. So the sentence
was a list of FOUR, and it lost the conjunction that made it one.

**All four verified as still naming the command and the actor:**

| Place | Where it prints | Reader it saves |
|---|---|---|
| `roster-sessioncheck.ps1` -> `check-roster-sync.ps1:1021` | `[BOOTSTRAP]` | an unbootstrapped repo's session start |
| `script-contract-sessioncheck.ps1` -> `check-script-contract.ps1:294` | `[BOOTSTRAP]` | the same, from the workflow plugin |
| `adopt-config.ps1:179-182` | `[STOP]` | a model that ran the adopt command too early |
| `plugins/teams/team-alpha/skills/orchestrator/SKILL.md:64-72` | the page itself | a model in a repo that was never adopted |

Each says `/team-alpha:specialists-init` in full and then says the repo owner has to type it -- which
is exactly what the paragraph above claims of them, so nothing but the sentence's own grammar was
wrong.

#### Out of scope, deliberately

`plugins/teams/team-shopify/scripts/task/adopt-shopify-floor.ps1:361` does the same thing and is a
fifth such place. It is not added to the count: this page is `team-alpha`'s and the sentence is about
the reservation team-alpha's own surfaces honour, so pulling a second plugin's message into the list
would make the number stale the next time any plugin gains one. The four named are the four the
sentence always meant.

### CREATE

- [x] Rewrite the sentence at `specialists-init/SKILL.md:50` as an explicit list of four, naming each
      hook by its own file and the script or page behind it, so no reader has to guess which two the
      "two SessionStart hooks" were.

### TEST

- [x] `check-plugin-integrity.ps1` -- the paragraph gained four inline code spans and no links, so the
      dead-link scan and the install-flag scan have nothing new to read; run for the frontmatter and
      manifest checks regardless.
- [x] All suites under `scripts/tests/`, exactly as CI runs them.
- [x] Re-read each of the four cited places against the claim -- the table in PLAN is that reading.
      This is the check the report itself could not complete, because it needed the intent first.

### DEPLOY: docs/1470-sessionstart-hooks-sentence

One sentence in the `specialists-init` skill page named its own evidence in a way that did not parse:
it introduced *"the two SessionStart hooks"* and then apposed two files that are not hooks. The
paragraph's claim was always true -- four places do name `/team-alpha:specialists-init` in full and
say the repo owner has to type it -- but the sentence carrying it could not be checked by a reader,
which is the only thing that makes such a citation worth writing. It now names all four, each with
the hook file and the script behind it.

The page carries `disable-model-invocation`, so a model never reads it; the reader here is the repo
owner adopting the family for the first time, and they are exactly the reader who has no other way to
verify that the no-bare-imperative rule is honoured anywhere. A citation they cannot follow is worse
than none, because it looks like evidence.

**Score:** 2

#### What makes this deploy extra special

Nothing structural -- one paragraph, no mechanism, no script. What is worth keeping is the method: the
intent the report said it could not determine was recoverable from the tree, in a comment sitting
directly above one of the lines the sentence cites. `adopt-config.ps1` says of itself *"Not a
SessionStart hook like the roster check, but the same trap"*, which settles both that the sentence
meant a list of four and that its author knew the distinction. Reading the cited code before guessing
at the wording is what turned "needs someone who remembers" into a mechanical repair.

**Score:** 1 -- cosmetic on the page itself; the failure it prevents is a reader checking a citation,
finding it names the wrong kind of thing, and discounting the paragraph's claim along with it.

#### Pull Request

The specialists-init 'two SessionStart hooks' sentence names its four places

