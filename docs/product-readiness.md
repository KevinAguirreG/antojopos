# From Portfolio Repo to Sellable Product

A repo with good architecture and a product a restaurant will pay for are two different things. This document is the honest list of what separates one from the other, so the decision to cross that line gets made with information.

---

## 1. What a real restaurant demands on day one

None of these are negotiable. A POS without them doesn't get bought, no matter how well-architected it is.

| Requirement | Why | Phase |
|---|---|---|
| **Keeps selling with no internet** | The network drops weekly at peak hours, not exceptionally | 7 |
| **Prints tickets on a thermal printer** | No ticket, no sale; ESC/POS over network or USB | 7 |
| **A cash count that balances to the cent** | It's the operation the owner reviews every single day | 2 |
| **CFDI 4.0 e-invoicing** | In Mexico this is a legal requirement, not a feature | 7 |
| **Boots in under 5 seconds on an old tablet** | The restaurant's hardware isn't getting replaced for your software | 3 |
| **Migrating the current menu** | Nobody types 200 products by hand; needs an Excel import | 7 |
| **Support that answers the phone at 10pm on a Saturday** | This isn't software anymore, it's personal commitment | — |

The last one is the one that decides whether this is a business. Selling POS software means selling **availability**, and one person can't provide it to ten restaurants. That limit is real and it's worth being clear about it before signing the first contract.

---

## 2. Legal and tax (Mexico)

| Topic | What it implies |
|---|---|
| CFDI 4.0 | Integration with an authorized PAC (Facturama, SW Sapien, Finkok). Per-stamp cost |
| CSD custody | Encrypted at rest, access audited. If a CSD leaks, the customer can receive fake invoices under their name |
| LFPDPPP (Mexican data protection law) | Privacy notice, data-subject rights, and an actual procedure for deleting a departing tenant's data |
| Service contract | SLA, maintenance windows, liability cap, ownership of the customer's data on termination |
| Card payment receipts | If you integrate a card terminal, PCI-DSS enters the picture. **Recommendation: don't integrate it.** Use a separate bank terminal and log the payment as a reference |

The last row matters: integrating card payments inside the POS multiplies the regulatory complexity. Logging the charge as "card, auth 4421" and letting the bank's terminal handle the charge on its own is what most small POS systems do, and it's the right call here.

---

## 3. Operational gaps the repo doesn't show

| Gap | Effort |
|---|---|
| Full self-service onboarding | M |
| Billing the customer for the SaaS itself (recurring charges, suspension on non-payment) | M |
| An admin panel for you: view tenants, usage, incidents | S |
| Full data export for a tenant that's leaving | S |
| Incident runbook and on-call | S but ongoing |
| Documentation and training video for waiters | M |
| A staging environment separate from production | S |
| A data retention and deletion policy | S |

---

## 4. The decision worth making consciously

The microservices architecture and the commercial goal **pull in opposite directions**:

| | Microservices | Modular monolith |
|---|---|---|
| Portfolio value | High — demonstrates sagas, events, k8s | Medium |
| Infra cost with 3 customers | ~$180/month | ~$25/month |
| Time to add a feature | 2–3× more | Baseline |
| Debugging at 11pm on a Saturday | Distributed traces, 8 logs | One log |
| Time to first customer | 8–10 months | 3–4 months |

There are three paths, and all three are defensible:

**A. Pure portfolio.** Finish phases 0–6, deploy the demo, write about the process, and don't sell it. Value: interviews, positioning, the Kubernetes and saga practice your roadmap is missing. Cost: ~$15/month for a small demo.

**B. Sell the monolith, show the microservices.** After phase 3, extract the domain into a monolithic Laravel app (the business code carries over almost intact, because the boundaries are already clean) and sell that instead. The microservices repo stays as an architecture project. It's more total work, but each version does its own job well.

**C. Sell the microservices.** Only makes sense with a partner handling support, or a first customer paying for custom development. With one person running eight services for restaurants that call on weekends, the model doesn't hold up.

**Recommendation: A, with the door open to B.** Start with the portfolio — that's the stated goal, and it pays off sooner. If a genuinely interested restaurant shows up by phase 3, one that already told you a price it would pay, evaluate B then, with real information instead of a hypothesis.

What you **shouldn't** do is design today for scenario C. That's the path where the project grows past the point of ever getting finished, and then it serves neither as a sale nor as a showcase.

---

## 5. Signals that it's worth crossing into product

Don't cross because you're excited. Cross when all three of these hold:

1. A specific restaurant told you a monthly price it would pay, without you proposing it first.
2. That restaurant let you observe a full shift and you took notes.
3. You have a real plan to cover weekend support for six straight months.

If any of the three is missing, stay on path A. The project loses nothing by waiting.
