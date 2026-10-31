---
paths:
  - "services/identity/**/*.php"
  - "services/catalog/**/*.php"
  - "services/reporting/**/*.php"
  - "services/_shared/php/**/*.php"
  - "**/*.blade.php"
---

# Laravel conventions

- Domains in `app/Domains/<Name>/` with invokable Actions. One domain calls
  another only through its public service, never through its Eloquent model.
- All validation in a FormRequest. All authorization in a Policy. No exceptions:
  an `if ($user->role === 'admin')` inside a controller is a bug.
- Every model uses the `BelongsToTenant` trait. If a new model doesn't have it,
  the architecture test fails — and it should.
- `withoutGlobalScopes()` only inside admin commands, with a comment explaining
  why. See ADR-0002.
- Money as an integer in cents. No cast to `decimal` or `float`.
- Tests with Pest. A test that only checks Eloquent persists something adds
  nothing; test the rules: totals, check splitting, transitions, tenant isolation.
