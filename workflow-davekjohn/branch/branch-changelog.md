## Branch `feat/entry-format-two-sections` changelog · 20260819-142147

### What does the change on this branch deploy to main?

The changelog entry's tier declarations stop naming themselves. `#### Tier 0` is gone -- the question the
entry opens with IS that section now -- and `#### Higher than tier 0?` reads
`#### What makes this change extra special`, at the same level, inside it. The question itself says
`deploy to main?` where it said `bring to main?`, and the creation stamp is separated from the title by a
middle dot instead of a hyphen. So an entry is still two `###` sections, and no heading names a tier number:
the numbers resolve on read, from `Get-ReleaseAudienceTier`, exactly as the retired heading already did.

Whoever fills one in is answering two questions rather than classifying two readers, which is the point --
and the guidance under the second one now names the repo's own audience in words
(`For tier 2 audiences: the subscriber of a service.`), assembled per repo rather than stored, so a tier-1
repo is not told about subscribers it does not have. That sentence replaces a trailing space left behind when
the previous wording was cut on August 16.

**Seven shapes are read and one is written.** The current nested pair, the `###`-levelled pair this branch
tried on the way to it, the `#### Tier 0` + `#### Higher than tier 0?` pair, the fully numbered
sub-headings, the impact table and the `Tier: N` line all still parse -- which is what keeps the entries
already in `CHANGELOG.md` and in every consumer's tree folding. The discriminator for tier 0's unheaded form
is the **score label** under the question, and it is load-bearing: every entry ever written carries that
heading, so matching it without the guard would have made hundreds of table-shaped and line-shaped entries
read as an unscored tier 0 and emptied every release document built from them. All seven verified before the
gates ran.

**Score:** 4

#### What makes this change extra special

The format arrives through a plugin update rather than by choosing to, so every consumer's next branch is
scaffolded in the new shape and their `branch/templates/` is rewritten to match. Nothing they have already
written has to be migrated, and nothing about their release documents changes. The half they gain is the
guidance naming their own reader: a repo whose audience is tier 1 now reads
`For tier 1 audiences: management and the employer/commissioner.` where the form previously either named a
tier that was only right for a tier-2 repo or trailed off after a space.

**A repo that has stated no audience tier sees no change to its tier headings at all** -- it keeps the
numbered sub-sections and the routing comments between them, because a heading with no tier to resolve to
would read as tier 0 and empty its release documents. That is the same conservative direction the audience
knob has carried since August 12, 2026, and it is deliberate rather than incidental: absent means unchanged.

**Score:** 4

### Pull Request

The entry's tier sections become the two questions it asks
