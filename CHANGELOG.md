# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #253 · The seam, specified and readable · Feat · 2026-07-29

The first half of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221)'s remaining work:
the seam is **specified** in the family README and **readable** by every reader, with no behaviour change
for any existing consumer. What is deliberately not in this change is the writer flip — see the end.

**The shape.** A fresh consumer's whole specialist surface becomes one directory and one line:
`.claude/specialists/SPECIALISTS.md` (the inclusion: body import, lens import, roster slot) plus
`.claude/specialists/lenses/<group>-<id>-extension.md`, flat because `<group>-<id>` is unique
family-wide. `CLAUDE.md` carries `@.claude/specialists/SPECIALISTS.md` and nothing else, so a teardown
becomes *remove one directory and one line* instead of hand-cutting a roster woven through 6 sections.

**Four facts were verified from the reference before any of this was designed, and each could have sunk
it.** Nested imports work (*"a maximum depth of four hops"* — the seam spends two). A path in backticks
is not an import, so the docs can name the seam line safely. A project-root `CLAUDE.md` is re-read after
`/compact`, so the roster comes back with it. And it is **not a token saving**: *"imported files still
load and enter the context window at launch"* — the seam buys removability, nothing else, and claiming
otherwise would be the kind of unearned win this repo keeps catching elsewhere.

**One fragility the seam concentrates rather than removes,** now written down: the body import resolves
into the marketplace cache, outside the working directory, and such an import is gated by a one-time
approval dialog whose refusal is sticky — *"If you decline, the imports stay disabled and the dialog
doesn't appear again."* With one line instead of two, a single decline delivers nothing at all, silently.
Worth knowing before diagnosing that as a bug in this repo.

**The mechanism, in one place.** `check-report-lib.ps1` gains `Get-SeamPaths` (the literals the bootstrap
will write and the teardown must match — one source, because a drift between those two leaves a dangling
import that nothing errors on) and `Get-LensWriteDir`. `Get-LensDirCandidates` gains the seam as its most
canonical candidate ahead of the three it already walked, so **a consumer who migrates by hand works
immediately** — the roster check, the drift lint and the teardown all find lenses there today. The
mirrored plugin copy is back in step.

`Get-LensWriteDir` encodes the promise that keeps this safe: a fresh consumer gets the seam, a consumer
that already has lenses keeps writing where they are. The bootstrap never relocates a tree the repo owner
owns, because seam lenses written beside a legacy tree would split the surface in two — worse than either
layout alone, with the teardown then reasoning about both at once.

A new suite covers all of it (`check-report-lib.tests.ps1`, 12 asserts) — these shared helpers previously
had no direct test at all, only indirect coverage from suites that happen to call them. The pinned
properties: the seam is candidate 0, the legacy locations still resolve and `extensions/` stays last, the
import line never picks up a backslash from `Join-Path`, an *empty* legacy directory does not count as
adopted, and after a hand migration the writer follows to the seam without being told.

**Deliberately still to come, and why the split.** Flipping the bootstrap to write the seam by default
(and teaching the teardown its one-line/one-directory form) changes 30 assertions across five suites that
encode the current layout. Landing the readable half first means the seam can be proved on a real repo —
this one, by hand — before the default moves under every consumer at once.

Plugins: specialists

