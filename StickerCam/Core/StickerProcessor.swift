import Metal
import MetalPerformanceShaders
import CoreImage

enum StickerProcessorErrors: Error {
    case maskGenerationFailed
    case strokeRenderError
    case stickerApplyError
}

final class StickerProcessor {
    
    private let gpu: GPU
    private let mtlLib: MTLLibrary
    private let segmentationService: SegmentationService
    private let alphaMaskKernel: AlphaMaskKernel
    private let paperMaskKernel: PaperMaskKernel
    private let stickerKernel: StickerKernel
    private let brush: Brush
    private let ciContext: CIContext
    private let renderData = BrushRenderData()
    
    init(brushTexture: MTLTexture?) throws {
        let gpu = GPU.default
        let mtlLib = try gpu.device.makeDefaultLibrary(bundle: .main)
        self.gpu = gpu
        self.mtlLib = mtlLib
        self.segmentationService = SegmentationService()
        self.alphaMaskKernel = try AlphaMaskKernel(library: mtlLib)
        self.paperMaskKernel = try PaperMaskKernel(library: mtlLib)
        self.stickerKernel = try StickerKernel(library: mtlLib)
        self.brush = try Brush(gpu: gpu, texture: brushTexture, library: mtlLib)
        self.ciContext = CIContext(mtlCommandQueue: gpu.commandQueue)
    }
    
    // MARK: - Public
    
    func generateSticker(image: CIImage, paperTexture: MTLTexture) async throws -> CIImage {
        let (stickerImage, strokeScale) = try await self.segmentationService.generateStickerImage(
            from: image,
            brushSize: CGFloat(self.brush.pointSize)
        )
                
        let (stickerTexture, maskTexture) = try self.prepareMask(image: stickerImage)

        guard let maskImage = CIImage(
            mtlTexture: maskTexture
        ) else {
            throw StickerProcessorErrors.maskGenerationFailed
        }
        
        let strokePoints = try await self.segmentationService.generateStrokePoints(
            for: maskImage
        )

        let strokedTexture = try self.processStrokeTexture(
            points: strokePoints, size: maskTexture.size, scale: strokeScale
        )
                
        let paperMask = try self.preparePaperMask(stickerMask: maskTexture, strokeMask: strokedTexture)
        
        let stickerResult = try maskTexture.matchingTexture()
        let resizedPaperTexture = try maskTexture.matchingTexture()
        
        let commandBuffer = MPSCommandBuffer(from: self.gpu.commandQueue)
        
        self.gpu.imageScaler.encode(
            commandBuffer: commandBuffer,
            sourceTexture: paperTexture,
            destinationTexture: resizedPaperTexture
        )
        try self.stickerKernel.encode(
            sticker: stickerTexture,
            paperMask: paperMask,
            paperTexture: resizedPaperTexture,
            destination: stickerResult,
            in: commandBuffer
        )
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        if let resultImage = CIImage(
            mtlTexture: stickerResult,
            options: [CIImageOption.colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!]
        ) {
            return resultImage
        } else {
            throw StickerProcessorErrors.stickerApplyError
        }
    }
    
    // MARK: - Private
    
    private func prepareMask(image: CIImage) throws -> (MTLTexture, MTLTexture) {
        let commandBuffer = MPSCommandBuffer(from: self.gpu.commandQueue)
        let source = try self.renderCIImageToTexture(ciImage: image, commandBuffer: commandBuffer)
        let mask = try source.matchingTexture()
        try self.alphaMaskKernel.encode(
            source: source,
            destination: mask,
            in: commandBuffer
        )
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return (source, mask)
    }
    
    private func processStrokeTexture(
        points: [SIMD2<Float>],
        size: MTLSize,
        scale: Float
    ) throws -> MTLTexture {
        self.brush.canvasSize = SIMD2<Float>(
            Float(size.width), Float(size.height)
        )

        guard
            let strokeData = self.brush.drawLine(
                vertices: points, scale: scale
            ) else {
            throw StickerProcessorErrors.strokeRenderError
        }
        
        let brushRenderer = try BrushRenderer(
            gpu: self.gpu,
            library: self.mtlLib,
            textureSize: size
        )
        brushRenderer.draw(strokes: [strokeData])
        
        if let result = brushRenderer.texture {
            return result
        } else {
            throw StickerProcessorErrors.strokeRenderError
        }
    }
    
    private func preparePaperMask(
        stickerMask: MTLTexture,
        strokeMask: MTLTexture
    ) throws -> MTLTexture {
        let paperMask = try stickerMask.matchingTexture()
        
        let commandBuffer = MPSCommandBuffer(from: self.gpu.commandQueue)
        
        try self.paperMaskKernel.encode(
            stickerMask: stickerMask,
            strokeMask: strokeMask,
            destination: paperMask,
            in: commandBuffer
        )
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return paperMask
    }
    
    private func renderCIImageToTexture(
        ciImage: CIImage,
        pixelFormat: MTLPixelFormat = .rgba8Unorm,
        commandBuffer: MPSCommandBuffer? = nil
    ) throws -> MTLTexture {
        let destinationTexture = try self.gpu.device.texture2D(
            pixelFormat: pixelFormat,
            width: Int(ciImage.extent.width),
            height: Int(ciImage.extent.height)
        )
        
        self.ciContext.render(
            ciImage,
            to: destinationTexture,
            commandBuffer: commandBuffer,
            bounds: ciImage.extent,
            colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!
        )
        return destinationTexture
    }
}
