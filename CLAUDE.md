# CLAUDE.md

Project instructions for Claude Code. Read at the start of every session, so it's kept short and dense. Details live in `docs/`; this file only covers what changes behavior.

## What this is

A multi-tenant point-of-sale SaaS for restaurants. Eight independent services, each owning its own database, talking over RabbitMQ. Three languages: Go, PHP/Laravel, and TypeScript.

**This project exists to learn distributed-system architecture.** When there's a choice between "simple" and "correct in a distributed system," the latter wins. That's the point of the project.

Worth reading before touching anything big:
- `docs/technical-design.md` — boundaries, contracts, events, security
- `docs/adr/` — why things are the way they are
- `docs/roadmap.md` — which phase we're in and what's next

## Rules that never get broken

These aren't style preferences. Breaking any of them is an architecture bug, not a detail.

1. **A service never reads another service's database.** Not through a view, not through a `FOREIGN DATA WRAPPER`, not "temporarily." If you need someone else's data, get it via an event or an HTTP call, and store it as a snapshot.

2. **`orders` stores product snapshots, not references.** `name_snapshot`, `unit_price_snapshot`, `modifiers_snapshot`. Changing a price in `catalog` never alters an existing order.

3. **Nothing publishes to RabbitMQ directly from a handler.** Every event is inserted into the `outbox` table within the same transaction as the state change. The worker publishes. If you see a `publish()` call outside the worker, that's a bug.

4. **Every event consumer is idempotent**, keyed by `event_id`, checked against the `processed_events` table, inside the transaction that applies the effect.

5. **Money is in cents, `int64` / `BIGINT`.** Never a float, never a decimal in application code, never a total recomputed from another service.

6. **`tenant_id` on every table, every event, and every log line.** Taken from the `tid` JWT claim or from the event envelope. Never from a request parameter, never from the payload.

7. **Nothing gets deleted.** `deleted_at` or a void line, depending on the case. Order lines are voided, not removed (ADR-0003).

8. **Every public write requires explicit authorization inside the service.** The gateway only validates the token's signature; it never decides domain permissions.

9. **No distributed transactions.** No 2PC. Eventual consistency with compensation and timeout, as in §5 of the technical design.

10. **Public identifiers are ULIDs.** Internal PK is `BIGSERIAL`. The client can generate ULIDs for offline mode.

## Structure

```
services/
  identity/  catalog/  reporting/     → PHP 8.3 / Laravel 12
  orders/    payments/ inventory/     → Go 1.23
  gateway/   kds-notifications/       → TypeScript / NestJS
  _shared/{go,php,ts}/                → outbox, idempotent consumer, tenant, OTel
apps/pos-web/  apps/kds-web/          → Vue 3 + Vite
contracts/{openapi,asyncapi,events}/  → source of truth for every contract
infra/{docker,k8s,terraform}/
docs/
```

**`contracts/` is the source of truth.** Event types are generated from there into all three languages (`make contracts`). Don't hand-write an event struct — change the schema and regenerate.

## Commands

```bash
make up                  # brings up everything with Docker Compose
make down                # stops it, keeps volumes
make seed                # demo tenant with menu and users
make contracts            # regenerates types from contracts/events/*.json
make test                 # full suite
make test SVC=orders      # a single service
make lint                 # golangci-lint + pint + eslint
make logs SVC=payments
make e2e                  # Playwright against the running Compose stack
```

Per service, from inside its folder:

| | Go | Laravel | NestJS |
|---|---|---|---|
| Test | `go test ./...` | `./vendor/bin/pest` | `pnpm test` |
| Lint | `golangci-lint run` | `./vendor/bin/pint` | `pnpm lint` |
| Migrate | `migrate up` | `php artisan migrate` | — |

## Language conventions

These live in `.claude/rules/` with `paths:`, so Go's conventions only load when you touch a `.go` file and don't take up context the rest of the time: `go.md`, `php-laravel.md`, `typescript.md`, `contracts.md`.

The only cross-cutting rule: JSON logs to stdout with `tenant_id`, `correlation_id`, `service`, and `user_id`. Never amounts or personal data in the free-text message.

## How I want changes made

- **Scoped changes, not rewrites.** If a file needs three lines, change three lines. If you think a restructure is warranted, say so and wait for confirmation before doing it.
- **One concern per change.** Don't mix a bugfix with a formatting refactor.
- **Explain the why when the decision isn't obvious**, in one or two sentences. Don't narrate what the diff already shows.
- **If something in the technical design is wrong or stale, say so.** The document gets corrected, not obeyed out of inertia.
- **If a task crosses three or more services, stop and propose the plan first.** That's a sign the boundary might be wrong.

## Before calling a change done

- [ ] `make test SVC=<service>` passes
- [ ] `make lint` passes
- [ ] If an event changed: the JSON Schema is updated and `make contracts` regenerated
- [ ] If an endpoint changed: the OpenAPI spec is updated
- [ ] If it's a new consumer: it's idempotent and has its own DLQ
- [ ] If it's a new producer: it goes through `outbox`, doesn't publish directly
- [ ] Every new table has `tenant_id` and is covered by the isolation test
- [ ] If it's a structural decision: there's a new ADR in `docs/adr/`

## What not to do

- Don't add a dependency without saying why, and which standard-library alternative you ruled out.
- Don't introduce a new service. Eight is the agreed ceiling (ADR-0001).
- Don't touch Docker Compose, k8s manifests, or Terraform without flagging it first.
- Don't touch `contracts/` and the code that consumes it in the same step without calling it out: that's a contract change and deserves its own attention.
- Don't write tests that only check the framework works. Test domain rules: totals, check splitting, state transitions, recipe consumption, tenant isolation.
- Don't generate test data with real people's names or valid tax IDs.
