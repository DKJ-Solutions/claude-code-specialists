## Development cycle: `docs/step-0a-names-its-destination-and-its-end-point-v1` · 20260827-183443

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

Inbound #988 from life-hub: step 0a of the cut-release skill asks for the end-to-end duration in the release document's organisational section, and step 4 says a patch writes no document at all -- so on the release type cut most often the figure has nowhere to go except the closing chat report, which step 0a names as insufficient. And its end point (when the Release is published) stops before the attachments, which step 5 deliberately uploads afterwards, so two people following it write down two different totals.

### CREATE

- [x] Verify both halves of inbound #988 against the tree before building either. Both stand: step 4 does
      say **a patch writes no document at all**, and `Get-ReleaseConsumerBumps`' shipped default really is
      minor and major, so the gap is every consumer's rather than that repo's deviation.
- [x] Move step 0a's end point to the last asset, and say why the old one was wrong -- step 5 publishes
      and *then* uploads, deliberately, so the clock stopped one action before the release finished.
- [x] State the destination requirement as conditional on a document existing, with the two honest
      answers a repo can give and the one it must not give.
- [x] Reconcile the paragraph below it, which called the closing chat report insufficient without
      qualification. Left alone it would have contradicted the new conditional in the same section --
      exactly the kind of inconsistency this branch is supposed to remove, created by the branch removing
      it. Now clause-scoped: *where a document IS written*.
- [x] Add the attachment leg to the list of legs still running when the document is frozen, since the end
      point now includes it.

### TEST

- [x] The reporter's proposed remedy is deliberately **not** adopted as stated, and the reason is a
      measurement. It asked to *"name the fallback destination rather than leaving it to each consumer to
      invent one"*. There is no file this page could name that exists in every repo: the generated tier-0
      note is rewritten by the next cut, and the release history is a generated table of rows. So this
      takes the second shape the same report offered -- state the condition -- and points a repo at its
      own release-answers page for where to record its answer. The consumer that filed it did exactly
      that, and said so.
- [x] No test pins step 0a's wording: grepped `scripts/tests/` for it and found nothing, so the change is
      prose with no assert behind it. Stated as a gap rather than papered over -- a test asserting this
      page's phrasing would pin the wording, which is not what the instruction is for.
- [x] There is exactly one copy of this SKILL.md in the tree (`plugins/workflows/.../cut-release/`), so
      nothing needs mirroring -- checked with `find` rather than assumed.
- [x] The full gate (`check-plugin-integrity.ps1` + all suites) via `open-pr`.

### DEPLOY: `docs/step-0a-names-its-destination-and-its-end-point-v1`

Step 0a of the cut-release skill asked for a measured end-to-end duration and left two things unsaid.
**Its clock stopped at the publish**, while step 5 publishes the Release and *then* uploads the
attachments -- so the step defined an end point one action before the release actually finished, and two
people following it on the same release wrote down two different totals. The end point is now the last
asset, named explicitly. **And it asked for a destination a patch does not have**: step 4 says a patch
writes no document at all, and `Get-ReleaseConsumerBumps` defaults to minor and major, so on the release
type cut most often the figure had nowhere to go but the closing chat report -- which the next paragraph
named as insufficient. The requirement is conditional now, and says so.

**Score:** 3

#### What makes this deploy extra special

**The reported remedy is not the one that shipped, and the difference is worth knowing.** #988 asked the
page to *name* the fallback destination rather than leave each consumer to invent one. There is no file
it could name: the generated tier-0 note is rewritten by every cut, and the release history is a
generated table. So this takes the other shape the same report offered -- state the condition -- and
sends a repo to its own release-answers page for where to record its answer, which is what the reporting
consumer did. The observation was right; the lever it reached for did not exist.

**5 seconds is the whole argument, not a rounding error.** The measured gap between publish and last
asset on the reported patch was 5s against a 59s release. That is small, on one attachment, and nothing
in the instruction said whether it counted -- which is precisely the defect: a step whose premise is that
the figure was *measured* cannot leave its own end point ambiguous. On a release with a dozen
attachments the same ambiguity is minutes.

**Score:** 3

#### Pull Request

step 0a names where the duration goes on a patch, and where the clock stops

Plugins: contributing-davekjohn