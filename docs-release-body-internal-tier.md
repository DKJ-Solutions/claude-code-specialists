### The internal note becomes the release body, at every release · Docs · 2026-08-04

**Two decisions by Dave, August 4, 2026, with separate reasons — so they are recorded separately.** A
GitHub Release is now published at **every** release, patch included (until now a patch skipped the step
entirely, tag only), and its **body is the internal note**, with the highlights and the development notes
attached. Dave's reasoning for the second: highlights only exist at a minor or major, while the internal
note exists at every release, so it is the only tier that can be the body under a rule with no exceptions.
It is also the tier written as *what the work is worth*, which is what a public Release page is read as.

**The objection was raised before the decision and is recorded as a known trade-off, not as an open
question.** The internal tier deliberately carries no file names, no commands and no code. On `v3.2.0`
— where the marketplace rename breaks every existing install *with no error message* — that means the
migration steps sit in the attached highlights rather than on the page a consumer lands on. Dave chose the
internal note anyway, so the rule now carries its own mitigation: when a release requires action, the body
says so and points at the attachment. Applied immediately to `v3.2.0`'s note rather than left as advice.

**The step had to move, and that is a correction rather than a preference.** The GitHub Release was step 2
of the checklist, directly after the tag — which worked only because its body was the highlights file
`cut-release.ps1` had already generated. The internal note is written *after* the cut and merged via a
branch + PR, so publishing from step 2 would publish a body that does not exist yet. It is step 5 now,
after the documents merge. A checklist that exists to impose itself has to be walked in an order that is
possible.

**The portable/repo split was measured before it was written, and it landed differently than expected.**
The skill travels to consumers, so "the body is the internal note" may only be unconditional if every
consumer has one. It does not: `cut-release.ps1` gates the internal tier on **the script existing in the
repo tree**, not on a config knob (its own comment says why — a repo's file tree already answers that
question). So the checklist now carries a three-row table — internal note, else highlights, else the
development notes — and *which bumps get a Release* moved out of the portable page entirely into the
release manager's repo lens, on the same reasoning that made `Get-PrMergeMethod` repo policy: a repo
publishing at every release and one publishing at Minor/Major only are both coherent, and the choice
follows from who reads the page. No new script machinery was needed for either half.

**One consequence worth knowing: the internal note stopped being an archive document.** Being the body
makes it published output, so a stale line in it now ships. `v3.2.0`'s note listed "the user-facing version
still needs an editorial pass" under *what is still open* — true when filed, untrue since the highlights
were edited hours later. Corrected here. The general lesson is the tier's, not this release's: the
development notes and the highlights are written once and left alone, and the internal note now has to be
re-read whenever what it calls open has closed.

Also updated: `releases/README.md` (both the summary and the full mechanics, where the two patch examples
cited for years now describe the old rule and are left standing as history), the root `README.md`, and both
places in Rendall's lens.
