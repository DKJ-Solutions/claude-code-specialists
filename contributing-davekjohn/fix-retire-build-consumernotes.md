## fix/retire-build-consumernotes

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

### CREATE
### PLAN

Issue [#1370](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1370) left two questions
open, in order. Both are answered before anything was edited:

- [x] **Does anything still want `Build-ConsumerNotes`?** No. No caller in this repo or in the shipped
      `contributing-davekjohn` mirror; `releases/consumer/` does not exist here; and commit `f239ed57`
      (August 11, 2026) dropped the *call* while leaving the *function*, with no note saying why -- unlike
      the `MOVED, NOT DELETED` and `RENAMED, NOT DELETED` records a few hundred lines above it in the same
      file. It was left behind, not kept.
- [x] **So delete rather than level.** Levelling alone leaves the entries hanging under the document's H1
      with H2 empty -- the same skip the version heading was added to `Build-ReleaseNotes` to close -- so
      the honest repair needs a container heading too: a design decision about a document nothing
      generates, for a reader nothing writes to.
- [x] **And the report's one inferred claim, checked.** #1370 could not rule out a consumer who forked
      `cut-release.ps1` before August 12, 2026. The lib and the scripts ship together from one plugin
      version, so a pinned consumer holds the old pair; this removal cannot reach them.

### CREATE

- [x] `scripts/lib/release-lib.ps1`: the function replaced by a retirement record in the file's own
      established convention -- what it built, when the flow went, why it went *now*, why deleted rather
      than levelled, and what still covers a consumer holding one of those documents.
- [x] The four comments and one lens paragraph that cited it as a live renderer repointed at
      `Build-ReleaseNoteDraft`, which carries the same argument (`-RankByTier $AudienceTier`) under a name
      that still exists: `release-lib.ps1` twice, `entry-scaffold-lib.ps1`, `fold-changelog-entry.ps1`,
      and the release lens.
- [x] Mirror resynced via `scripts/sync/build-shared-scripts.ps1` -- three files.
- [~] The archived release notes under `contributing-davekjohn/releases/changelog/4.x/` name it too, and
      are deliberately left alone: they are the record of what those releases said.

### TEST

- [x] The ~40 asserts that only ever ran through this renderer triaged one at a time rather than deleted
      with it. Everything still describing live behaviour moved onto `Build-ReleaseNoteDraft`, which passes
      the identical switch set: the branch-administration strip, both legacy significance shapes, the
      retired marker and its four knobs, the audience-score ordering, and the link rewriting.
- [x] The two legacy shapes now run against a fixture that actually carries them (`$e22`), where the
      `$dossier` fixture declares its significance in a named section -- so they assert something.
- [x] The no-HTML scan repaired rather than moved: it now covers **both** generated documents and excludes
      html *comments* by name, because the draft carries its guidance as comments on purpose. Moving it
      across unchanged failed on correct output, which is how this was found.
- [x] `release-lib.tests.ps1`: 471 asserts green (470 before, one of which this branch turned into a real
      check).
- [x] Full local gate: `check-plugin-integrity.ps1` + every suite.

### DEPLOY: fix/retire-build-consumernotes

`Build-ConsumerNotes` is gone from `scripts/lib/release-lib.ps1`, and with it the second answer to a
question the library should only answer once. It rendered `releases/consumer/<dir>/<X.Y.Z>.md` for the
two-document release flow that became one document on August 11, 2026; that commit dropped the call and
left the function, and nothing has called it since. It was still passing a hard-coded `-EntryLevel 2` --
the literal [#1369](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1369) had just
repaired out of both live renderers -- and its own test pinned that stale answer, which is why the repair
could not reach it.

It is **retired rather than levelled** because levelling needed a container heading invented for a
document nothing generates. In its place is a record in the file's own convention, saying what it built,
why it went, why deletion was the honest repair, and why a pinned consumer cannot be reached by it: the
lib and `cut-release.ps1` ship together from one plugin version.

**The tests were triaged, not deleted with it.** Around forty asserts only ever ran through this
renderer, and every property still true of a document that travels outward moved onto
`Build-ReleaseNoteDraft`, which passes the identical switch set. Two of them now assert something they
could not before: the legacy impact table and the older `Tier: N` line run against a fixture that
actually carries them. And the no-HTML scan came out stronger than it went in -- it covers both generated
documents now, excluding html comments by name, because the draft carries its guidance as comments
deliberately and the scan had been written against a document that had none.

**Score:** 2

#### What makes this deploy extra special

N/A. Nothing a consumer runs changes: the function had no caller, the document it built is not generated
anywhere, and every archived `releases/consumer/` document a consumer may still hold is read by
`check-plugin-integrity.ps1` from disk rather than through this code.

**Score:** N/A

#### Pull Request

Build-ConsumerNotes is retired rather than levelled
