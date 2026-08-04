### The last undocumented mirror gets its page, and check 18's coverage line is down to one honest exemption · Feat · 2026-08-04

**Check 18's coverage line now reads: `NOT covered ... check-script-contract`.** One entry, and it is a
declaration rather than a gap — that script runs from a SessionStart hook and reports, so there is no
procedure to write down. Everything else a consumer can invoke has a page. The line went from four names
to one across three PRs today (#443 took `ship-pr` and `verify-resolved-issues`, this one takes
`fix-mojibake`), and it stayed truthful at every step because the registry declares its own gaps beside
the registration instead of in a second hand-written list.

**This mirror is the one where the missing page was hardest to defend.** It was shared precisely because
three repos had each written their own copy — three people needing the tool and none of them having
anything to read. Mirroring the script without the page fixed the drift and left the reason for it.

**What the page carries beyond the invocation**, both parameters (`-Path`, `-Check`) included:

- **How the damage happens, because that is what prevents it.** `Get-Content` reads a BOM-less UTF-8 file
  as ANSI in Windows PowerShell 5.1, so a middot comes back as two characters and writing it out stores
  the pair. One round trip is enough and **nothing errors** — the file stays valid UTF-8, it just says
  something else.
- **Why it is not cosmetic.** The measured instance: 35 mangled separators in a changelog, and since the
  separator *is* the field delimiter in an entry heading, the release script could no longer read the
  entry type — eleven entries fell into a catch-all category. Caught by `-NoPush` before it shipped.
- **Why the method is the inverse round trip and not a lookup table**, with the number that settles it:
  517 doubly-encoded runs matched no rule in the table it replaced, in files the gate beside it called
  clean. A gate that examines almost nothing while reporting "clean" is worse than no gate.
- **Why both loops run to a fixpoint** (text can be mangled twice; one pass leaves a remainder) and why
  termination is safe (every accepted step makes the text strictly shorter).
- **Why the script's own source is pure ASCII** — a repair tool written with literal non-ASCII characters
  corrupts on the first careless edit and then silently repairs nothing.
- **That the repo-owned `Get-MojibakePaths` REPLACES the fallback rather than extending it**, and that the
  fallback exists because the built-in list used to be workshop-shaped: it walked directories no consumer
  has, so the path filter quietly reduced it to whatever happened to be present. The same failure the
  round trip replaced the table for, one layer up.

**Prevention is stated in order of preference, with running the script third.** Use encoding-aware reads
first, let a gate catch it second. A page for a repair tool that does not say how to avoid needing it is
half a page.
