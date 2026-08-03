### Repair the stale marketplace name in generated intros · Fix · 2026-08-03

Found while verifying the post-restart state after the rename series (#403–#406) closed: the rename
swept `davekjohns-workshop` out of 59 files, and all four **per-plugin `CHANGELOG.md` files still
opened by naming it** — in a sentence describing the present mechanism, in the most consumer-facing
file each plugin has.

**The reason, verified in the code rather than inferred from the symptom.** `Add-PluginChangelogSection`
emits the intro only when the file does not exist yet (`if (-not $Existing)`), so every later release
appends *below* it and never revisits it. Editing the template reaches future plugins and no current
one — the template had in fact already been corrected, and the correction could not arrive. Every
existing gate looked past it for a defensible reason: checks 11 and 12 exclude per-plugin CHANGELOGs as
history, and they are right about the entries. **The intro is the one part of those files that is not
history**, and no rule covered it.

**Repaired as a class, not as four strings:**

- **`Build-PluginChangelogIntro` extracted** as the single source of that header, with the marketplace
  name a **parameter** rather than a literal — a copy of the name is exactly what went stale. Its
  authority is `name` in `.claude-plugin/marketplace.json`, read through the new pure
  `Get-MarketplaceName`, which throws on a missing *or blank* name instead of yielding a plausible
  `()` in a published file.
- **Check 17 in the lint gate** holds every `plugins/<plugin>/CHANGELOG.md` intro against that
  function, deriving the expected text from the same manifest field `cut-release.ps1` writes — so the
  two agree by construction instead of by upkeep. There is deliberately **no expected value written
  down in the gate**: a literal there would be another copy of the string whose copies are the bug.
  Compared whitespace-normalized, so it judges content and never becomes a wrapping police over a file
  no human should be rewrapping. Everything below the first `## vX.Y.Z` heading is left alone — that
  half *is* history.
- **The six stale statements themselves**: the four plugin intros, `CHANGELOG.md`'s own opening line,
  and the handbook's outlier note in `.claude/specialists/README.md`, which additionally still called
  the plugins "the first product family" — the framing the
  [one-product rule](README.md#one-product-one-repository) retired the same day.

**Five test scenarios (33–37), and one of them is the design rather than a bug guard.** #37 renames the
marketplace in the fixture manifest and *nothing else*, and the same file must flip from failing to
passing: without that case the check could carry a hardcoded copy of the name and all four other
scenarios would still pass — precisely the shape of the defect it exists to catch. #36 locks in that a
CHANGELOG with no version heading is *reported* rather than silently skipped, since a check that quietly
asserts nothing is the failure mode this gate is here to prevent. #35's own first failure is recorded in
its comment: the fixture retyped the em-dash title as a plain hyphen, making a content difference
masquerade as the layout difference the case was meant to prove.

**The general rule, written into `release-lib.ps1` for the next template added there:** ask whether the
string is rewritten on every release. A section, a reference line, a fully regenerated card all reach
their file again and self-heal; anything written once needs a gate rather than a good intention. The
library's own header claimed "only FUTURE output from these templates changed" — true of every template
in it except this one, and that single exception cost four consumer-facing files.

**Also closed a smaller drift found on the way:** the gate's `.SYNOPSIS` indexed checks 1–12 while the
script ran 17. Checks 13–16 (entry-heading, encoding, unbound output samples, measured figures) were
documented at their definitions but absent from the index a reader consults first, so all five are now
listed rather than only the new one.

**Deliberately not done, and it is a decision rather than an omission.** "Workshop" survives as internal
shorthand for this repo in 278 places across 58 files — including the parameter name
`-WorkshopPathOverride` (a live contract between `connector-sessioncheck.ps1` and
`check-connectors.ps1`, mirrored into the plugin) and the test helper `New-StubWorkshop`. Retiring the
*word* is a vocabulary migration needing a chosen replacement term; retiring the stale *statements* is a
defect repair. Only the second is in this branch. Dave's call, August 3, 2026.
