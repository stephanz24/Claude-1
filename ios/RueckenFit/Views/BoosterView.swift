import SwiftUI

/// Karte mit Bühne, Level, Serie, Balken, Trend und nächster Belohnung
struct BoosterCard: View {
    @Environment(Store.self) private var store
    @State private var director = BoosterDirector()

    private static let levelNames = ["Schlappi 😮‍💨", "Aufgewacht", "In Form", "Kraftpaket", "Booster-Modus 💪"]

    var body: some View {
        let booster = store.booster()
        let snapshot = makeSnapshot(booster)
        let m = booster.fraction
        let hue = 15 + m * 115

        Card(title: "Dein Booster") {
            BoosterStageView(director: director, snapshot: snapshot)
                .padding(.horizontal, -8)

            VStack(alignment: .leading, spacing: 4) {
                Text(booster.isMax ? "Maximal-Booster 🔥" : Self.levelNames[booster.stage]).font(.headline)
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
                .frame(height: 12)

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
                unlockText(booster.power)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Der Booster zeigt, wie regelmäßig Du in den letzten zwei Wochen trainiert hast – die letzten Tage zählen am meisten. \(Catalog.goodMin) von \(Catalog.required.count) Übungen oder Pilates = voller Tag, weniger zählt anteilig, Indoor Cycling und Gehen geben einen Bonus. Pausen lassen den Muskel schrumpfen.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 12)
        }
    }

    private func makeSnapshot(_ b: Store.Booster) -> BoosterDirector.Snapshot {
        let today = store.todayKey
        let credit = store.dayCredit(today)
        return BoosterDirector.Snapshot(
            power: b.power,
            stage: b.stage,
            isMax: b.isMax,
            streak: b.streak,
            items: BFUnlock.items(for: b.power),
            todayTicks: store.entry(today).done.count,
            todayFull: credit >= 1,
            missing: max(1, Int((Double(Catalog.goodMin) * (1 - credit) - 0.001).rounded(.up)))
        )
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

    private func unlockText(_ power: Double) -> Text {
        if let next = BFUnlock.all.first(where: { power < $0.at }) {
            return Text("🎁 Ab \(Int(next.at)): ") + Text(next.name).bold() + Text(" · noch " + (next.at - power).germanOneDecimal)
        }
        return Text("👑 Alles freigeschaltet – Krone verdient!")
    }

    private func barStyle(hue: Double, full: Bool) -> AnyShapeStyle {
        if full {
            return AnyShapeStyle(LinearGradient(colors: [Color(hue: 130 / 360, saturation: 0.55, brightness: 0.68), Color(hex: 0xF0B429)],
                                                startPoint: .leading, endPoint: .trailing))
        }
        return AnyShapeStyle(Color(hue: hue / 360, saturation: 0.6, brightness: 0.7))
    }
}

// MARK: - Regie

/// Entscheidet, was das Männchen gerade tut und sagt. Bewusst keine beobachtete
/// Klasse: sie wird pro Bild in der Zeitleiste fortgeschrieben.
final class BoosterDirector {
    struct Snapshot: Equatable {
        var power: Double
        var stage: Int
        var isMax: Bool
        var streak: Int
        var items: Set<String>
        var todayTicks: Int
        var todayFull: Bool
        var missing: Int
    }

    private(set) var state: Snapshot? = nil
    private(set) var pose = BFPose()
    private var x = 0.0
    private var action: BFAction? = nil
    private var actStart = 0.0
    private var actDur = 0.0
    private var plan = BFAction.WalkPlan()
    private var lastAction: BFAction? = nil
    private var nextAt = 0.0
    private(set) var bubble: String? = nil
    private(set) var bubbleStart = 0.0
    private var bubbleUntil = 0.0
    private var nextChatAt = 0.0
    private var lastGreet = -1e9
    private var lastFrame = 0.0

    static func now() -> Double { Date().timeIntervalSinceReferenceDate }

    var isActing: Bool { action != nil }

    // MARK: Eingänge

