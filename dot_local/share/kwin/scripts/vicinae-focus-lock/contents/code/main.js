// While a vicinae window exists, focus-follows-mouse is suspended (click-to-focus)
// so hovering other windows can't start a focus tug-of-war (= flicker).
// A windowActivated backstop reverts deliberate clicks. Closing vicinae
// restores the previous focus policy.
let vic = null;
let savedPolicy = null;

function lock(w) {
    vic = w;
    if (savedPolicy === null) {
        savedPolicy = options.focusPolicy;
        options.focusPolicy = 0; // ClickToFocus while vicinae is open
    }
}

function unlock() {
    vic = null;
    if (savedPolicy !== null) {
        options.focusPolicy = savedPolicy;
        savedPolicy = null;
    }
}

function track(w) {
    if (w && w.resourceClass === "vicinae-server") {
        lock(w);
    }
}

workspace.windowAdded.connect(track);
workspace.windowRemoved.connect((w) => {
    if (w === vic) {
        unlock();
    }
});
for (const w of workspace.windowList()) {
    track(w);
}

workspace.windowActivated.connect((w) => {
    if (vic !== null && w !== vic && vic.visible !== false) {
        workspace.activeWindow = vic;
    }
});
