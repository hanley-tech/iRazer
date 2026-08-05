import SwiftUI

/// Original minimalist vector glyphs that represent each Razer device family —
/// drawn natively (SwiftUI can't load SVG). No third-party product imagery, so
/// nothing copyrighted is bundled. Matches the SVGs used on the website.
struct DeviceGlyph: View {
    let category: DeviceCategory
    var color: Color = Theme.green
    var glow: Bool = false

    var body: some View {
        Canvas { ctx, size in
            // Fit the 64x48 artwork with a SINGLE uniform scale so circles stay
            // circular (non-uniform x/y scaling was turning the round speakers oval).
            let scale = min(size.width / 64, size.height / 48)
            let ox = (size.width - 64 * scale) / 2
            let oy = (size.height - 48 * scale) / 2
            let sx = scale, sy = scale
            func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: ox + x * sx, y: oy + y * sy) }
            let stroke = StrokeStyle(lineWidth: 2.4 * sx, lineCap: .round, lineJoin: .round)
            let ink = GraphicsContext.Shading.color(color)
            let underglow = GraphicsContext.Shading.color(color.opacity(0.28))

            func ellipse(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) -> Path {
                Path(ellipseIn: CGRect(x: ox + (cx - rx) * sx, y: oy + (cy - ry) * sy,
                                       width: 2 * rx * sx, height: 2 * ry * sy))
            }
            func line(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> Path {
                var p = Path(); p.move(to: P(x1, y1)); p.addLine(to: P(x2, y2)); return p
            }

            switch category {
            case .speakers:
                // Round spheres (the Nommo V2 speakers are round, not oval).
                ctx.fill(ellipse(18, 43, 11, 3), with: underglow)
                ctx.fill(ellipse(46, 43, 11, 3), with: underglow)
                for cx in [18.0, 46.0] {
                    ctx.stroke(ellipse(cx, 18, 11, 11), with: ink, style: stroke)     // round body
                    ctx.stroke(ellipse(cx, 18, 4.6, 4.6), with: ink, style: stroke)   // driver
                    ctx.stroke(line(cx, 29, cx, 37), with: ink, style: stroke)        // neck
                    ctx.stroke(line(cx - 5, 38, cx + 5, 38), with: ink, style: stroke) // base
                }
            case .mousepads:
                ctx.stroke(Path(roundedRect: CGRect(x: ox + 8 * sx, y: oy + 12 * sy,
                                width: 48 * sx, height: 26 * sy), cornerRadius: 6 * sx),
                           with: ink, style: stroke)
            case .keyboards:
                ctx.fill(Path(roundedRect: CGRect(x: ox + 6 * sx, y: oy + 35 * sy, width: 52 * sx, height: 3 * sy), cornerRadius: 1.5 * sx), with: underglow)
                ctx.stroke(Path(roundedRect: CGRect(x: ox + 5 * sx, y: oy + 12 * sy, width: 54 * sx, height: 24 * sy), cornerRadius: 4 * sx), with: ink, style: stroke)
                for row in [19.0, 26.0] { for kx in stride(from: 12.0, through: 52.0, by: 8.0) {
                    ctx.stroke(line(kx, row, kx + 2, row), with: ink, style: stroke) } }
                ctx.stroke(line(20, 32, 44, 32), with: ink, style: stroke)
            case .mice:
                ctx.fill(ellipse(32, 44, 12, 2.6), with: underglow)
                ctx.stroke(Path(roundedRect: CGRect(x: ox + 21 * sx, y: oy + 6 * sy, width: 22 * sx, height: 36 * sy), cornerRadius: 11 * sx), with: ink, style: stroke)
                ctx.stroke(line(32, 6, 32, 19), with: ink, style: stroke)
                ctx.stroke(line(21, 19, 43, 19), with: ink, style: stroke)
            case .headsets:
                ctx.fill(ellipse(32, 44, 16, 2.6), with: underglow)
                var band = Path()
                band.move(to: P(14, 30))
                band.addLine(to: P(14, 24))
                band.addArc(center: P(32, 24), radius: 18 * sx, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                band.addLine(to: P(50, 30))
                ctx.stroke(band, with: ink, style: stroke)
                ctx.stroke(Path(roundedRect: CGRect(x: ox + 8 * sx, y: oy + 28 * sy, width: 10 * sx, height: 14 * sy), cornerRadius: 4 * sx), with: ink, style: stroke)
                ctx.stroke(Path(roundedRect: CGRect(x: ox + 46 * sx, y: oy + 28 * sy, width: 10 * sx, height: 14 * sy), cornerRadius: 4 * sx), with: ink, style: stroke)
            }
        }
        .shadow(color: glow ? color.opacity(0.4) : .clear, radius: 8)
    }
}
