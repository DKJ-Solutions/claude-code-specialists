## `docs/missing-readmes` changelog

### Branch title

The two source directories that had no page now have one

### Branch ID

20260809-181137

### Branch type

docs

### What does the change on this branch bring to main?

Three directories were documented only from a distance, and the two worst cases were both **sources** whose
copies were better documented than they were.

**`scripts/` had no page at all.** It holds 60-odd files across eight subdirectories, it is the canonical
source of the 23 scripts mirrored into the plugins, and the only description of it anywhere was one bullet
in the root README's layout list. Meanwhile its *mirror* in `workflow-davekjohn` has had a page for months.
So the directory a maintainer actually edits was the one with no map, while the directory nobody may edit
had the explanation — and "never edit the mirror, change the source" was written only on the side you are
not supposed to touch. `scripts/README.md` now carries the subdirectory map, the thirteen entry points with
the skill each is reached through, the four gates and what each refuses, and why `repo-config.ps1` sits at
the top level rather than in a folder.

**`plugins/agent-shared/` had the same shape, with a sharper edge.** Its whole contract is *never edit
between the sentinels — change the source and rebuild*, and that sentence lived three directories away in
the root README. Somebody opening the directory it governs found twelve markdown files and no statement of
what they are or what happens if you edit a generated copy instead. The new page carries the rule, the
rebuild command, the `-Check` form, why the duplication is safe because it is generated, and the fact that
per-block reach is a decision rather than a default. Deliberately **no table of carrier counts**: the
generator knows that number, and a copy here would go stale the first time a specialist joins a circle.

**`workflow-davekjohn` had no root README while `workflow-default` did** — and `workflows/README.md` linked
"it has its own README" for the small one only. The larger plugin, the one with eight skills, twenty
mirrored scripts, two hooks and a seam a consumer has to fill in, was the one you could not read about from
its own folder. It now states what the workflow is in a paragraph, what each of the four folders holds,
what the eight skills are for, what it expects from your repo, and the one-workflow rule with the reason
the hook enforcing it lives in the core team instead.

All three are linked from the pages that already enumerate their directories, so none of them is reachable
only by knowing it exists.

### Significance

#### Tier 0

Two of the three gaps sat exactly where a maintainer works: `scripts/` is edited on nearly every branch,
and `agent-shared/` is the one directory where doing the obvious thing — editing the copy you can see — is
the documented mistake.

**Score:** 3

#### Tier 1

Someone new to this project could read the mirror's page and the plugin folders and still have no map of
the directory everything is actually built in.

**Score:** 3

#### Tier 2

`workflow-davekjohn/README.md` and `agent-shared/README.md` both ship inside the plugin cache, so a
consumer receives them. For the workflow plugin that is the first page they can read from the folder they
just enabled — until now the only per-plugin page they got was the one belonging to the plugin that does
nothing.

**Score:** 3

### Pull Request

