# FS Volume

A small Plasma 6 panel widget that shows your default output volume as an icon and percentage.

Needs KDE Plasma 6, `plasma-pa`, and a PulseAudio-compatible audio server (PipeWire with `pipewire-pulse` works).

## Install

```bash
git clone https://github.com/Fartman42121cool/fs-volume.git
cd fs-volume
kpackagetool6 --type Plasma/Applet --install .
```

Add **FS Volume** from the panel's widget list.

To update an existing install:

```bash
git pull --ff-only origin main
kpackagetool6 --type Plasma/Applet --upgrade .
```

## Settings

Right-click the widget and open **Configure FS Volume**.

Appearance lets you choose separate speaker images for high, medium, low, and muted states, plus the percentage font.

Behavior controls when the displayed number updates: immediately, 1.5 seconds after volume changes stop, or at a chosen interval. Tweening can animate changes at Fast, Medium, or Slow speed.

FS Volume listens to KDE's default-output volume model, so it doesn't repeatedly run `wpctl` to check the volume. The percentage and mute state come from the active output device.

No build step or root access is needed.
