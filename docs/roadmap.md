# Roadmap — 84 sessions

**A "session" is a real 2-to-3-hour block of work**, not a calendar day. At 4 sessions a week the whole project runs about 5 months; at 2 a week, about 10. Adjust the pace, not the scope of each session.

Rules for the plan:

1. **Every session ends with something that runs.** No "pick this back up tomorrow, half-finished."
2. **Every phase ends with a tagged commit** (`v0.1-phase1`) and a README entry. If you stop at phase 3, what's there is still demonstrable.
3. **If a session overruns, split it in two.** Don't carry it over.
4. Each session has a written "done" criterion. If you don't meet it, the session isn't done.

---

## Phase 0 — Design and contracts (sessions 1–5)

The goal is to avoid writing business code before knowing what talks to what. It's the phase most people skip, and the most expensive one to skip.

| # | Goal | Deliverable | Done when |
|---|---|---|---|
| 1 | Solo event storming of the full flow: guest arrives → guest pays and leaves | `docs/domain-events.md` with the business facts as digital sticky notes (Miro or markdown) | You can narrate a restaurant's day using only events |
| 2 | Group events into aggregates and confirm the 7 boundaries | §2 of the technical design validated or corrected | Every event has one, single owning service |
| 3 | Write the event catalog with JSON Schema | `contracts/events/*.json` for the 16 events (includes availability, ADR-0009) | `ajv validate` passes with examples of each one |
| 4 | OpenAPI for `orders` and `catalog` | `contracts/openapi/orders.yaml`, `catalog.yaml` | They render in Swagger UI with no errors |
| 5 | Monorepo skeleton and `docker-compose.yml` with Postgres, Redis, RabbitMQ | `make up` brings up the base infra | All three containers pass their healthcheck |

**Phase deliverable:** a public repo with contracts and diagrams, zero business code. This is already showable.

---

## Phase 0 bis — Language fundamentals (sessions A1–A4)

Numbered separately so they don't shift the rest of the plan. They sit between phase 0 and phase 1, and **they aren't optional**: Go doesn't get learned by writing `payments`; it gets learned first, and `payments` gets written once Go is already familiar. See [ADR-0004](adr/0004-language-selection.md).

| # | Goal | Deliverable | Done when |
|---|---|---|---|
| A1 | Go: syntax, structs, interfaces, errors, goroutines, and channels | A CLI that queries an API and writes to Postgres | You understand why Go has no exceptions, and you're not fighting it |
| A2 | Go: HTTP service layout with `chi`, `pgx`, migrations, tests with Testcontainers | A toy service with CRUD and an integration test | The service starts in under 100 ms and the image is under 30 MB |
| A3 | NestJS: modules, DI, DTOs, WebSocket gateway | A minimal chat app with Socket.IO and JWT auth | Two browsers exchange authenticated messages |
| A4 | Generating types from `contracts/`: quicktype to Go, TS, and PHP | `make contracts` working | Changing a JSON Schema breaks the Go build |

**Phase deliverable:** three disposable toy projects, outside the main repo. Their value is keeping phase 1 from also being a Go tutorial.

---

## Phase 1 — Three services and the gateway, all synchronous (sessions 6–22)

No RabbitMQ yet. The goal is to understand distributed auth and prove the data boundaries hold.

