import Foundation
import simd

struct Point {
    
    var position: simd_float4
    var color: simd_float4
    var angle: Float
    var size: Float
    var hardness: Float
    
    init(
        x: Float,
        y: Float,
        color: BrushColor,
        size: Float,
        angle: Float = 0,
        hardness: Float = 1
    ) {
        self.position = SIMD4<Float>(x, y, 0, 1)
        self.size = size
        self.color = color
        self.angle = angle
        self.hardness = hardness
    }
}
