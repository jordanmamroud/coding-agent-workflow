# Naming Rules

Apply these to every file and folder the skill creates. They're embedded in the generated `AGENTS.md` so future agents follow them too.

---

## Folder naming

Folders live in a hierarchy. Unlike files (which appear in imports, stack traces, and grep results detached from their path), folders are always read with their parent visible. Name them accordingly.

- **A folder may assume its immediate parent's role.** A folder under `app/` is a route — you don't need to encode that in the folder name.
- **A folder may NOT assume the project's domain.** Name the specific workflow or surface, not the noun the whole app shares.
- **If a token appears in most sibling folders, it is project context, not a distinguisher.** Remove it from the folder name. Keep it in file names inside, where names travel and need to stand alone.
- **Cap folder names at 3 words.** If you cannot, the folder probably contains two features and should be split.
- **Lead with a verb when the folder represents a workflow** (`upload-csv/`, `review-runs/`).
- **Use a noun when it represents a surface or resource** (`credentials/`, `guardrails/`).
- Don't mix forms — pick the one that matches what's inside.
- **Avoid `manage-`, `handle-`, and other bucket verbs.** They signal the folder lacks a clear success state, which by these rules means it shouldn't exist as one folder.

### Folder names that are NOT negotiable

These are Next.js conventions and must be used as-is:

- `app/` — App Router root
- `_components/` — private UI folder under a route
- `_lib/` — private logic folder under a route
- `[id]`, `[slug]`, etc. — dynamic route segments
- `(group)` — route groups (no URL impact)
- `api/` — API route handlers (rare in our stack — prefer server actions)

---

## File naming

- **kebab-case always:** `parse-search-terms-csv.ts`, `runs-history-table.tsx`
- **Verb-led when the file does something:** `parse-`, `validate-`, `create-`, `update-`, `list-`, `get-`, `start-`, `export-`, `rotate-`
- **Noun-led when the file describes something** (a record, a type, a status, a UI surface)

### Required suffix tags

The file's role must be legible in any tree, import, or grep result. Use these suffix tags:

| Suffix | Use for |
|---|---|
| `-action.ts` | Single Next.js Server Action (rare — most actions live in `actions.ts`) |
| `-record.ts` | Entity row shape (matches a DB table or domain entity) |
| `-status.ts` | Enum or status union type |
| `-table.tsx` | Data table component |
| `-form.tsx` | Form component |
| `-modal.tsx` | Modal/dialog component |
| `-panel.tsx` | Panel or section component |
| `-chart.tsx` | Chart or visualization component |
| `-grid.tsx` | Grid layout component |
| `-sidebar.tsx` | Sidebar component |
| `-editor.tsx` | Editor component (text, code, structured input) |
| `-button.tsx` | Custom button component (only when not a generic primitive) |

### Special files (Next.js conventions — do not add suffixes)

- `page.tsx` — the route file (always exactly this name)
- `layout.tsx` — segment layout
- `loading.tsx`, `error.tsx`, `not-found.tsx` — special UI files
- `actions.ts` — the per-route server actions file (one per route, holds all action exports)
- `route.ts` — API route handler

### Migrations

Drizzle generates these via `drizzle-kit`. If hand-written or hand-named:

- Numbered prefix, kebab body: `0001-create-runs-table.sql`, `0002-add-cost-column.sql`

---

## Examples

### Good

```
app/
  runs/
    page.tsx                          # Next.js convention
    actions.ts                        # all run-related server actions
    _components/
      runs-history-table.tsx          # noun-led, suffix matches role
      csv-uploader-panel.tsx          # noun-led, suffix matches role
      progress-panel.tsx
    _lib/
      parse-csv.ts                    # verb-led, file does something
      run-record.ts                   # noun-led, describes a row shape
      run-status.ts                   # status enum
    [id]/
      page.tsx
      actions.ts
      _components/
        results-table.tsx
        export-button.tsx
```

### Bad — and why

```
app/
  runs/
    page.tsx
    components/                       # ❌ should be _components/ (Next.js will route it)
      RunsHistoryTable.tsx            # ❌ PascalCase
      runs-component.tsx              # ❌ no role suffix; vague
    handlers/                         # ❌ bucket folder
      runs-handler.ts                 # ❌ "handler" is a bucket verb
    runs-types.ts                     # ❌ "runs" repeats parent context
    types.ts                          # ❌ no role suffix
```

---

## Cross-cutting principles

- **Folder strips project context. Files keep it.** A file named `runs-table.tsx` inside `app/runs/_components/` reads as "runs/runs-table" in imports and grep — the redundancy isn't a bug, it's how grep finds the file. The folder doesn't need "runs-components" because the parent already says runs.
- **Suffix tags > generic names.** `csv-uploader-panel.tsx` beats `csv-uploader.tsx` because the suffix tells you what shape the file produces (a panel, not a button or a hook).
- **One actions file per route.** `actions.ts` always. Multiple exports inside, not multiple files.
- **No bucket folders.** `handlers/`, `services/`, `utils/`, `helpers/` — these are signals of vague purpose. If you reach for them, the contents probably belong in `_lib/` with verb-led filenames.
