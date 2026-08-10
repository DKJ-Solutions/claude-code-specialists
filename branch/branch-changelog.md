## `docs/a-record-is-cited-where-it-lives` changelog

### Branch title

Documentation cites the contract records in the file they actually live in

### Branch ID

20260810-205505

### Branch type

docs

### What does the change on this branch bring to main?

Two documents still sent a reader to `check-script-contract.ps1` to find a contract record. The records
moved out of that file into `scripts/lib/script-contract-lib.ps1` on August 8, 2026 (issue #456), when
three readers each needed a different half of the registry — so both pointers had been wrong for two
days, and one of them ships.

- **`README.md`** cited "the record in `check-script-contract.ps1`, which states the retirement of its
  own 'out of scope' note". The sentence makes **two** claims and the extraction split them across two
  files: the `Get-ReleasePluginTier` record is in `script-contract-lib.ps1`, while the retirement note
  really did stay in the check. Swapping the filename would have repaired one half and broken the
  other, so the sentence now names both homes and says which file used to hold them together.
- **`cut-release/SKILL.md`** said `Get-LiveStage` is "declared in `check-script-contract.ps1` as an
  **Optional** record". This is the one that matters: the skill travels to consumers in the plugin, so
  a consumer looking up the record opened a file that has not contained one since #456.

**No gate could have caught either, and for two different reasons worth keeping straight.** The README
citation was a real markdown link, so check 4 passed it correctly — the file exists; what was wrong was
the claim about what is inside it, and no link checker reads claims. The SKILL.md citation was a path in
inline code, which is exactly the territory this repo measured and declined on August 9, 2026: five
candidate rules over 120 documents, the narrowest giving 124 findings of which not one was true, because
most paths a plugin source names correctly describe somebody else's repo. Both defects were found by
reading, which is what that declined measurement said would have to happen.

Plugins: workflow-davekjohn

### Significance

#### Tier 0

A developer here who follows the README to find the record opens a file that has not held one since
August 8. Small, and it costs one redirect.

**Score:** 1

#### Tier 1

The same for a colleague on this project, and it is the second half of the README sentence that makes
it worth stating: a reader who noticed the record was missing from the check would reasonably conclude
the retirement note was misfiled too, when that half was right all along.

**Score:** 1

#### Tier 2

The `cut-release` skill ships in the plugin, so a consumer configuring `Get-LiveStage` was sent to a
file that does not declare it — with no error to correct them, since the file is real and does discuss
the seam.

**Score:** 2

### Pull Request

