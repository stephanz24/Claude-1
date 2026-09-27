# RückenFit als native iPhone-App

Dieser Ordner enthält die App als natives Xcode-Projekt (Swift / SwiftUI,
ab iOS 17). Sie hat denselben Funktionsumfang wie die Web-App im
Hauptordner – Übungen abhaken, Booster, Kalender mit Nachtragen,
Verlaufs-Diagramm, Notizen – und zusätzlich eine tägliche Erinnerung.

## Auf dem eigenen iPhone installieren (ohne Developer-Konto)

Voraussetzungen: ein Mac mit **Xcode 16 oder neuer** (kostenlos im Mac App
Store), ein iPhone mit iOS 17 oder neuer, ein Ladekabel und eine Apple-ID.

1. Repository auf den Mac holen (z. B. auf GitHub „Code → Download ZIP“
   oder `git clone`).
2. `ios/RueckenFit.xcodeproj` doppelklicken – Xcode öffnet das Projekt.
3. **Apple-ID hinterlegen:** Xcode → Settings → Accounts → „+“ → Apple ID.
   Ein kostenloses Konto genügt; Xcode legt daraus ein „Personal Team“ an.
4. Links im Projektbaum ganz oben auf **RueckenFit** klicken → Reiter
   **Signing & Capabilities** → bei **Team** das Personal Team wählen.
   Erscheint eine Meldung, der Bundle Identifier sei bereits vergeben,
   einfach am Ende etwas anhängen, z. B. `de.stephanzabel.rueckenfit2`.
5. iPhone per Kabel anschließen, auf dem iPhone „Diesem Computer
   vertrauen“ bestätigen. Beim ersten Mal muss der **Entwicklermodus**
   eingeschaltet werden: iPhone-Einstellungen → Datenschutz & Sicherheit →
   Entwicklermodus → ein (Neustart).
6. Oben in Xcode neben dem Play-Knopf das iPhone als Ziel auswählen und
   **Run** (⌘R) drücken. Xcode baut die App und installiert sie.
7. Beim ersten Start blockt iOS: Einstellungen → Allgemein →
   VPN & Geräteverwaltung → die eigene Apple-ID antippen → **Vertrauen**.
   Danach startet die App normal vom Home-Bildschirm.

**Wichtig bei der kostenlosen Signatur:** Die App läuft **7 Tage**, dann
verweigert iOS den Start, bis sie über Xcode erneut installiert wird (Schritt
6 wiederholen – die Daten bleiben erhalten). Mit einem Developer-Konto
(99 €/Jahr) entfällt diese Grenze.

## Daten aus der Web-App übernehmen

In der Web-App unter **Übersicht → Daten exportieren** tippen (kopiert alle
Einträge in die Zwischenablage), dann in der iPhone-App unter
**Mehr → Aus der Web-App übernehmen → Aus der Zwischenablage einfügen →
Importieren**.

## Aufbau

```
ios/
  RueckenFit.xcodeproj/        Xcode-Projekt (Ordner-synchronisiert – neue
                               Dateien im Ordner RueckenFit werden automatisch Teil der App)
  RueckenFit/
    RueckenFitApp.swift        Einstieg, Tabs
    Models/Catalog.swift       Übungen, Notizen, Farben
    Models/DayEntry.swift      Ein Tag; Datums-Schlüssel "yyyy-MM-dd"
    Models/Store.swift         Speichern (JSON), Booster-Rechnung, Import/Export
    Views/TodayView.swift      Heute
    Views/BoosterView.swift    Booster-Karte und Muskel-Männchen (Canvas)
    Views/OverviewView.swift   Kalender, Statistik
    Views/DayEditorView.swift  Nachtragen eines Tages
    Views/TrendChartView.swift Verlaufs-Diagramm (Swift Charts)
    Views/SettingsView.swift   Erinnerung, Import/Export, Löschen
    Reminders.swift            Tägliche Mitteilung (lokal, ohne Server)
```

Das Datenformat der gespeicherten Datei entspricht dem der Web-App, damit
Exporte in beide Richtungen funktionieren.

## Automatischer Build

`.github/workflows/ios-build.yml` übersetzt die App bei jedem Push auf
einem macOS-Runner für den Simulator – ohne Signatur, nur als
Übersetzungs-Prüfung.
