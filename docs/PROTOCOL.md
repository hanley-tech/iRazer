# Razer Nommo V2 — USB Protocol (reverse-engineered on macOS)

Verified live against hardware on 2026-08-04, macOS 27 (Apple Silicon), firmware/HW v1.3,
serial `472316B05000752`. Every command below returned status `0x02 SUCCESS` unless noted.

## Device identity

| Field | Value |
|---|---|
| Vendor ID | `0x1532` (Razer) |
| Product ID | `0x055C` (Nommo V2 2.1 speakers) |
| Chipset | Actions Semiconductor (USB manufacturer string "Actions") |
| Related PIDs | `0x055A` Nommo V2 Pro, `0x055E` Nommo V2 X |

## USB interfaces

| # | Class | Purpose |
|---|---|---|
| 0 | HID (2 interrupt EPs, 64 B) | Razer control protocol + media keys |
| 1 | Audio Control | UAC mute/volume feature unit (macOS native volume works through this) |
| 2 | Audio Streaming | 48 kHz 16-bit stereo PCM, isochronous |

No kernel driver needed — everything is reachable from userspace via `IOHIDManager`.

## HID reports (interface 0)

| Report ID | Type | Size | Role |
|---|---|---|---|
| 1 | Input | 1 B | Consumer-control media keys (vol up/down, mute, transport) |
| 3 | Output | 91 B | declared Data — writes are ACKed but **ignored** by firmware |
| 5 | Input | 15 B | unknown (likely async notifications) |
| 7 | Feature | 90 B | **Razer command channel** (declared Constant, but SET works with ID-prefixed buffer) |

## Command framing (the key macOS-specific finding)

Commands are the standard 90-byte OpenRazer packet sent as a **SET_REPORT(feature, ID 7)**
whose payload must **include the report-ID byte**: `[0x07] + 90-byte packet` (91 bytes total).
`IOHIDDeviceSetReport` does *not* prepend the ID on macOS — send it bare (90 bytes) and the
device STALLs (`kIOReturnTimeout`). Read the response ~60 ms later with GET_REPORT(feature, 7).

90-byte packet layout (OpenRazer `razer_report`):

```
offset 0   status            0x00 on send; response: 02=OK 01=busy 03=fail 04=timeout 05=unsupported
offset 1   transaction id    0x3F for this device family
offset 2-3 remaining packets 0
offset 4   protocol type     0
offset 5   data size         payload length
offset 6   command class
offset 7   command id        GET = SET id | 0x80
offset 8   args[80]
offset 88  crc               XOR of bytes 2..87
offset 89  reserved          0
```

## Command map (all verified on hardware except where noted)

### Class 0x00 — device info
| Cmd | Size | Meaning | Observed response |
|---|---|---|---|
| `0x81` | 2 | device mode | `00 00` |
| `0x82` | 22 | serial number | ASCII `472316B05000752` |
| `0x87` | 2 | hardware version | `01 03` = v1.3 |
| `0x8D` | 2 | device type | `00 00` |

### Class 0x07 — power
| Cmd | Size | Meaning | Observed |
|---|---|---|---|
| `0x83` / set `0x03` | 3 | idle/standby timeout, big-endian seconds at args[1..2]; `0` disables | `03 84` = 900 s |
| `0x88` / set `0x08` | 2 | power-saving toggle, args[1] bool | `00 01` = on |

### Class 0x08 — audio DSP
| Cmd (GET/SET) | Size | Meaning | Observed |
|---|---|---|---|
| `0x82` / `0x02` | 2 | EQ preset, args[1] 0–3 | `00 02` |
| `0x84` / `0x04` | 11 | 10-band EQ (31 Hz→16 kHz), `0x0C` = flat/center | `00` + `0c`×10 |
| `0x86` / `0x06` | 2 | master volume 0–100 at args[1] | read `00 00` (SET untested — device is live audio output) |
| `0x8A` / `0x0A` | 2 | audio source (03=BT, 04=USB on V2 X) | `00 00` |

### Class 0x0F — Chroma lighting (extended matrix)
| Cmd | Args | Verified |
|---|---|---|
| set brightness `0x04` | `[0x01, led=0x00, 0–255]` | ✓ set 0x7F, read back 0x7F |
| get brightness `0x84` | `[0x01, 0x00, —]` | ✓ |
| effect `0x02` static | `[0x01, 0x00, 0x01, 0, 0, 0x01, r, g, b]` (size 9) | ✓ accepted |
| effect `0x02` off | `[0x01, 0x00, 0x00, 0, 0, 0]` (size 6) | sent, ACKed |
| effect `0x02` breathing | `[0x01, 0x00, 0x02, 0, 0, 0x01, r, g, b]` | untested visually |
| effect `0x02` spectrum | `[0x01, 0x00, 0x03, 0, 0, 0]` | ✓ accepted |
| effect `0x02` wave | `[0x01, 0x00, 0x04, dir, 0, 0]` | untested visually |
| get effect `0x82` | | returns zeros — may need different args |

## Lighting findings (hardware-verified via Protocol Lab, 2026-08-04)

The lighting picture is more complicated than the audio/power protocol:

- **Physical layout:** each speaker is a single uniform color zone (2 zones total,
  one per L/R speaker), rear-projection. Default state: spectrum cycle.
- **Brightness works** and is visually confirmed: `0x0F/0x04` args `[0x01, 0x00, 0-255]`,
  accepted on BOTH transaction IDs 0x3F and 0x1F. 0 = lights off. GET `0x84` returns
  the real stored value.
