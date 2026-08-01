### The heading gate covers the level the lens actually warned about · Fix · 2026-08-01

Found by cutting the release again with `-NoPush` and reading the generated notes. The separators were
right and the categories were finally right — `## Features` (1), `## Fixes` (5), `## Documentation` (7) — and
**two `##` headings from PR #321's entry body were sitting among them**, as if they were release categories
of their own.

**That is v2.13.2's defect verbatim, and it is the case Rendall's lens actually documents:** *"a body's
`## On the tests` and `## Filed separately` came out looking like two extra release categories next to
`## Fixes`."* The gate I built one PR ago covered `###` — the level I had just tripped over — and not `##`.
**A gate that covers the instance you met and not the one the documentation warned about is half a gate**,
and the very next release cut demonstrated it.

Check 13 now rejects any heading at or above the entry's own level (`#`, `##`, `###`) in an entry body, and
any `#`/`##` inside the Pull Requests section, with the message naming which level it found and what that
level does — an H3 becomes a separate entry, an H1/H2 climbs out of its category. `####` and deeper stay
free, which is what an entry body should use.

**One bug in the widened check, caught by its own fixture.** The section scan originally ended at *the next
H2*. A stray H2 **is** an H2 — so the scan ended at exactly the defect it was looking for, and everything
after it passed silently. The first run reported neither of #321's two. It now ends at `## Releases`
specifically, and the fixture proves the difference the only way that is not brittle: a second defect placed
**after** the stray H2, which can only be reported if the scan kept going. Asserting on the error total would
have been the easy version and would have passed either way, since the fixture carries its own expected
noise.

The two headings in `CHANGELOG.md` are demoted to `####`. Same words, two levels down. Done with a UTF-8
read this time rather than `Get-Content` — and the mojibake gate from the previous PR confirmed it: 44
separators before, 44 after, 0 damaged.

#### Tested

Four asserts added to `check-plugin-integrity.tests.ps1` scenario 34: the H2 inside Pull Requests reported
with its line, the message naming the consequence, **a defect after the stray H2 still reported** (the
scan-boundary trap), and an H2 in an entry file caught on the PR where the author can still fix it. The
`## Releases` boundary assert from the previous PR still passes, so widening the levels did not start firing
on every `### vX.Y.Z` heading a released repo carries.

Plugins: specialists
