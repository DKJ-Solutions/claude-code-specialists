## `feat/the-contract-check-sees-an-unreachable-seam` changelog

### Branch title

The script-contract check reports a seam function that is present but out of scope

### Branch ID

20260810-194705

### Branch type

feat

### What does the change on this branch bring to main?

A contract record makes two claims and only one of them was ever checked. "`Get-RepoName` lives in
`scripts\repo-config.ps1`" is presence, which `check-script-contract` probes by dot-sourcing that lib
on its own. "`fold-changelog-entry` calls it" is **reachability**, and a lib the calling script never
dot-sources is not in scope at runtime however present it is. Nothing anywhere modelled the second
half, so a declared, present, correctly-written seam function could be answered by the caller's
built-in fallback with the check reporting `[OK]` the whole time.

Inbound [#580](https://github.com/DaveKJohn/claude-code-specialists/issues/580) is the measured
instance. A consumer whose branch table produces types outside `Feat`/`Fix`/`Docs`/`Chore` had every
folded entry read as typeless under 4.0.0 — silently — and a refused fold under 4.1.0, while
`Get-BranchTypes` sat present in their `branch-info.ps1` and undeclared in the contract. The source
repo cannot feel either half: its own `Get-BranchTypes` returns exactly the hardcoded fallback, so the
fallback and the real answer are indistinguishable here.

Two things now hold. `Get-BranchTypes` is a declared `Optional` record whose `Default` says what the
fallback **costs** — a refused fold, not a degraded one — and `Test-ContractLibReachable` reports an
`[INFO]` per (record, script) pair where the lib is never reached, directly or through any lib the
script loads. Always `[INFO]`, never `[ERROR]`: every function reached this way is probed with
`Get-Command` by the lib that wants it, so the fallback is a designed state, and for a repo whose types
are the canonical four it is also the right one. What was missing was any way to learn which of the two
answers you are getting, before the fold rather than at it. A consumer closes it by making the lib
reachable from a file the script already loads; the test suite proves that repair works end to end.

**The measurement is the transferable half, because two of the three candidate rules were green on the
very defect they were built for.** Each was run over the declared records and over the reported case
before anything was written:

| candidate rule | findings | true | why it lost |
|---|---|---|---|
| a text mention of the lib leaf | 0 | 0 | `fold-changelog-entry.ps1` names `branch-info.ps1` in a **comment**, so the defect reports green |
| `ViaLib` may satisfy reachability | 0 | 0 | fold reaches `entry-scaffold-lib`, which merely **probes** for the function |
| AST, literals and named variables only | 3 | **0** | false on the `& { . $args[0] }` child-scope idiom |

So `ViaLib` is deliberately **not** an escape hatch here — it names the *plugin* lib a function is
reached through, which is a different question from whether the *consumer* lib is loaded — and the walk
resolves **paths rather than leaf names**: `release-lib.ps1` dot-sources a sibling `branch-info.ps1`
that exists in this repo and not in the plugin mirror, so a name-based walk would have reported this
repo's answer at every consumer. The built rule finds **0 findings over the 22 existing records**, so
it is born green with no exemption list, and fires on the reported case.

The same walk replaced the `ViaLib` guard in `script-contract.tests.ps1`, which was a text match and
had both failures one level up: it could not tell a dot-source from a comment, and it could not follow
`new-internal-note`'s two-hop route to `entry-scaffold-lib` through `release-lib` — a route already in
the tree, which it would have called a stale record.

Plugins: workflow-davekjohn

### Significance

#### Tier 0

A new contract record here is now checked on both halves instead of one, and the workshop gains one
standing `[INFO]`: `fold-changelog-entry` cannot see its own `Get-BranchTypes`. That is accurate and
costs nothing, because this repo's types *are* the canonical four — which is also exactly why the class
could never have been found from inside it.

**Score:** 2

#### Tier 1

Anyone adding a seam function to this project gets the second claim verified rather than assumed. The
failure it prevents is specific and has now happened once: a function written correctly, declared
correctly, and never in scope for the script that reads it.

**Score:** 3

#### Tier 2

A consumer whose branch types are not the canonical four learns it from a check instead of from a
refused fold, and the finding names the repair. Consumers whose types *are* the canonical four see one
informational line and have nothing to do.

**Score:** 3

### Pull Request

