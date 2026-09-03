## Development: `docs/date-1244-passage-and-roles-v1` · 20260903-112212

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

#### What this branch answers

[#1284](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1284): two statements in the
`#1244` passage of `.claude/specialists/lenses/05-15-extension.md` that the repo now contradicts --
the issue state (`#1244 is closed`, measured OPEN) and `davekokbwj`'s role (`write rights, not admin`,
measured admin). The issue's own proposed repair is followed: **date** both rather than sweep them.

#### One measurement in the report had itself moved on

The report's role table (taken 09:09 UTC) reads `maikel-bwj write`. Re-measured before writing, all
three accounts are **org owners** of `DKJ-Solutions`, so all three read `role_name: admin` on this
repo. The lens records what was measured today, not the table in the report -- the same
verify-before-repair rule the report was itself applying to the lens.

### CREATE

- [x] Verify both reported statements against the repo (`gh issue view 1244` -> OPEN;
      `orgs/DKJ-Solutions/memberships/*` -> all `admin`; ruleset `19008062` bypass list ->
      `OrganizationAdmin` + `RepositoryRole 5`, no Write role).
- [x] Date the role sentence on the `ci.yml` bullet: keep the pre-transfer fact, add the measured
      table, and state that an admin push proves nothing about the Write role.
- [x] Date the `#1244 is closed` paragraph: reopened, why (author vs. pusher), residual is #1278, and
      the half that is unaffected (#1253/#1261 folded).
- [x] Repair the three knock-on spots the above would otherwise contradict, all in the same file's
      August 14 App passage: the present-tense `admin: false ... push: true`, the "the list is empty"
      framing, the `current_user_can_bypass` inference, and the closing "the knob this turns on".
- [x] Repair the same claim in Rendall's lens (`05-06-extension.md`), which said the bypass "is back"
      without saying it came back as a different pair.

### TEST

- [x] `check-plugin-integrity.ps1` green (manifests, frontmatter, dead links).
- [x] Full suite run via `open-pr.ps1`'s gates.
- [x] No remaining statement in the tree that `#1244` is closed or that `davekokbwj` holds write and
      not admin (`grep` over `*.md`, archived release notes excluded as historical record).

### DEPLOY: `docs/date-1244-passage-and-roles-v1`

Two statements in the sysadmin lens's `#1244` passage had gone stale and are now dated against a
measurement rather than swept: **`#1244` is open**, not closed -- it was reopened because its closing
evidence read a commit's *author* as its *pusher*, and the residual runs on as `#1278` -- and
**`davekokbwj` holds admin**, not write. The second matters beyond bookkeeping: the whole `#1244`
thread turns on which account holds which role, so a fold that pushes cleanly from that account now
proves the **admin** bypass works and says nothing about the Write role. That is the exact
mis-attribution the thread had to retract, and this lens is the document the retraction cites as its
baseline.

The measured picture the lens now carries: all three accounts are **org owners** of `DKJ-Solutions`,
and the restored bypass list is `OrganizationAdmin` + a repository role with **no Write role** in it.
So the bypass follows org ownership rather than a repo permission -- a wider grant that no repo-level
setting displays -- and the old "safe while there are no external collaborators" caveat no longer
guards what it was written to guard. Four knock-on statements in the same file's August 14 App passage
were re-tensed for the same reason, and Rendall's lens, which said the bypass "is back" without saying
it came back as a *different* pair, now says which pair.

**Score:** 2

#### What makes this deploy extra special

The report proposed dating two sentences; verifying it first turned up that the report's own role
table had gone stale between filing and pickup, and that repairing only the two named spots would have
left four more statements in the same passage contradicting them. Both are the house rule working as
intended -- a reported *reason* is verified before it is repaired, and an inconsistency the repair
creates is part of the repair.

**Score:** N/A

#### Pull Request

Date the sysadmin lens's #1244 passage against the measured repo state
