### open-pr can refresh a resumed PR's description from the changelog entry · Feat · 2026-08-04

**`open-pr -RefreshBody` rewrites the description of an already-open PR from the current changelog entry,
and only that section.** This closes the gap the resume feature left the same day: a resumed branch runs its
gates and pushes, but deliberately leaves the body alone — so a rewritten entry never reached the PR. On a
branch that keeps growing that is the normal case, and the result is a PR describing an earlier version of
the work while the merged entry carries the new one. The entry is what ends up in the release notes, so the
two disagreed precisely where people go looking.

**Opt-in, and the default silence is the safer half.** A body may have been edited on github.com; refreshing
on every run would overwrite those edits without being asked. So the switch exists for the case that
actually happens and stays off otherwise. Everything else is preserved: the `Type of change` boxes, the
checklist, the `## Resolved issues` block, and anything a reviewer added.

**No new seam.** The heading the description lives under is the **first `## ` heading of the PR template** —
where the placeholder sits that the fresh-PR path already replaces — so the template answers this instead of
a `Get-PrDescriptionHeading` a consumer would have to set. A template without such a heading warns and
changes nothing rather than guessing.

**Both body edits now go out as one `gh pr edit`.** The resume path could already append a missing
`Closes #<n>`; with the refresh there are two possible mutations, computed against the same starting body
and compared to it once at the end. Two calls would be two PR updates and two notifications for one run,
and "nothing to do" now means no API call at all rather than a no-op edit.

**The logic went into a new `scripts/lib/pr-body-lib.ps1` rather than into the script, and that is the
lesson from earlier today applied rather than restated.** `open-pr.ps1` drives a live remote and carries a
documented test gap; the defect found in `ship-pr.ps1` that morning sat in an **inline parse**, not in the
orchestration the gap note excused. So both pure functions live in the lib with 28 asserts behind them:

- **`Get-EntryDescription`** — everything after the entry's first `###` heading. It **replaces** the inline
  loop `open-pr.ps1` used, so the fresh path and the refresh path cannot read the entry differently. Putting
  it under test immediately bought something: it now refuses to treat a **later** `###` in the entry's own
  prose as the heading, which would have truncated a description while looking perfectly plausible.
- **`Update-PrBodySection`** — replaces one section, bounded by the next heading **at the same level or
  higher**. That subtlety is load-bearing: stopping at the first deeper heading would strand half the old
  description below the new one, leaving a body that reads as though it says two things. Fenced code is
  skipped when looking for that boundary, because an entry explaining this mechanism writes the heading it
  is explaining — as this one does.

**One assert failed on the first run, and it was right.** With empty content the function cleared the
section. The suite demanded the body come back untouched, because there is no reason to want a blank
description while there are several ways to arrive with nothing — an entry with no body, a heading that did
not parse, a failed read. That is now an explicit no-op in the lib, plus a guard in the script that refuses
to send a body that assembled to empty.

**Both of those exist because it was measured, on a PR earlier today.** Refreshing #463's body by hand
published an **empty body**: `gh pr view --jq '.body'` returns a string *array*, so `.IndexOf()` gave an
array index and `.Substring()` member-enumerated — the same PowerShell trap repaired in `ship-pr` that
morning, hit again in a throwaway script. The body was rebuilt and restored, and the rule that came out of
it is the one now in the code: **a body edit may never remove text without putting text back.**
