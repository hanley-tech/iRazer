import Foundation
import CoreBluetooth
import AVFoundation

// nommoblefuzz — decode the Nommo V2 BLE lighting framing by correlation.
//
// For each candidate packet framing we send a RED variant and a GREEN variant
// and measure the glow's hue after each. The framing whose observed hue follows
// the commanded color is the real lighting protocol. Fully automated via camera.
//
// Candidates: lab/ble-framings.json  ->  results: lab/ble-fuzz-results.jsonl

let labDir = NSHomeDirectory() + "/Git/htai/iRazer/lab"
let cmdCharUUID    = CBUUID(string: "416D0000-2D52-617A-6572-424C4501F40A")
let notifyCharUUID = CBUUID(string: "416D0001-2D52-617A-6572-424C4501F40A")

// MARK: - Camera

final class FrameGrabber: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let lock = NSLock()
    private var _latest: (r: Double, g: Double, b: Double)?
    var latest: (r: Double, g: Double, b: Double)? {
        lock.lock(); defer { lock.unlock() }; return _latest
    }
    func captureOutput(_ o: AVCaptureOutput, didOutput sb: CMSampleBuffer, from c: AVCaptureConnection) {
        guard let pb = CMSampleBufferGetImageBuffer(sb) else { return }
        CVPixelBufferLockBaseAddress(pb, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pb) else { return }
        let w = CVPixelBufferGetWidth(pb), h = CVPixelBufferGetHeight(pb)
        let stride = CVPixelBufferGetBytesPerRow(pb)
        let p = base.assumingMemoryBound(to: UInt8.self)
        var r = 0.0, g = 0.0, b = 0.0, n = 0.0
        for y in Swift.stride(from: 0, to: h, by: 8) {
            for x in Swift.stride(from: 0, to: w, by: 8) {
                let o = y * stride + x * 4
                b += Double(p[o]); g += Double(p[o+1]); r += Double(p[o+2]); n += 1
            }
        }
        lock.lock(); _latest = (r/n, g/n, b/n); lock.unlock()
    }
}

func hsv(_ c: (r: Double, g: Double, b: Double)) -> (h: Double, s: Double, v: Double) {
    let mx = max(c.r, c.g, c.b), mn = min(c.r, c.g, c.b), d = mx - mn
    var h = 0.0
    if d > 0.001 {
        if mx == c.r { h = 60 * ((c.g - c.b)/d).truncatingRemainder(dividingBy: 6) }
        else if mx == c.g { h = 60 * ((c.b - c.r)/d + 2) }
        else { h = 60 * ((c.r - c.g)/d + 4) }
        if h < 0 { h += 360 }
    }
    return (h, mx > 0 ? d/mx : 0, mx)
}

func meanHue(_ g: FrameGrabber, frames: Int = 5, gapMs: UInt32 = 250) -> (h: Double, s: Double, v: Double) {
    var cx = 0.0, cy = 0.0, s = 0.0, v = 0.0, n = 0.0
    for _ in 0..<frames {
        usleep(gapMs * 1000)
        guard let c = g.latest else { continue }
        let p = hsv(c)
        cx += cos(p.h * .pi/180) * p.s; cy += sin(p.h * .pi/180) * p.s
        s += p.s; v += p.v; n += 1
    }
    guard n > 0 else { return (0,0,0) }
    var mh = atan2(cy, cx) * 180 / .pi; if mh < 0 { mh += 360 }
    return (mh, s/n, v/n)
}

func openCamera(_ grabber: FrameGrabber, want: String?) -> AVCaptureSession? {
    let sem = DispatchSemaphore(value: 0); var granted = false
    AVCaptureDevice.requestAccess(for: .video) { granted = $0; sem.signal() }; sem.wait()
    guard granted else { print("❌ camera denied"); return nil }
    let all = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
        mediaType: .video, position: .unspecified).devices
    let virtual = ["obs","virtual","zoom","snap"]
    let cam = want.flatMap { w in all.first { $0.localizedName.lowercased().contains(w) } }
        ?? all.first { c in !virtual.contains { c.localizedName.lowercased().contains($0) } }
    guard let cam else { print("❌ no camera"); return nil }
    print("📷 \(cam.localizedName)")
    let s = AVCaptureSession(); s.sessionPreset = .vga640x480
    guard let inp = try? AVCaptureDeviceInput(device: cam), s.canAddInput(inp) else { return nil }
    s.addInput(inp)
    let out = AVCaptureVideoDataOutput()
    out.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    out.setSampleBufferDelegate(grabber, queue: DispatchQueue(label: "cam"))
    s.addOutput(out); s.startRunning(); return s
}

// MARK: - BLE + fuzz loop

struct Framing: Codable { var id: String; var template: String }

