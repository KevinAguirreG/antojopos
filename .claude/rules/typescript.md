---
paths:
  - "services/gateway/**/*.ts"
  - "services/kds-notifications/**/*.ts"
  - "apps/**/*.ts"
  - "apps/**/*.vue"
---

# TypeScript conventions

- NestJS: one module per area. DTOs with `class-validator`. Controllers hold
  no logic, they only orchestrate.
- Contract types come from what `make contracts` generates. Hand-redefining an
  event type is a contract bug.
- `strict: true`. No `any` — if you need it, use `unknown` and narrow explicitly.
- The KDS keeps its socket scoped to tenant and branch. No message ever leaves
  its room.
- Frontend: colors come from `apps/pos-web/src/styles/tokens.css`. No component
  writes a hex value. If a color is missing, a token is missing (ADR-0008).
- Minimum touch target 48px. The system's actual targets run 76 to 104px.
- `--brand-signal` is never text color: it gives 3.7:1. Marks, pulses, or
  borders only.
