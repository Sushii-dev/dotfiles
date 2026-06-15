#!/usr/bin/env bash
#
# kde-dank :: make KDE Plasma 6 feel like niri/Hyprland with a DMS aesthetic
#
# What this does:
#   1. Installs Krohnkite (dynamic tiling KWin script, dwm-style, the
#      actively maintained anametologin fork from Codeberg)
#   2. Creates 9 virtual desktops in a single row (workspaces 1-9)
#   3. Rebinds Plasma/KWin shortcuts to niri/Hyprland muscle memory
#      (Meta+1..9, Meta+Shift+1..9, Meta+Q, Meta+Return, Meta+D, hjkl focus)
#   4. Removes titlebars on all windows via a KWin window rule (tiles only,
#      CSD apps keep their headers)
#   5. Sets gaps, snappy animations, multi-monitor focus behavior
#   6. Configures Better Blur DX (blur + rounded corners) if installed
#
# Idempotent: safe to re-run. Everything it writes is namespaced or
# documented in uninstall.sh.
#
# Requires: kwriteconfig6, kreadconfig6, qdbus6 (qt6-tools), curl, jq
# Optional: kwin-effects-better-blur-dx (AUR) for blur + rounded corners
#
# Run as your user, NOT root. Log out/in once at the end.

set -euo pipefail

# ----------------------------------------------------------------------------
# Tweakables
# ----------------------------------------------------------------------------
TERMINAL_DESKTOP="kitty-shortcut.desktop"   # .desktop file id of your terminal (matches niri Mod+T -> kitty)
                                            # e.g. "kitty.desktop", "com.mitchellh.ghostty.desktop"
DESKTOP_COUNT=9                             # number of workspaces
GAP=10                                      # inner + outer gap in px (DMS-ish)
GAP_TOP=54                                  # top gap: 8px float margin + 36px panel + 10px gap.
                                            # Panel is "windows go below" (panelVisibility=3 in
                                            # plasmashellrc) so it never de-floats; this gap is
                                            # what keeps tiles out from under it.
CORNER_RADIUS=12                            # rounded corner radius (Better Blur DX)
ANIM_SPEED=0.5                              # 1.0 = Plasma default, 0.5 = snappy

KWINRC="$HOME/.config/kwinrc"
KGLOBAL="$HOME/.config/kglobalshortcutsrc"
KRULES="$HOME/.config/kwinrulesrc"
KDEGLOBALS="$HOME/.config/kdeglobals"

c() { kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; }

QDBUS=$(command -v qdbus6 || command -v qdbus || true)
[ -z "$QDBUS" ] && { echo "qdbus6 not found, install qt6-tools"; exit 1; }

echo "==> kde-dank install"

# ----------------------------------------------------------------------------
# 1. Krohnkite (dynamic tiling)
# ----------------------------------------------------------------------------
if kpackagetool6 --type=KWin/Script --list 2>/dev/null | grep -q krohnkite; then
    echo "==> Krohnkite already installed, skipping download"
else
    echo "==> Downloading latest Krohnkite from Codeberg (anametologin fork)"
    TMP=$(mktemp -d)
    URL=$(curl -fsSL "https://codeberg.org/api/v1/repos/anametologin/krohnkite/releases/latest" \
          | jq -r '.assets[] | select(.name | endswith(".kwinscript")) | .browser_download_url' | head -n1)
    if [ -n "$URL" ] && [ "$URL" != "null" ]; then
        curl -fsSL -o "$TMP/krohnkite.kwinscript" "$URL"
        kpackagetool6 --type=KWin/Script -i "$TMP/krohnkite.kwinscript"
    else
        echo "!!  Could not fetch release automatically."
        echo "    Install manually: https://codeberg.org/anametologin/krohnkite (Releases tab)"
        echo "    then: kpackagetool6 --type=KWin/Script -i krohnkite.kwinscript"
    fi
    rm -rf "$TMP"
fi

