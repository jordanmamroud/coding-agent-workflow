Web app initializer skill comes from this claude chat. https://claude.ai/chat/51a2772c-1d65-44dc-bf85-8ad04b0a89d3
# Coding Agent Workflow

Two skills for building Next.js web apps with parallel AI coding agents (Codex CLI).

The premise: when you're running 3-8 agents in parallel against the same codebase, the architecture and the documentation around it matter more than the agent quality. Most of the work isn't writing better prompts — it's setting up an environment where agents don't collide and don't lose context across sessions.

This repo contains two skills that work together:

- **`jm-init/`** — bootstraps a new Next.js project from a `./prototype/` folder using a deferred-promotion architecture
- **`jm-checkpoint/`** — preserves session knowledge to disk so context survives across sessions and parallel agents

Both opinionated. Both built around a specific tech stack and architecture. Customize freely.

---

## Why this exists

The default failure modes when running parallel agents:

1. **Agents step on each other's files.** Two agents both edit `src/components/Button.tsx`, conflicts everywhere.
2. **Each new session starts with no memory of previous decisions.** Agents re-litigate the same questions every time.
3. **Pre-abstracted architectures (FSD, layered, feature-first with `src/features/`)** force agents to traverse 4-5 folders for one feature, multiplying collision surface and context load.
4. **AGENTS.md grows into a 800-line architecture manifesto** that costs ~20% extra inference per session (per the ETH Zurich AGENTS.md study, Feb 2026).

This repo is my opinionated answer to those failures:

- **Vertical-slice routing** — the route folder under `app/` IS the feature. No `src/features/`. Agents work in self-contained folders.
- **Deferred promotion** — code lives in routes until duplication is *proven*, then promoted on user-initiated refactor days. Never speculatively.
- **Blast radius thinking** (from Peter Steinberger) — when unsure where to put something, smaller blast radius wins.
- **Lean AGENTS.md** — only non-inferable rules. Richer context lives in `docs/`, read on demand.
- **Persistent project memory** — bugs, dead ends, gotchas, decisions, prototype overrides all flow into `docs/working-notes.md` instead of dying in chat history.

---

## The skills

### `jm-init`

Bootstraps a new Next.js project from a `./prototype/` folder.

**Inputs:**
- A folder containing `./prototype/` (HTML, JSX, CSS — usually built with Claude Design or similar). The skill scaffolds *into* that folder; it doesn't create a new one.

**Outputs:**
- The current folder becomes the Next.js project. `prototype/` stays put as a sibling of `app/`, `src/`, `AGENTS.md`, and `docs/`.
- Fully configured: TypeScript, Tailwind, shadcn/ui, SQLite + Drizzle, Vitest, jscpd, knip
- `AGENTS.md` at project root
- `docs/` folder with `product.md`, `codebase-map.md`, `working-notes.md`
- Route folders under `app/` matching the prototype, each with stubbed `page.tsx`, `actions.ts`, `_components/`
- Initial git commit

**Workflow:** 7 phases, 4 user gates.

1. **Auto-detect** — find `./prototype/`, derive project name from HTML `<title>` or cwd basename, scaffold target = cwd (silent)
2. **Explore prototype with Playwright** — click through every interaction, capture states (silent + progress)
3. **Inventory check (gate 1)** — show pages/features/components found, confirm
4. **Understanding check (gate 2)** — show one-line description per page, confirm
5. **User flow check (gate 3)** — show main flows, confirm
6. **Scaffold preview (gate 4)** — show route map, file tree, AGENTS.md, docs, shadcn primitives
7. **Execute** — silent scaffold + commit

The skill drives, you correct. It's not gap-question-driven ("what should this be?") — it's confirmation-driven ("here's what I see, did I get it right?").

**Tech stack baked in:**
- Next.js (latest stable, App Router only — no Pages Router)
- TypeScript strict
- Tailwind CSS + shadcn/ui (primitives in `components/ui/`)
- SQLite + Drizzle ORM (`better-sqlite3`)
- Zod for env + action input validation
- Vitest (tests are opt-in only — the workflow is UI-first verification)
- pnpm

To change the stack, edit `jm-init/scripts/scaffold.sh` and `templates/AGENTS.md`.

---

### `jm-checkpoint`

