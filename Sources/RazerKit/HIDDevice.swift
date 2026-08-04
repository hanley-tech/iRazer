import Foundation
import IOKit.hid

public let razerVID = 0x1532
public let nommoV2PID = 0x055C

public final class HIDDevice {
    public let device: IOHIDDevice

    public init(device: IOHIDDevice) {
        self.device = device
    }

    func prop(_ key: String) -> Any? {
        IOHIDDeviceGetProperty(device, key as CFString)
    }
    func intProp(_ key: String) -> Int? { prop(key) as? Int }
    func strProp(_ key: String) -> String? { prop(key) as? String }

    public var vendorID: Int { intProp(kIOHIDVendorIDKey) ?? 0 }
    public var productID: Int { intProp(kIOHIDProductIDKey) ?? 0 }
    public var product: String { strProp(kIOHIDProductKey) ?? "?" }
    public var manufacturer: String { strProp(kIOHIDManufacturerKey) ?? "?" }
    public var maxFeatureReportSize: Int { intProp(kIOHIDMaxFeatureReportSizeKey) ?? 0 }
    public var maxOutputReportSize: Int { intProp(kIOHIDMaxOutputReportSizeKey) ?? 0 }
    public var maxInputReportSize: Int { intProp(kIOHIDMaxInputReportSizeKey) ?? 0 }
    public var usagePage: Int { intProp(kIOHIDPrimaryUsagePageKey) ?? 0 }
    public var usage: Int { intProp(kIOHIDPrimaryUsageKey) ?? 0 }
    public var reportDescriptor: [UInt8]? {
        guard let d = prop(kIOHIDReportDescriptorKey) as? Data else { return nil }
        return [UInt8](d)
    }

    public func open() throws {
        // Non-exclusive first so the app and CLI can talk to the device at
        // the same time; feature reports work fine without seizing.
        let r = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        if r != kIOReturnSuccess {
            let r2 = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
            guard r2 == kIOReturnSuccess else {
                throw NommoError.ioKit("IOHIDDeviceOpen", r2)
            }
        }
    }

    public func close() {
        IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    public func setFeatureReport(id: CFIndex, bytes: [UInt8]) throws {
        let data = bytes
        let r = data.withUnsafeBufferPointer {
            IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, id, $0.baseAddress!, $0.count)
        }
        guard r == kIOReturnSuccess else { throw NommoError.ioKit("SetReport(feature,\(id))", r) }
    }

    public func getFeatureReport(id: CFIndex, length: Int) throws -> [UInt8] {
        var buf = [UInt8](repeating: 0, count: length)
        var len = CFIndex(length)
        let r = buf.withUnsafeMutableBufferPointer {
            IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, id, $0.baseAddress!, &len)
        }
        guard r == kIOReturnSuccess else { throw NommoError.ioKit("GetReport(feature,\(id))", r) }
        return Array(buf[0..<len])
    }

    /// Register for incoming input reports (e.g. report 5 events). The device
    /// must be scheduled on a run loop; call from the main thread of an app.
    public func listenForInputReports(_ handler: @escaping (Int, [UInt8]) -> Void) {
        let bufSize = max(maxInputReportSize, 64)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
        let box = InputCallbackBox(handler: handler)
        inputBox = box
        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDDeviceRegisterInputReportCallback(device, buffer, bufSize, { context, _, _, _, reportID, report, reportLength in
            guard let context else { return }
            let box = Unmanaged<InputCallbackBox>.fromOpaque(context).takeUnretainedValue()
            let bytes = Array(UnsafeBufferPointer(start: report, count: reportLength))
            box.handler(Int(reportID), bytes)
        }, Unmanaged.passUnretained(box).toOpaque())
    }

    private var inputBox: InputCallbackBox?

    public func setOutputReport(id: CFIndex, bytes: [UInt8]) throws {
        let data = bytes
        let r = data.withUnsafeBufferPointer {
            IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, id, $0.baseAddress!, $0.count)
        }
        guard r == kIOReturnSuccess else { throw NommoError.ioKit("SetReport(output,\(id))", r) }
    }
}

public enum NommoError: Error, CustomStringConvertible {
    case ioKit(String, IOReturn)
    case notFound
    case badResponse(String)

    public var description: String {
        switch self {
        case .ioKit(let op, let code):
            return String(format: "%@ failed: 0x%08x (%@)", op, code, ioReturnName(code))
        case .notFound:
            return "No Razer HID device found. Is the Nommo V2 plugged in via USB?"
        case .badResponse(let s):
            return "Bad response: \(s)"
        }
    }
}

public func ioReturnName(_ r: IOReturn) -> String {
    switch r {
    case kIOReturnNotPrivileged: return "kIOReturnNotPrivileged — try running with sudo"
    case kIOReturnExclusiveAccess: return "kIOReturnExclusiveAccess — device claimed by another process"
    case kIOReturnUnsupported: return "kIOReturnUnsupported"
    case kIOReturnTimeout: return "kIOReturnTimeout"
    case kIOReturnNotFound: return "kIOReturnNotFound"
    default: return "see IOKit/IOReturn.h"
    }
}

/// Enumerate all HID devices, optionally filtered to Razer VID.
public func enumerateHIDDevices(vendorID: Int? = razerVID, productID: Int? = nil) -> [HIDDevice] {
    let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    var match: [String: Any] = [:]
    if let v = vendorID { match[kIOHIDVendorIDKey] = v }
    if let p = productID { match[kIOHIDProductIDKey] = p }
    IOHIDManagerSetDeviceMatching(manager, match.isEmpty ? nil : match as CFDictionary)
    IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    defer { IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone)) }
    guard let set = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else { return [] }
    return set.map { HIDDevice(device: $0) }
        .sorted { ($0.productID, $0.usagePage) < ($1.productID, $1.usagePage) }
}
final class InputCallbackBox {
    let handler: (Int, [UInt8]) -> Void
    init(handler: @escaping (Int, [UInt8]) -> Void) { self.handler = handler }
}
