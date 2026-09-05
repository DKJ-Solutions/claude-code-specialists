## docs/1467-rename-workflows-to-dkj-policy

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

The government IS the container: the prime ministry's own files move up to the root of plugins/dkj-policy/ and dkj-policy-bwj nests inside it as a ministry. The two READMEs merge into one, and the plugin-kind gate's directory rule follows.

### CREATE

- [x] `git mv plugins/workflows plugins/dkj-policy`, and lift the prime ministry's own files from
      `plugins/dkj-policy/dkj-policy/` up to that root, leaving `dkj-policy-bwj/` nested inside it
- [x] Merge the two READMEs that then sit in one folder: the plugin's own page is the base, the
      consumer-facing halves of the old kind page fold into it, and the naming/directory doctrine goes
      up to `plugins/README.md` beside the same rule for teams
- [x] Repoint both `source` values in `.claude-plugin/marketplace.json`
- [x] Narrow the `[plugin-kind]` gate: `*-policy` / `*-policy-*` anchored on
      `^plugins\dkj-policy($|\)`; `workflow-*`, `contributing-*` and `*-codex` accepted by name and
      held to no location, because the directory that named their kind is gone
- [x] Repoint every live reference to the two moved plugin paths, and the doctrine prose that named
      `plugins/workflows/` as the kind directory
- [x] Archived release notes: link TARGETS repointed so navigation still works, PROSE left alone --
      it records what the layout was at that version

### TEST

- [x] `check-plugin-integrity.ps1` -- 0 errors; `[plugin-kind]` checked 6, `[link]` clean
- [ ] every suite in `scripts/tests/`

### DEPLOY: docs/1467-rename-workflows-to-dkj-policy

`plugins/workflows/` is `plugins/dkj-policy/`, and the prime ministry's own files sit at that root with
`dkj-policy-bwj/` nested inside it as a ministry. That completes the government metaphor #1437 opened:
the directory used to name the KIND -- a way of working -- and now names the government, with the rank
order carried by the tree instead of by a sentence.

The two READMEs that ended up in one folder are one page now. `plugins/dkj-policy/README.md` is the
plugin's own, and it absorbed the consumer-facing halves of the old kind page -- why there is no default
workflow, what enabling and disabling actually mean. The naming and directory doctrine went the other
way, up to `plugins/README.md`, where the same rule for teams already lived.

**The `[plugin-kind]` gate narrowed, deliberately, and that is the part worth reading twice.** Only two
name shapes still claim a directory: `team-*` claims `plugins/teams/`, and `*-policy` / `*-policy-*`
claim `plugins/dkj-policy/`. `workflow-*`, `contributing-*` and `*-codex` keep the naming half and lose
the directory half -- there is no directory left to send them to, and pointing a stranger's workflow at
this government would be worse than saying nothing. The else-branch is untouched: a name matching none
of the five shapes is still an error, because a plugin silently held to nothing is the failure that has
actually happened here.

Archived release notes were split rather than swept: their link **targets** are repointed so navigation
still works, and their **prose** is untouched, because `plugins/workflows/...` in a 4.8.0 note is a
correct statement about the layout that shipped in 4.8.0.

**Score:** 3

#### What makes this deploy extra special

**If your repo ran `adopt-workflow-folder`, one line of your own CI breaks the moment this lands, and
re-running the skill will not repair it.** `.github/workflows/branch-entry.yml` checks this repo out at
`ref: main` -- not at a tag -- and runs the gate by path, so the break arrives before you update any
plugin. The skill is additive and never overwrites, so the file it wrote once is yours to edit:

```text
- .workflow-scripts/plugins/workflows/dkj-policy/scripts/lint/check-branch-entry.ps1
+ .workflow-scripts/plugins/dkj-policy/scripts/lint/check-branch-entry.ps1
```

That is the whole migration -- one line, one file, and it is the only place a consumer's own tree names
a shared script by path. Nothing else moves for you: plugin **ids** are unchanged, so
`claude plugin install/enable`, `${CLAUDE_PLUGIN_ROOT}` and every skill invocation resolve exactly as
before, and the orchestrator `@`-import points into `plugins/teams/`, which this change does not touch.

**Score:** 5

#### Pull Request

Rename plugins/workflows to plugins/dkj-policy

