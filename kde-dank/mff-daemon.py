#!/usr/bin/env python3
"""Mouse-follows-focus warp daemon (KDE Wayland, niri parity).

KWin scripts cannot move the pointer (workspace.cursorPos is read-only) and are
sandboxed (no exec, no file I/O) — their only outward channel is callDBus. So the
companion KWin script `mouse-follows-focus` computes the focused window's center,
normalises it to a 0..65535 fraction of the virtual-screen bounding box, and calls
warp() here over the session bus.

This daemon owns a persistent uinput ABSOLUTE pointer. KWin maps an absolute device's
[0,65535] range onto the full output bounding rect, so a normalised coord lands 1:1 at
the right pixel across multiple monitors and rotation — no per-layout calibration.

Requires rw on /dev/uinput (sushii has it via ACL; no root needed).
"""
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
from evdev import UInput, AbsInfo, ecodes as e

BUS_NAME = "org.sushii.mff"
OBJ_PATH = "/org/sushii/mff"
IFACE = "org.sushii.mff"
ABS_MAX = 65535


class MouseFollowsFocus(dbus.service.Object):
    def __init__(self, bus, ui):
        super().__init__(bus, OBJ_PATH)
        self.ui = ui

    @dbus.service.method(IFACE, in_signature="ii", out_signature="")
    def warp(self, ax, ay):
        ax = max(0, min(ABS_MAX, int(ax)))
        ay = max(0, min(ABS_MAX, int(ay)))
        self.ui.write(e.EV_ABS, e.ABS_X, ax)
        self.ui.write(e.EV_ABS, e.ABS_Y, ay)
        self.ui.syn()


def main():
    cap = {
        e.EV_KEY: [e.BTN_LEFT, e.BTN_RIGHT, e.BTN_MIDDLE],
        e.EV_ABS: [
            (e.ABS_X, AbsInfo(value=0, min=0, max=ABS_MAX, fuzz=0, flat=0, resolution=0)),
            (e.ABS_Y, AbsInfo(value=0, min=0, max=ABS_MAX, fuzz=0, flat=0, resolution=0)),
        ],
    }
    ui = UInput(cap, name="mff-virtual-pointer", version=1)

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName(BUS_NAME, bus)  # keep ref: GC would release the name
    service = MouseFollowsFocus(bus, ui)
    _keep = (name, service)  # noqa: F841 — hold refs for the loop's lifetime

    try:
        GLib.MainLoop().run()
    finally:
        ui.close()


if __name__ == "__main__":
    main()
