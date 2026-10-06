# Run report 2026-10-06 — tourmakeady-scoping

No extraction performed. Nothing created in the app.

- Queue: no `pending` entries; first non-done entry is `tourmakeady-scoping`
  (`needs_scoping`). Human + interactive scoping session required (EXTRACTION.md §6).
- App/connector: `https://mayo-irish-app.fly.dev/` unreachable from the sandbox
  (5 attempts, proxy returned 403 on CONNECT), and the `mayo-irish-app` MCP
  server requires (re)authorisation — non-interactive session cannot run OAuth.
  Re-authorise the connector in claude.ai connector settings before the next
  run that has real work.
- Records created: none. For human deletion: none.
