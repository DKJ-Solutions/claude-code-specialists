### Remove the three dated research dossiers and the lens link that pointed at one · Chore · 2026-07-26

Dave decided the three dated dossiers under `research/` could go. Removed:

- `research/copilot/bevindingen.md` — Copilot research, July 16, 2026
- `research/plugin-sharing/vervolgstappen.md` — the marketplace-migration project log, last
  updated July 16, 2026
- `research/security/nulmeting-2026-07-15.md` — the security baseline, July 15, 2026

**Verified before deleting.** The baseline listed three follow-up actions; all three were checked
one by one and confirmed done before removal, so no open action was lost: the injection guardrail
now exists as the shared block `webcontent-boundary` (in four agent defs), the CI check is a
required status check via the ruleset, and the literal Windows paths in
`check-consumer-drift.ps1` were replaced by the placeholder `C:\path\to\life-hub`.

**The convention stays, only the dead example goes.** Dave's decision covers the dossiers, not
the `research/<topic>/` destination convention itself — that remains valid for future research.
[Rebecca's lens](.claude/plugins/claude-specialists/specialists/03-07-extension.md) referenced the
now-removed `research/plugin-sharing/vervolgstappen.md` as a worked example; that dead link is
gone and the surrounding text now describes the destination on its own terms, without depending on
a dossier that exists to point at.

**Resolves the PII note in passing.** The security baseline itself had flagged the literal local
paths with an account name in `research/plugin-sharing/vervolgstappen.md` as a light PII exposure
in a public repo; removing that file resolves it.