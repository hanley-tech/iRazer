import Foundation
import RazerKit

// nommoctl — research CLI for the Razer Nommo V2 on macOS.
//
// Subcommands:
//   list                Enumerate Razer HID devices (VID 0x1532)
//   info                Dump descriptors + report sizes for the Nommo V2
//   probe               Send safe read-only Razer queries (fw version, serial,
//                       device mode) over the feature-report channel and print
//                       raw responses. Tries several transaction IDs.
//   raw <hex...>        Send an arbitrary 90-byte razer packet (advanced;
//                       provide cls id datasize arg0 arg1 ... as hex bytes)

// Per the HID descriptor: output report ID 3 (91 bytes, Data) is the command
// channel; feature report ID 7 (90 bytes, Constant/read-only) is the response
// channel. SET_REPORT on the feature report stalls (kIOReturnTimeout).
let outputReportID: CFIndex = 3
let outputReportLen = 91
let featureReportID: CFIndex = 7   // 90-byte feature report per HID descriptor

func findNommo() -> HIDDevice? {
    // Prefer the HID device that actually exposes the 90-byte feature report.
    enumerateHIDDevices().first { $0.maxFeatureReportSize >= RazerReport.size }
        ?? enumerateHIDDevices().first
}

func cmdList() {
    let devices = enumerateHIDDevices()
    if devices.isEmpty {
        print("No Razer (VID 0x1532) HID devices found.")
        return
    }
    for d in devices {
        print(String(format: "VID 0x%04x  PID 0x%04x  usagePage %d usage %d  in/out/feat %d/%d/%d  %@ (%@)",
                     d.vendorID, d.productID, d.usagePage, d.usage,
                     d.maxInputReportSize, d.maxOutputReportSize, d.maxFeatureReportSize,
                     d.product, d.manufacturer))
    }
}

func cmdInfo() {
    guard let d = findNommo() else { print(NommoError.notFound.description); exit(1) }
    print("Product:       \(d.product)")
    print("Manufacturer:  \(d.manufacturer)")
    print(String(format: "VID/PID:       0x%04x / 0x%04x", d.vendorID, d.productID))
    print("Usage:         page \(d.usagePage) usage \(d.usage)")
    print("Report sizes:  input \(d.maxInputReportSize), output \(d.maxOutputReportSize), feature \(d.maxFeatureReportSize)")
    if let rd = d.reportDescriptor {
        print("\nHID report descriptor (\(rd.count) bytes):")
        print(hexDump(rd))
    }
}

enum Framing: String, CaseIterable {
    case outputPrefixed, outputBare, featurePrefixed, featureBare
}

func sendQuery(_ d: HIDDevice, _ report: RazerReport, label: String,
               framing: Framing = .featurePrefixed) {
    let base = report.serialize()
    print("\n→ \(label) (txID 0x\(String(format: "%02x", report.transactionID)), framing \(framing))")

    // Framing variants — macOS IOHIDDeviceSetReport does not prepend the
    // report-ID byte, but this firmware appears to expect it in the payload.
    do {
        switch framing {
        case .outputBare:      // 90-byte packet padded to 91, no ID byte
            var p = base; while p.count < outputReportLen { p.append(0) }
            try d.setOutputReport(id: outputReportID, bytes: p)
        case .outputPrefixed:  // 0x03 + packet, padded to 92
            var p: [UInt8] = [UInt8(outputReportID)] + base
            while p.count < outputReportLen + 1 { p.append(0) }
            try d.setOutputReport(id: outputReportID, bytes: p)
        case .featureBare:     // classic OpenRazer style on report 7
            try d.setFeatureReport(id: featureReportID, bytes: base)
        case .featurePrefixed: // 0x07 + packet (91 bytes total)
            try d.setFeatureReport(id: featureReportID, bytes: [UInt8(featureReportID)] + base)
        }
    } catch {
        print("  send failed: \(error)")
        return
    }
    usleep(60_000) // give firmware time to fill the response
    do {
        var resp = try d.getFeatureReport(id: featureReportID, length: RazerReport.size + 1)
        // Some HID stacks prefix the report ID; strip it if present.
        if resp.count == RazerReport.size + 1 && resp[0] == UInt8(featureReportID) {
            resp = Array(resp.dropFirst())
        }
        guard let parsed = RazerReport.parse(resp) else {
            print("  short response (\(resp.count) bytes): \(hexDump(resp))")
            return
        }
        print("  status: \(parsed.statusDescription)")
        print(hexDump(resp))
        if parsed.status == RazerReport.Status.success.rawValue {
            interpret(parsed, label: label)
        }
    } catch {
        print("  read failed: \(error)")
    }
}

