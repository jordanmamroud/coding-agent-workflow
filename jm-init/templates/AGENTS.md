## Response prefix
- Start every response with `container 5 - test 1teas` so the user can verify you read this file.


## Project context
 
This repo contains two things:
 
1. `prototype/v1/` — a Claude-built UI prototype using mock data. Visual and behavioral spec.
2. The Next.js app at the repo root — the real implementation.
Treat `prototype/v1/` as the source of truth for UI, layout, interactions, and component behavior. The prototype uses mock data; the real app uses real data sources. Match the UI/UX, not the data layer.

## Critical rules
- **HALT on missing dependencies.** Identify external dependencies (API keys, credentials, permissions) before starting. If anything is missing, stop and ask. Do not work around it.
- **File paths:** always use relative paths when putting them in a response. Never respond to me with a absolute path or put them in memory docs. 
- **Persist raw external responses to disk before processing.** REST APIs, MCP servers, webhooks — write the raw response to disk before parsing or transforming.
- After completing any feature, verify the Next.js implementation matches the prototype: visual design, component structure, user flows, and edge-case states (loading, empty, error). Match the UI/UX, not the data layer. **The implementation should match the prototype except where `docs/product.md` (Divergences from prototype section) lists an intentional difference** — check there before flagging or "fixing" anything that looks off.
- **Prototype divergences go in product.md, not chat.** When you intentionally diverge from `prototype/v1/`, append an entry to `docs/product.md` (Divergences from prototype section) inline as you work — no mid-task gate. At end of task, list the entries you added so the user can review, edit, or remove. Never leave a divergence undocumented.


### Forbidden workarounds (illustrative, not exhaustive)

When a dependency is missing, you must NOT:

- Mock, stub, or fake the missing piece
- Substitute a different library, model, service, or framework
- Generate placeholder, synthetic, sample, or example data in place of real data
- Hardcode values that should come from the missing source
- Catch the error and continue with degraded behavior
- Leave a `TODO` / `FIXME` and move past the step
- Skip the step silently or mark it "done"
- Implement a stub "for now" that returns plausible output

Stop and ask instead.

## Behavioral guidelines

These bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think before coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing.

### 2. Simplicity first

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### 4. Goal-driven execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Build minimal UI to enter invalid inputs, verify error states in the browser, check server logs are clean"
- "Fix the bug" → "Reproduce in the UI, fix, verify the bug is gone in the UI, check server logs"
- "Refactor X" → "Verify the UI behavior before, refactor, verify the UI behavior is unchanged after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## Tech stack
 
- Next.js (latest stable, App Router only — no Pages Router)
- TypeScript strict mode
- Tailwind CSS + shadcn/ui (primitives in `components/ui/`)
- SQLite + Drizzle ORM (`better-sqlite3`)
- Zod validates all server action inputs and env vars
- pnpm

## Commands
 
- Dev server: `pnpm dev`
- Typecheck: `pnpm tsc --noEmit`
- Lint: `pnpm lint` (if configured)
- Test (only when explicitly asked): `pnpm test`
- DB push (dev): `pnpm db:push`
- DB generate migration: `pnpm db:generate`
- DB run migrations: `pnpm db:migrate`
- DB GUI: `pnpm db:studio`
- Refactor day: `pnpm refactor-day` (jscpd + knip)

## File placement (one rule)
 
New code goes in the closest private folder to the route that uses it, unless it belongs in `src/db/` or `src/lib/`.
 
- New UI → `app/<route>/_components/`
- New logic → `app/<route>/_lib/`
- New server action → `app/<route>/actions.ts` (one file per route, multiple exports)
- New DB column or table → `src/db/schema.ts`
- New env var → `src/lib/env.ts`

When unsure between two locations, pick the smaller blast radius (the route folder, not `src/`).

## Promotion to `src/`
 
**Never promote on your own.** Do not move code from `app/<route>/` to `src/` as part of feature work, bug fixes, or cleanup. Do not promote because something "feels reusable" or because you noticed two routes doing similar things. Promotion only happens during explicit refactor sessions the user initiates.


