## Development: `docs/a-repo-with-no-required-check-v1` · 20260829-151413

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

Inbound #1083: a private repo on the GitHub Free plan cannot have branch protection, and the page
describes a gate that reader cannot build.

The report proposes two things and they did not survive verification equally. **The documentation half
holds**: `CONTRIBUTING-portable.md` describes the merge waiting on "whatever status check your branch
protection requires" and says nothing about a repo that can have none, while the scripts in fact behave
well there -- the wait covers every check, and `Get-MergeBlockVerdict` refuses rather than proceeds when
the required list cannot be read. **The output-line half does not.** The report reads
`waited 2s -- which check governed could not be read` as what a no-ruleset repo sees, and the code says
otherwise: `Get-CheckWaitReport` omits the required/not-required label when the required payload is empty
and still renders the line (asserted in `pr-issues.tests.ps1` as `$line3`, before this branch). That
fallback fires only when the CHECK FACTS cannot be read. So the proposed wording -- "no required check is
configured -- judged on all checks" -- would have stated a cause the code does not produce.

### CREATE

- [x] `CONTRIBUTING-portable.md`: say what the cycle does in a repo that cannot have a required check.
- [x] The `ship-pr` skill page: the same for the reader who is already at the wait, plus what the
      fallback line does and does not mean.
- [~] Reword the fallback line as the report proposed -- dropped: it names a cause the code does not
      produce, and a wrong diagnosis in a message is worse than a vague one.
- [x] Reword it to name the condition it actually fires on instead.
- [x] Mirror the changed script into the plugin (`build-shared-scripts.ps1`).

### TEST

- [x] Asserts that the fallback names the payload and no longer words it as a fault; the no-ruleset
      report itself was already asserted and is cited rather than duplicated.
- [x] The full local gate green: `check-plugin-integrity.ps1` + every suite.

### DEPLOY: `docs/a-repo-with-no-required-check-v1`

A private repository on the GitHub Free plan cannot have branch protection -- the API answers
*"Upgrade to GitHub Pro or make this repository public to enable this feature"* -- and that is the shape
most new repos start in. Until now the contributing page described the merge as waiting on "whatever
status check your branch protection requires" and stopped there, so the first reader to walk this cycle
on a fresh repo met a mechanism they had no way to switch on and nothing saying what happens instead.

What happens instead is good news, and both halves are now written down on the page and in the `ship-pr`
skill: the wait covers **every** check the PR has rather than only required ones, so it works with no
ruleset at all; and where nothing is required the merge verdict cannot tell *"this repo requires
nothing"* from *"the required checks have not reported yet"*, so it refuses on a red check rather than
proceeding. A repo without a ruleset is guarded conservatively rather than left open -- it simply cannot
be told which check governed, because none does.

One line of output changed with it, and not the way the report asked. `ship-pr`'s wait-report fallback
read *"which check governed could not be read"*, which was reported as sounding like a fault. It now
reads *"no readable check facts, so nothing to report about the wait"*, which is the condition it
actually fires on: gh answered nothing, or no check carried a readable completion time. The report's own
proposal -- word it as the no-ruleset case -- was declined, because a repo that requires nothing still
gets a fully rendered report with the required label omitted. That is asserted in this suite and was
before this branch; wording the fallback as the no-ruleset case would have sent a reader with no ruleset
looking for a setting they cannot have.

Closes [#1083](https://github.com/DaveKJohn/claude-code-specialists/issues/1083).

**Score:** 2

#### What makes this deploy extra special

This is the document a consumer is handed on day one, read on the exact configuration a new repo starts
in: private, Free plan, no ruleset possible. What it cost before was not a broken run -- the whole cycle
runs green there -- but a reader who could not tell whether it was. They met a gate they cannot build
and an output line that reads like a fault, and finding out that both were fine took reading
`ship-pr.ps1`.

**Score:** 3

#### Pull Request

what the cycle does in a repo that cannot have a required check