# Enable the script
c "$KWINRC" Plugins krohnkiteEnabled true

# Krohnkite settings: gaps, layouts, ignore list
c "$KWINRC" Script-krohnkite screenGapTop     "$GAP_TOP"
c "$KWINRC" Script-krohnkite screenGapBottom  "$GAP"
c "$KWINRC" Script-krohnkite screenGapLeft    "$GAP"
c "$KWINRC" Script-krohnkite screenGapRight   "$GAP"
c "$KWINRC" Script-krohnkite screenGapBetween "$GAP"   # 0.9.9.x name (was tileLayoutGap)

# Layout set: tile (master/stack), monocle, floating. Rest off = clean cycling.
c "$KWINRC" Script-krohnkite enableTileLayout        true
c "$KWINRC" Script-krohnkite enableMonocleLayout     true
c "$KWINRC" Script-krohnkite enableFloatingLayout    true
c "$KWINRC" Script-krohnkite enableSpreadLayout      false
c "$KWINRC" Script-krohnkite enableStairLayout       false
c "$KWINRC" Script-krohnkite enableSpiralLayout      false
c "$KWINRC" Script-krohnkite enableThreeColumnLayout false
c "$KWINRC" Script-krohnkite enableColumnsLayout     false
c "$KWINRC" Script-krohnkite enableStackedLayout     true   # vertical stack for portrait monitor
c "$KWINRC" Script-krohnkite enableBTreeLayout       false

# Portrait monitor (DP-1, 1080x1920): windows stack vertically by default
c "$KWINRC" Script-krohnkite screenDefaultLayout "DP-1:stacked"

# Never tile these (launchers, games, dialogs, Steam popups)
c "$KWINRC" Script-krohnkite ignoreClass "krunner,yakuake,spectacle,plasmashell,org.kde.plasmashell,ksplashqml,org.kde.polkit-kde-authentication-agent-1,xwaylandvideobridge,steam,gamescope,org.kde.kded6"
c "$KWINRC" Script-krohnkite ignoreRole  "quake"
# Float dialogs and utility windows instead of tiling them
c "$KWINRC" Script-krohnkite floatUtility true

# ----------------------------------------------------------------------------
# 2. Workspaces: 9 in one vertical column (niri stacks workspaces vertically,
#    so "desktop down/up" matches Mod+J/K muscle memory)
# ----------------------------------------------------------------------------
c "$KWINRC" Desktops Number "$DESKTOP_COUNT"
c "$KWINRC" Desktops Rows "$DESKTOP_COUNT"
c "$KWINRC" Windows RollOverDesktops false   # niri does not wrap at first/last workspace
c "$KWINRC" Effect-slide SlideBackground false  # wallpaper static during workspace slide (niri)
# KWin scripts in ~/.local/share/kwin/scripts/: dynamic-desktops, vicinae-focus-lock,
# mouse-follows-focus (warps pointer to center of newly focused window, keyboard-nav
# only; pairs with mff-daemon.service below), directional-nav (Super+arrows directional
# window focus/move that crosses monitors at the edge — owns all 8 arrow chords).
# NOTE: enabling a script here only loads it after `kwin reconfigure` (run in §8) or
# relogin — the runtime loadScript API does NOT register a script's global shortcuts.
c "$KWINRC" Plugins dynamic-desktopsEnabled true
c "$KWINRC" Plugins vicinae-focus-lockEnabled true
c "$KWINRC" Plugins mouse-follows-focusEnabled true
c "$KWINRC" Plugins directional-navEnabled true

# ----------------------------------------------------------------------------
# 3. Multi-monitor behavior recommended by Krohnkite docs
#    (focus stays per-screen, like niri/Hyprland)
# ----------------------------------------------------------------------------
c "$KWINRC" Windows ActiveMouseScreen false
c "$KWINRC" Windows SeparateScreenFocus true

