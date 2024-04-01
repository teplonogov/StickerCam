import Metal
import MetalPerformanceShaders

final class BrushRenderer {
    
    var texture: MTLTexture? { self.offscreenRenderer.texture }
    
    private let gpu: GPU
    private let textureSize: MTLSize
    private let library: MTLLibrary
    private let offscreenRenderer: OffscreenRenderer
    
    // MARK: - Init

    init(gpu: GPU, library: MTLLibrary, textureSize: MTLSize) throws {
        self.gpu = gpu
        self.library = library
        self.textureSize = textureSize
        self.offscreenRenderer = try .init(
            in: self.gpu,
            width: textureSize.width,
            height: textureSize.height,
            pixelFormat: .rgba8Unorm
        )
    }
    
    // MARK: - Public

    func draw(strokes: [BrushStrokeData]) {
        let commandBuffer = MPSCommandBuffer(from: self.gpu.commandQueue)
        self.offscreenRenderer.draw(in: commandBuffer) { encoder in
            encoder.label = "Brush renderer"
            
            // For performance reasons until we dont use different brush textures
            guard let firstStroke = strokes.first else { return }
            if let texture = firstStroke.brush.texture {
                encoder.setFragmentTexture(texture, index: 0)
            }
            
            var currentPipelineState: MTLRenderPipelineState?
            
            for stroke in strokes {
                if currentPipelineState == nil || stroke.brush.pipelineState.label != currentPipelineState?.label {
                    encoder.setRenderPipelineState(stroke.brush.pipelineState)
                    currentPipelineState = stroke.brush.pipelineState
                }
                var color = stroke.brush.renderingColor
                encoder.setFragmentBytes(&color, length: 32, index: 0)
                
                if let vertexBuffer = stroke.vertexBuffer {
                    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                    encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: stroke.vertexCount)
                }
            }
        }
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
