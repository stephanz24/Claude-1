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

    static let powerMax = 10.0
    /// So viele Tage fließen in den Booster ein
    static let boostDays = 14
    /// Indoor Cycling / Gehen geben je 30 % Bonus
    static let extraBonus = 0.3

    /// Was ein Tag zählt (0 … 1): anteilig nach Übungen, Pilates zählt voll,
    /// Extras geben einen Bonus. 8 von 10 Übungen = 80 %.
    func dayCredit(_ key: String) -> Double {
        guard let e = entries[key] else { return 0 }
        if e.done.contains("pilates") { return 1 }
        let extras = Catalog.exercises.filter { $0.isOptional && e.done.contains($0.id) }.count
        let share = Double(e.requiredDone) / Double(Catalog.goodMin)
        return min(1, share + Store.extraBonus * Double(extras))
    }

    func isGoodDay(_ key: String) -> Bool { dayCredit(key) >= 1 }

    /// Gewichteter Schnitt der letzten 14 Tage bis einschließlich `end` –
    /// jüngere Tage zählen stärker, damit der Muskel schnell reagiert.
    func powerEnding(_ end: Date) -> Double {
        var sum = 0.0
        var weights = 0.0
        for i in 0..<Store.boostDays {
            let weight = Double(Store.boostDays - i)
            sum += weight * dayCredit(DayKey.key(DayKey.shift(end, days: -i)))
            weights += weight
        }
        return Store.powerMax * sum / weights
    }

    struct Booster {
        var power: Double
        var streak: Int
        /// Was der heutige Tag gebracht hat
        var todayGain: Double
        /// Was gestern bewirkt hat (wird gezeigt, solange heute noch nichts zählt)
        var yesterdayChange: Double
        var fraction: Double { power / Store.powerMax }

        /// 0 Schlappi … 4 Booster-Modus
        var stage: Int {
            switch power {
            case ..<2: return 0
            case ..<4: return 1
            case ..<6: return 2
            case ..<8: return 3
            default: return 4
            }
        }
        var isMax: Bool { power >= Store.powerMax }
    }

    func booster() -> Booster {
        let today = DayKey.date(todayKey) ?? Date()
        let yesterday = DayKey.shift(today, days: -1)
        let dayBefore = DayKey.shift(today, days: -2)
        let round1: (Double) -> Double = { ($0 * 10).rounded() / 10 }

        let pYesterday = powerEnding(yesterday)
        // Der laufende Tag zählt nur, wenn er nach oben bringt
        let power = round1(max(pYesterday, powerEnding(today)))
        let todayGain = round1(power - pYesterday)
        let yesterdayChange = round1(pYesterday - powerEnding(dayBefore))

        var streak = isGoodDay(todayKey) ? 1 : 0
        var cursor = yesterday
        for _ in 0..<3650 {
            guard isGoodDay(DayKey.key(cursor)) else { break }
            streak += 1
            cursor = DayKey.shift(cursor, days: -1)
        }
        return Booster(power: power, streak: streak, todayGain: todayGain, yesterdayChange: yesterdayChange)
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
