# Weird Audio HAT — driver

Linux driver for the [Weird Audio HAT](https://github.com/loopea-lab/weird): a WM8960 sound card for the Raspberry Pi.

https://weirdelectronica.tech/

## Install

```bash
git clone https://github.com/loopea-lab/weird-audio-hat-driver
cd weird-audio-hat-driver
sudo ./install.sh
sudo reboot
```

After the reboot the card should appear:

```bash
aplay -l      # → card N: wm8960soundcard [wm8960-soundcard]
arecord -l    # same for capture
```

> **Do not add `dtoverlay=wm8960-soundcard` to `/boot/config.txt`.** A systemd service
> loads the overlay at runtime; adding it by hand breaks enumeration.

## Requirements

**Raspberry Pi 1–4 or Zero 2W — not a Pi 5.** The codec has no oscillator of its own and
takes its master clock from the Pi's GPCLK0, which the Pi 5 does not expose.

## Usage

**Capture must use `S32_LE`.** The card accepts `S16_LE`, `S24_LE` and `S32_LE`, but *not*
`S24_3LE` — with that format `arecord` fails, the stream never starts, and it looks like
the input is dead.

```bash
# record
arecord -D hw:1,0 -f S32_LE -r 44100 -c 2 take.wav

# play back
aplay -D hw:1,0 take.wav

# levels
alsamixer
```

Input routing, gain and the full recipe: **[Audio from code](https://github.com/loopea-lab/weird/blob/main/software/audio.md)**.

To save mixer settings:

```bash
sudo alsactl --file=/etc/wm8960-soundcard/wm8960_asound.state store
```

## Uninstall

```bash
sudo ./uninstall.sh
sudo reboot
```

## Documentation

Full manual for the Weird system: **https://github.com/loopea-lab/weird**
