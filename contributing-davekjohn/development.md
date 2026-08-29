## Development: `docs/enabled-is-not-installed-v1` · 20260829-152217

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

A repo can be fully adopted **on paper** and carry zero plugin surface: `enabledPlugins` set in
`.claude/settings.json`, `CLAUDE.md` describing the plugins as project-scoped, and no record in
`installed_plugins.json` for that path at all. In a session there are then no skills, and the
documented workflow can only be driven by calling the shipped `.ps1` files by absolute path into the
marketplace cache -- which is what produced the sibling permission report (inbound #1076).

#### What makes it recur rather than get caught

**Every detector that would report the state ships inside the plugin that is not loaded.** Verified
in this tree: `roster-sessioncheck.ps1:265`, `connector-sessioncheck.ps1:290` and
`check-roster-sync.ps1:587` all print it, and `bootstrap.ps1` detects it as `$notInstalledIds` --
and a plugin's SessionStart hook is plugin surface too, so a repo missing the install record is
precisely the repo where none of them can fire. The detection is thorough and unreachable from the
one state it was written for. That is a documentation repair, not a code one: a check that needs the
plugin cannot verify the plugin's own arrival.

#### And the verification the report proposed needs correcting before it is written down

It says *"`/new-branch` must appear in your slash commands"*, which works -- but the neighbouring
instinct, having the session list its skills, does not. Measured in this tree: of the workflow's 14
skills, **five** are model-visible (`adopt-config`, `adopt-workflow-folder`, `check-branch-entry`,
`measure-skill`, `new-branch`); the other nine carry `disable-model-invocation: true`. The testrun's
own correction put that number at three, which was already stale when it was written -- so the docs
name the **slash-command menu**, which does not go stale, rather than a count that does.

### CREATE

- [x] `INSTALL.md`: say plainly that `enabledPlugins` is not an install, and that the check for it is
      the slash menu -- not the session's own skill listing, and not a count
- [x] `INSTALL.md`: say that every detector for this state ships inside the plugin, so their silence
      here is not an all-clear
- [x] `ADOPTION.md`: sharpen "Before you begin" so the reader can tell this failure from a page they
      simply have not reached yet, and point at the plugin-free verification

### TEST

`check-plugin-integrity.ps1`: 0 errors -- which covers the two things a doc change here can break,
the link scan and the plugin-relative link resolution, since both new blocks carry issue links and
one crosses from `plugins/ADOPTION.md` to the root `INSTALL.md`. Full suite run green.

**The claims themselves were verified against the tree rather than taken from the report**: the four
detectors by file and line, and the model-visible skill set by reading every `SKILL.md`'s
frontmatter -- which is what caught that the number the testrun corrected to three is now five.

No test suite is added. What changed is prose, and the one thing a suite could pin here -- the
model-visible skill count -- is exactly the number this change refuses to write down.

### DEPLOY: `docs/enabled-is-not-installed-v1`

`INSTALL.md` and `plugins/ADOPTION.md` now say plainly that **enabling a plugin is not installing
it**, and that a repo can look completely adopted in that state: the settings key is yours, the
install record is the machine's, and setting the first without the second leaves a session with no
skills, no subagents and no hooks while every visible surface says the adoption is done.

Both pages name the check, and both name it as the **slash-command menu** rather than as anything
the session says about itself -- several skills ship `disable-model-invocation: true` on purpose, so
a healthy session lists fewer than the plugins ship and a count read off that listing means nothing.
`INSTALL.md` points at the query that needs no plugin at all.

And both say the part that makes this recur: **all four detectors for this state ship inside the
plugin that is not installed**, so the one repo they were written for is the one repo they cannot
speak in. Their silence is the symptom, not an all-clear.

**Score:** 3

#### What makes this deploy extra special

This is the root of the day of friction the two sibling reports describe, and it is invisible from
every angle a consumer can see. It also carries a correction they need: the workflow's model-visible
skill set is five, not three -- so any verification written against a count was already wrong, and
the menu is the durable check.

**Score:** 3

#### Pull Request

the adoption says plainly that enabling a plugin is not installing it, and that its own checks are silent in exactly that state

