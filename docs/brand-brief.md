# Visual Identity Brief — Prompts for Claude Design

Four prompts in sequence, not one. A single prompt asking for logo, palette, typography, and components at once produces four mediocre things that don't talk to each other. Run one, review it, then move to the next in the same session so it keeps the context.

Before starting, two decisions that only you can make, and that change everything downstream:

- **The name.** The prompts use *AntojoPOS*, which is the final name. If you change it, change it in all four.
- **The personality.** The brief is written as a *reliable work tool*, not a *modern startup*. If you want the other register, the personality block in prompt 1 is the only thing that needs rewriting — but read it first, because the case for that choice is right there.

---

## Prompt 1 — Direction and identity

```
I need the visual identity for AntojoPOS, a point-of-sale SaaS for
independent restaurants and cafés in Mexico.

CONTEXT OF USE (this outranks any aesthetic preference):

- Used by waiters on cheap 10" Android tablets, held in one hand and tapped
  with the other, sometimes with wet or greasy hands.
- Used on patios in direct sunlight and indoors under warm, dim light.
  Contrast has to survive both conditions.
- The kitchen display is read from two meters away, out of the corner of
  the eye, by someone whose hands are busy.
- The buyer is a restaurant owner with one to five locations, not a CTO.
  They need to trust this won't fail on a Saturday at 9pm.
- A shift runs eight hours and the interface is on screen the whole time.
  Nothing that tires the eyes, nothing loud.

BRAND PERSONALITY:

Three adjectives: reliable, fast, unobtrusive.

What it is NOT: innovative, disruptive, premium, playful, artisanal. This
product doesn't compete on excitement. It competes on staying out of the
way. The right aesthetic is that of a well-made tool — a professional
kitchen scale, a bank terminal — not a consumer app.

WHAT I NEED AT THIS STEP:

1. Three distinct visual directions, not variations on one. Each with:
   a concept paragraph, a 5-color palette with hex values, a type pairing,
   and a sketch of the mark.
2. For each direction, explicitly state what it trades off.
3. Your recommendation for which one best serves the context of use
   above, with the reasoning.

MARK CONSTRAINTS:

- Must work at 24×24 px as a favicon and app icon.
- Must print legibly on an 80mm thermal printer, which is 1-bit: black or
  nothing, no grays, no gradients, at 203 dpi.
- Must read in white on a dark background and in black on a light one.
- A single shape, no text inside it.

CLICHÉS I DON'T WANT TO SEE:

Chef's hat, crossed cutlery, a covered plate, a decorative QR code, a chat
bubble, a generic purple-blue SaaS gradient, a friendly rounded typeface.

Work in English. Color notes and names can stay in English since you'll
likely use them as code tokens.
```

---

## Prompt 2 — Color system and states

Run this after picking one of the three directions.

```
Let's go with direction [N]. Now the full color system.

An order moves through six states, and a waiter has to tell them apart
at a glance, from across the room, without reading:

  open · sent to kitchen · ready to serve · pending payment ·
  closed · voided

SYSTEM RULES:

1. Color is NEVER the only carrier of meaning. Every state is also told
   apart by shape, icon, or position. Two reasons: some waiters are
   colorblind, and cheap tablets distort color unpredictably.
2. Minimum contrast ratio 4.5:1 for text, 3:1 for UI elements. Verify it
   and show the number for each pair.
3. "Ready to serve" and "pending payment" are the two states that trigger
   an immediate action. They need to be the most salient of the six, and
   unmistakable from each other.
4. "Voided" should read as neutral, not as an error. Cancelling an order
   is a normal operation, not a failure.

DELIVERABLES:

- A full palette with semantic tokens, not descriptive ones. I want
  `--state-ready-bg`, not `--green-500`. The name should say what it's
  for.
- A 10-step neutral scale for surfaces, borders, and text.
- A light theme for the waiter's POS and a dark theme for the kitchen
  display, sharing the same token names with different values.
- Feedback colors: success, warning, error, info.
- A sheet showing all six states side by side, in both themes, at real
  card size.
- Exported as CSS variables.

TEST IT HAS TO PASS:

Show me the state sheet in grayscale. If two states become confusable
with no color, the system isn't done.
```

---

## Prompt 3 — Typography and components

```
Let's continue with typography and the four core components.

TYPOGRAPHY:

- One interface typeface, legible at 14px on cheap screens, with good
  Spanish support (accents, ñ, ¿, ¡). Free and self-hostable: I can't
  depend on Google Fonts at a location with spotty internet.
- Numbers with **tabular figures, mandatory**. Prices stack in a column
  and have to align on the decimal point. A typeface with proportional
  figures disqualifies the whole option, no matter how nice it looks.
- A 6-level type scale with line-height, for a touch screen, not for
  long-form reading.
- A separate, much larger size for the kitchen display, read from two
  meters away.

COMPONENTS (give me each in its states: default, pressed, disabled,
loading):

1. Product button for the menu grid. Minimum touch area 48×48 px,
   ideally 64. Has to fit a long name ("Double-shot decaf cappuccino")
   without breaking, with the price aligned. Show me the grid with 12
   products.

2. Order card on the table map. Shows: table number, state, elapsed
   time, running total, waiter. Elapsed time is the most-checked piece
   of information: if a table has been sitting 40 minutes with no food,
   someone needs to see it without hunting for it.

3. Checkout numpad. Big keys, room for a thick finger, and the amount
   tendered and the change due in a size that's impossible to misread.
   Change is the number that produces the most expensive mistakes on a
   POS.

4. Kitchen display card. Read from two meters away: dish, table,
   modifiers, time in queue. Modifiers ("no onion") have to be
   impossible to miss, because that's where the customer complaint is
   born.

GENERAL CONSTRAINT:

No animations over 150ms, no decorative transitions. The tablet is slow
and the waiter is in a hurry. If an animation doesn't communicate a
state change, cut it.
```

---

## Prompt 4 — Brand applications

```
Let's close with the applications where the identity leaves the screen.

1. 80mm thermal ticket. 1-bit design — black only, no grays or
   gradients — at 203 dpi, 48 characters wide in a monospace font. Must
   include the logo, business info, line items with quantity and price,
   subtotal, tax, total, payment method, and a footer with the order
   number. Show it at actual size.

2. Favicon and app icon, at 16, 32, 180, and 512 px. Show me the 16px
   one at the size it's actually seen, not zoomed in.

3. POS login screen, on a landscape 1280×800 tablet.

4. Manager dashboard header, with a branch selector.

5. A single-page summary sheet: logo, palette with tokens, typography,
   and the six states. This sheet is what goes in the repo's README, so
   it has to explain itself.

6. Three lines of homepage positioning copy. Concrete and about the real
   benefit, not adjectives. "Keeps selling even when the internet goes
   down" communicates something; "the complete solution for your
   business" doesn't communicate anything.
```

---

## What to do with the output

The summary sheet from item 5 goes in the README. The CSS tokens from prompt 2 go to `apps/pos-web/src/styles/tokens.css` and are the source of truth: no component ever writes a hex value by hand. If a component needs a color that doesn't exist as a token, a token is missing — nothing else is.

Save the chosen direction and the reasoning in `docs/adr/0008-visual-identity.md`. Six months from now you'll want to know why you ruled out the other two.
