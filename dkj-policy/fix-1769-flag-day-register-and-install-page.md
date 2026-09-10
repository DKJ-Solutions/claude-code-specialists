## fix/1769-flag-day-register-and-install-page

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

The two pieces of source-side bookkeeping the #1769 flag day leaves behind, both of which could only
be done once it had actually happened.

#### The register -- decision A coming due

Decision A (Dave, 2026-09-10) deferred the five CONSUMER records in `connectors/` to the flag day,
because `connectors/README.md`'s doctrine writes a renamed id only after the consumer itself has
migrated -- the register records what a consumer HAS, not what it is expected to have next. All five
merged today, so the condition is met and the deferral is over. The self-record was the one exception
and moved with the source branch.

#### `INSTALL.md` -- four sites the sweep should have caught

The rename's own test is **whether something RESOLVES the name or merely prints it**: a citation may
lag, a lookup may not. Four sites in `INSTALL.md` resolve it and were missed, and two of them are
self-contradictory within three lines -- an `extraKnownMarketplaces` block naming the marketplace
`dkj-claude-plugins` while pointing its `repo` at the retired slug. A reader pasting either gets a
registration that works only because GitHub answers the transfer redirect, which is the one thing
`CLAUDE.md`'s own citation rule says must never be load-bearing.

Found by Tessa while writing the `v5.0.0` release note, and verified against the file before being
acted on rather than taken from the report.

### CREATE

- [x] The five consumer records in `connectors/` migrate to their final ids. Written from
      MEASUREMENT rather than from the plan: each consumer's own `.claude/settings.json` on `main`
      was read through the API after its merge, and every record now matches what that file enables.
      `figma@claude-plugins-official` stays unregistered in the three repos that enable it, for the
      standing reason -- this register is the register of THIS marketplace's consumers
- [x] Each record's `notes` gains a dated `MIGRATED 2026-09-11 (#1769)` line in the established
      style, naming what was measured and what was deliberately NOT re-read (extensions, machine
      versions, drift figures). The sentences above it keep the names they were written with, per #952
- [x] `INSTALL.md`: the four sites that RESOLVE the name -- the public-source sentence at the top of
      the page, the two `extraKnownMarketplaces` examples, and the paste-ready
      `marketplace add` command. The three remaining old-slug hits are issue URLs and stay exactly as
      they are, per the #1526 correct-on-edit rule

### TEST

`check-plugin-integrity.ps1`: 0 errors. All 91 suites: green.

`check-connectors.ps1` was run deliberately, and it now reports the truth rather than a stale
register:

- `DKJ-Solutions/dkj-claude-plugins` (this repo, self-consuming) -- all six `[OK]` on `v5.0.0`.
- `BWJ-ecommerce/xoxowildhearts` -- all five `[OK]` on `v5.0.0`. The `[ERROR]` this repo's session
  start printed all day (machine record on `v4.31.0`) is gone.
- `DaveKJohn/life-hub`, `DaveKJohn/thumbnail-generator`, `DaveKJohn/djcylow-react` -- `[SKIP]`, not
  checked out on this machine, which is the register's normal answer and not a gap.
- `BWJ-Development/smartwatchbanden` -- five `[ERROR]`s that are **true about the folder read and
  false about the repo named**, and they are left standing rather than silenced. The folder
  `bwjecommerce\smartwatchbanden` on this machine is a clone of the RETIRED
  `BWJ-ecommerce/smartwatchbanden`; the live repo's trunk does enable all five under the new name.
  Filed as [#1821](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1821), because a
  `localCheckout` is matched by PATH and a path says nothing about which repository sits in it -- an
  org move makes two repos share a folder name, and the check then reports five confident errors
  about a repo it never opened.

### DEPLOY: fix/1769-flag-day-register-and-install-page

The connector register now records the five consumer repositories as they actually are after the
`v5.0.0` flag day: `<plugin>@dkj-claude-plugins`, with the current plugin names. Every record was
written from the consumer's own `.claude/settings.json` on `main` rather than from the migration plan,
which matters because three of them were two renames behind and the plan's one-axis swap would have
written ids that never existed.

This is decision A coming due rather than a change of mind about it. The doctrine in
`connectors/README.md` -- write a renamed id only after the consumer itself has migrated, so the
register never raises a false alarm about a migration nobody performed -- held the whole way: all five
consumers merged first, and their records followed within the hour.

**And `INSTALL.md` stops handing a reader the retired slug in a command they are meant to paste.**
Four sites resolved the repository name rather than merely printing it, and two contradicted
themselves inside three lines by naming the marketplace `dkj-claude-plugins` while pointing its
`repo` at `DKJ-Solutions/claude-code-specialists`. They worked, because GitHub answers the transfer
redirect -- which is exactly the dependency `CLAUDE.md` says must never be load-bearing, since it
holds only while nothing is created at the old path. The three old-slug hits still on the page are
issue URLs and are correct as they stand.

**Score:** 3

#### What makes this deploy extra special

**A page that tells a new consumer to register the wrong source is the one doc defect that cannot be
noticed by the person it hurts.** The registration succeeds, the plugins install, and nothing is
visibly wrong -- until the day the redirect stops answering, at which point the failure lands on
somebody who followed the instructions exactly. Three adoption rounds' worth of lint rules in this
repo exist for that class, and this is the same class arriving through the rename that was supposed
to close it.

The register half has a quieter payoff: `check-connectors.ps1` is the thing that answers *"is this
consumer behind?"*, and it SKIPS a plugin whose id it cannot resolve. With five records naming a
marketplace that no longer exists, every one of those consumers would have been unreportable in
exactly the way #1465, #1525 and #1698 each recorded before -- the fourth time by the same route.

**Score:** 3

#### Pull Request

The connector register and the install page catch up with the flag day
