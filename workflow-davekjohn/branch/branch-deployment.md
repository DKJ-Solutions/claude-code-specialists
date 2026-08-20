## `docs/v4-16-0-timing-total` deployment

### What does the change on this branch deploy to main?

The second of the two timing passes step 0a of the `cut-release` checklist asks for. The v4.16.0 release
document froze at a subtotal of **7m 36s** because four of its legs were still running on the file it was
written into — writing the page itself, its local gates, its CI and merge, and the fold. Those legs now have
timestamps, so the total goes in: **25m 29s** of working time, with writing the page **5m 45s**, the local
gates and push **2m 57s**, CI and the merge **9m 07s**, and the fold **4s**.

**The reading that needed a decision rather than a subtraction is the 58m 53s between the published Release
and the start of the page.** That is the requester deciding to ask for the document, not the procedure
running. Folded into the total it would report **1h 24m 22s** for work that took twenty-five minutes, and
every comparison with another release would break. So it is stated beside the total rather than inside it,
and the wall-clock span is given once so the number is not lost.

Two readings the first pass could not produce. The head came to **26%** of the working total, a fifth reading
for the claim that most of a release happens after the version number exists (`v4.15.0` 21%, `v4.12.0` 24%,
`v4.13.0` 30%, `v4.14.0` 32%). And the two heaviest legs are **58%** between them, of which only the writing
is a person's time.

**Score:** 2

#### What makes this change extra special

It puts a second consecutive end-to-end measurement beside the first, and the pair is what makes the
fixed-cost claim concrete: **24m 34s** for v4.15.0's thirteen entries against **25m 29s** for v4.16.0's four.
A release costs what it costs per *event*, not per change — which is an argument for cutting when there is
something to ship rather than for batching until there is a lot.

The separated requester gap is the part a consumer running this workflow will meet first. A release
interrupted halfway is the normal case, not the exception, and a timing section that cannot tell waiting
apart from working produces a number nobody can use twice. The rule this instance sets is to exclude the
wait, name it, and give the wall clock once.

**Score:** 2

### Pull Request

The v4.16.0 release note gains its end-to-end total
