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

/// Eine Übung mit rundem Häkchen-Feld
struct ExerciseRow: View {
    let exercise: Exercise
    let done: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
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

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.body.weight(.medium))
                        .strikethrough(done)
                        .foregroundStyle(done ? Color.secondary : Color.primary)
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
}

/// Die komplette Übungsliste für einen Tag, mit Abschnitt "Workouts"
struct ExerciseList: View {
    let key: String
    @Environment(Store.self) private var store

    var body: some View {
        let entry = store.entry(key)
        VStack(spacing: 0) {
            ForEach(Array(Catalog.exercises.enumerated()), id: \.element.id) { index, exercise in
                if exercise.isWorkout && (index == 0 || !Catalog.exercises[index - 1].isWorkout) {
                    SectionLabel("Workouts")
                }
                ExerciseRow(exercise: exercise, done: entry.done.contains(exercise.id)) {
                    store.toggleExercise(exercise.id, on: key)
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
