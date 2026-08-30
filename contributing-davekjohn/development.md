## Development: `docs/pr-template-interface-is-the-placeholder-v1` · 20260830-110256

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

#### What inbound #1128 reports, and what verifying it added

`CONTRIBUTING-portable.md` describes the PR template's interface as **two lines** -- a first heading and
a placeholder line -- and warns that breaking either silently costs you every PR description. Three
things in the tree disagree, all on the plugin's own side: the shipped reference is one line with zero
headings, this repo's `.github/pull_request_template.md` is byte-identical to it, and `open-pr.ps1`
supports `$descHeading = ''` on purpose and records the migration away from the first-heading rule
(#865, #598) in its own comments.

Verified before routing; all three stand. The lint gate already knows -- check 24's own comment says
*"THE CONTRACT LOST ITS SECOND HALF ON AUGUST 24, 2026 ... a heading-less template is a supported
shape"* -- so the doc layer is the only place still carrying the retired rule.

#### The reach is wider than the report measured, and every extra place is portable

The paragraph sends the reader to the `open-pr` skill for the detail, so repairing only the paragraph
moves the contradiction one hop instead of removing it. That skill states the retired rule twice, states
a behaviour that is now false (*"If your template has no heading at all, the switch warns and changes
nothing"* -- that warning is for a MISSING template, not a heading-less one), and counts the recognised
placeholder strings at three where the list holds twelve.

#### What is deliberately NOT touched

- `scripts/lint/check-plugin-integrity.ps1` and its suite keep the label *"the two promises"*: there the
  two are the two FILES held to two different strengths, and both already record in so many words that
  the heading half is retired.
- The archived release notes under `contributing-davekjohn/releases/` describe what was true when they
  were cut, and read as history.

### CREATE

- [x] `CONTRIBUTING-portable.md`: the interface paragraph -- the placeholder is the one line, later
      headings are boundaries `-RefreshBody` will not cross, a template with no heading of its own is
      the normal shape
- [x] `skills/open-pr/SKILL.md`: the `-RefreshBody` heading rule (stated twice), the "two promises"
      section and its table, and the stale count of recognised placeholder strings
- [x] `plugins/workflows/contributing-davekjohn/README.md`: the `templates/` row pointing at "the two
      promises"
- [x] `.claude/specialists/lenses/05-15-extension.md`: check 24's contract, described there as "a first
      heading, a recognised placeholder"

### TEST

- [x] `check-plugin-integrity.ps1` green -- 0 errors, 303 links scanned
- [ ] All suites green

### DEPLOY: `docs/pr-template-interface-is-the-placeholder-v1`

`CONTRIBUTING-portable.md` told a consumer the PR template's interface was **two lines** — a first heading
and a placeholder — and warned that breaking either silently costs them every PR description. The heading
half came off on August 24, 2026 with #865, when `-RefreshBody` stopped reading "the first heading" and
started reading where the placeholder sits. The page never followed, so the paragraph that instructs a
consumer to *copy the shipped reference and diff against it* described a rule the reference itself breaks:
that file is one line, an HTML comment, with no heading at all. Every available reading was wrong — add a
heading the tooling does not want, treat the shipped reference as stale, or go read `open-pr.ps1` to find
out which of the two documents is lying.

**It demonstrably misled, which is the part worth having.** The testrun plan on #1079 — written by a
careful reader of exactly this page — states its assert as *"`.github/pull_request_template.md` from
`${CLAUDE_PLUGIN_ROOT}/templates/`, **with its first heading** and its placeholder line intact"*. That
assert cannot be satisfied by the file it names, and it sat there unsatisfiable until a run copied the
file and looked at it.

**The interface is now stated as one line, in all four places that describe it.** The placeholder is the
whole contract; a template carrying nothing else is the normal shape rather than a broken one; the
headings you add below it are the form's, and each is a boundary the refresh will not cross. The
`open-pr` skill gets the mechanism in full — the description sits under the **last** heading *above* the
placeholder, or is the body's leading section where there is none, and only a **missing** template makes
`-RefreshBody` warn and change nothing. That skill also stopped claiming the matcher compares against
*three* built-in strings, which has been twelve for some time and is now described by what the list is
(every placeholder this family has ever shipped, oldest first) rather than by a count that goes stale in
silence.

**Score:** 3

#### What makes this deploy extra special

N/A. This repo is the source of the plugin, not a subscriber to a service; the reader who gains is the
consumer adopting `contributing-davekjohn`, and they receive it through the next release rather than from
anything visible here.

**Score:** N/A

#### Pull Request

the PR template's interface is the placeholder line, and a heading-less template is the normal shape
