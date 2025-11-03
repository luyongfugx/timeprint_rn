//
//  WatermarkID7View.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/1.
//

import Foundation
import UIKit

class WatermarkID7View: BaseWatermark{
 
    //animation_View的宽度
    static let currentAnimationViewWidth: CGFloat = 230
    
    var topItemList: [WatermarkItem] = []
    var bottomItemList: [WatermarkItem] = []
    
    private lazy var topCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.estimatedItemSize = .init(width: WatermarkID7View.currentAnimationViewWidth, height: 22)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .fromHex("#0527AF").withAlphaComponent(0.6)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.registerCell(ID120WatermarkTopCell.self)
        collectionView.registerHeader(ID120WatermarkLogoView.self)
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    private lazy var bottomCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.estimatedItemSize = .init(width: WatermarkID7View.currentAnimationViewWidth, height: 22)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .white.withAlphaComponent(0.6)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.registerCell(ID120WatermarkBottomCell.self)
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    var tableWidth: CGFloat = 0
    var topTableHeight: CGFloat = 0
    var bottomTableHeight: CGFloat = 0

    var themeColor: UIColor {
        return UIColor.fromHex("#0527AF")
    }
    
    override func buildViews() {
        super.buildViews()
        animationView.addSubview(topCollectionView)
        animationView.addSubview(bottomCollectionView)

        outLogoPadding = 6
    }
    
    override func updateUI() {
        super.updateUI()
        
        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        let watermarkTextColor = watermarkModel?.textColor ?? .text_ultrastrong
//        watermarkThemeColor = .fromHex("#07d4b7")
//        watermarkTextColor = .fromHex("#000000")
        
        // 时间
        reloadTimes()
                
        topItemList = watermarkModel?.allTopOpenItem ?? []
        bottomItemList = watermarkModel?.allBottomOpenItem ?? []
        topTableHeight = calculateTopViewHeight()
        bottomTableHeight = calculateBottomViewHeight()
        
        topCollectionView.backgroundColor = watermarkThemeColor.withAlphaComponent(0.6)
        topCollectionView.reloadData()
        bottomCollectionView.reloadData()
                  
        updateSubLabelColor(bottomCollectionView, watermarkTextColor)
        
        setNeedsLayout()
        
    }
        
    func calculateTopViewHeight() -> CGFloat {
        var totalHeight: CGFloat = 0
        for item in topItemList {
            if item.idType == .logo, item.canShowID7Logo() {
                totalHeight += 42
            } else {
                totalHeight += ID120WatermarkTopCell.calculateHeight(item: item, conent: item.getShowContent(baseID: watermarkModel?.baseID))
            }
        }
        return totalHeight
    }
    
    func calculateBottomViewHeight() -> CGFloat {
        var totalHeight: CGFloat = 0
        for item in bottomItemList {
            totalHeight += ID120WatermarkBottomCell.calculateHeight(item: item, conent: item.getShowContent(baseID: watermarkModel?.baseID))
        }
        if totalHeight > 0 {
            totalHeight += 8
        }
        return totalHeight
    }
    
    override func reloadTimes() {
        super.reloadTimes()
        bottomCollectionView.reloadData()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        reloadAnimationViewSize()
    }
    
    func reloadAnimationViewSize(shouldRelayout: Bool = true) {
        if shouldRelayout {
            layoutIfNeeded()
        }
        
        if animationView.bottom == 0 {
            animationView.bottom = height
        }
        
        topCollectionView.frame = .init(x: 6, y: 6, width: WatermarkID7View.currentAnimationViewWidth, height: topTableHeight)
        
        bottomCollectionView.frame = .init(x: 6, y: topCollectionView.bottom, width: WatermarkID7View.currentAnimationViewWidth, height: bottomTableHeight)
        
        let animateViewHeight = topTableHeight + bottomTableHeight + 12
        let animationView_w = WatermarkID7View.currentAnimationViewWidth + 12
        animationView.frame = CGRect.init(x: animationView.left, y: animationView.bottom - animateViewHeight, width: animationView_w, height: animateViewHeight)
        
        if sizeScale != 1 {
            makeChangSizeUI(animationView_w: animationView_w, content_y: animateViewHeight)
        } else {
            scaleContentView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        resetFrame()
    }

}

extension WatermarkID7View: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if collectionView == topCollectionView {
            if section == 0 {
                let isOpen = watermarkModel?.logoItem()?.canShowID7Logo() ?? false
                return isOpen ? .init(width: collectionView.bounds.width, height: 42) : .zero
            }
            return .zero
        } else {
            return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == topCollectionView {
            guard let item = topItemList[safe: indexPath.item] else {
                return .zero
            }
            if item.idType == .logo, item.canShowID7Logo() {
                return .init(width: WatermarkID7View.currentAnimationViewWidth, height: 42)
            } else {
                return .init(width: WatermarkID7View.currentAnimationViewWidth, height: ID120WatermarkTopCell.calculateHeight(item: item, conent: item.getShowContent(baseID: watermarkModel?.baseID)))
            }
        } else {
            guard let item = bottomItemList[safe: indexPath.item] else {
                return .zero
            }
            return .init(width: WatermarkID7View.currentAnimationViewWidth, height: ID120WatermarkBottomCell.calculateHeight(item: item, conent: item.getShowContent(baseID: watermarkModel?.baseID)))
        }
        
    }
}

extension WatermarkID7View: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == topCollectionView {
            return topItemList.count
        } else {
            return bottomItemList.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == topCollectionView {
            let cell = collectionView.dequeueCell(ID120WatermarkTopCell.self, for: indexPath)

            guard let item = topItemList[safe: indexPath.item] else {
                return cell
            }
            
            let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
            let watermarkTextColor = watermarkModel?.textColor ?? .white

            cell.configData(item: item, conent: item.getShowContent(baseID: watermarkModel?.baseID), themeColor: watermarkThemeColor, textColor: watermarkTextColor)
            
            let noLogo = !(watermarkModel?.logoItem()?.canShowID7Logo() == true)
            cell.shouldAdjustSpacing = indexPath.item == 0 && noLogo
            cell.isLast = indexPath.item + 1 == topItemList.count
            
            return cell
        } else {
            let cell = collectionView.dequeueCell(ID120WatermarkBottomCell.self, for: indexPath)

            guard let item = bottomItemList[safe: indexPath.item] else {
                return cell
            }
            
            let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
            let watermarkTextColor = watermarkModel?.textColor ?? .white
            cell.configData(title: item.title, conent: item.getShowContent(baseID: watermarkModel?.baseID), themeColor: watermarkThemeColor, textColor: watermarkTextColor)
            
//            cell.loadWatermarkItem(item, watermark: twModel)
            cell.isFirst = indexPath.item == 0
            cell.isLast = indexPath.item + 1 == bottomItemList.count
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if collectionView == topCollectionView {
            if kind.elementsEqual(UICollectionView.elementKindSectionHeader) {
                let header = collectionView.dequeueHeader(ID120WatermarkLogoView.self, for: indexPath)
                let logoList = watermarkModel?.logoItem()?.extraLogoListInfo.logoList ?? []
                let isOpen = watermarkModel?.logoItem()?.canShowID7Logo() ?? false
                header.loadWatermarkLogos(isOpen ? logoList : [])
                return header
            }
        }
        
        return UICollectionReusableView()
    }
}
