# connectors/ — the registry of connected repos

This is the registry of **which repos have installed this family's plugins and whether they are
still in sync with this repo** — one `<repo>.json` manifest per connected repo, directly in this
directory, each containing the extension inventory per plugin. The connector *is* the repo. This
README is the doctrine; the manifests are the data.

**The registry deliberately lives at the family level, next to the plugin directories — not inside
them.** The marketplace sources point to the plugin directories themselves, so this registry does
*not* travel with consumers' plugin caches: this way, no consumer sees another's manifests
(decision by Dave, July 16, 2026, after the security review). The registry is workshop
administration.

## The doctrine: this repo is the source of truth

davekjohns-workshop works like a **Customer Data Platform**: all changes to shared plugin content
(agent defs, manuals, persona bodies, skills) **land here first**, and are only then synced out to
the connected repos — never the other way around (see the safety rules in the repo
[`CLAUDE.md`](../../../CLAUDE.md)). If an improvement nevertheless originates in a consumer, that
is an **inbound signal**: the change is first brought back here and then synced out again.

**The standing inbound route** (agreed with Dave, July 16, 2026): if a session in a consuming repo
discovers core improvements (something for the shared agent defs, manuals, persona bodies, or
skills — not lens work), that session does not build it itself, but opens an **issue on this repo**
with the label **`inbound`** — template:
[`inbound-improvement`](../../../.github/ISSUE_TEMPLATE/inbound-improvement.md). This way nothing
gets lost and every workshop session has a visible backlog; the workshop processes it through the
normal chain (branch → reviews → PR → release bump on Dave's word), after which the consumer gets
it back via the plugin update. The only legitimate bridge on the consumer side is a deliberately
temporary note in its own repo lens, which disappears again after the sync.

An important nuance — **what syncs and what doesn't**:

- **Synced (source here):** the portable persona bodies (everything above the
  `## Specific to this repo` marker) and all plugin content itself (agent defs, manuals, skills).
- **Not synced (repo-specific):** the `## Specific to this repo` slot of each extension — the repo
  lens differs per consumer and belongs there. The registry only tracks *that* a lens exists,
  never what it contains.
- **Why extensions cannot live only here:** the session in a consuming repo reads the lens files
  at runtime from its **own checkout** (agent defs refer to them, and the orchestrator's persona
  is loaded via an `@`-import in the repo CLAUDE.md). The copy in the consumer is therefore
  technically necessary; this registry + the check keep it honest.

## Privacy boundary (hard rule)

This repo is **public**. Manifests therefore contain **metadata** only: repo name, plugin,
extension inventory (only `<group>-<id>` numbers), and a relative checkout path. **Never** lens
content, absolute machine paths, or other data from the (private) consuming repos. The relative
`localCheckout` paths reveal the sibling layout of the local checkouts; that is a deliberately
accepted degree of transparency (security review, July 16, 2026).

## The manifest format

```json
{
  "repo": "DaveKJohn/life-hub",
  "visibility": "private",
  "localCheckout": "../life-hub",
  "plugins": [
    {
      "id": "specialists@davekjohns-workshop",
      "extensions": ["01-01", "05-05"]
    }
  ],
  "notes": ""
}
```

- `localCheckout` is **relative to the root of this repo** (the workshop checkout); if the
  checkout is not on the machine, the check skips it. Absolute paths and paths outside the scope
  root are rejected by the check.
- `plugins` contains, per installed plugin, that plugin's `extensions` inventory.
- `notes` is the human summary/explanation; updated when something changes substantively, not on
  every check.
- **The manifest deliberately has no version bookkeeping (anymore)** (decision by Dave, July 20,
  2026): the check reads the actually installed version from the machine record
  (`installed_plugins.json`), and a `syncedVersion` field duplicating those numbers produced
  nothing but maintenance PRs while nobody was watching the signals anymore.
- **A machine can hold several records for one checkout, and then the check refuses to guess**
  (#240, July 29, 2026). Measured: one repo registered at three versions at once, because
  `~/.claude.json` held several project records for it in two path spellings. The check used to take
  the first record whose path resolved and stop — an arbitrary pick presented as a fact, on which the
  session hook's `[OK]`/`[ERROR]` then rested. It now collects every match: agreeing records (two
  spellings of one directory are not two answers) are reported as before, while disagreeing ones
  produce an `[ERROR]` naming all versions found and withholding the source comparison, because while
  they disagree no version claim about that consumer can be trusted. Cleaning up the duplicate project
  records is Claude Code's own state, not something this repo writes to.

## The check

[`scripts/sync/check-connectors.ps1`](../../../scripts/sync/check-connectors.ps1) runs the two-way
check across all manifests: plugin still enabled, registered extensions present (outbound),
unregistered extensions flagged (inbound), the machine version against the source, and per
consumer the content drift check
([`check-consumer-drift.ps1`](../../../scripts/lint/check-consumer-drift.ps1)). Run it at the
start of a workday or session:

```powershell
.\scripts\sync\check-connectors.ps1              # everything
.\scripts\sync\check-connectors.ps1 -SkipDrift   # registry checks only (fast)
```

Syncing itself remains **pull-based per consumer**: each connected repo pulls changes in its own
session, under its own governance — this registry signals, it never writes cross-repo.

## Maintenance: drift lint

Through the `github` marketplace source, the Claude Code CLI clones and caches this repo itself for
every consumer, so no physical copy in the consuming repo is needed and thus no sync step either —
every consumer literally consumes the same files. Left over from a transition, however, a consuming
repo may still have an outdated local copy of an agent def that is by now shared here.
[`scripts/lint/check-consumer-drift.ps1`](../../../scripts/lint/check-consumer-drift.ps1) (invoked
per consumer as part of the `check-connectors.ps1` run above, or standalone) compares such a local
copy (read-only, changes nothing) with the canonical version here and reports `MISSING` (already
migrated), `IDENTICAL` (dead copy, safe to remove), or `DRIFTED` (inspect first before removing). The
cleanup itself happens in the consuming repo, not by this script. The same script's persona-body
comparison is covered separately below, see [Persona drift](#persona-drift-how-to-read-a-drifted-report-doctrine).

```powershell
./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\path\to\life-hub
./scripts/lint/check-consumer-drift.ps1 -ConsumerPath C:\path\to\smartwatchbanden
```

## Persona drift: how to read a DRIFTED report (doctrine)

Recorded after the drift investigation of July 17, 2026 (Rebecca; dossier
`persona-drift-doctrine`), which established across all seven reports at the time: **zero**
deliberate changes to portable bodies, one genuine lag, and six false positives caused by one
structural path difference.

- **There is no "deliberately divergent" status for the portable body.** Practice confirms the
  model: repo-specific content belongs in the `## Specific to this repo` slot (the lens), and a
  desired change to the portable part goes through the inbound route above — never as a permanent
  local divergence. So the check does not need to facilitate or mark deliberate drift.
- **Lens-only personas produce no body drift.** A correctly set-up persona lens (in the seam,
  `.claude/specialists/lenses/`) no longer carries a body copy -- the
  portable body comes from the plugin install via an `@`-import. Since #64 the index line is
  location-independent plain text (no path-depth link), so there is nothing left to normalize.
  `check-consumer-drift.ps1` recognizes the `> Repo-lens (lens-only persona)` blockquote and
  reports such a lens as `LENS-ONLY`; a consumer with an old, full body copy is still compared for
  real body drift.
- **A `DRIFTED` persona therefore always means a work item**: either lag (the source has moved on
  — refresh the copy from the source in a session of the consumer itself), or a not-yet-returned
  consumer change (bring that back through the inbound route first). Don't dismiss it, don't leave
  it sitting.
- **After a refresh, also update the manifest** (`notes`, and the `extensions` inventory if lenses
  were added or removed): the investigation found an already-performed refresh that was still
  administratively booked as open — the registry data should follow reality.
- **Update the `extensions` inventory in the same change that lands the lens — nothing will remind
  you later.** "Exists in the consumer but is not in the register" is an `[INFO]`, and the session
  hook surfaces only `[ERROR]` lines, so a drifted inventory is invisible at session start; it takes
  a deliberate run of `check-connectors.ps1` to find. On July 29, 2026 such a run found eleven of
  them at once, six in the register of *this* repo — the lenses had landed with the adopt-the-six
  change (PR #212) and the inventory was simply never updated alongside. The rule above ("after a
  refresh") was already there and was not enough, because it reads as a follow-up step and a
  follow-up step is exactly what goes missing. Treat the inventory as part of the lens change, not
  as bookkeeping that trails it.

## The session check (automatic)

The `specialists` plugin carries a **SessionStart hook**
([`hooks/hooks.json`](../specialists/hooks/hooks.json) +
[`connector-sessioncheck.ps1`](../specialists/hooks/connector-sessioncheck.ps1)) that, when a
session starts — in every repo that has the plugin, so also life-hub and smartwatchbanden —
locates the workshop checkout and runs the connectors check there. Two guardrails from the
security review: the found path is **verified** first (a marker check on the marketplace name in
`.claude-plugin/marketplace.json` — never run code on a guessed path), and outside the workshop
the check is **scoped** to the repo's own manifest, so a session never gets another consumer's
registry data into its context. Beyond that the hook is deliberately soft: no verified workshop
checkout means a notice and nothing more, only **blocking signals** (`[ERROR]`/`[DRIFTED]`) end up
as a compact summary in the session context, and the hook never blocks a session start (always
exit 0, read-only). `[INFO]` signals — registry administration about the sync state and the
registration of consumers: sometimes something to update here, often the business of another
machine or user, but in no case work worth interrupting a session start for — deliberately stay
silent at session start (decision by Dave, July 20, 2026); they are visible on a deliberate run of
`check-connectors.ps1` in the workshop. From this follows
a classification rule for extensions of the check (security review advice, July 20, 2026): a new
signal category that may be security-relevant (e.g. an indication of tampering) must never be
classified as `[INFO]`, but as `[ERROR]` — otherwise it silently stays out of sight at session
start.

**First named exception to that silence: `[UNREGISTERED]`** (July 28, 2026). "This repo has no manifest
in the register" was filed as `[INFO]`, and the consequence was the worst possible reading: a
brand-new consumer got `connector-sessioncheck: no errors.` — a positive all-clear for a repo this
workshop cannot see at all (no plugin-version check, no lens inventory, no agent-def drift). Found
after a third consumer had been running, and filing inbound issues, unregistered for days without
anyone noticing. `check-connectors.ps1` therefore also emits a **non-counting `[UNREGISTERED]`** line
that the hook does surface, next to the no-errors verdict rather than under it — nothing is wrong with
the plugin install there, only with this workshop's view of it, so the exit code stays 0 and the
per-signal `[INFO]` line stays suppressed.

This is deliberately *not* a relaxation of the `[INFO]` rule above. That rule was justified as "often
the business of another machine or user"; this signal is the exact opposite — it is about the repo the
session is in, and it is actionable there. The mechanism is the same one `check-roster-sync` uses for
`[ORPHANS]` (inbound #204): a dedicated non-counting token, rather than promoting the finding to
`[ERROR]` and putting a red line plus a non-zero exit code in every session of a repo somebody
deliberately chose not to register.

**Second named exception, one step further in: `[INVENTORY]`** (July 29, 2026). The repo *is*
registered, but its entry lists fewer lenses than the repo actually holds — the `[INFO]` at check 3.
Same failure mode as the first exception, and it had already happened: a deliberate run found eleven
of these at once, six of them in **this repo's own entry**, where the lenses had landed with the
adopt-the-six change (PR #212) and the inventory was simply never updated alongside. Nothing had
surfaced it for a day, because the finding is an `[INFO]` and the hook shows only `[ERROR]` lines. The
["update the inventory in the same change"](#maintenance-drift-lint) rule was added at the same time,
but a rule alone was demonstrably not enough — the earlier "after a refresh, also update the manifest"
rule was already on the books when this drift happened.

Scoped exactly as narrowly as the reasoning allows: `check-connectors.ps1` emits the marker **only for
the connector whose checkout is the repo the session is in** — the workshop's own `localCheckout: "."`
entry on a full sweep, or the consumer's own entry under `-OnlyConsumer`. Every other connector's
inventory drift stays an `[INFO]` and stays silent, so the `[INFO]` rule's justification ("often the
business of another machine or user") keeps applying wherever it is actually true. Decision by Dave,
July 29, 2026.

**Registering a new consumer is a workshop-side, manual step, and nothing can do it for you.** The
manifest lives here while the install happens in the consumer, and this registry never writes
cross-repo — so the `specialists-init` skill closes the loop from the other side: after bootstrapping a
consumer it prints a **paste-ready manifest block** (repo name derived from the git remote, the lens
inventory per plugin, `visibility` and `localCheckout` left as `VUL-IN` because it cannot know them),
which then lands here through the normal branch + PR flow. This hook is — alongside the `specialists-init` skill and the `roster-sessioncheck` hook
(the roster-sync feature) — one of the named, repo-neutral exceptions to the rule that plugins
carry no hooks/skills (see the root README). Mind the **version gate**: consumers only receive the
hook after a release bump plus a `claude plugin update` + session restart on their side.

The same gate applies to a newly added **skill** file — see
[Staying up to date](../QUICKSTART.md#staying-up-to-date) in the Quickstart for the full mechanics.
Watch out here in particular: the `/reload-plugins`/`/reload-skills` skill counters are no proof
that this hook has landed for a consumer — treating a reload notice as that confirmation is exactly
the trap from #186.
