import Foundation
import Metal

final class AlphaMaskKernel {
    enum Errors: Error {
        case failedCommandEncoderCreation
    }
    
    init(library: MTLLibrary) throws {
        self.pipelineState = try library.makeComputePipelineState(function: "alphaMaskKernel")
    }
    
    // MARK: - Public
    
    func encode(
        source: MTLTexture,
        destination: MTLTexture,
        in commandBuffer: MTLCommandBuffer
    ) throws {
        guard let encoder = commandBuffer.makeComputeCommandEncoder()
        else {
            throw Errors.failedCommandEncoderCreation
        }
        
        encoder.label = "AlphaMask"
        let _threadgroupSize = self.pipelineState.maxThreadsPerThreadgroup2D
        encoder.setTexture(source, index: 0)
        encoder.setTexture(destination, index: 1)
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
