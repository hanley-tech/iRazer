# Contributing to iRazer

Thanks for helping build the Razer control app macOS never got. The goal is broad:
**support as many Razer devices as possible on the Mac.** The Nommo V2 is just the
first. Contributions of new devices, protocol captures, fixes, and UI work are all welcome.

## Ways to help

1. **Add support for your Razer device.** Even a USB/Bluetooth capture is hugely
   valuable — see [docs/ADDING_DEVICES.md](docs/ADDING_DEVICES.md).
2. **Improve an existing device.** e.g. finish the Nommo V2 Bluetooth RGB decode
   (see [docs/FINDINGS.md](docs/FINDINGS.md) for exactly where it stands).
3. **App / UX** — menu-bar mode, launch-at-login, per-device UI.
4. **Docs** — anything that helps the next person.

## Development setup

```bash
git clone https://github.com/<you>/iRazer.git
cd iRazer
swift build --build-system native      # default backend errors on some toolchains
```

Layout:

```
Sources/RazerKit/      core library: HID + BLE transport, Razer packet, device APIs
Sources/iRazer/        SwiftUI app (Control / Lab / Console tabs)
Sources/nommoctl/      USB HID CLI
Sources/nommoble/      Bluetooth LE CLI
Sources/nommofuzz/     USB camera-feedback fuzzer
Sources/nommoblefuzz/  BLE camera-feedback fuzzer
docs/                  protocol map, findings log, device matrix, how-to-add-devices
lab/                   reverse-engineering experiment inputs + logs
```

## Ground rules

- **Test on your own hardware only.** Sending commands to devices you don't own is
  out of scope and not okay.
- **No fabricated protocol data.** If a value is a guess, label it a guess. The
  findings log distinguishes confirmed-on-hardware from inferred — keep that honesty.
- **Match the surrounding Swift style.** Small, focused PRs.
- **Don't commit captured result logs** (`lab/*results*.jsonl` are gitignored); do
  commit reusable experiment *inputs* and documented findings.
- Be respectful. This is a hobbyist interoperability project, not a Razer product.

## Reporting a device

Open an issue titled `Device support: <name> (<VID:PID>)` and include:

- `nommoctl list` and `nommoctl info` output (USB), and/or `nommoble scan` / `nommoble dump` (BLE)
- What Synapse can do with it that you want on Mac
- A USB or Bluetooth capture if you can (see the how-to)

## Legal

By contributing you agree your work is MIT-licensed. This project is not affiliated
with Razer Inc.; only contribute reverse-engineering of devices you own, for
interoperability.
