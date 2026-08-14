# `agent-shared/` — one source for the boundaries that appear verbatim in many agent defs

**This directory is not a plugin.** It is the canonical source of the blocks that a generator writes
*into* the plugin folders beside it. That is why it sits here, one level above `teams/` and
`workflows/`: it is plugin **source**, but it ships in no plugin of its own.

## Why the text is copied at all

A number of bullets under **Boundaries** are word-for-word identical across many agent defs — the inbound
rule and the automation-first rule across **all 26**, the repo's-way-of-working rule across all 26 plus
the four personas. Such governance belongs *in* the agent-def body, because that body is always loaded,
including for a worker subagent somebody invoked directly. But Claude Code has no transclusion in an agent
def: what is written there is there, literally.

So the text really is duplicated on disk, and the duplication is made safe by being **generated**. One
source file, one build, and a gate that fails the moment a copy stops matching.

## The rule

> **Never edit between the sentinels.**

In an agent def or a persona the block sits between
`<!-- BEGIN shared:<name> … -->` and `<!-- END shared:<name> -->`. To change it: edit the file **here**,
then run [`scripts/agents/build-agent-defs.ps1`](../../scripts/agents/build-agent-defs.ps1), which
rewrites every carrier. Lint check 7 in
[`check-plugin-integrity.ps1`](../../scripts/lint/check-plugin-integrity.ps1) fails as soon as a marked
region deviates from its source — whether from a hand edit or a forgotten rebuild — and
`build-agent-defs.ps1 -Check` answers the same question without writing.

### The BEGIN line is generated too, and it deliberately points nowhere

It reads `<!-- BEGIN shared:<name> -- GENERATED, do not edit here -->`, and that wording has one source:
`Format-SharedBeginSentinel` in
[`agent-shared-lib.ps1`](../../scripts/lib/agent-shared-lib.ps1). Until August 14, 2026 the expander
copied the line through unchanged, so the text sat hand-maintained in **178** places with nothing
holding it — and it said `GENERATED, edit agent-shared/<name>.md`.

