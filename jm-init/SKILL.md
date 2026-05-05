---
name: jm-init
description: Bootstrap a new Next.js + Tailwind + shadcn/ui + SQLite/Drizzle web app from a `./prototype/` folder using deferred-promotion architecture for parallel AI coding agents. Use this skill whenever there is a `prototype/` folder at the workspace root and the user wants to scaffold a new project from it, mentions "initialize this project", "scaffold from prototype", "set up new app", "use the initializing skill", or starts a fresh codebase. The skill explores the prototype with Playwright, confirms understanding through 3 quick gates (inventory, page descriptions, user flows), then bootstraps the project with route stubs, AGENTS.md, and a docs/ folder for cross-session context. Manual-only initialization only. Use only when the user explicitly writes "$jm-init", "/jm-init", or directly asks for the jm-init skill. Never use implicitly for ordinary project setup.
---

# Web App Initializer

Bootstraps a new web app from a prototype folder. Tech stack is fixed. Architecture is opinionated. Workflow is gated by user confirmations to ensure the agent's understanding matches the user's intent before any files are written.

## Tech stack (fixed — do not deviate)

- **Framework:** Next.js (latest stable, App Router, no Pages Router)
- **Language:** TypeScript (strict mode)
- **UI:** React + Tailwind CSS + shadcn/ui
- **Database:** SQLite + Drizzle ORM (with `better-sqlite3`)
- **Package manager:** pnpm
- **Testing:** Vitest
- **Refactor tooling:** jscpd, knip
- **Validation:** Zod (env vars + server action inputs)

## Architecture (must read before scaffolding)

Read these reference files first. They govern every placement decision the skill makes:

1. `references/architecture.md` — deferred-promotion model, blast radius thinking, refactor day workflow
2. `references/naming.md` — file and folder naming rules

The skill's `AGENTS.md` template embeds the runtime version of these rules so future agents follow them too.

## Workflow

The skill follows seven phases. Phases 3, 4, 5, and 6 each end at a user confirmation gate. Do not proceed past a gate without explicit confirmation.

### Phase 1 — Auto-detect (silent unless multiple HTMLs)

1. Verify `./prototype/` exists at the current working directory. If not, stop and tell the user.
2. **Pick the canonical prototype HTML.** Recursively find every `*.html` file under `./prototype/`.
   - **0 found** → stop and tell the user no HTML was found in `./prototype/`.
   - **1 found** → use it. Continue silently.
   - **>1 found** → list them and ask the user which one. Do NOT auto-pick — no version-number heuristics, no "prefer subfolders" guessing. Show each path with its `<title>` tag so they're easy to tell apart:

     ```
     Multiple HTML files in ./prototype/:

       1. prototype/v1/index.html         — "GA Helper — V1"
       2. prototype/final/index.html      — "GA Helper — Final"

     Which one is the canonical prototype?
     ```

     **WAIT** for the user to pick. Carry the chosen path into Phase 2.
3. Determine the **project name** (used for `package.json` `"name"` and `create-next-app`, NOT for a folder):
   - Read the `<title>` tag from the chosen HTML
   - Fall back to cwd's basename
   - Sanitize to kebab-case (e.g., "GA Helper" → `ga-helper`)
4. The **project root is cwd itself**. The scaffold lands directly in cwd, alongside the existing `prototype/`. No new project folder is created — `prototype/`, `app/`, `src/`, `AGENTS.md`, and `docs/` all sit at the same level.
5. Collision check: if cwd already contains `package.json`, `app/`, or other Next.js artifacts (indicating a previous scaffold), stop and ask the user before proceeding.

Print a one-line summary: *"Detected prototype for `<project-name>` (using `<chosen-html-path>`). Will scaffold into `<cwd>`."*

### Phase 2 — Explore the prototype with Playwright

Playwright is configured in the user's Codex environment. Use it.

1. Open the canonical HTML chosen in Phase 1 with Playwright in a headless browser.
2. Systematically explore:
   - Click every visible button, link, tab
   - Open every dropdown and menu
   - Trigger every modal/dialog
   - Submit every form (with mock data if needed)
   - Note every navigation that changes the visible state
   - Capture screenshots of distinct visual states for the docs/
3. Cross-reference Playwright observations against the JSX/TSX/CSS source files for any logic not visible at runtime.
4. Build an internal map: pages, features, components, user flows.

### Phase 3 — Inventory check (gate 1)

Output the inventory exactly in this format:

```
**Pages found:**
- `/<route>` → [one-line description from prototype]
- ...

**Features:**
- [feature name] — [one-line description]
- ...

**Major components:**
- [component name] (in [routes])
- ...
```

End with: **"Anything missing or wrong?"**

WAIT for confirmation. If the user corrects anything, update the internal map and re-display the full inventory. Repeat until they confirm.

### Phase 4 — Understanding check (gate 2)

For each page in the confirmed inventory, output one paragraph describing what the page does, what's on it, and how interactions behave:

```
**`/<route>`** — [2-3 sentences: what's on the page, what the user does, how interactions work]
```

End with: **"Any I got wrong?"**

WAIT for confirmation. Update misunderstandings (these become Phase 5 source material). Repeat until confirmed.

### Phase 5 — User flow check (gate 3)

Output the main user flows discovered:

```
**Main user flows:**

1. **[Flow name]**: step → step → step → outcome
2. **[Flow name]**: step → step → step → outcome
...
```

End with: **"Did I miss any flows? Any wrong?"**

WAIT for confirmation.

### Phase 6 — Scaffold preview (gate 4 — final approval)

Output everything that will be created:

