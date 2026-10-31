# ADR-0003: Offline sync via append-only lines with a client-generated ULID

- **Date:** 2026-09-11
- **Status:** Proposed (implemented in session 79)
- **Decided by:** Kevin Aguirre

## Context

A restaurant loses network regularly: the router reboots, WiFi doesn't reach the patio, a neighbor knocks down the pole. Operations can't stop because of it. Every commercial POS on the market sells offline, so this isn't a differentiator, it's a table-stakes requirement.

The hard scenario isn't one disconnected device, it's **two**: two waiters on different tablets serving the same table, both offline, both adding dishes. On reconnect, no line can be lost — a lost line is a served dish that never gets charged.

Practical constraint: this gets implemented by one person. Any solution that requires deeply understanding CRDTs eats more time than the rest of the project combined.

## Options considered

### Option A — Last writer wins on the order's state
Implementation: S. The client stores the whole order and sends it on reconnect; the server overwrites. In favor: trivial. Against it: **it loses data** in the two-waiters scenario. Whichever tablet syncs second erases the first one's dishes. Unacceptable.

### Option B — Append-only lines with a client-generated ULID
Implementation: M. The client never edits state: it queues operations like "add line," each with a ULID it generates itself. On reconnect it sends the queue; the server inserts whatever ULID it doesn't already have. In favor: the merge is an `INSERT ... ON CONFLICT DO NOTHING`; both waiters keep their lines; idempotency comes free from the ULID. Against it: deleting a line offline gets modeled as a void line, not a `DELETE`, which slightly complicates the UI and the totals.

### Option C — CRDTs (Yjs, Automerge)
Implementation: L. Automatic convergence for arbitrary structures. In favor: solves the general problem. Against it: a heavy dependency, a hard mental model, and it solves a problem this domain doesn't have — nobody is collaboratively editing the same field. It's the right tool for a text editor, not for an order.

### Option D — Don't support offline
Implementation: none. This is the current state. In favor: nothing to build. Against it: the product isn't sellable, and the README itself would have to admit that.

## Decision

Option B. The domain is naturally append-only — an order is a record of things that were requested, in order — and forcing it into that shape isn't a technical concession, it's a more faithful description of what actually happens in the restaurant.

Operations allowed while offline: open an order, add a line, void a line, send to kitchen.
Operations that require connectivity: request payment, charge, close the drawer, close the order. That's acceptable, because for all of them the client is already standing at the register.

## Consequences

**We gain:** the restaurant keeps selling with no network and no line is ever lost on reconciliation. The client's ULID works end to end as an idempotency key, so a network retry never duplicates a dish.

**We lose / accept:** there's no `DELETE` for lines; a void is one more row, with its own reason and author. An order's total is computed by summing additions and voids, not by reading a field. Reports have to distinguish "sold" from "voided" everywhere.

**Changes:** the `order_lines` schema accepts a `client_ulid UNIQUE` and a line type. The sync endpoint is a `POST /orders/{id}/sync` that takes a batch of operations and is idempotent per batch.

## Reversal criteria

This decision has failed if, in a test with two tablets and the network off for 10 minutes, any total diverges on reconciliation. In that case the problem isn't append-only itself but resolving the order's state (for example, two waiters closing it at the same time), and the fix would be a per-device order lock with an expiry — not switching to CRDTs.
