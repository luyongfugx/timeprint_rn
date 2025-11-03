
import UIKit

class ID120WatermarkBottomCell: GPBaseCollectionViewCell {
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let size = super.systemLayoutSizeFitting(.init(width: WatermarkID7View.currentAnimationViewWidth, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        
        layoutAttributes.frame.size = size
        
        return layoutAttributes
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .text_ultrastrong
        label.font = .robotoCondensedRegular(11)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var colon: UILabel = {
        let label = UILabel()
        label.font = .robotoCondensedRegular(11)
        label.textColor = .text_ultrastrong
        label.text = ":"
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private(set) lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = .text_ultrastrong
        label.font = .robotoCondensedMedium(11)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var isFirst: Bool = false {
        didSet {
            if isFirst {
                titleLabel.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(6)
                }
                colon.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(6)
                }
            } else {
                titleLabel.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(3)
                }
                colon.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(3)
                }
            }
        }
    }
    
    var isLast: Bool = false {
        didSet {
            if isLast {
                titleLabel.snp.updateConstraints { make in
                    make.bottom.lessThanOrEqualToSuperview().offset(-6)
                }
            } else {
                titleLabel.snp.updateConstraints { make in
                    make.bottom.lessThanOrEqualToSuperview().offset(-3)
                }
            }
        }
    }
    
    override func buildUI() {
        super.buildUI()
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(colon)
        contentView.addSubview(contentLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(6)
            make.top.equalToSuperview().offset(3)
            make.right.lessThanOrEqualTo(colon.snp.left).offset(-2)
            make.bottom.lessThanOrEqualToSuperview().offset(-3)
        }
        
        colon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(62)
            make.top.equalToSuperview().offset(3)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(colon.snp.right).offset(2)
            make.top.equalTo(titleLabel.snp.top)
            make.right.lessThanOrEqualToSuperview().offset(-6)
            make.bottom.lessThanOrEqualToSuperview().offset(-3)
        }
    }
        
    // 填充数据
    func configData(title: String?, conent: String?, themeColor: UIColor, textColor: UIColor) {
        titleLabel.text = title
        contentLabel.text = conent
    }
    
    static func calculateHeight(item: WatermarkItem, conent: String) -> CGFloat {
        let title = item.title ?? ""
        let titleSizeHeight = title.size(WithFont: .robotoCondensedRegular(11), ConstrainedToWidth: 62 - 8).height + 6
        
        let contentSizeHeight = conent.size(WithFont: .robotoCondensedMedium(11), ConstrainedToWidth: WatermarkID7View.currentAnimationViewWidth - 70).height + 6
        return max(titleSizeHeight, contentSizeHeight)
    }
    
}
