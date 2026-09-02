## Development: `docs/prio-label-workspace-limit-v1` · 20260902-094251

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

Closes [#1213](https://github.com/DaveKJohn/claude-code-specialists/issues/1213), and only the half of
it that lives in this tree.

#### What the issue asked, and what is answerable here

#1213 names two decisions. The first -- repointing both store repos' `Get-AsanaProjectGid` and their
`ASANA_PROJECT_GID` variable at the Workload Overview board -- is a **consumer** change plus two Actions
variables, so it is Dave's word and not this repo's files. Grepped to be sure: neither placeholder GID
nor the word `PROVISIONAL` appears anywhere outside archived release notes. That half stays on #1213.

The second is answerable here: `WORKFLOW-portable.md` step 5 states that the sweep needs no
`ASANA_PROJECT_GID`, which is true, and says nothing about a self-filed ticket being unscoreable, which
is also true and more surprising. This branch writes the second half in, at the four sites a reader
meets it.

#### Verified before writing, not after

- **The mechanism holds.** `Get-PrioScoreFromTask` matches the score field **by name** on the task's own
  `custom_fields` (`templates/asana-mirror.ps1`), and the parameter's own comment already says *"its GID
  differs per workspace"*. A task outside the board's workspace therefore has no such field -- the code
  assumes the very fact the issue infers.
- **The inference stays labelled as one.** The issue could not read the 7 self-filed tasks (`Not
  Authorized` on the whole workspace), so it could not measure that they carry no score. Every site
  below says the workspace boundary is the *reading* of why, and names the token boundary as the rival
  cause that could not be separated from outside. Writing it as measured would have been the citation
  failure the repo's own inbound rule warns about.

### CREATE

- [x] `WORKFLOW-portable.md` step 5: two paragraphs after the "walks GitHub, not the Asana project"
      one -- the field belongs to one workspace, so the two populations come apart, and the project GID
      therefore has an answer it did not have before. Carries the September 2, 2026 measurement and
      labels the inference.
- [x] `WORKFLOW-portable.md` step 6, "The Asana project answer": the one-vs-two-projects choice now has
      a constraint -- either shape has to sit in the workspace that defines `Prio-Score`.
- [x] `skills/adopt-bwj-asana/SKILL.md` step 2: the adopting session says the constraint out loud when
      it proposes the seam, because that is where the value is actually chosen and it is not guessable
      from the two function stubs.
- [x] `README.md`, the seam list: `Get-AsanaProjectGid`'s line names the requirement in one clause.
- [x] `templates/asana-mirror.ps1`, `Get-PrioScoreFromTask`'s comment: the workspace fact was already
      half-written there; it now says whose problem the consequence is (the caller's) and what it costs.

### TEST

- [x] `check-plugin-integrity.ps1` -- manifests, frontmatter and dead links, including the new
      cross-file anchors.
- [x] All suites in `scripts/tests/`, as CI runs them.

### DEPLOY: `docs/prio-label-workspace-limit-v1`

Step 5 of the BWJ workflow page now states the limit that decides whether the prio labels reach
anything: **`Prio-Score` is a field of one Asana workspace and does not cross into another.** The page
already said the sweep needs no `ASANA_PROJECT_GID` -- true, and the reason the labels work at all
today. What it did not say is the surprising half: a ticket the workflow **files itself** lands in
whatever `Get-AsanaProjectGid` points at, and where that project sits in another workspace, its task has
no `Prio-Score` to read -- not an empty one, none. So a provisional project GID costs an imported ticket
nothing and costs a self-filed one every label it could have had.

Measured across both BWJ stores on September 2, 2026, the day after the labels shipped: of the 12 open
issues that resolved to a task, every one that came away with a label was imported from the board, and
no self-filed ticket was labelled in either repo. The workspace boundary is the *reading* of why, and
the page says so -- the same self-filed tasks were unreadable to that session's token, and from outside
the two causes cannot be told apart.

The statement lands at the four sites a reader actually meets it: step 5, step 6's "Asana project
answer" bullet, the `adopt-bwj-asana` step that proposes the seam, and the seam list in the plugin
README. `Get-PrioScoreFromTask`'s comment in the template picks up the other end -- it already noted
that the field's GID differs per workspace, and now says whose problem that is.

**Nothing about the mechanism changed**, and the repointing #1213 also asks for is not here: that is a
consumer change plus two Actions variables, and it stays on the issue.

**Score:** 3

#### What makes this deploy extra special

A subscriber who has set `ASANA_PROJECT_GID` to something provisional can now find out what it costs
them, from the page, instead of discovering it by watching a daily run label only the imported half of
their board. That reverses the shape of the surprise: the limit was live in both stores before anyone
had written it down, which is the state a portable page exists to prevent.

**Score:** 3

#### Pull Request

step 5 names the workspace the prio field cannot cross

