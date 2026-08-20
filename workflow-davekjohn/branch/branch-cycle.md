# `feat/shopify-live-theme-guard` cycle · 20260820-044616

## PLAN

- [x] Read the reference implementation the reporter offered, and its 30 cases, rather than the
      description of it
- [x] Verify #769's own comparison before porting: is the first consumer's match really "blunt"?
- [x] Decide what has to become a seam, since the original hardcoded one store's answers

## CREATE

- [x] `hooks/guard-live-theme.ps1` -- ported, with the two hardcoded values behind optional seam
      functions and every message made repo-neutral
- [x] `hooks/shopify-floor-sessioncheck.ps1` -- the half-armed state is the one thing it reports
- [x] `hooks/hooks.json` -- `PreToolUse` on `Bash|PowerShell` (both, because the wrapper gap is the
      whole reason this exists) plus the session check
- [x] `README.md` for the plugin: the floor, the two seam answers, and the matching rule with its limits
- [x] `plugin.json` says it ships a floor now, since that description is what a consumer reads
- [~] The `.theme-check.yml` starter and the CI workflow -- deliberately a separate branch: #769 itself
      calls them conveniences, and mixing them with a security control makes one review of two things

## TEST

- [x] `scripts/tests/guard-live-theme.tests.ps1`: 51 asserts, 0 failed
- [x] Groups 1-3 ported: the real commands blocked including through a wrapper, the two real-world false
      positives allowed, and a counter-case for each of the three exemptions
- [x] Group 4 is new and is the part with no field history: no config still blocks publish/delete and
      `--allow-live`, the id half is asserted OPEN without an id, a configured id closes it, both
      consumers' existing markers are accepted by the default, and configuring a marker NARROWS
- [x] A broken `repo-config.ps1` still blocks a publish -- it fails towards checking, not open
- [x] An unparseable hook payload likewise
- [x] `check-plugin-integrity.ps1` green

## DEPLOY

## Where I left off

Done, and one correction to the report is worth keeping.

#769 said the first consumer's guard "has the blunt match ... it will hit the same wall". It does not: it
matches `shopify\s+theme\s+publish` with a comment saying why. The conclusion survives in sharper form --
a prefix check does not save you from documentation that quotes the FULL command, which is the case that
was actually measured. Their guard has one of the two defences.

What I did not take is the second half of #769: the `.theme-check.yml` starter and the CI workflow. Its own
text calls those conveniences while calling the guard the one with real stakes, and reviewing a security
control together with two scaffolds makes one review of two unrelated things. Next branch.
