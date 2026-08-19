## Branch `fix/dave-count` changelog - 20260819-103016

### What does the change on this branch bring to main?

#### Tier 0

`CLAUDE.md` said the top half *"names Dave as the decision-maker fifteen times"*. It named him
**fourteen**. The figure came from `grep -c`, which counts **lines containing** a string rather than
occurrences, and one of the counted lines was `github.com/DaveKJohn/...` — the GitHub org inside a
URL. The same measurement, in the same entry, separately counted that line as the link to issue #388,
so the error was visible from inside the sentence that made it. Dave read the paragraph, counted, and
asked.

**The number is gone rather than corrected in place**, and that is the durable half. A tally of a name
written inside the document that carries the name is wrong when typed and wrong again after the next
edit — this one became 15 the moment the previous branch added a sentence of its own about Dave's
ownership, which is a statement *about* the arrangement rather than an instance of him deciding. The
sentence now reads *throughout*, which needs no maintenance. The paragraph one screen above already
warned about exactly this for the word *portable* and deliberately carried no count; the warning is
now stated once, for both.

**The folded entry of [#750](https://github.com/DaveKJohn/claude-code-specialists/pull/750) in
`CHANGELOG.md` is corrected too, and marked.** It was false when written, and the record rule protects
a line that *went* stale, not one that arrived wrong — correcting that kind restores the record. The
correction names the date, what it first said, and where the figure came from.

**Nothing was changed in the `CONTRIBUTING` layers, deliberately.** The same law was applied to all
three and all three pass: the root page's three rules hold with no plugin installed;
`CONTRIBUTING-portable.md` earns its claim to travel, measured at **0** hardcoded trunk names, **0**
mentions of this repo's `lint-en-tests` check, and **16** seam functions named where a local answer
could have been asserted; and the workflow layer's claim that the portable half travels is therefore
true. Its 8 mentions of `workflow-davekjohn/` are the plugin's own folder name, identical in every
consumer, not a local answer. Where `CLAUDE.md` claimed portability it had not earned, this family
had earned it and said so accurately.

**Score:** 2

#### Higher than tier 0?

N/A — `CLAUDE.md` and `CHANGELOG.md` are this repo's own documents and are not plugin payload. The
`CONTRIBUTING` audit changed nothing, so nothing travels from this branch.

**Score:** N/A

### Pull Request

The root's count of Dave was the grep's count, not Dave's
