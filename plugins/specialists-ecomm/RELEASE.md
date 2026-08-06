# Release v3.6.0

**Date:** 2026-08-06  
**Type:** Minor

The changelog ranks itself by reach and weight, a branch keeps its plan in branch/, and a filled lens survives the teardown

This card describes v3.6.0, the version your plugin manifest carries. Whether it is the code you are running is a separate question: the documented update path installs from `main`, so a `main` that has moved past the tag reports this same number. [The version is not the code](https://github.com/DaveKJohn/claude-code-specialists/blob/main/plugins/INSTALL.md#staying-up-to-date) in INSTALL.md is the check.

## The three consumer-facing documents become plugins/INSTALL.md and plugins/UNINSTALL.md

### What does this change do?

The repo root goes from eight markdown files to five. `UNINSTALL.md` moved to `plugins/` unchanged;
`ADOPTION.md` and `QUICKSTART.md` moved there too and were then **merged into one `INSTALL.md`**, with
the short commands-only page as its first half and the full adoption manual as its second. Everything
that pointed at any of the three moved with them, in both directions: the `README.md` entry table and
its eight other pointers, `connectors/README.md`, Sylvester #15's lens, `specialists-init/SKILL.md`,
and the pages' own outbound links, which now sit a level deeper and reach the root through `../`.

**Two halves in one file needed more than a rename.** Three headings existed twice after the merge, so
`#staying-up-to-date` — the anchor every external link uses — had become ambiguous and resolved to the
two-command summary instead of the measured section. The short half's headings were renamed rather than
the long half's, because every inbound link means the long one. The self-referencing prose went with
it: the quickstart half no longer tells the reader to open a page that is now the text below it, and
the note explaining the #408 rename now explains why the split was undone as well. It was not reversed
— what #408 asked for was that a reader can tell a one-hour manual from a command list before
committing to it, and two named halves do that while removing the failure mode a split invites, where
one page is updated and the other quietly disagrees.

**The absolute URLs moved too, and those are the half a consumer feels.** `release-lib.ps1` bakes
`…/blob/main/…#staying-up-to-date` into every generated `RELEASE.md` card, and that card ships in the
plugin cache. The generator, all four committed cards, `specialists-teardown/SKILL.md` and
`UNINSTALL.md`'s own "on GitHub" pointer now name `plugins/INSTALL.md`. Cards already delivered for
v3.5.0 and earlier keep the old URL and will 404 — that cost is real, it cannot be recalled, and it is
named here rather than left to be discovered.

**Seven links in published release documents were rewritten**, in `releases/development/2.x/2.7.1.md`,
`3.0.3`, `3.0.6`, `3.1.0` and `releases/highlights/3.x/3.2.0.md`, `3.3.0.md`. That is deliberately
unlike the seven wrong dates left standing on August 5, 2026: a date is a claim about what was true
then and stays true unedited, while a relative link is a pointer to where a file is *now* and is simply
wrong once the file moves. Repairing it changes no statement the document makes.

**And the move exposed a gate that had gone quiet, which is the part worth keeping.** The dead-link scan
gathers every root `*.md` by glob — a rule written precisely because a named list goes stale — but reaches
into `plugins/` only for `CHANGELOG.md`, `SKILL.md`, manuals and personas. A document sitting directly in
`plugins/` matched no rule at all, so all three went dark the moment they landed there: their own outbound
links unvalidated, and the run still reporting clean. `plugins/` now gets the same non-recursive glob the
root has. The same staleness hit `$consumerDocs`, the root-relative list checks 15 and 16 read, which
`Test-Path`-skips a missing entry in silence. Both are repaired, and the coverage line is the proof:
link-scan 159 → 162, lifecycle 11 → 18, record-query 1 → 5, expected-output 1 → 5, measured-figure 0 → 11.
Five checks were examining less than they reported, and nothing said so.

**Also corrected because the merge invalidated it:** the reading-time figure in `INSTALL.md`, remeasured
at ~9,800 words (~49 min) against `specialists-init`'s ~5,600 (~28 min), and the same figure where
`README.md` quotes it. The `measured-figure` check passed it either way — it holds a figure to naming
what binds it, not to being right — which is exactly why a merge has to remeasure by hand.

**The skip is a finding now, not a `continue`.** Both readers of `$consumerDocs` opened their file with
`if (-not (Test-Path)) { continue }`, so a stale entry cost coverage and said nothing — which is precisely
how the drop above went unnoticed. A named document that is not there is now `[consumer-doc]`, validated
once before the two loops so one cause does not read as two findings.

**And that check found something older and worse.** Adding it produced
`the collection is of a fixed size` and a run that died mid-scan. The cause was not the new check:
`Add-Error` appends to a `List[string]`, and sixteen other places did `$errors += "..."`, which on a
`List` does not append — it rebuilds the whole thing as a fixed-size `Object[]` and rebinds `$errors` to
it. **Every** `Add-Error` after the first `+=` would have thrown. It never fired because the ordering hid
it: all existing `Add-Error` callers sit above the first `+=`, so the array only came into being after
the last one. The first check added below that line hit it immediately. All sixteen now go through
`Add-Error`, and scenario 43 in the test suite is the canary — check 19 sits below every former `+=`
site, so if the style returns, that scenario stops reporting a finding and starts reporting an exception.

Worth stating plainly, because it is the uncomfortable half: this defect was reachable by any future
check written at the bottom of that file, and the gate that guards this repo would have died rather than
reported. It was found by accident, while adding two lines for something else.

### Type of change

Docs

[PR #482](https://github.com/DaveKJohn/claude-code-specialists/pull/482) · merged 2026-08-06

---

Full workshop notes: [releases/development/3.x/3.6.0.md](https://github.com/DaveKJohn/claude-code-specialists/blob/main/releases/development/3.x/3.6.0.md)
Cumulative plugin history: [CHANGELOG.md](CHANGELOG.md)
