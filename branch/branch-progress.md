## `feat/the-contract-check-sees-an-unreachable-seam` progress

### Steps

- [x] Reachability walker in `script-contract-lib.ps1`: resolve every dot-source target from the AST
      (literal, named variable, `$args[i]` into an `&`-invoked block), resolve it to a real PATH, and
      close over it transitively through both plugin libs and consumer libs
- [x] Declare `Get-BranchTypes` as an Optional record (Lib `scripts\lib\branch-info.ps1`,
      Scripts fold-changelog-entry/cut-release/new-internal-note) with a Default naming what the
      fallback costs a consumer whose types are not the canonical four
- [x] Wire the walker into `check-script-contract.ps1` as an `[INFO]` per unreachable (record, script)
- [x] Make `ViaLib` transitive in the test's completeness guard, so `new-internal-note`'s two-hop route
      (release-lib -> entry-scaffold-lib) validates instead of going red
- [x] Tests: the four dot-source shapes, the record count 22 -> 23, the new record's attribution, and a
      fixture where chaining branch-info from repo-config turns the finding green
- [x] Mirror the changed shared scripts into the plugin; regenerate the config blueprint (23 records);
      lint green
- [x] Code review: memoise the AST walk, and keep it off the SessionStart path -- both were real
      findings, see below
- [x] Lint + all 30 suites green (0 errors, 30 run, 0 failing)
- [x] Write the measurement down (the three candidate rules and why A and B mask the defect) -- it lives
      in `script-contract-lib.ps1` above the walker, with the check's docstring pointing at it
- [x] Fill in the changelog entry: body + a score per tier

### Where I left off

Done. Lint reports 0 errors and all 30 suites pass; the contract suite alone is 264 pass / 0 fail.

**Two things the measurement changed against what inbound #580 proposed**, both worth keeping in view at
review: `ViaLib` may NOT satisfy reachability (it names the plugin lib, and letting it answer both
questions makes the rule green on the very record it exists for), and the walk resolves PATHS rather
than leaf names (`release-lib` dot-sources a sibling `branch-info.ps1` that exists here and not in the
mirror, so a name-based walk would report this repo's answer at every consumer).

**Two things the code review changed**, both about a cost paid in every consumer forever. The walk
re-parsed the same libs once per record -- 3,625 ms over the 23 records, with `entry-scaffold-lib.ps1`
alone over three thousand lines -- so it is memoised per (file, repo root). And it is skipped at session
start via `-SkipReachability`, which the hook now passes: the hook filters output to `[ERROR]`/`[SCOPE]`
and a reachability finding is always `[INFO]`, so 1,470 ms per session bought nothing that could ever be
displayed. Measured after both: session start +13 ms, deliberate run +1,519 ms.
