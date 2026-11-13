import SwiftUI

// MARK: - Pose

/// Eine Körperhaltung. Hände relativ zur Schulter (dx nach außen, dy nach unten),
/// Füße relativ zur Ruheposition (dy negativ = angehoben). Werte wie in der Web-App.
struct BFPose {
    enum Elbow { case out, down, up }
    enum Face { case tired, neutral, smile, grin, joy, effort, wow, sleep, yawn, happy, sip }
    enum Prop { case dumbbell, bottle }

    var x = 0.0, lift = 0.0, squat = 0.0, lean = 0.0, tilt = 0.0
    var hLx = 8.0, hLy = 42.0, hRx = 8.0, hRy = 42.0
    var fLx = 0.0, fLy = 0.0, fRx = 0.0, fRy = 0.0
    var elL: Elbow = .out, elR: Elbow = .out
    var face: Face? = nil
    var prop: Prop? = nil

    /// Weich auf eine Zielpose zubewegen (k = Anteil pro Bild)
    mutating func approach(_ t: BFPose, k: Double) {
        x += (t.x - x) * k; lift += (t.lift - lift) * k; squat += (t.squat - squat) * k
        lean += (t.lean - lean) * k; tilt += (t.tilt - tilt) * k
        hLx += (t.hLx - hLx) * k; hLy += (t.hLy - hLy) * k; hRx += (t.hRx - hRx) * k; hRy += (t.hRy - hRy) * k
        fLx += (t.fLx - fLx) * k; fLy += (t.fLy - fLy) * k; fRx += (t.fRx - fRx) * k; fRy += (t.fRy - fRy) * k
        elL = t.elL; elR = t.elR; face = t.face; prop = t.prop
    }
}

// MARK: - Bewegungsabläufe

enum BFAction: CaseIterable {
    case wave, walk, squat, jacks, curl, stretch, flex, drink, yawn, sleep, look, dance, cheer, victory

    var duration: Double {
        switch self {
        case .wave: return 2.6
        case .walk: return 2
        case .squat: return 3.6
        case .jacks: return 3.2
        case .curl: return 3.6
        case .stretch: return 4.4
        case .flex: return 3.0
        case .drink: return 3.2
        case .yawn: return 3.4
        case .sleep: return 6.0
        case .look: return 2.8
        case .dance: return 3.6
        case .cheer: return 1.5
        case .victory: return 3.0
        }
    }

    struct WalkPlan { var x0 = 0.0, x1 = 0.0, steps = 2.0 }

    private static func lerp(_ a: Double, _ b: Double, _ k: Double) -> Double { a + (b - a) * k }
    private static func osc(_ p: Double, _ n: Double) -> Double { sin(p * n * .pi * 2) }
    private static func rep(_ p: Double, _ n: Double) -> Double { (1 - cos(p * n * .pi * 2)) / 2 }

