### Inventory drift in the session's own repo is visible at session start · Fix · 2026-07-29

The register's `extensions` inventory is meant to follow reality. When it does not, the check reports
an `[INFO]` — and the session hook surfaces only `[ERROR]` lines, so the finding is invisible where
someone would act on it. That is not theoretical: the run that prompted this found eleven of them at
once, six in **this repo's own entry**, where the lenses had landed with the adopt-the-six change
(PR #212) and the inventory was never updated alongside. It sat there until someone ran the check by
hand.

The connectors README had carried an "after a refresh, also update the manifest" rule the whole time.
That rule is why this is filed as a fix rather than a feature: it was on the books, it was not
followed, and nothing reported the omission — so nothing prompted anyone. A sharper sentence would
have changed nothing.

`check-connectors.ps1` now also emits a **non-counting `[INVENTORY]`** line that the hook surfaces,
on its own verdict (`no errors, but the register's lens inventory for this repo is behind`) rather
than folded under the not-registered one — those are different situations with different fixes. The
third instance of the `[UNREGISTERED]`/`[ORPHANS]` shape: the `[INFO]` stays for the count and the
deliberate run, the exit code stays 0, and nothing about the plugin install is implied to be broken.

**Scoped as narrowly as the reasoning allows.** The marker fires only for the connector whose checkout
*is* the repo the session is in — the workshop's own `localCheckout: "."` entry on a full sweep, or the
consumer's own entry under `-OnlyConsumer`. Every other connector's drift stays silent, so the
`[INFO]`-silence rule keeps applying wherever its justification ("often the business of another machine
or user") is actually true. Promoting it for all connectors would have reintroduced exactly the noise
that rule removed. Decision by Dave, July 29, 2026.

Fifteen tests cover it (99 pass, up from 84), including the two that matter most: that drift in
*another* repo's entry produces the `[INFO]` and **no** marker, and that the marker still surfaces when
real `[ERROR]` signals are present too — a regression there would drop it exactly when a session is
busiest.

Two verification lessons are recorded in
[Sylvester #15's lens](.claude/plugins/claude-specialists/specialists/05-15-extension.md): a
`Write-Host` line is invisible to a same-process pipeline, so an in-process assertion about one passes
whether the line is there or not (both cases read 0 — which makes a negative scoping assertion
worthless unless it runs the check as a child process, the way the hook does); and
`Set-Content -Encoding utf8` restores a file *with* a BOM under PowerShell 5.1, so undo a temporary
probe with `git checkout --` instead.
