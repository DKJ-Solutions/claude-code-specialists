### the gh multiline-body pitfall recorded in Derek's lens · Docs · 2026-07-30

Hit twice while closing the two inbound issues from the life-hub round, so it is written down rather
than left in a session: **a multiline body passed inline to `gh` from PowerShell 5.1 does not get
mangled, it gets split.** Each line arrives as its own argument (`accepts 1 arg(s), received 4`), and
the expensive variant is the half-success — `gh issue close <n> --comment "<multiline>"` **closed the
issue and dropped the comment**, printing only its "Closed issue" line. A caller trusting that output
believes the summary landed.

Recorded in [Derek #05's lens](.claude/specialists/lenses/05-05-extension.md) under *The quoting
lesson*, where the related single-line `"`-mangling lesson from July 16 already lived: the rule is not
"quote it carefully" but **never inline a multiline body** — write it to a file and use `--body-file`
(and since `gh issue close` has no `--body-file`, comment first, then close). Plus the general form of
what went wrong: after a `gh` call that was supposed to leave text behind, verify the text is there
instead of trusting the exit line.
