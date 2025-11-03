//
//  BaseWatermark+Gesture.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import Foundation
import UIKit

extension BaseWatermark{
    
    func addGesture() {
        if GPCheetManager.isCheetMode {
            return
        }
        if isPreviewMode {
            // 预览模式不加交互
            animationView.isUserInteractionEnabled = false
            outLogoView.isUserInteractionEnabled = false
            mapView.isUserInteractionEnabled = false
        } else {
            animationView.addTapGestureRecognizer(target: self, action: #selector(eidtWatermark))
            outLogoView.addTapGestureRecognizer(target: self, action: #selector(clickOutLogo))
            mapView.addTapGestureRecognizer(target: self, action: #selector(clickOutMap))
            
            subviews.forEach { view in
                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
                view.addGestureRecognizer(panGesture)
                view.isUserInteractionEnabled = true
            }
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let movingView = gesture.view else { return }
        
        switch gesture.state {
        case .began:
            selectedView = movingView
            lastLocation = movingView.center
            bringSubviewToFront(movingView)
            
        case .changed:
            let translation = gesture.translation(in: self)
            var newCenter = CGPoint(x: lastLocation.x + translation.x, y: lastLocation.y + translation.y)
            
            // 确保不超出父视图边界
            newCenter.x = max(movingView.bounds.width/2, min(newCenter.x, self.bounds.width - movingView.bounds.width/2))
            newCenter.y = max(movingView.bounds.height/2, min(newCenter.y, self.bounds.height - movingView.bounds.height/2))
            
            // 自由移动当前视图
            movingView.center = newCenter
            
            // 其他视图自动避让
            adjustOtherViews(for: movingView, forceCheck: true, maxDepth: 3)
            
        case .ended, .cancelled:
            adjustOtherViews(for: movingView, forceCheck: false, maxDepth: 3)
            selectedView = nil
            saveViewPositions()
            
        default:
            break
        }
    }
    
    // MARK: - 自适应避让逻辑
    func adjustOtherViews(for movingView: UIView, forceCheck: Bool, maxDepth: Int) {
        guard maxDepth > 0 else { return }

        // ✅ 关键 1：如果本次移动的是官方水印，直接跳过，不触发其它视图避让
        if movingView.tag == OffcialLogoViewTag {
            return
        }

        // 原来这里是：let otherViews = subviews.filter { $0 != movingView || $0.tag == OffcialLogoViewTag }
        // ✅ 关键 2：从对比列表中移除官方水印（它是全屏容器，会导致总是相交）
        let otherViews = subviews.filter {
            $0 !== movingView && $0.tag != OffcialLogoViewTag
        }
        
        for view in otherViews {
            guard view.isHidden == false else { continue }
            if movingView.frame.intersects(view.frame) {
                // 计算重叠方向和需要移动的距离
                let overlapX = movingView.frame.minX - view.frame.minX
                let overlapY = movingView.frame.minY - view.frame.minY
                
                var newFrame = view.frame
                
                // 判断主要重叠方向（X轴或Y轴）
                if abs(overlapY) > abs(overlapX) {
                    // Y轴方向重叠（上下方向）
                    if overlapY < 0 {
                        // 向上移动其他视图
                        newFrame.origin.y = movingView.frame.maxY + minSpacing
                        if newFrame.origin.y > realHeight() {
                            // 超过最大高度，那么调换位置，放到上面
                            newFrame.origin.y = movingView.frame.minY - minSpacing - newFrame.height
                        }
                    } else {
                        // 向下移动其他视图
                        newFrame.origin.y = movingView.frame.minY - view.frame.height - minSpacing
                        if newFrame.origin.y < 0 {
                            // 超出最顶部，那么调换位置放到下面
                            newFrame.origin.y = movingView.frame.maxY + minSpacing
                        }
                    }
                } else {
                    // X轴方向重叠（左右方向）
                    if overlapX < 0 {
                        // 向右移动其他视图
                        newFrame.origin.x = movingView.frame.maxX + minSpacing
                        if newFrame.origin.x > realWidth() {
                            // 超出最右边，那么放到左边
                            newFrame.origin.x = movingView.frame.minX - minSpacing - newFrame.width
                        }
                    } else {
                        // 向左移动其他视图
                        newFrame.origin.x = movingView.frame.minX - view.frame.width - minSpacing
                        if newFrame.origin.x < 0 {
                            // 超出了最左边，那么放到右边
                            newFrame.origin.x = movingView.frame.minX + minSpacing
                        }
                    }
                }
                
                // 确保不会移出父视图
                if forceCheck {
                    if (newFrame.origin.x < 0) || (newFrame.origin.x > self.bounds.width - newFrame.width) || (newFrame.origin.y > self.bounds.height - newFrame.height) || (newFrame.origin.y < 0) {
                        return
                    }
                }
                
                // 确保不会移出父视图
                newFrame.origin.x = max(0, min(newFrame.origin.x, self.bounds.width - newFrame.width))
                newFrame.origin.y = max(0, min(newFrame.origin.y, self.bounds.height - newFrame.height))
                
                // 应用新位置
                UIView.animate(withDuration: 0.2) {
                    view.frame = newFrame
                }
                
                // 递归检查是否需要继续避让
                adjustOtherViews(for: view, forceCheck: forceCheck, maxDepth: maxDepth - 1 )
            }
        }
    }
    
    func frameSizeChange(orientation: GPOrientation){
        self.orientation = orientation
    }

}

extension BaseWatermark {
    @objc func eidtWatermark() {
        gotoEdit()
    }
    
    @discardableResult
    func gotoEdit() -> EditWatermarkVC? {
        guard let watermarkModel else { return nil }
        return delegate?.gotoEditCurrentWatermark()
    }
}

extension BaseWatermark {
    
    @objc
    func clickOutLogo() {
        GPToViewManager.shared.goto(.editLogo)
    }
    
    @objc
    func clickOutMap() {
        GPToViewManager.shared.goto(.editMap)
    }
    
}


enum Quadrant: String {
    case topLeft = "topLeft"
    case topRight = "topRight"
    case bottomLeft = "bottomLeft"
    case bottomRight = "bottomRight"
}

class AllWatermarkViewPosition: NSObject, GPCodable {
    var list: [OneWatermarkViewPosition]?
}

class OneWatermarkViewPosition: NSObject, GPCodable {
    var classIdentifer: String?
    var quadrantStr: String?
    var quadrantEnum: Quadrant {
        get {
            Quadrant.init(rawValue: quadrantStr ?? "") ?? .topLeft
        } set {
            quadrantStr = newValue.rawValue
        }
    }
    var left: CGFloat?
    var top: CGFloat?
    var right: CGFloat?
    var bottom: CGFloat?
    
    static func getClassIdentifer(_ view: UIView) -> String {
        return String(describing: type(of: view))
    }
}
