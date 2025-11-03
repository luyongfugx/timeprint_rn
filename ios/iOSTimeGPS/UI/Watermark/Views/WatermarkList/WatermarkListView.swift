//
//  WatermarkListView.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/4/6.
//
import UIKit

class WatermarkCategory2: Codable {
    var name: String?
    var list: [WatermarkCoverModel]?
}

//// 数据模型
//struct WatermarkCategory: Codable {
//    let name: String
//    let list: [WatermarkItem2]
//}
//
//struct WatermarkItem2: Codable {
//    let base_id: String
//    let id: String
//    let cover: String
//    let name: String
//    let templateColorStr: String?
//    let textColorStr: String?
//    let logo: String?
//    let extraItemList: [ExtraItem]?
//
//    var aspectRatio: CGFloat {
//        // 匹配最后两个下划线之间的数字（宽和高）
//        let pattern = "_(\\d+)_(\\d+)\\."
//        guard let regex = try? NSRegularExpression(pattern: pattern),
//              let match = regex.firstMatch(in: cover, range: NSRange(cover.startIndex..., in: cover)) else {
//            return 1.0 // 默认比例
//        }
//
//        let widthRange = match.range(at: 1)
//        let heightRange = match.range(at: 2)
//
//        guard let widthStr = Range(widthRange, in: cover),
//              let heightStr = Range(heightRange, in: cover),
//              let width = Int(cover[widthStr]),
//              let height = Int(cover[heightStr]), height != 0 else {
//            return 1.0 // 默认比例
//        }
//
//        return CGFloat(width) / CGFloat(height)
//    }
//}
//
//struct ExtraItem: Codable {
//    let id: Int
//    let logoUrl: String
//}

protocol WatermarkListViewDelegate: AnyObject {
    func chooseWatermark(model: BaseWatermarkModel)
    func clickEdit()
}

class WatermarkListView: GPView {
    
    lazy var scrollTab: HorizontalScrollTab = {
        let scrollTab = HorizontalScrollTab()
        // 设置滚动Tab
        scrollTab.delegate = self
        
        // 自定义外观 (可选)
        scrollTab.normalTextColor = .darkGray
        scrollTab.selectedTextColor = .text_highlight
        scrollTab.selectedFont = .systemFont(ofSize: 16, weight: .bold)
        scrollTab.buttonSpacing = 12
        return scrollTab
    }()
    
    // MARK: - Properties
        
    private var categories: [WatermarkCategory2] = []
    private var selectedItemIndexPath: IndexPath?
    weak var delegate: WatermarkListViewDelegate?

    private lazy var collectionView: UICollectionView = {
        let layout = WaterfallLayout()
        layout.delegate = self
        layout.numberOfColumns = 2
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        layout.minimumColumnSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.register(WatermarkCell.self, forCellWithReuseIdentifier: "WatermarkCell")
        cv.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader")
        cv.dataSource = self
        cv.delegate = self
        cv.showsVerticalScrollIndicator = true
        return cv
    }()
    
    override func buildUI() {
        super.buildUI()
        addSubview(scrollTab)
        scrollTab.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44+8)
        }
        
        // 添加瀑布流
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(scrollTab.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        loadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            // 延迟注册通知，特别是针对，首次安装，首次打开水印列表的用户
            self?.addNotication()
        }

    }
    
    private func addNotication() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: GPNotification.loadCoverSuccessNotification, object: nil)
    }
    
    @objc func handleNotification(_ notification: Notification) {
        if let wmID = notification.userInfo?["wmID"] as? String {
            // 刷新水印封面
            for (section, WatermarkCategory) in categories.enumerated() {
                if let list = WatermarkCategory.list {
                    for (row, item) in list.enumerated() {
                        if item.watermarkModel?.id == wmID {
                            // 确保索引路径有效
                            let validIndexPath = IndexPath(item: row, section: section)
                            DispatchQueue.main.async {
                                if validIndexPath.item < self.collectionView.numberOfItems(inSection: validIndexPath.section) {
                                    self.collectionView.reloadItems(at: [validIndexPath])
                                }
                            }
                            break
                        }
                    }
                }
                
            }
        }
    }
    
    // MARK: - Helper Methods
        
    private func scrollToSection(_ section: Int) {
        let indexPath = IndexPath(item: 0, section: section)
        collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
    }
    
    // MARK: - Data Loading
        
    private func loadData() {
        
        categories = WatermarkManager.shared.watermarkCategoryList
        let tabTitles = categories.compactMap { $0.name?.localized() }
        scrollTab.configure(with: tabTitles)
        
        // 选中默认水印
        for (section, WatermarkCategory) in categories.enumerated() {
            if let list = WatermarkCategory.list {
                for (row, item) in list.enumerated() {
                    if item.watermarkModel?.id == WatermarkManager.selectStoreWatermarkID {
                        let indexPath = IndexPath(item: row, section: section)
                        selectedItemIndexPath = indexPath
                        scrollTab.selectTab(at: section, isAutoScroll: true)
                        collectionView.reloadData()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // delay
                            self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                        }
                        return
                    }
                }
            }
            
        }
        
        collectionView.reloadData()
    }
    