## Naming rules
 
- Standard conventions (kebab-case, camelCase, PascalCase, SCREAMING_SNAKE, `is`/`has` boolean prefixes) apply automatically. Don't abbreviate domain nouns: `searchTerms` not `terms`, `negativeKeyword` not `negKw`. Only the opinionated rules:
- UI Label Rules: Use Sentence case (not Title Case). Verb-led, specific action buttons — "Start classification run", not "Submit". Empty/loading/error states need real copy — never ship "Loading…", "Something went wrong", or "No data".

### Folder Naming Rules
 
- Cap at 3 words. Longer probably means two features.
- Verb-led for workflow routes (`upload-csv/`, `review-runs/`); noun-led for resource routes (`credentials/`, `guardrails/`).
- Avoid bucket verbs: `manage-`, `handle-`, `process-`. They signal a missing success state.
- Strip project context. If most siblings have `ga-` in them, drop it from folders — keep it in file names where they need to stand alone in grep.
- Fixed Next.js names: `app/`, `_components/`, `_lib/`, `[id]`, `(group)`.

### File Naming Rules
 
**One file = one primary export. Export name matches file name** (kebab → camel/Pascal). `parse-search-terms-csv.ts` → `parseSearchTermsCsv`. `csv-uploader-panel.tsx` → `CsvUploaderPanel`.
 
**Required role suffixes:** `-table.tsx`, `-form.tsx`, `-modal.tsx`, `-record.ts` (DB row shape), `-status.ts` (enum/union). Other shapes (panel, button, chart, sidebar, editor, grid) follow the same pattern when it adds clarity.


## Validation Requirements

"Done" means the *task* is verifiable in the UI. The agent must test its own work in the UI before declaring the task done. Not "the code looks right."

At this early stage, we are relying heavily on UI-first verification rather than automated test suites. Do not write or run unit or integration tests unless explicitly requested.

### Verification layers

- **Lint + typecheck** — run on every change to catch basic errors.
- **Agent UI Verification** — The agent must start the local dev server (e.g. `npm run dev`), wait for it to compile, and then use browser tools to navigate to `localhost:3000` to interact with the UI, click buttons, and verify the UI state locally before declaring a task done.
- **Server Log Verification** — After interacting with the UI, you must check the terminal running the dev server to ensure no hidden errors, warnings, or unhandled promise rejections were thrown.
- **User UI Verification** — the ultimate review surface for actions the agent cannot take itself (e.g., completing OAuth flows).

- For any database write/persistence work, verify the actual database contents directly after the UI flow. A UI success state is not sufficient; confirm with SQLite/admin row counts or targeted DB queries that the expected records were durably stored.


### Done criteria

A task is done when:

- Lint and typecheck pass.
- You have built the necessary UI components (can be a minimal, unstyled button or raw JSON dump) just enough so the backend logic can be tested visually.
- The agent has actively exercised and verified the task in the running UI using a browser tool.
- The agent has verified the terminal logs are clear of hidden errors.
- After completing any feature, verify the Next.js implementation matches the prototype: visual design, component structure, user flows, and edge-case states (loading, empty, error). Match the UI/UX, not the data layer. **The implementation should match the prototype except where `docs/product.md` (Divergences from prototype section) lists an intentional difference** — check there before flagging or "fixing" anything that looks off.
 

Do not declare a task done from code inspection alone.

## Other docs to read on demand

- `docs/codebase-map.md` — read at the start of any non-trivial task to know where code lives. Update when you add a new route or significant `_lib/` file.
- `docs/product.md` — read when starting work on a feature, or before changing UX in an area that's been decided. Add UX decisions here when you make non-obvious ones.
- `docs/working-notes.md` — known bugs, dead ends, gotchas, and decisions. Read the relevant section by trigger; **write back new entries when you discover something**.
- `prototype/v1/` — already covered in Project context; reference for visual/layout details
