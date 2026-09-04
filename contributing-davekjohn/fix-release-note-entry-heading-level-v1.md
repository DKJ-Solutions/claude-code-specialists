## fix/release-note-entry-heading-level-v1

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

Read the level from Get-EntryHeadingLevel instead of the literal 2, and give the entries the
`## Version X.Y.Z (Mon DD, YYYY)` parent Dave specified in
[#1369](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1369).

#### What the issue reported, and what it turned out to be

Dave's report: a `DEPLOY:` heading is an H3 in `CHANGELOG.md` and comes out an H2 in the generated
release note. Verified before routing: `$EntryHeadingLevel` in
[`scripts/lib/entry-scaffold-lib.ps1`](../scripts/lib/entry-scaffold-lib.ps1) is 3, and
`Build-ReleaseNotes` passed a hard-coded `-EntryLevel 2`. So the symptom stands and the cause is a
literal that went stale, not a rule anybody chose.

`#881` (August 25, 2026) had already fixed exactly this defect, by setting the literal to the entry
level of that day. Three weeks later `CHANGELOG.md` gained its `## [Unreleased]` heading, entries
moved to H3, and the renderer -- holding a number rather than the question -- began promoting them
again. Its docstring and its own test both still asserted the repaired claim was true, which is why
nothing caught it: every release since v4.11.0 carries the demoted shape.

### CREATE

- [x] `Format-ReleaseVersionHeading` in `release-lib.ps1`: `Version 4.29.0 (Sep 04, 2026)`, the
      wording from the issue, formatted through the invariant culture so a published record cannot
      change with the locale that cut it
- [x] `Build-ReleaseNotes`: both `Format-RankedEntries` calls read `Get-EntryHeadingLevel`; the H1
      becomes the constant `# Changelog Releases` and the version heading occupies H2
- [x] `Build-ReleaseNoteDraft`: its literal `3` reads the same function -- same value, no change to
      any note, one fewer second statement of a fact `entry-scaffold-lib.ps1` owns
- [x] `**Date:**` / `**Type:**` deliberately KEPT: `new-internal-note.ps1` parses both out of this
      document, so dropping them would degrade a consumer's two-document flow to `(fill in)`
- [~] `Build-ConsumerNotes` left at `-EntryLevel 2` -- nothing calls it (the two-document flow it
      served is retired here) and moving it would change a renderer this branch cannot exercise.
      Filed instead, so it is not lost
- [x] Mirror rebuilt with `scripts/sync/build-shared-scripts.ps1`

### TEST

- [x] `release-lib.tests.ps1`: the level expectations are now COMPUTED from `Get-EntryHeadingLevel`
      and `Get-EntrySectionLevel` rather than written as `##`/`###`, so the suite cannot drift with
      the format again -- which is the half that failed last time. New block for
      `Format-ReleaseVersionHeading`, including an assert run under `nl-NL` (which renders September
      as `sep.`) so the invariant culture is proven rather than assumed. 482 asserts pass
- [x] `internal-note.tests.ps1`: a fixture at the shape written TODAY -- constant H1, version H2,
      entries at H3 -- proving the reader still finds them one level deeper and does NOT read the new
      container heading as an entry. That second half is the failure mode this suite already carries a
      standing check for. 111 asserts pass
- [x] Lint gate clean (0 errors, 33 checks) and every suite green

### DEPLOY: fix/release-note-entry-heading-level-v1

A generated release note keeps a `DEPLOY:` heading at the H3 it was written at, under a
`## Version <X.Y.Z> (<Mon DD, YYYY>)` heading naming the release the entries landed in. It came out
an H2, so the record contradicted the changelog the entry had been copied out of -- and an entry
pasted back out of it landed a level shallower than it was written.

**The defect is a repaired one that came back through its own repair.** `#881` set these entries to
`##` because that was `CHANGELOG.md`'s entry level on August 25, 2026; on August 26 that document
gained `## [Unreleased]`, every entry moved to H3, and this renderer went on promoting them. Nothing
errored and no gate fired: the docstring above the literal and the assert below it both still stated
the repaired claim, so the suite passed against a document that had started disagreeing with its
source again. Every release from v4.11.0 on carries the demoted shape. The level is now asked for --
`Get-EntryHeadingLevel`, the one function that owns it -- so the next move of that pair carries this
document with it instead of leaving it behind.

**The H2 is what the level change needed, and the H1 pays for it.** Entries at their written level
would hang under an H1 with H2 empty, so the release occupies H2 and states its own version and date;
the H1 becomes the constant `# Changelog Releases`, mirroring `CHANGELOG.md`'s own `# Changelog`, so
the version is stated once by the heading that owns the entries rather than twice in four lines. The
date is formatted through the invariant culture: a published record must not read differently
depending on the machine that cut it, and `nl-NL` abbreviates September as `sep.` -- the assert runs
under that culture rather than trusting the flag.

**The `**Date:**` and `**Type:**` pair stays, and that is a reader rather than a preference.**
`new-internal-note.ps1` parses both labels out of this document to build the internal note, so
dropping them would silently degrade a consumer's two-document flow to `(fill in)` and a warning.

**Existing notes are untouched.** They are published records and are not rewritten, so the 60-odd
already cut keep the shape they were cut with; this changes what the next cut writes.

**Score:** 2

#### What makes this deploy extra special

N/A -- a subscriber of a service reads none of this. The document is the raw record written for this
repo's own developers, and the change is to the heading levels inside it.

**Score:** N/A

#### Pull Request

Release notes keep DEPLOY at the H3 it was written at, under a version heading