Pushes session knowledge into `docs/working-notes.md` and produces a paste-ready next-action prompt. Run it whenever knowledge would be lost otherwise.

**Three modes:**

- **(a) Continuing** — staying in the session, just saving knowledge mid-stream
- **(b) Natural break** — clean stopping point, hand off to next session (writes `handoff.md`)
- **(c) Mid-task break** — context filling up but task unfinished, detailed resume state needed (writes `handoff.md` with detailed in-flight section)

**Workflow:** 4 phases, 2-3 user gates depending on mode.

1. **Mode selection** — one question, picks a/b/c
2. **Working-notes draft review (gate)** — show proposed entries grouped by section, approve/edit/skip per entry
3. **Next-action prompt + (b/c) handoff.md draft (gate)** — show the artifacts before writing
3.5. **Resolve candidates (b/c only)** — review AGENTS.md candidates and Prototype overrides, optionally promote to AGENTS.md and product.md
4. **Execute** — write to disk, print next-action prompt in chat

**Working-notes sections (6 total):**

- **Known bugs** — current bugs and workarounds
- **Dead ends** — failed attempts (read before retrying, write back when something fails)
- **Gotchas** — library/API/infrastructure quirks discovered the hard way
- **Decisions** — non-obvious technical or product choices (also tech debt acknowledgments)
- **Prototype overrides** — deliberate divergences from `prototype/v1/`. Doubles as the source for `product.md` upgrades at handoff.
- **AGENTS.md candidates** — proposed AGENTS.md additions captured during work, resolved at handoff time

**Key behaviors locked in:**

- Always produces a next-action prompt (no opt-in question — opt-out is faster)
- Mode (a) prompt is two lines: `Next:` + `Done when:`. Mode (b)/(c) is the full 4-section template (Task / Read first / Pick up at / Done when verifiable in UI).
- Auto-creates `working-notes.md` from template if missing
- Append-only to working-notes (never modifies existing entries except status fields during candidate resolution)
- Append-only to AGENTS.md and product.md (resolution flow is per-entry approval, exact text shown before write)
- Mode (a) never touches AGENTS.md or product.md — only saves to working-notes
- Prototype is never modified — divergences tracked in working-notes only
- No code changes, no git commits, no external tracker pushes

---

## Architecture: deferred-promotion model

Both skills assume the same architecture. Quick summary; full version in `jm-init/references/architecture.md`.

### Two top-level folders

```
app/      Routes. Each folder is both a URL and a self-contained feature.
          Code lives in private subfolders (_components/, _lib/) that
          Next.js does not expose as routes.

src/      Stack-level infrastructure with no natural route owner. Only
          contains things that genuinely have nowhere else to live.
```

### Initial `src/` structure (fixed)

```
src/
  db/
    schema.ts        # Drizzle schema, single source of truth
    client.ts        # better-sqlite3 + drizzle client
    migrations/      # generated by drizzle-kit
  lib/
    env.ts           # validated env vars (zod)
```

That's the entire `src/` tree at scaffold time. Everything else gets created on refactor day, only when proven necessary.

### Folders that DO NOT exist at scaffold time

- `src/features/` — **ever**. The folder under `app/` IS the feature.
- `src/domain/` — wait until refactor day proves it.
- `src/ui/` — wait until refactor day proves it.
- `src/hooks/`, `src/types/`, `src/utils/`, `src/services/`, `src/components/` — none.

Empty folders are guesses. Guesses confuse agents.

### Where new code goes (one rule)

For every new piece of code:

1. UI used by one route → `app/<route>/_components/`
2. Logic used by one route → `app/<route>/_lib/`
3. Server action → `app/<route>/actions.ts` (one file per route, multiple exports)
4. New table/column → `src/db/schema.ts`
5. New env var → `src/lib/env.ts`
6. "I might need this elsewhere later" → STOP. Put it in the route. Defer.

### Blast radius

When unsure between two locations, pick the smaller blast radius. Every file makes a claim about what other code will exist. Putting `format-cost.ts` in `src/lib/` claims "this will be widely used." If wrong, the file sits in the wrong place forever. Putting it in `app/runs/_lib/` claims only "the runs route uses this." If wrong, no harm — `mv` later.