# Meta+LMB drag move, Meta+RMB resize, Meta+wheel workspace switch (niri parity)
c "$KWINRC" MouseBindings CommandAllKey Meta
c "$KWINRC" MouseBindings CommandAll1 Move
c "$KWINRC" MouseBindings CommandAll3 Resize
c "$KWINRC" MouseBindings CommandAllWheel "nothing"   # native wheel cmd MOVES window, no view switch; meta-scroll-workspace.py daemon handles it

# Instant focus-follows-mouse, no raise (niri behavior)
c "$KWINRC" Windows FocusPolicy FocusFollowsMouse
c "$KWINRC" Windows DelayFocusInterval 0     # default 300ms = "laggy" hover focus
c "$KWINRC" Windows AutoRaise false

# No cursor friction between monitors, no hot corners (niri has neither)
c "$KWINRC" EdgeBarrier EdgeBarrier 0
c "$KWINRC" EdgeBarrier CornerBarrier false
c "$KWINRC" Effect-overview BorderActivate 9

# ----------------------------------------------------------------------------
# 4. Borderless tiles: global "no titlebar and frame" window rule
#    Namespaced group "kde-dank-noborder", appended to existing rules.
# ----------------------------------------------------------------------------
RULE_ID="kde-dank-noborder"
c "$KRULES" "$RULE_ID" Description "kde-dank: no titlebars (tiling)"
c "$KRULES" "$RULE_ID" noborder true
c "$KRULES" "$RULE_ID" noborderrule 2          # force
c "$KRULES" "$RULE_ID" types 1                 # normal windows only
c "$KRULES" "$RULE_ID" wmclass ".*"
c "$KRULES" "$RULE_ID" wmclassmatch 3          # regex

EXISTING_RULES=$(kreadconfig6 --file "$KRULES" --group General --key rules 2>/dev/null || true)
if [[ ",$EXISTING_RULES," != *",$RULE_ID,"* ]]; then
    if [ -n "$EXISTING_RULES" ]; then
        c "$KRULES" General rules "$EXISTING_RULES,$RULE_ID"
    else
        c "$KRULES" General rules "$RULE_ID"
    fi
fi
RULE_COUNT=$(kreadconfig6 --file "$KRULES" --group General --key count 2>/dev/null || echo 0)
NEW_COUNT=$(kreadconfig6 --file "$KRULES" --group General --key rules | tr ',' '\n' | wc -l)
c "$KRULES" General count "$NEW_COUNT"

# Also: maximized windows borderless (monocle looks clean)
c "$KWINRC" Windows BorderlessMaximizedWindows true

# ----------------------------------------------------------------------------
# 5. Shortcuts
#    Format: "active,default,description". "none" clears.
# ----------------------------------------------------------------------------
echo "==> Writing shortcuts"

# 5a. Free up Meta+1..9 from the task manager
for i in $(seq 1 9); do
    c "$KGLOBAL" plasmashell "activate task manager entry $i" "none,Meta+$i,Activate Task Manager Entry $i"
done

# 5b. Meta+1..9 switch workspace, Meta+Shift+1..9 move window to workspace
for i in $(seq 1 9); do
    c "$KGLOBAL" kwin "Switch to Desktop $i" "Meta+$i,,Switch to Desktop $i"
    c "$KGLOBAL" kwin "Window to Desktop $i" "Meta+Shift+$i,,Window to Desktop $i"
done

# 5c. Core window management, mirroring ~/.config/niri/dms/binds.kdl
c "$KGLOBAL" kwin "Window Close"            "Meta+Q,Alt+F4,Close Window"
c "$KGLOBAL" kwin "Window Fullscreen"       "Meta+Shift+F,,Make Window Fullscreen"
c "$KGLOBAL" kwin "Window Maximize"         "Meta+F,Meta+PgUp,Maximize Window"
c "$KGLOBAL" kwin "Overview"                "Meta+D\tMeta+Tab,Meta+W,Toggle Overview"
c "$KGLOBAL" ksmserver "Lock Session"       "Meta+Alt+L\tScreenSaver,Meta+L\tScreenSaver,Lock Session"
c "$KGLOBAL" ksmserver "Log Out"            "Meta+Shift+E\tCtrl+Alt+Del,Ctrl+Alt+Del,Show Logout Screen"

