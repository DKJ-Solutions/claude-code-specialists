## `feat/claude-app-publication` changelog

### Branch title

The Claude App marketplace becomes its own published set

### Branch ID

20260815-102849

### Branch type

feat

### What does the change on this branch bring to main?

Issue [#683](https://github.com/DaveKJohn/claude-code-specialists/issues/683) asked for three things:
map which half of this repo is aimed at Claude Code users and which at Claude App users, make the App
half easy to sync to the public repo those users read, and stop offering the workflow in an environment
where a workflow cannot work. Points 2 and 3 turned out to be one mechanism, exactly as the issue
suspected: **if the workflow is not in the published set, it is not offered, and nothing has to
remember to hide it.**

**`publish-to-business.ps1` publishes a subset now, and rebuilds the manifest to match.**
`Get-BusinessMarketplacePlugins` in `scripts/repo-config.ps1` names the plugins that travel — the four
teams — with `-Plugins a,b` as the override for a second organisation. Excluded plugin folders are
pruned after the copy and the manifest is regenerated from what is left, so the tree and the manifest
cannot disagree. A kind directory emptied of plugins goes whole, `README.md` included: a page describing
plugins that are not there is worse than no page. Measured on the real target: 152 files became 98.

**An unstated seam publishes everything**, which is what the script did before the seam existed. That
is not politeness — this script is the marketplace source's own tool and is deliberately outside the
script contract, so nothing warns a repo that has never defined the function.

**No per-entry hide flag was invented**, and the marketplace keeps its name. The manifest format has no
way to gate an entry, and one would need Claude to honour it, while a plugin that did not travel cannot
be offered by anything. `claude-code-specialists` stays the marketplace name because it is the key in
every consumer's `enabledPlugins`, so this is the same marketplace with fewer entries rather than a
second one under a new key.

**Three refusals, and each of them closes a failure that is silent on its own.** A plugin folder that
travels while the rebuilt manifest never names it is the one #683 asked about: nothing errors, Claude
simply never offers it, and the manifest reads as complete to anyone who checks it instead of the tree.
A keep-list name the manifest does not have is refused because a typo there would quietly exclude the
plugin it meant to keep and report success. A keep-list that keeps nothing is an empty marketplace, not
a subset.

**Two defects were found by running it rather than by reading it, and both are pinned by a test.** The
manifest is the one file the script both reads and writes, and `Get-Content -Raw` on Windows PowerShell
5.1 decoded the BOM-less UTF-8 source with the system ANSI codepage — the em dashes in the plugin
descriptions came back as three characters and were written out as valid, permanent mojibake on the
first dry run. And `powershell -File script.ps1 -Plugins a,b`, the invocation form this script's own
examples use, binds `a,b` as a **single string**: repeating the parameter is a bind error, so without a
split the documented form silently filters to a plugin named `a,b`.

**The map itself is in the README**, as a new section beside *Where this runs* — the rule for
classifying an item, the measurement behind it, and the answer. The rule's unit is the item and its
verdict has **three** values rather than two: `grep -rl '\.ps1' plugins --include='*.md'` returns 30
files, 28 of them genuinely repo-bound, and the two survivors are agent defs (Ravi `06-24`, Liam
`04-20`) that name a script in **one step** of one procedure. A binary map has to round those either
into "App-safe", handing a user a step that cannot run, or out of their team, losing a whole specialist
over one line. Neither is right, because a craft is portable and one step of a procedure is not — so
the third verdict is *degraded*.

**The unit for publishing is the plugin, deliberately**, even though `team-alpha` ships three PowerShell
skills and two SessionStart hooks a Claude App user cannot run either. The plugin published there has to
be byte-identical to the plugin released here, or its version number stops meaning one thing. Those five
items are already handled where they can be handled without forking: the hooks are inert in a plain Chat
session, and `v4.9.0` (#672) made all three skills non-model-invocable with their PowerShell dependency
named in their own descriptions.

Also here, found while mapping: the repo-layout section still placed `INSTALL.md` and `UNINSTALL.md`
under `plugins/`, four days after #664 moved them to the root — and their being at the root is precisely
what keeps them out of the published marketplace without an exclusion list.

Plugins: workflow-davekjohn

### Significance

#### Tier 0

The seam, the three refusals and the two defects the dry run surfaced are all this repo's own
machinery. The mojibake one is the reason the score is not lower: it produced a valid, silent,
permanent corruption in a file that Claude parses, and it would have shipped on the next publication.
The per-item map is the other half — the next person to ask "does this work without a repo" has a rule
to apply instead of a sweep to redo.

**Score:** 4

#### Tier 2

A Claude App user stops being offered a workflow that cannot work for them, and receives a marketplace
of 98 files instead of 152. They notice the first time they open the plugin list: two entries that could
only have disappointed them are gone. Nothing they had breaks — the marketplace name is unchanged, so
every `enabledPlugins` key still resolves.

**Score:** 3

### Pull Request

