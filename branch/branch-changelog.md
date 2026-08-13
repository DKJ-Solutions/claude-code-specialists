## `feat/releases-portable` changelog

### Branch title

The release workflow's portable half ships with the plugin as RELEASES-portable.md

### Branch ID

20260813-142153

### Branch type

feat

### What does the change on this branch bring to main?

The release workflow's process documentation now travels with the plugin instead of being hand-copied.
Inbound [#646](https://github.com/DaveKJohn/claude-code-specialists/issues/646) measured the cost of the
old shape: two consumers, on the same day, each hand-copied the 4,154-word portable half of
`releases/README.md` verbatim because that was the only way to stop it drifting — one of them after its
page had become a Dutch translation in which three claims had gone stale unnoticed. A hand-maintained
mirror is correct on the day it is made and manual forever; a plugin file stays current through updates.

`plugins/workflows/workflow-davekjohn/RELEASES-portable.md` is the half that used to live above the
horizontal rule, following the `CONTRIBUTING-portable.md` precedent (#566): the tier model, what a
release must earn, the release documents, and how one is cut, with the seam named wherever a repo owns
the answer. Its reading rule survives the move — *this repo* names the source, links into the source's
script tree stay absolute — and the files every adopting repo has of its own are named in code rather
than linked, since a relative link from the plugin directory is dead on arrival. The sentence #646
caught as non-portable (the `CHANGELOG.md` release block "points here") is now stated in terms of
`Get-ReleaseHistoryPath` rather than as a claim about the reader's own file.

`releases/README.md` keeps what only this repo can own — the seam values, the local decisions, the
measured instances, and the release list the row inserter writes into — and opens with a pointer to the
portable page, exactly like `CONTRIBUTING.md`. The mirroring instruction is rewritten for the new
shape: a consumer's page holds only its own half, and one that still carries a hand-copied process half
should delete it, because the plugin's page is the same text with a maintainer. The six inbound anchor
references (in `CONTRIBUTING.md`, `README.md` and Rendall's lens) are repointed at the portable file.

### Significance

#### Tier 0

This repo reads the same text one directory over; the release list, the inserter's table and the
guardrail's heading rule are untouched.

**Score:** 2

#### Tier 2

The two consumers maintaining verbatim mirrors can delete 4,154 hand-copied words each and replace them
with a pointer; every future correction to the release process reaches them through a plugin update
instead of through a manual re-copy that historically did not happen — the measured Dutch mirror carried
a claim a dry run had already refuted.

**Score:** 4

### Pull Request

