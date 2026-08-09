## `feat/one-workflow-at-a-time` changelog

### Branch title

Exactly one workflow may be enabled, and the core says so

### Branch ID

20260809-105633

### Branch type

feat

### What does the change on this branch bring to main?

"Exactly one workflow" was a sentence in six plugin descriptions and nowhere else. It is now something
the system can observe. Two enabled workflows answer the same questions differently — how a branch is
named, how a change reaches the trunk, what a release is — and nothing in the session says which answer
belongs to the repo, so the specialists would pick, silently and differently each time. That is worse
than either workflow on its own.

**The check lives in the core team, and that placement is the design rather than a convenience.** A
SessionStart hook in `team-alpha` counts the enabled plugin ids whose name starts with `workflow-`.
Putting it in each workflow instead would be symmetrical and would fail exactly where it is needed: a
conflict takes two plugins and only one of them has to have left the check out. The core is the one
plugin every consuming repo enables, so it is the only place that can see all the workflows at once —
and it keeps `workflow-default` free of hooks and scripts, which is what lets that plugin stay as thin
as it claims to be.

**What it reports, and what it deliberately does not.** Zero workflows is **silent**: a repo may run the
specialists with no workflow at all, which the README says in as many words, so a notice there would be
this plugin having an opinion about somebody else's repo. One is silent, because a session start should
be quiet about ordinary states. Two or more is an `[ERROR]` naming each id **and the settings layer that
enabled it** — that second half is the useful one, because a conflict arriving from the machine-wide
layer looks identical, from inside the repo, to one the repo caused, and without it the reader opens the
wrong file first. It never blocks: always exit 0, like the three session checks before it.

**The consequence that needed its own gate: the `workflow-` prefix stopped being a label and became a
mechanism.** The hook decides what a workflow *is* by that prefix alone, which is deliberate — a workflow
written by somebody else is then covered by naming, carrying none of this repo's code. But it holds only
while the name can be trusted. A plugin called `davekjohn-workflow` would be a workflow the check never
counts, so enabling it beside another would pass in silence: the exact failure the check exists to
prevent, arriving through a naming choice nobody thought was load-bearing. So **lint check 23**
(`[plugin-kind]`) holds every published plugin to being `team-*` under `plugins/teams/` or `workflow-*`
under `plugins/workflows/`, and refuses a name that is neither. The directory half keeps the tree
readable and a reader can see a violation; the naming half cannot be seen by reading anything, which is
why it needs a gate rather than a convention.

### Significance

#### Tier 0

The prefix is now load-bearing, so adding a plugin means choosing its kind first — which is one more
thing to know, and the reason the checklist in `README.md` gained a step for it rather than a sentence
somewhere.

**Score:** 2

#### Tier 1

Is this next one still relevant for a colleague working on this project?

Yes. A misconfiguration that produced no error and no visible symptom — just specialists behaving
inconsistently for reasons nobody could point at — now announces itself at the next session start, and
says which of the three settings files to open.

**Score:** 3

#### Tier 2

Is this next one still relevant for a consumer of the product?

Yes, and it matters most to the ones who are about to have a choice for the first time. Until this
release there was one workflow, so nobody could enable two by accident; from now on there are two, and
the moment a consumer switches without disabling the old one they are in the state this catches. It
costs them nothing when they are right, and it never blocks a session.

**Score:** 3

### Pull Request
