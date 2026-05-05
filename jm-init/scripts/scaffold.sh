#!/usr/bin/env bash
# scaffold.sh — bootstrap a Next.js project with the deferred-promotion architecture
#
# Usage:
#   scaffold.sh <project-name> <target-dir>
#
# Example:
#   scaffold.sh ga-helper /Users/x/projects/ga-helper-workspace/ga-helper
#
# What it does (deterministic parts only — agent handles content generation):
#   1. Runs create-next-app with the fixed stack (Next.js, TS, Tailwind, App Router)
#   2. Installs and initializes shadcn/ui with common primitives
#   3. Installs and configures Drizzle ORM with better-sqlite3
#   4. Installs jscpd and knip for refactor day
#   5. Creates src/db/ and src/lib/ scaffolding
#   6. Adds package.json scripts
#   7. Writes .knip.json
#   8. Initializes git (no commit yet — agent does that after content generation)

set -euo pipefail

PROJECT_NAME="${1:-}"
TARGET_DIR="${2:-}"

if [ -z "$PROJECT_NAME" ] || [ -z "$TARGET_DIR" ]; then
  echo "Usage: scaffold.sh <project-name> <target-dir>" >&2
  exit 1
fi

# Verify pnpm is available
if ! command -v pnpm &>/dev/null; then
  echo "❌ pnpm is required but not found in PATH" >&2
  echo "   Install with: npm install -g pnpm" >&2
  exit 1
fi

PARENT_DIR="$(dirname "$TARGET_DIR")"
mkdir -p "$PARENT_DIR"
cd "$PARENT_DIR"

echo "→ Creating Next.js app at $TARGET_DIR"

# 1. Run create-next-app with our fixed stack
#    --no-src-dir keeps app/ at root so we can have src/ for shared infra
pnpm create next-app@latest "$PROJECT_NAME" \
  --typescript \
  --tailwind \
  --app \
  --no-src-dir \
  --no-eslint \
  --import-alias "@/*" \
  --use-pnpm \
  --turbopack \
  --skip-install

cd "$PROJECT_NAME"

echo "→ Installing dependencies"
pnpm install

# 2. Install Drizzle + better-sqlite3
echo "→ Adding Drizzle + SQLite"
pnpm add drizzle-orm better-sqlite3
pnpm add -D drizzle-kit @types/better-sqlite3

# 3. Install Zod for env + action validation
pnpm add zod

# 4. Install Vitest for testing
pnpm add -D vitest @vitejs/plugin-react

# 5. Install refactor day tooling
echo "→ Adding refactor-day tooling (jscpd, knip)"
pnpm add -D jscpd knip

# 6. Initialize shadcn/ui (non-interactive defaults)
echo "→ Initializing shadcn/ui"
# Create a components.json with sensible defaults so shadcn init doesn't prompt
cat > components.json <<'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "lucide"
}
EOF

# Add the common shadcn primitives
pnpm dlx shadcn@latest add -y \
  button input label dialog card table dropdown-menu sonner form select separator tabs

# 7. Create src/ structure
echo "→ Creating src/ scaffold"
mkdir -p src/db src/lib

# src/lib/env.ts with zod validation
cat > src/lib/env.ts <<'EOF'
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  DATABASE_URL: z.string().default("file:./local.db"),
  // Add additional env vars here. All must be validated.
});

export const env = envSchema.parse(process.env);
EOF

# src/db/schema.ts (empty schema, ready for first feature)
cat > src/db/schema.ts <<'EOF'
// Drizzle schema. Single source of truth for all tables.
//
// Add tables here as features are built. This file is a collision-risk
// file — coordinate when multiple agents are adding tables in parallel.

import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";

// Example (remove when first real table is added):
// export const example = sqliteTable("example", {
//   id: text("id").primaryKey(),
//   createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
// });
EOF

# src/db/client.ts
cat > src/db/client.ts <<'EOF'
import { drizzle } from "drizzle-orm/better-sqlite3";
import Database from "better-sqlite3";
import { env } from "@/lib/env";
import * as schema from "./schema";

const sqlite = new Database(env.DATABASE_URL.replace(/^file:/, ""));
sqlite.pragma("journal_mode = WAL");
sqlite.pragma("foreign_keys = ON");

export const db = drizzle(sqlite, { schema });
EOF

# drizzle.config.ts at project root
cat > drizzle.config.ts <<'EOF'
import type { Config } from "drizzle-kit";

export default {
  schema: "./src/db/schema.ts",
  out: "./src/db/migrations",
  dialect: "sqlite",
  dbCredentials: {
    url: process.env.DATABASE_URL ?? "file:./local.db",
  },
} satisfies Config;
EOF

# 8. Vitest config
cat > vitest.config.ts <<'EOF'
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "node:path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "node",
    globals: true,
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "."),
    },
  },
});
EOF

# 9. .knip.json
cat > .knip.json <<'EOF'
{
  "$schema": "https://unpkg.com/knip@latest/schema.json",
  "entry": [
    "app/**/page.tsx",
    "app/**/layout.tsx",
    "app/**/route.ts",
    "middleware.ts",
    "drizzle.config.ts",
    "vitest.config.ts"
  ],
  "project": [
    "app/**/*.{ts,tsx}",
    "src/**/*.{ts,tsx}",
    "components/**/*.{ts,tsx}",
    "lib/**/*.{ts,tsx}"
  ]
}
EOF

# 10. .env.example
cat > .env.example <<'EOF'
# Local SQLite database file
DATABASE_URL="file:./local.db"
EOF

# 11. Add scripts to package.json (using node since jq may not be available)
echo "→ Adding package.json scripts"
node <<'EOF'
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("package.json", "utf-8"));
pkg.scripts = {
  ...pkg.scripts,
  "test": "vitest",
  "test:run": "vitest run",
  "db:push": "drizzle-kit push",
  "db:generate": "drizzle-kit generate",
  "db:migrate": "drizzle-kit migrate",
  "db:studio": "drizzle-kit studio",
  "refactor-day": "pnpm jscpd && pnpm knip",
  "jscpd": "jscpd --pattern \"app/**/*.{ts,tsx}\" \"src/**/*.{ts,tsx}\" --threshold 0 --min-lines 8 --reporters console",
  "knip": "knip"
};
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
EOF

# 12. .gitignore additions
cat >> .gitignore <<'EOF'

# Local database
local.db
local.db-shm
local.db-wal

# Drizzle migrations dev artifacts
src/db/migrations/meta/_journal.json.bak
EOF

# 13. Initialize git (no commit yet — the agent commits after generating AGENTS.md and docs/)
if [ ! -d ".git" ]; then
  git init -q
fi

echo ""
echo "✓ Scaffold complete at $TARGET_DIR"
echo ""
echo "Deterministic setup done. Now the agent will:"
echo "  - Generate AGENTS.md from the template"
echo "  - Generate docs/ folder content from confirmed prototype breakdown"
echo "  - Create route folders matching the confirmed map"
echo "  - Create page stubs adapted from the prototype"
echo "  - Make the initial git commit"
