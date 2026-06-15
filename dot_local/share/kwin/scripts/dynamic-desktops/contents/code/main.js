// niri-style dynamic workspaces:
// - there is always exactly one empty desktop at the end
// - an empty desktop in the middle is removed once you leave it

function occupies(w) {
    return w.normalWindow && !w.skipPager && !w.onAllDesktops && w.desktops.length > 0;
}

function hasWindows(d) {
    for (const w of workspace.windowList()) {
        if (occupies(w) && w.desktops.indexOf(d) !== -1) {
            return true;
        }
    }
    return false;
}

function reflow() {
    const desks = workspace.desktops;
    if (hasWindows(desks[desks.length - 1])) {
        workspace.createDesktop(desks.length, "Desktop " + (desks.length + 1));
    }
    for (const d of workspace.desktops.slice(0, -1)) {
        if (d !== workspace.currentDesktop && !hasWindows(d) && workspace.desktops.length > 1) {
            workspace.removeDesktop(d);
        }
    }
}

function hookWindow(w) {
    if (w.normalWindow) {
        w.desktopsChanged.connect(reflow);
    }
}

workspace.windowAdded.connect((w) => { hookWindow(w); reflow(); });
workspace.windowRemoved.connect(reflow);
workspace.currentDesktopChanged.connect(reflow);
// manual desktop add/remove (e.g. in Overview) must also restore the invariant
workspace.desktopsChanged.connect(reflow);
for (const w of workspace.windowList()) {
    hookWindow(w);
}
reflow();
