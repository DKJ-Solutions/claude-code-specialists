### `specialists-teardown` — adoption is now reversible · Feat · 2026-07-29

Third item of [#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221), and the half that
could be built and tested without restructuring anything first. Dave's requirement: a consumer must be
able to install **and uninstall** at any moment and afterwards stand free of the plugin. There was a
`specialists-init` to build up and nothing to take down.

[`specialists-teardown`](claude-code-plugins/claude-specialists/specialists/skills/specialists-teardown/SKILL.md)
is the bootstrap's mirror image: where the bootstrap is strictly **additive** and never overwrites, the
teardown is strictly **subtractive** and never deletes what the owner wrote.

**Classifying before removing is the entire design**, because consumer-side content is three things and
only one is disposable:

| category | what happens |
|---|---|
| generated and untouched — a lens still carrying its `VUL-IN` marker, an unfilled script scaffold, the `@`-imports, `settings.suggested.jsonc` | **removed** |
| authored by the owner — a filled-in lens holding repo knowledge somebody wrote | **reported, never touched** |
| owned by the repo anyway — a real `repo-config.ps1`, a filled branch table | **reported as yours to keep or drop** |

The `VUL-IN` marker is the test, because that is the exact contract `bootstrap.ps1` writes those files
under; its absence means somebody edited the file, which makes it theirs. Deliberately a content test
rather than a timestamp or hash — a reformat or a merge does not make content authored.

**Dry run by default.** A destructive script running on somebody's repo should have to be asked twice,
and the preview doubles as the inventory a reader needs in order to say yes.

**Two things it refuses to do.** It never edits `.claude/settings.json` — disabling the plugin is the
owner's act, and the bootstrap never wrote that file either, so the symmetry that makes this safe cuts
both ways; it is reported instead, noting that the subagents and hooks stay active until the entry is
gone and the session restarted. And it never removes roster rows or repo prose from `CLAUDE.md`: the only
lines it touches there are the two `@`-imports, safe because an import naming a persona body or an
extension lens is knowably bootstrap-written — the same property that let `check-roster-sync` stop
counting them as roster rows (#227).

**Measured round-trip:** bootstrap a fixture → 24 items placed → teardown removes 22 and keeps the 2 the
owner filled in, with the owner's own `CLAUDE.md` prose intact.

**38 tests, and the ones that matter are the negative ones.** A teardown that removes plenty is easy; one
that can be trusted has to demonstrably not touch authored content, not edit `settings.json`, and not eat
an unrelated `@`-import. That last case is the sharpest risk in the design: a consumer's own
`@docs/git-instructions.md` is exactly the line a sloppy rule destroys, and they would have no idea why
their instructions stopped loading. The matcher keys on the specialist shape, and the test proves it.

**What it still cannot finish, stated rather than glossed.** A repo that authored lenses and roster
sections is not blank afterwards — those are reported, not removed. As long as specialist content is woven
through `CLAUDE.md` instead of sitting behind one inclusion, no script can finish without guessing where a
roster row ends and the owner's prose begins. That is the seam, and #221 stays open for it.

The lint gate's skill-enumeration check (#10) caught the new skill missing from two `<!-- skills:all -->`
spans in the family README before CI did — the guard working exactly as designed.
