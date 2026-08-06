import AVFoundation
import AppKit

/// How aggressively to keep the speakers awake.
enum KeepAwakeMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case smart = "Smart"
    case always = "Always"
    var id: String { rawValue }
    var detail: String {
        switch self {
        case .off:    return "Speakers sleep normally."
        case .smart:  return "Keep awake while you're using the Mac — but let the speakers sleep when the display or computer sleeps."
        case .always: return "Never let the speakers sleep while the Mac is awake, even with the display off."
        }
    }
}

/// Prevents the Nommo V2's audio-idle standby with a brief inaudible pulse — but
/// only when it should. In Smart mode it stops when the display/computer sleeps,
/// so the speakers sleep with your Mac (and no power is wasted). Efficient:
/// the timer is fully suspended when not running, and the audio engine is paused
/// between pulses (~0.5 s of near-silent 80 Hz once a minute).
final class KeepAwake {
    private(set) var mode: KeepAwakeMode = .off
    private let intervalSeconds: TimeInterval = 60
    private let pulseSeconds = 0.5

    private var timer: Timer?
    private var displayAsleep = false
    private var observersAdded = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?
    private var wired = false

    func setMode(_ m: KeepAwakeMode) {
        mode = m
        addObserversIfNeeded()
        reevaluate()
    }

    // MARK: - Sleep awareness

    private func addObserversIfNeeded() {
        guard !observersAdded else { return }
        observersAdded = true
        let nc = NSWorkspace.shared.notificationCenter
        let sleep: (Notification) -> Void = { [weak self] _ in self?.displayAsleep = true;  self?.reevaluate() }
        let wake:  (Notification) -> Void = { [weak self] _ in self?.displayAsleep = false; self?.reevaluate() }
        nc.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main, using: sleep)
        nc.addObserver(forName: NSWorkspace.screensDidWakeNotification,  object: nil, queue: .main, using: wake)
        nc.addObserver(forName: NSWorkspace.willSleepNotification,       object: nil, queue: .main, using: sleep)
        nc.addObserver(forName: NSWorkspace.didWakeNotification,         object: nil, queue: .main, using: wake)
    }

    private var shouldRun: Bool {
        switch mode {
        case .off:    return false
        case .always: return true
        case .smart:  return !displayAsleep   // let speakers sleep with the Mac
        }
    }

    private func reevaluate() { shouldRun ? startTimer() : stopTimer() }

    // MARK: - Pulse engine

    private func startTimer() {
        guard timer == nil else { return }
        wireIfNeeded()
        pulse()
        let t = Timer(timeInterval: intervalSeconds, repeats: true) { [weak self] _ in self?.pulse() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate(); timer = nil
        player.stop(); engine.stop()
    }

    private func wireIfNeeded() {
        guard !wired else { return }
        let format = engine.outputNode.outputFormat(forBus: 0)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        let frames = AVAudioFrameCount(format.sampleRate * pulseSeconds)
        if let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) {
            buf.frameLength = frames
            let inc = 2.0 * Double.pi * 80.0 / format.sampleRate
            for ch in 0..<Int(format.channelCount) {
                if let p = buf.floatChannelData?[ch] {
                    for f in 0..<Int(frames) { p[f] = Float(sin(Double(f) * inc)) * 0.004 }
                }
            }
            buffer = buf
        }
        wired = true
    }

    private func pulse() {
        guard let buffer else { return }
        do {
            if !engine.isRunning { try engine.start() }
            player.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
                DispatchQueue.main.async { self?.engine.pause() }  // idle between pulses
            }
            player.play()
        } catch {
            NSLog("KeepAwake pulse failed: \(error)")
        }
    }
}