- **Everything else in the lighting classes is a facade.** The firmware returns
  SUCCESS and echoes args for: extended effects (`0x0F/0x02` — all var stores, LED
  IDs 0-8, both tx IDs), extended custom frames (`0x0F/0x03`, geometries 2/9/14/18/24
  LEDs, with/without software device mode), classic effects (`0x03/0x0A` — most IDs),
  and every GET except brightness. SET device mode 3 ACKs but reads back 0.
- Classic effect `0x03/0x0A` id `0x04` (spectrum) twice registered a visible "changed"
  — possibly an animation restart. Under investigation.
- Extended `0x0F/0x02` var-store 1 writes were once observed to change animation
  speed. Unconfirmed.
- Conclusion: the effect/animation engine is controlled by something other than the
  documented Razer HID commands — candidates: the Actions Semiconductor vendor
  protocol over the 91-byte output / 15-byte input reports, a USB Audio class
  side-channel, or the Bluetooth LE interface used by the Razer Audio mobile app.

The Protocol Lab (app "Lab" tab + `lab/experiments.json` → `lab/results.jsonl`)
is the harness for continuing this: batches of candidate packets, one-click user
verdicts, bulk analysis.

## Lighting lives on Bluetooth LE, not HID (confirmed 2026-08-04)

Two automated camera-fuzzer passes (173 candidates + 22-shot confirmation, machine
hue/brightness classification, `nommofuzz`) proved **no HID packet controls the
animation**. Every apparent "hit" was spectrum-cycle drift — none reproduced across
repeats. The HID lighting classes (0x03, 0x0F) are a facade on this firmware; only
brightness (`0x0F/0x04`) is real. Standby timeout (`0x07/0x03`) is also read-only.

The speaker continuously advertises a **BLE peripheral "Razer Nomv2 LE"**
(service FFC0 in the advert). This is the channel the Razer Audio mobile app uses.
GATT dump (`nommoble dump nomv2`):

- Device Information: Serial = `ACTIONS-STUB-000`, FW rev `01 00 02 00`
- Service FD65
- **Service E49A25F8-F69A-11E8-8EB2-F2801F1B9FD1** — the control service:
  - `416D0000-2D52-617A-6572-424C4501F40A` — **writeWithoutResponse** (command in).
    The UUID base ASCII-decodes to `Am-Razer BLE…` — this is the Razer BLE command pipe.
  - `416D0001-2D52-617A-6572-424C4501F40A` — notify (responses/events)
  - `E49A28E1-…` read|notify, `E49A25E0-…` read|write|writeNR (larger buffers)

Next step for lighting: write candidate packets to `416D0000…` and watch the camera —
same fuzzer harness, BLE transport instead of HID. The 90-byte Razer packet (or a
BLE-chunked variant) is the likely payload.

Tools: `nommoble scan` / `nommoble dump <name>` for GATT recon,
`nommoble opsweep` for command-table discovery, `nommoble probe`.

### BLE command grammar (decoded 2026-08-04)

Connection needs **no pairing / no bonding / no PIN** — open GATT, 182-byte MTU.
The lighting protocol is a **compact opcode protocol, NOT the 90-byte HID razer_report.**
Write to char `416D0000…`, responses arrive as notifies on `416D0001…`.

Response frame: `[opcode] [type] [len] [value…]`
- type `0x01` = reply to our command; type `0x02` = unsolicited state-change notification
- **SET opcode = GET opcode | 0x80** (confirmed: writing `0x93` produced a `0x13`
  type-0x02 change notification, i.e. 0x93 sets what 0x13 gets)

Responsive opcodes found by `opsweep` (GET form, sent `[op,00,00,00,00]`):

| GET | reply value | likely meaning |
|-----|-------------|----------------|
| 0x02 | `01 03 00 00` | ? (4-byte struct) |
| 0x03 | `05 5d` | ? |
| 0x10 | `12 02 ff 00` | effect/mode struct (has an 0xff) |
| 0x11 | `12` | ? |
| 0x13 | `ff` | **brightness (255)** |
| 0x1a | `00` | toggle |
| 0x20 | `01` | toggle/state |
| 0x25 | `00` | ? |
| 0x27 | `00` | ? |
| 0x61 | `00` | ? |
| 0x62 | `02` | ? (source/mode?) |

Others also ACK (0x93/0x9a/0xa0 = SET forms of 0x13/0x1a/0x20).

**Open:** which opcode carries RGB. The color is likely a multi-byte struct under
one opcode (0x10 is the prime suspect — it returns a 4-byte value including 0xff).
Correct approach: GET the opcode to learn its exact length, then SET (op|0x80) with
the same length and modified color bytes, camera-correlating red vs green.
NOTE: payload length appears to be validated — wrong-length SETs are silently
dropped (no notify), so blind fixed-length fuzzing mostly misses. GET-then-SET
with matching length is required.

## Open questions

- Visual confirmation of RGB effects (commands ACK; user must confirm LEDs change).
- Master-volume GET returns 0 — verify SET while audio is playing; macOS native volume
  already works via the UAC interface regardless.
- Custom per-LED frames (`0x0F/0x03` matrix rows) — LED count/layout unknown.
- Report 5 input payloads (subwoofer status? knob events?) — attach an input-report
  listener and observe.
- THX/spatial mode — not present in the V2 X map; candidate classes to sweep: 0x08 ids
  0x87/0x89/0x8B‥0x8F with `raw`.

## Sources

- Live probing with `nommoctl` (this repo).
- [openrazer #2758 — Nommo V2 X protocol notes](https://github.com/openrazer/openrazer/issues/2758) (command map)
- [openrazer #2172 — Nommo V2 device report](https://github.com/openrazer/openrazer/issues/2172) (lsusb/descriptors)
- [OpenRazer](https://github.com/openrazer/openrazer) (packet format, CRC, extended-matrix effects)
