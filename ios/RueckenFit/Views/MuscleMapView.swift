import SwiftUI

// MARK: - Auswertung

enum MuscleStatus: String, CaseIterable {
    case aufbau, brach, vernachlaessigt

    var label: String {
        switch self {
        case .aufbau: return "Im Aufbau"
        case .brach: return "Liegt brach"
        case .vernachlaessigt: return "Vernachlässigt"
        }
    }
    var text: String {
        switch self {
        case .aufbau: return "mind. 2× pro Woche"
        case .brach: return "zuletzt zu selten"
        case .vernachlaessigt: return "kaum trainiert"
        }
    }
    /// Feste Status-Farben (geprüft) – nie allein: immer mit Symbol, Text und beim Roten mit Schraffur
    var color: Color {
        switch self {
        case .aufbau: return Color(hex: 0x0CA30C)
        case .brach: return Color(hex: 0xFAB219)
        case .vernachlaessigt: return Color(hex: 0xD03B3B)
        }
    }
    var symbol: String {
        switch self {
        case .aufbau: return "checkmark"
        case .brach: return "minus"
        case .vernachlaessigt: return "exclamationmark"
        }
    }
}

struct MuscleReport {
    struct Item {
        var recent = 0.0
        var long = 0.0
        var by: [String: Int] = [:]
        var status: MuscleStatus = .vernachlaessigt
    }
    let ref: Date
    let items: [String: Item]

    func item(_ id: String) -> Item { items[id] ?? Item() }
    func count(_ s: MuscleStatus) -> Int { Muscles.all.filter { item($0.id).status == s }.count }
}

extension Store {
    /// Wie oft jeder Muskel in den letzten 14 bzw. 60 Tagen bis `ref` dran war (pro Tag höchstens 1)
    func muscleReport(ref: Date) -> MuscleReport {
        var items: [String: MuscleReport.Item] = [:]
        for m in Muscles.all { items[m.id] = MuscleReport.Item() }
        for i in 0..<Muscles.longDays {
            let e = entry(DayKey.key(DayKey.shift(ref, days: -i)))
            if e.done.isEmpty { continue }
            var day: [String: Double] = [:]
            for id in e.done {
                guard let map = Muscles.map[id] else { continue }
                for (mid, w) in map {
                    day[mid, default: 0] += w
                    if i < Muscles.recentDays && w >= 0.5 { items[mid]?.by[id, default: 0] += 1 }
                }
            }
            for (mid, v) in day {
                let c = min(1, v)
                items[mid]?.long += c
                if i < Muscles.recentDays { items[mid]?.recent += c }
            }
        }
        for (mid, it) in items {
            let s: MuscleStatus = it.recent >= Muscles.good ? .aufbau
                : (it.recent < Muscles.some && it.long < Muscles.good ? .vernachlaessigt : .brach)
            items[mid]?.status = s
        }
        return MuscleReport(ref: ref, items: items)
    }
}

enum MuscleText {
    static func exerciseName(_ id: String) -> String {
        Catalog.exercises.first { $0.id == id }?.name
            ?? Catalog.legacyExercises.first { $0.id == id }?.name ?? id
    }

    /// Passende Übung: höchste Wirkung, Pflicht-Übungen vor Workouts
    static func bestExercise(for mid: String) -> Exercise? {
        var best: Exercise? = nil
        var score = 0.0
        for ex in Catalog.exercises {
            let w = Muscles.map[ex.id]?[mid] ?? 0
            let sc = w - (ex.isWorkout ? 0.05 : 0)
            if w >= 0.5 && sc > score { best = ex; score = sc }
        }
        return best
    }

    static func fmt(_ v: Double) -> String {
        let r = (v * 10).rounded() / 10
        return r == r.rounded() ? String(Int(r)) : r.germanOneDecimal
    }
    static func days(_ v: Double) -> String { fmt(v) + (abs(v - 1) < 0.05 ? " Trainingstag" : " Trainingstage") }

    static func focus(_ r: MuscleReport) -> String {
        let n = Muscles.all.count
        let focus = Muscles.all.filter { r.item($0.id).status != .aufbau }
            .sorted {
                let a = r.item($0.id), b = r.item($1.id)
                let pa = a.status == .vernachlaessigt ? 0 : 1, pb = b.status == .vernachlaessigt ? 0 : 1
                return pa != pb ? pa < pb : a.recent < b.recent
            }
            .prefix(2)
        if focus.isEmpty { return "🔥 Ganzkörper-Booster! Alle Muskelgruppen sind im Aufbau." }
        var tips: [String] = []
        for m in focus { if let ex = bestExercise(for: m.id), !tips.contains(ex.name) { tips.append(ex.name) } }
        let core = "Nächster Fokus: " + focus.map(\.name).joined(separator: " und ")
            + (tips.isEmpty ? "" : " – Tipp: " + tips.joined(separator: " oder "))
        return (r.count(.aufbau) >= n - 2 ? "💪 Fast alles im Aufbau! " : "🎯 ") + core
    }
}

