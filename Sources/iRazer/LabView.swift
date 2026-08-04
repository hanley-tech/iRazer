import SwiftUI
@preconcurrency import RazerKit

// Protocol Lab: walks through experiment batches defined in lab/experiments.json,
// sends each experiment's packets to the device, and appends packets + device
// responses + the user's visual verdict to lab/results.jsonl for offline analysis.

struct LabPacket: Codable {
    var tx: String          // transaction id, hex ("1f")
    var bytes: String       // "class id dataSize arg0 arg1 …" hex bytes
}

struct LabExperiment: Codable, Identifiable {
    var id: String
    var title: String
    var detail: String?
    var packets: [LabPacket]
}

@MainActor
final class LabRunner: ObservableObject {
    @Published var experiments: [LabExperiment] = []
    @Published var index = 0
    @Published var sent = false
    @Published var lastResponses: [String] = []
    @Published var note = ""
    @Published var status = ""
    @Published var completed = 0

    private let queue = DispatchQueue(label: "nommo.lab")
    static let labDir = NSHomeDirectory() + "/Git/htai/iRazer/lab"

    var current: LabExperiment? {
        experiments.indices.contains(index) ? experiments[index] : nil
    }

    func load() {
        let url = URL(fileURLWithPath: Self.labDir + "/experiments.json")
        do {
            let data = try Data(contentsOf: url)
            experiments = try JSONDecoder().decode([LabExperiment].self, from: data)
            status = "Loaded \(experiments.count) experiments."
            index = 0
            sent = false
        } catch {
            status = "Couldn't load experiments.json: \(error.localizedDescription)"
        }
    }

    func send() {
        guard let exp = current else { return }
        sent = false
        lastResponses = []
        status = "Sending \(exp.packets.count) packet(s)…"
        queue.async {
            var responses: [String] = []
            guard let dev = NommoDevice.find() else {
                Task { @MainActor in self.status = "Device not found" }
                return
            }
            do {
                try dev.open()
                defer { dev.close() }
                for p in exp.packets {
                    let bytes = p.bytes.split(separator: " ").compactMap { UInt8($0, radix: 16) }
                    guard bytes.count >= 3 else { responses.append("bad-packet"); continue }
                    let report = RazerReport.command(class: bytes[0], id: bytes[1], dataSize: bytes[2],
                                                     args: Array(bytes.dropFirst(3)),
                                                     transactionID: UInt8(p.tx, radix: 16) ?? 0x1F)
                    do {
                        let resp = try dev.request(report)
                        let argHex = resp.args.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " ")
                        responses.append("status=\(String(format: "%02x", resp.status)) args=\(argHex)")
                    } catch {
                        responses.append("error: \(error)")
                    }
                }
            } catch {
                responses.append("open failed: \(error)")
            }
            Task { @MainActor in
                self.lastResponses = responses
                self.sent = true
                self.status = "Sent. Look at the speakers, then record what you see."
            }
        }
    }

    func record(_ verdict: String) {
        guard let exp = current else { return }
        var entry: [String: Any] = [
            "ts": ISO8601DateFormatter().string(from: Date()),
            "id": exp.id,
            "title": exp.title,
            "packets": exp.packets.map { "tx=\($0.tx) \($0.bytes)" },
            "responses": lastResponses,
            "verdict": verdict,
        ]
        if !note.isEmpty { entry["note"] = note }
        if let data = try? JSONSerialization.data(withJSONObject: entry),
           let line = String(data: data, encoding: .utf8) {
            let url = URL(fileURLWithPath: Self.labDir + "/results.jsonl")
            let handle: FileHandle
            if !FileManager.default.fileExists(atPath: url.path) {
                FileManager.default.createFile(atPath: url.path, contents: nil)
            }
            handle = (try? FileHandle(forWritingTo: url)) ?? FileHandle.nullDevice
            handle.seekToEndOfFile()
            handle.write((line + "\n").data(using: .utf8)!)
            try? handle.close()
        }
        completed += 1
        note = ""
        next()
    }

    func next() {
        if index < experiments.count - 1 {
            index += 1
            sent = false
            lastResponses = []
            send()   // auto-send the next experiment so it's one click per verdict
        } else {
            status = "Batch complete — all \(experiments.count) recorded. Tell Claude to analyze lab/results.jsonl."
        }
    }

    func back() {
        if index > 0 { index -= 1; sent = false; lastResponses = [] }
    }
}

struct LabView: View {
    @StateObject private var lab = LabRunner()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("Reload experiments") { lab.load() }
                Spacer()
                Text("\(lab.completed) recorded")
                    .foregroundStyle(.secondary)
            }

            if let exp = lab.current {
                GroupBox {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(lab.index + 1) / \(lab.experiments.count):  \(exp.title)")
                            .font(.headline)
                        if let d = exp.detail {
                            Text(d).font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(exp.packets.indices, id: \.self) { i in
                            Text("tx=\(exp.packets[i].tx)  \(exp.packets[i].bytes)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !lab.sent {
                    Button("Send to device") { lab.send() }
                        .keyboardShortcut(.return, modifiers: [])
                        .buttonStyle(.borderedProminent)
                } else {
                    Text("What do the speakers show?").font(.headline)
                    HStack {
                        Button("No change") { lab.record("no-change") }
                            .keyboardShortcut("1", modifiers: [])
                        Button("Changed!") { lab.record("changed") }
                            .keyboardShortcut("2", modifiers: [])
                            .buttonStyle(.borderedProminent)
                        Button("Lights off") { lab.record("off") }
                            .keyboardShortcut("3", modifiers: [])
                        Button("Skip") { lab.next() }
                    }
                    TextField("Optional note (what color/effect you see)", text: $lab.note)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Button("◀ Back") { lab.back() }
                    Spacer()
                }
            } else {
                Text("No experiments loaded.")
                    .foregroundStyle(.secondary)
            }

            Text(lab.status)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !lab.lastResponses.isEmpty {
                GroupBox("Device responses") {
                    VStack(alignment: .leading) {
                        ForEach(lab.lastResponses.indices, id: \.self) { i in
                            Text(lab.lastResponses[i])
                                .font(.system(size: 10, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer()
        }
        .padding()
        .onAppear { lab.load() }
    }
}
