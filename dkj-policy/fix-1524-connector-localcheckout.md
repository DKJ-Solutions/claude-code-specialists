## fix/1524-connector-localcheckout

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

Issue [#1524](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1524): both BWJ manifests
record a `../../davekokbwj/<repo>` checkout that does not exist, so `check-connectors.ps1` reports
`[SKIP] ... not present on this machine` -- a sentence that asserts an absence which is false, exits 0,
and suppresses the whole connector block.

#### The reason was verified before the repair, and it changed the repair

The report's symptom stands. Its **proposed repair does not**, and the report itself flagged the reason
as unmeasured: *"Whether `davekokbwj/` is the correct path on another machine. `connectors/README.md`
treats `localCheckout` as a single per-manifest value, so if the two machines differ this is a design
question rather than a typo."*

Measured on this machine, September 6, 2026: both BWJ checkouts are present, one folder structure over
from the one the report measured. Relative to this repo's root the path here is
`../../GitHub/bwjecommerce/<repo>`; on the reporting machine it is `../../bwjecommerce/<repo>`. Neither
is `davekokbwj/`, and **no single string is true on both**. So writing the reported machine's answer in
would have satisfied the report and left the identical false `[SKIP]` standing here -- the defect moved,
not closed.

- [x] Verify the symptom, the reason and the proposed repair against this tree -- done, and the repair
      changed as a result (above).
- [~] File the design question as a separate issue -- dropped: it is not a finding beside the work, it
      *is* what the work turns on, and #1524 already names it as the open question.

### CREATE

- [x] `scripts/sync/check-connectors.ps1`: `localCheckout` accepts one relative path or a list of
      candidates; the first present on this machine wins, and the guardrails (absolute path, scope
      root) apply to the field rather than to its first element. An empty list is rejected as
      malformed rather than reported as an absent checkout.
- [x] The `[SKIP]` names **every** candidate, so a register stale about this machine's layout reads
      differently from a checkout that is genuinely absent.
- [x] `connectors/smartwatchbanden.json` + `connectors/xoxowildhearts.json`: both record the two
      measured layouts, with the measurement appended to `notes` -- the dated 2026-08-09 sentence
      claiming `davekokbwj/` is correct keeps its wording and is corrected by the new paragraph.
- [x] `connectors/README.md`: the field's list form, the reason it is a list rather than one machine's
      answer, and the privacy boundary re-stated for a field that can now name several layouts.

### TEST

- [x] Four new cases in `scripts/tests/connectors.tests.ps1`: a list with none present (SKIP naming
      all candidates), a list whose later candidate resolves (not skipped), an absolute path in the
      second position (rejected), and an empty list (rejected). 178 pass, 0 fail.
- [x] The suite's manifest fixture takes `localCheckout` untyped, so the plain-string form -- what
      every manifest but the two BWJ ones still carries -- keeps being exercised.
- [x] Measured on this machine: `check-connectors.ps1` no longer skips either BWJ connector. Both are
      now actually checked, exit 0, and what the false skip had been hiding surfaces -- four `[INFO]`
      lines about retired plugin ids and a drift check reading 26 missing agent-defs. Those belong to
      [#1523](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1523) (the register stale
      in its plugin **ids**) and are deliberately left to it: this branch makes them visible, which is
      the whole point, and does not touch them.
- [x] Lint gate + all suites green before the PR.

### DEPLOY: fix/1524-connector-localcheckout

A connector manifest's `localCheckout` may now name several candidate relative paths, and both BWJ
manifests record the two layouts that were actually measured. The check takes the first candidate
present on the machine running it and, where none resolves, names all of them in the `[SKIP]`.

This closes a defect whose cost was invisible by construction. A checkout path that does not resolve is
not reported as wrong -- it is reported as `[SKIP] checkout ... not present on this machine`, which
asserts an absence, exits 0, and suppresses everything that connector would have said. On the machine
[#1524](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1524) was measured from, one
such skip covered four `[INFO]` lines and a drift check reading 26 missing agent-defs. The list exists
rather than one corrected string because the two machines holding those checkouts place them
differently, so any single value is false on one of them -- which would have moved the false skip
instead of removing it.

**Score:** 3

#### What makes this deploy extra special

N/A -- the connector register is this repo's own bookkeeping about its consumers. It changes nothing a
subscriber of a service could notice.

**Score:** N/A

#### Pull Request

connectors: localCheckout accepts per-machine candidate paths, and both BWJ manifests record the real ones
