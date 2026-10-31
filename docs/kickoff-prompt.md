# Kickoff prompt for Claude Code

Paste this as the first message in a fresh Claude Code session at the repo root.
Do NOT run `/init` (it would overwrite CLAUDE.md).

---

Read `CLAUDE.md`, then `docs/technical-design.md`, `docs/roadmap.md` and everything in `docs/adr/`.

Project state:
- Phase 0, sessions 1-3 are DONE: domain events, service boundaries, and the 16 JSON Schemas in `contracts/events/` (validated by `./scripts/validate-events.sh`).
- Next is **session 4**: OpenAPI specs for `orders` and `catalog` in `contracts/openapi/orders.yaml` and `catalog.yaml`. Session 5 is `docker-compose.yml` (Postgres, Redis, RabbitMQ).

Before writing anything:
1. Run `/session 4` (or read its roadmap row) and give me a short plan: files you'll create, decisions you need from me.
2. Wait for my approval.

Constraints for session 4:
- Money in integer cents, ULID public IDs, `tenant_id` only from the JWT `tid` claim (never a path/query/body field).
- Use the same field names in `GET /orders/{id}` as in the `orders.order.closed.v1` event payload, so there is one vocabulary.
- Order lines are voided, never deleted (ADR-0003); availability is owned by `orders` (ADR-0009).
- If the task starts touching 3+ services, stop and tell me.
- Any contract change goes under `contracts/`, with its own commit.
