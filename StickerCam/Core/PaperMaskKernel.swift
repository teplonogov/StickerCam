import Foundation
import Metal

final class PaperMaskKernel {
    enum Errors: Error {
        case failedCommandEncoderCreation
    }
    
    init(library: MTLLibrary) throws {
        self.pipelineState = try library.makeComputePipelineState(function: "paperMaskKernel")
    }
    
    // MARK: - Public
    
    func encode(
        stickerMask: MTLTexture,
        strokeMask: MTLTexture,
        destination: MTLTexture,
        in commandBuffer: MTLCommandBuffer
    ) throws {
        guard let encoder = commandBuffer.makeComputeCommandEncoder()
        else {
            throw Errors.failedCommandEncoderCreation
        }
        
        encoder.label = "PaperMask"
        let _threadgroupSize = self.pipelineState.maxThreadsPerThreadgroup2D
        encoder.setTexture(stickerMask, index: 0)
        encoder.setTexture(strokeMask, index: 1)
        encoder.setTexture(destination, index: 2)
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
