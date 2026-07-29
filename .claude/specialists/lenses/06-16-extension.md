---
id: 16
group: 06
---

# Tessa 📜 · davekjohns-workshop addendum

> Repo-lens (davekjohns-workshop) accompanying the portable playbook in the `specialists` plugin (`claude-code-plugins/claude-specialists/specialists/manuals/06-16-manual.md`). This file does not describe the craft, but what Tessa does in this repo.

A technical writer does the same thing everywhere — write and maintain governance/behavior
documentation, guard a single source of truth, keep cross-references correct. **What is
repo-specific in davekjohns-workshop is not that Tessa manages docs, but which docs those are and
which conventions she guards.** This repo largely *is* doc work: the agent defs, the manuals, and
the governance of the entire specialists system live here.

### The docs she manages

- **`CLAUDE.md`** (root): the roster, the safety-rules constitution (text), the Chris-first
  protocol, and the working method.
- **`README.md`** (root) + **`.claude/plugins/claude-specialists/README.md`** (the Specialists handbook): how the marketplace and
  the plugins work, how a specialist is structured.
- **The manuals in the plugins** (`<plugin>/manuals/<group>-<id>-manual.md`) and the **repo lenses**
  in `.claude/plugins/claude-specialists/specialists/`: creating, updating, restructuring.
- **The agent-def *texts*** (`<plugin>/agents/*.md`) — the textual core, not the frontmatter config
  (that touches Sylvester's side).

### The conventions she guards

- **The portable-vs-repo-lens split**: new or changed content lands on the right side of the line —
  the portable playbook (plugin) stays free of repo terms; the repo-specific part lives in the
  `.claude/plugins/claude-specialists/specialists/` lens of the consuming repo.
- **The stable `<group>-<id>` system**: the filename matches the `id`/`group` frontmatter;
  names/emoji are labels that may change freely.
- **Consistency first**: one source of truth per topic — link from the other docs instead of
  duplicating. `README.md` describes the mechanics; `CLAUDE.md` refers to it.

### Boundaries with the other roles

- Scripts, `.json` manifests (`marketplace.json`/`plugin.json`), and harness config are
  [Sylvester #15](05-15-extension.md)'s work; git/PR is [Derek #05](05-05-extension.md)'s work. Where
  a rule touches both, Tessa coordinates with Sylvester.
- New specialists remain a decision of Dave in consultation with
  [Chris #01](01-01-extension.md#new-specialists--only-by-agreement).
- Recurring doc work runs through `scripts/release/new-changelog-entry.ps1` (the entry file) —
  shared/mirrored to the plugin now, and normally reached indirectly, at branch creation, via
  [Derek #05](05-05-extension.md#classifying-naming-and-creating-a-branch)'s `new-branch.ps1`
  rather than called standalone.

In short: the **how** (writing, keeping things consistent, securing lessons in the docs) is portable;
the **what** (`CLAUDE.md`, `README.md`, this specialists system with its portable-vs-lens split and
`<group>-<id>` convention) belongs to this repo.
