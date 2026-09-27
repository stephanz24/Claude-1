import SwiftUI

/// Nachtragen eines beliebigen Tages – Gefühl, Übungen, Notizen
struct DayEditorView: View {
    let key: String
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let entry = store.entry(key)
        let date = DayKey.date(key) ?? Date()
        let isToday = key == store.todayKey

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Antippen zum Nachtragen – alles lässt sich jederzeit wieder ändern.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    SectionLabel("Rücken-Gefühl")
                    FeelScale(value: entry.feel) { store.setFeel($0, on: key) }

                    SectionLabel("Übungen")
                    ExerciseList(key: key)

                    SectionLabel("Notizen zum Tag")
                    FactorChips(key: key)

                    Text("\(entry.requiredDone) von \(Catalog.required.count) Übungen · " +
                         (store.isGoodDay(key) ? "zählt als guter Tag für den Booster" : "zählt (noch) nicht als guter Tag"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .navigationTitle(DayKey.longText(date) + (isToday ? " · Heute" : ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
