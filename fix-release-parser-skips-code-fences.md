### The release notes parser skips fenced code blocks · Fix · 2026-07-29

Caught by `-NoPush` while cutting v2.13.3, which reported **3 entries from 2 PRs**. The cause: PR #243's
entry body quoted a broken heading structure inside a fenced block — including a `### #242 ...` line — and
`Get-PullRequestEntries` split on it. The generated notes came out with a phantom `#242` entry, `## Fixes`
twice, and the fence torn open so the quoted `##` lines rendered as real headings. Precisely the defect
#243 had just fixed, reproduced by the generator itself.

Two fence-blind tests in one loop, and a third above it:

- `^###\s` started a new entry, inside a fence or not.
- `^---$` was skipped **anywhere**, so a YAML frontmatter example in a quoted block would lose everything
  after its separator.
- The intro/entries boundary scan had the same blindness, which would put that boundary inside a code
  block.

All three now consult **`Get-FencedLineFlags`**, a new pure helper returning one flag per line. It reports
the fence markers themselves as fenced, so a caller that skips fenced lines keeps the markers with their
content instead of stripping them and leaving the body rendered as prose. An unclosed fence leaves the tail
flagged — the safe direction, since it stops the parser inventing structure out of code.

**Fourth instance of one defect class in a single day:** a matcher satisfied by a *mention* rather than a
use. The roster check counted an `@`-import path as a roster row (#227); the lint gate read a marker quoted
in changelog prose as a real enumeration (#235); the teardown read a docstring explaining placeholders as a
placeholder (#242); and this read quoted markdown as structure. Worth noting the shape it took here: the
pre-check written to hunt for stray `##` headings *also* lacked fence awareness and produced a false
positive on the same file — which is how the real bug surfaced.

Also fixed while binding it: a `Mandatory [string[]]` parameter rejects an empty string outright
(`ParameterArgumentValidationError`), and a changelog section can legitimately be a single empty line.

**16 new assertions, verified to fail without the fix** — the flag helper in isolation (including the
unclosed-fence and empty-line cases) and the parser against a sample that quotes both a heading and a
separator inside a fence, asserting two entries rather than three, the quote *kept* in the body, and the
fence intact.

The v2.13.3 release commit that exposed this was local and unpushed; Dave gave explicit permission to undo
it with `git reset --hard`, so nothing broken shipped and the release is re-cut on top of this fix.
