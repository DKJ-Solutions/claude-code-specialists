# Development cycle: `feat/open-questions-become-issues-v1` · 20260823-231210

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own.** It is the result, and the one part of this file that
> travels verbatim into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THE REPO ROOT, not from this directory:
> write `scripts/x.ps1`, never `../../scripts/x.ps1`.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-CYCLE-portable.md`, which ships
> with this workflow.

A new agent-shared behavioural rule: a finding that is not part of the assignment becomes a GitHub issue in the repo being worked in, so the owner can clear context instead of answering a list of questions first. Gated on there actually being a repo and an issue tracker.

## PLAN

- [x] Establish which block reaches "every specialist". Only `repo-way-of-working` carries all 30
  carriers (26 agent defs + 4 personas); `inbound-behaviour` and `laziness-automation` stop at the 26
  agent defs. So its END sentinel is the anchor, and the new block reaches the personas too -- which
  matters, because the four main-loop specialists are the ones who close a session out.
- [x] A block of its own rather than a bullet appended to `repo-way-of-working`: that block is about
  deferring to the repo's conventions, and this is about how work is wrapped up. One subject per source
  file is what lets a later circle scope it differently.
- [x] Check it does not contradict `inbound-behaviour`, which already routes SHARED-CORE improvements to
  an `inbound` issue on the source repo. It does not: the new rule is for the repo in front of you, and
  says so, pointing at that route for the other case.

## CREATE

- [x] New source `plugins/teams/agent-shared/findings-become-issues.md`, three bullets: file rather than
  ask at the end of the turn; establish there is a tracker before promising one; and the bar that keeps
  it from becoming noise.
- [x] Sentinel pair inserted after `shared:repo-way-of-working` in all 30 carriers, then generated with
  `scripts/agents/build-agent-defs.ps1`.
- [x] The two places that enumerate the blocks updated, so they are not false the next day:
  `plugins/teams/agent-shared/README.md` (the prose and the carrier table) and the four-tier list in
  `.claude/specialists/lenses/06-24-extension.md`.

## TEST

- [x] Full gate green: lint 0 errors with `[shared] checked 30`, and all 52 suites in 186s.
- [~] No new assert. The `[shared]` gate already proves the block reaches every carrier byte for byte,
  and check 7 fails the moment a copy drifts; an assert on the wording would test the wording and would
  have to be rewritten by anybody who sharpens the sentence. The reach is the thing that can break, and
  it is already covered.

## DEPLOY: `feat/open-questions-become-issues-v1`

A session that finds a bug, a stale doc or a decision that is not its own used to end by handing that
list back, so the owner had to answer everything before they could close a finished session and clear its
context. Every specialist now files those findings as issues in the repo being worked in and finishes the
assignment instead, naming what it parked. The rule reaches all 30 carriers, the four personas included,
which is the half that matters here: they are the ones who close a session out.

**Score:** 4

### What makes this deploy extra special

This changes what every consumer's specialists do at the end of a turn, in the direction the owner asked
for: fewer interruptions, nothing lost. It is deliberately gated on there being a repository and a
reachable tracker -- in a chat session with no checkout there is nothing to file to, and the rule says to
check that rather than assume it, and never to report an issue as filed where it could not be. It also
carries a bar, because a specialist that opens an issue per stray thought is worse than one that mentions
it in a sentence: search first, one subject each, say what was measured and what was inferred, and never
file instead of asking when the question genuinely blocks.

**Score:** 4

### Pull Request

Every specialist files the loose ends as issues instead of handing them back
