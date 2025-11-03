
import Foundation

class MultiPhotoSectionHeader: UICollectionReusableView {
    var selectAllHandler: (() -> Bool)?
    
    var isSelectAll: Bool = false {
        didSet {
            selectAllView.image = isSelectAll ? UIImage(named: "multiphoto_selected") : UIImage(named: "multiphoto_selectAll")
        }
    }
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .title_normal_bold
        label.numberOfLines = 1
        label.textColor = .white
        return label
    }()
    
    let selectAllView: UIImageView = {
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.contentMode = .scaleAspectFit
        imgView.layer.masksToBounds = true
        imgView.image = UIImage(named: "multiphoto_selectAll")
        return imgView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(selectAllView)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(12)
            make.trailing.greaterThanOrEqualTo(-40)
        }
        selectAllView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(-12)
            make.size.equalTo(28)
        }
        selectAllView.addTapGestureRecognizer(target: self, action: #selector(selectAllViewTapped))
    }
    
    func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    @objc
    func selectAllViewTapped() {
        guard let selectAllHandler else { return }
        isSelectAll = selectAllHandler()
    }
    
    override func prepareForReuse() {
        selectAllView.image = UIImage(named: "multiphoto_selectAll")
    }
}
