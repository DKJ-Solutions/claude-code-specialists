### Translate ci.yml to English, closing the last gap in the repo-wide language norm · Chore · 2026-07-26

A documentation audit found that `CLAUDE.md`'s Language section claimed the repo-wide English norm
covers "unambiguously everything," with exactly three named exceptions, while
`.github/workflows/ci.yml` was still entirely Dutch and matched none of those three. Sylvester
translated `ci.yml` (comments, step names, and console output all English now; the job id
`lint-en-tests` deliberately kept as-is — see below). This entry covers the accompanying doc fix
in `CLAUDE.md`'s `### Language` slot, so the norm's own text matches the repo state again.

**The scope enumeration now actually covers what the heading promises.** The "script layer is
fully in scope" bullet named only `scripts/**`, the hooks, and the tests — `.github/**` (the
workflows, the issue templates, the PR template) was missing from the list even though nothing
in the norm ever meant to exclude it. Added, with `ci.yml`'s translation in this pass noted as the
concrete instance that surfaced the gap.

**A technical identifier is now recorded, not just fixed.** The CI job id `lint-en-tests` is the
exact name GitHub's `main` ruleset requires as a passing status check before any PR can merge.
Renaming it to something more English-shaped would silently break that binding: every future PR
would sit unmergeable, waiting on a check that no longer exists — a failure that would only surface
at the next PR, not at the moment of the rename. `CLAUDE.md`'s technical-identifiers bullet now
names it explicitly alongside the existing `VUL-IN` example, with that consequence spelled out, so
a future language pass does not "fix" it into a merge-blocking regression.

**On the "unambiguously everything" phrasing itself:** reworded to "every layer of the repo," with
the enumeration described as meant to be exhaustive and any future undercount named as a gap to
close on discovery — not a quiet exception. The norm itself (repo-wide English) is unchanged; only
the self-description of the list's completeness was softened, since an absolute claim had now
failed twice (once for script-generated document content, once for `ci.yml`).

**A second language gap, found while drafting the `.github/**` scope-bullet above and closed in
the same branch:** the issue template `.github/ISSUE_TEMPLATE/inbound-verbeterpunt.md` had fully
English frontmatter and body, but a Dutch filename. Flagged as a follow-up finding; Sylvester
picked it up directly (a git rename, `inbound-verbeterpunt.md` → `inbound-improvement.md`) rather
than leaving it as a loose end. That broke two links the lint gate then caught: the reference in
`claude-code-plugins/claude-specialists/QUICKSTART.md` and the reference (path plus visible link
text) in `claude-code-plugins/claude-specialists/connectors/README.md`. Both updated to the new
filename. The third reference, in the archived `releases/development/1.x/1.3.0.md`, is
deliberately left as-is: archived release history isn't rewritten to match a later rename (and the
lint gate doesn't scan that directory, confirmed by it flagging only the two live docs above).

**A third technical identifier, found by Edith's copy edit and re-checked before acting on her
read:** `.claude/plugins/claude-specialists/specialists/05-15-extension.md` names the GitHub
ruleset `main-ci-poort` as the required-status-check enforcer. Edith initially read that as
translation debt. The coordinator queried GitHub's API directly to check: the ruleset is really
named `main-ci-poort` there (id 19008062, target `branch`) — the lens quotes reality rather than
lagging behind a norm. Translating the doc's mention would make it false (a ruleset by that English name
does not exist); making the name itself English requires renaming the ruleset in GitHub's
branch-protection settings first, which touches `main`'s merge security and is Dave's decision, not
something this documentation pass can decide on its own. Added to `CLAUDE.md`'s
technical-identifiers bullet, alongside `VUL-IN` and `lint-en-tests`, with the distinction spelled
out explicitly: `lint-en-tests` may not change because the ruleset *binds on* that job name;
`main-ci-poort` may not change because the doc *describes* that ruleset's actual name — two
different reasons, both valid, worth keeping apart rather than folding into one blanket "don't
translate identifiers" rule.

Also, on Edith's copy-edit: the closing sentence under `### Language` now names this pass's own
scope-sharpening (`.github/**` explicitly covered, July 26, 2026) as a third dated milestone
alongside the July 20 decision and the July 21 sharpening — the identifier bookkeeping and the
completeness-wording revision are left out of that milestone list, since they document existing
practice rather than move the norm's boundary. One wording nit taken as proposed: "had stayed
untranslated regardless" → "had simply been missed" (redundant with "matching none of the
exceptions below").

Corrected in `CLAUDE.md`, `claude-code-plugins/claude-specialists/QUICKSTART.md`, and
`claude-code-plugins/claude-specialists/connectors/README.md`; the rename itself in
`.github/ISSUE_TEMPLATE/` is Sylvester's terrain and was done by him.
