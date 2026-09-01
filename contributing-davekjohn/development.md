## Development: `docs/sync-rules-floor-consequence-v1` · 20260901-211416

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

Issue [#1199](https://github.com/DaveKJohn/claude-code-specialists/issues/1199): `Get-SyncReferencePoint`'s
`.DESCRIPTION` states the **time-window** consequence of a missing floor -- the one inbound #807 retired --
in the file that carries the rule itself. Same defect as #1197 reported in Sandra's manual, one layer down.

- [x] Verify the report against the tree rather than the report: symptom still at `sync-rules.ps1:110-114`;
      reason confirmed against the rule comment at line ~247 and `Get-SyncFileVerdict`'s table, which
      consults the floor in **one** cell and can only escalate to a human; both mirrors byte-identical.
- [x] Widen only where the repair would otherwise contradict itself. The paragraph below the reported one
      calls this *"that same failure"* and then states `the rule keeps NOTHING back` -- present tense, same
      retired consequence -- so repairing line 112 alone leaves the docstring disagreeing with itself four
      lines later. The `sync-rules.tests.ps1` comment for that same case carries the identical wording.
- [~] Sweep the two mirrors for further time-window assumptions -- not done, and #1199 asked for exactly
      that restraint. The dated, past-tense measurements of inbound #801 and #819 stay as they are: they
      record what the old rule was about to do, which is a correct historical account. Same for the
      deliberate historical mentions at `sync-rules.ps1:197` and `sync-main.ps1:20`.

### CREATE

- [x] `scripts/lib/sync-rules.ps1`: state what a missing floor actually costs -- one unreported
      both-sides-moved conflict, taken as `take-live` -- and name #807 as what changed it.
- [x] Same file, the `--no-merges` paragraph: `the rule keeps NOTHING back` becomes the conflict cell
      collapsing to `take-live`, so *"that same failure"* still points at the failure above it.
- [x] `scripts/tests/sync-rules.tests.ps1`: the `ref/merged` case comment, same substitution, no assert
      touched -- the suite was measuring the floor, never the consequence.
- [x] Mirror via `scripts/sync/build-shared-scripts.ps1`; `-Check` reports all shared scripts in sync.

### TEST

- [x] `scripts/tests/sync-rules.tests.ps1`: **111 asserts pass**, unchanged in count -- a comment repair
      that moved an assert would have been the wrong repair.
- [x] `check-plugin-integrity.ps1` + the full suite set via `open-pr.ps1`.

### DEPLOY: `docs/sync-rules-floor-consequence-v1`

`Get-SyncReferencePoint`'s docstring is what a reader consults to decide how much a wrong or missing floor
costs, and it overstated that cost in the direction that misdescribes the guardrail: *"the exclusion rule
silently passes everything through"* is the **time-window** consequence inbound #807 retired. Under the
content rule the floor decides no file's winner -- `Get-SyncFileVerdict` consults it in exactly one cell,
live's content is foreign AND the trunk moved the same path, where it can only ever escalate to a human. So
a missing floor costs **one silently-taken conflict**, not a wholesale overwrite. The refusal itself was
always correct; only its stated reason was stale.

Repaired in both byte-identical mirrors and in the suite comment for the same case, which carried the
identical wording. Nothing executable changed: 111 asserts, the same 111. The dated measurements of inbound
#801 and #819 are left alone -- they describe what the old rule was about to do, and that is history rather
than drift.

**Score:** 2

#### What makes this deploy extra special

N/A -- a PowerShell docstring and a test comment inside the sync lib. No subscriber of any service reaches
this text, and nothing about the sync's behaviour changed.

**Score:** N/A

#### Pull Request

Get-SyncReferencePoint's docstring states what a missing floor actually costs under the content rule
