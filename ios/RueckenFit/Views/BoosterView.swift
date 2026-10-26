import SwiftUI

/// Karte mit Comic-Männchen, Level, Serie, Balken und Trend
struct BoosterCard: View {
    @Environment(Store.self) private var store

    private static let levelNames = ["Schlappi 😮‍💨", "Aufgewacht", "In Form", "Kraftpaket", "Booster-Modus 💪"]

    var body: some View {
        let booster = store.booster()
        let m = booster.fraction
        let name = booster.isMax ? "Maximal-Booster 🔥" : Self.levelNames[booster.stage]
        let hue = 15 + m * 115 // rot-orange -> grün

        Card(title: "Dein Booster") {
            HStack(spacing: 16) {
                ComicBoosterFigure(fraction: m, stage: booster.stage, isMax: booster.isMax)
                    .frame(width: 124, height: 132)

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
                                .fill(barStyle(hue: hue, full: booster.isMax))
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

                    trendText(booster)
                        .font(.caption.weight(.semibold))
                        .padding(.top, 4)
                }
            }
            .padding(.top, 8)

            Text("Der Booster zeigt, wie regelmäßig Du in den letzten zwei Wochen trainiert hast – die letzten Tage zählen am meisten. \(Catalog.goodMin) von \(Catalog.required.count) Übungen oder Pilates = voller Tag, weniger zählt anteilig, Indoor Cycling und Gehen geben einen Bonus. Pausen lassen den Muskel schrumpfen.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 12)
        }
    }

    private func streakText(_ streak: Int) -> String {
        switch streak {
        case 0: return "Noch kein voller Tag in Folge – heute geht's los!"
        case 1: return "1 voller Tag in Folge"
        default: return "\(streak) volle Tage in Folge"
        }
    }

    private func powerText(_ power: Double) -> String {
        power == power.rounded() ? String(Int(power)) : power.germanOneDecimal
    }

    @ViewBuilder
    private func trendText(_ b: Store.Booster) -> some View {
        if b.todayGain > 0 {
            Text("▲ " + b.todayGain.germanOneDecimal + " durch heute").foregroundStyle(Theme.green)
        } else if b.yesterdayChange > 0 {
            Text("▲ " + b.yesterdayChange.germanOneDecimal + " durch gestern").foregroundStyle(Theme.green)
        } else if b.yesterdayChange < 0 {
            Text("▼ " + abs(b.yesterdayChange).germanOneDecimal + " durch gestern – heute zurückholen!")
                .foregroundStyle(Color(hex: 0xD0613C))
        } else {
            Text("unverändert seit gestern").foregroundStyle(.secondary)
        }
    }

    private func barStyle(hue: Double, full: Bool) -> AnyShapeStyle {
        if full {
            return AnyShapeStyle(LinearGradient(colors: [Color(hue: 130 / 360, saturation: 0.55, brightness: 0.68), Color(hex: 0xF0B429)],
                                                startPoint: .leading, endPoint: .trailing))
        }
        return AnyShapeStyle(Color(hue: hue / 360, saturation: 0.6, brightness: 0.7))
    }
}

/// Das animierte Comic-Männchen – gleiche Zeichnung wie in der Web-App
struct ComicBoosterFigure: View {
    let fraction: Double
    let stage: Int
    let isMax: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let renderer = ComicFigureRenderer(
                    m: CGFloat(min(1, max(0, fraction))),
                    stage: min(4, max(0, stage)),
                    isMax: isMax,
                    t: t,
                    dark: colorScheme == .dark
                )
                renderer.draw(in: &context, size: size)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Zeichnet das Männchen auf einer Fläche von 160 × 170 Punkten
struct ComicFigureRenderer {
    let m: CGFloat
    let stage: Int
    let isMax: Bool
    let t: Double
    let dark: Bool

    static let ink = Color(hex: 0x15261F)
    static let skin = Color(hex: 0x46C793)
    static let band = Color(hex: 0xE5484D)
    static let shorts = Color(hex: 0x2F62C0)
    static let gold = Color(hex: 0xF5B82E)
    static let mouth = Color(hex: 0x7A1F2B)
    static let tongue = Color(hex: 0xFF8A95)
    static let cheek = Color(hex: 0xFF7B8A)
    static let drop = Color(hex: 0x8FD3FF)
    static let rim = Color(hex: 0xE8EFEC)

    let cx: CGFloat = 80
    let shY: CGFloat = 76
    let waistY: CGFloat = 118
    let headR: CGFloat = 23
    let headCY: CGFloat = 49

