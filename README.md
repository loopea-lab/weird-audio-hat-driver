# Weird Audio HAT — driver

Linux driver for the [Weird Audio HAT](https://github.com/loopea-lab/weird-audio-hat-hw), a WM8960
sound card for the Raspberry Pi.

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
> loads the overlay at boot; adding it by hand breaks enumeration.

A `Driver 'asoc-simple-card' is already registered` warning in `dmesg` is harmless.

## Requirements

**Raspberry Pi 1–4 or Zero 2W — not a Pi 5.** The codec has no oscillator of its own and
takes its master clock from the Pi's GPCLK0, which the Pi 5 does not expose.

The clock is 11.2896 MHz, the **44.1 kHz family**. 48 kHz needs a 12.288 MHz clock and a
device-tree change.

## Recording and playback

**Use `S32_LE`** (or `S16_LE` / `S24_LE`). The card does not accept `S24_3LE`: `arecord`
fails with *"Sample format non available"*, the ADC never powers on, and it looks like dead
hardware. When in doubt, run `arecord --dump-hw-params`.

```bash
arecord -D hw:wm8960soundcard -f S32_LE -r 44100 -c 2 take.wav
aplay   -D hw:wm8960soundcard take.wav
alsamixer -c wm8960soundcard
```

A provisioned unit restores its mixer state at boot: inputs on the line path, DAC routed to
the outputs, MIC bias off. If it comes up muted, reinstall the driver.

## Input routing and gain

Two input paths:

- **Line** (`Left/Right Input Line`) — a volume, 0–7, up to +6 dB. It ships at −∞ dB; it is
  not a switch, so `sset ... on` returns `Invalid command!`.
- **PGA** (`Left/Right Input Mixer MIC` on, plus `Left/Right MIC` gain) — up to +30 dB.

To configure a card by hand:

```bash
sudo /usr/bin/minimal_clk 11.2896M -m 1 -q          # master clock on GPCLK0
amixer -c wm8960soundcard sset 'Capture' 100% cap
amixer -c wm8960soundcard sset 'Left Input Line'  100%
amixer -c wm8960soundcard sset 'Right Input Line' 100%
amixer -c wm8960soundcard sset 'Left MIC' 100%
amixer -c wm8960soundcard sset 'Right MIC' 100%
```

For sound out, the `Headphone` and `Out Mixer DAC` paths must be on.

To keep your settings across reboots:

```bash
sudo alsactl --file=/etc/wm8960-soundcard/wm8960_asound.state store
```

## `DAC L/R Swap`

Swaps the playback channels inside the codec (R7 bit 5, `DLRSWAP`), for every path including
software that opens `hw:` directly. On the Audio HAT **R1.1** the output jacks are labelled
the wrong way round; turn this on to correct it. It ships **off**: on a corrected revision it
would swap the channels back.

## Checking a capture at register level

While a capture is running:

```bash
sudo cat /sys/kernel/debug/regmap/1-001a/registers | grep -E '^(19|2f):'
```

| Register | Expected | Meaning |
|---|---|---|
| `19:` | `00fc` | ADCL + ADCR + AINL + AINR on, VMID = 01 |
| `2f:` | `0030` | LMIC + RMIC on |

## Changing the driver's controls

`wm8960_asound.state` is a snapshot of every mixer control. `alsactl restore` aborts on any
control the running driver does not expose, and the codec comes up unrouted and muted. **If
you add or remove a control, regenerate the state file** on the board:

```bash
sudo alsactl store -f wm8960_asound.state
```

## Uninstall

```bash
sudo ./uninstall.sh
sudo reboot
```

## License

GPL-2.0 — see [`LICENSE`](LICENSE).

Copyright © 2024–2026 Weird Electronics / Loopea Lab.
