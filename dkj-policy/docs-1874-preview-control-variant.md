## docs/1874-preview-control-variant

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

#### Where this branch stands

Written and gated. The rule comes from the consumer `BWJ-Development/smartwatchbanden`, filed as inbound
[#1874](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1874).

- [x] Establish that this is policy rather than mechanism -- `push-preview.ps1` stays `dkj-subagents-shopify`'s,
      and what is being stated is what a handover contains
- [x] Establish the chapter shape against the precedent of #1382 -- a third portable page, not a section
      bolted onto a page that answers a different question
- [x] Measure the control URL rather than assume it, on a live store

### CREATE

- [x] Write `plugins/dkj-policy/dkj-policy-bwj/PREVIEW-portable.md` -- chapter three
- [x] Register it in the plugin `README.md`: the chapter table, the chapter-three paragraph, the
      folder table, and the add-on paragraph's seam count (two -> three)
- [x] Update the root `README.md` row for `dkj-policy-bwj` -- "Two chapters" -> three, with the new one
      summarised and the extended seam list
- [x] Extend the ships-assert in `scripts/tests/dkj-policy-bwj.tests.ps1` to cover the new page, and
      `SYNC-LOG-portable.md` beside it -- the same loop had never guarded either, and a portable page
      that goes missing is silent
- [~] A seam of its own -- dropped: the control URL needs the live theme id, and
      `Get-ShopifyLiveThemeId` already answers that for `dkj-subagents-shopify`'s live-theme guard. A
      second answer to one fact is what this plugin exists to prevent
- [~] An adopt step -- dropped: this chapter scaffolds no file and wires no CI, so there is nothing for
      `adopt-dkj-policy-bwj` to place

### TEST

- [x] The control URL is measured, not assumed. On `smartwatchbanden.nl`, one product page, reading
      `Shopify.theme` out of the rendered markup: the preview URL renders the branch theme
      (`role: unpublished`); **the same URL with no parameter renders that same branch theme**, because
      `preview_theme_id` sets a cookie; `?preview_theme_id=0` renders no page at all but the
      "missing one of these required files" error; `?preview_theme_id=<live id>` renders the live theme
      (`role: main`) and leaves the session back on live
- [x] The same measurement confirms the rule is worth writing: the bare-URL control agrees with the
      preview, so a reviewer using it concludes nothing changed
- [x] Lint: 0 errors
- [x] The full suite under `scripts/tests/`
- [x] `dkj-policy-bwj.tests.ps1` green with the extended ships-assert

### DEPLOY: docs/1874-preview-control-variant

`dkj-policy-bwj` gains a third chapter, [`PREVIEW-portable.md`](../plugins/dkj-policy/dkj-policy-bwj/PREVIEW-portable.md):
**a preview handover is a pair per market -- the preview, and the live control variant.**

A preview alone shows what a page will look like; it never shows what *changed*. The reader supplies the
other half from memory while looking at something else, which is the exact judgement the preview was
pushed for. The rule comes from a five-market handover in `smartwatchbanden` that was complete by the
letter of the rule then in force and still left that half undone.

**The part that had to be measured is what the control URL is.** It names the **live theme id**, and not
the same URL with the parameter dropped -- `preview_theme_id` sets a cookie, so once a market's preview
has been opened the bare URL keeps serving the preview theme. The control tab then agrees with the preview
and the reviewer concludes nothing changed: a false negative that looks like a clean result. Measured on a
live store, with both neighbouring wrong answers recorded on the page -- including `preview_theme_id=0`,
which renders the "missing one of these required files" error rather than resetting anything, and reads
like a broken preview theme.

The live id needs no seam of its own: `Get-ShopifyLiveThemeId` already states it for
`dkj-subagents-shopify`'s live-theme guard, and the page points there rather than at a pasted number.
Nothing here decides which changes owe a preview, or when a PR may open -- both stay the consumer's and
`dkj-policy`'s, unchanged. No new seam, no adopt step, no CI.

The ships-assert in `dkj-policy-bwj.tests.ps1` now covers the portable pages it had never guarded --
the new one and `SYNC-LOG-portable.md` beside it.

Resolves [#1874](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1874).

**Score:** 3

#### What makes this deploy extra special

N/A -- a workflow plugin's house rule for two store repos. It changes what one colleague hands another
before a merge; no subscriber of any service reaches it.

#### Pull Request

A preview handover owes the control variant, not only the preview
