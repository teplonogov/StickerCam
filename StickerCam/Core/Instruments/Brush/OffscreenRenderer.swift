import Metal

final class OffscreenRenderer {
    
    var texture: MTLTexture! {
        self.renderPassDescriptor.colorAttachments[0].resolveTexture
            ?? self.renderPassDescriptor.colorAttachments[0].texture
    }
    
    private let textureWidth: Int
    private let textureHeight: Int
    private let pixelFormat: MTLPixelFormat
    
    init(
        in context: GPU,
        width: Int,
        height: Int,
        pixelFormat: MTLPixelFormat,
        clearColor: MTLClearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    ) throws {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor

        let targetTexture = try context.device.texture2D(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            usage: [.shaderRead, .shaderWrite, .renderTarget]
        )
        renderPassDescriptor.colorAttachments[0].texture = targetTexture
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        renderPassDescriptor.stencilAttachment.storeAction = .dontCare
        renderPassDescriptor.stencilAttachment.loadAction = .dontCare

        self.renderPassDescriptor = renderPassDescriptor
        self.textureWidth = width
        self.textureHeight = height
        self.pixelFormat = pixelFormat
    }

    // MARK: - Public

    func draw(
        in commandBuffer: MTLCommandBuffer,
        drawCommands: (MTLRenderCommandEncoder) -> Void
    ) {
        commandBuffer.render(descriptor: self.renderPassDescriptor) {
            drawCommands($0)
        }
    }

    // MARK: Private

    private var renderPassDescriptor: MTLRenderPassDescriptor
}
