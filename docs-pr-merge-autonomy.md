### Relax the PR rule: wait only for visible or irreversible work · Docs · 2026-07-27

The rule that a PR only opens on Dave's explicit word was written for a case that no longer occurs:
Dave wanted to look at a frontend change with his own eyes before it went in. In practice the work
here has been tooling, config, dossiers, and agent defs for a long time — none of which he can
meaningfully assess in a few seconds — so nine times out of ten he was rubber-stamping a merge
button that added nothing. **The checkpoint was costing a round trip and buying no safety.**

**The new test is one question: does Dave's own look add something the gates cannot?** Not
"frontend versus backend" — this very change is backend, and it is exactly the kind he *does* want
to see. What matters is whether an automated gate can prove the change is sound.

- **Default — no waiting.** Once a branch is finished, committed, and the gates are green, opening →
  merging → folding runs in one motion, without asking. Scripts, tests, config, manifests, docs,
  agent defs and manuals, the changelog, and research all fall here: the lint gate, the test gate,
  and CI prove them, and anything that slips through is one revert PR away.
- **Exception — stop and report.** Work with a **visible result** (a frontend, styling, rendered
  output, an artifact — no gate proves that something *looks* right) and work that is
  **irreversible or outward-facing** (a release, version bump, tag, repo settings/rulesets,
  publishing outside the PR flow).
- **Dave keeps the wheel in both directions.** He can pull a specific job under the exception when
  he assigns it ("this one I want to see first"), and an explicit PR command still counts as
  approval for the whole movement, so a waiting branch resumes in one move.

The reasoning worth keeping: **substantive approval is given in the conversation before the work is
built, not at the merge button afterwards.** That is why the button is only a checkpoint where it
genuinely buys something.

**Carried through both layers in one pass**, because a half-applied governance rule contradicts
itself. Portable (travels to the consuming repos via a release): the constitution in `CLAUDE.md`
(the permission list plus the "never directly on the main branch" block), Derek's persona
`05-05-persona.md` (his responsibilities and his hard rules), Chris's persona `01-01-persona.md`
(the PR step is no longer automatically a waiting point), the `open-pr` skill (frontmatter
description plus the governance note), the `ship-pr.ps1` docstring, and the inbound-route chain in
the connectors README. Repo lens: Chris's gatekeepers and all four chain descriptions in
`01-01-extension.md`, Derek's branch hygiene in `05-05-extension.md`, and step 4 of the workflow in
`CONTRIBUTING.md`.

**Deliberately left alone:** the `park` and `new-branch` skills say "opens no PR", but that is a
statement about those skills' scope, not an approval rule — unchanged. And the release/version bump
stays firmly on Dave's explicit request; this relaxation touches the merge, never the release.

Decision by Dave, July 27, 2026.
