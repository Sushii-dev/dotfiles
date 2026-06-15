// kde-dank :: DMS-style top bar
//
// Converts your existing primary panel into a slim, floating top bar:
// app launcher | pager | spacer | clock (center) | spacer | tray
//
// Apply (inside the Plasma session):
//   qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat extras/dank-panel.js)"
//
// Revert: right-click panel > Enter Edit Mode, or re-add a default panel.
// This rebuilds the panel's widgets, so note any custom widgets first.

var allPanels = panels();
var p;

if (allPanels.length > 0) {
    p = allPanels[0];
    // Strip existing widgets so we control the layout
    var widgets = p.widgets();
    for (var i = 0; i < widgets.length; i++) {
        widgets[i].remove();
    }
} else {
    p = new Panel;
}

p.location = "top";
p.height = Math.round(gridUnit * 1.6);   // slim, DMS-bar territory
p.floating = true;                        // detached, rounded (Plasma 6 floating panels)
p.hiding = "none";
p.lengthMode = "fill";
p.opacity = "translucent";                // pairs with Better Blur on plasmashell

// Left: launcher + workspace pager
p.addWidget("org.kde.plasma.kickoff");
var pager = p.addWidget("org.kde.plasma.pager");
pager.currentConfigGroup = ["General"];
pager.writeConfig("displayedText", "Number");
pager.writeConfig("showOnlyCurrentScreen", false);

// Center: clock
p.addWidget("org.kde.plasma.panelspacer");
var clock = p.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateFormat", "shortDate");
p.addWidget("org.kde.plasma.panelspacer");

// Right: tray
p.addWidget("org.kde.plasma.systemtray");

p.reloadConfig();