final class Fuzzer: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    let central: CBCentralManager
    let grabber = FrameGrabber()
    var session: AVCaptureSession?
    var peripheral: CBPeripheral?
    var cmdChar: CBCharacteristic?
    var pending = 0
    let framings: [Framing]
    let camWant: String?
    var lastNotify: [UInt8] = []

    init(framings: [Framing], camWant: String?) {
        self.framings = framings
        self.camWant = camWant
        self.central = CBCentralManager(delegate: nil, queue: DispatchQueue(label: "ble"))
        super.init()
        central.delegate = self
    }

    func centralManagerDidUpdateState(_ c: CBCentralManager) {
        if c.state == .poweredOn { c.scanForPeripherals(withServices: nil) }
        else if c.state == .unauthorized { print("❌ BT denied"); exit(1) }
    }
    func centralManager(_ c: CBCentralManager, didDiscover p: CBPeripheral,
                        advertisementData d: [String: Any], rssi: NSNumber) {
        let name = p.name ?? (d[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        if name.lowercased().contains("nomv2") {
            peripheral = p; p.delegate = self; c.stopScan(); c.connect(p)
        }
    }
    func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) {
        print("✅ BLE connected"); p.discoverServices(nil)
    }
    func peripheral(_ p: CBPeripheral, didDiscoverServices e: Error?) {
        pending = p.services?.count ?? 0
        p.services?.forEach { p.discoverCharacteristics(nil, for: $0) }
    }
    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error e: Error?) {
        for ch in s.characteristics ?? [] {
            if ch.uuid == cmdCharUUID { cmdChar = ch }
            if ch.uuid == notifyCharUUID { p.setNotifyValue(true, for: ch) }
        }
        pending -= 1
        if pending == 0 { startFuzz() }
    }
    func peripheral(_ p: CBPeripheral, didUpdateValueFor ch: CBCharacteristic, error e: Error?) {
        if ch.uuid == notifyCharUUID, let v = ch.value { lastNotify = [UInt8](v) }
    }

    func send(_ bytes: [UInt8]) {
        guard let ch = cmdChar, let p = peripheral else { return }
        p.writeValue(Data(bytes), for: ch, type: .withoutResponse)
    }

    func startFuzz() {
        guard cmdChar != nil else { print("❌ no cmd char"); exit(1) }
        DispatchQueue.global().async { self.fuzzLoop() }
    }

    func parse(_ template: String, r: UInt8, g: UInt8, b: UInt8) -> [UInt8] {
        template.split(separator: " ").compactMap { tok -> UInt8? in
            switch tok {
            case "RR": return r
            case "GG": return g
            case "BB": return b
            case "CRC": return 0  // placeholder, filled below
            default: return UInt8(tok, radix: 16)
            }
        }
    }

    func fuzzLoop() {
        let resultsURL = URL(fileURLWithPath: labDir + "/ble-fuzz-results.jsonl")
        if !FileManager.default.fileExists(atPath: resultsURL.path) {
            FileManager.default.createFile(atPath: resultsURL.path, contents: nil)
        }
        func log(_ o: [String: Any]) {
            if let d = try? JSONSerialization.data(withJSONObject: o),
               let s = String(data: d, encoding: .utf8),
               let h = try? FileHandle(forWritingTo: resultsURL) {
                h.seekToEndOfFile(); h.write((s + "\n").data(using: .utf8)!); try? h.close()
            }
        }
        print("🚀 testing \(framings.count) framings (red vs green correlation)")
        // Put the LEDs in static mode first so measurements aren't fighting the
        // spectrum cycle. 0x82 with effect byte = 0x01 (static) stops cycling.
        send([0x82, 0x01, 0x01, 0x00, 0x00]); usleep(800_000)
        var hits = 0
        for f in framings {
            // RED
            lastNotify = []
            send(parse(f.template, r: 0xFF, g: 0x00, b: 0x00))
            usleep(700_000)
            let red = meanHue(grabber, frames: 4)
            let redNotify = lastNotify
            // GREEN
            lastNotify = []
            send(parse(f.template, r: 0x00, g: 0xFF, b: 0x00))
            usleep(700_000)
            let grn = meanHue(grabber, frames: 4)
            let grnNotify = lastNotify

            // Correlation: red hue near 0/360, green near 120, and they differ.
            let redOK = (red.h < 35 || red.h > 325) && red.s > 0.15
            let grnOK = (grn.h > 80 && grn.h < 170) && grn.s > 0.15
            let diff = min(abs(red.h - grn.h), 360 - abs(red.h - grn.h))
            let correlated = redOK && grnOK && diff > 40
            let anyNotify = !redNotify.isEmpty || !grnNotify.isEmpty
            let verdict = correlated ? "COLOR-MATCH" : (diff > 40 ? "changed" : "no-change")
            if correlated || diff > 40 || anyNotify { hits += 1 }
            log(["id": f.id, "template": f.template,
                 "redHue": red.h.rounded(), "grnHue": grn.h.rounded(),
                 "redSat": (red.s*100).rounded()/100, "grnSat": (grn.s*100).rounded()/100,
                 "diff": diff.rounded(), "verdict": verdict,
                 "redNotify": redNotify.map { String(format: "%02x", $0) }.joined(),
                 "grnNotify": grnNotify.map { String(format: "%02x", $0) }.joined()])
            let flag = correlated ? "  ⭐️ COLOR-MATCH" : (diff > 40 ? "  ~changed" : "")
            print(String(format: "%@ red=%3.0f grn=%3.0f diff=%3.0f%@%@",
                         f.id.padding(toLength: 20, withPad: " ", startingAt: 0),
                         red.h, grn.h, diff, anyNotify ? " 📩" : "", flag))
            // Leave whatever the candidate set (stable canvas). Do NOT re-send
            // the mode command every iteration — the repeated mode-switch was
            // what power-cycled the speaker.
            usleep(300_000)
        }
        print("🏁 done — \(hits) interesting. See lab/ble-fuzz-results.jsonl")
        exit(0)
    }
}

// MARK: - Main

let camArg = CommandLine.arguments.firstIndex(of: "--camera").map { CommandLine.arguments[$0 + 1] }
guard let data = FileManager.default.contents(atPath: labDir + "/ble-framings.json"),
      let framings = try? JSONDecoder().decode([Framing].self, from: data) else {
    print("❌ couldn't load lab/ble-framings.json"); exit(1)
}
let fuzzer = Fuzzer(framings: framings, camWant: camArg)
fuzzer.session = openCamera(fuzzer.grabber, want: camArg)
guard fuzzer.session != nil else { exit(1) }
sleep(2)
DispatchQueue.main.asyncAfter(deadline: .now() + 300) { print("timeout"); exit(0) }
RunLoop.main.run()
