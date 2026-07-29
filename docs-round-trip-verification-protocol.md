### The round-trip verification protocol lives with the skill, and does not trust git · Docs · 2026-07-29

Addresses item 2 of [#241](https://github.com/DaveKJohn/davekjohns-workshop/issues/241). The first real
round-trip test was verified with `git status` / `git diff`, and that method was **partly blind**: the
consumer ignores `.claude/*`, so `settings.suggested.jsonc` never appeared in `git status` and
`git checkout .` did not clean it up. Since `.claude/` holds most of what the bootstrap writes, git can
miss the bulk of a teardown's effect.

The protocol now lives in the teardown's own `SKILL.md`, where an operator actually looks, rather than in
a prompt that exists once and is then lost:

- **Take a filesystem inventory per stage** — lens count, import count, both script scaffolds, the
  settings proposal — instead of trusting `git diff --stat`.
- **Run the cycle twice.** One pass cannot distinguish "does not accumulate" from "accumulates once", and
  accumulation is exactly what the first round found (1 → 2 → 3, with every hook reporting "in sync").
- **Count lone LFs in `CLAUDE.md`.** The other defect no gate saw.
- **Declare your own empty-lens convention** with `-EmptyLensPattern`, or the report keeps files it cannot
  recognise.

**The sharper warning is recorded with it:** in a repo that ignores `.claude/`, git cannot *restore* a
wrongly deleted lens either. So establish whether `.claude/` is tracked **before** running with `-Apply`,
not after. That is a materially different safety story from the one the skill was written under, and it
was only visible because the test ran somewhere real.

Item 1 of #241 (the teardown noting its own unmeasurability) and item 3 (whether the proposal file should
live outside `.claude/` at all) stay open there.
