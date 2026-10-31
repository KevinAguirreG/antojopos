# Architecture Decision Records (ADR)

Each ADR says **what we decided, why, and what we gave up**. Its value shows up a year later, when someone asks "why is this like this?" and the alternative is archaeology in the git history.

ADRs don't get deleted or edited when a decision changes: they get marked **Superseded by ADR-NNNN**, and a new one gets written. The history of bad decisions is part of the value.

| # | Decision | Status |
|---|---|---|
| [0001](0001-microservices-as-a-learning-decision.md) | Microservices as a learning decision, not an engineering one | Accepted |
| [0002](0002-tenant-column-multi-tenancy.md) | Multi-tenancy via a tenant column, with RLS in phase 7 | Accepted |
| [0003](0003-offline-append-only-strategy.md) | Offline sync via append-only lines with a client-generated ULID | Proposed |
| [0004](0004-language-selection.md) | Three languages (Go, PHP, TypeScript) assigned by service need | Accepted |
| [0008](0008-visual-identity.md) | "Instrument" visual identity and the AntojoPOS name | Accepted |
| [0009](0009-product-availability.md) | `orders` owns shift-level availability; `catalog` owns the definition | Accepted |

## Still to write

| # | Decision | When |
|---|---|---|
| 0005 | RabbitMQ instead of Kafka | Session 23 |
| 0006 | ECS Fargate vs. EKS, with the cost estimate | Session 71 |
| 0007 | Repository license (MIT vs. BSL) | Before publishing it |
