## `fix/stamp-the-source-measurement` changelog

### Branch title

The connector check says which commit it measured

### Branch ID

20260809-110754

### Branch type

fix

### What does the change on this branch bring to main?

`check-connectors.ps1` names the commit its version verdicts were read at, and
`connector-sessioncheck.ps1` carries that into the session:

```text
== check-connectors -- 4 manifest(s) -- source read at 5becd87 ==
  (all registered connectors; source read at 5becd87 -- compare with 'git rev-parse --short HEAD'
   if this session has been open a while; full output: ...)
```

**The defect it closes is age, not arithmetic.** Every `source on vX` in a run is read from a
`plugin.json` in the workshop checkout at that moment, and the SessionStart hook forwards it into a
context that holds it for hours. The claim outlives the tree it was true of, and nothing about its
shape says so — `source on v3.6.0` reads exactly like a live statement.

**The measured instance** ([#533](https://github.com/DaveKJohn/claude-code-specialists/issues/533),
August 9, 2026). A session started at `faa7273`, where the source really was v3.6.0. At 10:24 a
`git pull` moved the checkout to `855fd40`, bringing v3.7.0, v3.8.0, v3.9.0 and 17 commits. The line
already in context still said v3.6.0 and was repeated as current fact — three commands before the tree
was asked directly and answered v3.9.0. Nothing was wrong with that line except that it had aged, and
an undated claim is indistinguishable from a fresh one.

**Two properties that are the whole design, and are easy to undo by accident:**

- **Printed once at run level, not per finding.** It is the same answer for every line in the run, so
  repeating it would cost the reader on every line to say nothing new.
- **The hook lifts the value out of the check's header rather than measuring its own.** The commit that
  matters is the one the *versions* were read at, which is the check's moment; a second `git` call in
  the hook could disagree and put a wrong timestamp on a right number — worse than no timestamp,
  because it invites trust.

No git, no header, no stamp. A source tree that is not a git repo — a consumer holding a downloaded
copy — gets the line it always had. An omitted stamp is honest; an invented one would be the defect
this closes, wearing its own repair as a disguise.

### Significance

#### Tier 0

The instance is this repo's own: a stale version claim was read back as current fact in the session
that then measured the real answer three commands later. Working from more than one device makes the
window routine rather than exotic — any pull ages every version line already in context.

**Score:** 3

#### Tier 1

The same window exists for anyone whose checkout moves while a session is open, and the cost is not
knowing which of two plausible numbers to believe. What the stamp buys is a one-step check instead of a
reconstruction from the reflog.

**Score:** 2

#### Tier 2

The hook half ships in the workflow plugin, so a consumer's summary carries the stamp too. Scored low
rather than N/A because the failure it prevents is theirs as well: a consumer session reading a version
gap that the workshop checkout beside it has already closed, and acting on it. It is one clause on a
line they already had — worth naming, not worth announcing.

**Score:** 1

### Pull Request