# Workspace down/up: Meta+PgUp/PgDown + Meta+wheel only. NO vim aliases (J/K/U/I) and
# NO plain arrows (arrows are window nav, owned by the directional-nav script — see 5e).
# Linear Next/Previous (NOT "One Desktop Down/Up"): grid rows reset to 1 whenever
# desktops are removed manually, which makes Down/Up dead ends. Linear always works.
c "$KGLOBAL" kwin "Switch to Next Desktop"     "Meta+PgDown,,Switch to Next Desktop"
c "$KGLOBAL" kwin "Switch to Previous Desktop" "Meta+PgUp,,Switch to Previous Desktop"
c "$KGLOBAL" kwin "Window to Next Desktop"     "Meta+Shift+PgDown,,Window to Next Desktop"
c "$KGLOBAL" kwin "Window to Previous Desktop" "Meta+Shift+PgUp,,Window to Previous Desktop"
c "$KGLOBAL" kwin "Switch One Desktop Down" "none,Meta+Ctrl+Down,Switch One Desktop Down"
c "$KGLOBAL" kwin "Switch One Desktop Up"   "none,Meta+Ctrl+Up,Switch One Desktop Up"
c "$KGLOBAL" kwin "Window One Desktop Down" "none,,Window One Desktop Down"
c "$KGLOBAL" kwin "Window One Desktop Up"   "none,,Window One Desktop Up"

# Monitor focus / move: NO dedicated keybinds. Cross-monitor is handled implicitly by
# the directional-nav script (see 5e) — Super+arrows focus crosses monitors at the edge,
# Super+Shift+arrows invoke "Window to Next Screen" by NAME (works with no key bound).
# Keys cleared (none,none) so they cannot collide with the arrow scheme.
c "$KGLOBAL" kwin "Switch to Previous Screen" "none,none,Switch to Previous Screen"
c "$KGLOBAL" kwin "Switch to Next Screen"     "none,none,Switch to Next Screen"
c "$KGLOBAL" kwin "Window to Previous Screen" "none,none,Move Window to Previous Screen"
c "$KGLOBAL" kwin "Window to Next Screen"     "none,none,Move Window to Next Screen"
# Free Meta+Ctrl+arrows from desktop-left/right (1-column grid; niri uses them for monitors)
c "$KGLOBAL" kwin "Switch One Desktop to the Left"  "none,Meta+Ctrl+Left,Switch One Desktop to the Left"
c "$KGLOBAL" kwin "Switch One Desktop to the Right" "none,Meta+Ctrl+Right,Switch One Desktop to the Right"
c "$KGLOBAL" kwin "Window One Desktop to the Left"  "none,Meta+Ctrl+Shift+Left,Window One Desktop to the Left"
c "$KGLOBAL" kwin "Window One Desktop to the Right" "none,Meta+Ctrl+Shift+Right,Window One Desktop to the Right"

# Clear stock KDE binds that collide with the niri scheme.
# Default slot CLEARED too (was Meta+arrows): dormant defaults re-grabbed the arrows on
# registry flush and zeroed Krohnkite focus binds. Krohnkite owns Meta+arrows now.
c "$KGLOBAL" kwin "Window Quick Tile Left"   "none,,Quick Tile Window to the Left"
c "$KGLOBAL" kwin "Window Quick Tile Right"  "none,,Quick Tile Window to the Right"
c "$KGLOBAL" kwin "Window Quick Tile Top"    "none,,Quick Tile Window to the Top"
c "$KGLOBAL" kwin "Window Quick Tile Bottom" "none,,Quick Tile Window to the Bottom"
c "$KGLOBAL" kwin "Show Desktop"            "none,Meta+D,Peek at Desktop"
c "$KGLOBAL" kwin "Edit Tiles"              "none,Meta+T,Toggle Tiles Editor"
c "$KGLOBAL" kwin "Walk Through Windows"    "Alt+Tab,Meta+Tab\tAlt+Tab,Walk Through Windows"
c "$KGLOBAL" kwin "Walk Through Windows (Reverse)" "Alt+Shift+Tab,Meta+Shift+Tab\tAlt+Shift+Tab,Walk Through Windows (Reverse)"

