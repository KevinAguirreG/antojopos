---
description: Starts a roadmap session by its number. Reads the matching row, proposes a plan, and doesn't write code until you approve it.
disable-model-invocation: true
argument-hint: <session number, e.g. 14 or A2>
---

## Roadmap row

!`grep -E "^\| $ARGUMENTS \|" docs/roadmap.md || grep -E "^\| $ARGUMENTS \|" docs/roadmap.md`

## Repo state

!`git log --oneline -5 && echo "---" && git status --short`

---

We're working session **$ARGUMENTS**. The row above has the goal, the
deliverable, and the done criterion.

Before writing anything:

1. Say in two or three sentences what you're going to do and which files
   you're going to touch.
2. Name any decision the row leaves open, and propose one with its reasoning.
3. If the session crosses three or more services, stop: that's a sign the
   boundary might be wrong. Say so before continuing.
4. Wait for my go-ahead.

When you're done, check it against the row's done criterion — the literal
one, not an approximation — and against the CLAUDE.md checklist. Report what
passed and what didn't.
