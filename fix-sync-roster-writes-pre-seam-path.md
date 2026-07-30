### sync-roster wrote its scaffolds to the pre-seam path · Fix · 2026-07-30

The seam ([#221](https://github.com/DaveKJohn/davekjohns-workshop/issues/221)) made
`.claude/specialists/lenses/` the place a consumer's lenses live, and taught the bootstrap to resolve
that destination through `Get-LensWriteDir` — the seam for a fresh or migrated consumer, the existing
tree for one that has not migrated. **`sync-roster` never got the same treatment.** It hardcoded
`.claude/plugins/<family>/<plugin>/<group>-<id>-extension.md` in three places: the scaffold it writes,
the link in the roster row it proposes, and the path it prints for a stale header.

**What that costs a real consumer.** Run `sync-roster` after a plugin update — which is exactly what the
session hook tells you to do when the roster drifts — and a migrated repo gets its new scaffolds in the
pre-seam directory while the rest of its lenses sit in the seam. `Get-LensWriteDir`'s own docstring names
that outcome: *"splitting the surface in two, which is worse than either layout alone."* On top of that
`check-roster-sync` then reports the fresh scaffolds as off-path, and the proposed roster row a human
pastes links to a file that is not there — worse than no row, because it looks authoritative.

Both writers now resolve through the one helper, so they cannot disagree about a repo's layout.

**Why the suite stayed green through all of it, which is the more useful half of this entry.** Every one
of the six existing scenarios built its fixture consumer with a **pre-seam lens tree** — and
`Get-LensWriteDir` follows an existing tree by design. So the suite exercised the one branch where the
hardcoded literal happened to be correct, 39 asserts deep, and never the fresh or migrated cases. **A
fixture that always arrives in the same state tests one branch, however many asserts hang off it.** The
suite now builds three: fresh (no tree), migrated (lenses in the seam), and pre-seam (lenses on the old
path), plus a fourth check that the proposed roster row's link follows too. Verified by running the new
asserts against the unfixed script: **7 fail, and the pre-seam case passes both ways** — which is the
proof that the test targets the defect rather than the implementation.

`Get-LensFamily` is no longer called anywhere in this script: with the seam there is no family segment
left for it to compose.

**On the unparseable-plugin case.** The stale-header branch used to print `<plugin>` as a placeholder
segment. In the seam there is no plugin segment to placeholder, so an unknown plugin now resolves to the
seam — and deliberately does *not* pass the placeholder on to `Get-LensWriteDir`, whose candidate list
documents that the caller slug-validates any name that becomes a path segment (a `<plugin>` literal would
break that contract, and `Test-Path` on the illegal characters with it). Everywhere the id *did* parse it
is passed through, still slug-validated by `Split-PluginId`.

The `SKILL.md` line describing where scaffolds land was deliberately held back from
[#261](https://github.com/DaveKJohn/davekjohns-workshop/pull/261)'s prose sweep and lands here instead:
the doc follows the behaviour, never the other way round.
