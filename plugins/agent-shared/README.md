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

## What each block is for

The directory listing is the enumeration: one `.md` per block, and the filename is the `<name>` in the
sentinel. **How many agent defs carry a block is a per-block decision, not a default.** A block is added
to the specialists the rule applies to, which is what keeps a boundary about storefront previews out of a
copy editor's context.

| block | roughly who carries it |
|---|---|
| `repo-way-of-working` · `inbound-behaviour` · `laziness-automation` | everyone — these are the family's constitution |
| `language-behavior` | everyone who writes anything |
| `no-conversation-history` · `no-commit-push-pr` | the specialists who deliver material rather than land it |
| `browser-compatibility` · `webcontent-boundary` · `artifact-publishing-boundary` · `design-owner-boundary` · `changelog-entry-boundary` · `storefront-preview-boundary` | the narrow circles whose craft touches that surface |

Run `build-agent-defs.ps1 -Check` for the exact carrier count per block; a table of numbers here would be
a second statement of something the generator already knows, and would go stale the first time a
specialist joins a circle.

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
