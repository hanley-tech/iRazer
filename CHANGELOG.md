# Changelog

All notable changes to iRazer are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- Initial public release: open-source Razer control for macOS (Synapse alternative).
- **Razer Nommo V2 (`1532:055C`)** support:
  - Device detection, serial, firmware/hardware version (USB HID).
  - 10-band EQ + presets, master volume, LED brightness — all confirmed on hardware.
  - **Keep-awake**: host-side inaudible pulse (1×/min) to defeat audio-idle standby,
    since the firmware standby timer is read-only.
  - **Lights out with the display** (on by default, except in Keep-awake "Always"):
    dims the LEDs to 0 as soon as the display or computer sleeps, and restores them
    on wake. Without it the LEDs stay lit until the speakers' own standby timer
    (default 15 min, reset by *any* audio on the Mac) expires — so a 10-minute
    display sleep would leave them glowing at a dark desk.
- SwiftUI app with **Control**, **Lab**, and **Console** tabs.
- `RazerKit` core library (HID + BLE transport, Razer 90-byte packet, device API).
- CLI tools: `nommoctl` (USB), `nommoble` (BLE), `nommofuzz` / `nommoblefuzz`
  (camera-feedback protocol fuzzers).
- Docs: protocol map, reverse-engineering findings, device matrix, how-to-add-devices.

### In progress
- Nommo V2 RGB color/effects over Bluetooth LE — channel and command grammar decoded;
  specific color opcode not yet pinned (see `docs/FINDINGS.md`).

### Known limitations
- Color/effect controls are shown but disabled in the app until the BLE decode lands.
- Standby-timeout cannot be set on-device (firmware register is read-only).
