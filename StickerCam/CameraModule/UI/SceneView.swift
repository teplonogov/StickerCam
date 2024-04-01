import UIKit
import AVFoundation.AVCaptureVideoPreviewLayer

final class SceneView: UIView {
    
    private weak var videoLayer: AVCaptureVideoPreviewLayer?
        
    // MARK: - Public
    
    func setVideoLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.layer.sublayers?.forEach({ $0.removeFromSuperlayer() })
        self.layer.addSublayer(layer)
        layer.frame = self.layer.bounds
        self.videoLayer = layer
    }
    
    func closeShutter() {
        UIView.animate(withDuration: 0.05) {
            self.alpha = 0
        }
    }

    func openShutter() {
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1
        }
    }
}
