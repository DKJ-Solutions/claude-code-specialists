## `docs/plugins-directory-readme` changelog

### Branch title

A README in plugins/ explaining the teams-versus-workflows split

### Branch ID

20260809-152615

### Branch type

docs

### What does the change on this branch bring to main?

`plugins/` gets its own README, completing the set the two subdirectories received a moment earlier:
it puts a team and a workflow side by side in one table — what each answers, what it ships, whether it
stacks, how it is named, and what enabling none of either kind costs — and then hands the reader the
test question that decides which kind a new plugin is: does this describe a *craft*, or a *way of
working*. It also names the two rules that guard the split and where each is checked (lint check 23
for the naming and placement, the core team's `workflow-sessioncheck` for the at-most-one count), and
what else lives in the directory without being a plugin: `agent-shared/`, `INSTALL.md`, `UNINSTALL.md`.

The page states the distinction; it does not restate the plugin table, which stays in the root README
as the single answer to "which plugins exist and who is each one for". The 9%/47% measurement that
forced the split is cited with its date rather than re-argued, so the page carries the reasoning
without becoming a second version of it. The root README's repo-layout bullet and both subdirectory
READMEs now link up to it.

### Significance

#### Tier 0

The split was explained only in the root README, roughly two hundred lines below the layout bullet
that names the directories. A developer in `plugins/` deciding whether a new plugin is a team or a
workflow now has the test question in the directory they are standing in.

**Score:** 2

#### Tier 1

Same, plus the part that is easy to get wrong once and never notice: the page says out loud that the
naming is load-bearing rather than cosmetic, because the session check counts workflows by their
prefix alone.

**Score:** 2

#### Tier 2

A consumer deciding what to enable browses this directory, and the choice they have to make — as many
teams as they like, but at most one workflow — is exactly what the page leads with. Until now the
first thing `plugins/` showed them was two folder names and two procedures.

**Score:** 3

### Pull Request

