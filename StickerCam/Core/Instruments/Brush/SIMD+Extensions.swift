import Foundation
import Darwin

public extension SIMD2 where Scalar == Float {
    func distance(to point: SIMD2<Float>) -> Float {
        sqrt(
            (self.x - point.x) * (self.x - point.x) +
                (self.y - point.y) * (self.y - point.y)
        )
    }
}
