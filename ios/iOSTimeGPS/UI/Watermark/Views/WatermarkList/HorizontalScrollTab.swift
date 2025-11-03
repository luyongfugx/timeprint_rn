//
//  HorizontalScrollTab.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/4/6.
//

import UIKit
import SnapKit

protocol HorizontalScrollTabDelegate: AnyObject {
    func didSelectTab(at index: Int)
}

class HorizontalScrollTab: UIView {
    
    // MARK: - Properties
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()
    
    private var buttons: [UIButton] = []
    private var buttonTitles: [String] = []
    var selectedIndex: Int = 0
    
    weak var delegate: HorizontalScrollTabDelegate?
    
    // 自定义外观属性
    var normalTextColor: UIColor = .gray {
        didSet { updateButtonAppearance() }
    }
    var selectedTextColor: UIColor = .blue {
        didSet { updateButtonAppearance() }
    }
    var normalFont: UIFont = .systemFont(ofSize: 14) {
        didSet { updateButtonAppearance() }
    }
    var selectedFont: UIFont = .systemFont(ofSize: 16, weight: .medium) {
        didSet { updateButtonAppearance() }
    }
    var buttonSpacing: CGFloat = 12 {
        didSet { layoutButtons() }
    }
    var buttonPadding: CGFloat = 16 {
        didSet { layoutButtons() }
    }
    var cornerRadius: CGFloat = 16 {
        didSet { updateButtonAppearance() }
    }
    var borderWidth: CGFloat = 1 {
        didSet { updateButtonAppearance() }
    }
    var contentInset: CGFloat = 12 {
        didSet { layoutButtons() }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(scrollView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    
    func configure(with titles: [String]) {
        buttonTitles = titles
        createButtons()
        layoutButtons()
        selectTab(at: 0, animated: false, isAutoScroll: true)
    }
    
    func selectTab(at index: Int, animated: Bool = true, isAutoScroll: Bool = false) {
        guard index >= 0 && index < buttons.count else { return }
        
        // 更新按钮状态
        selectedIndex = index
        updateButtonAppearance()
        
        // 滚动到中间
        scrollToButton(at: index, animated: animated)
        
        if !isAutoScroll {
            // 通知代理
            delegate?.didSelectTab(at: index)
        }
    }
    
    // MARK: - Private Methods
    
    private func createButtons() {
        // 移除旧的按钮
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        
        // 创建新的按钮
        for (index, title) in buttonTitles.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(title, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            button.layer.cornerRadius = 4
            button.layer.borderWidth = borderWidth
            button.layer.masksToBounds = true
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: contentInset, bottom: 0, right: contentInset)
            buttons.append(button)
            scrollView.addSubview(button)
        }
    }
    
    private func layoutButtons() {
        var previousButton: UIButton?
        
        for button in buttons {
            button.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.bottom.equalToSuperview().offset(-6)
                make.height.equalTo(32) // 固定高度
                
                if let previous = previousButton {
                    make.leading.equalTo(previous.snp.trailing).offset(buttonSpacing)
                } else {
                    make.leading.equalToSuperview().offset(buttonPadding)
                }
            }
            
            previousButton = button
        }
        
        // 最后一个按钮
        if let lastButton = buttons.last {
            lastButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-buttonPadding)
            }
        }
    }
    
    private func updateButtonAppearance() {
        for (index, button) in buttons.enumerated() {
            if index == selectedIndex {
                button.setTitleColor(selectedTextColor, for: .normal)
                button.titleLabel?.font = selectedFont
                button.layer.borderColor = selectedTextColor.cgColor
                button.backgroundColor = selectedTextColor.withAlphaComponent(0.1)
            } else {
                button.setTitleColor(normalTextColor, for: .normal)
                button.titleLabel?.font = normalFont
                button.layer.borderColor = normalTextColor.cgColor
                button.backgroundColor = .clear
            }
        }
    }
    
    private func scrollToButton(at index: Int, animated: Bool) {
        guard index >= 0 && index < buttons.count else { return }
        
        let button = buttons[index]
        let buttonFrame = button.convert(button.bounds, to: scrollView)
        let scrollViewWidth = scrollView.bounds.width
        let targetOffsetX = buttonFrame.midX - scrollViewWidth / 2
        
        // 计算边界值
        let maxOffset = scrollView.contentSize.width - scrollViewWidth
        let minOffset: CGFloat = 0
        let finalOffsetX = max(min(targetOffsetX, maxOffset), minOffset)
        
        scrollView.setContentOffset(CGPoint(x: finalOffsetX, y: 0), animated: animated)
    }
    
    // MARK: - Actions
    
    @objc private func buttonTapped(_ sender: UIButton) {
        selectTab(at: sender.tag)
    }
}
