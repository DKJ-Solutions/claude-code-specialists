## `feat/shopify-live-theme-guard` deployment

### What does the change on this branch deploy to main?

`team-shopify` gains an operational floor: a `PreToolUse` guard that refuses a theme **publish**, a theme
**delete**, or an unauthorised **push aimed at the live theme** — whatever shell wraps the command. It is
this plugin's first hook, and its first executable of any kind: until now the payload was three agent defs,
three manuals and one skill page, all of it instruction text.

**Prose was the whole enforcement, and prose does not stop a command.** Two things make a written rule
insufficient here rather than merely weak. A **permission deny list matches a command prefix**, so a rule
forbidding the CLI never sees the same command wrapped in `powershell -Command "…"` — and a settings file
that allows both leaves the exact forbidden command reachable by wrapping it, which is the default state of
a repo rather than a misconfiguration. And it **was built twice**: both Shopify consumers wrote this guard
independently before it shipped here, which is the definition of something belonging in the plugin.

**Rules 1 and 2 have no escape hatch at all** and need no configuration: publishing makes a theme the
customer-facing one and a delete cannot be undone, so both stay the owner's own keystroke. Rule 3 is
authorised per command by a marker written as a shell comment — a marker rather than an environment
variable, because the hook runs as its own process and would not inherit an inline prefix; a variable would
have to be set session-wide, which is exactly the state that makes a stray push dangerous.

**Two optional seam values, and the absent case is reported rather than left silent.**
`Get-ShopifyLiveThemeId` is what lets the guard recognise a push aimed at live *by id*; without it
`--allow-live` still blocks and that push passes. A guard that is installed reads as protection, so that
half-armed state is the one thing the accompanying `SessionStart` check speaks about — naming the function
to add and, deliberately, which rules **do** still hold, so it cannot read as "unprotected".
`Get-ShopifyLivePushMarker` defaults to accepting any marker **ending in** `LIVE-PUSH-AUTHORIZED`, which is
what both existing consumers already write (`SWB-…`, `XOXO-…`); setting it narrows to one spelling.
Recognise both, write one.

**Nothing changes in this repo**: it enables `team-alpha` and `workflow-davekjohn` only, so the hook is
payload here rather than something that runs.

**Score:** 4

#### What makes this change extra special

Both Shopify consumers serve real customers from a live theme, and Shopify provides no lock. So the failure
this prevents is a single stray command against revenue — which has not happened, and the reason it is
worth 4 rather than 1 is that the route to it was **open by default** in every repo enabling this team,
through the wrapper gap that permissions structurally cannot see.

There is also something to do on receipt, which is why this is not merely a gift: a consumer who does not
answer `Get-ShopifyLiveThemeId` carries a standing `[ERROR]` at session start until they do, and the two
consumers who already wrote their own guard now have two — theirs is redundant, and both of their markers
are accepted by the shipped default, so removing the local copy breaks nothing.

**The transferable half is the matching, not the rule.** The reporting consumer's first version matched the
forbidden words anywhere in the command string, and on day one it blocked the heredoc that wrote the rule
into their own `CLAUDE.md` and the `perl` line that later edited that sentence. Neither would have touched
the store. A guard that makes its own rule impossible to write down is one somebody eventually switches
off, which is worse than no guard — so this asks *where* the words sit rather than whether they occur:
heredoc bodies stripped unless an interpreter reads them, text-tool segments skipped unless the command
pipes into a shell or uses `eval`/`xargs`, everything else matched per segment. **Each of those three
exemptions has a counter-case in the suite**, because an exemption without one is a hole with a comment on
it.

**Score:** 4

### Pull Request

the Shopify team ships the live-theme guard
