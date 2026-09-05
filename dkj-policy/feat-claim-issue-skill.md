## feat/claim-issue-skill

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

A skill and script that claim a GitHub issue for this checkout's own account before any work on it
starts, refusing where the issue is closed, missing, or already somebody else's.

#### Why this is a script and not one more sentence in a manual

The claim rule is not new. Chris's persona body has carried it for as long as the orchestrator has
had one, and `dkj-policy/CONTRIBUTING.md` restates it for a contributor without the plugin. What
neither has is anything that performs it: `gh issue edit <n> --add-assignee @me`, left to a session to
remember, to type, and to read the result of.

Measured in this repo the day before this branch, in
[#1456](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1456): **0 of 67** assigned
issues carried `DaveKJohn`, an identity holding **132** merged PRs and **83** authored issues here. That
report's own corrective action was *behavioural* -- claim going forward. This branch is the mechanical
half, on this repo's standing rule that a defect gets a gate rather than only a fix.

#### And three things the documented one-liner gets wrong

Each is a refusal in the script, and none of them is reachable by writing the rule down more firmly:

1. **`@me` can name the wrong account.** It binds to whatever `gh` is authenticated as, while the
   branch a second session correlates the claim with carries the git identity
   ([#1315](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1315)).
2. **`--add-assignee` succeeds silently on a CLOSED issue** -- so the claim hands a session every
   signal of having taken ownership of work already finished. This is the failure `new-branch.ps1`'s
   stale-base block records: a branch cut, committed, pushed and PR'd against an issue another session
   had closed by a merged PR four minutes earlier.
3. **It ADDS, so it never says the issue is taken.** Reading the claim back is a separate command the
   rule names and nobody runs.

### CREATE

- [x] `scripts/lib/git-identity-lib.ps1` -- `Test-GitHubLoginShape`, `Get-ActiveGhAccount` and
      `Get-GitUserName`, extracted verbatim from `scripts/lint/check-git-identity.ps1`, which now
      dot-sources them. The claim needs the same three reads and cannot dot-source that script, which
      runs its comparison and exits on load; the alternative was a second copy of the multi-account
      `gh auth status` parse.
- [x] `scripts/lib/claim-issue-lib.ps1` -- the two pure decisions. `Resolve-ClaimAccount` (which
      account, never `@me`) and `Get-ClaimVerdict` (claim / skip / refuse, with the four codes). Pure
      so that every refusal is testable without a tracker.
- [x] `scripts/task/claim-issue.ps1` -- the entry point: resolve the account, read the issue, judge it,
      write one assignee, **read the claim back**. Accepts `1234`, `#1234` or the issue URL; `-DryRun`
      judges and writes nothing.
- [x] Registered in `scripts/lib/shared-scripts-lib.ps1` -- the script under `Skill = 'claim-issue'`,
      both libs as `LibOnly`, all three in `dkj-policy`. Mirrors built with
      `scripts/sync/build-shared-scripts.ps1`.
- [x] `plugins/workflows/dkj-policy/skills/claim-issue/SKILL.md` -- **model-invocable on purpose**,
      unlike `start-task` and `sync-roster`: the pain it removes is a session hearing *"fix issue
      1234"* and starting to fix, so a page nobody may invoke until it is typed leaves that path open.
- [x] The three documents that state the rule now name the step: `dkj-policy/CONTRIBUTING.md`,
      Chris's persona body (one portable paragraph, no plugin assumed), and the two skill listings in
      `README.md` plus the plugin's own table.

### TEST

- [x] `scripts/tests/claim-issue.tests.ps1` -- **27 asserts, all green.** Ten on
      `Resolve-ClaimAccount` (the measured #1315 split, case-insensitive logins, a display name, the
      39/40-character login-shape boundary at both edges, a logged-out gh, trimming); eleven on
      `Get-ClaimVerdict` (all four verdicts, a null assignee list, case-insensitive state, closed
      beating already-yours, a co-assignment, `Others` always an array); and six structural, of which
      the load-bearing one asserts the script **never sends `@me`** -- a later "simplification" back to
      the one-liner would pass every behavioural assert and reintroduce #1315 in one line.
- [x] The lint gate: `check-plugin-integrity.ps1`, **0 errors**, including the skill-parameter check
      (both documented parameters), the shared-script mirror check, and the three skill listings.
- [x] The four verdicts exercised against the **live** tracker: #1454 (closed) refused, #1450 (held by
      `DaveKJohn`) refused, #1453 (already mine) skipped, and a bad argument refused. All by URL, hash
      and bare number.
- [x] The **write** path exercised for real: #1453 was unassigned by hand, claimed by the script, read
      back, and ended in exactly the state it started in. There was no unassigned open issue in the
      repo to use, so this was the only route that touched nobody else's work.

#### The named test gap

The gh round trip itself is not in the suite -- gh accepting the edit, and the read-back catching an
assignee GitHub silently dropped. It needs a live tracker, a write-capable account and an issue it may
edit, so a suite that arranged all three would be testing gh. Exercised by hand instead, as recorded
above, on the same reasoning `git-identity-gate.tests.ps1` gives for not installing a keyring.

### DEPLOY: feat/claim-issue-skill

The claim rule, performed. A `claim-issue` skill and script put an issue on the account **this
checkout commits as** before any work on it begins -- and refuse the three states the documented
one-liner cannot see: a **closed** issue, which `gh issue edit --add-assignee` claims silently; one
**somebody else holds**, which it joins; and a **split identity**, where `@me` writes the tracker
account while every commit lands under another name. The claim is **read back** afterwards, because
`--add-assignee` reports success for a login GitHub drops. Two supporting libs, one of them extracted
from `check-git-identity.ps1` so the identity reads have a single source, a 27-assert suite, and the
three documents that state the rule now name the step that performs it.

**Score:** 4 -- it changes what happens at the start of every piece of issue work, and it does so
without being asked: the skill is model-invocable, so *"fix issue 1234"* now claims before it fixes. A
consumer notices the first time a session refuses to start on a closed issue.

#### What makes this deploy extra special

It closes a rule that had been enforced by memory alone, and the measurement is unusually blunt about
what that was worth: **0 of 67** assigned issues in this repo carried the identity with **132** merged
PRs and **83** authored issues
([#1456](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1456), filed the day before
this branch, whose own corrective action was *behavioural*). The rule was not unclear, unknown or
disputed -- it was simply never the thing anybody remembered to type. This repo's standing answer to
that is a gate rather than a firmer sentence, and the same measurement is why the skill is
model-invocable rather than reserved for an explicit `/claim-issue`: a step nobody may take until it is
typed has exactly the failure mode being repaired.

**Score:** N/A -- workflow tooling between a repo and its tracker; no subscriber of a service reads it.

#### Pull Request

the claim-issue skill
