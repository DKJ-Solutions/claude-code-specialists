## `fix/agent-content-boundaries` progress

### Steps

- [x] Verify both inbound items still stand against the tree, before building anything
- [x] #667: drop `Bash` from Sandra's `tools`, and move her description with it
- [x] #667: rewrite the working method — no `shopify theme list`, prepare from the repo side instead
- [x] #667: replace the paragraph that documented the instruction+`settings.json` construction
- [x] #667: separate the two representations in her manual, so the subagent is not left with a
      pre-push checklist it cannot run
- [x] #668: write `plugins/agent-shared/filecontent-boundary.md`, answering the "you fetched this"
      difference the web block leans on
- [x] #668: settle the scope question the issue left open — all 26 agent defs, personas excluded —
      and record the reasoning in `agent-shared/README.md` rather than only in the entry
- [x] #668: insert the sentinels into all 26 defs and run `build-agent-defs.ps1`
- [x] Lint gate green (`check-plugin-integrity.ps1`, 0 errors)
- [x] All test suites green
- [~] Give Sandra a gated replacement for `shopify theme list` — dropped: no gate exists that a
      subagent could hold (a `Skill` cannot grant `Bash`), and the persona already owns the call.
      Building one would be a new mechanism, not part of closing #667.

### Where I left off

Golf 1 of the seven-issue plan is complete. Still open, in the agreed order: golf 2 is the two
decisions that are Dave's — #669 §E (a Cowork-native package beside `team-alpha`?) and #660 (the
Projects board, which also needs `gh auth refresh -s read:project`). The decision note for those two
is the next deliverable after this merges.
