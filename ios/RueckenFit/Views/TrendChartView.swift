import SwiftUI
import Charts

enum TrendRange: String, CaseIterable, Identifiable {
    case month = "Monat"
    case year = "12 Monate"
    var id: String { rawValue }
}

/// Ein Punkt im Verlaufs-Diagramm: ein Tag (Monatsansicht) oder ein Monat (Jahresansicht)
struct TrendPoint: Identifiable {
    let id: Int              // Position auf der X-Achse, 1 … n
    let axisLabel: String
    let title: String
    let feel: Double?
    let share: Double        // Anteil erledigter Pflicht-Übungen 0 … 1
    let doneCount: Int
    let feelDays: Int
    let isFuture: Bool
    var segment: Int = 0     // Linienabschnitt – Lücken werden nicht überbrückt
}

struct TrendChartCard: View {
    let monthStart: Date
    @Environment(Store.self) private var store
    @State private var range: TrendRange = .month
    @State private var selectedIndex: Int? = nil

    var body: some View {
        let points = makePoints()
        let measured = points.filter { $0.feel != nil }
        let feelValues = measured.compactMap { $0.feel }
        let avg: Double? = feelValues.isEmpty ? nil : feelValues.reduce(0, +) / Double(feelValues.count)

        Card(title: "Verlauf: Wie geht es Dir?",
             subtitle: "Dein Gefühls-Wert über die Zeit – darunter, wie viel Du trainiert hast") {
            Picker("Zeitraum", selection: $range) {
                ForEach(TrendRange.allCases) { r in Text(r.rawValue).tag(r) }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)
            .onChange(of: range) { _, _ in selectedIndex = nil }

            if measured.isEmpty {
                Text("Noch keine Gefühls-Werte in diesem Zeitraum.\nTippe oben im Kalender einen Tag an, um ihn nachzutragen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                Text(infoText(points: points, measured: measured, avg: avg))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 6)
                    .frame(minHeight: 34, alignment: .top)

                chart(points: points, avg: avg)
                    .frame(height: 220)

                HStack(spacing: 14) {
                    HStack(spacing: 6) {
                        Circle().fill(Theme.chartLine).frame(width: 10, height: 10)
                        Text("Gefühl 1–10")
                    }
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3).fill(Theme.chartTrain).frame(width: 10, height: 10)
                        Text("Training (je dunkler, desto mehr Übungen)")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 10)
            }
        }
    }

    // MARK: - Diagramm

