# Working Notes

Append-only log of project memory. Read the relevant section when triggered; write back when you discover something future agents need to know.

---

## Known bugs

Current bugs in the codebase. Read when working on or near a flagged area.

Also use for **known limitations** — things that aren't bugs per se but will need addressing eventually (e.g., "no pagination on runs list, breaks at 1000+ rows"). Mark these with `Status: Open`.

**Format:**

```
### [Title]
- **Status:** Open / Has-workaround / Wontfix
- **Symptoms:** what the user sees
- **Trigger:** when it happens
- **Workaround:** if any
```

_(none yet)_

---

## Dead ends

Approaches tried that didn't work. **Read before attempting an approach that may have been tried before.** Add an entry here when an attempt fails so the next agent doesn't repeat it.

Also use for **open questions** — things you're still figuring out. Set `Did instead: still open` and update the entry once resolved.

**Format:**

```
### [YYYY-MM-DD] — [Approach]
- **Goal:** what we were trying to do
- **Tried:** what we did
- **Failed because:** root cause
- **Did instead:** what we ended up doing (or "still open")
```

_(none yet)_

---

## Gotchas

Library / API / infrastructure quirks discovered the hard way. The kind of thing that's not in any official doc but bit someone.

**Format:**

```
### [Library or area]: [The quirk]
- **What:** the surprising behavior
- **Where it bit us:** context
- **Mitigation:** what to do
```

_(none yet)_

---

## Decisions

Non-obvious choices and rationale. Both technical and product decisions go here. Read when revisiting a related choice.

Also use for **tech debt acknowledgments** — deliberate shortcuts taken with awareness (e.g., "using SQLite for V1, will revisit at scale", "skipping CSRF for V1 single-user app"). The point is to make the shortcut explicit so a future agent doesn't think it's an oversight.

**Format:**

```
### [YYYY-MM-DD] — [Decision]
- **Type:** Technical / Product
- **Choice:** what we decided
- **Considered:** alternatives
- **Why this one:** rationale
```

_(none yet)_

---

## Prototype overrides

Places where the Next.js implementation **deliberately diverges** from `prototype/v1/`.

**⚠️ Read this section before declaring a feature "matches the prototype" or attempting to "fix" a divergence.** Some divergences are intentional product decisions and must not be reverted.

This section also feeds **product.md updates at handoff time**. At a session handoff, the checkpoint skill reviews unresolved entries and asks whether they should be reflected in `product.md`. Resolved entries stay here (warning function) but get marked accordingly.

**Format:**

```
### [YYYY-MM-DD] — [Feature/area]
- **Prototype shows:** what's in `prototype/v1/`
- **We built:** what's in the real app
- **Why:** product or technical reason
- **Status:** Pending review / Resolved in product.md / Override only (cosmetic)
```

_(none yet)_

---

## AGENTS.md candidates

Proposed additions to `AGENTS.md` captured during work. **Do not edit `AGENTS.md` mid-session** — capture the proposal here and resolve at handoff.

When a rule, preference, or counterintuitive behavior surfaces during work (e.g., user says "I don't want X in commits" or a bug reveals a needed validation rule), log it here. At handoff, the checkpoint skill reviews each entry and asks whether to append it to `AGENTS.md`.

**Hard rules:** append-only to `AGENTS.md` (never remove or modify existing rules), per-entry approval at handoff, exact text shown before any write.

**Format:**

```
### [YYYY-MM-DD] — [Type: rule / preference / forbidden / counterintuitive]
- **Trigger:** what happened in the session that surfaced this
- **Proposed text:** the actual line or paragraph for AGENTS.md
- **Suggested section:** where in AGENTS.md it would go (Critical rules / Behavioral guidelines / Naming / etc.)
- **Status:** Pending / Resolved (added to AGENTS.md) / Rejected
```

_(none yet)_
