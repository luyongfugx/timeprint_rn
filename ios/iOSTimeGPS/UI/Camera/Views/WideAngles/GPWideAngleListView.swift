//
//  GPWideAngleListView.swift
//  XCamera
//

import UIKit

class GPWideAngleListView: UIView, UIGestureRecognizerDelegate {
    
    // 焦距的数值
    private var wideAngleValues: [CGFloat] = [10, 2, 1, 0.5]
    // 焦距的按钮数组
    private var wideAngleButtons = [XHOneWideAngleButton]()
    
    private var progressCallback: ((_ focusScale: CGFloat)->())?

    private var frontWideScale: CGFloat?
    private var backWideScale: CGFloat?
    private var isCameraBackPosition = false
    private var isSupportWidge = false
    
    private var currentScale: CGFloat?
    private var original: GPOrientation?
        
    class func angleListView(progressCallback: ((_ focusScale: CGFloat)->())?) -> GPWideAngleListView {
        
        let view = GPWideAngleListView()
        view.progressCallback = progressCallback
        view.buildUI()
        view.updateScale(1.0)
        
        return view
    }
    
    private func buildUI() {
        
        let space: CGFloat = 6.0 // 5
        var widgeViewTop: CGFloat = 30 // 152 - 2.5*GPWideAngleView.width - 2*space
        
        for (index, widge) in wideAngleValues.enumerated() {
            
            var titleStr = String(format: "%.0f", widge)
            if widge < 1 {
                titleStr = String(format: "%.1f", widge)
            }
            
            let widgeView = XHOneWideAngleButton(titleText: titleStr)
            widgeView.tag = index
            addSubview(widgeView)
            widgeView.addTarget(self, action: #selector(widgeViewTapAction(_ :)), for: .touchUpInside)
            widgeView.snp.makeConstraints { make in
                // make.left.equalTo(3)
                make.centerX.equalToSuperview()
                make.width.height.equalTo(GPWideAngleView.width)
                make.top.equalTo(widgeViewTop)
            }
            wideAngleButtons.append(widgeView)
            widgeViewTop += (space + GPWideAngleView.width)
            
            if index == wideAngleValues.count - 1 {
                widgeView.isHidden = true
                continue
            }
        }
                
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureAction(_:)))
        addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureAction(_:)))
        addGestureRecognizer(longPressGesture)
    }
    
    func updateScale(_ scale: CGFloat?) {
        
        guard let _scale = scale else{
            return
        }
        
        guard var index = wideAngleValues.firstIndex(where: { ($0 <= _scale) || abs($0 - _scale) <= 0.01 }) else {
            return
        }
        
        currentScale = _scale
        if index > 0 {
            
            let lastIndex = index - 1
            
            if abs(wideAngleValues[lastIndex] - _scale) < abs(wideAngleValues[index] - _scale) {
                index = lastIndex
            }
        }
        
        for (i, view) in wideAngleButtons.enumerated() {
            
            var isSelected: Bool = false
            var titleStr = ""
            if i == index {
                isSelected = true
                titleStr = "\(GPWideAngleTipView.scaleString(_scale))x"
            } else {
                isSelected = false
                titleStr = String(format: "%.0f", wideAngleValues[i])
                if wideAngleValues[i] < 1 {
                    titleStr = String(format: "%.1f", wideAngleValues[i])
                }
            }
            
            view.updateStatus(isSelected: isSelected, titleText: titleStr)
        }
        
    }
    
    @objc private func widgeViewTapAction(_ sender: UIButton) {
        
        var scale = wideAngleValues[sender.tag]
        if sender.tag == wideAngleValues.count - 1 {
            scale = getWideAngleValue()
        }
        
        if sender.isSelected == true {
            
            if let _currentScale = currentScale {
                
                progressCallback?(_currentScale)
                return
            }
        }
        
        progressCallback?(scale)
    }
    
    // 拖动手势的响应
    @objc private func panGestureAction(_ ges: UIGestureRecognizer) {
        
//        toSliderAction(ges: ges,from: .slide)
    }
    
    // 点击手势的响应
    @objc private func tapGestureAction(_ ges: UIGestureRecognizer) {
        
//        toSliderAction(ges: ges, from: .longPressEntry)
    }
    
    // 长按手势的响应
    @objc private func longPressGestureAction(_ ges: UIGestureRecognizer) {
        
//        toSliderAction(ges: ges, from: .longPressEntry)
    }

