### QUICKSTART entry path: prerequisites, the settings fragment, and the first command · Docs · 2026-08-01

The first four findings of test round v10 (#340), all of them on the stretch a consumer walks *before*
the adoption path begins. v10 was the first round run on a **virgin Windows user profile**, which is why
none of this was findable earlier: on an occupied machine every prerequisite below was satisfied years
ago.

- **A `Before you start` section, which the QUICKSTART did not have** (#334). Claude Code installed and
  `claude` actually running (pointing at Anthropic's own [setup
  documentation](https://code.claude.com/docs/en/setup) rather than an install command that would go
  stale here), signed in, and on Windows raising the execution policy — a fresh profile defaults to
  `Restricted`, which blocks every `.ps1` **including `claude.ps1` itself** on an npm install, so this
  page's own first command failed with a `PSSecurityException`. The `PATH`/full-restart symptom is
  recorded as context rather than as a defect, because it is partly an artefact of the install route that
  measurement took.
- **The first executable command was a dead end, and now it is not** (#329). The marketplace is
  registered by a **session start**, not by writing `extraKnownMarketplaces` — measured in three states,
  and the CLI's own error (`Marketplace 'davekjohns-workshop' not found. Available marketplaces:
  claude-plugins-official`) reads as a typo rather than as a missing step. Step 1 now restarts first, with
  `claude plugin marketplace add <source> --scope project` as the no-restart alternative. That command
  gets its own caveats because it breaks the page's pattern twice: it takes a **source** where everything
  else uses the marketplace *name*, and it defaults to `--scope user` — which would rebuild #279 in a
  fourth command. Its `--scope project` is flagged as **documented rather than measured** (from the CLI
  `--help`; #329's measurement was taken at the default scope).
- **Step 1's fragment now parses when pasted, and `.claude` no longer means two things silently**
  (#335). The `jsonc` block with a comment and no outer braces is a complete `json` file, with the
  merge case named for readers who already have a `settings.json`. The repo-level `.claude/` is
  identified as a directory to **create**, and a blockquote separates it from the machine-level
  `~/.claude/` the verification query reads — one consumer read the former as something still to be
  *installed*.
- **Reaching the documents at all** (#338). A pointer to the Quickstart and UNINSTALL.md at the **top**
  of the root README, where a reader handed only the repository stands, instead of two-thirds down under
  `## Consumption`. The `specialists-teardown` skill now names its own missing half: the machine side of
  leaving lives in `UNINSTALL.md`, which ships in the marketplace clone and not in the payload, and was
  reached in the measurement **only by grepping blindly**. And a warning that an agent pointed at this
  page may not read it: `WebFetch` refused a verbatim request and then returned a summary that
  understated the document's size and **invented an enumeration for Step 2** that the page does not
  contain.

**The act count moved from five to six, in all three places at once.** Adding the registering restart made
the `enable → refresh → install → restart → verify` line wrong — the exact cross-document count that #297
and #305 exist to keep aligned, asserted in the QUICKSTART, the family README and `specialists-init`'s
step 0. It is now `enable → restart → refresh → install → restart → verify` in all three, with
`specialists-init`'s letters absorbing it (`0a` is two acts). Folding the restart into act 1 would have
kept the number at five and was rejected deliberately: being folded into another act is what kept this
step unwritten while it was already required. Verified with the emphasis-tolerant sweep #305 prescribes —
the remaining `five steps` hits all belong to the **migration** path (steps 0–4), a different procedure.

**One correction pulled in from outside this branch's four issues.** The bold claim *"Those keys do not
install anything, though"* sits in the exact paragraph #329 rewrites, and #327 falsifies it: on a virgin
profile with the marketplace registered, a single session start wrote a full project-scoped install
record, indistinguishable from the one the documented command produces. Leaving a measured-false sentence
standing inside a paragraph being rewritten was not defensible, so it is corrected here — stating what was
measured, that the session doing the writing still loads nothing itself, and that whether this makes Step
1's two commands redundant is **untested end to end**. That last question needs one round on a fresh
profile and stays open.