    func update(_ s: Snapshot, reduceMotion: Bool) {
        guard s != state else { return }
        let prev = state
        state = s
        guard let prev else { return }
        let t = Self.now()
        let gained = BFUnlock.all.filter { s.items.contains($0.key) && !prev.items.contains($0.key) }
        if let last = gained.last {
            if !reduceMotion { play(.victory, at: t) }
            say("Neu freigeschaltet: " + last.name + "!", at: t, for: 4.5)
        } else if s.todayFull && !prev.todayFull {
            if !reduceMotion { play(.victory, at: t) }
            say(["VOLLER TAG! 🎉", "Voller Tag – Booooost! 🔥", "Geschafft! Ich bin stolz auf Dich!"].randomElement()!, at: t)
        } else if s.todayTicks > prev.todayTicks {
            if !reduceMotion { play(.cheer, at: t) }
            say(["+1! 💪", "Jawoll!", "Sauber!", "Mehr davon!", "Das tut dem Rücken gut!", "Noch eine? 😄"].randomElement()!, at: t, for: 2.2)
        }
        if s.items.count < prev.items.count { x = min(max(x, -90), 90) }
    }

    func greet(reduceMotion: Bool) {
        let t = Self.now()
        guard t - lastGreet > 60, state != nil else { return }
        lastGreet = t
        let h = Calendar.current.component(.hour, from: Date())
        let hello = h < 11 ? "Guten Morgen!" : (h >= 18 ? "Guten Abend!" : "Hallo!")
        if !reduceMotion { play(.wave, at: t) }
        say(hello + " " + (["Bereit? 💪", "Schön, dass Du da bist!", "Auf geht's!", chatter()].randomElement() ?? ""), at: t)
        nextChatAt = t + 14 + Double.random(in: 0...8)
    }

    func tap(reduceMotion: Bool) {
        let t = Self.now()
        if !reduceMotion { play((state?.stage ?? 0) >= 3 ? .flex : .wave, at: t) }
        say(chatter(), at: t)
    }

    // MARK: Ablauf

    private func play(_ a: BFAction, at t: Double, plan p: BFAction.WalkPlan? = nil, duration: Double? = nil) {
        action = a
        actStart = t
        actDur = duration ?? a.duration
        if let p { plan = p }
        lastAction = a
    }

    private func say(_ text: String, at t: Double, for seconds: Double = 3.8) {
        guard !text.isEmpty else { return }
        bubble = text
        bubbleStart = t
        bubbleUntil = t + seconds
    }

    private func startRandom(at t: Double) {
        guard let s = state else { return }
        let pools: [[BFAction]] = [
            [.sleep, .yawn, .look],
            [.yawn, .look, .wave, .stretch],
            [.squat, .stretch, .wave, .jacks, .look],
            [.squat, .jacks, .curl, .flex, .dance, .drink, .stretch],
            [.flex, .curl, .jacks, .dance, .squat, .drink, .flex],
        ]
        // Etwa jede dritte Aktion: über die Bühne laufen
        if lastAction != .walk && Double.random(in: 0..<1) < 0.35 {
            var x1 = x
            for _ in 0..<6 where abs(x1 - x) < 40 { x1 = Double(Int.random(in: -90...90)) }
            let speed = s.stage == 0 ? 28.0 : 46.0
            let dist = abs(x1 - x)
            play(.walk, at: t, plan: BFAction.WalkPlan(x0: x, x1: x1, steps: max(2, (dist / 10).rounded())), duration: dist / speed + 0.3)
            return
        }
        let pool = pools[min(4, max(0, s.stage))].filter { $0 != lastAction && ($0 != .curl || s.items.contains("dumbbell")) }
        if let a = pool.randomElement() { play(a, at: t) }
    }

    private func idlePose(_ t: Double) -> BFPose {
        var P = BFPose()
        P.x = x
        let breath = (1 - cos(t * .pi * 2 / 1.6)) / 2
        let stage = state?.stage ?? 0
        if stage == 0 {
            P.squat = 3; P.tilt = -9 + sin(t * .pi * 2 / 3.4) * 3
            P.hLx = 5; P.hLy = 44; P.hRx = 5; P.hRy = 44
        } else if stage >= 3 {
            P.hLx = 12; P.hLy = 26; P.hRx = 12; P.hRy = 26; P.lift = breath * 2
        } else {
            P.lift = breath * 3
        }
        return P
    }

