## feat/1873-preview-handover-rule

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

#### What #1873 asks for, and what verifying it changed

Inbound #1873: both BWJ store repos hand a reviewer a markdown table of preview URLs. Verified against
the tree before routing -- the symptom stands (`Write-PreviewUrls` in `scripts/task/push-preview.ps1`
prints one bare URL per line; the skill's own description says it "prints the preview URL(s) to hand
over"), and nothing anywhere states how a preview is handed over. The reason stands too: no page is
loaded at the moment a preview is pushed, so a policy page alone loses to the printed list.

One thing the report left implicit and this branch states outright: the QR codes it asks for are
served through the Artifact CSP, which blocks images from every host. A rule prescribing QR codes
without that constraint produces a page of ten invisible boxes and no error.

### CREATE

- [x] `PREVIEW-HANDOVER-portable.md` -- chapter three of `dkj-policy-bwj`: one link to a published
      page, what that page carries per market, and why a QR rather than a URL
- [x] The plugin `README.md` -- two chapters become three, in all five places it says so
- [x] The four overviews outside the plugin that state the chapter count: the root `README.md`,
      `plugins/dkj-policy/README.md`, `.claude-plugin/marketplace.json` (both descriptions) and the
      plugin's own `plugin.json`, which the copy edit caught still saying two
- [x] The mechanism side, so the rule is carried where the list is printed: a `Get-PreviewHandoverNote`
      in `scripts/lib/preview-theme.ps1`, printed by `push-preview.ps1` when it emits more than one URL,
      and a section in the `push-preview` skill page
- [x] Mirror the two shared scripts into the plugin (`scripts/sync/build-shared-scripts.ps1`)

### TEST

- [x] `push-preview.tests.ps1` covers the new note -- silent on one URL, and carries what it has to
- [x] `dkj-policy-bwj.tests.ps1` asserts both portable pages ship and the chapter count is stated
- [x] The lint gate and all suites green


#### What the review pass changed

Three reviewers ran in parallel on the diff. The code review found nothing. The other two each moved
the deliverable rather than only confirming it, so both are recorded here:

- **Security.** The CSP note answered *rendering* and said nothing about *confidentiality*, which
  reads as complete and is not: a preview URL is what lets a viewer see an unpublished theme, so a QR
  generator that round-trips it to a third-party service is wrong whatever the CSP happens to permit
  -- and the handover link itself now reaches every market's preview at once, where the terminal
  printout reached whoever was at the terminal. Both are stated on the page now, on their own terms.
- **Copy edit.** Two real defects and four stragglers. The skill page said the note fires *"above two"*
  URLs while the code fires *at* two, and `plugin.json` still said "Two chapters" while the marketplace
  entry beside it had been updated -- two hand-written copies of one blurb, drifting on this very
  branch. Both are repaired, and both now have an assert: the boundary at exactly two, and the two
  descriptions held to the chapter count the folder actually ships.

### DEPLOY: feat/1873-preview-handover-rule

`dkj-policy-bwj` gains a third chapter, `PREVIEW-HANDOVER-portable.md`: **a Shopify preview is handed
over as one link to a published page, never as a table of URLs.** The page carries, per market, a QR
code and the concretely changed pages, plus what the gates already proved and the one question the
reviewer is being asked. The existing requirement is untouched -- the changed pages, per market,
unasked -- and so is the rule it serves: no PR opens before the preview is approved. What changes is
the carrier.

The rule is carried where the failure happens, not only where it is stated. `push-preview` printed a
bare list of URLs and its own page called that list "the preview URL(s) to hand over", so a policy page
nothing loads at push time would have lost to it every time. `Get-PreviewHandoverNote` in
`preview-theme.ps1` now prints a closing note whenever more than one URL is emitted -- a list is raw
material, not a handover -- and the `push-preview` page says the same in prose. Both stay **generic**,
naming no repo: what is true everywhere is that a wrapped column of 90-character URLs is not a handover
and the reviewer is on a phone; what the handover *is* stays BWJ's house rule. One URL prints nothing,
because a single line in a terminal genuinely is a handover.

One thing the report left implicit is stated outright, because without it the rule is unfollowable: a
published Artifact's CSP permits external scripts from a short list of CDNs and blocks images from
every host, so a QR pulled from a QR-image API renders as a blank square and says nothing. The page
names the two shapes that work.

**Score:** 2

#### What makes this deploy extra special

Both BWJ store repos stop handing their reviewer something they cannot use. The measured handover was
ten URLs of 70 to 100 characters in a two-column table: the terminal wrapped it until the columns
saying *which market, which page* were gone, the reviewer was on the phone the change only existed on,
and everything about what was proven and what was being asked stayed in the transcript. A QR per market
is the difference between reviewing the change and retyping a query string ten times.

Every other Shopify consumer gets the generic half -- the note under a multi-URL list -- and nothing
else changes for them: no seam to answer, no file to scaffold, and a single-market repo sees no new
output at all.

**Score:** 4

#### Pull Request

A preview is handed over as one link to a published page, not as a table of URLs
