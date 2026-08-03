### The teardown audit walks every file under the scanned roots, and now says so · Fix · 2026-08-03

Closes [#421](https://github.com/DaveKJohn/claude-code-specialists/issues/421). The free-standing
audit's walk carried `-Include '*.md', '*.ps1', '*.json', '*.jsonc'` beside `-LiteralPath`, and
**PowerShell silently ignores `-Include` when the path is given as `-LiteralPath`** — so the walk has
always read every file under `CLAUDE.md`, `.claude/` and `scripts/` while its own code named four
extensions. Sibling instance of the one repaired in `Get-MojibakePaths` (#413), and reported with it.

**Repaired in the other direction, and only after measuring — the issue filed it rather than fixing
it in passing precisely because the line cannot answer its own question.** Both halves:

1. **Does any documented teardown figure move?** No. Across the three repos on hand
   (`claude-code-specialists`, `life-hub`, `djcylow-react`) the only files outside the four extensions
   anywhere under those roots were two `.js` files in `djcylow-react/scripts`, and both scan to zero
   hits. No round's number was measured against something the strict list would have excluded, so
   nothing already written down changes.
2. **Is the superset the better behaviour?** Yes, and the experiment is not close. A fixture holding
   `// Derek opens the PR` in `scripts/deploy.js` and `Tessa maintains the manuals` in
   `.claude/notes.txt`, with a `CLAUDE.md` that mentions nobody:

   | walk | scanned | verdict |
   |---|---|---|
   | as it is (extension-agnostic) | 3 files | 3 `[LIVE]` references, named by file and line |
   | with the filter made to work | 1 file | **`[FREE]` — no live reference at all** |

   So "repairing" the call would have turned a repo carrying three live references into a clean bill
   of health. A live reference is live regardless of the extension it sits in; an allowlist here is a
   false-negative generator, in the one section whose bias is stated twice in its own comments — *a
   false positive is cheap and a false negative silent*.

So the four names are **deleted** rather than made to work, with the measurement recorded at the call
site. The one cost is named instead of left to be found: a non-text file under those roots is read
too and could match the id pattern on decoded bytes, which costs one `[LIVE]` line — the output prints
the path and what matched, never the matched text, so no binary content can reach the console.

**The regression test asserts on the result, not on the code**, because that is the only reason the
sibling instance was ever found: `Get-MojibakePaths returns only .md files` caught #413 while the line
itself read correctly for years. A test grepping this script for `-Include` would pass against a
rewrite that reintroduced the same blindness by another route.

**To do / where I left off:** done — lint gate green, all suites green (teardown suite 202 pass).
