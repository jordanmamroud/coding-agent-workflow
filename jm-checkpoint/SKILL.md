---
name: jm-checkpoint
description: Push session knowledge into docs/working-notes.md and produce a next-action prompt. Use only when the user explicitly invokes `/jm-checkpoint` or `$jm-checkpoint`.  Works in three modes — continuing the same session (mid-stream save), natural break (handoff at a clean stopping point), or mid-task break (handoff when context is full but task is unfinished). Always produces a paste-ready prompt for the next action regardless of mode.Use only when the user explicitly invokes `/jm-checkpoint` or `$jm-checkpoint` 
---

# Session Checkpoint

Pushes accumulated session knowledge into `docs/working-notes.md` and produces a next-action prompt. Always run this when knowledge would be lost otherwise — between tasks, at end of session, or when context is filling up mid-task.

## When this skill triggers

- User says "checkpoint", "save what we learned", "do a checkpoint"
- User says "let's hand off", "wrap up", "I'm stopping here", "we're done for now"
- User indicates context is full and they need to start a fresh session
- User has finished a discrete unit of work and is moving to the next
- A long debugging session uncovered gotchas worth recording

## Core principle

Agents will not reliably write back to memory docs on their own — they mention things in chat and forget to log them. This skill is a deliberate ceremony: review the session, draft entries, get approval, write to disk.

The skill ALSO produces a next-action prompt every time, opt-out style. The user can use it or ignore it; the cost of producing it is small and the cost of asking "want one?" wastes a turn.

## Workflow

Three phases, each ends at a user gate. After all three, silent execution.

### Phase 1 — Mode selection (1 question)

Ask the user:

> Which checkpoint mode?
>
> a) **Continuing** — staying in this session, just saving knowledge before we lose it
> b) **Natural break** — stopping at a clean point (feature done, end of work block)
> c) **Mid-task break** — stopping mid-task, need detailed state to resume later

The mode determines depth of capture (Phase 2) and whether `handoff.md` is written (Phase 4).

### Phase 2 — Working-notes draft review (gate)

Review the session conversation. Identify items worth logging across the five sections of `docs/working-notes.md`:

1. **Known bugs** — bugs encountered and not yet fixed, or fixed but flag-worthy
2. **Dead ends** — approaches tried that failed (with root cause)
3. **Gotchas** — library/API/infrastructure quirks discovered the hard way
4. **Decisions** — non-obvious technical or product choices made (including tech debt acknowledgments)
5. **AGENTS.md candidates** — rules, preferences, or counterintuitive behaviors that surfaced during the session and should be considered for `AGENTS.md` at handoff time

Examples of what triggers a #6 entry:
- User says "don't do X" or "always do Y"
- A bug reveals a needed validation rule
- A library quirk reveals a counterintuitive behavior worth codifying
- A preference emerges from the session that should bind future agents

Log AGENTS.md candidates at the moment they surface — even in mode (a). Just don't modify AGENTS.md until handoff.

For mode (a), capture is selective — only log things future sessions would benefit from knowing. Routine debugging that resolved cleanly doesn't need to be logged.

For modes (b) and (c), capture more aggressively — anything ambiguous gets a draft entry the user can edit or skip.

Display the drafts grouped by section:

```
**Proposed working-notes.md additions:**

### Known bugs
- [draft entry]

### Dead ends
- [draft entry]

### Gotchas
- [draft entry]

### Decisions
- [draft entry]
```

End with: **"Approve all / edit specific entries / skip individual ones?"**

WAIT for confirmation. Apply edits and removals as instructed. Repeat until approved.

If a section has no candidate entries, omit that section entirely from the display.

### Phase 2.5 — Divergence sweep (all modes, gate per entry)

Review the session conversation for prototype divergences — places where the implementation deliberately differs from `prototype/v1/` (different layout, behavior, copy, structure, etc.).

Sources to scan:
- Anything the agent or user framed as "we're doing X instead of what the prototype shows"
- Inline entries the agent already appended to `docs/product.md` (Divergences from prototype section) during work — verify they're listed here so the user can review them at this gate
- New deliberate-difference observations the agent didn't write inline

If there are no candidates, skip this phase silently.

For each candidate, present:

**Divergence [N of M]:** [Feature/area]

**Prototype shows:** [from session]
**We built:** [from session]
**Why:** [product or technical reason from session]

About to append this to `docs/product.md` (Divergences from prototype section). Approve / edit / reject?

- **Approve** → append to `docs/product.md`. If already inline-appended during work, this is a no-op (user is confirming the existing entry).
- **Edit** → user provides revised text. Show the revision and re-ask.
- **Reject** → if not yet written, drop. If already inline-appended, the user removes it manually (the skill does not modify product.md outside of approved appends).

Hard rules:
- Append-only to `product.md`. Per-entry approval.
- Show the EXACT text that will be appended.
- This phase runs in all three modes — divergences accumulate across sessions and the sweep is the failsafe against losing them.

### Phase 3 — Next-action prompt + (for handoff modes) handoff.md draft (gate)

Draft the next-action prompt and (for modes b/c) the handoff document.

#### Next-action prompt format by mode

**Mode (a) — same session, receiver has context:**

```
**Next:** [brief instruction]
**Done when:** [verifiable UI outcome]
```

Two lines. If no clear next step can be inferred from the session, print:

```
**Next:** (no clear next step inferred — what would you like to do?)
**Done when:** (depends on next step)
```

**Modes (b) and (c) — new session, receiver has no context:**

```
**Task:** [one-line description]

**Read first:**
- docs/codebase-map.md
- docs/working-notes.md
- docs/product.md  (if task touches feature scope or UX)
- prototype/v1/  (if task is UI-heavy)

**Pick up at:**
- [specific files or starting point]
- [in-flight state, if mid-task]

**Done when (verify in UI):**
- [specific user action in browser]
- [observable outcome]
- [DB or log verification, if applicable]
```

