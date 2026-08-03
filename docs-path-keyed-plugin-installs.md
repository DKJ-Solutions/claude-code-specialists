### A folder rename silently unlinks plugin installs · Docs · 2026-08-03

Records the lesson measured on August 3, 2026, when this repo's directory was renamed from
`davekjohns-workshop` to `claude-code-specialists`: the install record is keyed on `projectPath`, so the
rename left it naming the old folder. `.claude/settings.json` still enabled
`specialists@claude-code-specialists` correctly, nothing errored, and the session loaded no subagent,
skill or hook at all.

The cause was not new to the system — `scripts/lib/check-report-lib.ps1` has always named "a renamed or
moved repo directory" among the ways a record goes missing. It was new to the *reader*: the list a
consumer actually reads, in `QUICKSTART.md`, offered only "It moves" and "It can be taken". So the gap
closed here is a documentation gap, not a mechanism one.

It is also a gap in the rename plan, which is why it went unnoticed. Renaming the **local checkout
directory** is in none of #403–#406, and #409's four-item handoff covers the marketplace remove/re-add,
the stale user-scope entry and the restart — not a moved checkout. Matching the local folder to a
renamed repository is the obvious next move for anyone, and nothing warned that it needs a re-install.
The handoff's own instruction to *verify by the surface, not by the record* is what surfaced it.

Out of scope here, deliberately: the consumer switch-over (`smartwatchbanden` still resolves against
`davekjohns-workshop`). #409 reserves the consumer repositories for Dave by name, so that stays his
step and no file in them is touched from here.

- **`QUICKSTART.md`** — third bullet in the missing-record list ("It can be orphaned, by an ordinary
  directory rename"), the one cause that is predictable rather than surprising, with the August 3
  measurement.
- **`QUICKSTART.md`** — sharpens the neighbouring `#315` warning that "two lines for one plugin" is a
  stray duplicate. After repairing a rename, two records is the *expected* state and needs no cleaning:
  `Get-InstallRecord` skips a record whose `projectPath` no longer resolves, so it reports neither a
  duplicate nor `[RECORD-SHAPE]`. `#315`'s duplicate is two records naming the **same** path.
- **`.claude/specialists/lenses/05-15-extension.md`** — Sylvester carries the repo-side instance: the
  detection signal is a **deliberate** `check-roster-sync.ps1` run reporting `[NOT-INSTALLED-HERE]`,
  because the session-start hook that would otherwise report it ships in the plugin that did not load.
  Plus the repair pair of commands, pointing at `QUICKSTART.md` for the mechanism rather than restating
  it.
- **`CLAUDE.md`** — one pointer clause in "The repo consumes itself", which already enumerates the
  consequences of self-consumption; this is the second one.
