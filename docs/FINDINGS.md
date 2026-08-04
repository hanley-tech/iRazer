# Nommo V2 reverse-engineering — findings log

Chronological record of what was tried and what it proved, so the next session
doesn't repeat dead ends. Hardware: Razer Nommo V2 `1532:055C`, serial
`472316B05000752`, HW v1.3, on macOS 27 / Apple Silicon, 2026-08-04.

## Confirmed working (USB HID, feature report 7)

The device speaks the standard 90-byte OpenRazer packet over HID **feature report 7**,
with the report-ID byte manually prefixed (`[0x07] + 90 bytes`) and transaction ID
`0x3F`. These all returned status `0x02 SUCCESS` and, where visible, were confirmed:

- Serial, firmware/hardware version, device mode
- **EQ**: 10-band (`0x08/0x84`, flat = `0x0C`) and presets (`0x08/0x82`)
- **Volume**: DSP master (`0x08/0x86`)
- **Brightness**: `0x0F/0x04` args `[0x01,0x00,0-255]` — visually confirmed (set 0 = off)

## Confirmed dead ends (don't retry these)

| What | Evidence |
|---|---|
| HID lighting effects (class 0x0F/0x02, 0x0F/0x03 custom frames, class 0x03/0x0A) | 173-candidate + 22-shot camera fuzz: every apparent hit was spectrum-cycle drift, none reproduced. Firmware fake-ACKs. |
| Standby timeout SET (`0x07/0x03`) | Read-only: reads back factory `900s` on every transaction ID and arg layout; writes ignored. |
| Bare 90-byte feature write (no ID prefix) | Stalls with `kIOReturnTimeout`. |
| Output report 3 as command channel | ACKed but ignored by firmware. |

## Key discovery: lighting is on Bluetooth LE, not USB

The speaker continuously advertises **`Razer Nomv2 LE`** (BLE, service FFC0). Its GATT
control service `E49A25F8-…` exposes:
- `416D0000-2D52-617A-6572-424C4501F40A` — writeWithoutResponse (commands in)
- `416D0001-…` — notify (responses/events out)

Connection needs **no pairing/PIN/bonding** (open GATT, 182-byte MTU). This is the
channel the Razer Audio mobile app uses; the manual confirms Bluetooth mode drives the
audio-reactive lighting.

## BLE command grammar (decoded)

Compact opcode protocol — **NOT** the HID razer_report. Response frame:
`[opcode] [type] [len] [value…]`, type `0x01` = reply, `0x02` = change notification.
**SET opcode = GET opcode | 0x80** (writing `0x93` triggered a `0x13` change notify).

Responsive opcodes (`nommoble opsweep`, sent `[op,00,00,00,00]`):

| GET | reply | note |
|---|---|---|
| 0x13 | `ff` | **brightness = 255** |
| 0x10 | `12 02 ff 00` | effect/mode struct — RGB suspect |
| 0x02 | `01 03 00 00` | 4-byte struct |
| 0x03 | `05 5d` | |
| 0x11 | `12` | |
| 0x1a | `00` | toggle |
| 0x20 | `01` | toggle |
| 0x25,0x27,0x61 | `00` | |
| 0x62 | `02` | |

SET forms 0x93/0x9a/0xa0 (= 0x13/0x1a/0x20 | 0x80) also ACK.

## BLE lighting decode attempt (2026-08-04, session 2) — INCONCLUSIVE

Earlier in the session I believed `82 01 01 00 00` set static green. **A later
GET-diff disproved this:** after sending it, opcode `0x02` still reads
`01 03 00 00` (byte1 = 0x03 = spectrum). The "green" was a coincidental frame of
the rainbow cycle; the command's real effect was destabilizing the speaker
(caused the power-offs). **No confirmed command yet switches effect/mode over BLE.**

Solid negative result worth keeping: reading all responsive opcodes (0x00-0x7f)
twice, a minute apart, while cycling, returned **identical values both times**:

```
02: 01 04 01 03 00 00     10: 01 04 18 02 00 00     13: 01 01 00
03: 01 02 05 5d           11: 01 01 18             1a: 01 01 00
20: 01 01 01              25: 01 01 00             26: 01 01 00
60: 01 01 00              62: 01 01 02
```

→ The live spectrum color is **not stored in any readable opcode** — the firmware
generates the animation internally. So read-and-diff can only find the color register
once the device is genuinely in static mode, which we cannot yet force. Blind SET
fuzzing also fails (destabilizes the device; wrong-length payloads silently dropped).

**Conclusion: BLE is confirmed as the lighting channel and its command grammar is
decoded, but the effect/color commands cannot be reverse-engineered by blind probing.
The reliable path is capturing the Razer Audio mobile app's BLE writes (below).**

### Why the full color decode stalled this session

1. **Device destabilizes under fuzzing.** Repeated writes (especially SET opcodes
   0x82/0x9a/0xa0) power-cycled the speaker several times; the user had to physically
   re-power it. Afterward it answered only 1 of ~15 previously-responsive opcodes —
   a degraded/limited state. A physical power-cycle (or waiting) should recover it.
2. **Likely missing session init.** The Razer Audio mobile app almost certainly sends
   a handshake/auth/session-open command on connect before the device fully accepts
   color/custom commands. Without it, many opcodes are ignored or the device bails.
3. **Effect overrides color.** While in spectrum mode the cycle overwrites any static
   color, so color tests must set static mode first (now known: `82 01 01 00 00`).

### Correct next-session approach (don't repeat the brute force)

1. Start from a freshly power-cycled speaker (all ~15 opcodes responsive).
2. Capture the mobile app's BLE writes if possible (nRF Connect / a BLE sniffer) to
   learn the session-init sequence — this is the highest-leverage single step.
3. With a `getall` read-only baseline: set static, then set a distinct color via the
   mobile app, `getall` again, and diff — the opcode whose value becomes the RGB is
   the color register. (This avoids all destructive SET fuzzing.)
4. Only then wire color into the app.

## Open (next steps, in priority order)

1. **RGB opcode.** Payload length is validated — wrong-length SETs are silently dropped,
   so blind fixed-length fuzzing misses. Correct method: GET a candidate opcode (0x10
   first) to learn its length, then SET (`op|0x80`) with modified color bytes at that
   exact length, camera-correlating a red vs green send (`nommoblefuzz`).
2. Decode remaining opcodes (0x02, 0x03, 0x11, 0x1a, 0x20, 0x62).
3. Button/knob events: subscribe BLE notify + USB HID input report 5 while pressing
   physical controls.

## Gotchas for the next session

- Build with `swift build --build-system native`; the default SwiftBuild backend errors
  with "Unknown error parsing property list" on this toolchain.
- `nommofuzz`/`nommoblefuzz` need the camera physically aimed at the speaker glow. A
  bumped camera silently invalidates a whole run (readings track the room, not the LEDs).
  Always `nommofuzz snap` first and eyeball `/tmp/fuzz-view.jpg`.
- The `opsweep` sends zeros to SET opcodes and can change settings (e.g. brightness→0);
  restore with `nommoctl brightness 100` afterward.
- Camera classification is before/after comparison, not absolute — the idle spectrum
  cycle drifts a few degrees/sec, so only hue *jumps* >30° or brightness blackouts count.
