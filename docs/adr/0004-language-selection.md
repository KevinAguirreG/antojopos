# ADR-0004: Three languages, assigned by each service's actual needs

- **Date:** 2026-09-11
- **Status:** Accepted
- **Decided by:** Kevin Aguirre

## Context

The project exists to practice distributed architecture (ADR-0001). Keeping all eight services in Laravel would satisfy the architecture goal but waste one of the few real advantages of microservices: that each service can use the tool its problem calls for.

There's a stated secondary goal: broadening the technical repertoire beyond PHP, where there's already ~3 years of professional experience.

The constraint that shapes this decision is the **cross-cutting tax of being polyglot**. Every new language means reimplementing and maintaining seven pieces:

1. JWT validation against JWKS
2. Tenant context and its isolation
3. The outbox pattern with guaranteed publishing
4. An idempotent consumer with `processed_events`
5. OpenTelemetry instrumentation with context propagation
6. Structured JSON logging with the agreed-upon fields
7. Event-envelope validation against a JSON Schema

With one language that gets written once. With four, four times, and every bugfix gets replicated four times. That cost is linear and permanent, and it's why "one language per service" is an anti-pattern no matter how much it sounds like freedom.

## Options considered

### Option A — Everything in Laravel
Implementation: S. In favor: the cross-cutting tax is paid once; maximum velocity. Against it: adds nothing new to the repertoire and wastes the one free technical advantage of this architecture. `kds-notifications` is also poorly served: PHP-FPM isn't the right model for long-lived WebSocket connections.

### Option B — One language per service (eight languages)
Ruled out. Eight implementations of the cross-cutting tax for one person. Produces a repo that looks like a résumé, not a system.

### Option C — Three languages assigned by each service's needs
Implementation: M. Go, TypeScript, and PHP, assigned by what each service actually demands. In favor: every choice is defensible in an interview without appealing to "I wanted to learn it"; the tax gets paid three times, which is sustainable. Against it: three toolchains, three CI pipelines, three ways of debugging.

### Option D — Two languages: Laravel + Go
Implementation: M. In favor: half the tax of Option C. Against it: leaves `kds-notifications` in Go, where WebSocket ergonomics are worse than Node's, and rules out TypeScript, which would otherwise share types with the Vue frontend.

### Option E — Kotlin + Spring Boot instead of Go
Implementation: L. In favor: it's the dominant corporate stack in Europe, and Spring demand there significantly outweighs Go's. Against it: double the learning cost (JVM, Gradle, the whole Spring universe), startup times that hurt autoscaling, and zero overlap with the ongoing AWS and Kubernetes roadmap.

## Decision

Option C, with this assignment:

| Service | Language | Technical reason, not taste |
|---|---|---|
| `identity` | PHP / Laravel 12 | Authentication, roles, and CRUD. A mature framework where security risk is highest |
| `catalog` | PHP / Laravel 12 | Pure CRUD with complex relationships. Eloquent solves this faster than anything else |
| `orders` | **Go 1.23** | The highest-load service. Strict typing over the state machine; millisecond startup for phase-5 autoscaling |
| `payments` | **Go 1.23** | Money. Explicit types over cents and errors that can't be silently ignored |
| `inventory` | **Go 1.23** | A pure event consumer. Native concurrency for processing multiple queues |
| `reporting` | PHP / Laravel 12 | Projection and queries. Isolated from every saga, so the lowest-risk spot |
| `kds-notifications` | **TypeScript / NestJS** | Long-lived WebSockets. PHP-FPM is the wrong model; Node's event loop is the right one |
| `gateway` (BFF) | **TypeScript / NestJS** | Shares generated contract types with the Vue frontend |
| `pos-web`, `kds-web` | TypeScript / Vue 3 | — |

**Python is deliberately kept out of the services.** Its place in this project is infrastructure tooling: operational scripts, load testing with Locust, DLQ reprocessing utilities, test data generation. Adding it as a fourth service language would add a fourth copy of the cross-cutting tax for nothing Go or TS don't already provide.

**How the tax gets paid without it hurting:** the seven pieces are generated or derived from `contracts/`, not hand-written three times.

- Event types are generated from JSON Schema: `quicktype` produces Go structs, TS interfaces, and PHP classes from the same source.
- A contract change regenerates all three and breaks the build for whoever hasn't updated — that's exactly the intended behavior.
- Outbox and the idempotent consumer are implemented once per language, in `services/_shared/<language>/`, never inside a service.
- OTel and logging are configured through the official library, mature in all three.

## Consequences

**We gain:** every language choice is backed by a technical argument, not "I wanted to learn it." Go gets in through the door that pays off most: it's the language Docker, Kubernetes, Terraform, and Prometheus are written in — exactly the tools the current roadmap is chasing. TypeScript shares types between the gateway and the frontend.

**We lose / accept:** three toolchains, three base images, three CI jobs, three ways to debug. The first month in Go will be slower than a month in Laravel, and that needs to be budgeted for. Shared code gets duplicated three times even when generated from a single source.

**Changes:** the roadmap needs two extra sessions before phase 1 for Go fundamentals, and one for NestJS. `payments` doesn't get written to learn Go; it gets written once Go is already known.

## Reversal criteria

This decision has failed if, by the end of phase 2 (session 36), either of these hold:

- The Go services systematically take more than 3x as long as the Laravel ones to implement the same feature. That means the learning curve isn't being overcome and the project is going to stall.
- A fix to the outbox pattern or the idempotent consumer takes more than one session to propagate across all three languages. That means the shared code isn't factored well.

Plan B: consolidate `inventory` and `reporting` into Laravel, keeping Go only for `orders` and `payments`, which benefit most from strict typing. TypeScript stays in `kds-notifications` without question: there's no reasonable alternative there.
