## docs/1686-priority-axis-decision

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
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

#1686 asked two questions and said both were Dave's. He is away, with a standing instruction that his
answer is *"I follow the specialist's advice here"* -- so both are decided here, and the grounds are
written into the docs rather than into a reply he would have to read back.

#### 1. The naming: the two sets stay apart

Not on preference. Three things, the first two measured:

- **The BWJ names are code, not convention.** `asana-mirror.ps1` holds them as a literal
  (`$script:PrioLabels = @('very low', 'low', 'high', 'very high')`), `Get-PrioLabelForScore` returns
  those exact strings from a score band, and `dkj-policy-bwj.tests.ps1` asserts every boundary from
  both sides. Unifying is not a rename: it edits a shipped CI mechanism running daily against two live
  stores, re-pins its suite, and renames labels on two live trackers this repo does not own.
- **The collision cannot mis-file anything.** `gh label list` on all three trackers in the family:
  this one carries only `prio-1`..`prio-4`, and **both** `BWJ-Development/smartwatchbanden` and
  `BWJ-ecommerce/xoxowildhearts` carry only the four words. The sets are disjoint in both directions,
  so the whole symptom is a refused label that names itself, plus one re-run.
- **The names are the only signal of which motor owns the rung.** One vocabulary would read as one
  mechanism, which is the more expensive mistake: a rung hand-typed in a BWJ repo is answering to a
  score nobody typed, and a derived rung is meaningless here, where there is no Asana.

#### 2. The reach: the rule stays repo-local

**Nothing in the workflow reads a priority.** Searched `scripts/`, `plugins/` and `.github/`: `prio-`
appears in no gate, no script and no runner here -- only on the BWJ side, where a shipped script owns
it. A portable version would prescribe to every consumer a convention nothing enforces (the
enforced-by-memory shape of #1665) and would owe `adopt-dkj-policy` a label-creation step for four
labels they never asked for. That is worse than #1540's trap: here a consumer *could* follow it and
would gain nothing.

The seam is named as the shape if that ever changes -- one `repo-config.ps1` function, like
`Get-ReleaseAudienceTier` -- and deliberately not built, because nothing reads it.

#### What was deliberately NOT touched

- **`01-01-extension.md`, the always-on half.** The decision changes nothing a session here must do,
  so the file every session pays for stays exactly as it is. A session working in this repo does not
  need to know the BWJ set exists; the one who does is on the other side of the family, and that is
  where the cross-reference went.
- **How recently either set was created.** `prio-1`..`prio-4` are a day older than this decision and
  the BWJ set a week. Neither is an argument, and the recorded reasoning does not lean on either.

#### Why one paragraph DID go into the portable page, which is not a contradiction

What stays repo-local is the **prescription** -- every issue here carries a rung. What went into
`WORKFLOW-portable.md` is the **fact** that two disjoint sets exist and that a refusal is therefore
expected rather than a broken setup. That is not a rule anybody has to follow, and its reader is a BWJ
session who would otherwise read `gh`'s refusal as misconfiguration. Said in the paragraph itself, so
a later reader does not have to reconstruct the distinction.

### CREATE

- [x] Measure both label sets, in both directions, on all three trackers -- the fact decision 1 turns on
- [x] Establish that nothing in this repo reads a priority label -- the fact decision 2 turns on
- [x] Replace the open question in [`05-05-extension.md`](../.claude/specialists/lenses/05-05-extension.md)
      (*"Whether the two should be unified is #1686, and it is Dave's call"*) with the decision and its grounds
- [x] One cross-reference paragraph in `dkj-policy-bwj`'s `WORKFLOW-portable.md` step 5, in that page's
      own `--` style, where the BWJ reader actually is

### TEST

- [x] The lint gate (`check-plugin-integrity.ps1`) -- dead links, anchors, mojibake
- [ ] Copy edit (Edith #17) and conclusion red-team (Marlowe #29) on the diff

### DEPLOY: docs/1686-priority-axis-decision

The priority axis exists twice in this family and now says so on purpose. The two schemes -- `prio-1`
to `prio-4` here, `very low` to `very high` in the BWJ store repos -- stay apart, because the names are
the only thing that says which motor owns the rung: one is a judgement typed by whoever files, the
other is derived from an Asana score by a daily sweep, and a single vocabulary would invite a session
to hand-set a rung that a sweep is about to overwrite. Measured on all three trackers, the two sets are
disjoint in both directions, so the collision the issue was filed about can only ever produce a refused
label that names itself -- not an issue filed at a rung meaning something else. And the rule that every
issue carries a rung stays this repo's own: nothing in the workflow reads a priority, so a portable
version would prescribe a convention no gate enforces and hand consumers four labels they never asked
for.

**Score:** 2

#### What makes this deploy extra special

One paragraph reaches a consumer, and it is the half worth having: a BWJ session that reaches for
`prio-4` and gets a refusal now reads that as the expected answer rather than as a broken setup, and
is told in the same breath that nothing on their side needs doing. The rule itself deliberately did
not become theirs to follow.

**Score:** 2

#### Pull Request

The two priority label sets stay apart, and the rule stays repo-local
