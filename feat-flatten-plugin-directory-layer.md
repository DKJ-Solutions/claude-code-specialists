### Flatten the plugin directory layer into plugins/ and give the repo one landing page · Feat · 2026-08-03

Steps 3 and 4 of the repository rename (#405 + #406), in one movement because they rewrite the same
page. `claude-code-plugins/claude-specialists/` existed to hold several product *families* side by
side; with one product per repository both levels were empty scaffolding, so they collapse into one:

- **`plugins/<plugin>/`** for the four plugins and `agent-shared/` (plugin source — its generator
  writes the shared blocks into plugin agent defs), **`connectors/` at the repo root** (consumer
  register read by `scripts/sync/`, deliberately not payload that travels in the plugin cache). Moved
  with `git mv`, so history follows. Every path in the repo loses 31 characters — net 27 shorter than
  before the rename began, the longer marketplace name included.
- **The three family-level documents moved to the root**: `QUICKSTART.md`, `UNINSTALL.md`, and the
  735-line family `README.md`, which **becomes** the root README (the old 151-line one contributed
  only `Consumption`, `Versioning`, `Contributing` and the repo layout). One ~800-line landing page
  whose first screen now *routes* — a "Start here" table — rather than explains.
- **The one-product-per-repository rule is recorded** in `README.md`, `CLAUDE.md`,
  `.claude-plugin/marketplace.json` and `CONTRIBUTING.md`, with the nuance that stops the wrong repair
  later: lockstep *within* this product is correct, `cut-release.ps1` needs no change, and the
  versioning problem dissolved with the reorganisation instead of needing a fix.

**Three defects a mechanical path sweep would have shipped, each caught by reading rather than by
replacing.** They are the reason this entry is longer than a move deserves:

1. **`bootstrap.ps1` derived the plugin from a named path segment**, and the new name is not unique.
   It looked up the index of `claude-code-plugins` and took two segments further to skip the family
   level; renamed to `plugins`, that segment occurs a **second** time in every real install path
   (`~/.claude/plugins/marketplaces/<mp>/plugins/<plugin>/personas`), `IndexOf` returns the first, and
   the derivation would have yielded the **marketplace** name — precisely the defect #179 fixed, back
   again through a rename. The segment lookup was already redundant: the parent walk beside it derives
   the plugin correctly in the source, clone and cache layouts alike, so it is gone rather than
   renamed.
2. **The lint gate's parse check matched `plugins` as a path segment**, which now also matches
   `.claude/plugins/` — it is anchored on the plugins root instead.
3. **`Get-TouchedPlugins` excluded the wrong sibling.** `connectors` left the plugins tree (so its
   exclusion guarded nothing) while `agent-shared` moved in (and would have been reported as a touched
   plugin on release). The exclusion follows the directory now, asserted from both sides.

**The lint gate got the root-level `*.md` glob** that #405 asked for, replacing a named list of four
root documents *plus* a glob over the family directory. That directory's glob existed because a
hardcoded list of two had gone stale the moment `UNINSTALL.md` was written beside them and no gate saw
it; moving those documents into the root would have left the named list as the only rule over exactly
the directory where that class of defect lives. It also picks up `SECURITY.md`, which no rule had ever
covered.

**Two measurements in #405 turned out low, and the repo won.** The archived release notes carry **19**
relative links into the old paths, not 8 — all repaired as link *targets* only, since a target is
machinery that has to resolve while the backtick prose around it states where a file stood at the time
and stays untouched (42 such mentions remain, deliberately). And `QUICKSTART.md` and `UNINSTALL.md`
carried relative links of their own that changed meaning **without changing text** — `../../` used to
reach the root from the family directory, and a bare `specialists/…` used to be a sibling. A path sweep
cannot see those; the dead-link gate is what found them.

Not touched, deliberately: `CHANGELOG.md` and every per-plugin `CHANGELOG.md`, the prose in
`releases/**`, and `cut-release.ps1`. Closes #405, #406 and tracking issue #407.
