## `docs/plugin-folder-readmes` changelog

### Branch title

A README in plugins/teams/ and plugins/workflows/

### Branch ID

20260809-150446

### Branch type

docs

### What does the change on this branch bring to main?

The two directories the plugins are split across each get their own README, so opening one no longer
means reading a list of folder names and guessing what binds them. Each page states what belongs in
that directory, the one rule that governs it, and what a folder inside it holds — for the teams: they
stack, and the `team-*` name plus its directory is held by lint check 23; for the workflows: at most
one may be enabled, why that check lives in the core team rather than in these plugins, and what
`workflow-davekjohn` expects from a repo's own seam. The root README's repo-layout bullet now names
both directories and links them, so the pages are reachable from the landing page rather than only by
browsing.

Both pages deliberately stop short of restating the plugin table. They name the folders and point at
the root README for the "who it's for" column, because a second copy of that table would be free to
disagree with the first and nobody reads both pages in one sitting — the failure this repo has already
paid for with the per-plugin `CHANGELOG.md` and `RELEASE.md` files.

### Significance

#### Tier 0

The split between teams and workflows was documented only in the root README, so a developer working
inside `plugins/` had to leave the directory to find out what governed it. Now the rule sits next to
what it governs. Small: they already knew the rule.

**Score:** 2

#### Tier 1

Same gain, plus one that outlasts it: the two naming rules that are load-bearing rather than cosmetic
— the `workflow-` prefix the session check counts by, and the directory each prefix implies — are now
stated where somebody adding a plugin is already looking.

**Score:** 2

#### Tier 2

A consumer receives the marketplace source as a clone of the whole repository, so these two
directories are what they browse when deciding which plugins to enable. Until now `plugins/teams/`
showed four unexplained folders and `plugins/workflows/` two, with the explanation a level up in a
1,000-line README. It is noticed the moment they open either directory.

**Score:** 3

### Pull Request

