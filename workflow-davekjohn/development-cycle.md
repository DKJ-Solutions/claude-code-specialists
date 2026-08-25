# Development cycle: `feat/rename-workflow-to-contributing-davekjohn-v1` · 20260825-151315

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

PLAN only for now (issue #886) -- do not start CREATE until Dave says go.

## PLAN

**The ask ([#886](https://github.com/DaveKJohn/claude-code-specialists/issues/886), Dave).** Three
things, all inside one branch because they are one decision read three ways:

1. **Rename the plugin to what it does.** `workflow-davekjohn` is not a workflow among several — it is
   Dave's own contributing rules, packaged as an opt-in for his own repos. `contributing-davekjohn` says
   that; `workflow-davekjohn` says "a way of working" and invites the false symmetry with
   `workflow-default`.
2. **Remove `workflow-default` rather than rename it.** There is no default *contributing* — a consumer
   already has its own contributing by default, before any plugin is installed. Renaming it to
   `contributing-default` would keep asserting a thing that does not exist; removing it is the honest
   move Dave already made in the issue text, not a choice this branch reopens.
3. **Merge `workflow-davekjohn/CLAUDE.md` into `workflow-davekjohn/CONTRIBUTING.md`**, one file instead
   of two, because `CONTRIBUTING.md` is what this folder is actually for once it stops pretending to be a
   workflow among several.

**Scope survey, so CREATE is sized against the real subject and not a guess.** `workflow-davekjohn`
occurs in **150** tracked files, `workflow-default` in **32** — grep counts taken on this branch's base
(`main` @ 459bf667), not yet triaged into what actually needs an edit vs. what is a historical mention
that must NOT move (see Non-goals). That triage is CREATE's first job, not PLAN's; the number is here so
nobody scopes this as a small rename.

**What research already answered, so CREATE does not re-derive it:**
- **No registered consumer has `workflow-default` enabled.** Checked all three connector records
  (`smartwatchbanden`, `xoxowildhearts`, `djcylow-react`) and this repo's own
  `.claude/settings.json` — every one of them runs `workflow-davekjohn` only, none `workflow-default`.
  Removing it breaks no registered install. The repo is public, so an unregistered third party could in
  principle have it enabled — Dave's own reasoning in the issue ("not expected to have other people...
  install the plugin") already accepts that risk; this branch does not need to re-litigate it.
- **All three external consumers, plus this repo, currently have `workflow-davekjohn@claude-code-specialists: true`.**
  A plugin *id* rename is a breaking change for every one of them at their next marketplace refresh — see
  open decision B below.
- **The "exactly one workflow" guard (`workflow-sessioncheck`, lives in `team-alpha`'s hooks per
  `plugins/workflows/README.md`) counts enabled plugin ids starting with `workflow-`.** Once
  `workflow-default` is gone and the remaining plugin is renamed off that prefix, this hook's whole
  reason for existing may be gone too — see open decision C.

**Non-goals, recorded so CREATE does not sweep them in:**
- **Historical mentions stay as written.** `CHANGELOG.md`, every `releases/development/**` and
  `releases/audience/**` note, and folded PRs are published records of what was true when they were
  written (the doctrine `workflow-davekjohn/CLAUDE.md` itself states for `releases/audience/`, applied
  here to the plugin's own name). They are not rewritten to say `contributing-davekjohn` after the fact.
- **`DEVELOPMENT-CYCLE-portable.md` and `RELEASES-portable.md` are not merged into anything.** The issue
  names only `CLAUDE.md` + `CONTRIBUTING.md`; those two stay separate portable pages.
- **The root `CLAUDE.md` / `CONTRIBUTING.md` split (repo-wide, not this folder's) is untouched.** It is
  the split the folder's own pages mirror, not the reverse — collapsing the folder's mirror does not
  imply collapsing the original. Root pages only need the sentences that cite the folder's split as a
  worked example rewritten (they currently point at `workflow-davekjohn/CLAUDE.md` in at least 4 places).
- **`.github/workflows/ci.yml`'s job id `lint-en-tests` is never touched.** Unrelated string, already
  called out by name in `.claude/rules/language-layers.md` as a binding to the `main` ruleset — a rename
  here would silently unmerge every future PR. Named so nobody's find-and-replace catches it by accident.
- **`development-cycle.md` keeps its name, and so does "development cycle" as a concept — Dave reversed
  himself on this explicitly (August 25, 2026), after first not objecting to it.** The rename is of the
  *plugin*, not of this document or the phase model (PLAN/CREATE/TEST/DEPLOY) it carries. `contributing-cycle.md`
  is NOT the target filename anywhere this branch touches — not the file this branch itself is writing in
  right now, not `DEVELOPMENT-CYCLE-portable.md`'s own name, not `Get-BranchFilePaths`' path constant, not
  any doc that names the file. A future find-and-replace across the 150-file survey must skip every
  occurrence of "development cycle" / "development-cycle.md" — those are not instances of the plugin's old
  name, they are the document's own name and stay exactly as written.

**Relationship to `feat/isolate-workflow-from-consumer-root-v1`, parked (Derek stashed its uncommitted
CREATE checklist before opening this branch; nothing lost, nothing committed there).** That branch is
mid-flight hardening the *same folder's* seam under the *current* name — `Get-ChangelogPath`,
`Get-ReleaseHistoryPath`, the provenance allowlist, all written against `workflow-davekjohn/...` paths.
Landing this rename first would make that branch's whole CREATE checklist stale before it is ever
resumed (wrong paths, wrong function names to grep for); landing the isolation branch first means this
rename's own CREATE has to move the seam's paths too, on top of the plain rename. **Open decision E**
below is which order Dave wants.

**Open decisions — for Dave, before CREATE is scoped:**

- **A. Does `plugins/workflows/` stay as the directory name?** Assumption unless told otherwise: yes —
  the issue asks to rename the *plugin*, not the category folder, and renaming both in one branch doubles
  an already-large diff. Lint check 23 (`[plugin-kind]`, `check-plugin-integrity.ps1`) currently pairs the
  `workflow-` id prefix with living under `plugins/workflows/`; if the id drops that prefix, this check's
  rule needs restating regardless of A's answer.

  
  Dave's answer: Yes, keep plugins/workflows/

  
- **B. Migration path for the 3 registered consumers + this repo, all on `workflow-davekjohn@claude-code-specialists: true` today.**
  A marketplace rename makes that id resolve to nothing at their next `claude plugin marketplace update`.
  Options: (i) accept the breakage, follow up with a manual PR per consumer repo — Dave owns all four
  checkouts, so this is small in absolute terms; (ii) a temporary alias/shim plugin id that points at the
  new one; (iii) something else. No CREATE work starts on this until Dave picks.

  Dave's answer: Option 1. I accept the breakage. I'm the only consumer so I it's something I can fix easily myself.

  
- **C. Retire the "exactly one workflow" exclusivity guard, or keep it for a category that (for now) holds
  one plugin?** If retired: `workflow-sessioncheck` (in `team-alpha`), the "At most one, ever" section of
  `plugins/workflows/README.md`, and its test coverage all become dead machinery to remove. If kept: it
  still needs to stop matching on a `workflow-` prefix that will no longer exist.

  Dave's answer: Yes retire workflow completely. 
  
- **E. Sequencing against `feat/isolate-workflow-from-consumer-root-v1`.** ~~Land the isolation branch
  first...~~ **RESOLVED (Dave, August 25, 2026), and widened.** This rename is the last of a four-issue
  set that all edit the same shared libs — see below. Order: **#882 → #885 → #884 → this branch (#886)**,
  each its own branch/PR, so this rename only ever touches settled ground.

  

**The wider picture, found while researching this branch: #886 is one of four open issues that all edit
`workflow-davekjohn`'s shared libs, and running them independently would collide.**

| Order | Issue | Ask | Shares a file with |
|---|---|---|---|
| 1 | [#882](https://github.com/DaveKJohn/claude-code-specialists/issues/882) | Remove `prompts/` entirely — folder, skill, scripts, hook | — (standalone, shrinks the surface for 2–4) |
| 2 | [#885](https://github.com/DaveKJohn/claude-code-specialists/issues/885) | Isolation/provenance — the parked `feat/isolate-workflow-from-consumer-root-v1` branch | `fold-changelog-entry.ps1` (also #884) |
| 3 | [#884](https://github.com/DaveKJohn/claude-code-specialists/issues/884) | DEPLOY heading consistent everywhere + locked once the PR opens | `fold-changelog-entry.ps1` (also #885) |
| 4 | **#886 (this branch)** | Rename + drop `workflow-default` + merge `CLAUDE.md` into `CONTRIBUTING.md` | everything #882/#885/#884 just touched |

**#884 carries a live reversal, confirmed by Dave rather than assumed:** it asks for "What makes this
**deploy** extra special", which is the wording issue **#865** (Aug 24, 2026 — one day before this
research) moved *away from*, back to "PR", specifically because the section also lands in
`CHANGELOG.md` and the release notes where "PR" fits no better. Dave confirmed today (August 25, 2026)
that **#884 wins — "deploy" wording, deliberately reversing #865** — recency was not treated as an
argument against changing it; the reasoning was reread and the call made fresh.

**Decision B (migration for the 4 installs pinned to `workflow-davekjohn@claude-code-specialists`) stays
open** — answer it when this branch resumes, not before; #882/#885/#884 do not touch the plugin id.

Nothing in CREATE starts until A, B, C and the table above have run — #882, #885 and #884 are not yet
branched. This branch stops here per Dave's instruction ("PLAN only for now — do not start CREATE until
Dave says go").

## CREATE

- [ ] TODO: the first step of this branch

## TEST

## DEPLOY: `feat/rename-workflow-to-contributing-davekjohn-v1`

**Score:**

### What makes this PR extra special

**Score:**

### Pull Request

Rename workflow-davekjohn to contributing-davekjohn

