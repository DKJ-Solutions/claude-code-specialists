### The roster check inspects the version a session actually loads, not the highest one in the cache · Fix · 2026-08-04

**Two gates were answering the same question differently, and the roster check was the one that was
wrong.** `check-roster-sync` printed `cache 3.3.0` for this repo while the connector hook reported the
machine record on `v3.2.0`. The record wins: `installed_plugins.json` pins this path to
`...\specialists\3.2.0`, so that is what a session here loads — and the roster check was reporting on a
different directory than the one under test.

**The cause is that `Resolve-PluginDir` never consulted the record.** It picks the semantically highest
version under the cache that has an `agents/` dir. That answers *"the newest version present on this
machine"*, which stops being the same question as *"the version this repo loads"* the moment a second
consumer pulls a newer one into the shared cache. Measured here: the cache held **3.1.2, 3.2.0 and
3.3.0**, all three with an `agents/` dir.

**Nothing looked wrong, and that is the point.** Both versions happen to ship the same 15 agents, so the
verdict was accidentally right. As soon as two versions differ in roster content, a check reading the
wrong one reports *"present in roster + lens"* about a specialist the session does not have — the same
shape as this morning's fixture defect: a check examining something other than what it reports on.

**The repair is a third step, not a replacement.** `Resolve-PluginDir` now resolves in order:
`CLAUDE_PLUGIN_ROOT` (hook context) → **the install record for `-RepoRoot`, when one is given** → the
highest-version cache scan. The scan remains the answer when no root is passed, when the repo has no
record, or when the record is stale, so the existing behaviour and its test are untouched.

**Three deliberate details.** The record's `installPath` is used **directly** rather than rebuilt from
its `version` field — the record names the directory, and reconstructing it would be a second way of
saying the same thing that can disagree with the first. A recorded path that is **gone from disk, or has
no `agents/` dir**, falls through to the scan instead of returning `$null`: a stale record must not
blind a check that would otherwise have found something. And an **unreadable administration** changes
nothing, because `Get-InstallRecord` reports rather than throws — which is what makes this a refinement
rather than a gate in front of the old path.

**One thing I started to get wrong, and the docs caught it.** The first version forwarded the check's
`-UserHomeOverride` into `Get-InstallRecord`. That function's own parameter documentation says its
callers deliberately do **not** do that: the flag pins the *user layer of the settings chain*, and the
administration is a different file answering a different question. So there is no passthrough, and the
test redirects `$env:USERPROFILE` instead — the route the connector version test already uses. Adding
the parameter would have offered a second, contradicting way to do the same thing.

**Six new asserts, one per branch, and the negative control run.** No `-RepoRoot` → highest version
(with a version lacking `agents/` still skipped, proving the old filter survives); a record pinning the
*older* version wins; another repo's record does not apply; a stale `installPath` falls through; a
recorded path without `agents/` falls through; an unreadable administration still resolves. With the new
step disabled, **exactly one** assert goes red — the one testing the new behaviour — which is the
evidence that the other five cover unchanged behaviour rather than restating it. **171 asserts, up from
165.**

**Verified live afterwards:** the header now reads `cache 3.2.0`, matching both the record and the
connector hook. The two gates no longer contradict each other.
