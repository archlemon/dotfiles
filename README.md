# dotfiles

## Aliases

```
l        # lvim
v        # vim
n        # nvim
suspend  # systemctl suspend
hexit    # hyprctl dispatch exit
update   # yay -Syu --noconfirm update && flatpak update -y
hl       # hyprland
mbat     # upower -i /org/freedesktop/UPower/devices/battery_hidpp_battery_1 | grep -E "state|percentage|battery-level"
cnt      # cn --config ~/.continue/config.yaml
```

## Apply local settings

```bash
~/.local-settings.sh
```

## Update system

Aliased to `yay -Syu --noconfirm update && flatpak update -y`.

```bash
update
```

## Arch packages

```bash
yay -S --needed $(< ~/.config/arch-packages.txt)
```

## Global NPM libraries

```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
npm i -g $(< ~/.config/npm-packages.txt)
```

## Hyprland Trackball Raw Input Godot Drag Fix

This adds drag threshold to stop simple clicks from dragging.

File: `/etc/libinput/local-overrides.quirks`

Use `hyprctl devices` to find name.

```
[Godot Trackball Drag Protection]
MatchName=logitech-mx-ergo-1
AttrEventCode=-EV_ABS;ABS_X;ABS_Y
DragThreshold=15
```
