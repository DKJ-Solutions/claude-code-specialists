## `docs/portable-ticketwork-rules` progress

### Steps

- [x] Verify inbound #603 against the tree: the landing site exists, nothing here already covers it
- [x] Ask Dave how far to take it -- rules doc only, no template, no skill
- [x] Author `TICKETWORK-portable.md`: the ten rules with their reasoning and their measured instances
- [x] State the provenance honestly up front -- one repo, one day, no DRY payoff by the usual test
- [x] Name what the consumer answers, and what is deliberately absent
- [x] Register it in the plugin README so it is reachable rather than orphaned
- [~] No `templates/ticket_template.md` -- Dave chose rules only; the shape has met one tracker
- [~] No `new-ticket` skill -- every other skill in this plugin wraps a script, and there is no script here
- [x] Lint (link scan over both anchors) + full suites green

### Where I left off

Done. The two dropped steps are the report's own options 2 and 3, declined by Dave rather than missed, and
the document says so in its closing section so a consumer does not read the absence as an oversight.
