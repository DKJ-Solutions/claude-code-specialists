## `fix/shared-sentinel-points-nowhere` progress

### Steps

- [x] Verify C2 still stands, and check the two remedies it proposes before building either --
      both declined, with the reason recorded rather than only the choice
- [x] Measure the alternative rather than argue it: repointing adds 178 personal-repo references
      (against C4 on the same report), removing saves 4,305 bytes
- [x] `Format-SharedBeginSentinel` as the one source of the wording
- [x] `Expand-AgentDefShared` rebuilds the BEGIN line instead of copying it -- success path only, the
      two failure branches still leave their region untouched
- [x] Regenerate all 30 carriers (26 agent defs + 4 personas)
- [x] Tests: the fixture asks the lib for the sentinel, the retired wording is rewritten, an invented
      wording is normalized too, and the indent survives
- [x] Record the reasoning in `agent-shared/README.md`, beside the rule it belongs to
- [x] Lint gate green
- [x] All test suites green

### Where I left off

C2 done. Remaining from #669 in Dave's order (E stays open): C1 (every agent looks for a lens that is
not there -- 30 of the 53 pointers come from one shared block, 23 are per-file opening lines), then
C4's hygiene half. **C4's first half is with Dave**: `Shopmonkey MAIN` and live theme id `170064871700`
sit in two shipped team-shopify agent defs in a public repo. Not a credential, but identifiable
client data -- his call, and it is not blocking anything else.

