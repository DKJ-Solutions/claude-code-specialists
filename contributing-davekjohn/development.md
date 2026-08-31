## Development: `fix/checkout-v5-node20-deprecation-v1` · 20260831-220808

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

Consumer BWJ-ecommerce/smartwatchbanden (inbound #1175) sees a Node 20 deprecation notice on every asana-mirror run, because workflow-bwj's asana-mirror.yml template pins actions/checkout@v4, which targets Node 20. GitHub force-runs it on Node 24. Bump that template to @v5, and the same one-line bump on the other shared workflow templates that pin @v4: the repo's own .github/workflows/ci.yml and branch-entry.yml, and the branch-entry.yml body that adopt-workflow-folder.ps1 scaffolds into a consumer (both the scripts/ copy and its byte-identical plugins/ mirror). Noise-reduction, not a failure fix.

### CREATE

- [x] Bump `actions/checkout@v4` -> `@v5` in `plugins/workflows/workflow-bwj/templates/asana-mirror.yml` (the file inbound #1175 names -- the only `workflow-bwj` file a consumer copies).
- [x] Same one-line bump on the repo's own CI that pinned `@v4`: `.github/workflows/ci.yml` and `.github/workflows/branch-entry.yml`.
- [x] Same bump in the `branch-entry.yml` body that `adopt-workflow-folder.ps1` scaffolds into a consumer (two `checkout` steps), in both `scripts/task/adopt-workflow-folder.ps1` and its byte-identical mirror `plugins/workflows/contributing-davekjohn/scripts/task/adopt-workflow-folder.ps1`; the two stay identical (verified with `diff`).
- [x] Confirmed no `actions/checkout@v4` remains anywhere in the tree. `adopt-shopify-floor.ps1`'s `@v7` is a separate `team-shopify` matter, out of scope here.

### TEST

- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 error(s).
- [x] All `scripts/tests/*.tests.ps1` suites -- green (same set CI runs).

### DEPLOY: `fix/checkout-v5-node20-deprecation-v1`

`actions/checkout@v4` targets Node 20, which GitHub now force-runs on Node 24 while emitting a
deprecation notice on every run. This bumps every `@v4` pin in the repo's shared workflow surface to
`@v5` (Node 24 native): the `workflow-bwj` `asana-mirror.yml` template a consumer copies, the repo's
own `ci.yml` and `branch-entry.yml`, and the `branch-entry.yml` body `adopt-workflow-folder.ps1`
scaffolds into a consumer (both the script and its plugin mirror). Behaviour is unchanged; the
Actions log loses the deprecation line.

**Score:** 1

Cosmetic today -- the runs still succeed. It forecloses one failure: when GitHub retires the Node 24
fallback for actions still targeting Node 20, every `@v4` `checkout` step stops running, and every
`asana-mirror` run plus this repo's CI would break until someone traced it to the pin.

#### What makes this deploy extra special

A `workflow-bwj` consumer who has copied `asana-mirror.yml` sees the deprecation line drop out of
their own Actions log (the reporter, BWJ-ecommerce/smartwatchbanden, filed it for exactly that), and
inherits the same foreclosed future break. Still cosmetic for them until that fallback is retired.

**Score:** 1

#### Pull Request

Bump actions/checkout@v4 to @v5 across shared workflow templates and CI

