#!/usr/bin/env bash
#
# kde-dank :: uninstall
# Reverts everything install.sh wrote. Plasma defaults come back after relogin.

set -uo pipefail

KWINRC="$HOME/.config/kwinrc"
KGLOBAL="$HOME/.config/kglobalshortcutsrc"
KRULES="$HOME/.config/kwinrulesrc"
KDEGLOBALS="$HOME/.config/kdeglobals"

d() { kwriteconfig6 --file "$1" --group "$2" --key "$3" --delete 2>/dev/null || true; }

echo "==> Removing meta-scroll workspace daemon"
systemctl --user disable --now meta-scroll-workspace.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/meta-scroll-workspace.service"
systemctl --user daemon-reload 2>/dev/null || true

echo "==> Removing dynamic desktops"
kwriteconfig6 --file "$KWINRC" --group Plugins --key dynamic-desktopsEnabled --delete 2>/dev/null || true
rm -rf "$HOME/.local/share/kwin/scripts/dynamic-desktops"
kwriteconfig6 --file "$KWINRC" --group Effect-slide --key SlideBackground --delete 2>/dev/null || true

echo "==> Removing vicinae focus lock"
kwriteconfig6 --file "$KWINRC" --group Plugins --key vicinae-focus-lockEnabled --delete 2>/dev/null || true
rm -rf "$HOME/.local/share/kwin/scripts/vicinae-focus-lock"

echo "==> Removing Krohnkite"
kwriteconfig6 --file "$KWINRC" --group Plugins --key krohnkiteEnabled false
kpackagetool6 --type=KWin/Script -r krohnkite 2>/dev/null || true
# Drop the whole settings group
for key in screenGapTop screenGapBottom screenGapLeft screenGapRight tileLayoutGap screenGapBetween \
           enableTileLayout enableMonocleLayout enableFloatingLayout enableSpreadLayout \
           enableStairLayout enableSpiralLayout enableThreeColumnLayout enableColumnsLayout \
           enableStackedLayout enableBTreeLayout ignoreClass ignoreRole floatUtility \
           screenDefaultLayout; do
    d "$KWINRC" Script-krohnkite "$key"
done

echo "==> Restoring desktops, window behavior"
kwriteconfig6 --file "$KWINRC" --group Desktops --key Number 4
d "$KWINRC" Windows ActiveMouseScreen
d "$KWINRC" Windows SeparateScreenFocus
d "$KWINRC" MouseBindings CommandAllKey
d "$KWINRC" MouseBindings CommandAll1
d "$KWINRC" MouseBindings CommandAll3
d "$KWINRC" MouseBindings CommandAllWheel
d "$KWINRC" Windows BorderlessMaximizedWindows
d "$KDEGLOBALS" KDE AnimationDurationFactor
d "$KWINRC" Plugins wobblywindowsEnabled
d "$KWINRC" Plugins squashEnabled
d "$KWINRC" Plugins magiclampEnabled
d "$KWINRC" Plugins forceblurEnabled
d "$KWINRC" Plugins better_blur_dxEnabled
d "$KWINRC" Plugins blurEnabled
d "$KWINRC" Plugins contrastEnabled
for key in BlurStrength NoiseStrength CornerRadius BlurDecorations WindowClasses BlurMatching; do
    d "$KWINRC" Effect-better-blur-dx "$key"
done
for key in OutlineThickness ActiveOutlineAlpha ActiveOutlineUsePalette ActiveOutlinePalette InactiveOutlineThickness; do
    d "$KWINRC" Round-Corners "$key"
done
d "$KWINRC" Windows FocusPolicy
d "$KWINRC" Windows DelayFocusInterval
d "$KWINRC" Windows AutoRaise
d "$KWINRC" EdgeBarrier EdgeBarrier
d "$KWINRC" EdgeBarrier CornerBarrier
d "$KWINRC" Effect-overview BorderActivate

