import Foundation
import AVFoundation
import CoreImage
@preconcurrency import RazerKit

// nommofuzz — camera-feedback protocol fuzzer.
//
// Points a camera at the Nommo V2's rear-projection glow and automatically
// classifies the lighting state (cycling / static / off) after each candidate
// packet. Calibrates itself with the known-good brightness command, so a run
// aborts early if the camera can't actually see the speakers.
//
// Usage:
//   nommofuzz calibrate            check camera + device pipeline only
//   nommofuzz run [candidates.json] [--interval ms]
//
// Results append to lab/fuzz-results.jsonl; already-tested candidate IDs are
// skipped on re-run, so it's resumable.

let labDir = NSHomeDirectory() + "/Git/htai/iRazer/lab"
let resultsURL = URL(fileURLWithPath: labDir + "/fuzz-results.jsonl")

// MARK: - Camera

final class FrameGrabber: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let lock = NSLock()
    private var _latest: (r: Double, g: Double, b: Double)?
    var latest: (r: Double, g: Double, b: Double)? {
        lock.lock(); defer { lock.unlock() }
        return _latest
    }

    private var _latestCI: CIImage?
    var latestCI: CIImage? {
        lock.lock(); defer { lock.unlock() }
        return _latestCI
    }

    func saveSnapshot(to path: String) -> Bool {
        guard let ci = latestCI else { return false }
        let ctx = CIContext()
        let url = URL(fileURLWithPath: path)
        return (try? ctx.writeJPEGRepresentation(of: ci, to: url,
                colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)) != nil
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ci = CIImage(cvPixelBuffer: pb)
        lock.lock(); _latestCI = ci; lock.unlock()
        CVPixelBufferLockBaseAddress(pb, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pb) else { return }
        let w = CVPixelBufferGetWidth(pb), h = CVPixelBufferGetHeight(pb)
        let stride = CVPixelBufferGetBytesPerRow(pb)
        let ptr = base.assumingMemoryBound(to: UInt8.self)
        var r = 0.0, g = 0.0, b = 0.0, n = 0.0
        // Sample every 8th pixel (BGRA)
        for y in Swift.stride(from: 0, to: h, by: 8) {
            for x in Swift.stride(from: 0, to: w, by: 8) {
                let o = y * stride + x * 4
                b += Double(ptr[o]); g += Double(ptr[o + 1]); r += Double(ptr[o + 2])
                n += 1
            }
        }
        lock.lock()
        _latest = (r / n, g / n, b / n)
        lock.unlock()
    }
}

func openCamera(_ grabber: FrameGrabber) -> AVCaptureSession? {
    let sem = DispatchSemaphore(value: 0)
    var granted = false
    AVCaptureDevice.requestAccess(for: .video) { ok in granted = ok; sem.signal() }
    sem.wait()
    guard granted else {
        print("❌ camera access denied — enable it in System Settings → Privacy")
        return nil
    }
    let discovery = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
        mediaType: .video, position: .unspecified)
    let all = discovery.devices
    print("cameras: " + all.map(\.localizedName).joined(separator: " | "))
    var pick: AVCaptureDevice?
    if let i = CommandLine.arguments.firstIndex(of: "--camera"),
       CommandLine.arguments.count > i + 1 {
        let want = CommandLine.arguments[i + 1].lowercased()
        pick = all.first { $0.localizedName.lowercased().contains(want) }
        if pick == nil { print("❌ no camera matching \"\(want)\"") ; return nil }
    } else {
        // Prefer a Continuity/real camera; never a virtual one.
        let virtual = ["obs", "virtual", "zoom", "snap"]
        let real = all.filter { cam in !virtual.contains { cam.localizedName.lowercased().contains($0) } }
        pick = real.first { $0.deviceType == .continuityCamera } ?? real.first
    }
    guard let cam = pick else {
        print("❌ no usable camera found — connect a webcam or enable Continuity Camera")
        return nil
    }
    print("📷 using camera: \(cam.localizedName)")
    let session = AVCaptureSession()
    session.sessionPreset = .vga640x480
    guard let input = try? AVCaptureDeviceInput(device: cam), session.canAddInput(input) else {
        print("❌ couldn't open camera input")
        return nil
    }
    session.addInput(input)
    let output = AVCaptureVideoDataOutput()
    output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    output.setSampleBufferDelegate(grabber, queue: DispatchQueue(label: "fuzz.camera"))
    session.addOutput(output)
    session.startRunning()
    return session
}

// MARK: - Color metrics

