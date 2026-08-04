# RückenFit 💪

Eine ganz einfache App zum täglichen Abhaken Deiner Rücken-Übungen – als
**Progressive Web App (PWA)**, die Du direkt auf dem iPhone-Home-Bildschirm
installieren kannst. Kein App Store, kein Account, keine Kosten.

## Funktionen

- **Tägliche Übungsliste zum Abhaken:** Liegestütze, Planke, Seitplanke,
  Großer Käfer, Beinheben in Bauchlage, Beinheben in Seitenlage
  (Thera-Band), Beinheben nach hinten, Schulterbrücke, Streckung des
  Hüftbeugers – plus die Workouts
  Pilates und Indoor Cycling (Cycling zählt nicht zum Tages-Soll)
- **Tages-Notizen für die Rück-Analyse:** Schmerzmittel genommen,
  Physio-Termin, anstrengender Tag mit viel Stehen – erscheinen als
  farbige Punkte im Kalender und als Zähler in der Monatsstatistik
- **Gefühls-Skala 1–10:** Beim Öffnen der App wählst Du mit einem Tipp,
  wie es Dir körperlich (Rücken) gerade geht
- **Monatsübersicht:** Kalender, der zeigt, an welchen Tagen Du trainiert
  hast (grün = alles geschafft, gelb = teilweise) plus Dein Tages-Gefühl
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
  Frameworks, keine Abhängigkeiten
- `manifest.webmanifest` + `sw.js` (Service Worker) machen daraus eine
  installierbare, offline-fähige PWA
- Daten werden pro Tag unter dem Schlüssel `rueckenfit-v1` im
  localStorage gespeichert

## Lokal ausprobieren

```bash
python3 -m http.server 8000
# dann http://localhost:8000 im Browser öffnen
```
