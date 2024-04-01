import Foundation
import simd

struct BrushLine {
    var begin: SIMD2<Float>
    var end: SIMD2<Float>

    var pointSize: Float
    var pointStep: Float
    var color: BrushColor

    var length: Float {
        self.begin.distance(to: self.end)
    }

    init(
        begin: SIMD2<Float>,
        end: SIMD2<Float>,
        pointSize: Float,
        pointStep: Float,
        color: BrushColor
    ) {
        self.begin = begin
        self.end = end
        self.pointSize = pointSize
        self.pointStep = pointStep
        self.color = color
    }
}
