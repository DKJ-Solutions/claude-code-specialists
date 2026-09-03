## Development: `docs/changelog-1268-mechanism-corrected-v1` · 20260903-144325

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

Correcting three mechanism claims in the folded fix/legacy-name-test-hardcodes-v1-suffix entry, per issue #1307.

#### Why this is an ordinary docs branch and not a fold-exception edit

The fold exception covers `fold-changelog-entry.ps1` writing a branch's entry INTO
`CHANGELOG.md` and clearing the branch document. This is neither: the entry is already folded and
merged, and what changes is its prose. So it takes the ordinary branch + PR route, which is what
issue #1307 says too.

### CREATE

- [x] Verify all three reported claims against the tree before repairing any of them -- the
      reported reason is checked, not just the symptom. All three hold: `ci.yml:13` triggers on
      `pull_request` (a merge-ref checkout, as `branch-entry.yml:8` states, so NOT the branch head);
      `gh pr view 1259` fails to resolve while `7b783516` reaches `main` via `8c37c956` = PR #1267;
      `ci.yml:15` carries `push: branches: [main]`, so the merge commit IS triggered.
- [x] Re-measure every figure rather than inheriting it from #1292's comment. CI run `33729227618`
      (`pull_request`) started `07:39:34Z`, ended `07:55:08Z`; `8c37c956` landed `07:54:19Z`; #1268
      merged `10:06:12Z`; merge-commit run `33742497546` created `10:06:15Z`, cancelled `10:06:23Z`.
      One correction to that comment: it says the block landed "45 seconds before that run finished"
      -- `07:55:08Z` minus `07:54:19Z` is 49s. The entry therefore states the timestamps and
      "under a minute" rather than repeating a second-level figure.
- [x] Verify the one claim the comment asserts about repo settings instead of trusting it:
      `main-ci-gate` really does carry `strict_required_status_checks_policy: false`.
- [x] Rewrite the paragraph: the stale-certificate mechanism, PR #1267 for issue #1259, and the
      merge run as triggered-then-cancelled. The plain statement of the incident, the `**Score:** 3`
      and the surrounding text are untouched, per #1307.

### TEST

- [x] Copy edit on the diff: no non-ASCII introduced, no typographic dashes or smart quotes, the
      repo's `--` convention held, and each of the five numbers the paragraph now cites (#1259,
      #1267, #1268, #1292, #1294) resolves to what the text claims it is.
- [x] Lint gate + all suites via `open-pr.ps1`.

### DEPLOY: `docs/changelog-1268-mechanism-corrected-v1`

`CHANGELOG.md`'s account of the #1268 red trunk no longer states three mechanisms that do not hold.
It said "the check runs on the branch head"; `ci.yml` runs on `pull_request`, whose checkout is the
merge ref, so CI does test the merged tree. It credited the test block to `#1259`, which is an issue
and not a PR -- `7b783516` arrived via PR #1267. And it said "the merge is not gated", where the
merge commit's run was created and then cancelled 8 seconds later by the fold push behind it. The
replacement states what actually happened: a merge-ref certificate fixed at run creation, never
re-fired when the base moved, and spent 2h11m later. Every figure in it was re-measured here rather
than copied from the report -- which caught one more, a 45s interval that is 49s.

This is the repo's own history, in the more durable of the two places the incident is written down,
and it was the account a later reader would have reached for when this recurs. The stale certificate
stays open as #1292; the cancelled merge run was repaired as #1294.

**Score:** 3

#### What makes this deploy extra special

Nothing reaches a consumer. `contributing-davekjohn/CHANGELOG.md` is this repo's own history and
ships nowhere: no script, manual, persona or manifest changes, so a repo on either plugin sees no
difference at all.

**Score:** N/A

#### Pull Request

the changelog's account of the #1268 red trunk states the stale-certificate mechanism and the right PR number