| # | Goal | Deliverable | Done when |
|---|---|---|---|
| 6 | `identity`: Laravel scaffold, multi-stage Dockerfile, tenants/branches/users migrations | A service that responds to `/health` | `docker compose up identity` comes up in under 20s |
| 7 | `identity`: RS256 JWT issuance, JWKS endpoint | `POST /login` returns access + refresh | A token validates against the exposed public key |
| 8 | `identity`: refresh token rotation and reuse detection | Token family invalidated on reuse detection | A test reuses a refresh token and gets 401 across the whole family |
| 9 | `identity`: roles and permissions, demo tenant seed | `make seed` creates a restaurant with 4 users | Each role's permissions appear in the login response |
| 10 | `BelongsToTenant` trait + `TenantContext` + middleware | Shared package in `services/_shared/` | The cross-tenant-leak test returns zero rows |
| 11 | `catalog`: scaffold, categories, products, prices in cents | Working CRUD | Creating a product with no explicit `tenant_id` assigns it automatically |
| 12 | `catalog`: modifiers and modifier groups | A coffee with an alt milk and a size option | The modifier's price adds correctly to the total |
| 13 | `catalog`: menus per branch and price lists | The same product priced differently at two branches | A `GET /menu?branch_id=` returns the correct prices |
| 14 | `orders`: scaffold, tables, opening an order | `POST /orders` opens a check at a table | Two open orders at the same table return 409 |
| 15 | `orders`: adding lines with a **snapshot** pulled from `catalog` over HTTP | A line with name and price frozen | Changing the price in `catalog` doesn't touch the open order |
| 16 | `orders`: Redis cache of the catalog + degradation, plus the shift availability table (ADR-0009) | `orders` works with `catalog` powered off; a product can be marked unavailable without touching `catalog` | Power off `catalog`, add a product, it works; marking "86'd" doesn't write to `catalog` |
| 17 | `orders`: order state machine | Valid transitions documented and enforced | Moving from `closed` to `open` throws a domain exception |
| 18 | `orders`: total calculation, discounts, splitting a check | A check split evenly and by item | Tests for the 6 split cases that don't round evenly |
| 19 | `gateway`: Traefik with label-based routing + JWT validation middleware | A single port 8080 in front of everything | A request with no token gets 401 before reaching the service |
| 20 | `gateway`: BFF aggregating menu + tables + open orders into one call | `GET /bff/pos-home` | The tablet makes 1 request instead of 4 |
| 21 | Producer/consumer contract tests between `orders` and `catalog` | Pact or JSON Schema in CI | Changing a contract field breaks CI |
| 22 | GitHub Actions: build, test, and lint per service with a matrix | Green pipeline on `main` | A push only runs the services that changed |

**Phase deliverable:** a working POS API, no UI, documented in Swagger. Tag `v0.1-phase1`.

---

## Phase 2 — Events, outbox, and the saga (sessions 23–36)

This is where it starts being microservices rather than a monolith cut into pieces.

| # | Goal | Deliverable | Done when |
|---|---|---|---|
| 23 | RabbitMQ: topic exchange, queues, bindings, DLQs per service | `infra/docker/rabbitmq/definitions.json` | Queues and DLQs exist on startup, no manual steps |
| 24 | Shared publishing library in Go and PHP: event envelope and JSON Schema validation | `services/_shared/{go,php}/events/` | Publishing a malformed event throws in development |
| 25 | Outbox table and worker in `orders` (Go) and `catalog` (PHP) | Worker in both languages | Kill RabbitMQ, close 5 orders, revive it, all 5 arrive |
| 26 | Idempotent consumption library in all three languages: `processed_events` | Reusable base consumer per language | Resending the same `event_id` 10 times produces a single effect |
| 27 | `payments` (Go): scaffold, payment methods, charge model | `POST /payments` records a charge | Idempotency by `order_id` verified with a test |
| 28 | `payments`: cash session, opening, movements, count and closing | Cash drawer closed with a computed discrepancy | A short close writes a row to `audit_log` |
| 29 | `payments`: tips, mixed payment, rounding | A check paid with cash + card | Cents balance in all 4 rounding cases |
| 30 | Implement the saga: `payment.requested` → `captured` → `closed` | Full asynchronous flow | Closing a check from Postman triggers the 3 events in order |
| 31 | Compensation: `payment.failed` returns the order to `open` | Unhappy path tested | Force a payment failure, the order becomes editable again |
| 32 | Saga timeout: scheduled job that rescues stuck `pending_payment` orders | `orders.payment.timed_out.v1` | Kill `payments`, at 90s the order returns to `open` |
| 33 | `pending_payment` state locks edits | Order lock | Adding a dish mid-charge returns 409 |
| 34 | DLQ handling: a tool to inspect and reprocess | CLI in Python at `infra/tools/dlq.py` | A poison message can be fixed and reinjected |
| 35 | E2E test of the saga with everything running | Playwright or Pest against Compose | Runs in CI and fails if the saga breaks |
| 36 | Document the saga with a real sequence diagram in the repo | §5 of the technical design with the actual diagram | The diagram matches the code |

**Phase deliverable:** end-to-end checkout with eventual consistency, compensation, and timeout. Tag `v0.2-phase2`. **This is the phase that actually matters in an interview.**

