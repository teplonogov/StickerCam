import Foundation

protocol CameraViewModelProtocol {
    func viewDidLoad()
}

final class CameraViewModel: CameraViewModelProtocol {
    
    weak var view: CameraView?
    
    private let captureService: CaptureServiceProtocol
    
    // MARK: - Initializers
    
    init(captureService: CaptureServiceProtocol) {
        self.captureService = captureService
    }
    
    // MARK: - CameraViewModelProtocol
    
    func viewDidLoad() {
        self.setupCaptureSession()
    }
    
    // MARK: - Private
    
    private func setupCaptureSession() {
        Task.detached {
            do {
                let layer = try await self.captureService.setupSession()
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.view?.showCaptureLayer(layer)
                }
            } catch let error as CaptureServiceErrors {
                print(error)
                // TODO: Handle error. Show alert or smthng.
            }
        }
    }
}
