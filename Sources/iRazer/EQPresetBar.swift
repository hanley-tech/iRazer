import SwiftUI

/// Saved EQ presets: one-click chips, save-current, and the global shortcut
/// toggle. The same presets appear in the menu-bar popover and on ⌥⌘E, so this
/// card is really just where you *curate* them — switching happens elsewhere.
struct EQPresetBar: View {
    @ObservedObject var model: NommoViewModel
    // The toolchain's SwiftUI macro plugin isn't available in this SwiftPM
    // build, so transient UI state lives on the view model rather than @State.

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick presets").font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.text)
                Spacer()
                Text("⌥⌘E next · ⇧⌥⌘E previous")
                    .font(.system(size: 10).monospaced()).foregroundStyle(Theme.text3)
                Toggle("", isOn: $model.hotKeysEnabled).labelsHidden().toggleStyle(.switch)
                    .scaleEffect(0.8).frame(width: 38)
            }

            FlowRow(spacing: 8) {
                ForEach(model.presets) { preset in
                    let active = preset.matches(model.eqGains)
                    Button { model.apply(preset) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: preset.symbol).font(.system(size: 10))
                            Text(preset.name).font(.system(size: 12, weight: active ? .semibold : .regular))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .foregroundStyle(active ? Theme.green : Theme.text)
                        .background(active ? Theme.greenDim : Theme.cardHi)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(active ? Theme.borderHi : Theme.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Overwrite with current sliders") {
                            model.saveCurrentAsPreset(named: preset.name)
                        }
                        Button("Delete", role: .destructive) { model.deletePreset(preset) }
                    }
                }
            }

            HStack(spacing: 8) {
                if model.namingPreset {
                    TextField("Preset name", text: $model.newPresetName)
                        .textFieldStyle(.roundedBorder).frame(width: 160)
                        .onSubmit { commit() }
                    Button("Save") { commit() }.buttonStyle(RazerButton())
                    Button("Cancel") { model.namingPreset = false; model.newPresetName = "" }.buttonStyle(RazerButton())
                } else {
                    Button("Save current as preset…") { model.namingPreset = true }.buttonStyle(RazerButton())
                    Spacer()
                    Button("Restore defaults") { model.resetPresetsToBuiltins() }.buttonStyle(RazerButton())
                }
            }
        }
    }

    private func commit() {
        model.saveCurrentAsPreset(named: model.newPresetName)
        model.newPresetName = ""
        model.namingPreset = false
    }
}

/// Minimal wrapping HStack — the preset chips need to wrap once you add a few.
struct FlowRow<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: Content

    var body: some View {
        Layout(spacing: spacing) { content }
    }

    private struct Layout: SwiftUI.Layout {
        var spacing: CGFloat
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let width = proposal.width ?? .infinity
            var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
            for v in subviews {
                let s = v.sizeThatFits(.unspecified)
                if x + s.width > width, x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
                x += s.width + spacing
                rowHeight = max(rowHeight, s.height)
            }
            return CGSize(width: proposal.width ?? x, height: y + rowHeight)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
            for v in subviews {
                let s = v.sizeThatFits(.unspecified)
                if x + s.width > bounds.maxX, x > bounds.minX {
                    x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
                }
                v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
                x += s.width + spacing
                rowHeight = max(rowHeight, s.height)
            }
        }
    }
}
