## `docs/shopify-line-endings` deployment

### What does the change on this branch deploy to main?

`team-shopify` says what happens to line endings, which until now it did not mention anywhere: a
`grep -rniE "crlf|line ending|autocrlf"` over the whole plugin returned nothing. Steven's manual gains
the fact and the trap, since it is a property of the CLI rather than of any one store; Sandra's hard
rules gain the reading instruction, at the moment she reads a pull; the plugin README gains a section
before the two adoption sections, because a reader hits this on their first pull; and both the
`sync-main` skill page and `adopt-shopify-floor`'s closing output point at it.

Two things, and the second is why this is worth more than a footnote. **Read the drift after a
`git add -A`, never off the raw `git status`** -- the CLI writes each file with the line endings live
holds, live holds both, so a pull reports files as modified with zero changed lines. And **do not pin
`eol=lf`**, which is the obvious fix and makes the noise permanent: the same files then come back after
every pull forever, converting the one signal that spots a third party's in-flight edit into standing
noise. What `.gitattributes` should carry instead is stated, and why this plugin deliberately does not
place that file: the measurement says the working procedure is where the problem is handled, and
`* text=auto` dropped into a repo whose index already holds CRLF renormalises the whole tree on the
next `add` -- a bad surprise to arrive by scaffold.

The three measurements were verified in the reporting consumer's own tree rather than copied from the
report, and one of the report's figures had already moved: it says "over 712 tracked files", the tree
now says 740. The count that matters -- 37 files, zero changed lines -- holds, so the text carries that
and drops the total.

**Score:** 2

#### What makes this change extra special

The whole safety model of this team rests on one human judgement, made by reading `git status` after a
pull: is this diff mine, or a third party's in-flight edit? That judgement is the only thing between a
push and somebody else's unsaved work -- and the raw output of that command is unreadable, 37 times out
of 37. A verification step that cries wolf every time is the step nobody reads on the day it is right.

Both existing Shopify consumers discovered this independently, and one discovered it *twice*: it filed
`eol=lf` as an improvement, then inverted its own conclusion on re-measuring, because the proposed
remedy would have broken the safety check it was meant to help. That whole loop is what the next
consumer inherits, and none of it is about their store.

**Score:** 4

### Pull Request

team-shopify names the CLI's line-ending churn, and the fix that makes it permanently worse
