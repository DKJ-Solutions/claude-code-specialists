## Branch `fix/session-status-tier-reader` changelog · 20260819-153236

### What does the change on this branch deploy to main?

`session-status.ps1` reads an entry's tiers through `Resolve-EntryImpact` -- the same reader the fold ranks
on and the release cut groups on -- instead of through a `#### Tier N` pattern of its own. The block now
hands the reader one whole `##` block per entry rather than walking the file a line at a time, which is what
the current format requires: tier 0's section is the entry's opening `###` question, its discriminator is the
score label underneath, and neither is visible one line at a time or fence-aware.

**The pattern it replaces had gone blind in two steps, and both pointed at a patch.** It knew only
`#### Tier N`, so from August 16 it reported tier 0 alone and dropped the audience tier in silence; when tier
0 in turn stopped carrying a heading of its own on August 19 it printed no tier at all for an entry written in
the shape the scaffolder had just been taught to write. Measured on this repo's own three pending entries: one
printed nothing, two printed `tier 0 -> 2` and swallowed their tier-2 line. All three now read correctly, and
the reach they were hiding is a **tier 2 at score 4** -- the minor the pending work has earned, against the
patch a silent tier 0 argues for. `/lock` and `/handover` both open with this script, so that wrong answer was
the first thing a session read.

**Reading through the shared reader is the repair; adding the missing heading would not have been.** Seven
shapes parse there, so every entry already in `CHANGELOG.md` and in every consumer's tree is read as what it
is -- and the next rename cannot reopen this. `N/A` and an unanswered score are now printed as themselves
rather than folded into a zero, and a malformed tier section is surfaced instead of dropped.

**The script keeps its promise that nothing is required.** The library is probed at `..\lib`, the same
relative step `new-branch.ps1` takes, so it resolves in this repo and in the plugin mirror alike; `repo-config`
is loaded once above both readers that need it, because a named tier heading resolves through
`Get-ReleaseAudienceTier`. Absent either, the block states that the tiers are unread rather than inventing a
number -- `tier not read` is a worse-looking answer than `tier 0` and a far better one, because tier 0 is not
a missing answer but a decided one.

Its header said *"it dot-sources nothing"* until today, which had been untrue since the source-repo guard
arrived on August 12 -- and while it stood, that sentence was the argument for giving this block a pattern of
its own. It now says what is actually load-bearing: nothing is **required**.

**Score:** 4

#### What makes this change extra special

A consumer's `/lock` and `/handover` stop reporting a tier nobody declared. How far that reaches depends on
one thing, and it is worth stating rather than averaging over: a repo that has **stated an audience tier** is
scaffolded in the named shape, so its reporter was silently wrong in exactly the way this repo's was; a repo
that has **stated none** keeps the numbered `#### Tier N` headings, which the retired pattern did read -- for
them this is the smaller half. Both gain the parts that were never right: `N/A` rendered as `N/A` instead of a
zero, a malformed section surfaced instead of swallowed, and a reporter that cannot be outrun by the next
format change.

**A consumer who has the reporter and not the format loses nothing.** The library is optional, and where it is
absent the tiers report as unread -- a stated line, not an error and not a fabricated 0.

**Score:** 3

### Pull Request

session-status reads the entry tiers through the shared reader
