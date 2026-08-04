import SwiftUI
@preconcurrency import RazerKit

// Manual protocol console: free-form packet composition on any channel,
// live input-report monitoring, and timed sweeps with a MARK button.
// Every send and every incoming report is appended to lab/console.jsonl.

enum Channel: String, CaseIterable, Identifiable {
    case razerFeature7 = "Razer → Feature 7"
    case razerOutput3 = "Razer → Output 3"
    case rawFeature7 = "Raw bytes → Feature 7"
    case rawOutput3 = "Raw bytes → Output 3"
    var id: String { rawValue }
}

struct ConsoleEntry: Identifiable {
    let id = UUID()
    let ts: Date
    let direction: String   // "send" | "resp" | "input" | "mark" | "note"
    let text: String
}

@MainActor
final class ConsoleModel: ObservableObject {
    @Published var channel: Channel = .razerFeature7
    @Published var tx = "1f"
    @Published var bytes = "0f 04 03 01 00 ff"
    @Published var readBack = true
    @Published var log: [ConsoleEntry] = []
    @Published var listening = false

    // Sweep
    @Published var sweepTemplate = "03 0a 01 XX"
    @Published var sweepFrom = "00"
    @Published var sweepTo = "0f"
    @Published var sweepIntervalMs = 1500.0
    @Published var sweeping = false
    @Published var sweepCurrent = ""

    private var device: NommoDevice?
    private let queue = DispatchQueue(label: "nommo.console")
    private var sweepTask: Task<Void, Never>?
    private let logURL = URL(fileURLWithPath: LabRunner.labDir + "/console.jsonl")

    private func dev() -> NommoDevice? {
        if let d = device { return d }
        guard let d = NommoDevice.find() else { append("note", "device not found"); return nil }
        do { try d.open() } catch { append("note", "open failed: \(error)"); return nil }
        device = d
        return d
    }

    func append(_ direction: String, _ text: String) {
        let e = ConsoleEntry(ts: Date(), direction: direction, text: text)
        log.append(e)
        if log.count > 400 { log.removeFirst(100) }
        let obj: [String: Any] = ["ts": ISO8601DateFormatter().string(from: e.ts),
                                  "dir": direction, "text": text]
        if let data = try? JSONSerialization.data(withJSONObject: obj),
           let line = String(data: data, encoding: .utf8) {
            if !FileManager.default.fileExists(atPath: logURL.path) {
                FileManager.default.createFile(atPath: logURL.path, contents: nil)
            }
            if let h = try? FileHandle(forWritingTo: logURL) {
                h.seekToEndOfFile()
                h.write((line + "\n").data(using: .utf8)!)
                try? h.close()
            }
        }
    }

    func startListening() {
        guard !listening, let d = dev() else { return }
        listening = true
        d.hid.listenForInputReports { [weak self] reportID, bytes in
            let hex = bytes.map { String(format: "%02x", $0) }.joined(separator: " ")
            Task { @MainActor in
                self?.append("input", "report \(reportID): \(hex)")
            }
        }
        append("note", "listening for input reports")
    }

    func parseBytes(_ s: String) -> [UInt8] {
        s.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { UInt8($0, radix: 16) }
    }

