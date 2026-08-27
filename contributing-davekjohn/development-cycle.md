## Development cycle: `docs/two-contributing-pages-gets-its-condition-v1` · 20260827-183156

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

Issue #965: CONTRIBUTING-portable prescribes two contributing pages unconditionally, on the reasoning that something must survive an uninstall. That assumes the root CONTRIBUTING.md is the survivor. Where the root CLAUDE.md already states the rules a contributor needs without the plugin, IT is the survivor and a second page is a copy that will drift. Add the condition, plus the section-by-section inventory that has to happen before removing the page.

### CREATE

- [x] Check whether #965 still stands before building it. Half of it does not: the section it quotes has
      been rewritten since the 4.20.0 copy the reporter read -- it is called *The two contributing
      LAYERS* now, and #991 already gave the prescription its condition, named the source's own reason
      for differing, and stated the GitHub-surfacing cost. That half is closed by work that landed first.
- [x] Build the half that does stand, which is the load-bearing one: **inventory the root page section by
      section before deleting it.** Added to the floor section of `CONTRIBUTING-portable.md`, with the
      measurement that makes it an instruction rather than a suggestion.
- [x] Repair the plugin `README.md`, which the report named at its line 24 and which nobody had touched:
      it still prescribed a root `CONTRIBUTING.md` unconditionally, and its worked-example link pointed
      at the source's root page -- deleted by #980.

### TEST

- [x] The old link really was dead and the new one really resolves, checked with `curl` rather than by
      reading: `https://github.com/DaveKJohn/claude-code-specialists/blob/main/CONTRIBUTING.md` -> **404**,
      `.../contributing-davekjohn/CONTRIBUTING.md` -> **200**.
- [x] The inventory instruction exists nowhere else in the plugin: grepped the whole
      `plugins/workflows/contributing-davekjohn/` tree for it, and every hit was
      `connector-sessioncheck.ps1` talking about a lens inventory, an unrelated subject.
- [x] The full gate (`check-plugin-integrity.ps1` + all suites) via `open-pr`.
- [x] Test gap, stated rather than papered over: the lint gate's dead-link scan did not catch the 404,
      because it resolves relative targets and does not fetch external URLs. That is a real gap and it is
      deliberately not closed here -- a gate that fetches every external link on every run is a different
      change with its own cost, and this branch is not the place to decide it.

### DEPLOY: `docs/two-contributing-pages-gets-its-condition-v1`

`CONTRIBUTING-portable.md` now says what has to happen **before** a repo retires its root
`CONTRIBUTING.md`: inventory it section by section and move anything that lives nowhere else. The
condition #965 asked for was already added by #991 -- the floor is the repo's to place, the root page is
the recommendation, and the source's own reason for differing is written out. What was missing is the
step that makes the removal safe rather than merely tidy. Measured in one consumer the same day: of seven
sections, six were restatements of its root `CLAUDE.md`, and three rules lived **only** on the page being
deleted -- one of them a safety rule about pushing to the live theme. No gate reads a contributing page,
so dropping it would have been silent.

**Score:** 2

#### What makes this deploy extra special

**The plugin's own README was shipping a 404 to consumers, and telling them the wrong thing beside it.**
Its worked-example link pointed at the source's root `CONTRIBUTING.md`, which #980 deleted on August 27,
2026 -- confirmed 404 rather than assumed -- while the sentence around it still said to pair the portable
page with a root `CONTRIBUTING.md`, unconditionally, which is the very prescription #965 was filed
against. Both are repaired, and the link now resolves. #965 named this file; it had simply not been part
of the branch that fixed the page next to it.

**The instruction is written from a measurement, which is what stops it reading as tidiness.** Six of
seven sections were restatement -- so the honest summary of a drifting root page is *mostly safe to
delete*, and that is exactly why the pass is needed: the danger is the minority, it is invisible from a
skim, and a page far enough out of date to be worth retiring is the page whose contents you can no longer
predict from memory. The same page's gate list named three test suites on a day its `CLAUDE.md` named ten.

**Score:** 3

#### Pull Request

retiring the root contributing page needs an inventory first, and the README's worked example is not a 404

Plugins: contributing-davekjohn