| Decision | Bigger radius (avoid when unsure) | Smaller radius (prefer) |
|---|---|---|
| New helper | `src/lib/foo.ts` | `app/<route>/_lib/foo.ts` |
| New component | `src/ui/Button.tsx` | `app/<route>/_components/button.tsx` |
| New type | `src/types/foo.ts` | inline in the file using it |
| New hook | `src/hooks/use-foo.ts` | `app/<route>/_lib/use-foo.ts` |
| Splitting a file | Split into 3 files now | Wait until file >300 lines with clear sub-pieces |
| Adding abstraction | Generic interface upfront | Concrete impl, abstract on second use |

### Promotion (refactor day)

The deferred-promotion model only works if duplication is detected. `pnpm refactor-day` runs `jscpd` (duplication detector) and `knip` (dead code finder). The output tells you what to promote.

Promotion only happens when the user explicitly initiates it. Agents never promote on their own. AGENTS.md enforces this hard.

---

## What scaffolded projects get in `docs/`

Three documents, distinct purposes:

```
docs/
  product.md         # what we're building (intent + decisions + roadmap)
  codebase-map.md    # where the code lives and why
  working-notes.md   # what happened (bugs, dead ends, gotchas, decisions, overrides)
```

Plus `handoff.md` gets created on first handoff (overwriteable; for the user, not for agents during work).

### `product.md`
The living product spec. Sections: What this app does, Pages, User flows, UX decisions, Roadmap (V1/V2+). Updated at handoff time when prototype overrides get promoted to it. Read at the start of any feature work.

### `codebase-map.md`
A description of where things live and why. Not file system tree — semantic context. "app/runs/ is the classification runs feature" with one-line purpose for major files. Updated when adding new routes or significant `_lib/` files. Read at the start of any non-trivial task.

### `working-notes.md`
Append-only log of project memory. Six sections (above). Read selectively when triggered, written by `jm-checkpoint`. Doesn't go stale because nothing gets removed — just accumulates with status updates.

### `handoff.md`
Overwriteable session-state snapshot. Contains: just shipped / in flight / about to start / open questions / suggested next focus / next session prompt. NOT in AGENTS.md's "read on demand" list — it's for the user, not for agents during work. Last-writer-wins is the right behavior because only the user reads it.

---

## Installation

```bash
git clone <this-repo> ~/codex-skills
```

For Codex CLI, point it at the skills directory (refer to Codex docs for the current convention — this evolves).

Each skill is a self-contained folder with a SKILL.md that Codex reads. The `description` field in the frontmatter is what triggers the skill from natural language ("scaffold from prototype", "do a checkpoint", etc.).

### Prerequisites

