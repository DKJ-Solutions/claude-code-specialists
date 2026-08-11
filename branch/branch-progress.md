## `feat/lock-and-continue` progress

### Steps

- [x] Settle the design with Dave: three steps, the lock as a decision and the repo as the authority,
      and the name (`/lock` over `hold`/`propose`/`pin`, with the reasoning recorded in the entry)
- [x] `scripts/task/session-status.ps1` — the reporter: lock first, then the repo blocks; reads only;
      no lib dependencies; every optional source degrades to a stated line
- [x] Fix the BOM-less UTF-8 read found on the first run (`-Encoding UTF8` on every markdown read)
- [x] Both skill pages, with "the lock is recorded intent, not a refusal" written in as load-bearing
- [x] Register: the shared-scripts registry (+ `StoreOverride` exempt), the mirror, both `skills:all`
      spans in README.md, `.gitignore` for `.claude/handover.md`
- [x] `scripts/tests/session-status.tests.ps1` — 24 asserts on the printed OUTPUT, including the
      mojibake regression, the lock-before-repo ordering, the parked-branch positive path against a
      bare origin, and the writes-nothing contract
- [x] Lint 0 errors, script contract 0 errors, all suites green
- [~] Wiring the two commands into Chris's close-out ritual so `/lock` is offered automatically —
      dropped from this branch on purpose. That edits a portable persona and changes how every
      consumer's orchestrator behaves; it belongs in its own branch with Dave's word, not smuggled in
      behind a tooling change.

### Where I left off

Done — the chain is at the PR step.
