import Foundation

/// Ein Tag: abgehakte Übungen, Gefühls-Wert 1–10 und Notizen.
/// Das JSON-Format entspricht der Web-App (`done`, `feel`, `factors`).
struct DayEntry: Codable, Equatable {
    var done: [String] = []
    var feel: Int? = nil
    var factors: [String] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        done = try c.decodeIfPresent([String].self, forKey: .done) ?? []
        feel = try c.decodeIfPresent(Int.self, forKey: .feel)
        factors = try c.decodeIfPresent([String].self, forKey: .factors) ?? []
    }

    var isEmpty: Bool { done.isEmpty && feel == nil && factors.isEmpty }

    /// Anzahl der Pflicht-Übungen (ohne optionale Extras)
    var requiredDone: Int { Catalog.required.filter { done.contains($0.id) }.count }

    var isComplete: Bool { requiredDone == Catalog.required.count }
}

/// Tages-Schlüssel im Format "yyyy-MM-dd" in der lokalen Zeitzone
enum DayKey {
    static var calendar: Calendar { Calendar.current }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(_ date: Date) -> String { formatter.string(from: date) }
    static func date(_ key: String) -> Date? { formatter.date(from: key) }
    static var today: String { key(Date()) }

    static func shift(_ date: Date, days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    static func startOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    static func shiftMonth(_ date: Date, by months: Int) -> Date {
        calendar.date(byAdding: .month, value: months, to: startOfMonth(date)) ?? date
    }

    static func daysInMonth(_ monthStart: Date) -> Int {
        calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }

    /// Wochentag als Index Montag = 0 … Sonntag = 6
    static func weekdayIndex(_ date: Date) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7
    }

    /// "Fr, 25. September"
    static func headerText(_ date: Date) -> String {
        let c = calendar.dateComponents([.day, .month], from: date)
        return Catalog.weekdays[weekdayIndex(date)] + ", " + String(c.day ?? 0) + ". " + Catalog.months[(c.month ?? 1) - 1]
    }

    /// "25. September 2026"
    static func longText(_ date: Date) -> String {
        let c = calendar.dateComponents([.day, .month, .year], from: date)
        return String(c.day ?? 0) + ". " + Catalog.months[(c.month ?? 1) - 1] + " " + String(c.year ?? 0)
    }
}
