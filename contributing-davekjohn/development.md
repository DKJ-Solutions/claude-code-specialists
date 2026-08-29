## Development: `docs/contributing-new-issue-task-chapter-v1` · 20260829-092256

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

#### What this branch is

`contributing-davekjohn/CONTRIBUTING.md` gains a chapter ahead of everything else: `## 1. NEW ISSUE /
TASK`, the layer *before* a branch exists. It has two headings and they are kinds rather than steps --
`### Human` (a colleague's ticket, arriving from a tracker outside the repo) and `### Claude` (how a
finding becomes a GitHub issue in this repo). The four steps that were 1-4 become 2-5, with every
substep, every cross-reference and every anchor moved with them.

`TICKETWORK-portable.md` in this repo's own plugin source is the rule half of the Human side, and
`davekokbwj/smartwatchbanden`'s `contributing-davekjohn/TICKETWORK.md` is a consumer's local half of it.
Neither is copied here: the chapter points at the first and states this repo's own answer, which is that
no tracker feeds it -- the same shape step 5 already uses for a live stage this repo does not have.

### CREATE

- [x] Renumber `CONTRIBUTING.md`: the four `##` steps, their `###`/`####` substeps, every dotted
      in-prose reference, the `#224-` anchor, and the bare `step 4` / `section 3` prose references --
      leaving `ship-pr.ps1 step 5` and every version number alone
- [x] Correct the intro's own count: `four numbered ## sections` becomes five, in the two places that
      state it, without rewriting the dated history that was true at four
- [x] Write `## 1. NEW ISSUE / TASK` with its `### Human` and `### Claude` halves
- [x] Follow the renumbering out of the file: `contributing-davekjohn/README.md` (the four numbered
      steps, `step 1.1`, `step 4` in the seam table) and the `#24-merge-the-pr` anchor in
      `.claude/specialists/lenses/05-05-extension.md`

### TEST

- [x] Every in-page anchor and every inbound link to a renumbered heading resolves --
      `check-plugin-integrity.ps1`'s dead-link scan is the measurement -- 298 links scanned, 0 findings
- [x] `check-plugin-integrity.ps1` clean and all 54 suites green

### DEPLOY: `docs/contributing-new-issue-task-chapter-v1`

`contributing-davekjohn/CONTRIBUTING.md` opens with a fifth step, written ahead of the four it had:
`## 1. NEW ISSUE / TASK`, the layer before a branch exists. It carries two headings that are **kinds rather
than steps** — the only `###` on the page with no number, because neither precedes the other. `### Human` is
ticket work: a colleague files in Asana, one GitHub issue per ticket carries the analysis, and the gate *do
we know enough?* decides whether it can be built at all — with the rules pointed at
`TICKETWORK-portable.md` and this repo's own answer stated, which is that nothing arrives that way here.
`### Claude` is the filing route: a finding leaves the session as an issue rather than as a question in the
close-out, what the bar is, how the four labels map onto the branch prefixes, and the six ways an inbound
report fails on pickup.

The page described the route from the branch onwards and said nothing about where the work came from, so
the one step a contributor could not look up was the first one. The four steps that were 1–4 are now 2–5,
with every substep, every in-prose reference and the two anchors pointing in from `README.md` and Derek's
lens moved with them.

**Score:** 3

#### What makes this deploy extra special

N/A — a contributor-facing page in the source repo. Nothing a subscriber of this system reads or runs
changes; the workflow plugin ships no new file and no script behaviour moved.

**Score:** N/A

#### Pull Request

A NEW ISSUE / TASK chapter opens CONTRIBUTING.md, and the four steps shift up
