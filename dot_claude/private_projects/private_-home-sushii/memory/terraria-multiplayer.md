# Terraria Multiplayer Optimization

## Setup
- **Modpack:** Infernal Eclipse of Ragnarok (Calamity + Infernum + Thorium + ~87 mods)
- **tModLoader version:** 2025.12.3.0
- **Install path:** `/mnt/Tsukiji/SteamLibrary/steamapps/common/tModLoader/`
- **Worlds:** Mopey_Nation, Wildwood_of_Hope, Wooshi
- **Active MP world:** Wildwood_of_Hope

## Applied Fixes

### 1. NPC Smoothing → 0 (anti-desync)
- `MultiplayerNPCSmoothingRange: 0` in both:
  - `~/.local/share/Terraria/config.json`
  - `~/.local/share/Terraria/tModLoader/config.json`
- Files locked with `chattr +i` (immutable) — `chmod 444` alone is NOT enough, tModLoader does atomic rename to bypass read-only
- Unlock with: `sudo chattr -i <file>`

### 2. Stack Size → 6400000 (anti-FPS-drop)
- `DEFAULT_STACK_SIZE: "6400000"` in `tModLoader.runtimeconfig.json`
- Default is 400000, increased 16x to prevent stack overflows with heavy mod hooks
- NOT immutable — Steam updates may need to modify this file
- Launcher script re-checks on every launch

### 3. NPC Stream → 1 (max sync frequency)
- `npcstream=1` in `/mnt/Tsukiji/SteamLibrary/steamapps/common/tModLoader/serverconfig.txt`
- Lower = more frequent NPC position updates, more bandwidth
- Fine for LAN play

### 4. Dedicated Server
- `tml.sh both` launches server + client
- `tml.sh server` launches server only
- Server runs headless — no GPU, stable tick rate during boss fights
- serverconfig.txt auto-loads Wildwood_of_Hope, priority=1 (High), nosteam

## Key Files
- **Launcher (sushii):** `~/.local/bin/tml.sh`
- **Carepackage:** `~/carepackages/tml/` (tml.sh + README.txt)
- **Carepackage zip:** `~/carepackages/tml.tar.gz`
- **Server config:** `/mnt/Tsukiji/SteamLibrary/steamapps/common/tModLoader/serverconfig.txt`

## Important Notes
- `chmod 444` does NOT prevent tModLoader from overwriting config — it writes a temp file and renames. Must use `chattr +i`.
- Partner connects to `192.168.1.102:7777` (LAN)
- Partner is on Wi-Fi — recommend 5GHz band
