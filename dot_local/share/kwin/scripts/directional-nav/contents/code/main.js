// Directional window navigation (niri parity, monitor-aware).
//
// Super+arrows  : focus the nearest visible window in that direction. Distance is
//                 measured across the whole layout, so at the edge of one monitor it
//                 naturally jumps to the window on the adjacent monitor.
// Super+Shift+arrows : move/swap the active window. If there is a window in that
//                 direction on the SAME monitor, delegate to Krohnkite's reorder
//                 (swap tiles). Otherwise, if a monitor exists in that direction, send
//                 the window there. Krohnkite re-tiles on arrival.
//
// Setting workspace.activeWindow also fires windowActivated, so mouse-follows-focus
// warps the pointer to the newly focused window (incl. across the monitor jump).

function visible() {
    var cd = workspace.currentDesktop;
    var r = [];
    var list = workspace.windowList();
    for (var i = 0; i < list.length; i++) {
        var w = list[i];
        if (!w.normalWindow || w.minimized) continue;
        if (!w.onAllDesktops && w.desktops.indexOf(cd) === -1) continue;
        r.push(w);
    }
    return r;
}

function cx(w) { var g = w.frameGeometry; return g.x + g.width / 2; }
function cy(w) { var g = w.frameGeometry; return g.y + g.height / 2; }

function focusDir(dir) {
    var a = workspace.activeWindow;
    if (!a) return;
    var ax = cx(a), ay = cy(a);
    var best = null, bestScore = Infinity;
    var wins = visible();
    for (var i = 0; i < wins.length; i++) {
        var w = wins[i];
        if (w === a) continue;
        var dx = cx(w) - ax, dy = cy(w) - ay;
        var primary, ortho;
        if (dir === "left")  { if (dx >= -1) continue; primary = -dx; ortho = Math.abs(dy); }
        else if (dir === "right") { if (dx <= 1) continue; primary = dx; ortho = Math.abs(dy); }
        else if (dir === "up")    { if (dy >= -1) continue; primary = -dy; ortho = Math.abs(dx); }
        else { if (dy <= 1) continue; primary = dy; ortho = Math.abs(dx); }
        // Prefer small angular deviation: weight the orthogonal axis heavier.
        var score = primary + ortho * 2;
        if (score < bestScore) { bestScore = score; best = w; }
    }
    if (best) workspace.activeWindow = best;
}

function sameScreenNeighbor(a, dir) {
    var ax = cx(a), ay = cy(a);
    var wins = visible();
    for (var i = 0; i < wins.length; i++) {
        var w = wins[i];
        if (w === a || w.output !== a.output) continue;
        var dx = cx(w) - ax, dy = cy(w) - ay;
        if (dir === "left"  && dx < -1) return true;
        if (dir === "right" && dx > 1)  return true;
        if (dir === "up"    && dy < -1) return true;
        if (dir === "down"  && dy > 1)  return true;
    }
    return false;
}

function monitorInDir(a, dir) { // only meaningful for left/right
    if (!a.output || !a.output.geometry) return false;
    var ag = a.output.geometry;
    var acx = ag.x + ag.width / 2;
    var screens = workspace.screens;
    for (var i = 0; i < screens.length; i++) {
        var s = screens[i];
        if (s === a.output || !s.geometry) continue;
        var scx = s.geometry.x + s.geometry.width / 2;
        if (dir === "left"  && scx < acx) return true;
        if (dir === "right" && scx > acx) return true;
    }
    return false;
}

var KROHN = {
    left: "KrohnkiteShiftLeft", right: "KrohnkiteShiftRight",
    up: "KrohnkiteShiftUp", down: "KrohnkiteShiftDown"
};

function invoke(action) {
    callDBus("org.kde.kglobalaccel", "/component/kwin",
             "org.kde.kglobalaccel.Component", "invokeShortcut", action);
}

function moveDir(dir) {
    var a = workspace.activeWindow;
    if (!a) return;
    if (sameScreenNeighbor(a, dir)) { invoke(KROHN[dir]); return; }
    if ((dir === "left" || dir === "right") && monitorInDir(a, dir)) {
        invoke("Window to Next Screen"); // 2 monitors -> the other one
        return;
    }
    // No neighbor and no monitor that way: let Krohnkite attempt its own move.
    invoke(KROHN[dir]);
}

registerShortcut("DirNavFocusLeft",  "Directional: Focus Left",  "Meta+Left",  function () { focusDir("left"); });
registerShortcut("DirNavFocusRight", "Directional: Focus Right", "Meta+Right", function () { focusDir("right"); });
registerShortcut("DirNavFocusUp",    "Directional: Focus Up",    "Meta+Up",    function () { focusDir("up"); });
registerShortcut("DirNavFocusDown",  "Directional: Focus Down",  "Meta+Down",  function () { focusDir("down"); });
registerShortcut("DirNavMoveLeft",   "Directional: Move Left",   "Meta+Shift+Left",  function () { moveDir("left"); });
registerShortcut("DirNavMoveRight",  "Directional: Move Right",  "Meta+Shift+Right", function () { moveDir("right"); });
registerShortcut("DirNavMoveUp",     "Directional: Move Up",     "Meta+Shift+Up",    function () { moveDir("up"); });
registerShortcut("DirNavMoveDown",   "Directional: Move Down",   "Meta+Shift+Down",  function () { moveDir("down"); });