For mode (c), `Pick up at` must be detailed — exact file states, what was just attempted, what's next, any failed approaches recently logged.

For mode (b), `Pick up at` is lighter — usually "start fresh" for a new feature.

#### Handoff.md draft (modes b and c only)

```
# Handoff — [date/time]

## Just shipped
- [completed and verified items from this session]

## In flight
- [for mode c: detailed file/line state, what was just attempted]
- [for mode b: lighter — what feature is next, where you are in the lifecycle]

## Was about to start
- [next planned thing if known]

## Open questions / blockers
- [things unresolved this session]

## Suggested next session focus
1. ...
2. ...

## Next session prompt

[Embed the full next-action prompt from above here, paste-ready]
```

#### Display

Present both artifacts to the user:

```
**Next-action prompt (mode a only — printed in chat):**
[the prompt]

OR

**Handoff.md (modes b/c — to be written to disk):**
[the full handoff content]

**Next-action prompt (printed in chat for easy copy):**
[the prompt]
```

End with: **"Approve / edit / regenerate?"**

WAIT for confirmation.

### Phase 3.5 — Resolve AGENTS.md candidates (handoff modes b/c only)

This phase runs ONLY for modes (b) and (c). Mode (a) skips it — mid-session checkpoints never modify `AGENTS.md`.

If `docs/working-notes.md` → AGENTS.md candidates section has any entries with `Status: Pending`:

For each pending entry, present:

```
**Candidate [N of M]**: [Date] — [Type]

**Trigger:** [from working-notes]
**Proposed text:** [from working-notes — exact text that would be added]
**Suggested section in AGENTS.md:** [from working-notes]

About to append the proposed text to AGENTS.md → [section]. Approve / edit / defer / reject?
```

- **Approve** → append proposed text to the named section of `AGENTS.md`. Mark the working-notes entry `Status: Resolved`.
- **Edit** → user provides revised text. Show the revision and ask "approve this revision?" again.
- **Defer** → leave entry as `Status: Pending`. Will be reviewed at next handoff.
- **Reject** → mark entry `Status: Rejected` (kept for history; not deleted).

Hard rules:
- Append-only to `AGENTS.md`. Never remove or modify existing rules.
- Per-entry approval. Even if user says "approve all", confirm each individually.
- Show the EXACT text that will be appended before writing.

### Phase 4 — Execute (silent except for status)

Run in this order:

1. Append approved entries to `docs/working-notes.md` under their respective sections. Append-only — never modify or remove existing entries.
2. **Update status fields** in working-notes AGENTS.md candidate entries that were resolved during Phase 3.5.
3. If Phase 2.5 approved any entries: append text to `docs/product.md` (Divergences from prototype section).
4. If Phase 3.5 approved any entries: append text to `AGENTS.md` in the specified sections.
5. If mode is (b) or (c): write/overwrite `docs/handoff.md` with the approved content.
6. Print summary:

```
✓ Updated docs/working-notes.md (N entries added)
✓ [Updated docs/product.md (N divergences added)] (only if Phase 2.5 wrote)
✓ [Updated AGENTS.md (N rules added)] (only if Phase 3.5 wrote)
✓ [Wrote docs/handoff.md] (modes b/c only)

Next prompt (for easy copying):

---
[the full next-action prompt]
---
```

The prompt is ALWAYS printed in chat at the end, regardless of mode. User decides whether to use it.

## Hard rules during this skill

- **Never modify existing working-notes entries.** Append-only. The only exception is updating the `Status` field on AGENTS.md candidates during Phase 3.5 resolution. Otherwise, if an entry needs correction, the user does that manually.
- **Never write to working-notes, handoff.md, AGENTS.md, or product.md without user approval.** Phases 2, 2.5, 3, and 3.5 are all approval gates. No silent writes.
- **Append-only to AGENTS.md and product.md.** Never remove or modify existing rules or content. The skill only adds.
- **Per-entry approval in Phases 2.5 and 3.5.** Even if user says "approve all", confirm each candidate individually with the exact text shown.
- **Mode (a) never modifies AGENTS.md.** It may modify `docs/product.md` via the Phase 2.5 divergence sweep. Phase 3.5 is skipped entirely in mode (a).
- **If `docs/working-notes.md` doesn't exist, create it** from `templates/working-notes.md` before appending.
- **Never invent entries that didn't actually happen in the session.** Only log things that demonstrably occurred. If unsure whether something is worth logging, include it as a draft and let the user remove it.
- **Don't over-log.** Routine work doesn't need entries. The bar for inclusion: would a future agent benefit from knowing this? If marginal, skip.
- **The next-action prompt is always produced**, even in mode (a). No "want a prompt?" question.

## What this skill does NOT do

- Does not modify code or run code.
- Does not create or modify files outside `docs/working-notes.md`, `docs/handoff.md`, `AGENTS.md`, and `docs/product.md` (with explicit per-entry approval for AGENTS.md and product.md).
- Does not modify `prototype/v1/`. Ever. The prototype is a frozen design spec; divergences are tracked directly in `docs/product.md` (Divergences from prototype section).
- Does not commit to git. The user commits when they're ready.
- Does not push tasks to an external tracker. If you have one, that's a separate workflow.
- Does not produce milestone artifacts (README, CHANGELOG). For V1-done or larger milestones, prompt for those separately.

## Reference files

- `templates/working-notes.md` — used to create `docs/working-notes.md` if it doesn't exist
- `references/prompt-formats.md` — full reference for the next-action prompt format with worked examples