**That path resolves in this repo and nowhere else.** This directory sits *outside* every plugin root,
so it does not travel in the package: for a consumer the instruction pointed at a file they do not have.
Inbound [#669](https://github.com/DaveKJohn/claude-code-specialists/issues/669) C2 reported it as a dead
pointer, which understates it — three lines below, in the same agent def, the `inbound-behaviour` block
says *"You do not modify the shared core locally"* and names the issue route. The pointer told a reader
to do what the paragraph it introduces forbids.

**Both remedies #669 proposed were weighed and declined.** *Shipping this directory in the package* hands
a consumer a file they may open but which is not the source — precisely the confusion the inbound route
exists to remove. *Repointing it at `DaveKJohn/claude-code-specialists`* would add 178 references to a
personal repo, straight against C4 of the same report. And for the only reader who can act on it — a
maintainer here — the pointer is redundant: `shared:<name>` maps to `agent-shared/<name>.md` by
construction. Measured: dropping it takes those 178 lines from **17,332 to 13,027 bytes**.

**Owning the line is what makes it a rule rather than a habit.** The builder and lint check 7 both compare
the whole file against the expander's output, so a reworded sentinel is rebuilt by the one and reported by
the other — with no check of its own, and no exemption list.

## What each block is for

The directory listing is the enumeration: one `.md` per block, and the filename is the `<name>` in the
sentinel. **How many agent defs carry a block is a per-block decision, not a default.** A block is added
to the specialists the rule applies to, which is what keeps a boundary about storefront previews out of a
copy editor's context.

| block | roughly who carries it |
|---|---|
| `repo-way-of-working` · `inbound-behaviour` · `laziness-automation` | everyone — these are the family's constitution |
| `language-behavior` | everyone who writes anything |
| `filecontent-boundary` · `lens-optional` | every agent def, all 26; no persona — see below |
| `no-conversation-history` · `no-commit-push-pr` | the specialists who deliver material rather than land it |
| `browser-compatibility` · `webcontent-boundary` · `artifact-publishing-boundary` · `design-owner-boundary` · `changelog-entry-boundary` · `storefront-preview-boundary` | the narrow circles whose craft touches that surface |

Run `build-agent-defs.ps1 -Check` for the exact carrier count per block; a table of numbers here would be
a second statement of something the generator already knows, and would go stale the first time a
specialist joins a circle.

### Why `filecontent-boundary` is in all 26 rather than in a circle

It is the second-widest block, and the width was a decision rather than a default — the per-block rule
above says so. Inbound
[#668](https://github.com/DaveKJohn/claude-code-specialists/issues/668) offered the narrower option:
insert it only into the specialists that *act* on file content, not the ones that merely locate it. That
line was measured against the roster and does not hold. **All 26 agent defs carry `Read`, `Grep` and
`Glob`**, and a specialist that greps a file and reports what it found has already relayed the content
into a context that acts on it — the locating/acting split describes what a specialist intends, not what
reaches the next reader. A boundary with a hole shaped like "I was only looking" is not one.

**The web block is the deliberate contrast, and the two texts differ because their arrival does.**
`webcontent-boundary` sits in exactly two agents, because two hold fetch tools, and it can lean on *you
went and fetched this*. File content cannot: it did not arrive because a specialist reached for it, it
was simply within reach. So this block says instead that **a file being present says nothing about who
wrote it or why** — the sentence the web version has no need of.

**The personas deliberately do not carry it.** They run in the main loop of a repo whose own `CLAUDE.md`
is loaded, which is the layer that already answers for what is in that tree. The exposure this block
guards is the one the subagents have: an assignment that points them at files nobody in the conversation
has read.

### Why `lens-optional` has exactly the same 26 carriers

Same scope, and for a reason that is the mirror image rather than a copy. Inbound
[#669](https://github.com/DaveKJohn/claude-code-specialists/issues/669) C1 measured that **all four**
specialists put on that assessment hit the same friction first and independently: look for the repo lens,
fail to find it, continue on the plugin source. Every agent def names its lens in its opening sentence,
so every agent def could produce that hunt — the width follows the pointer, and the pointer is in all 26.

**A persona cannot be in that position.** It is loaded *through* the consuming repo's `CLAUDE.md`, so a
persona reading this would already be proof that a repo exists. Giving it the block would be reassuring
it about a state it can never be in.

The per-file half of the same repair sits in those opening sentences: they now say the lens is in the
consuming repo **"if it has one"**. Both halves are needed, and neither is sufficient. The pointer alone
would still leave a specialist deciding for itself what a missing file means; the block alone would sit
under **Boundaries** contradicting a sentence twenty lines above it.

## Personas carry blocks too

The generator walks `personas/` as well as `agents/`, and has since August 8, 2026. A persona is prose
rather than a bullet list under **Boundaries**, so its block sits under its own `##` heading instead of
dangling as a stray bullet; the sentinels and the never-edit-between-them rule are identical.

The widening was not cosmetic. The two specialists whose craft *is* a way of working — the DevOps engineer
and the release manager — ship as personas, so a shared block about process could never have reached its
primary readers while the generator walked `agents/` alone.

**What deliberately did not widen with it:** the lint's agent-def↔manual coupling still leaves personas
alone, because that check is about a pairing personas genuinely do not have.

## Adding a block

1. Write the canonical text as `<name>.md` here — the body only, no sentinels and no heading.
2. Add the `<!-- BEGIN shared:<name> … -->` / `<!-- END shared:<name> -->` pair to each agent def or
   persona that should carry it, with nothing between them.
3. Run `scripts/agents/build-agent-defs.ps1`, then the lint gate.

The DRY judgement about *when* a rule has earned promotion to a shared block — rather than being restated
in two places that are free to disagree — belongs to
[Ravi #24](../../.claude/specialists/lenses/06-24-extension.md). The mechanism is described once more,
from the reader's side, in the root README under
[Shared agent-def blocks](../../README.md#shared-agent-def-blocks--one-source-for-the-verbatim-boundaries).
