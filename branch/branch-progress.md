## `feat/scaffold-without-comments` progress

### Branch description

The scaffolded branch files carry no guidance comments

### Branch ID

20260807-103608

### Branch type

feat

### Steps

- [x] One `-Template` switch decides guidance + the `(template)` marker together; only `Get-BranchTemplates` passes it
- [x] The routing questions go with the guidance -- Dave chose that over keeping them, shown both shapes
- [x] Both templates verify byte-identical, so the reference is untouched by this
- [x] Moved the two routing-question asserts onto the template rendering, and added the mirror assert
- [ ] Docs still to follow: branch/README.md, CONTRIBUTING.md, CLAUDE.md, the new-branch skill
- [ ] Dave is making his own adjustments first -- no PR until he says so

### Where I left off

Code is done and green: entry-scaffold 259 asserts, new-branch 98, lint 0 errors, mirrors rebuilt.
Committed locally, nothing pushed.

**Paused on Dave's word** -- he wants to adjust something himself before this goes anywhere. The docs
were deliberately left for after that, since his edits may change what they have to say.

Worth knowing when picking this back up: the templates were verified byte-identical AFTER the change,
which is what proves the guidance only moved rather than being rewritten.