struct Burst {
    var brightness: Double   // mean of per-frame max(r,g,b), 0-255
    var hueDrift: Double     // 0 = hue locked, 1 = chaotic
    var meanHue: Double      // degrees
    var saturation: Double
}

func hueSat(_ c: (r: Double, g: Double, b: Double)) -> (h: Double, s: Double, v: Double) {
    let mx = max(c.r, c.g, c.b), mn = min(c.r, c.g, c.b)
    let d = mx - mn
    var h = 0.0
    if d > 0.001 {
        if mx == c.r { h = 60 * ((c.g - c.b) / d).truncatingRemainder(dividingBy: 6) }
        else if mx == c.g { h = 60 * ((c.b - c.r) / d + 2) }
        else { h = 60 * ((c.r - c.g) / d + 4) }
        if h < 0 { h += 360 }
    }
    return (h, mx > 0 ? d / mx : 0, mx)
}

func captureBurst(_ grabber: FrameGrabber, frames: Int = 7, gapMs: UInt32 = 320) -> Burst {
    var samples: [(h: Double, s: Double, v: Double)] = []
    for _ in 0..<frames {
        usleep(gapMs * 1000)
        if let c = grabber.latest { samples.append(hueSat(c)) }
    }
    guard !samples.isEmpty else { return Burst(brightness: 0, hueDrift: 0, meanHue: 0, saturation: 0) }
    let bright = samples.map(\.v).reduce(0, +) / Double(samples.count)
    let sat = samples.map(\.s).reduce(0, +) / Double(samples.count)
    // Circular statistics on hue, weighted by saturation so gray frames don't add noise
    var cx = 0.0, cy = 0.0
    for s in samples {
        cx += cos(s.h * .pi / 180) * s.s
        cy += sin(s.h * .pi / 180) * s.s
    }
    let totalW = max(samples.map(\.s).reduce(0, +), 0.0001)
    let r = sqrt(cx * cx + cy * cy) / totalW
    let meanHue = atan2(cy, cx) * 180 / .pi
    return Burst(brightness: bright, hueDrift: 1 - r,
                 meanHue: meanHue < 0 ? meanHue + 360 : meanHue, saturation: sat)
}

// MARK: - Device

func sendPacket(_ dev: NommoDevice, tx: UInt8, bytes: [UInt8]) -> String {
    guard bytes.count >= 3 else { return "bad" }
    let report = RazerReport.command(class: bytes[0], id: bytes[1], dataSize: bytes[2],
                                     args: Array(bytes.dropFirst(3)), transactionID: tx)
    do {
        let resp = try dev.request(report)
        return String(format: "%02x", resp.status)
    } catch {
        return "err"
    }
}

func setBrightness(_ dev: NommoDevice, _ v: UInt8) {
    _ = sendPacket(dev, tx: 0x1F, bytes: [0x0F, 0x04, 0x03, 0x01, 0x00, v])
}

// MARK: - Candidates

struct Candidate: Codable {
    var id: String
    var tx: String
    var packets: [String]   // each "cls cmd size args…" hex
}

func parseHex(_ s: String) -> [UInt8] {
    s.split(separator: " ").compactMap { UInt8($0, radix: 16) }
}

// MARK: - Main

func classify(_ b: Burst, offBright: Double, onBright: Double) -> String {
    let offThreshold = offBright + (onBright - offBright) * 0.35
    if b.brightness < offThreshold { return "off" }
    if b.hueDrift < 0.12 && b.saturation > 0.25 { return "static" }
    if b.hueDrift < 0.35 { return "slow-or-partial" }
    return "cycling"
}

func appendResult(_ obj: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: obj),
          let line = String(data: data, encoding: .utf8) else { return }
    if !FileManager.default.fileExists(atPath: resultsURL.path) {
        FileManager.default.createFile(atPath: resultsURL.path, contents: nil)
    }
    if let h = try? FileHandle(forWritingTo: resultsURL) {
        h.seekToEndOfFile()
        h.write((line + "\n").data(using: .utf8)!)
        try? h.close()
    }
}

let grabber = FrameGrabber()
guard let session = openCamera(grabber) else { exit(1) }
sleep(2) // warm-up

if CommandLine.arguments.contains("snap") {
    let path = "/tmp/fuzz-view.jpg"
    if grabber.saveSnapshot(to: path) {
        print("📸 saved \(path)")
    } else {
        print("❌ no frame captured yet")
    }
    session.stopRunning()
    exit(0)
}

guard let dev = NommoDevice.find() else { print("❌ Nommo V2 not found"); exit(1) }
do { try dev.open() } catch { print("❌ open failed: \(error)"); exit(1) }

