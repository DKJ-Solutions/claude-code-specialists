## docs/1587-staleness-source-of-truth

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

- [x] Verify the reported defect against the tree: read `dkj-policy/README.md` lines 96-113,
  `connectors/README.md` (the manifest format, "no version bookkeeping" decision, and check 4's
  `[NOT-INSTALLED-HERE]`/inert-machine cases), and `scripts/sync/check-connectors.ps1`'s docstring.
  Confirmed all three claimed errors: no manifest field stores a version, the July 20, 2026 removal is
  real, and the comparison reads the machine's own `installed_plugins.json` record with the register
  supplying only `localCheckout`.
- [x] Searched the rest of `dkj-policy/README.md` for a second passage resting on the same false
  premise (a stored/last-seen version in the register). The other two "version" mentions (the
  no-version-check-between-releases line and the "why the version number is not the code you are
  running" pointer) do not claim the register stores anything — no second occurrence found.

### CREATE

- [x] Replaced the false paragraph (former lines 102-106) in `dkj-policy/README.md` with a corrected
  one: the machine's own install record is the authority, the register's only contribution is
  `localCheckout`, no manifest stores a version (linked to `connectors/README.md`'s manifest-format
  section rather than restated), the surviving true claims (`connector-sessioncheck` reports every
  lagging consumer at session start, `check-connectors.ps1` is the deliberate full run, a lagging
  checkout reports a plausible version and works) are kept, and the inert case — no verified source
  checkout on the machine means the check is skipped, so silence there is not "up to date" — is named
  and cited to #1587.

### TEST

- [~] No suite: this is a prose correction to `dkj-policy/README.md` with no code behind it. The
  standing dead-link and mojibake checks in `check-plugin-integrity.ps1` run at `open-pr` and are the
  only automated coverage this text is subject to.

### DEPLOY: docs/1587-staleness-source-of-truth

`dkj-policy/README.md`'s staleness paragraph claimed a connector manifest "carries the version its
record was last seen on." No manifest field has ever stored a version — that bookkeeping was removed
by decision on July 20, 2026 (see [`connectors/README.md`](../connectors/README.md#the-manifest-format))
— and the actual mechanism reads the version installed on that machine from its own
`installed_plugins.json` record and compares it to the source checkout's `plugin.json`; the register's
only part in that is `localCheckout`, i.e. which machine record to read. The rewritten paragraph keeps
what was true (`connector-sessioncheck` still reports every lagging consumer at session start, and
`check-connectors.ps1` is still the deliberate full run, because the lagging checkout itself reports a
plausible version and works) and adds the case the old wording missed: with no verified source checkout
on the machine, the check is skipped outright, so silence there is not "up to date" — it is no verdict
at all. No other passage in the file rested on the same false premise.

**Score:** 2

#### What makes this deploy extra special

N/A -- this corrects one paragraph's wording about an internal maintenance mechanism (the connector
register and the staleness check). No subscriber of a service reaches this page or is affected by
whether the mechanism is described accurately.

**Score:** N/A

#### Pull Request

Describe the plugin-staleness mechanism as it actually works

