import Foundation
import Metal

final class StickerKernel {
    enum Errors: Error {
        case failedCommandEncoderCreation
    }
    
    init(library: MTLLibrary) throws {
        self.pipelineState = try library.makeComputePipelineState(function: "stickerKernel")
    }
    
    // MARK: - Public
    
    func encode(
        sticker: MTLTexture,
        paperMask: MTLTexture,
        paperTexture: MTLTexture,
        overlayPaperTexture: MTLTexture,
        destination: MTLTexture,
        in commandBuffer: MTLCommandBuffer
    ) throws {
        guard let encoder = commandBuffer.makeComputeCommandEncoder()
        else {
            throw Errors.failedCommandEncoderCreation
        }
        
        encoder.label = "Sticker"
        let _threadgroupSize = self.pipelineState.maxThreadsPerThreadgroup2D
        encoder.setTexture(sticker, index: 0)
        encoder.setTexture(paperMask, index: 1)
        encoder.setTexture(paperTexture, index: 2)
        encoder.setTexture(overlayPaperTexture, index: 3)
        encoder.setTexture(destination, index: 4)
        encoder.dispatch2D(
            state: self.pipelineState,
            exact: destination.size,
            threadgroupSize: _threadgroupSize
        )
        
        encoder.endEncoding()
    }
    
    // MARK: - Private
    
    private let pipelineState: MTLComputePipelineState
}
