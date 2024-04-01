import Metal
import MetalKit
import MetalPerformanceShaders

final class GPU {
    init?() {
        guard let commandQueue = MTLCreateSystemDefaultDevice()?.makeCommandQueue() else {
            return nil
        }
        
        self.commandQueue = commandQueue
        self.textureLoader = .init(device: commandQueue.device)
        self.imageScaler = MPSImageBilinearScale(device: commandQueue.device)
        self.imageScaler.edgeMode = .clamp
    }
    
    static let `default` = GPU()!
    
    let commandQueue: MTLCommandQueue
    let textureLoader: MTKTextureLoader
    let imageScaler: MPSImageScale
    
    var device: MTLDevice {
        self.commandQueue.device
    }
}
