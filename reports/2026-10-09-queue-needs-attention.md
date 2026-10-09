# Run report — 2026-10-09

No extraction performed.

- Queue: no `status: pending` entries. First non-done entry is `tourmakeady-scoping` (`needs_scoping`) — needs an interactive session to scope (EXTRACTION.md §6).
- App warm-up: `GET https://mayo-irish-app.fly.dev/` returned no HTTP response (curl 000) on 3 attempts from the sandbox.
- The `mayo-irish-app` MCP connector reported "requires authentication" (OAuth cannot be run non-interactively). No write path was used.

Created records: none. For human deletion: none.

Follow-ups: re-authorize the mayo-irish-app connector in claude.ai settings; scope the Tourmakeady unit or add pending entries.
