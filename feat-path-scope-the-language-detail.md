### The language detail moves off the always-on path, and the rules of that lever are now verified · Feat · 2026-07-29

Part of [#217](https://github.com/DaveKJohn/davekjohns-workshop/issues/217). That issue proposed moving
content off the automatic loading path into path-scoped `.claude/rules/` files, and flagged one thing as
**unverified: whether such rules survive a `/compact`.** The whole strategy rested on it, so it was
checked before anything moved — and the answer constrains the lever rather than just enabling it.

| at `/compact` | what happens |
|---|---|
| project-root `CLAUDE.md` and rules **without** `paths:` | re-injected from disk |
| rules **with** `paths:` frontmatter | **lost until a matching file is read again** |

Two consequences that together define the whole trade. **A rule without `paths:` saves nothing** — it
loads unconditionally with the same priority as `CLAUDE.md`, so relocating text there is filing, not
trimming; the scoping *is* the saving. And **a `paths:`-scoped rule is deliberately not always-on**, so
the test for a candidate is whether the content is inert until someone opens a matching file. If yes the
scoping is self-healing, because touching the layer reloads the rule.

`### Language` was the textbook case: 65 lines, the largest section in `CLAUDE.md`, almost all of it
per-layer detail about `scripts/**`, `.github/**` and `releases/**`. It now lives in
[`.claude/rules/language-layers.md`](.claude/rules/language-layers.md), scoped to exactly those paths.
**`CLAUDE.md` goes from 328 to 282 lines.**

**The trap inside that section is the part worth keeping.** It also contained one sentence that had to
stay behind: *the session-reply language follows the user.* That governs every turn regardless of which
files it touches, so path-scoping it would have quietly weakened it after the first compaction — and it
is a rule that had already been broken in practice earlier the same day. Generalised in
[Nolan #25's lens](.claude/plugins/claude-specialists/specialists/06-25-extension.md): **read a candidate
section for the one sentence that is not about the files, before moving the block.** The docs' own escape
hatch is the tell — *"if a rule must persist across compaction, drop the `paths:` frontmatter or move it
to the project-root `CLAUDE.md`."*

**The easy room is now spent, and that is recorded too.** Applying the same test to what remains: the
roster/routing table fails it (routing is needed at intake, before any file is read), the safety rules
fail it (they must survive compaction), and `## The Claude Specialists` fails it. So `CLAUDE.md` stays
above the 200-line target, and closing the rest is the judgement call Dave already deferred — not more
relocation.

Verified beyond the gates: every link in the new rule file resolves (the lint gate does not scan
`.claude/rules/`, so that was checked by hand), and `check-roster-sync` still reports `0 error(s)`
against the shortened `CLAUDE.md` — the roster table was not touched, but a trim that silently broke the
roster check would be a poor trade.