func interpret(_ r: RazerReport, label: String) {
    let n = min(Int(r.dataSize), 32)
    let argBytes = Array(r.args.prefix(n))
    let hex = argBytes.map { String(format: "%02x", $0) }.joined(separator: " ")
    let ascii = argBytes.allSatisfy { $0 == 0 || (32...126).contains($0) }
        ? " \"" + argBytes.prefix { $0 != 0 }.map { String(UnicodeScalar($0)) }.joined() + "\"" : ""
    print("  ✓ args[0..<\(n)]: \(hex)\(ascii)")
}

func cmdProbe() {
    guard let d = findNommo() else { print(NommoError.notFound.description); exit(1) }
    print(String(format: "Probing %@ (0x%04x:0x%04x), feature report ID %d…",
                 d.product, d.vendorID, d.productID, featureReportID))
    do { try d.open() } catch { print("open failed: \(error)"); exit(1) }
    defer { d.close() }

    // Confirmed framing: feature report 7, buffer = [0x07] + 90-byte packet.
    // Command map per openrazer #2758 (Nommo V2 X, same family):
    let tx: UInt8 = 0x3F
    sendQuery(d, .command(class: 0x00, id: 0x81, dataSize: 0x02, transactionID: tx), label: "get_device_mode(0x81)")
    sendQuery(d, .command(class: 0x00, id: 0x82, dataSize: 0x16, transactionID: tx), label: "get_serial(0x82)")
    sendQuery(d, .command(class: 0x00, id: 0x87, dataSize: 0x02, transactionID: tx), label: "get_hw_version(0x87)")
    sendQuery(d, .command(class: 0x00, id: 0x8D, dataSize: 0x02, transactionID: tx), label: "get_device_type(0x8D)")
    sendQuery(d, .command(class: 0x08, id: 0x86, dataSize: 0x02, transactionID: tx), label: "get_master_volume(0x08/0x86)")
    sendQuery(d, .command(class: 0x08, id: 0x82, dataSize: 0x02, transactionID: tx), label: "get_eq_preset(0x08/0x82)")
    sendQuery(d, .command(class: 0x08, id: 0x84, dataSize: 0x0B, transactionID: tx), label: "get_eq_bands(0x08/0x84)")
    sendQuery(d, .command(class: 0x08, id: 0x8A, dataSize: 0x02, transactionID: tx), label: "get_audio_source(0x08/0x8A)")
    sendQuery(d, .command(class: 0x07, id: 0x83, dataSize: 0x03, transactionID: tx), label: "get_idle_timeout(0x07/0x83)")
    sendQuery(d, .command(class: 0x07, id: 0x88, dataSize: 0x02, transactionID: tx), label: "get_power_saving(0x07/0x88)")
    // RGB (the V2, unlike the X, has Chroma lighting). Classic razer lighting
    // queries — read-only:
    sendQuery(d, .command(class: 0x0F, id: 0x84, dataSize: 0x02, transactionID: tx), label: "get_brightness(0x0F/0x84)")
    sendQuery(d, .command(class: 0x0F, id: 0x82, dataSize: 0x06, transactionID: tx), label: "get_effect(0x0F/0x82)")
}

func cmdRaw(_ hexArgs: [String]) {
    guard let d = findNommo() else { print(NommoError.notFound.description); exit(1) }
    var hexArgs = hexArgs
    var txID: UInt8 = 0x3F
    if let first = hexArgs.first, first.hasPrefix("tx="),
       let v = UInt8(first.dropFirst(3), radix: 16) {
        txID = v
        hexArgs.removeFirst()
    }
    let bytes = hexArgs.compactMap { UInt8($0.replacingOccurrences(of: "0x", with: ""), radix: 16) }
    guard bytes.count >= 3 else {
        print("usage: nommoctl raw <cls> <id> <datasize> [arg0 arg1 ...]  (hex bytes)")
        exit(1)
    }
    let r = RazerReport.command(class: bytes[0], id: bytes[1], dataSize: bytes[2],
                                args: Array(bytes.dropFirst(3)), transactionID: txID)
    do { try d.open() } catch { print("open failed: \(error)"); exit(1) }
    defer { d.close() }
    sendQuery(d, r, label: "raw")
}

func withDevice(_ body: (HIDDevice) -> Void) {
    guard let d = findNommo() else { print(NommoError.notFound.description); exit(1) }
    do { try d.open() } catch { print("open failed: \(error)"); exit(1) }
    defer { d.close() }
    body(d)
}

let tx3F: UInt8 = 0x3F

func cmdVolume(_ arg: String?) {
    withDevice { d in
        if let s = arg, let v = UInt8(s), v <= 100 {
            sendQuery(d, .command(class: 0x08, id: 0x06, dataSize: 0x02,
                                  args: [0x00, v], transactionID: tx3F), label: "set_volume(\(v))")
        }
        sendQuery(d, .command(class: 0x08, id: 0x86, dataSize: 0x02, transactionID: tx3F), label: "get_volume")
    }
}

