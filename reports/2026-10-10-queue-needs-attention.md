# Run report — 2026-10-10

No extraction performed.

- Queue: no `status: pending` entries. First non-done entry is `tourmakeady-scoping` (`needs_scoping`) — needs an interactive session to scope (EXTRACTION.md §6).
- App warm-up: `GET https://mayo-irish-app.fly.dev/` failed (curl 000; proxy CONNECT returned 403) on 4 attempts from the sandbox.
- The `mayo-irish-app` MCP connector still "requires authentication". No write path was used.

Created records: none. For human deletion: none.

Follow-ups: re-authorize the mayo-irish-app connector in claude.ai settings; check that the routine's network policy allows mayo-irish-app.fly.dev; scope the Tourmakeady unit or add pending entries.