# 5d. Launchers (niri: Mod+T terminal, Mod+Space vicinae [already set by user],
#     Mod+E dolphin, Mod+Comma settings, Mod+M task manager)
svc() { kwriteconfig6 --file "$KGLOBAL" --group services --group "$1" --key _launch "$2"; }
svc "$TERMINAL_DESKTOP"                       "Meta+T"
svc "org.kde.dolphin.desktop"                 "Meta+E"
svc "systemsettings.desktop"                  "Meta+Comma"
svc "org.kde.plasma-systemmonitor.desktop"    "Meta+M"

# 5e. Krohnkite tiling keys, by action ID (the "Krohnkite: ..." strings are
#     display names, NOT config keys — IDs verified against installed release).
#     Verify after first login in System Settings > Shortcuts > KWin.
k() { c "$KGLOBAL" kwin "$1" "$2,none,$3"; }
# Focus/move directional keys are owned by the directional-nav KWin script, NOT bound
# here: Super+arrows = directional focus (crosses monitors at the edge), Super+Shift+
# arrows = move (swap on-monitor / send to other monitor at the edge). The script
# performs same-monitor moves by invoking the Krohnkite Move actions by NAME, so those
# actions stay registered but carry NO keybind (none). No vim aliases (H/J/K/L/U/I).
k "KrohnkiteFocusLeft"    "none"   "Krohnkite: Focus Left"
k "KrohnkiteFocusRight"   "none"   "Krohnkite: Focus Right"
k "KrohnkiteFocusUp"      "none"   "Krohnkite: Focus Up"
k "KrohnkiteFocusDown"    "none"   "Krohnkite: Focus Down"
k "KrohnkiteShiftLeft"    "none"   "Krohnkite: Move Left"
k "KrohnkiteShiftRight"   "none"   "Krohnkite: Move Right"
k "KrohnkiteShiftDown"    "none"   "Krohnkite: Move Down/Next"
k "KrohnkiteShiftUp"      "none"   "Krohnkite: Move Up/Prev"
# Manual sizing (niri Mod+Minus/Equal, Mod+Shift+Minus/Equal)
k "KrohnkiteShrinkWidth"  "Meta+Minus"        "Krohnkite: Shrink Width"
k "KrohnkitegrowWidth"    "Meta+Equal"        "Krohnkite: Grow Width"
k "KrohnkiteShrinkHeight" "Meta+Shift+Minus"  "Krohnkite: Shrink Height"
k "KrohnkiteGrowHeight"   "Meta+Shift+Equal"  "Krohnkite: Grow Height"
# Float toggle (niri Mod+Shift+T)
k "KrohnkiteToggleFloat"  "Meta+Shift+T"      "Krohnkite: Toggle Float"
# Clear Krohnkite defaults that collide with the niri scheme
k "KrohnkiteFocusNext"    "none"              "Krohnkite: Focus Next"
k "KrohnkiteFocusPrev"    "none"              "Krohnkite: Focus Previous"
k "KrohnkiteMonocleLayout" "none"             "Krohnkite: Monocle Layout"
k "KrohnkiteSetMaster"    "Meta+Return"       "Krohnkite: Set master"
k "KrohnkiteFloatAll"     "none"              "Krohnkite: Toggle Float All"

