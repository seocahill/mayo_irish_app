# Run report — 2026-10-11

No extraction performed.

- Queue: no `status: pending` entries. First non-done entry is `tourmakeady-scoping` (`needs_scoping`) — needs an interactive session to scope (EXTRACTION.md §6).
- App warm-up: `GET https://mayo-irish-app.fly.dev/` failed (curl 000; proxy CONNECT returned 403) on 5 attempts from the sandbox. The MCP tools did load this run, but no writes were attempted since there is nothing to extract.

Created records: none. For human deletion: none.

Follow-ups: scope the Tourmakeady unit (or add pending Foxford/Erris entries); allow mayo-irish-app.fly.dev in the routine's network policy.
