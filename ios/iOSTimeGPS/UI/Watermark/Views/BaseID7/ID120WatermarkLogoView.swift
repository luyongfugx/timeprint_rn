
import UIKit

class ID120LogoImageView: GPView {
    
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 2
        imageView.backgroundColor = .white
        return imageView
    }()
    
    override func buildUI() {
        super.buildUI()
        
        addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(1)
            make.bottom.right.equalToSuperview().offset(-1)
        }
    }
}

class ID120WatermarkLogoView: UICollectionReusableView {
    
    private lazy var logoList: [WatermarkLogoOneItem] = []
    
    private lazy var firstLogo: ID120LogoImageView = {
        let imageView = ID120LogoImageView()
        imageView.layer.cornerRadius = 2
        imageView.backgroundColor = .white
        return imageView
    }()
    
    private lazy var secondLogo: ID120LogoImageView = {
        let imageView = ID120LogoImageView()
        imageView.layer.cornerRadius = 2
        imageView.backgroundColor = .white
        return imageView
    }()
    
    private lazy var thirdLogo: ID120LogoImageView = {
        let imageView = ID120LogoImageView()
        imageView.layer.cornerRadius = 2
        imageView.backgroundColor = .white
        return imageView
    }()
    
    private lazy var logoStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        
        stackView.addArrangedSubview(firstLogo)
        stackView.addArrangedSubview(secondLogo)
        stackView.addArrangedSubview(thirdLogo)
        
        firstLogo.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
        
        secondLogo.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
        
        thirdLogo.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
        
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        
        addSubview(logoStack)
        
//        backgroundColor = .init(hex: 0x0527AF).withAlphaComponent(0.6)
        
        logoStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-6)
            make.top.equalToSuperview().offset(6)
            make.left.equalToSuperview().offset(6)
            make.right.equalToSuperview().offset(-6)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadWatermarkLogos(_ logoList: [WatermarkLogoOneItem]) {
        for logo in logoList {
            let result = logo.getLogoImage()
            if let image = result {
                self.logoStack.arrangedSubviews[safe: logo.logoIndex.or(0)]?.isHidden = false
                (self.logoStack.arrangedSubviews[safe: logo.logoIndex.or(0)] as? ID120LogoImageView)?.image = image
            } else {
                self.logoStack.arrangedSubviews[safe: logo.logoIndex.or(0)]?.isHidden = true
            }
            self.logoStack.arrangedSubviews[safe: logo.logoIndex.or(0)]?.isHidden = logo.isOpen == false
        }
        self.logoList = logoList
    }
}
