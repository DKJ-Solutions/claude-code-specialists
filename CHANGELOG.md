# Changelog

Everything merged since the last release, **newest first**: **one `##` per change**, and under it two
named `###` sections. The `##` heading is the change's own — `` DEPLOY: `<branch>` `` and the moment it
landed — and the text directly beneath it answers what a reader arrives with: what the change deploys to
`main`. Then `### What makes this PR extra special` for the second audience, and `### Pull Request`.
The tier numbers live in the parser rather than in any heading. That second heading said `deploy` rather
than `PR` for one day, August 23 to 24, 2026, and `change` for the four days before that; every wording it
has ever carried is still read, so an entry below written under any of them is parsed exactly as it always
was. Entries written before August 23, 2026
carry that first answer under a `###` question of its own with the second nested at `####` beneath it;
entries before August 16 carry the longer set of headings that shape replaced, and every earlier shape is
read exactly as it always was. Every release ever cut is listed in
[`releases/README.md`](releases/README.md) — each with its date, type and title, and a link to what that
release was worth. How the mechanism works (entry files, the Significance sections, folding) is described in
[`workflow-davekjohn/CONTRIBUTING.md`](workflow-davekjohn/CONTRIBUTING.md).

Each change declares its own **reach**, and per audience how much it **weighs** there — one `#### Tier N`
sub-section per tier, each closing with its score. This list does not order on it: it is a record of what
landed, so it reads in the order things landed. What the declaration decides is what the **release
documents** lead with — they rank themselves on it — and what may be released at all, because **the bump
follows the highest tier pending**: **tier 0 only earns a patch**, **tier 1 or higher earns a minor**, and
a **major** recaps ten minors. So a changelog holding nothing but tier 0 is a patch waiting to be cut, not
a release with nobody to announce it to.

---
