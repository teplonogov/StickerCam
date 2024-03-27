import UIKit
import AVFoundation.AVCaptureVideoPreviewLayer
import SnapKit

protocol CameraView: AnyObject {
    func showCaptureLayer(_ layer: AVCaptureVideoPreviewLayer)
}

final class CameraController: UIViewController {
    
    private let viewModel: CameraViewModelProtocol
    
    private lazy var sceneView = SceneView()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Lifecycle
    
    init(viewModel: CameraViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        self.setupUI()
        self.viewModel.viewDidLoad()
    }
    
    // MARK: - Private
    
    private func setupUI() {
        self.view.addSubview(self.sceneView)
        self.sceneView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(self.sceneView.snp.width).multipliedBy(Constants.captureAspectRatio)
        }
    }
}

// MARK: - CameraView

extension CameraController: CameraView {
    func showCaptureLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.sceneView.setVideoLayer(layer)
    }
}

private enum Constants {
    static let captureAspectRatio: CGFloat = 4/3
}
