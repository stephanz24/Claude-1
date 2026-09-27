import SwiftUI

struct SettingsView: View {
    @Environment(Store.self) private var store
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 8 * 60
    @State private var showDeniedHint = false
    @State private var confirmErase = false

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = reminderMinutes / 60
                comps.minute = reminderMinutes % 60
                return DayKey.calendar.date(from: comps) ?? Date()
            },
            set: { date in
                let c = DayKey.calendar.dateComponents([.hour, .minute], from: date)
                reminderMinutes = (c.hour ?? 8) * 60 + (c.minute ?? 0)
                if reminderOn { Reminders.schedule(minutesFromMidnight: reminderMinutes) }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Tägliche Erinnerung", isOn: $reminderOn)
                    if reminderOn {
                        DatePicker("Uhrzeit", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Erinnerung")
                } footer: {
                    Text("Eine Mitteilung auf dem iPhone, jeden Tag zur gewählten Zeit.")
                }

                Section {
                    NavigationLink("Aus der Web-App übernehmen") { ImportView() }
                    ShareLink(item: store.exportJSON(), preview: SharePreview("RückenFit-Daten")) {
                        Label("Daten sichern (Export)", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Daten")
                } footer: {
                    Text("\(store.entries.count) Tage gespeichert – nur auf diesem iPhone, nichts wird irgendwohin gesendet.")
                }

                Section {
                    Button("Alle Daten löschen", role: .destructive) { confirmErase = true }
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Tages-Soll", value: "\(Catalog.required.count) Übungen")
                    LabeledContent("Guter Tag ab", value: "\(Catalog.goodMin) Übungen")
                } header: {
                    Text("Über")
                }
            }
            .navigationTitle("Mehr")
            .onChange(of: reminderOn) { _, on in
                if on {
                    Task {
                        if await Reminders.requestAuthorization() {
                            Reminders.schedule(minutesFromMidnight: reminderMinutes)
                        } else {
                            reminderOn = false
                            showDeniedHint = true
                        }
                    }
                } else {
                    Reminders.cancel()
                }
            }
            .alert("Mitteilungen sind ausgeschaltet", isPresented: $showDeniedHint) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Bitte in den iPhone-Einstellungen unter Mitteilungen → RückenFit erlauben.")
            }
            .confirmationDialog("Wirklich alle Einträge löschen?", isPresented: $confirmErase, titleVisibility: .visible) {
                Button("Alle Daten löschen", role: .destructive) { store.eraseAll() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Das lässt sich nicht rückgängig machen. Vorher sichern lohnt sich.")
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return v + " (" + b + ")"
    }
}

/// Export-Text aus der Web-App einfügen und übernehmen
struct ImportView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var message: String? = nil
    @State private var succeeded = false

    var body: some View {
        Form {
            Section {
                Text("In der Web-App unter Übersicht auf „Daten exportieren“ tippen, den Text kopieren und hier einfügen. Vorhandene Tage werden durch die importierten ersetzt.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Export-Text") {
                TextEditor(text: $text)
                    .font(.system(.footnote, design: .monospaced))
                    .frame(minHeight: 160)
                Button {
                    if let s = UIPasteboard.general.string { text = s }
                } label: {
                    Label("Aus der Zwischenablage einfügen", systemImage: "doc.on.clipboard")
                }
            }
            Section {
                Button("Importieren") {
                    do {
                        let n = try store.importJSON(text)
                        message = "\(n) Tage übernommen."
                        succeeded = true
                    } catch {
                        message = error.localizedDescription
                        succeeded = false
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Daten übernehmen")
        .navigationBarTitleDisplayMode(.inline)
        .alert(succeeded ? "Fertig" : "Import fehlgeschlagen", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") { if succeeded { dismiss() } }
        } message: {
            Text(message ?? "")
        }
    }
}
