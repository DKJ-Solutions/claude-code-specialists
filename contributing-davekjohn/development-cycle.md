## Development cycle: `fix/convergence-advice-waits-for-the-seam-v1` · 20260827-183745

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

Inbound #994: shopify-floor-sessioncheck's duplicate-guard advice calls the shipped guard the superset unconditionally, but that only holds once the repo has answered Get-ShopifyLiveThemeId. Unanswered, the shipped guard does not recognise the live theme BY ID -- so a hand-written guard that does is complementary, not a subset, and following the advice opens the push-at-the-live-id vector on an ERROR that calls removal a safety improvement.

### CREATE

- [x] Verify the report against the tree. It stands exactly as written: the advice is an independent
      `if ($dupes.Count -gt 0)`, nothing above it consults the seam, and the file's own header at line 14
      states the consequence -- a repo that never answered `Get-ShopifyLiveThemeId` has a guard that does
      not recognise a push aimed at live BY ID.
- [x] Measure the finding's real size rather than taking the report's. It named the hook; the same
      unconditional superset claim is in `plugins/teams/team-shopify/README.md`, and the hook's own
      message sends the reader there. Fixing one and leaving the other would have shipped the defect in
      the document the message points at.
- [x] Split the advice on `$liveId`, which the script already computes 60 lines above -- answered, the
      current text; unanswered, answer the seam first and why.
- [x] Give the README's convergence route a **step 0** (answer the seam) and condition the superset
      sentence, quoting what it used to say.
- [x] Write `scripts/tests/shopify-floor-sessioncheck.tests.ps1`: the hook had no suite at all.

### TEST

- [x] Both branches run end to end against a scratch fixture repo, not reasoned about: with `VUL-IN` the
      message says **ANSWER Get-ShopifyLiveThemeId BEFORE YOU CONVERGE**; with `190793613653` it makes
      the superset claim and sends them to converge.
- [x] The new suite: **18 pass, 0 fail** -- both seam states with a duplicate, both without one, the
      placeholder-counts-as-unanswered path, and the never-bootstrapped repo.
- [x] **And the suite was run against the PRE-FIX hook to prove it catches the regression**, because a
      test that passes on both versions pins nothing: **15 pass, 3 fail**, and the three are exactly the
      asserts about the gated branch. A test whose failure has been seen is the only kind worth adding.
- [x] The hook parses clean (`[Parser]::ParseFile`), and there is exactly one copy of it in the tree --
      no mirror to keep in step.
- [x] The full gate (`check-plugin-integrity.ps1` + all suites) via `open-pr`.

### DEPLOY: `fix/convergence-advice-waits-for-the-seam-v1`

The Shopify floor session check told a repo with a second, hand-written live-theme guard to remove it,
calling the shipped guard **the superset** and the removal *"a safety improvement rather than
housekeeping"* -- unconditionally. That claim only holds once the repo has answered
`Get-ShopifyLiveThemeId`. Until then the shipped guard's third rule recognises a push aimed at live
**by id** not at all, so a hand-written guard that does know the id is covering a case the shipped one
is not: the two are complementary, not superset and subset. The advice is gated on the seam now, and the
unanswered branch says to answer it first and why. The same unconditional sentence in the team-shopify
README gets the same condition, plus a **step 0** at the head of its convergence route.

**Score:** 3

#### What makes this deploy extra special

**The superset argument was about the matcher; the gap is in the rules, and that is the whole confusion.**
`Bash|PowerShell` versus `Bash` says which commands a guard inspects. The live-id trigger says which
commands it refuses. A guard can be narrower in the first and wider in the second at once -- which is
precisely what an unanswered seam produces -- so the two claims never composed into "superset" the way
the sentence assumed.

**The failure direction is silent, which is why this is worth more than a wording fix.** Follow the old
advice with the seam unanswered and nothing breaks: the hook keeps running, the guard keeps blocking
publish, delete and `--allow-live`, every session start stays quiet. Only a push naming live by its
number starts getting through, and nothing announces it. Neither consumer is exposed today -- both have
answered the seam -- so this is about the next repo to install the plugin, not a live incident.

**The hook had no test suite; it has one now, and its failure has been seen.** 18 asserts, and the three
that matter were confirmed red against the pre-fix hook before being confirmed green against this one.
That ordering is the point: an assert nobody has watched fail is a claim, not a test.

**Score:** 4

#### Pull Request

the live-theme convergence advice states its condition instead of an unconditional superset

Plugins: team-shopify