    /// Ein Bild weiterrechnen – liefert die Pose zum Zeichnen
    func advance(to t: Double, reduceMotion: Bool) -> BFPose {
        if reduceMotion {
            var P = idlePose(0)
            if (state?.stage ?? 0) >= 3 { P = BFAction.flex.pose(0, plan: plan, base: P) }
            pose = P
            if t > bubbleUntil { bubble = nil }
            return P
        }
        let dt = min(0.1, max(0, t - (lastFrame == 0 ? t : lastFrame)))
        lastFrame = t

        if let a = action, t - actStart >= actDur {
            if a == .walk { x = plan.x1 }
            action = nil
            nextAt = t + 2.2 + Double.random(in: 0...3)
        }
        if action == nil && t >= nextAt { startRandom(at: t) }
        if t > bubbleUntil { bubble = nil }
        if t >= nextChatAt && bubble == nil {
            say(chatter(), at: t)
            nextChatAt = t + 16 + Double.random(in: 0...10)
        }

        var target: BFPose
        if let a = action {
            var base = BFPose()
            base.x = x
            target = a.pose(min(1, (t - actStart) / actDur), plan: plan, base: base)
        } else {
            target = idlePose(t)
        }
        pose.approach(target, k: 1 - exp(-dt * 16))
        return pose
    }

    func chatter() -> String {
        guard let s = state else { return "" }
        var c: [String] = []
        if s.todayTicks == 0 {
            c += ["Heute schon gedehnt?", "Ich mach mich schon mal warm …", "Komm, ein paar Übungen?", "Mein Bizeps langweilt sich."]
        } else if !s.todayFull {
            c += ["Noch \(s.missing) bis zum vollen Tag!", "Läuft bei uns!", "Weiter so – ich spür's schon!"]
        } else {
            c += ["Voller Tag! Ich platze vor Stolz!", "Boooost! 🔥", "Heute bist Du mein Held."]
        }
        if s.stage <= 1 { c += ["Puh … ich brauch Training 😮‍💨", "Ich bin ganz schlapp …"] }
        if let next = BFUnlock.all.first(where: { s.power < $0.at }) {
            c.append("Noch " + (next.at - s.power).germanOneDecimal + " Punkte " + next.to + "!")
        }
        if s.streak >= 3 { c.append("\(s.streak) volle Tage in Folge – Wahnsinn!") }
        return c.randomElement() ?? ""
    }
}

// MARK: - Bühne

struct BoosterStageView: View {
    let director: BoosterDirector
    let snapshot: BoosterDirector.Snapshot

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false

    private static let ground = 158.0
    private static let rim = Color(hex: 0xE8EFEC)

