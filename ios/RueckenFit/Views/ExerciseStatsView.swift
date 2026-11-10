import SwiftUI

enum ExerciseStatsRange: String, CaseIterable, Identifiable {
    case month = "Dieser Monat"
    case all = "Insgesamt"
    var id: String { rawValue }
}

/// Wie oft jede Übung gemacht wurde – im angezeigten Monat oder seit Beginn
struct ExerciseStatsCard: View {
    let monthStart: Date
    @Environment(Store.self) private var store
    @State private var range: ExerciseStatsRange = .month

    struct Row: Identifiable {
        let id: String
        let name: String
        let count: Int
        let order: Int
        let legacy: Bool
    }

    struct Stats {
        var rows: [Row] = []
        var total = 0
        var trainedDays = 0
        var periodDays = 0
        var since: Date? = nil
    }

    var body: some View {
        let stats = makeStats()
        Card(title: "Deine Übungen im Überblick", subtitle: subtitle(stats)) {
            Picker("Zeitraum", selection: $range) {
                ForEach(ExerciseStatsRange.allCases) { r in Text(r.rawValue).tag(r) }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)

            if stats.periodDays == 0 {
                emptyText("Dieser Monat liegt noch in der Zukunft.")
            } else if stats.total == 0 {
                emptyText("In diesem Zeitraum ist noch keine Übung abgehakt.")
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 18) {
                    heroNumber("\(stats.total)", "Übungen abgehakt")
                    heroNumber("\(stats.trainedDays)", "von \(stats.periodDays) Tagen trainiert")
                }
                .padding(.bottom, 12)

                ExerciseBars(rows: stats.rows, periodDays: stats.periodDays)
                    .id(range.rawValue + DayKey.key(monthStart))

                legend(showLegacy: stats.rows.contains { $0.legacy })
                    .padding(.top, 12)
            }
        }
    }

    // MARK: - Teile

    private func emptyText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    private func heroNumber(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.system(size: 30, weight: .heavy)).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func legend(showLegacy: Bool) -> some View {
        var labels: [String] = Catalog.categoryLegend.map { $0.label }
        var colors: [Color] = Catalog.categoryLegend.map { $0.category.color }
        if showLegacy {
            labels.append("Frühere Übung")
            colors.append(Color.secondary.opacity(0.5))
        }
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                ForEach(labels.indices, id: \.self) { i in
                    HStack(spacing: 5) {
                        Circle().fill(colors[i]).frame(width: 9, height: 9)
                        Text(labels[i])
                    }
                }
            }
            Text("% = Anteil der Tage im Zeitraum")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func subtitle(_ stats: Stats) -> String {
        if range == .month {
            let c = DayKey.calendar.dateComponents([.year, .month], from: monthStart)
            return "Wie oft Du jede Übung im " + Catalog.months[(c.month ?? 1) - 1] + " " + String(c.year ?? 0) + " gemacht hast"
        }
        if let since = stats.since {
            return "Seit dem " + DayKey.longText(since) + " – \(stats.periodDays) Tage"
        }
        return "Seit Beginn"
    }

    // MARK: - Daten

    private func makeStats() -> Stats {
        let today = store.todayKey
        var keys: [String] = []
        var since: Date? = nil

        if range == .month {
            for day in 1...DayKey.daysInMonth(monthStart) {
                let key = DayKey.key(DayKey.shift(monthStart, days: day - 1))
                if key > today { break }
                keys.append(key)
            }
        } else if let first = store.entries.keys.filter({ $0 <= today }).sorted().first,
                  let start = DayKey.date(first) {
            since = start
            var cursor = start
            while DayKey.key(cursor) <= today {
                keys.append(DayKey.key(cursor))
                cursor = DayKey.shift(cursor, days: 1)
            }
        }

        var counts: [String: Int] = [:]
        var stats = Stats(periodDays: keys.count, since: since)
        for key in keys {
            guard let e = store.entries[key], !e.done.isEmpty else { continue }
            stats.trainedDays += 1
            for id in e.done {
                counts[id, default: 0] += 1
                stats.total += 1
            }
        }

        // Aktuelle Übungen nach Häufigkeit, bei Gleichstand in Listen-Reihenfolge
        var rows = Catalog.exercises.enumerated().map { index, ex in
            Row(id: ex.id, name: ex.name, count: counts[ex.id] ?? 0, order: index, legacy: false)
        }
        rows.sort { $0.count != $1.count ? $0.count > $1.count : $0.order < $1.order }
        for (index, legacy) in Catalog.legacyExercises.enumerated() {
            if let n = counts[legacy.id], n > 0 {
                rows.append(Row(id: legacy.id, name: legacy.name + " (früher)", count: n, order: 1000 + index, legacy: true))
            }
        }
        stats.rows = rows
        return stats
    }
}

/// Die Balken – wachsen beim Erscheinen nacheinander ins Bild
struct ExerciseBars: View {
    let rows: [ExerciseStatsCard.Row]
    let periodDays: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var grown = false

    private static let track = Color.adaptive(light: 0xEEF1EF, dark: 0x26322D)

    var body: some View {
        let top = rows.first(where: { !$0.legacy })?.count ?? 0
        VStack(spacing: 9) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                let share = periodDays > 0 ? Double(row.count) / Double(periodDays) : 0
                let percent = Int((share * 100).rounded())
                HStack(spacing: 10) {
                    if row.legacy {
                        Circle().fill(Color.secondary.opacity(0.35)).frame(width: 26, height: 26)
                    } else {
                        ExerciseIcon(id: row.id, size: 26)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(row.name + (row.count > 0 && row.count == top && !row.legacy ? " 🏆" : ""))
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(row.count > 0 ? Color.primary : Color.secondary)
                            .lineLimit(1)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Self.track)
                                if row.count > 0 {
                                    Capsule()
                                        .fill(color(for: row))
                                        .frame(width: max(4, geo.size.width * share))
                                        .scaleEffect(x: grown ? 1 : 0, y: 1, anchor: .leading)
                                        .animation(reduceMotion ? nil
                                                   : .easeOut(duration: 0.8).delay(Double(index) * 0.035), value: grown)
                                }
                            }
                        }
                        .frame(height: 10)
                    }
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(row.count)×").font(.subheadline.weight(.heavy)).monospacedDigit()
                        Text("\(percent) %").font(.caption2).foregroundStyle(.secondary).monospacedDigit()
                    }
                    .frame(minWidth: 50, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(row.name): an \(row.count) von \(periodDays) Tagen, \(percent) Prozent")
            }
        }
        .onAppear { grown = true }
    }

    private func color(for row: ExerciseStatsCard.Row) -> Color {
        if row.legacy { return Color.secondary.opacity(0.5) }
        return Catalog.icons[row.id]?.category.color ?? Theme.green
    }
}
