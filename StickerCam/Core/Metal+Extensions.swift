import Foundation
import Metal
import UIKit.UIImage

public extension MTLLibrary {
    func makeComputePipelineState(
        function: String
    ) throws -> MTLComputePipelineState {
        try self.device.makeComputePipelineState(
            function: self.makeFunction(
                name: function,
                constantValues: MTLFunctionConstantValues()
            )
        )
    }
}

public extension MTLDevice {
    func texture2D(
        pixelFormat: MTLPixelFormat,
        width: Int,
        height: Int,
        usage: MTLTextureUsage = [.shaderRead, .shaderWrite],
        storageMode: MTLStorageMode? = nil,
        mipmapped: Bool = false
    ) throws -> MTLTexture {
        guard width > 0, height > 0 else {
            throw MTLDeviceErrors.creationTextureFailed
        }
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: mipmapped
        )
        descriptor.usage = usage
        
        if let storageMode = storageMode {
            descriptor.storageMode = storageMode
        }
        
        return try self.texture(descriptor: descriptor)
    }
    
    func texture(descriptor: MTLTextureDescriptor) throws -> MTLTexture {
        guard let t = self.makeTexture(descriptor: descriptor) else {
            throw MTLDeviceErrors.creationTextureFailed
        }
        return t
    }
}

enum MTLDeviceErrors: Error {
    case creationTextureFailed
}

extension MTLTexture {
    var descriptor: MTLTextureDescriptor {
        let retVal = MTLTextureDescriptor()
        
        retVal.width = width
        retVal.height = height
        retVal.depth = depth
        retVal.arrayLength = arrayLength
        retVal.storageMode = storageMode
        retVal.cpuCacheMode = cpuCacheMode
        retVal.usage = usage
        retVal.textureType = textureType
        retVal.sampleCount = sampleCount
        retVal.mipmapLevelCount = mipmapLevelCount
        retVal.pixelFormat = pixelFormat
        if #available(iOS 12, macOS 10.14, *) {
            retVal.allowGPUOptimizedContents = allowGPUOptimizedContents
        }
        
        return retVal
    }
    
    func matchingTexture(
        usage: MTLTextureUsage? = nil,
        storage: MTLStorageMode? = nil
    ) throws -> MTLTexture {
        let matchingDescriptor = self.descriptor
        
        if let u = usage {
            matchingDescriptor.usage = u
        }
        if let s = storage {
            matchingDescriptor.storageMode = s
        }
        
        guard let matchingTexture = self.device.makeTexture(descriptor: matchingDescriptor)
        else { throw MTLError.textureCreationFailed }
        
        return matchingTexture
    }
}

enum MTLError: Error {
    case textureCreationFailed
    case cgImageCreationFailed
}

extension MTLCommandBuffer {
    private func encode<T: MTLCommandEncoder>(
        commands: (T) throws -> Void,
        makeEncoder: () -> T?
    ) rethrows {
        guard let encoder = makeEncoder() else {
            assertionFailure()
            return
        }
        try commands(encoder)
        encoder.endEncoding()
    }

    func compute(_ commands: (MTLComputeCommandEncoder) throws -> Void) rethrows {
        try self.encode(commands: commands, makeEncoder: self.makeComputeCommandEncoder)
    }

    func blit(_ commands: (MTLBlitCommandEncoder) throws -> Void) rethrows {
        try self.encode(commands: commands, makeEncoder: self.makeBlitCommandEncoder)
    }

    func render(
        descriptor: MTLRenderPassDescriptor,
        _ commands: (MTLRenderCommandEncoder) throws -> Void
    ) rethrows {
        try self.encode(commands: commands, makeEncoder: {
            self.makeRenderCommandEncoder(descriptor: descriptor)
        })
    }
}

extension MTLComputeCommandEncoder {
    func dispatch2D(
        state: MTLComputePipelineState,
        exact gridSize: MTLSize,
        threadgroupSize: MTLSize? = nil
    ) {
        let threadgroupSize = threadgroupSize ?? state.maxThreadsPerThreadgroup2D

        assert(threadgroupSize.width > 0 && threadgroupSize.height > 0 && threadgroupSize.depth > 0)
        assert(gridSize.width > 0 && gridSize.height > 0 && gridSize.depth > 0)

        self.setComputePipelineState(state)

        self.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroupSize)
    }
}

// https://developer.apple.com/documentation/metal/compute_passes/calculating_threadgroup_and_grid_sizes
public extension MTLComputePipelineState {
    var maxThreadsPerThreadgroup2D: MTLSize {
        let w = self.threadExecutionWidth
        let h = self.maxTotalThreadsPerThreadgroup / w

        return MTLSize(width: w, height: h, depth: 1)
    }
}

public extension MTLTexture {
    var size: MTLSize {
        MTLSize(width: self.width, height: self.height, depth: self.depth)
    }
}

extension UIImage {
    func pngTexture(gpu: GPU) -> MTLTexture? {
        guard let pngData = pngData() else { return nil }
        let usage: MTLTextureUsage = [.shaderRead, .pixelFormatView]
        let texture = try? gpu.textureLoader.newTexture(
            data: pngData,
            options: [.textureUsage: NSNumber(value: usage.rawValue)]
        )
        return texture
    }
}
