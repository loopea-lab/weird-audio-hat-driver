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

**Raspberry Pi Zero 2W on 32-bit Raspberry Pi OS** (tested). Pi 1, Zero, 2 and 3 on a 32-bit OS
should work but are untested. **Not supported:** Pi 4, Pi 5, or any 64-bit OS — the codec has no
oscillator, and the helper that clocks it from the Pi's GPCLK0 only knows the 32-bit register
addresses of the older chips.

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

A provisioned unit restores its mixer state at boot: both inputs at −3 dB on the line path,
`MIC Bias` on. The DAC is always routed to the outputs. If it comes up muted, reinstall the
driver.

`MIC Bias` stays on because the Audio HAT's MIC-R BIAS switch decides whether the bias reaches the
IN R jack: with the switch off it goes nowhere, with it on an electret mic works without touching
the mixer.

## Mixer controls

| Control | Values | What it does |
|---|---|---|
| `IN L Capture Volume`, `IN R Capture Volume` | 0 mute, 1–7 = −12…+6 dB, 8 = +13 dB, 9 = +22 dB | Gain of each input jack. Up to +6 dB the line path; 8 and 9 switch to the codec's PGA and boost, for an electret on IN R or a weak source |
| `ADC Capture Volume` | −97…+30 dB | Digital level after the converter; a fine trim |
| `PCM Playback Volume` | −127…0 dB | Digital level before the DAC |
| `OUT L/R Playback Volume` | mute, −73…+6 dB | Level at the OUT L/R jack. OUT MONO does not follow it |
| `Mono Output Mixer Left/Right Switch` | on / off | What reaches OUT MONO; both = the sum |
| `Left/Right Out Mixer Monitor Switch`, `Left/Right Input Monitor Volume` | on / off, −21…0 dB | Analog input-to-output monitor, no latency. Unplug any output-to-input cable first |
| `DAC L/R Swap` | on / off | See below |
| `MIC Bias` | on / off | Keep on; the board switch decides |
| `ADC High Pass Filter Switch` | on / off | On removes DC from the recording; keep on |
| `_ADC Data Output Select` | 4 routings | e.g. IN R into both recorded channels |

The +13 and +22 dB steps are net gains measured on an R1.1 board; take them as approximate.
Crossing between 7 and 8 while recording clicks: the codec changes path.

For an electret on IN R, with the MIC-R BIAS switch on, start at 8:

```bash
amixer -c wm8960soundcard cset name='IN R Capture Volume' 8
```

Go back to 1–7 for line sources: at 8 and 9 they clip.

To configure a card by hand:

```bash
sudo /usr/bin/minimal_clk 11.2896M -m 1 -q          # master clock on GPCLK0
amixer -c wm8960soundcard cset name='IN L Capture Volume' 4
amixer -c wm8960soundcard cset name='IN R Capture Volume' 4
```

To keep your settings across reboots:

```bash
sudo alsactl --file=/etc/wm8960-soundcard/wm8960_asound.state store
```

## `DAC L/R Swap`

Swaps the playback channels inside the codec (R7 bit 5, `DLRSWAP`), for every path including
software that opens `hw:` directly. On the Audio HAT **R1.1** the output jacks are labelled
the wrong way round, so the mixer state this repo installs turns it **on**. The control itself
defaults to off; on a corrected revision, turn it off and store the state, or it swaps the
channels back. With it on, `Mono Output Mixer Left Switch` carries what software
sends on the right channel, and vice versa.

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
