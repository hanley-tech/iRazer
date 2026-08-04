import Foundation

/// A curated catalog of Razer devices so the app presents as a full device
/// manager — supported devices are interactive, the rest show as "planned"
/// so users see where the project is going (and how to help).
enum DeviceCategory: String, CaseIterable, Identifiable {
    case speakers = "Speakers"
    case keyboards = "Keyboards"
    case mice = "Mice"
    case headsets = "Headsets"
    case mousepads = "Mouse Mats"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .speakers: return "hifispeaker.fill"
        case .keyboards: return "keyboard.fill"
        case .mice: return "magicmouse.fill"
        case .headsets: return "headphones"
        case .mousepads: return "rectangle.fill"
        }
    }
}

enum SupportLevel {
    case supported          // fully integrated, controllable
    case partial            // some features work
    case planned            // known device, not yet implemented
}

struct RazerDeviceInfo: Identifiable {
    let id: String          // stable key
    let name: String
    let category: DeviceCategory
    let pid: String         // "1532:055C" or "—"
    let support: SupportLevel
    /// Capabilities to advertise in the detail pane (grayed for planned devices).
    let capabilities: [String]
}

enum DeviceCatalog {
    /// The one device we actually drive. `id` is matched by the view model.
    static let nommoV2ID = "nommo-v2"

    static let all: [RazerDeviceInfo] = [
        // Speakers
        .init(id: nommoV2ID, name: "Razer Nommo V2", category: .speakers, pid: "1532:055C",
              support: .supported, capabilities: ["Brightness", "EQ", "Volume", "Keep-awake", "RGB (soon)"]),
        .init(id: "nommo-v2-pro", name: "Razer Nommo V2 Pro", category: .speakers, pid: "1532:055A",
              support: .planned, capabilities: ["EQ", "Volume", "RGB", "THX"]),
        .init(id: "nommo-v2-x", name: "Razer Nommo V2 X", category: .speakers, pid: "1532:055E",
              support: .planned, capabilities: ["EQ", "Volume", "RGB"]),
        .init(id: "leviathan-v2", name: "Razer Leviathan V2", category: .speakers, pid: "1532:0532",
              support: .planned, capabilities: ["RGB", "EQ", "THX"]),
        .init(id: "leviathan-v2-x", name: "Razer Leviathan V2 X", category: .speakers, pid: "1532:054A",
              support: .planned, capabilities: ["RGB", "EQ"]),

        // Keyboards
        .init(id: "blackwidow-v4-pro", name: "Razer BlackWidow V4 Pro", category: .keyboards, pid: "1532:0295",
              support: .planned, capabilities: ["Per-key RGB", "Macros", "Brightness"]),
        .init(id: "huntsman-v3-pro", name: "Razer Huntsman V3 Pro", category: .keyboards, pid: "1532:02a6",
              support: .planned, capabilities: ["Per-key RGB", "Rapid Trigger", "Macros"]),
        .init(id: "ornata-v3", name: "Razer Ornata V3", category: .keyboards, pid: "1532:028f",
              support: .planned, capabilities: ["Zone RGB", "Brightness"]),

        // Mice
        .init(id: "deathadder-v3-pro", name: "Razer DeathAdder V3 Pro", category: .mice, pid: "1532:00b6",
              support: .planned, capabilities: ["DPI", "Polling", "Battery"]),
        .init(id: "basilisk-v3", name: "Razer Basilisk V3", category: .mice, pid: "1532:0099",
              support: .planned, capabilities: ["RGB", "DPI", "Scroll modes"]),
        .init(id: "viper-v3-pro", name: "Razer Viper V3 Pro", category: .mice, pid: "1532:00c1",
              support: .planned, capabilities: ["DPI", "Polling", "Battery"]),
        .init(id: "naga-v2-pro", name: "Razer Naga V2 Pro", category: .mice, pid: "1532:00b4",
              support: .planned, capabilities: ["RGB", "DPI", "Side buttons"]),

        // Headsets
        .init(id: "kraken-v3", name: "Razer Kraken V3", category: .headsets, pid: "1532:0559",
              support: .planned, capabilities: ["RGB", "THX", "Mic"]),
        .init(id: "blackshark-v2-pro", name: "Razer BlackShark V2 Pro", category: .headsets, pid: "1532:0561",
              support: .planned, capabilities: ["EQ", "Mic", "Battery"]),
        .init(id: "barracuda-x", name: "Razer Barracuda X", category: .headsets, pid: "1532:0574",
              support: .planned, capabilities: ["EQ", "Battery"]),

        // Mouse mats
        .init(id: "firefly-v2", name: "Razer Firefly V2", category: .mousepads, pid: "1532:0c04",
              support: .planned, capabilities: ["RGB", "Brightness"]),
        .init(id: "goliathus-chroma", name: "Razer Goliathus Chroma", category: .mousepads, pid: "1532:0c02",
              support: .planned, capabilities: ["RGB", "Brightness"]),
    ]

    static func byCategory(_ c: DeviceCategory) -> [RazerDeviceInfo] {
        all.filter { $0.category == c }
    }
}
