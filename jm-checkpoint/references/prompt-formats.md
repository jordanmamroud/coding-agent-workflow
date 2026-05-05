# Next-Action Prompt Formats

The skill produces a next-action prompt in every mode. This file documents the format and shows worked examples.

## Why every mode produces a prompt

The cost of producing a prompt is small (a few lines of text). The cost of asking "do you want one?" wastes a turn. Opt-out is faster than opt-in. The user uses or ignores it.

## What a good prompt does

It answers, for the receiver:

1. What am I doing?
2. What context do I need?
3. Where do I start?
4. How do I know I'm done?

The format adapts to who the receiver is — if they already have context (same session), questions 2 and 3 collapse. If they don't (new session), all four are needed.

## Mode A — same session, receiver has context

Two lines. The receiver is the same agent (or you), still in the conversation, with all the session's context already loaded. They don't need to be told to read the docs — they already know what's going on.

### Format

```
**Next:** [brief instruction]
**Done when:** [verifiable UI outcome]
```

### Examples

```
**Next:** Implement consensus.ts using the 2-of-3 agreement rule we just discussed.
**Done when:** /runs/[id] shows "confirmed" badge for terms where 2+ models agreed.
```

```
**Next:** Wire up the deleteRun action to the trash icon in runs-table.tsx.
**Done when:** Click trash icon, confirm dialog appears, click confirm, row vanishes from history table and SQLite shows it deleted.
```

```
**Next:** (no clear next step inferred — what would you like to do?)
**Done when:** (depends on next step)
```

The "no clear next step" version is fine. Better to print it than to skip.

### What NOT to include in Mode A

- Don't say "Read first: docs/..." — the agent already has context
- Don't say "Pick up at: file X, line Y" — the agent knows the state
- Don't restate the project context — wasted tokens

## Mode B — natural break, new session, no context

Full four-section template. The receiver is a fresh agent that needs context loaded.

### Format

```
**Task:** [one-line description]

**Read first:**
- docs/codebase-map.md
- docs/working-notes.md
- docs/product.md  (if task touches feature scope or UX)
- prototype/v1/  (if task is UI-heavy)

**Pick up at:**
- [specific files or starting point]
- [any state worth being aware of]

**Done when (verify in UI):**
- [specific user action in the browser]
- [observable outcome]
- [DB or log verification, if applicable]
```

### Example

```
**Task:** Start the prompts page (app/prompts/).

**Read first:**
- docs/codebase-map.md
- docs/product.md
- docs/working-notes.md

**Pick up at:**
- app/prompts/page.tsx (doesn't exist yet — create from scratch)
- Reference prototype/v1/v1-prompts.jsx for layout
- See docs/working-notes.md → Decisions for the inline-editing approach (chosen over modal)

**Done when (verify in UI):**
- Navigate to /prompts, see editor render with current prompt content
- Edit the text, click save
- Confirm a new row appears in the prompt_versions table (verify with `pnpm db:studio`)
- Version history list shows the new version
- No errors in dev server logs
```

### Pick up at — guidance

For mode B, "Pick up at" is usually lighter — the task is fresh. Common content:

- The file that doesn't exist yet (start here)
- Reference prototype file
- Any decisions in working-notes that are directly relevant

## Mode C — mid-task break, new session, no context

Same four-section template, but "Pick up at" gets aggressive detail. The receiver must be able to resume from the same place without re-discovery.

### Format

Same as Mode B.

### Example

```
**Task:** Resume implementing CSV parsing for the upload-csv flow.

**Read first:**
- docs/codebase-map.md
- docs/working-notes.md  (recent Dead ends entries on BOM handling are critical)
- docs/handoff.md  (detailed in-flight state from where we stopped)

**Pick up at:**
- app/runs/_lib/parse-csv.ts — function signature is in place, no implementation yet
- The component csv-uploader-panel.tsx already calls this function; uploader UI is verified working
- Two approaches were tried in the previous session and failed:
  - PapaParse with default options (failed on BOM)
  - Manual line splitting (failed on quoted commas)
  - See docs/working-notes.md → Dead ends for details
- Next attempt: PapaParse with skipEmptyLines + custom transformHeader to strip BOM

**Done when (verify in UI):**
- Drag the sample CSV at localhost:3000/runs (sample CSV has 247 terms after metadata rows)
- Preview panel shows 247 terms parsed
- Click "Start run" — creates a row in runs table (verify with `pnpm db:studio`)
- No errors in the dev server logs
- The Google Ads metadata rows (top 3) are stripped, not included as terms
```

### Pick up at — guidance for Mode C

Be specific. The receiver has nothing but this prompt. Include:

- Exact files modified and their state (in progress / done / not started)
- What was just attempted (and whether it worked)
- What had been tried and failed (or point to working-notes entries)
- The next concrete step

The test: could a fresh agent resume from this prompt in under 30 seconds without asking questions?

If no → add more detail.

## What "Done when (verify in UI)" should look like

This section ties to the AGENTS.md rule that "done" means UI-verifiable. Good entries describe a sequence:

1. **User action** — "drag a CSV", "click the trash icon", "navigate to /prompts"
2. **Observable outcome** — "preview shows X", "row vanishes", "editor renders"
3. **Persistence verification** (if applicable) — "row in SQLite confirmed via db:studio", "logs show no errors"

Bad version: *"Done when CSV parsing works."* — not verifiable, no clear test.

Good version: *"Drag sample.csv at /runs, preview shows 247 terms, no console errors."* — concrete, testable.

## Common mistakes to avoid

- **Too vague:** "Done when feature works." Receiver has no test.
- **Pure code description:** "Done when the function returns the expected value." Doesn't tie to UI.
- **Over-broad scope:** "Done when the entire feature is complete." A single agent task should have a focused outcome.
- **Reading the whole codebase:** Only list `Read first` items that are genuinely relevant to the task. The agent will read more if needed.
- **Including session-specific debugging chatter** in Mode B/C prompts. The receiver doesn't need to know about every wrong turn — just the conclusions.
