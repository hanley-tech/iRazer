<div align="center">

# ⚡ iRazer

### Open-source Razer control for macOS — a native Synapse alternative for Apple Silicon.

Control your Razer devices on your Mac **without Razer Synapse**: RGB, EQ, volume,
brightness, and power — in a clean native app. First supported device: the **Razer Nommo V2**.

<br>

[![Platform](https://img.shields.io/badge/macOS-14%2B-000?logo=apple&logoColor=white)](https://github.com/hanley-tech/iRazer)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-native-44D62C)](https://github.com/hanley-tech/iRazer)
[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](https://github.com/hanley-tech/iRazer)
[![License: MIT](https://img.shields.io/badge/License-MIT-44D62C.svg)](LICENSE)
[![Website](https://img.shields.io/badge/website-hanley--tech.github.io%2FiRazer-44D62C)](https://hanley-tech.github.io/iRazer/)

**[⬇ Download](https://github.com/hanley-tech/iRazer/releases) · [🌐 Website](https://hanley-tech.github.io/iRazer/) · [🧩 Add a device](docs/ADDING_DEVICES.md)**

<br>

<img src="docs/assets/screenshot.png?v=3" alt="iRazer controlling a Razer Nommo V2 on macOS — device dashboard with lighting, EQ, and power" width="820">

<sub>*Not affiliated with, authorized, or endorsed by Razer Inc. "Razer", "Synapse", and
"Chroma" are trademarks of Razer Inc., used here only to describe compatibility.*</sub>

</div>

---

## What is iRazer?

**iRazer is a free, open-source native macOS app that controls Razer devices —
RGB lighting, EQ, volume, brightness, and power — without Razer Synapse.** It's a
Synapse alternative for Apple Silicon and Intel Macs. The first supported device is
the Razer Nommo V2.

## Why this exists

Razer Synapse doesn't run on macOS. If you own Razer gear and a Mac, you get no
lighting control, no EQ, no device settings — nothing. iRazer talks to Razer hardware
directly over USB and Bluetooth, so you can control your devices from your Mac with no
Razer account, no background services, and no proprietary software.

It's built device-by-device from real reverse-engineering. The Razer Nommo V2 is the
first fully-integrated device; the architecture is designed so more Razer devices
(keyboards, mice, speakers, headsets) can be added over time.

## Features

- 🎛️ **Native macOS app** (SwiftUI) — menu-bar-friendly, no daemon, no login.
- 🔌 **Direct device control** over USB HID and Bluetooth LE — no Synapse, no kext, no root.
- 🍏 **Apple Silicon–first** (M1/M2/M3/M4), also runs on Intel Macs.
- 🧰 **CLI tools + reverse-engineering harness** for adding new devices.
- 🔓 **MIT-licensed**, community-driven.

## Supported devices

<div align="center">
<img src="docs/assets/devices/nommo.svg?v=2" width="70" alt="Razer Nommo V2">
&nbsp;&nbsp;&nbsp;
<img src="docs/assets/devices/soundbar.svg" width="70" alt="Leviathan">
&nbsp;&nbsp;&nbsp;
<img src="docs/assets/devices/keyboard.svg" width="70" alt="keyboards">
&nbsp;&nbsp;&nbsp;
<img src="docs/assets/devices/mouse.svg" width="70" alt="mice">
&nbsp;&nbsp;&nbsp;
<img src="docs/assets/devices/headset.svg" width="70" alt="headsets">
<br>
<sub>Original minimalist device glyphs — no Razer imagery is bundled. The Nommo V2 is live; the rest are on the roadmap.</sub>
</div>

| Device | USB PID | Audio / EQ | Volume | Brightness | RGB color / effects | Power |
|---|---|:--:|:--:|:--:|:--:|:--:|
| **Razer Nommo V2** | `1532:055C` | ✅ | ✅ | ✅ | 🚧 Bluetooth (in progress) | ⚙️ keep-awake |

Legend: ✅ working · 🚧 in progress · ⚙️ workaround. See
[`docs/DEVICES.md`](docs/DEVICES.md) for the details and
[`docs/FINDINGS.md`](docs/FINDINGS.md) for the full protocol reverse-engineering log.

**Want your device supported?** See [Adding a device](docs/ADDING_DEVICES.md) — the
whole point of the project is to grow this table. Captures and PRs welcome.

## Install

**Download (DMG):** grab `iRazer-x.y.z.dmg` from
[Releases](https://github.com/<you>/iRazer/releases), open it, drag **iRazer** to
Applications. The app isn't notarized yet, so on first launch **right-click →
Open** once to get past Gatekeeper (a paid Apple Developer ID is needed to remove
that warning — contributions/sponsorship welcome).

**Build from source:** requires macOS 14+ and the Swift toolchain (Xcode or CLT).

```bash
git clone https://github.com/<you>/iRazer.git
cd iRazer
./Scripts/make-app.sh        # builds build/iRazer.app
open build/iRazer.app
./Scripts/make-dmg.sh        # optional: package a DMG in build/
```

> Build note: `make-app.sh` uses `swift build --build-system native` because the
> default SwiftBuild backend errors with "Unknown error parsing property list" on
> some toolchains.

### Menu-bar app

iRazer lives in the **menu bar**, not the Dock. Closing the window doesn't quit it —
it stays resident and available from the ⚡ menu-bar item, which has quick
brightness/volume/keep-awake controls and "Open iRazer…". Footprint is small (the
keep-awake audio engine only runs when enabled; otherwise it's just a light 3-second
connection poll). Quit from the menu-bar item.

## The app

Three tabs:

- **Control** — device status, lighting (brightness live; color/effects gated on the
  Bluetooth work), 10-band EQ + presets, master volume, and a **Keep speakers awake**
  toggle (plays a brief inaudible pulse once a minute to defeat audio-idle standby).
- **Lab** — steps through reverse-engineering experiment batches and logs verdicts.
- **Console** — free-form packet composer, live input-report monitor, and sweeps.

## Command-line tools

For power users and contributors (`swift build --build-system native`, then `.build/debug/…`):

- **`nommoctl`** — USB HID control: `list`, `info`, `probe`, `volume`, `brightness`,
  `rgb`, `effect`, `idle-timeout`, `raw`.
- **`nommoble`** — Bluetooth LE: `scan`, `dump`, `opsweep`, `getall`, `probe`, `send`, `raw`.
- **`nommofuzz` / `nommoblefuzz`** — camera-feedback protocol fuzzers that classify
  the LED state automatically (no human "did it change?" needed).

## How it works

Razer devices speak a well-documented 90-byte command protocol (the same one
[OpenRazer](https://github.com/openrazer/openrazer) implements on Linux). iRazer
sends it from userspace via `IOHIDManager` (USB) and `CoreBluetooth` (BLE):

- **USB HID** carries audio/EQ/volume/brightness/device-info on the Nommo V2.
- **Bluetooth LE** carries the RGB lighting on the 2023 "Actions"-chipset Nommo V2 —
  a channel no open project had touched before this one. Grammar decoded; specific
  color command still being pinned (see [`docs/FINDINGS.md`](docs/FINDINGS.md)).

Full protocol map: [`docs/PROTOCOL.md`](docs/PROTOCOL.md).

## Roadmap

- [x] Nommo V2: detection, EQ, volume, brightness, keep-awake
- [x] Reverse-engineering harness (CLI + camera fuzzers)
- [x] Nommo V2 Bluetooth channel + command grammar decoded
- [x] Menu-bar resident app + device dashboard (all Razer gear listed)
- [x] DMG packaging
- [ ] Nommo V2 RGB color/effects over Bluetooth
- [ ] Launch-at-login
- [ ] More devices (Kraken, Leviathan, BlackWidow, DeathAdder, …) — contributions welcome
- [ ] Signed/notarized release + Homebrew cask

## Contributing

New devices, protocol captures, and fixes are all welcome — see
[CONTRIBUTING.md](CONTRIBUTING.md) and [docs/ADDING_DEVICES.md](docs/ADDING_DEVICES.md).
The fastest way to help: capture your device's USB or Bluetooth traffic and open an issue.

## Related projects

- [OpenRazer](https://github.com/openrazer/openrazer) — Linux driver/daemon (protocol reference)
- [razer-macos](https://github.com/1kc/razer-macos) — macOS lighting app (older device generations)
- [Polychromatic](https://github.com/polychromatic/polychromatic) — OpenRazer frontend

iRazer targets newer, unsupported devices (starting with the 2023 Nommo V2) and
covers audio/EQ/power, not just lighting.

## FAQ

### Is there a Razer Synapse for Mac?
No — Razer does not make Synapse for macOS. iRazer is a free, open-source alternative
that controls Razer devices natively on macOS (Apple Silicon and Intel).

### How do I control a Razer Nommo V2 on a Mac?
Install iRazer (download the DMG or build from source), plug the Nommo V2 in over USB,
and open iRazer. You get brightness, 10-band EQ, presets, master volume, and a
keep-awake toggle today; RGB color/effects (over Bluetooth) are in progress.

### Is iRazer free?
Yes. It's MIT-licensed and open source, with no account, subscription, or telemetry.

### Does it need Razer Synapse installed?
No. iRazer talks to the hardware directly over USB HID and Bluetooth LE. Synapse is
not required and does not need to be installed.

### Which Macs are supported?
macOS 14 or later, on both Apple Silicon (M1/M2/M3/M4) and Intel Macs.

### Which Razer devices does iRazer support?
The Razer Nommo V2 is fully integrated (audio/EQ/volume/brightness). The app lists the
broader Razer lineup and is built to add more devices — see [DEVICES.md](docs/DEVICES.md)
and [ADDING_DEVICES.md](docs/ADDING_DEVICES.md).

### Is it safe / does it need admin rights?
It runs entirely in userspace — no kernel extension, no root. It only talks to Razer
devices you have plugged in.

### How is this different from OpenRazer or razer-macos?
Those target older device generations (mostly over USB HID, Linux-first for OpenRazer).
iRazer is macOS-native, covers audio/EQ/power in addition to lighting, and targets newer
devices those projects don't — starting with the 2023 Razer Nommo V2.

## License

[MIT](LICENSE). Not affiliated with Razer Inc.

---

<div align="center">
<sub>Keywords: Razer Synapse for Mac · Razer Synapse macOS alternative · control Razer
on Mac · Razer Chroma macOS · Razer Nommo V2 Mac · Apple Silicon Razer · open-source Razer driver.</sub>
</div>
