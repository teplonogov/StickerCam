import Foundation
import AVFoundation

protocol CaptureServiceDelegate: AnyObject {
    func willStartCapturing()
    func willFinishCapturing()
    func didFinishCapturing(photo: AVCapturePhoto)
}

protocol CaptureServiceProtocol {
    func setDelegate(_ delegate: CaptureServiceDelegate?)
    func setupSession() async throws -> AVCaptureVideoPreviewLayer
    func capturePhoto() async
    func stopSession() async
    func resumeSession() async
}

final class CaptureService: NSObject, CaptureServiceProtocol {
    
    private weak var delegate: CaptureServiceDelegate?
    private let captureSession = AVCaptureSession()
    private let photoOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()
    
    // MARK: - CameraServiceProtocol
    
    func setDelegate(_ delegate: CaptureServiceDelegate?) {
        self.delegate = delegate
    }
    
    func setupSession() async throws -> AVCaptureVideoPreviewLayer {
        guard 
            let wideCameraDevice = AVCaptureDevice.wideDevice,
            let wideInput = try? AVCaptureDeviceInput(device: wideCameraDevice)
        else {
            throw CaptureServiceErrors.noDevice
        }
        
        self.captureSession.beginConfiguration()
        
        self.captureSession.inputs.forEach { input in
            if let deviceInput = input as? AVCaptureDeviceInput {
                self.captureSession.removeInput(deviceInput)
            }
        }
        
        guard 
            self.captureSession.canAddInput(wideInput),
            self.captureSession.canAddOutput(self.photoOutput)
        else {
            throw CaptureServiceErrors.failedCaptureInputOrOutput
        }
        
        self.captureSession.addInput(wideInput)
        self.captureSession.addOutput(self.photoOutput)
        
        if self.captureSession.canSetSessionPreset(.photo) {
            self.captureSession.sessionPreset = .photo
        }
        
        self.captureSession.commitConfiguration()
        self.captureSession.startRunning()
        
        return AVCaptureVideoPreviewLayer(session: self.captureSession)
    }
    
    func capturePhoto() async {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.photoQualityPrioritization = .speed
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func stopSession() async {
        guard self.captureSession.isRunning else { return }
        self.captureSession.stopRunning()
    }
    
    func resumeSession() async {
        guard !self.captureSession.isRunning else { return }
        self.captureSession.startRunning()
    }
    
    // MARK: - Private
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CaptureService: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        self.delegate?.willStartCapturing()
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        self.delegate?.willFinishCapturing()
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil else {
            // TODO: Handle error
            return
        }
        self.delegate?.didFinishCapturing(photo: photo)
    }
}

enum CaptureServiceErrors: Error {
    case noDevice
    case failedCaptureInputOrOutput
}

extension AVCaptureDevice {
    static var wideDevice: AVCaptureDevice? {
        return AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        )
    }
}
