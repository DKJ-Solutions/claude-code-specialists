### Turn the highlights tier on: this repo cuts a stakeholder document too · Feat · 2026-08-03

**Dave's decision, and it reverses what the previous PR wrote one commit earlier.** #427 landed the
highlights tier as shared code and left it switched **off** here, on the reasoning that this repo's
release audience "is developers", so a stakeholder document would have no reader. That was the wrong
unit of analysis. The audience question is not developer-versus-not, it is **who decides whether to
update** — and that reader does not want the full per-PR record. Serving them the development notes is
the same mismatch a storefront repo has with its management: one tier doing two jobs badly.

**So this repo now runs the same three tiers as the consumer the model came from, grouped per major:**

| tier | for whom | when | status |
|---|---|---|---|
| `development/<X>.x/<X.Y.Z>.md` | developers — the raw, complete per-PR record | every release | already existed |
| `internal/<X>.x/<X.Y.Z>.md` | colleagues, employers — what the work is worth | every release | **not yet** — port pending |
| `highlights/<X>.x/<X.Y.Z>.md` + `.html` | consumers — what they actually notice | minor/major | **on now** |

**Per major (`3.x`), not per minor** — Dave's explicit call. The consumer folders per minor; here all
three tiers read the one answer in `Get-ReleaseNotesGrouping`, so the scheme is stated once.

**Why minor/major and not patch needs no second rule.** A minor here is cut when a consumer actually
notices something; a patch is what is left over. So the bump type already answers "does this release
have a highlights reader", and the tier agrees with it by construction rather than by convention.

**The measured caveat, recorded in all four places a reader might look.** The split puts `Feat`/`Fix`
above the "remove before publishing" marker and everything else below it, and in the storefront repo
that is reliable — a `Style` or `Content` branch there *is* a customer-visible change. **Held against
this repo's real 19 pending entries, it is not:** the single most consequential change a consumer could
face — renaming the marketplace, which breaks every existing install — arrived on a `chore/` branch and
therefore lands *below* the marker, as did "a folder rename silently unlinks plugin installs" from a
`docs/` one. `Feat`/`Fix` is kept anyway and deliberately: the value of the split is that **both halves
are written out**, so the release manager sees what is a candidate for cutting. A wrong-but-visible
proposal costs one edit; no split at all costs the hint entirely. What changed is the instruction around
it — the editing pass is "read both halves and promote what matters", not "delete the bottom one".

**Docs corrected rather than appended to,** because three of them stated the opposite as settled fact:
`CLAUDE.md` (the tier is off "as a statement about the product"), [Rendall
#06](.claude/specialists/lenses/05-06-extension.md) ("Rendall therefore never has a highlights draft to
edit here, and should not go looking for one"), and the `cut-release` skill, which named this repo as an
example of a repo that wants no such document. `releases/README.md` gained a **Three tiers** section.

**Two stale marketplace names fixed on the way.** `releases/README.md` still opened with
`# Release notes — davekjohns-workshop` and called it "the davekjohns-workshop marketplace", three
weeks after the [one-product rename](README.md#one-product-one-repository). Corrected, with a note that
the archived notes under `development/` keep the old name deliberately — those are history.

**Tests: `repo-config.tests.ps1` asserts the new values rather than dropping the old asserts** (33
asserts, up 5). Both knobs are held to something stronger than a literal: the stakeholder types are
checked against this repo's **own** branch table, because a type named here that `branch-info.ps1` never
produces would put an empty category above the marker and silently drop the real ones below it; and the
complement is asserted non-empty, or the marker block never appears and the knob does nothing. `patch`
is asserted **absent** so adding it later is a decision rather than a drift.
