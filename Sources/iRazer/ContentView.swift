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
        d.id == DeviceCatalog.nommoV2ID && model.connected
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
            VStack(alignment: .leading, spacing: 14) {
                let connectedCount = DeviceCatalog.all.filter(isConnected).count
                HStack {
                    SectionLabel(text: "Devices")
                    Spacer()
                    Text("\(connectedCount) connected")
                        .font(.system(size: 10)).foregroundStyle(Theme.text3)
                }
                .padding(.horizontal, 14).padding(.top, 12)

                ForEach(DeviceCategory.allCases) { cat in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon).font(.system(size: 9)).foregroundStyle(Theme.text3)
                            Text(cat.rawValue.uppercased()).font(.system(size: 9, weight: .bold))
                                .tracking(1.2).foregroundStyle(Theme.text3)
                        }
                        .padding(.horizontal, 14).padding(.top, 4)
                        ForEach(DeviceCatalog.byCategory(cat)) { d in
                            DeviceRow(device: d,
                                      connected: isConnected(d),
                                      selected: ui.selectedDevice == d.id) {
                                ui.selectedDevice = d.id
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
                    sectionPills
                    switch ui.section {
                    case .lighting: lightingCards
                    case .sound: soundCards
                    case .power: powerCards
                    }
                } else {
                    plannedPanel(d)
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
                                color: isConnected(d) ? Theme.green : Theme.text2,
                                glow: isConnected(d))
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

    private func statusBadge(_ d: RazerDeviceInfo) -> some View {
        let (txt, col): (String, Color) =
            isConnected(d) ? ("CONNECTED", Theme.green)
            : d.support == .supported ? ("NOT CONNECTED", .orange)
            : ("SUPPORT PLANNED", Theme.text3)
        return HStack(spacing: 5) {
            Circle().fill(col).frame(width: 7, height: 7)
            Text(txt).font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(col)
        }
    }

    private var sectionPills: some View {
        HStack(spacing: 8) {
            ForEach(ControlSection.allCases) { s in
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

    private func plannedPanel(_ d: RazerDeviceInfo) -> some View {
        Card {
            HStack(spacing: 8) {
                Image(systemName: "hammer.fill").foregroundStyle(Theme.green)
                Text("Support planned").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.text)
            }
            Text("iRazer doesn't control the \(d.name) yet. It's on the roadmap — the fastest way to add it is a USB/Bluetooth capture from someone who owns one.")
                .font(.system(size: 12)).foregroundStyle(Theme.text2).fixedSize(horizontal: false, vertical: true)
            SectionLabel(text: "Expected controls")
            FlowChips(items: d.capabilities)
            HStack(spacing: 10) {
                Link(destination: URL(string: "https://github.com/")!) {
                    Text("Contribute this device").font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Theme.green).clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Text("See docs/ADDING_DEVICES.md").font(.system(size: 11)).foregroundStyle(Theme.text3)
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
                sub: "Plays a brief inaudible pulse each minute so the speakers never sleep.") {
                Toggle("", isOn: $model.keepAwake).labelsHidden().toggleStyle(.switch)
            }
        }.disabled(!model.connected)
    }
}

/// A device row in the left list.
struct DeviceRow: View {
    let device: RazerDeviceInfo
    let connected: Bool
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Rectangle().fill(selected ? Theme.green : .clear).frame(width: 3)
                Circle()
                    .fill(connected ? Theme.green : (device.support == .supported ? Color.orange : Theme.text3.opacity(0.5)))
                    .frame(width: 7, height: 7)
                Text(device.name)
                    .font(.system(size: 12, weight: selected ? .semibold : .regular))
                    .foregroundStyle(device.support == .planned && !selected ? Theme.text3 : Theme.text)
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