    func send(bytesOverride: String? = nil) {
        let byteStr = bytesOverride ?? bytes
        let parsed = parseBytes(byteStr)
        guard !parsed.isEmpty else { append("note", "no valid hex bytes"); return }
        let ch = channel
        let txID = UInt8(tx, radix: 16) ?? 0x1F
        let wantRead = readBack
        guard let d = dev() else { return }
        append("send", "[\(ch.rawValue)] tx=\(String(format: "%02x", txID)) \(byteStr)")
        queue.async {
            do {
                switch ch {
                case .razerFeature7, .razerOutput3:
                    guard parsed.count >= 3 else {
                        Task { @MainActor in self.append("note", "razer channels need: cls cmd size args…") }
                        return
                    }
                    let report = RazerReport.command(class: parsed[0], id: parsed[1], dataSize: parsed[2],
                                                     args: Array(parsed.dropFirst(3)), transactionID: txID)
                    if ch == .razerFeature7 {
                        try d.hid.setFeatureReport(id: 7, bytes: [7] + report.serialize())
                    } else {
                        var p: [UInt8] = [3] + report.serialize()
                        while p.count < 92 { p.append(0) }
                        try d.hid.setOutputReport(id: 3, bytes: p)
                    }
                case .rawFeature7:
                    try d.hid.setFeatureReport(id: 7, bytes: parsed)
                case .rawOutput3:
                    try d.hid.setOutputReport(id: 3, bytes: parsed)
                }
                if wantRead {
                    usleep(60_000)
                    var resp = try d.hid.getFeatureReport(id: 7, length: 91)
                    if resp.first == 7 { resp = Array(resp.dropFirst()) }
                    let status = resp.first.map { String(format: "%02x", $0) } ?? "?"
                    let hex = resp.prefix(24).map { String(format: "%02x", $0) }.joined(separator: " ")
                    Task { @MainActor in self.append("resp", "status=\(status)  \(hex)…") }
                }
            } catch {
                Task { @MainActor in self.append("resp", "error: \(error)") }
            }
        }
    }

    func startSweep() {
        guard !sweeping,
              let lo = UInt8(sweepFrom, radix: 16),
              let hi = UInt8(sweepTo, radix: 16), lo <= hi,
              sweepTemplate.contains("XX") else {
            append("note", "sweep needs template containing XX and valid from/to")
            return
        }
        sweeping = true
        let interval = UInt64(sweepIntervalMs * 1_000_000)
        sweepTask = Task { @MainActor in
            for v in lo...hi {
                if Task.isCancelled { break }
                let hex = String(format: "%02x", v)
                sweepCurrent = hex
                append("send", "SWEEP value 0x\(hex)")
                send(bytesOverride: sweepTemplate.replacingOccurrences(of: "XX", with: hex))
                try? await Task.sleep(nanoseconds: interval)
            }
            sweeping = false
            append("note", "sweep finished")
        }
    }

    func stopSweep() {
        sweepTask?.cancel()
        sweeping = false
    }

    func mark() {
        append("mark", "USER MARK at sweep value 0x\(sweepCurrent)")
    }
}

struct ConsoleView: View {
    @StateObject private var model = ConsoleModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Picker("Channel", selection: $model.channel) {
                    ForEach(Channel.allCases) { Text($0.rawValue).tag($0) }
                }
                .frame(width: 260)
                TextField("tx", text: $model.tx).frame(width: 44)
                Toggle("Read back", isOn: $model.readBack)
                Button(model.listening ? "Listening ✓" : "Listen (input reports)") {
                    model.startListening()
                }
                .disabled(model.listening)
            }

            HStack {
                TextField("cls cmd size args…  (hex)", text: $model.bytes)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit { model.send() }
                Button("Send") { model.send() }.buttonStyle(.borderedProminent)
            }

            GroupBox("Sweep (XX = swept byte)") {
                HStack {
                    TextField("template with XX", text: $model.sweepTemplate)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    TextField("from", text: $model.sweepFrom).frame(width: 44)
                    TextField("to", text: $model.sweepTo).frame(width: 44)
                    TextField("ms", value: $model.sweepIntervalMs, format: .number).frame(width: 60)
                    if model.sweeping {
                        Button("Stop") { model.stopSweep() }
                        Button("MARK 0x\(model.sweepCurrent)") { model.mark() }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.space, modifiers: [])
                    } else {
                        Button("Start") { model.startSweep() }
                    }
                }
            }

            GroupBox("Log (also written to lab/console.jsonl)") {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(model.log) { e in
                                Text("\(e.ts.formatted(date: .omitted, time: .standard))  \(e.direction.uppercased().padding(toLength: 5, withPad: " ", startingAt: 0))  \(e.text)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(color(for: e.direction))
                                    .id(e.id)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: model.log.count) { _ in
                        if let last = model.log.last { proxy.scrollTo(last.id) }
                    }
                }
                .frame(minHeight: 200)
            }
        }
        .padding()
    }

    private func color(for dir: String) -> Color {
        switch dir {
        case "send": return .primary
        case "resp": return .secondary
        case "input": return .orange
        case "mark": return .green
        default: return .secondary
        }
    }
}
