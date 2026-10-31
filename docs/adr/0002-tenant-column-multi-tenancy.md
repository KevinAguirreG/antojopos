# ADR-0002: Multi-tenancy via a tenant column

- **Date:** 2026-09-11
- **Status:** Accepted
- **Decided by:** Kevin Aguirre

## Context

A multi-tenant SaaS where each tenant is a restaurant with 1 to 5 branches. The expected profile is many small tenants: hundreds of restaurants each producing a few thousand orders a month, not a handful of huge customers.

The system has seven databases (one per service). Any isolation strategy gets multiplied by seven, which weighs on this decision more than it would in a monolith.

Business requirement: a departing restaurant must be able to take its data and disappear from the system within 24 hours.

## Options considered

### Option A — `tenant_id` column with a global scope
Implementation: S. Operations: zero extra. One database per service, shared by every tenant. In favor: migrations run once per service; infra cost doesn't grow with each new customer; onboarding a tenant is an `INSERT`. Against it: a query that bypasses the scope leaks data between restaurants, which is the worst possible incident for this product.

### Option B — Database per tenant
Implementation: M. Operations: **high and growing** — with 50 tenants that's 350 databases (50 × 7 services) to migrate on every deploy. In favor: strong isolation; deleting a tenant is a `DROP DATABASE`. Against it: the database count becomes unmanageable for one person; dynamic connections needed in every service and every event consumer; the connection pool becomes a real problem.

### Option C — One application per tenant
Ruled out with no analysis. Cost scales linearly per customer, incompatible with a single developer.

### Option D — Tenant column + PostgreSQL Row Level Security
Implementation: M. Same as A, plus RLS policies the engine enforces even if the application fails. In favor: isolation stops depending on discipline. Against it: complicates seeds, migrations, and debugging; and requires managing `SET app.tenant_id` on every connection, including queue workers.

## Decision

Option A for phases 1 through 6, migrating to Option D in phase 7, before the first paying customer.

The reason: during development, the risk of a cross-tenant leak is theoretical and the cost of RLS is real. The moment two restaurants' data actually coexist, that balance flips.

## Consequences

**We gain:** one migration per service, instant onboarding, flat infra cost, simple local development.

**We lose / accept:** isolation depends on the global scope never being bypassed. `withoutGlobalScopes()`, `DB::raw()`, and event consumers are the three places it can break.

**Changes:** three mandatory, non-optional defenses:
1. An architecture test that fails if any model doesn't use the `BelongsToTenant` trait.
2. A functional test that, authenticated as tenant A, walks every public endpoint trying to read tenant B's resources and expects a 404 or zero rows.
3. In event consumers, `TenantContext` is populated from the message envelope, never from the payload.

## Reversal criteria

This decision has failed if **a single** cross-tenant data leak occurs in production. There's no second strike: at that point RLS is enabled immediately across every service, and if the incident involved billing data, per-tenant databases get evaluated for the affected customers.

Early warning sign, before an incident happens: if code review turns up two or more uses of `withoutGlobalScopes()` outside admin commands, move the RLS phase up.
