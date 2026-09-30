# 2026-09-30 — Nightly extraction run: queue needs human attention

## Outcome

No extraction performed. No records created, no queue entries changed.

## Reason

1. **App unreachable:** `GET https://mayo-irish-app.fly.dev/` failed 5 times over ~2 minutes
   (curl exit 000; `CONNECT tunnel failed, response 403` from the agent proxy —
   a network-policy denial, not Fly auto-sleep). The mayo-irish-app MCP tools
   never appeared in ToolSearch. Same failure as every night since at least
   2026-08-20.
2. **Queue head needs a human:** the only non-done entry is
   `tourmakeady-scoping` (`status: needs_scoping`). No pending entries exist.

## Needed from a human

- Allow `mayo-irish-app.fly.dev` in the environment's network policy and make
  sure the mayo-irish-app connector is enabled for this routine.
- Scope the Tourmakeady material into T-units (or add other pending units).
