import SwiftUI

@main
struct iRazerApp: App {
    @StateObject private var model = NommoViewModel.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Main window — opened on demand from the menu bar. Closing it does NOT
        // quit the app; iRazer keeps running resident in the menu bar.
        Window("iRazer", id: "main") {
            ContentView(model: model)
                .onAppear { model.start() }
        }
        .windowResizability(.contentSize)

        // Always-available menu-bar item with quick controls.
        MenuBarExtra("iRazer", systemImage: "bolt.horizontal.fill") {
            MenuBarView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Menu-bar resident: no Dock icon, doesn't quit when the window closes.
/// Footprint stays small — the keep-awake audio engine only runs when enabled,
/// and the only background work is a lightweight 3 s connection poll.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // menu-bar utility, no Dock icon
        NommoViewModel.shared.start()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false                                    // stay resident in the menu bar
    }
}
