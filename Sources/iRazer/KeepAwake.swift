import AVFoundation

/// Prevents the speakers' audio-idle standby (the firmware timer is read-only)
/// by playing a brief, inaudible pulse on an interval — NOT a continuous tone.
///
/// The Nommo family powers off after minutes of true silence (the original
/// Nommo Pro used 20 min; the V2 defaults to 15). A short sub-audible blip well
/// inside that window keeps the audio path "active" without any constant output.
final class KeepAwake {
    /// How often to emit the keep-alive pulse. 60 s is comfortably inside the
    /// multi-minute standby window with lots of margin.
    var intervalSeconds: TimeInterval = 60
    /// Pulse duration — long enough for the idle detector to register it.
    private let pulseSeconds = 0.5

    private var timer: Timer?
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?
    private var wired = false

    var isRunning: Bool { timer != nil }

    func start() {
        guard timer == nil else { return }
        wireIfNeeded()
        pulse() // fire one immediately so standby resets right away
        let t = Timer(timeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            self?.pulse()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        player.stop()
        engine.stop()
    }

    private func wireIfNeeded() {
        guard !wired else { return }
        let format = engine.outputNode.outputFormat(forBus: 0)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        // Pre-render one inaudible pulse: 80 Hz at ~-48 dBFS.
        let frames = AVAudioFrameCount(format.sampleRate * pulseSeconds)
        if let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) {
            buf.frameLength = frames
            let inc = 2.0 * Double.pi * 80.0 / format.sampleRate
            for ch in 0..<Int(format.channelCount) {
                if let p = buf.floatChannelData?[ch] {
                    for f in 0..<Int(frames) {
                        p[f] = Float(sin(Double(f) * inc)) * 0.004
                    }
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
                // Stop the engine between pulses so nothing runs in the gaps.
                DispatchQueue.main.async { self?.engine.pause() }
            }
            player.play()
        } catch {
            NSLog("KeepAwake pulse failed: \(error)")
        }
    }
}