1. **Route map** (compact list of all routes with file structure)
2. **File tree** for `app/` and `src/` (top 2-3 levels)
3. **Generated `AGENTS.md`** (full content)
4. **Generated `docs/` files**: `product.md` (what app does + pages + flows + roadmap), `codebase-map.md` (scaffolded structure), `working-notes.md` (empty, copied from template)
5. **shadcn primitives to install**: `button`, `input`, `dialog`, `card`, `table`, `dropdown-menu`, `toast`, `form`, `label`, `select`, `separator`, `tabs`
6. **Drizzle setup**: client config + empty schema + first migration placeholder
7. **package.json scripts to add**: `dev`, `test`, `db:push`, `db:generate`, `db:migrate`, `refactor-day`, `jscpd`, `knip`

End with: **"Proceed with scaffolding?"**

### Phase 7 — Execute (silent except for status)

Run in this order:

1. `scripts/scaffold.sh "<project-name>"` — handles the deterministic bootstrap (create-next-app, deps, shadcn, Drizzle, jscpd, knip, base config). Runs in cwd; the project name is used for `package.json` and create-next-app only, not for a folder.
2. After scaffold.sh succeeds, copy `templates/AGENTS.md` to the project root as-is. The template is opinionated and project-agnostic; the user has already customized it for their stack and preferences.
3. Generate **`docs/product.md`** by filling `templates/docs/product.md` with content from confirmed Phases 3-5:
   - **What this app does** — 1-2 paragraphs based on Phase 3 features
   - **Pages** — list each route with the description from Phase 4
   - **User flows** — numbered list from Phase 5
   - **UX decisions** — leave the format template; populate only if Phase 3-5 surfaced specific corrections worth recording (otherwise leave the "(none yet)" placeholder)
   - **Roadmap V1** — populate from the confirmed feature breakdown
   - **Roadmap V2+** — leave as placeholder
4. Generate **`docs/codebase-map.md`** by filling `templates/docs/codebase-map.md` with the actual scaffolded structure:
   - One entry per route folder created in Step 7 below, with 1-2 sentence purpose from Phase 4
   - List `page.tsx`, `actions.ts` (with action names from stubs), and a one-line summary of `_components/` for each route
   - List the `src/db/` and `src/lib/` files actually created (with current schema state — likely "empty until first feature adds one")
5. Copy `templates/docs/working-notes.md` to the project's `docs/working-notes.md` as-is. Empty append-only log.
6. Create route folders under `app/` matching the confirmed route map
7. For each route:
   - Create `page.tsx` with placeholder content adapted from the prototype's JSX (real React, but with TODO comments instead of business logic)
   - Create `_components/` folder with the components identified for that route, each as a stub matching the prototype visually
   - Create empty `actions.ts` with comment-stubbed action signatures (e.g., `// export async function startRun() {}`)
8. Apply naming rules from `references/naming.md` to every file generated
9. Run `git init && git add -A && git commit -m "Initial scaffold from prototype"`
10. Print next steps:

```
✓ Project scaffolded in <cwd>
✓ Initial commit made

Next steps:
  pnpm dev                          # verify it runs

  Then prompt your agents to start building features:
    "Implement the upload-csv feature in app/<route>/. The page stub
    is in place. Wire up the action and the components."

To revisit project decisions later, see:
  AGENTS.md       — rules for new code (read this every session)
  docs/           — what the app does, why decisions were made

Run `pnpm refactor-day` weekly to detect promotion candidates.
```

## Architecture rules to apply during scaffolding

These govern every file the skill writes. Future agents follow the same rules via `AGENTS.md`.

**Build in the route, not in `src/`:**
- UI used by one route → `app/<route>/_components/`
- Logic used by one route → `app/<route>/_lib/`
- Server actions → `app/<route>/actions.ts` (single file, multiple exports)

**Only create these `src/` folders at scaffold time:**
- `src/db/` (Drizzle schema, client, config)
- `src/lib/` (env.ts only)

**Do NOT create at scaffold time:**
- `src/features/` (ever)
- `src/domain/` (created later when refactor day proves it)
- `src/ui/` (created later when refactor day proves it)
- `src/hooks/`, `src/types/`, `src/utils/`, `src/services/`

**One `actions.ts` per route**, not one file per action.

**Empty folders are guesses.** Don't create them.

## Naming rules

See `references/naming.md` for full rules. Summary the skill must apply:

- All files kebab-case
- Required suffix tags on component files: `-table.tsx`, `-form.tsx`, `-modal.tsx`, `-panel.tsx`, `-chart.tsx`, `-editor.tsx`, `-grid.tsx`, `-sidebar.tsx`
- Server action files: `actions.ts` always (the file containing all actions for the route); individual exported actions inside use verb-led names (`startRun`, `deleteRun`)
- Type files: `-record.ts` for entity row shapes, `-status.ts` for status enums
- Page files: always exactly `page.tsx` (Next.js convention)
- Folders: 3-word cap, no project context words, verb-led for workflow routes, noun-led for resource routes
- Migration files: numbered prefix + kebab body (e.g., `0001-create-runs-table.sql`)

## Reference files

- `references/architecture.md` — deferred-promotion model, blast radius, refactor day
- `references/naming.md` — full naming rules
- `templates/AGENTS.md` — opinionated AGENTS.md (copied as-is to project root)
- `templates/docs/product.md` — product notes template (filled in from prototype exploration)
- `templates/docs/codebase-map.md` — codebase map template (filled in from scaffolded structure)
- `templates/docs/working-notes.md` — empty working-notes log (copied as-is to project's `docs/`)
- `scripts/scaffold.sh` — deterministic project bootstrap
