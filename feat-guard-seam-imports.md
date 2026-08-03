### Make a dead persona-body import loud instead of silent · Feat · 2026-08-03

`check-roster-sync.ps1` now resolves every `@`-import in the roster/seam file and reports an
**`[ERROR]`** for any that does not exist — so the one file in this system whose absence nothing
reported finally has a guard.

**Why this was the worst possible silence.** The roster is repo-local, so it always loads. The
orchestrator's *body* is the only part that comes from outside it, through a single `@`-import. If
that path is wrong the session still starts, the roster still renders, the persona table is still
intact — and the orchestrator runs with no ritual, no delegation discipline, and no
"nothing happens anonymously" rule. Claude Code reports nothing: an unresolvable import fails
silently. It has already happened once, on August 3, 2026, when the marketplace rename broke that
import in every consumer at the same moment; the only available signal was somebody noticing that the
orchestrator sounded generic, and the repair was by hand, per repo.

The check runs **before** the existing strip of `@`-lines from the roster text (#227) — the same line,
read for two different reasons, and previously silent when wrong in both.

Deliberately narrow about what counts as an import: the whole line must be an `@` followed by a path
ending in `.md`, and fenced blocks are skipped. The roster's own prose says a specialist can be
invoked as `@specialists:<name>`, and a fenced block may quote an example import; reporting either
would train the reader to ignore the check. It stays an `[ERROR]` even when the cause is "the plugin
is not installed on this machine" — that is not a false positive, it is precisely the state in which
this session's orchestrator has no body — so the finding names the plausible causes instead.

Two things followed from getting the message right:

- **`Format-SafePathToken`**, a path-shaped sibling of `Format-SafeToken` in the shared report lib.
  The id-shaped sanitizer strips `~`, `\` and `:`, which turns `C:\Users\...` into `CUsers...` and
  drops the `~` that says where a home-relative path starts. A finding whose whole job is to name the
  missing path must print one the reader can look up — `Format-SafeToken`'s own docstring says as
  much. It still strips control characters (the line-forging risk these hooks are sanitized against)
  **and square brackets**, because the hooks decide what to surface by matching markers like
  `[ERROR]`, so a bracket in a path would be *counted*, not merely look odd.
- **The `roster-sessioncheck` headline** now reads "a specialist is missing from the roster/lenses, or
  an @-import in the roster does not resolve". Until now that branch had one possible cause; this
  finding is its opposite — every specialist present and correct, while the body is not loading at
  all — and a reader taking the old headline at face value would search a roster that has nothing
  wrong with it.

Scope, as decided: only point 1 of the issue. The clone-versus-install-cache question (point 2) and
the hardcoded names (point 3) stay open, on the issue's own reasoning that the missing guard is worth
more than the path choice, because a guard turns any future recurrence — including one nobody has
thought of — from silent into loud.

---

**A separate repair that had to travel with it, because it blocked the gate.** Running the test suites
for the above surfaced two failures in suites this branch does not otherwise touch, and they turned
out to be one defect with two halves — both of them tests failing on their own formatting:

1. **The child wraps its own `Write-Error` output** at its own width, so its stderr arrives as two
   lines split *anywhere*, including on a space. Removing the newline then glues the words
   (`token` + `'final'` → `token'final'`) and a phrase assert fails — the mirror image of the mid-word
   case the existing normalization was written for. `new-branch.tests.ps1` had predicted exactly this
   in a comment ("if that case ever bites, the fix is to strip ALL whitespace from both the text and
   the pattern"), left it unmeasured, and it bit at console width 198. The prediction was right, and is
   now implemented and pinned in both directions.
2. **The parent then interleaves error-record decoration into the sentence.** Under `2>&1` each stderr
   line becomes its own `NativeCommandError`, and the second record's header, `CategoryInfo` and
   `FullyQualifiedErrorId` were rendered *between* the two halves: the captured text read
   `...the token 'fina` + ~300 characters of decoration + `l'.`. No whitespace normalization can
   survive that — the phrase is not reformatted, it has other content inserted into it. Both suites now
   capture the child's stderr as **plain text** through a redirect file, so nothing but what the child
   actually wrote is ever matched.

Worth stating, because a natural assumption is wrong here: `Invoke-NativeCapture` does not help. It
solves the *terminating* half of the stderr problem (`EAP=Stop` promoting a stderr line to a fatal
error) and leaves the *rendering* half untouched, because it still uses `2>&1`.
