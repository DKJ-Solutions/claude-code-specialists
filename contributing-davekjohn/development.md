## Development: `feat/thumbnail-generator-joins-the-connector-register-v1` · 20260829-112518

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

Register the new private consumer so the workshop regains its view of it (issue
DaveKJohn/thumbnail-generator#3).

#### What the finding actually was

`thumbnail-generator` was split out of `life-hub` on August 29, 2026 and adopted the specialists the
same morning. Its own session hook reported `[UNREGISTERED]` from the first run, and the consumer
filed it as an issue there rather than acting on it: the manifest lives here, this register never
writes cross-repo, and that repo is `private` while this one is public. That last point is why the
issue was parked on Dave's word rather than built -- given August 29, 2026.

#### And why the registration had to wait for their PR #1

Their whole install -- `.claude/settings.json` and all 19 lenses -- sat on
`claude/claude-code-specialists-installeren-v1` and not on `main`. Check 3 reads the consumer's
working tree, so a manifest written before that merge would have reported 19 registered extensions
as missing and arrived red. Same discipline as the plugin-id rule in `connectors/README.md`, from
the other end: this register books what a consumer HAS.

### CREATE

- [x] Confirm the consumer's install landed on `main` (their PR #1 merged first, 33 files, 19 lenses)
- [x] Measure the enable state from their live `.claude/settings.json`: `team-alpha@` and
      `contributing-davekjohn@`, both post-rename, so this record starts with nothing to catch up on
- [x] Measure the lens inventory: 19 files against the 15 agents + 4 personas `team-alpha` ships --
      an exact match, and the 4 personas carry the lens-only blockquote
- [x] Write `connectors/thumbnail-generator.json` -- `visibility: private`, `localCheckout:
      ../thumbnail-generator`, the 19 extensions, and `contributing-davekjohn` with the empty list
      it ships no agents for
- [x] Write the `notes` as measurements rather than intentions, including the one thing knowingly
      left open (no machine install record for that checkout yet)

### TEST

- [x] `check-connectors.ps1 -Manifest connectors/thumbnail-generator.json -ConsumerPathOverride
      <their checkout>`: `[OK] all 19 registered extensions present` for `team-alpha`, `[OK] all 0`
      for `contributing-davekjohn`, 0 errors, no `[INVENTORY]` marker
- [x] Drift leg in the same run: 26 agent defs missing (already migrated -- the correct answer for a
      lens-only consumer), 0 identical, 0 drifted, 0 of 4 personas drifted
- [x] Full sweep with `-SkipDrift`: 6 manifests parsed, exit 0 -- the new file breaks nothing that
      was green

### DEPLOY: `feat/thumbnail-generator-joins-the-connector-register-v1`

`thumbnail-generator` is the sixth connector in the register. The repo was split out of `life-hub`
on August 29, 2026 as the DJ Cylow thumbnail pipeline's own repo, adopted `team-alpha` and
`contributing-davekjohn` the same morning, and had been running unregistered ever since -- no plugin
version check, no lens inventory, no agent-def drift check reaching it from here.

Two things about this entry are worth more than the file it adds.

**The `[UNREGISTERED]` marker did the job it was invented for.** It was added on July 28, 2026 after
a third consumer had been running, and filing inbound issues, unregistered for days before anyone
noticed. Here the gap lasted hours, and the consumer's session turned it into a written issue on its
own repo instead of a line in a transcript nobody reads twice.

**The registration deliberately waited for the consumer's own install PR to merge**, and that is the
first time that wait is the whole decision rather than a note afterwards. Check 3 reads the
consumer's working tree; registering 19 extensions while their `main` still held none would have
reported all 19 as missing and put this entry in the report red on the day it was written. The
plugin-id rule in `connectors/README.md` already says the register books what a consumer HAS rather
than what it is expected to have next -- this is that rule met from the other end, before the file
existed rather than after an id went stale.

Measured after their merge and not taken from the PR: `team-alpha@` and `contributing-davekjohn@`
enabled under their post-August-26 names, 19 lens files against the 15 agents + 4 personas
`team-alpha` ships, and the four personas on the lens-only model. One thing is left open on purpose
-- this machine holds no install record for that checkout, so check 4 reports
`[NOT-INSTALLED-HERE]` until a session actually starts there and Claude Code writes the record
itself. That is the machine's state, not this register's, and nothing here can write it.

**Score:** 2

#### What makes this deploy extra special

Nothing reaches the subscriber of a service here: this is one repo's maintainer regaining sight of
another repo he owns.

**Score:** N/A

#### Pull Request

thumbnail-generator joins the connector register
