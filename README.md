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

## Changing the driver's controls

`wm8960_asound.state` is a snapshot of **every** mixer control. `alsactl restore` fails on
any control the running driver does not expose, exits non-zero, and the service is marked
`failed` — so **nothing** gets restored and the codec comes up unrouted and muted.

That means: **if you add or remove a control, regenerate the state file.**

```bash
# on the board, with the mixer configured the way it should come up
sudo alsactl store -f wm8960_asound.state
```

This bit us twice. The state that shipped until 2026-08-05 came from a different build of
the driver: 64 controls against the 42 this one has. And adding `DAC L/R Swap` broke it
again the same afternoon, for the same reason.

## `DAC L/R Swap`

Sets the WM8960's playback channel swap (R7 bit 5, `DLRSWAP`). It exists because on the
Audio HAT **R1.1** the two output net labels are swapped against the codec's own pins, so
the jack silkscreened `LINE OUT L` carries the right channel. The swap undoes it inside
the chip, which corrects every path — including software that opens `hw:` directly.

It ships **off**. Turn it on for boards whose routing has the fault; on a revision with
the routing corrected, leaving it on would swap the channels right back.

## Documentation

Full manual for the Weird system: **https://github.com/loopea-lab/weird**
