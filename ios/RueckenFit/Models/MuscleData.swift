import Foundation

// Automatisch aus der Web-App (index.html, Abschnitt Muskel-Karte) übernommen,
// damit beide Apps gleich rechnen und zeichnen.

struct Muscle: Identifiable, Hashable {
    let id: String
    let name: String
}

enum Muscles {
    static let all: [Muscle] = [
        Muscle(id: "schultern", name: "Schultern"),
        Muscle(id: "brust", name: "Brust"),
        Muscle(id: "arme", name: "Arme (Trizeps)"),
        Muscle(id: "bauch", name: "Gerader Bauch"),
        Muscle(id: "schraeg", name: "Seitliche Bauchmuskeln"),
        Muscle(id: "tiefbauch", name: "Tiefe Bauchmuskeln"),
        Muscle(id: "hueftbeuger", name: "Hüftbeuger"),
        Muscle(id: "quadrizeps", name: "Oberschenkel vorne"),
        Muscle(id: "adduktoren", name: "Oberschenkel innen"),
        Muscle(id: "waden", name: "Waden"),
        Muscle(id: "oberer_ruecken", name: "Oberer Rücken"),
        Muscle(id: "unterer_ruecken", name: "Unterer Rücken"),
        Muscle(id: "huefte_aussen", name: "Hüfte außen"),
        Muscle(id: "gesaess", name: "Gesäß"),
        Muscle(id: "beinrueckseite", name: "Oberschenkel hinten"),
    ]

    /// Was jede Übung trainiert: 1 = Hauptarbeit, 0,5 = hilft mit, 0,3 = wird gedehnt
    static let map: [String: [String: Double]] = [
        "transversus": ["tiefbauch": 1.0],
        "bauchatmung": ["tiefbauch": 0.5],
        "stretching_seite": ["adduktoren": 0.3, "schraeg": 0.3],
        "hueftbeuger": ["hueftbeuger": 0.3],
        "liegestuetze": ["brust": 1.0, "arme": 1.0, "schultern": 0.5, "bauch": 0.5],
        "planke": ["bauch": 1.0, "tiefbauch": 1.0, "schultern": 0.5, "schraeg": 0.5, "gesaess": 0.3],
        "seitplanke": ["schraeg": 1.0, "huefte_aussen": 0.5, "tiefbauch": 0.5, "schultern": 0.5],
        "kaefer": ["tiefbauch": 1.0, "bauch": 0.5, "hueftbeuger": 0.5],
        "situps": ["bauch": 1.0, "hueftbeuger": 0.5, "schraeg": 0.5],
        "beinheben_bauch": ["gesaess": 1.0, "beinrueckseite": 0.5, "unterer_ruecken": 0.5],
        "superman": ["unterer_ruecken": 1.0, "oberer_ruecken": 1.0, "gesaess": 0.5, "schultern": 0.5],
        "kniebeugen": ["quadrizeps": 1.0, "gesaess": 1.0, "beinrueckseite": 0.5, "adduktoren": 0.5, "waden": 0.3, "unterer_ruecken": 0.3],
        "beinpresse": ["quadrizeps": 1.0, "gesaess": 0.5, "beinrueckseite": 0.3, "waden": 0.3],
        "adduktoren": ["adduktoren": 1.0],
        "abduktoren": ["huefte_aussen": 1.0, "gesaess": 0.5],
        "beindrehen_seite": ["huefte_aussen": 1.0, "gesaess": 0.5],
        "schulterbruecke": ["gesaess": 1.0, "beinrueckseite": 1.0, "unterer_ruecken": 0.5],
        "pilates": ["tiefbauch": 1.0, "bauch": 1.0, "schraeg": 0.5, "unterer_ruecken": 0.5, "gesaess": 0.5, "huefte_aussen": 0.3, "adduktoren": 0.3, "schultern": 0.3],
        "cycling": ["quadrizeps": 1.0, "waden": 0.5, "gesaess": 0.5, "beinrueckseite": 0.5, "hueftbeuger": 0.3],
        "gehen": ["waden": 1.0, "gesaess": 0.5, "quadrizeps": 0.5, "beinrueckseite": 0.5, "hueftbeuger": 0.3, "schultern": 0.3, "arme": 0.3],
        "beinheben_hinten": ["gesaess": 1.0, "beinrueckseite": 0.5],
        "beinheben_seite": ["huefte_aussen": 1.0, "gesaess": 0.5],
    ]

    static let recentDays = 14
    static let longDays = undefined
    static let good = undefined
    static let some = undefined

