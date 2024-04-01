import Foundation
import simd
import UIKit

typealias BrushColor = SIMD4<Float>

extension UIColor {
    func toBrushColor() -> BrushColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)

        return SIMD4<Float>(Float(r), Float(g), Float(b), Float(a))
    }
}
