import AppKit
import SwiftUI

/// Brief centred overlay shown when a preset is switched from the hot key, so
/// you get the same feedback as the system volume HUD without opening the app.
@MainActor
final class PresetHUD {
    static let shared = PresetHUD()

    private var panel: NSPanel?
    private var hideWork: DispatchWorkItem?

    func show(name: String, symbol: String) {
        hideWork?.cancel()

        let view = NSHostingView(rootView: HUDContent(name: name, symbol: symbol))
        view.frame = NSRect(x: 0, y: 0, width: 200, height: 200)

        let panel = self.panel ?? makePanel()
        self.panel = panel
        panel.contentView = view

        if let screen = NSScreen.main {
            let f = screen.frame
            panel.setFrame(NSRect(x: f.midX - 100, y: f.minY + f.height * 0.15,
                                  width: 200, height: 200), display: false)
        }
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        let work = DispatchWorkItem { [weak self] in self?.fadeOut() }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1, execute: work)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.appearance = NSAppearance(named: .vibrantDark)   // system-HUD look
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        return panel
    }

    private func fadeOut() {
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            panel.animator().alphaValue = 0
        } completionHandler: { panel.orderOut(nil) }
    }
}

private struct HUDContent: View {
    let name: String
    let symbol: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 54, weight: .regular))
                .foregroundStyle(Theme.green)
            Text(name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 12)
        }
        .frame(width: 200, height: 200)
        .background(Theme.card.opacity(0.94))   // opaque enough to read on any wallpaper
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        .preferredColorScheme(.dark)
    }
}
