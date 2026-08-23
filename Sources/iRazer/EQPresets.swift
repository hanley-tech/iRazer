import Foundation

/// A named set of the ten band gains, in dB (-12…+12).
///
/// The speakers have four *firmware* presets (see `NommoDevice.setEQPreset`), but
/// they can't be renamed and only one of them is genuinely useful. These are
/// host-side presets: iRazer just writes the band gains, so a preset can be
/// anything and switching is a single HID write.
struct EQPreset: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var gains: [Double]          // 10 values, -12…+12

    /// Symbol shown next to the preset in menus. Built-ins get a fitting glyph;
    /// user presets fall back to a generic slider icon.
    var symbol: String = "slider.horizontal.3"

    static func == (a: EQPreset, b: EQPreset) -> Bool { a.id == b.id }

    /// True when the given live gains match this preset (so the menu can tick it).
    func matches(_ live: [Double]) -> Bool {
        guard live.count == gains.count else { return false }
        return zip(live, gains).allSatisfy { abs($0 - $1) < 0.5 }
    }
}

extension EQPreset {
    //                                 31   63  125  250  500   1k   2k   4k   8k  16k
    static let builtins: [EQPreset] = [
        EQPreset(name: "Flat",       gains: [ 0,  0,  0,  0,  0,  0,  0,  0,  0,  0], symbol: "minus"),
        EQPreset(name: "Bass Boost", gains: [ 8,  7,  5,  2,  0,  0,  0,  0,  1,  2], symbol: "waveform.path"),
        EQPreset(name: "Vocal",      gains: [-3, -2,  0,  2,  4,  4,  3,  1,  0, -1], symbol: "mic"),
        EQPreset(name: "Movie",      gains: [ 5,  4,  1,  0,  1,  2,  2,  3,  4,  4], symbol: "film"),
        EQPreset(name: "Night",      gains: [-4, -3, -1,  1,  3,  3,  2,  0, -2, -3], symbol: "moon"),
    ]
}

/// Persisted list of presets. Built-ins are seeded on first launch and are then
/// ordinary editable entries — nothing here is special-cased.
final class EQPresetStore {
    private static let key = "eqPresets"

    static func load() -> [EQPreset] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([EQPreset].self, from: data),
              !list.isEmpty else { return EQPreset.builtins }
        return list
    }

    static func save(_ presets: [EQPreset]) {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
