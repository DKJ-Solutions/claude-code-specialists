## Development: `docs/language-layers-bypass-restored-v1` · 20260903-131839

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

#### What this branch does

#1290 reported three documents still stating `main-ci-gate` has no bypass list after the
September 3 restore. Verified against the repo: two of the three -- `05-15-extension.md` and
`05-06-extension.md` -- were already repaired by #1286 (`596f2e7c`, merged after #1290 was
filed), and both carry the "no Write role" nuance the issue asks for. Only
`.claude/rules/language-layers.md:148-155` was still stale, describing the emptied bypass list
as the standing state. This branch repairs that one passage and closes #1290 with the
already-done part named.

### CREATE

- [x] Re-tense the `language-layers.md` #1244 paragraph: the list was emptied by the transfer
  and refilled on September 3 with a different shape (`OrganizationAdmin` + repository admin,
  no Write role); the snapshot went stale twice, which strengthens the paragraph's own point.
- [x] Point at the system-administration lens for the bypass mechanics; cite #1244 and #1290.

### TEST

- [x] `check-plugin-integrity.ps1` dead-link scan -- the new `../specialists/lenses/05-15-extension.md`
  link resolves from `.claude/rules/`.
- [x] Lint + tests green, then PR + merge + fold.

### DEPLOY: `docs/language-layers-bypass-restored-v1`

`.claude/rules/language-layers.md` said the `DKJ-Solutions` org transfer had "dropped the
bypass actors to empty" as the current state. Dave refilled `main-ci-gate`'s bypass list on
September 3, 2026, with a shape the July field-by-field re-check had not seen --
`OrganizationAdmin` plus a repository admin role, where it once held repository admin plus the
Write role. The paragraph now states the restore beside the emptying, names the new list
shape, and points at the system-administration lens for the mechanics. Its language point --
`lint-en-tests` is an external name this repo may cite but not rename -- is unchanged; the
"a re-check is a snapshot" observation is now backed by two stale readings instead of one.

The two other passages #1290 named were already repaired by #1286.

**Score:** 2

#### What makes this deploy extra special

N/A -- an internal governance-rule document. No subscriber of any service reaches it.

**Score:** N/A

#### Pull Request

record the main-ci-gate bypass restore in the language-layers rule

#### Pull Request

record the main-ci-gate bypass restore in the language-layers rule

