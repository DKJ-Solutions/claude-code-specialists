## feat/1869-consumer-divergence-check

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

#### What this branch is

Issue #1869 (inbound, from smartwatchbanden) reports that the two BWJ store repos maintain the same
mechanism layer twice. Triaged and verified before routing: the headline reproduces exactly from the
source repo (96 / 73 tooling files, 48 shared paths, 1 byte-identical, and that one is the plugin's own
`asana-mirror.ps1` template). Three per-file rows of its table were mis-sized and are corrected in a
comment on the issue; nothing that changes the verdict.

The report offers three repair shapes and says explicitly that the choice is the decision. Put to Dave
on 2026-09-11; he chose **detector first, converge afterwards**. This branch is the detector. Moving
ownership -- which of `dkj-policy` and `dkj-policy-bwj` should own `test-lib.ps1`, `lint-brain.ps1` and
the market/theme mechanisms -- is the follow-up and is deliberately not in scope here.

### CREATE

- [x] `scripts/lib/sibling-divergence-lib.ps1` -- the comparison as pure functions over inventories:
      path normalization, the comparable-root and by-design-exclusion rules, the ONLY-IN / PARTIAL /
      DRIFTED classification, and the capability-aliasing pass that finds one mechanism under two
      filenames.
- [x] `scripts/sync/check-consumer-siblings.ps1` -- the entry point: reads the register, groups by the
      declared `siblingGroup`, reads each member's tooling tree over `gh` or off a resolved
      `localCheckout`, and reports. Refuses nothing unless `-FailOnFinding`.
- [x] `connectors/smartwatchbanden.json` + `connectors/xoxowildhearts.json` -- `"siblingGroup": "bwj-store"`,
      the one piece of data the check reads. No other field touched, and nothing claimed about what
      either consumer HAS.
- [x] `Test-GitHubOwnerNameSlug` promoted from inside `check-connectors.ps1` into
      `scripts/lib/check-report-lib.ps1`, rather than copied into the second caller -- the case its own
      docstring already made. Plugin mirrors regenerated.
- [x] Docs: the register's page (the new field, the check, the three finding classes, what is excluded
      and why), `scripts/README.md`, and Sylvester's lens for the reasoning and the three decisions not
      to re-litigate.

### TEST

- [x] `scripts/tests/sibling-divergence.tests.ps1` -- 47 asserts over 10 cases. The ones that matter:
      case 3 holds the by-design exclusions (a false positive trains people to ignore the report), case 4
      holds the grouping being declared rather than inferred (the change somebody will reach for first,
      and wrong in a way no error would show), case 7 holds the PARTIAL class (the finding a binary
      vocabulary would drop silently), cases 9-10 hold the aliasing. No network and no fixture repos --
      the reading needs a network, the deciding does not, which is why the comparison lives in a lib.
- [x] Fixtures are synthetic: this repo is public and the consumers are private, so a fixture carrying
      real consumer content would publish it permanently to make an assert a made-up filename makes just
      as well.
- [x] Run against the live register: reports 93 findings across the declared `bwj-store` group, and the
      alias pass finds both pairs #1869 named by hand -- `market-domains.ps1` <-> `market-urls.ps1` on two
      shared function names, and `archive-and-remove-theme.ps1` <-> `archive-theme.ps1` on one.
- [x] Lint gate + full suite green.

### DEPLOY: feat/1869-consumer-divergence-check

The connector register can now answer the question it was asked for. `check-consumer-siblings.ps1`
compares the tooling layers of consumers that declare a shared `siblingGroup` and reports three classes:
`ONLY-IN` (a mechanism one has and the other does not), `DRIFTED` (two copies of one mechanism that have
grown apart) and `ALIASED` (one capability under two filenames -- the class no path comparison can make).

Every other check here runs source-to-consumer. This is the first that runs consumer-to-consumer, and
#1869 measured what that axis was hiding: of the 48 tooling paths the two BWJ stores share, 47 have
diverged, and the only one that has not is a template this marketplace ships. `prune-merged.ps1` is the
argument in one file -- shipped centrally in `dkj-policy` 4.21.0, adopted by one store and not the other
three weeks later, with nothing watching the gap.

It reports and refuses nothing. Converging is an ownership decision, not a repair a script can make.

**Score:** 4

#### What makes this deploy extra special

N/A -- nothing here reaches a subscriber of a service. The register, the check and the group label are
internal maintenance machinery of this marketplace, and the two consumers it compares are private repos
whose own tooling is unchanged by this branch.

**Score:** N/A

#### Pull Request

Report mechanisms a sibling consumer has and this one does not
