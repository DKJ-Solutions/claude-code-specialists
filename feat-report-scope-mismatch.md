### report the local-scope record a session start leaves behind · Feat · 2026-08-01

Closes inbound [#314](https://github.com/DaveKJohn/davekjohns-workshop/issues/314), the second of round
v8's three findings (overview: [#316](https://github.com/DaveKJohn/davekjohns-workshop/issues/316)), and
gives [#315](https://github.com/DaveKJohn/davekjohns-workshop/issues/315) the mechanism its documentation
fix could not provide.

**The finding: `[NOT-INSTALLED-HERE]` cannot fire from a session at all.** The fix for #302 was present
and correct in the payload, and round v8 built the exact partial fixture it targets — three plugins
enabled, one with no record anywhere on the machine — and got the line on no branch. Not a bug in the
predicate: **the session start writes the missing record itself**, with a fresh `installedAt`, so the
state has healed before any hook can look. The marker is reachable only by a *deliberate* run in a repo
where a record went missing and no session has started since — a far narrower window than the code's own
blind-spot note claimed, and that note is corrected in place rather than quietly widened.

**What survives a session start is a record of the wrong shape, and nothing reported it.** So there is now
a fifth non-counting marker, `[RECORD-SHAPE]`, joining `[ORPHANS]` (#204), `[UNREGISTERED]` (#208),
`[INVENTORY]` (#220) and `[BOOTSTRAP]` (#225) — reached for rather than invented, which is that pattern's
own instruction. It reports two measured shapes:

- **a record scoped `local` and none `project`** — what a session start leaves behind (#314);
- **more than one record for one `projectPath`** — what the prescribed repair install leaves (#315).
  Step 0c already taught the reader that two lines is the signal, but only a human eyeballing that query
  ever saw it. That is the "a rule with no mechanism" shape, and this closes it.

Not an `[ERROR]`, deliberately: the plugin loads from a `local` record just as well, so nothing is broken
and exit 1 would be a lie. Neither shape can indicate tampering — the CLI writes both. It gets **its own
verdict line** in `roster-sessioncheck`, and that is the point of the change: on a clean run the state
would otherwise fall through to *"roster in sync with the enabled plugins"* — true about the roster, and
the most misleading thing the hook could say to that reader. It also rides along with the drift, bootstrap
and not-installed headlines, since an `[INFO]` the hook suppresses is indistinguishable from no finding.

`Get-RecordShape` sits beside `Test-PluginInstalledHere` rather than inside it: one predicate must stay
permissive (a false not-installed claim is the cry-wolf failure #294 spent a release removing) and the
other strict about a shape. The tests assert both on the same fixtures, so the disagreement is pinned
rather than merely argued — "still installed here" stays true in every case the new one reports.

Coverage: 6 new scenarios in `roster-sync.tests.ps1` (11g–11l) plus 3 hook-branch cases (H11–H11c), and a
`Get-RecordShape` block in `check-report-lib.tests.ps1` including all four states that belong to another
marker — a pathless record, no record, an absent `scope` field, and an unreadable administration — so the
predicate cannot grow into its neighbours' territory unnoticed.