// MARK: - Karte

struct MuscleMapCard: View {
    let monthStart: Date
    @Environment(Store.self) private var store
    @State private var selected: String? = nil

    private var refDate: Date {
        let end = DayKey.shift(DayKey.shiftMonth(monthStart, by: 1), days: -1)
        return min(end, Date())
    }

    var body: some View {
        let ref = refDate
        let report = store.muscleReport(ref: ref)
        let isToday = DayKey.key(ref) == store.todayKey

        Card(title: "Deine Muskeln",
             subtitle: (isToday ? "Stand heute" : "Stand " + DayKey.longText(ref))
                + " – welche Muskeln Du aufbaust und welche zu kurz kommen · tippe einen Muskel an") {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(report.count(.aufbau))").font(.system(size: 34, weight: .heavy))
                    + Text(" / \(Muscles.all.count)").font(.headline).foregroundColor(.secondary)
                Text("Muskelgruppen im Aufbau").font(.subheadline).foregroundStyle(.secondary)
            }
            Text(MuscleText.focus(report))
                .font(.subheadline.weight(.semibold))
                .padding(.bottom, 4)

            BodyFigure(report: report, selected: $selected)
                .frame(maxWidth: 360)
                .frame(maxWidth: .infinity)

            detail(report)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(MuscleStatus.allCases, id: \.self) { st in
                    group(st, report)
                }
            }
            .padding(.top, 6)

