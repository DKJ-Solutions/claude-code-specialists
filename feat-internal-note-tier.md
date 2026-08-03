### The internal tier: a release summary for colleagues and employers · Feat · 2026-08-03

**The third tier, and the one that covers a patch.** `new-internal-note.ps1` is ported from the consumer
repo as a **shared** script and writes `releases/internal/<X>.x/<X.Y.Z>.md` — for colleagues, employers
and management, at **every** release including a patch. That last part is the whole reason it exists next
to highlights: the two answer different questions. Highlights is *what a consumer notices*; internal is
*what the organisation gets out of it*. They come apart most clearly on a patch — a release with nothing
for a consumer, correctly a patch and therefore without highlights, can still be the one where a routine
change stopped needing a developer.

**It generates only half, deliberately.** Version, date, type and the entry titles come from the
development notes; *"what it is worth"* cannot be derived from a changelog. So the output is a **skeleton**:
the metadata, the titles as `[type]`-prefixed bullets, and three fixed headings. The headings are fixed on
purpose — without that boundary this tier grows back into the developer notes it was created to avoid.

**Its own script rather than part of `cut-release`, and the reason changed on the way.** The source repo
kept it separate because `cut-release.ps1` was marked "temporarily diverged" and must not be extended —
which #417 settled, so that reason is gone. What holds instead is better: `cut-release` **commits and
tags in one motion**, so a skeleton generated there would put an empty document inside the release tag
while the written version landed afterwards anyway. Separate keeps the release commit what it is —
purely generated artefacts — while the one document that is human-written end to end travels the normal
reviewed route.

**So both hand-written documents ship via a branch + PR**, and that is now stated in `CLAUDE.md`, Rendall's
lens, `releases/README.md` and the skill rather than left to be worked out: the edited highlights draft and
the filled-in internal note are both written *after* the cut, when the release commit is already tagged, and
neither is one of the two named direct-on-`main` exceptions.

**`cut-release` now names what it did not write.** At the end of a run it prints the highlights draft still
needing an edit and the `new-internal-note.ps1` invocation — **gated on that script existing**, not on a
config knob, because whether a repo has an internal tier is a fact its file tree already answers. Same
reasoning as `Get-ReleasePluginTier`'s computed fallback. Printed on the `-NoPush` path too, where it is
most useful.

**English script, repo-owned document.** Console output and errors are English like every shared script
here, but the eleven strings that land *in the file* come from the optional `Get-InternalNoteWording` —
the #410 class, third time in `repo-config.ps1`. Merged over the English defaults, so a consumer
translating three headings does not silently lose the fill-in hints. Contract: 22 records → 23.

**Verified against real data, not only fixtures:** run against this repo's own `v3.2.0` notes it read all
21 entries, copied the date and type, and stripped every PR number and date from the titles. That probe
skeleton was then removed — the script belongs in this PR, the *written* note for v3.2.0 is content for a
separate one.

**Tests: a new suite, `internal-note.tests.ps1`, 52 asserts**, weighted toward the refusals rather than the
happy path — an existing note is the one document of the three that cannot be regenerated from anything, so
`-Force` being required is asserted by writing text into a note and checking it survives. Also: the folder
scheme really follows `Get-ReleaseNotesGrouping` (per-minor lands in `3.2/` and *not* in `3.x/`), only H3
headings count (an H4 inside an entry body does not become a bullet), missing metadata becomes a visible
`(fill in)` plus a warning rather than a blank line, and every document string is overridable while an
unmentioned key keeps its default.

**Two PowerShell traps hit while writing that suite, both now comments in it.** `$args` inside a function
is an *automatic* variable holding the caller's arguments, so assigning to it and splatting passes
something else entirely — it made a correct refusal look like exit 0. And `[string]$Param = $null` coerces
to `''`, so a fixture could not tell "no notes file" from "an empty notes file" and wrote an empty one,
which made the same refusal look broken while the script was right. Both were measured by running the
script by hand rather than reasoned about.