    /// Körper: nur linke Bildhälfte (x < 50), wird an x = 50 gespiegelt
    static let bodyBase: [String] = [
        "M50 3 Q40 3 39.5 15 Q40 26 46 28 L46 35 L50 35 Z",
        "M50 33 L50 126 L33.5 126 Q32 116 35 104 Q34 86 32.5 66 Q28 61 25 62 Q21 54 23.5 44 Q28 38 42 34.5 Z",
        "M24 44 Q19 48 19 60 Q17 74 17 88 Q14.5 104 13.5 122 Q11 128 12 138 Q14 141 16.5 138 Q17 130 18.5 123 Q23 106 25 90 Q29 74 30 60 Z",
        "M33.5 118 Q31 140 33.5 166 Q33.5 188 36.5 208 L34 217 Q40 219 46 217 L45 206 Q47.5 188 46 168 Q48.6 146 48.6 126 L50 122 L50 118 Z",
    ]
    static let front: [(id: String, d: String)] = [
        ("schultern", "M30 40 Q22.5 41 21.5 51 Q21.5 58 24.5 62 Q28 52 34.5 47 Q34 42 30 40 Z"),
        ("brust", "M36 44.5 Q43 42.5 49.3 44.5 L49.3 61 Q41 66 34 61.5 Q31 54 36 44.5 Z"),
        ("arme", "M22.5 64 Q26 60.5 29.2 62.5 Q29.5 75 26.5 87 Q22.5 89 19.8 86.5 Q19.3 74 22.5 64 Z"),
        ("bauch", "M43.2 64.5 Q46.5 63.5 49.3 64 L49.3 95 Q46 96.5 43.2 95 Z"),
        ("schraeg", "M34.3 65 Q38.5 63.5 41.8 66.5 L41.8 95 Q38.5 99 35.3 104 Q33.6 88 34.3 65 Z"),
        ("tiefbauch", "M38 101 Q43 97.5 49.3 97.5 L49.3 110.5 Q43 111 39.5 108 Z"),
        ("hueftbeuger", "M35.6 108 Q39.5 110.5 45 113.5 L43.6 124 Q38.8 120.5 35 115 Z"),
        ("quadrizeps", "M34.6 121 Q39 118.5 43.2 126 Q45.6 145 43.8 163 Q39.5 167 36 162.5 Q33 143 34.6 121 Z"),
        ("adduktoren", "M44.6 118.5 Q47.6 120 48.2 123.5 Q48 138 46.6 151 Q45 152 44.6 147 Q45.4 133 44.6 118.5 Z"),
        ("waden", "M36.2 172 Q40 168.5 42.6 172.5 Q43.8 187 41 201 Q37.8 200 36.8 189 Q35.4 179 36.2 172 Z"),
    ]
    static let back: [(id: String, d: String)] = [
        ("oberer_ruecken", "M45 30 L49.3 29.5 L49.3 69 Q43 61 37.5 50.5 Q34 45 30.5 42.5 Q38.5 38.5 45 30 Z"),
        ("schultern", "M30 40 Q22.5 41 21.5 51 Q21.5 58 24.5 62 Q28 52 34.5 47 Q34 42 30 40 Z"),
        ("arme", "M22.5 64 Q26 60.5 29.2 62.5 Q29.5 75 26.5 87 Q22.5 89 19.8 86.5 Q19.3 74 22.5 64 Z"),
        ("oberer_ruecken", "M34 53 Q38.5 60.5 42.3 70 L42.3 88 Q37.5 90.5 34.3 85 Q32 69 34 53 Z"),
        ("unterer_ruecken", "M43.6 72 Q46 72.5 49.3 73 L49.3 104 Q46 105.5 43.4 103 Q42.8 88 43.6 72 Z"),
        ("huefte_aussen", "M34.3 92 Q38.5 91.5 42 95.5 L41.6 104 Q37.5 104.5 34.6 108 Q33.4 100 34.3 92 Z"),
        ("gesaess", "M35 110 Q42 104.5 49.3 108 L49.3 127 Q42 133 35.3 128 Q32.6 118 35 110 Z"),
        ("beinrueckseite", "M35.2 134 Q41.5 136.5 47.6 134 Q47.6 150 45.4 162 Q40.5 165.5 37 162 Q33.8 148 35.2 134 Z"),
        ("waden", "M36.2 170 Q41 166 45 170 Q46 182 43 194 Q39.2 196 37.4 192 Q34.6 181 36.2 170 Z"),
    ]
    static let sixpack = "M43.2 74.5 L49.3 74.5 M43.2 84.5 L49.3 84.5"
}
