## fix/1850-runner-adoption-visible

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

Close the blind spot in which an unadopted consumer and a clean one are indistinguishable to the
connector register -- issue #1850.

#### What the register could not see

`check-connectors.ps1` check 6 judges the paths a consumer's CI runners NAME.
`consumer-runner-lib.ps1` writes its own limit into its docstring: *"a finding here is therefore
always about a path that IS named; the absence of one is never evidence that a consumer is clean."*
So a consumer running none of the three scaffolded runners produces no reference, no finding, and
reads exactly like a fully adopted repo. Verified against the tree before building:
`DaveKJohn/djcylow-react` registers the full core-team adoption AND names the workflow plugin, and
the remote read shows its `.github/workflows/` holding one `ci.yml`.

#### Why an [INFO] and not an [ERROR]

Both halves of `adopt-dkj-policy` that place those runners are optional and separate from enabling
the plugin, so an absent runner may be a decision somebody made. `connectors/README.md` already
draws this line one check over, for a plugin id the marketplace no longer declares: *"this consumer
has not migrated, which is a state rather than a defect."* Check 6 stays an `[ERROR]` for the
opposite reason -- a stale path is red on every pull request, with nobody able to learn it from
their side.

### CREATE

- [x] `Test-ConsumerRunnerAdoption` in `scripts/lib/consumer-runner-lib.ps1` -- four statuses,
      because `no-workflows`, `unreadable`, `no-reference` and `adopted` are four different
      sentences and a caller that cannot tell them apart is wrong in three of the four cases. It
      inherits the parser bound rather than escaping it, so `no-reference` means *nothing
      recognisable*, never *nothing is there*.
- [x] `Get-RunnerRecordField` beside it. The two callers genuinely hold two shapes -- the network
      read builds a hashtable, the disk read a `[pscustomobject]` -- and a hashtable's
      `PSObject.Properties` are Keys/Values/Count, so reading only one shape is a SILENT miss
      rather than an error: every file reads as unreadable. Measured on the first real run.
- [x] Check 6c in `scripts/sync/check-connectors.ps1` (`Write-RunnerAdoptionFinding`), gated on the
      manifest naming the workflow plugin under every name it has carried, and never asked of this
      repo's own record.
- [x] Both routes: the disk, and under `-RemoteRunners` the network, where `no-workflows` used to
      be deliberate silence -- which was the blind spot itself.
- [x] `connectors/README.md` states the check, its `[INFO]` line and both bounds.

### TEST

- [x] `connectors.tests.ps1`: 12j adopted (silence), 12k workflows-but-no-reference
      (djcylow-react's shape), 12l no `.github/workflows` at all, 12m the plugin gate, 12n the
      source-repo exclusion. 381 pass, 0 fail.
- [x] Run against the real register: silent everywhere it should be, and `-RemoteRunners` reports
      exactly `DaveKJohn/djcylow-react` -- the case #1850 was filed on.
- [x] Lint gate and full suite via `open-pr.ps1`.

### DEPLOY: fix/1850-runner-adoption-visible

The connector register can now tell an unadopted consumer from a clean one. Check 6 judges the paths
a consumer's CI runners name, so a consumer running NONE of the three runners this workflow
scaffolds named none, produced no finding, and read exactly like a fully adopted repo -- the limit
`consumer-runner-lib.ps1` had written into its own docstring without closing. Check 6c asks the
other question: does anything in that consumer reach into this tree at all.
`DaveKJohn/djcylow-react` is the measured case -- full core-team adoption registered, workflow
plugin listed, entire `.github/workflows/` one `ci.yml` -- and it reported green.

It is an `[INFO]`, on the line this register already draws for an unmigrated plugin id: both halves
of `adopt-dkj-policy` that place those runners are optional, so their absence is a state that may be
a decision. The finding says so, and points at the manifest's `notes` for recording one. Two bounds
are in the finding itself: only a manifest naming the workflow plugin is asked, and this repo's own
record never is -- it runs those scripts by local path, being the tree every consumer checks out, so
it is the one registered repo that can never produce a reference. It runs on the disk and, under
`-RemoteRunners`, over the network, where `no-workflows` used to be deliberate silence.

Worth keeping from the build: reading only one of the two record shapes the callers hold is a silent
miss rather than an error -- a hashtable's `PSObject.Properties` are Keys/Values/Count, so `Text` is
never found and every file reads as unreadable. That is what the first real run said, and
`Get-RunnerRecordField` is the answer.

**Score:** 3

#### What makes this deploy extra special

Nothing a consumer runs behaves differently -- this check lives in the maintainer's register and
reads consumers from the outside. What it changes is on the maintainer's side: a repo that never ran
parts 1 and 3 of the adoption is now visible instead of reading as clean, which is the difference
between knowing the gate is off and assuming it is on.

**Score:** N/A

#### Pull Request

the connector register reports a consumer that runs none of the scaffolded runners

