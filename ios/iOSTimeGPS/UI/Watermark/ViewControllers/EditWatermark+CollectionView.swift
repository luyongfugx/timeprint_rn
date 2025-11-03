//
//  EditWatermark+CollectionView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/21.
//

import Foundation

///云配水印列表布局
class CloudWatermarkListLayout: UICollectionViewFlowLayout {
    

    static let edge = UIEdgeInsets.init(top: 0, left: 11, bottom: 0, right: 11)
    static let columnSpace: CGFloat = 4
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    override init() {
        super.init()
  

        setUp()
    }
    
    func setUp(){
        
        minimumLineSpacing = 0
        minimumInteritemSpacing =  0
        scrollDirection = .vertical
        sectionInset = CloudWatermarkListLayout.edge
        itemSize = CloudWatermarkListLayout.itemSize()
        footerReferenceSize = CGSize(width: GPApp.screenWidth, height: GPApp.tabBarBottomHeight+40)
    }
    
    static func topSpace()->CGFloat{
        return 5
    }
    
    static func itemSize() -> CGSize {
        
        let itemW = (UIScreen.main.bounds.width - edge.left - edge.right - columnSpace) * 0.5
        return CGSize(width: itemW , height: 118 / 176 * itemW)
    }
    
    static func coverSize() -> CGSize {
        
        let coverWidth = itemSize().width * 165 / 176
        return CGSize(width: coverWidth , height: 80 / 166 * coverWidth)
    }
    
    static func scale() -> CGFloat {
        
        let itemW = (UIScreen.main.bounds.width - edge.left - edge.right - columnSpace) * 0.5
        return itemW / 176
    }
}

