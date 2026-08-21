## `docs/redeploy-verify-past-the-cache` deployment

### What does the change on this branch deploy to main?

The redeploy verification step gains the failure mode it did not have: **a fetch seconds after a good deploy
can be a cached 200 with the old body**, which is indistinguishable from the silent-inactive-version failure
the step was written to catch.

**Measured on the `v4.18.0` redeploy, August 21, 2026, doing exactly what the skill says.** `npx wrangler
deploy` reported success and printed a version id. The first fetch of the worker URL answered **HTTP 200
with 265,415 bytes** -- against the 352,146 just built -- carrying none of the new release's rows and none
of the new template's `Version X.Y` labels, so it was not merely the previous release's page but a build
from before the template's second pass. A second request with `Cache-Control: no-cache` and a throwaway
query string returned **352,146 bytes, byte-identical to the built file**, and three subsequent plain
fetches agreed. Nothing had been wrong with the deploy at any point.

**Why this is worth writing down rather than shrugging at.** The paragraph above it tells a reader to
verify against the served bytes precisely because a deploy can report success while the live page stays
old -- so the observation *"200, old body"* already has a documented meaning, and it is the wrong one here.
A reader following the page in good faith concludes the documented failure has just happened. The cheap
next step is a second deploy; the expensive one is `-InitToken`, on the theory that the route is wrong,
which is the one action the skill spends a whole section warning never to take casually, because a new
token 404s every link already sent. So an unqualified check pointed at the most destructive available
remedy.

Both halves of the fix, because they reach different moments:

- **[the `release-notes-page` skill](plugins/workflows/workflow-davekjohn/skills/release-notes-page/SKILL.md)**
  gains the measurement and the ordering rule: fetch, and if the bytes are stale fetch again cache-busted
  *before* believing it, comparing against the built file with `cmp` rather than by eye -- a size that
  merely looks plausible is how a half-updated page passes.
- **the build script's own closing advice**, in both mirrors, since that is the line somebody actually reads
  at the moment they deploy rather than the page they read once. It now says to fetch twice and why. Held
  byte-identical by the shared-script drift lint, and ASCII, per the script layer's rule.

**What is deliberately NOT done.** No retry or cache-busting logic is added to any script: the script does
not deploy and does not fetch, and giving it either would make it the thing that verifies its own
publication. And no claim is made about *which* cache answered -- edge, intermediary or local -- because
one observation cannot tell them apart and the remedy is the same either way.

**Score:** 3

#### What makes this change extra special

Every consumer who hosts this page meets this on their first redeploy, and the skill had walked them into
reading a success as the one failure it documents. The asymmetry is what makes it worth a 3 rather than a 1:
the false negative is cheap to disprove -- one more request -- while the action it invites is the single
irreversible one in this whole surface, since a regenerated path token silently breaks every link already
sent to management or a commissioner. A check that points at that remedy on a false reading is worse than
no check.

The transferable half is the sentence rather than the mechanism: **a stale read and a failed publish are
indistinguishable from one request**, so any instruction to "verify against what the URL serves" owes its
reader a second read. That generalises past this worker to anything fronted by a cache, which is most
things somebody is told to go and look at.

**Score:** 3

### Pull Request

The redeploy check says to fetch twice, because the first fetch can be a cached miss
