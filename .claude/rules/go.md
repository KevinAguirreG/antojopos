---
paths:
  - "services/orders/**/*.go"
  - "services/payments/**/*.go"
  - "services/inventory/**/*.go"
  - "services/_shared/go/**/*.go"
---

# Go conventions

Layout: `cmd/api`, `cmd/worker`, `internal/domain`, `internal/app`, `internal/infra`.
`internal/domain` imports nothing from `internal/infra`. If it needs to talk to the
outside world, define an interface in `domain` and implement it in `infra`.

- No heavy web framework: `chi` and the standard library. `pgx` for Postgres.
- Errors always wrapped: `fmt.Errorf("closing order %s: %w", id, err)`.
  Never `_ = err`. Never a `panic` outside `main`.
- Money is its own type over `int64` in cents (`money.Cents`), not a bare `int`.
  That makes it impossible to accidentally add cents to the wrong unit.
- Order states are a type with constants, not strings. Valid transitions live
  in a single domain method.
- Context as the first parameter in every function that does I/O — always `ctx`.
- Tests with `testify/require` and Testcontainers for anything touching Postgres.
  A domain test doesn't spin up containers.
- Event structs are generated from `contracts/events/`. Don't hand-write them.
