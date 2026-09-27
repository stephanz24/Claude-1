import Foundation
import Observation

/// Hält alle Tages-Einträge, speichert sie als JSON im App-Speicher
/// und rechnet den Booster aus.
@Observable
final class Store {
    private(set) var entries: [String: DayEntry] = [:]

    /// Wird beim Zurückkehren in die App aufgefrischt, damit Ansichten
    /// nach Mitternacht den neuen Tag zeigen.
    private(set) var todayKey: String = DayKey.today

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("rueckenfit.json")
        load()
    }

    func refreshToday() { todayKey = DayKey.today }

    // MARK: - Lesen und Ändern

    func entry(_ key: String) -> DayEntry { entries[key] ?? DayEntry() }

    func update(_ key: String, _ change: (inout DayEntry) -> Void) {
        var e = entry(key)
        change(&e)
        if e.isEmpty { entries.removeValue(forKey: key) } else { entries[key] = e }
        save()
    }

    func toggleExercise(_ id: String, on key: String) {
        update(key) { e in
            if let i = e.done.firstIndex(of: id) { e.done.remove(at: i) } else { e.done.append(id) }
        }
    }

    func toggleFactor(_ id: String, on key: String) {
        update(key) { e in
            if let i = e.factors.firstIndex(of: id) { e.factors.remove(at: i) } else { e.factors.append(id) }
        }
    }

    /// Nochmaliges Antippen desselben Werts löscht ihn wieder
    func setFeel(_ value: Int, on key: String) {
        update(key) { e in e.feel = (e.feel == value) ? nil : value }
    }

    // MARK: - Speichern

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        entries = (try? JSONDecoder().decode([String: DayEntry].self, from: data)) ?? [:]
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Booster

    static let gain = 1.0
    static let lossMax = 1.0
    static let powerMax = 10.0

    /// Tages-Bilanz: Soll erfüllt (oder Pilates) = +1. Darunter geht es
    /// abwärts – je weniger Übungen, desto stärker; ganz ohne Training −1.
    func dayDelta(_ key: String) -> Double {
        guard let e = entries[key] else { return -Store.lossMax }
        if e.done.contains("pilates") { return Store.gain }
        let n = e.requiredDone
        if n >= Catalog.goodMin { return Store.gain }
        return -Store.lossMax * (1 - Double(n) / Double(Catalog.goodMin))
    }

    func isGoodDay(_ key: String) -> Bool { dayDelta(key) >= Store.gain }

    struct Booster {
        var power: Double
        var streak: Int
        var fraction: Double { power / Store.powerMax }
    }

    func booster() -> Booster {
        let keys = entries.filter { !$0.value.isEmpty }.keys.sorted()
        let today = todayKey
        var power = 0.0
        var streak = 0
        if let first = keys.first, var cursor = DayKey.date(first) {
            // Alle Tage vom ersten Eintrag bis gestern (Lücken = kein Training)
            while DayKey.key(cursor) < today {
                let k = DayKey.key(cursor)
                power = max(0, min(Store.powerMax, power + dayDelta(k)))
                if isGoodDay(k) { streak += 1 } else { streak = 0 }
                cursor = DayKey.shift(cursor, days: 1)
            }
        }
        // Heute zählt nur positiv, sobald das Soll erreicht ist
        if isGoodDay(today) {
            power = min(Store.powerMax, power + Store.gain)
            streak += 1
        }
        return Booster(power: (power * 10).rounded() / 10, streak: streak)
    }

    // MARK: - Import / Export (kompatibel zur Web-App)

    func exportJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        guard let data = try? encoder.encode(entries) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    enum ImportError: LocalizedError {
        case invalid
        var errorDescription: String? { "Das ist kein gültiger RückenFit-Export. Bitte den kompletten Text aus der Web-App einfügen." }
    }

    /// Übernimmt Tage aus einem Export; vorhandene Tage werden durch die
    /// importierten ersetzt. Gibt die Zahl der übernommenen Tage zurück.
    @discardableResult
    func importJSON(_ text: String) throws -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8),
              let parsed = try? JSONDecoder().decode([String: DayEntry].self, from: data) else {
            throw ImportError.invalid
        }
        var count = 0
        for (key, value) in parsed where !value.isEmpty && DayKey.date(key) != nil {
            entries[key] = value
            count += 1
        }
        save()
        return count
    }

    func eraseAll() {
        entries = [:]
        save()
    }
}
