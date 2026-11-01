import SwiftUI
import UIKit

/// Merkt sich, ob gerade eine Serie gefeiert wird
@Observable
final class Celebration {
    struct Event: Identifiable {
        let id = UUID()
        let exerciseID: String
        let count: Int
    }

    var current: Event? = nil

    /// Nach dem Abhaken: Hat die laufende Serie gerade einen Meilenstein erreicht?
    func check(store: Store, exerciseID: String, before: Int) {
        let after = store.streakInfo(exerciseID).count
        guard after > before, Catalog.milestones.contains(after) else { return }
        let event = Event(exerciseID: exerciseID, count: after)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { current = event }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            if self.current?.id == event.id { self.dismiss() }
        }
    }

    func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) { current = nil }
    }
}

/// Feier-Karte mit Comic-Stern, Symbol und Konfetti
struct CelebrationOverlay: View {
    @Environment(Celebration.self) private var celebration
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let event = celebration.current {
            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { celebration.dismiss() }

                if !reduceMotion {
                    ConfettiView(seed: event.id.hashValue)
                        .id(event.id)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                card(event)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
            .transition(.opacity)
        }
    }

    private func card(_ event: Celebration.Event) -> some View {
        let name = Catalog.exercises.first { $0.id == event.exerciseID }?.name ?? ""
        return VStack(spacing: 6) {
            ZStack {
                BurstStar(spinning: !reduceMotion)
                    .frame(width: 132, height: 132)
                ExerciseIcon(id: event.exerciseID, size: 64)
            }
            .padding(.top, -70)

            Text("🔥 \(event.count) Tage am Stück!")
                .font(.title2.weight(.heavy))
            Text(Catalog.milestoneTitles[event.count] ?? "Serien-Held")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Color(hex: 0x3A2600))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(hex: 0xF5B82E), in: Capsule())
                .rotationEffect(.degrees(-2))
            Text(name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 10)

            Button { celebration.dismiss() } label: {
                Text("Weiter so!")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.green, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .padding(.bottom, 20)
        .frame(maxWidth: 320)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 25, y: 18)
        .padding(24)
    }
}

/// Goldener Comic-Stern hinter dem Symbol, dreht sich langsam
struct BurstStar: View {
    let spinning: Bool

    var body: some View {
        TimelineView(.animation(paused: !spinning)) { timeline in
            let t = spinning ? timeline.date.timeIntervalSinceReferenceDate : 0
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let unit = size.width / 100
                let p = (t / 10) - (t / 10).rounded(.down)
                ctx.translateBy(x: center.x, y: center.y)
                ctx.rotate(by: .degrees(p * 360))
                var star = Path()
                for i in 0..<20 {
                    let angle = Double(i) / 20 * 2 * Double.pi
                    let r: CGFloat = (i % 2 == 1 ? 37 : 48) * unit
                    let point = CGPoint(x: CGFloat(cos(angle)) * r, y: CGFloat(sin(angle)) * r)
                    if i == 0 { star.move(to: point) } else { star.addLine(to: point) }
                }
                star.closeSubpath()
                ctx.fill(star, with: .color(Color(hex: 0xF5B82E)))
                ctx.stroke(star, with: .color(Color(hex: 0x15261F)),
                           style: StrokeStyle(lineWidth: 3 * unit, lineJoin: .round))
            }
        }
    }
}

/// Fallendes Konfetti, einmalig pro Feier
struct ConfettiView: View {
    let seed: Int
    @State private var start = Date()

    private static let colors: [Color] = [
        Color(hex: 0xF5B82E), Color(hex: 0xE5484D), Color(hex: 0x46C793),
        Color(hex: 0x3570C9), Color(hex: 0x8459C4), Color(hex: 0xFF8A95),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSince(start)
                var rng = SeededRandom(seed: UInt64(truncatingIfNeeded: seed))
                for i in 0..<36 {
                    let x0 = CGFloat(rng.next())
                    let delay = rng.next() * 0.4
                    let duration = 1.6 + rng.next() * 1.3
                    let drift = CGFloat(rng.next() * 120 - 60)
                    let spin = rng.next() * 1080 - 540
                    let p = min(1, max(0, (t - delay) / duration))
                    guard p > 0 else { continue }
                    let progress = CGFloat(p)
                    var piece = ctx
                    piece.translateBy(x: x0 * size.width + drift * progress,
                                      y: -14 + progress * (size.height + 28))
                    piece.rotate(by: .degrees(spin * p))
                    piece.fill(Path(roundedRect: CGRect(x: -4.5, y: -7, width: 9, height: 14), cornerRadius: 2),
                               with: .color(Self.colors[i % Self.colors.count]))
                }
            }
        }
    }
}

/// Kleiner Zufallsgenerator mit festem Startwert – gleiches Konfetti in jedem Bild
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(UInt64(1) << 53)
    }
}