//    private func toSliderAction(ges: UIGestureRecognizer, from: XHWidgeSliderView.ComeFrom) {
//        if isHidden == true {
//            return
//        }
//        
//        if ges.state == .began || ges.state == .changed || ges.state == .ended{
//            
//            isUserInteractionEnabled = false
//            toSliderModelHandler?(from)
//            
//            isUserInteractionEnabled = true
//        }
//    }
    func update(isSupportWidge: Bool, frontWideScale: CGFloat?, backWideScale: CGFloat?, isCameraBackPosition: Bool) {
        
        self.isSupportWidge = isSupportWidge
        self.frontWideScale = frontWideScale
        self.backWideScale = backWideScale
        self.isCameraBackPosition = isCameraBackPosition
        updateWideWidgeViewStatus()
        updateWideWidgeValue()
        updateScale(currentScale)
    }
    
    func updateCameraStatus(_ isCameraBackPosition: Bool) {
        self.isCameraBackPosition = isCameraBackPosition
        updateWideWidgeValue()
    }

    private func updateWideWidgeViewStatus() {
        
        wideAngleButtons.last?.isHidden = !isSupportWidge
    }
    
    private func updateWideWidgeValue() {
        
        wideAngleValues[wideAngleValues.count - 1] = getWideAngleValue()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    // 获取广角的数值
    func getWideAngleValue() -> CGFloat {
        
        if !isSupportWidge {
            return 0.5
        }
        
        var wideAngleValue: CGFloat = 0.5
        
        if isCameraBackPosition {
            
            if let _backWideScale = backWideScale {
                
                wideAngleValue = _backWideScale
            } else {
                LogDebug("支持广角的时候, 获取的后置广角的值为空")
            }
        } else {
            if let _fontWideScale = frontWideScale {
                wideAngleValue = _fontWideScale
            } else {
                LogDebug("支持广角的时候, 获取的前面置广角的值为空")
            }
        }
        return wideAngleValue
    }

    func original(original: GPOrientation) {
        
        if self.original == original {
            return
        }
        self.original = original
        
        var transfer = CGAffineTransform.identity
        switch original {
        case .portraitDirection: break
        case .downDirection: transfer = transfer.rotated(by: CGFloat.pi)
        case .leftDirection: transfer = transfer.rotated(by: CGFloat.pi * 0.5)
        case .rightDirection: transfer = transfer.rotated(by: -CGFloat.pi * 0.5)
        default:return
        }
        
        wideAngleButtons.forEach {
            $0.transform = transfer
        }
    }
}

// MARK: - // 3.0.80：焦距入口外露显示数字+圆圈
class XHOneWideAngleButton: UIButton {
    
    private var titleLab: UILabel = {
        UILabel(text: "", textColor: UIColor.white, textFont: UIFont.boldSystemFont(ofSize: 11), textAlignment: .center, backgroundColor: UIColor.fromHex("#000000").withAlphaComponent(0.2), cornerRadius: 12.0)
    }()
    
    private var titleText: String = ""
    
    init(titleText: String) {
        self.titleText = titleText
        super.init(frame: .zero)
        buildUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildUI() {
        addSubview(titleLab)
        titleLab.adjustsFontSizeToFitWidth = true
        titleLab.snp.remakeConstraints { make in
            make.width.height.equalTo(24.0)
            make.centerX.centerY.equalToSuperview()
        }
        
        //设置阴影颜色
        titleLab.layer.shadowColor = UIColor.fromHex("#000000").cgColor
        //阴影透明度，默认0
        titleLab.layer.shadowOpacity = 0.5
        // shadowOffset阴影偏移,x向右偏移0，y向下偏移0，默认(0, -3),这个跟shadowRadius配合使用
        titleLab.layer.shadowOffset = CGSize(width: 0, height: 0)
        //阴影半径，默认3
        titleLab.layer.shadowRadius = 1
    }
    
    // 更新状态
    func updateStatus(isSelected: Bool, titleText: String) {
        
        self.isSelected = isSelected
        self.titleText = titleText
        titleLab.text = titleText
        
        if isSelected {
            titleLab.layerCornerRadius = GPWideAngleView.width / 2.0
            titleLab.font = UIFont.boldSystemFont(ofSize: 13)
            titleLab.setBorder(color: UIColor.white, width: 1.3)
            titleLab.backgroundColor = UIColor.fromHex("#000000").withAlphaComponent(0.3)
            titleLab.snp.remakeConstraints { make in
                make.width.height.equalTo(GPWideAngleView.width)
                make.centerX.centerY.equalToSuperview()
            }
        } else {
            titleLab.layerCornerRadius = 12.0
            titleLab.font = UIFont.boldSystemFont(ofSize: 11)
            titleLab.setBorder(color: UIColor.clear, width: 0)
            titleLab.backgroundColor = UIColor.fromHex("#000000").withAlphaComponent(0.2)
            titleLab.snp.remakeConstraints { make in
                make.width.height.equalTo(24.0)
                make.centerX.centerY.equalToSuperview()
            }
        }
    }
}
