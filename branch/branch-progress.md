# Branch progress

**Branch:** `feat/significance-per-tier`

## Steps

- [x] Rename the section (`Who is this for` -> `Significance`) and its internal key, and record the
      retired name so name-matchers still accept it
- [x] `Format-EntrySignificanceSections`: `#### Tier N`, lowest first, why then `Score: N` then the
      routing question -- under every tier that has a successor
- [x] `Read-EntryTierSections` + the new first branch in `Resolve-EntryImpact`: three shapes read, one
      written
- [x] `Remove-EntryTierSections` and one entry point (`Remove-EntrySignificanceDeclaration`) for the
      documents that travel outward
- [x] Follow it through: release-lib, the lint's section-name set, `new-internal-note`
- [~] Teach lint check 13 that `#### ` inside `### Significance` may only be `Tier N` -- dropped for
      now: the parser already reports a malformed section and refuses before the PR, so a lint rule
      would be a second answer to a question that already has one. Worth revisiting only if a real
      entry gets it wrong in a way the parser lets through.
- [x] Tests: the writer, the round trip, all three shapes, three malformed cases, the strippers, the
      fence
- [x] Docs: `branch/README.md` (template + worked example), `CONTRIBUTING.md`, `CLAUDE.md`,
      Rendall #06, the `fold-changelog` skill
- [x] Mirror, lint, all suites
- [x] Take `main` in and re-run the gates on the merged tree
- [x] PR

## Where I left off

Done. Two silent defects were caught by their own tests on the first run and are written up in the
entry: a `[ref]` to a `pscustomobject` property writes to a copy, and an entry whose every section is
malformed has zero rows -- both would have sent a broken entry through as an undeclared tier 0.
