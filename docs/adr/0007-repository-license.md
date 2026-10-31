# ADR-0007: PolyForm Noncommercial license, with commercial licenses sold separately

- **Date:** 2026-10-31
- **Status:** Accepted
- **Decided by:** Kevin Aguirre

## Context

The repository is about to go public, and the roadmap's phase 0 deliverable is a public repo. Two goals pull in different directions:

1. **Portfolio.** Anyone (a recruiter, an interviewer) has to be able to read the whole code, clone it, and run it.
2. **A future product.** If a restaurant wants to use AntojoPOS, it should pay for it. Phase 7 and `product-readiness.md` keep that door open on purpose.

Without a license, the code is "all rights reserved": readable on GitHub, but nobody can legally run it. That protects the commercial goal and hurts the portfolio one.

What makes this decision cheap: as the sole author, the copyright holder can always grant separate licenses to anyone. The public license only defines what's free for people who haven't paid. It doesn't limit what can be sold.

## Options considered

### Option A — MIT or Apache 2.0
Implementation: trivial. In favor: maximum portfolio friendliness, the conventional choice. Against it: kills the commercial goal. Anyone, a competitor included, can host it and sell it without paying anything or publishing changes.

### Option B — AGPL-3.0 plus a commercial license (dual licensing)
Implementation: S. In favor: real, OSI-approved open source. Companies that don't want the copyleft obligations buy a commercial license. Against it: a restaurant can legally run it for free, because the AGPL only obliges it to publish its changes, and a restaurant has none. The model only bites on companies that modify and redistribute, which isn't who a POS gets sold to.

### Option C — Business Source License 1.1
Implementation: S. In favor: blocks production use without a license, it's well known (MariaDB, and CockroachDB and HashiCorp in the past), and the README already pointed at it. Against it: it has parameters to fill in (additional use grant, change date, change license), and a badly worded grant opens holes. Every version converts to open source after at most four years, which only makes sense if community ownership is a goal. It isn't one here.

### Option D — PolyForm Noncommercial 1.0.0
Implementation: trivial. A fixed text with no parameters: any noncommercial use is allowed, and anything commercial needs a separate license. In favor: says exactly what's wanted, with nothing to misconfigure, and never converts on its own. Against it: less known than BSL. It also allows free use by noncommercial organizations, which see below.

## Decision

Option D. A restaurant using the software to take orders and charge customers is commercial use, so it needs a license. Reading, studying, cloning, running it for an interview, and personal experiments stay free. That's exactly the line between the two goals, drawn by a standard text instead of a custom grant.

The `LICENSE.md` file carries a `Required Notice:` line naming the copyright holder, which the license requires to be kept in any copy.

## Consequences

**We gain:** a public repo that's fully readable and runnable for portfolio purposes, and a legal basis to charge any business that uses it. Selling is just signing a commercial license with that customer, with no relicensing and no change to the repo.

**We lose / accept:**
- **It isn't open source** by the OSI definition. The README and any talk about the project say "source-available," never "open source."
- **Noncommercial organizations use it for free:** schools, charities, and government institutions. A school cafeteria qualifies. That's an accepted cost: none of them are the target customer.
- **Outside contributions need a CLA.** Code from a contributor stays theirs, and without a contributor license agreement it can't be included in a commercial license freely. Until a CLA exists, outside pull requests don't get merged.
- **Dependencies** (Laravel, Go modules, NestJS, Vue) are MIT, BSD, or Apache. All of them allow this. A future GPL or AGPL dependency would conflict and needs checking before it gets added.

## Reversal criteria

Revisit if the commercial goal is dropped: at that point Option A (MIT) maximizes the portfolio value with nothing left to protect. Also revisit if real customers object to a non-standard license during procurement. Then BSL, being better known, becomes worth its configuration cost.

Changing the license doesn't revoke it for copies already published under this one. That's a reason to decide before the first public push, not after.
