## docs/1420-private-consumer-quote-bound

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

Issue [#1420](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1420) asked a convention
question rather than reporting a defect: this repo is public, its measurements cite their instance
verbatim, and the instances now come out of consumers that are private. Dave answered it on
September 5, 2026 with the middle option -- **quote what the finding needs, not the sentence around it**
-- so this branch writes that rule down and brings the tree into line with it.

#### What the verification changed about the scope

The issue's own measurement was checked against the tree before anything was built, and the first pass
read it as half-wrong: the English instance appeared nowhere, and #1415 looked unbuilt. That reading came
off a **stale** base -- `new-branch`'s trunk-gap warning put the base 10 commits behind `origin/main`, and
#1415 had merged in the meantime (PR #1423). Re-measured on the current trunk the issue stands in full,
and the spread is wider than it reports: the lens **twice**, `entry-scaffold-lib.ps1` and its plugin
mirror **twice each**, and the fixtures of `supremacy-declaration-gate.tests.ps1`.

#### Where the bound falls, and why the fixtures are not an exception

The check reads an **adjacency** -- `wint`/`wins` beside `` `CLAUDE.md` `` -- which is the detector's own
pattern rather than anybody's prose. That clause is what every one of these findings turns on; the
governance sentence around it (`Dit bestand blijft de grondwet`, `en is de contributor-pagina de bug`,
`and this page is the bug`) is read by nothing. A fixture is held to the same bound because a matcher
reads shape: the consumer's remaining words add no coverage, and a public repository keeps them forever.

### CREATE

- [x] `CLAUDE.md`: the rule in the `public` bullet -- the excerpt is bounded, the repo/file/line still
      published, the verbatim-citation convention explicitly not weakened, and fixtures named as in scope
- [x] `.claude/specialists/lenses/05-15-extension.md`: both passages trimmed to the adjacency plus the
      Dutch prose noun the third-term argument needs, with `smartwatchbanden/CLAUDE.md:22` carrying the rest
- [x] `scripts/lib/entry-scaffold-lib.ps1`: the wrap example and the "real sentence" paragraph trimmed,
      and the bound recorded beside `THE TWO STANDING INSTANCES` where a future author of these fixtures reads
- [x] `plugins/workflows/contributing-davekjohn/scripts/lib/entry-scaffold-lib.ps1`: mirror synced
      byte-for-byte, as the shared-scripts drift lint requires
- [x] `scripts/tests/supremacy-declaration-gate.tests.ps1`: header rewritten to cite by structure and
      line, and all six fixtures rebuilt from this repo's own words around the clause that fires
- [x] Swept the rest of the tree for verbatim private-consumer prose -- clean; the remaining quotes near a
      consumer name are this repo's own propositions or `gh` output strings

### TEST

- [x] `supremacy-declaration-gate.tests.ps1`: 42/42 asserts pass on the rebuilt fixtures, including the
      suppression case and the direction case that fails first if adjacency is ever loosened
- [~] No new assert. The behaviour under test is unchanged -- this branch rewrites the fixtures' wording,
      not the matcher -- and the existing suite is what proves the rebuild kept every case intact

### DEPLOY: docs/1420-private-consumer-quote-bound

A measurement taken in a private consumer now quotes only the fragment the finding reads. The repo, file
and line are published as before and carry the provenance; the sentence around the match stays in the
consumer's tree. `CLAUDE.md`'s `public` bullet states it, and the three sites that had gone further --
the #15 lens, `entry-scaffold-lib.ps1` with its plugin mirror, and the supremacy-declaration fixtures --
are brought back to that bound. The verbatim-citation convention itself is untouched and said so
explicitly: a bounded quote plus `file:line` is still re-verifiable, which is the property a paraphrase
loses. Test fixtures are named as in scope, because a matcher reads structure and the consumer's
remaining words buy no coverage while a public repository keeps them forever.

**Score:** 3

#### What makes this deploy extra special

N/A -- this repo publishes plugins, not a subscribed service, and nothing here reaches a subscriber. The
reader is a maintainer of this tree or of a consuming one.

**Score:** N/A

#### Pull Request

Bound a verbatim quote from a private consumer to the fragment the finding needs

