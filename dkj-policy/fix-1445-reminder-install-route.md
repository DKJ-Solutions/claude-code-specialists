## fix/1445-reminder-install-route

> **How this file is read.** A step is `- [ ]` until it is resolved -- `- [x]` done, or
> `- [~]` dropped with the reason, which exists so nobody ticks a box for work they did not do.
> open-pr and ship-pr both refuse while one is still open, and there is no `-Force`.
>
> **FOUR `###` HEADINGS, AND NEVER A FIFTH** -- PLAN, CREATE, TEST, DEPLOY are the whole top
> level. A section needing its own heading goes in as a `####` UNDER whichever of the four owns
> it. No gate sees a heading, so this one is on you (Dave, August 26, 2026).
>
> **AND NOTHING BRANCH-SPECIFIC ABOVE `### PLAN`** -- everything between the title and that heading
> is this guidance, which is identical in every branch document. A status line, a note about
> THIS branch or an instruction to a session belongs under one of the four, normally as a `####`
> in PLAN. Same rule, same reason: no gate reads this region (Dave, August 26, 2026).
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

cut-release's self-consumption reminder prints `claude plugin update ... --scope project` for every enabled
plugin, but reads only `enabledPlugins` -- a declarative-route repo has no install record, so the command it
prints always fails there. Print the update line only where an install record for this repo exists;
otherwise the marketplace refresh plus a restart is the whole remedy.

#### What the report left inferred, and why it had to be measured first

[#1445](https://github.com/DKJ-Solutions/claude-code-specialists/issues/1445) named its own open question
rather than guessing past it: *"I did not test whether a repo enabled via `plugin install --scope project`
gets a working `plugin update`."* The repair differs per answer -- detect the route, or drop the update
command for everyone -- so the branch begins by establishing it instead of choosing.

### CREATE

- [x] Verify the symptom still stands. `~/.claude/plugins/installed_plugins.json` holds exactly one record
      (`shopify-ai-toolkit`, user scope) and none for either plugin;
      `claude plugin update team-alpha@claude-code-specialists --scope project` still answers
      `Failed to update plugin ...: Plugin "team-alpha" is not installed`.
- [x] Measure the inferred half in an isolated probe directory, with the machine's install administration
      backed up first and verified byte-identical afterwards. Both halves came back, and the second one
      decided the shape of the repair:
      - `claude plugin install --scope project` writes a record, and `claude plugin update --scope project`
        then answers `already at the latest version (4.30.0)`. So the route is not always wrong -- it is
        conditional on adoption route, exactly as the report suspected.
      - **The trap:** that same install writes the SAME `enabledPlugins` key the declarative route uses.
        The two routes are therefore indistinguishable from `.claude/settings.json`, which is the only file
        the reminder read. Detection cannot come from there.
- [x] Reuse the shared reader rather than adding a second one. `Get-InstallRecord` /
      `Test-PluginInstalledHere` in [`check-report-lib.ps1`](../scripts/lib/check-report-lib.ps1) already
      answer *"is this plugin installed for this repo?"*, and that lib already ships in the same plugin as
      `cut-release.ps1`, so the dot-source resolves from both the source tree and the mirror. Its own header
      records why: *"one reader per call site, tightened in none of them"* is the sentence #294 was filed
      about.
- [x] Print per plugin, not per repo. An id with a record for this path keeps its
      `claude plugin update <id> --scope project`; an id without one is named under the refresh, which is
      its whole remedy, with a restart as what applies it.
- [x] Keep the permissive default where the administration is absent or unreadable -- inherited from
      `Test-PluginInstalledHere` rather than re-decided here. "I could not look" is not evidence of absence,
      and erring that way can only restore the old line, never suppress a command that would have worked.
- [x] Mirror the changed script into the plugin (`build-shared-scripts.ps1`).

### TEST

- [x] Drive the function for real across all four states -- declarative, install-record, mixed, and an
      unreadable administration -- via a fixture repo root and a redirected `$env:USERPROFILE`. Ten new
      asserts in [`cut-release-guardrail.tests.ps1`](../scripts/tests/cut-release-guardrail.tests.ps1),
      which is the first block in that suite to RUN the script rather than read its source; the reason
      stated there for reading source (*"driving the whole script needs a repo to cut"*) is about the
      script and does not reach this one self-contained function.
- [x] Prove the new asserts bite. Mutating the fix back out (`$installed` -> `$enabled`) fails exactly two
      of them -- *"declarative route: NO update command is printed"* and *"mixed: and the plugin without one
      does not"* -- and nothing else. Restored: 105/105 green.
- [x] Full lint gate and every test suite, as CI runs them.

### DEPLOY: fix/1445-reminder-install-route

`cut-release`'s closing self-consumption reminder no longer prints a command that cannot run in the repo it
is printed for. It used to read `.claude/settings.json` and emit
`claude plugin update <id> --scope project` for every enabled plugin -- but `enabledPlugins` is the
**declarative** route while `plugin update` operates on an **install record**, so in a repo adopted that way
the very source the reminder consulted was the one guaranteeing the command it printed would refuse. Measured
here immediately after the v4.30.0 cut: the refresh succeeded, both update commands answered
`Plugin "..." is not installed`.

It now asks the install administration which of the two routes each enabled plugin actually took, through the
shared `Test-PluginInstalledHere` rather than a second private reader, and prints per plugin: an id with a
record for this path keeps its update command, an id without one is named under the marketplace refresh --
which is its whole remedy, a restart being what applies it. Both routes were measured rather than reasoned
about, because the report flagged the second as inferred and the repair differed per answer; the finding that
settled the shape is that `claude plugin install --scope project` writes the **same** `enabledPlugins` key the
declarative route uses, so the two are indistinguishable from settings and detection had to come from
elsewhere. Where the administration is absent or unreadable the old line is printed unchanged -- absence of
evidence is not evidence of absence, and that default is inherited from the shared predicate rather than
re-decided.

The reminder's premise, its conditionality and its 2026-08-15 reasoning are untouched: this is the remedy it
names, not the reason it exists.

**Score:** 3

#### What makes this deploy extra special

A consuming repo that cuts its own releases with this plugin gets the same correction, and it matters most
for the adoption route `INSTALL.md` does *not* document -- settings keys without an install. Such a repo used
to end every cut with a hard failure against a machine that was in fact fully up to date, with no way to tell
that from a real one. A repo adopted the documented way (`claude plugin install --scope project`) sees no
change at all: it has a record, so it still gets its update command.

**Score:** 2

#### Pull Request

Self-consumption reminder: only print an update command the repo's adoption route can run
