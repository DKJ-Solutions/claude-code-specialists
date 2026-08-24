# Development cycle: `feat/every-script-lives-in-a-skill-v1` · 20260824-205958

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
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

## PLAN

The scope is [#875](https://github.com/DaveKJohn/claude-code-specialists/issues/875)'s approved one and
no wider: **the shared block + the four personas + `SPECIALISTS.md`**, plus the rule applied to the one
script that prompted it. The **29 hand-written "X is lazy" sections in the manuals are deliberately out**
-- each says something about its own craft, and a sweep would flatten exactly what makes them worth
having.

## CREATE

- [x] Rewrite `plugins/teams/agent-shared/laziness-automation.md` to the agreed rule: hook / which
      skill / script.
- [x] The four personas in their own words -- Chris (routing and close-out), Bianca (intake templates),
      Derek (git by hand), Rendall (the release scripts). No sweep.
- [x] The shared-trait paragraph in `.claude/specialists/SPECIALISTS.md`.
- [x] `scripts/agents/build-agent-defs.ps1` -- 26 agent defs rewritten from the block.
- [x] Make `scripts/maintenance/measure-always-on.ps1` travel: dual-context repo root, and a
      `$PSScriptRoot`-relative dot-source of its lib instead of a repo-root one.
- [x] Register it plus `measure-context-lib.ps1` in `scripts/lib/shared-scripts-lib.ps1`, under the
      **existing** `measure-skill` skill, and generate the mirrors.
- [x] Document it on `measure-skill/SKILL.md`, with the five parameters `[skill-param]` requires.
- [x] Point the `scripts/README.md` row at that skill instead of at `—`.
- [x] Correct the pending #876 entry in `CHANGELOG.md`, whose audience answer claims the opposite.

## TEST

- [x] `check-plugin-integrity.ps1` -- 0 errors, `[skill-param]` now checking 86 parameters across 23
      shared entry points (was 22).
- [x] `shared-scripts.tests.ps1` 450 asserts, `measure-always-on.tests.ps1` 47, `agent-shared.tests.ps1`
      27 -- all green.
- [x] The mirror smoke-tested the way a consumer runs it: from a foreign working directory with
      `CLAUDE_PROJECT_DIR` set. It resolved the root, found its lib beside itself, and printed the
      four-document table.

## DEPLOY: `feat/every-script-lives-in-a-skill-v1`

**The automation-first rule now says what to build, not merely that something should be built.** It said
"an existing script/tool" three times and named neither skills nor hooks -- and a search of all fifteen
shared blocks for the word *hook* returns **zero hits in every one of them**, while 7 hook scripts ship
across three plugins and this repo runs five SessionStart hooks of its own. As it now reads: what has to
happen without anyone asking for it is a **hook**, because the harness runs it and nobody has to
remember; what somebody invokes is a **script, and every script lives in a skill** -- the question being
*which* skill, not whether. From
[#875](https://github.com/DaveKJohn/claude-code-specialists/issues/875).

**The shared block does not reach the personas, and that is where repairing only the block would have
gone wrong.** All 26 copies sit under `agents/`; the four main-loop specialists carry a hand-written
"is lazy" section instead, and the orchestrator's loads in every session. So the block, the four personas
and `SPECIALISTS.md` moved together -- each persona in its own words, because a sweep would have
flattened what each one says about its own craft. The 29 manuals are out of scope for the same reason,
not as a backlog item.

**And the rule was applied to the first script written after it.**
`scripts/maintenance/measure-always-on.ps1` (merged the day before, #876) is now registered in the
shared-scripts mirror under the **existing** `measure-skill` page rather than one of its own: same
subject, same owner, and only a skill's *description* is paid by every session -- so an existing page is
the cheap answer to "which skill", and "whether" was never the question. Two things had to change before
it could travel, both found by reading it rather than by a gate: it resolved its repo root from
`git rev-parse` alone, and it dot-sourced its lib from the **repo root**, so in a consumer the mirror
would have looked for `scripts/lib/measure-context-lib.ps1` inside the repo being measured, which has no
such file. It is dual-context and `$PSScriptRoot`-relative now, and was run from a foreign working
directory to prove it.

**The entry #876 left pending said the opposite, and it is withdrawn where it stands.** It declared the
script deliberately repo-local -- *"nothing about it ships. That is the point rather than an omission"* --
as a principle rather than as a description of that branch. It has not been released and both entries
reach a reader in the same document, so correcting it in place was the only form that does not publish a
contradiction. The reasoning it borrowed was #861's, and #861 was about a **skill**: a new always-on
description. Packaging deterministic code under a description that already exists is a different act.

**The cost is stated rather than claimed to be zero.** The skill's description gained one sentence --
132 bytes, an estimated ~42 tokens at the calibrated factor -- so this page's always-on price rises by
that much in every consumer that has the workflow plugin. An estimate, because the authoritative figure
comes from `claude plugin details` against the marketplace clone, and the clone advances on a release
rather than on this merge. That is what discoverability costs, and it is the right trade: a script
documented on a page whose description never names its subject is a script the skill will not fire for.

**Score:** 3

### What makes this PR extra special

**Consumers get the measurement, and a page that tells them it exists.** `measure-always-on.ps1` arrives
in `workflow-davekjohn`: what *their* always-on document path costs -- `CLAUDE.md` plus everything it
`@`-imports -- per document and per section, including which documents load from the marketplace clone
rather than from their own tree and how much cost that gap has queued up for their next plugin update.
Until now that number came from `wc -c` typed by hand, in the one repo that had the script.

**And every specialist they run stops naming a script as the answer.** 26 agent defs and four personas
now distinguish the three forms, so a consumer's specialist proposes a hook for what must happen unasked
and an existing skill page for what somebody invokes -- instead of proposing a script for both and
leaving it undiscoverable in a `scripts/` directory.

**Score:** 3

### Pull Request

Every script lives in a skill, and what must happen unasked is a hook
