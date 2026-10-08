# 2026-10-08 — run blocked (no extraction performed)

- Warm-up of https://mayo-irish-app.fly.dev/ failed on all 3 attempts: the
  sandbox egress proxy returned `CONNECT tunnel failed, response 403`
  (host not allowed by the environment's network policy).
- The `mayo-irish-app` MCP server reported "requires authentication"; this
  non-interactive session cannot run the OAuth flow, so its tools were never available.
- Per EXTRACTION.md §4.1, no other write path was tried. No records created,
  queue untouched, `next_lesson_number` unchanged.

Action needed: add mayo-irish-app.fly.dev to the routine environment's allowed
domains and re-authorize the mayo-irish-app connector in claude.ai connector settings.
