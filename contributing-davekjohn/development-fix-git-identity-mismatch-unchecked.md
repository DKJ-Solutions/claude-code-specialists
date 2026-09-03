## Development: `fix/git-identity-mismatch-unchecked` · 20260903-155104

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

Issue #1315: nothing checks that the account gh acts as and the identity git commits as agree, so the
claim rule's `@me` silently writes the wrong account and Derek's cross-device tell fires by
construction. Add a SessionStart check for the mismatch, and give the tell its precondition.

#### What the report claimed, and what held on re-reading

All six citations were checked against the tree before anything was written. Every one stands, except
that the *specific* mismatch is machine-local and this checkout is not the one it was measured on:

- `gh auth status` here reads `maikel-bwj` and `git config user.name` reads `maikel-bwj` -- they AGREE,
  so the reported pairing (`DaveKJohn` / `davekokbwj`) is not reproducible from this machine.
- The repo-level defect the report names is nevertheless exactly true: a grep over `scripts/` and
  `plugins/` finds NO script that reads `gh auth status` or `git config user.name` in order to compare
  them. The only hits are one prose comment in `open-pr.ps1`. Nothing anywhere checks that they agree.
- The two cited instruction sites exist and say what the report quotes:
  `plugins/teams/team-alpha/personas/01-01-persona.md:297` and
  `contributing-davekjohn/CONTRIBUTING.md:161`, both prescribing `--add-assignee @me`.
- The cross-device tell at `.claude/specialists/lenses/05-05-extension.md:357` is stated
  UNCONDITIONALLY, so the report's second consequence holds exactly as written.
- `switch-account` is indeed gone from this tree: the only mentions are one archived release note and
  one test comment.

#### The decision the report deliberately left open

It offered two directions and picked neither. Both are taken, because they answer different halves and
neither is sufficient alone: the check makes the mismatch visible, which it is not today in EITHER
direction, and the doc half repairs an instruction that is wrong whichever account a machine is meant
to use.

#### Why the check compares NAMES and not emails, measured

The comparison one reaches for first -- does `git config user.email` belong to the authenticated
account -- is not available at session start:

```
$ gh api user --jq '{login,name,email}'  ->  {"email":null,"login":"maikel-bwj","name":null}
$ gh api user/emails                     ->  404, needs the "user" scope
   (token scopes on this checkout: 'gist', 'read:org', 'repo')
```

An email comparison would therefore mean widening a token scope to print an advisory line, which is
the wrong trade. `gh auth status` names the active account from the KEYRING -- no network, no extra
scope -- so the check reads that instead.

#### And why it fires only on a login-shaped user.name

`git config user.name` is free text, and in most repos it holds a display name (`Maikel Hoogendoorn`)
rather than a login -- so comparing it to a GitHub account unconditionally would fire forever in every
consumer that spells its name normally. This repo has already declined a check for precisely that
reason (the stale-path check, 124 findings all false, recorded in Sylvester's lens). So the check
reports only when `user.name` is itself a valid GitHub username by GitHub's own rule AND differs from
the active account: a display name with a space is silence, while the three accounts in this family
(`DaveKJohn`, `davekokbwj`, `maikel-bwj`) are all login-shaped and therefore all caught.

### CREATE

- [x] `scripts/lint/check-git-identity.ps1` -- the check itself: active `gh` account against
      `git config user.name`, local only, no network. Reports `[ERROR]` + exit 1 on a provable split,
      `[OK]` when they agree, `[SKIP]` in the three states where there is nothing meaningful to compare.
- [x] Mirrored into `plugins/workflows/contributing-davekjohn/scripts/lint/` by
      `build-shared-scripts.ps1` from a new registry entry in `scripts/lib/shared-scripts-lib.ps1`
      (`Skill = ''`, the three overrides declared as `SkillParamsExempt`) -- generated, not hand-copied.
- [x] `plugins/workflows/contributing-davekjohn/hooks/git-identity-sessioncheck.ps1` plus its entry in
      that plugin's `hooks.json`, following `unfolded-entry-sessioncheck.ps1`: forwards only `[ERROR]`,
      always exits 0, never blocks a session start.
- [x] The claim rule now names what `@me` BINDS to, in both places that state it -- Chris's portable
      body (`plugins/teams/team-alpha/personas/01-01-persona.md`) and
      `contributing-davekjohn/CONTRIBUTING.md`. The body's definition was the actual defect: it said
      "the account the session is logged in as", where the claim's own job needs the account the
      COMMITS will name.
- [x] The cross-device tell in `.claude/specialists/lenses/05-05-extension.md` has its precondition,
      naming which half of its own sentence is the `gh` account and which the `git` one.
- [x] Recorded in Sylvester's lens (`05-15-extension.md`), which owns the session checks -- including
      why there is deliberately no CI half and why the login-shape guard is what makes it shippable.

#### Not done, and why -- the `@me` idiom itself is kept

The report's second direction was to replace `@me` with an explicit account if the split is deliberate.
That is NOT taken: the idiom is correct on a checkout whose identities agree, which is every consumer
except the measured one, and hard-coding an account into a portable persona body would be wrong
everywhere else. What changed instead is the DEFINITION the idiom serves plus a check that says when
the idiom is lying -- and the check prints `--add-assignee <committing account>` as the interim, so the
by-name claim is available exactly where it is needed without becoming the default.

#### Not done, and why -- no repair of the machine itself

Nothing here writes `git config` or runs `gh auth login`. Which of the two accounts is the right one is
Dave's call, not a script's, and both ways out are printed. On DAVE-KOK-BWJ the check will fire until he
picks one.

### TEST

- [x] `scripts/tests/git-identity-gate.tests.ps1` -- 27 asserts, all green. It passes both identities in
      explicitly, so it asserts the same thing on every checkout: a suite that read the machine's own
      would go green or red for reasons unrelated to the code. Covers the measured pairing, agreement,
      the case-insensitive match, both edges of GitHub's 39-character username rule (39 reported, 40
      skipped; leading, trailing and doubled hyphens skipped), the three nothing-to-compare states, the
      mirror running from its own directory, and all four hook branches via stub check scripts.
