// KeyRemap Lite: GUI over macOS's built-in `hidutil` key remapping.
// No driver, no daemon. Mappings persist via a LaunchAgent that reruns hidutil at login.
import SwiftUI
import ServiceManagement

struct Key: Hashable { let name: String; let code: Int }

let keys: [Key] = {
    var k: [Key] = []
    func add(_ name: String, _ usage: Int) { k.append(Key(name: name, code: 0x7_0000_0000 | usage)) }
    add("Escape", 0x29); add("Caps Lock", 0x39); add("Tab", 0x2B); add("Return", 0x28)
    add("Delete (Backspace)", 0x2A); add("Forward Delete", 0x4C); add("Space", 0x2C)
    add("Left Control", 0xE0); add("Left Shift", 0xE1); add("Left Option", 0xE2); add("Left Command", 0xE3)
    add("Right Control", 0xE4); add("Right Shift", 0xE5); add("Right Option", 0xE6); add("Right Command", 0xE7)
    add("Up", 0x52); add("Down", 0x51); add("Left", 0x50); add("Right", 0x4F)
    add("Home", 0x4A); add("End", 0x4D); add("Page Up", 0x4B); add("Page Down", 0x4E)
    for i in 0..<12 { add("F\(i + 1)", 0x3A + i) }
    for (i, c) in "ABCDEFGHIJKLMNOPQRSTUVWXYZ".enumerated() { add(String(c), 0x04 + i) }
    for (i, c) in "1234567890".enumerated() { add(String(c), 0x1E + i) }
    for (n, u) in [("-", 0x2D), ("=", 0x2E), ("[", 0x2F), ("]", 0x30), ("\\", 0x31), (";", 0x33),
                   ("'", 0x34), ("`", 0x35), (",", 0x36), (".", 0x37), ("/", 0x38), ("§ (Non-US)", 0x64)] { add(n, u) }
    k.append(Key(name: "fn", code: 0xFF_0000_0003))
    return k
}()

struct Mapping: Identifiable { let id = UUID(); var from: Int; var to: Int }

let label = "local.keyremap-lite"
let agentURL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/LaunchAgents/\(label).plist")

func hidutilJSON(_ maps: [Mapping]) -> String {
    let items = maps.map { "{\"HIDKeyboardModifierMappingSrc\":\($0.from),\"HIDKeyboardModifierMappingDst\":\($0.to)}" }
    return "{\"UserKeyMapping\":[\(items.joined(separator: ","))]}"
}

/// Applies now and persists for next login. Returns an error message or nil.
func apply(_ maps: [Mapping]) -> String? {
    let args = ["property", "--set", hidutilJSON(maps)]
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
    p.arguments = args
    p.standardOutput = FileHandle.nullDevice
    do { try p.run(); p.waitUntilExit() } catch { return "hidutil failed: \(error.localizedDescription)" }
    if p.terminationStatus != 0 { return "hidutil exit \(p.terminationStatus)" }

    UserDefaults.standard.set(maps.map { [$0.from, $0.to] }, forKey: "maps")
    if maps.isEmpty { try? FileManager.default.removeItem(at: agentURL); return nil }
    try? FileManager.default.createDirectory(at: agentURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    let plist: NSDictionary = ["Label": label, "ProgramArguments": ["/usr/bin/hidutil"] + args, "RunAtLoad": true]
    return plist.write(to: agentURL, atomically: true) ? nil : "Failed to Write \(agentURL.path)"
}

func loadSaved() -> [Mapping] {
    ((UserDefaults.standard.array(forKey: "maps") as? [[Int]]) ?? []).map { Mapping(from: $0[0], to: $0[1]) }
}

func keyName(_ code: Int) -> String { keys.first { $0.code == code }?.name ?? String(code, radix: 16) }

// ponytail: ObservableObject instead of @State because @State is a macro whose plugin ships only with Xcode, not the Command Line Tools.
final class Model: ObservableObject {
    @Published var maps = loadSaved()     // being edited in the window
    @Published var applied = loadSaved()  // what hidutil currently has (as last applied by this app)
    @Published var status = ""

    func save(_ new: [Mapping], ok: String) {
        if let err = apply(new) { status = err; return }
        maps = new; applied = new; status = ok
    }
}

struct ContentView: View {
    @ObservedObject var model: Model

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach($model.maps) { $m in
                HStack {
                    picker($m.from); Text("→"); picker($m.to)
                    Button { model.maps.removeAll { $0.id == m.id } } label: { Image(systemName: "minus.circle") }
                        .buttonStyle(.borderless)
                }
            }
            HStack {
                Button("+ Add") { model.maps.append(Mapping(from: keys[1].code, to: keys[0].code)) }
                Spacer()
                Button("Reset") { model.save([], ok: "All remap deleted") }
                Button("Apply") { model.save(model.maps, ok: "Active") }
                    .keyboardShortcut(.defaultAction)
            }
            Text(model.status).font(.caption).foregroundStyle(.secondary)
        }
        .padding().frame(minWidth: 420)
    }

    func picker(_ sel: Binding<Int>) -> some View {
        Picker("", selection: sel) { ForEach(keys, id: \.code) { Text($0.name).tag($0.code) } }
            .labelsHidden().frame(width: 170)
    }
}

struct MenuContent: View {
    @ObservedObject var model: Model
    @Environment(\.openWindow) var openWindow

    var body: some View {
        Text(model.applied.isEmpty ? "Remap: Nonactive" : "Remap: Active (\(model.applied.count))")
        ForEach(model.applied) { Text("\(keyName($0.from)) → \(keyName($0.to))") }
        Divider()
        Button("Edit Remap…") { NSApp.activate(); openWindow(id: "main") }
        Button("Quit KeyRemap Lite") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}

@main struct KeyRemapLite: App {
    @StateObject var model = Model()

    init() {
        // Single instance: if another copy is already running, quit this one.
        let me = NSRunningApplication.current
        if NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
            .contains(where: { $0.processIdentifier != me.processIdentifier }) { exit(0) }
        try? SMAppService.mainApp.register()  // show the menu bar icon after login
    }

    var body: some Scene {
        MenuBarExtra { MenuContent(model: model) } label: {
            Image(systemName: model.applied.isEmpty ? "keyboard" : "keyboard.fill")
        }
        Window("KeyRemap Lite", id: "main") { ContentView(model: model) }
            .windowResizability(.contentSize)
            .defaultLaunchBehavior(.suppressed)
    }
}
