## `fix/workflow-folder-history-split` deployment

### What does the change on this branch deploy to main?

`adopt-workflow-folder` stops contradicting itself inside one command's output. It scaffolded
`workflow-davekjohn/releases/README.md` with a `## Release history` heading, a table, and a `VUL-IN`
promising that the cut would insert its rows there -- and then, in the same run, told the reader to
leave `Get-ReleaseHistoryPath` at its repo-root default. Two statements that cannot both be true. The
scaffolded page now states this repo's release ANSWERS and names where the list actually lives, read
through the seam rather than hardcoded, so a repo that has repointed it is not sent to a file that is
not theirs.

Four places carried the claim and all four are repaired: the script header, the folder README's own
table row, the folder `CLAUDE.md`'s rules list, and the page itself. The test that asserted the table
header now asserts its absence, which makes it the regression guard on the contradiction.

**The report's proposed second half is deliberately not built, and the recount is why.** It asked for
the root history file to be scaffolded too, "so the cut is not the thing that creates an unannounced
one" -- but the cut creates nothing: with the file missing it warns `<path> is missing -- row not added`
and cuts anyway. And a scaffolded file with a table but no `<major>.x` heading would read as DONE to
`cut-release`, filing the row while silently disabling the guardrail that refuses a `v2` row under a
`1.x` heading, because that check skips when it finds no section. That is the same hole-with-a-comment
`adopt-shopify-floor` refuses to write. So the closing advice now prints the exact shape the reader
owes, the warning they get if they forget, and why the command will not write it for them.

**Score:** 2

#### What makes this change extra special

It is silent until the first cut, and the first cut is the worst possible moment to discover it. A
consumer who follows the advice ends up hand-maintaining a table nothing will ever write to, and the
consumer who reported it resolved it by doing exactly what the closing advice says not to -- which then
became nine lines of retracted reasoning in their own `repo-config.ps1`. Every consumer that adopts the
folder walks into the same fork.

**Score:** 3

### Pull Request

The workflow folder stops scaffolding a release history it tells you not to point the cut at