//    private func getWMJson() -> String {
//        let appLan = GPLanguageManager.xhSpecialLocaleIdentifier()
//        let fileName = "filtercolor_\(appLan).json"
//        if Bundle.main.url(forResource: fileName, withExtension: nil) != nil {
//            return fileName
//        } else {
//            return "filtercolor_en.json"
//        }
//    }
    
    // 要让 UICollectionView 的滚动条在展示时闪动一下再消失
    func flashScrollIndicators() {
        collectionView.flashScrollIndicators()
    }
    
}


// MARK: - HorizontalScrollTabDelegate
extension WatermarkListView: HorizontalScrollTabDelegate {
    func didSelectTab(at index: Int) {
        scrollToSection(index)
    }
}

// MARK: - UICollectionViewDataSource
extension WatermarkListView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories[section].list?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WatermarkCell", for: indexPath) as! WatermarkCell
        if let item = categories[indexPath.section].list?[indexPath.item] {
            cell.configure(with: item)
        }
        cell.delegate = delegate
        // 设置选中状态
        if selectedItemIndexPath == indexPath {
            cell.setSelected(true)
        } else {
            cell.setSelected(false)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as! SectionHeaderView
            header.titleLabel.text = categories[indexPath.section].name?.localized()
            return header
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate
extension WatermarkListView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 更新选中状态
        if let previousIndexPath = selectedItemIndexPath {
            if let cell = collectionView.cellForItem(at: previousIndexPath) as? WatermarkCell {
                cell.setSelected(false)
            }
        }
        
        if let cell = collectionView.cellForItem(at: indexPath) as? WatermarkCell {
            cell.setSelected(true)
        }
        
        selectedItemIndexPath = indexPath
        
        if let item = categories[indexPath.section].list?[indexPath.item], let watermarkModel = item.watermarkModel, let wmID = item.watermarkModel?.id, !wmID.isEmpty, WatermarkManager.shared.selectWatermarkID() != wmID {
            WatermarkManager.selectStoreWatermarkID = wmID
            let localModel = WatermarkManager.shared.getWaterModelByID(wmID)
            delegate?.chooseWatermark(model: localModel ?? watermarkModel)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // delay
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        
        // 获取所有可见的section
        let visibleSections = Set(collectionView.indexPathsForVisibleItems.map { $0.section })
        
        // 找出最靠近屏幕顶部的section
        if let firstSection = visibleSections.min() {
            // 只有当分类变化时才更新Tab
            if firstSection != scrollTab.selectedIndex {
                scrollTab.selectTab(at: firstSection, animated: true, isAutoScroll: true)
            }
        }
    }
}

// MARK: - WaterfallLayoutDelegate
extension WatermarkListView: WaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, withWidth width: CGFloat) -> CGFloat {
        
        var aspectRatio = 2.4
        if let wmID = categories[indexPath.section].list?[indexPath.item].watermarkModel?.id {
            aspectRatio = WatermarkPreloader.watermarkCoverRatio(wmID: wmID)
        }
                        
        let maxImgW = width - WatermarkCell.imgPadding*4
        
        // 图片高度 = 单元格宽度 / 图片宽高比
        let imageHeight = maxImgW / aspectRatio
        
        // 文字固定高度 + 上下边距
        let textHeight: CGFloat = 28
        let verticalPadding: CGFloat = 1
        let hasLogo = categories[indexPath.section].list?[indexPath.item].watermarkModel?.logoItem()?.extraLogo.logoUrl != nil
        let logoHeight = hasLogo ? WatermarkCell.logoCoverHeight : 0
        
        // 总高度 = 图片高度 + 文字高度 + 边距
        return WatermarkCell.imgPadding*2 + logoHeight + imageHeight + WatermarkCell.imgPadding*1.5 + textHeight + verticalPadding * 2
    }
    
    func collectionView(_ collectionView: UICollectionView, heightForHeaderInSection section: Int) -> CGFloat {
        // 第一个section的header高度设为0（不显示）
        return section == 0 ? 0 : 40
    }
}

