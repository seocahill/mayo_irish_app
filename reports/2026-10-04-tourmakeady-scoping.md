# 2026-10-04 — no extraction run

- Queue head: first non-done entry is `tourmakeady-scoping` (`status: needs_scoping`). No `pending` entries remain. Per EXTRACTION.md §6 this needs an interactive human scoping session.
- Warm-up: `https://mayo-irish-app.fly.dev/` unreachable from the routine sandbox (5 tries, proxy `CONNECT tunnel failed, response 403`). The `mayo-irish-app` MCP tools were not available either.
- Nothing was created in the app. No queue changes.

Action for human: scope the Tourmakeady scans (or add new pending units), and check that the routine environment's network policy allows `mayo-irish-app.fly.dev`.