            Text("Grundlage sind Deine abgehakten Übungen. Ein Trainingstag zählt voll, wenn der Muskel Hauptarbeit leistet; hilft er nur mit, zählt er halb, Dehnen ein Drittel. Im Aufbau = mind. 2× pro Woche in den letzten 14 Tagen.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func detail(_ r: MuscleReport) -> some View {
        Group {
            if let id = selected, let m = Muscles.all.first(where: { $0.id == id }) {
                let it = r.item(id)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        StatusIcon(status: it.status)
                        Text(m.name).font(.subheadline.weight(.bold))
                        Text("– " + it.status.label).font(.subheadline)
                    }
                    Text(MuscleText.days(it.recent) + " in den letzten \(Muscles.recentDays) Tagen (Ziel: \(Int(Muscles.good))) · "
                         + MuscleText.fmt(it.long) + " in \(Muscles.longDays) Tagen")
                        .font(.footnote)
                    let by = it.by.sorted { $0.value > $1.value }.prefix(4).map { MuscleText.exerciseName($0.key) }
                    if !by.isEmpty {
                        Text("Trainiert durch: " + by.joined(separator: ", ")).font(.footnote).foregroundStyle(.secondary)
                    }
                    if it.status != .aufbau, let ex = MuscleText.bestExercise(for: id) {
                        Text("💡 Tipp: " + ex.name).font(.footnote)
                    }
                }
            } else {
                Text("Tippe einen Muskel oder einen Namen an – dann siehst Du, wie oft er zuletzt dran war und womit.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(10)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
        .padding(.top, 6)
    }

    private func group(_ st: MuscleStatus, _ r: MuscleReport) -> some View {
        let list = Muscles.all.filter { r.item($0.id).status == st }
        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                StatusIcon(status: st)
                Text(st.label).font(.subheadline.weight(.bold))
                Text("\(list.count) · " + st.text).font(.subheadline).foregroundStyle(.secondary)
            }
            if list.isEmpty {
                Text("keine").font(.footnote).foregroundStyle(.secondary)
            } else {
                ChipFlow(spacing: 6) {
                    ForEach(list) { m in
                        Button {
                            selected = selected == m.id ? nil : m.id
                        } label: {
                            Text(m.name)
                                .font(.footnote.weight(selected == m.id ? .bold : .regular))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .overlay(Capsule().stroke(selected == m.id ? Color.primary : Theme.line, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct StatusIcon: View {
    let status: MuscleStatus
    var body: some View {
        ZStack {
            Circle().fill(status.color)
            Image(systemName: status.symbol)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(status == .brach ? Color(hex: 0x0B0B0B) : .white)
        }
        .frame(width: 16, height: 16)
        .accessibilityHidden(true)
    }
}

/// Einfacher Zeilenumbruch für die Namens-Chips
struct ChipFlow: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, widest: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0 && x + s.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            x += s.width + spacing
            rowH = max(rowH, s.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, maxW), height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > bounds.minX && x + s.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
    }
}

// MARK: - Körper

/// Vorder- und Rückansicht, Muskeln nach Status eingefärbt. Antippen wählt einen Muskel.
struct BodyFigure: View {
    let report: MuscleReport
    @Binding var selected: String?

    private static let size = CGSize(width: 212, height: 236)
    private static let base = Color.adaptive(light: 0xDDE4E1, dark: 0x33423C)
    private static let hatch = Color.adaptive(light: 0x8A1F1F, dark: 0x5A1212)
    private static let mirror = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 100, ty: 0)

    /// Alle Muskelflächen beider Ansichten in Bild-Koordinaten, je Seite gespiegelt
    private static let shapes: [(id: String, path: Path, front: Bool)] = {
        var out: [(id: String, path: Path, front: Bool)] = []
        for (vi, list) in [Muscles.front, Muscles.back].enumerated() {
            let shift = CGAffineTransform(translationX: CGFloat(vi) * 108 + 3, y: 4)
            for (id, d) in list {
                let p = SVGPath.parse(d)
                out.append((id: id, path: p.applying(shift), front: vi == 0))
                out.append((id: id, path: p.applying(mirror).applying(shift), front: vi == 0))
            }
        }
        return out
    }()
    private static let basePath: Path = {
        var all = Path()
        for vi in 0..<2 {
            let shift = CGAffineTransform(translationX: CGFloat(vi) * 108 + 3, y: 4)
            for d in Muscles.bodyBase {
                let p = SVGPath.parse(d)
                all.addPath(p.applying(shift))
                all.addPath(p.applying(mirror).applying(shift))
            }
        }
        return all
    }()
    private static let sixpackPath: Path = {
        let p = SVGPath.parse(Muscles.sixpack)
        let shift = CGAffineTransform(translationX: 3, y: 4)
        var all = Path()
        all.addPath(p.applying(shift))
        all.addPath(p.applying(mirror).applying(shift))
        return all
    }()

    var body: some View {
        GeometryReader { geo in
            let k = geo.size.width / Self.size.width
            Canvas { c, _ in
                c.scaleBy(x: k, y: k)
                c.fill(Self.basePath, with: .color(Self.base))
                for s in Self.shapes {
                    let st = report.item(s.id).status
                    let dim = selected != nil && selected != s.id
                    c.drawLayer { l in
                        l.opacity = dim ? 0.28 : 1
                        l.fill(s.path, with: .color(st.color))
                        if st == .vernachlaessigt { drawHatch(&l, in: s.path) }
                        l.stroke(s.path, with: .color(Self.base), style: StrokeStyle(lineWidth: 1.2, lineJoin: .round))
                    }
                }
                c.stroke(Self.sixpackPath, with: .color(Self.base), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
                for (i, label) in ["Vorne", "Hinten"].enumerated() {
                    let t = c.resolve(Text(label).font(.system(size: 8, weight: .bold)).foregroundColor(.secondary))
                    c.draw(t, at: CGPoint(x: CGFloat(i) * 108 + 53, y: 230), anchor: .center)
                }
            }
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { ev in
                let p = CGPoint(x: ev.location.x / k, y: ev.location.y / k)
                let hit = Self.shapes.last { $0.path.contains(p) }?.id
                selected = (hit == nil || hit == selected) ? nil : hit
            })
        }
        .aspectRatio(Self.size.width / Self.size.height, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Körper vorne und hinten, Muskeln nach Trainingsstand eingefärbt. Die Liste darunter nennt jeden Muskel mit Status.")
    }

    /// 45°-Schraffur als zweites Merkmal neben der Farbe (für Rot-Grün-Schwäche)
    private func drawHatch(_ c: inout GraphicsContext, in path: Path) {
        let r = path.boundingRect
        var lines = Path()
        var x = r.minX - r.height
        while x < r.maxX {
            lines.move(to: CGPoint(x: x, y: r.maxY))
            lines.addLine(to: CGPoint(x: x + r.height, y: r.minY))
            x += 4 * 1.414
        }
        c.drawLayer { l in
            l.clip(to: path)
            l.stroke(lines, with: .color(Self.hatch), lineWidth: 1.6)
        }
    }
}
