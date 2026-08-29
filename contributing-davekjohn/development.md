## Development: `fix/record-shape-pathless-arm-v1` · 20260829-192126

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

Inbound [#1095](https://github.com/DaveKJohn/claude-code-specialists/issues/1095): `[RECORD-SHAPE]`'s
`pathless-only` arm states the demotion as fact and closes with a re-install instruction that is wrong in the
common case. The register cannot distinguish the two states, so the arm must stop asserting a cause.

#### Verified before anything was built, including the withdrawn proposal

The issue was filed with a scope gate as its fix and then **self-corrected** on the thread. Both halves were
re-checked here rather than inherited:

- **The finding stands.** `Get-RecordShape` classifies on the conjunction alone -- no record for this path,
  a pathless one exists -- and that is equally the resting state of every correctly user-installed plugin in
  a repo that never project-installed it. The line then instructs the reader to undo exactly that.
- **The withdrawal is right.** [#323](https://github.com/DaveKJohn/claude-code-specialists/issues/323)
  measured the demotion directly: it writes `scope=user`, drops `projectPath`, and merges away any
  pre-existing pathless record. A demoted record is byte-for-byte an ordinary machine-wide install, so a
  scope gate would have restored the silence #314/#315/#323 were built to end.

#### The third proposal is declined, with its reason

#1095 also asks to consider dropping these from the roll-up count for plugins not enabled by the repo's own
`settings.json`. The provenance exists (`Get-EnabledPlugins.LayerById`), so it is cheap -- and it has a hole:
a repo that enables a plugin in the **user** layer *and* project-installed it here would have its genuine
#323 loss dropped out of the headline. That is the same shape as the proposal this issue already withdrew, on
a marker built from three prior inbound issues, and the report itself only says *consider*. Answered on the
issue rather than built.

### CREATE

- [x] The detail line reports the observation and asks the reader for the history, with a two-branch remedy
- [x] The lib comment that produced the false cause (`check-report-lib.ps1`, "that is the demotion") states what the conjunction actually covers
- [x] Mirror both scripts into the plugins (`build-shared-scripts.ps1`)
- [~] Roll-up count gating -- declined above, with the hole named; it is a decision rather than a repair

### TEST

- [x] `roster-sync.tests.ps1` 11j: the two retired claims asserted as NEGATIVES, because the old assert on the word `demotes` pinned the defect
- [x] Both remedy branches asserted, including the no-action one -- an unstated "or this is fine" reads as a defect the reader must clear
- [x] Everything #323 and #324 pinned still asserted: the marker fires, the other marker stays silent, the line is non-counting, and the #323 remedy is still reachable

### DEPLOY: `fix/record-shape-pathless-arm-v1`

`[RECORD-SHAPE]`'s pathless line stops telling most readers a story about their own repo that is not true.

The arm fires on one conjunction -- no install record for this path, and a pathless one exists -- and read
that as a demotion: *"the shape a SESSION START leaves behind when it demotes a 'project' record"*, *"this
repo simply no longer has its own record"*, *"Re-install at project scope from this root."* That conjunction
is equally the resting state of every plugin somebody installed machine-wide on purpose, in every repo that
never project-installed it. So the line fired at every session start, for a deliberate install shape, and
closed by instructing the reader to convert it into a per-repo one.

No predicate can separate the two: #323 measured that the demotion writes `scope=user` and drops
`projectPath`, which is byte-for-byte an ordinary user install. So the arm keeps firing -- a silently lost
record must not go back to being unreported -- and stops claiming. It states what it can see, then asks the
one question the reader answers instantly and the register cannot answer at all, with both branches written
out including the one that says no action is needed.

**Score:** 3

#### What makes this deploy extra special

Every consumer with a machine-wide plugin install has been reading this line at every session start, in every
repo, with a re-install instruction that should not be followed. Following it converts a deliberate
machine-wide install into a per-repo one and adds a record nobody wanted -- so the cost was never only
attention.

**Score:** 4

#### Pull Request

the pathless-only record-shape line reports what it can see instead of asserting a history it cannot
