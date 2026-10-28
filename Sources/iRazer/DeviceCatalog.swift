import Foundation

// AUTO-GENERATED device catalog. Facts (name / PID / category / matrix type /
// transaction id) sourced from the OpenRazer & OpenRGB projects (device metadata
// is factual, not copyrightable); iRazer's control code is its own (MIT).
//
// support: .supported = verified on real hardware. .experimental = protocol known
// but UNTESTED on macOS — needs community verification. See docs/TESTING.md.

enum DeviceCategory: String, CaseIterable, Identifiable {
    case speakers = "Speakers"
    case keyboards = "Keyboards"
    case mice = "Mice"
    case mousepads = "Mouse Mats"
    case headsets = "Headsets"
    case keypads = "Keypads"
    case laptops = "Laptops"
    case ledstrips = "LED Strips"
    case gpus = "GPUs"
    case accessories = "Accessories"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .speakers: return "hifispeaker.fill"
        case .keyboards: return "keyboard.fill"
        case .mice: return "magicmouse.fill"
        case .mousepads: return "rectangle.fill"
        case .headsets: return "headphones"
        case .keypads: return "square.grid.3x3.fill"
        case .laptops: return "laptopcomputer"
        case .ledstrips: return "sparkles"
        case .gpus: return "cpu"
        case .accessories: return "shippingbox.fill"
        }
    }
}

enum SupportLevel { case supported, experimental, planned }

struct RazerDeviceInfo: Identifiable {
    let id: String
    let name: String
    let category: DeviceCategory
    let pid: String
    let support: SupportLevel
    let capabilities: [String]
    var matrix: String = ""
    var tx: String = ""
}

enum DeviceCatalog {
    static let nommoV2ID = "nommo-v2"

