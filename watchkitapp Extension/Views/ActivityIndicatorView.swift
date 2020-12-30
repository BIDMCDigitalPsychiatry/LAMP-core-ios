// watchkitapp Extension

import SwiftUI

struct ActivityIndicatorView: View {

    // MARK: - Value
    // MARK: Public
    @Binding var isAnimating: Bool


    // MARK: Private
    private let radius: CGFloat = 24.0
    private let count = 18
    private let interval: TimeInterval = 0.1

    private let point = { (index: Int, count: Int, radius: CGFloat, frame: CGRect) -> CGPoint in
        let angle   = 2.0 * .pi / Double(count) * Double(index)
        let circleX = radius * cos(CGFloat(angle))
        let circleY = radius * sin(CGFloat(angle))

       return CGPoint(x: circleX + frame.midX, y: circleY + frame.midY)
   }

   private let timer = Timer.publish(every: 1.8, on: .main, in: .common).autoconnect()     // every(1.8) = count(18) / interval(0.1)

   @State private var scale: CGFloat  = 0
   @State private var opacity: Double = 0

   // MARK: - View
   var body: some View {
       GeometryReader { geometry in
            ForEach(0..<self.count) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 3.0, height: 3.0)
                    .animation(nil)
                    .opacity(self.opacity)
                    .scaleEffect(self.scale)
                    .position(self.point(index, self.count, self.radius, geometry.frame(in: .local)))
                    .animation(
                        Animation.easeOut(duration: 1.0)
                            .repeatCount(1, autoreverses: true)
                            .delay(TimeInterval(index) * self.interval)
                     )
             }
             .onReceive(self.timer) { output in
                self.update()
             }
        }
        .rotationEffect(.degrees(10.0))
        .opacity(isAnimating == false ? 0 : 1.0)
        .onAppear {
            self.update()
        }
    }



    // MARK: - Function
    // MARK: Private
    private func update() {
        scale   = 0 < scale ? 0 : 1.0
        opacity = 0 < opacity ? 0 : 1.0

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.scale   = 0
            self.opacity = 0
        }
    }
}
