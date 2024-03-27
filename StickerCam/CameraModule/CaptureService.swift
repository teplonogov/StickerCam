import Foundation
import AVFoundation

protocol CaptureServiceProtocol {
    func setupSession() async throws -> AVCaptureVideoPreviewLayer
}

final class CaptureService: CaptureServiceProtocol {
    
    private let captureSession = AVCaptureSession()
//    private var captureInput: AVCaptureInput?
    private let photoOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()
//    private let streamOutput = AVCaptureVideoDataOutput()
    
    // MARK: - CameraServiceProtocol
    
    func setupSession() async throws -> AVCaptureVideoPreviewLayer {
        guard 
            let wideCameraDevice = AVCaptureDevice.wideDevice,
            let wideInput = try? AVCaptureDeviceInput(device: wideCameraDevice)
        else {
            throw CaptureServiceErrors.noDevice
        }
        
        self.captureSession.beginConfiguration()
        if self.captureSession.canSetSessionPreset(.photo) {
            self.captureSession.sessionPreset = .photo
        }
        
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
        
        self.captureSession.commitConfiguration()
        self.captureSession.startRunning()
        
        return AVCaptureVideoPreviewLayer(session: self.captureSession)
    }
    
    // MARK: - Private
    
//    private func prepareCaptureSession() async throws {
//        self.captureSession.beginConfiguration()
//        if self.captureSession.canSetSessionPreset(.photo) {
//            self.captureSession.sessionPreset = .photo
//        }
//        
//        if let currentInput = self.captureSession.inputs.first as? AVCaptureDeviceInput {
//            self.captureSession.removeInput(currentInput)
//        }
//        
//        guard
//            let captureInput = self.captureInput,
//            self.captureSession.canAddInput(captureInput) else {
//            throw CaptureServiceErrors.failedAddingCaptureInput
//        }
//        
//        self.captureSession.addInput(captureInput)
//        try self.prepareOutputs()
//        self.captureSession.commitConfiguration()
//        self.captureSession.startRunning()
//        self.isSessionRunning = self.captureSession.isRunning
//    }
    
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
