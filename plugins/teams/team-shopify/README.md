# `team-shopify` — the Shopify add-on team

Three specialists for a Shopify store repo, two skills, and an **operational floor**: the part that is
not advice.

| what | who / where |
|---|---|
| **Liam** 💧 `04-20` | Liquid Developer — features and fixes in the theme code, plus `assets/` and `locales/` |
| **Sandra** 🛍️ `05-21` | Store Manager — read-only admin reconnaissance and the pre-push checklist |
| **Steven** 🗂️ `05-22` | Configuration Manager — theme estate, cleanup policy, CLI and auth reference |
| `start-task` | the skill that opens a task: a branch plus its matching unpublished preview theme |
| `adopt-shopify-floor` | the skill that **places** the floor in your repo: the guard's seam, a starter `.theme-check.yml`, and the CI workflow over it |
| `hooks/guard-live-theme.ps1` | **the floor** — a `PreToolUse` guard on the live theme |
| `hooks/shopify-floor-sessioncheck.ps1` | says when that guard is only half armed, and when a second one is registered beside it |

Teams stack: this one adds to `team-alpha`, and a commercial store typically enables `team-ecomm` beside
it. Which store a repo *is* belongs to that repo's lenses, never to this plugin.

## The floor: why a guard and not a rule

This team exists because a live theme serves real money and Shopify has no locking. The manuals state
that in prose, in three places — and **prose does not stop a command**. Two things make a written rule
insufficient here rather than merely weak:

- **A permission deny list matches a command prefix.** A rule that forbids the CLI never sees the same
  command wrapped in a shell invocation, and a settings file that allows both the CLI and a
  `powershell -Command "…"` wrapper leaves the exact forbidden command reachable by wrapping it. That is
  the default state of a repo, not a misconfiguration.
