import SwiftUI
import RazerKit

enum Mode: String, CaseIterable { case control = "Control", lab = "Lab", console = "Console" }
enum ControlSection: String, CaseIterable, Identifiable {
    case lighting = "Lighting", sound = "Sound", power = "Power"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .lighting: return "lightbulb.fill"
        case .sound: return "waveform"
        case .power: return "bolt.fill"
        }
    }
}

final class UIState: ObservableObject {
    @Published var mode: Mode = .control
    @Published var selectedDevice: String = DeviceCatalog.nommoV2ID
    @Published var section: ControlSection = .lighting
}

struct ContentView: View {
    @ObservedObject var model: NommoViewModel
    @StateObject private var ui = UIState()

    private var selected: RazerDeviceInfo {
        DeviceCatalog.all.first { $0.id == ui.selectedDevice } ?? DeviceCatalog.all[0]
    }
    private func isConnected(_ d: RazerDeviceInfo) -> Bool {
        guard model.connected, let pid = Int(d.pid.split(separator: ":").last ?? "", radix: 16) else {
            return false
        }
        return model.connectedProductID == pid
    }
    /// Any Razer device (incl. experimental) physically plugged in right now.
    private func isDetected(_ d: RazerDeviceInfo) -> Bool {
        guard let pid = Int(d.pid.split(separator: ":").last ?? "", radix: 16) else { return false }
        return model.connectedPIDs.contains(pid)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().overlay(Theme.border)
            Group {
                switch ui.mode {
                case .control:
                    HStack(spacing: 0) {
                        deviceList.frame(width: 250)
                        Divider().overlay(Theme.border)
                        detail.frame(maxWidth: .infinity)
                    }
                case .lab: LabView()
                case .console: ConsoleView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 820, minHeight: 600)
        .background(Theme.bg)
        .tint(Theme.green)
        .preferredColorScheme(.dark)
        .onChange(of: model.connectedProductID, initial: true) { _, productID in
            guard let productID,
                  let device = DeviceCatalog.all.first(where: {
                      Int($0.pid.split(separator: ":").last ?? "", radix: 16) == productID
                  }) else { return }
            ui.selectedDevice = device.id
            ui.section = availableSections(for: device).first ?? .sound
        }
    }

    // MARK: Top brand bar

    private var topBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill").foregroundStyle(Theme.green)
                Text("iRAZER").font(.system(size: 15, weight: .heavy)).tracking(2).foregroundStyle(Theme.text)
            }
            Spacer()
            ForEach(Mode.allCases, id: \.self) { m in
                ModeTab(title: m.rawValue, active: ui.mode == m) { ui.mode = m }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
        .background(Theme.sidebar)
    }

    // MARK: Device list (grouped by category, all Razer gear)

