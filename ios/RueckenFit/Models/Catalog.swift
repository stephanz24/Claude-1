import SwiftUI

struct Exercise: Identifiable, Hashable {
    let id: String
    let name: String
    var hint: String? = nil
    var isWorkout: Bool = false
    var isOptional: Bool = false
}

struct Factor: Identifiable, Hashable {
    let id: String
    let name: String
    let short: String
    let icon: String
    let color: Color
}

/// Übungen, Notizen und Texte – dieselben Kennungen wie in der Web-App,
/// damit exportierte Daten 1:1 übernommen werden können.
enum Catalog {
    static let motto = ["Erst mobilisieren", "Dann Gegenrichtung aufdehnen", "Und dann kräftigen"]

    static let exercises: [Exercise] = [
        Exercise(id: "transversus", name: "Transversus aktivieren", hint: "tiefe Bauchmuskulatur: Bauchnabel sanft nach innen ziehen, ohne die Luft anzuhalten"),
        Exercise(id: "bauchatmung", name: "Bauchatmung", hint: "ruhig in den Bauch atmen, Rippen weit werden lassen"),
        Exercise(id: "stretching_seite", name: "Stretching in die Seite", hint: "links + rechts, Innenseiten der Oberschenkel dehnen – gern mehrfach am Tag"),
        Exercise(id: "hueftbeuger", name: "Streckung des Hüftbeugers", hint: "zuerst dehnen, als Vorbereitung – links und rechts"),
        Exercise(id: "liegestuetze", name: "Liegestütze"),
        Exercise(id: "planke", name: "Planke"),
        Exercise(id: "seitplanke", name: "Seitplanke", hint: "rechts und links"),
        Exercise(id: "kaefer", name: "Großer Käfer"),
        Exercise(id: "beinheben_bauch", name: "Beinheben in Bauchlage", hint: "aus der Hüfte, li + re – nicht aus dem Rücken"),
        Exercise(id: "kniebeugen", name: "Kniebeugen", hint: "Gewicht auf den Fersen, Knie über den Füßen, Rücken gerade"),
        Exercise(id: "beindrehen_seite", name: "Beindrehen in Seitenlage", hint: "Bein hinten nach oben drehen, mit Thera-Band"),
        Exercise(id: "schulterbruecke", name: "Schulterbrücke"),
        Exercise(id: "pilates", name: "Pilates Workout", isWorkout: true),
        Exercise(id: "cycling", name: "Indoor Cycling", hint: "extra – zählt nicht zum Tages-Soll", isWorkout: true, isOptional: true),
        Exercise(id: "gehen", name: "Nordic Walking / Wandern / strammes Gehen", hint: "mind. 30 Minuten – extra, zählt nicht zum Tages-Soll", isWorkout: true, isOptional: true),
    ]

    static let required: [Exercise] = exercises.filter { !$0.isOptional }

    /// Ab so vielen Übungen zählt der Tag als "gut" (70 % des Solls, aufgerundet)
    static let goodMin: Int = Int((Double(required.count) * 0.7).rounded(.up))

    static let factors: [Factor] = [
        Factor(id: "schmerzmittel", name: "Schmerzmittel genommen", short: "Schmerzmittel", icon: "💊", color: Color(hex: 0xE05D5D)),
        Factor(id: "voltaren", name: "Voltaren aufgetragen", short: "Voltaren", icon: "🧴", color: Color(hex: 0xE08A3C)),
        Factor(id: "physio", name: "Physio-Termin", short: "Physio", icon: "🧑‍⚕️", color: Color(hex: 0x4A90D9)),
        Factor(id: "anstrengend", name: "Anstrengender Tag, viel gestanden", short: "Viel gestanden", icon: "🦵", color: Color(hex: 0x9B6FC3)),
    ]

    static let months = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"]
    static let weekdays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
}

enum Theme {
    static let green = Color(hex: 0x26A077)
    static let greenDark = Color(hex: 0x1C7A5A)
    static let partial = Color(hex: 0xF0B429)
    static let chartLine = Color.adaptive(light: 0x3D7FC4, dark: 0x4E93DA)
    static let chartTrain = Color.adaptive(light: 0x26A077, dark: 0x2EA57F)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let line = Color(uiColor: .separator)
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(hex: UInt32) { self.init(uiColor: UIColor(hex: hex)) }

    /// Eigene Farbwerte für hellen und dunklen Modus
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}