// --- Calibration: verify the camera actually sees the speakers ---
print("🔧 calibrating…")
setBrightness(dev, 0xFF)
let baseline = captureBurst(grabber)
setBrightness(dev, 0x00)
sleep(1)
let dark = captureBurst(grabber)
setBrightness(dev, 0xFF)
sleep(1)

let delta = baseline.brightness - dark.brightness
print(String(format: "   lights-on brightness %.1f, lights-off %.1f (Δ %.1f), baseline hueDrift %.2f",
             baseline.brightness, dark.brightness, delta, baseline.hueDrift))
guard delta > 8 else {
    print("""
    ❌ Camera can't distinguish lights on/off (Δ too small).
       Point the camera directly at the wall glow behind the speakers,
       dim the room lights, and run `nommofuzz calibrate` again.
    """)
    exit(1)
}
print("✅ calibration OK — camera sees the speakers")

let args = CommandLine.arguments
if args.contains("calibrate") { exit(0) }

// --- Load candidates + already-done set ---
let candPath = args.count > 2 && !args[2].hasPrefix("--") ? args[2] : labDir + "/fuzz-candidates.json"
guard let candData = FileManager.default.contents(atPath: candPath),
      let candidates = try? JSONDecoder().decode([Candidate].self, from: candData) else {
    print("❌ couldn't load candidates from \(candPath)")
    exit(1)
}
var done = Set<String>()
if let existing = try? String(contentsOf: resultsURL, encoding: .utf8) {
    for line in existing.split(separator: "\n") {
        if let d = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
           let id = d["id"] as? String { done.insert(id) }
    }
}
let todo = candidates.filter { !done.contains($0.id) }
print("🚀 fuzzing \(todo.count) candidates (\(done.count) already done). Ctrl-C to stop; re-run to resume.")

func hueDiff(_ a: Double, _ b: Double) -> Double {
    let d = abs(a - b).truncatingRemainder(dividingBy: 360)
    return d > 180 ? 360 - d : d
}

// The spectrum cycle drifts slowly (baseline hueDrift ≈ 0 within a burst), so
// detection is before/after comparison: a real effect command jumps the hue or
// brightness instantly; the idle cycle moves only a few degrees per second.
var hits = 0
let offThreshold = dark.brightness + (baseline.brightness - dark.brightness) * 0.45
for (i, cand) in todo.enumerated() {
    let pre = captureBurst(grabber, frames: 3)
    var statuses: [String] = []
    for p in cand.packets {
        statuses.append(sendPacket(dev, tx: UInt8(cand.tx, radix: 16) ?? 0x1F, bytes: parseHex(p)))
    }
    usleep(400_000)
    let post = captureBurst(grabber, frames: 4)
    let jump = hueDiff(pre.meanHue, post.meanHue)
    let brightDelta = post.brightness - pre.brightness
    var verdict = "no-change"
    if post.brightness < offThreshold && pre.brightness >= offThreshold { verdict = "hit-dark" }
    else if jump > 30 && post.saturation > 0.2 { verdict = "hit-hue-jump" }
    else if abs(brightDelta) > (baseline.brightness - dark.brightness) * 0.6 { verdict = "hit-brightness" }
    let interesting = verdict != "no-change"
    appendResult([
        "ts": ISO8601DateFormatter().string(from: Date()),
        "id": cand.id, "tx": cand.tx, "packets": cand.packets, "statuses": statuses,
        "preHue": pre.meanHue.rounded(), "postHue": post.meanHue.rounded(),
        "hueJump": jump.rounded(),
        "preBright": (pre.brightness * 10).rounded() / 10,
        "postBright": (post.brightness * 10).rounded() / 10,
        "verdict": verdict,
    ])
    let flag = interesting ? "  ⭐️ \(verdict)" : ""
    print(String(format: "[%3d/%d] %@ hue %3.0f→%3.0f (Δ%3.0f) bright %.0f→%.0f%@",
                 i + 1, todo.count, cand.id.padding(toLength: 24, withPad: " ", startingAt: 0),
                 pre.meanHue, post.meanHue, jump, pre.brightness, post.brightness, flag))
    if interesting {
        hits += 1
        setBrightness(dev, 0xFF)
        _ = sendPacket(dev, tx: 0x1F, bytes: [0x03, 0x0A, 0x01, 0x04])
        _ = sendPacket(dev, tx: 0x1F, bytes: [0x00, 0x04, 0x02, 0x00, 0x00])
        sleep(2)
    }
}
print("🏁 done — \(hits) interesting results. Analyze lab/fuzz-results.jsonl.")
session.stopRunning()
dev.close()
