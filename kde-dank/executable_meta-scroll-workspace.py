#!/usr/bin/env python3
"""Meta+wheel = switch workspace, Meta+Shift+wheel = move window to workspace.

Read-only evdev listener (no grab, no re-emission — adds zero input latency).
Triggers KWin shortcuts over D-Bus, mirroring niri's Mod+WheelScroll binds.

Also pins the desktop grid to N rows x 1 column (vertical, like niri's workspace
stack): KWin resets rows to 1 when desktops are removed manually, which flips the
slide animation horizontal. KWin scripts cannot set the rows property (variant
marshaling), so this daemon watches countChanged/rowsChanged and re-pins.
"""
import re
import select
import subprocess
import threading
import time

import evdev
from evdev import ecodes

COOLDOWN = 0.15  # niri uses cooldown-ms=150 for the same binds
META_KEYS = {ecodes.KEY_LEFTMETA, ecodes.KEY_RIGHTMETA}
SHIFT_KEYS = {ecodes.KEY_LEFTSHIFT, ecodes.KEY_RIGHTSHIFT}


def invoke(shortcut: str) -> None:
    subprocess.Popen(
        ["qdbus6", "org.kde.kglobalaccel", "/component/kwin",
         "org.kde.kglobalaccel.Component.invokeShortcut", shortcut],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


def relevant_devices(skip_paths=()):
    devs = []
    for path in evdev.list_devices():
        if path in skip_paths:
            continue
        try:
            d = evdev.InputDevice(path)
            caps = d.capabilities()
            keys = set(caps.get(ecodes.EV_KEY, []))
            rels = set(caps.get(ecodes.EV_REL, []))
            if (META_KEYS & keys) or (ecodes.REL_WHEEL in rels):
                devs.append(d)
            else:
                d.close()
        except OSError:
            continue
    return devs


def rescan(devices: dict) -> int:
    """Open any newly-appeared matching devices. Wireless mice (e.g. the Logitech
    PRO X2) re-enumerate with NEW evdev nodes after sleep/reconnect; without this
    the daemon keeps reading dead nodes and Meta+wheel silently stops working."""
    have = {d.path for d in devices.values()}
    new = relevant_devices(skip_paths=have)
    for d in new:
        devices[d.fd] = d
    return len(new)


def run() -> None:
    devices = {d.fd: d for d in relevant_devices()}
    if not devices:
        raise OSError("no input devices readable")
    meta_down = set()
    shift_down = set()
    last_fire = 0.0
    last_rescan = time.monotonic()

    while True:
        r, _, _ = select.select(list(devices), [], [], 3.0)
        # Periodically pick up re-enumerated/hotplugged input devices so a wireless
        # mouse reconnect doesn't silently kill Meta+wheel until the next restart.
        now = time.monotonic()
        if now - last_rescan >= 3.0:
            last_rescan = now
            added = rescan(devices)
            if added:
                print(f"meta-scroll: picked up {added} new input device(s)", flush=True)
        for fd in r:
            dev = devices.get(fd)
            if dev is None:
                continue
            try:
                for ev in dev.read():
                    if ev.type == ecodes.EV_KEY:
                        if ev.code in META_KEYS:
                            (meta_down.add if ev.value else meta_down.discard)(ev.code)
                        elif ev.code in SHIFT_KEYS:
                            (shift_down.add if ev.value else shift_down.discard)(ev.code)
                    elif (ev.type == ecodes.EV_REL and ev.code == ecodes.REL_WHEEL
                          and meta_down and ev.value):
                        now = time.monotonic()
                        if now - last_fire < COOLDOWN:
                            continue
                        last_fire = now
                        direction = "Previous" if ev.value > 0 else "Next"
                        action = ("Window to " if shift_down
                                  else "Switch to ") + direction + " Desktop"
                        invoke(action)
            except OSError:
                del devices[fd]
                if not devices:
                    raise


VDM = ["--session", "--dest", "org.kde.KWin", "--object-path", "/VirtualDesktopManager"]


def vdm_get(prop: str) -> int:
    out = subprocess.run(
        ["gdbus", "call", *VDM, "--method", "org.freedesktop.DBus.Properties.Get",
         "org.kde.KWin.VirtualDesktopManager", prop],
        capture_output=True, text=True).stdout
    m = re.search(r"uint32 (\d+)", out)
    return int(m.group(1)) if m else 0


def pin_rows() -> None:
    count = vdm_get("count")
    if count and vdm_get("rows") != count:
        subprocess.run(
            ["gdbus", "call", *VDM, "--method", "org.freedesktop.DBus.Properties.Set",
             "org.kde.KWin.VirtualDesktopManager", "rows", f"<uint32 {count}>"],
            capture_output=True)


def rows_watchdog() -> None:
    while True:
        try:
            pin_rows()
            mon = subprocess.Popen(
                ["gdbus", "monitor", *VDM],
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
            for line in mon.stdout:
                if "countChanged" in line or "rowsChanged" in line:
                    pin_rows()
        except Exception:
            pass
        time.sleep(3)


if __name__ == "__main__":
    threading.Thread(target=rows_watchdog, daemon=True).start()
    while True:
        try:
            run()
        except OSError:
            time.sleep(3)  # device hotplug churn — rescan