- pnpm
- Node 20+
- Playwright (for `jm-init`'s prototype exploration). The skill assumes it's set up in your Codex environment.
- Git

---

## Usage

### Initializing a new project

1. Create a project folder (this folder will become the Next.js project root).
2. Drop your prototype in as `./prototype/` (HTML/JSX/CSS).
3. From that folder, invoke Codex CLI: *"use the jm-init skill"* or just *"scaffold this prototype"*.
4. Walk through the 4 confirmation gates. Skill scaffolds, generates docs/, makes initial commit.
5. The folder is now the Next.js project. `prototype/` sits next to `app/`, `src/`, `AGENTS.md`, and `docs/`.

### Working with the project

- Read `AGENTS.md` (Codex auto-loads it).
- Each route folder under `app/` is a self-contained feature.
- Build new code in the route that uses it. Don't move to `src/` unless explicitly told to (refactor day).
- Verify in the UI before declaring tasks done.

### Using `jm-checkpoint`

Invoke during work whenever you've accumulated knowledge that would be lost. Phrases that trigger it: *"checkpoint"*, *"save what we learned"*, *"do a handoff"*, *"I'm stopping here"*, *"context is filling up"*.

The skill asks the mode (continuing / natural break / mid-task break) and walks through approval gates. Always produces a paste-ready next-action prompt at the end.

**Recommended cadence:**
- Mode (a) checkpoints throughout long sessions whenever you discover something worth logging
- Mode (b) at clean stopping points (feature done, end of work block)
- Mode (c) when context is filling up but you can't finish the task — captures detailed resume state

### Refactor day

Run `pnpm refactor-day` weekly or after each major feature. It runs `jscpd` (finds code duplication across routes) and `knip` (finds unused code). The output is your promotion candidate list.

For each duplication found, prompt an agent: *"jscpd found duplication between A and B. Promote the shared part to `src/<appropriate-place>` and update both files. Atomic commit."*

The skill never promotes on its own. Refactor day is user-initiated.

---

## Repo structure

```
.
├── README.md                                 # this file
├── jm-init/
│   ├── SKILL.md                              # the playbook
│   ├── references/
│   │   ├── architecture.md                   # full deferred-promotion + blast radius + refactor day
│   │   └── naming.md                         # full naming rules
│   ├── templates/
│   │   ├── AGENTS.md                         # template copied to project root
│   │   └── docs/
│   │       ├── product.md                    # filled in from prototype exploration
│   │       ├── codebase-map.md               # filled in from scaffolded structure
│   │       └── working-notes.md              # copied as-is
│   └── scripts/
│       └── scaffold.sh                       # deterministic project bootstrap
└── jm-checkpoint/
    ├── SKILL.md                              # the playbook
    ├── references/
    │   └── prompt-formats.md                 # full next-action prompt reference with examples
    └── templates/
        └── working-notes.md                  # used to create the file if missing
```

---

## Customization

### What's worth editing for personal preferences

**`jm-init/templates/AGENTS.md`** — the project-level AGENTS.md. Most opinionated file in the repo. Contains:
- Critical rules (HALT on missing deps, persist raw responses, atomic commits, no `src/features/`)
- Behavioral guidelines (Karpathy's 4 sections — think before coding, simplicity first, surgical changes, goal-driven)
- File placement and promotion rules
- Naming rules
- Validation requirements (UI-first verification)
- Pointer to `docs/`

This is the file you'll most want to tweak. It's also the file that ships into every new project.

**`jm-init/scripts/scaffold.sh`** — change the tech stack here. Currently bakes in Drizzle + better-sqlite3 + Tailwind + shadcn + Vitest. To swap any of those, edit this script.

**`jm-init/references/naming.md`** — the verbose naming rules used during scaffolding. Tighter version is in the AGENTS.md template; this one is the full reference.

**`jm-init/templates/docs/working-notes.md`** — sections and format templates. Synced manually with `jm-checkpoint/templates/working-notes.md` (they're identical).

**`jm-checkpoint/SKILL.md`** — the checkpoint workflow. Edit if you want different modes, different gate behavior, or different next-action prompt format.

### What's not worth touching

- `jm-init/references/architecture.md` — the architecture rationale. Reference doc; agents read it during scaffolding. Stable.
- `jm-checkpoint/references/prompt-formats.md` — examples and rules for the next-action prompt. Stable.

### Sync points

The `working-notes.md` template lives in two places (jm-init and jm-checkpoint). When you change one, copy to the other:

```bash
cp jm-init/templates/docs/working-notes.md jm-checkpoint/templates/working-notes.md
```

Could be automated with a pre-commit hook or a sync script. Not worth it yet.

---

## Acknowledgments

Ideas in this repo come from:

- **Peter Steinberger ([@steipete](https://steipete.me))** — parallel-agent workflow, atomic commits, blast radius thinking, refactor day pattern, ~20% time on refactoring rule. The whole "agents in same folder with discipline" approach.
- **Andrej Karpathy** — the four behavioral guidelines now embedded in AGENTS.md (think before coding, simplicity first, surgical changes, goal-driven execution).
- **ETH Zurich + DeepMind, Feb 2026** — *"Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?"* The lean-AGENTS.md principle, the cost of architectural overviews, the value of non-inferable details.
- **Feature-Sliced Design 2.1 (`feature-sliced.design`)** — the "pages first" deferral principle that became the foundation of the deferred-promotion model here.
- **Next.js team** — the App Router private folders (`_components/`, `_lib/`) that make route-local colocation work cleanly.

---

## License

MIT. Use, fork, customize freely.

---

## Notes to self

- The two skills don't depend on each other operationally — `jm-checkpoint` works on any project that has a `docs/` folder and an AGENTS.md. But they share assumptions (the architecture, the working-notes structure) so they pair best together.
- If something feels overcomplicated, it probably is. The point of all this is fewer collisions and less lost context, not maximum process. When in doubt, cut.
- The README is for me. Trim aggressively when something stops being useful.
