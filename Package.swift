// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "iRazer",
    platforms: [.macOS(.v14)],
    targets: [
        // Core library: HID/BLE transport + Razer protocol + device abstractions.
        .target(name: "RazerKit", path: "Sources/RazerKit"),

        // Menu-bar / windowed app.
        .executableTarget(
            name: "iRazer",
            dependencies: ["RazerKit"],
            path: "Sources/iRazer"
        ),

        // Command-line tools (USB HID + BLE control and reverse-engineering).
        .executableTarget(name: "nommoctl", dependencies: ["RazerKit"], path: "Sources/nommoctl"),
        .executableTarget(name: "nommoble", dependencies: ["RazerKit"], path: "Sources/nommoble"),
        .executableTarget(name: "nommofuzz", dependencies: ["RazerKit"], path: "Sources/nommofuzz"),
        .executableTarget(name: "nommoblefuzz", path: "Sources/nommoblefuzz"),
    ]
)