    private func chart(points: [TrendPoint], avg: Double?) -> some View {
        let n = points.count
        let ticks: [Double] = range == .year
            ? points.map { Double($0.id) }
            : stride(from: 1, through: n, by: 7).map { Double($0) }

        return Chart {
            // Trainings-Streifen unten – eigene Farbskala, keine zweite Y-Achse
            ForEach(points.filter { !$0.isFuture && $0.share > 0 }) { p in
                RectangleMark(
                    xStart: .value("von", Double(p.id) - 0.45),
                    xEnd: .value("bis", Double(p.id) + 0.45),
                    yStart: .value("unten", 0.0),
                    yEnd: .value("oben", 0.65)
                )
                .foregroundStyle(Theme.chartTrain.opacity(0.2 + 0.8 * min(1, p.share)))
                .cornerRadius(2)
            }

            ForEach(points.filter { $0.feel != nil }) { p in
                LineMark(
                    x: .value("Zeit", Double(p.id)),
                    y: .value("Gefühl", p.feel ?? 0),
                    series: .value("Abschnitt", p.segment)
                )
                .foregroundStyle(Theme.chartLine)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value("Zeit", Double(p.id)),
                    y: .value("Gefühl", p.feel ?? 0)
                )
                .foregroundStyle(Theme.chartLine)
                .symbolSize(range == .year ? 60 : (n > 20 ? 24 : 36))
            }

            if let avg {
                RuleMark(y: .value("Durchschnitt", avg))
                    .foregroundStyle(Color.secondary.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Ø " + avg.germanOneDecimal)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }

            if let sel = selectedIndex {
                RuleMark(x: .value("Auswahl", Double(sel)))
                    .foregroundStyle(Color.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
            }
        }
        .chartYScale(domain: 0...10.6)
        .chartXScale(domain: 0.5...(Double(n) + 0.5))
        .chartYAxis {
            AxisMarks(position: .leading, values: [2.0, 4.0, 6.0, 8.0, 10.0]) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks(values: ticks) { value in
                AxisValueLabel {
                    if let v = value.as(Double.self), let p = points.first(where: { $0.id == Int(v.rounded()) }) {
                        Text(p.axisLabel)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { g in
                                guard let frame = proxy.plotFrame else { return }
                                let x = g.location.x - geo[frame].origin.x
                                if let v: Double = proxy.value(atX: x) {
                                    selectedIndex = min(max(1, Int(v.rounded())), n)
                                }
                            }
                            .onEnded { _ in selectedIndex = nil }
                    )
            }
        }
    }

    // MARK: - Texte

    private func infoText(points: [TrendPoint], measured: [TrendPoint], avg: Double?) -> String {
        let total = Catalog.required.count
        if let sel = selectedIndex, let p = points.first(where: { $0.id == sel }) {
            if range == .year {
                let feelPart: String
                if let f = p.feel {
                    feelPart = "Ø Gefühl " + f.germanOneDecimal + " aus \(p.feelDays) " + (p.feelDays == 1 ? "Tag" : "Tagen")
                } else {
                    feelPart = "kein Gefühls-Wert"
                }
                let perDay = Int((p.share * Double(total)).rounded())
                return p.title + " · " + feelPart + " · Ø \(perDay) von \(total) Übungen pro Tag"
            }
            let feelPart = p.feel.map { "Gefühl \(Int($0)) von 10" } ?? "kein Gefühls-Wert"
            return p.title + " · " + feelPart + " · \(p.doneCount) von \(total) Übungen"
        }
        guard let avg else { return "" }
        let values = measured.compactMap { $0.feel }
        let avgText = "Ø " + avg.germanOneDecimal
        if range == .year {
            let days = points.reduce(0) { $0 + $1.feelDays }
            return avgText + " über \(measured.count) Monate · \(days) Tage bewertet"
        }
        let hi = Int(values.max() ?? 0)
        let lo = Int(values.min() ?? 0)
        return avgText + " · \(measured.count) von \(points.count) Tagen bewertet · höchster \(hi), niedrigster \(lo)"
    }

    // MARK: - Daten

    private func makePoints() -> [TrendPoint] {
        var points = range == .year ? yearPoints() : monthPoints()
        // Linienabschnitte: Lücken über maxGap werden nicht verbunden
        let maxGap = range == .year ? 1 : 3
        var segment = 0
        var lastIndex: Int? = nil
        for i in points.indices where points[i].feel != nil {
            if let last = lastIndex, i - last > maxGap { segment += 1 }
            points[i].segment = segment
            lastIndex = i
        }
        return points
    }

    private func monthPoints() -> [TrendPoint] {
        let days = DayKey.daysInMonth(monthStart)
        let today = store.todayKey
        return (1...days).map { day in
            let date = DayKey.shift(monthStart, days: day - 1)
            let key = DayKey.key(date)
            let e = store.entries[key]
            let done = e?.requiredDone ?? 0
            return TrendPoint(
                id: day,
                axisLabel: String(day),
                title: DayKey.headerText(date),
                feel: e?.feel.map(Double.init),
                share: Double(done) / Double(Catalog.required.count),
                doneCount: done,
                feelDays: e?.feel == nil ? 0 : 1,
                isFuture: key > today
            )
        }
    }

    private func yearPoints() -> [TrendPoint] {
        let today = store.todayKey
        let thisMonth = DayKey.startOfMonth(Date())
        return (0..<12).map { i in
            let start = DayKey.shiftMonth(thisMonth, by: i - 11)
            let comps = DayKey.calendar.dateComponents([.year, .month], from: start)
            var sum = 0, count = 0, elapsed = 0
            var shareSum = 0.0
            for day in 1...DayKey.daysInMonth(start) {
                let key = DayKey.key(DayKey.shift(start, days: day - 1))
                if key > today { break }
                elapsed += 1
                guard let e = store.entries[key] else { continue }
                if let f = e.feel { sum += f; count += 1 }
                shareSum += Double(e.requiredDone) / Double(Catalog.required.count)
            }
            let name = Catalog.months[(comps.month ?? 1) - 1]
            return TrendPoint(
                id: i + 1,
                axisLabel: String(name.prefix(3)),
                title: name + " " + String(comps.year ?? 0),
                feel: count > 0 ? Double(sum) / Double(count) : nil,
                share: elapsed > 0 ? shareSum / Double(elapsed) : 0,
                doneCount: count,
                feelDays: count,
                isFuture: false
            )
        }
    }
}
