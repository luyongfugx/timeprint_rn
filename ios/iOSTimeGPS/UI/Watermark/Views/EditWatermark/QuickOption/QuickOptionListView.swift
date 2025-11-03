//
//  QuickOptionListView.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/5/14.
//

class QuickOptionListView: UIView {
    private let scrollView = UIScrollView()
    private var buttons = [UIButton]()
    private var items: [String]
    private var selectedItem: String?
    private var callback: (String) -> Void
    private let maxWidth: CGFloat
    private var totalHeight: CGFloat = 0
    
    init(maxWidth: CGFloat, items: [String], selectedItem: String?, callback: @escaping (String) -> Void) {
        self.maxWidth = maxWidth
        self.items = items
        self.selectedItem = selectedItem
        self.callback = callback
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        let verticalSpacing: CGFloat = 8
        let horizontalSpacing: CGFloat = 8
        let itemHeight: CGFloat = 28
        
        for (index, item) in items.enumerated() {
            let button = createButton(item: item, index: index)
            let buttonWidth = Self.calculateButtonWidth(for: item, maxWidth2: maxWidth)
            
            // Check if needs new line
            if currentX + buttonWidth > maxWidth - 8 {
                currentY += itemHeight + verticalSpacing
                currentX = 0
            }
            
            button.frame = CGRect(x: currentX, y: currentY, width: buttonWidth, height: itemHeight)
            scrollView.addSubview(button)
            buttons.append(button)
            
            currentX += buttonWidth + horizontalSpacing
        }
        
        totalHeight = currentY + itemHeight + verticalSpacing
        scrollView.contentSize = CGSize(width: maxWidth, height: totalHeight)
    }
    
    static func calculateHeight(items: [String], maxWidth2: CGFloat) -> CGFloat {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        let verticalSpacing: CGFloat = 8
        let horizontalSpacing: CGFloat = 8
        let itemHeight: CGFloat = 28
        
        for (_, item) in items.enumerated() {
            let buttonWidth = Self.calculateButtonWidth(for: item, maxWidth2: maxWidth2)
            
            // Check if needs new line
            if currentX + buttonWidth > maxWidth2 - 8 {
                currentY += itemHeight + verticalSpacing
                currentX = 0
            }
            
            currentX += buttonWidth + horizontalSpacing
        }
        
        return currentY + itemHeight + verticalSpacing
    }
    
    private func createButton(item: String, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = index
        button.backgroundColor = .white
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 0.5
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle(item, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.titleLabel?.numberOfLines = 1
        
        // Set initial state
        if item == selectedItem {
            button.isSelected = true
            button.layer.borderColor = UIColor.systemBlue.cgColor
            button.setTitleColor(.systemBlue, for: .normal)
        } else {
            button.layer.borderColor = UIColor.systemGray.cgColor
            button.setTitleColor(.systemGray, for: .normal)
        }
        
        button.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private static func calculateButtonWidth(for text: String, maxWidth2: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 14)
        let maxItemWidth = (maxWidth2 - 16) / 2  // (总宽度 - 左右边距 - 间距) / 2
        let textWidth = text.size(withAttributes: [.font: font]).width
        let padding: CGFloat = 16  // 8 + 8
        return min(textWidth + padding, maxItemWidth)
    }
    
    @objc private func itemTapped(_ sender: UIButton) {
        let selectedText = items[sender.tag]
        
        buttons.forEach { button in
            let isSelected = button.tag == sender.tag
            button.isSelected = isSelected
            button.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.systemGray.cgColor
            button.setTitleColor(isSelected ? .systemBlue : .systemGray, for: .normal)
        }
        
        callback(selectedText)
    }
    
    func calculateContentHeight() -> CGFloat {
        return totalHeight
    }
}
