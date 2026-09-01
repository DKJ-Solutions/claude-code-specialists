## Development: `fix/asana-mirror-intake-link-v1` · 20260901-210535

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

Verified: the CI ran on #388 and logged 'No asana-task marker'. Imported tickets carry the task as a header-row link only. Next: tiered resolution + a GitHub-side reconcile pass.

### CREATE

- [x] `Resolve-AsanaTaskRef` in the asana-mirror template: marker, then the imported ticket's
  `| **Asana** |` header row, then a sole task URL; several different tasks report as `ambiguous`
  and resolve to nothing. `Get-AsanaTaskGid` kept as a thin wrapper, so every existing caller and
  assert is unchanged.
- [x] Both Asana URL shapes read -- `/1/<ws>/project/<p>/task/<t>` and the classic `/0/<p>/<t>`.
- [x] The reconciliation sweep gained its second direction: GitHub -> Asana over the issues closed in
  the last `-SinceDays` days, which is the only half that can reach an imported ticket (its task was
  written by a colleague and carries no GitHub back-link for the Asana -> GitHub pass to find).
- [x] `Get-AsanaTaskState` reports and skips a task the token cannot read, so one unreachable ticket
  cannot end a sweep over all of them.
- [x] `templates/asana-mirror.yml`: the reconcile step passes `-Repo $env:GITHUB_REPOSITORY`.
- [x] `WORKFLOW-portable.md` and the plugin README: the three tiers, the measurement behind tier 2,
  and the PAT-reach caveat. The claim *"a task URL alone is not enough"* was true and is now false.

### TEST

- [x] `scripts/tests/bwj-codex.tests.ps1`: 14 new asserts -- the intake header row, its precedence
  over both a sibling link and (in reverse) the marker, both URL shapes, the ambiguity report, a
  project link naming no task. 44/44 green.
- [x] Resolution replayed against the live bodies of all 11 imported tickets in
  `BWJ-ecommerce/smartwatchbanden` (#386-#396): every one resolves, all by `header-row`.

### DEPLOY: `fix/asana-mirror-intake-link-v1`

The Asana mirror now recognises a ticket that came FROM Asana. It only ever matched the
`<!-- asana-task: ... -->` marker it writes itself, so an issue imported from Asana -- which carries
its task as a link in the header row, written for a reader -- closed without touching Asana. Measured
in `BWJ-ecommerce/smartwatchbanden` on 2026-09-01: of 55 issues, 4 carried a marker and 11 carried a
header-row link only, 6 of those already closed with their Asana task still open. The workflow had
run on each of them and logged exactly why. The daily sweep gained the matching direction -- GitHub's
recently closed issues, forward into Asana -- because the Asana-side pass reads a GitHub back-link
that an imported ticket's task does not have.

**Score:** 4

#### What makes this deploy extra special

N/A -- this repo's subscribers are the consumers of the plugins, and nothing about installing or
running them changes. The repair is inside a CI template a BWJ store repo copies.

**Score:** N/A

#### Pull Request

asana-mirror resolves an imported ticket's Asana task from its header link, not only from the marker
