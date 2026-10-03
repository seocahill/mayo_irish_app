# Run report 2026-10-03 — tourmakeady-scoping

No extraction performed. The first non-done queue entry is
`tourmakeady-scoping` (`status: needs_scoping`), so the queue needs human
attention (EXTRACTION.md §6). No `pending` units exist. Fourth consecutive
night in this state.

- Warm-up: GET https://mayo-irish-app.fly.dev/ failed on 6 attempts over ~2 minutes (curl 000; the agent proxy answered `CONNECT tunnel failed, response 403`, so the host appears not to be allowed by the environment's network policy). mayo-irish-app MCP tools never appeared in the tool list.
- No records created; nothing for human deletion.
- Action needed: (1) scope the Tourmakeady material interactively and append T-units to `extraction_queue.yml`, or add other pending units; (2) allow `mayo-irish-app.fly.dev` in the environment's network policy and check the mayo-irish-app connector is attached to the routine.
