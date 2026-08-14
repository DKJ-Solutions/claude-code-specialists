## `feat/chris-arrives-without-a-repo` changelog

### Branch title

the orchestrator can be loaded by a skill, so a session without a repo still has one

### Branch ID

20260814-220450

### Branch type

feat

### What does the change on this branch bring to main?

Item **B1** of inbound [#669](https://github.com/DaveKJohn/claude-code-specialists/issues/669), and the
one thing the decision note on §E recommended building before deciding anything else. The worker
specialists arrive by themselves — install a team plugin and its subagents are callable — but the
**orchestrator does not**. Chris is a persona, and his route into a session is an `@`-import in a
consuming repo's `CLAUDE.md`. Measured in a Cowork session with no repo at all: all twenty-one subagents
worked and produced usable output, while the coordination layer had no way in. `orchestrator` is that
way in, and nothing more.

**It runs no script, and that is the property rather than an omission.** Every other `.ps1`-wrapping
skill here is fine as it is: a repo that has one also has a machine to run it on. This skill exists for
the opposite case — the environment where `powershell` answers exit 127 — so a script in it would fail
in exactly the place it was written for and nowhere else. Green on the maintainer's machine, broken only
for its own audience. `orchestrator-skill.tests.ps1` asserts the absence of every shelling-out form and
was verified to go red when one is added, because a property nobody can see is one a later edit removes
without noticing.

**It is model-invocable, which is the opposite call from the three skills locked down earlier today**
([#672](https://github.com/DaveKJohn/claude-code-specialists/pull/672)). Those write files through a
script, so a model reaching for one can start something it cannot finish. This one reads a persona into
the conversation and changes nothing on disk — a model reaching for it when a conversation needs routing
is the intended use, not the hazard.

**And it says out loud where it is the wrong tool.** Inside an adopted repo the `@`-import beats it
twice over: it loads Chris at the *start* of every session rather than when somebody remembers, and it
brings his **repo lens** — the routing table, the gatekeepers, the local agreements. This skill carries
the portable half only. Without that paragraph it would quietly compete with the better route, which is
the failure mode a test also holds.

**What the roster is without a repo** gets an answer instead of a silence: the subagent descriptions
already in the session. That keeps Chris's ritual — name the specialist and why — executable where no
roster document exists, and it keeps his hard rule intact, because a team of exactly the enabled plugins
is a team you cannot invent a member into.

### Significance

#### Tier 0

Nothing changes here: this repo loads Chris through the import and always will. What it gains is the
guard, and the recorded reason a skill in this family may deliberately have no script.

**Score:** 1

#### Tier 2

For a colleague working in an app with no repo, this is the difference between twenty-one loose
specialists and a team with a conductor — the layer #669 measured as entirely missing. It is opt-in,
costs a consumer inside a repo nothing, and tells that consumer to use the better route instead.

**Score:** 4

### Pull Request

