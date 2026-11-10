# RückenFit 💪

Eine ganz einfache App zum täglichen Abhaken Deiner Rücken-Übungen – als
**Progressive Web App (PWA)**, die Du direkt auf dem iPhone-Home-Bildschirm
installieren kannst. Kein App Store, kein Account, keine Kosten.

## Funktionen

- **Tägliche Übungsliste zum Abhaken:** Transversus aktivieren und
  Bauchatmung (zuerst), Stretching in die Seite (li + re, Innenseiten
  der Oberschenkel), Streckung des Hüftbeugers (Dehnung), Liegestütze,
  Planke, Seitplanke, Großer Käfer, Sit-ups, Beinheben in Bauchlage, Superman,
  Kniebeugen, Beinpresse, Beindrehen in Seitenlage (Thera-Band), Schulterbrücke – plus
  die Workouts
  Pilates, Indoor Cycling und Nordic Walking / Wandern / strammes Gehen
  (mind. 30 Minuten) – Cycling und Gehen zählen als Extra nicht zum
  Tages-Soll
- **Booster-Anzeige:** Ein Muskel-Männchen, das mit jedem guten
  Trainingstag (mind. 10 Übungen oder ein Pilates Workout) wächst
  und stärker wird – mit farbigem Booster-Balken (0–10) und
  Serien-Zähler. Jeder Tag zählt: An schwächeren Tagen schrumpft der
  Muskel wieder, und zwar umso stärker, je weniger Übungen geschafft
  wurden (ein Tag ganz ohne Training kostet einen vollen Punkt)
- **Symbole und Serien:** Jede Übung hat ein eigenes Symbol, farbig nach
  Mobilisieren, Dehnen, Kräftigen und Workout. Eine Flamme zeigt, wie
  viele Tage am Stück eine Übung gemacht wurde (⏳ = heute noch
  fortsetzen). Bei 3, 5, 7, 10, 14, 21, 30 … Tagen gibt es eine Feier mit
  Konfetti und einem Titel wie „Wochen-Held“
- **Tage nachtragen:** In der Monatsübersicht einen beliebigen Tag
  antippen – dort lassen sich Übungen, Gefühls-Wert und Notizen
  rückwirkend eintragen und jederzeit wieder ändern
- **Tages-Notizen für die Rück-Analyse:** Schmerzmittel genommen,
  Voltaren aufgetragen, Physio-Termin, anstrengender Tag mit viel
  Stehen – erscheinen als farbige Punkte im Kalender und als Zähler in
  der Monatsstatistik
- **Gefühls-Skala 1–10:** Beim Öffnen der App wählst Du mit einem Tipp,
  wie es Dir körperlich (Rücken) gerade geht
- **Monatsübersicht:** Kalender, der zeigt, an welchen Tagen Du trainiert
  hast (grün = alles geschafft, gelb = teilweise) plus Dein Tages-Gefühl
- **Verlaufs-Diagramm:** Zeigt den Gefühls-Wert als Kurve – wahlweise
  Tag für Tag im gewählten Monat oder als Monats-Durchschnitt über die
  letzten zwölf Monate. Darunter ein Streifen, der pro Tag anzeigt, wie
  viele Übungen geschafft wurden (je dunkler, desto mehr); Antippen oder
  Wischen zeigt die Werte des einzelnen Tages
- **Übungen im Überblick:** In der Web-App eine Übungs-Spirale (D3.js):
  ein leuchtender Strahl pro Übung, im Uhrzeigersinn nach Häufigkeit
  sortiert. Alle Strahlen sind gleich dick, nur die Länge zeigt den Wert
  (linear, mit Messringen bei 25/50/75/100 % der Tage); außen stehen
  Symbol und genaue Anzahl. Antippen zeigt in der Mitte Name, Anzahl,
  Anteil und Platz. Darunter die genaue Liste zum Aufklappen. Umschaltbar
  zwischen angezeigtem Monat und insgesamt. In der iPhone-App als
  Balkendiagramm
- **Statistik:** Tage komplett, Tage trainiert, durchschnittliches Gefühl
- **Offline-fähig:** Funktioniert auch ohne Internet, alle Daten bleiben
  lokal auf Deinem iPhone (localStorage) – nichts wird irgendwohin gesendet

## So bekommst Du die App aufs iPhone

1. **Veröffentlichen über GitHub Pages** (einmalig):
   - Diesen Branch in den Standard-Branch (z. B. `main`) mergen
   - Im Repository auf GitHub: **Settings → Pages → Source: „Deploy from a
     branch"**, Branch `main`, Ordner `/ (root)` wählen und speichern
   - Hinweis: Bei einem privaten Repository braucht GitHub Pages einen
     Bezahl-Plan – alternativ das Repository öffentlich machen (die App
     enthält keine persönlichen Daten, Deine Einträge bleiben nur auf dem
     Handy) oder einen kostenlosen Host wie Netlify/Vercel nutzen
2. **Auf dem iPhone installieren:**
   - Die GitHub-Pages-Adresse (z. B.
     `https://stephanz24.github.io/Claude-1/`) in **Safari** öffnen
   - Auf das **Teilen-Symbol** (Quadrat mit Pfeil nach oben) tippen
   - **„Zum Home-Bildschirm"** wählen und bestätigen
   - Fertig – die App liegt mit eigenem Icon auf dem Home-Bildschirm und
     öffnet sich wie eine normale App im Vollbild

## Technik

- Eine einzige `index.html` mit HTML, CSS und JavaScript – keine
  Frameworks; einzige Bibliothek ist D3.js für die Übungs-Spirale
- `manifest.webmanifest` + `sw.js` (Service Worker) machen daraus eine
  installierbare, offline-fähige PWA
- `vendor/d3.v7.min.js`: D3.js 7.9.2 (ISC-Lizenz, siehe
  `vendor/d3-LICENSE.txt`) liegt lokal in der App und wird vom Service
  Worker zwischengespeichert, damit die Spirale auch offline funktioniert
- Daten werden pro Tag unter dem Schlüssel `rueckenfit-v1` im
  localStorage gespeichert

## Lokal ausprobieren

```bash
python3 -m http.server 8000
# dann http://localhost:8000 im Browser öffnen
```
