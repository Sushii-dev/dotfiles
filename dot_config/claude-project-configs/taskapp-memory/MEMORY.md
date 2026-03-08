# Project Memory

## Architecture
- **UserHubModal refactored** (v8.53.0): Split from 5,502-line monolith into 14 files under `src/components/ui/user-hub/`
  - Main shell: `UserHubModal.tsx` (~620 lines) — modal wrapper, tabs, data fetching
  - Tab components: ProfileTab, ActivityTab, TitlesTab, LeaderboardsTab, AdminTab
  - Shared: `UserHubTypes.ts` (types), `titleHelpers.ts` (pure functions + getLoggedInUsername), `index.ts` (re-export)
  - Heavy components lazy-loaded: TitlesTab, LeaderboardsTab, AdminTab, TitlePreview via `next/dynamic`
  - `STATIC_CACHE` lives in UserHubModal.tsx, child updates via `onAdminTitlesUpdate` callback
- RenewalBoard is the gold standard reference (~390 lines main component)
- `sonner` toast library used throughout for notifications

## Patterns
- **CRITICAL**: Never import `@/lib/fiscal` in `'use client'` components — it pulls in `@/lib/db` (server-only). Inline pure helpers instead.
- For large block replacements (>50 lines), use Python script via Bash instead of Edit tool
  - **CRITICAL**: Python scripts that write files must use `encoding='utf-8'` AND avoid escaping non-ASCII chars. Use raw string content, not repr(). Norwegian æøå and emojis get mangled to `\uXXXX` literal text in JSX otherwise.
- Background agents (Task tool with general-purpose) work well for 500+ line extractions
- Always verify `tsc --noEmit` after edits — auto-hook validates too
- Version + patch notes required for every commit (see CLAUDE.md)
- Push after every commit — Vercel auto-deploys, check with Vercel MCP

## Pending Design Work
- **Main nav redesign** — see [nav-redesign.md](nav-redesign.md) for full plan
  - Merge 3-row nav (dept + sectors + days) into 1 row
  - Icon toolbar → [⋯] overflow menu with labels
  - Hide day pills for Calman/Fornyelser (no daily routing)
  - Use Figma MCP to mock up before implementing

## Key File Locations
- Types: `src/components/ui/user-hub/UserHubTypes.ts`
- Helpers: `src/components/ui/user-hub/titleHelpers.ts`
- Version: `src/lib/version.ts`
- Patch notes: `src/lib/patchNotes.ts`
