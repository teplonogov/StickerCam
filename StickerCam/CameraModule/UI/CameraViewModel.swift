import Foundation
import AVFoundation
import UIKit.UIImage
import Photos

protocol CameraViewModelProtocol {
    func viewDidLoad()
    func viewDidTapCapture()
    func viewDidTapRetake()
    func viewDidTapMakeSticker()
    func viewDidTapSaveSticker()
}

final class CameraViewModel: CameraViewModelProtocol {
    
    weak var view: CameraView?
    
    private let captureService: CaptureServiceProtocol
    private let stickerProcessor: StickerProcessor
    
    private let paperTexture: MTLTexture? = {
        return UIImage(
            named: "PaperTexture",
            in: .main,
            with: nil
        )?.pngTexture(gpu: .default)
    }()
    private let overlayPaperTexture: MTLTexture? = {
        return UIImage(
            named: "CrumpledPaperTexture",
            in: .main,
            with: nil
        )?.pngTexture(gpu: .default)
    }()
    private var capturedImage: CGImage?
    private var stickerImage: CIImage?
    
    // MARK: - Initializers
    
    init(
        captureService: CaptureServiceProtocol,
        stickerProcessor: StickerProcessor
    ) {
        self.captureService = captureService
        self.stickerProcessor = stickerProcessor
        self.captureService.setDelegate(self)
    }
    
    // MARK: - CameraViewModelProtocol
    
    func viewDidLoad() {
        self.setupCaptureSession()
    }
    
    func viewDidTapCapture() {
        Task(priority: .high) { [weak self] in
            guard let self = self else { return }
            await self.captureService.capturePhoto()
        }
    }
    
    func viewDidTapRetake() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            self.capturedImage = nil
            self.stickerImage = nil
            await self.captureService.resumeSession()
        }
    }
    
    func viewDidTapMakeSticker() {
        guard
            let capturedImage = self.capturedImage,
            let paperTexture = self.paperTexture,
            let overlayPaperTexture = self.overlayPaperTexture
        else { return }
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            do {
                // TODO: Support landscape orientation in CaptureService and here
                let ciImage = CIImage(cgImage: capturedImage).oriented(.right)
                let stickerImage = try await self.stickerProcessor.generateSticker(
                    image: ciImage, 
                    paper: paperTexture,
                    overlayPaper: overlayPaperTexture
                )
                self.stickerImage = stickerImage
                await MainActor.run {
                    let uiSticker = UIImage(ciImage: stickerImage)
                    self.view?.showSticker(uiSticker)
                }
            } catch {
                await MainActor.run {
                    self.view?.showErrorLabel()
                }
            }
        }
    }
    
    func viewDidTapSaveSticker() {
        guard
            let image = self.stickerImage.flatMap({ UIImage(ciImage: $0) }),
            let pngData = image.pngData() else {
            return
        }
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: pngData, options: nil)
                }
                await MainActor.run {
                    self.view?.showSuccesSavingAlert()
                }
            } catch let error {
                // TODO: Handle saving error
                print(error)
            }
        }
    }
    
    // MARK: - Private
    
    private func setupCaptureSession() {
        Task.detached(priority: .userInitiated) {
            do {
                let layer = try await self.captureService.setupSession()
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.view?.showCaptureLayer(layer)
                }
            } catch let error as CaptureServiceErrors {
                // TODO: Handle error. Show alert or smthng.
                print(error)
            }
        }
    }
}

// MARK: - CaptureServiceDelegate

extension CameraViewModel: CaptureServiceDelegate {
    func willStartCapturing() {
        self.view?.closeShutter()
    }
    
    func willFinishCapturing() {
        self.view?.openShutter()
    }
    
    func didFinishCapturing(photo: AVCapturePhoto) {
        guard let cgImg = photo.cgImageRepresentation() else { return }
        let img = UIImage(cgImage: cgImg, scale: 1.0, orientation: .right)
        self.view?.showCapturedImage(img)
        self.capturedImage = cgImg
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            await self.captureService.stopSession()
        }
    }
}
