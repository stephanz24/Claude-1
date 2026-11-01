import SwiftUI

/// Liest die einfachen SVG-Pfade der Symbole (nur absolute M, L, Q, C, Z)
enum SVGPath {
    static func parse(_ d: String) -> Path {
        var tokens: [String] = []
        var current = ""
        for ch in d {
            if ch.isLetter {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(ch))
            } else if ch == " " || ch == "," {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else if ch == "-" && !current.isEmpty {
                tokens.append(current)
                current = "-"
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { tokens.append(current) }

        var path = Path()
        var i = 0
        var command: Character = "M"

        func number() -> CGFloat {
            guard i < tokens.count else { return 0 }
            let value = CGFloat(Double(tokens[i]) ?? 0)
            i += 1
            return value
        }
        func point() -> CGPoint {
            let x = number()
            let y = number()
            return CGPoint(x: x, y: y)
        }

        while i < tokens.count {
            if let first = tokens[i].first, first.isLetter {
                command = first
                i += 1
                if command == "Z" {
                    path.closeSubpath()
                    continue
                }
            }
            switch command {
            case "M":
                path.move(to: point())
                command = "L"
            case "L":
                path.addLine(to: point())
            case "Q":
                let control = point()
                path.addQuadCurve(to: point(), control: control)
            case "C":
                let c1 = point()
                let c2 = point()
                path.addCurve(to: point(), control1: c1, control2: c2)
            default:
                i += 1
            }
        }
        return path
    }
}

/// Rundes Übungs-Symbol mit Kategorie-Farbe
struct ExerciseIcon: View {
    let id: String
    var size: CGFloat = 34

    private struct Shapes {
        let line: Path
        let fill: Path?
    }

    private static let shapes: [String: Shapes] = Catalog.icons.mapValues { spec in
        Shapes(line: SVGPath.parse(spec.line), fill: spec.fill.map(SVGPath.parse))
    }

    var body: some View {
        if let spec = Catalog.icons[id], let shapes = Self.shapes[id] {
            Canvas { ctx, canvasSize in
                ctx.fill(Path(ellipseIn: CGRect(origin: .zero, size: canvasSize)), with: .color(spec.category.color))
                let unit = canvasSize.width / 24
                ctx.scaleBy(x: unit, y: unit)
                ctx.translateBy(x: 1.68, y: 1.68)
                ctx.scaleBy(x: 0.86, y: 0.86)
                if let fill = shapes.fill {
                    ctx.fill(fill, with: .color(.white.opacity(0.9)))
                }
                ctx.stroke(shapes.line, with: .color(.white),
                           style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round))
                let head = CGRect(x: spec.head.x - 2.1, y: spec.head.y - 2.1, width: 4.2, height: 4.2)
                ctx.fill(Path(ellipseIn: head), with: .color(.white))
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
        }
    }
}
