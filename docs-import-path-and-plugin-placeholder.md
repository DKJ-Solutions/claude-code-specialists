### The import path tracks main, and the plugin placeholder is explained · Docs · 2026-08-01

Test round v10's #330, both halves. They are one PR because they are one fact seen twice: **a machine that
has run this family has two plugin directories, and the documents never said so.**

**The `@`-imports resolve through the clone; the install record describes the cache.** The imports
`specialists-init` writes point into `~/.claude/plugins/marketplaces/<marketplace>/…`, while the record's
`installPath`, `version` and `gitCommitSha` describe `…/plugins/cache/<marketplace>/<plugin>/<version>/`. The
two were hash-identical when measured, so there was nothing to see — which is exactly why it is worth writing
down now rather than after the first divergence. A `marketplace update` fast-forwards the clone, and with it
the persona body your next session loads, while `version` and `gitCommitSha` do not move because the refresh
does not touch the cache. So the QUICKSTART's own rule — *"the sha tells you which code you are running; only
the second is the truth about your session"* — is not true of the persona bodies, and that rule is the
family's own hard-won conclusion from #313.

**The issue offered two repairs and this takes the second, for a reason already on record here.** Pointing the
import at the cache would make `gitCommitSha` true about everything, and it was rejected when the seam was
built: the version-pinned cache directory is **cleaned up after an update**, so an import into it would leave
the orchestrator's body failing to load at all after the first refresh. `bootstrap-drift.tests.ps1` still pins
that choice ("the `@`-import points to the marketplaces clone", "does NOT point to the version-pinned cache").
A stale-but-loading body beats a pinned-and-gone one, so the asymmetry stays and is now stated — including
*why*, so the next reader does not "fix" it back. The QUICKSTART also names the one command that answers the
question the sha cannot: `git -C <clone> rev-parse HEAD`.

**The `<plugin>` placeholder in `UNINSTALL.md` Step 1 was never explained**, and the paragraph above is why
that mattered more than a missing definition: there are two plausible directories, both present, and the one
reachable from `SPECIALISTS.md` is the wrong one. In round v10 the executor had to reason it out instead of
reading it. Step 1 now says it is the `installPath` from the install record, gives the query, states the
typical shape, and says outright not to use the path from the imports.

**The lint gate improved that snippet rather than merely permitting it.** Check 12 rejected the first version:
a printed query that reads `installed_plugins.json` must name `projectPath`, `scope`, `version` and
`gitCommitSha`, because a reader runs such a query to answer *"what am I actually running?"*. Mine only wanted
a path. Satisfying the gate turned out to be the better document: at the moment you are choosing a teardown
target, the **scope** is exactly what you need to see, since Step 2's uninstall is scope-keyed and refuses at
the wrong one — the #325 class of mistake, one document over. The snippet prints all five fields and says why.

Lint green, all suites green. No script changed; this is documentation of measured behaviour.

Plugins: specialists
