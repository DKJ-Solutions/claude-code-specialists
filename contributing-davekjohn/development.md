## Development: `feat/repoint-org-transfer-v1` · 20260902-174417

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

Transfer verified (301 redirect, 806 PRs, secret + main-ci-gate ruleset all survived). Next: repoint the functional slugs only -- other DaveKJohn repos (life-hub, thumbnail-generator, djcylow-react), local filesystem paths and author attribution stay.

#### The classification, because a sweep is wrong here

`git grep DaveKJohn` returns **2,133** hits. Filtering out the issue/PR/blob citations and the release
archive leaves **102**, and only **30** of those are functional. The other 72 are four kinds that a
find-and-replace would break:

| kind | example | why it stays |
|---|---|---|
| other repos under `DaveKJohn` | `connectors/life-hub.json`, `thumbnail-generator`, `djcylow-react`, `ccs-testrun-*` | **not transferred** — repointing them names repos that do not exist |
| local filesystem paths | `worktree-lib.tests.ps1` (4), `connector-sessioncheck.ps1`'s `..\..\DaveKJohn\claude-code-specialists` | the checkout folder is deliberately not renamed — the install record is keyed on it |
| author attribution | `marketplace.json`, every `plugin.json` `author`, `SECURITY.md`, the `contributing-davekjohn` plugin name | Dave is still `DaveKJohn`; the org owns the repo, not the authorship |
| dated measurements | `specialists-init/SKILL.md:246`, `06-16-extension.md:239` | they record what was true on a date — rewriting falsifies the record |

### CREATE

- [x] Classify all 102 non-citation hits by hand into change / reword / leave, per the table above
- [x] Repoint the 28 functional slugs — `Get-RepoName`, `extraKnownMarketplaces`, the connector register, the shipped blueprint (both hits, one inside the JSON-escaped `Get-RepoName` body), both `adopt-workflow-folder.ps1` copies, the `specialists-init` bootstrap block and its `gh api` example, `check-consumer-drift`'s docstring, five test fixtures, the two `*-portable.md` pointers, `INSTALL.md` (4), `README.md` (2), `CLAUDE.md`, the specialists handbook and Sylvester's lens
- [x] Repoint the two prose owner mentions in Derek's lens (`lives under DaveKJohn`, `the public DaveKJohn repo`) — not slugs, so no sweep would have caught them
- [x] Record the transfer in `README.md`'s canonical-channel paragraph: a **transfer** redirect is not a rename redirect, and it holds only while nothing is created at the old path
- [x] Reword the `#669` C4 argument in `agent-shared/README.md` + `agent-shared-lib.ps1` instead of repointing it — its premise was *"a **personal** repo"*, which the transfer retired
- [~] Repoint the other three connector entries — dropped: `life-hub`, `thumbnail-generator` and `djcylow-react` were not part of this transfer and still live under `DaveKJohn`

### TEST

- [x] `check-plugin-integrity.ps1`: **0 findings** across all 33 checks — including `[config-blueprint]`, which regenerates the shipped artefact from these libs and would have caught a half-repointed blueprint
- [x] Full suite gate: **58 suites, 0 failures** (245s), covering the five fixtures that assert the repo name
- [x] `check-connectors.ps1`: the register reads `DKJ-Solutions/claude-code-specialists` and **still resolves this repo's install record** — that record is keyed on the folder path, which did not change
- [x] `git push` to the new `origin`, and `gh issue`/`gh api` against the org path, both exercised during the branch

### DEPLOY: `feat/repoint-org-transfer-v1`

The repo moved from the personal account `DaveKJohn` into the `DKJ-Solutions` organisation on
September 2, 2026, and every functional reference now names the new owner: `Get-RepoName` (so every
`gh --repo` in the tree), the marketplace source this repo consumes itself through, the connector
register, the config blueprint shipped to consumers, and the install documentation.

**The work was deciding what NOT to touch.** Of 2,133 mentions of `DaveKJohn`, 30 were functional; the
rest are other repos that did not move, local filesystem paths, author attribution, and dated
measurements. Each is named in CREATE with the reason it stays, so the next reader does not re-open
the question — and so nobody runs the sweep this branch deliberately did not.

**Nothing breaks in the meantime, and one thing must never happen.** GitHub's transfer redirect keeps
the old path resolving, which is what every existing consumer's `settings.json` still rides on. That
redirect survives only while nothing is created at `DaveKJohn/claude-code-specialists`, so that path
must never be recreated — now stated in `README.md` beside the two rename redirects it sits next to.

**Score:** 3

#### What makes this deploy extra special

A consumer needs to do nothing: their `extraKnownMarketplaces` still names the old owner, and the
transfer redirect resolves it. What changes for them is what a *fresh* adoption writes — `INSTALL.md`,
the `specialists-init` bootstrap block and the shipped config blueprint now name `DKJ-Solutions` — and
one standing condition they inherit without asking for it: the old path must never be recreated, or
every registration still pointing at it stops resolving at once.

**Score:** 2

#### Pull Request

Repoint every functional reference to the DKJ-Solutions org

