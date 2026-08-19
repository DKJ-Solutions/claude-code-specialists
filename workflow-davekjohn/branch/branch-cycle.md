# `fix/manuals-path-and-start-task` cycle · 20260820-003615

## PLAN

- [x] Verify both reports against the tree: does `.claude/manuals/` exist anywhere, and does
      `start-task.ps1` exist anywhere in the marketplace
- [x] Decide how far #767 goes -- the report offered three routes and declined to pick one

## CREATE

- [x] Tessa's two references, not the one the report counted: the `description:` AND the body line
- [x] Her body gains the layer split the correction implies -- lens in a consumer, manuals in the source
- [x] `start-task/SKILL.md` rewritten: the repo owns the script, the repo owns the taxonomy, and the
      page says what to do where the repo has neither
- [~] Writing the missing `start-task.ps1` -- not done: it is real Shopify-CLI work against one store
      estate, and which of the report's three routes is right is Dave's call, not a side effect of a
      text repair
- [~] Moving the skill to `workflow-davekjohn` -- same reason: structural, and it is Shopify domain
      work rather than workflow mechanics

## TEST

- [x] `grep -rn '\.claude/manuals' plugins/` returns nothing
- [x] `check-plugin-integrity.ps1` green -- including `[agent-def]`, `[skill-command]` and
      `[skill-param]`, the three that read exactly what changed
- [x] All test suites green

## DEPLOY

## Where I left off

Done, and one thing is worth carrying forward rather than being buried in the entry.

The seam I pointed `start-task` at is **conditional**: `scripts/lib/branch-info.ps1` is scaffolded only
when `workflow-davekjohn` is enabled, so a `team-shopify` consumer without that plugin has no such file.
My first draft named it flatly, which would have replaced one nonexistent path with another -- the exact
defect being repaired, one file along. The page hedges it now.
