# FS Volume

A minimal KDE Plasma 6 widget that displays the current default audio output volume as a percentage in the panel.

## Requirements

- KDE Plasma 6
- `plasma-pa` (provides KDE's `org.kde.plasma.private.volume` QML module)
- PipeWire with WirePlumber and `pipewire-pulse`, or another PulseAudio-compatible audio server

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

To update an existing installation after pulling new commits:

```bash
git pull
kpackagetool6 --type Plasma/Applet --upgrade .
```

## Customize

Right-click FS Volume and open **Configure FS Volume**.

### Appearance

- **Volume icon:** Choose a PNG, JPG, SVG, or WebP image. The widget stores the selected file's location, so keep the image in place. Use Reset to return to the built-in speaker icon. The built-in muted icon is still shown when output is muted or set to zero.
- **Percentage font:** Choose an installed font for the percentage. Use Reset to return to the system default font.

### Behavior

- **UI update behavior:** Choose Every Update to refresh as volume changes arrive, When Finished Changing to wait 1.5 seconds after the last detected change, or Custom Interval to limit how often the displayed value refreshes.
- **Custom interval:** Limit visible volume updates to a chosen interval from 100 to 2,000 milliseconds. The audio state is still monitored immediately; this setting is only shown when Custom Interval is selected.
- **Volume tweening:** Optionally animate the displayed percentage when its value changes. Fast, Medium, and Slow presets adjust the animation. Larger changes take longer overall but move more percentage points per second, and the animation eases out near the target.

## How it works

The widget observes the current default output through KDE's PulseAudioQt-backed volume model. Volume and mute changes arrive as property-change signals, so the widget does not poll `wpctl` or launch recurring subprocesses. The update behavior setting controls when those changes are shown. Volume tweening is handled by QML animation; no extra process or background service is needed.

No compilation or root access is required.
