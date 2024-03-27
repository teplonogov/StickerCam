import Foundation
import UIKit

enum CameraModuleAssembly {
    static func buildCameraModule() -> UIViewController {
        let captureService = CaptureService()
        let viewModel = CameraViewModel(captureService: captureService)
        let controller = CameraController(viewModel: viewModel)
        viewModel.view = controller
        
        return controller
    }
}
