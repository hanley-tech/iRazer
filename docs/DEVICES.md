# Supported devices

Live status of Razer hardware support in iRazer. "Confirmed" means verified on real
hardware, not inferred. Want to add a row? See [ADDING_DEVICES.md](ADDING_DEVICES.md).

## Razer Nommo V2 — `1532:055C`

2.1 gaming speakers, "Actions" chipset (2023 generation).

| Capability | Channel | Status | Notes |
|---|---|---|---|
| Detection / serial / FW+HW version | USB HID | ✅ confirmed | feature report 7, tx `0x3F` |
| 10-band EQ + presets | USB HID | ✅ confirmed | `0x08/0x84` bands, `0x08/0x82` preset; flat = `0x0C` |
| Master volume (DSP) | USB HID | ✅ confirmed | `0x08/0x86` |
| LED brightness (incl. off) | USB HID | ✅ confirmed | `0x0F/0x04`, visually verified |
| Keep-awake (anti-standby) | host audio | ✅ working | firmware standby timer is read-only; host plays a 1×/min inaudible pulse |
| RGB color / effects | Bluetooth LE | 🚧 in progress | BLE channel + command grammar decoded; specific color opcode not yet pinned |
| Standby-timeout set | USB HID | ❌ not possible | firmware register is read-only |
| THX Spatial Audio | — | ⛔ out of scope | PC-side DSP, not a device setting |

Details: [PROTOCOL.md](PROTOCOL.md) · reverse-engineering log: [FINDINGS.md](FINDINGS.md).

## Wanted (no support yet)

These are common Razer devices people want on Mac. None are implemented — captures/PRs
would kick them off:

- Razer Nommo V2 Pro (`1532:055A`), Nommo V2 X (`1532:055E`) — likely close to the V2
- Leviathan V2 / V2 X soundbars
- Kraken headsets
- BlackWidow / Huntsman keyboards
- DeathAdder / Basilisk mice

> Older-generation devices (Nommo Chroma/Pro, Leviathan V2) are already handled by
> [OpenRazer](https://github.com/openrazer/openrazer) / [razer-macos](https://github.com/1kc/razer-macos)
> over USB HID. iRazer focuses on newer devices those projects don't cover, and on
> audio/EQ/power in addition to lighting.
