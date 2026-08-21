## `fix/cut-release-baseline-crosscheck` deployment

### What does the change on this branch deploy to main?

`cut-release.ps1` read the version it bumps **from** out of the plugin manifests, or failing those out
of the highest `v*` git tag — and never held that number against the release overview it is about to
write a row into. Neither of those is the document that says which release is which, and where one
disagrees the cut still succeeds: the number can be right while the bump **type** is wrong in four
places at once and in silence. The `**Type:**` line in the generated notes, the `Type` cell of the
overview row, the question `Test-ReleaseBumpEarned` answers, and whether the hand-written consumer
document is drafted at all.

Three changes, one guardrail and two diagnostics:

- **[`scripts/lib/release-lib.ps1`](scripts/lib/release-lib.ps1)** gains `Get-OverviewLatestVersion`:
  the release the overview records as newest. It walks on to the next table where the first is empty,
  because that is exactly the state a freshly opened major section is in — the highest-stakes cut there
  is, and the one a first-table-only reader would leave unguarded.
- **[`scripts/release/cut-release.ps1`](scripts/release/cut-release.ps1)** refuses on a disagreement,
  naming both numbers and where each came from, with the other guardrails and before the first write.
  `-Type <major|minor|patch>` is the way through, deliberately **not** a `-Skip` switch: a bypass would
  hand back the very label the check caught, while stating the type produces a correct release. And the
  `-NoPush` path now closes with `($current -> $new, $typeLabel)` — the flag whose whole purpose is
  reading a release before it is public was the one path that hid the number every label hangs on.
- **[the `cut-release` skill](plugins/workflows/workflow-davekjohn/skills/cut-release/SKILL.md)**
  documents `-Type`, and repairs a claim that had gone stale in the other direction: it said
  `release-lib.ps1` was deliberately **not** mirrored into the plugin, while the reporting consumer read
  `Get-BumpType` at line 136 of its own install cache. A page that talks a reader out of looking where
  the answer is costs more than one that says nothing.

**It refuses on both routes in, which goes further than inbound
[#802](https://github.com/DaveKJohn/claude-code-specialists/issues/802) asked for** — it proposed
refusing only where `-Version` was passed. `-Bump` is the worse of the two, not the safer one: with
`-Version` the author has named the number and only its label is wrong, while `-Bump` computes the
number **from** the baseline, so a wrong baseline produces a version belonging to a different release
altogether. The reporting consumer met exactly that and was saved by an unrelated refusal downstream,
which is luck rather than a guard.

**Score:** 4

#### What makes this change extra special

`cut-release.ps1` is mirrored into `workflow-davekjohn`, so every consumer cuts its releases with this
script — and **one stray tag is enough** to trigger the whole failure. `--sort=-v:refname` takes the
highest `v*` tag in the repo, so a single mistyped `v99.0.0`, a per-component tag in a monorepo, or
imported history relabels every later release as a Major, silently, with no policy decision by anyone.
Two of the four consequences are the ones a consumer cannot see: a guardrail evaluating a bump type
that is not being cut, and a document appearing (or failing to appear) for the wrong reader.

The reporting consumer had to correct a cut by hand afterwards — delete an audience document that
should never have been drafted, change `Minor` to `Patch` in two files, and repoint an overview cell
whose link would otherwise have failed their own lint gate on a dead link.

**Score:** 4

### Pull Request

cut-release cross-checks its bump baseline against the release overview
