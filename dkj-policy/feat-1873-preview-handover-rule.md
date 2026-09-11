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

- [x] The carrier half of chapter three -- folded into `PREVIEW-portable.md`, which landed from #1874
      mid-branch: one link to a published page, what each market card carries, and why a QR rather than
      a URL. This branch's own `PREVIEW-HANDOVER-portable.md` is deleted -- see the collision note below
- [x] The plugin `README.md` -- the chapter-three rows and paragraph now state both halves, not one
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



#### The collision, and why chapter three is ONE page

While this branch was building, [#1874](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1874)
landed on the trunk with a chapter three of its own -- `PREVIEW-portable.md`, from a session working the
**same day on the same handover**. Both reports came from one exchange with Dave: #1874 carried what the
handover must *contain* (the control variant beside the preview), #1873 what must *carry* it (one link
to a published page, never a table). Neither knew about the other, and both pages opened by declaring
themselves chapter three.

**Two pages was not an option, and the reason is a contradiction rather than tidiness.** #1874's page
prescribes a markdown table of preview and control URLs as the shape of the handover, and in its very
next paragraph records Dave saying a terminal table could not even be selected. That is #1873's finding
arriving one report too early to be acted on. Kept side by side, the plugin would ship one chapter
telling a session to build the table and another forbidding it.

So the page that was already merged keeps its name and its measurements, and this branch folds its own
into it: the rule is stated in two halves, the carrier argument sits beside the control-variant
argument, and the shape section is rewritten from a terminal table to the page's own cards -- each
carrying the QR for the preview and the pair as text beneath it. `PREVIEW-HANDOVER-portable.md`, this
branch's own page, is deleted rather than shipped.

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

`dkj-policy-bwj`'s chapter three gains its second half: **the preview handover is one link to a
published page, never a table of URLs.** The page carries one card per market -- a QR code to the
preview, the preview and live-control pair as text beneath it -- plus what a URL cannot say: how to see
the change, what the gates already proved, and the one question being asked. Nothing about which
changes owe a preview, or about no PR opening before one is approved, changes.

**It lands in `PREVIEW-portable.md` rather than beside it.** That page arrived on the trunk from
[#1874](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1874) while this branch was
building -- the same day, the same handover, the other half of one complaint -- and it prescribed a
markdown table of URLs while recording, a paragraph later, that a terminal table could not even be
selected. Two chapter threes would have shipped a plugin that tells a session to build the table and
forbids it. So the rule is now stated in two halves on one page, and this branch's own page is deleted.

The carrier half is carried where the failure happens, not only where it is stated. `push-preview`
printed a bare list and its own page called that list "the preview URL(s) to hand over", so a policy
page nothing loads at push time would have lost to it every time. `Get-PreviewHandoverNote` in
`preview-theme.ps1` now prints a closing note whenever more than one URL is emitted; the `push-preview`
page says the same in prose. Both stay generic, naming no repo: what is true everywhere is that a
wrapped column of 90-character URLs is not a handover and the reviewer is on a phone -- what the
handover IS stays BWJ's house rule. One URL prints nothing, because a single line in a terminal
genuinely is a handover.

Two things neither report stated are written down, because without them the rule is unfollowable: a
published Artifact's CSP blocks images from every host, so a QR pulled from a QR-image API renders as a
blank square and says nothing; and the preview URL is what grants access to an unpublished theme, so it
must never be round-tripped to a third-party generator, and the handover link is as sensitive as the
URLs on it.

**Score:** 3

#### What makes this deploy extra special

Both BWJ store repos stop handing their reviewer something they cannot use. The measured handover was
ten URLs of 70 to 100 characters in a two-column table: the terminal wrapped it until the columns
saying *which market, which page* were gone, it could not be selected to copy, the reviewer was on the
phone the change only existed on, and everything about what was proven and what was being asked stayed
in the transcript. A QR per market is the difference between reviewing the change and retyping a query
string ten times -- twenty, now that the control variant doubles the pairs.

Every other Shopify consumer gets the generic half -- the note under a multi-URL list -- and nothing
else changes for them: no seam to answer, no file to scaffold, and a single-market repo sees no new
output at all.

**Score:** 4

#### Pull Request

A preview is handed over as one link to a published page, not as a table of URLs
