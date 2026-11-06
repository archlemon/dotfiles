#!/usr/bin/env python3
"""Pop up a menu at the cursor for choosing the default audio output sink."""

import json
import subprocess
from pathlib import Path

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, Gtk, GtkLayerShell  # noqa: E402

PALETTE = Path.home() / ".config/waybar/mocha.css"
CHECK = ""

CSS = """
window {
    background: transparent;
}

#menu {
    background: black;
    color: white;
    border: 1px solid @surface0;
    padding: 4px 0;
    font-family: Hack Nerd Font Propo;
    font-size: 16px;
}

#menu button {
    all: unset;
    padding: 4px 12px;
}

#menu button:hover,
#menu button:focus {
    background: @surface0;
}

#menu button.active {
    color: @maroon;
}
"""


def run(*args):
    """Run a command and return its stdout."""
    return subprocess.run(args, capture_output=True, text=True, check=True).stdout


def list_sinks():
    """Return ``(name, description)`` pairs for every sink and the default sink name."""
    sinks = json.loads(run("pactl", "-f", "json", "list", "sinks"))
    default = run("pactl", "get-default-sink").strip()
    return [(s["name"], s.get("description") or s["name"]) for s in sinks], default


def cursor_position():
    """Return the cursor position in compositor layout coordinates."""
    pos = json.loads(run("hyprctl", "cursorpos", "-j"))
    return pos["x"], pos["y"]


class OutputMenu(Gtk.Window):
    """Full-screen transparent overlay holding a sink menu placed at the cursor."""

    def __init__(self):
        super().__init__()
        cx, cy = cursor_position()
        display = Gdk.Display.get_default()
        monitor = display.get_monitor_at_point(cx, cy)
        self.geometry = monitor.get_geometry()
        self.cursor = (cx - self.geometry.x, cy - self.geometry.y)

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, "audio-output-menu")
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_monitor(self, monitor)
        for edge in (
            GtkLayerShell.Edge.TOP,
            GtkLayerShell.Edge.BOTTOM,
            GtkLayerShell.Edge.LEFT,
            GtkLayerShell.Edge.RIGHT,
        ):
            GtkLayerShell.set_anchor(self, edge, True)
        GtkLayerShell.set_exclusive_zone(self, -1)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)

        visual = self.get_screen().get_rgba_visual()
        if visual is not None:
            self.set_visual(visual)
        self.set_app_paintable(True)

        self.focus_target = None
        self.menu = self.build_menu()
        self.fixed = Gtk.Fixed()
        self.fixed.put(self.menu, 0, 0)
        self.add(self.fixed)

        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK)
        self.connect("button-press-event", self.on_button_press)
        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", Gtk.main_quit)

    def build_menu(self):
        """Build the box of sink buttons, focusing the current default."""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, name="menu")
        sinks, default = list_sinks()

        if not sinks:
            box.add(Gtk.Label(label="No output devices", xalign=0))
            return box

        for name, description in sinks:
            check = Gtk.Label(label=CHECK if name == default else "", width_chars=2, xalign=0)
            row = Gtk.Box(spacing=4)
            row.add(check)
            row.add(Gtk.Label(label=description, xalign=0))

            button = Gtk.Button()
            button.add(row)
            button.connect("clicked", self.on_select, name)
            button.connect("enter-notify-event", lambda b, _e: b.grab_focus())
            if name == default:
                button.get_style_context().add_class("active")
                self.focus_target = button
            box.add(button)

        return box

    def place_menu(self):
        """Move the menu to the cursor, keeping it inside the monitor."""
        self.menu.show_all()
        _, size = self.menu.get_preferred_size()
        x = max(0, min(self.cursor[0], self.geometry.width - size.width))
        y = max(0, min(self.cursor[1], self.geometry.height - size.height))
        self.fixed.move(self.menu, x, y)
        if self.focus_target is not None:
            self.focus_target.grab_focus()

    def on_select(self, _button, name):
        subprocess.run(["pactl", "set-default-sink", name], check=False)
        self.destroy()

    def on_button_press(self, _widget, event):
        if event.window != self.get_window():
            return False
        alloc = self.menu.get_allocation()
        if (
            alloc.x <= event.x < alloc.x + alloc.width
            and alloc.y <= event.y < alloc.y + alloc.height
        ):
            return False
        self.destroy()
        return True

    def on_key_press(self, _widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.destroy()
            return True
        return False


def main():
    css = (PALETTE.read_text() if PALETTE.exists() else "") + CSS
    provider = Gtk.CssProvider()
    provider.load_from_data(css.encode())
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
    )

    window = OutputMenu()
    window.show_all()
    window.place_menu()
    Gtk.main()


if __name__ == "__main__":
    main()
