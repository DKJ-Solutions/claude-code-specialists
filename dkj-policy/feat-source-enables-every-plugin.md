## feat/source-enables-every-plugin

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

Dave, September 8, 2026: the source is deliberately a FULL consumer -- every plugin in the marketplace
enabled, even though the add-on teams have no real work here. The reason is validation: the repo that
ships a plugin should also be a repo that loads it.

#### How this branch started

Not as a request for a feature. `.claude/settings.json` had four extra plugins enabled in the working
copy, uncommitted, written there by the harness when somebody ran a project-scope `/plugin` enable. That
was reverted first (the committed state was alpha + dkj-policy, which is what `CLAUDE.md` described), and
Dave then said the enable was the intent and the document was what should change. So this branch makes
the local dirt the declared state, and pays what the declaration owes.

#### What this branch deliberately does NOT do

- **It does not seed `Get-ShopifyLiveThemeId`.** A repo with no store has no truthful theme id, and a
  fake one would arm a guard over a revenue-serving theme on an unverified number. The standing `[ERROR]`
  is named in `CLAUDE.md` instead and filed as
  [#1570](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1570) -- the check has no third
  state for "no store here", which is a gap in the check rather than in this repo.
- **It does not fill in the eleven new lenses.** They are empty `VUL-IN` scaffolds on purpose and stay
  that way; a filled-in lens for a Liquid developer would describe work this repo does not have.
- **It does not touch `Get-RosterIgnoredIds`.** That list is reserved for a deliberate, self-authored
  omission, and adopting a specialist is the documented default -- the eleven are listed in the roster,
  not exempted from it.
- **It changes nothing under `plugins/`.** No consumer receives anything from this branch.

### CREATE

- [x] `.claude/settings.json`: all six plugins enabled -- `dkj-team-alpha`, `dkj-team-ecomm`,
      `dkj-team-lifehub`, `dkj-team-shopify`, `dkj-policy`, `dkj-policy-bwj`.
- [x] `sync-roster.ps1` run: 11 lens scaffolds created under `.claude/specialists/lenses/`
      (06-26, 06-27, 06-28, 02-10, 03-08, 03-14, 04-03, 04-04, 04-20, 05-21, 05-22). Byte-identical in
      form to the existing scaffolds.
- [x] `CLAUDE.md` repo slot: "The repo consumes itself" now states all six, why the four that do not
      describe this repo are on anyway, and both costs (the eleven empty lenses, the Shopify `[ERROR]`).
- [x] `.claude/specialists/SPECIALISTS.md`: the id list regrouped **per plugin** and the eleven added;
      the roster intro states the enable-everything decision; a new paragraph says the eleven lenses are
      structurally empty and must not be worked through as a backlog.
- [x] Chris's lens `01-01-extension.md`: the "table is the routing, not the roster" paragraph rewritten
      -- it claimed the five remaining core specialists "have no repo lens (yet)", which was already
      false (all five have scaffolds), and it now also says Chris does not route to the add-on teams here.
- [~] The proposed roster rows from `sync-roster` were **not** pasted as table rows. This roster
      deliberately carries no subagent descriptions (Nolan #25: Claude Code already loads them into every
      session, ~750 tokens/session to repeat). The ids went into the id list instead, which is what the
      roster-sync check reads.
- [~] `README.md`: nothing to change. Its `enabledPlugins` prose is about how a *consumer* adopts
      plugins in general and makes no claim about which set this repo itself enables (checked lines 214-232,
      355-368, 418-428).
- [~] `Get-ShopifyLiveThemeId` seam: dropped, see PLAN above -- filed as #1570 instead.

### TEST

- [x] `scripts/sync/check-roster-sync.ps1`: was 22 errors (11 agents x no row + no lens), now
      **0 errors, 2 info** -- the two info lines are `dkj-policy` and `dkj-policy-bwj` shipping no
      `agents/` directory, which the check skips by design. This one is a step because it is not part of
      any gate: it runs from a SessionStart hook, so nothing on the way to the merge would have caught it.

#### The lint and test gates are deliberately NOT steps here

`open-pr` runs `check-plugin-integrity.ps1` and every suite in `scripts/tests/` before it pushes, and it
refuses the push on a failure. A step saying "lint green" could therefore only ever be ticked *before* the
run that proves it -- which is the tick-in-advance this document's own guidance is written against, and
this repo has measured 14 branches doing it. The gate's verdict is recorded where it belongs: the PR's
check run.

### DEPLOY: feat/source-enables-every-plugin

The source repo now enables **every** plugin in its own marketplace, not just the core team and the
workflow, and says why: a plugin whose agent defs, manifests and hooks are never resolved anywhere is one
whose install is only ever proven in somebody else's session. Enabling all six means a frontmatter that
stops parsing, a manifest that goes stale or a hook that stops resolving surfaces at this repo's own
session start instead of downstream. The three add-on teams and `dkj-policy-bwj` have no work here and are
not expected to, so the eleven specialists they bring get roster entries and empty `VUL-IN` lenses -- and
`CLAUDE.md` and `SPECIALISTS.md` both now say, in as many words, that those eleven lenses are the intended
end state and not a backlog. The one cost that cannot be documented away is `dkj-team-shopify`'s floor
check, which reports an `[ERROR]` every session here because it asks which theme is live and has no third
state for a repo with no store; that is named in the repo slot and filed as #1570, with an explicit
instruction not to silence it by inventing a theme id.

**Score:** 4

#### What makes this deploy extra special

N/A -- nothing under `plugins/` changed, so no released payload moves and no consumer sees anything from
this branch. It is a change to how the source repo is configured and what its own governance documents
claim.

**Score:** N/A

#### Pull Request

Enable every plugin in the source repo, with the roster catch-up it owes

