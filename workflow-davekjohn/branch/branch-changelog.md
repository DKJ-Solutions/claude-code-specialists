## `feat/publish-to-business` changelog

### Branch title

The marketplace publishes to the business repo with one script

### Branch ID

20260814-120015

### Branch type

feat

### What does the change on this branch bring to main?

The marketplace can now be published to the business organisation with one script
(`scripts/release/publish-to-business.ps1`), so Claude Enterprise can sync a private business repo
as a plugin marketplace and colleagues without GitHub access receive the plugins. The model: this
repo stays the single source of truth, the business repo is a publication target that every run
overwrites — it empties the target (except `.git`) and rebuilds it from a fixed published set
(manifest, `plugins/` including `agent-shared/`, the reader-facing root docs — 148 files, measured
by the dry run; `scripts/`, `.claude/`, `connectors/`, `releases/`, `workflow-davekjohn/` and the
governance root docs are the maintainer's half and stay behind), so a plugin removed here disappears
there too. Before committing it verifies that every
`source` in `marketplace.json` resolves to a folder with a `plugin.json` in the rebuilt tree — a
manifest pointing at a folder that did not travel is invisible here and loud for every colleague, so
it is a hard stop with nothing committed. Versions are untouched: the lockstep bump of the release
is the update signal, and the commit message records the source commit and every plugin version it
carried, so the target's history reads as a release log.

Four things around the script itself:

**The target lives in the seam, not in the script.** `Get-BusinessMarketplaceRepo` in
`scripts/repo-config.ps1` names `BWJ-ecommerce/claude-plugins-bwj` — the same rule that moved
`Get-RepoName` out of `open-pr` — read as an optional function with a fallback; `-TargetRepo` stays
as the override for a second organisation, and no seam plus no parameter is a refusal, not a guess.
Deliberately **not** in the script contract and not mirrored into the plugin: like the blueprint
generator, this is the marketplace source's own tool, and a consumer would be answering a question
no script of theirs reads.

**Windows PowerShell 5.1 compatibility, repaired rather than assumed — three defects, and the third
was invisible to the testing that found the first two.** The script was written and tested on
PowerShell 7.4.6. On 5.1 its raw `& git ... 2>&1` under `$ErrorActionPreference = 'Stop'` would die
on the first stderr progress line (the #96/#97/#107 lesson) — git clone and push write their
progress there — so every git call now runs through the shared `native-capture-lib.ps1` guard, with
output stringified before the report's `Group-Object` substrings it. `git init -b` (needs
git >= 2.28) became `init` + `symbolic-ref`, so the fresh-history path has no version floor.

The third came out of the code review and is the one worth recording: under
`Set-StrictMode -Version Latest` a **missing property is a terminating error on 5.1 and silent on
7.4.6**, measured on all three shapes the script used (a missing property, a missing top-level key,
`.Count` on a non-array). So `$plugin.source` threw before the integrity check that exists to
explain a malformed manifest could report anything — which means the manual test *"missing required
manifest field → clean error"* passed on the machine it was run on and would have failed on the
convention this repo actually runs. Every JSON field is read through a `Get-JsonField` helper now,
so the defensive branches are reachable and the reader gets the named problem instead of *"The
property 'source' cannot be found on this object"*.

**Tests without network or tokens**: `scripts/tests/publish-to-business.tests.ps1`, 34 asserts
against a fixture source repo and local bare targets (`git init --bare`) — first publication,
idempotence (second run publishes nothing), a version bump travelling as exactly one change, the
integrity hard stop with the target history untouched, a deletion travelling once the manifest
agrees, dry run committing nothing, the seam answering, the no-target refusal, and the two
malformed-manifest shapes above, each asserted on the message rather than only the exit code —
both paths exited 1 before the repair too, so an exit-code assert would have been green over the
bug. Two asserts in `repo-config.tests.ps1` hold the seam value's form.

**Publishing is a boundary, documented where releases are documented**: Block 3 of the
`cut-release` skill (the `Get-LiveStage` pattern — driven by facts of the repo, absent for every
consumer) and a paragraph in `RELEASES-portable.md`. Publishing is a separate, deliberate decision
after the cut, only on the owner's explicit request — releasing without publishing is a normal
outcome, not a half-finished one (Dave, August 14, 2026).

The marketplace name stays `claude-code-specialists` even though the target repo is called
`claude-plugins-bwj`: the name is the key in every consumer's `enabledPlugins`, and aligning it with
the repo name would break that line in every consuming repo (Dave's decision, recorded at the seam).

### Significance

#### Tier 0

The release manager gets a tested, gated publication step where publishing used to be impossible
without hand-copying 148 files; the seam keeps the target out of the script and the suite keeps the
delete-before-copy model honest.

**Score:** 3

#### Tier 2

Nothing changes for any current consumer until the owner actually publishes: the new checklist block
tells them explicitly it does not exist for their repo. The reach it prepares — colleagues receiving
the plugins through Claude Enterprise without GitHub access — arrives with the first publication,
not with this merge.

**Score:** 2

### Pull Request

