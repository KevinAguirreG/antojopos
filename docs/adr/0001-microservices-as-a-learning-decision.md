# ADR-0001: Adopt microservices as a learning decision, not an engineering one

- **Date:** 2026-09-11
- **Status:** Accepted
- **Decided by:** Kevin Aguirre (sole developer)

## Context

A personal project: a POS SaaS for restaurants and cafés. One developer, working in spare time. Zero users today. Zero real scale requirements: an independent restaurant produces on the order of 200 orders a day, which is negligible traffic for any stack.

The project's stated goal is to **practice microservices architecture** and produce a demonstrable artifact on GitHub. There's a secondary, explicitly subordinate goal: the possibility of selling it to real customers later.

Given that context, the orthodox technical recommendation is unambiguous: a modular monolith in Laravel. The team is one person, there's no deployment-coupling problem, and no component has a distinct scaling profile. Microservices solve organizational and scaling problems; neither exists here.

## Options considered

### Option A — Modular monolith in Laravel
Implementation: M. Operations: minimal — one deployment, one log, one database. Ships sooner and runs itself. Against it: it exercises none of what the project wants to learn (sagas, eventual consistency, orchestration, distributed tracing). As a portfolio piece, indistinguishable from twenty other Laravel CRUD apps.

### Option B — Microservices with real boundaries
Implementation: L. Operations: high and ongoing — eight deployments, eight sets of logs, a broker, contracts between services, eventual consistency with compensation. In favor: it's exactly the material the project wants to practice, and it fills the gaps in the ongoing Cloud/DevOps roadmap (Kubernetes, distributed observability, non-trivial IaC). Against it: the cost of every new feature multiplies by 2–3x, and infra cost goes from ~$25 to ~$180/month with only a few customers.

### Option C — Modular monolith with boundaries ready to extract
Implementation: M. One repo, modules with public service interfaces, tables separated by domain, internal events. Services get extracted later if needed. In favor: the best of both worlds if the project gets commercialized. Against it: it doesn't force any of the hard problems to get solved — transactions stay local and consistency stays strong. You learn the vocabulary without paying the price, and that's exactly where the learning lives.

### Option D — Do nothing
Keep studying microservices in theory. This was already tried in the SmartFactory ERP project, where the 7-service design was never actually deployed to a real environment. The conclusion from that experience is that without implementation there's no verifiable learning.

## Decision

Option B, with the nature of the decision stated openly in the README.

The reason: the project's goal isn't to deliver the best possible POS with the least effort — it's to learn how to operate a distributed system. Choosing Option A optimizes a metric this project isn't chasing.

Being upfront about it in the README is part of the decision, not decoration. A repo that presents eight services for a restaurant CRUD with no explanation tells a technical reader the author doesn't know how to size a system. The same repo, with an ADR that argues the choice and names its cost, tells the opposite story.

## Consequences

**We gain:** real practice with sagas, outbox, idempotency, versioned contracts, distributed tracing, and Kubernetes. A portfolio artifact that can carry an hour-long technical conversation.

**We lose / accept:** the project takes 2–3x longer to become usable. AWS infra cost rises in a way that's only justified once customers are paying. One person running eight services can't sustain a commercial SLA.

**Changes:** every feature requires thinking about which service it lives in and which contract it touches. No cross-service joins, ever. No transaction spans two services.

## Reversal criteria

This decision has failed if, by the end of phase 3 (session 52), any of these hold:

- A typical feature requires touching four or more services.
- The local environment takes more than 3 minutes to start and stops being used for development.
- More than two synchronous HTTP calls appear between business services besides `orders → catalog`.

Plan B: collapse `catalog`, `inventory`, and `reporting` into `orders` as modules, keeping the split for `identity`, `payments`, and `kds-notifications`. Still a defensible distributed system, at half the operational cost.
