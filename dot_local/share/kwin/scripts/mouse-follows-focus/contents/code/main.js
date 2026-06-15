// Mouse-follows-focus: on window activation, warp the pointer to the window center.
//
// KWin scripts cannot move the cursor (workspace.cursorPos is read-only) and are
// sandboxed, so the actual warp is done by mff-daemon.py over D-Bus. This script only
// detects activation, computes the center, normalises it to the virtual-screen
// bounding box (0..65535), and hands it off.
//
// Key heuristic: warp ONLY when the pointer is NOT already inside the activated window.
// On a mouse click / focus-follows-mouse the pointer is already on the window -> skip.
// On keyboard nav (Krohnkite focus, Meta+arrows) the pointer is elsewhere -> warp.
// That restricts warps to keyboard-driven focus changes, which is what we want.

var ABS_MAX = 65535;

function contains(g, p) {
    return p.x >= g.x && p.x < g.x + g.width && p.y >= g.y && p.y < g.y + g.height;
}

function onActivated(window) {
    if (!window || !window.normalWindow || window.minimized) {
        return;
    }
    var g = window.frameGeometry;
    if (!g || g.width <= 0 || g.height <= 0) {
        return;
    }
    var p = workspace.cursorPos;
    if (contains(g, p)) {
        return; // pointer already on the window (mouse/FFM) -> not a keyboard nav
    }
    var vss = workspace.virtualScreenSize;
    if (!vss || vss.width <= 0 || vss.height <= 0) {
        return;
    }
    var cx = g.x + g.width / 2;
    var cy = g.y + g.height / 2;
    var ax = Math.round(cx / vss.width * ABS_MAX);
    var ay = Math.round(cy / vss.height * ABS_MAX);
    callDBus("org.sushii.mff", "/org/sushii/mff", "org.sushii.mff", "warp", ax, ay);
}

workspace.windowActivated.connect(onActivated);
