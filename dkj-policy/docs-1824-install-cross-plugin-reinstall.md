## docs/1824-install-cross-plugin-reinstall

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

#### What #1824 reports, and what verification added

`INSTALL.md`'s `dkj-team-*` section tells the reader the workflow ids are **unchanged -- do not touch
them**, then at step 3 runs `claude plugin marketplace remove claude-code-specialists`, and at step 4
reinstalls only the four team ids. Per #1820, that `remove` takes every install record keyed on the old
marketplace. So a reader with the teams **and** a workflow installed ends the procedure with the workflow
uninstalled, `enabledPlugins` still naming it, and the blockquote being the reason they never look.

**Verified here before repairing, rather than carried over.** `~/.claude/plugins/installed_plugins.json`
keys records as `<plugin>@<marketplace>` at the top level, each key holding an array of per-checkout
entries. A `marketplace remove` that retires the marketplace half therefore cannot be selective by
plugin -- which is the same-checkout, other-plugin case #1820 measured only across checkouts.

**What #1824 missed, found while verifying it.** The defect is symmetric. #1824 says the neighbouring
`contributing-davekjohn` section "does not have this problem" because its step 4 installs `dkj-policy`
explicitly -- true for the workflow half, and it is the mirror image for the team half: a reader with
teams installed who follows *that* section loses their team records at step 3, and its step 4 never puts
them back. Same defect, same page, one edit away, so it is repaired here rather than filed.

The third section (`Migrating from the old plugin names`) is already self-sufficient: its step 2 and
step 4 span every id, teams and workflow together. It needs only the corrected statement of reach.

#### The decision the issue asked for

#1824 offers two repairs and argues for the first. Taking it: **make each section self-sufficient**,
because a reader following one section top to bottom is what this page optimises for -- the same reason
#1820's own repair kept the order and stated the consequence instead of reordering the steps. Option 2
(tell the reader to run the neighbouring section too) makes two independent renames into a sequence
they are not.

#### Root cause, stated once and therefore repaired in every copy

The under-statement is one sentence repeated verbatim in all three sections: the step-3 comment says the
`remove` drops "the install records of every OTHER checkout on this machine". That is one of its two
axes. It also drops **this** checkout's records for plugins step 2 never named. Correcting it in one
section and not the others would leave the same trap in the two copies.

### CREATE

- [x] Correct the step-3 caveat in all three migration sections: the `remove` drops every record keyed
      on the old marketplace -- every plugin, every checkout -- not only the ids step 2 named
- [x] `dkj-team-*` section: replace the "unchanged -- do not touch them" blockquote with what is
      actually unchanged (the plugin id) and what is not (the marketplace half)
- [x] `dkj-team-*` section: add the workflow reinstalls to step 4, as 4b
- [x] `contributing-davekjohn` section: add the team reinstalls to step 4, as 4b (the mirror defect)
- [x] `If this machine has more than one checkout`: name the second axis of the reach and point at the
      sections that now handle it
- [x] Widen the `enabledPlugins` inventory after the `dkj-team-*` step 4 -- it named four entries in
      and four out, which stops being the whole diff once 4b reinstalls a workflow

### TEST

- [x] `check-plugin-integrity.ps1` -- green. It caught a real consequence first: the `lifecycle` check
      requires a printed `install` to sit within 12 lines of its `marketplace update`, and the first
      draft's 4b comments pushed the last install to 13. Both comment blocks were tightened rather
      than the check worked around; that is the gate doing its job on added command lines.
- [~] All suites (`scripts/tests/*.tests.ps1`) -- dropped as a step of its own, not skipped:
      `open-pr.ps1` runs them before it pushes, and CI runs them again as `lint-en-tests`. A third
      copy started by hand proves nothing either of those would not catch.
- [x] Read all three sections top to bottom as a reader holding teams + workflow: each now uninstalls
      what it renames, warns that step 3 reaches wider, and reinstalls everything step 3 took.

### DEPLOY: docs/1824-install-cross-plugin-reinstall

`INSTALL.md`'s migration sequences each uninstall one family of ids, then run
`claude plugin marketplace remove claude-code-specialists`, then reinstall what they uninstalled. That
middle command is not selective by plugin: install records are keyed `<plugin>@<marketplace>`, so
retiring the marketplace half takes **every** plugin's record with it -- including the ones the section
never named. Both partial sections ended with a plugin silently uninstalled and `enabledPlugins` still
naming it under a marketplace that no longer exists. Nothing errored and nothing printed.

The `dkj-team-*` section was the worse of the two, because its blockquote told the reader in so many
words that the workflow ids were **unchanged -- do not touch them**, which is exactly what stopped them
looking. Both sections now reinstall what step 3 takes, as a `4b`, and the step-3 comment in all three
states both axes of the command's reach instead of only the cross-checkout one.

**Score:** 4 -- a consumer following either section loses a working plugin and gets no signal at all;
the page is the only thing that can tell them, since a session that loads no plugin has no hooks left
to complain.

#### What makes this deploy extra special

The report named one section; the defect was symmetric and the neighbouring section had the mirror of
it, which verification found rather than the report. Repaired together, because half of this repair
would have left the page saying two different things about the same command.

**Score:** N/A

#### Pull Request

INSTALL.md: marketplace remove drops every plugin's record, so each migration section must reinstall what it dropped
