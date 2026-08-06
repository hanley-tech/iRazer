import SwiftUI

/// Compact controls shown from the menu-bar item — quick access without opening
/// the full window.
struct MenuBarView: View {
    @ObservedObject var model: NommoViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Circle().fill(model.connected ? Theme.green : .red).frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Razer Nommo V2").font(.system(size: 13, weight: .bold))
                    Text(model.connected ? "Connected" : "Not connected")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }

            if model.connected {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Brightness").font(.system(size: 11)).foregroundStyle(.secondary)
                    Slider(value: $model.brightness, in: 0...100) { e in if !e { model.applyBrightness() } }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume").font(.system(size: 11)).foregroundStyle(.secondary)
                    Slider(value: $model.volume, in: 0...100) { e in if !e { model.applyVolume() } }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keep awake").font(.system(size: 11)).foregroundStyle(.secondary)
                    Picker("", selection: $model.keepAwakeMode) {
                        ForEach(KeepAwakeMode.allCases) { Text($0.rawValue).tag($0) }
                    }.labelsHidden().pickerStyle(.segmented)
                }
            }

            Divider()
            Button {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Open iRazer…", systemImage: "macwindow")
            }
            Button(role: .destructive) { NSApp.terminate(nil) } label: {
                Label("Quit iRazer", systemImage: "power")
            }
        }
        .padding(14)
        .frame(width: 260)
        .tint(Theme.green)
    }
}
