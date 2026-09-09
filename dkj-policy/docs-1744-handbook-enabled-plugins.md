## docs/1744-handbook-enabled-plugins

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

#### What #1744 reported, and what the tree said

The handbook closed its scaffold paragraph with *"The add-on teams `dkj-team-lifehub` and
`dkj-team-shopify` are **off** here"*. Verified as still standing at pickup, and three documents
contradict it -- one of them the machine state: [`../.claude/settings.json`](../.claude/settings.json)
enables all six plugins, [`../CLAUDE.md`](../CLAUDE.md) carries Dave's September 8, 2026 decision that
this repo enables EVERY plugin in the marketplace, and
[`../.claude/specialists/SPECIALISTS.md`](../.claude/specialists/SPECIALISTS.md) calls the three add-on
teams *"enabled here for validation only"* with their eleven empty lenses *"the intended state, not a
backlog item"*. The sentence also named two add-on teams where there are three.

#### The repair is to carry the distinction over, not to strike a sentence

The paragraph that sentence closes explains why some lenses are empty, and with every plugin enabled
that explanation got sharper rather than disappearing: the six core-team scaffolds are WAITING, and the
eleven add-on ones will STAY empty. Striking the clause would leave the six unexplained and the eleven
unmentioned.

#### The report asked for the rest of the page, and the same failure was in five more places

Found by reading, not by a check, so the page was read end to end. Every instance is the same stale
premise -- that `dkj-team-alpha` is the only plugin enabled here:

- the outlier note (l. 10-16): *"consumes that system here itself, via the `dkj-team-alpha` plugin"*
- the subagent-lens definition (l. 36): *"the fifteen specialists that come out of the `dkj-team-alpha`
  plugin"* -- a count correct for the core team alone, describing a KIND of lens that 26 files now are
- the agent-def bullet (l. 55-59): all agent defs attributed to `dkj-team-alpha`
- the `settings.json` bullet (l. 62): `enabledPlugins` spelled as the single entry it used to hold
- the index table's claim (l. 226): *"Every specialist the enabled plugin ships has a lens file, so this
  table is complete"* -- singular, and the table is 19 rows against 30 files in `lenses/`

#### Two counts were replaced rather than corrected

*"the fifteen specialists"* and the `enabledPlugins` spelling are both figures this page nothing
regenerates -- the exact class its own *"A measurement in a document that nothing regenerates goes stale
silently"* warns about, and the class that produced this issue. Both now point at the file that holds the
answer instead of restating it, so the next plugin cannot make them wrong.

### CREATE

- [x] Verify #1744's symptom, reason, repair, size, subject and repo against the tree before routing
- [x] Repair the reported sentence, carrying `SPECIALISTS.md`'s distinction (waiting vs. staying empty)
- [x] Repair the five further instances of the same stale premise on the same page
- [x] Replace the two stale counts with a pointer to the file that holds the answer
- [x] Correct the four `DaveKJohn/` repo citations, under `CLAUDE.md`'s corrected-when-edited rule
- [x] Copy edit on the diff (Edith #17), held against `SPECIALISTS.md` and the repo slot of `CLAUDE.md`

### TEST

- [x] `check-plugin-integrity.ps1` green -- 0 errors; its 346-link scan is what proves the three new
      anchors resolve (`CLAUDE.md#specific-to-this-repo-claude-code-specialists`,
      `SPECIALISTS.md#the-team-roster--routing`, Chris's routing-table anchor)
- [x] All suites green via `open-pr.ps1`
- [~] No new test: the subject is prose on an on-demand page, and #1744 declines a gate holding prose
      about enabled plugins against `settings.json` -- it would have to recognise an enablement claim in
      free text, and the same words appear in correct sentences about what a CONSUMER enables

### DEPLOY: docs/1744-handbook-enabled-plugins

The specialists handbook no longer tells a session the add-on teams are off here. Six places on
[`../.claude/specialists/README.md`](../.claude/specialists/README.md) carried the same stale premise --
that `dkj-team-alpha` is the only plugin enabled -- and the reported sentence was the one a reader used
to explain the empty lenses, so the repair carries the distinction over instead of striking it: the six
core-team scaffolds are waiting, the eleven from the add-on teams will stay empty, and Chris routes to
none of the eleven. The index table now says it is the core team's rather than claiming to be complete,
which it was not -- 19 rows against 30 files in `lenses/`.

Two of the six were stale COUNTS rather than stale claims (*"the fifteen specialists"*, `enabledPlugins`
spelled as one entry) and both were replaced with a pointer to the file that holds the answer. That is
this page's own rule about measurements going stale silently, applied to the page -- and it is the half
that keeps the next plugin from reopening this issue.

**Score:** 3

#### What makes this deploy extra special

N/A -- `.claude/specialists/README.md` is this repo's own handbook and ships in no plugin, so nothing
here travels to a consumer. What a consumer holds is `SPECIALISTS.md`'s wording, which was already
correct and is what this page was reconciled TO.

**Score:** N/A

#### Pull Request

Reconcile the specialists handbook with every plugin being enabled here

