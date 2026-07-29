### Two plugins both setting agent: settled by experiment · Docs · 2026-07-29

The open question from [#215](https://github.com/DaveKJohn/davekjohns-workshop/issues/215) — *what
happens when two enabled plugins both set `agent` in their root `settings.json`* — is no longer an
unknown. It was the **first** of the three reasons the main-thread switch stays off, and the one the
family README called "the honest prerequisite… by experiment rather than by reading". So it was
measured rather than reasoned about.

**The answer: the last-listed plugin silently wins.** Two throwaway plugins, each with an `agent` in
its root `settings.json` pointing at its own agent, run in both orders along **both** load paths:

| Path | Order | Winner | Main model |
|---|---|---|---|
| `--plugin-dir A --plugin-dir B` | alpha, beta | `IDENTITY=BETA` | haiku |
| `--plugin-dir B --plugin-dir A` | beta, alpha | `IDENTITY=ALPHA` | sonnet-5 |
| `enabledPlugins` | alpha, beta | `IDENTITY=BETA` | haiku |
| `enabledPlugins` | beta, alpha | `IDENTITY=ALPHA` | sonnet-5 |

Three things follow, and the second is the one that matters for the switch:

- **The whole agent config travels, not just the system prompt.** The winner's `model` came through
  too — the two experiment agents were deliberately given different models, so the JSON `modelUsage`
  proves which one won independently of what the model *said* about itself.
- **There is no error and no warning.** The harness knows and logs it exactly once, at debug level:
  `[DEBUG] Plugin "expbeta" overrides setting "agent" (previously set by another plugin)`. That is
  worse than a hard failure: a consumer who enables a second `agent`-setting plugin loses their
  orchestrator to whichever plugin sits last, with nothing on screen to say so.
- **Ordering is positional, not alphabetical.** Reversing the order reverses the winner, which rules
  out the obvious alternative explanation (`expalpha` < `expbeta`).

Recorded in the family README, in the *"Delivering the orchestrator from the plugin"* section, as a
measured fact replacing the "not documented" wording. **The switch stays off** — reasons 2 (it changes
every consumer's main loop from a version bump they did not read) and 3 (Chris ships as a persona, so
there is no agent file whose `tools:`/`model` may become the whole main thread's) are untouched by
this, and flipping it is Dave's call regardless.

**Two things the method is worth more than the result for.**

- **The control run came first, deliberately.** One plugin alone was run before the pair, because a
  null result from a misconfigured harness is indistinguishable from a real "neither wins". It
  answered `IDENTITY=ALPHA` on alpha's own model, so the mechanism was proven live before anything was
  concluded from its absence.
- **That precaution immediately paid for itself.** The first attempt at the consumer path answered as
  plain Claude Code — no identity at all. Not a finding: `extraKnownMarketplaces` had
  `"source": "local"`, which is invalid (the valid type is `"directory"`), and `-p` mode *silently
  ignores* settings files that fail validation. `claude doctor` named the offending key exactly. A
  project-declared marketplace also needs an install step before `enabledPlugins` bites — headless,
  the plugins were simply never loaded. Both were fixed and the run redone before any conclusion.

**One side effect worth knowing before anyone repeats this:** `claude plugin marketplace remove`
rewrites the **project** `settings.json` of the current working directory, not just the scope the
marketplace was declared in — it emptied the test consumer's `enabledPlugins` and
`extraKnownMarketplaces`. Run it from a throwaway directory, never from a repo whose `settings.json`
you want to keep. The experiment's own cleanup was done that way; this repo's `.claude/settings.json`
and Dave's user settings are verified unchanged.

**Also in this change:** the `gh pr checks --watch` pitfall is now recorded in
[Derek #05](.claude/specialists/lenses/05-05-extension.md#merging-to-main)'s lens rather than living
only in one session's memory. Chaining the watch onto a merge looks safe and is not: with no run
started yet the watch returns immediately with `no checks reported` — a success-looking exit meaning
"I found nothing" — so the chained merge fires against an unevaluated gate, gets blocked by the `main`
ruleset, and leaves an unmerged PR behind while every step appeared to pass. The note also flags that
PowerShell 5.1 has no `&&`, so such a chain is `;` or `if ($?) { … }` here, which runs the merge
regardless of what the watch concluded.