    private var deviceList: some View {
        ScrollView {
            // Lazy so only visible rows of the ~190-device catalog are built.
            LazyVStack(alignment: .leading, spacing: 14, pinnedViews: []) {
                let detectedCount = model.connectedPIDs.count
                HStack {
                    SectionLabel(text: "Devices")
                    Spacer()
                    Text("\(detectedCount) detected · \(DeviceCatalog.all.count) known")
                        .font(.system(size: 10)).foregroundStyle(Theme.text3)
                }
                .padding(.horizontal, 14).padding(.top, 12)

                ForEach(DeviceCategory.allCases) { cat in
                    let items = DeviceCatalog.byCategory(cat)
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon).font(.system(size: 9)).foregroundStyle(Theme.text3)
                                Text("\(cat.rawValue.uppercased())  ·  \(items.count)").font(.system(size: 9, weight: .bold))
                                    .tracking(1.2).foregroundStyle(Theme.text3)
                            }
                            .padding(.horizontal, 14).padding(.top, 4)
                            ForEach(items) { d in
                                DeviceRow(device: d,
                                          detected: isDetected(d),
                                          selected: ui.selectedDevice == d.id) {
                                    ui.selectedDevice = d.id
                                    ui.section = availableSections(for: d).first ?? .sound
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .background(Theme.sidebar)
    }

    // MARK: Detail pane

    @ViewBuilder private var detail: some View {
        let d = selected
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                deviceHeader(d)
                if d.support == .supported {
                    sectionPills(availableSections(for: d))
                    Group {
                        switch ui.section {
                        case .lighting: lightingCards
                        case .sound: soundCards
                        case .power: powerCards
                        }
                    }
                    .disabled(!isConnected(d))
                } else {
                    devicePanel(d)
                }
            }
            .padding(24)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func deviceHeader(_ d: RazerDeviceInfo) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.card)
                .frame(width: 60, height: 60)
                .overlay(
                    DeviceGlyph(category: d.category,
                                color: isDetected(d) ? Theme.green : Theme.text2,
                                glow: isDetected(d))
                        .frame(width: 42, height: 42)
                )
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border, lineWidth: 1))
            VStack(alignment: .leading, spacing: 5) {
                Text(d.name).font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.text)
                HStack(spacing: 8) {
                    statusBadge(d)
                    Text(d.pid).font(.system(size: 10).monospaced()).foregroundStyle(Theme.text3)
                    if isConnected(d) {
                        Text("· SN \(model.serial) · fw v\(model.hardwareVersion)")
                            .font(.system(size: 10)).foregroundStyle(Theme.text3)
                    }
                }
            }
            Spacer()
        }
    }

    private func badgeInfo(_ d: RazerDeviceInfo) -> (String, Color) {
        if isConnected(d) { return ("CONNECTED", Theme.green) }
        if d.support == .supported { return ("NOT CONNECTED", .orange) }
        if d.support == .experimental {
            return isDetected(d) ? ("DETECTED · EXPERIMENTAL", .yellow)
                                 : ("EXPERIMENTAL · UNTESTED", Theme.text3)
        }
        return ("SUPPORT PLANNED", Theme.text3)
    }

    private func statusBadge(_ d: RazerDeviceInfo) -> some View {
        let (txt, col) = badgeInfo(d)
        return HStack(spacing: 5) {
            Circle().fill(col).frame(width: 7, height: 7)
            Text(txt).font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(col)
        }
    }

    private func availableSections(for device: RazerDeviceInfo) -> [ControlSection] {
        var sections: [ControlSection] = []
        if device.capabilities.contains("Brightness") { sections.append(.lighting) }
        if device.capabilities.contains("Volume") || device.capabilities.contains("EQ") {
            sections.append(.sound)
        }
        if device.capabilities.contains("Keep-awake") { sections.append(.power) }
        return sections
    }

    private func sectionPills(_ sections: [ControlSection]) -> some View {
        HStack(spacing: 8) {
            ForEach(sections) { s in
                Button { ui.section = s } label: {
                    HStack(spacing: 6) {
                        Image(systemName: s.icon).font(.system(size: 11))
                        Text(s.rawValue).font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(ui.section == s ? .black : Theme.text2)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(ui.section == s ? Theme.green : Theme.card)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(ui.section == s ? .clear : Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder private func devicePanel(_ d: RazerDeviceInfo) -> some View {
        let experimental = d.support == .experimental
        Card {
            HStack(spacing: 8) {
                Image(systemName: experimental ? "testtube.2" : "hammer.fill").foregroundStyle(experimental ? .yellow : Theme.green)
                Text(experimental ? "Experimental support" : "Support planned")
                    .font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.text)
            }
            if experimental {
                Text(isDetected(d)
                     ? "Your \(d.name) is plugged in. iRazer knows this device's protocol, but it hasn't been tested on macOS yet — trying the controls could work, do nothing, or behave oddly. If you try it, please report what happens so we can mark it verified."
                     : "iRazer knows the \(d.name)'s protocol from the Razer/OpenRazer database, but it's untested on macOS. Plug it in and help verify it.")
                    .font(.system(size: 12)).foregroundStyle(Theme.text2).fixedSize(horizontal: false, vertical: true)
            } else {
                Text("iRazer doesn't control the \(d.name) yet. The fastest way to add it is a USB/Bluetooth capture from someone who owns one.")
                    .font(.system(size: 12)).foregroundStyle(Theme.text2).fixedSize(horizontal: false, vertical: true)
            }
            SectionLabel(text: experimental ? "Expected controls (unverified)" : "Expected controls")
            FlowChips(items: d.capabilities)
            HStack(spacing: 10) {
                Link(destination: URL(string: experimental
                        ? "https://github.com/hanley-tech/iRazer/issues/new?template=device_test_report.yml&title=\(d.pid)%20\(d.name)"
                        : "https://github.com/hanley-tech/iRazer/blob/main/docs/ADDING_DEVICES.md")!) {
                    Text(experimental ? "Report a test result" : "Help add this device")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Theme.green).clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Link("How to help test", destination: URL(string: "https://github.com/hanley-tech/iRazer/blob/main/docs/TESTING.md")!)
                    .font(.system(size: 11)).foregroundStyle(Theme.text3)
            }
        }
    }

    // MARK: Nommo V2 sections

    private var lightingCards: some View {
        Group {
            Card {
                Row(label: "Brightness") {
                    HStack(spacing: 10) {
                        Slider(value: $model.brightness, in: 0...100) { e in if !e { model.applyBrightness() } }
                            .frame(width: 220)
                        Text("\(Int(model.brightness))%").font(.system(size: 12, weight: .semibold).monospacedDigit())
                            .foregroundStyle(Theme.green).frame(width: 42, alignment: .trailing)
                    }
                }
            }
            .disabled(!model.connected)

            Card {
                Row(label: "Effect") {
                    Picker("", selection: $model.effect) {
                        Text("Off").tag(NommoDevice.Effect.off)
                        Text("Static").tag(NommoDevice.Effect.static)
                        Text("Breathing").tag(NommoDevice.Effect.breathing)
                        Text("Spectrum Cycle").tag(NommoDevice.Effect.spectrum)
                        Text("Wave").tag(NommoDevice.Effect.wave)
                    }.labelsHidden().frame(width: 170)
                }
                Divider().overlay(Theme.border)
                Row(label: "Color") {
                    ColorPicker("", selection: $model.color, supportsOpacity: false).labelsHidden()
                }
                HStack(spacing: 7) {
                    Image(systemName: "wave.3.right").font(.system(size: 10)).foregroundStyle(Theme.green)
                    Text("Color & effects run over Bluetooth (in progress). Brightness works over USB today.")
                        .font(.system(size: 11)).foregroundStyle(Theme.text3)
                }
            }
            .disabled(true).opacity(0.6)
        }
    }

    private var soundCards: some View {
        Group {
            Card {
                Row(label: "Master volume") {
                    HStack(spacing: 10) {
                        Slider(value: $model.volume, in: 0...100) { e in if !e { model.applyVolume() } }
                            .frame(width: 220)
                        Text("\(Int(model.volume))").font(.system(size: 12, weight: .semibold).monospacedDigit())
                            .foregroundStyle(Theme.green).frame(width: 42, alignment: .trailing)
                    }
                }
            }.disabled(!model.connected)

            Card {
                EQPresetBar(model: model)
            }.disabled(!model.connected)

            Card {
                Row(label: "EQ preset") {
                    Picker("", selection: $model.eqPreset) {
                        Text("Default").tag(0); Text("Preset 1").tag(1)
                        Text("Game / THX").tag(2); Text("Preset 3").tag(3)
                    }.labelsHidden().frame(width: 170)
                    .onChange(of: model.eqPreset) { _ in model.applyEQPreset() }
                }
                Divider().overlay(Theme.border)
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<10, id: \.self) { i in
                        VStack(spacing: 6) {
                            Text("\(Int(model.eqGains[i]) > 0 ? "+" : "")\(Int(model.eqGains[i]))")
                                .font(.system(size: 9, weight: .semibold).monospacedDigit())
                                .foregroundStyle(model.eqGains[i] == 0 ? Theme.text3 : Theme.green)
                            Slider(value: $model.eqGains[i], in: -12...12, step: 1) { e in if !e { model.applyEQ() } }
                                .frame(width: 120).rotationEffect(.degrees(-90)).frame(width: 26, height: 120)
                            Text(NommoViewModel.bandLabels[i]).font(.system(size: 9)).foregroundStyle(Theme.text3)
                        }.frame(maxWidth: .infinity)
                    }
                }
                HStack {
                    Button("Flatten") { model.flattenEQ() }.buttonStyle(RazerButton())
                    Spacer()
                    Text("±12 dB · 31 Hz – 16 kHz").font(.system(size: 10)).foregroundStyle(Theme.text3)
                }
            }.disabled(!model.connected)
        }
    }

    private var powerCards: some View {
        Card {
            Row(label: "Keep speakers awake",
                sub: "Stop the Nommo V2 from auto-sleeping / powering off.") {
                Picker("", selection: $model.keepAwakeMode) {
                    ForEach(KeepAwakeMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden().pickerStyle(.segmented).frame(width: 200)
            }
            HStack(spacing: 7) {
                Image(systemName: "moon.zzz.fill").font(.system(size: 10)).foregroundStyle(Theme.green)
                Text(model.keepAwakeMode.detail).font(.system(size: 11)).foregroundStyle(Theme.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if model.supports("Brightness") {
                Row(label: "Lights out with the display",
                    sub: "Dim the LEDs the moment your display sleeps, instead of waiting out the speakers' own standby timer.") {
                    Toggle("", isOn: $model.dimOnDisplaySleep).labelsHidden().toggleStyle(.switch)
                }
                .disabled(model.keepAwakeMode == .always)
            }
        }.disabled(!model.connected)
    }
}

/// A device row in the left list.
struct DeviceRow: View {
    let device: RazerDeviceInfo
    let detected: Bool
    let selected: Bool
    let action: () -> Void
    private var dotColor: Color {
        if detected { return device.support == .supported ? Theme.green : .yellow }
        return device.support == .supported ? .orange : Theme.text3.opacity(0.5)
    }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Rectangle().fill(selected ? Theme.green : .clear).frame(width: 3)
                Circle().fill(dotColor).frame(width: 7, height: 7)
                Text(device.name)
                    .font(.system(size: 12, weight: selected ? .semibold : .regular))
                    .foregroundStyle(detected || device.support == .supported || selected ? Theme.text : Theme.text2)
                    .lineLimit(1)
                Spacer(minLength: 4)
            }
            .padding(.vertical, 7).padding(.trailing, 10)
            .background(selected ? Theme.cardHi : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Simple wrapping chip row for capability tags.
struct FlowChips: View {
    let items: [String]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.self) { t in
                Text(t).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text2)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.cardHi).clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
            }
        }
    }
}

struct RazerButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(configuration.isPressed ? Theme.green.opacity(0.3) : Theme.cardHi)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
