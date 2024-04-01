import Foundation
import Metal

final class BrushRenderData {
    var strokes: [BrushStrokeData] = []
    var step: Int = 0

    func addStroke(_ stroke: BrushStrokeData) {
        if self.step < self.strokes.count {
            self.strokes.removeLast(self.strokes.count - self.step)
        }
        self.strokes.append(stroke)
        self.step = self.strokes.count
    }
}

struct BrushStrokeData {
    var vertexBuffer: MTLBuffer?
    var vertexCount = 0
    var brush: Brush
}
