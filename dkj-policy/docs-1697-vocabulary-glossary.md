## docs/1697-vocabulary-glossary

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
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

Phase 0 of the #1697 plan: the glossary section in the root README, then the displayName labels and the marketplace descriptions. No plugin renames -- decided against in the issue's plan comment.

#### What this branch is NOT doing, and why

- **No plugin id changes.** Three of the four renames #1697 proposed were declined on the merits; the
  fourth survived and is deferred with its full cost in #1698. The reasoning for all four is now in
  `README.md` rather than only in the issue.
- **No sweep of the 101 `"this workflow"` self-references** in `plugins/dkj-policy/**`. That was the
  repair proposed in conversation, and reading the tree changed it: `plugins/dkj-policy/` calls itself
  *"this workflow"* because **workflow is this repo's own product taxonomy**, held by lint check 23
  (`[plugin-kind]`) and by the whole `## Teams and workflows` section. Sweeping it would fight a checked
  convention to import a word from a different register. The glossary states the **bridge** instead --
  the workflow plugin is the policy half of the scaffold -- so both vocabularies stand.
- **No change to `marketplace.json`'s descriptions.** Same reason: the team/workflow split they state is
  correct in its own register, and the glossary now says how it maps onto the anatomy.

### CREATE

- [x] `README.md`: new `## The vocabulary -- where these plugins sit inside an agent` section, placed
      immediately above `## Teams and workflows` so the terms are fixed before the taxonomy uses them --
      the sourced anatomy table, the two-halves bridge, the three overloaded words, and the declined
      renames with their reasons.
- [x] `README.md`: one `## Start here` row routing to it.
- [x] The six `plugin.json` `displayName` labels carry the anatomy where a person chooses what to
      install -- `(subagent scaffold)` on the four teams, `(policy scaffold)` on the two policy plugins.
      Verified free first: nothing in `scripts/`, `.github/` or any doc reads that field.
- [x] #1698 filed for the deferred rename, `prio-1`, with the measured cost and the checklist.

### TEST

- [x] `check-plugin-integrity.ps1` -- the dead-link scan is what proves the new section's own anchor and
      the `## Start here` row that points at it.
- [x] The full suite set, as CI runs it.

### DEPLOY: docs/1697-vocabulary-glossary

The README now states where these plugins sit inside an agent -- Claude Code is the harness, every plugin
here is scaffold, `dkj-team-*` is the half that says who acts and `dkj-policy` the half that says what
follows -- with each term quoted from the source that defines it. It also records why none of that renamed
a plugin: `dkj-agent` is the one name the source rules out, `scaffold` is a constant across every plugin
here and already means two narrower things in this tree, and `dkj-scaffold-core` could not have reached
its own content across a `${CLAUDE_PLUGIN_ROOT}` boundary. Each plugin's `displayName` carries the same
vocabulary to the place a person actually chooses from.

**Score:** 3

#### What makes this deploy extra special

A consumer sees the six plugins under new labels in their own plugin listing -- `(subagent scaffold)` and
`(policy scaffold)` -- and can now place them against the vocabulary they already use for agents.
Nothing to migrate: no plugin id changed, so no install, no `enabledPlugins` key and no `@`-import moved.

**Score:** 2

#### Pull Request

A glossary for the agent anatomy, and the plugin labels that carry it
