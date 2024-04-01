import Foundation
import Metal
import UIKit.UIColor

class Brush {

    init(
        gpu: GPU,
        texture: MTLTexture?,
        library: MTLLibrary
    ) throws {
        self.gpu = gpu
        self.texture = texture
        self.pipelineState = try self.makePipelineState(gpu: gpu, library: library)
    }

    // MARK: Internal

    var canvasSize: SIMD2<Float> = .init(0, 0)
    var renderingColor: BrushColor = UIColor.white.toBrushColor()
    let pointSize: Float = 200

    private let gpu: GPU
    private(set) var pipelineState: MTLRenderPipelineState!
    private(set) var texture: MTLTexture?
    private var initialPointStep: Float {
        self.pointSize / 4
    }
    private var currentStrokeVertices: [Point] = []
    
    // MARK: - Public
    
    func drawLine(
        vertices: [SIMD2<Float>],
        scale: Float
    ) -> BrushStrokeData? {
        var lines: [BrushLine] = []

        guard vertices.count >= 2 else {
            return nil
        }

        var lastPoint = vertices[0]
        let pointStep = self.initialPointStep * scale

        for i in 1 ..< vertices.count {
            let point = vertices[i]
            if (i == vertices.count - 1) ||
                pointStep <= 1 ||
                (pointStep > 1 && lastPoint.distance(to: point) >= Float(pointStep))
            {
                let line = self.makeLine(from: lastPoint, to: point, scale: scale)
                lines.append(contentsOf: line)
                lastPoint = point
            }
        }

        return self.updateVertexBuffer(with: lines)
    }
    
    // MARK: - Private

    private func makeRenderPipelineDescriptor(gpu: GPU, library: MTLLibrary) -> MTLRenderPipelineDescriptor {
        let rpd = MTLRenderPipelineDescriptor()

        rpd.label = "Brush render pipeline"

        if let vertex_func = library.makeFunction(name: "vertex_point_func") {
            rpd.vertexFunction = vertex_func
        }
        if let fragment_func = library.makeFunction(name: "fragment_point_func") {
            rpd.fragmentFunction = fragment_func
        }

        rpd.colorAttachments[0].pixelFormat = .rgba8Unorm

        self.setupBlendOptions(for: rpd.colorAttachments[0])

        return rpd
    }

    private func makePipelineState(gpu: GPU, library: MTLLibrary) throws -> MTLRenderPipelineState {
        let rpd = self.makeRenderPipelineDescriptor(gpu: gpu, library: library)
        return try gpu.device.makeRenderPipelineState(descriptor: rpd)
    }

    private func setupBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
        attachment.isBlendingEnabled = true

        attachment.rgbBlendOperation = .add
        attachment.sourceRGBBlendFactor = .sourceAlpha
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha

        attachment.alphaBlendOperation = .add
        attachment.sourceAlphaBlendFactor = .one
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
    
    private func makeLine(
        from: SIMD2<Float>,
        to: SIMD2<Float>,
        scale: Float
    ) -> [BrushLine] {
        let line = BrushLine(
            begin: from,
            end: to,
            pointSize: Float(self.pointSize * scale),
            pointStep: Float(self.initialPointStep * scale),
            color: self.renderingColor
        )

        return [line]
    }

    private func updateVertexBuffer(with lines: [BrushLine]) -> BrushStrokeData? {
        guard self.canvasSize.x > 0, self.canvasSize.y > 0 else { return nil }
        
        var newVertices: [Point] = []
        
        lines.forEach { line in
            let count = max(line.length / line.pointStep, 1)
            
            var line = line
            line.begin = line.begin
            line.end = line.end
            
            for i in 0 ..< Int(count) {
                let index = Float(i)
                let x = line.begin.x + (line.end.x - line.begin.x) * (index / count)
                let y = line.begin.y + (line.end.y - line.begin.y) * (index / count)
                
                // Random angle from 0 to 360
                let angle: Float = Float.random(
                    in: Range(uncheckedBounds: (0, 2 * Float.pi))
                )
                
                newVertices.append(
                    Point(
                        x: x * (2 / self.canvasSize.x),
                        y: y * (2 / self.canvasSize.y),
                        color: line.color,
                        size: line.pointSize,
                        angle: angle,
                        hardness: 1
                    )
                )
            }
        }
        
        self.currentStrokeVertices.append(contentsOf: newVertices)
        let currentStrokeVerticesCount = self.currentStrokeVertices.count
        
        let currentStrokeVerticesBuffer = self.gpu.device.makeBuffer(
            bytes: self.currentStrokeVertices,
            length: MemoryLayout<Point>.stride * currentStrokeVerticesCount,
            options: .cpuCacheModeWriteCombined
        )
        self.currentStrokeVertices = []
        
        return BrushStrokeData(
            vertexBuffer: currentStrokeVerticesBuffer,
            vertexCount: currentStrokeVerticesCount,
            brush: self
        )
    }
}