    static let all: [RazerDeviceInfo] = [
        .init(id: nommoV2ID, name: "Razer Nommo V2", category: .speakers, pid: "1532:055C",
              support: .supported, capabilities: ["Keep-awake", "Brightness", "EQ", "Volume", "RGB (soon)"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-055a", name: "Razer Nommo V2 Pro", category: .speakers, pid: "1532:055A", support: .experimental, capabilities: ["EQ","Volume","RGB"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-055e", name: "Razer Nommo V2 X", category: .speakers, pid: "1532:055E",
              support: .supported, capabilities: ["Keep-awake", "EQ", "Volume"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0241", name: "Razer BlackWidow 2019", category: .keyboards, pid: "1532:0241", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0203", name: "Razer BlackWidow Chroma", category: .keyboards, pid: "1532:0203", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0211", name: "Razer Blackwidow Chroma Overwatch", category: .keyboards, pid: "1532:0211", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0209", name: "Razer BlackWidow Chroma Tournament Edition", category: .keyboards, pid: "1532:0209", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0221", name: "Razer BlackWidow Chroma V2", category: .keyboards, pid: "1532:0221", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0228", name: "Razer BlackWidow Elite", category: .keyboards, pid: "1532:0228", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-024e", name: "Razer Blackwidow V3", category: .keyboards, pid: "1532:024E", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-025a", name: "Razer BlackWidow V3 Pro (Wired)", category: .keyboards, pid: "1532:025A", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-025b", name: "Razer BlackWidow V3 Pro (Bluetooth)", category: .keyboards, pid: "1532:025B", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-025c", name: "Razer BlackWidow V3 Pro (Wireless)", category: .keyboards, pid: "1532:025C", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0a24", name: "Razer BlackWidow V3 TKL", category: .keyboards, pid: "1532:0A24", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0258", name: "Razer BlackWidow V3 Mini (Wired)", category: .keyboards, pid: "1532:0258", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0271", name: "Razer BlackWidow V3 Mini (Wireless)", category: .keyboards, pid: "1532:0271", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "9f"),
        .init(id: "pid-0287", name: "Razer Blackwidow V4", category: .keyboards, pid: "1532:0287", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-028d", name: "Razer Blackwidow V4 Pro", category: .keyboards, pid: "1532:028D", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-02b3", name: "Razer Blackwidow V4 Pro 75% (Wired)", category: .keyboards, pid: "1532:02B3", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-02b4", name: "Razer Blackwidow V4 Pro 75% (Wireless)", category: .keyboards, pid: "1532:02B4", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-02a5", name: "Razer Blackwidow V4 75% (Wired)", category: .keyboards, pid: "1532:02A5", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0293", name: "Razer Blackwidow V4 X", category: .keyboards, pid: "1532:0293", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-02d7", name: "Razer Blackwidow V4 TKL (Wired)", category: .keyboards, pid: "1532:02D7", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-02d5", name: "Razer Blackwidow V4 TKL (Wireless)", category: .keyboards, pid: "1532:02D5", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "9f"),
        .init(id: "pid-02d4", name: "Razer Blackwidow V4 Low Profile TKL (Wired)", category: .keyboards, pid: "1532:02D4", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-02d2", name: "Razer Blackwidow V4 Low Profile TKL (Wireless)", category: .keyboards, pid: "1532:02D2", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "9f"),
        .init(id: "pid-0216", name: "Razer BlackWidow X Chroma", category: .keyboards, pid: "1532:0216", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-021a", name: "Razer BlackWidow X Chroma Tournament Edition", category: .keyboards, pid: "1532:021A", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-022a", name: "Razer Cynosa Chroma", category: .keyboards, pid: "1532:022A", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-025e", name: "Razer Cynosa v2", category: .keyboards, pid: "1532:025E", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-023f", name: "Razer Cynosa Lite", category: .keyboards, pid: "1532:023F", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-021e", name: "Razer Ornata Chroma", category: .keyboards, pid: "1532:021E", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-025d", name: "Razer Ornata Chroma V2", category: .keyboards, pid: "1532:025D", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-028f", name: "Razer Ornata V3", category: .keyboards, pid: "1532:028F", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-02a1", name: "Razer Ornata V3 rev2", category: .keyboards, pid: "1532:02A1", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-02a3", name: "Razer Ornata V3 TKL", category: .keyboards, pid: "1532:02A3", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0294", name: "Razer Ornata V3 X", category: .keyboards, pid: "1532:0294", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-02a2", name: "Razer Ornata V3 X Rev2", category: .keyboards, pid: "1532:02A2", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0204", name: "Razer DeathStalker Chroma", category: .keyboards, pid: "1532:0204", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "LINEAR", tx: "3f"),
        .init(id: "pid-0295", name: "Razer Deathstalker V2", category: .keyboards, pid: "1532:0295", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0298", name: "Razer DeathStalker V2 Pro TKL (Wired)", category: .keyboards, pid: "1532:0298", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0296", name: "Razer DeathStalker V2 Pro TKL (Wireless)", category: .keyboards, pid: "1532:0296", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "9f"),
        .init(id: "pid-0290", name: "Razer DeathStalker V2 Pro (Wireless)", category: .keyboards, pid: "1532:0290", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "9f"),
        .init(id: "pid-0292", name: "Razer DeathStalker V2 Pro (Wired)", category: .keyboards, pid: "1532:0292", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "9f"),
        .init(id: "pid-0227", name: "Razer Huntsman", category: .keyboards, pid: "1532:0227", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0226", name: "Razer Huntsman Elite", category: .keyboards, pid: "1532:0226", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0266", name: "Razer Huntsman V2 Analog", category: .keyboards, pid: "1532:0266", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0257", name: "Razer Huntsman Mini", category: .keyboards, pid: "1532:0257", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0282", name: "Razer Huntsman Mini Analog", category: .keyboards, pid: "1532:0282", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0243", name: "Razer Huntsman Tournament Edition", category: .keyboards, pid: "1532:0243", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-026b", name: "Razer Huntsman V2 TKL", category: .keyboards, pid: "1532:026B", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-026c", name: "Razer Huntsman V2", category: .keyboards, pid: "1532:026C", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-02a6", name: "Razer Huntsman V3 Pro", category: .keyboards, pid: "1532:02A6", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-02a7", name: "Razer Huntsman V3 Pro TKL White", category: .keyboards, pid: "1532:02A7", support: .experimental, capabilities: ["Per-key RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-020f", name: "Razer Blade (2016)", category: .laptops, pid: "1532:020F", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0224", name: "Razer Blade (Late 2016)", category: .laptops, pid: "1532:0224", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0233", name: "Razer Blade 15 (2018 Advanced)", category: .laptops, pid: "1532:0233", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-023b", name: "Razer Blade 15 (2018 Base)", category: .laptops, pid: "1532:023B", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0240", name: "Razer Blade 15 (2018 Mercury)", category: .laptops, pid: "1532:0240", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-023a", name: "Razer Blade 15 (2019 Advanced)", category: .laptops, pid: "1532:023A", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0246", name: "Razer Blade 15 (2019 Base)", category: .laptops, pid: "1532:0246", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0245", name: "Razer Blade 15 (2019 Mercury)", category: .laptops, pid: "1532:0245", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-024d", name: "Razer Blade 15 (2019 Studio)", category: .laptops, pid: "1532:024D", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0253", name: "Razer Blade 15 (2020 Advanced)", category: .laptops, pid: "1532:0253", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0255", name: "Razer Blade 15 (2020 Base)", category: .laptops, pid: "1532:0255", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0268", name: "Razer Blade (Late 2020)", category: .laptops, pid: "1532:0268", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-026d", name: "Razer Blade 15 (2021 Advanced)", category: .laptops, pid: "1532:026D", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-026f", name: "Razer Blade 15 (2021 Base)", category: .laptops, pid: "1532:026F", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-027a", name: "Razer Blade 15 (2021 Base)", category: .laptops, pid: "1532:027A", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "1f"),
        .init(id: "pid-0276", name: "Razer Blade 15 (Late 2021 Advanced)", category: .laptops, pid: "1532:0276", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0270", name: "Razer Blade 14 (2021)", category: .laptops, pid: "1532:0270", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-028c", name: "Razer Blade 14 (2022)", category: .laptops, pid: "1532:028C", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "1f"),
        .init(id: "pid-029d", name: "Razer Blade 14 (2023)", category: .laptops, pid: "1532:029D", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "1f"),
        .init(id: "pid-028a", name: "Razer Blade 15 (2022)", category: .laptops, pid: "1532:028A", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "1f"),
        .init(id: "pid-026a", name: "Razer Book 13 (2020)", category: .laptops, pid: "1532:026A", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0210", name: "Razer Blade Pro (2016)", category: .laptops, pid: "1532:0210", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0225", name: "Razer Blade Pro (2017)", category: .laptops, pid: "1532:0225", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-022f", name: "Razer Blade Pro (2017 FullHD)", category: .laptops, pid: "1532:022F", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0234", name: "Razer Blade Pro (2019)", category: .laptops, pid: "1532:0234", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-024c", name: "Razer Blade Pro (Late 2019)", category: .laptops, pid: "1532:024C", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0256", name: "Razer Blade Pro 17 (2020)", category: .laptops, pid: "1532:0256", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0279", name: "Razer Blade Pro 17 (2021)", category: .laptops, pid: "1532:0279", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0205", name: "Razer Blade Stealth (2016)", category: .laptops, pid: "1532:0205", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0220", name: "Razer Blade Stealth (Late 2016)", category: .laptops, pid: "1532:0220", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-022d", name: "Razer Blade Stealth (2017)", category: .laptops, pid: "1532:022D", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0232", name: "Razer Blade Stealth (Late 2017)", category: .laptops, pid: "1532:0232", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0239", name: "Razer Blade Stealth (2019)", category: .laptops, pid: "1532:0239", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-024a", name: "Razer Blade Stealth (Late 2019)", category: .laptops, pid: "1532:024A", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0252", name: "Razer Blade Stealth (2020)", category: .laptops, pid: "1532:0252", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0259", name: "Razer Blade Stealth (Late 2020)", category: .laptops, pid: "1532:0259", support: .experimental, capabilities: ["Keyboard RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-006a", name: "Razer Abyssus Elite DVa Edition", category: .mice, pid: "1532:006A", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-006b", name: "Razer Abyssus Essential", category: .mice, pid: "1532:006B", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0064", name: "Razer Basilisk", category: .mice, pid: "1532:0064", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0065", name: "Razer Basilisk Essential", category: .mice, pid: "1532:0065", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0086", name: "Razer Basilisk Ultimate", category: .mice, pid: "1532:0086", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0088", name: "Razer Basilisk Ultimate (Wireless)", category: .mice, pid: "1532:0088", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0085", name: "Razer Basilisk V2", category: .mice, pid: "1532:0085", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0099", name: "Razer Basilisk V3", category: .mice, pid: "1532:0099", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00cb", name: "Razer Basilisk V3 35K", category: .mice, pid: "1532:00CB", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00aa", name: "Razer Basilisk V3 Pro (Wired)", category: .mice, pid: "1532:00AA", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00ab", name: "Razer Basilisk V3 Pro (Wireless)", category: .mice, pid: "1532:00AB", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00cc", name: "Razer Basilisk V3 Pro 35K (Wired)", category: .mice, pid: "1532:00CC", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00cd", name: "Razer Basilisk V3 Pro 35K (Wireless)", category: .mice, pid: "1532:00CD", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00d6", name: "Razer Basilisk V3 Pro 35K Phantom Green Edition (Wired)", category: .mice, pid: "1532:00D6", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00d7", name: "Razer Basilisk V3 Pro 35K Phantom Green Edition (Wireless)", category: .mice, pid: "1532:00D7", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00d8", name: "Razer Basilisk V3 Pro 35K Phantom Green Edition (Bluetooth)", category: .mice, pid: "1532:00D8", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00ac", name: "Razer Basilisk V3 Pro (Bluetooth)", category: .mice, pid: "1532:00AC", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00b9", name: "Razer Basilisk V3 X HyperSpeed", category: .mice, pid: "1532:00B9", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00a3", name: "Razer Cobra", category: .mice, pid: "1532:00A3", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00af", name: "Razer Cobra Pro (Wired)", category: .mice, pid: "1532:00AF", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00b0", name: "Razer Cobra Pro (Wireless)", category: .mice, pid: "1532:00B0", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0043", name: "Razer DeathAdder Chroma", category: .mice, pid: "1532:0043", support: .experimental, capabilities: ["RGB","DPI"], matrix: "CUSTOM", tx: "1f"),
        .init(id: "pid-005c", name: "Razer DeathAdder Elite", category: .mice, pid: "1532:005C", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-006e", name: "Razer DeathAdder Essential", category: .mice, pid: "1532:006E", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0098", name: "Razer DeathAdder Essential V2", category: .mice, pid: "1532:0098", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0071", name: "Razer DeathAdder Essential (White Edition)", category: .mice, pid: "1532:0071", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0084", name: "Razer DeathAdder V2", category: .mice, pid: "1532:0084", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-008c", name: "Razer DeathAdder V2 Mini", category: .mice, pid: "1532:008C", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-007c", name: "Razer DeathAdder V2 (Wired)", category: .mice, pid: "1532:007C", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-007d", name: "Razer DeathAdder V2 (Wireless)", category: .mice, pid: "1532:007D", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-004c", name: "Razer Diamondback Chroma", category: .mice, pid: "1532:004C", support: .experimental, capabilities: ["RGB","DPI"], matrix: "LINEAR", tx: "3f"),
        .init(id: "pid-0059", name: "Razer Lancehead 2017 (Wired)", category: .mice, pid: "1532:0059", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-005a", name: "Razer Lancehead 2017 (Wireless)", category: .mice, pid: "1532:005A", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0070", name: "Razer Lancehead 2019 (Wired)", category: .mice, pid: "1532:0070", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-006f", name: "Razer Lancehead 2019 (Wireless)", category: .mice, pid: "1532:006F", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0060", name: "Razer Lancehead Tournament Edition", category: .mice, pid: "1532:0060", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0532", name: "Razer Leviathan V2", category: .speakers, pid: "1532:0532", support: .experimental, capabilities: ["EQ","Volume","RGB"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-054a", name: "Razer Leviathan V2 X", category: .speakers, pid: "1532:054A", support: .experimental, capabilities: ["EQ","Volume","RGB"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0024", name: "Razer Mamba 2012 (Wired)", category: .mice, pid: "1532:0024", support: .experimental, capabilities: ["RGB","DPI"], matrix: "CUSTOM", tx: "3f"),
        .init(id: "pid-0025", name: "Razer Mamba 2012 (Wireless)", category: .mice, pid: "1532:0025", support: .experimental, capabilities: ["RGB","DPI"], matrix: "CUSTOM", tx: "3f"),
        .init(id: "pid-0044", name: "Razer Mamba 2015 (Wired)", category: .mice, pid: "1532:0044", support: .experimental, capabilities: ["RGB","DPI"], matrix: "LINEAR", tx: "3f"),
        .init(id: "pid-0045", name: "Razer Mamba (Wireless)", category: .mice, pid: "1532:0045", support: .experimental, capabilities: ["RGB","DPI"], matrix: "LINEAR", tx: "3f"),
        .init(id: "pid-0073", name: "Razer Mamba 2018 (Wired)", category: .mice, pid: "1532:0073", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0072", name: "Razer Mamba 2018 (Wireless)", category: .mice, pid: "1532:0072", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-006c", name: "Razer Mamba Elite", category: .mice, pid: "1532:006C", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0046", name: "Razer Mamba Tournament Edition", category: .mice, pid: "1532:0046", support: .experimental, capabilities: ["RGB","DPI"], matrix: "LINEAR", tx: "3f"),
        .init(id: "pid-0069", name: "Razer Mamba Hyperflux (Wired)", category: .mice, pid: "1532:0069", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0053", name: "Razer Naga Chroma", category: .mice, pid: "1532:0053", support: .experimental, capabilities: ["RGB","DPI"], matrix: "LINEAR", tx: "3f"),
        .init(id: "pid-0093", name: "Razer Naga Classic", category: .mice, pid: "1532:0093", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0050", name: "Razer Naga Hex V2", category: .mice, pid: "1532:0050", support: .experimental, capabilities: ["RGB","DPI"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-008d", name: "Razer Naga Left Handed", category: .mice, pid: "1532:008D", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0067", name: "Razer Naga Trinity", category: .mice, pid: "1532:0067", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-008f", name: "Razer Naga Pro (Wired)", category: .mice, pid: "1532:008F", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0090", name: "Razer Naga Pro (Wireless)", category: .mice, pid: "1532:0090", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00a7", name: "Razer Naga Pro V2 (Wired)", category: .mice, pid: "1532:00A7", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-00a8", name: "Razer Naga Pro V2 (Wireless)", category: .mice, pid: "1532:00A8", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0091", name: "Razer Viper 8kHz", category: .mice, pid: "1532:0091", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-008a", name: "Razer Viper Mini", category: .mice, pid: "1532:008A", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-007a", name: "Razer Viper Ultimate (Wired)", category: .mice, pid: "1532:007A", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-007b", name: "Razer Viper Ultimate (Wireless)", category: .mice, pid: "1532:007B", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0078", name: "Razer Viper", category: .mice, pid: "1532:0078", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-003e", name: "Razer Naga Epic Chroma", category: .mice, pid: "1532:003E", support: .experimental, capabilities: ["RGB","DPI"], matrix: "CUSTOM", tx: "1f"),
        .init(id: "pid-0207", name: "Razer Orbweaver Chroma", category: .keypads, pid: "1532:0207", support: .experimental, capabilities: ["RGB","Macros"], matrix: "CUSTOM", tx: "3f"),
        .init(id: "pid-0208", name: "Razer Tartarus Chroma", category: .keypads, pid: "1532:0208", support: .experimental, capabilities: ["RGB","Macros"], matrix: "CUSTOM", tx: "1f"),
        .init(id: "pid-0244", name: "Razer Tartarus Pro", category: .keypads, pid: "1532:0244", support: .experimental, capabilities: ["RGB","Macros"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-022b", name: "Razer Tartarus V2", category: .keypads, pid: "1532:022B", support: .experimental, capabilities: ["RGB","Macros"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0c00", name: "Razer Firefly", category: .mousepads, pid: "1532:0C00", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "LINEAR", tx: "3f"),
        .init(id: "pid-0068", name: "Razer Firefly Hyperflux", category: .mousepads, pid: "1532:0068", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0c04", name: "Razer Firefly V2", category: .mousepads, pid: "1532:0C04", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0c08", name: "Razer Firefly V2 Pro", category: .mousepads, pid: "1532:0C08", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0c01", name: "Razer Goliathus", category: .mousepads, pid: "1532:0C01", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0c06", name: "Razer Goliathus Chroma 3XL", category: .mousepads, pid: "1532:0C06", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0c02", name: "Razer Goliathus Extended", category: .mousepads, pid: "1532:0C02", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0c05", name: "Razer Strider Chroma", category: .mousepads, pid: "1532:0C05", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0f19", name: "Razer Kraken Kitty Edition", category: .headsets, pid: "1532:0F19", support: .experimental, capabilities: ["RGB","Mic"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0560", name: "Razer Kraken Kitty Black Edition V2", category: .headsets, pid: "1532:0560", support: .experimental, capabilities: ["RGB","Mic"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-056b", name: "Razer Kraken V4 (Wired)", category: .headsets, pid: "1532:056B", support: .experimental, capabilities: ["RGB","Mic"], matrix: "EXTENDED", tx: "60"),
        .init(id: "pid-056c", name: "Razer Kraken V4 (Wireless)", category: .headsets, pid: "1532:056C", support: .experimental, capabilities: ["RGB","Mic"], matrix: "EXTENDED", tx: "60"),
        .init(id: "pid-0587", name: "Razer Kraken Kitty V3 Pro (Wired)", category: .headsets, pid: "1532:0587", support: .experimental, capabilities: ["RGB","Mic"], matrix: "EXTENDED", tx: "60"),
        .init(id: "pid-0588", name: "Razer Kraken Kitty V3 Pro (Wireless)", category: .headsets, pid: "1532:0588", support: .experimental, capabilities: ["RGB","Mic"], matrix: "EXTENDED", tx: "60"),
        .init(id: "pid-0f03", name: "Razer Tiamat 7.1 V2", category: .headsets, pid: "1532:0F03", support: .experimental, capabilities: ["RGB","Mic"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0215", name: "Razer Core", category: .gpus, pid: "1532:0215", support: .experimental, capabilities: ["RGB"], matrix: "STANDARD", tx: "3f"),
        .init(id: "pid-0f1a", name: "Razer Core X", category: .gpus, pid: "1532:0F1A", support: .experimental, capabilities: ["RGB"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0f07", name: "Razer Chroma Mug Holder", category: .accessories, pid: "1532:0F07", support: .experimental, capabilities: ["RGB"], matrix: "LINEAR", tx: "3f"),
        .init(id: "pid-0f1f", name: "Razer Chroma Addressable RGB Controller", category: .ledstrips, pid: "1532:0F1F", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED_ARGB", tx: "3f"),
        .init(id: "pid-0f09", name: "Razer Chroma HDK", category: .ledstrips, pid: "1532:0F09", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0f0e", name: "Razer Chroma PC Case Lighting Kit", category: .ledstrips, pid: "1532:0F0E", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0f08", name: "Razer Base Station Chroma", category: .accessories, pid: "1532:0F08", support: .experimental, capabilities: ["RGB"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0f1d", name: "Razer Mouse Bungee V3 Chroma", category: .mice, pid: "1532:0F1D", support: .experimental, capabilities: ["RGB","DPI"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0f20", name: "Razer Base Station V2 Chroma", category: .accessories, pid: "1532:0F20", support: .experimental, capabilities: ["RGB"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0f0d", name: "Razer Laptop Stand Chroma", category: .ledstrips, pid: "1532:0F0D", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0f2b", name: "Razer Laptop Stand Chroma V2", category: .ledstrips, pid: "1532:0F2B", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-007e", name: "Razer Mouse Dock Chroma", category: .ledstrips, pid: "1532:007E", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-00a4", name: "Razer Mouse Dock Pro", category: .ledstrips, pid: "1532:00A4", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "ff"),
        .init(id: "pid-0518", name: "Razer Nommo Pro", category: .speakers, pid: "1532:0518", support: .experimental, capabilities: ["EQ","Volume","RGB"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0517", name: "Razer Nommo Chroma", category: .speakers, pid: "1532:0517", support: .experimental, capabilities: ["EQ","Volume","RGB"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0f26", name: "Razer Charging Pad Chroma", category: .accessories, pid: "1532:0F26", support: .experimental, capabilities: ["RGB"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0f13", name: "Lian Li O11 Dynamic - Razer Edition", category: .ledstrips, pid: "1532:0F13", support: .experimental, capabilities: ["RGB","Brightness"], matrix: "EXTENDED", tx: "1f"),
        .init(id: "pid-0f1b", name: "Razer Seiren Emote", category: .accessories, pid: "1532:0F1B", support: .experimental, capabilities: ["RGB"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0f21", name: "Razer Thunderbolt 4 Dock Chroma", category: .accessories, pid: "1532:0F21", support: .experimental, capabilities: ["RGB"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0f52", name: "Razer Thunderbolt 5 Dock Chroma", category: .accessories, pid: "1532:0F52", support: .experimental, capabilities: ["RGB"], matrix: "EXTENDED", tx: "3f"),
        .init(id: "pid-0f35", name: "Razer Hanbo Chroma", category: .accessories, pid: "1532:0F35", support: .experimental, capabilities: ["RGB"], matrix: "EXTENDED", tx: "3f"),
    ]

    static func byCategory(_ c: DeviceCategory) -> [RazerDeviceInfo] { all.filter { $0.category == c } }
    static var supportedCount: Int { all.filter { $0.support == .supported }.count }
    static var experimentalCount: Int { all.filter { $0.support == .experimental }.count }
}