---

## Phase 3 — Inventory, kitchen, and reporting (sessions 37–52)

| # | Goal | Deliverable | Done when |
|---|---|---|---|
| 37 | `inventory` (Go): supplies, units, conversions | Supply CRUD | 1 kg of coffee converts to 50 portions of 20 g |
| 38 | `inventory`: recipes per product | The cappuccino's recipe with 3 supplies | A product with no recipe doesn't break order closing |
| 39 | `inventory`: `order.closed` consumer that deducts stock | Stock drops when an order closes | Resending the event doesn't deduct twice |
| 40 | `inventory`: movements, waste, purchase receipts | A ledger per supply | The computed balance matches the sum of movements |
| 41 | `inventory`: low-stock alerts (`stock.low.v1`) | Event fired when the threshold is crossed | Not fired on every sale, only when crossing the threshold |
| 41b | `inventory`: emit `stock.depleted.v1`; `orders` consumes it and marks affected products | Availability consumer in `orders` | A supply hits zero, the product goes unavailable with no manual step |
| 42 | `reporting` (PHP): denormalized read model, sales table schema | A wide table with names, not references | Deleting `catalog` doesn't affect a historical report |
| 43 | `reporting`: consumer for every event, and the projection | Up-to-date projection | Rebuilding from scratch gives the same numbers |
| 44 | `reporting`: sales-by-day, by-product, by-waiter endpoints | 3 endpoints with date and branch filters | Totals match `payments` to the cent |
| 45 | `reporting`: read model rebuild command | `php artisan projection:rebuild` | Drop the table and rebuild, same totals |
| 46 | `kds-notifications` (NestJS): Socket.IO with JWT auth | Authenticated WebSocket connection | A token from another tenant receives nothing |
| 47 | `kds-notifications`: consuming `item.sent_to_kitchen` and pushing to the tenant's room | Kitchen receives orders in real time | Under 500 ms latency from the tap to the display |
| 48 | `kds-notifications`: mark a dish ready → HTTP to `orders` → push to the waiter | Full kitchen-to-waiter loop | The waiter sees "ready" with no refresh |
| 49 | `apps/pos-web`: Vue 3 + Vite scaffold, login, branch selection | Installable PWA | Installs on a real Android tablet |
| 50 | `pos-web`: table map and order taking | Full waiter flow | A 5-item order can be entered in under 30s |
| 51 | `pos-web`: checkout and closing screen | Full cashier flow | A mixed payment with a tip from the UI |
| 52 | `apps/kds-web`: kitchen screen | Working kitchen display | Two screens stay in sync at the same branch |

**Phase deliverable:** a usable end-to-end product with a UI. Tag `v0.3-phase3`. **This is where you can film the demo video for the README.**

---

## Phase 4 — Observability and resilience (sessions 53–60)

| # | Goal | Deliverable | Done when |
|---|---|---|---|
| 53 | OpenTelemetry across all three languages, exporting to Jaeger | Visible traces | A trace runs from the cashier's request to the inventory deduction |
| 54 | Propagating `traceparent` over HTTP and through the event envelope | Continuous trace across RabbitMQ | The trace doesn't break when crossing the broker |
| 55 | Structured JSON logs with `tenant_id` and `correlation_id` | Identical format across the three languages | Searching by `correlation_id` reconstructs the whole flow |
| 56 | Prometheus + Grafana: the four golden signals per service | Base dashboard | A latency spike shows up on the dashboard |
| 57 | Business metrics: `outbox_pending`, `saga_duration`, `dlq_messages` | Architecture-health dashboard | `outbox_pending` rises when you kill the worker |
| 58 | Exponential backoff retries and circuit breaker on `orders → catalog` | Resilient HTTP client | With `catalog` slow, `orders` opens the circuit and uses cache |
| 59 | Real health checks: liveness vs. readiness per service | `/health/live` and `/health/ready` | `ready` returns 503 if Postgres is unreachable |
| 60 | **Chaos day:** kill services one by one and document what happened | `docs/failure-modes.md` with real results | §8 of the technical design verified empirically |

**Phase deliverable:** dashboards and a failure-modes document backed by evidence. Tag `v0.4-phase4`.