// MARK: - Custom Cells

class WatermarkCell: UICollectionViewCell {
    
    static let logoCoverHeight = 72.0
    static let imgPadding = 8.0
    weak var delegate: WatermarkListViewDelegate?
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()
    
    private let logoImgView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 4
        iv.clipsToBounds = true
        return iv
    }()
    
    private let imageBGView: UIView = {
        let iv = UIView()
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .cover_color
        return iv
    }()
    
    lazy var editBtn: GPButton = {
        let button = GPButton.init(frame: .zero)
        button.setTitleColor(.white, for: .normal)
        button.setTitle("i_edit".localized(), for: .normal)
        button.layerCornerRadius = 4
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = UIColor(hex: "#0093FF").withAlphaComponent(0.8)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
        button.addTarget(self, action: #selector(editAction), for: .touchUpInside)
        return button
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .text_ultrastrong
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.3
        label.numberOfLines = 1
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 0
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(imageBGView)
        imageBGView.addSubview(logoImgView)
        imageBGView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        
        imageBGView.snp.makeConstraints { make in
            make.top.leading.equalTo(WatermarkCell.imgPadding)
            make.trailing.equalTo(-WatermarkCell.imgPadding)
            make.bottom.equalTo(-28-2)
        }
        
        logoImgView.snp.makeConstraints { make in
            make.left.top.equalTo(WatermarkCell.imgPadding)
            make.right.equalTo(-WatermarkCell.imgPadding)
            make.height.equalTo(80)
        }
        
        imageView.snp.makeConstraints { make in
            make.left.top.equalTo(WatermarkCell.imgPadding)
            make.right.bottom.equalTo(-WatermarkCell.imgPadding)
        }
                
        nameLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(28) // 文字固定高度
            make.bottom.equalTo(-1)
        }
        
        imageBGView.addSubview(editBtn)
        editBtn.isHidden = true
        editBtn.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(68)
            make.height.equalTo(26)
        }
    }
    
    func configure(with item: WatermarkCoverModel) {
        nameLabel.text = item.name?.localized()
        if let wmID = item.watermarkModel?.id {
            if let coverImg = WatermarkPreloader.shared.getWatermarkImage(for: wmID) {
                imageView.image = coverImg
            } else {
                // 使用兜底的封面
                imageView.image = getPlaceHolder(with: item)
            }
        }
        
        if let logoUrl = item.watermarkModel?.logoItem()?.extraLogo.logoUrl {
            
            logoImgView.isHidden = false
            imageView.snp.remakeConstraints { make in
                make.left.equalTo(WatermarkCell.imgPadding)
                make.top.equalTo(WatermarkCell.imgPadding*1.5 + WatermarkCell.logoCoverHeight)
                make.right.bottom.equalTo(-WatermarkCell.imgPadding)
            }
            logoImgView.setImage_xh(with: logoUrl) { [weak self] img,url in
                if let img {
                    
                    let imgFrameW = WatermarkCell.logoCoverHeight/img.size.height * img.size.width
                    
                    self?.logoImgView.snp.remakeConstraints { make in
                        make.left.top.equalTo(WatermarkCell.imgPadding*2)
                        make.width.equalTo(imgFrameW)
                        make.height.equalTo(WatermarkCell.logoCoverHeight)
                    }
                                        
                    self?.setNeedsLayout()
                    self?.layoutIfNeeded()
                }
            }
        } else {
            logoImgView.isHidden = true
            imageView.snp.remakeConstraints { make in
                make.left.top.equalTo(WatermarkCell.imgPadding)
                make.right.bottom.equalTo(-WatermarkCell.imgPadding)
            }
        }
    }
    
    func getPlaceHolder(with item: WatermarkCoverModel) -> UIImage? {
        guard let baseID = item.watermarkModel?.base_id else { return nil }
        let appLan = GPLanguageManager.shortDeviceLanguage2()
        return UIImage(named: "cover_\(appLan)_\(baseID)") ?? UIImage(named: "cover_en_\(baseID)")
    }
    
    func setSelected(_ selected: Bool) {
        if selected {
            editBtn.isHidden = false
            contentView.layer.borderWidth = 2
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            editBtn.isHidden = true
            contentView.layer.borderWidth = 0
        }
    }
    
    @objc
    func editAction() {
        delegate?.clickEdit()
    }
}

