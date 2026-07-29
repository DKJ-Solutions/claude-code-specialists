### Teardown warns when a consumer script resolves the plugin cache · Feat · 2026-07-29

The teardown documented a leftover it could not act on: the consumer's own resolver locates the
marketplace cache and throws once the plugin is gone, and in the measured repo
(`davekokbwj/smartwatchbanden`, July 29, 2026) three operational scripts dot-sourced it — so an
uninstall took the daily git workflow down rather than leaving debris behind. Documenting that was
right, but it left the dry run silent about the only leftover that breaks a run: the report answered
*"what did the bootstrap put here"* while a reader's actual question before trusting the word
*reversible* is *"what stops working after I uninstall"*.

`teardown.ps1` now answers the second question too. Every `.ps1` under `scripts/` that references the
marketplace cache or `CLAUDE_PLUGIN_ROOT` is reported as a `[WARN]` line together with the scripts that
depend on it, plus a note naming the two ways out (keep local copies of the operational scripts, or make
the resolver degrade to one clear failure instead of a throw) and stating plainly that no teardown can
fix this, because the shared-script model (#81) is what creates the dependency.

**It is report-only by construction, and that is the property under test.** These files are the
consumer's own code; a check that deleted them to make its own summary look clean would do exactly the
damage the classification exists to prevent. So the suite asserts both halves — the report *names* the
resolver and its dependents, and `-Apply` still leaves both files on disk — plus exit code 0 (a warning
is not a failure) and no false alarm on a consumer whose scripts never reach into the plugin. Eight new
asserts, 77 total in `teardown.tests.ps1`.

Two limits stated rather than hidden: the scan covers `scripts/` only, so a resolver living elsewhere is
not counted, and dependents are matched by filename rather than by parsing dot-source syntax — a
consumer may reach the resolver via `$PSScriptRoot`, a variable, or `Join-Path`, and this report only has
to point a human at the right file.
