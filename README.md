# FS Volume

A minimal KDE Plasma 6 widget that displays the current default audio output volume as a percentage in the panel.

## Requirements

- KDE Plasma 6
- PipeWire with WirePlumber
- `wpctl` (provided by WirePlumber)

You can check that `wpctl` is available by running:

```bash
wpctl get-volume @DEFAULT_AUDIO_SINK@
```

## Install

Clone the repository:

```bash
git clone https://github.com/Fartman42121cool/fs-volume.git
cd fs-volume
```

Install the widget for your user:

```bash
kpackagetool6 --type Plasma/Applet --install .
```

Then right-click your panel, choose **Enter Edit Mode → Add Widgets**, search for **FS Volume**, and add it.

No compilation, root access, or separate background service is required.

## How it works

The widget runs `wpctl get-volume @DEFAULT_AUDIO_SINK@` every 1.5 seconds, reads the default output's volume, and displays the rounded percentage. Its speaker icon changes with the volume level and indicates when the output is muted.
