# 2026-08-02 — erris-intro-notation (RUN ABORTED — connector unavailable)

## Summary

No extraction was performed. The routine could not confirm the
mayo-irish-app MCP tools (`create_record`, `update_record`, `get_record`,
`list_records`) as usable this run, and per EXTRACTION.md §4.1 / the routine
prompt step 2 ("Never write through any other path"), stopped without
attempting any write.

## What was attempted

1. Read EXTRACTION.md in full (step 1) — no changes needed there.
2. Warm-up: `GET https://mayo-irish-app.fly.dev/` — failed on every attempt
   with a hard TCP/CONNECT-level failure (curl exit, no HTTP response),
   confirmed via the sandbox's outbound-proxy status endpoint to be an
   explicit `403` policy denial on the CONNECT to
   `mayo-irish-app.fly.dev:443`, not a timeout. Per today's earlier
   successful run (`reports/2026-08-02-erris-initial-mutation.md`), this
   direct-HTTP path is *known* to be blocked by this sandbox's egress policy
   even when the MCP connector itself works fine — so this failure alone is
   not conclusive.
3. Checked the MCP connector directly instead, since that's the actual
   write path: `ListConnectors` reports `mayo-irish-app` as
   `installState: connected`, `connected: true`, `enabledInChat: true` —
   but `ToolSearch` returned **zero** matching tools for every query tried
   (`create_record`/`update_record`/`get_record`/`list_records` by name,
   plus topical queries like "lesson", "grammar_rules vocabulary_items",
   "create record lesson grammar"). `ListMcpResourcesTool` likewise found no
   resources for the server. `ToolSearch` was confirmed working correctly in
   general during the same window (it returned normal results for the
   `Abairt` connector on an identical-shape query).
4. Waited ~90s (on top of the ~2 minutes of warm-up retries) in case the
   server was still finishing initialization, then repeated the `ToolSearch`
   and `ListConnectors` checks — same result: connected at the org/OAuth
   level, zero tools exposed.

Total elapsed on diagnosis: ~4-5 minutes across warm-up retries, tool
searches, and one deliberate wait cycle — well past the ~2 minute budget in
step 2 of the routine prompt.

## Conclusion

The mayo-irish-app MCP server is authenticated/connected but is not
surfacing any callable tools in this session — a different and more
concerning failure mode than a sleeping Fly app (which the connector layer
handled transparently on the previous run). This may mean the app is
erroring on its own backend (e.g. crashing on boot, DB connection failure)
in a way that leaves the MCP transport connected but tool-listing broken,
or a transient issue with the connector plugin itself.

No records were created, no lesson consumed, and `extraction_queue.yml` is
**unchanged** — `erris-intro-notation` remains `status: pending` and is
still the correct head-of-queue entry for the next run.

## Suggested follow-ups

- A human should check `https://mayo-irish-app.fly.dev/` directly (outside
  this sandbox) to confirm the app is actually up and the DB is reachable.
- If the app is healthy, check the mayo-irish-app MCP connector
  configuration/health from the claude.ai connector settings — it may need
  reauthorization or a restart independent of the app's own uptime.
- Re-run the routine (manual "run now") once the above is confirmed; no
  queue or content changes are needed first.
