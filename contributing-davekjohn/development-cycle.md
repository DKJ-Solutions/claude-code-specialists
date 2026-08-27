## Development cycle: `fix/the-source-test-means-what-its-name-says-v1` · 20260827-200903

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

Issue #998: Test-IsWorkflowSourceRepo tests 'publishes plugins'. Eleven sites use that one-file test for three different meanings. Collapse the three computed defaults so layout stops depending on it, remove the guard exemption whose stated reason died with them, narrow the function so its name is true, and repoint adopt-workflow-folder -- the one refusal that would block a genuine consumer.

### CREATE

- [x] Recount the finding in its own terms first. Issue #998 said "four sites read the current function".
      The one-file test appears at **eleven** sites, and the recount is what shaped the work: four call
      the function, six inline `Test-Path .claude-plugin/marketplace.json`, and they ask **three
      different questions** between them.
- [x] Classify all eleven by what each one MEANS, from the code rather than from the name -- see TEST.
- [x] Collapse the three computed defaults that still branched (`Get-DefaultChangelogPath`,
      `Get-DefaultReleaseHistoryPath`, `Get-DefaultReleaseInternalNotesRoot`), so the layout question
      stops consulting the test at all. #914 had already done this to the other two.
- [x] Remove the source exemption from `Assert-WorkflowIsolatedSeamPath`, whose stated reason was that a
      source's computed defaults ARE root files -- which the collapse above ends.
- [x] Narrow `Test-IsWorkflowSourceRepo` so its name is true: it reads the manifest and asks whether a
      plugin named after the workflow folder is published.
- [x] Repoint `adopt-workflow-folder`'s refusal onto it, and move it below the dot-source it now needs.
- [x] Record in the function's own docstring which sites deliberately keep the broad inline test, and
      what each of them is really asking, so the next reader does not "finish the job" wrongly.

### TEST

- [x] The classification, measured site by site:
      **"publishes plugins" is correct** at `Get-ReleasePluginTier`'s fallback (that IS the question) and
      at `Assert-OwnCopy`, whose own comment says it -- *"only a repo that publishes plugins can be the
      repo a shared script is maintained in"*. **"is this workflow's source" was wanted** at
      `adopt-workflow-folder` and at `check-branch-entry`'s heading rule. **"is not a Shopify store" is a
      third question** at `push-preview`, `sync-main` and `adopt-shopify-floor` -- *"there is no theme
      estate here"* -- which this function must not answer. Only the second group changed.
- [x] Removing the exemption was measured safe before it was removed: all five seams that guard covers
      resolve inside `contributing-davekjohn/` here. Three are stated in `scripts/repo-config.ps1` and
      the other two run on computed defaults #914 already moved.
- [x] `seam-lib.tests.ps1`: **44 pass, 0 fail**, including a new section for the narrowed test with the
      fixture shape that did not exist before -- a repo publishing OTHER plugins.
- [x] `adopt-workflow-folder.tests.ps1`: **24 pass**, with a new case proving a repo that publishes other
      plugins is scaffolded rather than refused.
- [x] `branch-entry-gate.tests.ps1`: **35 pass**. Its source fixture published an EMPTY plugins array,
      which the old test called a source -- the conflation reproduced in a fixture.
- [x] **The suite found a real bug in the first draft**: under `Set-StrictMode`, reaching for
      `$json.plugins` on a manifest without it throws. Fixed with the `PSObject.Properties.Name -contains`
      idiom this repo already uses in team-shopify's floor check. An empty `{}` manifest is a real shape;
      a fixture carries one.
- [x] The mirrors are byte-identical to their sources, compared as bytes.
- [x] The full gate (`check-plugin-integrity.ps1` + all suites) via `open-pr`.

### DEPLOY: `fix/the-source-test-means-what-its-name-says-v1`

`Test-IsWorkflowSourceRepo` was `Test-Path .claude-plugin/marketplace.json`, which answers **does this
repo publish plugins** rather than **is this repo the source of this workflow**. The two coincide only
while this is the only repo with a marketplace manifest, and Dave's own one-product-one-repository rule
guarantees they come apart: the next product gets its own repository *and* its own marketplace, and
consumes this workflow like any other consumer. It reads the manifest now.

Two things follow, and they are the substance. **The layout question stops asking the test at all**: the
three computed defaults that still branched -- the changelog, the release history and the internal-note
root -- now answer one string for every repo, the same move #914 made to the other two. And **the source
exemption in `Assert-WorkflowIsolatedSeamPath` is gone**, because its stated reason was that a source's
computed defaults ARE root files, which the collapse ends.

**Score:** 3

#### What makes this deploy extra special

**The guard now runs against the repo that maintains it.** `Assert-WorkflowIsolatedSeamPath` exists to
catch a repo's own seam resolving somewhere it should not -- its own example is a typo'd
`Get-ChangelogPath` pointing at `README.md` and the cut truncating a file it does not own -- and this
repo was exempt from it outright. Measured before the exemption was removed rather than after: all five
seams it covers resolve inside `contributing-davekjohn/` here, three stated and two computed. A
plugin-publishing repo that really does keep a root file is still covered, by the pre-isolation lookup --
recognised as a layout rather than waved through as an identity.

**The report undercounted its own subject, and the recount changed the work.** #998 said four sites read
the function; the one-file test is at **eleven**, asking **three** different questions. Two of them are
right as they are, and the docstring now says so by name -- `Get-ReleasePluginTier` genuinely asks
"publishes plugins", and `Assert-OwnCopy`'s own comment argues for it as a cheap necessary condition.
Narrowing those would have been a change that looked like finishing the job and was wrong. Three more ask
a third question entirely -- *is this repo a Shopify store* -- and are left alone with that recorded.

**The concrete harm was a refusal, and it is fixed.** `adopt-workflow-folder` turned away any
plugin-publishing repo with a message telling it that it *"arranges contributing-davekjohn/ by hand"*. A
second product's repo does not; it needs that scaffold like any consumer. There is now a test proving it
gets one.

**Score:** 3

#### Pull Request

the source test means what its name says, and the layout defaults stop asking it

Plugins: contributing-davekjohn