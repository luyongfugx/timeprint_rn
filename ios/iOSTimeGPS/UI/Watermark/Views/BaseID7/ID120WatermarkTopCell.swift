
import UIKit

class ID120WatermarkTopCell: GPBaseCollectionViewCell {
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let size = super.systemLayoutSizeFitting(.init(width: WatermarkID7View.currentAnimationViewWidth, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        
        layoutAttributes.frame.size = size
        
        return layoutAttributes
    }
    
    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .robotoCondensedBold(14)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    var shouldAdjustSpacing: Bool = false {
        didSet {
            titleLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(shouldAdjustSpacing ? 7 : 1)
            }
        }
    }
    
    var isLast: Bool = false {
        didSet {
            titleLabel.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(isLast ? -7 : -1)
            }
        }
    }
    
    override func buildUI() {
        super.buildUI()
                
        contentView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().offset(-12)
            make.top.equalToSuperview().offset(1)
            make.bottom.equalToSuperview().offset(-1)
        }
    }
    
    // 填充数据
    func configData(item: WatermarkItem, conent: String?, themeColor: UIColor, textColor: UIColor) {
        
        if item.idType == .wm7_project {
            titleLabel.font = .robotoCondensedBold(14)
            
        } else {
            titleLabel.font = .robotoCondensedRegular(12)
        }
        titleLabel.backgroundColor = themeColor.withAlphaComponent(0.8)
        titleLabel.layer.cornerRadius = 5
        titleLabel.textAlignment = .center
        titleLabel.layer.masksToBounds = true
  
    }
    
    static func calculateHeight(item: WatermarkItem, conent: String) -> CGFloat {
        if conent.isEmpty {
            return 0
        }
        if item.idType == .wm7_project {
            let size = conent.size(WithFont: .robotoCondensedBold(14), ConstrainedToWidth: WatermarkID7View.currentAnimationViewWidth - 24)
            return size.height + 7 + 1
        } else {
            let size = conent.size(WithFont: .robotoCondensedBold(12), ConstrainedToWidth: WatermarkID7View.currentAnimationViewWidth - 24)
            return size.height + 7 + 1
        }
    }
}
