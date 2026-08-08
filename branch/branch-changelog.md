## `feat/specialists-read-the-repo-first` changelog

### Branch title

The specialists read the repo's own way of working first

### Branch ID

20260808-095329

### Branch type

feat

### What does the change on this branch bring to main?

Every specialist now carries a written instruction to **read the repo's own way of working before
proposing anything about process** — its `CLAUDE.md` and contribution guide, its git history, its CI, and
the scripts it already has — and to follow what it finds, including where that differs from how another
repo does it. Where a repo is genuinely silent, the instruction is to *say* it is silent and pick the most
conventional option for its stack, rather than importing a convention from elsewhere and presenting it as
the standard.

This is the behavioural half of the doctrine that
[`docs/the-plugin-serves-the-consumer`](https://github.com/DaveKJohn/claude-code-specialists/pull/520)
wrote down. That branch stated the promise; this one makes a specialist act on it. The gap it closes is
specific: adapting to the repo was described nowhere *as an instruction*, so a specialist who found no
way of working fell back on the only one it knew — ours.

The text is a shared block (`plugins/agent-shared/repo-way-of-working.md`), so it is one source filled
verbatim into every agent def rather than 30 copies free to drift.

**The mechanism had to grow by one directory to make that true, and that is the part worth recording.**
The generator and lint check 7 walked `agents/` only. But the two specialists whose craft *is* a way of
working — the DevOps engineer (branches, PRs, merges) and the release manager (changelog, versions,
releases) — ship as **personas**, because they run in the main loop and have no agent def at all. A block
about adapting to the repo would therefore have reached every specialist except the two it is most for.
So [`build-agent-defs.ps1`](scripts/agents/build-agent-defs.ps1) now collects `personas/*-persona.md`
alongside the agent defs, and check 7 walks the same two collections. This was foreseen rather than
invented: the orchestrator's routing already named *"extending the generator/lint, e.g. to personas"* as
the case where this machinery legitimately grows.

**Both halves are widened together on purpose**, and the test says why: a generator that writes a file the
gate does not read is the exact shape in which a shared block goes quietly stale — the build keeps
reporting "in sync", the gate keeps reporting green, and nothing has compared that file with its source
since the day it was placed. The test asserts against the gate's own `[shared]` coverage line rather than
against its exit code, so a gate that later narrows back to `agents/` fails instead of staying green on a
smaller surface.

In a persona the block sits under its own `##` heading rather than as a bullet under **Boundaries**,
because a persona is prose; the sentinels and the never-edit-between-them rule are identical. What did
**not** widen: the lint's agent-def↔manual coupling still leaves personas alone, since that check is
about a pairing personas genuinely do not have.

### Significance

#### Tier 0

The shared-block mechanism reaches a second file kind, so anyone editing a persona from here on is
editing a file with generated regions in it — and the gate now says so. 26 files became 30.

**Score:** 3

Is there a tier 1?

#### Tier 1

"The specialists adapt to the repo they land in" stops being a claim on a landing page and becomes an
instruction each of them carries. It is also the first change measured against the test question the
previous branch established, which is what makes that question a working rule rather than a paragraph.

**Score:** 4

Is there a tier 2?

#### Tier 2

This is the one a consumer actually feels. A specialist installed in someone else's repo now starts by
reading how that repo works, instead of reaching for the conventions of the repo it was built in. For
anyone who adopted this plugin without knowing anything about the author's way of working, that is the
difference between a teammate and an unwanted migration.

**Score:** 4

### Pull Request

