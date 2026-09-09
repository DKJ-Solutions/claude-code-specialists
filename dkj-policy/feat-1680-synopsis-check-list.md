## feat/1680-synopsis-check-list

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
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

#### What #1680 reported, and what it turned out to be

The gate's `.DESCRIPTION` enumerates its checks in prose, and that list had stopped at `30.` while the code
ran to `36.` -- with its own item `30.` describing the check #1494 renumbered to `33` a month after the
list was written. Verifying it against the tree turned up a third drift the report did not name: items
`9.` and `17.` still describe checks **retired on August 8, 2026**, reading as live ones.

#### And why the repair is a check and not only a rewrite

Rewriting the list by hand resets the clock rather than stopping it -- the same conclusion check 32's own
header records after three hand repairs of the mirror table, and the reason check 35 exists after the
#1635 sweep. Check 34 already holds the column-0 headers to each other; nothing held the prose that
summarises them for a reader who has not opened a four-thousand-line file. The check earned that
argument on its first run by finding a seventh missing entry, `13b`, that no report had noticed.

### CREATE

- [x] Verify the drift against the code's own headers rather than the report's summary
- [x] Repair the list: renumber the barred-skill entry to 33, write back 30, 31, 32, 34, 35 and 36, and
      turn 9 and 17 into tombstones that keep their numbers
- [x] Add check 37, opt-in through the existing marked-span walk, holding every column-0 header to that
      list in ONE direction so it is born green with no exemptions
- [x] Record the shape and the measurements in Sylvester's lens
- [x] Act on the code review: the gutter rule for entries, the per-file union, the two zero-state
      coverage notes, and the `.SYNOPSIS`/`.DESCRIPTION` citation in this document

### TEST

- [x] Seven scenarios in the gate's own suite: the missing entry, the entry with no header (the bound),
      the lettered sub-section, the list in a headerless file, the unpaired marker plus the opt-out, the
      nested enumeration, and the two spans unioned into one
- [x] The lint gate and every suite are green

### DEPLOY: feat/1680-synopsis-check-list

The gate's `.DESCRIPTION` enumerates its checks in prose -- the summary a reader who has not opened four
thousand lines consults, and the one a lens, a hook, a test-scenario name or a released note quotes a
number from. It had stopped at `30.` while the code ran to `36.`, and its own item `30.` still described
the check #1494 renumbered to `33` a month after the list was written, so grepping the list for "check 30"
answered with a different check. Two more drifts were found on verification and neither was in the report:
items `9.` and `17.` still read as live checks a month after they were **retired**, and `13b` had no entry
at all.

**Check 37 now holds that list to the file's own column-0 headers**, because a hand rewrite resets the
clock rather than stopping it -- the conclusion check 32's header already records after three hand repairs
of the mirror table. It is opt-in through the same marked-span walk checks 10, 29 and 32 use, so it
inherits their three refusals for free and no unmarked script becomes a subject; it reads check 34's own
header pattern, so the two cannot disagree about what a header is; and it asserts **one direction only** --
every header needs an entry, an entry needs no header. That is what let it be born green rather than with
an exemption list: three entries legitimately have no header of their own, the two retirement tombstones
and the consumer-doc guard the suites call check 19. Measured after the repair: 1 span, 37 headers, 37
claimed, 0 findings, 0 exemptions. Its own first run is the argument for it -- `13b` was reported by the
check, not by a reader.

The review round moved four things, and three were one defect in different clothes -- a rule read off the
happy path. An entry must now **start inside the list's gutter**, so a nested enumeration in an entry's
prose cannot satisfy a header (found by probing the check, not by measuring the tree: the list contains no
such line today); the header comparison runs once per FILE over the union of its spans, where running it
per span doubled the count and named one gap twice; and the coverage note now distinguishes "no marker
anywhere" from "markers present, none of them paired", which used to print the reassuring sentence over a
run that had just raised an error about that very file. Two bounds are named rather than closed -- a
STALE entry still satisfies its number, and the two zero-state notes are unreachable from the suite
because every fixture run copies this script into the fixture -- both written into the check's own header,
because an unstated gap reads as coverage.

**Score:** 3

#### What makes this deploy extra special

N/A. `check-plugin-integrity.ps1` is this repo's own gate and is mirrored into no plugin, so nothing here
reaches a consumer: the repaired list, the new check and its scenarios all stay in the source tree. A
consumer's own lint script is theirs, and the marker is opt-in, so nothing starts asserting anything on
their side either.

**Score:** N/A

#### Pull Request

The gate's own check list is held to its headers, and the seven it had lost are back
