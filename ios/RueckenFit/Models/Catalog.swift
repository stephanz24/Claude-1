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
        Exercise(id: "situps", name: "Sit-ups", hint: "langsam aufrollen, ohne Schwung – Hände an den Schläfen, nicht am Nacken ziehen"),
        Exercise(id: "beinheben_bauch", name: "Beinheben in Bauchlage", hint: "aus der Hüfte, li + re – nicht aus dem Rücken"),
        Exercise(id: "superman", name: "Superman", hint: "in Bauchlage Arme und Beine gleichzeitig leicht anheben, Blick zum Boden, Nacken lang"),
        Exercise(id: "kniebeugen", name: "Kniebeugen", hint: "Gewicht auf den Fersen, Knie über den Füßen, Rücken gerade"),
        Exercise(id: "beinpresse", name: "Beinpresse", hint: "Rücken und Becken fest an der Lehne, Knie nicht ganz durchstrecken"),
        Exercise(id: "beindrehen_seite", name: "Beindrehen in Seitenlage", hint: "Bein hinten nach oben drehen, mit Thera-Band"),
        Exercise(id: "schulterbruecke", name: "Schulterbrücke"),
        Exercise(id: "pilates", name: "Pilates Workout", isWorkout: true),
        Exercise(id: "cycling", name: "Indoor Cycling", hint: "extra – zählt nicht zum Tages-Soll", isWorkout: true, isOptional: true),
        Exercise(id: "gehen", name: "Nordic Walking / Wandern / strammes Gehen", hint: "mind. 30 Minuten – extra, zählt nicht zum Tages-Soll", isWorkout: true, isOptional: true),
    ]

    static let required: [Exercise] = exercises.filter { !$0.isOptional }

    /// Ab 10 Übungen zählt der Tag voll – fest, egal wie lang die Liste wird
    static let goodMin: Int = min(10, required.count)

    static let factors: [Factor] = [
        Factor(id: "schmerzmittel", name: "Schmerzmittel genommen", short: "Schmerzmittel", icon: "💊", color: Color(hex: 0xE05D5D)),
        Factor(id: "voltaren", name: "Voltaren aufgetragen", short: "Voltaren", icon: "🧴", color: Color(hex: 0xE08A3C)),
        Factor(id: "physio", name: "Physio-Termin", short: "Physio", icon: "🧑‍⚕️", color: Color(hex: 0x4A90D9)),
        Factor(id: "anstrengend", name: "Anstrengender Tag, viel gestanden", short: "Viel gestanden", icon: "🦵", color: Color(hex: 0x9B6FC3)),
    ]

    // MARK: Symbole – dieselben Zeichendaten wie in der Web-App (24 × 24)

    enum IconCategory {
        case mobil, dehnen, kraft, workout

        var color: Color {
            switch self {
            case .mobil: return Color(hex: 0x0A8FA9)
            case .dehnen: return Color(hex: 0x8459C4)
            case .kraft: return Color(hex: 0xD2602A)
            case .workout: return Color(hex: 0x3570C9)
            }
        }
    }

    struct IconSpec {
        let category: IconCategory
        let head: CGPoint
        let line: String
        var fill: String? = nil
    }

    static let icons: [String: IconSpec] = [
        "transversus": IconSpec(category: .mobil, head: CGPoint(x: 4.5, y: 14), line: "M6.5 15.5 L13.5 15.5 L16.5 11 L19.5 16 M11 6 L11 11.5 M9 9.8 L11 11.8 L13 9.8"),
        "bauchatmung": IconSpec(category: .mobil, head: CGPoint(x: 12, y: 5.5), line: "M12 8 L12 14 M7 17.5 Q12 12.5 17 17.5 M12 10 L8.5 13 M12 10 L15.5 13 M16.5 4.5 Q18 3 19.5 4.5 Q21 6 22.5 4.5 M16.5 7.5 Q18 6 19.5 7.5"),
        "stretching_seite": IconSpec(category: .dehnen, head: CGPoint(x: 9, y: 5), line: "M10 7.5 L12 14 L6.5 20 M12 14 L18.5 20 M10.5 9 Q14 3.5 18 5.5 M11 10 L8 13.5"),
        "hueftbeuger": IconSpec(category: .dehnen, head: CGPoint(x: 11, y: 4.5), line: "M11 7 L11 13 L15.5 13.5 L16 19.5 M11 13 L8 18.5 L3.5 18.5 M11 9 L13.5 11.5"),
        "liegestuetze": IconSpec(category: .kraft, head: CGPoint(x: 5.5, y: 9), line: "M8 11 L21 16.5 M8 11 L8 18 M21 16.5 L21 18"),
        "planke": IconSpec(category: .kraft, head: CGPoint(x: 5, y: 11.5), line: "M7.5 12.5 L21 15.5 M7.5 12.5 L8 16.5 L12 16.5 M21 15.5 L21 17"),
        "seitplanke": IconSpec(category: .kraft, head: CGPoint(x: 7, y: 6.5), line: "M8.5 9 L20.5 18.5 M8.5 10 L8.5 18.5 M9.5 10 L12.5 4"),
        "kaefer": IconSpec(category: .kraft, head: CGPoint(x: 4.5, y: 15), line: "M6.5 16 L14 16 M8.5 16 L8.5 8.5 M11 16 L11 9.5 M14 16 L17.5 11 L21 12.5"),
        "beinheben_bauch": IconSpec(category: .kraft, head: CGPoint(x: 5, y: 14.5), line: "M7 16.5 L14 16.5 L20.5 11.5 M3 17.5 L8 17.5"),
        "superman": IconSpec(category: .kraft, head: CGPoint(x: 7, y: 11.5), line: "M8.5 13.5 Q12 16 15.5 13.5 M8 13 L3 10 M15.5 13.5 L21 10.5", fill: "M10 14 L15 10 L14.5 13.5 Z"),
        "situps": IconSpec(category: .kraft, head: CGPoint(x: 9, y: 7.5), line: "M10 9.8 L12 16 L16.5 12 L19.5 16.5 M9.8 9.5 L7.5 7.5 L8.5 5.5 M3 18.5 L21 18.5"),
        "kniebeugen": IconSpec(category: .kraft, head: CGPoint(x: 10, y: 4.5), line: "M10.5 7 L12 12.5 L16 13.5 L15 19.5 M10.5 8.5 L16.5 8.5"),
        "beinpresse": IconSpec(category: .kraft, head: CGPoint(x: 6.5, y: 7.5), line: "M7.5 10 L10 15.5 L15 11.5 L18.5 7.5 M4 18.5 L7.5 9.5 M8 11.5 L11.5 11", fill: "M17 4.5 L18.5 3.5 L22.5 9 L21 10 Z"),
        "beindrehen_seite": IconSpec(category: .kraft, head: CGPoint(x: 4.5, y: 14.5), line: "M6.5 15.5 L14 16.5 L20.5 17.5 M14 16.5 L19 11.5 M17.5 7.5 Q21 7.5 21.5 11 M20 10 L21.5 11.5 L22.8 9.8"),
        "schulterbruecke": IconSpec(category: .kraft, head: CGPoint(x: 4, y: 16.5), line: "M6 17.5 L13 12 L17 13 L18 18.5 M7 18 L11.5 18.5"),
        "pilates": IconSpec(category: .workout, head: CGPoint(x: 8, y: 6.5), line: "M9 8.5 L12 15 L19.5 8.5 M9.5 10 L16 7 M5 17.5 L20 17.5"),
        "cycling": IconSpec(category: .workout, head: CGPoint(x: 14.5, y: 4.5), line: "M11 10 L15 7 M14.5 7.8 L17.5 9.5 M11 10 L14 13.5 L14 17 M9 10 L13 10 M17.5 9.5 L17 12 M8 19.5 L20 19.5 M17 15 Q20 15 20 17.5 Q20 19.5 17 19.5 Q14 19.5 14 17.5 Q14 15 17 15"),
        "gehen": IconSpec(category: .workout, head: CGPoint(x: 12, y: 4.5), line: "M12 7 L11 13 L8 19.5 M11 13 L15 19.5 M12 8.5 L15.5 11.5 M12 8.5 L8.5 10.5 M15.5 11.5 L19 20"),
    ]

    // MARK: Serien-Belohnung

    /// Übungen, die es früher gab – für die Gesamt-Statistik
    static let legacyExercises: [(id: String, name: String)] = [
        ("beinheben_seite", "Beinheben in Seitenlage"),
        ("beinheben_hinten", "Beinheben nach hinten"),
    ]

    static let categoryLegend: [(label: String, category: IconCategory)] = [
        ("Mobilisieren", .mobil), ("Dehnen", .dehnen), ("Kräftigen", .kraft), ("Workout", .workout),
    ]

    static let milestones: [Int] = [3, 5, 7, 10, 14, 21, 30, 50, 75, 100, 150, 200, 365]

    static let milestoneTitles: [Int: String] = [
        3: "Dranbleiber", 5: "Gewohnheitstier", 7: "Wochen-Held", 10: "Zehner-Serie",
        14: "Zwei-Wochen-Profi", 21: "Drei-Wochen-Champion", 30: "Monats-Legende",
        50: "Halbes Hundert", 75: "Unaufhaltsam", 100: "Hunderter-Club",
        150: "Eiserner Wille", 200: "Rücken aus Stahl", 365: "Jahres-Legende",
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
