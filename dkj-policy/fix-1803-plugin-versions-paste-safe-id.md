## fix/1803-plugin-versions-paste-safe-id

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate in YOUR repo reads a heading, so this half is on you -- only the repo that authors
> this workflow refuses a fifth (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE THE FIRST OF THOSE FOUR HEADINGS** -- everything between the
> title and it is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. THIS half open-pr refuses, in every repo, before the push -- it reads the shape, so a
> guidance block in your own language passes and your own paragraph here does not (Dave,
> August 26, 2026; refused since #1650).
>
> **DEPLOY takes no steps of its own, and it is WRITTEN LAST** -- it is what the branch DID, once
> TEST says so. Written while steps above it are still open it states an INTENTION, and no gate
> holds it against what landed: the step gate splits this file at that heading and counts only
> above it. The PR title is the one exception -- new-branch -Title writes it at creation, because
> open-pr composes the PR title from it. It is the one part of this file that travels verbatim
> into `CHANGELOG.md` at the merge. In each tier, write the reason
> ABOVE the Score line -- anything below it is discarded.
>
> Relative links in that text resolve FROM THIS DIRECTORY -- `CHANGELOG.md` sits here too, so
> write each path exactly as it reads in this file.
>
> For tier 2 audiences: the subscriber of a service. That reader and nobody else -- what matters only
> inside this repo belongs under the first `**Score:**`. If the change reaches that reader
> not at all, N/A is a complete answer and the common one.
>
> The phase arc, the marks and the whole form: `DEVELOPMENT-portable.md`, which ships
> with this workflow.

### PLAN

#### What #1803 asks

`plugin-versions.ps1` interpolates an unvalidated `enabledPlugins` id (`$id`, and `$mp` split from it)
into every paste-ready `claude plugin ...` command it prints, and into the default view's raw field
prints. The `-Brief` sanitizers close line/marker forging but not shell metacharacters (`;`, `` ` ``,
`$()`, `|`, `&`) inside the embedded command. The #1802 branch fixed only the one `not-installed`
install command it made reachable; this is the standing remainder. The issue leaves two decisions to
the implementer -- withhold vs sanitize, and whether the default view is held to the same rule.

#### Decisions taken (both follow established doctrine, not a new call)

- [x] **Withhold, not sanitize.** A sanitized id yields `claude plugin update <altered-id>`, a command
  that cannot work -- so a redacted command is replaced wholesale by one sentence saying why, the
  shape `Get-PasteableRef`'s `.Note` has (#1594) and the shape the `not-installed` branch already
  used since #1591.
- [x] **The default view is held to the same rule as `-Brief`.** Zero false positives (every real
  plugin id is a clean lowercase slug pair -- the same "costs nothing real" argument #1594 made after
  measuring all 994 PR head refs), and a person pasting from a terminal is the higher-stakes paste
  target, not a lower one.
- [x] `Get-PasteableRef` itself is **not** reused as the check: its allowlist has no `@`, so it
  refuses every legitimate plugin id. The id's allowlist already exists in this tree -- the
  `Test-PluginNameSlug` + `Test-PluginMarketplaceSlug` pair, i.e. `$idIsCommandSafe`.

### CREATE

- [x] `scripts/task/plugin-versions.ps1`: add `$idTok` / `$mpTok` -- the id / marketplace segment when
  it passes its slug check, else a `<plugin-id>` / `<marketplace>` placeholder. Build every
  `claude plugin ...` `$action` string from the tokens instead of `$id` / `$mp` (19 sites).
- [x] After the verdict chain, replace any `$action` still carrying a placeholder with the unified
  withhold sentence (`no paste-ready command -- the 'enabledPlugins' key is not a valid plugin id
  (bad slug); fix it in .claude/settings.json and re-run`). Drops the bespoke one-off wording the
  `not-installed` branch carried.
- [x] Default view: sanitize every emitted field at the point of `Write-Host`, exactly as `-Brief`
  already does -- `Format-SuspectToken` for the id header, `Format-SafeProseToken` for the
  installed-here / clone / verdict / action lines, `Format-SafePathToken` for the clone directory,
  and the all-current version summary.
- [x] `scripts/sync/build-shared-scripts.ps1`: mirror to `plugins/dkj-policy/scripts/task/plugin-versions.ps1`.

### TEST

- [x] `scripts/tests/plugin-versions.tests.ps1`: rewire scenarios 28/29 to the unified withhold
  wording; add scenario 30 (`-Brief`: a bad-slug id at a `behind` verdict -> the `update` command is
  withheld too, not just `install`) and 31 (default view: command withheld AND the id header /
  verdict / action sanitized at emission). 183 pass, 0 fail.
- [x] Full lint gate (`check-plugin-integrity.ps1`) + all suites green, as CI runs them.

### DEPLOY: fix/1803-plugin-versions-paste-safe-id

`plugin-versions.ps1` no longer builds a paste-ready `claude plugin ...` command out of an
`enabledPlugins` id -- an arbitrary string from a settings file -- unless both halves of the id pass
their slug check. Where they do not, the command is withheld and a one-line reason takes its place,
following the `Get-PasteableRef` doctrine (#1594). The guard, which #1591 had scoped to a single
install command, now covers all 19 command sites and both output modes; the default view additionally
sanitizes every field it prints, the way `-Brief` already did.

**Score:** 2

#### What makes this deploy extra special

N/A -- an internal hardening of a diagnostic script's output. No subscriber of a service reaches this
code path or its output.

**Score:** N/A

#### Pull Request

Withhold the enabledPlugins id from every command plugin-versions.ps1 prints when it is not a valid slug