    var sh: CGFloat { 17 + m * 19 }
    var waist: CGFloat { 12 + m * 5 }
    var armW: CGFloat { 6 + m * 7 }
    var legW: CGFloat { 9 + m * 6 }
    var tired: Bool { stage == 0 }

    // MARK: - Zeit

    /// Bruchteil der aktuellen Periode, 0 … 1
    func phase(_ period: Double, delay: Double = 0) -> Double {
        let p = (t - delay) / period
        return p - p.rounded(.down)
    }

    /// Sanftes Hin und Her 0 … 1 … 0 – wie CSS ease-in-out
    func wave(_ period: Double, delay: Double = 0) -> CGFloat {
        CGFloat(0.5 - 0.5 * cos(phase(period, delay: delay) * 2 * Double.pi))
    }

    // MARK: - Helfer

    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    func circle(_ c: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    }

    func ellipse(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2))
    }

    func line(_ a: CGPoint, _ b: CGPoint) -> Path {
        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        return p
    }

    func quad(_ a: CGPoint, _ control: CGPoint, _ b: CGPoint) -> Path {
        var p = Path()
        p.move(to: a)
        p.addQuadCurve(to: b, control: control)
        return p
    }

    func round(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }

    func rotate(_ c: inout GraphicsContext, degrees: Double, around p: CGPoint) {
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .degrees(degrees))
        c.translateBy(x: -p.x, y: -p.y)
    }

    func scale(_ c: inout GraphicsContext, x: CGFloat, y: CGFloat, around p: CGPoint) {
        c.translateBy(x: p.x, y: p.y)
        c.scaleBy(x: x, y: y)
        c.translateBy(x: -p.x, y: -p.y)
    }

    /// Comic-Strich: dunkle Kontur, darüber die Füllfarbe
    func comicStroke(_ c: inout GraphicsContext, _ path: Path, width: CGFloat) {
        c.stroke(path, with: .color(Self.ink), style: round(width + 5))
        c.stroke(path, with: .color(Self.skin), style: round(width))
    }

    func fillAndOutline(_ c: inout GraphicsContext, _ path: Path, fill: Color, width: CGFloat) {
        c.fill(path, with: .color(fill))
        c.stroke(path, with: .color(Self.ink), style: round(width))
    }

    // MARK: - Zeichnen

    func draw(in context: inout GraphicsContext, size: CGSize) {
        let fit = min(size.width / 160, size.height / 170)
        context.translateBy(x: (size.width - 160 * fit) / 2, y: (size.height - 170 * fit) / 2)
        context.scaleBy(x: fit, y: fit)
        context.clip(to: Path(CGRect(x: 0, y: 0, width: 160, height: 170)))

        if isMax { drawRays(&context) }
        drawShadow(&context)

        context.drawLayer { layer in
            if dark {
                // Heller Sticker-Rand, damit die dunkle Kontur im Dunkelmodus sichtbar bleibt
                for (dx, dy) in [(1.6, 0.0), (-1.6, 0.0), (0.0, 1.6), (0.0, -1.6)] {
                    layer.addFilter(.shadow(color: Self.rim, radius: 0.3, x: dx, y: dy))
                }
            }
            drawFigure(&layer)
        }

        if stage >= 3 { drawSparkles(&context) }
        if isMax { drawPow(&context) }
    }

    func drawRays(_ c: inout GraphicsContext) {
        c.drawLayer { l in
            rotate(&l, degrees: phase(14) * 360, around: pt(80, 88))
            var rays = Path()
            for i in 0..<12 {
                let a = Double(i) / 12 * 2 * Double.pi
                let b = a + Double.pi / 12
                rays.move(to: pt(80, 88))
                rays.addLine(to: pt(80 + CGFloat(cos(a)) * 120, 88 + CGFloat(sin(a)) * 120))
                rays.addLine(to: pt(80 + CGFloat(cos(b)) * 120, 88 + CGFloat(sin(b)) * 120))
                rays.closeSubpath()
            }
            let fade = Gradient(colors: [Self.gold.opacity(0.55), Self.gold.opacity(0)])
            l.fill(rays, with: .radialGradient(fade, center: pt(80, 88), startRadius: 0, endRadius: 84))
        }
    }

    func drawShadow(_ c: inout GraphicsContext) {
        c.drawLayer { l in
            scale(&l, x: 1 - 0.12 * wave(1.6), y: 1, around: pt(80, 161))
            let shade = dark ? Color.black.opacity(0.35) : Self.ink.opacity(0.14)
            l.fill(ellipse(pt(80, 161), 26 + m * 12, 5), with: .color(shade))
        }
    }

    func drawFigure(_ c: inout GraphicsContext) {
        c.drawLayer { l in
            if tired {
                rotate(&l, degrees: 2.5 * sin(phase(3.4) * 2 * Double.pi), around: pt(80, 158))
            } else {
                l.translateBy(x: 0, y: -4 * wave(1.6))
            }
            drawLegs(&l)
            drawTorso(&l)
            drawShorts(&l)
            drawArms(&l)
            drawHead(&l)
            if tired { drawDrop(&l) }
        }
    }

    func drawLegs(_ c: inout GraphicsContext) {
        for s in [CGFloat(-1), CGFloat(1)] {
            let x1 = cx + s * (waist - 5)
            let x2 = cx + s * (waist - 3 + (tired ? 2 : 0))
            comicStroke(&c, line(pt(x1, waistY + 10), pt(x2, 150)), width: legW)
            let shoeX = x2 + s * 3
            fillAndOutline(&c, ellipse(pt(shoeX, 153), 10 + m * 2, 5.5), fill: .white, width: 3)
            c.stroke(line(pt(shoeX - 5, 151), pt(shoeX + 5, 151)), with: .color(Self.band), style: round(2.4))
        }
    }

    func drawTorso(_ c: inout GraphicsContext) {
        let neckTop = shY - 6 - m * 4
        var torso = Path()
        torso.move(to: pt(cx - sh, shY + 4))
        torso.addQuadCurve(to: pt(cx + sh, shY + 4), control: pt(cx, neckTop))
        torso.addQuadCurve(to: pt(cx + waist, waistY), control: pt(cx + sh + 1, shY + 18))
        torso.addLine(to: pt(cx - waist, waistY))
        torso.addQuadCurve(to: pt(cx - sh, shY + 4), control: pt(cx - sh - 1, shY + 18))
        torso.closeSubpath()
        fillAndOutline(&c, torso, fill: Self.skin, width: 3.5)

        let detail = GraphicsContext.Shading.color(Self.ink.opacity(0.55))
        if m > 0.3 {
            let pw = sh * 0.72
            c.stroke(quad(pt(cx - pw, shY + 14), pt(cx - pw / 2, shY + 23), pt(cx - 2, shY + 15)), with: detail, style: round(2.2))
            c.stroke(quad(pt(cx + pw, shY + 14), pt(cx + pw / 2, shY + 23), pt(cx + 2, shY + 15)), with: detail, style: round(2.2))
        }
        if m > 0.6 {
            var abs = line(pt(cx, shY + 24), pt(cx, waistY - 5))
            for y in [waistY - 27, waistY - 17] {
                abs.move(to: pt(cx - 9, y + 1))
                abs.addQuadCurve(to: pt(cx - 2.5, y), control: pt(cx - 5.5, y - 1.5))
                abs.move(to: pt(cx + 9, y + 1))
                abs.addQuadCurve(to: pt(cx + 2.5, y), control: pt(cx + 5.5, y - 1.5))
            }
            c.stroke(abs, with: detail, style: round(1.8))
        }
        if tired {
            c.stroke(quad(pt(cx - 9, waistY - 8), pt(cx, waistY + 1), pt(cx + 9, waistY - 8)), with: detail, style: round(2.2))
        }
    }

    func drawShorts(_ c: inout GraphicsContext) {
        var p = Path()
        p.move(to: pt(cx - waist - 2, waistY - 3))
        p.addLine(to: pt(cx + waist + 2, waistY - 3))
        p.addLine(to: pt(cx + waist + 5, waistY + 15))
        p.addLine(to: pt(cx + 3, waistY + 15))
        p.addLine(to: pt(cx, waistY + 7))
        p.addLine(to: pt(cx - 3, waistY + 15))
        p.addLine(to: pt(cx - waist - 5, waistY + 15))
        p.closeSubpath()
        fillAndOutline(&c, p, fill: Self.shorts, width: 3)
    }

    struct Arm {
        let s: CGFloat
        let shoulder: CGPoint
        let elbow: CGPoint
        let hand: CGPoint
        let bicep: CGPoint
        let bicepR: CGFloat
        let flex: Bool
    }

    func arms() -> [Arm] {
        [CGFloat(-1), CGFloat(1)].map { s in
            let flex = stage >= 3 || (stage == 2 && s == 1)
            let shoulder = pt(cx + s * (sh - 4), shY + 7)
            if flex {
                return Arm(s: s, shoulder: shoulder,
                           elbow: pt(cx + s * (sh + 19), shY + 3),
                           hand: pt(cx + s * (sh + 16), shY - 23),
                           bicep: pt(cx + s * (sh + 9), shY - 2),
                           bicepR: 4 + m * 8, flex: true)
            }
            return Arm(s: s, shoulder: shoulder,
                       elbow: pt(cx + s * (sh + 5), shY + (tired ? 30 : 27)),
                       hand: pt(cx + s * (sh + (tired ? 2 : 4)), shY + (tired ? 54 : 49)),
                       bicep: pt(cx + s * (sh + 2), shY + 15),
                       bicepR: 3 + m * 5, flex: false)
        }
    }

    func drawArms(_ c: inout GraphicsContext) {
        let fistR = armW * 0.6 + 3
        let beat = wave(1.6)
        for arm in arms() {
            c.drawLayer { l in
                if arm.flex { rotate(&l, degrees: -6 * Double(beat), around: arm.shoulder) }
                var path = Path()
                path.move(to: arm.shoulder)
                path.addLine(to: arm.elbow)
                path.addLine(to: arm.hand)

                // Kontur zuerst, dann Füllung – so verschmelzen Arm, Bizeps und Faust
                l.stroke(path, with: .color(Self.ink), style: round(armW + 5))
                l.fill(circle(arm.bicep, arm.bicepR + 2.5), with: .color(Self.ink))
                l.fill(circle(arm.hand, fistR + 2.5), with: .color(Self.ink))
                l.stroke(path, with: .color(Self.skin), style: round(armW))
                let pump: CGFloat = arm.flex ? 1 + 0.14 * beat : 1
                l.fill(circle(arm.bicep, arm.bicepR * pump), with: .color(Self.skin))
                l.fill(circle(arm.hand, fistR), with: .color(Self.skin))

                if arm.flex && m > 0.25 {
                    let r = arm.bicepR
                    let start = pt(arm.bicep.x - arm.s * r * 0.35, arm.bicep.y - r * 0.55)
                    let shine = quad(start,
                                     pt(start.x + arm.s * r * 0.3, start.y - r * 0.25),
                                     pt(start.x + arm.s * r * 0.6, start.y))
                    l.stroke(shine, with: .color(.white.opacity(0.7)), style: round(2))
                }
            }
        }
    }

    func drawHead(_ c: inout GraphicsContext) {
        c.drawLayer { l in
            if tired {
                l.translateBy(x: 80, y: 66)
                l.rotate(by: .degrees(-9))
                l.translateBy(x: 0, y: 3)
                l.translateBy(x: -80, y: -66)
            }
            fillAndOutline(&l, circle(pt(80, headCY), headR), fill: Self.skin, width: 3.5)
            drawBand(&l)
            drawFace(&l)
        }
    }

    func drawBand(_ c: inout GraphicsContext) {
        let y1 = headCY - 19
        let y2 = headCY - 12
        let w1 = sqrt(headR * headR - 19 * 19)
        let w2 = sqrt(headR * headR - 12 * 12)
        var band = Path()
        band.move(to: pt(80 - w1, y1))
        band.addLine(to: pt(80 + w1, y1))
        band.addLine(to: pt(80 + w2, y2))
        band.addLine(to: pt(80 - w2, y2))
        band.closeSubpath()
        fillAndOutline(&c, band, fill: Self.band, width: 2.6)

        let knot = pt(80 - w2 + 1, y1 + 3)
        c.drawLayer { l in
            rotate(&l, degrees: 14 * Double(wave(0.9)), around: knot)
            var tail1 = Path()
            tail1.move(to: knot)
            let t1 = pt(knot.x - 19, knot.y - 2)
            tail1.addQuadCurve(to: t1, control: pt(knot.x - 10, knot.y - 6))
            let t2 = pt(t1.x + 3, t1.y + 5)
            tail1.addLine(to: t2)
            tail1.addQuadCurve(to: pt(t2.x + 16, t2.y), control: pt(t2.x + 8, t2.y - 2))
            tail1.closeSubpath()
            fillAndOutline(&l, tail1, fill: Self.band, width: 2.6)

            var tail2 = Path()
            let k2 = pt(knot.x, y1 + 4)
            tail2.move(to: k2)
            let u1 = pt(k2.x - 16, k2.y + 9)
            tail2.addQuadCurve(to: u1, control: pt(k2.x - 8, k2.y + 4))
            let u2 = pt(u1.x + 5, u1.y + 3)
            tail2.addLine(to: u2)
            tail2.addQuadCurve(to: pt(u2.x + 11, u2.y - 9), control: pt(u2.x + 6, u2.y - 5))
            tail2.closeSubpath()
            fillAndOutline(&l, tail2, fill: Self.band, width: 2.6)
        }
        fillAndOutline(&c, circle(pt(knot.x, y1 + 3.5), 3.2), fill: Self.band, width: 2.6)
    }

    func drawFace(_ c: inout GraphicsContext) {
        let ey = headCY - 1
        let ink = GraphicsContext.Shading.color(Self.ink)

        // Augenbrauen
        var brows = Path()
        switch stage {
        case 0:
            brows.addPath(line(pt(66, ey - 7), pt(74, ey - 10)))
            brows.addPath(line(pt(94, ey - 7), pt(86, ey - 10)))
        case 1:
            brows.addPath(line(pt(67, ey - 9), pt(75, ey - 9)))
            brows.addPath(line(pt(85, ey - 9), pt(93, ey - 9)))
        case 2:
            brows.addPath(line(pt(67, ey - 10), pt(75, ey - 9)))
            brows.addPath(line(pt(85, ey - 9), pt(93, ey - 10)))
        case 3:
            brows.addPath(line(pt(66, ey - 11), pt(75, ey - 7)))
            brows.addPath(line(pt(85, ey - 7), pt(94, ey - 11)))
        default:
            brows.addPath(quad(pt(66, ey - 11), pt(71, ey - 15), pt(76, ey - 11)))
            brows.addPath(quad(pt(84, ey - 11), pt(89, ey - 15), pt(94, ey - 11)))
        }
        c.stroke(brows, with: ink, style: round(2.6))

        // Augen
        if stage == 0 {
            for x in [CGFloat(71), CGFloat(89)] {
                var lower = Path()
                lower.move(to: pt(x - 5, ey))
                lower.addRelativeArc(center: pt(x, ey), radius: 5, startAngle: .degrees(180), delta: .degrees(-180))
                lower.closeSubpath()
                fillAndOutline(&c, lower, fill: .white, width: 2)
                c.fill(circle(pt(x, ey + 2.6), 1.8), with: ink)
                c.stroke(line(pt(x - 5, ey), pt(x + 5, ey)), with: ink, style: round(1.6))
                c.stroke(quad(pt(x - 4, ey + 7.5), pt(x, ey + 9.5), pt(x + 4, ey + 7.5)), with: ink, style: round(1.6))
            }
        } else if stage == 4 {
            for x in [CGFloat(71), CGFloat(89)] {
                c.stroke(quad(pt(x - 5, ey + 2), pt(x, ey - 5), pt(x + 5, ey + 2)), with: ink, style: round(3.2))
            }
        } else {
            c.drawLayer { l in
                scale(&l, x: 1, y: blinkScale(), around: pt(80, ey))
                for x in [CGFloat(71), CGFloat(89)] {
                    fillAndOutline(&l, ellipse(pt(x, ey), 4.6, 5.6), fill: .white, width: 2)
                    l.fill(circle(pt(x + 0.8, ey + 0.8), 2.4), with: ink)
                    l.fill(circle(pt(x + 1.8, ey - 0.6), 0.9), with: .color(.white))
                }
            }
        }

        // Wangen
        if stage >= 3 {
            c.fill(ellipse(pt(63, headCY + 7), 4.5, 2.6), with: .color(Self.cheek.opacity(0.55)))
            c.fill(ellipse(pt(97, headCY + 7), 4.5, 2.6), with: .color(Self.cheek.opacity(0.55)))
        }

        // Mund
        let my = headCY + 10
        switch stage {
        case 0:
            c.stroke(quad(pt(73, my + 3), pt(80, my - 3), pt(87, my + 3)), with: ink, style: round(2.6))
        case 1:
            c.stroke(quad(pt(74, my - 1), pt(80, my + 3), pt(86, my - 1)), with: ink, style: round(2.6))
        case 2:
            c.stroke(quad(pt(71, my - 2), pt(80, my + 6), pt(89, my - 2)), with: ink, style: round(2.6))
        default:
            let wide: CGFloat = stage == 4 ? 12 : 9
            let deep: CGFloat = stage == 4 ? 12 : 8
            var mouth = quad(pt(80 - wide, my - 3), pt(80, my + deep), pt(80 + wide, my - 3))
            mouth.closeSubpath()
            fillAndOutline(&c, mouth, fill: Self.mouth, width: 2.4)
            var teeth = Path()
            teeth.move(to: pt(80 - wide + 2, my - 2.6))
            teeth.addLine(to: pt(80 + wide - 2, my - 2.6))
            teeth.addLine(to: pt(80 + wide - 3.5, my + 0.8))
            teeth.addLine(to: pt(80 - wide + 3.5, my + 0.8))
            teeth.closeSubpath()
            c.fill(teeth, with: .color(.white))
            if stage == 4 {
                c.fill(ellipse(pt(80, my + 5), 5, 2.4), with: .color(Self.tongue))
            }
        }
    }

    /// Blinzeln alle 4,2 Sekunden
    func blinkScale() -> CGFloat {
        let p = phase(4.2)
        if p >= 0.92 && p < 0.95 { return CGFloat(1 - 0.9 * (p - 0.92) / 0.03) }
        if p >= 0.95 { return CGFloat(0.1 + 0.9 * (p - 0.95) / 0.05) }
        return 1
    }

    func drawDrop(_ c: inout GraphicsContext) {
        let p = phase(2.4)
        let opacity = p < 0.15 ? p / 0.15 : 1 - (p - 0.15) / 0.85
        c.drawLayer { l in
            l.opacity = opacity
            l.translateBy(x: 0, y: CGFloat(p) * 14)
            var drop = Path()
            drop.move(to: pt(104, 33))
            drop.addCurve(to: pt(104, 45), control1: pt(109, 41), control2: pt(109, 45))
            drop.addCurve(to: pt(104, 33), control1: pt(99, 45), control2: pt(99, 41))
            drop.closeSubpath()
            fillAndOutline(&l, drop, fill: Self.drop, width: 1.8)
        }
    }

    func drawSparkles(_ c: inout GraphicsContext) {
        let spots: [(CGFloat, CGFloat, CGFloat)] = isMax
            ? [(22, 46, 7), (138, 104, 5), (20, 112, 5)]
            : [(22, 46, 7), (140, 30, 6), (138, 104, 5), (20, 112, 5)]
        for (i, spot) in spots.enumerated() {
            let (x, y, r) = spot
            let w = wave(1.8, delay: Double(i) * 0.35)
            c.drawLayer { l in
                l.opacity = Double(0.2 + 0.8 * w)
                let center = pt(x, y)
                rotate(&l, degrees: 45 * Double(w), around: center)
                scale(&l, x: 0.4 + 0.7 * w, y: 0.4 + 0.7 * w, around: center)
                var star = Path()
                star.move(to: pt(x, y - r))
                star.addQuadCurve(to: pt(x + r, y), control: center)
                star.addQuadCurve(to: pt(x, y + r), control: center)
                star.addQuadCurve(to: pt(x - r, y), control: center)
                star.addQuadCurve(to: pt(x, y - r), control: center)
                star.closeSubpath()
                l.fill(star, with: .color(Self.gold))
                l.stroke(star, with: .color(Self.ink), style: round(1.4))
            }
        }
    }

    func drawPow(_ c: inout GraphicsContext) {
        let center = pt(127, 23)
        let w = wave(1.6)
        c.drawLayer { l in
            rotate(&l, degrees: -4 * Double(w), around: center)
            scale(&l, x: 1 + 0.12 * w, y: 1 + 0.12 * w, around: center)
            var burst = Path()
            for i in 0..<16 {
                let a = Double(i) / 16 * 2 * Double.pi
                let r: CGFloat = i % 2 == 1 ? 13 : 22
                let p = pt(center.x + CGFloat(cos(a)) * r * 1.15, center.y + CGFloat(sin(a)) * r)
                if i == 0 { burst.move(to: p) } else { burst.addLine(to: p) }
            }
            burst.closeSubpath()
            fillAndOutline(&l, burst, fill: Self.gold, width: 2.4)

            rotate(&l, degrees: 10, around: center)
            let text = Text("POW!")
                .font(.system(size: 12, weight: .black).italic())
                .foregroundColor(Self.band)
            l.draw(text, at: pt(center.x, center.y + 0.5), anchor: .center)
        }
    }
}
