## fix/1453-token-recovery-from-worker

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

#1453 asks Dave to confirm whether the release page's live URL survives outside the repo. It reports
the path token as absent from every local path, and offers two possibilities it calls indistinguishable
from inside the repo: the URL is recorded somewhere outside, or it is gone and every link already sent
is unrecoverable.

#### The symptom was checked first, and it stands exactly as reported

`dkj-policy/releases/page/` does not exist, no `worker-path-token.txt` exists anywhere in the tree
(`Find-StrayPathToken`, added on #1452, agrees), and `contributing-davekjohn/` is gone with the #1437
rename. `Get-ReleasePageWorkerName` does return `ccs-release-notes`, so this repo does host the page.

#### What does NOT stand is the second half, and that is this branch

The two possibilities are not exhaustive, and the one they leave out is the recoverable one. This
script writes the route into the bundle as a **literal** -- `const ROUTE = "/notes/<token>"` -- so a
worker that is still deployed *is* a copy of its own token, held by Cloudflare rather than by any
machine here. Cloudflare returns that deployed source: the worker's code view in the dashboard, and the
Workers script API. So "no token on any disk I can reach" does not imply "the URL is unrecoverable",
and #1444's document reached the same conclusion one issue earlier -- *"only Dave can say whether the
URL survives outside the repo"* -- from the same missing route.

#### The defect is that the tooling never names it, at either of the two moments it matters

The refusal under `-Worker` enumerated the ways back and named two of three: the URL you have, and
`-InitToken`. `-InitToken` is the destructive one -- it mints a path that 404s every link already sent
-- so a recovery instruction that puts it second, with nothing between, walks the reader past the
recoverable route to the irreversible one. And `-InitToken` itself said nothing about a live
deployment even where the repo names a worker, which is the moment the loss actually becomes real.

Verifying it against Cloudflare is not this session's to do -- this checkout holds no credentials and
scanning for them is blocked here -- so this branch repairs the tooling and the docs that produced the
wrong conclusion, and the issue carries the reading that is now available to Dave.

### CREATE

- [x] The missing-token refusal under `-Worker` in `scripts/release/build-release-notes-page.ps1` now
      names **three** ways back in the order worth trying: the URL you have, then the deployment, then
      `-InitToken`. The ordering is the point -- the recoverable route is named before the one that
      makes the loss permanent.
- [x] `-InitToken` warns when `Get-ReleasePageWorkerName` is non-empty: a named worker means this repo
      has hosted the page before, so a fresh token may be about to orphan a live one, and the old token
      is still readable from the deployment. Reported rather than refused -- a first-ever token looks
      identical from there, and `-InitToken` is explicit.
- [x] The script's header note gains the half both refusals left out: a lost token is not a lost URL
      while the worker is up.
- [x] Docs, all three layers: the portable
      [`release-notes-page` skill page](../plugins/workflows/dkj-policy/skills/release-notes-page/SKILL.md)
      and [`RELEASES-portable.md`](../plugins/workflows/dkj-policy/RELEASES-portable.md) for consumers,
      and this repo's own `scripts/repo-config.ps1` seam comment -- which is the sentence that most
      directly produced the issue's conclusion, since it says nothing in git remembers the URL and
      stopped there.
- [x] Mirror regenerated from the registry (`build-shared-scripts.ps1`, 1 updated).

### TEST

- [x] `scripts/tests/release-notes-page.tests.ps1`: **158 asserts, all passing**, eight of them new --
      150 before this branch, which is the count #1444 left.
- [x] The refusal enumerates the routes, names the deployment, and -- asserted on the string positions
      rather than on both being present -- names it **before** `-InitToken`. Presence alone would pass
      on the exact ordering the defect is about.
- [x] `-InitToken` warns where a worker is named, and a new unhosted fixture proves it stays **silent**
      where none is. Most consumers host nothing, and warning them about a deployment they do not have
      is the noise that teaches people to skim the yellow block.
- [x] Lint gate green (`check-plugin-integrity.ps1`); all suites green.

### DEPLOY: fix/1453-token-recovery-from-worker

The release page's path token is the one file in this system that cannot be rebuilt, and both of its
refusals used to describe the loss as worse than it is. The token is deliberately uncommitted in a
public repo and nothing in git remembers the URL it forms -- but the script writes that route into the
worker bundle as a **literal**, so a deployment that is still up is itself a copy of the token, held by
Cloudflare rather than by any machine of yours. "There is no token on this disk" and "the URL is gone"
are different findings, and only the first one is answered by looking at your own tree.

`build-release-notes-page.ps1` now names three ways back rather than two, in the order worth trying:
the URL you have, then the deployment -- the worker's code view, or the Workers script API -- and only
then `-InitToken` for a fresh path. The ordering is the repair, because `-InitToken` is the step that
404s every link already sent, and a recovery instruction that reached it second walked the reader past
the recoverable route to the irreversible one. `-InitToken` now also says so at the moment it runs,
where the repo names a worker and a live page may already be serving the old token.

Measured on this repo: with every local copy genuinely gone (#1453), the conclusion drawn was that
every link already sent was unrecoverable -- and #1444 had reached the same reading one issue earlier.
Both followed from tooling that never mentioned the deployment.

**Score:** 3

#### What makes this deploy extra special

N/A -- the person a release page is written for never meets any of this. It is a guard between the
operator and an irreversible step, and it earns its place by changing what that operator concludes on
the one day the token is missing.

**Score:** N/A

#### Pull Request