class SectionHeaderView: UICollectionReusableView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .darkText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var lineview: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .border_medium
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview().offset(8)

        }
        addSubview(lineview)
        lineview.snp.makeConstraints { make in
            make.leading.equalTo(12)
            make.trailing.equalTo(-12)
            make.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Waterfall Layout

protocol WaterfallLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, withWidth width: CGFloat) -> CGFloat
    func collectionView(_ collectionView: UICollectionView, heightForHeaderInSection section: Int) -> CGFloat
}

class WaterfallLayout: UICollectionViewLayout {
    weak var delegate: WaterfallLayoutDelegate?
    
    var numberOfColumns = 2
    var minimumColumnSpacing: CGFloat = 1
    var minimumInteritemSpacing: CGFloat = 1
    var sectionInset = UIEdgeInsets.zero
    
    private var columnHeights: [[CGFloat]] = []
    private var itemAttributes: [[UICollectionViewLayoutAttributes]] = []
    private var headerAttributes: [Int: UICollectionViewLayoutAttributes] = [:]
    private var contentHeight: CGFloat = 0
    
    override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView else { return }
        
        let numberOfSections = collectionView.numberOfSections
        columnHeights = Array(repeating: [], count: numberOfSections)
        itemAttributes = Array(repeating: [], count: numberOfSections)
        headerAttributes = [:]
        contentHeight = 0
        
        for section in 0..<numberOfSections {
            // 添加section header
            let headerHeight = delegate?.collectionView(collectionView, heightForHeaderInSection: section) ?? 0
            if headerHeight > 0 {
                let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: 0, y: contentHeight, width: GPApp.screenWidth, height: headerHeight)
                headerAttributes[section] = attributes
                contentHeight += headerHeight
            }
            
            contentHeight += sectionInset.top
            
            // 计算列宽
            let columnWidth = (GPApp.screenWidth - sectionInset.left - sectionInset.right - CGFloat(numberOfColumns - 1) * minimumColumnSpacing) / CGFloat(numberOfColumns)
            
            // 初始化每列的高度
            columnHeights[section] = Array(repeating: contentHeight, count: numberOfColumns)
            
            let itemCount = collectionView.numberOfItems(inSection: section)
            var attributesList: [UICollectionViewLayoutAttributes] = []
            
            for item in 0..<itemCount {
                let indexPath = IndexPath(item: item, section: section)
                let columnIndex = shortestColumnIndex(in: section)
                let xOffset = sectionInset.left + (columnWidth + minimumColumnSpacing) * CGFloat(columnIndex)
                let yOffset = columnHeights[section][columnIndex]
                
                // 获取动态高度
                let itemHeight = delegate?.collectionView(collectionView, heightForItemAt: indexPath, withWidth: columnWidth) ?? 100
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: xOffset, y: yOffset, width: columnWidth, height: itemHeight)
                attributesList.append(attributes)
                
                // 更新列高
                columnHeights[section][columnIndex] = yOffset + itemHeight + minimumInteritemSpacing
            }
            
            itemAttributes[section] = attributesList
            
            // 更新内容高度
            if let maxHeight = columnHeights[section].max() {
                contentHeight = maxHeight - minimumInteritemSpacing + sectionInset.bottom
            }
        }
    }
    
    private func shortestColumnIndex(in section: Int) -> Int {
        var shortestIndex = 0
        var shortestHeight = CGFloat.greatestFiniteMagnitude
        
        for (index, height) in columnHeights[section].enumerated() {
            if height < shortestHeight {
                shortestHeight = height
                shortestIndex = index
            }
        }
        
        return shortestIndex
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: collectionView?.bounds.width ?? 0, height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes: [UICollectionViewLayoutAttributes] = []
        
        for section in 0..<itemAttributes.count {
            if let headerAttribute = headerAttributes[section], headerAttribute.frame.intersects(rect) {
                attributes.append(headerAttribute)
            }
            
            for itemAttribute in itemAttributes[section] where itemAttribute.frame.intersects(rect) {
                attributes.append(itemAttribute)
            }
        }
        
        return attributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.section < itemAttributes.count,
              indexPath.item < itemAttributes[indexPath.section].count else {
            return nil
        }
        return itemAttributes[indexPath.section][indexPath.item]
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == UICollectionView.elementKindSectionHeader {
            return headerAttributes[indexPath.section]
        }
        return nil
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return collectionView?.bounds.width != newBounds.width
    }
}
