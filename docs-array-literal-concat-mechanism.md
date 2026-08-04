### Name the mechanism behind the broken fixture, and its stiller second form · Docs · 2026-08-04

**#446 fixed the fixture and named the effect; this names the cause.** That entry said PowerShell "takes
the three operands as three elements," which is what you see but not why, and a rule you cannot apply
anywhere else. The cause is operator precedence: **the comma operator binds tighter than `+`**, so inside
a comma-separated array literal the `+` never joins its neighbouring strings — it joins the array on its
left to the array on its right.

```powershell
@( 'H', '', 'A' + $x + 'B', '', 'T' )   is   ( ('H','','A') + $x + ('B','','T') )
```

Seven elements where five were written, verified element-for-element against that regrouping rather than
inferred from the count matching.

**The second form is quieter, and it is the one worth knowing about.** With no comma to the *left*, the
left operand is a plain string, so string concatenation wins and the array on the right is flattened into
it with `$OFS` — a space — between its parts:

```powershell
@( 'A' + $x + 'B', 'T' )   ->   ONE element: "A—B T"
```

**That version leaves no loose line to spot.** It produces no bare separator, so the bare-separator checks
added in #446 would not catch it; it simply swallows the next element into a plausible-looking string. The
first form is the one that got caught precisely because it was the noisy one.

**Searched before claiming it was unique.** Every `.ps1` in the repo was scanned for both shapes: no other
instance. The remaining `+`-built strings are assignments or single expressions, where there is no comma
for the operator to bind to — including the one `@(...)` that holds a single concatenated element, which
is safe for that same reason.

**Split across the two layers rather than written once.** The precedence rule and both worked examples are
language-specific, so they sit in the test comment where the defect lived. Tycho's portable manual gets the
form a reader in any language can act on: **string concatenation inside a list literal is the highest-risk
construction in a fixture**, because precedence there is rarely what it looks like — build the value first
and put the variable in the list, or interpolate. No numbers, no PowerShell syntax, per the layer test
from #440.