- [x] Every branch of the check exercised against the real machine too: the live run reads
      `maikel-bwj`/`maikel-bwj` and reports `[OK]`, which is the one assert the suite deliberately does
      not make.
- [x] `scripts/lint/check-plugin-integrity.ps1` -- 0 errors. Check 18 picked the new script up on its
      own and lists it among those declaring no skill.
- [x] `shared-scripts.tests.ps1` (492 asserts), `script-contract.tests.ps1` (293) and
      `measure-skill.tests.ps1` (57) green -- the three suites that read the registry the new entry
      joins. The full suite set runs in the PR gate.

#### Test gap, named rather than papered over

The reading of `gh auth status` is not asserted. `Get-ActiveGhAccount` parses that output, including
the multi-account case where only the line marked `Active account: true` is the one `@me` binds to --
and a suite that proved it would need a keyring with two accounts in it, at which point it is testing
gh rather than this check. What IS covered is everything downstream of that string. The parse was
verified by hand against real output on this checkout (single account, active) and against the
three-line shape quoted in the function's own docstring.

### DEPLOY: `fix/git-identity-mismatch-unchecked`

On a checkout where `gh` is authenticated as one GitHub account and `git config user.name` reads
another, nothing said so. Two things broke from that, both silently. The claim rule -- `gh issue edit
<n> --add-assignee @me`, stated in Chris's persona body and in this folder's contributing page --
resolves `@me` through the GitHub API, so it wrote the account `gh` held while every commit on the
branch read the other one: measured on DAVE-KOK-BWJ, where claiming #1314 with the documented idiom put
`DaveKJohn` on work whose commits all said `davekokbwj`, and it had to be corrected by hand. And Derek's
cross-device tell -- a branch whose commits name a different account than the checkout, which the lens
teaches as the signature of work built on another device -- fires on such a machine **by construction**,
so a later session reads "built elsewhere" off a branch that never left the room.

`scripts/lint/check-git-identity.ps1` now reports the split, from a SessionStart hook in every repo that
has this plugin, at the one moment it matters: just before a session claims an issue and starts
committing. It prints both accounts, both ways out, and the by-name claim to use in the meantime; it
repairs nothing itself, because which of the two accounts is right is not a script's call. The claim rule
in both places that state it now names what `@me` actually binds to -- the defect was its definition,
which said "the account the session is logged in as" where the claim's own job needs the account the
commits will name -- and the tell in the lens has gained the precondition it always depended on.

Two things it deliberately does not do. It compares names rather than emails, although GitHub attributes
a commit by email: `gh api user` returns a null email for an account with no public one and
`gh api user/emails` needs the `user` token scope, and widening a scope to print an advisory line is the
wrong trade. And it fires only when `user.name` is a valid GitHub username by GitHub's own rule --
because that free-text field usually holds a person's name, and an unconditional comparison would fire
forever in every repo that spells its name normally, which is the shape of the stale-path check this repo
declined at 124 findings all false.

Closes [#1315](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1315).

**Score:** 3

#### What makes this deploy extra special

Both halves travel. The check and its hook ship in the workflow plugin, so a consumer with a split
identity is told at session start instead of discovering it from a tracker that disagrees with its own
branches -- and one with a single account never sees a line, which is what the login-shape guard buys. The
claim rule's corrected definition ships in Chris's persona body, which every consumer loads on every turn,
so the instruction they read is the one that matches what the tracker will actually record. Most consumers
run one account and will notice nothing; for the ones that do not, this is the difference between a claim
that means something and a claim that names the wrong person.

**Score:** 2

#### Pull Request

Report when gh and git commit as different accounts