    var body: some View {
        let _ = director.update(snapshot, reduceMotion: reduceMotion)
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !visible || scenePhase != .active)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let pose = director.advance(to: t, reduceMotion: reduceMotion)
                draw(&context, size: size, pose: pose, t: t)
            }
        }
        .aspectRatio(320.0 / 200.0, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture { director.tap(reduceMotion: reduceMotion) }
        .onAppear {
            visible = true
            director.greet(reduceMotion: reduceMotion)
        }
        .onDisappear { visible = false }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && visible { director.greet(reduceMotion: reduceMotion) }
        }
        .accessibilityElement()
        .accessibilityLabel("Dein Booster-Männchen")
    }

    private func draw(_ c: inout GraphicsContext, size: CGSize, pose: BFPose, t: Double) {
        guard let s = director.state else { return }
        let k = size.width / 320
        c.scaleBy(x: k, y: k)
        c.translateBy(x: 0, y: 30)
        let X = 160 + pose.x

        // Boden
        var floor = Path()
        floor.move(to: CGPoint(x: 14, y: 161.5))
        floor.addLine(to: CGPoint(x: 306, y: 161.5))
        c.stroke(floor, with: .color(Theme.line), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        // Strahlenkranz bei voller Kraft
        if s.isMax {
            c.drawLayer { l in
                l.translateBy(x: X, y: 88)
                l.rotate(by: .degrees((t * 26).truncatingRemainder(dividingBy: 360)))
                var rays = Path()
                for i in 0..<12 {
                    let a = Double(i) / 12 * 2 * .pi
                    let b = a + .pi / 12
                    rays.move(to: .zero)
                    rays.addLine(to: CGPoint(x: cos(a) * 130, y: sin(a) * 130))
                    rays.addLine(to: CGPoint(x: cos(b) * 130, y: sin(b) * 130))
                    rays.closeSubpath()
                }
                let fade = Gradient(colors: [BFRenderer.gold.opacity(0.55), BFRenderer.gold.opacity(0)])
                l.fill(rays, with: .radialGradient(fade, center: .zero, startRadius: 0, endRadius: 130))
            }
        }

        // Schatten
        let sw = 1 - min(0.5, pose.lift / 40)
        let rx = (26 + s.power * 1.2) * sw
        let shade = colorScheme == .dark ? Color.black.opacity(0.35) : BFRenderer.ink.opacity(0.13)
        c.fill(Path(ellipseIn: CGRect(x: X - rx, y: 161 - 5 * sw, width: rx * 2, height: 10 * sw)), with: .color(shade))

        // Funkeln ab Stufe 3
        if s.stage >= 3 { drawSparkles(&c, X: X, t: t) }

        // Figur
        let blink = !director.isActing && t.truncatingRemainder(dividingBy: 4.2) > 4.06
        let renderer = BFRenderer(pose: pose, m: s.power / 10, stage: s.stage, items: s.items, blink: blink, t: t)
        c.drawLayer { l in
            if colorScheme == .dark {
                for (dx, dy) in [(1.6, 0.0), (-1.6, 0.0), (0.0, 1.6), (0.0, -1.6)] {
                    l.addFilter(.shadow(color: Self.rim, radius: 0.3, x: dx, y: dy))
                }
            }
            l.translateBy(x: X, y: Self.ground - pose.lift)
            renderer.draw(&l)
        }

        // Sprechblase
        if let text = director.bubble { drawBubble(&c, text: text, X: X, lift: pose.lift, t: t, width: 320) }
    }

    private func drawSparkles(_ c: inout GraphicsContext, X: Double, t: Double) {
        let spots: [(Double, Double, Double)] = [(-62, -112, 7), (62, -128, 6), (60, -52, 5), (-62, -44, 5)]
        for (i, spot) in spots.enumerated() {
            let w = (1 - cos((t + Double(i) * 0.45) * .pi * 2 / 1.8)) / 2
            let x = X + spot.0, y = Self.ground + spot.1, r = spot.2 * (0.4 + 0.7 * w)
            c.drawLayer { l in
                l.opacity = 0.2 + 0.8 * w
                l.translateBy(x: x, y: y)
                l.rotate(by: .degrees(w * 45))
                var star = Path()
                star.move(to: CGPoint(x: 0, y: -r))
                star.addQuadCurve(to: CGPoint(x: r, y: 0), control: .zero)
                star.addQuadCurve(to: CGPoint(x: 0, y: r), control: .zero)
                star.addQuadCurve(to: CGPoint(x: -r, y: 0), control: .zero)
                star.addQuadCurve(to: CGPoint(x: 0, y: -r), control: .zero)
                l.fill(star, with: .color(BFRenderer.gold))
                l.stroke(star, with: .color(BFRenderer.ink), style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
            }
        }
    }

    private func drawBubble(_ c: inout GraphicsContext, text: String, X: Double, lift: Double, t: Double, width: Double) {
        let resolved = c.resolve(Text(text).font(.system(size: 12.5, weight: .bold)).foregroundColor(BFRenderer.ink))
        let maxW = width * 0.6
        let textSize = resolved.measure(in: CGSize(width: maxW - 22, height: 200))
        let w = Double(textSize.width) + 22, h = Double(textSize.height) + 13
        let right = X < 190
        let ax = X + (right ? 16 : -16)
        let ay = Self.ground - lift - 132
        var x0 = right ? ax : ax - w
        x0 = min(max(x0, 4), width - w - 4)
        let rect = CGRect(x: x0, y: ay - h, width: w, height: h)

        // Kurzes Aufploppen
        let age = Self.ageScale(t - director.bubbleStart)
        c.drawLayer { l in
            l.translateBy(x: ax, y: ay)
            l.scaleBy(x: age, y: age)
            l.translateBy(x: -ax, y: -ay)
            let bubble = Path(roundedRect: rect, cornerRadius: 14)
            l.fill(bubble.offsetBy(dx: 3, dy: 3), with: .color(BFRenderer.ink.opacity(0.18)))
            l.fill(bubble, with: .color(.white))
            l.stroke(bubble, with: .color(BFRenderer.ink), lineWidth: 2.5)
            l.draw(resolved, in: rect.insetBy(dx: 11, dy: 6.5))
        }
    }

    private static func ageScale(_ age: Double) -> CGFloat {
        if age >= 0.3 { return 1 }
        let p = max(0, age / 0.3)
        return CGFloat(0.6 + 0.4 * (1 - pow(1 - p, 3)) + sin(p * .pi) * 0.08)
    }
}
