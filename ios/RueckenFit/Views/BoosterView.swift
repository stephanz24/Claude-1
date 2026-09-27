import SwiftUI

/// Karte mit Muskel-Männchen, Level, Serie und Balken
struct BoosterCard: View {
    @Environment(Store.self) private var store

    private static let levelNames = ["Aufwärmen", "Auf dem Weg", "In Form", "Stark", "Booster-Modus 💪"]

    var body: some View {
        let booster = store.booster()
        let m = booster.fraction
        let name = booster.power >= Store.powerMax
            ? "Maximal-Booster 🔥"
            : Self.levelNames[min(4, Int(m * 5))]
        let hue = 15 + m * 115 // rot-orange -> grün

        Card(title: "Dein Booster") {
            HStack(spacing: 16) {
                BoosterFigure(fraction: m)
                    .frame(width: 96, height: 110)
                    .foregroundStyle(Theme.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(.headline)
                    Text(streakText(booster.streak))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 6)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.line)
                            Capsule()
                                .fill(barStyle(m: m, hue: hue, full: booster.power >= Store.powerMax))
                                .frame(width: geo.size.width * m)
                                .animation(.easeOut(duration: 0.4), value: m)
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text("0")
                        Spacer()
                        Text(powerText(booster.power) + " / 10")
                        Spacer()
                        Text("10")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)

            Text("Guter Tag = mindestens \(Catalog.goodMin) von \(Catalog.required.count) Übungen oder ein Pilates Workout (+1) · an schwächeren Tagen schrumpft der Muskel wieder – je weniger Übungen, desto stärker, ganz ohne Training −1 pro Tag")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 12)
        }
    }

    private func streakText(_ streak: Int) -> String {
        switch streak {
        case 0: return "Noch kein guter Tag in Folge – heute geht's los!"
        case 1: return "1 guter Tag in Folge"
        default: return "\(streak) gute Tage in Folge"
        }
    }

    private func powerText(_ power: Double) -> String {
        power == power.rounded() ? String(Int(power)) : power.germanOneDecimal
    }

    private func barStyle(m: Double, hue: Double, full: Bool) -> AnyShapeStyle {
        if full {
            return AnyShapeStyle(LinearGradient(colors: [Color(hue: 130 / 360, saturation: 0.55, brightness: 0.68), Color(hex: 0xF0B429)],
                                                startPoint: .leading, endPoint: .trailing))
        }
        return AnyShapeStyle(Color(hue: hue / 360, saturation: 0.6, brightness: 0.7))
    }
}

/// Das Männchen – gezeichnet wie in der Web-App, wächst mit dem Booster
struct BoosterFigure: View {
    let fraction: Double

    var body: some View {
        Canvas { context, size in
            let m = max(0, min(1, fraction))
            let sh = 11 + m * 19          // halbe Schulterbreite
            let waist = 8.5 + m * 7.5     // halbe Taille
            let armW = 2.8 + m * 7.7
            let bicepR = 2 + m * 8
            let legW = 4.5 + m * 7
            let scale = 0.74 + m * 0.36
            let flex = m >= 0.55          // ab "In Form" wird posiert
            let armY = flex ? 30.0 : 50.0
            let elbowX = sh + 11
            let fistX = flex ? sh + 9 : sh + 13

            // Zeichenfläche 122 x 120 (wie der SVG-viewBox "-11 0 122 120")
            let fit = min(size.width / 122, size.height / 120)
            let offsetX = (size.width - 122 * fit) / 2 + 11 * fit
            let offsetY = (size.height - 120 * fit) / 2
            let grow = CGAffineTransform(translationX: -50, y: -116)
                .concatenating(CGAffineTransform(scaleX: scale, y: scale))
                .concatenating(CGAffineTransform(translationX: 50, y: 116))
            let total = grow
                .concatenating(CGAffineTransform(scaleX: fit, y: fit))
                .concatenating(CGAffineTransform(translationX: offsetX, y: offsetY))
            context.concatenate(total)

            let color = GraphicsContext.Shading.color(Theme.green)
            // Schatten
            let rx = 20 + m * 10
            context.fill(Path(ellipseIn: CGRect(x: 50 - rx, y: 110, width: rx * 2, height: 8)),
                         with: .color(Theme.green.opacity(0.15)))
            // Kopf
            context.fill(Path(ellipseIn: CGRect(x: 41, y: 4, width: 18, height: 18)), with: color)
            // Rumpf
            var torso = Path()
            torso.move(to: CGPoint(x: 50 - sh, y: 27))
            torso.addQuadCurve(to: CGPoint(x: 50 + sh, y: 27), control: CGPoint(x: 50, y: 22 - m * 2))
            torso.addLine(to: CGPoint(x: 50 + waist, y: 72))
            torso.addLine(to: CGPoint(x: 50 - waist, y: 72))
            torso.closeSubpath()
            context.fill(torso, with: color)
            // Arme + Bizeps
            for sgn in [-1.0, 1.0] {
                var arm = Path()
                arm.move(to: CGPoint(x: 50 + sgn * (sh - 2), y: 31))
                arm.addLine(to: CGPoint(x: 50 + sgn * elbowX, y: 44))
                arm.addLine(to: CGPoint(x: 50 + sgn * fistX, y: armY))
                context.stroke(arm, with: color, style: StrokeStyle(lineWidth: armW, lineCap: .round, lineJoin: .round))
                let bx = 50 + sgn * (sh + 4)
                let by = flex ? 39.0 : 37.0
                context.fill(Path(ellipseIn: CGRect(x: bx - bicepR, y: by - bicepR, width: bicepR * 2, height: bicepR * 2)), with: color)
            }
            // Beine
            for sgn in [-1.0, 1.0] {
                var leg = Path()
                leg.move(to: CGPoint(x: 50 + sgn * (waist - 3), y: 70))
                leg.addLine(to: CGPoint(x: 50 + sgn * (waist + 1), y: 108))
                context.stroke(leg, with: color, style: StrokeStyle(lineWidth: legW, lineCap: .round))
            }
        }
    }
}
