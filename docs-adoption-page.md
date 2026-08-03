### QUICKSTART becomes ADOPTION.md, with a real quickstart beside it · Docs · 2026-08-03

Closes inbound [#408](https://github.com/DaveKJohn/claude-code-specialists/issues/408),
[#402](https://github.com/DaveKJohn/claude-code-specialists/issues/402) and
[#401](https://github.com/DaveKJohn/claude-code-specialists/issues/401) — three findings from the same
adoption round, all on the same page, and one of them restructures it, so they travel together.

**The page is renamed, and the name was the defect (#408).** `QUICKSTART.md` is a thorough,
measurement-backed adoption manual; "quickstart" set an expectation it never tried to meet, and the
consumer who had just adopted through it said so in as many words. It is now `ADOPTION.md`, and it
states its own reading time at the top — ~44 minutes at 200 wpm, plus ~27 for `specialists-init`'s
`SKILL.md`, measured August 3, 2026 and framed as an order of magnitude because both pages grow. That
is the one number a first-time reader would plan with, on a page meticulous about every other count.
The short page comes out at ~4 minutes, so the split is a factor of eleven rather than the "roughly
twenty lines" the issue estimated.

**`QUICKSTART.md` still exists, and now the name is true**: a commands-only page — the two settings
keys, the four commands, the verification query, the two restarts — that links out to `ADOPTION.md`
for every caveat. Keeping the filename is also what keeps ~19 inbound links alive, including the
`#staying-up-to-date` anchor cited from archived release notes and the per-plugin CHANGELOGs, which
are history and are not rewritten. Both pages carry that anchor; living docs point at the detailed
one.

**Three steps became four.** Filling the lenses was always part of the procedure and was disclosed in
a trailing clause reading *"then, at your own pace"*, after the page had framed itself as complete.
That is how an owner came to attribute half an hour of *authoring* to the *installer* —
`specialists-init` places the whole seam in seconds. It is Step 4 now, with its cost stated and with
the two things that reliably surface while doing it (a `.gitignore` that swallows the seam, a
`repo-config.ps1` behind the script contract) named as things to plan for rather than diagnose. Per
#297's lesson the count moved on all three pages in one change — here, in the README, and in the
skill.

**Where a delegated adoption has to stop (#402).** The page addressed the agent-reader once, about
*reading* it. It now also addresses *executing* it: a table splitting the procedure by who can perform
each act. Of Step 1's six acts an agent can do four; the two restarts it structurally cannot, because
it runs inside the session it would restart, and Steps 2–3 follow from that. Named with it: what the
agent hands back, and why the state it stops in is the one this page devotes a blockquote to as
reading healthy from every angle — three correct records, right sha, payload present, and an inert
session.

**The third machine state (#401).** *Before you start* knew a virgin profile and a machine satisfied
long ago. It did not know the one that is the *expected* condition of any second adoption: a leftover
**user-scope** marketplace registration, because `UNINSTALL.md` Step 5 is the removal no command
performs. In that state the restart act and its `marketplace add` alternative are silently
unnecessary, #329's failure message never appears — so its absence proves nothing — and, the sharper
half, the repo's own `extraKnownMarketplaces` key is never exercised at all. A mistyped slug then
survives every check on the page. Act 3 gains the one-line close: after the refresh, `claude plugin
marketplace list`, and confirm the entry came from your repo's settings.

**Two allowlists needed the new file, and both are the same class of bug this repo has now hit three
times.** `cut-release.ps1`'s `$reservedRootMd` treats every unlisted root `*.md` as an unfolded
changelog entry, so without `ADOPTION.md` the next release would have refused to cut, complaining
about a document nobody failed to fold (#165, then #405, now this). And the lint gate's
`$consumerDocs` — the set checks 15 and 16 examine for unbound samples and unbound measured figures —
listed `QUICKSTART.md`; the page carrying almost all of those samples had just been renamed out from
under it, which would have left both checks reporting green over their own subject. The comment above
that list warned about exactly this arriving.

`release-lib.ps1` now generates the `RELEASE.md` card's "the version is not the code" link against
`ADOPTION.md`; the four committed cards were brought in line by hand so the next generation is a
no-op, and the test asserting that URL moved with it.

**To do / where I left off:** done — lint gate and all 23 test suites green.
