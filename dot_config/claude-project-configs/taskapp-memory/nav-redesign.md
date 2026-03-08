# Main Navigator Redesign Plan

## Status: BRAINSTORMED, NOT YET IMPLEMENTED

## Problem
The main task dashboard navigator takes ~140px across 3 rows:
1. ASO / SALES department tabs (full-width bar)
2. Sector tabs (Frontend/Backend/Calman/Fornyelser) + user pill + ~10 icon buttons
3. Day pills (Ma-Lø) + admin buttons (+/≡)

## Proposed Design: Merge to 1 row (~48px)

Combines ideas B (inline days with sectors), D (icon toolbar → overflow menu), F (context-aware hiding).

### Desktop layout:
```
ASO│SALES  Frontend Backend Calman Forn.  Ma Ti On To [Fr] Lø  MARKUSMI [⋯]
```

- Department: compact segmented control (ASO│SALES), not full-width tabs
- Sector tabs: underline on active, same row
- Day pills: inline after sectors, separated visually
- Icon toolbar → single [⋯] overflow menu with labeled items
- Admin buttons (+/≡) stay near task list area

### Context-aware (idea F):
- Calman/Fornyelser: hide day pills (no daily routing)
- Only show day pills for sectors that use them

### Overflow menu [⋯] contents:
- Brukere, Kveldsrapport, Lasemelding, Ledertavle, Arkiv, Personlige, Varsler
- Separator
- Admin av/pa, Logg ut

### Mobile (~375px): wraps to 2 rows
```
ASO│SAL  Front Back Calm Forn
Ma Ti On To [Fr] Lo    MARK [⋯]
```

### SALES variant:
```
ASO│SALES  MDA  SDA  Tele  Data  CE   Ma Ti On To [Fr] Lor    MARKUSMI [⋯]
```

## Key files to modify (when implementing)
- Main nav component (needs exploration — likely in src/features/dashboard/ or src/components/)
- Routing: `[sector]/[[...day]]/` structure
- The ~10 icon buttons are in the header area of the dashboard

## Also completed this session (v9.8.0)
- FiscalNavigator.tsx rewritten with collapsible compact design
- EveningReportModal export controls moved to dropdown
