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

- **UI update behavior:** Choose Every Update to refresh whenever a changed volume is detected, When Finished Changing to wait 1.5 seconds after the last detected change, or Custom Interval to choose the polling interval.
- **Custom interval:** Set the polling interval from 100 to 2,000 milliseconds. Shorter intervals react faster but run `wpctl` more frequently. This setting is only shown when Custom Interval is selected.
- **Volume tweening:** Optionally animate the displayed percentage when its value changes. Fast, Medium, and Slow presets adjust the animation. Larger changes take longer overall but move more percentage points per second, and the animation eases out near the target.

## How it works

By default, the widget runs `wpctl get-volume @DEFAULT_AUDIO_SINK@` every 250 milliseconds and displays the rounded percentage. The update behavior setting can defer display updates or change the polling interval. Volume tweening is handled by QML animation; no extra process or background service is needed.

No compilation or root access is required.
