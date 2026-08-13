## `fix/audience-tier-strings` changelog

### Branch title

The visible tier strings state the post-#620 audience definition

### Branch ID

20260813-124219

### Branch type

fix

### What does the change on this branch bring to main?

Every string a human reads when answering the tier question now states the post-#620 audience
definition — tier 1 is management and the employer/commissioner, tier 2 is the subscriber of a
service — where all of them still carried the pre-#620 ladder ("a colleague working on this project" /
"a consumer of the product notices it"). Inbound
[#640](https://github.com/DaveKJohn/claude-code-specialists/issues/640) measured that the two
definitions produce opposite answers for the same repo: a webshop's customers are literally "consumers
of the product", so the old wording sent the one worked example the new model is built on to tier 2
instead of tier 1 — and one consumer (life-hub) had already answered its `Get-ReleaseAudienceTier`
knob wrong from these strings, declaring tier 2 structurally N/A and cutting every release as a patch.

Repaired, verified against the tree before building: the routing questions and UNCOMMENT openers in
`entry-scaffold-lib.ps1` (`Route0`/`Route1`/`Uncomment1`/`Uncomment2`), the refused-entry tier table in
`open-pr.ps1`, the tier tables in `new-branch/SKILL.md` and `CONTRIBUTING-portable.md`, and four
sites the issue did not name: the tier tables in `branch/README.md` and `open-pr/SKILL.md`, and the
two gate-refusal messages in `cut-release.ps1` (the tier gate and the significance gate) — found by
the verification sweep and the pre-PR reviews. Two source comments that still stated the cumulative
model as current (`release-lib.ps1`, `new-internal-note.ps1`) now mark it as the pre-#620 reading. Both doc tables now also carry the
webshop worked example, since that is the case that separates the two kinds of audience. The
contradiction inside `entry-scaffold-lib.ps1` — the cumulative ladder at one comment block and the
one-audience model thirty lines below it — is resolved: the ladder block now marks itself as the
superseded half and points at the block that wins. The retired route questions joined
`EntrySignificanceRetiredRoutes` so in-flight entries scaffolded with the old wording keep being
filtered from the `Why` sections everywhere — recognise both, write one. `branch/templates/` is
regenerated from the new wording, and both scripts' plugin mirrors travel byte-for-byte.

Deliberately left standing: `Get-ReleaseTierHeading`'s `Tier 1 - colleagues` heading in the
development notes. It does not feed the audience decision, it is machine-parsed by the internal-note
generator, and every existing development note carries it — renaming it is a separate decision, not
part of this defect.

### Significance

#### Tier 0

Source readers of `entry-scaffold-lib.ps1` no longer meet two contradicting tier definitions thirty
lines apart, with only the wrong half getting printed.

**Score:** 2

#### Tier 2

The strings a consumer reads when answering the `Get-ReleaseAudienceTier` knob — the new-branch table,
the scaffolded template comments, the refused-entry printout — gave the inverted answer, and the knob
is `Adopt = 'decide'`, so every repo taking the update is asked to answer it from exactly these
strings. One consumer already answered wrong and had its release cadence silently degraded to
patches; after this, the visible definition and the model agree.

**Score:** 4

### Pull Request