[PR #253](https://github.com/DaveKJohn/davekjohns-workshop/pull/253)

---

### #252 · Chris's body can serve as a main-thread system prompt · Feat · 2026-07-29

The blocker on [#215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215) is removed. Chris's
portable body said he *"never executes anything himself — he writes no content, opens no PR, does not
merge"*. As a role inside a general-purpose loop that works; as **the main thread's own system prompt**
it is crippling, because the main thread would refuse to edit files. No configuration change could fix
that, which is why the issue sat blocked.

**The rule was reframed, not weakened: it now forbids unattributed work rather than typing.** Every
executing action still belongs to the specialist who owns it, is announced before it happens, and is
performed under that specialist's craft rules — by handing off to a subagent where subagents exist, and
otherwise by Chris doing that specialist's work *under their name*. What is forbidden is work with no
specialist behind it, work done by Chris's general judgment where a craft has rules, and a handover
claimed but not made. Read it as *"nothing happens anonymously"*.

Two things this surfaced. The old wording was **internally inconsistent** — ritual step 5 has always
read *"execute according to their trade rules"*, so the body both forbade and prescribed the same act.
And in a harness without subagents the old rule was already fiction: the work got done anyway, just
without the wording admitting it. The reframing describes what actually happens and keeps the property
that matters, which is attribution.

**The mechanism was verified from the docs rather than assumed**, and recorded in the
[family README](claude-code-plugins/claude-specialists/README.md#adoption-the-bootstrap-path): a plugin
root `settings.json` supports `agent` (and `subagentStatusLine`) and *"activates one of the plugin's
custom agents as the main thread, applying its system prompt, tool restrictions, and model"*. The
issue's compaction worry dissolves in this route: only **skill** descriptions are flagged as not
re-injected after `/compact`, and a main-thread agent's body *is* the system prompt, which travels with
every request anyway.

**The switch stays off, deliberately.** What happens when two enabled plugins both set `agent` is
documented nowhere — not on the plugins page, not in the reference — and that is a poor thing to
discover through your main thread. It would also change every consumer's main loop from a version bump
they did not read, and since Chris ships as a persona there is no agent-def to point at: creating one
means its `tools:` and `model` become the whole main thread's policy. Ready, not thrown; settling the
multi-plugin question needs an experiment, not another read.

Plugins: specialists

[PR #252](https://github.com/DaveKJohn/davekjohns-workshop/pull/252)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.14.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.14.1.md](releases/development/2.x/2.14.1.md) for the full release notes.

---

### [v2.14.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.14.0.md](releases/development/2.x/2.14.0.md) for the full release notes.

---

### [v2.13.3] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.3.md](releases/development/2.x/2.13.3.md) for the full release notes.

---

### [v2.13.2] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.2.md](releases/development/2.x/2.13.2.md) for the full release notes.

---

### [v2.13.1] - 2026-07-29 — Patch

See [releases/development/2.x/2.13.1.md](releases/development/2.x/2.13.1.md) for the full release notes.

---

### [v2.13.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.13.0.md](releases/development/2.x/2.13.0.md) for the full release notes.

---

### [v2.12.0] - 2026-07-29 — Minor

See [releases/development/2.x/2.12.0.md](releases/development/2.x/2.12.0.md) for the full release notes.

---

### [v2.11.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.11.0.md](releases/development/2.x/2.11.0.md) for the full release notes.

---

### [v2.10.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.10.0.md](releases/development/2.x/2.10.0.md) for the full release notes.

---

### [v2.9.0] - 2026-07-28 — Minor

See [releases/development/2.x/2.9.0.md](releases/development/2.x/2.9.0.md) for the full release notes.

---

### [v2.8.0] - 2026-07-27 — Minor

See [releases/development/2.x/2.8.0.md](releases/development/2.x/2.8.0.md) for the full release notes.

---

### [v2.7.3] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.3.md](releases/development/2.x/2.7.3.md) for the full release notes.

---

### [v2.7.2] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.2.md](releases/development/2.x/2.7.2.md) for the full release notes.

---

### [v2.7.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.7.1.md](releases/development/2.x/2.7.1.md) for the full release notes.

---

### [v2.7.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.7.0.md](releases/development/2.x/2.7.0.md) for the full release notes.

---

### [v2.6.1] - 2026-07-26 — Patch

See [releases/development/2.x/2.6.1.md](releases/development/2.x/2.6.1.md) for the full release notes.

---

### [v2.6.0] - 2026-07-26 — Minor

See [releases/development/2.x/2.6.0.md](releases/development/2.x/2.6.0.md) for the full release notes.

---

### [v2.5.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.5.0.md](releases/development/2.x/2.5.0.md) for the full release notes.

---

### [v2.4.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.4.1.md](releases/development/2.x/2.4.1.md) for the full release notes.

---

### [v2.4.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.4.0.md](releases/development/2.x/2.4.0.md) for the full release notes.

---

### [v2.3.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.3.0.md](releases/development/2.x/2.3.0.md) for the full release notes.

---

### [v2.2.1] - 2026-07-24 — Patch

See [releases/development/2.x/2.2.1.md](releases/development/2.x/2.2.1.md) for the full release notes.

---

### [v2.2.0] - 2026-07-24 — Minor

See [releases/development/2.x/2.2.0.md](releases/development/2.x/2.2.0.md) for the full release notes.

---

### [v2.1.0] - 2026-07-23 — Minor

See [releases/development/2.x/2.1.0.md](releases/development/2.x/2.1.0.md) for the full release notes.

---

### [v2.0.2] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.2.md](releases/development/2.x/2.0.2.md) for the full release notes.

---

### [v2.0.1] - 2026-07-23 — Patch

See [releases/development/2.x/2.0.1.md](releases/development/2.x/2.0.1.md) for the full release notes.

---

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.x/2.0.0.md](releases/development/2.x/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.18.0.md](releases/development/1.x/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.17.0.md](releases/development/1.x/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.x/1.16.0.md](releases/development/1.x/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.x/1.15.1.md](releases/development/1.x/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.15.0.md](releases/development/1.x/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.14.0.md](releases/development/1.x/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.x/1.13.0.md](releases/development/1.x/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.x/1.12.1.md](releases/development/1.x/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.12.0.md](releases/development/1.x/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.x/1.11.0.md](releases/development/1.x/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.10.0.md](releases/development/1.x/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.2.md](releases/development/1.x/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.x/1.9.1.md](releases/development/1.x/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.x/1.9.0.md](releases/development/1.x/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.8.0.md](releases/development/1.x/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.7.0.md](releases/development/1.x/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.x/1.6.0.md](releases/development/1.x/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.2.md](releases/development/1.x/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.x/1.5.1.md](releases/development/1.x/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.x/1.5.0.md](releases/development/1.x/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.x/1.4.1.md](releases/development/1.x/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.4.0.md](releases/development/1.x/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.3.0.md](releases/development/1.x/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.x/1.2.0.md](releases/development/1.x/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.x/1.1.1.md](releases/development/1.x/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.x/1.1.0.md](releases/development/1.x/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.x/1.0.0.md](releases/development/1.x/1.0.0.md) for the full release notes.
