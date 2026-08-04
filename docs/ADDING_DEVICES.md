# Adding a Razer device

iRazer grows one device at a time. This is the playbook for going from "I plugged in
my Razer thing" to "iRazer controls it." You don't need to finish all of it — even a
capture (step 2) is a valuable contribution.

## 0. What kind of device is it?

Razer devices expose control over one or both of:

- **USB HID** — keyboards, mice, most speakers/soundbars, headsets. Uses the 90-byte
  Razer packet (see [PROTOCOL.md](PROTOCOL.md)).
- **Bluetooth LE** — newer/wireless devices and the 2023 Nommo V2 lighting. Compact
  opcode protocol over a GATT characteristic.

## 1. Identify it

```bash
swift build --build-system native
.build/debug/nommoctl list      # USB HID Razer devices: VID/PID, report sizes
.build/debug/nommoctl info      # descriptors for the matching device
.build/debug/nommoble scan      # BLE advertisements (look for a Razer name)
.build/debug/nommoble dump <name-fragment>   # BLE GATT services/characteristics
```

Record the VID:PID and which channels it exposes.

## 2. Capture the real protocol (highest-value step)

The reliable way to learn a device's commands is to watch the official software talk
to it, then diff before/after for each action (set red, set green, volume up, …):

- **USB (Windows + Synapse):** Wireshark + [USBPcap]. Save as `.pcapng`. Toggle one
  setting at a time in Synapse and note the packet. (See OpenRazer's
  [Reverse Engineering USB Protocol](https://github.com/openrazer/openrazer/wiki/Reverse-Engineering-USB-Protocol).)
- **Bluetooth (Android + Razer Audio app):** enable Developer Options →
  "Bluetooth HCI snoop log", drive the app, pull the log, open in Wireshark. Or use an
  nRF Sniffer. Diff the `ATT Write` payloads per action.

Attach the capture (or the decoded per-action bytes) to a GitHub issue. That alone
lets someone else implement the device.

## 3. Verify commands without the official app

Once you have candidate packets, replay them from macOS and confirm they work:

- USB: `nommoctl raw [tx=NN] <cls> <id> <size> <args…>`
- BLE: `nommoble raw <hex bytes…>` / `nommoble send <cls id size args…>`
- Automated visual check (lighting): point a webcam/Continuity Camera at the device and
  run `nommofuzz` (USB) or `nommoblefuzz` (BLE) — they classify the LED state from
  pixels so you don't have to eyeball every packet. Candidate lists live in `lab/`.

Label everything confirmed-on-hardware vs. guessed.

## 4. Model it in RazerKit

The core library (`Sources/RazerKit/`) provides the reusable pieces:

- `HIDDevice` — `IOHIDManager` transport (open, feature/output/input reports, enumerate).
- `RazerReport` — the 90-byte packet: build, serialize (with CRC), parse.
- `NommoDevice` — a **worked example** of a device abstraction: typed getters/setters
  (`brightness()`, `setEQBands()`, `setEffect()`, …) built on the transport.

Add a new `<YourDevice>.swift` alongside `NommoDevice.swift` exposing typed methods
for your device's confirmed commands. Keep transport generic; keep device specifics in
the device type. (A `RazerDevice` protocol + a device registry keyed by VID:PID is the
natural next refactor once there are two or three devices — propose it in your PR.)

## 5. Surface it in the app

Add the device's capabilities to the SwiftUI `Control` tab (or a per-device view). Only
show controls that are confirmed to work — gate or hide the rest (see how the Nommo V2
lighting effect/color controls are disabled until the BLE decode lands).

## 6. Document + PR

- Add a row to [DEVICES.md](DEVICES.md).
- Add the command map to [PROTOCOL.md](PROTOCOL.md) and any dead ends to [FINDINGS.md](FINDINGS.md).
- Open the PR. Small and honest beats big and speculative.

[USBPcap]: https://desowin.org/usbpcap/
