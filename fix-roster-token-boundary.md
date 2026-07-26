### Roster token scan no longer reads ISO dates as specialist ids · Fix · 2026-07-26

Inbound issue #182 (source: `DaveKJohn/life-hub`) reported that `check-roster-sync.ps1`'s
orphan-scan reads an ISO date in roster prose as a specialist id: in `2026-07-25` the `07` is
preceded by a hyphen, and the old boundary (`(?<!\d)...(?!\d)`) only excluded a preceding *digit*,
so `07-25` matched and was reported as `[INFO] orphan '07-25' -- no matching agent/persona`. Every
ISO date with a day 01-31 triggers this in any consuming repo that dates its documentation notes --
the normal way to write them.

Verification while fixing this turned up the same boundary duplicated in `Test-InRoster`, with a
more serious consequence: where the orphan-scan only adds `[INFO]` noise, `Test-InRoster` decides
whether a specialist has a roster row at all. A false match there is a missed `[ERROR]` -- a
specialist that has actually been removed from the roster reads as "present" as long as the text
contains a date that happens to look like their id. Concretely reproduced: a roster with no row for
Sylvester (05-15), containing only the prose date `2026-05-15`, made the old `Test-InRoster` return
`True`. The groups this system uses (02 through 06) are exactly the month range covered by everyday
dates, so this was a real, not theoretical, gap -- `2026-05-15` masks Sylvester, `2026-06-16` masks
Tessa, `2026-06-17` masks Edith, and so on.

**Fix:** tightened the leading boundary to also exclude a preceding hyphen
(`(?<![\d-])\d{2}-\d{2}(?!\d)`), as issue #182's option 1 proposed, but implemented as **one shared
source** instead of two separately-tightened regexes -- a new `Get-RosterIdTokenPattern` in
`scripts/lib/check-report-lib.ps1` (optionally parameterized with a specific id), which both
`Test-InRoster` and the orphan-scan's `[regex]::Matches` now call. That single source is the point
of this fix: the bug existed on two call sites in the first place because the same lookaround was
duplicated instead of shared, so a one-sided fix would have left the door open to the same drift
recurring.

The trailing boundary deliberately stays `(?!\d)`, not tightened to `(?![\d-])`: a real lens
reference is immediately followed by a hyphen (`05-15-extension.md`), so excluding a trailing hyphen
too would break that legitimate case. Verified both directions before and after the change (ISO
dates no longer match, `06-24`/`05-15` inside real references still do).

Deliberately **not** done: issue #182's option 2 (binding the token to a roster-row/table shape).
`Test-InRoster` is asked about a specific id in free prose, and consuming repos are free to format
their roster differently (table or list, per `Get-RosterPath`'s own doc note); binding the match to
a table shape would change behavior for those consumers -- a bigger risk than the residual noise
this leaves.

**Known limitation (not silently closed):** this narrows the ISO-date case specifically, but does
not cover every prose false positive. Issue #182 itself named a version range like `1.2-3.4` as the
example, but that example is wrong -- verified against the actual pattern, `1.2-3.4` does not match
at all (`\d{2}` needs two-digit segments, and `1`/`2`/`3`/`4` are single digits). The real residual
case is a plain two-digit number range in ordinary prose, e.g. "see pages 12-34" or "a range of
10-20 items" -- verified those do match. That only surfaces as a visible `[INFO] orphan '12-34'`
line as long as no real specialist happens to share that id; it never escalates to `[ERROR]`.
Accepted as documented residual risk.

Mirror rebuilt (`scripts/sync/build-shared-scripts.ps1`) so
`claude-code-plugins/claude-specialists/specialists/scripts/{lib/check-report-lib.ps1,sync/check-roster-sync.ps1}`
stay byte-identical to the root copies.
