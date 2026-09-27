import SwiftUI

struct SelectedDay: Identifiable {
    let key: String
    var id: String { key }
}

struct OverviewView: View {
    @Environment(Store.self) private var store
    @State private var monthStart: Date = DayKey.startOfMonth(Date())
    @State private var selected: SelectedDay? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                AppHeader(date: Date())

                Card {
                    CalendarMonth(monthStart: $monthStart) { key in
                        selected = SelectedDay(key: key)
                    }
                }

                TrendChartCard(monthStart: monthStart)

                StatsSection(monthStart: monthStart)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .sheet(item: $selected) { day in
            DayEditorView(key: day.key)
                .presentationDragIndicator(.visible)
        }
    }
}

/// Monatsnavigation + Kalenderraster
struct CalendarMonth: View {
    @Binding var monthStart: Date
    let onSelect: (String) -> Void
    @Environment(Store.self) private var store

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let comps = DayKey.calendar.dateComponents([.year, .month], from: monthStart)
        let title = Catalog.months[(comps.month ?? 1) - 1] + " " + String(comps.year ?? 0)
        let offset = DayKey.weekdayIndex(monthStart)
        let days = DayKey.daysInMonth(monthStart)
        let today = store.todayKey

        VStack(spacing: 12) {
            HStack {
                navButton("chevron.left") { monthStart = DayKey.shiftMonth(monthStart, by: -1) }
                Spacer()
                Text(title).font(.headline)
                Spacer()
                navButton("chevron.right") { monthStart = DayKey.shiftMonth(monthStart, by: 1) }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Catalog.weekdays, id: \.self) { d in
                    Text(d.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                ForEach(0..<offset, id: \.self) { _ in Color.clear.frame(height: 44) }
                ForEach(1...days, id: \.self) { day in
                    let date = DayKey.shift(monthStart, days: day - 1)
                    let key = DayKey.key(date)
                    CalendarCell(day: day, entry: store.entries[key], isToday: key == today, isFuture: key > today)
                        .onTapGesture { if key <= today { onSelect(key) } }
                }
            }

            HStack(spacing: 12) {
                legendItem(Theme.green, "alles geschafft")
                legendItem(Theme.partial.opacity(0.45), "teilweise")
                Text("Zahl unten = Gefühl")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            Text("Tag antippen = nachtragen")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func navButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .frame(width: 36, height: 36)
                .background(Theme.background, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func legendItem(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
            Text(text)
        }
    }
}

struct CalendarCell: View {
    let day: Int
    let entry: DayEntry?
    let isToday: Bool
    let isFuture: Bool

    var body: some View {
        let complete = entry?.isComplete ?? false
        let partial = !(entry?.done.isEmpty ?? true) && !complete
        VStack(spacing: 1) {
            Text("\(day)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(complete ? Color.white : (isFuture ? Color.secondary : Color.primary))
            if let feel = entry?.feel {
                Text("\(feel)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(complete ? Color.white.opacity(0.9) : Color.secondary)
            }
            HStack(spacing: 2) {
                ForEach(Catalog.factors.filter { entry?.factors.contains($0.id) ?? false }) { f in
                    Circle().fill(f.color).frame(width: 4, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            complete ? Theme.green : (partial ? Theme.partial.opacity(0.45) : Color.clear),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isToday ? Theme.green : Color.clear, lineWidth: 2))
        .contentShape(Rectangle())
    }
}

/// Zahlen unter dem Kalender: Tage komplett, trainiert, Ø Gefühl, Notizen
struct StatsSection: View {
    let monthStart: Date
    @Environment(Store.self) private var store

    private struct Stats {
        var full = 0
        var any = 0
        var feelSum = 0
        var feelCount = 0
        var factorCounts: [String: Int] = [:]

        var average: String {
            feelCount > 0 ? (Double(feelSum) / Double(feelCount)).germanOneDecimal : "–"
        }
    }

    private var stats: Stats {
        var s = Stats()
        for day in 1...DayKey.daysInMonth(monthStart) {
            let key = DayKey.key(DayKey.shift(monthStart, days: day - 1))
            guard let e = store.entries[key] else { continue }
            if e.isComplete { s.full += 1 }
            if !e.done.isEmpty { s.any += 1 }
            if let f = e.feel { s.feelSum += f; s.feelCount += 1 }
            for id in e.factors { s.factorCounts[id, default: 0] += 1 }
        }
        return s
    }

    var body: some View {
        let s = stats
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatTile(value: "\(s.full)", label: "Tage komplett", color: Theme.green)
                StatTile(value: "\(s.any)", label: "Tage trainiert", color: Theme.green)
                StatTile(value: s.average, label: "Ø Gefühl", color: Theme.green)
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Catalog.factors) { f in
                    StatTile(value: "\(s.factorCounts[f.id] ?? 0)", label: f.icon + " " + f.short, color: f.color)
                }
            }
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.weight(.bold)).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
