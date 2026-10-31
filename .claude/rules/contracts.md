---
paths:
  - "contracts/**"
---

# Working in contracts/

This is the agreement between services, not any one service's property. A
change here breaks someone else by definition.

Before touching any file:

1. Say which services produce and consume whatever you're about to change.
2. If the change isn't additive, don't edit the schema: create the next
   version (`order.closed.v2`) and keep v1 alive until every consumer has
   migrated. Events get versioned, not corrected.
3. After any change, run `make contracts` to regenerate the types in Go,
   TypeScript, and PHP, and report what stopped compiling. Breaking is correct.

Fields that never get removed from an event envelope: `event_id`, `event_type`,
`occurred_at`, `tenant_id`, `correlation_id`, `causation_id`, `producer`.
