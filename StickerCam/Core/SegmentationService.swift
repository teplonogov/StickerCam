import Foundation
import Vision
import CoreImage.CIFilterBuiltins

final class SegmentationService {
        
    // MARK: - Public
    
    func generateStickerImage(
        from image: CIImage, brushSize: CGFloat
    ) async throws -> (CIImage, Float) {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: image)

        do {
            try handler.perform([request])
        } catch {
            throw SegmentationErrors.stickerGenerationError
        }

        guard
            let maskResult = request.results?.first
        else {
            throw SegmentationErrors.stickerGenerationError
        }
                
        let stickerPixelBuffer = try maskResult.generateMaskedImage(
            ofInstances: maskResult.allInstances,
            from: handler,
            croppedToInstancesExtent: true
        )
        let stickerImage = CIImage(cvPixelBuffer: stickerPixelBuffer)
        
        let smallestSize: CGFloat = min(stickerImage.extent.width, stickerImage.extent.height)
        let brushScale = smallestSize / (4 * brushSize)
        
        // padding is additional space for stroke
        let paddedSticker = self.paddedImage(
            inputImage: stickerImage, padding: brushSize * brushScale
        )
        
        return (paddedSticker, Float(brushScale))
    }
    
    func generateStrokePoints(for mask: CIImage) async throws -> [SIMD2<Float>] {
        let contourRequest = VNDetectContoursRequest()
        
        let contourHandler = VNImageRequestHandler(ciImage: mask)
        try contourHandler.perform([contourRequest])
        
        guard let contourResult = contourRequest.results?.first else {
            throw SegmentationErrors.strokeError
        }
        // 0 – frame border of image. 1 - foreground.
        let contour = try contourResult.contour(at: 1)
        
        let normalizedPoints = contour.normalizedPoints
        
        let points = normalizedPoints.map { point in
            return SIMD2<Float>(point.x * Float(mask.extent.width) - Float(mask.extent.width) / 2, (1 - point.y) * Float(mask.extent.height) - Float(mask.extent.height) / 2)
        }
        
        return points
    }

    // MARK: - Private
    
    /// Returns the same image with paddings
    private func paddedImage(inputImage: CIImage, padding: CGFloat) -> CIImage {
        let cgRect = CGRect(
            origin: inputImage.extent.origin,
            size: CGSize(
                width: inputImage.extent.width + padding * 2,
                height: inputImage.extent.height + padding * 2
            )
        )
        let bgImage = CIImage(color: CIColor.clear).cropped(to: cgRect)
        let filter = CIFilter.sourceOverCompositing()
        filter.backgroundImage = bgImage
        filter.inputImage = inputImage.transformed(
            by: CGAffineTransform(translationX: padding, y: padding)
        )
        
        let result = filter.outputImage!
        
        return result
    }
}

enum SegmentationErrors: Error {
    case strokeError
    case stickerGenerationError
}
