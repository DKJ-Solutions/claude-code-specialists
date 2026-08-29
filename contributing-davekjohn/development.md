## Development: `fix/the-hook-handover-uses-the-owners-own-voice-v1` · 20260829-212002

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

PR #1111 rewrote seven printed instructions so that none of them names a skill barred to its reader.
Five of the seven came out in one voice and **two came out in another**, and the two are the
`roster-sessioncheck` hook lines:

| Site | Wording |
|---|---|
| `check-roster-sync.ps1` (both), `adopt-config.ps1`, `adopt-shopify-floor.ps1`, `INSTALL.md` | *run X -- that command must be **TYPED by the repo owner*** |
| `roster-sessioncheck.ps1` (both) | *ask the repo owner to type X* |

#### The second form is the one #1096 measured and rejected

It is not a style preference. `check-roster-sync.ps1`'s `[BOOTSTRAP]` marker carries the reasoning in
full, written when that line was repaired:

> **DUAL AUDIENCE, WHICH IS WHY THIS IS NOT THE REPORT'S LITERAL WORDING.** The report proposed
> "Ask the user to run ..." -- correct for the model and **odd for the OWNER**, who reads this same line
> on their own terminal and is not a third party to themselves.

The hook is exactly the reader that reasoning is about, and the worst place to get it wrong: a
SessionStart hook is the first thing in context on a fresh consumer, at the top of **every** session
until the repo is adopted. Dave reading his own terminal is told to ask himself.

#### Why this is a separate branch rather than a fix inside #1111

#1111 was already in CI when this was spotted, and pushing to a branch a background `ship-pr` is
mid-merge on is how a green run gets merged at the wrong SHA. The wording is not wrong enough to be
worth that risk; it is wrong enough not to leave.

### CREATE

- [x] Both hook lines rewritten into the same form the other five use, with a comment saying why that
      form and not the other -- pointing at the `[BOOTSTRAP]` marker rather than restating its reasoning.

### TEST

- [x] `roster-sync.tests.ps1`: 333 asserts pass.
- [x] **One assert had to move with it**, and it is the assert #1111 itself added. It pinned the literal
      words `cannot start it`, which this wording no longer contains; it now pins `TYPED by the repo
      owner`, which is the half that carries the meaning. An assert on the words rather than on the claim
      is the reason it needed touching twice in two branches.
- [x] The lint gate is green, check 30 included -- both new lines name the command rather than the skill.

### DEPLOY: `fix/the-hook-handover-uses-the-owners-own-voice-v1`

The two `roster-sessioncheck` hook lines now hand the reader `/team-alpha:sync-roster` in the same words
the other five repaired sites use -- *"that command must be TYPED by the repo owner"* -- instead of
*"ask the repo owner to type"*.

Both forms tell a model the right thing. Only one of them also reads correctly to the **owner**, who sees
this same line on their own terminal and is not a third party to themselves; that is the dual-audience
reasoning `check-roster-sync.ps1`'s `[BOOTSTRAP]` marker already carries, and PR #1111 applied it to five
of its seven sites and not to these two. A SessionStart hook is the worst place for the gap: on a fresh
consumer it is the first thing in context, in every session, until the repo is adopted.

**Score:** 1

#### What makes this deploy extra special

The repair that introduced the inconsistency was the repair for inconsistent instructions. Check 30 could
not have caught it -- both forms pass, because both name the command rather than the skill. What the gate
guarantees is that a message is *followable*; whether it is followable **by the person actually reading
it** is still a judgement, and this is the second time that particular judgement has had to be made in
the same file.

**Score:** 1

#### Pull Request

The roster hook's handover speaks to the owner in their own voice, like the other five sites
