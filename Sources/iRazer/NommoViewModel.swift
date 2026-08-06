import SwiftUI
@preconcurrency import RazerKit

@MainActor
final class NommoViewModel: ObservableObject {
    @Published var connected = false
    @Published var serial = ""
    @Published var hardwareVersion = ""
    @Published var statusMessage = "Searching for Razer Nommo V2…"

    // Lighting
    @Published var brightness: Double = 100          // percent
    @Published var effect: NommoDevice.Effect = .spectrum
    @Published var color: Color = .green

    // Sound
    @Published var volume: Double = 50
    static let bandLabels = ["31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    @Published var eqGains: [Double] = Array(repeating: 0, count: 10)   // dB, -12…+12, 0 = flat (0x0C)
    @Published var eqPreset: Int = 0

    // Power
    @Published var idleTimeoutMinutes: Double = 15   // 0 = never sleep
    @Published var powerSaving = true

    /// Shared instance so the window and the menu-bar extra drive one device.
    static let shared = NommoViewModel()

    private var device: NommoDevice?
    private let queue = DispatchQueue(label: "nommo.hid")
    private var pollTimer: Timer?
    private var started = false

    /// PIDs of every Razer HID device currently plugged in (any model). Lets the
    /// app honestly show "detected" for experimental devices we don't fully drive yet.
    @Published var connectedPIDs: Set<Int> = []

    func start() {
        guard !started else { return }   // idempotent: safe to call from multiple scenes
        started = true
        applyKeepAwakeOnLaunch()
        connect()
        scanPresence()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.scanPresence()
                if !self.connected { self.connect() }
            }
        }
    }

    /// Enumerate all Razer HID devices and record which PIDs are present.
    func scanPresence() {
        queue.async {
            let pids = Set(enumerateHIDDevices(vendorID: razerVID).map { $0.productID })
            Task { @MainActor in self.connectedPIDs = pids }
        }
    }

    private func connect() {
        queue.async {
            guard let dev = NommoDevice.find() else {
                Task { @MainActor in
                    self.connected = false
                    self.statusMessage = "Razer Nommo V2 not found — check the USB cable."
                }
                return
            }
            do {
                try dev.open()
                let state = try dev.readState()
                let vol = (try? dev.masterVolume()).map(Double.init)
                Task { @MainActor in
                    self.device = dev
                    self.connected = true
                    self.serial = state.serial
                    self.hardwareVersion = state.hardwareVersion
                    self.brightness = Double(state.brightness) / 255 * 100
                    if let vol { self.volume = vol }
                    self.eqPreset = Int(state.eqPreset)
                    self.eqGains = state.eqBands.map { Double(Int($0) - 0x0C) }
                    self.idleTimeoutMinutes = Double(state.idleTimeoutSeconds) / 60
                    self.powerSaving = state.powerSaving
                    self.statusMessage = "Connected — serial \(state.serial), hw v\(state.hardwareVersion)"
                }
            } catch {
                Task { @MainActor in
                    self.connected = false
                    self.statusMessage = "Found device but couldn't open it: \(error)"
                }
            }
        }
    }

    /// Run a device call off the main thread; on failure mark disconnected.
    private func perform(_ label: String, _ body: @escaping (NommoDevice) throws -> Void) {
        guard let dev = device else { return }
        queue.async {
            do {
                try body(dev)
            } catch {
                Task { @MainActor in
                    self.statusMessage = "\(label) failed: \(error)"
                    if case NommoError.ioKit = error { self.connected = false; self.device = nil }
                }
            }
        }
    }

    // MARK: - Actions

    func applyBrightness() {
        let v = UInt8(min(255, brightness / 100 * 255))
        perform("Set brightness") { try $0.setBrightness(v) }
    }

    func applyEffect() {
        let rgb = color.rgbBytes
        let e = effect
        perform("Set effect") { try $0.setEffect(e, color: rgb) }
    }

    func applyVolume() {
        let v = UInt8(min(100, max(0, volume)))
        perform("Set volume") { try $0.setMasterVolume(v) }
    }

    func applyEQ() {
        let bands = eqGains.map { UInt8(max(0, min(24, Int($0.rounded()) + 0x0C))) }
        perform("Set EQ") { try $0.setEQBands(bands) }
    }

    func applyEQPreset() {
        let p = UInt8(eqPreset)
        perform("Set EQ preset") { try $0.setEQPreset(p) }
        // Presets reset the band sliders on the device; re-read them.
        refreshEQ()
    }

    func flattenEQ() {
        eqGains = Array(repeating: 0, count: 10)
        applyEQ()
    }

    private func refreshEQ() {
        guard let dev = device else { return }
        queue.async {
            if let bands = try? dev.eqBands() {
                Task { @MainActor in
                    self.eqGains = bands.map { Double(Int($0) - 0x0C) }
                }
            }
        }
    }

    func applyIdleTimeout() {
        let secs = UInt16(min(65535, idleTimeoutMinutes * 60))
        perform("Set standby timeout") { try $0.setIdleTimeout(seconds: secs) }
    }

    func applyPowerSaving() {
        let on = powerSaving
        perform("Set power saving") { try $0.setPowerSaving(on) }
    }

    // MARK: - Keep awake (host-side: the firmware standby timer is read-only)

    @Published var keepAwakeMode: KeepAwakeMode = KeepAwakeMode(rawValue:
        UserDefaults.standard.string(forKey: "keepAwakeMode") ?? "") ?? .off {
        didSet {
            UserDefaults.standard.set(keepAwakeMode.rawValue, forKey: "keepAwakeMode")
            keepAwakePlayer.setMode(keepAwakeMode)
        }
    }
    private let keepAwakePlayer = KeepAwake()

    /// Apply the persisted keep-awake mode on launch.
    func applyKeepAwakeOnLaunch() { keepAwakePlayer.setMode(keepAwakeMode) }
}

extension Color {
    var rgbBytes: (r: UInt8, g: UInt8, b: UInt8) {
        let ns = NSColor(self).usingColorSpace(.deviceRGB) ?? .green
        return (UInt8(ns.redComponent * 255), UInt8(ns.greenComponent * 255), UInt8(ns.blueComponent * 255))
    }
}
