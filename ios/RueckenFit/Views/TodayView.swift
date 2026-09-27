import SwiftUI

struct TodayView: View {
    @Environment(Store.self) private var store

    var body: some View {
        let key = store.todayKey
        let entry = store.entry(key)

        ScrollView {
            VStack(spacing: 14) {
                AppHeader(date: Date())

                MottoCard()

                Card(title: "Wie geht es Dir körperlich?",
                     subtitle: "Dein Rücken-Gefühl heute – 1 (schlecht) bis 10 (super)") {
                    FeelScale(value: entry.feel) { store.setFeel($0, on: key) }
                }

                BoosterCard()

                Card(title: "Deine Übungen heute", subtitle: "Einfach antippen zum Abhaken") {
                    ExerciseList(key: key)
                    ProgressRow(done: entry.requiredDone, total: Catalog.required.count)
                }

                Card(title: "Zum Tag notieren",
                     subtitle: "Für die spätere Auswertung, wenn es Dir mal nicht gut geht") {
                    FactorChips(key: key)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
    }
}

/// Merksatz-Box ganz oben
struct MottoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(Catalog.motto.enumerated()), id: \.offset) { index, line in
                HStack(spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Theme.green, in: Circle())
                    Text(line).font(.subheadline.weight(.semibold))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.green)
                .frame(width: 5)
                .padding(.vertical, 12)
        }
    }
}
