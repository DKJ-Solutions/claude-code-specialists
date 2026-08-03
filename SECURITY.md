# Security Policy

`claude-code-specialists` is the public marketplace repo for Dave (DaveKJohn)'s Claude Code plugins
(the Claude Specialists system): plugin/agent definitions, manuals, PowerShell scripts, docs, and
CI config. It's public **by design**, and by the same design it holds **no secrets, credentials,
or personal data** — see [`CLAUDE.md`](CLAUDE.md#specific-to-this-repo-claude-code-specialists).
Nothing in here is meant to be confidential in the first place.

## Reporting a vulnerability

If you believe you've found something with an actual security impact (see Scope below), please
report it privately rather than opening a public issue or PR:

- **Preferred: GitHub Security Advisories.** Use this repo's Security tab →
  "Report a vulnerability" to open a private advisory. That keeps the report out of public view
  until it's assessed, and is the most reliable way to reach the maintainer.
- If that route isn't available to you for some reason, open a regular (non-sensitive) issue
  asking for a private way to get in touch, and one will be provided.

This is a solo-maintained repo, not a project with a dedicated security team — a clear
description and, where possible, a reproducible example goes a long way toward a fast triage.

## Scope

**In scope:**
- An agent definition, manual, persona, skill, or hook whose content could cause unsafe or
  unintended behavior when loaded into a Claude Code session (e.g. prompt-injection-style
  instructions, or a hook/script that does something destructive or unsafe by default).
- A script under `scripts/**` or CI config (`.github/workflows/`) with a genuine security flaw
  (e.g. unsafe handling of input, unintended command execution).
- Any accidental exposure of secrets, credentials, or personal data anywhere in this repo or its
  history — this should never happen given the "no secrets" rule above, but if it does, it's in
  scope.

**Out of scope:**
- There is no hosted service, API, or user data behind this repo — it's plugin source, docs, and
  scripts, consumed by other repos' Claude Code sessions. Availability/denial-of-service-style
  reports don't apply.
- General bugs without a security impact — please file those as a normal GitHub issue instead.

## Response expectations

Best-effort, single-maintainer response — there's no formal SLA and no dedicated security team.
Reports are triaged as soon as they're seen, and a confirmed issue is fixed through the repo's
normal branch + PR (+ release, if warranted) workflow described in
[`CONTRIBUTING.md`](CONTRIBUTING.md).
