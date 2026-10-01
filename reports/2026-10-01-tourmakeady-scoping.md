# Run report 2026-10-01 — tourmakeady-scoping

No extraction performed. Nothing was created in the app.

- Queue: no `status: pending` entries remain; the first non-done entry is
  `tourmakeady-scoping` (`status: needs_scoping`). The queue needs human attention
  (an interactive scoping session for the Tourmakeady scans).
- Connector: https://mayo-irish-app.fly.dev/ was unreachable from this sandbox
  (5 attempts, proxy CONNECT returned 403), and no mayo-irish-app MCP tools were
  exposed. Not relevant to the outcome today, but the network allowlist likely
  needs fly.dev if future runs are to write.

Created records: none. For human deletion: none.
