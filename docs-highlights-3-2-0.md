### The v3.2.0 highlights, edited for the reader who decides whether to update · Docs · 2026-08-04

**The first edited highlights document, and editing turned out to mean rewriting.** The generated draft
was **1,098 lines** of the same prose the development notes carry — the tier renders the release a second
time, it does not translate it. Nineteen entries written for someone reviewing a diff cannot become a
document for someone deciding whether to update by deleting the bottom half; the audience change is the
work. The result is **153 lines** (86% shorter) in four sections: what to act on, what you gain, what was
repaired, and where to start reading. Both figures counted the same way, since the two conventions this
repo distinguishes differ by one here.

**The marker's proposal was wrong in exactly the way Rendall's lens predicted, and the measurement now
has a worked instance behind it.** The generator puts `Feat`/`Fix` above the "remove before publishing"
marker and everything else below. The single most consequential change in this release — renaming the
marketplace, which breaks **every existing installation with no error message** — arrived on a `chore/`
branch and therefore sat *below* the marker, in `Maintenance`, at line 1,034 of 1,098. "A folder rename
silently unlinks plugin installs" was below it too, from a `docs/` branch. Both are now the document's
opening section, under a heading that tells the reader to act before updating. Nothing above the marker
outranked them.

**What a consumer actually faces, once translated out of nineteen technical titles.** One action
(re-point two settings keys, drop the stale install record, re-install), one path change (the plugin
directory lost a level, so a hard-coded import into the cache moves), and one class of silence made
loud — a dead persona import now raises an error instead of yielding an orchestrator with no ritual.
Everything else is gain: three previously unreachable scripts, configurable entry-stub wording for a
non-English repo, and a shared release cut.

**One limit is stated rather than papered over.** The migration sequence follows from the documented
mechanics, not from a measured migration of a real existing consumer — so the document says so, and
points at the verification query rather than at the install's success line, which names no version at
all. Writing a confident procedure nobody has walked is how a wrong reason gets a citation.

**Three scaffold remnants removed, and they are the reason the gate that now blocks them exists.** Three
of the draft's entries still carried the status heading the scaffolder writes:

```
**To do / where I left off:** done -- lint gate green, all suites green.
```

They reached the release notes and the per-plugin `CHANGELOG.md` files that travel to consumers in the
plugin cache. The scaffold gate landed *after* this release was cut, so v3.2.0 is the last document that
could contain them.

**Two claims inside the draft had gone stale between the cut and the edit**, both from entries that were
true when written: the tier table announced a print-ready `.html` alongside the markdown (removed the
same day, in #429) and listed the internal tier as *not yet — port pending* (it shipped hours later, in
#431). An entry body is history and is not rewritten; a consumer-facing document is not, so neither
claim survives here.

**The GitHub Release itself is deliberately not published.** `v3.2.0` is a minor, so it has one, and this
document is its body — but publishing is outward-facing and waits for Dave's explicit word, unlike this
file, which lands the ordinary way.
