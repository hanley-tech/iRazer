import Foundation

/// The 90-byte Razer command packet used by Synapse across nearly all Razer
/// devices (documented by the OpenRazer project). Sent as a HID feature
/// report; the response is read back with a feature GET after a short delay.
public struct RazerReport {
    public static let size = 90

    public var status: UInt8 = 0x00        // 0x00 new command; response: 0x02 = OK
    public var transactionID: UInt8 = 0xFF
    public var remainingPackets: UInt16 = 0
    public var protocolType: UInt8 = 0x00
    public var dataSize: UInt8 = 0x00
    public var commandClass: UInt8 = 0x00
    public var commandID: UInt8 = 0x00
    public var args = [UInt8](repeating: 0, count: 80)

    public init() {}

    public enum Status: UInt8 {
        case newCommand = 0x00
        case busy = 0x01
        case success = 0x02
        case failure = 0x03
        case timeout = 0x04
        case notSupported = 0x05
    }

    public var statusDescription: String {
        switch Status(rawValue: status) {
        case .newCommand: return "NEW_COMMAND (no response written)"
        case .busy: return "BUSY"
        case .success: return "SUCCESS"
        case .failure: return "FAILURE"
        case .timeout: return "TIMEOUT"
        case .notSupported: return "NOT_SUPPORTED"
        case nil: return String(format: "UNKNOWN(0x%02x)", status)
        }
    }

    public func serialize() -> [UInt8] {
        var buf = [UInt8](repeating: 0, count: Self.size)
        buf[0] = status
        buf[1] = transactionID
        buf[2] = UInt8(remainingPackets >> 8)
        buf[3] = UInt8(remainingPackets & 0xFF)
        buf[4] = protocolType
        buf[5] = dataSize
        buf[6] = commandClass
        buf[7] = commandID
        for (i, b) in args.enumerated() { buf[8 + i] = b }
        buf[88] = Self.crc(buf)
        buf[89] = 0
        return buf
    }

    /// XOR of bytes 2...87
    public static func crc(_ buf: [UInt8]) -> UInt8 {
        var c: UInt8 = 0
        for i in 2...87 { c ^= buf[i] }
        return c
    }

    public static func parse(_ buf: [UInt8]) -> RazerReport? {
        guard buf.count >= size else { return nil }
        var r = RazerReport()
        r.status = buf[0]
        r.transactionID = buf[1]
        r.remainingPackets = UInt16(buf[2]) << 8 | UInt16(buf[3])
        r.protocolType = buf[4]
        r.dataSize = buf[5]
        r.commandClass = buf[6]
        r.commandID = buf[7]
        r.args = Array(buf[8..<88])
        return r
    }

    public static func command(class cls: UInt8, id: UInt8, dataSize: UInt8,
                               args: [UInt8] = [], transactionID: UInt8 = 0x3F) -> RazerReport {
        var r = RazerReport()
        r.transactionID = transactionID
        r.commandClass = cls
        r.commandID = id
        r.dataSize = dataSize
        for (i, b) in args.enumerated() { r.args[i] = b }
        return r
    }
}

public func hexDump(_ bytes: [UInt8], perLine: Int = 16) -> String {
    stride(from: 0, to: bytes.count, by: perLine).map { start in
        let end = min(start + perLine, bytes.count)
        let hex = bytes[start..<end].map { String(format: "%02x", $0) }.joined(separator: " ")
        let ascii = bytes[start..<end].map { (32...126).contains($0) ? String(UnicodeScalar($0)) : "." }.joined()
        return String(format: "%04x  %-47s  %@", start, (hex as NSString).utf8String!, ascii)
    }.joined(separator: "\n")
}
