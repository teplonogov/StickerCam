import UIKit
import AVFoundation.AVCaptureVideoPreviewLayer
import SnapKit

protocol CameraView: AnyObject {
    func showCaptureLayer(_ layer: AVCaptureVideoPreviewLayer)
    func closeShutter()
    func openShutter()
    func showCapturedImage(_ image: UIImage)
    func showSticker(_ image: UIImage)
    func showErrorLabel()
    func showSuccesSavingAlert()
}

final class CameraController: UIViewController {
    
    private let viewModel: CameraViewModelProtocol
    
    private lazy var sceneView = SceneView()
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    private lazy var captureButton: CaptureButton = {
        let button = CaptureButton(frame: .zero)
        button.addTarget(self, action: #selector(self.handleCaptureButton), for: .touchUpInside)
        return button
    }()
    private lazy var retakeButton: UIButton = {
        let button = UIButton()
        button.setTitle("Take new image", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(self.handleRetakeButton), for: .touchUpInside)
        button.layer.cornerRadius = 12
        button.layer.cornerCurve = .continuous
        button.backgroundColor = .white
        button.isHidden = true
        return button
    }()
    private lazy var stickerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Make sticker", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(self.handleStickerButton), for: .touchUpInside)
        button.layer.cornerRadius = 12
        button.layer.cornerCurve = .continuous
        button.backgroundColor = .white
        button.isHidden = true
        return button
    }()
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("Save to Library", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(self.handleSaveButton), for: .touchUpInside)
        button.layer.cornerRadius = 12
        button.layer.cornerCurve = .continuous
        button.backgroundColor = .white
        button.isHidden = true
        return button
    }()
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.isHidden = true
        label.numberOfLines = 2
        label.text = "Failed sticker generation. Probably there is no object in the photo."
        return label
    }()
    
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
        self.setupUI()
        self.viewModel.viewDidLoad()
    }
    
    // MARK: - Private
    
    private func setupUI() {
        self.view.backgroundColor = .black
        self.view.addSubview(self.sceneView)
        self.sceneView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(self.sceneView.snp.width).multipliedBy(Constants.captureAspectRatio)
        }
        
        self.view.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { make in
            make.edges.equalTo(self.sceneView)
        }
        
        self.view.addSubview(self.captureButton)
        self.captureButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.sceneView.snp.bottom).offset(80)
        }
        
        self.view.addSubview(self.retakeButton)
        self.retakeButton.snp.makeConstraints { make in
            make.width.equalTo(170)
            make.height.equalTo(60)
            make.top.equalTo(self.sceneView.snp.bottom).offset(80)
            make.right.equalToSuperview().inset(12)
        }
        
        self.view.addSubview(self.errorLabel)
        self.errorLabel.snp.makeConstraints { make in
            make.top.equalTo(self.sceneView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().inset(8)
        }
        
        self.view.addSubview(self.stickerButton)
        self.stickerButton.snp.makeConstraints { make in
            make.width.equalTo(170)
            make.height.equalTo(60)
            make.top.equalTo(self.sceneView.snp.bottom).offset(80)
            make.left.equalToSuperview().offset(12)
        }
        
        self.view.addSubview(self.saveButton)
        self.saveButton.snp.makeConstraints { make in
            make.width.equalTo(170)
            make.height.equalTo(60)
            make.top.equalTo(self.sceneView.snp.bottom).offset(80)
            make.left.equalToSuperview().offset(12)
        }
    }
    
    @objc
    private func handleCaptureButton() {
        self.viewModel.viewDidTapCapture()
    }
    
    @objc
    private func handleRetakeButton() {
        self.viewModel.viewDidTapRetake()
        // TODO: Make more conveniente state switch
        self.sceneView.isHidden = false
        self.captureButton.isHidden = false
        self.retakeButton.isHidden = true
        self.stickerButton.isHidden = true
        self.imageView.isHidden = true
        self.errorLabel.isHidden = true
        self.saveButton.isHidden = true
    }
    
    @objc
    private func handleStickerButton() {
        self.viewModel.viewDidTapMakeSticker()
    }
    
    @objc
    private func handleSaveButton() {
        self.viewModel.viewDidTapSaveSticker()
    }
}

// MARK: - CameraView

extension CameraController: CameraView {
    func showCaptureLayer(_ layer: AVCaptureVideoPreviewLayer) {
        self.sceneView.setVideoLayer(layer)
    }
    
    func closeShutter() {
        self.sceneView.closeShutter()
    }
    
    func openShutter() {
        self.sceneView.openShutter()
    }
    
    func showCapturedImage(_ image: UIImage) {
        self.imageView.image = image
        self.imageView.isHidden = false
        self.captureButton.isHidden = true
        self.retakeButton.isHidden = false
        self.stickerButton.isHidden = false
        self.saveButton.isHidden = true
        self.sceneView.isHidden = true
    }
    
    func showSticker(_ image: UIImage) {
        self.imageView.image = image
        self.saveButton.isHidden = false
        self.stickerButton.isHidden = true
    }
    
    func showErrorLabel() {
        self.errorLabel.isHidden = false
        self.stickerButton.isHidden = true
        self.saveButton.isHidden = true
    }
    
    func showSuccesSavingAlert() {
        let alert = UIAlertController(title: "Done!", message: "Sticker was saved :)", preferredStyle: .alert)
        alert.addAction(.init(title: "Okay", style: .default))
        self.present(alert, animated: true)
    }
}

private enum Constants {
    static let captureAspectRatio: CGFloat = 4/3
}
