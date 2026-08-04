import Foundation
import CoreBluetooth
@preconcurrency import RazerKit

// nommoble — BLE recon + control for the Razer Nommo V2.
//
// Usage:
//   nommoble scan [seconds]         list advertisements
//   nommoble dump [name-fragment]   connect + enumerate GATT (default "nommo")
//   nommoble probe                  send known Razer queries over BLE, print notify replies
//   nommoble send <cls id size args…>   send one Razer packet (hex), print reply
//   nommoble raw <hex bytes…>       write raw bytes to the command characteristic

// Razer BLE control service on the Nommo V2 (from `nommoble dump`).
let cmdCharUUID    = CBUUID(string: "416D0000-2D52-617A-6572-424C4501F40A") // writeNR
let notifyCharUUID = CBUUID(string: "416D0001-2D52-617A-6572-424C4501F40A") // notify

final class BLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    let central: CBCentralManager
    let mode: String
    let filter: String
    let payloadArgs: [String]
    var target: CBPeripheral?
    var pendingServices = 0
    var cmdChar: CBCharacteristic?
    var notifyChar: CBCharacteristic?
    var probeQueue: [(String, [UInt8])] = []
    var seen = Set<UUID>()

    init(mode: String, filter: String, payloadArgs: [String] = []) {
        self.mode = mode
        self.filter = filter
        self.payloadArgs = payloadArgs
        self.sendGap = mode == "opsweep" ? 0.18 : (mode == "getall" ? 0.4 : 1.5)
        self.central = CBCentralManager()
        super.init()
        central.delegate = self
    }

    func centralManagerDidUpdateState(_ c: CBCentralManager) {
        switch c.state {
        case .poweredOn:
            print("🔍 scanning… (\(mode))")
            c.scanForPeripherals(withServices: nil,
                                 options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        case .unauthorized:
            print("❌ Bluetooth permission denied — allow it in System Settings → Privacy"); exit(1)
        case .poweredOff:
            print("❌ Bluetooth is off"); exit(1)
        default: break
        }
    }

    func centralManager(_ c: CBCentralManager, didDiscover p: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = p.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        if mode == "scan", seen.insert(p.identifier).inserted {
            let mfg = (advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data)
                .map { $0.map { String(format: "%02x", $0) }.joined() } ?? "-"
            let svc = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?
                .map(\.uuidString).joined(separator: ",") ?? "-"
            if !name.isEmpty || mfg != "-" {
                print("📡 \(name.isEmpty ? "(unnamed)" : name)  rssi \(RSSI)  mfg \(mfg)  svc \(svc)")
            }
            return
        }
        if mode != "scan", !name.isEmpty, name.lowercased().contains(filter) {
            print("🎯 connecting to \(name)…")
            target = p; p.delegate = self
            c.stopScan(); c.connect(p)
        }
    }

    func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) {
        print("✅ connected — discovering services")
        p.discoverServices(nil)
    }

    func centralManager(_ c: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        print("❌ connect failed: \(error.map(String.init(describing:)) ?? "?")"); exit(1)
    }

    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = p.services else { return }
        pendingServices = services.count
        for s in services {
            if mode == "dump" { print("service \(s.uuid)") }
            p.discoverCharacteristics(nil, for: s)
        }
    }

    func props(_ ch: CBCharacteristic) -> String {
        var out: [String] = []
        let p = ch.properties
        if p.contains(.read) { out.append("read") }
        if p.contains(.write) { out.append("write") }
        if p.contains(.writeWithoutResponse) { out.append("writeNR") }
        if p.contains(.notify) { out.append("notify") }
        if p.contains(.indicate) { out.append("indicate") }
        return out.joined(separator: "|")
    }

    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        for ch in s.characteristics ?? [] {
            if mode == "dump" {
                print("  char \(ch.uuid)  [\(props(ch))]")
                if ch.properties.contains(.read) { p.readValue(for: ch) }
            }
            if ch.uuid == cmdCharUUID { cmdChar = ch }
            if ch.uuid == notifyCharUUID {
                notifyChar = ch
                p.setNotifyValue(true, for: ch)
            }
        }
        pendingServices -= 1
        if pendingServices == 0 { didFinishDiscovery(p) }
    }

    var currentLabel = ""
    let sendGap: Double

    func didFinishDiscovery(_ p: CBPeripheral) {
        switch mode {
        case "dump":
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { print("done"); exit(0) }
        case "probe", "send", "raw", "opsweep", "getall":
            guard cmdChar != nil else { print("❌ command characteristic not found"); exit(1) }
            print("📶 MTU (writeNR) = \(p.maximumWriteValueLength(for: .withoutResponse)) bytes")
            buildPayloads()
            let total = Double(probeQueue.count) * sendGap + 5
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.sendNext(p) }
            DispatchQueue.main.asyncAfter(deadline: .now() + total) { print("done"); exit(0) }
        default: exit(0)
        }
    }

    func buildPayloads() {
        func pkt(_ label: String, _ cls: UInt8, _ id: UInt8, _ size: UInt8, _ args: [UInt8] = []) {
            let r = RazerReport.command(class: cls, id: id, dataSize: size, args: args, transactionID: 0x3F)
            probeQueue.append((label, r.serialize()))
        }
        switch mode {
        case "probe":
            pkt("firmware(0x00/0x81)", 0x00, 0x81, 0x02)
            pkt("serial(0x00/0x82)",   0x00, 0x82, 0x16)
            pkt("brightness(0x0F/0x84)", 0x0F, 0x84, 0x03, [0x01, 0x00, 0x00])
            pkt("static-red(0x0F/0x02)", 0x0F, 0x02, 0x09, [0x01, 0x00, 0x01, 0x00, 0x00, 0x01, 0xFF, 0x00, 0x00])
        case "opsweep":
            // Map the compact BLE command table: send each opcode with a small
            // payload and record which ones the device answers (notify).
            for op in 0...255 {
                probeQueue.append((String(format: "op-%02x", op),
                                   [UInt8(op), 0x00, 0x00, 0x00, 0x00]))
            }
        case "getall":
            // Read-only: only GET opcodes (0x00-0x7f), never SET. Safe — won't
            // change device state. Used to find which opcode holds the color.
            for op in 0...0x7f {
                probeQueue.append((String(format: "get-%02x", op),
                                   [UInt8(op), 0x00, 0x00, 0x00, 0x00]))
            }
        case "send":
            let b = payloadArgs.compactMap { UInt8($0, radix: 16) }
            if b.count >= 3 {
                pkt("send", b[0], b[1], b[2], Array(b.dropFirst(3)))
            }
        case "raw":
            let b = payloadArgs.compactMap { UInt8($0, radix: 16) }
            probeQueue.append(("raw", b))
        default: break
        }
    }

    func sendNext(_ p: CBPeripheral) {
        guard let ch = cmdChar, !probeQueue.isEmpty else { return }
        let (label, bytes) = probeQueue.removeFirst()
        currentLabel = label
        if mode != "opsweep" {
            let hex = bytes.prefix(12).map { String(format: "%02x", $0) }.joined(separator: " ")
            print("→ \(label): \(hex)… (\(bytes.count) B)")
        }
        writeChunked(p, ch, Data(bytes))
        if !probeQueue.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + sendGap) { self.sendNext(p) }
        }
    }

    /// Write the payload, chunking to the negotiated MTU if needed.
    func writeChunked(_ p: CBPeripheral, _ ch: CBCharacteristic, _ data: Data) {
        let mtu = max(20, p.maximumWriteValueLength(for: .withoutResponse))
        if data.count <= mtu {
            p.writeValue(data, for: ch, type: .withoutResponse)
        } else {
            var off = 0
            while off < data.count {
                let end = min(off + mtu, data.count)
                p.writeValue(data.subdata(in: off..<end), for: ch, type: .withoutResponse)
                off = end
            }
        }
    }

    func peripheral(_ p: CBPeripheral, didUpdateValueFor ch: CBCharacteristic, error: Error?) {
        guard let v = ch.value, !v.isEmpty else { return }
        let hex = v.map { String(format: "%02x", $0) }.joined(separator: " ")
        if ch.uuid == notifyCharUUID {
            print("  ◀ notify\(mode == "opsweep" || mode == "getall" ? " [\(currentLabel)]" : ""): \(hex)")
        } else if mode == "dump" {
            let ascii = v.map { (32...126).contains($0) ? String(UnicodeScalar($0)) : "." }.joined()
            print("  value \(ch.uuid): \(hex)  \"\(ascii)\"")
        }
    }
}

let args = CommandLine.arguments
let mode = args.count > 1 ? args[1] : "scan"
var filter = "nomv2"
var payload: [String] = []
if mode == "dump", args.count > 2 { filter = args[2].lowercased() }
if mode == "send" || mode == "raw" { payload = Array(args.dropFirst(2)) }

let ble = BLE(mode: mode, filter: filter, payloadArgs: payload)
let timeout: TimeInterval = mode == "scan" ? (Double(args.count > 2 ? args[2] : "12") ?? 12) : 60
DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
    print(mode == "scan" ? "scan finished" : "timeout"); exit(0)
}
RunLoop.main.run()
