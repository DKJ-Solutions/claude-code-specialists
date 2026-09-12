## docs/1896-tier2-subscriber-reader

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

Settle the ambiguity in the tier model that let one release score the same question N/A and 4.

#### What the report claimed, and what had to be checked before writing anything

[#1896](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1896) reported a contradiction inside
`v5.1.0` and named its own unverified half: whether the reading is older than that release. Both halves
were checked against the tree before a line was written.

- **The contradiction is real.** `feat/1842-unify-prio-labels-bwj` scored the tier-2 question `N/A` and
  `fix/1841-reach-label-seam` scored it `4`, about issue labels in the same two store repos, in the same
  release.
- **The reading IS older.** Every `dkj-policy-bwj` entry in the record was scanned. `docs/1537-bwj-scope-org-agnostic`
  and `fix/1536-boardless-stage-floor`, both in `v4.32.0`, score `N/A` in the identical shape -- each names
  in its own sentence the consumers who *do* receive the change.
- **The proposed direction holds.** *Subscriber of a service* names a role, not a party, and says nothing
  about which service. That is the defect, and it is the one the repair addresses.

#### What is deliberately NOT done

The three mis-scored entries are left exactly as written. `v5.1.0` was cut while this was being verified,
so all three now sit in `releases/changelog/`, which is historical record under this repo's standing
carve-out -- a document that says what it said on the day it went out. Re-scoring them days after the fold
is the re-estimation the tier model forbids by name, and the release record is not where the model gets
repaired.

### CREATE

- [x] Verify both halves of the report against the tree -- the contradiction, and whether the reading
      predates the release that reported it
- [x] Name the rule in the portable tier model: `../plugins/dkj-policy/RELEASES-portable.md`
- [x] Put the same rule where the author actually scores -- the guidance block `new-branch` writes into
      every development document, in `../scripts/lib/entry-scaffold-lib.ps1`
- [x] Keep the new clause INSIDE the `{0}` seam paragraph, or a no-audience consumer gets #928 again -- a
      paragraph opening with "that reader" after the clause naming that reader has been dropped
- [x] Guard that with an assert, since the failure is unreachable in this repo (`repo-config.ps1` states
      tier 2) and would reach consumers only
- [x] Sync the plugin mirror (`build-shared-scripts.ps1`)
- [~] Sweep the ~20 other places that say "the subscriber of a service" -- dropped. Those state the tier's
      NAME; only two places state its DEFINITION, and a name is not where a definition gets fixed. A sweep
      would touch a dozen files, a generated blueprint and the mirror for no added meaning.

### TEST

- [x] Render the guidance in BOTH audience states and read the result: with tier 2 the clause continues the
      reader sentence; with no tier stated the whole paragraph, clause included, is gone
- [x] `check-plugin-integrity.ps1` and the full suite, via `open-pr.ps1`
- [x] `build-shared-scripts.ps1 -Check` reports no drift between source and mirror

### DEPLOY: docs/1896-tier2-subscriber-reader

The tier model now says **whose** service. *Subscriber of a service* names a role, and a role does not say
which party fills it -- so in a repo whose subscribers are themselves businesses the phrase reads two ways,
and the wrong reading is the more vivid one, because that party is a real customer somebody can picture.
The rule added is **one hop and no further**: the tier-2 reader is whoever takes what this repo ships, and
that party's own customers are one hop further out and are never this reader.

It is written in two places and deliberately not in the other twenty. `RELEASES-portable.md` carries the
rule and the measurement, because that is where the tier model is defined. The guidance block in
`entry-scaffold-lib.ps1` carries a three-line version, because that block is rendered into every
development document and is the line an author is looking at *while* scoring -- the report named it for
exactly that reason. Everywhere else the phrase appears it is a name for the tier, not a definition of it,
and a name is not where this gets fixed.

The guidance version is deliberately tier-agnostic, so it stays correct under a tier-1 repo's `{0}` too: a
commissioner who resells has customers of their own, one hop past the repo just the same.

**It is a continuation of the reader sentence rather than a paragraph of its own, and that is issue #928
one clause further down.** `Remove-EntryAudienceGuidance` drops the whole paragraph carrying `{0}` in a repo
that states no audience tier, fenced by separator lines. Written as its own paragraph -- which is how it was
written first -- the clause survives that removal and opens with "that reader" after the clause naming that
reader has gone: exactly the mid-sentence paragraph #928 was filed for, reappearing in the same consumers,
and invisible here because this repo's `repo-config.ps1` states tier 2. Keeping it inside the paragraph is
also the right answer on the merits, since a repo asked about every tier has no single "that reader" for the
clause to qualify. Caught by rendering both states rather than by a gate, so the new assert is what makes
the next split fail loudly: the existing #928 asserts derive the paragraph from the seam and would simply
see a shorter one.

**Score:** 3

#### What makes this deploy extra special

Every consumer writes this question into every branch document they open, and answers it on every entry --
so the ambiguity is not this repo's alone, and the repos most exposed to it are precisely those whose own
subscribers are businesses: both BWJ store repos, and the webshop that filed #620 and gave the model its
two-kinds-of-audience shape in the first place. They get the sharpened question the next time `new-branch`
runs after this release, and the reasoning behind it in `RELEASES-portable.md`.

Scoring this 3 rather than `N/A` is the rule being applied to its own entry. The reading it corrects would
have reached past the consuming repos to their customers, found nobody, and written `N/A` -- which is the
exact move that cost a required migration its place on the `v5.1.0` audience note.

**Score:** 3

#### Pull Request

Name the tier-2 subscriber explicitly: the consuming repo, never its own customers

Plugins: dkj-policy

Resolves [#1896](https://github.com/DKJ-Solutions/dkj-claude-plugins/issues/1896).
