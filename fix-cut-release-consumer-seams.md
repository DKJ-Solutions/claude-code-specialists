### cut-release stops resolving consumer-side facts by source-repo paths · Fix · 2026-08-05

Tier: 2

Four inbound findings from the first repo to cut a release on the shared `cut-release.ps1`
([#464](https://github.com/DaveKJohn/claude-code-specialists/issues/464),
[#461](https://github.com/DaveKJohn/claude-code-specialists/issues/461),
[#460](https://github.com/DaveKJohn/claude-code-specialists/issues/460),
[#462](https://github.com/DaveKJohn/claude-code-specialists/issues/462)), and they are one defect wearing
four faces: **the shared release route answered consumer-side questions by looking at paths that only exist
in the source repo.** Sharing the script in #417 moved the code and left three of its lookups behind.

**Each reported reason was checked against the code before anything was repaired**, per this repo's own
rule. All four held — unusually, since the class of report that names a line number and a mechanism is
exactly the class that turns out to have diagnosed the symptom correctly and the cause not. Here the
diagnoses were right, so the repairs are the ones the issues proposed.

**The lint gate was the consequential one, because it removed a gate rather than a prompt.** The cut
resolved it as `$PSScriptRoot/../lint/check-plugin-integrity.ps1` — this repo's own script, by a path a
consumer's plugin cache does not have. So every consumer release ran with **no lint gate at all**, and said
so in a `WARNING` that nothing required anyone to act on. It now reads `Get-LintScript`, the same seam
`open-pr` has always used for this question, so both routes run the same repo's gate. **And a named gate
that is not on disk is now a hard stop**: a gate that switches itself off on a condition the operator did
not choose is not a gate, and `-SkipLint` is how you choose it — in the command, where the choice is
recorded, rather than in output that scrolls past. The reporting repo had learned this at first hand: two
dead links once reached its `main` through the release route, which is the one route that never meets the
PR gate, and adopting the shared script silently took its replacement away again.

**The internal note's prompt was invisible in exactly the repos that need it.** The line naming the third
tier is gated on the note's script existing — deliberately, because whether a repo has that tier is a fact
its file tree answers rather than a preference. The gate probed the **consumer's repo root**, which by
design holds no copy. So the reasoning held in the source and inverted everywhere else, and the one tier
written at *every* release, patch included, was the one tier nothing mentioned. The fact is still read off a
file tree; it is now read off the tree that can answer it — the repo's own copy first, then the sibling that
travels with the script. **The printed path is the resolved one**, so the line is a command rather than a
description of one.

**The skill's first command was dead in a consumer**, which is the same defect one file over: the checklist
opened with `./scripts/release/cut-release.ps1`, a real file in the repo the script is *maintained* in and
nothing at all in the repo you are cutting a release for. It now uses the `${CLAUDE_PLUGIN_ROOT}` form the
other shared skills already use, with the caveat stated rather than implied — that variable resolves only
inside a plugin-owned component, so running it by hand means spelling out the cache path.

**And the changelog's release block finally has a wording seam**, the fourth knob of a class this repo had
already solved three times (the entry stubs, the category labels, the internal note). `Get-ChangelogReleaseWording`
overrides `LatestIntro`, `AllIntro`, `NotesLine` and `InternalNoteLine`, merged over the English defaults.
Values carry `{history}`, `{notes}`, `{internal}`, `{dev}` and `{emdash}` as **tokens**, because an override
is written in a config file that has none of those values in scope. The block is the most visible output a
release produces — it sits at the top of the file — and it was the last one still written in the script's
language instead of the repo's.

**The defaults are unchanged, byte for byte, and that is the seam's contract rather than caution.** It
includes `AllIntro` still saying *"the marketplace"*, which is the wrong noun for a consumer that is not
one: the script contract's `[INFO]` line names that default, so it is a thing you are told rather than one
you meet at release time. Verified by the release-lib suite passing all 316 asserts untouched.

**One repair inside the repair, found by reading the code rather than the report.**
`Set-ReleaseInternalNoteLink` located the line to rewrite by anchoring on `^See \[` — the English default's
opening words. With the wording configurable that becomes a silent failure of exactly the kind the
function's own header warns about: the cut succeeds, the note is written, and the link simply never moves.
It now finds the line **by its shape** — inside a release block the notes line is the only line carrying a
markdown link, which is true in every language — so the seam cannot break the function that reads what the
seam wrote.

**Contract and tests moved with the behaviour, not after it.** `Get-LintScript` is now attributed to two
callers, `Get-ChangelogReleaseWording` is declared as a twenty-sixth record, and the four asserts that went
red were the pinned counts and attributions doing their job: they were updated with the reason, never
loosened. All suites green.