---

## Phase 5 — Local Kubernetes (sessions 61–68)

| # | Goal | Deliverable | Done when |
|---|---|---|---|
| 61 | Local `kind` cluster and namespace | `make kind-up` | 3 nodes running |
| 62 | Service manifests: Deployment, Service, ConfigMap, Secret | `infra/k8s/base/` | All 8 services run in the cluster |
| 63 | Liveness and readiness probes wired to the phase-4 endpoints | Pods that self-heal | Killing Postgres leaves pods `NotReady`, not `CrashLoop` |
| 64 | Ingress + local cert-manager | A single entry hostname | `https://antojopos.local` works |
| 65 | Postgres and RabbitMQ as StatefulSets with a PVC | Data survives restarts | Deleting the pod doesn't lose orders |
| 66 | Kustomize with `dev` and `prod` overlays | One base, two variants | The prod overlay changes replica count and resources |
| 67 | HPA on `orders` based on CPU | Working autoscaling | A k6 load test triggers new replicas |
| 68 | Rolling update with zero downtime | Deploying a new version | A k6 run during the deploy shows no 5xx errors |

**Phase deliverable:** the full system on Kubernetes with autoscaling. Tag `v0.5-phase5`.

---

## Phase 6 — AWS with Terraform and CI/CD (sessions 69–76)

| # | Goal | Deliverable | Done when |
|---|---|---|---|
| 69 | Terraform: VPC, subnets, security groups, remote backend in S3 + DynamoDB lock | `infra/terraform/network/` | `terraform plan` runs clean from scratch |
| 70 | RDS PostgreSQL multi-AZ + Amazon MQ (RabbitMQ) + ElastiCache | Managed data layer | Local services connect to RDS |
| 71 | ECS Fargate or EKS depending on estimated cost | Decision documented in an ADR-0005 | The monthly cost estimate is written down |
| 72 | Deploy the 8 services + ALB + Route53 | A public staging environment | The demo runs on a real URL |
| 73 | Secrets Manager + least-privilege IAM per service | Zero secrets in plain variables | `orders` can't read `payments`'s secrets |
| 74 | Full CI/CD: build, push to ECR, deploy per service | `main`-to-staging pipeline | A merge only deploys what changed |
| 75 | CloudWatch alarms and a budget with a billing alert | Alerts wired to email | An alarm fires in a real test |
| 76 | Automated backups and a **restore drill** | Recovery runbook | You restored a snapshot and verified the data |

**Phase deliverable:** a deployed public demo with reproducible infrastructure. Tag `v1.0`.

---

## Phase 7 — What it takes to charge a customer (sessions 77–80+)

These sessions aren't about architecture, they're about product. See `product-readiness.md` for the full list; here are the first four.

| # | Goal | Deliverable | Done when |
|---|---|---|---|
| 77 | Self-service onboarding: creating a tenant, branch, and starter menu | A restaurant signs up with no help from you | Someone outside the project completes signup alone |
| 78 | Ticket printing: ESC/POS over the network to a thermal printer | A ticket printed from the POS | A real ticket comes out of a real 80mm printer |
| 79 | Offline sync: IndexedDB queue, append-only by ULID | A sale with the network down | Turn off WiFi, take 3 orders, turn it back on, everything arrives |
| 80 | CFDI 4.0 via a PAC, with a swappable provider interface | An invoice stamped in sandbox | A valid stamped XML in the PAC's test environment |

---

## How to know you're on track

| By the end of | You should be able to | If you can't |
|---|---|---|
| Phase 1 | Explain why `orders` stores snapshots instead of joining | Repeat phase 0; the boundaries weren't understood |
| Phase 0 bis | Write an HTTP handler in Go with no tutorial open | Don't move to phase 1; you'll suffer twice as much |
| Phase 2 | Draw the saga from memory, with compensation and timeout | Don't continue; it's the heart of the project |
| Phase 3 | Record a 2-minute video selling the product | Product is missing, not architecture |
| Phase 4 | Debug a production bug using only traces and logs | Observability is decorative |
| Phase 5 | Explain the difference between liveness and readiness with your own example | You copied manifests without understanding them |
| Phase 6 | Recreate the whole environment from scratch with `terraform apply` | There are undocumented manual steps |