    /// Pose zum Fortschritt p (0…1), aufbauend auf der Grundpose
    func pose(_ p: Double, plan: WalkPlan, base: BFPose) -> BFPose {
        var P = base
        switch self {
        case .wave:
            P.hRx = 14 + Self.osc(p, 3) * 7; P.hRy = -34; P.face = .happy; P.tilt = Self.osc(p, 1.5) * 4
        case .walk:
            let ph = p * plan.steps * .pi
            P.x = Self.lerp(plan.x0, plan.x1, p)
            P.fLy = -max(0, sin(ph)) * 7; P.fRy = -max(0, -sin(ph)) * 7
            P.hLx = 8 + sin(ph) * 6; P.hRx = 8 - sin(ph) * 6
            P.lift = abs(sin(ph)) * 2.5; P.tilt = sin(ph) * 3
        case .squat:
            let q = Self.rep(p, 3)
            P.squat = q * 17; P.fLx = 5; P.fRx = 5
            P.hLx = -3; P.hLy = 15; P.hRx = -3; P.hRy = 15; P.elL = .down; P.elR = .down
            P.face = q > 0.6 ? .effort : nil
        case .jacks:
            let q = Self.rep(p, 4)
            P.hLx = Self.lerp(8, 16, q); P.hLy = Self.lerp(42, -36, q)
            P.hRx = Self.lerp(8, 16, q); P.hRy = Self.lerp(42, -36, q)
            P.fLx = q * 9; P.fRx = q * 9; P.lift = abs(sin(p * 8 * .pi)) * 7; P.face = .happy
        case .curl:
            let q = Self.rep(p, 3)
            P.hRx = Self.lerp(6, 2, q); P.hRy = Self.lerp(40, 6, q); P.elR = .down
            P.hLx = 12; P.hLy = 26; P.prop = .dumbbell; P.face = q > 0.7 ? .effort : .grin
        case .stretch:
            let l = sin(p * .pi * 2) * 20
            let k = abs(l) / 20
            P.lean = l
            if l > 0 { P.hLx = Self.lerp(8, -12, k); P.hLy = Self.lerp(42, -36, k); P.elL = .up }
            else { P.hRx = Self.lerp(8, -12, k); P.hRy = Self.lerp(42, -36, k); P.elR = .up }
        case .flex:
            let pump = Self.rep(p, 3)
            P.hLx = 19; P.hLy = -29 + pump * 4; P.hRx = 19; P.hRy = -29 + pump * 4; P.face = .grin; P.lift = pump * 1.5
        case .drink:
            let k = min(1, sin(p * .pi) * 1.6)
            P.hRx = Self.lerp(8, -12, k); P.hRy = Self.lerp(42, -22, k); P.elR = .down; P.tilt = -12 * k
            P.prop = .bottle; P.face = k > 0.8 ? .sip : .happy; P.hLx = 12; P.hLy = 26
        case .yawn:
            let k = sin(p * .pi)
            P.hLx = Self.lerp(8, 6, k); P.hLy = Self.lerp(42, -38, k); P.hRx = Self.lerp(8, 6, k); P.hRy = Self.lerp(42, -38, k)
            P.face = k > 0.3 ? .yawn : .tired; P.lift = k * 2
        case .sleep:
            P.squat = 4; P.tilt = 14; P.face = .sleep; P.lift = sin(p * 6 * .pi) * 0.8
        case .look:
            P.tilt = Self.osc(p, 1) * 12
        case .dance:
            let b = p * 6 * .pi
            P.lean = sin(b) * 9; P.lift = abs(sin(b)) * 4
            P.hLx = 14; P.hLy = sin(b) > 0 ? -32 : 30; P.hRx = 14; P.hRy = sin(b) > 0 ? 30 : -32
            P.fLy = -max(0, sin(b)) * 5; P.fRy = -max(0, -sin(b)) * 5; P.face = .joy
        case .cheer:
            P.lift = sin(p * .pi) * 16; P.hLx = 12; P.hLy = -36; P.hRx = 12; P.hRy = -36; P.fLy = -3; P.fRy = -3; P.face = .joy
        case .victory:
            let j = abs(sin(p * 2 * .pi))
            P.lift = j * 18; P.hLx = 12; P.hLy = -36; P.hRx = 12; P.hRy = -36
            P.fLx = j * 4; P.fRx = j * 4; P.face = .joy; P.lean = sin(p * 2 * .pi) * 6
        }
        return P
    }
}

// MARK: - Belohnungen

struct BFUnlock {
    let at: Double
    let key: String
    let name: String
    let to: String

    static let all: [BFUnlock] = [
        BFUnlock(at: 3, key: "wrist", name: "Schweißbänder", to: "zu den Schweißbändern"),
        BFUnlock(at: 5, key: "dumbbell", name: "Hantel 🏋️", to: "zur Hantel 🏋️"),
        BFUnlock(at: 7, key: "shades", name: "Sonnenbrille 😎", to: "zur Sonnenbrille 😎"),
        BFUnlock(at: 8, key: "cape", name: "Superhelden-Umhang 🦸", to: "zum Superhelden-Umhang 🦸"),
        BFUnlock(at: 9, key: "medal", name: "Goldmedaille 🥇", to: "zur Goldmedaille 🥇"),
        BFUnlock(at: 10, key: "crown", name: "Krone 👑", to: "zur Krone 👑"),
    ]

    static func items(for power: Double) -> Set<String> {
        Set(all.filter { power >= $0.at }.map { $0.key })
    }
}

