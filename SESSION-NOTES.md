# Session Notes — Continuation Handoff

This document is for restoring context in a new Claude session. It captures what we built, why we made the decisions we did, where we left off, and what to work on next.

---

## Project at a glance

**Repo:** `coding-agent-workflow`
**Purpose:** Two skills for Codex CLI that make parallel AI coding agents work without colliding or losing context.
**Skills:**
- `jm-init` — bootstraps a Next.js project from a `./prototype/` folder
- `jm-checkpoint` — preserves session knowledge to disk + produces next-action prompts

The project is mine (Jordan) and is for personal use, not a public OSS project. The README and these notes are detail-heavy on purpose — easier to trim than to reconstruct.

---

## Why we built this (the problem)

Running parallel AI coding agents fails in predictable ways:

1. **Agents step on each other's files.** Two agents both edit a shared component, conflicts everywhere.
2. **Each new session starts with no memory.** Decisions get re-litigated every time.
3. **Pre-abstracted architectures (FSD, layered, feature-first with `src/features/`)** force agents to traverse 4-5 folders for one feature.
4. **AGENTS.md grows into a 800-line manifesto** that costs ~20% extra inference per session (per ETH Zurich AGENTS.md study, Feb 2026) without improving task success.

The repo is my opinionated answer.

---

## Tech stack (baked in — do not change unless deliberate)

- **Framework:** Next.js (latest stable, App Router only — no Pages Router)
- **Language:** TypeScript strict mode
- **UI:** React + Tailwind + shadcn/ui (primitives in `components/ui/`)
- **Database:** SQLite + Drizzle ORM (`better-sqlite3`)
- **Validation:** Zod (env vars + server action inputs)
- **Tests:** Vitest, but **opt-in only** — workflow is UI-first verification
- **Package manager:** pnpm
- **Refactor tooling:** jscpd (duplication) + knip (dead code)

To change the stack: edit `jm-init/scripts/scaffold.sh` and `jm-init/templates/AGENTS.md`.

---

## Architecture: deferred-promotion model

This is the heart of everything. Three rules in priority order:

1. **Build in the route** that uses the code. Default for everything except infrastructure.
2. **Defer promotion** until proven: a second importer, jscpd flagging duplication, or a 300+ line file with clear sub-pieces.
3. **When unsure, smaller blast radius wins.** Smaller guesses are cheaper to undo.

### Two top-level folders

```
app/      Routes. Each folder is both a URL and a self-contained feature.
          Code lives in private subfolders (_components/, _lib/) that
          Next.js does not expose as routes.

src/      Stack-level infrastructure with no natural route owner.
```

### Initial `src/` structure (fixed)

```
src/
  db/                # schema.ts, client.ts, drizzle.config.ts, migrations/
  lib/
    env.ts           # Zod-validated env vars
```

That's the entire `src/` tree at scaffold time.

### Folders that DO NOT exist at scaffold time

`src/features/`, `src/domain/`, `src/ui/`, `src/hooks/`, `src/types/`, `src/utils/`, `src/services/`, `src/components/`. None. Empty folders are guesses; guesses confuse agents.

`src/domain/` and `src/ui/` get created on refactor day, only when proven.

### Where new code goes (one rule)

- UI used by one route → `app/<route>/_components/`
- Logic used by one route → `app/<route>/_lib/`
- Server action → `app/<route>/actions.ts` (one file per route, multiple exports)
- New table → `src/db/schema.ts`
- New env var → `src/lib/env.ts`

### Promotion (refactor day only)

Code never gets promoted speculatively. Agents NEVER promote on their own — even when they notice duplication. They mention it; the user initiates promotion via `pnpm refactor-day` and explicit prompts.

This rule is enforced in AGENTS.md and is one of the strongest constraints in the whole system.

---

## Influences and credits

