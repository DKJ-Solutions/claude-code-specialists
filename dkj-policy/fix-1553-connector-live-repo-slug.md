## fix/1553-connector-live-repo-slug

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

Inbound [#1553](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1553): the register's
live `repo` field names an archived repo. The org move was only ever noted in a comment on
[#1523](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1523), and that comment closed
with the issue.

#### Verified before it was repaired, and one half of it turned out to be the smaller half

The symptom stands. Re-measured 2026-09-07 from this checkout:
`BWJ-ecommerce/smartwatchbanden` -> `isArchived: true` (last pushed 09:18:59Z),
`BWJ-Development/smartwatchbanden` -> `isArchived: false` (last pushed 17:57:28Z) -- still being pushed
to hours after the archived one stopped, so the live consumer is unambiguous. A fresh repo rather than
a transfer, so no redirect stands behind the old name.

**The report's own explicitly unmeasured question is answered rather than left open**, and it decides
the size of this branch. #1553 asked whether anything downstream of the register actually fetches by
that slug and would therefore now read the archived repo rather than fail -- naming that as the
question that decides whether this is bookkeeping or a wrong answer, and saying it had not been chased.

Chased: it is bookkeeping. `check-connectors.ps1` reads the field in four places and resolves it in
none -- the `== connector:` header, the connector label that disambiguates a two-consumer run, and
`checkedConsumers`, whose value supplies the drift-check header and the finding scope. All four are
display. So no check was reading the archived repo; a label was reading wrong. That is why this is a
one-field data correction and **not** a repair to the checker.

### CREATE

- [x] `connectors/smartwatchbanden.json`: `repo` -> `BWJ-Development/smartwatchbanden`.
- [x] A dated `CORRECTED 2026-09-07 (#1553)` sentence appended to `notes`, carrying the measurement,
      why the class is silent, the answer to the report's open question, and why the register heard
      about the move late.
- [x] Read back through `ConvertFrom-Json` after the hand edit -- nothing in this repo parses this file
      until somebody's session start does, so the parse happens here instead.

#### What was deliberately NOT touched

- [~] Every other `BWJ-ecommerce/smartwatchbanden` in the tree is a **dated measurement** ("measured in
      BWJ-ecommerce/smartwatchbanden on September 1, 2026") or a link to a PR or issue that genuinely
      lives in the archived repo. Both keep the names they were written with, per
      [#952](https://github.com/DKJ-Solutions/claude-code-specialists/issues/952) and the repo-citation
      rule in `CLAUDE.md`. Rewriting one to match today's answer is the defect #952 was made of.
- [~] `connectors/xoxowildhearts.json` still names `BWJ-ecommerce/xoxowildhearts`, and that field is
      currently **correct**: not archived, pushed 2026-09-07T14:40:18Z. A
      `BWJ-Development/xoxowildhearts` also exists (pushed 13:18:54Z), so that store may be mid-move --
      the owner's call, and #1553 scopes it out explicitly.
- [~] The plugin's live scope prose was checked and needed nothing: `report-issue/SKILL.md` and
      `adopt-dkj-policy-bwj/SKILL.md` already name the move. That was
      [#1537](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1537), now closed. Worth
      recording because the skill listing a session reads comes from the **plugin cache**, which still
      carries the 4.31.0 wording -- so the stale text is real in a session and already repaired at the
      source, which is the ordinary lag rather than a finding.
- [~] No detection was added. Nothing here resolves a slug against GitHub, by standing decision, and
      #1553 did not ask for that to change.

### TEST

- [x] `ConvertFrom-Json` round trip on the edited manifest -- `repo` reads back as
      `BWJ-Development/smartwatchbanden`, `notes` at 9131 chars.
- [x] `scripts/sync/check-connectors.ps1` -- no errors.
- [x] `scripts/lint/check-plugin-integrity.ps1` + the full test gate, via `open-pr.ps1`.

### DEPLOY: fix/1553-connector-live-repo-slug

The connector register points at the live `smartwatchbanden` repo again. `smartwatchbanden` moved out
of `BWJ-ecommerce` into `BWJ-Development` as a **fresh** repo rather than a transfer -- so the old name
has no redirect behind it, and the `BWJ-ecommerce` original is archived. The register's `repo` field is
a live field, not a dated measurement, and it still named the archived one.

It read wrong rather than answering wrong, and the branch says so in the register itself instead of
leaving it to be re-measured: the field is used only as a label -- the connector header, the
two-consumer disambiguator, and the drift-check scope -- and is resolved against GitHub nowhere. That
was the open question #1553 filed alongside the symptom, and it is what keeps this to one field.

The reason it went unnoticed is worth more than the field. Nothing in this register resolves a slug
against GitHub, which the 2026-08-09 note already stated, so a stale slug is never reported as *wrong*
-- it is simply never checked. That is the same silent class the `localCheckout` correction
([#1524](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1524)) recorded for a
different field of the same file: a value that fails by asserting something false and exiting 0.

**Score:** 2

#### What makes this deploy extra special

It is a lesson about where a finding is allowed to live. The move was raised as a **comment** on #1523
-- correct at the time, to avoid duplicating #1537 -- and when #1523 was closed for the plugin-id
renames it was actually about, the comment closed with it and nothing open carried the move any more.
A finding parked on somebody else's thread inherits that thread's lifetime, and this one outlived its
host by a day.

**Score:** 2

#### Pull Request

connectors/smartwatchbanden.json points at the live BWJ-Development repo, since the BWJ-ecommerce one is archived
