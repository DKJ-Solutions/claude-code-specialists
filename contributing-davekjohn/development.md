## Development: `fix/adoption-handover-and-jsonc-caveat-v1` · 20260829-183542

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

Repair three inbound defects from the testrun-2 adoption (#1093, #1096, #1097). Under Dave's decision of 2026-08-29 the disable-model-invocation flag on specialists-init STAYS, so the four sites that name the skill must name the actor and the slash command instead of the bare imperative; and the copy instruction for settings.suggested.jsonc must warn that its comments are illegal in strict-JSON settings.json.

### CREATE

- [x] Verify all three reports against the tree before touching anything — symptom, reason, repair,
      size, subject and repo. All three stand; one correction to #1096's reasoning is recorded under
      TEST.
- [x] Put the one decision that is not a craft call to Dave: keep the flag and repair the handover,
      or drop the flag. Answered **keep** (August 29, 2026), which is what makes the wording repair
      the right one rather than a guess.
- [x] Name the command and the actor at the three script sites — `check-roster-sync.ps1`,
      `check-script-contract.ps1`, `adopt-config.ps1` — in both the root copy and the plugin mirror,
      which are byte-identical and must stay so.
- [x] Give `orchestrator/SKILL.md` the #734 treatment: it is the one page upstream of the barred
      step that the model may actually read, framed as a route and explicitly not a licence.
- [x] Record the decision itself on `specialists-init/SKILL.md`, beside the section that already
      says step 0 is the owner's, so the premise is settled once instead of rediscovered per testrun.
- [x] Warn about the JSONC boundary where the reader crosses it: the step-3 output, the proposal
      file's own header, and the skill page's step 2.
- [~] Dropped: the regression guard #1093 offers ("a sync check asserting no message names a
      barred skill with a bare imperative"). A real risk that has not bitten in a way this branch
      must repair, so it is filed rather than built, per this repo's no-pre-emptive-fixes rule —
      [#1104](https://github.com/DaveKJohn/claude-code-specialists/issues/1104), which carries the
      contrast case that would make a naive version of the check wrong on its first run.

### TEST

Lint gate green (`check-plugin-integrity.ps1`, 0 findings over 31 checks); the suites run in the
push gate rather than twice.

Three things were measured rather than assumed, and two of them changed the work:

- **The files are LF, not CRLF.** A first pass joined the inserted comment blocks with `\r\n` and put
  mixed endings into two scripts. Reverted and redone against the measured ending. Worth writing down:
  every `.ps1` in this tree is LF with no BOM, and nothing in the gate would have caught the mixture.
- **#1096's reasoning is half wrong, and the half that fails is the one that made the decision look
  forced.** It states that adoption *"has no upstream model-visible page"* — its first step being the
  barred one — and concludes the #734 treatment cannot reach it. But `orchestrator/SKILL.md` carries no
  flag, and the two `[BOOTSTRAP]` markers are SessionStart hooks: three model-visible surfaces stand
  upstream of the barred step. So option B was always fully available, which is what let the decision be
  made on cost rather than on necessity.
- **The three scripts are byte-identical mirrors** (root and plugin). Each edit was applied to the root
  and copied over, and the identity re-checked afterwards.
- **`main` reached two of the four sites first, while this branch was open** (August 29, 2026). #1111
  added a lint rule refusing a printed instruction that names a skill the model cannot invoke, and
  #1114 followed it; between them they landed the wording for `check-roster-sync.ps1` and
  `adopt-config.ps1`. Merging `main` in produced four conflicts — those two files and their plugin
  mirrors — and after resolving them `adopt-config.ps1` has no diff against the trunk at all, while
  `check-roster-sync.ps1` keeps only the reasoning comment. The DEPLOY section above was corrected to
  say so: it had claimed all four wordings and a first appearance of `/team-alpha:specialists-init`
  in a shipped file, and `a6bff813` got there first.

### DEPLOY: `fix/adoption-handover-and-jsonc-caveat-v1`

Adoption stopped being a path a consumer can only complete by guessing. Four places told the reader to
run `specialists-init`; that reader is usually the model, and `disable-model-invocation` structurally
forbids it — while the same flag hides the page documenting the route, so it could not even learn the
skill exists. All four now name the command and who types it — two of those wordings reached `main`
ahead of this branch, through #1111's lint rule against printing an instruction that names a skill
the reader is barred from running; this branch carries the remaining two, in
`check-script-contract.ps1` and `orchestrator/SKILL.md`, and the recorded reasoning behind all four,
which that rule landed without. Separately, the instruction that copies
`settings.suggested.jsonc` into strict-JSON `settings.json` now says the `//` lines have to go.

The flag stays, deliberately: dropping it would have loaded this skill's description into every
session of every consumer, forever, for something that happens once per repo. That decision is now
written on the skill page rather than left implicit, together with the reason a runbook cannot claim
to run adoption end to end on its own.

**Score:** 3

#### What makes this deploy extra special

Two failures a consumer could not diagnose from inside their own repo. The first left a fresh session
told to act with nothing it could act on, one absolute path away from running the bootstrap itself —
the substitution the refusal exists to prevent. The second is worse for being silent: copying the
proposal's comments into `settings.json` makes Claude Code discard the **whole** file, so `deny`
(`git push --force`, `git reset --hard`, `rm -rf`), `allow`, `enabledPlugins` and
`extraKnownMarketplaces` were all inactive behind one startup line that says *malformed JSON* rather
than *your safety rules are off*.

**Worth one check on an already-adopted repo:** if `.claude/settings.json` was filled from the
proposal, confirm it parses. If it does not, nothing in it has ever been in force.

**Score:** 4

#### Pull Request

The adoption path becomes followable: the handover is named, and the JSONC trap is warned about