// MARK: - Zeichnen

/// Zeichnet die Figur in Figur-Koordinaten (Ursprung = Boden unter der Körpermitte)
struct BFRenderer {
    let pose: BFPose
    let m: Double
    let stage: Int
    let items: Set<String>
    let blink: Bool
    let t: Double

    static let ink = Color(hex: 0x15261F)
    static let skin = Color(hex: 0x46C793)
    static let band = Color(hex: 0xE5484D)
    static let cape = Color(hex: 0xC8323A)
    static let shorts = Color(hex: 0x2F62C0)
    static let gold = Color(hex: 0xF5B82E)
    static let mouth = Color(hex: 0x7A1F2B)
    static let tongue = Color(hex: 0xFF8A95)
    static let cheek = Color(hex: 0xFF7B8A)
    static let drop = Color(hex: 0x8FD3FF)
    static let glass = Color(hex: 0x1B1F24)

    var sh: Double { 17 + m * 19 }
    var waist: Double { 12 + m * 5 }
    var armW: Double { 6 + m * 7 }
    var legW: Double { 9 + m * 6 }
    let shY = -82.0, waistY = -40.0

    struct Limb {
        let s: Double
        let root: CGPoint
        let joint: CGPoint
        let end: CGPoint
        let bend: Double
    }

    // MARK: Helfer

    func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    func round(_ w: Double) -> StrokeStyle { StrokeStyle(lineWidth: CGFloat(w), lineCap: .round, lineJoin: .round) }

    func lerp(_ a: CGPoint, _ b: CGPoint, _ k: Double) -> CGPoint {
        CGPoint(x: Double(a.x) + (Double(b.x) - Double(a.x)) * k, y: Double(a.y) + (Double(b.y) - Double(a.y)) * k)
    }

    func line(_ pts: [CGPoint]) -> Path {
        var path = Path()
        path.move(to: pts[0])
        for q in pts.dropFirst() { path.addLine(to: q) }
        return path
    }

