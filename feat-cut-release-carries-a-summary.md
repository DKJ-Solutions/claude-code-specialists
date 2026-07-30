### A milestone release can carry an authored summary · Feat · 2026-07-30

Groundwork for a **3.0.0 milestone** whose notes are a summary of everything between 2.2.0 and 2.16.0
(Dave's request, July 30, 2026) — 26 releases. The release machinery could not express that, and finding
out *why* is the useful part.

**`cut-release.ps1` generates its notes from the pending `## Pull Requests` entries, and nothing else.**
`Build-ReleaseNotes` is header + `-Title` + the entries grouped by category. `-Title` is exactly one
sentence; the entries are per-PR. So an ordinary release's notes answer *"what changed since the last
one"* — the right question for an ordinary release, and the wrong one for a milestone, whose whole point
is the arc across many. The only route left was to cut normally and hand-edit the generated file
afterwards, which is not a repeatable release and is the reason this script exists at all.

`-SummaryFile <path>` now places an authored markdown block between the title line and the generated
entries, closed off with a horizontal rule.

**Three decisions in it, each of which could reasonably have gone the other way:**

- **A file path, not a string.** A multi-page summary does not survive a command line.
- **The file may live outside the repo, and normally will.** Its canonical home *becomes* the generated
  notes file, so keeping a second copy under `releases/` purely to feed the parameter would be exactly the
  duplication this repo removes elsewhere. A scratch path is the expected case.
- **The rule separating it from the entries is not decoration.** Without a visible boundary an authored
  summary reads as though it were generated, which is the one thing it must not be mistaken for.

**And one deliberate non-symmetry with the entries, asserted by test.** An entry's root-relative links
*are* rewritten (`../../../`), because an entry was authored in the root `CHANGELOG.md` and then moved
three folders deeper. A summary is authored **for** the notes file, so its links are already relative to
where they will sit — rewriting them would break the ones that were right. Same input shape, opposite
correct treatment, and it is only obvious once the reason is written down.

Opt-in throughout: a test asserts that a call without `-Summary` is **byte-identical** to the output
before the parameter existed. A missing or empty `-SummaryFile` is a hard stop rather than a silent
fallback — an empty file would otherwise produce an ordinary release while the operator believes they cut
a milestone, which is the failure this parameter would be blamed for.

**Recorded next to it in [Rendall's lens](.claude/specialists/lenses/05-06-extension.md), because it is a
judgment call and not a flag:** a `major` bump reads as *breaking* to anyone applying semver
mechanically, and a milestone in this repo may break nothing at all — the seam, the largest change in
2.x, is backward compatible by construction, since every reader accepts the old layouts. When nothing
breaks, the summary's opening lines have to say so, or a consumer sits on an old version waiting for a
migration that does not exist.

**The cut itself waits.** The 3.0.0 release is deliberately not part of this branch: it comes after the
first real adoption round-trip in `life-hub`, because a milestone whose central claim is *"adoption is
reversible"* should not be published before that claim has been tested outside a fixture.
