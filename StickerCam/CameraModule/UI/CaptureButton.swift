import Foundation
import UIKit

final class CaptureButton: UIButton {
    
    private static let size: CGFloat = 80
    
    override public var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.lightGray : UIColor.white
        }
    }
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.layer.cornerRadius = Self.size / 2
        self.snp.makeConstraints { make in
            make.size.equalTo(Self.size)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