func cmdBrightness(_ arg: String?) {
    withDevice { d in
        if let s = arg, let pct = UInt8(s), pct <= 100 {
            let v = UInt8(min(255, Int(pct) * 255 / 100))
            sendQuery(d, .command(class: 0x0F, id: 0x04, dataSize: 0x03,
                                  args: [0x01, 0x00, v], transactionID: tx3F), label: "set_brightness(\(pct)%)")
        }
        sendQuery(d, .command(class: 0x0F, id: 0x84, dataSize: 0x03,
                              args: [0x01, 0x00, 0x00], transactionID: tx3F), label: "get_brightness")
    }
}

func cmdRGB(_ a: [String]) {
    let vals = a.compactMap { UInt8($0) }
    guard vals.count == 3 else { print("usage: nommoctl rgb <r> <g> <b>  (0-255)"); exit(1) }
    withDevice { d in
        // Extended matrix static effect (openrazer razer_chroma_extended_matrix_effect_static)
        sendQuery(d, .command(class: 0x0F, id: 0x02, dataSize: 0x09,
                              args: [0x01, 0x00, 0x01, 0x00, 0x00, 0x01, vals[0], vals[1], vals[2]],
                              transactionID: tx3F), label: "set_static_rgb")
    }
}

func cmdEffect(_ a: [String]) {
    // spectrum | off | breathing r g b | wave
    withDevice { d in
        switch a.first {
        case "off":
            sendQuery(d, .command(class: 0x0F, id: 0x02, dataSize: 0x06,
                                  args: [0x01, 0x00, 0x00, 0x00, 0x00, 0x00], transactionID: tx3F), label: "effect_off")
        case "spectrum":
            sendQuery(d, .command(class: 0x0F, id: 0x02, dataSize: 0x06,
                                  args: [0x01, 0x00, 0x03, 0x00, 0x00, 0x00], transactionID: tx3F), label: "effect_spectrum")
        case "wave":
            sendQuery(d, .command(class: 0x0F, id: 0x02, dataSize: 0x06,
                                  args: [0x01, 0x00, 0x04, 0x01, 0x00, 0x00], transactionID: tx3F), label: "effect_wave")
        case "breathing":
            let v = a.dropFirst().compactMap { UInt8($0) }
            let rgb: [UInt8] = v.count == 3 ? v : [0, 255, 0]
            sendQuery(d, .command(class: 0x0F, id: 0x02, dataSize: 0x09,
                                  args: [0x01, 0x00, 0x02, 0x00, 0x00, 0x01] + rgb, transactionID: tx3F), label: "effect_breathing")
        default:
            print("usage: nommoctl effect <off|spectrum|wave|breathing [r g b]>")
        }
        sendQuery(d, .command(class: 0x0F, id: 0x82, dataSize: 0x09,
                              args: [0x01, 0x00], transactionID: tx3F), label: "get_effect")
    }
}

func cmdIdleTimeout(_ arg: String?) {
    withDevice { d in
        if let s = arg, let secs = UInt16(s) {
            sendQuery(d, .command(class: 0x07, id: 0x03, dataSize: 0x03,
                                  args: [UInt8(secs >> 8), UInt8(secs & 0xFF), 0x00],
                                  transactionID: tx3F), label: "set_idle_timeout(\(secs)s)")
        }
        sendQuery(d, .command(class: 0x07, id: 0x83, dataSize: 0x03, transactionID: tx3F), label: "get_idle_timeout")
    }
}

let args = CommandLine.arguments.dropFirst()
switch args.first {
case "list": cmdList()
case "info": cmdInfo()
case "probe": cmdProbe()
case "raw": cmdRaw(Array(args.dropFirst()))
case "volume": cmdVolume(args.dropFirst().first)
case "brightness": cmdBrightness(args.dropFirst().first)
case "rgb": cmdRGB(Array(args.dropFirst()))
case "effect": cmdEffect(Array(args.dropFirst()))
case "idle-timeout": cmdIdleTimeout(args.dropFirst().first)
default:
    print("""
    nommoctl — Razer Nommo V2 research CLI
    usage: nommoctl <command>
      list                     enumerate Razer HID devices
      info                     descriptors + report sizes
      probe                    run all known read-only queries
      volume [0-100]           get/set master volume
      brightness [0-100]       get/set LED brightness
      rgb <r> <g> <b>          static color
      effect <off|spectrum|wave|breathing [r g b]>
      idle-timeout [seconds]   get/set standby timeout (0 disables)
      raw <cls> <id> <size> [args…]   send arbitrary packet (hex)
    """)
}