    func quad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint) -> Path {
        var path = Path()
        path.move(to: a)
        path.addQuadCurve(to: b, control: c)
        return path
    }

    func circle(_ c: CGPoint, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: Double(c.x) - r, y: Double(c.y) - r, width: r * 2, height: r * 2))
    }

    func ellipse(_ c: CGPoint, _ rx: Double, _ ry: Double) -> Path {
        Path(ellipseIn: CGRect(x: Double(c.x) - rx, y: Double(c.y) - ry, width: rx * 2, height: ry * 2))
    }

    func fillOutline(_ c: inout GraphicsContext, _ path: Path, _ fill: Color, _ w: Double) {
        c.fill(path, with: .color(fill))
        c.stroke(path, with: .color(Self.ink), style: round(w))
    }

    /// Zwei-Gelenk-Kette wie in der Web-App
    func ik(_ A: CGPoint, _ T: CGPoint, _ l1: Double, _ l2: Double, _ s: Double, _ pref: BFPose.Elbow) -> (CGPoint, CGPoint) {
        var dx = Double(T.x) - Double(A.x)
        var dy = Double(T.y) - Double(A.y)
        var d = (dx * dx + dy * dy).squareRoot()
        let maxD = l1 + l2 - 0.05
        if d > maxD { dx *= maxD / d; dy *= maxD / d; d = maxD }
        d = max(d, 0.5)
        let a = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
        let h = max(0, l1 * l1 - a * a).squareRoot()
        let mx = Double(A.x) + dx * a / d
        let my = Double(A.y) + dy * a / d
        let px = -dy / d, py = dx / d
        let j1 = p(mx + h * px, my + h * py)
        let j2 = p(mx - h * px, my - h * py)
        let joint: CGPoint
        switch pref {
        case .down: joint = j1.y > j2.y ? j1 : j2
        case .up: joint = j1.y < j2.y ? j1 : j2
        case .out: joint = s * Double(j1.x) > s * Double(j2.x) ? j1 : j2
        }
        return (joint, p(Double(A.x) + dx, Double(A.y) + dy))
    }

    var leanRad: Double { pose.lean * .pi / 180 }

    func rot(_ q: CGPoint) -> CGPoint {
        let px = 0.0, py = waistY + pose.squat
        let x = Double(q.x) - px, y = Double(q.y) - py
        let c = cos(leanRad), s = sin(leanRad)
        return p(px + x * c - y * s, py + x * s + y * c)
    }

    func rotV(_ x: Double, _ y: Double) -> CGPoint {
        let c = cos(leanRad), s = sin(leanRad)
        return p(x * c - y * s, x * s + y * c)
    }

    func legs() -> [Limb] {
        [-1.0, 1.0].map { s in
            let hip = p(s * (waist - 5), waistY + 10 + pose.squat)
            let fx = s < 0 ? pose.fLx : pose.fRx
            let fy = s < 0 ? pose.fLy : pose.fRy
            let target = p(s * (waist - 3 + fx), -8 + fy)
            let (knee, foot) = ik(hip, target, 12.5, 12.5, s, .out)
            return Limb(s: s, root: hip, joint: knee, end: foot, bend: 0)
        }
    }

    func arms() -> [Limb] {
        [-1.0, 1.0].map { s in
            let shoulder = rot(p(s * (sh - 4), shY + 7 + pose.squat))
            let hx = s < 0 ? pose.hLx : pose.hRx
            let hy = s < 0 ? pose.hLy : pose.hRy
            let off = rotV(s * hx, hy)
            let target = p(Double(shoulder.x) + Double(off.x), Double(shoulder.y) + Double(off.y))
            let (elbow, hand) = ik(shoulder, target, 21, 21, s, s < 0 ? pose.elL : pose.elR)
            let reach = hypot(Double(hand.x) - Double(shoulder.x), Double(hand.y) - Double(shoulder.y))
            return Limb(s: s, root: shoulder, joint: elbow, end: hand, bend: 1 - reach / 42)
        }
    }

    // MARK: Figur

    func draw(_ c: inout GraphicsContext) {
        if items.contains("cape") { drawCape(&c) }
        drawLegs(&c)
        drawTorso(&c)
        drawShorts(&c)
        let a = arms()
        drawArms(&c, a)
        drawHead(&c)
        drawProp(&c, hand: a[1].end)
    }

    func torsoLayer(_ c: inout GraphicsContext, _ body: (inout GraphicsContext) -> Void) {
        c.drawLayer { l in
            l.translateBy(x: 0, y: CGFloat(pose.squat))
            l.translateBy(x: 0, y: CGFloat(waistY))
            l.rotate(by: .degrees(pose.lean))
            l.translateBy(x: 0, y: CGFloat(-waistY))
            body(&l)
        }
    }

    func drawCape(_ c: inout GraphicsContext) {
        let w1 = sin(t * 4.2) * 3, w2 = sin(t * 5.1 + 1) * 2.5
        torsoLayer(&c) { l in
            var cape = Path()
            cape.move(to: p(-sh + 3, shY + 2))
            cape.addLine(to: p(sh - 3, shY + 2))
            cape.addQuadCurve(to: p(sh + 12 + w1, -20 + w2), control: p(sh + 10, -46))
            cape.addQuadCurve(to: p(-sh - 12 + w2, -20 + w1), control: p(0, -14 + w2))
            cape.addQuadCurve(to: p(-sh + 3, shY + 2), control: p(-sh - 10, -46))
            cape.closeSubpath()
            fillOutline(&l, cape, Self.cape, 3)
        }
    }

    func drawLegs(_ c: inout GraphicsContext) {
        for g in legs() {
            let path = line([g.root, g.joint, g.end])
            c.stroke(path, with: .color(Self.ink), style: round(legW + 5))
            c.stroke(path, with: .color(Self.skin), style: round(legW))
            let shoe = p(Double(g.end.x) + g.s * 3, Double(g.end.y) + 3)
            fillOutline(&c, ellipse(shoe, 10 + m * 2, 5.5), .white, 3)
            c.stroke(line([p(Double(shoe.x) - 5, Double(shoe.y) - 2), p(Double(shoe.x) + 5, Double(shoe.y) - 2)]),
                     with: .color(Self.band), style: round(2.4))
        }
    }

    func drawTorso(_ c: inout GraphicsContext) {
        torsoLayer(&c) { l in
            let neckTop = shY - 6 - m * 4
            var torso = Path()
            torso.move(to: p(-sh, shY + 4))
            torso.addQuadCurve(to: p(sh, shY + 4), control: p(0, neckTop))
            torso.addQuadCurve(to: p(waist, waistY), control: p(sh + 1, shY + 18))
            torso.addLine(to: p(-waist, waistY))
            torso.addQuadCurve(to: p(-sh, shY + 4), control: p(-sh - 1, shY + 18))
            torso.closeSubpath()
            fillOutline(&l, torso, Self.skin, 3.5)

            let detail = GraphicsContext.Shading.color(Self.ink.opacity(0.55))
            if m > 0.3 {
                let pw = sh * 0.72
                l.stroke(quad(p(-pw, shY + 14), p(-pw / 2, shY + 23), p(-2, shY + 15)), with: detail, style: round(2.2))
                l.stroke(quad(p(pw, shY + 14), p(pw / 2, shY + 23), p(2, shY + 15)), with: detail, style: round(2.2))
            }
            if m > 0.6 {
                var abs = line([p(0, shY + 24), p(0, waistY - 5)])
                for y in [waistY - 27, waistY - 17] {
                    abs.addPath(quad(p(-9, y + 1), p(-5.5, y - 1.5), p(-2.5, y)))
                    abs.addPath(quad(p(9, y + 1), p(5.5, y - 1.5), p(2.5, y)))
                }
                l.stroke(abs, with: detail, style: round(1.8))
            }
            if stage == 0 {
                l.stroke(quad(p(-9, waistY - 8), p(0, waistY + 1), p(9, waistY - 8)), with: detail, style: round(2.2))
            }
            if items.contains("medal") {
                l.stroke(line([p(-7, shY + 3), p(0, shY + 19), p(7, shY + 3)]), with: .color(Self.shorts), style: round(3.2))
                fillOutline(&l, circle(p(0, shY + 23), 5.5), Self.gold, 2)
            }
        }
    }

    func drawShorts(_ c: inout GraphicsContext) {
        var s = Path()
        let y0 = waistY + pose.squat
        s.move(to: p(-waist - 2, y0 - 3))
        s.addLine(to: p(waist + 2, y0 - 3))
        s.addLine(to: p(waist + 5, y0 + 15))
        s.addLine(to: p(3, y0 + 15))
        s.addLine(to: p(0, y0 + 7))
        s.addLine(to: p(-3, y0 + 15))
        s.addLine(to: p(-waist - 5, y0 + 15))
        s.closeSubpath()
        fillOutline(&c, s, Self.shorts, 3)
    }

    func bicep(_ a: Limb) -> (CGPoint, Double) {
        let mid = lerp(a.root, a.joint, 0.5)
        let ux = Double(a.joint.x) - Double(a.root.x)
        let uy = Double(a.joint.y) - Double(a.root.y)
        let ul = max(hypot(ux, uy), 1)
        var nx = -uy / ul, ny = ux / ul
        if ny > 0 { nx = -nx; ny = -ny }
        let br = (3 + m * 5) + max(0, a.bend) * (2 + m * 6)
        return (p(Double(mid.x) + nx * br * 0.45, Double(mid.y) + ny * br * 0.45), br)
    }

    func drawArms(_ c: inout GraphicsContext, _ arms: [Limb]) {
        let fistR = armW * 0.6 + 3
        for a in arms {
            let (b, br) = bicep(a)
            c.stroke(line([a.root, a.joint, a.end]), with: .color(Self.ink), style: round(armW + 5))
            c.fill(circle(b, br + 2.5), with: .color(Self.ink))
            c.fill(circle(a.end, fistR + 2.5), with: .color(Self.ink))
        }
        for a in arms {
            let (b, br) = bicep(a)
            c.stroke(line([a.root, a.joint, a.end]), with: .color(Self.skin), style: round(armW))
            c.fill(circle(b, br), with: .color(Self.skin))
            c.fill(circle(a.end, fistR), with: .color(Self.skin))
            if a.bend > 0.25 && m > 0.25 {
                let start = p(Double(b.x) - br * 0.35, Double(b.y) - br * 0.5)
                let shine = quad(start, p(Double(start.x) + br * 0.35, Double(start.y) - br * 0.28), p(Double(start.x) + br * 0.7, Double(start.y)))
                c.stroke(shine, with: .color(.white.opacity(0.7)), style: round(2))
            }
            if items.contains("wrist") {
                let cuff = line([lerp(a.joint, a.end, 0.58), lerp(a.joint, a.end, 0.78)])
                c.stroke(cuff, with: .color(Self.ink), style: StrokeStyle(lineWidth: CGFloat(armW + 4.5), lineCap: .butt))
                c.stroke(cuff, with: .color(Self.band), style: StrokeStyle(lineWidth: CGFloat(armW + 1.5), lineCap: .butt))
            }
        }
    }

    func drawProp(_ c: inout GraphicsContext, hand: CGPoint) {
        guard let prop = pose.prop else { return }
        c.drawLayer { l in
            l.translateBy(x: hand.x, y: hand.y)
            switch prop {
            case .dumbbell:
                fillOutline(&l, Path(roundedRect: CGRect(x: -11, y: -1.6, width: 22, height: 3.2), cornerRadius: 1.5), Color(hex: 0x6B7570), 1.4)
                fillOutline(&l, Path(roundedRect: CGRect(x: -15, y: -6.5, width: 6, height: 13), cornerRadius: 2), Color(hex: 0x3B4642), 1.6)
                fillOutline(&l, Path(roundedRect: CGRect(x: 9, y: -6.5, width: 6, height: 13), cornerRadius: 2), Color(hex: 0x3B4642), 1.6)
            case .bottle:
                l.rotate(by: .degrees(-35))
                fillOutline(&l, Path(roundedRect: CGRect(x: -4, y: -15, width: 8, height: 18), cornerRadius: 3), Self.drop, 1.8)
                fillOutline(&l, Path(roundedRect: CGRect(x: -2.5, y: -19, width: 5, height: 4.5), cornerRadius: 1), .white, 1.4)
            }
        }
    }

    // MARK: Kopf

    var face: BFPose.Face {
        pose.face ?? [BFPose.Face.tired, .neutral, .smile, .grin, .joy][min(4, max(0, stage))]
    }

    func drawHead(_ c: inout GraphicsContext) {
        let center = rot(p(0, -109 + pose.squat))
        c.drawLayer { l in
            l.translateBy(x: center.x, y: center.y)
            l.rotate(by: .degrees(pose.lean + pose.tilt))
            fillOutline(&l, circle(p(0, 0), 23), Self.skin, 3.5)
            drawBand(&l)
            drawFace(&l)
            if items.contains("crown") { drawCrown(&l) }
            drawHeadEffects(&l)
        }
    }

    func drawBand(_ c: inout GraphicsContext) {
        let y1 = -19.0, y2 = -12.0
        let w1 = (23.0 * 23 - 19 * 19).squareRoot(), w2 = (23.0 * 23 - 12 * 12).squareRoot()
        fillOutline(&c, line([p(-w1, y1), p(w1, y1), p(w2, y2), p(-w2, y2), p(-w1, y1)]), Self.band, 2.6)
        let kx = -w2 + 1, ky = y1 + 3
        c.drawLayer { l in
            l.translateBy(x: CGFloat(kx), y: CGFloat(ky))
            l.rotate(by: .degrees(sin(t * 7) * 12))
            var tails = Path()
            tails.move(to: p(0, 0))
            tails.addQuadCurve(to: p(-19, -2), control: p(-10, -6))
            tails.addLine(to: p(-16, 3))
            tails.addQuadCurve(to: p(0, 3), control: p(-8, 1))
            tails.closeSubpath()
            tails.move(to: p(0, 1))
            tails.addQuadCurve(to: p(-16, 10), control: p(-8, 5))
            tails.addLine(to: p(-11, 13))
            tails.addQuadCurve(to: p(0, 4), control: p(-5, 8))
            tails.closeSubpath()
            fillOutline(&l, tails, Self.band, 2.6)
        }
        fillOutline(&c, circle(p(kx, ky + 0.5), 3.2), Self.band, 2.6)
    }

    func drawFace(_ c: inout GraphicsContext) {
        let ey = -1.0
        let ink = GraphicsContext.Shading.color(Self.ink)
        let f = face

        // Augenbrauen
        var brows = Path()
        switch f {
        case .tired: brows = line([p(-14, -8), p(-6, -11)]); brows.addPath(line([p(14, -8), p(6, -11)]))
        case .neutral, .sleep: brows = line([p(-13, -10), p(-5, -10)]); brows.addPath(line([p(5, -10), p(13, -10)]))
        case .smile: brows = line([p(-13, -11), p(-5, -10)]); brows.addPath(line([p(5, -10), p(13, -11)]))
        case .grin, .effort: brows = line([p(-14, -12), p(-5, -8)]); brows.addPath(line([p(5, -8), p(14, -12)]))
        case .joy, .happy, .sip: brows = quad(p(-14, -12), p(-9, -16), p(-4, -12)); brows.addPath(quad(p(4, -12), p(9, -16), p(14, -12)))
        case .wow: brows = quad(p(-13, -14), p(-9, -17), p(-5, -14)); brows.addPath(quad(p(5, -14), p(9, -17), p(13, -14)))
        case .yawn: brows = line([p(-14, -10), p(-5, -12)]); brows.addPath(line([p(5, -12), p(14, -10)]))
        }
        c.stroke(brows, with: ink, style: round(2.6))

        // Augen
        let shades = items.contains("shades") && f != .sleep && f != .yawn && f != .sip
        if shades {
            var g = line([p(-16, -5), p(-2, -5), p(-3, 3)])
            g.addQuadCurve(to: p(-14, 3), control: p(-9, 6))
            g.closeSubpath()
            g.addPath(line([p(2, -5), p(16, -5), p(14, 3)]))
            g.addQuadCurve(to: p(3, 3), control: p(9, 6))
            g.closeSubpath()
            fillOutline(&c, g, Self.glass, 1.8)
            c.stroke(quad(p(-2, -4), p(0, -6), p(2, -4)), with: ink, style: round(2))
            var glint = line([p(-12, -3), p(-9, -1)])
            glint.addPath(line([p(6, -3), p(9, -1)]))
            c.stroke(glint, with: .color(.white.opacity(0.75)), style: round(1.6))
        } else {
            for x in [-9.0, 9.0] { drawEye(&c, x: x, ey: ey, f: f) }
        }

        // Wangen
        if f == .grin || f == .joy || f == .happy {
            c.fill(ellipse(p(-17, 7), 4.5, 2.6), with: .color(Self.cheek.opacity(0.55)))
            c.fill(ellipse(p(17, 7), 4.5, 2.6), with: .color(Self.cheek.opacity(0.55)))
        }
        drawMouth(&c, f: f)
    }

    func drawEye(_ c: inout GraphicsContext, x: Double, ey: Double, f: BFPose.Face) {
        let ink = GraphicsContext.Shading.color(Self.ink)
        switch f {
        case .tired:
            var lower = Path()
            lower.move(to: p(x - 5, ey))
            lower.addRelativeArc(center: p(x, ey), radius: 5, startAngle: .degrees(180), delta: .degrees(-180))
            lower.closeSubpath()
            fillOutline(&c, lower, .white, 2)
            c.fill(circle(p(x, ey + 2.6), 1.8), with: ink)
            c.stroke(line([p(x - 5, ey), p(x + 5, ey)]), with: ink, style: round(1.6))
        case .joy, .happy:
            c.stroke(quad(p(x - 5, ey + 2), p(x, ey - 5), p(x + 5, ey + 2)), with: ink, style: round(3.2))
        case .effort:
            let o = x < 0 ? -1.0 : 1.0
            c.stroke(line([p(x + o * 4, ey - 3.5), p(x - o * 3, ey), p(x + o * 4, ey + 3.5)]), with: ink, style: round(2.6))
        case .sleep, .yawn, .sip:
            c.stroke(quad(p(x - 5, ey), p(x, ey + 4), p(x + 5, ey)), with: ink, style: round(2.4))
        default:
            let ry = (f == .wow ? 6.2 : 5.6) * (blink ? 0.12 : 1)
            fillOutline(&c, ellipse(p(x, ey), 4.6, ry), .white, 2)
            if !blink {
                c.fill(circle(p(x + 0.8, ey + 0.8), 2.4), with: ink)
                c.fill(circle(p(x + 1.8, ey - 0.6), 0.9), with: .color(.white))
            }
        }
    }

    func drawMouth(_ c: inout GraphicsContext, f: BFPose.Face) {
        let ink = GraphicsContext.Shading.color(Self.ink)
        let my = 10.0
        switch f {
        case .tired: c.stroke(quad(p(-7, my + 3), p(0, my - 3), p(7, my + 3)), with: ink, style: round(2.6))
        case .neutral: c.stroke(quad(p(-6, my - 1), p(0, my + 3), p(6, my - 1)), with: ink, style: round(2.6))
        case .smile: c.stroke(quad(p(-9, my - 2), p(0, my + 6), p(9, my - 2)), with: ink, style: round(2.6))
        case .effort:
            fillOutline(&c, Path(roundedRect: CGRect(x: -8, y: my - 3, width: 16, height: 7), cornerRadius: 2), .white, 2.2)
            c.stroke(line([p(-8, my + 0.5), p(8, my + 0.5)]), with: ink, style: round(1.4))
        case .wow, .yawn:
            let r = f == .yawn ? 6.0 : 4.2
            fillOutline(&c, ellipse(p(0, my + 1), r * 0.8, r), Self.mouth, 2.2)
        case .sleep: c.stroke(quad(p(-4, my + 1), p(0, my + 3), p(4, my + 1)), with: ink, style: round(2.2))
        case .sip: fillOutline(&c, ellipse(p(2, my + 1), 2.6, 2.2), Self.mouth, 2)
        case .grin, .joy, .happy:
            let wide = f == .grin ? 9.0 : 12.0
            let deep = f == .grin ? 8.0 : 12.0
            var mouth = quad(p(-wide, my - 3), p(0, my + deep), p(wide, my - 3))
            mouth.closeSubpath()
            fillOutline(&c, mouth, Self.mouth, 2.4)
            var teeth = line([p(-wide + 2, my - 2.6), p(wide - 2, my - 2.6), p(wide - 3.5, my + 0.8), p(-wide + 3.5, my + 0.8)])
            teeth.closeSubpath()
            c.fill(teeth, with: .color(.white))
            if f != .grin { c.fill(ellipse(p(0, my + 5), 5, 2.4), with: .color(Self.tongue)) }
        }
    }

    func drawCrown(_ c: inout GraphicsContext) {
        var crown = line([p(-12, -21), p(-13, -33), p(-6, -27), p(0, -36), p(6, -27), p(13, -33), p(12, -21)])
        crown.closeSubpath()
        fillOutline(&c, crown, Self.gold, 2.2)
        c.fill(circle(p(0, -26), 2), with: .color(Self.band))
    }

    func drawHeadEffects(_ c: inout GraphicsContext) {
        let f = face
        if f == .effort || f == .tired {
            let q = (t.truncatingRemainder(dividingBy: 1.6)) / 1.6
            c.drawLayer { l in
                l.opacity = 1 - q
                l.translateBy(x: 0, y: CGFloat(q * 10))
                var drop = Path()
                drop.move(to: p(24, -16))
                drop.addCurve(to: p(24, -4), control1: p(29, -8), control2: p(29, -4))
                drop.addCurve(to: p(24, -16), control1: p(19, -4), control2: p(19, -8))
                drop.closeSubpath()
                fillOutline(&l, drop, Self.drop, 1.6)
            }
        }
        if f == .sleep {
            for i in 0..<3 {
                let q = (t * 0.6 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let z = Text("Z").font(.system(size: CGFloat(8 + q * 6), weight: .heavy)).foregroundColor(Self.shorts)
                c.drawLayer { l in
                    l.opacity = 1 - q
                    l.draw(z, at: p(18 + q * 14, -20 - q * 26), anchor: .bottomLeading)
                }
            }
        }
    }
}