echo "==> Removing window rules"
RULES=$(kreadconfig6 --file "$KRULES" --group General --key rules 2>/dev/null || true)
NEW=$(echo "$RULES" | tr ',' '\n' | grep -vE '^kde-dank-(noborder|frost-terminal|frost-dolphin)$' | paste -sd, -)
if [ -n "$NEW" ]; then
    kwriteconfig6 --file "$KRULES" --group General --key rules "$NEW"
    kwriteconfig6 --file "$KRULES" --group General --key count "$(echo "$NEW" | tr ',' '\n' | wc -l)"
else
    d "$KRULES" General rules
    kwriteconfig6 --file "$KRULES" --group General --key count 0
fi
for key in Description noborder noborderrule types wmclass wmclassmatch; do
    d "$KRULES" kde-dank-noborder "$key"
done
for key in Description opacityactive opacityactiverule opacityinactive opacityinactiverule types wmclass wmclassmatch; do
    d "$KRULES" kde-dank-frost-terminal "$key"
    d "$KRULES" kde-dank-frost-dolphin "$key"
done

echo "==> Restoring shortcuts to Plasma defaults"
for i in $(seq 1 9); do
    kwriteconfig6 --file "$KGLOBAL" --group plasmashell --key "activate task manager entry $i" --delete 2>/dev/null || true
    kwriteconfig6 --file "$KGLOBAL" --group kwin --key "Switch to Desktop $i" --delete 2>/dev/null || true
    kwriteconfig6 --file "$KGLOBAL" --group kwin --key "Window to Desktop $i" --delete 2>/dev/null || true
done
for key in "Window Close" "Window Fullscreen" "Window Maximize" "Overview" \
           "Switch One Desktop Down" "Switch One Desktop Up" \
           "Window One Desktop Down" "Window One Desktop Up" \
           "Switch to Previous Screen" "Switch to Next Screen" \
           "Window to Previous Screen" "Window to Next Screen" \
           "Show Desktop" "Edit Tiles" \
           "Switch One Desktop to the Left" "Switch One Desktop to the Right" \
           "Window One Desktop to the Left" "Window One Desktop to the Right" \
           "Window Quick Tile Left" "Window Quick Tile Right" \
           "Window Quick Tile Top" "Window Quick Tile Bottom" \
           "Walk Through Windows" "Walk Through Windows (Reverse)" \
           "KrohnkiteFocusLeft" "KrohnkiteFocusRight" "KrohnkiteFocusDown" "KrohnkiteFocusUp" \
           "KrohnkiteFocusNext" "KrohnkiteFocusPrev" \
           "KrohnkiteShiftLeft" "KrohnkiteShiftRight" "KrohnkiteShiftDown" "KrohnkiteShiftUp" \
           "KrohnkiteShrinkWidth" "KrohnkitegrowWidth" "KrohnkiteShrinkHeight" "KrohnkiteGrowHeight" \
           "KrohnkiteToggleFloat" "KrohnkiteFloatAll" "KrohnkiteSetMaster" \
           "KrohnkiteNextLayout" "KrohnkiteMonocleLayout"; do
    kwriteconfig6 --file "$KGLOBAL" --group kwin --key "$key" --delete 2>/dev/null || true
done
kwriteconfig6 --file "$KGLOBAL" --group ksmserver --key "Lock Session" --delete 2>/dev/null || true
kwriteconfig6 --file "$KGLOBAL" --group ksmserver --key "Log Out" --delete 2>/dev/null || true
# Launcher shortcuts added by install.sh (Meta+T kitty-shortcut.desktop predates
# kde-dank — left alone)
for app in org.kde.dolphin.desktop systemsettings.desktop org.kde.plasma-systemmonitor.desktop; do
    kwriteconfig6 --file "$KGLOBAL" --group services --group "$app" --key _launch --delete 2>/dev/null || true
done
kwriteconfig6 --file "$KWINRC" --group Windows --key RollOverDesktops --delete 2>/dev/null || true
kwriteconfig6 --file "$KWINRC" --group Desktops --key Rows --delete 2>/dev/null || true

QDBUS=$(command -v qdbus6 || command -v qdbus || true)
[ -n "$QDBUS" ] && "$QDBUS" org.kde.KWin /KWin reconfigure || true
kquitapp6 kglobalaccel 2>/dev/null || true

echo "Done. Log out and back in. Better Blur DX package itself: remove with your package manager if unwanted."
