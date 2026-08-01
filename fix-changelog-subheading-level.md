### A sub-heading in an entry body cannot be an entry itself · Fix · 2026-08-01

Found while checking `CHANGELOG.md` before cutting a release, and it is my own defect, four times in one
day. Four entry bodies used `### Tested` (and one `### What the reviews changed…`) as a sub-heading. **The
entry's own heading is an H3**, so after the fold those became siblings: the `## Pull Requests` section
carried four headings with no PR number.

**That is not cosmetic.** `release-lib.ps1`'s `Read-Changelog` splits entries on **every** unfenced `###`
line — so `cut-release.ps1` would have emitted four extra "entries" with no number, no type and no
`Plugins:` line, grouped under whatever category happened to come last. The release would have shipped them.

**Rendall's lens already warned about this**, in the `##` form: *"Seen in v2.13.2, where a body's `## On the
tests` and `## Filed separately` came out looking like two extra release categories next to `## Fixes`."*
The warning was there, it was specific, and it did not stop me — which is the whole argument for a gate
rather than a sharper sentence. The rule is exactly checkable, so nobody should have to remember it.

**Check 13 catches it at both moments, and the two are not redundant:**

- **The root entry files** — where the author can still fix it on the PR. An entry file holds exactly one
  H3: its own heading, on the first line.
- **`CHANGELOG.md`'s `## Pull Requests` section** — what `cut-release.ps1` actually parses. This half also
  catches damage that arrives through the **fold**, which is one of the two writes that happen directly on
  `main`, past every PR gate. That is the #234 lesson one section over: an error introduced by the fold used
  to surface only at the next `cut-release`, which then refused to release.

Fence-aware in both halves, via the same `Get-FenceMaskedText` the other checks use: an entry that *quotes*
a heading line inside a code fence is discussing structure, not creating it — the mention-versus-use question
this file has now answered five times. And scoped to the Pull Requests section, because `## Releases`
legitimately holds `### vX.Y.Z` headings; without that boundary the check would fire on every repo that has
ever released.

**Verified in both directions rather than assumed from a green run.** The defect was reintroduced on purpose
and the gate named it with its line number and its consequence; then removed, and the gate went quiet. Same
for the entry-file half. Nine asserts in `check-plugin-integrity.tests.ps1` scenario 34 pin it: the accepted
`####` form, the rejected form with its line, the fenced example that must stay silent, the CHANGELOG half in
both directions, and the `## Releases` boundary.

The four headings are demoted to `####`. No content changed — the same words, one level down.

Plugins: specialists
