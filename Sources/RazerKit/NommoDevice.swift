import Foundation

/// High-level API for the Razer Nommo V2.
///
/// Framing (verified on hardware): the 90-byte Razer packet goes out as a
/// SET_REPORT on feature report 7 with the report-ID byte manually prefixed
/// (`[0x07] + packet`); the response is read back with a feature GET ~60 ms
/// later. Transaction ID is 0x3F for this device family.
public final class NommoDevice {
    public static let featureReportID: CFIndex = 7
    public static let transactionID: UInt8 = 0x3F

    public let hid: HIDDevice
    private var isOpen = false

    public struct State {
        public var serial = ""
        public var hardwareVersion = ""
        public var brightness: UInt8 = 0          // 0-255
        public var eqPreset: UInt8 = 0            // 0-3
        public var eqBands = [UInt8](repeating: 0x0C, count: 10)  // 0x0C = flat
        public var idleTimeoutSeconds: UInt16 = 0 // 0 = standby disabled
        public var powerSaving = false
        public init() {}
    }

    public enum Effect: String, CaseIterable, Identifiable {
        case off, `static`, breathing, spectrum, wave
        public var id: String { rawValue }
    }

    public init(hid: HIDDevice) {
        self.hid = hid
    }

    /// Find the Nommo V2's control interface (the one with the 90-byte feature report).
    public static func find() -> NommoDevice? {
        enumerateHIDDevices(vendorID: razerVID)
            .first { $0.maxFeatureReportSize >= RazerReport.size }
            .map(NommoDevice.init)
    }

    public func open() throws {
        guard !isOpen else { return }
        try hid.open()
        isOpen = true
    }

    public func close() {
        guard isOpen else { return }
        hid.close()
        isOpen = false
    }

    deinit { close() }

    // MARK: - Transport

    @discardableResult
    public func request(_ report: RazerReport) throws -> RazerReport {
        try hid.setFeatureReport(id: Self.featureReportID,
                                 bytes: [UInt8(Self.featureReportID)] + report.serialize())
        usleep(60_000)
        var resp = try hid.getFeatureReport(id: Self.featureReportID,
                                            length: RazerReport.size + 1)
        if resp.count == RazerReport.size + 1 && resp[0] == UInt8(Self.featureReportID) {
            resp = Array(resp.dropFirst())
        }
        guard let parsed = RazerReport.parse(resp) else {
            throw NommoError.badResponse("short response (\(resp.count) bytes)")
        }
        guard parsed.status == RazerReport.Status.success.rawValue else {
            throw NommoError.badResponse(parsed.statusDescription)
        }
        return parsed
    }

    private func get(class cls: UInt8, id: UInt8, size: UInt8, args: [UInt8] = []) throws -> [UInt8] {
        let resp = try request(.command(class: cls, id: id, dataSize: size,
                                        args: args, transactionID: Self.transactionID))
        return Array(resp.args.prefix(Int(size)))
    }

    private func set(class cls: UInt8, id: UInt8, args: [UInt8]) throws {
        try request(.command(class: cls, id: id, dataSize: UInt8(args.count),
                             args: args, transactionID: Self.transactionID))
    }

    // MARK: - Device info

    public func serial() throws -> String {
        let a = try get(class: 0x00, id: 0x82, size: 0x16)
        return a.prefix { $0 != 0 }.map { String(UnicodeScalar($0)) }.joined()
    }

    public func hardwareVersion() throws -> String {
        let a = try get(class: 0x00, id: 0x87, size: 0x02)
        return "\(a[0]).\(a[1])"
    }

    // MARK: - Lighting

    public func brightness() throws -> UInt8 {
        try get(class: 0x0F, id: 0x84, size: 0x03, args: [0x01, 0x00, 0x00])[2]
    }

    public func setBrightness(_ value: UInt8) throws {
        try set(class: 0x0F, id: 0x04, args: [0x01, 0x00, value])
    }

    public func setEffect(_ effect: Effect, color: (r: UInt8, g: UInt8, b: UInt8) = (0, 255, 0)) throws {
        switch effect {
        case .off:
            try set(class: 0x0F, id: 0x02, args: [0x01, 0x00, 0x00, 0x00, 0x00, 0x00])
        case .static:
            try set(class: 0x0F, id: 0x02, args: [0x01, 0x00, 0x01, 0x00, 0x00, 0x01, color.r, color.g, color.b])
        case .breathing:
            try set(class: 0x0F, id: 0x02, args: [0x01, 0x00, 0x02, 0x00, 0x00, 0x01, color.r, color.g, color.b])
        case .spectrum:
            try set(class: 0x0F, id: 0x02, args: [0x01, 0x00, 0x03, 0x00, 0x00, 0x00])
        case .wave:
            try set(class: 0x0F, id: 0x02, args: [0x01, 0x00, 0x04, 0x01, 0x00, 0x00])
        }
    }

    // MARK: - Audio DSP

    /// 10 bands, 31 Hz → 16 kHz. 0x0C is flat; observed range roughly 0x00–0x18 (±12 dB).
    public func eqBands() throws -> [UInt8] {
        Array(try get(class: 0x08, id: 0x84, size: 0x0B).dropFirst())
    }

    public func setEQBands(_ bands: [UInt8]) throws {
        precondition(bands.count == 10)
        try set(class: 0x08, id: 0x04, args: [0x00] + bands)
    }

    public func eqPreset() throws -> UInt8 {
        try get(class: 0x08, id: 0x82, size: 0x02)[1]
    }

    public func setEQPreset(_ preset: UInt8) throws {
        try set(class: 0x08, id: 0x02, args: [0x00, preset])
    }

    public func masterVolume() throws -> UInt8 {
        try get(class: 0x08, id: 0x86, size: 0x02)[1]
    }

    public func setMasterVolume(_ volume: UInt8) throws {
        try set(class: 0x08, id: 0x06, args: [0x00, min(volume, 100)])
    }

    // MARK: - Power

    public func idleTimeout() throws -> UInt16 {
        let a = try get(class: 0x07, id: 0x83, size: 0x03)
        return UInt16(a[0]) << 8 | UInt16(a[1])
    }

    /// 0 disables auto-standby entirely.
    public func setIdleTimeout(seconds: UInt16) throws {
        try set(class: 0x07, id: 0x03, args: [UInt8(seconds >> 8), UInt8(seconds & 0xFF), 0x00])
    }

    public func powerSaving() throws -> Bool {
        try get(class: 0x07, id: 0x88, size: 0x02)[1] != 0
    }

    public func setPowerSaving(_ on: Bool) throws {
        try set(class: 0x07, id: 0x08, args: [0x00, on ? 1 : 0])
    }

    /// Read everything the UI shows in one pass.
    public func readState() throws -> State {
        var s = State()
        s.serial = try serial()
        s.hardwareVersion = try hardwareVersion()
        s.brightness = try brightness()
        s.eqPreset = try eqPreset()
        s.eqBands = try eqBands()
        s.idleTimeoutSeconds = try idleTimeout()
        s.powerSaving = try powerSaving()
        return s
    }
}
