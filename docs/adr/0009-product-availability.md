# ADR-0009: `orders` owns shift-level availability; `catalog` keeps owning the definition

- **Date:** 2026-09-12
- **Status:** Accepted
- **Decided by:** Kevin Aguirre

## Context

Session 2's event storming flagged "product out of stock" as the event most likely to move a boundary. Breaking it down revealed three distinct phenomena, not one:

1. **Off the menu by time of day** — no chilaquiles at night. Predictable, configuration, low frequency.
2. **Out of stock** — a recipe calls for a supply that hit zero.
3. **86'd by the kitchen** — "we ran out of fish," "the fryer broke." High frequency, several times a shift, and not necessarily tied to stock at all: a broken fryer takes six dishes off the menu without moving a gram of inventory.

The third is the dominant one in frequency and urgency, and it doesn't fit as a catalog fact or an inventory fact: it's operational state scoped to a shift, at a single branch.

## Options considered

### Option A — Availability as a `catalog` field
Implementation: S. In favor: seems like the obvious spot — "what can be sold" sounds like a catalog concern. Against it: breaks three assumptions of the design at once. `catalog` is low-write, high-cacheable-read (§2 of the technical design), and `orders` reads it with a 60s TTL in Redis — a waiter selling salmon that ran out 40 seconds ago isn't an edge case, it's the normal scenario. Availability is scoped to branch and shift; `catalog` is scoped to tenant. And if `catalog` goes down, `orders` keeps selling from cache (§8) — fine for names and prices, unacceptable for availability exactly when the system is degraded.

### Option B — Availability derived from `inventory`
Implementation: M. In favor: stock deduction already lives there, and there's a real relationship between a supply and availability. Against it: the roadmap already establishes that a product with no recipe shouldn't break order closing — many products have no stock to check against. And it doesn't cover the dominant case: a broken fryer isn't an inventory event.

### Option C — `orders` owns shift availability; `inventory` only notifies
Implementation: M. A table inside `orders`, keyed by `(tenant_id, branch_id, operating_date, product_ref)`, with an available/unavailable state, who set it, why, and when. `inventory` emits `inventory.stock.depleted.v1` when a supply hits zero; `orders` consumes it and flags the affected products with `source: inventory`. `catalog` doesn't change: it stays the owner of what exists, what's on the menu, and when.

## Decision

Option C. The reasoning isn't elegance, it's failure domain: `orders` is the only service with no acceptable degradation (§8) — if it goes down, operations stop. Putting availability there makes it available exactly when the POS is available, not a second less. `orders` is also already the only service scoped to branch and shift, which is exactly this data's scope.

Favorable side effect: it resolves the caching tension without touching it. `catalog`'s 60s cache keeps serving names and prices, which change rarely. Availability reads from `orders`'s own table, with no TTL and no staleness.

**Two rules implemented alongside the table, not afterward:**

1. **A manual kitchen mark beats an automatic inventory one.** If the kitchen restores a product that `inventory` had taken down, that override is stored in a separate field and survives the next inventory event. Without this, the next stock event knocks it right back down and nobody can sell what's actually there.
2. **Availability resets at the start of each shift.** Operating date is in the key exactly for this: without it, yesterday's out-of-stock salmon is still out of stock today.

**New events** (added to the §3 catalog in the technical design):

| Event | Producer | Consumers |
|---|---|---|
| `orders.availability.marked_unavailable.v1` | orders | kds, reporting |
| `orders.availability.restored.v1` | orders | kds, reporting |
| `inventory.stock.depleted.v1` | inventory | orders |

## The case that doesn't get solved, and shouldn't be forced

An offline tablet keeps whatever availability it had when it disconnected. If the kitchen 86's a product during that gap, the waiter will still sell it — there's no way to know without a network, and that isn't a bug.

It's treated as a kitchen rejection, not a validation error: the line syncs regardless (ADR-0003, append-only), the kitchen rejects it, `orders.item.rejected.v1` fires, and the waiter is notified over the same channel that today tells them "ready." Trying to validate this on the client would mean fighting the physics of being disconnected.

## Scope deliberately excluded

This decision covers **binary** availability: available or not. A counter version ("3 salmon orders left") requires reserving on add-to-order, releasing on cancel, and resolving the race between two waiters ordering the last one at the same time — a considerably harder problem with no evidence yet that a real restaurant needs it. V1 assumes a small business simply 86's a dish once it runs out. Observing a real shift (§5 of `product-readiness.md`) should be what decides whether this gets revisited.

## Consequences

**We gain:** availability that's as reliable as the POS itself, with no dependency on `catalog`'s cache or on `inventory` being up to date. Covers the dominant case (kitchen 86) without forcing it through inventory.

**We lose / accept:** `orders` gains a table and one more responsibility, on top of already being the highest-load service. `catalog` and `orders` now share the concept of "sellable product" split across two places — name and price in one, availability in the other — and the docs need to be explicit about which one answers what.

**Changes:** the gateway's BFF (`GET /bff/pos-home`, session 20) has to combine `catalog`'s menu with `orders`'s availability into a single aggregated response, so the waiter doesn't make two calls or see inconsistencies between them.

## Reversal criteria

This decision has failed if, on observing a real shift, availability turns out to depend on stock far more often than expected, and the "86'd with no relation to inventory" case turns out to be rare rather than dominant. In that scenario Option B becomes the right one, and this table collapses into `inventory`.

It also fails if a real, frequent need for a counter instead of binary shows up — in that case this decision gets revisited together with the availability decision as a whole, not separately, because a counter changes the shape of the entire table.
