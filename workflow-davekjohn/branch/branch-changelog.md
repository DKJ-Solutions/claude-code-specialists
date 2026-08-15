## `docs/release-craft-off-always-on` changelog

### Branch title

the release craft moves off the always-on path into Rendall's lens

### Branch ID

20260815-133730

### Branch type

docs

### What does the change on this branch bring to main?

`CLAUDE.md` goes from **875 lines to 451**, and the always-on layer from **~41,800 tokens to ~30,300** --
about **11,500 tokens returned on every turn of every session**. The measurement that made this actionable
landed hours earlier on `docs/always-on-token-calibration`: the cost was never diffuse across 875 lines,
it was **one sub-item of a two-item list**, 41,168 B over 474 lines, 56% of the document and 32% of
everything loaded before a word of work.

The rule applied is the one this repo wrote for itself on July 28, 2026 and then used exactly once:
**the decision belongs on the always-on path, the evidence for it does not.** Every alternative that was
weighed and declined, every measurement behind a rule, the entry format, the tier model and its audience
knob, the significance rubric and its bands, the release documents and their writing norm, the bump rules
and the renames now sit in [Rendall #06](.claude/specialists/lenses/05-06-extension.md)'s lens, which is
read on demand -- and which `CLAUDE.md` already named on August 4, 2026 as the place holding "the release
craft itself".

**What stayed is the operative half, and the split is the point.** `CLAUDE.md` keeps that the release
commit is a direct-on-`main` exception, that it runs **only on explicit request**, the **bound** on it (a
major only, those two paths only, only once a cut has been asked for), that a **major needs two commits
ahead of it**, and that the hand-written documents land **via a branch + PR** rather than under the
exception. The test used was: *if a specialist could take a wrong action without this sentence, it stays.*
Applied honestly it came out 87% -- much larger than "move the evidence" implies -- so the split was put in
front of Dave as a list before anything was cut, rather than after.

Three things were done to keep this safe rather than merely smaller. The moved prose is **verbatim**, with
only relative links repointed -- the published-record rule this repo already applies to `releases/`, so
dates, attributions and superseded measurements stand as written. The operative half carries a **pointer
into the evidence**, so a rule that reads as arbitrary at the point of use is one click from its reasoning.
And the section heading did not move, so the **six inbound anchors** into it still resolve.

Sylvester's lens gains the encoding trap this branch hit twice: `Get-Content -Raw` reads with the ANSI
codepage and mangled 127 sequences in one command, and a double-quoted PowerShell string ate a backtick and
left a **vertical tab** in `CLAUDE.md` -- legal markdown, invisible in a diff, past every gate. The first
has a repair script already; the second is deliberately **not** proposed as a new check.

### Significance

#### Tier 0

Every session in this repo starts ~11,500 tokens cheaper, which is the single largest context saving ever
measured here and the first movement on a document that had grown to 4.4x its own stated target. It also
resolves the one practice the repo knowingly diverged from in the August 14 best-practices audit. The risk
it carries is real and bounded: a rule mistaken for evidence would now be one click away instead of
resident, which is why the split was reviewed before it was cut and why the pointer exists.

**Score:** 4

#### Tier 2

A consumer's `CLAUDE.md` is their own file and nothing here edits it, so the saving does not travel. What
travels is the demonstrated method -- separate the decision from its evidence, measure the block before
cutting it, and keep the moved prose verbatim -- on a repo where it returned a third of the always-on
layer. Any consumer whose governance document has grown the same way can run the same measurement.

**Score:** 2

### Pull Request
