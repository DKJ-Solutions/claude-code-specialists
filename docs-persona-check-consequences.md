### Record the v2.9.0 persona-check consequences · Docs · 2026-07-28

Follow-up to v2.9.0 (PRs #205/#206). Two things the release made true that were not written down
anywhere the next session would look.

**The smartwatchbanden register note asserted something the release invalidated.** It read
*"03-02 (Bianca) has no repo lens in swb yet; not required, but worth mentioning."* The
"not required" was accurate until v2.9.0 and is now the opposite of the truth: `check-roster-sync`
checks persona-only specialists for a missing roster row/lens, so once that consumer updates past
v2.1.0 this surfaces as an `[ERROR]` there. Rewritten to say so, and to name both valid outcomes —
adopt her, or record the deliberate omission in that repo's `Get-RosterIgnoredIds`. Deliberately not
resolved here: which of the two is right is a decision about that repo, not a defect this repo can
fix. The register `notes` field is where that bookkeeping belongs, so the correction lands here rather
than as a reminder about work elsewhere.

**Two script lessons recorded in [Sylvester #15](.claude/plugins/claude-specialists/specialists/05-15-extension.md)'s
lens**, alongside the existing `$LASTEXITCODE`/stderr/StrictMode pitfalls:

- **A check's `[ERROR]` text is a consumed interface.** `sync-roster.ps1` parses
  `check-roster-sync.ps1`'s finding lines rather than re-implementing detection, so rewording or
  widening a finding changes what the recovery skill can act on. Inbound #204 hit this: the new
  `persona '01-01' ...` findings did not match the then-`agent`-only pattern, while both the check's
  report and the session hook point the reader at that skill. Left alone it would have shipped advice
  that looks helpful and does nothing — for exactly the findings the change introduced. Also noted:
  the sync-roster tests drive the *real* check for this reason, so a wording change does fail them;
  that failure is the coupling reporting itself, not a test to patch.
- **Verify a diagnosability fix against real data, not against the diff.** A report that "names the
  thing" reads correct in review and can still be useless. Inbound #203's connector label was provably
  right and fully tested, and still produced two word-for-word identical lines against this repo's own
  register — that consumer registers two plugins, both behind on one outdated install, and the
  distinguishing `-- plugin:` header is what the hook filters away. Only running it surfaced that. A
  fixture proves the mechanism, not the usefulness.