# ----------------------------------------------------------------------------
# 6. Feel: fast animations, no wobble, hide cursor noise
# ----------------------------------------------------------------------------
c "$KDEGLOBALS" KDE AnimationDurationFactor "$ANIM_SPEED"
c "$KWINRC" Plugins wobblywindowsEnabled false
c "$KWINRC" Plugins squashEnabled false        # Krohnkite docs: squash minimize animation causes issues
c "$KWINRC" Plugins magiclampEnabled true

# ----------------------------------------------------------------------------
# 7. Better Blur DX (blur + antialiased rounded corners), if present
#    AUR: kwin-effects-better-blur-dx
# ----------------------------------------------------------------------------
if [ -f /usr/lib/qt6/plugins/kwin/effects/plugins/forceblur.so ] || \
   ls /usr/lib*/qt6/plugins/kwin/effects/plugins/ 2>/dev/null | grep -qi "blur"; then
    echo "==> Better Blur detected, enabling frosted-glass blur"
    # Better Blur DX: effect id is better_blur_dx, config group Effect-better-blur-dx
    # (the old taj-ny fork used forceblur / Effect-blurplus — keys differ).
    # Blur only — corners belong to KDE Rounded Corners (Blacksuan profile);
    # two corner effects must not run at once.
    c "$KWINRC" Plugins blurEnabled false           # stock blur off (conflict)
    c "$KWINRC" Plugins contrastEnabled false       # stock contrast draws SQUARE slabs
                                                    # behind translucent windows (no
                                                    # rounding support); DX has its own
    c "$KWINRC" Plugins better_blur_dxEnabled true
    c "$KWINRC" Effect-better-blur-dx BlurStrength 10   # heavy: shapes only behind glass
    c "$KWINRC" Effect-better-blur-dx NoiseStrength 10  # matte grain, masks OLED banding
    # Must MATCH KDE Rounded Corners [Round-Corners] Size, else the square
    # blur region pokes past the rounded window corners
    c "$KWINRC" Effect-better-blur-dx CornerRadius 20
    c "$KWINRC" Effect-better-blur-dx BlurDecorations true

    # Focus indicator: KDE Rounded Corners outline on the active window only
    # (windows have no decorations, so this is the niri-style focus border)
    c "$KWINRC" Round-Corners OutlineThickness 2
    c "$KWINRC" Round-Corners ActiveOutlineAlpha 255
    c "$KWINRC" Round-Corners ActiveOutlineUsePalette true
    c "$KWINRC" Round-Corners ActiveOutlinePalette 12   # QPalette::Highlight (accent, follows tint)
    c "$KWINRC" Round-Corners InactiveOutlineThickness 0
    # Force blur behind terminals/dolphin (they don't request the KDE blur hint).
    # Format is COMMA-separated (kcfg default: "class1, class2, class3")
    c "$KWINRC" Effect-better-blur-dx WindowClasses "kitty, ghostty, com.mitchellh.ghostty, org.kde.dolphin"
    c "$KWINRC" Effect-better-blur-dx BlurMatching true

    # Frosted terminal: Plasma-side opacity rule so the niri session's kitty
    # config stays untouched (blur needs a translucent surface)
    FROST_ID="kde-dank-frost-terminal"
    c "$KRULES" "$FROST_ID" Description "kde-dank: frosted terminal opacity"
    c "$KRULES" "$FROST_ID" opacityactive 85
    c "$KRULES" "$FROST_ID" opacityactiverule 2
    c "$KRULES" "$FROST_ID" opacityinactive 80
    c "$KRULES" "$FROST_ID" opacityinactiverule 2
    c "$KRULES" "$FROST_ID" wmclass "ghostty|com\\.mitchellh\\.ghostty"   # kitty gets app-level alpha via kitty-shortcut.desktop
    c "$KRULES" "$FROST_ID" wmclassmatch 3
    c "$KRULES" "$FROST_ID" types 1
    # Dolphin frost is handled by Darkly (~/.config/darklyrc):
    # TransparentDolphinView=true + DolphinViewOpacity/ToolBarOpacity/TabBarOpacity/
    # MenuBarOpacity/DolphinSidebarOpacity=75 (uniform glass), plus
    # [Colors:View] BackgroundAlternate alpha=0 in kdeglobals + tint schemes
    # (alternate detail rows otherwise paint OPAQUE stripes over the glass).
    # A KWin opacity rule does NOT work: Better Blur DX only blurs windows
    # with a real alpha channel, not rule-induced transparency.
    for RID in "$FROST_ID"; do
        EXISTING_RULES=$(kreadconfig6 --file "$KRULES" --group General --key rules 2>/dev/null || true)
        if [[ ",$EXISTING_RULES," != *",$RID,"* ]]; then
            if [ -n "$EXISTING_RULES" ]; then
                c "$KRULES" General rules "$EXISTING_RULES,$RID"
            else
                c "$KRULES" General rules "$RID"
            fi
            c "$KRULES" General count "$(kreadconfig6 --file "$KRULES" --group General --key rules | tr ',' '\n' | wc -l)"
        fi
    done
