//
//  BaseWatermark+Position.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/5/5.
//

extension BaseWatermark {
    
    func getModelPositionKey() -> String {
        return "local_viewPositions_" + (watermarkModel?.id ?? "")
    }
    
    private func getPositionM() -> AllWatermarkViewPosition {
        if let positionModel {
            return positionModel
        }
        if let quadrantPositionsStr = UserDefaults.standard.string(forKey: getModelPositionKey()), let positionM = SpeedyModel.anyToModel(AllWatermarkViewPosition.self, param: quadrantPositionsStr) {
            return positionM
        }
        return getDefaultPosition()
    }
    
    func loadViewPositions() {
        
        let positionM = getPositionM()
        self.positionModel = positionM
        
        // 先尝试从保存的象限位置加载
        for view in subviews {
            let identifier = OneWatermarkViewPosition.getClassIdentifer(view)
            if let oneViewPosition = positionM.list?.first(where: { $0.classIdentifer == identifier }) {
                switch oneViewPosition.quadrantEnum {
                case .topLeft:
                    view.top = oneViewPosition.top ?? minSpacing
                    view.left = oneViewPosition.left ?? minSpacing
                case .topRight:
                    view.top = oneViewPosition.top ?? minSpacing
                    view.right = realWidth() - (oneViewPosition.right ?? minSpacing)
                case .bottomLeft:
                    view.bottom = realHeight() - (oneViewPosition.bottom ?? minSpacing)
                    view.left = oneViewPosition.left ?? minSpacing
                case .bottomRight:
                    view.bottom = realHeight() - (oneViewPosition.bottom ?? minSpacing)
                    view.right = realWidth() - (oneViewPosition.right ?? minSpacing)
                }
                
                // 特殊处理，编辑模式下，适配
                if view.isKind(of: WMAnimationView.self), isPreviewMode {
                    view.bottom = realHeight()
                    view.left = oneViewPosition.left ?? 0
                }

            } else {
                // 否则放到左上角
                view.top = minSpacing
                view.left = minSpacing
                
                // 特殊处理，编辑模式下，适配
                if view.isKind(of: WMAnimationView.self), isPreviewMode {
                    view.bottom = realHeight()
                    view.left = 0
                }
            }
            
        }
        
        // 检查View是否冲突
        if let lastV = subviews.last {
            selectedView = lastV
            adjustOtherViews(for: lastV, forceCheck: false, maxDepth: 3)
            selectedView = nil
        }
    }
    
    func getDefaultPosition() -> AllWatermarkViewPosition {
        let newPositionModel = AllWatermarkViewPosition()
        newPositionModel.list = []
        for view in subviews {
            let onePosition = OneWatermarkViewPosition()
            onePosition.classIdentifer = OneWatermarkViewPosition.getClassIdentifer(view)
            if view.isKind(of: GPMapView.self) {
                onePosition.quadrantEnum = .topRight
                onePosition.left = minSpacing
                onePosition.right = minSpacing
                onePosition.top = minSpacing
                onePosition.bottom = minSpacing
            } else if view.isKind(of: GPOutLogoView.self) {
                onePosition.quadrantEnum = .topLeft
                if let logoPosition = watermarkModel?.logoItem()?.extraLogo.enumPosition {
                    if logoPosition == .rightTop {
                        onePosition.quadrantEnum = .topRight
                    }
                }
                onePosition.left = minSpacing
                onePosition.right = minSpacing
                onePosition.top = minSpacing
                onePosition.bottom = minSpacing
            } else if view.isKind(of: WMAnimationView.self) {
                onePosition.quadrantEnum = .bottomLeft
                onePosition.left = 0
                onePosition.right = 0
                onePosition.top = 0
                onePosition.bottom = 0
            }
            
            newPositionModel.list?.append(onePosition)
        }
        return newPositionModel
    }
    
    // MARK: - 象限相关方法
    
    // 获取视图所在的象限
    private func getQuadrant(for view: UIView) -> Quadrant {
        let center = view.center
        let parentCenter = CGPoint(x: realWidth() / 2, y: realHeight() / 2)
        
        if center.x <= parentCenter.x {
            return center.y <= parentCenter.y ? .topLeft : .bottomLeft
        } else {
            return center.y <= parentCenter.y ? .topRight : .bottomRight
        }
    }
    
    func saveViewPositions () {
        if isCover || isEditPage || isPreviewMode {
            return
        }
        let newPositionModel = AllWatermarkViewPosition()
        newPositionModel.list = []
        for view in subviews {
            if view.isHidden == false {
                let onePosition = OneWatermarkViewPosition()
                onePosition.classIdentifer = OneWatermarkViewPosition.getClassIdentifer(view)
                onePosition.quadrantEnum = getQuadrant(for: view)
                onePosition.left = view.left
                onePosition.right = realWidth() - view.right
                onePosition.top = view.top
                onePosition.bottom = realHeight() - view.bottom
                newPositionModel.list?.append(onePosition)
            }
        }
        self.positionModel = newPositionModel
        let modelKey = getModelPositionKey()
        let postionValue = SpeedyModel.modelToString(newPositionModel)
        UserDefaults.standard.setValue(postionValue, forKey: modelKey)
    }
    
}

extension BaseWatermark {
    
    func realWidth() -> CGFloat {
        if self.orientation == .portraitDirection || self.orientation == .downDirection {
            return self.width
        } else {
            return self.height
        }
    }
    
    func realHeight() -> CGFloat {
        if self.orientation == .portraitDirection || self.orientation == .downDirection {
            return self.height
        } else {
            return self.width
        }
    }
    
}
