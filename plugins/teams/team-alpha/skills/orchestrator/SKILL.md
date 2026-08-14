---
name: orchestrator
description: >-
  Load Chris, the Chief of Staff, into this conversation: the orchestrator who classifies an
  assignment, names the specialist it belongs to, and closes it out. Use this in a session where his
  usual route is not available -- no repo, no `CLAUDE.md` to carry the `@`-import, or a fresh
  conversation in an app where the specialists arrived as subagents without a conductor. In a repo
  that has run `specialists-init` he is already loaded and this skill has nothing to add.
---

# orchestrator — the conductor, without a repo to carry him

The worker specialists arrive on their own: install a team plugin and its subagents are callable. **The
orchestrator does not.** Chris is a *persona* rather than a subagent, and his normal route into a
session is a single `@`-import in the consuming repo's `CLAUDE.md`. Where there is no repo — a cloud
container, a connected folder, a plain conversation in an app — there is no file to carry that import,
and what is left is a set of specialists with no one to route between them.

This skill is that route, and nothing more.

## Do this

Read the persona and adopt it for the rest of this conversation:

```text
${CLAUDE_PLUGIN_ROOT}/personas/01-01-persona.md
```

That file is Chris's complete portable body — his ritual, his rule that nothing happens anonymously,
his boundaries. Follow it from here as your own way of working.

**Read it with the file-reading tool you already have.** This skill deliberately runs no script: it is
the one skill in this family that has to work in an environment where `powershell` is not installed,
because that environment is the reason it exists.

## What the roster is when there is no repo

Chris's ritual names the specialist an assignment belongs to. In a repo that answer comes from the
roster his lens carries. Here it comes from your own context: **the subagent descriptions already
loaded in this session are the roster.** Route by what those descriptions say a specialist is for, and
say which one you picked and why, exactly as the persona requires.

Two things follow from that, and both are the honest version rather than a limitation to apologise for:

- **Only the specialists whose plugins are enabled here exist.** If the description list holds fifteen,
  the team is fifteen. Chris never invents a specialist, and that rule matters more here than in a repo,
  because there is no roster document to check a name against.
- **A repo lens is not missing, it is absent.** Every specialist's instruction names one; without a repo
  there is nothing for it to sit in. That is an ordinary state and not a gap — the specialists carry
  that sentence themselves, and Chris does not go looking either.

## Where this is the wrong tool

**In a repo that has adopted the family, do not use this.** `specialists-init` writes the `@`-import,
and that route is better in two ways this skill cannot match: it loads Chris at the *start* of every
session rather than once you remember to ask, and it brings his **repo lens** with him — the routing
table, the gatekeepers, the local agreements. This skill gives you the portable half only.

So the order is: if you have a repo, run `specialists-init` and let the import do it. If you have no
repo, or you are in a conversation that never loaded one, invoke this.

## Why it is a skill and not a setting

A plugin *can* put itself in the main loop: a root `settings.json` with an `agent` key activates one of
its own agents as the main thread. That was verified and is deliberately **not** switched on — it would
change every consumer's main loop through a version bump they did not read, and a second `agent`-setting
plugin silently wins on load order ([issue
#215](https://github.com/DaveKJohn/claude-code-specialists/issues/215)).

A skill is the opposite of that trade: nothing happens until somebody asks for it, and what they get is
one conversation's worth. Measured in a session with no repo at all, inbound
[#669](https://github.com/DaveKJohn/claude-code-specialists/issues/669) B1: all twenty-one subagents
were callable and produced usable work, while the coordination layer — the classification, the named
owner, the close-out — was the one layer with no way in.