- **Peter Steinberger ([@steipete](https://steipete.me))** — parallel-agent workflow, blast radius thinking, atomic commits, refactor day pattern, ~20% time on refactoring rule, "agents in same folder with discipline" approach.
- **Andrej Karpathy** — the four behavioral guidelines (think before coding, simplicity first, surgical changes, goal-driven execution) embedded in AGENTS.md.
- **ETH Zurich + DeepMind, Feb 2026** — *"Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?"* The lean-AGENTS.md principle.
- **Feature-Sliced Design 2.1** — the "pages first" deferral principle that became the deferred-promotion model.
- **Next.js team** — the App Router private folders (`_components/`, `_lib/`).

---

## What's in the repo

```
coding-agent-workflow/
├── README.md                                 # detailed personal README
├── LICENSE                                   # MIT
├── .gitignore
├── jm-init/
│   ├── SKILL.md                              # the playbook
│   ├── references/
│   │   ├── architecture.md                   # full deferred-promotion + blast radius + refactor day
│   │   └── naming.md                         # full naming rules
│   ├── templates/
│   │   ├── AGENTS.md                         # template copied to project root at scaffold
│   │   └── docs/
│   │       ├── product.md                    # filled from prototype exploration
│   │       ├── codebase-map.md               # filled from scaffolded structure
│   │       └── working-notes.md              # copied as-is (empty template)
│   └── scripts/
│       └── scaffold.sh                       # deterministic project bootstrap
└── jm-checkpoint/
    ├── SKILL.md                              # the playbook
    ├── references/
    │   └── prompt-formats.md                 # next-action prompt reference + examples
    └── templates/
        └── working-notes.md                  # used to create the file if missing
```

The two `working-notes.md` templates are identical. When you change one, copy to the other (no automation yet).

---

## How `jm-init` works

Bootstraps a new Next.js project from a `./prototype/` folder. Uses Playwright to actually click through the prototype.

**Workflow: 7 phases, 4 user gates.**

1. **Auto-detect** — find prototype, derive project name from HTML `<title>` or parent folder name, target directory is sibling to `prototype/` (silent)
2. **Explore prototype with Playwright** — clicks every interaction, navigates every link, captures states (silent + progress)
3. **Inventory check (gate 1)** — show pages/features/components found → user confirms or corrects
4. **Understanding check (gate 2)** — one-line description per page → user confirms or corrects
5. **User flow check (gate 3)** — main flows → user confirms or refines
6. **Scaffold preview (gate 4)** — show route map, file tree, AGENTS.md preview, docs preview, shadcn primitives → user approves
7. **Execute** — silent scaffold + initial commit

**Key principle:** the skill drives, the user corrects. Confirmation-driven, not gap-question-driven. We landed on this after the user pushed back on an earlier "ask 10 UX questions" design.

**Outputs at scaffold time:**
- New Next.js project at `../<project-name>/`
- `AGENTS.md` at project root
- `docs/product.md` (populated from Phases 3-5)
- `docs/codebase-map.md` (populated from scaffolded structure)
- `docs/working-notes.md` (empty template)
- Route folders under `app/` with stubbed `page.tsx`, `actions.ts`, `_components/`
- shadcn primitives: `button`, `input`, `dialog`, `card`, `table`, `dropdown-menu`, `sonner`, `form`, `select`, `separator`, `tabs`, `label`
- Drizzle setup with empty schema
- `pnpm refactor-day` script wired up
- Initial git commit

---

## How `jm-checkpoint` works

Pushes session knowledge to disk + produces next-action prompts. Run it whenever knowledge would otherwise be lost.

**Three modes:**
- **(a) Continuing** — same session, mid-stream save. Just appends to working-notes; never touches AGENTS.md or product.md.
- **(b) Natural break** — clean stopping point, hand off to next session. Writes `handoff.md`. Resolves AGENTS.md candidates and Prototype overrides.
- **(c) Mid-task break** — context filling up, task unfinished, detailed resume state needed. Same as (b) but `Pick up at` section gets aggressive detail.

**Workflow: 4 phases, 2-3 user gates depending on mode.**

1. **Mode selection** — one question
2. **Working-notes draft review (gate)** — show proposed entries grouped by section → approve/edit/skip per entry
3. **Next-action prompt + handoff.md draft (gate)** — show artifacts before writing. Mode (a) just shows the 2-line prompt; modes (b)/(c) show full handoff.md
4. **3.5 — Resolve candidates (gate, modes b/c only)** — review AGENTS.md candidates and Prototype overrides, optionally promote to AGENTS.md and product.md
5. **Execute** — write to disk, print next-action prompt in chat

**Working-notes has 6 sections:**
1. Known bugs
2. Dead ends (read before retrying, write back when something fails)
3. Gotchas (library/API/infra quirks)
4. Decisions (technical or product, includes tech debt acknowledgments)
5. Prototype overrides (deliberate divergences from `prototype/v1/` — also feeds product.md at handoff)
6. AGENTS.md candidates (proposed AGENTS.md additions captured during work — resolved at handoff)

**Hard rules locked in:**
- Always produces a next-action prompt (no opt-in question — opt-out is faster)
- Mode (a) prompt is 2 lines: `Next:` + `Done when:`
- Modes (b)/(c) prompt is the 4-section template (Task / Read first / Pick up at / Done when verifiable in UI)
- Auto-creates `working-notes.md` from template if missing
- Append-only to working-notes (only exception: status fields update during candidate resolution)
- Append-only to AGENTS.md and product.md (resolution flow is per-entry approval, exact text shown before write)
- Mode (a) NEVER touches AGENTS.md or product.md
- Prototype is NEVER modified — divergences only flow into working-notes, then optionally into product.md
- No code changes, no git commits, no external tracker pushes

**Next-action prompt format:**

Mode (a):
```
**Next:** [brief instruction]
**Done when:** [verifiable UI outcome]
```

Modes (b)/(c):
```
**Task:** [one-line]

**Read first:**
- docs/codebase-map.md
- docs/working-notes.md
- docs/product.md (if task touches feature scope or UX)
- prototype/v1/ (if task is UI-heavy)

**Pick up at:**
- [specific files or starting point]
- [in-flight state, if mid-task]

**Done when (verify in UI):**
- [specific user action in browser]
- [observable outcome]
- [DB or log verification]
```

We deliberately don't point to specific sections of MD files because (per the user's testing) reading 3 medium MD files only consumes ~7% of context. MD reads are cheap; section-pointing was overkill.

---

## The four docs that ship with every project

```
docs/
  product.md         # what we're building (intent + decisions + roadmap)
  codebase-map.md    # where the code lives and why
  working-notes.md   # what happened (bugs, dead ends, gotchas, decisions, overrides, candidates)
  handoff.md         # where we left off (overwriteable; created on first handoff)
```

Each answers a distinct question:
- *"What is this app supposed to do?"* → product.md
- *"Where is the code that does X?"* → codebase-map.md
- *"Has this been tried before?"* → working-notes.md
- *"Where did I leave off?"* → handoff.md

`handoff.md` is **for the user, not for agents during work**. It's NOT in AGENTS.md's "read on demand" list. Agents during their tasks don't read it. Only the user reads it (when starting a new session). Last-writer-wins is fine because there's no agent contention.

`product.md` and `codebase-map.md` ARE in AGENTS.md's read-on-demand list with triggers ("read at the start of any non-trivial task").

---

## AGENTS.md (the project-level rules file)

The opinionated AGENTS.md template that ships with `jm-init` is at `jm-init/templates/AGENTS.md`. It's the most-edited file across our session.

**Sections (in order):**
1. Response prefix (container test marker)
2. Project context (`prototype/v1/` is visual spec, real app is implementation)
3. Critical rules (HALT on missing deps, persist raw responses, atomic commits, no `src/features/`, etc.)
4. Forbidden workarounds (mock/stub/fake/etc — what NOT to do when deps are missing)
5. Behavioral guidelines (Karpathy's 4 — think before coding / simplicity first / surgical changes / goal-driven execution, with examples adapted to UI-first verification)
6. Tech stack
7. Commands
8. File placement (one rule)
9. Promotion to `src/` (NEVER promote on your own)
10. Naming rules (folders, files, domain nouns, UI labels — opinionated rules only, standard conventions not repeated)
11. Validation requirements (UI-first, 5 verification layers, done criteria)
12. Other docs to read on demand (codebase-map, product, working-notes, prototype)

**Major decisions made during the session:**
- Started bloated (~217 lines), tightened to ~129 lines, then back up to ~196 with Karpathy guidelines added. Final is somewhere in between.
- Cut redundant standard conventions (kebab-case, camelCase) — agents do those automatically
- Cut bloated suffix tag list (was 11 tags, now 5: `-table.tsx`, `-form.tsx`, `-modal.tsx`, `-record.ts`, `-status.ts`)
- Removed "Counterintuitive" section header (was meta-talk; merged into Critical rules as direct rules)
- Removed "Collision-risk files" section entirely (it told agents to coordinate with other agents — agents can't do that; replaced with atomic-commits rule)
- Adapted Karpathy section 4 (Goal-driven) examples to UI-first verification instead of TDD
- Added prototype-override mechanism: AGENTS.md "match the prototype" rule explicitly says to check `working-notes.md` (Prototype overrides) before flagging a divergence
- Naming section: cut from ~80 lines to ~30 (intro line says "standard conventions apply automatically; only opinionated rules below")
- Folded "domain nouns" rule into the naming intro
- Compressed UI labels from 3 bullets to 1 paragraph
- Removed `Migrations:` and `Special Next.js files:` lines (agents know these)

---

## Other key decisions made (chronological-ish)

These are decisions worth knowing about that aren't obvious from the files alone.

### On the architecture itself

- We rejected FSD (Feature-Sliced Design) as the primary mental model — too many taxonomy decisions ("widget? feature? entity?") for agents to be consistent on.
- We rejected old-school feature-first with `src/features/` — same problem.
- We rejected layered/Clean architecture — too many folders to traverse for one feature.
- We landed on App Router native colocation as the primary architecture, with a thin `src/` layer for genuine infrastructure.

### On the docs structure

- Started with 6 docs (`app-overview`, `ux-decisions`, `feature-roadmap`, `working-notes`, `handoff`, plus `prototype/`).
- User asked to consolidate — we merged `app-overview`, `ux-decisions`, `feature-roadmap` into a single `product.md` with sections (because cheap MD reads make consolidation costless).
- Added `codebase-map.md` as a separate doc (semantic context about where code lives, distinct from product intent).
- Final: 4 docs (product, codebase-map, working-notes, handoff).

### On working-notes evolution

- Started with 5 sections (Known bugs, Dead ends, Gotchas, Decisions, Prototype overrides).
- User noted that "tech debt acknowledgments" and "open questions" should also be tracked. We folded them in: tech debt → Decisions section, open questions → Dead ends section with status `still open`. No new sections needed.
- User asked about an "AGENTS.md candidates" section to capture rules-to-be-added without losing flow. We added it as the 6th section.
- User then asked about prototype → product.md flow. We landed on: Prototype overrides section ALSO serves as the source for product.md updates at handoff. No new section; existing one does double duty. Status field was added to track resolution: `Pending review / Resolved in product.md / Override only (cosmetic)`.
- The final 6 sections are: Known bugs, Dead ends, Gotchas, Decisions, Prototype overrides, AGENTS.md candidates.

### On the checkpoint skill modes

- Original design had modes that mostly differed in handoff doc creation.
- Refined to 3 distinct modes based on receiver context:
  - Mode (a): same agent, has context → minimal 2-line prompt
  - Mode (b): new agent, no context, natural break → full prompt + handoff.md
  - Mode (c): new agent, no context, mid-task → full prompt with detailed resume + handoff.md
- We rejected adding a separate "milestone" skill (V1-done events are too rare to justify a dedicated skill — just prompt for README at that point).

### On the next-action prompt

- Originally proposed asking the user "want a next-step prompt?" — user pushed back: opt-out is faster. Skill always produces it.
- "Read first" originally pointed to specific MD sections. User pointed out MD reads are cheap (~7% context for 3 files). We changed to point at whole files.
- Mode (a) was originally going to use the same template as (b)/(c) — user pointed out the same-session agent already has context, so most fields are redundant. We collapsed mode (a) to 2 lines.
- The "Done when (verify in UI)" section is required, mode-specific in detail. It's the killer feature — it pairs with AGENTS.md's UI-first done criteria and gives the agent a clear finish line.

### On the prototype itself

- We agreed: never modify `prototype/v1/`. It's the original design spec, frozen.
- Divergences flow into working-notes Prototype overrides section.
- product.md gets updated to reflect implementation reality at handoff.
- The override entries STAY in working-notes after being resolved to product.md (warning function survives — agents reading prototype directly might still try to "fix" the divergence).

---

## What's already done and committed

Everything described above is in the repo and pushed to:
**https://github.com/jordanmamroud/coding-agent-workflow**

That includes:
- README.md (~360 lines, detailed personal version)
- Both skills (`jm-init`, `jm-checkpoint`) with full SKILL.md, references, templates, scripts
- LICENSE (MIT)
- .gitignore

---

## What we deferred (not built yet)

- **Milestone skill** for V1-done events. Decision: too rare to justify; just prompt manually when the time comes.
- **Sync automation** for the duplicate `working-notes.md` template (lives in both `jm-init/templates/docs/` and `jm-checkpoint/templates/`). Manual `cp` when changing one.
- **Tightening of `jm-init/references/naming.md`.** It's the verbose original. The AGENTS.md template has the tighter version. They're internally consistent (one is the rule applier during scaffolding, one is what future agents read). User chose not to tighten the verbose version yet.

---

## Where we left off — and what to work on next

We finished setting up the GitHub repo. The skills are committed and pushed. They've never been used on a real project yet.

**Immediate next priorities (in order of importance):**

### 1. Tighten the prototype override → product.md flow

This is the user's main concern going into the next session. The flow is:

- Agent makes a deliberate divergence from prototype during work
- Captures it in working-notes Prototype overrides section
- At handoff, jm-checkpoint asks whether each override should also be reflected in product.md
- If yes, content gets appended to product.md (in Pages / User flows / UX decisions / Roadmap)
- The working-notes entry stays but its status updates

**The concern to resolve:** when an agent reads BOTH product.md and working-notes.md in a future session, will it get confused?

Specifically:
- product.md says "the runs page has feature X"
- working-notes Prototype overrides says "we built X differently than the prototype"

Are these two entries coherent together? Will the agent understand they're describing the same thing from different angles? Or will it see them as conflicting?

Things to think about with the next agent:
- Should the override entry, once resolved, link to the product.md entry it created? ("See product.md → Pages → /runs for current behavior")
- Should the override entry's content change once resolved (focus shifts from "what we changed" to "this is the canonical behavior; here's the deviation history")?
- Should AGENTS.md's pointer to working-notes mention "if you see a conflict between product.md and an override, product.md is the current truth and the override is historical context"?
- How do we make sure the agent reading both files in sequence can resolve the relationship without re-asking the user?

The goal: **agent reads product.md, agent reads working-notes, agent knows exactly what the current product behavior is and which entries are warnings vs. historical record.** No ambiguity.

### 2. Same review for AGENTS.md candidates → AGENTS.md flow

Less urgent because we spent more time on this one already. But worth one final pass:

- Does the resolution flow make sense end-to-end?
- Are the status field values right (`Pending` / `Resolved` / `Rejected`)?
- Should the AGENTS.md candidate entry stay in working-notes after resolution, or get pruned?
  - Note: we kept overrides because of the warning function. AGENTS.md candidates have no warning function — they exist to be promoted. Maybe they should get pruned after resolution to keep working-notes clean?
  - Counter-argument: keeping them gives history of "why does this rule exist?"
- Are there edge cases we haven't thought about? Rule conflicts? Two candidates that contradict each other?

### 3. Put the skills to the test

After 1 and 2, the user wants to start using the skills on a real project. The plan:

- Create a workspace, drop a real prototype in
- Invoke `jm-init`
- Walk through the gates
- Use the scaffolded project for actual work
- When issues come up — invoke `jm-checkpoint`, see how the skill handles real session context
- Bring discovered issues back to the next chat session
- Iteratively improve the skills based on real usage

**This is the real test.** Everything we've built is theoretical until it survives contact with a real prototype and real feature work.

### 4. Things that will probably come up but we haven't thought about

The user is aware that real usage will surface things we haven't anticipated. The next chat will likely involve:
- Bug fixes to skill workflows that didn't behave as expected
- Tweaks to AGENTS.md based on what actual agents found ambiguous
- Possibly a milestone skill if V1-done becomes a real event
- Adjustments to the next-action prompt format if it's not landing right
- Refinements to working-notes section structure

The user has explicitly said they want to use the next session as a feedback loop: report issues from real usage, make updates to the skills together.

---

## Restart instructions for the next session

To begin a new chat with full continuity:

1. Open a new Claude chat.
2. Paste this entire document.
3. Describe what you want to work on next (e.g., "Let's tighten the prototype override → product.md flow per section 1 of the next priorities").
4. The new Claude will have nearly all the context I have right now and can proceed directly to work.

**Even better:** drop the `coding-agent-workflow` repo into a Claude Project. Project files persist across all chats. Then the new chat just needs:

> "I'm continuing work on the coding-agent-workflow project. Read SESSION-NOTES.md for context. Next I want to work on [tightening the prototype override → product.md flow / reviewing the AGENTS.md candidates flow / something else]."

The repo plus this notes doc is enough.

---

## Honest framing for the next agent

The next agent should know:

- This is a personal project. The user is iterating on infrastructure they'll use themselves. There's no team to align with, no users to please. Optimize for the user's actual workflow, not generic best practices.
- The user has tested individual pieces of this (e.g., they've confirmed MD context costs are ~7% for 3 files; they've tested that end-of-session-only handoffs lose information). When they push back on a recommendation based on testing, trust them.
- The user prefers shorter, more direct responses. They've explicitly asked for this multiple times. Don't pad.
- The user values "less is more" and frequently asks "can this be shorter without losing quality?" The answer is usually yes; cut aggressively.
- The user is OK with iteration. Decisions made now can be revisited. Don't over-engineer trying to get it perfect on the first pass.
- The user is familiar with the architecture (deferred-promotion, blast radius, etc.) — don't re-explain unless asked.
- When proposing a change to a file, default to making the change rather than just discussing it. The user will course-correct if needed.

---

## Quick reference: file paths in the repo

- Architecture rationale: `jm-init/references/architecture.md`
- Naming rules (verbose): `jm-init/references/naming.md`
- AGENTS.md template: `jm-init/templates/AGENTS.md`
- product.md template: `jm-init/templates/docs/product.md`
- codebase-map.md template: `jm-init/templates/docs/codebase-map.md`
- working-notes.md template (canonical): `jm-init/templates/docs/working-notes.md`
- working-notes.md template (mirror): `jm-checkpoint/templates/working-notes.md`
- Scaffold script: `jm-init/scripts/scaffold.sh`
- Init skill playbook: `jm-init/SKILL.md`
- Checkpoint skill playbook: `jm-checkpoint/SKILL.md`
- Prompt formats reference: `jm-checkpoint/references/prompt-formats.md`

---

End of session notes.
