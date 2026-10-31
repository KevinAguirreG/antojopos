# Event catalog

16 events, each with its schema (`<event>.json`) and a real example that
validates against it (`examples/<event>.example.json`). `_envelope.schema.json`
is the common shape described in `docs/technical-design.md` §3 — every event
extends it via `allOf`.

## Verify

```bash
./scripts/validate-events.sh
```

Runs in CI on every push that touches `contracts/events/`. If you add an event
with no example, or the example doesn't satisfy the schema, the pipeline
fails — that's the intended behavior.

## Adding a new event

1. Confirm which service produces it and who consumes it; note it in the §3
   table of the technical design before writing the schema.
2. Create `<service>.<aggregate>.<fact_in_past_tense>.v1.json` with `allOf`
   over `_envelope.schema.json`, pinning `event_type` and `producer` with
   `const`.
3. Create `examples/<same_name>.example.json` with a real case, not a
   half-thought-out one.
4. Run `./scripts/validate-events.sh`. Once it passes, run `make contracts`
   to generate the types in Go, TypeScript, and PHP (see
   `.claude/rules/contracts.md`).

## Changing an existing event

If the change is additive (a new optional field), edit the schema in place.
If it isn't — dropping a field, changing a type, making an optional field
required — don't edit it: create `v2` and keep `v1` alive until every
consumer has migrated. Events get versioned, not corrected. See
`.claude/rules/contracts.md`.

## Type conventions

| Field | Type | Note |
|---|---|---|
| `event_id`, `causation_id` | ULID | `^[0-7][0-9A-HJKMNP-TV-Z]{25}$` |
| `tenant_id`, `branch_id`, `correlation_id`, `*_user_id` | UUID | `uuid` format |
| Domain identifiers (`order_id`, `product_ref`, `line_id`, ...) | ULID | same as `event_id` — §9 of the technical design |
| Money | integer, cents | never a float or decimal |
| `event_type` | string | `^[a-z_]+\.[a-z_]+\.[a-z_]+\.v[0-9]+$` |

## The 16 events

| Event | Producer |
|---|---|
| `identity.tenant.created.v1` | identity |
| `identity.branch.created.v1` | identity |
| `catalog.product.updated.v1` | catalog |
| `orders.order.opened.v1` | orders |
| `orders.item.sent_to_kitchen.v1` | orders |
| `orders.payment.requested.v1` | orders |
| `orders.order.closed.v1` | orders |
| `orders.order.cancelled.v1` | orders |
| `orders.availability.marked_unavailable.v1` | orders — [ADR-0009](../../docs/adr/0009-product-availability.md) |
| `orders.availability.restored.v1` | orders — ADR-0009 |
| `orders.item.rejected.v1` | orders — ADR-0009 |
| `payments.payment.captured.v1` | payments |
| `payments.payment.failed.v1` | payments |
| `payments.cash_session.closed.v1` | payments |
| `inventory.stock.low.v1` | inventory |
| `inventory.stock.depleted.v1` | inventory — ADR-0009 |
