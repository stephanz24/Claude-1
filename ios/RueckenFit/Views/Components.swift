import SwiftUI

/// Weiße Karte mit abgerundeten Ecken – das Grundelement aller Ansichten
struct Card<Content: View>: View {
    var title: String? = nil
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title {
                Text(title).font(.headline)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// Kopfzeile wie in der Web-App: Name links, Datum rechts
struct AppHeader: View {
    let date: Date

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            (Text("Rücken") + Text("Fit").foregroundStyle(Theme.green))
                .font(.title.weight(.bold))
            Spacer()
            Text(DayKey.headerText(date))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }
}

/// Kleine Zwischenüberschrift in Großbuchstaben
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .kerning(0.6)
            .foregroundStyle(.secondary)
            .padding(.top, 14)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Gefühls-Skala 1–10 als zwei Reihen mit fünf Feldern
struct FeelScale: View {
    let value: Int?
    let onSelect: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...10, id: \.self) { i in
                    let selected = value == i
                    Button { onSelect(i) } label: {
                        Text("\(i)")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(selected ? Theme.green : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Theme.green : Theme.line, lineWidth: 1.5))
                            .foregroundStyle(selected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Text("schlecht")
                Spacer()
                Text("super")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

/// Eine Übung mit rundem Häkchen-Feld, Symbol und Serien-Flamme
struct ExerciseRow: View {
    let exercise: Exercise
    let done: Bool
    var streak: Store.StreakInfo? = nil
    let action: () -> Void

    private static let chipBackground = Color.adaptive(light: 0xFFF1E6, dark: 0x4A2A17)
    private static let chipText = Color.adaptive(light: 0xA8461A, dark: 0xFFC59E)
    private static let chipBorder = Color.adaptive(light: 0xE0956A, dark: 0xB8683C)

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(done ? Theme.green : Theme.line, lineWidth: 2)
                    if done {
                        Circle().fill(Theme.green)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 30, height: 30)

                ExerciseIcon(id: exercise.id)
                    .opacity(done ? 0.55 : 1)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(exercise.name)
                            .font(.body.weight(.medium))
                            .strikethrough(done)
                            .foregroundStyle(done ? Color.secondary : Color.primary)
                        if let streak, streak.count >= 2 {
                            streakChip(streak)
                        }
                    }
                    if let hint = exercise.hint {
                        Text(hint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 🔥 = Serie läuft, ⏳ = Serie bis gestern, heute abhaken zum Fortsetzen
    private func streakChip(_ streak: Store.StreakInfo) -> some View {
        Text("🔥 \(streak.count)" + (streak.active ? "" : " ⏳"))
            .font(.caption2.weight(.bold))
            .foregroundStyle(Self.chipText)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(streak.active ? Self.chipBackground : Color.clear, in: Capsule())
            .overlay(
                Capsule().strokeBorder(streak.active ? Color.clear : Self.chipBorder,
                                       style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
            )
            .fixedSize()
            .accessibilityLabel(streak.active
                ? "\(streak.count) Tage am Stück"
                : "Serie von \(streak.count) Tagen, heute abhaken zum Fortsetzen")
    }
}

/// Die komplette Übungsliste für einen Tag, mit Abschnitt "Workouts"
struct ExerciseList: View {
    let key: String
    var showStreaks: Bool = false
    @Environment(Store.self) private var store
    @Environment(Celebration.self) private var celebration

    var body: some View {
        let entry = store.entry(key)
        VStack(spacing: 0) {
            ForEach(Array(Catalog.exercises.enumerated()), id: \.element.id) { index, exercise in
                if exercise.isWorkout && (index == 0 || !Catalog.exercises[index - 1].isWorkout) {
                    SectionLabel("Workouts")
                }
                ExerciseRow(exercise: exercise,
                            done: entry.done.contains(exercise.id),
                            streak: showStreaks ? store.streakInfo(exercise.id) : nil) {
                    let before = store.streakInfo(exercise.id).count
                    store.toggleExercise(exercise.id, on: key)
                    celebration.check(store: store, exerciseID: exercise.id, before: before)
                }
                if index < Catalog.exercises.count - 1 {
                    Divider()
                }
            }
        }
    }
}

/// Ein Notiz-Chip (Schmerzmittel, Voltaren, …)
struct FactorChip: View {
    let factor: Factor
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Circle()
                    .fill(selected ? factor.color : Theme.line)
                    .frame(width: 10, height: 10)
                Text(factor.icon + " " + factor.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(selected ? factor.color.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? factor.color : Theme.line, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Alle Notiz-Chips für einen Tag
struct FactorChips: View {
    let key: String
    @Environment(Store.self) private var store

    var body: some View {
        let entry = store.entry(key)
        VStack(spacing: 8) {
            ForEach(Catalog.factors) { factor in
                FactorChip(factor: factor, selected: entry.factors.contains(factor.id)) {
                    store.toggleFactor(factor.id, on: key)
                }
            }
        }
    }
}

/// Fortschrittsbalken "n von 13 Übungen"
struct ProgressRow: View {
    let done: Int
    let total: Int

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.line)
                    Capsule()
                        .fill(Theme.green)
                        .frame(width: geo.size.width * CGFloat(done) / CGFloat(max(1, total)))
                        .animation(.easeOut(duration: 0.25), value: done)
                }
            }
            .frame(height: 8)
            if done == total {
                Text("🎉 Alle Übungen geschafft – stark!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.green)
            } else {
                Text("\(done) von \(total) Übungen")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 14)
    }
}

extension Double {
    /// 6.4 → "6,4"
    var germanOneDecimal: String {
        String(format: "%.1f", self).replacingOccurrences(of: ".", with: ",")
    }
}