- **It was built twice.** Two consumers of this plugin independently wrote this same guard before it
  shipped here (inbound [#769](https://github.com/DaveKJohn/claude-code-specialists/issues/769)), and the
  second had to learn the false-positive lesson below from scratch while the first still carries it.

### What it refuses

| | rule | needs configuration? |
|---|---|---|
| 1 | a theme **publish** — always | no |
| 2 | a theme **delete** — always | no |
| 3 | a theme **push** aimed at live — unless authorised | the id half does |

Rules 1 and 2 have **no escape hatch at all**, and that is deliberate: publishing makes a theme the
customer-facing one and a delete cannot be undone, so both stay the store owner's own keystroke rather
than something a marker in a command line can stand in for.

**Untouched:** every form of `theme pull`, including `--live` — reading is how a pre-task sync works —
pushes to an unpublished preview theme, and every other command.

### Authorising the deliberate live push

Add the marker to that exact command, as a shell comment:

```bash
shopify theme push --store yours.myshopify.com --theme <live id> --only assets/x.css --allow-live # LIVE-PUSH-AUTHORIZED
```

It is a comment in both shells, so it changes nothing about what runs. **A marker rather than an
environment variable**, because the hook runs as its own process and would not inherit an inline env
prefix — a variable would have to be set session-wide, which is exactly the state that makes a stray push
dangerous. A marker authorises **one** command, visibly, in the transcript.

## What your repo has to answer

Two optional functions in your own `scripts/repo-config.ps1` — the file `specialists-init` already
scaffolds:

```powershell
function Get-ShopifyLiveThemeId    { return '190793613653' }   # shopify theme list names it
function Get-ShopifyLivePushMarker { return 'SWB-LIVE-PUSH-AUTHORIZED' }
```

| function | absent — or answered non-numerically, which counts as the same thing |
|---|---|
| `Get-ShopifyLiveThemeId` | the **id half of rule 3 cannot fire**: `--allow-live` still blocks, and a push aimed at live *by id* passes. A real hole, so the session check reports it once per session rather than leaving it silent. |
| `Get-ShopifyLivePushMarker` | any marker **ending in** `LIVE-PUSH-AUTHORIZED` is accepted — which is what both existing consumers already write (`SWB-…`, `XOXO-…`). Setting it **narrows** to your spelling alone. |

The guard reads them on every command, so a change takes effect immediately; nothing needs restarting.

**You do not have to place that block by hand** — the `adopt-shopify-floor` skill writes it, and takes
the id as a parameter so the guard is armed in the same move. It also places the two items every Shopify
consumer of this plugin has otherwise written from scratch: a starter `.theme-check.yml` and the CI
workflow over it.

**A placeholder does not count as an answer, on purpose.** `Get-ShopifyLiveThemeId` returning anything
non-numeric — a `VUL-IN` left in place, most likely — is read by both the guard and the session check as
*unanswered*. A theme id is numeric, and the alternative is worse than an absent function: a stub would
silence the report while leaving the id half exactly as inert as before. That is the shape this README
warns about two sections down — a hole with a comment on it.

## Converging off a hand-written guard

Read this if your repo wrote its own live-theme guard **before** this plugin shipped one. Both existing
consumers did, and inbound
[#777](https://github.com/DaveKJohn/claude-code-specialists/issues/777) is what that cost the second of
them.

**A plugin refresh does not replace your file. It registers a second hook beside it.** The plugin's guard
comes in through the plugin's own `hooks/hooks.json`; yours sits in your `.claude/settings.json`. Both are
live, both fire on every command, and they agree on their verdict — so two hooks block the same command
twice and nothing looks broken. What made it invisible in practice is worth knowing: that refresh happened
*inside* one version, so there was no bump to prompt anyone to read a changelog.

The floor session check now says so once per session. The route off it:

1. **Remove your own `PreToolUse` entry** from `.claude/settings.json`, and then your own script. The
   plugin's guard needs no registration from you — enabling `team-shopify` is the registration.
2. **Keep your test suite**, pointed at the shipped copy. It is the part of a hand-written guard that
   does not become redundant, and the shipped guard's own suite lives in the source repo where you
   cannot run it against your theme.
3. **Your authorisation marker keeps working.** Any marker *ending in* `LIVE-PUSH-AUTHORIZED` is
   accepted, so `SWB-LIVE-PUSH-AUTHORIZED` and `XOXO-LIVE-PUSH-AUTHORIZED` both pass unconfigured.
   Confirm that before you delete anything; set `Get-ShopifyLivePushMarker` only if you want to narrow
   to your spelling alone.

**Converging is a safety improvement, not housekeeping**, which is why it is written down rather than
tolerated: the shipped guard matches `Bash|PowerShell` where a hand-written one typically matches `Bash`
only, and it carries the false-positive lesson below that the first hand-written version had to learn on
its own. It is a superset in what it catches.

The removal stays **your** keystroke. `adopt-shopify-floor` will not do it: taking a `PreToolUse` entry
out of somebody's settings is a deletion, and a consumer who ends up with *no* guard because a script
was confident is worse off than one running two.

## Mentioning a rule is not performing it

This is the part that decides whether a guard survives contact with a repo, so it is worth reading before
changing the matching.

The first version of this guard, in the consumer that wrote it, matched the forbidden words **anywhere**
in the command string. On its first day it blocked, in order: the heredoc that wrote the rule into that
repo's `CLAUDE.md`, and the `perl` one-liner that later edited the same sentence. Neither would have
touched the store.

> A guard that makes its own rule impossible to write down is a guard somebody eventually switches off,
> which is worse than no guard.

So the matching asks **where** the words sit rather than whether they occur:

- **Heredoc bodies are stripped** — `cat > file <<EOF … EOF` writes data and the body never runs. *Unless*
  an interpreter is consuming it (`bash <<EOF`), in which case the body **is** a script.
- **Text tools are skipped** — a segment led by `grep`, `sed`, `perl`, `awk`, `cat`, `echo`, `git` and
  friends is handling the words, not obeying them. *Unless* the command pipes into an interpreter or uses
  `eval`/`xargs`: `echo "…" | bash` really does execute.
- **Everything else is matched per shell segment**, so a real command after a heredoc, after a semicolon,
  or inside a wrapper is still caught.

**Every one of those exemptions has a counter-case in the suite** (`scripts/tests/guard-live-theme.tests.ps1`
in the source repo, 69 asserts), because an exemption without one is a hole with a comment on it.

### The two limits, stated rather than hidden

- **A text tool asked to execute** — `perl -e` with a `system()` call, say — is exempted and is not
  caught. A deliberate trade: that vector needs somebody to go out of their way, while the false
  positives it would otherwise cause happen every time a repo documents its own safety rules.
- **The MCP vector is not covered.** This guard holds the CLI reached through the Bash and PowerShell
  tools. A publish issued through a Shopify MCP connector is a different path, held by that server's own
  permission prompt.
