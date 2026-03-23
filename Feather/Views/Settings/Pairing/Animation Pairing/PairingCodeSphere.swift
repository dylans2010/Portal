import SwiftUI
import simd

// MARK: - Pairing Code Sphere
/// A 3D animated sphere built from ~400 dots that morph from random chaos
/// to a perfectly ordered Fibonacci sphere as `morphProgress` moves 0 → 1.
///
/// - The sphere rotates continuously around the Y-axis with a slight X/Z tilt.
/// - A color sweep travels bottom-to-top in sync with `morphProgress`.
/// - Rendering uses `TimelineView` + `Canvas` for smooth 60 fps performance.
struct PairingCodeSphere: View {
    @EnvironmentObject var themeManager: ThemeManager

    // MARK: - Configuration

    /// Drives the morph: 0 = full chaos, 1 = perfect Fibonacci sphere.
    let morphProgress: Double
    /// Used to trigger a dot reset when the session restarts.
    let pairingStatus: PairingStatus

    // MARK: - Constants

    private let dotCount  = 400
    private let tiltX: Double = 0.28  // Radians — slight downward tilt
    private let tiltZ: Double = 0.08  // Radians — slight roll

    // MARK: - State

    @State private var dots: [Dot] = []

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            TimelineView(.animation) { timeline in
                Canvas { context, canvasSize in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    // Y-axis rotation: ~0.55 rad/s for a smooth, unhurried spin
                    let rotY = now * 0.55
                    drawDots(
                        context: context,
                        canvasSize: Double(min(canvasSize.width, canvasSize.height)),
                        rotY: rotY
                    )
                }
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { buildDots() }
        .onChange(of: pairingStatus) { newStatus in
            // Rebuild dots with fresh random positions when starting over
            if newStatus == .idle { buildDots() }
        }
    }

    // MARK: - Drawing

    private func drawDots(
        context: GraphicsContext,
        canvasSize: Double,
        rotY: Double
    ) {
        // Build the projected list once per frame
        struct ProjectedDot {
            var x, y, scale: Double
            var color: Color
        }

        var projected = [ProjectedDot]()
        projected.reserveCapacity(dotCount)

        for dot in dots {
            // 1. Lerp between start (chaos) and end (Fibonacci)
            var pos = dot.interpolated(progress: morphProgress)

            // 2. Apply fixed tilts then the time-driven Y rotation
            pos = SphereMath.rotateX(point: pos, angle: tiltX)
            pos = SphereMath.rotateZ(point: pos, angle: tiltZ)
            pos = SphereMath.rotateY(point: pos, angle: rotY)

            // 3. Perspective projection
            let proj = SphereMath.project(point: pos, canvasSize: canvasSize)

            // 4. Color: dots sweep colored bottom-to-top as morphProgress rises.
            //    In the Fibonacci sphere, endPos.z runs +1 (index 0) → -1 (last index).
            //    After the X-tilt, high-z dots appear near the visual bottom.
            //    colorProgress: 0 = visual bottom (high z), 1 = visual top (low z).
            //    Colored dots grow from the bottom upward as morphProgress increases.
            let colorProgress = (dot.endPos.z + 1.0) / 2.0
            let isColored = colorProgress > (1.0 - morphProgress)
            let color = dotColor(colorProgress: colorProgress, isColored: isColored)

            projected.append(ProjectedDot(
                x: proj.x, y: proj.y, scale: proj.scale, color: color
            ))
        }

        // Painter's algorithm: back → front (ascending scale order)
        projected.sort { $0.scale < $1.scale }

        for dot in projected {
            // Dots closer to the camera are larger and more opaque
            let dotSize = max(1.8, dot.scale * 5.5)
            let alpha   = min(1.0, max(0.25, dot.scale * 0.9))
            let rect = CGRect(
                x: dot.x - dotSize * 0.5,
                y: dot.y - dotSize * 0.5,
                width: dotSize,
                height: dotSize
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(dot.color.opacity(alpha))
            )
        }
    }

    // MARK: - Dot Color

    /// Friendly blue / purple / teal / green palette — no intense effects.
    private func dotColor(colorProgress: Double, isColored: Bool) -> Color {
        if isColored {
            // Hue gradually shifts from blue (0.55) → teal (0.50) → green (0.38)
            // as colorProgress moves bottom (0) → top (1)
            let hue = 0.55 - colorProgress * 0.17
            return Color(hue: hue, saturation: 0.72, brightness: 0.95)
        } else {
            // Unswept dots are dim purple-grey to hint at the shape
            return Color(hue: 0.62, saturation: 0.22, brightness: 0.48)
        }
    }

    // MARK: - Dot Construction

    private func buildDots() {
        let random    = SphereMath.randomSpherePoints(count: dotCount)
        let fibonacci = SphereMath.fibonacciSpherePoints(count: dotCount)
        dots = (0..<dotCount).map { i in
            Dot(startPos: random[i], endPos: fibonacci[i])
        }
    }
}
