## `feat/audience-archive-merge` changelog

### Branch title

The two-document archives merge into releases/audience/, so releases/ holds three reader-named roots

### Branch ID

20260812-161208

### Branch type

feat

### What does the change on this branch bring to main?

**`releases/consumer/` and `releases/internal/` are gone, and their twelve version pairs are twelve
documents in `releases/audience/`.** `releases/` now holds three roots and every one of them names its
reader: `development/` the developers, `github/` the Release page, `audience/` whoever this repo publishes
to. That completes the rule the `notes/` → `audience/` rename stated one entry earlier and did not finish.

**The repo recorded the opposite, and recorded it unattributed — which is the part worth keeping.** Both
directories were written up as *"frozen archives"* in three places, and **none of them named Dave**, while
the rename standing beside it in the same entry was attributed to him. So half of that movement was the
assistant's call presented as settled. Asked why `releases/` still had five folders, Dave was offered three
options — merge each pair into one sectioned document, move both under suffixed filenames, or keep the
freeze and own it as his decision — and chose the merge. The suffix option was declined as cosmetic (three
folders, with the split moved down into the filenames); the freeze because it does not answer the question
he asked.

**The identical filenames are why this is a merge and not a rename.** `3.x/3.2.0.md` existed in both trees,
so **24 documents became 12** and no `git mv` could produce that. Each pair keeps both registers intact —
the consumer body under *For consumers*, the organisational prose under *What it is worth* and *What was
still open at this release* — matching the shape `audience/4.x/4.3.0.md` already used.

**Exactly one section was dropped, and the 62/38 measurement is what licensed it.** The internal note's
`## What is different now` restated the consumer document in a colleague register; held against the writing
norm's test 2, `v4.2.0`'s internal note gave ~365 words (38%) that could appear in a consumer-facing section
and did, against ~597 (62%) that could not. That 38% *is* the duplicated half, so the section does not
survive into the merged document while everything else does.

**The prose of a published record was otherwise left as written, and only a clause that had become FALSE was
touched.** A merged document may still name `releases/highlights/`, or describe itself as one of three
tiers, or say `Get-ReleaseHighlightsBumps` — that is what it said on the day it went out, and the same rule
left the seven wrong merge dates standing. What could not stand is a lead written for the *other* document:
four internal notes opened by telling the reader that the commands and the migration steps were "not on this
page", and in a merged file they sit one section below the page that carries them. Those clauses were
dropped; nothing else in them was rewritten. Links were repointed rather than left dead — 8 Version cells in
`releases/README.md` and one in `releases/development/4.x/4.0.0.md` — because a dead link in a record is
worse than a relocated one and repointing one changes no claim the record makes.

**Lint check 25 keeps reading `releases/consumer/`, and that is the point of the list rather than an
oversight.** This repo no longer has that directory; a consumer on the two-document flow still does, and
they receive the gate through a plugin update rather than by choosing to. Dropping the name would silently
stop holding their outward-facing documents behind a coverage count that still looked healthy. Reading an
absent root costs nothing — absent roots are filtered out. `releases/internal/` is deliberately **not** in
that list, and a new assert pins it: an internal note's reader *is* the organisation, so a link from it into
the per-PR record is correct, and scanning that tree would accuse a right document of the one thing it
cannot commit. The merged document is covered because both registers share one file, which the check's
reader-not-directory rule already handles.

**And the paths that must NOT move were verified rather than assumed.** `new-internal-note.ps1:166`,
`Get-ReleaseNoteRoot`'s shared `releases/notes` default, `release-lib.ps1`'s defaults and the contract
record all still name the two-document flow's own directories. Those describe a *consumer's* archive, not
this repo's, and repointing them is the one failure available here that would produce no error message at
all. Both `CLAUDE.md` and Rendall's lens now say so at the point where somebody would reach for them.

### Significance

#### Tier 0

`releases/` answers "which of these do I write, and who reads it" with three folders instead of five, and
the two that carried the answer nobody could reconstruct — a freeze attributed to no one — are gone. The
merge also repaired a dead link in a published record and closed the last unfinished half of the
reader-naming rule, so the next person reading `releases/README.md` is not told a directory exists that
does not.

**Score:** 3

#### Tier 2

**A consumer reading this repo's release history gets one document per version instead of two, for every
version back to `v3.2.0`.** Before this, twelve versions were split across two directories with identical
filenames, and the release-overview row pointed at the organisational half — so the document written *for
them* was the one they were not linked to. All twelve Version cells now reach the merged document, and the
`For consumers` section is the first thing in it.

Nothing they run changes and nothing they hold breaks: the gate that checks their own outward-facing
documents still reads a `releases/consumer/` archive if they have one, and every script that writes the
two-document flow keeps writing exactly where it wrote before.

**Score:** 3

### Pull Request

