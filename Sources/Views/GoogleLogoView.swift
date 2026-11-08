import SwiftUI

struct GoogleLogoView: View {
    var size: CGFloat = 20
    
    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let scale = min(w, h) / 48.0
            
            context.translateBy(x: (w - 48 * scale) / 2, y: (h - 48 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            
            // Path 1: Red (Top curve)
            var redPath = Path()
            redPath.move(to: CGPoint(x: 24, y: 9.5))
            redPath.addCurve(to: CGPoint(x: 33.21, y: 13.1), control1: CGPoint(x: 27.54, y: 9.5), control2: CGPoint(x: 30.71, y: 10.72))
            redPath.addLine(to: CGPoint(x: 40.06, y: 6.25))
            redPath.addCurve(to: CGPoint(x: 24, y: 0), control1: CGPoint(x: 35.9, y: 2.38), control2: CGPoint(x: 30.47, y: 0))
            redPath.addCurve(to: CGPoint(x: 2.56, y: 13.22), control1: CGPoint(x: 14.62, y: 0), control2: CGPoint(x: 6.51, y: 5.38))
            redPath.addLine(to: CGPoint(x: 10.54, y: 19.41))
            redPath.addCurve(to: CGPoint(x: 24, y: 9.5), control1: CGPoint(x: 12.43, y: 13.72), control2: CGPoint(x: 17.74, y: 9.5))
            redPath.closeSubpath()
            context.fill(redPath, with: .color(Color(red: 234/255, green: 67/255, blue: 53/255)))
            
            // Path 2: Blue (Right horizontal bar and bottom right curve)
            var bluePath = Path()
            bluePath.move(to: CGPoint(x: 46.98, y: 24.55))
            bluePath.addCurve(to: CGPoint(x: 46.6, y: 20), control1: CGPoint(x: 46.98, y: 22.98), control2: CGPoint(x: 46.83, y: 21.46))
            bluePath.addLine(to: CGPoint(x: 24, y: 20))
            bluePath.addLine(to: CGPoint(x: 24, y: 29.02))
            bluePath.addLine(to: CGPoint(x: 36.94, y: 29.02))
            bluePath.addCurve(to: CGPoint(x: 32.16, y: 36.2), control1: CGPoint(x: 36.36, y: 31.98), control2: CGPoint(x: 34.68, y: 34.5))
            bluePath.addLine(to: CGPoint(x: 39.89, y: 42.2))
            bluePath.addCurve(to: CGPoint(x: 46.98, y: 24.55), control1: CGPoint(x: 44.4, y: 38.02), control2: CGPoint(x: 46.98, y: 31.84))
            bluePath.closeSubpath()
            context.fill(bluePath, with: .color(Color(red: 66/255, green: 133/255, blue: 244/255)))
            
            // Path 3: Yellow (Left curve)
            var yellowPath = Path()
            yellowPath.move(to: CGPoint(x: 10.53, y: 28.59))
            yellowPath.addCurve(to: CGPoint(x: 9.77, y: 24), control1: CGPoint(x: 10.05, y: 27.14), control2: CGPoint(x: 9.77, y: 25.6))
            yellowPath.addCurve(to: CGPoint(x: 10.53, y: 19.41), control1: CGPoint(x: 9.77, y: 22.4), control2: CGPoint(x: 10.05, y: 20.86))
            yellowPath.addLine(to: CGPoint(x: 2.55, y: 13.22))
            yellowPath.addCurve(to: CGPoint(x: 0, y: 24), control1: CGPoint(x: 0.92, y: 16.46), control2: CGPoint(x: 0, y: 20.12))
            yellowPath.addCurve(to: CGPoint(x: 2.56, y: 34.78), control1: CGPoint(x: 0, y: 27.88), control2: CGPoint(x: 0.92, y: 31.54))
            yellowPath.addLine(to: CGPoint(x: 10.53, y: 28.59))
            yellowPath.closeSubpath()
            context.fill(yellowPath, with: .color(Color(red: 251/255, green: 188/255, blue: 5/255)))
            
            // Path 4: Green (Bottom curve)
            var greenPath = Path()
            greenPath.move(to: CGPoint(x: 24, y: 48))
            greenPath.addCurve(to: CGPoint(x: 39.89, y: 42.19), control1: CGPoint(x: 30.48, y: 48), control2: CGPoint(x: 35.93, y: 45.87))
            greenPath.addLine(to: CGPoint(x: 32.16, y: 36.19))
            greenPath.addCurve(to: CGPoint(x: 24, y: 38.49), control1: CGPoint(x: 30.01, y: 37.64), control2: CGPoint(x: 27.24, y: 38.49))
            greenPath.addCurve(to: CGPoint(x: 10.53, y: 28.58), control1: CGPoint(x: 17.74, y: 38.49), control2: CGPoint(x: 12.43, y: 34.27))
            greenPath.addLine(to: CGPoint(x: 2.55, y: 34.77))
            greenPath.addCurve(to: CGPoint(x: 24, y: 48), control1: CGPoint(x: 6.51, y: 42.62), control2: CGPoint(x: 14.62, y: 48))
            greenPath.closeSubpath()
            context.fill(greenPath, with: .color(Color(red: 52/255, green: 168/255, blue: 83/255)))
        }
        .frame(width: size, height: size)
    }
}

