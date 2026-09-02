## Development: `feat/asana-stage-map-seam-v1` · 20260902-133055

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

Dave rebuilt the board to seven sections within the hour, which broke the hard-coded stage numbers #1223 shipped. His three answers: a merged PR keeps the card in Code review until the issue closes; the meaning-to-number mapping moves into a named Get-AsanaStageMap seam; and Need more info is driven by a GitHub label, which makes it the second answer in the script allowed to move a card backward.

#### The board Dave rebuilt, measured rather than assumed

```text
1. Requests               (was: 1. New - not yet reviewed)
2. Need more info          NEW -- and it is mid-pipeline, which is what broke the model
3. Development ready      (was: 2. GitHub issue created)
4. In development         (was: 3. In development - branch open)
5. Code review            (was: 4. Development done - merged)
6. Waiting on submitter   (was: 5. Waiting)
7. Completed              (was: 6. Completed)
```

**Two failures, and the second is the one worth the branch.** Every number from `Filed` upward shifted
by one, so the shipped literals would have filed each card a column early. And the new column is a
*human hold in the middle of the pipeline*, which forward-only would have trampled every night --
the shipped guard protected only the top of the board.

**Neither would have failed loudly.** That is what makes the seam the repair rather than new literals:
the symptom of a wrong map is cards in the wrong column on a board whose entire purpose is telling
somebody where their request is.

### CREATE

- [x] `Get-DefaultAsanaStageMap` + `Get-StageMapNumbers` + `Get-WritableStages` -- seven named stages,
      five of them writable
- [x] `Test-AsanaStageMap` -- refuses a missing, non-numeric or duplicated stage, all three of which
      are silent at runtime (a missing key reads as section 0)
- [x] `Resolve-AsanaStageMap` -- reads `Get-AsanaStageMap` from the consumer's `scripts/repo-config.ps1`,
      falls back to the default with a line saying why, and never throws
- [x] `Resolve-TargetStage` -- the label outranks the issue state; returns `AllowBackward` and a `Why`
      so every move in the log is attributable
- [x] `Get-StageFloorForIssue` re-expressed against the map; a merged PR now floors at `InReview`
- [x] `Sync-AsanaTaskStage`: takes the map, holds a card in an **unmapped** column, and holds
      `Completed` by name rather than by `>= 6`
- [x] `Get-IssueLinkState`: the same GraphQL query now also returns the issue's labels
- [x] `-Event` accepts `labeled`/`unlabeled`, which move the card and post no comment
- [x] `asana-mirror.yml`: those two event types, with the reason for the asymmetry on the line above
- [x] `WORKFLOW-portable.md`: step 6 rewritten in four sub-sections; step 7 gained three person-steps;
      four new entries under "why it is shaped this way"
- [x] `README.md`, `report-issue`, `adopt-bwj-asana`: stage NAMES instead of numbers throughout, the
      new seam, and the `needs-info` label
- [x] The three stale `#6-...six-stages` anchors repointed
- [~] Renaming the board's sections -- **not this branch's to do.** Dave named them himself; the map
      is the mechanism for adapting to his names, which is the whole point of it.

### TEST

- [x] `bwj-codex.tests.ps1`: 152 asserts, up from 128
- [x] **The map is exercised against a board numbered 10/20/30/40/50/60/70**, so it cannot quietly
      become decoration over literals -- the default `Filed` number is asserted *not* writable there
- [x] `Get-StageFloorForIssue` is asserted never to derive `InDevelopment`, which is the design
- [x] All four backward/forward cases: label present, label removed, reopen, and a label on an issue
      whose own state derives nothing
- [x] The script parses, is pure ASCII, and dot-sources without running its main flow
- [x] `check-plugin-integrity.ps1`: 0 errors
- [~] An end-to-end run against the live board -- not here. It needs `ASANA_PAT` in a store repo's CI,
      and this repo is not a consumer of `bwj-codex`.

### DEPLOY: `feat/asana-stage-map-seam-v1`

The stage model shipped with its meanings written as literals, and the board it was written against
changed shape the same afternoon -- a column added in the middle, moving every stage above it by one.
Nothing failed: the sweep would simply have filed every card a column early, on a board whose entire
purpose is telling somebody where their request is.

So the model now separates two questions that looked like one. **Which column is this?** is still
answered by the number a section's name starts with -- unchanged, and still what lets the team rename
a column freely. **What does that column mean?** is answered by the repo, in `Get-AsanaStageMap`, with
semantic keys rather than GIDs so a rebuilt column costs nothing. A repo that states no map gets the
built-in one and the run says which it read. **And a column the map does not name is now a hold** --
not a target and not a source -- so the next board that grows a section has cards that stop moving
rather than cards in the wrong place.

The blocked column is label-driven: while `needs-info` is on an issue the card stays there whatever
the branch and the pull request are doing, because the person who set it knows something the tracker
does not. That makes it the second of exactly two answers allowed to move a card backward, beside an
issue being reopened -- and it is why `labeled`/`unlabeled` now fire the workflow, moving the card
without commenting, since a label is a change in our state rather than news for the submitter.

**Score:** 3

#### What makes this deploy extra special

A consuming repo can now describe its own board instead of being described by the plugin. The seam is
optional and the default still works, so nothing breaks by ignoring it -- but a repo whose board is
numbered any other way needs it, and this release is the first that lets it say so.

**The failure it removes is the silent kind.** Before this, adapting the plugin to a board meant
editing the shipped script, which the drift lint would then flag forever; and a board that changed
shape produced no error at all, just cards a column out. After it, an unrecognised column stops the
card instead of moving it somewhere plausible.

**Score:** 3

#### Pull Request

the stage map becomes a repo seam, and Need more info is label-driven

