## `docs/releases-readme-portability` changelog

### Branch title

The portable half of releases/README.md survives mirroring

### Branch ID

20260813-132037

### Branch type

docs

### What does the change on this branch bring to main?

The claim at the heart of `releases/README.md` — *"everything above this line travels to any repo that
runs this release workflow"* — is now literally true. Inbound
[#643](https://github.com/DaveKJohn/claude-code-specialists/issues/643) measured it by performing the
first verbatim mirror (life-hub) and found three classes of content above the rule that did not travel;
all three are repaired at the source, so a mirror needs none of the manual repairs that mirror had to
invent.

The plugin lockstep is stated conditionally, matching what `cut-release.ps1` already does: where
`Get-ReleasePluginTier` is true the cut bumps every `plugin.json` in lockstep, otherwise the version
lives in the newest `vX.Y.Z` tag — the intro, the *Cutting a release* opener and step 1 all now describe
both branches of the seam instead of presenting the source's branch as the definition of a release. The
retired per-plugin-files step keeps one portable sentence; its source-only measurement (ten files,
11,684 lines, lint checks 9 and 17) moved below the rule to *Measured instances*.

A new **reading rule** in the intro defines the two conventions that make verbatim copying safe: *this
repo* above the rule always names the source repo, whose measurements travel as evidence rather than as
the mirror's own record; and links into the source's script tree are **absolute** on purpose. The five
relative links that were dead on arrival in a consumer (`cut-release.ps1` twice, the cut-release
`SKILL.md` twice, `release-lib.ps1`, `release-lib.tests.ps1`, `entry-scaffold-lib.ps1`) are absolutised;
the links every adopting repo can serve itself (`CHANGELOG.md`, `CONTRIBUTING.md`,
`scripts/repo-config.ps1`) deliberately stay relative. The one anchor that crossed the rule downward —
portable text linking `#measured-instances-behind-the-portable-rules` — now points at the same
measurement where it already lives above the rule, so a mirror is no longer silently required to
reproduce a heading the mirroring instruction tells it to replace.

Below the rule, the seam-values section now opens with the two answers a mirror needs first —
`Get-ReleasePluginTier` (true here, with what false means) and `Get-ReleaseAudienceTier` (2 here, with
what 1 means) — and the mirroring instruction names the two things a mirror must *not* repair: the
absolute links and the source's measurements.

### Significance

#### Tier 0

This repo's own reading of the page is unchanged — the absolute links still resolve here, and the moved
measurement is one section further down.

**Score:** 1

#### Tier 2

The first repo that mirrored this page needed three undocumented manual repairs, one of which — a
missing "read *this repo* as the source" rule — left its own release documentation instructing readers to
bump plugin files that repo has never had. A consumer copying the portable half verbatim now gets a page
that is true in their tree on arrival, and life-hub's bridging note shrinks to a pointer after the sync.

**Score:** 3

### Pull Request

