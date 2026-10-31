# ADR-0008: "Instrument" visual identity and the AntojoPOS name

- **Date:** 2026-09-12
- **Status:** Accepted
- **Decided by:** Kevin Aguirre

## Context

The product needed a visual identity before roadmap session 49, where `pos-web` kicks off. Without a resolved color and type system, every component invents its own values, and by the middle of phase 3 there are forty loose hex codes impossible to reconcile.

The working name was *Comanda* — Spanish for a restaurant order ticket. Descriptive and correct within the domain, but for that exact reason impossible to trademark and impossible to position: the word already means something specific inside the product, and using it as the brand too produces ambiguous phrasing ("the order for Order").

The constraints that drove the aesthetics, in order of weight:

1. Cheap 10" Android tablets, in direct sun on a patio and in warm, dim indoor light.
2. Kitchen display read from two meters away, out of the corner of the eye, by someone whose hands are full.
3. Eight-hour shifts staring at the same interface.
4. Thermal printing at 80mm, 203dpi: 1-bit, no grays, no gradients.
5. Six order states that must be told apart without reading and without depending on color.

## Options considered

### Option A — "Instrument": graphite and a single signal color
A neutral graphite-and-paper chrome where no color decorates and exactly one communicates state: a saturated amber-orange reserved for "needs your attention." The mark is a tare line: a solid square with a clean-cut notch, like a scale zeroing out. In favor: because the chrome is neutral, the same identity inverts into a real dark mode for the night shift without becoming a different brand; amber stays constant across both themes. Against it, by its own admission: there's no brand color left over for the website, packaging, or printed material, because the one color is already committed to state. And an owner comparing three vendors on their phone will find this the least eye-catching option at first glance.

### Option B — "Ticket": one ink on paper
Built from the one artifact every restaurant already knows: the printed ticket. Near-black ink on unbleached paper, condensed type in tight columns, rules instead of boxes, and a single green that always means *ready*. The discipline is that the screen and the thermal ticket are the same document. In favor: total conceptual coherence and cheap rendering on weak hardware. Against it: the paper background is darker than white, so in direct sun it loses exactly the top end of the luminance range it needs most — and that condition isn't an edge case, it's the best-selling table at any restaurant in Monterrey.

### Option C — Third direction explored
Ruled out during review for not solving any of the five constraints better than A.

## Decision

**Direction A, "Instrument."** The deciding criterion was context of use, not appeal: Direction B loses contrast in exactly the harshest condition (direct sunlight on a patio), and that condition isn't an edge case — it's the best table in any restaurant.

**Name: AntojoPOS.** Frees up the word *order/comanda* to mean only what it means in the domain.

**Verified, not assumed.** The 23 contrast pairs declared in the tokens were computed: all pass their minimum (4.5:1 for text, 3:1 for UI) in both themes. The values written in the CSS comments are off by up to 0.9 points from the real calculation, almost always on the safe side; they're treated as approximations, not measurements.

The grayscale test was also run on the six states. **It passes, but not because of color.** In light mode, four of the six card backgrounds are identical white (luminance 100.0): open, sent, pending payment, and voided. What separates them is geometry — solid border, dotted rail, 3px frame with a cut corner, 45° pattern — which is exactly what the system claims to do. The two action states do land at opposite extremes: *ready* is a solid field at luminance 16.9, *pending payment* is a white field at 100.0.

## Consequences

**We gain:** a semantic token system (`--state-ready-bg`, not `--green-500`) with two themes that share names and swap values; self-hosted typography across 7 woff2 files (~200KB) with no Google Fonts dependency for a location with spotty internet; and a kitchen scale derived from re-verifiable math (cap height ≥ distance/180, two meters yields a 57px floor).

One decision went beyond what was asked. IBM Plex Mono was chosen for numbers instead of turning on `tnum` on the interface family. A monospace font is tabular by construction, not by an OpenType flag that can silently fail.

**We lose / accept:** the identity has no brand color for marketing. If the project ever crosses into path B of `product-readiness.md` — selling an extracted monolith — it will need a marketing layer with its own color, separate from the product system. It's not being solved now, because designing today for a hypothetical commercial scenario is exactly the mistake that document warns against.

**Changes:** three rules that go into the code, not just the document.

1. `--brand-signal` (#E4571B) gives 3.7:1 on light chrome. It passes as a UI element, **not as text**. That token is never `color`, only marks, pulses, or borders. The rule lives in the CSS, not in anyone's memory.
2. `apps/pos-web/src/styles/tokens.css` is the source of truth. No component writes a hex value. If a color is missing, a token is missing.
3. Minimum touch target is 48px, and the system's actual targets run 76 to 104px. A new component under 48px doesn't get approved.

## Open items

Three questions the deliverable left open that need answers before session 78 (ticket printing):

- Does any location print on 58mm paper? That's a 32-column grid instead of 48, i.e. a second ticket layout, not a tweak.
- Does invoicing live in a shared domain, or does each location use its own portal? Changes the ticket footer.
- The positioning line promises a new waiter can take their first order in ten minutes with no training. If that can't be backed by a real test, soften it to "in their first shift" before publishing it.

## Reversal criteria

This decision has failed if, testing with real waiters in session 50, they can't tell *open* apart from *pending payment* at a glance across the room. In grayscale those two states are separated only by stroke weight and the corner notch, which is the thinnest margin in the whole system.

Plan B in that case: give *pending payment* a background difference, not just a border one — a sunken field or its own pattern — trading some of the chrome's cleanliness for a separation that survives distance.
