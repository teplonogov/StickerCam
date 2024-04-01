import Foundation
import UIKit

enum CameraModuleAssembly {
    static func buildCameraModule() throws -> UIViewController {
        let captureService = CaptureService()
        let brushTexture = UIImage(
            named: "Brush",
            in: .main,
            with: nil
        )?.pngTexture(gpu: .default)
        let stickerProcessor = try StickerProcessor(brushTexture: brushTexture)
        let viewModel = CameraViewModel(
            captureService: captureService,
            stickerProcessor: stickerProcessor
        )
        let controller = CameraController(viewModel: viewModel)
        viewModel.view = controller
        
        return controller
    }
}