else
    echo "!!  Better Blur DX not found. For blur + rounded corners:"
    echo "    paru -S kwin-effects-better-blur-dx"
    echo "    then re-run this script (or enable 'Better Blur' in Desktop Effects)."
fi

# ----------------------------------------------------------------------------
# 7b. User services (niri-parity daemons). Deps: python-evdev, python-dbus,
#     python-gobject. mff-daemon owns a uinput pointer (needs rw /dev/uinput — ACL
#     grants the user it by default). Both are KDE-only via ExecCondition.
# ----------------------------------------------------------------------------
echo "==> Enabling user services"
systemctl --user daemon-reload || true
for svc in meta-scroll-workspace mff-daemon; do
    if [ -f "$HOME/.config/systemd/user/$svc.service" ]; then
        systemctl --user enable --now "$svc.service" || true
    fi
done

# ----------------------------------------------------------------------------
# 8. Reload everything
# ----------------------------------------------------------------------------
echo "==> Reloading KWin and global shortcuts"
"$QDBUS" org.kde.KWin /KWin reconfigure || true
kquitapp6 kglobalaccel 2>/dev/null || true   # restarts automatically

cat <<'EOF'

Done. Now:
  1. Log out and back in (Krohnkite + shortcut daemon need a fresh session).
  2. If old KWin shortcut ghosts linger, clean them once:
       qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.cleanUp
  3. Verify Krohnkite keys: System Settings > Shortcuts > KWin, search "Krohnkite".
  4. Optional DMS-style top bar: see extras/dank-panel.js
  5. Optional Material You colors from wallpaper: see matugen/ (README has setup)

Keys (mirroring niri binds.kdl; arrows only, no vim aliases):
  Meta+T           terminal (kitty)    Meta+1..9            workspace
  Meta+Space       vicinae             Meta+Shift+1..9      move window to workspace
  Meta+Q           close               Meta+arrows          focus window (dir, crosses
  Meta+D, Meta+Tab overview                                  monitors at the edge)
  Meta+F           maximize            Meta+Shift+arrows    move window (dir, crosses
  Meta+Shift+F     fullscreen                                monitors at the edge)
  Meta+wheel       workspace swap      Meta+PgUp/PgDown     workspace up/down
  Meta+Shift+T     toggle float        Meta+Shift+PgUp/Dn   window to workspace up/down
  Meta+E           dolphin             Meta+Minus/Equal     width -/+
  Meta+Comma       settings            Meta+Shift+Min/Eq    height -/+
  Meta+M           system monitor
  Meta+S           screenshot region   (directional-nav script owns the arrows;
  Meta+V           clipboard            mouse-follows-focus warps the cursor along)
  Meta+Alt+L       lock                Meta+Shift+E       logout
  Meta+Return      set master          Meta+\\            next layout
EOF
