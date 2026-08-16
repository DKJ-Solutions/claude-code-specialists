## Branch `docs/entry-shape-repair` changelog - 20260816-224048

### What does the change on this branch bring to main?

#### Tier 0

The `docs/destination-reach` entry folded into `CHANGELOG.md` with five paragraphs of description sitting
**between** `### What does the change on this branch bring to main?` and its first `#### Tier 0`. That is
not the entry shape: the description begins **at tier 0**, because the tier is what the description is
answering (Dave, August 16, 2026, catching it minutes after the fold). The prose moves inside the tier 0
section, where it belongs; nothing is lost and no claim changes meaning.

**The scaffold was right and was overruled by hand, which is the part worth recording.**
`branch/templates/branch_template_changelog.md` writes `#### Tier 0` directly under the heading with no
prose slot between them, and the three sibling entries pending in `CHANGELOG.md` all follow it. The
malformed entry was written past a correct template rather than misled by one -- so this is a discipline
repair, not a tooling one, and no script or gate is changed here.

**Two stale claims in the shipped prose are corrected in the same pass**, both of them wording already
fixed in the files the entry describes but not in the entry itself: *"two destinations look correct and
are unreachable"* (the second failure resolves to the wrong root rather than failing to arrive), and
*"two candidate destinations were rejected"* (three were rejected there; two of them on reach).
`CHANGELOG.md` is pending rather than published, so correcting it restores the record instead of
rewriting one -- the published-record rule protects `releases/audience/`, which this has not reached.

**And a real drift was found in the portable page that documents this shape, deliberately NOT repaired
here.** `BRANCH-portable.md` still calls the entry's first section `Branch title` and still refers to a
`### Significance` wrapper; the current template has neither -- the title now sits under
`### Pull Request` and the tier sections sit directly under the question heading. Filed as an observation
rather than swept into a repair branch: it is portable payload reaching every consumer, several distinct
claims are affected, and rewriting a contributor page is its own scoped job.

**Score:** 2

#### Tier 2

N/A -- `CHANGELOG.md` is this repo's own pending record and is not plugin payload, so nothing here
reaches a consumer. The entry being repaired describes a change that does reach one, but that change
already landed and is not touched.

**Score:** N/A

### Pull Request

The destination-reach entry's description moves inside its tier 0 section
