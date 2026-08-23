import Carbon.HIToolbox
import AppKit

/// A system-wide hot key registered with Carbon's `RegisterEventHotKey`.
///
/// Carbon hot keys are the only way to get a global shortcut without asking for
/// Accessibility permission, which would be a heavy ask for a menu-bar utility.
/// The API is old but is still the supported path and works fine sandboxed.
final class GlobalHotKey {
    private var ref: EventHotKeyRef?
    private let id: UInt32
    private let action: () -> Void

    private static var nextID: UInt32 = 1
    private static var registry: [UInt32: GlobalHotKey] = [:]
    /// One shared handler for every hot key — installing one per instance would
    /// fire each action once per registered key.
    private static var handler: EventHandlerRef?

    /// - Parameters:
    ///   - keyCode: a `kVK_*` virtual key code.
    ///   - modifiers: Carbon modifier mask (`cmdKey`, `optionKey`, …).
    init?(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        self.action = action
        self.id = GlobalHotKey.nextID
        GlobalHotKey.nextID += 1

        let hotKeyID = EventHotKeyID(signature: OSType(0x69525A52), id: id)   // 'iRZR'
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                                         GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, ref != nil else { return nil }
        GlobalHotKey.registry[id] = self
        GlobalHotKey.installHandlerIfNeeded()
    }

    private static func installHandlerIfNeeded() {
        guard handler == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var fired = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &fired)
            GlobalHotKey.registry[fired.id]?.action()
            return noErr
        }, 1, &spec, nil, &handler)
    }

    deinit {
        if let ref { UnregisterEventHotKey(ref) }
        GlobalHotKey.registry[id] = nil
    }
}
