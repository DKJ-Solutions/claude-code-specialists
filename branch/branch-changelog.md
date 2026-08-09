## `feat/teams-and-workflows-tree` changelog

### Branch title

The plugin tree is grouped into teams and workflows

### Branch ID

20260809-053023

### Branch type

feat

### What does the change on this branch bring to main?

The tree now has the shape the names got on the previous branch:

```text
plugins/
├── agent-shared/          build source for the team plugins -- not a plugin
├── INSTALL.md
├── UNINSTALL.md
├── teams/                 team-alpha · team-ecomm · team-lifehub · team-shopify
└── workflows/             workflow-davekjohn
```

**Invisible to a consumer, deliberately.** A plugin is installed by name, and no name changed here —
only the repo-internal `source` in the marketplace. Nobody reinstalls anything for this.

**Two things stayed put, and both for the same reason.** `agent-shared/` is build source rather than a
publishable plugin — its generator writes shared blocks *into* plugin agent defs — so it sits beside
`teams/` and `workflows/` rather than inside one. `INSTALL.md` and `UNINSTALL.md` explain the whole
family rather than one group. Those two directories hold plugins and nothing else, which is what makes
them readable at a glance; the same reasoning already keeps `connectors/` at the repo root.

**What this branch measures, and the reason it was worth splitting off.** The move produced **45** lint
findings, and every single one was a **dead link in a document**. Not one production script broke —
because the previous-but-one branch had already taken the layout out of all of them. The single script
edited here is the blueprint generator, and only to remove the one hardcoded plugin path left in the
repo: its `-OutputPath` default. It is derived now, and refuses rather than guessing if no published
plugin carries a `blueprint/` directory. That literal had already been edited once for the rename; this
is the last time it needs editing for anything.

**Two link classes a name-only sweep does not catch**, both created by the extra directory level: a link
from `plugins/INSTALL.md` into a plugin is relative to `plugins/` and is now one segment short, and a
link from *inside* a moved plugin back out to the repo root needs one more `../`. Eleven of the 45.

One test was quietly hollowed out again and is repaired: the deliberately **flat** fixture in
`release-lib.tests.ps1` had its file paths swept to the nested shape while its own marketplace stayed
flat, so it matched nothing and asserted zero touched plugins. It is flat again on purpose — the nested
case is a separate fixture, and having one of each is the coverage.

### Significance

#### Tier 0

The directory tree stops being something you have to know and starts being something you can read. It
also removes the last hardcoded plugin path in the repo, which is the small permanent gain rather than
the visible one.

**Score:** 3

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Barely, and the honest answer is that this branch's value to a colleague is the *evidence* rather than
the change: 45 findings, all documentation, zero production scripts. That is what says the derivation
work two branches ago actually held, and it is the reason the next structural move will be cheap.

**Score:** 2

#### Tier 2

Is this next one still relevant for a consumer of the product?

No. A plugin is installed by name and no name changed; only the repo-internal `source` moved. A consumer
who updates gets identical payload at identical ids and has nothing to do.

**Score:** N/A

### Pull Request
