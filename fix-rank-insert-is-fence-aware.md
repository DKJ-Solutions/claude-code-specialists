## The ranked insert is fence-aware, like every other reader of the entry format

### What does this change do?

**A tier-1 entry led a list whose next six entries were tier 2.** `Get-ImpactInsertOffset` — the function
that decides where the fold places an entry, and therefore the order every release document inherits — split
the changelog into blocks with a plain regex. It was the one reader of this format that was not fence-aware.

**Measured on the fold of [#477](https://github.com/DaveKJohn/claude-code-specialists/pull/477), in the
document [#476](https://github.com/DaveKJohn/claude-code-specialists/pull/476) had created hours earlier.**
That entry quotes an entry heading inside a fence, as the worked example of the format it introduces —
exactly what an entry documenting a mechanism does. Three consequences, none of which errored:

- the quoted heading was read as an entry boundary, **splitting the real entry in two**;
- the fragment above the fence holds no impact table — the table sits further down, under
  `### Who is this for` — so it read as **tier 0, score 0**;
- the loop meets that tier-0 fragment **first**, so any entry of tier 1 or higher is inserted above it: at
  the very top of the document.

The ranker also read the *quoted* table as the entry's declaration, so a fence-blind read got both the
boundary and the tier wrong from one cause.

**The console line reported it and the number was the tell:** *"placed above 8 existing entries"* in a
document that had 7. Worth recording, because taking that line at face value was the available mistake — the
order was verified against the parser afterwards, which is what turned a plausible message into a defect.

**This is the fourth-plus instance of one class in this format's short history: a matcher satisfied by a
MENTION rather than a use.** `Split-EntryBlocks`, `Resolve-EntryImpact`, `Resolve-EntryTier`,
`Get-EntrySectionBody` and `Set-EntryHeadingLevel` were all made fence-aware for exactly this reason. This
one was missed because it was written when an entry could not contain headings of its own — the flat format
made that false the same day, and nothing re-derived which readers the change had newly exposed.

**Fixed by walking lines rather than characters**, since fence state is a per-line fact: the offsets are
rebuilt from the same split the flags come from, taking each line's separator from the source so a CRLF
document is not shifted by a byte per line — the root `CHANGELOG.md` is CRLF here.

**And the fence walk now has one owner in this lib.** `Get-EntryFencedLineFlags` is new, and
`Get-EntryTextOutsideFences` reads it instead of walking fences itself — two readers of one fact rather than
two answers that can drift, which is how a quoted heading becomes structure. `release-lib.ps1` has its own
`Get-FencedLineFlags` with the same semantics; **collapsing those two is a real follow-up and deliberately
not done here**, in the same change as a defect repair. The dependency can only run one way: the fold and
this lib's own suite load it standalone, so it cannot reach up into `release-lib`.

**The entry #477 had already been misplaced on `main` is repositioned in this branch**, by the fixed
function rather than by hand — so the placement is the code's answer, and correcting it exercises the repair.
It now sits between the tier-2 block and the tier-0 one, which is where its own table says it belongs.

### Who is this for

| Tier | Significance | Why |
|---|---|---|
| 2 | 3 | a consumer whose entries quote the format -- the likeliest kind of entry to do so, since it documents a mechanism -- gets the ordering their impact tables actually declare rather than one determined by where a fence sits; noticed the moment they look at the folded list |
| 1 | 4 | the ordering this team just built is the only thing deciding what leads a release document, and it was silently wrong for any entry quoting an entry heading -- which the entry introducing the format did |

### Type of change

Fix
